import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { gzipSync } from 'node:zlib';
import { loadSeeds } from '../seeds.js';
import { readStoredLessons } from '../store.js';

export interface PublishOptions {
  seedDir: string;
  dataDir: string;
  outDir: string;
  /** When set, also writes the pretty catalog.json as the app's bundled asset. */
  appAssetPath?: string;
  dryRun: boolean;
  now?: () => Date;
  log?: (line: string) => void;
}

export class PublishIntegrityError extends Error {
  constructor(public readonly problems: string[]) {
    super(
      `Catalog failed integrity checks with ${problems.length} problem(s):\n` +
        problems.map((p) => `  - ${p}`).join('\n'),
    );
    this.name = 'PublishIntegrityError';
  }
}

/**
 * Compiles seeds + synced lesson data into the versioned catalog snapshot
 * the app consumes. Only active series and published journeys are exported.
 */
export function publishCatalog(options: PublishOptions): { version: number; lessonCount: number } {
  const log = options.log ?? console.log;
  const bundle = loadSeeds(options.seedDir);
  const problems: string[] = [];

  const activeSeries = bundle.series.filter((s) => s.status === 'active');
  const lessonsBySeries = new Map(
    activeSeries.map((s) => [s.slug, readStoredLessons(options.dataDir, s.slug)]),
  );

  for (const [slug, lessons] of lessonsBySeries) {
    if (lessons.filter((l) => l.status === 'active').length === 0) {
      problems.push(`active series "${slug}" has no active lessons (run sync:youtube?)`);
    }
  }

  const publishedJourneys = bundle.journeys.filter((j) => j.is_published);
  for (const journey of publishedJourneys) {
    for (const stage of journey.stages) {
      for (const item of stage.items) {
        const series = bundle.series.find((s) => s.slug === item.series);
        if (!series || series.status !== 'active') {
          problems.push(
            `published journey "${journey.slug}" references non-active series "${item.series}"`,
          );
        }
      }
    }
  }

  if (problems.length > 0) throw new PublishIntegrityError(problems);

  const metaPath = join(options.outDir, 'meta.json');
  const previousVersion = existsSync(metaPath)
    ? (JSON.parse(readFileSync(metaPath, 'utf8')) as { version?: number }).version ?? 0
    : 0;
  const version = previousVersion + 1;
  const generatedAt = (options.now ? options.now() : new Date()).toISOString();

  const catalog = {
    version,
    generated_at: generatedAt,
    sciences: bundle.sciences.map((s) => ({
      slug: s.slug,
      name_ar: s.name_ar,
      description_ar: s.description_ar ?? null,
      icon: s.icon ?? null,
      sort_order: s.sort_order,
    })),
    series: activeSeries.map((s) => ({
      slug: s.slug,
      science: s.science,
      title_ar: s.title_ar,
      description_ar: s.description_ar ?? null,
      thumbnail_url: s.thumbnail_url ?? null,
      lessons: (lessonsBySeries.get(s.slug) ?? [])
        .filter((l) => l.status !== 'hidden')
        .map((l) => ({
          youtube_video_id: l.youtube_video_id,
          position: l.position,
          title_ar: l.title_ar,
          duration_seconds: l.duration_seconds,
          published_at: l.published_at,
          status: l.status,
        })),
    })),
    journeys: publishedJourneys.map((j) => ({
      slug: j.slug,
      title_ar: j.title_ar,
      description_ar: j.description_ar ?? null,
      level: j.level,
      science: j.science ?? null,
      cover_url: j.cover_url ?? null,
      sort_order: j.sort_order,
      stages: j.stages.map((stage) => ({
        title_ar: stage.title_ar,
        description_ar: stage.description_ar ?? null,
        items: stage.items.map((item) => ({ type: 'series', series: item.series })),
      })),
    })),
  };

  const pretty = JSON.stringify(catalog, null, 2) + '\n';
  const gz = gzipSync(Buffer.from(pretty));
  const sha256 = createHash('sha256').update(gz).digest('hex');
  const lessonCount = catalog.series.reduce((sum, s) => sum + s.lessons.length, 0);

  log(
    `catalog v${version}: ${catalog.sciences.length} sciences, ${catalog.series.length} series, ` +
      `${lessonCount} lessons, ${catalog.journeys.length} journeys ` +
      `(${(gz.length / 1024).toFixed(1)} KiB gzipped)${options.dryRun ? ' [dry-run]' : ''}`,
  );

  if (!options.dryRun) {
    mkdirSync(options.outDir, { recursive: true });
    writeFileSync(join(options.outDir, `catalog-v${version}.json.gz`), gz);
    writeFileSync(join(options.outDir, 'catalog.json'), pretty);
    writeFileSync(
      metaPath,
      JSON.stringify(
        { version, generated_at: generatedAt, file: `catalog-v${version}.json.gz`, sha256 },
        null,
        2,
      ) + '\n',
    );
    if (options.appAssetPath) {
      writeFileSync(options.appAssetPath, pretty);
      log(`bundled asset updated: ${options.appAssetPath}`);
    }
  }

  return { version, lessonCount };
}
