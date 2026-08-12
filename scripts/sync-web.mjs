#!/usr/bin/env node
/**
 * 배포된 웹 버전(https://reversechess.perfect.ai.kr)의 빌드 산출물을 www/로 미러링한다.
 *
 * 웹 소스 코드가 아직 이 레포에 없으므로, 앱은 라이브 사이트의 빌드 결과물을
 * 로컬 번들로 사용한다. 웹 소스가 레포에 들어오면 이 스크립트 대신
 * `vite build --outDir www`로 대체하면 된다.
 *
 * 변환 내용:
 *  - Google Analytics(gtag) 스크립트 제거 + window.gtag no-op 스텁 주입
 *    (번들이 window.gtag를 직접 호출하므로 스텁이 없으면 앱이 크래시한다)
 *  - Google Fonts를 로컬(/assets/fonts/)로 다운로드해 오프라인 동작 보장
 */
import fs from 'node:fs';
import path from 'node:path';

const ORIGIN = 'https://reversechess.perfect.ai.kr';
const OUT = 'www';
const FONTS_CSS_URL =
  'https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700&family=Noto+Sans+KR:wght@400;500;600;700&display=swap';
const CHROME_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';

async function fetchOk(url, opts = {}, retries = 3) {
  for (let i = 0; ; i++) {
    try {
      const res = await fetch(url, opts);
      if (res.ok) return res;
      throw new Error(`HTTP ${res.status} for ${url}`);
    } catch (e) {
      if (i >= retries) throw e;
      await new Promise((r) => setTimeout(r, 2000 * (i + 1)));
    }
  }
}

function save(rel, buf) {
  const p = path.join(OUT, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, buf);
  console.log(`  ${rel} (${buf.length.toLocaleString()} bytes)`);
}

console.log(`Mirroring ${ORIGIN} -> ${OUT}/`);

// 1. index.html에서 해시된 에셋 경로 추출
let html = await (await fetchOk(ORIGIN + '/')).text();
const assetRefs = [...html.matchAll(/(?:src|href)="(\/assets\/[^"]+|\/icon\.[a-z]+)"/g)].map((m) => m[1]);

// 2. GA 스크립트 블록 제거 (googletagmanager <script> 및 인라인 gtag 설정)
html = html
  .replace(/\s*<!-- Google tag[^>]*-->/g, '')
  .replace(/\s*<script[^>]*googletagmanager[^>]*><\/script>/g, '')
  .replace(/\s*<script>[\s\S]*?gtag\('config'[\s\S]*?<\/script>/g, '');

// 3. gtag 스텁 + 로컬 폰트 CSS 주입
html = html.replace(
  '</title>',
  `</title>
    <!-- App build: Google Analytics removed; the web bundle calls window.gtag directly, so stub it -->
    <script>
      window.dataLayer = window.dataLayer || [];
      window.gtag = function () {};
    </script>
    <link rel="stylesheet" href="/assets/fonts/fonts.css" />`,
);
save('index.html', Buffer.from(html));

// 4. index.html이 참조하는 에셋 + JS 번들이 참조하는 에셋(워커 등) 다운로드
const downloaded = new Set();
async function mirror(rel) {
  if (downloaded.has(rel)) return null;
  downloaded.add(rel);
  const buf = Buffer.from(await (await fetchOk(ORIGIN + rel)).arrayBuffer());
  save(rel, buf);
  return buf;
}
for (const ref of assetRefs) {
  const buf = await mirror(ref);
  if (buf && ref.endsWith('.js')) {
    for (const m of buf.toString('utf8').matchAll(/["'](\/assets\/[A-Za-z0-9._-]+)["']/g)) {
      await mirror(m[1]);
    }
  }
}
await mirror('/icon.png').catch(() => console.log('  (icon.png 없음 — 건너뜀)'));

// 5. Google Fonts 로컬 번들링
console.log('Bundling fonts...');
let css = await (await fetchOk(FONTS_CSS_URL, { headers: { 'User-Agent': CHROME_UA } })).text();
const fontUrls = [...new Set(css.match(/https:\/\/fonts\.gstatic\.com\/[^)]+/g) ?? [])];
let i = 0;
for (const u of fontUrls) {
  const name = `f${i++}.${u.split('.').pop()}`;
  save(path.join('assets/fonts', name), Buffer.from(await (await fetchOk(u)).arrayBuffer()));
  css = css.split(u).join(name);
}
save('assets/fonts/fonts.css', Buffer.from(css));

console.log(`Done. ${downloaded.size} assets + ${fontUrls.length} fonts mirrored.`);
