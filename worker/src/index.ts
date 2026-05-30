import {
  S3Client,
  PutObjectCommand,
  DeleteObjectsCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { verifyFirebaseJwt } from './jwt';
import { handleAiSummarize } from './ai-summarize';
import { handleAiChat } from './ai-chat';
import { handleAiSearch } from './ai-search';
import { handleAiReindex } from './ai-reindex';
import { handleAiModerate } from './ai-moderate';
import { CORS_HEADERS, json } from './response';

export interface Env {
  FIREBASE_PROJECT_ID: string;
  R2_PUBLIC_URL: string;
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_BUCKET: string;
  GROQ_API_KEY: string;
  GROQ_MODEL?: string;
  GROQ_VISION_MODEL?: string;
  // SPEC-0013 — shared secret gating the internal /ai/moderate route. Set via
  // `wrangler secret put MODERATION_KEY`. Called server-to-server by the
  // onPostUpdated Cloud Function, never by the client, so it uses an internal
  // key rather than a user Firebase JWT.
  MODERATION_KEY: string;
  // PROP-0011 Phase 4 — semantic search bindings. Provided by wrangler.toml.
  VECTORIZE: VectorizeIndex;
  // PROP-0011 Phase 4c — canonical-tag index for embedding-based tag dedup.
  TAG_INDEX: VectorizeIndex;
  // PROP-0011 follow-up — per-post chunk index for RAG chat retrieval on long docs.
  POST_CHUNK_INDEX: VectorizeIndex;
  AI: Ai;
}

const MIME_TO_EXT: Record<string, string> = {
  // Images
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/gif': 'gif',
  'image/webp': 'webp',
  'image/svg+xml': 'svg',
  'image/tiff': 'tiff',
  'image/bmp': 'bmp',
  'image/avif': 'avif',
  'image/heic': 'heic',
  'image/heif': 'heif',
  // Documents
  'application/pdf': 'pdf',
  'application/msword': 'doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
  'application/vnd.ms-powerpoint': 'ppt',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
  'application/vnd.ms-excel': 'xls',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
  'application/vnd.oasis.opendocument.text': 'odt',
  'application/vnd.oasis.opendocument.presentation': 'odp',
  'application/vnd.oasis.opendocument.spreadsheet': 'ods',
  'application/epub+zip': 'epub',
  // Text / code
  'text/plain': 'txt',
  'text/markdown': 'md',
  'text/html': 'html',
  'text/css': 'css',
  'text/csv': 'csv',
  'application/json': 'json',
  // Archives
  'application/zip': 'zip',
  'application/x-zip-compressed': 'zip',
  'application/x-tar': 'tar',
  'application/gzip': 'gz',
  // Video
  'video/mp4': 'mp4',
  'video/webm': 'webm',
  'video/ogg': 'ogv',
  'video/quicktime': 'mov',
  'video/x-msvideo': 'avi',
  'video/x-matroska': 'mkv',
};

const ALLOWED_CONTENT_TYPES = new Set(Object.keys(MIME_TO_EXT));


export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);

    // AI routes — auth required, POST only
    if (request.method === 'POST' && url.pathname === '/ai/summarize') {
      const uid = await requireAuth(request, env);
      if (uid instanceof Response) return uid;
      return handleAiSummarize(request, env);
    }

    if (request.method === 'POST' && url.pathname === '/ai/chat') {
      const uid = await requireAuth(request, env);
      if (uid instanceof Response) return uid;
      return handleAiChat(request, env);
    }

    if (request.method === 'POST' && url.pathname === '/ai/search') {
      const uid = await requireAuth(request, env);
      if (uid instanceof Response) return uid;
      return handleAiSearch(request, env);
    }

    if (request.method === 'POST' && url.pathname === '/ai/reindex') {
      const uid = await requireAuth(request, env);
      if (uid instanceof Response) return uid;
      return handleAiReindex(request, env, uid);
    }

    // SPEC-0013 — internal moderation classifier. Server-to-server only: the
    // caller is the onPostUpdated Cloud Function, authenticated by a shared
    // secret header rather than a user Firebase JWT.
    if (request.method === 'POST' && url.pathname === '/ai/moderate') {
      if (!isInternalCaller(request, env)) {
        return json({ error: 'Unauthorized' }, 401);
      }
      return handleAiModerate(request, env);
    }

    // Internal media GC. Server-to-server only (same shared secret as
    // /ai/moderate): the purgeRejectedPostMedia Cloud Function calls this to
    // delete R2 objects for posts whose rejection retention window has lapsed.
    if (request.method === 'POST' && url.pathname === '/media/delete') {
      if (!isInternalCaller(request, env)) {
        return json({ error: 'Unauthorized' }, 401);
      }
      return handleMediaDelete(request, env);
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    // Verify Firebase ID token
    const auth = request.headers.get('Authorization') ?? '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!token) return json({ error: 'Missing token' }, 401);

    let uid: string;
    try {
      uid = await verifyFirebaseJwt(token, env.FIREBASE_PROJECT_ID);
    } catch (e) {
      return json({ error: `Unauthorized: ${(e as Error).message}` }, 401);
    }

    // Parse body
    let body: { filename: string; contentType: string };
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Invalid JSON body' }, 400);
    }

    const { filename, contentType } = body;
    if (!filename || typeof filename !== 'string') {
      return json({ error: 'filename required' }, 400);
    }
    if (!ALLOWED_CONTENT_TYPES.has(contentType)) {
      return json({ error: `contentType not allowed: ${contentType}` }, 400);
    }

    // Generate pre-signed R2 URL — key uses timestamp+random, no user filename
    const ext = MIME_TO_EXT[contentType] ?? 'bin';
    const random = crypto.randomUUID().replace(/-/g, '').slice(0, 16);
    const key = `posts/${uid}/${Date.now()}-${random}.${ext}`;
    const client = r2Client(env);

    const command = new PutObjectCommand({
      Bucket: env.R2_BUCKET,
      Key: key,
      ContentType: contentType,
    });

    let uploadUrl: string;
    try {
      uploadUrl = await getSignedUrl(client, command, { expiresIn: 300 });
    } catch (e) {
      return json({ error: 'Failed to generate upload URL' }, 500);
    }
    const publicUrl = `${env.R2_PUBLIC_URL}/${key}`;

    return json({ uploadUrl, publicUrl }, 200);
  },
};

