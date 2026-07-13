import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { loadSeeds, SeedValidationError } from '../src/seeds.js';

const repoSeedDir = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', 'seed');

const validSciences = `
sciences:
  - slug: fiqh
    name_ar: الفقه
    sort_order: 1
`;

const validSeries = `
slug: sharh-zad
title_ar: شرح زاد المستقنع
science: fiqh
youtube_playlists: [PLtest123]
`;

const validJourney = `
slug: masar-fiqh
title_ar: مسار الفقه
level: beginner
science: fiqh
stages:
  - title_ar: المرحلة الأولى
    items:
      - series: sharh-zad
`;

function makeSeedTree(files: { sciences?: string; series?: Record<string, string>; journeys?: Record<string, string> }): string {
  const dir = mkdtempSync(join(tmpdir(), 'masar-seeds-'));
  mkdirSync(join(dir, 'series'), { recursive: true });
  mkdirSync(join(dir, 'journeys'), { recursive: true });
  writeFileSync(join(dir, 'sciences.yaml'), files.sciences ?? validSciences);
  for (const [name, content] of Object.entries(files.series ?? { 'sharh-zad.yaml': validSeries })) {
    writeFileSync(join(dir, 'series', name), content);
  }
  for (const [name, content] of Object.entries(files.journeys ?? { 'masar-fiqh.yaml': validJourney })) {
    writeFileSync(join(dir, 'journeys', name), content);
  }
  return dir;
}

describe('loadSeeds', () => {
  it('accepts a minimal valid seed tree', () => {
    const bundle = loadSeeds(makeSeedTree({}));
    expect(bundle.sciences).toHaveLength(1);
    expect(bundle.series[0]?.slug).toBe('sharh-zad');
    expect(bundle.journeys[0]?.stages[0]?.items[0]?.series).toBe('sharh-zad');
  });

  it('accepts the actual repository seeds', () => {
    expect(() => loadSeeds(repoSeedDir)).not.toThrow();
  });

  it('rejects a series referencing an unknown science', () => {
    const dir = makeSeedTree({
      series: { 'bad.yaml': validSeries.replace('science: fiqh', 'science: chemistry') },
      journeys: {},
    });
    expect(() => loadSeeds(dir)).toThrow(SeedValidationError);
    expect(() => loadSeeds(dir)).toThrow(/unknown science "chemistry"/);
  });

  it('rejects a journey item referencing an unknown series', () => {
    const dir = makeSeedTree({
      journeys: { 'bad.yaml': validJourney.replace('series: sharh-zad', 'series: nonexistent') },
    });
    expect(() => loadSeeds(dir)).toThrow(/unknown series "nonexistent"/);
  });

  it('rejects duplicate series slugs across files', () => {
    const dir = makeSeedTree({
      series: { 'a.yaml': validSeries, 'b.yaml': validSeries.replace('PLtest123', 'PLother456') },
    });
    expect(() => loadSeeds(dir)).toThrow(/duplicate series slug/);
  });

  it('rejects the same playlist claimed by two series', () => {
    const dir = makeSeedTree({
      series: {
        'a.yaml': validSeries,
        'b.yaml': validSeries.replace('slug: sharh-zad', 'slug: sharh-other'),
      },
    });
    expect(() => loadSeeds(dir)).toThrow(/duplicate youtube playlist/);
  });

  it('rejects an invalid title_cleanup regex', () => {
    const dir = makeSeedTree({
      series: {
        'bad.yaml': validSeries + '\noverrides:\n  title_cleanup: "[unclosed"\n',
      },
      journeys: {},
    });
    expect(() => loadSeeds(dir)).toThrow(/valid regular expression/);
  });

  it('rejects a published journey referencing an archived series', () => {
    const dir = makeSeedTree({
      series: { 'a.yaml': validSeries + '\nstatus: archived\n' },
      journeys: { 'j.yaml': validJourney + '\nis_published: true\n' },
    });
    expect(() => loadSeeds(dir)).toThrow(/archived series/);
  });

  it('rejects invalid slugs', () => {
    const dir = makeSeedTree({
      series: { 'bad.yaml': validSeries.replace('slug: sharh-zad', 'slug: Sharh_Zad') },
      journeys: {},
    });
    expect(() => loadSeeds(dir)).toThrow(SeedValidationError);
  });
});
