import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { loadSeeds, SeedValidationError } from './seeds.js';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const defaultSeedDir = resolve(repoRoot, 'seed');

const [command, ...rest] = process.argv.slice(2);
const flags = new Set(rest.filter((a) => a.startsWith('--')));

function seedDirArg(): string {
  const explicit = rest.find((a) => a.startsWith('--seed-dir='));
  return explicit ? resolve(explicit.slice('--seed-dir='.length)) : defaultSeedDir;
}

switch (command) {
  case 'validate-seeds': {
    try {
      const bundle = loadSeeds(seedDirArg());
      console.log(
        `Seeds OK: ${bundle.sciences.length} sciences, ${bundle.series.length} series, ${bundle.journeys.length} journeys.`,
      );
    } catch (e) {
      if (e instanceof SeedValidationError) {
        console.error(e.message);
        process.exit(1);
      }
      throw e;
    }
    break;
  }
  case 'sync-youtube':
  case 'apply-seeds':
  case 'publish-catalog':
    console.error(`"${command}" is not implemented yet (planned for milestone M5).${flags.has('--dry-run') ? ' (--dry-run)' : ''}`);
    process.exit(2);
    break;
  default:
    console.error('Usage: cli.ts <validate-seeds|sync-youtube|apply-seeds|publish-catalog> [--dry-run] [--seed-dir=PATH]');
    process.exit(64);
}
