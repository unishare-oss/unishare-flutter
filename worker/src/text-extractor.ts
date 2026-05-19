import { Buffer } from 'node:buffer'
import mammoth from 'mammoth'
import { extractText as extractPdfText } from 'unpdf'

/// Storage cap for cached extracted text on the post doc. Sized so the full
/// post doc plus all other fields stays well under Firestore's 1 MB limit
/// (~80 KB UTF-8 in the worst case). The summarizer still only sends a smaller
/// prefix to the LLM to keep token usage bounded; this cap is just how much
/// we persist for downstream features (search, full-RAG chat, practice qs).
const MAX_CHARS = 60000

export interface ExtractedText {
  text: string
  /** True when the source was longer than MAX_CHARS and the returned text was clipped. */
  truncated: boolean
}

export async function extractText(buffer: ArrayBuffer, filename: string): Promise<ExtractedText> {
  const lower = filename.toLowerCase()

  if (lower.endsWith('.pdf')) {
    const { text } = await extractPdfText(new Uint8Array(buffer), { mergePages: true })
    return clip(text)
  }

  if (lower.endsWith('.docx')) {
    const result = await mammoth.extractRawText({ buffer: Buffer.from(buffer) })
    return clip(result.value)
  }

  throw new Error('unsupported_format')
}

function clip(raw: string): ExtractedText {
  if (raw.length <= MAX_CHARS) return { text: raw, truncated: false }
  return { text: raw.slice(0, MAX_CHARS), truncated: true }
}
