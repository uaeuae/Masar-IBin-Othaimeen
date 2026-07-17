import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'yaml';
import {
  journeySeedSchema,
  scholarsFileSchema,
  sciencesFileSchema,
  seriesSeedSchema,
  type JourneySeed,
  type Scholar,
  type Science,
  type SeriesSeed,
} from './schemas.js';

export interface SeedBundle {
  scholars: Scholar[];
  sciences: Science[];
  series: SeriesSeed[];
  journeys: JourneySeed[];
}

export class SeedValidationError extends Error {
  constructor(public readonly problems: string[]) {
    super(`Seed validation failed with ${problems.length} problem(s):\n` + problems.map((p) => `  - ${p}`).join('\n'));
    this.name = 'SeedValidationError';
  }
}

function listYamlFiles(dir: string): string[] {
  try {
    return readdirSync(dir)
      .filter((f) => f.endsWith('.yaml') || f.endsWith('.yml'))
      .sort()
      .map((f) => join(dir, f));
  } catch {
    return [];
  }
}

/**
 * Loads and validates the whole seed tree (shape + referential integrity).
 * Throws SeedValidationError listing every problem found — CI shows them all at once.
 */
export function loadSeeds(seedDir: string): SeedBundle {
  const problems: string[] = [];

  let scholars: Scholar[] = [];
  try {
    const raw = parse(readFileSync(join(seedDir, 'scholars.yaml'), 'utf8'));
    const parsed = scholarsFileSchema.safeParse(raw);
    if (parsed.success) {
      scholars = parsed.data.scholars;
    } else {
      problems.push(`scholars.yaml: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
    }
  } catch (e) {
    problems.push(`scholars.yaml: cannot read (${(e as Error).message})`);
  }

  let sciences: Science[] = [];
  try {
    const raw = parse(readFileSync(join(seedDir, 'sciences.yaml'), 'utf8'));
    const parsed = sciencesFileSchema.safeParse(raw);
    if (parsed.success) {
      sciences = parsed.data.sciences;
    } else {
      problems.push(`sciences.yaml: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
    }
  } catch (e) {
    problems.push(`sciences.yaml: cannot read (${(e as Error).message})`);
  }

  const series: SeriesSeed[] = [];
  for (const file of listYamlFiles(join(seedDir, 'series'))) {
    const parsed = seriesSeedSchema.safeParse(parse(readFileSync(file, 'utf8')));
    if (parsed.success) {
      series.push(parsed.data);
    } else {
      problems.push(`${file}: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
    }
  }

  const journeys: JourneySeed[] = [];
  for (const file of listYamlFiles(join(seedDir, 'journeys'))) {
    const parsed = journeySeedSchema.safeParse(parse(readFileSync(file, 'utf8')));
    if (parsed.success) {
      journeys.push(parsed.data);
    } else {
      problems.push(`${file}: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
    }
  }

  // Referential integrity — only meaningful if shapes parsed.
  const scholarSlugs = new Set(scholars.map((s) => s.slug));
  const scienceSlugs = new Set(sciences.map((s) => s.slug));
  const seriesBySlug = new Map(series.map((s) => [s.slug, s]));

  checkUnique(scholars.map((s) => s.slug), 'scholar slug', problems);
  checkUnique(sciences.map((s) => s.slug), 'science slug', problems);
  checkUnique(series.map((s) => s.slug), 'series slug', problems);
  checkUnique(journeys.map((j) => j.slug), 'journey slug', problems);
  checkUnique(
    series.flatMap((s) => s.youtube_playlists),
    'youtube playlist id (a playlist may belong to only one series)',
    problems,
  );

  for (const s of series) {
    if (!scienceSlugs.has(s.science)) {
      problems.push(`series "${s.slug}": unknown science "${s.science}"`);
    }
    if (!scholarSlugs.has(s.scholar)) {
      problems.push(`series "${s.slug}": unknown scholar "${s.scholar}"`);
    }
  }

  for (const j of journeys) {
    if (j.science !== undefined && !scienceSlugs.has(j.science)) {
      problems.push(`journey "${j.slug}": unknown science "${j.science}"`);
    }
    for (const stage of j.stages) {
      for (const item of stage.items) {
        const target = seriesBySlug.get(item.series);
        if (!target) {
          problems.push(`journey "${j.slug}", stage "${stage.title_ar}": unknown series "${item.series}"`);
        } else if (j.is_published && target.status === 'archived') {
          problems.push(`journey "${j.slug}" is published but references archived series "${item.series}"`);
        }
      }
    }
  }

  if (problems.length > 0) {
    throw new SeedValidationError(problems);
  }

  return { scholars, sciences, series, journeys };
}

function checkUnique(values: string[], label: string, problems: string[]): void {
  const seen = new Set<string>();
  for (const v of values) {
    if (seen.has(v)) problems.push(`duplicate ${label}: "${v}"`);
    seen.add(v);
  }
}
