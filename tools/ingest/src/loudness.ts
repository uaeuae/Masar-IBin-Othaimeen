/**
 * Turns measured loudness into the playback correction the app applies.
 *
 * The foundation's uploads span decades of recording gear, and their levels
 * wander by more than 8 dB *within* a single series — رياض الصالحين runs from
 * −19.2 LUFS at lesson 1 to −11.0 at lesson 95. That mismatch, not the absolute
 * level, is what makes a lesson feel inaudible after the one before it.
 */

/**
 * What every lesson is aimed at. Roughly the library's middle on purpose:
 * pulling the loud ones down to it removes most of the jump, while a lower
 * target would just make the whole library quieter — iOS caps playback gain at
 * 1.0×, so a correction below the target can never be undone at playback time.
 */
export const TARGET_LUFS = -16;

/** Past these, the correction would do more harm than the mismatch did. */
const MAX_ATTENUATION_DB = 12;
const MAX_BOOST_DB = 8;

/**
 * dB correction toward [TARGET_LUFS], or null when the lesson was never
 * measured. Negative pulls a loud lesson down (works on every platform);
 * positive marks a quiet one, which only Android's loudness enhancer can
 * genuinely lift.
 */
export function gainForLoudness(lufs: number | null | undefined): number | null {
  if (lufs == null || !Number.isFinite(lufs)) return null;
  const clamped = Math.max(-MAX_ATTENUATION_DB, Math.min(MAX_BOOST_DB, TARGET_LUFS - lufs));
  return Math.round(clamped * 10) / 10;
}
