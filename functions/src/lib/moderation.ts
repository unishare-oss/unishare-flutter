import Groq from 'groq-sdk';
import { logger } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';

export const GROQ_API_KEY = defineSecret('GROQ_API_KEY');

const TEXT_MODEL = 'llama-3.3-70b-versatile';

export interface AiVerdict {
  recommended: 'approve' | 'reject';
  confidence: number;
  reason: string;
  error?: string;
}

interface ModerationInput {
  title: string;
  description: string;
  tags: string[];
  postType: string;
}

const buildPrompt = (input: ModerationInput) =>
  `You are a content moderator for an academic file-sharing platform used by university students.

Decide if this post should be APPROVED for the public feed or REJECTED.

Approve when the post is:
- academic in nature (lecture notes, exercises, study material, course-relevant)
- non-offensive (no slurs, sexual content, harassment, illegal material)
- not obvious spam or self-promotion

Reject when the post contains:
- harmful or clearly inappropriate content
- spam, advertising, or content unrelated to academic work
- harassment or attacks against a person or group

POST
title: ${input.title}
description: ${input.description}
tags: ${input.tags.join(', ') || '(none)'}
postType: ${input.postType}

Respond with EXACTLY this JSON shape. No preamble, no markdown fence, no closing remarks:
{ "recommended": "approve" | "reject", "confidence": <number between 0 and 1>, "reason": "<one short sentence>" }`;

export async function classifyPost(
  apiKey: string,
  input: ModerationInput,
): Promise<AiVerdict> {
  let raw: string;
  try {
    const groq = new Groq({ apiKey });
    const completion = await groq.chat.completions.create({
      model: TEXT_MODEL,
      temperature: 0,
      max_tokens: 200,
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: buildPrompt(input) }],
    });
    raw = completion.choices[0]?.message?.content ?? '';
  } catch (e) {
    logger.error('moderation: groq call failed', { error: (e as Error).message });
    return {
      recommended: 'approve',
      confidence: 0,
      reason: 'AI unavailable — defer to human moderator',
      error: (e as Error).message,
    };
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    logger.warn('moderation: non-JSON model output', { raw });
    return {
      recommended: 'approve',
      confidence: 0,
      reason: 'AI returned unparseable output',
      error: 'parse_failed',
    };
  }

  const obj = parsed as Record<string, unknown>;
  const recommended = obj.recommended === 'reject' ? 'reject' : 'approve';
  const rawConf = typeof obj.confidence === 'number' ? obj.confidence : 0;
  const confidence = Math.max(0, Math.min(1, rawConf));
  const reason =
    typeof obj.reason === 'string' && obj.reason.length > 0
      ? obj.reason.slice(0, 240)
      : 'No reason provided';

  return { recommended, confidence, reason };
}
