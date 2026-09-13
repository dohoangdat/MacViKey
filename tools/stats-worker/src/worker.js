// SPDX-License-Identifier: GPL-3.0-or-later
//
// MacViKey Stats Worker
// Gom so lieu "Muc A" (khong can app gui gi len server) roi tra ve:
//   GET /            widget HTML de nhung bang <iframe>
//   GET /stats.json  du lieu tho
//   GET /badge.svg   badge kieu shields
//
// Nguon du lieu, tat ca deu cong khai:
//   - GitHub Releases  -> luot tai tung file DMG
//   - GitHub Repo      -> sao, fork
//   - formulae.brew.sh -> luot cai qua Homebrew (chi co neu cask nam trong
//                         repo homebrew-cask CHINH THUC; tap rieng khong co)
//
// Copyright (c) 2026 Do Hoang Dat

const CACHE_TTL = 3600; // giay. GitHub API gioi han 5000 req/gio khi co token.

// ---------------------------------------------------------------- tien ich

const json = (data, status = 200, extra = {}) =>
  new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": `public, max-age=${CACHE_TTL}`,
      "access-control-allow-origin": "*",
      ...extra,
    },
  });

function ghHeaders(env) {
  const h = {
    accept: "application/vnd.github+json",
    "user-agent": "MacViKey-Stats-Worker",
  };
  if (env.GITHUB_TOKEN) h.authorization = `Bearer ${env.GITHUB_TOKEN}`;
  return h;
}

