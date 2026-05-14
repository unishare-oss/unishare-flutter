import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { verifyFirebaseJwt } from './jwt';
import { handleAiSummarize } from './ai-summarize';
import { handleAiChat } from './ai-chat';

export interface Env {
  FIREBASE_PROJECT_ID: string;
  R2_PUBLIC_URL: string;
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_BUCKET: string;
  GROQ_API_KEY: string;
  GROQ_MODEL?: string;
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

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

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
    const client = new S3Client({
      region: 'auto',
      endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: env.R2_ACCESS_KEY_ID,
        secretAccessKey: env.R2_SECRET_ACCESS_KEY,
      },
    });

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

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
