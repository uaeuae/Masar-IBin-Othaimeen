// Renders the app icon from icon.html into app/assets/icon/.
//
// The mark is CSS in the design file (masar-screens.dc.html section 2a), so it
// is rendered by a browser rather than redrawn by hand — that keeps the shipped
// icon and the design from drifting apart, and makes a change to 2a a one-command
// update instead of an art task.
//
//   node tools/icon/build-icon.mjs
//   cd app && dart run flutter_launcher_icons && dart run flutter_native_splash:create
//   node tools/icon/build-icon.mjs --refine
//
// The `--refine` pass is not optional polish. The generators derive every size
// by downscaling the 1024 master, and below ~120px «طالب العلم» stops being a
// word and becomes four grey pixels of noise. The design says as much
// («Wordmark drops "طالب العلم" below 120px»), so this pass re-renders those
// sizes from the roundel-only variant, laid out at the target size.
//
// Usage note: Chrome writes the screenshot at the window size, so the viewport
// is pinned to the render size and the page is exactly that big.

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, renameSync, rmSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const outDir = join(repo, 'app', 'assets', 'icon');
const page = pathToFileURL(join(here, 'icon.html')).href;

const CHROME_CANDIDATES = [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
].filter(Boolean);

const chrome = CHROME_CANDIDATES.find((p) => existsSync(p));
if (!chrome) {
  console.error(
    'No Chrome or Edge found. Set CHROME_PATH to a Chromium binary and re-run.',
  );
  process.exit(1);
}

function shoot(variant, outFile, px = 1024) {
  const tmp = join(here, `.render-${variant}-${px}.png`);
  execFileSync(
    chrome,
    [
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      // Transparent where the page paints nothing — the adaptive foreground
      // must not carry its own background, or Android would mask a green square.
      '--default-background-color=00000000',
      '--force-device-scale-factor=1',
      `--window-size=${px},${px}`,
      `--screenshot=${tmp}`,
      `${page}?v=${variant}&px=${px}`,
    ],
    { stdio: ['ignore', 'ignore', 'pipe'] },
  );
  if (!existsSync(tmp)) throw new Error(`chrome produced no output for ${variant}@${px}`);
  renameSync(tmp, outFile);
  return outFile;
}

/** Width from the PNG IHDR — cheaper and more reliable than parsing the size
 *  out of Apple's and Android's very different file-naming conventions. */
function pngWidth(file) {
  const head = readFileSync(file).subarray(0, 24);
  return head.readUInt32BE(16);
}

/** Below this the wordmark is noise rather than a word (design 2a). */
const WORDMARK_FLOOR = 120;

function refine() {
  const targets = [];
  const iosDir = join(
    repo, 'app', 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset',
  );
  if (existsSync(iosDir)) {
    for (const f of readdirSync(iosDir)) {
      if (f.endsWith('.png')) targets.push(join(iosDir, f));
    }
  }
  const resDir = join(repo, 'app', 'android', 'app', 'src', 'main', 'res');
  if (existsSync(resDir)) {
    for (const d of readdirSync(resDir)) {
      if (!d.startsWith('mipmap-')) continue;
      const f = join(resDir, d, 'ic_launcher.png');
      if (existsSync(f)) targets.push(f);
    }
  }

  let refined = 0;
  for (const file of targets) {
    const px = pngWidth(file);
    if (px >= WORDMARK_FLOOR) continue;
    shoot('small', file, px);
    refined++;
  }
  console.log(
    `refined ${refined} of ${targets.length} icons below ${WORDMARK_FLOOR}px ` +
      'to the roundel-only mark',
  );
}

if (process.argv.includes('--refine')) {
  refine();
} else {
  mkdirSync(outDir, { recursive: true });
  try {
    shoot('full', join(outDir, 'icon_full.png'));
    shoot('fg', join(outDir, 'icon_fg.png'));
    console.log('wrote icon_full.png and icon_fg.png');
  } finally {
    rmSync(join(here, '.render-full-1024.png'), { force: true });
    rmSync(join(here, '.render-fg-1024.png'), { force: true });
  }

  console.log(
    '\nNext: cd app && dart run flutter_launcher_icons && dart run flutter_native_splash:create' +
      '\nThen: node tools/icon/build-icon.mjs --refine',
  );
}
