import { Buffer } from 'node:buffer'
import Groq from 'groq-sdk'
import { PhotonImage, resize, SamplingFilter } from '@cf-wasm/photon'
import { extractText } from './text-extractor'
import type { Env } from './index'
import { json, jsonError } from './response'

/// Summary prompt used for both text and image inputs. The text path feeds
/// extracted PDF/DOCX content; the vision path feeds a compressed image of a
/// printed, scanned, or handwritten page.
const SUMMARY_PROMPT = `You are summarizing an academic document for university students. The input is either extracted text from a PDF or DOCX, or an image of a printed, scanned, or handwritten page — including lecture notes, textbook excerpts, problem sets, diagrams, and equations.

Respond with EXACTLY this format — no preamble, no markdown headers, no closing line:

One sentence describing what this document is.
• Specific topic or concept
• Specific topic or concept
• Specific topic or concept

Rules:
- Use 3 to 7 bullet points.
- Name actual topics, theorems, formulas, or terms (e.g. "Lagrangian mechanics", "RSA encryption", "Krebs cycle") — avoid generic phrases like "discusses concepts" or "covers material".
- If the page is mostly equations or a worked problem, identify the specific method or theorem applied, not just the subject area.
- If the input is unreadable, blank, or contains no academic content, respond with only: UNREADABLE
- If the input contains harmful or clearly inappropriate content, respond with only: FLAGGED`

const TEXT_MODEL_DEFAULT = 'llama-3.3-70b-versatile'
const VISION_MODEL_DEFAULT = 'meta-llama/llama-4-scout-17b-16e-instruct'
const MAX_IMAGE_DIM = 1600
const JPEG_QUALITY = 80

/// Photon-supported image MIME types. We branch on the R2 response's
/// Content-Type (server-controlled, set when the file was uploaded through
/// our presigned-URL flow) rather than the client-supplied filename — a
/// spoofed filename can't redirect routing into the wrong summarizer.
const PHOTON_SUPPORTED_MIME = /^image\/(jpe?g|png|webp)$/i

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

  const groq = new Groq({ apiKey: env.GROQ_API_KEY })
  const contentType = fileRes.headers.get('content-type')?.toLowerCase() ?? ''
  const isImage = PHOTON_SUPPORTED_MIME.test(contentType)

  let summary: string
  try {
    summary = isImage
      ? await summarizeImage(groq, env, buffer)
      : await summarizeText(groq, env, buffer, filename)
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

  const verdict = summary.trim().toUpperCase()
  if (verdict === 'FLAGGED') {
    return json({ summaryStatus: 'flagged', summary: null })
  }
  if (verdict === 'UNREADABLE') {
    return json({ summaryStatus: 'unsupported_type', summary: null })
  }

  return json({ summaryStatus: 'done', summary })
}

async function summarizeText(
  groq: Groq,
  env: Env,
  buffer: ArrayBuffer,
  filename: string,
): Promise<string> {
  const text = await extractText(buffer, filename)
  if (!text.trim()) throw new Error('empty_text')

  const model = env.GROQ_MODEL ?? TEXT_MODEL_DEFAULT
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
    return response.choices[0]?.message?.content?.trim() ?? ''
  } catch {
    throw new Error('llm_failed')
  }
}

async function summarizeImage(groq: Groq, env: Env, buffer: ArrayBuffer): Promise<string> {
  // Resize + re-encode the upload so Groq stays under its 5 MB image cap and
  // we don't pay to upload a 12 MP camera shot for handwriting summarization.
  // Photon throws on corrupt bytes, non-image content, or unsupported codec
  // variants — we surface those as `unsupported_format` so the API contract
  // stays stable instead of leaking 500s for bad uploads.
  let inputImg: PhotonImage | null = null
  let outputImg: PhotonImage | null = null
  let jpegBytes: Uint8Array
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
  } finally {
    inputImg?.free()
    outputImg?.free()
  }

  const dataUrl = `data:image/jpeg;base64,${Buffer.from(jpegBytes).toString('base64')}`
  const model = env.GROQ_VISION_MODEL ?? VISION_MODEL_DEFAULT

  try {
    const response = await groq.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: SUMMARY_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Summarize this page.' },
            { type: 'image_url', image_url: { url: dataUrl } },
          ],
        },
      ],
      max_tokens: 300,
      temperature: 0,
    })
    return response.choices[0]?.message?.content?.trim() ?? ''
  } catch {
    throw new Error('llm_failed')
  }
}

