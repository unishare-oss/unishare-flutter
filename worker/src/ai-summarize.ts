import { Buffer } from 'node:buffer'
import Groq from 'groq-sdk'
import { PhotonImage, resize, SamplingFilter } from '@cf-wasm/photon'
import { extractText } from './text-extractor'
import type { Env } from './index'
import { json, jsonError } from './response'

/// Shared aiTags rules — a flat list of specific topic strings. Mirrors the
/// shape of the user-typed `tags` field on the post doc, just labeled as
/// AI-derived so the UI can render them distinctly and the search backend
/// can index both.
const AI_TAGS_RULES_BASE = `aiTags rules:
- 3 to 7 specific topic strings (no broad subject areas like "biology" alone — use specific concepts like "krebs-cycle", "rsa-encryption", "matrix-multiplication").
- Lowercase kebab-case (hyphen-separated). Convert "Krebs Cycle" → "krebs-cycle".
- Each tag should be a concept a student would plausibly search for.`

/// Phase A vocabulary control (PROP-0011): when the client passes a whitelist
/// of "tags already in heavy use across the corpus", we append a preference
/// line to the prompt. The model is *encouraged* to reuse these tags so the
/// global vocabulary stays consistent, but it is *not* constrained — genuinely
/// novel topics should still get fresh tags. Phase B (embedding dedup) will
/// collapse near-synonyms automatically.
function buildAiTagsRules(existingTags: string[]): string {
  if (existingTags.length === 0) return AI_TAGS_RULES_BASE
  // Truncate the whitelist defensively so a runaway client can't blow up the
  // prompt size — 80 tags is plenty of signal for the model.
  const trimmed = existingTags.slice(0, 80).join(', ')
  return `${AI_TAGS_RULES_BASE}
- PREFER these tags already in heavy use across the corpus when applicable (reuse the exact kebab-case string): ${trimmed}. Only invent new tags for genuinely novel topics not covered by this list.`
}

/// Text-path prompt. Input is already-extracted document text. We ask for a
/// JSON envelope to get summary + aiTags in one round trip. Built per-request
/// so the Phase A whitelist can be injected into the aiTags rules.
function buildTextSummaryPrompt(existingTags: string[]): string {
  return `You are processing an academic document for university students.

Return EXACTLY a JSON object with these fields. No preamble. No markdown code fence. No closing remarks.

{
  "status": "ok" | "unreadable" | "flagged",
  "summary": "<see format below; empty string if status is not ok>",
  "aiTags": ["<topic tag>", ...]
}

When status is "ok", summary must be EXACTLY:

One sentence describing what this document is.
• Specific topic or concept
• Specific topic or concept
• Specific topic or concept

Summary rules:
- 3 to 7 bullet points.
- Name actual topics, theorems, formulas, or terms (e.g. "Lagrangian mechanics", "RSA encryption", "Krebs cycle") — avoid generic phrases like "discusses concepts" or "covers material".
- For math/science documents, identify the specific method or theorem applied, not just the subject area.

${buildAiTagsRules(existingTags)}

Set status to "unreadable" if the document is blank, gibberish, or contains no academic content (aiTags may be []).
Set status to "flagged" if the document contains harmful or clearly inappropriate content (aiTags may be []).`
}

