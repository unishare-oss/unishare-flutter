import mammoth from 'mammoth'
import { extractText as extractPdfText } from 'unpdf'

const MAX_CHARS = 6000

export async function extractText(buffer: ArrayBuffer, filename: string): Promise<string> {
  const lower = filename.toLowerCase()

  if (lower.endsWith('.pdf')) {
    const { text } = await extractPdfText(new Uint8Array(buffer), { mergePages: true })
    return text.slice(0, MAX_CHARS)
  }

  if (lower.endsWith('.docx')) {
    const result = await mammoth.extractRawText({ buffer: Buffer.from(buffer) })
    return result.value.slice(0, MAX_CHARS)
  }

  throw new Error('unsupported_format')
}
