import Groq from 'groq-sdk'
import type { Env } from './index'
import { json, jsonError } from './response'

/// Advisory content-moderation verdict. The Cloud Function that calls this
/// endpoint persists the result onto the post as `aiVerdict` — a human
/// moderator still makes the final approve/reject decision. The AI never
/// mutates `status`.
export interface AiVerdict {
  recommended: 'approve' | 'reject'
  /** 0..1 */
  confidence: number
  reason: string
}

interface ModerationInput {
  title: string
  description: string
  tags: string[]
  postType: string
  /** Extracted document text / OCR transcription, when summarize has run. */
  extractedText: string
}

const TEXT_MODEL_DEFAULT = 'llama-3.3-70b-versatile'

/// Cap the document excerpt we feed the classifier. The full text is already
/// persisted by summarize; a leading slice is plenty of signal for a verdict
/// and keeps per-request tokens (and Groq free-tier rate-limit pressure) bounded.
const CONTENT_CAP = 4000

function buildPrompt(input: ModerationInput): string {
  const content = input.extractedText.trim()
  const contentBlock = content
    ? `\n\ndocument content (excerpt):\n${content.slice(0, CONTENT_CAP)}`
    : ''
  return `You are a content moderator for an academic file-sharing platform used by university students.

Decide if this post should be APPROVED for the public feed or REJECTED.

Approve when the post is:
- academic in nature (lecture notes, exercises, study material, course-relevant)
- non-offensive (no slurs, sexual content, harassment, illegal material)
- not obvious spam or self-promotion

Reject when the post contains:
- harmful or clearly inappropriate content
- spam, advertising, or content unrelated to academic work
- harassment or attacks against a person or group

Judge the actual document content when it is provided — the title and tags are
author-supplied and may not reflect what the file really contains.

POST
title: ${input.title}
description: ${input.description}
tags: ${input.tags.join(', ') || '(none)'}
postType: ${input.postType}${contentBlock}

Respond with EXACTLY this JSON shape. No preamble, no markdown fence, no closing remarks:
{ "recommended": "approve" | "reject", "confidence": <number between 0 and 1>, "reason": "<one short sentence>" }`
}

/// Fail-open verdict — when the model is unavailable or returns garbage we
/// recommend approve at zero confidence so the post falls through to a human
/// moderator rather than being silently rejected.
function deferToHuman(reason: string): AiVerdict {
  return { recommended: 'approve', confidence: 0, reason }
}

async function classifyPost(
  apiKey: string,
  model: string,
  input: ModerationInput,
): Promise<AiVerdict> {
  let raw: string
  try {
    const groq = new Groq({ apiKey })
    const completion = await groq.chat.completions.create({
      model,
      temperature: 0,
      max_tokens: 200,
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: buildPrompt(input) }],
    })
    raw = completion.choices[0]?.message?.content ?? ''
  } catch (e) {
    console.error('moderation: groq call failed', (e as Error).message)
    return deferToHuman('AI unavailable — defer to human moderator')
  }

  let parsed: unknown
  try {
    parsed = JSON.parse(raw)
  } catch {
    console.warn('moderation: non-JSON model output', raw)
    return deferToHuman('AI returned unparseable output — defer to human moderator')
  }

  const obj = parsed as Record<string, unknown>
  const recommended = obj.recommended === 'reject' ? 'reject' : 'approve'
  const rawConf = typeof obj.confidence === 'number' ? obj.confidence : 0
  const confidence = Math.max(0, Math.min(1, rawConf))
  const reason =
    typeof obj.reason === 'string' && obj.reason.length > 0
      ? obj.reason.slice(0, 240)
      : 'No reason provided'

  return { recommended, confidence, reason }
}

export async function handleAiModerate(request: Request, env: Env): Promise<Response> {
  let body: {
    title?: unknown
    description?: unknown
    tags?: unknown
    postType?: unknown
    extractedText?: unknown
  }
  try {
    body = await request.json()
  } catch {
    return jsonError('Invalid JSON body', 400)
  }

  const title = typeof body.title === 'string' ? body.title : ''
  if (!title) return jsonError('title required', 400)

  const input: ModerationInput = {
    title,
    description: typeof body.description === 'string' ? body.description : '',
    tags: Array.isArray(body.tags)
      ? body.tags.filter((t): t is string => typeof t === 'string')
      : [],
    postType: typeof body.postType === 'string' ? body.postType : '',
    extractedText: typeof body.extractedText === 'string' ? body.extractedText : '',
  }

  const model = env.GROQ_MODEL ?? TEXT_MODEL_DEFAULT
  const verdict = await classifyPost(env.GROQ_API_KEY, model, input)
  return json(verdict)
}
