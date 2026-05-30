import type { Env } from './index'
import { embedText } from './embeddings'
import { json, jsonError } from './response'

const MAX_TITLE_LEN = 200
const MAX_DESCRIPTION_LEN = 5000
/// Mirrors ai-summarize.ts SEARCH_BLOB_CHAR_CAP; the search blob fed to the
/// embedding model is bounded by BGE's 512-token truncation.
const SEARCH_BLOB_CHAR_CAP = 2000

interface ReindexBody {
  postId: string
  title: string
  description: string
}

/// PROP-0011 follow-up — POST /ai/reindex.
/// Re-builds the post-level search blob from the incoming title/description
/// (Firestore replica may not have propagated yet) merged with persisted
/// summary + aiTags + extractedText, then upserts the post-level vector.
/// Chunks are NOT touched; extractedText doesn't change on a metadata edit.
export async function handleAiReindex(
  request: Request,
  env: Env,
  uid: string,
): Promise<Response> {
  let body: Partial<ReindexBody>
  try {
    body = (await request.json()) as Partial<ReindexBody>
  } catch {
    return jsonError('Invalid JSON body', 400)
  }

  const postId = typeof body.postId === 'string' ? body.postId.trim() : ''
  const title = typeof body.title === 'string' ? body.title.trim() : ''
  const description =
    typeof body.description === 'string' ? body.description.trim() : ''

  if (!postId) return jsonError('postId required', 400)
  if (title.length === 0 || title.length > MAX_TITLE_LEN) {
    return jsonError(`title required and ≤ ${MAX_TITLE_LEN} chars`, 400)
  }
  if (description.length > MAX_DESCRIPTION_LEN) {
    return jsonError(`description must be ≤ ${MAX_DESCRIPTION_LEN} chars`, 400)
  }

  // Fetch the post doc to confirm ownership + read persisted fields.
  // Worker uses Firestore REST (no Admin SDK in the runtime).
  const docUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/posts/${encodeURIComponent(postId)}`
  let docRes: Response
  try {
    docRes = await fetch(docUrl)
  } catch (e) {
    console.error('reindex: firestore fetch failed', e)
    return jsonError('Failed to read post', 502)
  }
  if (docRes.status === 404) return jsonError('Post not found', 404)
  if (!docRes.ok) return jsonError('Failed to read post', 502)

  const doc = (await docRes.json()) as {
    fields?: Record<string, { stringValue?: string; arrayValue?: { values?: { stringValue?: string }[] } }>
  }
  const fields = doc.fields ?? {}
  const authorId = fields.authorId?.stringValue ?? ''
  if (authorId !== uid) return jsonError('Forbidden', 403)

  const summary = fields.summary?.stringValue ?? ''
  const extractedText = fields.extractedText?.stringValue ?? ''
  const aiTagsRaw = fields.aiTags?.arrayValue?.values ?? []
  const aiTags = aiTagsRaw
    .map((v) => v.stringValue)
    .filter((s): s is string => typeof s === 'string' && s.length > 0)

  // Rebuild the search blob — same composition as ai-summarize.ts buildSearchBlob.
  const parts: string[] = []
  if (title) parts.push(title)
  if (summary) parts.push(summary)
  if (description) parts.push(description)
  if (aiTags.length > 0) parts.push(aiTags.join(' '))
  if (extractedText) parts.push(extractedText.slice(0, 1500))
  const blob = parts.join('\n\n').slice(0, SEARCH_BLOB_CHAR_CAP)
  if (!blob.trim()) return jsonError('Nothing to index', 400)

  let vector: number[]
  try {
    vector = await embedText(env, blob)
  } catch (e) {
    console.error('reindex: embed failed', e)
    return jsonError('Embedding failed', 502)
  }

  try {
    await env.VECTORIZE.upsert([{ id: postId, values: vector }])
  } catch (e) {
    console.error('reindex: upsert failed', e)
    return jsonError('Upsert failed', 502)
  }

  return json({ reindexed: true })
}