/// S3-compatible client pointed at the R2 bucket. Shared by the upload
/// (presign) and media-delete paths.
function r2Client(env: Env): S3Client {
  return new S3Client({
    region: 'auto',
    endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    },
  });
}

/// Deletes R2 objects given their public CDN URLs. Only URLs under
/// `R2_PUBLIC_URL` with a `posts/` key prefix are eligible — anything else is
/// ignored so a bad payload can never delete outside the posts namespace.
async function handleMediaDelete(request: Request, env: Env): Promise<Response> {
  let body: { urls?: unknown };
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  if (!Array.isArray(body.urls)) {
    return json({ error: 'urls array required' }, 400);
  }

  const prefix = `${env.R2_PUBLIC_URL}/`;
  const keys: string[] = [];
  for (const u of body.urls) {
    if (typeof u !== 'string' || !u.startsWith(prefix)) continue;
    const key = u.slice(prefix.length);
    if (key.startsWith('posts/')) keys.push(key);
  }

  if (keys.length === 0) return json({ deleted: 0 }, 200);

  try {
    await r2Client(env).send(
      new DeleteObjectsCommand({
        Bucket: env.R2_BUCKET,
        Delete: { Objects: keys.map((Key) => ({ Key })), Quiet: true },
      }),
    );
  } catch {
    return json({ error: 'Failed to delete objects' }, 500);
  }

  return json({ deleted: keys.length }, 200);
}

/// Constant-time-ish check of the shared internal secret used by trusted
/// server callers (Cloud Functions) instead of a per-user Firebase JWT.
/// Rejects when the key is unset so a misconfigured deploy fails closed.
function isInternalCaller(request: Request, env: Env): boolean {
  const provided = request.headers.get('X-Internal-Key') ?? '';
  const expected = env.MODERATION_KEY ?? '';
  if (expected.length === 0 || provided.length !== expected.length) return false;
  let mismatch = 0;
  for (let i = 0; i < expected.length; i++) {
    mismatch |= provided.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return mismatch === 0;
}

async function requireAuth(request: Request, env: Env): Promise<string | Response> {
  const auth = request.headers.get('Authorization') ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!token) return json({ error: 'Missing token' }, 401);
  try {
    return await verifyFirebaseJwt(token, env.FIREBASE_PROJECT_ID);
  } catch (e) {
    return json({ error: `Unauthorized: ${(e as Error).message}` }, 401);
  }
}

