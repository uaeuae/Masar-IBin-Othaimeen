import { describe, expect, it } from 'vitest';
import { gainForLoudness, TARGET_LUFS } from '../src/loudness.js';

describe('gainForLoudness', () => {
  it('pulls a loud lesson down and marks a quiet one for boost', () => {
    // رياض #95, the loudest sampled lesson.
    expect(gainForLoudness(-11.0)).toBe(-5);
    // الصلاة #26, the quietest.
    expect(gainForLoudness(-21.7)).toBe(5.7);
    expect(gainForLoudness(TARGET_LUFS)).toBe(0);
  });

  it('never over-corrects a broken measurement', () => {
    expect(gainForLoudness(-60)).toBe(8);
    expect(gainForLoudness(0)).toBe(-12);
  });

  it('leaves unmeasured lessons alone', () => {
    expect(gainForLoudness(null)).toBeNull();
    expect(gainForLoudness(undefined)).toBeNull();
    expect(gainForLoudness(Number.NaN)).toBeNull();
    expect(gainForLoudness(-Infinity)).toBeNull();
  });

  it('brings the sampled spread within a couple of dB', () => {
    // The real problem: 8.2 dB of drift inside رياض الصالحين alone.
    const measured = [-19.2, -13.4, -14.2, -11.5, -11.0];
    const corrected = measured.map((lufs) => lufs + gainForLoudness(lufs)!);
    const spread = Math.max(...corrected) - Math.min(...corrected);
    expect(Math.max(...measured) - Math.min(...measured)).toBeCloseTo(8.2, 1);
    // Everything at or above the target lands on it; only the quiet tail
    // (which iOS cannot lift) stays low.
    expect(spread).toBeLessThanOrEqual(3.2);
  });
});
