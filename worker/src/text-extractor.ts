import mammoth from 'mammoth'
import * as pdfjsLib from 'pdfjs-dist'

const MAX_CHARS = 6000

export async function extractText(buffer: ArrayBuffer, filename: string): Promise<string> {
  const lower = filename.toLowerCase()

  if (lower.endsWith('.pdf')) {
    const pdf = await pdfjsLib.getDocument({ data: new Uint8Array(buffer) }).promise
    const pages = await Promise.all(
      Array.from({ length: pdf.numPages }, (_, i) =>
        pdf.getPage(i + 1).then(async (page) => {
          const content = await page.getTextContent()
          return content.items.map((item) => ('str' in item ? item.str : '')).join(' ')
        }),
      ),
    )
    return pages.join('\n').slice(0, MAX_CHARS)
  }

  if (lower.endsWith('.docx')) {
    const result = await mammoth.extractRawText({ buffer: Buffer.from(buffer) })
    return result.value.slice(0, MAX_CHARS)
  }

  throw new Error('unsupported_format')
}
