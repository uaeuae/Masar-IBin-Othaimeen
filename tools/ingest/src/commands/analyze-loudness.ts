import { spawn } from 'node:child_process';
import { loadSeeds } from '../seeds.js';
import { readStoredLessons, writeStoredLessons, type StoredLesson } from '../store.js';

export interface AnalyzeLoudnessOptions {
  seedDir: string;
  dataDir: string;
  /** Re-measure lessons that already carry a reading. */
  force: boolean;
  /** Stop after this many measurements (handy for a trial run). */
  limit?: number;
  concurrency: number;
  dryRun: boolean;
  log?: (line: string) => void;
}

/**
 * Measures each audio lesson's integrated loudness (EBU R128) so the player
 * can even the library out.
 *
 * The foundation's uploads span decades of recording gear and their levels
 * wander by more than 8 dB *within a single series* (رياض الصالحين: −19.2 LUFS
 * at lesson 1, −11.0 at lesson 95), which is what makes some lessons feel
 * inaudible after the last one. Per-series correction can't fix that; this is
 * per lesson.
 *
 * Sampled rather than scanned end to end: three 60s windows land within ~0.3 dB
 * of a full pass on speech (verified −16.4 vs −16.7) for a twentieth of the
 * bandwidth, which matters when the alternative is pulling ~10 GB through the
 * foundation's servers.
 */
export function analyzeLoudness(options: AnalyzeLoudnessOptions): Promise<{
  measured: number;
  skipped: number;
  failed: number;
}> {
  const log = options.log ?? console.log;
  const bundle = loadSeeds(options.seedDir);
  const activeSeries = bundle.series.filter((s) => s.status === 'active' && s.media === 'audio');

  return (async () => {
    let measured = 0;
    let skipped = 0;
    let failed = 0;

    for (const series of activeSeries) {
      const lessons = readStoredLessons(options.dataDir, series.slug);
      const pending = lessons.filter(
        (l) =>
          l.status === 'active' &&
          l.audio_url &&
          (options.force || l.loudness_lufs == null),
      );
      skipped += lessons.filter((l) => l.status === 'active' && l.audio_url).length - pending.length;
      if (pending.length === 0) continue;

      log(`${series.slug}: measuring ${pending.length} lesson(s)…`);
      let dirty = 0;

      // A small worker pool: the wall clock here is dominated by connection
      // setup on the foundation's server, not by decoding.
      const queue = [...pending];
      const workers = Array.from(
        { length: Math.max(1, Math.min(options.concurrency, queue.length)) },
        async () => {
          for (;;) {
            if (options.limit != null && measured >= options.limit) return;
            const lesson = queue.shift();
            if (!lesson) return;

            const lufs = await measureLesson(lesson);
            if (lufs == null) {
              failed++;
              log(`  ! ${series.slug} #${lesson.position}: no reading`);
              continue;
            }
            lesson.loudness_lufs = Math.round(lufs * 10) / 10;
            measured++;
            dirty++;
            if (!options.dryRun && dirty >= 10) {
              writeStoredLessons(options.dataDir, series.slug, lessons);
              dirty = 0;
            }
          }
        },
      );
      await Promise.all(workers);

      if (!options.dryRun && dirty > 0) {
        writeStoredLessons(options.dataDir, series.slug, lessons);
      }
      if (options.limit != null && measured >= options.limit) break;
    }

    log(
      `loudness: ${measured} measured, ${skipped} already known, ${failed} failed` +
        `${options.dryRun ? ' [dry-run]' : ''}`,
    );
    return { measured, skipped, failed };
  })();
}

/** Energy-averages three windows into one integrated reading. */
async function measureLesson(lesson: StoredLesson): Promise<number | null> {
  const url = lesson.audio_url;
  if (!url) return null;
  const duration = lesson.duration_seconds ?? 0;

  // Skip the opening basmala/recitation and the closing du'a, which sit well
  // off the lecture's speaking level.
  const offsets =
    duration > 600
      ? [0.25, 0.5, 0.75].map((f) => Math.round(duration * f))
      : [Math.max(0, Math.round(duration * 0.4))];

  const readings: number[] = [];
  for (const offset of offsets) {
    const reading = await runEbur128(url, offset, 60);
    if (reading != null && Number.isFinite(reading)) readings.push(reading);
  }
  if (readings.length === 0) return null;

  const energy =
    readings.reduce((sum, lufs) => sum + Math.pow(10, lufs / 10), 0) / readings.length;
  return 10 * Math.log10(energy);
}

function runEbur128(url: string, startSeconds: number, seconds: number): Promise<number | null> {
  return new Promise((resolve) => {
    const child = spawn(
      'ffmpeg',
      [
        '-nostdin',
        '-ss', String(startSeconds),
        '-t', String(seconds),
        '-i', url,
        '-filter:a', 'ebur128=framelog=quiet',
        '-f', 'null', '-',
      ],
      { stdio: ['ignore', 'ignore', 'pipe'] },
    );

    let stderr = '';
    child.stderr.on('data', (chunk) => {
      stderr += chunk;
    });
    // A stalled request must not wedge the whole run.
    const timer = setTimeout(() => child.kill('SIGKILL'), 120_000);
    child.on('error', () => {
      clearTimeout(timer);
      resolve(null);
    });
    child.on('close', () => {
      clearTimeout(timer);
      // The summary block prints "I:  -16.4 LUFS" after "Integrated loudness".
      const match = /Integrated loudness[\s\S]*?I:\s*(-?[\d.]+)\s*LUFS/.exec(stderr);
      const value = match ? Number.parseFloat(match[1]!) : Number.NaN;
      resolve(Number.isFinite(value) ? value : null);
    });
  });
}
