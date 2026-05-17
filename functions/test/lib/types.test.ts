import { describe, expect, it } from 'vitest';

import { truncate } from '../../src/lib/types';

describe('truncate', () => {
  it('returns the input unchanged when under the limit', () => {
    expect(truncate('hello', 100)).toBe('hello');
  });

  it('returns the input unchanged when at exactly the limit', () => {
    const s = 'a'.repeat(100);
    expect(truncate(s, 100)).toBe(s);
  });

  it('appends an ellipsis when exceeding the limit', () => {
    const s = 'a'.repeat(150);
    const out = truncate(s, 100);
    expect(out.length).toBe(100);
    expect(out.endsWith('…')).toBe(true);
  });

  it('defaults to 100 chars when no limit is given', () => {
    const s = 'a'.repeat(120);
    expect(truncate(s)).toHaveLength(100);
  });
});