// Moi nguon hong mot cach doc lap: hong thi tra null, khong keo sap ca trang.
async function safeJSON(url, init) {
  try {
    const res = await fetch(url, init);
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------- thu thap

async function collect(env) {
  const owner = env.OWNER || "dohoangdat";
  const repo = env.REPO || "MacViKey";
  const cask = env.CASK_TOKEN || "macvikey";
  const h = ghHeaders(env);

  const [releases, repoInfo, brew] = await Promise.all([
    safeJSON(
      `https://api.github.com/repos/${owner}/${repo}/releases?per_page=100`,
      { headers: h },
    ),
    safeJSON(`https://api.github.com/repos/${owner}/${repo}`, { headers: h }),
    safeJSON(`https://formulae.brew.sh/api/cask/${cask}.json`, {
      headers: { "user-agent": "MacViKey-Stats-Worker" },
    }),
  ]);

  // --- Luot tai tung ban phat hanh
  let downloads = null;
  let perRelease = [];
  let latest = null;

  if (Array.isArray(releases)) {
    downloads = 0;
    for (const r of releases) {
      const n = (r.assets || []).reduce(
        (sum, a) => sum + (a.download_count || 0),
        0,
      );
      downloads += n;
      perRelease.push({
        tag: r.tag_name,
        downloads: n,
        published: r.published_at,
        prerelease: !!r.prerelease,
      });
      if (!latest && !r.prerelease && !r.draft) {
        latest = { tag: r.tag_name, published: r.published_at, downloads: n };
      }
    }
    perRelease.sort((a, b) => (a.published < b.published ? 1 : -1));
  }

  // --- Homebrew: chi co so neu cask da vao homebrew-cask chinh thuc.
  // Tap rieng (dohoangdat/homebrew-tap) tra ve 404 -> brewInstalls = null.
  const brewNum = (key) => {
    const v = brew?.analytics?.install?.[key];
    if (!v) return null;
    const first = Object.values(v)[0];
    return typeof first === "number" ? first : null;
  };

  return {
    ok: true,
    generated_at: new Date().toISOString(),
    source: { owner, repo, cask },
    github: {
      downloads_total: downloads,
      stars: repoInfo?.stargazers_count ?? null,
      forks: repoInfo?.forks_count ?? null,
      latest,
      releases: perRelease,
    },
    homebrew: {
      available: !!brew,
      installs_30d: brewNum("30d"),
      installs_90d: brewNum("90d"),
      installs_365d: brewNum("365d"),
    },
  };
}

// Cache o bien Cloudflare + ban luu cuoi cung trong KV (neu co binding
// STATS_KV). Khi GitHub hong, van con so cu de hien thay vi trang trong.
async function getStats(env, ctx) {
  const key = new Request("https://stats.local/macvikey");
  const cache = caches.default;

  const hit = await cache.match(key);
  if (hit) return await hit.json();

  const data = await collect(env);
  const usable = data.github.downloads_total !== null;

  if (!usable && env.STATS_KV) {
    const stale = await env.STATS_KV.get("last_good", "json");
    if (stale) return { ...stale, stale: true };
  }
  if (usable && env.STATS_KV) {
    ctx.waitUntil(env.STATS_KV.put("last_good", JSON.stringify(data)));
  }

  ctx.waitUntil(
    cache.put(
      key,
      new Response(JSON.stringify(data), {
        headers: { "cache-control": `public, max-age=${CACHE_TTL}` },
      }),
    ),
  );
  return data;
}

// ---------------------------------------------------------------- hien thi

const T = {
  vi: {
    downloads: "Lượt tải",
    installs: "Cài qua Homebrew",
    stars: "Sao trên GitHub",
    latest: "Bản mới nhất",
    day30: "30 ngày",
    updated: "Cập nhật",
    na: "—",
    brewHint: "chưa có dữ liệu",
  },
  en: {
    downloads: "Downloads",
    installs: "Homebrew installs",
    stars: "GitHub stars",
    latest: "Latest release",
    day30: "30 days",
    updated: "Updated",
    na: "—",
    brewHint: "not available yet",
  },
};

const fmt = (n, lang) =>
  typeof n === "number" ? n.toLocaleString(lang === "en" ? "en-US" : "vi-VN") : null;

function widgetHTML(s, opts) {
  const { theme, lang, compact } = opts;
  const t = T[lang] || T.vi;
  const g = s.github;
  const b = s.homebrew;

  const tiles = [
    { label: t.downloads, value: fmt(g.downloads_total, lang), sub: "GitHub Releases" },
    {
      label: t.installs,
      value: fmt(b.installs_30d, lang),
      sub: b.available ? t.day30 : t.brewHint,
    },
    { label: t.stars, value: fmt(g.stars, lang), sub: "github.com" },
  ];
  if (!compact && g.latest) {
    tiles.push({
      label: t.latest,
      value: g.latest.tag,
      sub: new Date(g.latest.published).toLocaleDateString(
        lang === "en" ? "en-US" : "vi-VN",
      ),
    });
  }

  const cells = tiles
    .map(
      (x) => `<div class="tile">
        <div class="v${x.value === null ? " muted" : ""}">${
          x.value === null ? t.na : x.value
        }</div>
        <div class="l">${x.label}</div>
        <div class="s">${x.sub}</div>
      </div>`,
    )
    .join("");

  // Bang mau: sang mac dinh, toi khi ?theme=dark hoac theo he thong khi auto.
  const darkVars = `
    --bg:#16161a; --fg:#f2f2f4; --dim:#a0a0aa; --line:#2c2c33; --card:#1d1d22;`;
  const themeBlock =
    theme === "dark"
      ? `:root{${darkVars}}`
      : theme === "light"
        ? ""
        : `@media (prefers-color-scheme: dark){:root{${darkVars}}}`;

  return `<!doctype html>
<html lang="${lang}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MacViKey — thống kê</title>
<style>
  :root{
    --bg:transparent; --fg:#1c1c1e; --dim:#6b6b73;
    --line:#e4e4e8; --card:#ffffff; --brand:#d98533;
  }
  ${themeBlock}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--fg);
    font:14px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;
    -webkit-font-smoothing:antialiased}
  .wrap{padding:14px}
  .grid{display:grid;gap:10px;
    grid-template-columns:repeat(auto-fit,minmax(130px,1fr))}
  .tile{background:var(--card);border:1px solid var(--line);
    border-radius:10px;padding:12px 14px}
  .v{font-size:26px;font-weight:640;letter-spacing:-.02em;
    font-variant-numeric:tabular-nums;color:var(--brand);line-height:1.15}
  .v.muted{color:var(--dim);font-weight:500}
  .l{margin-top:3px;font-size:12.5px;font-weight:560}
  .s{margin-top:1px;font-size:11px;color:var(--dim)}
  .foot{margin-top:10px;font-size:11px;color:var(--dim);
    display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap}
  .foot a{color:inherit;text-decoration:none;border-bottom:1px solid var(--line)}
  @media (max-width:400px){.wrap{padding:12px}.v{font-size:22px}}
</style></head><body>
<div class="wrap" id="root">
  <div class="grid">${cells}</div>
  <div class="foot">
    <span>${t.updated}: ${new Date(s.generated_at).toLocaleString(
      lang === "en" ? "en-US" : "vi-VN",
    )}${s.stale ? " (cache)" : ""}</span>
    <a href="https://github.com/${s.source.owner}/${s.source.repo}"
       target="_blank" rel="noopener">${s.source.owner}/${s.source.repo}</a>
  </div>
</div>
<script>
  // Bao chieu cao that cho trang cha de iframe tu co gian.
  function ping(){
    var h = document.getElementById('root').getBoundingClientRect().height;
    parent.postMessage({type:'macvikey-stats-height',height:Math.ceil(h)+2},'*');
  }
  addEventListener('load',ping); addEventListener('resize',ping); ping();
</script>
</body></html>`;
}

function badgeSVG(label, value, color) {
  // Badge kieu shields, tu ve, khong phu thuoc dich vu ngoai.
  const w1 = 6.6 * label.length + 12;
  const w2 = 6.6 * value.length + 12;
  const w = w1 + w2;
  const esc = (t) =>
    t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="20" role="img" aria-label="${esc(label)}: ${esc(value)}">
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#fff" stop-opacity=".7"/>
    <stop offset=".1" stop-color="#aaa" stop-opacity=".1"/>
    <stop offset=".9" stop-opacity=".3"/><stop offset="1" stop-opacity=".5"/>
  </linearGradient>
  <rect rx="3" width="${w}" height="20" fill="#555"/>
  <rect rx="3" x="${w1}" width="${w2}" height="20" fill="${color}"/>
  <rect rx="3" width="${w}" height="20" fill="url(#s)"/>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,DejaVu Sans,sans-serif" font-size="11">
    <text x="${w1 / 2}" y="15" fill="#010101" fill-opacity=".3">${esc(label)}</text>
    <text x="${w1 / 2}" y="14">${esc(label)}</text>
    <text x="${w1 / 2 + w2}" y="15" fill="#010101" fill-opacity=".3">${esc(value)}</text>
    <text x="${w1 / 2 + w2}" y="14">${esc(value)}</text>
  </g>
</svg>`;
}

// ---------------------------------------------------------------- dinh tuyen

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const q = url.searchParams;

    // frame-ancestors quyet dinh trang nao duoc nhung. Dat ALLOWED_ANCESTORS
    // trong wrangler.toml de chi cho phep website cua ban.
    const ancestors = env.ALLOWED_ANCESTORS || "*";
    const frameHeaders = {
      "content-security-policy": `frame-ancestors ${ancestors};`,
    };

    if (url.pathname === "/stats.json") {
      return json(await getStats(env, ctx));
    }

    if (url.pathname === "/badge.svg") {
      const s = await getStats(env, ctx);
      const metric = q.get("metric") || "downloads";
      const lang = q.get("lang") === "en" ? "en" : "vi";
      const pick = {
        downloads: [q.get("label") || "downloads", s.github.downloads_total],
        installs: [q.get("label") || "homebrew", s.homebrew.installs_30d],
        stars: [q.get("label") || "stars", s.github.stars],
      }[metric] || ["stats", null];
      const value = fmt(pick[1], lang) ?? "n/a";
      return new Response(
        badgeSVG(pick[0], value, q.get("color") || "#d98533"),
        {
          headers: {
            "content-type": "image/svg+xml; charset=utf-8",
            "cache-control": `public, max-age=${CACHE_TTL}`,
            "access-control-allow-origin": "*",
          },
        },
      );
    }

    if (url.pathname === "/" || url.pathname === "/widget") {
      const s = await getStats(env, ctx);
      const theme = ["light", "dark", "auto"].includes(q.get("theme"))
        ? q.get("theme")
        : "auto";
      const lang = q.get("lang") === "en" ? "en" : "vi";
      return new Response(
        widgetHTML(s, { theme, lang, compact: q.get("compact") === "1" }),
        {
          headers: {
            "content-type": "text/html; charset=utf-8",
            "cache-control": `public, max-age=${CACHE_TTL}`,
            ...frameHeaders,
          },
        },
      );
    }

    return json({ ok: false, error: "not found" }, 404);
  },
};