/// Image-path prompt. We additionally ask for verbatim transcription so the
/// page text is searchable / RAG-able for downstream features.
function buildVisionSummaryPrompt(existingTags: string[]): string {
  return `You are processing an academic page (printed, scanned, or handwritten) for university students.

Return EXACTLY a JSON object with these fields. No preamble. No markdown code fence. No closing remarks.

{
  "status": "ok" | "unreadable" | "flagged",
  "transcribedText": "<verbatim text from the page, including equations and labels; empty string if status is not ok>",
  "summary": "<see format below; empty string if status is not ok>",
  "aiTags": ["<topic tag>", ...]
}

When status is "ok", summary must be EXACTLY:

One sentence describing what this document is.
• Specific topic or concept
• Specific topic or concept
• Specific topic or concept

Summary rules:
- 3 to 7 bullet points.
- Name actual topics, theorems, formulas, or terms (e.g. "Lagrangian mechanics", "RSA encryption", "Krebs cycle") — avoid generic phrases like "discusses concepts" or "covers material".
- For math/science pages, identify the specific method or theorem applied, not just the subject area.

transcribedText rules:
- Preserve the page's reading order. Include equations in their original notation (LaTeX or as written).
- Do NOT add commentary or interpretation. Just the page's text.
- For partially illegible handwriting, transcribe what you can and mark gaps with [...].

${buildAiTagsRules(existingTags)}

Set status to "unreadable" if the page is blank, unreadable, or contains no academic content (aiTags may be []).
Set status to "flagged" if the page contains harmful or clearly inappropriate content (aiTags may be []).`
}

const TEXT_MODEL_DEFAULT = 'llama-3.3-70b-versatile'
const VISION_MODEL_DEFAULT = 'meta-llama/llama-4-scout-17b-16e-instruct'
const MAX_IMAGE_DIM = 1600
const JPEG_QUALITY = 80

/// Persisted-text cap. Matches text-extractor.ts MAX_CHARS so image
/// transcriptions follow the same Firestore-doc-size budget.
const PERSIST_TEXT_CAP = 60000
/// LLM input cap for the text path. We persist up to PERSIST_TEXT_CAP but
/// only send the leading prefix to the model to keep per-request token
/// usage (and Groq free-tier rate-limit pressure) bounded.
const LLM_INPUT_CAP = 6000

/// Photon-supported image MIME types. We branch on the R2 response's
/// Content-Type (server-controlled, set when the file was uploaded through
/// our presigned-URL flow) rather than the client-supplied filename — a
/// spoofed filename can't redirect routing into the wrong summarizer.
const PHOTON_SUPPORTED_MIME = /^image\/(jpe?g|png|webp)$/i

/// aiTags shape — flat list of topic strings. Caps to keep Firestore writes
/// bounded and protect against pathological model output.
const MAX_TAGS = 7
const MAX_TAG_LEN = 60

interface SummarizeResult {
  /** Summary text, or 'FLAGGED' / 'UNREADABLE' verdict (case-sensitive). */
  summary: string
  /** Persisted-cap-bounded source text (text path: extracted; image path: transcribed). */
  extractedText: string
  /** True when the persisted text was clipped at PERSIST_TEXT_CAP. */
  extractedTextTruncated: boolean
  /** Flat list of AI-derived topic tags. Empty when the model didn't supply any. */
  aiTags: string[]
}

export async function handleAiSummarize(request: Request, env: Env): Promise<Response> {
  let body: { fileUrl: string; filename: string; existingTags?: unknown }
  try {
    body = await request.json()
  } catch {
    return jsonError('Invalid JSON body', 400)
  }

  const { fileUrl, filename } = body
  if (!fileUrl || typeof fileUrl !== 'string') return jsonError('fileUrl required', 400)
  if (!filename || typeof filename !== 'string') return jsonError('filename required', 400)

  // Phase A whitelist (PROP-0011). Advisory — empty/missing disables vocabulary
  // control for this call. Defensive validation: drop non-strings.
  const existingTags: string[] = Array.isArray(body.existingTags)
    ? body.existingTags.filter((t): t is string => typeof t === 'string' && t.length > 0)
    : []

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

  const groq = new Groq({ apiKey: env.GROQ_API_KEY })
  const contentType = fileRes.headers.get('content-type')?.toLowerCase() ?? ''
  const isImage = PHOTON_SUPPORTED_MIME.test(contentType)

  let result: SummarizeResult
  try {
    result = isImage
      ? await summarizeImage(groq, env, buffer, existingTags)
      : await summarizeText(groq, env, buffer, filename, existingTags)
  } catch (e) {
    const msg = (e as Error).message
    if (msg === 'unsupported_format') {
      return json({ summaryStatus: 'unsupported_type', summary: null })
    }
    if (msg === 'empty_text') {
      return json({ summaryStatus: 'unsupported_type', summary: null })
    }
    if (msg === 'llm_failed') {
      return jsonError('LLM call failed', 502)
    }
    return jsonError('Summarization failed', 500)
  }

  const verdict = result.summary.trim().toUpperCase()
  if (verdict === 'FLAGGED') {
    return json({ summaryStatus: 'flagged', summary: null })
  }
  if (verdict === 'UNREADABLE') {
    return json({ summaryStatus: 'unsupported_type', summary: null })
  }

  return json({
    summaryStatus: 'done',
    summary: result.summary,
    extractedText: result.extractedText,
    extractedTextTruncated: result.extractedTextTruncated,
    aiTags: result.aiTags,
  })
}

