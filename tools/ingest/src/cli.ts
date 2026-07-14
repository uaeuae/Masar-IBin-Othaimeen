import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { loadSeeds, SeedValidationError } from './seeds.js';
import { syncYoutube } from './commands/sync-youtube.js';
import { publishCatalog, PublishIntegrityError } from './commands/publish-catalog.js';
import { createYoutubeClient } from './youtube.js';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const defaultSeedDir = resolve(repoRoot, 'seed');
const defaultDataDir = resolve(repoRoot, 'tools', 'ingest', 'data');
const defaultOutDir = resolve(repoRoot, 'tools', 'ingest', 'dist');
const appAssetPath = resolve(repoRoot, 'app', 'assets', 'catalog', 'catalog.json');

const [command, ...rest] = process.argv.slice(2);
const dryRun = rest.includes('--dry-run');

function pathArg(name: string, fallback: string): string {
  const arg = rest.find((a) => a.startsWith(`--${name}=`));
  return arg ? resolve(arg.slice(name.length + 3)) : fallback;
}

const seedDir = pathArg('seed-dir', defaultSeedDir);
const dataDir = pathArg('data-dir', defaultDataDir);
const outDir = pathArg('out-dir', defaultOutDir);

async function main(): Promise<void> {
  switch (command) {
    case 'validate-seeds': {
      const bundle = loadSeeds(seedDir);
      console.log(
        `Seeds OK: ${bundle.sciences.length} sciences, ${bundle.series.length} series, ${bundle.journeys.length} journeys.`,
      );
      break;
    }
    case 'sync-youtube': {
      const apiKey = process.env.YT_API_KEY;
      if (!apiKey) {
        console.error('YT_API_KEY environment variable is required (YouTube Data API v3 key).');
        process.exit(64);
      }
      const { changedSeries } = await syncYoutube({
        seedDir,
        dataDir,
        dryRun,
        client: createYoutubeClient(apiKey),
      });
      console.log(
        changedSeries.length === 0
          ? 'Everything already up to date.'
          : `${changedSeries.length} series changed: ${changedSeries.join(', ')}`,
      );
      break;
    }
    case 'publish-catalog': {
      const result = publishCatalog({
        seedDir,
        dataDir,
        outDir,
        appAssetPath: rest.includes('--no-app-asset') ? undefined : appAssetPath,
        dryRun,
      });
      console.log(`Published catalog v${result.version} (${result.lessonCount} lessons).`);
      // TODO(M5b, needs Supabase project): upload dist/ to Supabase Storage.
      break;
    }
    case 'discover-playlists': {
      const apiKey = process.env.YT_API_KEY;
      if (!apiKey) {
        console.error('YT_API_KEY environment variable is required (YouTube Data API v3 key).');
        process.exit(64);
      }
      const handle = rest.find((a) => !a.startsWith('--')) ?? 'ibnothaimeentv';
      const playlists = await createYoutubeClient(apiKey).fetchChannelPlaylists(handle);
      playlists.sort((a, b) => b.itemCount - a.itemCount);
      for (const p of playlists) {
        console.log(`${p.playlistId}  ${String(p.itemCount).padStart(4)}  ${p.title}`);
      }
      console.log(`\n${playlists.length} playlists on @${handle}. Paste the IDs into seed/series/*.yaml.`);
      break;
    }
    case 'apply-seeds':
      console.error(
        'apply-seeds mirrors seeds into Supabase Postgres and needs SUPABASE_URL / ' +
          'SUPABASE_SERVICE_ROLE_KEY. The git repo is the source of truth until then — ' +
          'publish-catalog works without it.',
      );
      process.exit(2);
      break;
    default:
      console.error(
        'Usage: cli.ts <validate-seeds|sync-youtube|publish-catalog|discover-playlists [handle]|apply-seeds> ' +
          '[--dry-run] [--seed-dir=PATH] [--data-dir=PATH] [--out-dir=PATH] [--no-app-asset]',
      );
      process.exit(64);
  }
}

main().catch((error) => {
  if (error instanceof SeedValidationError || error instanceof PublishIntegrityError) {
    console.error(error.message);
  } else {
    console.error(error);
  }
  process.exit(1);
});
