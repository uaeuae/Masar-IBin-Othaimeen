import { existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { gzipSync } from 'node:zlib';
import { loadSeeds } from '../seeds.js';
import { readStoredLessons } from '../store.js';
import { buildLessonText } from '../text-align.js';

export interface BuildTextsOptions {
  seedDir: string;
  dataDir: string;
  /** Asset directory, one gzipped file per lesson (app/assets/texts). */
  outDir: string;
  dryRun: boolean;
  log?: (line: string) => void;
}

/**
 * Compiles the read-along scripts the player renders. Kept out of the catalog
 * on purpose: ~10 MB of prose has no business in a snapshot the app imports
 * into drift on every version bump, and the player only needs one lesson at a
 * time. One file per lesson keeps that read to a few KB.
 */
export function buildLessonTexts(options: BuildTextsOptions): {
  files: number;
  bytes: number;
  transcript: number;
  matn: number;
} {
  const log = options.log ?? console.log;
  const bundle = loadSeeds(options.seedDir);
  const activeSeries = bundle.series.filter((s) => s.status === 'active');

  const written: { name: string; gz: Buffer }[] = [];
  let transcript = 0;
  let matn = 0;

  for (const series of activeSeries) {
    // Mirrors the gate in publish-catalog, so a lesson never claims a
    // text_kind the assets don't back.
    if (!series.read_along) continue;
    for (const lesson of readStoredLessons(options.dataDir, series.slug)) {
      // Same rule as publish-catalog, so every lesson the catalog flags with a
      // text_kind has an asset behind it — including `unavailable` ones, whose
      // audio is a dead upload but whose text is still worth reading.
      if (lesson.status === 'hidden') continue;
      const text = buildLessonText(lesson);
      if (!text) continue;
      if (text.kind === 'transcript') transcript++;
      else matn++;
      written.push({
        name: `${lesson.youtube_video_id}.json.gz`,
        gz: gzipSync(Buffer.from(JSON.stringify(text))),
      });
    }
  }

  const bytes = written.reduce((sum, f) => sum + f.gz.length, 0);
  log(
    `lesson texts: ${written.length} files (${transcript} transcript, ${matn} matn), ` +
      `${(bytes / 1048576).toFixed(1)} MiB gzipped${options.dryRun ? ' [dry-run]' : ''}`,
  );

  if (!options.dryRun) {
    mkdirSync(options.outDir, { recursive: true });
    // Drop stale scripts so a renamed or dropped lesson can't leave a file the
    // app would happily keep serving.
    if (existsSync(options.outDir)) {
      for (const name of readdirSync(options.outDir)) {
        if (name.endsWith('.json.gz')) rmSync(join(options.outDir, name));
      }
    }
    for (const file of written) writeFileSync(join(options.outDir, file.name), file.gz);
    log(`assets written: ${options.outDir}`);
  }

  return { files: written.length, bytes, transcript, matn };
}
