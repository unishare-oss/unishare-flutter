import Groq from 'groq-sdk'
import { extractText } from './text-extractor'
import type { Env } from './index'
import { json, jsonError } from './response'

const SUMMARY_PROMPT = `You are summarizing an academic document for university students.
Respond with exactly this format — no extra text, no markdown headers:

One sentence describing what this document is.
• Key topic or concept covered
• Key topic or concept covered
• Key topic or concept covered

Use 3 to 7 bullet points. Be specific about subject matter — not generic.
If the document contains harmful or clearly inappropriate content, respond with only: FLAGGED`

export async function handleAiSummarize(request: Request, env: Env): Promise<Response> {
  let body: { fileUrl: string; filename: string }
  try {
    body = await request.json()
  } catch {
    return jsonError('Invalid JSON body', 400)
  }

  const { fileUrl, filename } = body
  if (!fileUrl || typeof fileUrl !== 'string') return jsonError('fileUrl required', 400)
  if (!filename || typeof filename !== 'string') return jsonError('filename required', 400)

  let parsed: URL
  try {
    parsed = new URL(fileUrl)
  } catch {
    return jsonError('invalid fileUrl', 400)
  }
  const allowedOrigin = new URL(env.R2_PUBLIC_URL).origin
  if (
    parsed.protocol !== 'https:' ||
    parsed.origin !== allowedOrigin ||
    !parsed.pathname.startsWith('/posts/')
  ) {
    return jsonError('fileUrl must reference a file in this service', 400)
  }

  // Download file with size and time guards
  const MAX_BYTES = 20 * 1024 * 1024 // 20 MB
  const abort = new AbortController()
  const timeout = setTimeout(() => abort.abort(), 10_000)

  let fileRes: Response
  try {
    fileRes = await fetch(fileUrl, { signal: abort.signal })
  } catch {
    return jsonError('Failed to fetch file', 502)
  } finally {
    clearTimeout(timeout)
  }

  if (!fileRes.ok) return jsonError('Failed to fetch file', 502)

  const contentLength = Number(fileRes.headers.get('content-length') ?? 0)
  if (contentLength > MAX_BYTES) return jsonError('File too large', 413)

  const buffer = await fileRes.arrayBuffer()
  if (buffer.byteLength > MAX_BYTES) return jsonError('File too large', 413)

  let text: string
  try {
    text = await extractText(buffer, filename)
  } catch (e) {
    const msg = (e as Error).message
    if (msg === 'unsupported_format') {
      return json({ summaryStatus: 'unsupported_type', summary: null })
    }
    return jsonError('Text extraction failed', 500)
  }

  if (!text.trim()) {
    return json({ summaryStatus: 'unsupported_type', summary: null })
  }

  const groq = new Groq({ apiKey: env.GROQ_API_KEY })
  const model = env.GROQ_MODEL ?? 'llama-3.3-70b-versatile'

  let summary: string
  try {
    const response = await groq.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: SUMMARY_PROMPT },
        { role: 'user', content: text },
      ],
      max_tokens: 300,
      temperature: 0,
    })
    summary = response.choices[0]?.message?.content?.trim() ?? ''
  } catch {
    return jsonError('LLM call failed', 502)
  }

  if (summary.toUpperCase() === 'FLAGGED') {
    return json({ summaryStatus: 'flagged', summary: null })
  }

  return json({ summaryStatus: 'done', summary })
}
