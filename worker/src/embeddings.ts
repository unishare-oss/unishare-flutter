import type { Env } from './index'

export const EMBEDDING_MODEL = '@cf/baai/bge-base-en-v1.5'
export const EMBEDDING_DIM = 768

/// Single embedding for one input string. Throws if the model returns the
/// wrong shape — callers can catch and degrade gracefully.
export async function embedText(env: Env, input: string): Promise<number[]> {
  const result = (await env.AI.run(EMBEDDING_MODEL, { text: input })) as {
    data: number[][]
  }
  const vec = result.data?.[0]
  if (!Array.isArray(vec) || vec.length !== EMBEDDING_DIM) {
    throw new Error(`embed returned wrong shape: ${vec?.length ?? 'null'}`)
  }
  return vec
}

/// Batch embedding for multiple inputs in one model call. BGE accepts a
/// string[] and returns one vector per input — far cheaper than N round
/// trips. Throws when the result shape doesn't match the input length.
export async function embedTextBatch(
  env: Env,
  inputs: string[],
): Promise<number[][]> {
  if (inputs.length === 0) return []
  const result = (await env.AI.run(EMBEDDING_MODEL, { text: inputs })) as {
    data: number[][]
  }
  const vectors = result.data
  if (!Array.isArray(vectors) || vectors.length !== inputs.length) {
    throw new Error(
      `embed batch returned wrong count: expected ${inputs.length}, got ${vectors?.length ?? 'null'}`,
    )
  }
  for (const v of vectors) {
    if (!Array.isArray(v) || v.length !== EMBEDDING_DIM) {
      throw new Error(`embed batch vector wrong shape: ${v?.length ?? 'null'}`)
    }
  }
  return vectors
}