async function summarizeText(
  groq: Groq,
  env: Env,
  buffer: ArrayBuffer,
  filename: string,
  existingTags: string[],
): Promise<SummarizeResult> {
  const { text, truncated } = await extractText(buffer, filename)
  if (!text.trim()) throw new Error('empty_text')

  // Only send a leading prefix to the LLM; the full clipped text is persisted
  // for downstream features (search / RAG chat / practice questions).
  const llmInput = text.slice(0, LLM_INPUT_CAP)
  const model = env.GROQ_MODEL ?? TEXT_MODEL_DEFAULT
  let raw: string
  try {
    const response = await groq.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: buildTextSummaryPrompt(existingTags) },
        { role: 'user', content: llmInput },
      ],
      // 600 tokens covers summary + aiTags JSON envelope with margin.
      response_format: { type: 'json_object' },
      max_tokens: 600,
      temperature: 0,
    })
    raw = response.choices[0]?.message?.content?.trim() ?? '{}'
  } catch {
    throw new Error('llm_failed')
  }

  const parsed = parseSummarizeResponse(raw)
  if (parsed.status === 'flagged') {
    return { summary: 'FLAGGED', extractedText: '', extractedTextTruncated: false, aiTags: [] }
  }
  if (parsed.status === 'unreadable') {
    return { summary: 'UNREADABLE', extractedText: '', extractedTextTruncated: false, aiTags: [] }
  }
  return {
    summary: parsed.summary,
    extractedText: text,
    extractedTextTruncated: truncated,
    aiTags: parsed.aiTags,
  }
}

