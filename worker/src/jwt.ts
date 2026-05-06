const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

interface JwtHeader {
  kid: string;
  alg: string;
}

interface JwtPayload {
  sub: string;
  aud: string;
  iss: string;
  exp: number;
  iat: number;
}

function b64url(s: string): Uint8Array {
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

/** Verifies a Firebase ID token. Returns the uid on success, throws on failure. */
export async function verifyFirebaseJwt(
  token: string,
  projectId: string,
): Promise<string> {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Malformed JWT');

  const header = JSON.parse(
    new TextDecoder().decode(b64url(parts[0])),
  ) as JwtHeader;
  const payload = JSON.parse(
    new TextDecoder().decode(b64url(parts[1])),
  ) as JwtPayload;

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp <= now) throw new Error('Token expired');
  if (payload.aud !== projectId) throw new Error('Invalid audience');
  if (payload.iss !== `https://securetoken.google.com/${projectId}`)
    throw new Error('Invalid issuer');
  if (!payload.sub) throw new Error('Missing subject');

  // Fetch JWKS (Cloudflare caches this automatically via the Cache API)
  const jwksRes = await fetch(JWKS_URL);
  if (!jwksRes.ok) throw new Error('Failed to fetch JWKS');
  const jwks = (await jwksRes.json()) as { keys: JsonWebKey[] };

  const jwk = jwks.keys.find((k) => (k as { kid?: string }).kid === header.kid);
  if (!jwk) throw new Error(`Key not found: ${header.kid}`);

  const key = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );

  const data = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const sig = b64url(parts[2]);
  const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, sig, data);
  if (!valid) throw new Error('Invalid signature');

  return payload.sub;
}
