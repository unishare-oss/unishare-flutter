/// Target chunk size in characters. BGE-base-en-v1.5 truncates inputs at
/// ~2000 chars (512 tokens), so 800 stays well clear of the truncation line
/// while still giving each chunk 1-2 paragraphs of coherent context.
export const CHUNK_SIZE = 800

/// Overlap between consecutive chunks. 100 / 800 = 12.5% — enough to
/// preserve sentences that straddle a chunk boundary.
export const CHUNK_OVERLAP = 100

/// Max distance to walk back from the target boundary in search of
/// whitespace. Prevents distorting chunk sizes when the doc has long
/// whitespace-sparse runs (e.g. equations, code).
export const BOUNDARY_BACKTRACK = 60

/// Min text length below which we don't chunk at all. Aligned with the
/// chat handler's CONTEXT_CHAR_CAP so docs that fit whole in the chat
/// context don't pay for chunking infrastructure.
export const CHUNK_THRESHOLD = 30_000

/// Splits text into ~CHUNK_SIZE windows with CHUNK_OVERLAP characters
/// of overlap. Walks each boundary back up to BOUNDARY_BACKTRACK chars
/// to land on a whitespace character when one is nearby.
/// Pure function: same input → same output.
export function chunkText(text: string): string[] {
  const trimmed = text.trim()
  if (trimmed.length === 0) return []
  if (trimmed.length <= CHUNK_SIZE) return [trimmed]

  const chunks: string[] = []
  let start = 0

  while (start < trimmed.length) {
    const targetEnd = Math.min(start + CHUNK_SIZE, trimmed.length)
    let end = targetEnd

    // If we're not at the document end, prefer whitespace within ±backtrack.
    if (end < trimmed.length) {
      const backtrackLimit = Math.max(start + 1, end - BOUNDARY_BACKTRACK)
      for (let i = end; i > backtrackLimit; i--) {
        if (/\s/.test(trimmed[i - 1])) {
          end = i
          break
        }
      }
    }

    const chunk = trimmed.slice(start, end).trim()
    if (chunk.length > 0) chunks.push(chunk)

    if (end >= trimmed.length) break

    const nextStart = end - CHUNK_OVERLAP
    // Defensive: if overlap would push us backward (chunk too small),
    // advance by at least 1 to guarantee termination.
    start = nextStart > start ? nextStart : start + 1
  }

  return chunks
}
