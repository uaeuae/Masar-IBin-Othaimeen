import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { gunzipSync } from 'node:zlib';
import { describe, expect, it } from 'vitest';
import { publishCatalog, PublishIntegrityError } from '../src/commands/publish-catalog.js';
import type { StoredLesson } from '../src/store.js';

function makeWorkspace(options: {
  publish?: boolean;
  seriesStatus?: string;
  withLessons?: boolean;
  /** Adds the full audio edition of sharh-zad, the way every video series has one. */
  withCompanion?: boolean;
  /** Replaces the scholars.yaml body, for the coming-soon integrity checks. */
  scholars?: string;
}) {
  const root = mkdtempSync(join(tmpdir(), 'masar-publish-'));
  const seedDir = join(root, 'seed');
  const dataDir = join(root, 'data');
  const outDir = join(root, 'dist');
  mkdirSync(join(seedDir, 'series'), { recursive: true });
  mkdirSync(join(seedDir, 'journeys'), { recursive: true });
  mkdirSync(join(dataDir, 'series'), { recursive: true });

  writeFileSync(
    join(seedDir, 'scholars.yaml'),
    options.scholars ??
      'scholars:\n  - slug: ibn-uthaymeen\n    name_ar: الشيخ محمد بن صالح العثيمين\n' +
        '    initial_ar: ع\n    foundation_ar: مؤسسة الشيخ العثيمين الخيرية\n',
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

  if (options.withCompanion) {
    writeFileSync(
      join(seedDir, 'series', 'sharh-zad-audio.yaml'),
      'slug: sharh-zad-audio\ntitle_ar: شرح زاد المستقنع (صوتي)\nscience: fiqh\nstatus: active\n' +
        'media: audio\ncompanion_of: sharh-zad\nsite_audio_sections: [sec-1]\n',
    );
    const audioLessons: StoredLesson[] = [
      {
        youtube_video_id: 'a1',
        position: 1,
        title_ar: 'الدرس الصوتي الأول',
        duration_seconds: 4800,
        published_at: '2020-01-01T00:00:00Z',
        thumbnail_url: null,
        status: 'active',
        media: 'audio',
        audio_url: 'https://sounds.example/1.mp3',
      },
    ];
    writeFileSync(join(dataDir, 'series', 'sharh-zad-audio.json'), JSON.stringify(audioLessons));
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

  describe('coming-soon scholars', () => {
    const uthaymeen =
      '  - slug: ibn-uthaymeen\n    name_ar: الشيخ محمد بن صالح العثيمين\n' +
      '    initial_ar: ع\n    foundation_ar: مؤسسة الشيخ العثيمين الخيرية\n';

    it('is announced in the catalog with no series behind him', () => {
      const ws = makeWorkspace({
        scholars:
          `scholars:\n${uthaymeen}` +
          '  - slug: ibn-baz\n    name_ar: الشيخ عبد العزيز بن باز\n    initial_ar: ب\n' +
          '    accent: blue\n    honorific_ar: رحمه الله\n    status: coming_soon\n' +
          '    foundation_ar: مؤسسة الشيخ ابن باز الخيرية\n    sort_order: 2\n',
      });
      publishCatalog({ ...ws, dryRun: false, now: fixedNow });
      const catalog = JSON.parse(readFileSync(join(ws.outDir, 'catalog.json'), 'utf8'));

      const baz = catalog.scholars.find((s: { slug: string }) => s.slug === 'ibn-baz');
      expect(baz).toMatchObject({ status: 'coming_soon', initial_ar: 'ب', accent: 'blue' });
      expect(catalog.series.some((s: { scholar: string }) => s.scholar === 'ibn-baz')).toBe(false);
      // The one who does have lessons keeps his defaults.
      expect(catalog.scholars.find((s: { slug: string }) => s.slug === 'ibn-uthaymeen')).toMatchObject({
        status: 'active',
        accent: 'green',
        honorific_ar: null,
      });
    });

    it('rejects a coming-soon scholar who already has series', () => {
      // sharh-zad defaults to ibn-uthaymeen, so badging him «قريبًا» lies.
      const ws = makeWorkspace({
        scholars:
          'scholars:\n  - slug: ibn-uthaymeen\n    name_ar: الشيخ محمد بن صالح العثيمين\n' +
          '    initial_ar: ع\n    status: coming_soon\n    foundation_ar: مؤسسة الشيخ العثيمين الخيرية\n',
      });
      expect(() => publishCatalog({ ...ws, dryRun: true, now: fixedNow })).toThrow(
        /coming_soon but has 1 active series/,
      );
    });

    it('rejects an active scholar with nothing to show', () => {
      const ws = makeWorkspace({
        scholars:
          `scholars:\n${uthaymeen}` +
          '  - slug: ibn-baz\n    name_ar: الشيخ عبد العزيز بن باز\n    initial_ar: ب\n' +
          '    foundation_ar: مؤسسة الشيخ ابن باز الخيرية\n',
      });
      expect(() => publishCatalog({ ...ws, dryRun: true, now: fixedNow })).toThrow(
        /active but has no active series/,
      );
    });
  });

  it('unpublished journeys are simply omitted', () => {
    const ws = makeWorkspace({ publish: false });
    publishCatalog({ ...ws, dryRun: false, now: fixedNow });
    const catalog = JSON.parse(readFileSync(join(ws.outDir, 'catalog.json'), 'utf8'));
    expect(catalog.journeys).toHaveLength(0);
  });

  describe('audio-only', () => {
    function publishAudioOnly(ws: ReturnType<typeof makeWorkspace>) {
      publishCatalog({ ...ws, dryRun: false, audioOnly: true, now: fixedNow });
      return JSON.parse(readFileSync(join(ws.outDir, 'catalog.json'), 'utf8'));
    }

    it('exports the audio editions only, promoted to browsable', () => {
      const catalog = publishAudioOnly(makeWorkspace({ withCompanion: true }));

      expect(catalog.series).toHaveLength(1);
      expect(catalog.series[0]).toMatchObject({
        slug: 'sharh-zad-audio',
        media: 'audio',
        // Browsable: the app hides series with a non-null companion_of.
        companion_of: null,
        companion_slug: null,
        // «(صوتي)» stripped — it's the only edition now.
        title_ar: 'شرح زاد المستقنع',
      });
      expect(catalog.series[0].lessons[0]).toMatchObject({
        media: 'audio',
        audio_url: 'https://sounds.example/1.mp3',
      });
    });

    it('re-points journey stages at the audio companion', () => {
      const catalog = publishAudioOnly(makeWorkspace({ withCompanion: true }));
      expect(catalog.journeys[0].stages[0].items[0]).toEqual({
        type: 'series',
        series: 'sharh-zad-audio',
      });
    });

    it('rejects a journey on a video series that has no audio companion', () => {
      const ws = makeWorkspace({});
      expect(() => publishCatalog({ ...ws, dryRun: true, audioOnly: true, now: fixedNow })).toThrow(
        /no audio companion/,
      );
    });

    it('leaves the default publish untouched', () => {
      const ws = makeWorkspace({ withCompanion: true });
      publishCatalog({ ...ws, dryRun: false, now: fixedNow });
      const catalog = JSON.parse(readFileSync(join(ws.outDir, 'catalog.json'), 'utf8'));

      const bySlug = new Map<string, Record<string, unknown>>(
        catalog.series.map((s: { slug: string }) => [s.slug, s]),
      );
      expect([...bySlug.keys()].sort()).toEqual(['sharh-zad', 'sharh-zad-audio']);
      expect(bySlug.get('sharh-zad')).toMatchObject({ companion_slug: 'sharh-zad-audio' });
      expect(bySlug.get('sharh-zad-audio')).toMatchObject({
        companion_of: 'sharh-zad',
        title_ar: 'شرح زاد المستقنع (صوتي)',
      });
      expect(catalog.journeys[0].stages[0].items[0].series).toBe('sharh-zad');
    });
  });
});