async function summarizeImage(
  groq: Groq,
  env: Env,
  buffer: ArrayBuffer,
  existingTags: string[],
): Promise<SummarizeResult> {
  // Resize + re-encode the upload so Groq stays under its 5 MB image cap and
  // we don't pay to upload a 12 MP camera shot for handwriting summarization.
  // Photon throws on corrupt bytes, non-image content, or unsupported codec
  // variants — we surface those as `unsupported_format` so the API contract
  // stays stable instead of leaking 500s for bad uploads.
  let inputImg: PhotonImage | null = null
  let outputImg: PhotonImage | null = null
  let jpegBytes: Uint8Array
  try {
    try {
      inputImg = PhotonImage.new_from_byteslice(new Uint8Array(buffer))
      const w = inputImg.get_width()
      const h = inputImg.get_height()
      const needsResize = w > MAX_IMAGE_DIM || h > MAX_IMAGE_DIM
      if (needsResize) {
        const ratio = Math.min(MAX_IMAGE_DIM / w, MAX_IMAGE_DIM / h)
        const targetW = Math.max(1, Math.round(w * ratio))
        const targetH = Math.max(1, Math.round(h * ratio))
        outputImg = resize(inputImg, targetW, targetH, SamplingFilter.Lanczos3)
        jpegBytes = outputImg.get_bytes_jpeg(JPEG_QUALITY)
      } else {
        // Still re-encode to JPEG so PNG/WebP uploads aren't sent at original size.
        jpegBytes = inputImg.get_bytes_jpeg(JPEG_QUALITY)
      }
    } catch {
      throw new Error('unsupported_format')
    }
  } catch {
    throw new Error('unsupported_format')
  } finally {
    inputImg?.free()
    outputImg?.free()
  }

  const dataUrl = `data:image/jpeg;base64,${Buffer.from(jpegBytes).toString('base64')}`
  const model = env.GROQ_VISION_MODEL ?? VISION_MODEL_DEFAULT

  let raw: string
  try {
    const response = await groq.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: buildVisionSummaryPrompt(existingTags) },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Process this page.' },
            { type: 'image_url', image_url: { url: dataUrl } },
          ],
        },
      ],
      // Headroom for transcription: a dense handwritten page rarely exceeds
      // ~2000 chars (~600 tokens). 4096 covers transcription + summary +
      // aiTags + JSON overhead with margin, while staying well below Llama 4
      // Scout's output cap on Groq's free tier.
      response_format: { type: 'json_object' },
      max_tokens: 4096,
      temperature: 0,
    })
    raw = response.choices[0]?.message?.content?.trim() ?? '{}'
  } catch {
    throw new Error('llm_failed')
  }

  const parsed = parseSummarizeResponse(raw)
  if (parsed.status === 'flagged') {
    return { summary: 'FLAGGED', extractedText: '', extractedTextTruncated: false, aiTags: [] }
  }
  if (parsed.status === 'unreadable') {
    return { summary: 'UNREADABLE', extractedText: '', extractedTextTruncated: false, aiTags: [] }
  }
  const truncated = parsed.transcribedText.length > PERSIST_TEXT_CAP
  const extractedText = truncated
    ? parsed.transcribedText.slice(0, PERSIST_TEXT_CAP)
    : parsed.transcribedText
  return {
    summary: parsed.summary,
    extractedText,
    extractedTextTruncated: truncated,
    aiTags: parsed.aiTags,
  }
}

/// Safe parse of the model's JSON envelope (shared by both paths). The model
/// occasionally ignores `response_format` and emits a plain string or
/// JSON-wrapped-in-markdown-fence; we treat any of those as a non-fatal
/// fallback to "use the raw text as summary, no transcription, no aiTags".
function parseSummarizeResponse(raw: string): {
  status: 'ok' | 'unreadable' | 'flagged'
  summary: string
  transcribedText: string
  aiTags: string[]
} {
  try {
    const obj = JSON.parse(raw) as Record<string, unknown>
    const status = typeof obj.status === 'string' ? obj.status.toLowerCase() : 'ok'
    return {
      status: status === 'flagged' || status === 'unreadable' ? status : 'ok',
      summary: typeof obj.summary === 'string' ? obj.summary : '',
      transcribedText:
        typeof obj.transcribedText === 'string' ? obj.transcribedText : '',
      aiTags: sanitizeAiTags(obj.aiTags),
    }
  } catch {
    return { status: 'ok', summary: raw.trim(), transcribedText: '', aiTags: [] }
  }
}

/// Validate + clean the model's aiTags list before returning to clients.
/// Normalizes to lowercase kebab-case, dedups, enforces length caps.
function sanitizeAiTags(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  const seen = new Set<string>()
  const out: string[] = []
  for (const raw of value) {
    if (typeof raw !== 'string') continue
    const cleaned = raw
      .trim()
      .toLowerCase()
      .replace(/\s+/g, '-')
      .replace(/[^a-z0-9-]/g, '')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '')
      .slice(0, MAX_TAG_LEN)
    if (cleaned.length === 0 || seen.has(cleaned)) continue
    seen.add(cleaned)
    out.push(cleaned)
    if (out.length >= MAX_TAGS) break
  }
  return out
}
