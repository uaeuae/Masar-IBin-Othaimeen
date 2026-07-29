import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { gzipSync } from 'node:zlib';
import { loadSeeds } from '../seeds.js';
import { readStoredLessons } from '../store.js';
import { classifyLesson } from '../text-align.js';
import { gainForLoudness } from '../loudness.js';

export interface PublishOptions {
  seedDir: string;
  dataDir: string;
  outDir: string;
  /** When set, also writes the pretty catalog.json as the app's bundled asset. */
  appAssetPath?: string;
  /**
   * Ships the audio library only: video series are left out entirely, journey
   * stages fall through to each video series' audio companion, and the
   * companions are promoted to browsable (companion_of cleared, «(صوتي)»
   * stripped from their titles). Seeds are untouched — re-enabling video is
   * just a publish without this flag.
   */
  audioOnly?: boolean;
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
    const seed = activeSeries.find((s) => s.slug === slug);
    if (seed?.media === 'audio') {
      for (const lesson of lessons) {
        if (lesson.status === 'active' && !lesson.audio_url) {
          problems.push(`audio series "${slug}" lesson ${lesson.position} has no audio_url`);
        }
      }
    }
  }

  const companionByVideoSlug = new Map<string, string>();
  for (const s of activeSeries) {
    if (!s.companion_of) continue;
    if (s.media !== 'audio') {
      problems.push(`series "${s.slug}" sets companion_of but is not media: audio`);
      continue;
    }
    const target = activeSeries.find((v) => v.slug === s.companion_of);
    if (!target || target.media !== 'video') {
      problems.push(
        `series "${s.slug}" companion_of "${s.companion_of}" is not an active video series`,
      );
      continue;
    }
    if (companionByVideoSlug.has(s.companion_of)) {
      problems.push(`video series "${s.companion_of}" has more than one audio companion`);
      continue;
    }
    companionByVideoSlug.set(s.companion_of, s.slug);
  }

  const audioOnly = options.audioOnly ?? false;
  const exportedSeries = audioOnly ? activeSeries.filter((s) => s.media === 'audio') : activeSeries;
  const exportedSlugs = new Set(exportedSeries.map((s) => s.slug));
  /** Audio-only: a journey step on a video series plays its audio edition instead. */
  const resolveSeriesSlug = (slug: string) =>
    audioOnly ? companionByVideoSlug.get(slug) ?? slug : slug;

  const publishedJourneys = bundle.journeys.filter((j) => j.is_published);
  for (const journey of publishedJourneys) {
    for (const stage of journey.stages) {
      for (const item of stage.items) {
        const series = bundle.series.find((s) => s.slug === item.series);
        if (!series || series.status !== 'active') {
          problems.push(
            `published journey "${journey.slug}" references non-active series "${item.series}"`,
          );
          continue;
        }
        // Fail loudly rather than silently emptying a stage: a video series
        // with no audio companion has nothing to fall through to.
        if (!exportedSlugs.has(resolveSeriesSlug(item.series))) {
          problems.push(
            `audio-only publish: journey "${journey.slug}" references video series ` +
              `"${item.series}", which has no audio companion`,
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
    scholars: bundle.scholars.map((s) => ({
      slug: s.slug,
      name_ar: s.name_ar,
      foundation_ar: s.foundation_ar,
      website: s.website ?? null,
      sort_order: s.sort_order,
    })),
    sciences: bundle.sciences.map((s) => ({
      slug: s.slug,
      name_ar: s.name_ar,
      description_ar: s.description_ar ?? null,
      icon: s.icon ?? null,
      sort_order: s.sort_order,
    })),
    series: exportedSeries.map((s) => ({
      slug: s.slug,
      science: s.science,
      scholar: s.scholar,
      // Audio-only: the companions are the only edition left, so the
      // «(صوتي)» disambiguator is noise — the series header already reads
      // «صوتيات المؤسسة».
      title_ar: audioOnly ? s.title_ar.replace(/\s*\(صوتي\)\s*$/u, '') : s.title_ar,
      description_ar: s.description_ar ?? null,
      thumbnail_url: s.thumbnail_url ?? null,
      level: s.level ?? null,
      media: s.media,
      // Audio-only: clearing both promotes the companions to browsable
      // (the app hides `companion_of IS NOT NULL`) and hides the
      // cross-edition banners, which have nowhere to link.
      companion_of: audioOnly ? null : s.companion_of ?? null,
      companion_slug: audioOnly ? null : companionByVideoSlug.get(s.slug) ?? null,
      lessons: (lessonsBySeries.get(s.slug) ?? [])
        .filter((l) => l.status !== 'hidden')
        .map((l) => ({
          youtube_video_id: l.youtube_video_id,
          position: l.position,
          title_ar: l.title_ar,
          duration_seconds: l.duration_seconds,
          published_at: l.published_at,
          status: l.status,
          ...(l.media === 'audio'
            ? {
                media: 'audio',
                audio_url: l.audio_url ?? null,
                // Which read-along script `build-texts` emitted, so the player
                // knows whether to offer «النص» without probing for the asset.
                // Same classifier both sides — they can't disagree.
                text_kind: classifyLesson(l),
                // Playback correction from `analyze:loudness`; null until the
                // lesson has been measured.
                gain_db: gainForLoudness(l.loudness_lufs),
                // Chapter bodies (full matn passages) stay in the data files;
                // the app only renders titles + timestamps, and bodies are
                // ~10 MB across the library.
                chapters: (l.chapters ?? []).map((c) => ({
                  start_seconds: c.start_seconds,
                  title: c.title,
                })),
              }
            : {}),
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
        items: stage.items.map((item) => ({
          type: 'series',
          series: resolveSeriesSlug(item.series),
        })),
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
      `(${(gz.length / 1024).toFixed(1)} KiB gzipped)` +
      `${audioOnly ? ' [audio-only]' : ''}${options.dryRun ? ' [dry-run]' : ''}`,
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
