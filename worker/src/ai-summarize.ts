import Groq from 'groq-sdk'
import { extractText } from './text-extractor'
import type { Env } from './index'

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

  // Download file from its public R2 URL
  const fileRes = await fetch(fileUrl)
  if (!fileRes.ok) return jsonError('Failed to fetch file', 502)
  const buffer = await fileRes.arrayBuffer()

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

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function jsonError(message: string, status: number): Response {
  return json({ error: message }, status)
}
