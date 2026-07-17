import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { gunzipSync } from 'node:zlib';
import { describe, expect, it } from 'vitest';
import { publishCatalog, PublishIntegrityError } from '../src/commands/publish-catalog.js';
import type { StoredLesson } from '../src/store.js';

function makeWorkspace(options: { publish?: boolean; seriesStatus?: string; withLessons?: boolean }) {
  const root = mkdtempSync(join(tmpdir(), 'masar-publish-'));
  const seedDir = join(root, 'seed');
  const dataDir = join(root, 'data');
  const outDir = join(root, 'dist');
  mkdirSync(join(seedDir, 'series'), { recursive: true });
  mkdirSync(join(seedDir, 'journeys'), { recursive: true });
  mkdirSync(join(dataDir, 'series'), { recursive: true });

  writeFileSync(
    join(seedDir, 'scholars.yaml'),
    'scholars:\n  - slug: ibn-uthaymeen\n    name_ar: الشيخ محمد بن صالح العثيمين\n    foundation_ar: مؤسسة الشيخ العثيمين الخيرية\n',
  );
  writeFileSync(join(seedDir, 'sciences.yaml'), 'sciences:\n  - slug: fiqh\n    name_ar: الفقه\n    sort_order: 1\n');
  writeFileSync(
    join(seedDir, 'series', 'sharh-zad.yaml'),
    `slug: sharh-zad\ntitle_ar: شرح زاد المستقنع\nscience: fiqh\nstatus: ${options.seriesStatus ?? 'active'}\nyoutube_playlists: [PLx]\n`,
  );
  writeFileSync(
    join(seedDir, 'journeys', 'masar-fiqh.yaml'),
    `slug: masar-fiqh\ntitle_ar: مسار الفقه\nlevel: beginner\nscience: fiqh\nis_published: ${options.publish ?? true}\nstages:\n  - title_ar: المرحلة الأولى\n    items:\n      - series: sharh-zad\n`,
  );

  if (options.withLessons !== false) {
    const lessons: StoredLesson[] = [
      {
        youtube_video_id: 'v1',
        position: 1,
        title_ar: 'الدرس الأول',
        duration_seconds: 2700,
        published_at: '2020-01-01T00:00:00Z',
        thumbnail_url: null,
        status: 'active',
      },
      {
        youtube_video_id: 'v2',
        position: 2,
        title_ar: 'درس مخفي',
        duration_seconds: 100,
        published_at: null,
        thumbnail_url: null,
        status: 'hidden',
      },
    ];
    writeFileSync(join(dataDir, 'series', 'sharh-zad.json'), JSON.stringify(lessons));
  }

  return { seedDir, dataDir, outDir };
}

const fixedNow = () => new Date('2026-07-14T00:00:00Z');

describe('publishCatalog', () => {
  it('produces a versioned catalog, gzip, and meta; hidden lessons excluded', () => {
    const ws = makeWorkspace({});
    const result = publishCatalog({ ...ws, dryRun: false, now: fixedNow });

    expect(result.version).toBe(1);
    const catalog = JSON.parse(readFileSync(join(ws.outDir, 'catalog.json'), 'utf8'));
    expect(catalog.version).toBe(1);
    expect(catalog.series[0].lessons).toHaveLength(1); // hidden excluded
    expect(catalog.journeys).toHaveLength(1);
    expect(catalog.journeys[0].stages[0].items[0]).toEqual({ type: 'series', series: 'sharh-zad' });

    const gz = readFileSync(join(ws.outDir, 'catalog-v1.json.gz'));
    expect(JSON.parse(gunzipSync(gz).toString())).toEqual(catalog);

    const meta = JSON.parse(readFileSync(join(ws.outDir, 'meta.json'), 'utf8'));
    expect(meta).toMatchObject({ version: 1, file: 'catalog-v1.json.gz' });
    expect(meta.sha256).toMatch(/^[0-9a-f]{64}$/);
  });

  it('bumps the version on re-publish', () => {
    const ws = makeWorkspace({});
    publishCatalog({ ...ws, dryRun: false, now: fixedNow });
    const second = publishCatalog({ ...ws, dryRun: false, now: fixedNow });
    expect(second.version).toBe(2);
    expect(existsSync(join(ws.outDir, 'catalog-v2.json.gz'))).toBe(true);
  });

  it('dry-run writes nothing', () => {
    const ws = makeWorkspace({});
    publishCatalog({ ...ws, dryRun: true, now: fixedNow });
    expect(existsSync(join(ws.outDir, 'meta.json'))).toBe(false);
  });

  it('rejects an active series with no synced lessons', () => {
    const ws = makeWorkspace({ withLessons: false });
    expect(() => publishCatalog({ ...ws, dryRun: true, now: fixedNow })).toThrow(PublishIntegrityError);
    expect(() => publishCatalog({ ...ws, dryRun: true, now: fixedNow })).toThrow(/no active lessons/);
  });

  it('rejects a published journey referencing a draft series', () => {
    const ws = makeWorkspace({ seriesStatus: 'draft' });
    expect(() => publishCatalog({ ...ws, dryRun: true, now: fixedNow })).toThrow(/non-active series/);
  });

  it('unpublished journeys are simply omitted', () => {
    const ws = makeWorkspace({ publish: false });
    publishCatalog({ ...ws, dryRun: false, now: fixedNow });
    const catalog = JSON.parse(readFileSync(join(ws.outDir, 'catalog.json'), 'utf8'));
    expect(catalog.journeys).toHaveLength(0);
  });
});
