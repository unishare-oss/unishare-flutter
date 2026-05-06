import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { nanoid } from 'nanoid';
import { verifyFirebaseJwt } from './jwt';

export interface Env {
  FIREBASE_PROJECT_ID: string;
  R2_PUBLIC_URL: string;
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_BUCKET: string;
}

const ALLOWED_CONTENT_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
  'text/plain',
]);

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
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

    // Generate pre-signed R2 URL
    const key = `posts/${uid}/${nanoid()}-${filename}`;
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

    const uploadUrl = await getSignedUrl(client, command, { expiresIn: 300 });
    const publicUrl = `${env.R2_PUBLIC_URL}/${key}`;

    return json({ uploadUrl, publicUrl }, 200);
  },
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
