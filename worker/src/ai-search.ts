import type { Env } from './index'
import { embedText } from './embeddings'
import { json, jsonError } from './response'

const MAX_QUERY_LENGTH = 200
const DEFAULT_LIMIT = 10
const MAX_LIMIT = 30
/// Similarity floor — Vectorize returns cosine distances inverted to scores in
/// [0, 1] (1.0 is identical). We've seen academic-content noise sit at ~0.55
/// for unrelated queries; 0.65 keeps the tail clean without dropping useful
/// near-matches. Callers can override per-request.
const DEFAULT_SIMILARITY_FLOOR = 0.65

/// PROP-0011 Phase 4b — POST /ai/search.
/// Body: { query: string, limit?: number, similarityFloor?: number }
/// Returns: { results: [{ postId, score }] } ordered by similarity desc.
export async function handleAiSearch(request: Request, env: Env): Promise<Response> {
  let body: { query: unknown; limit?: unknown; similarityFloor?: unknown }
  try {
    body = await request.json()
  } catch {
    return jsonError('Invalid JSON body', 400)
  }

  const query = typeof body.query === 'string' ? body.query.trim() : ''
  if (!query || query.length > MAX_QUERY_LENGTH) {
    return jsonError(`query must be a non-empty string under ${MAX_QUERY_LENGTH} chars`, 400)
  }
  const limit = clampInt(body.limit, DEFAULT_LIMIT, 1, MAX_LIMIT)
  const floor = clampFloat(body.similarityFloor, DEFAULT_SIMILARITY_FLOOR, 0, 1)

  // Embed the query — same model + dim used at write time.
  let vector: number[]
  try {
    vector = await embedText(env, query)
  } catch (e) {
    console.error('embed query failed', e)
    return jsonError('Embedding failed', 502)
  }

  // Vectorize topK returns matches sorted desc by score.
  let queryResult: VectorizeMatches
  try {
    queryResult = await env.VECTORIZE.query(vector, { topK: limit })
  } catch (e) {
    console.error('vectorize query failed', e)
    return jsonError('Search failed', 502)
  }

  const results = (queryResult.matches ?? [])
    .filter((m) => m.score >= floor)
    .map((m) => ({ postId: m.id, score: m.score }))

  return json({ results })
}

function clampInt(value: unknown, fallback: number, min: number, max: number): number {
  const n = typeof value === 'number' ? Math.floor(value) : fallback
  if (Number.isNaN(n)) return fallback
  return Math.max(min, Math.min(max, n))
}

function clampFloat(value: unknown, fallback: number, min: number, max: number): number {
  const n = typeof value === 'number' ? value : fallback
  if (Number.isNaN(n)) return fallback
  return Math.max(min, Math.min(max, n))
}
