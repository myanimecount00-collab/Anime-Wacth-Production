/**
 * AnimeVault - Backend Scraper
 * Jalankan: NODE_ENV=production node server.js
 * Build: 1000-FIXED
 */

const express  = require('express');
const axios    = require('axios');
const cheerio  = require('cheerio');
const cors     = require('cors');
const path     = require('path');
const https    = require('https');
const fs       = require('fs');
const puppeteer = require("puppeteer");
const app  = express();
const PORT = 3000;

// ── Environment Check ─────────────────────────────────────────────────────────
const isDev = process.env.NODE_ENV !== 'production';
console.log(`🚀 Running in ${isDev ? 'DEVELOPMENT' : 'PRODUCTION'} mode`);

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// ── Headers ──────────────────────────────────────────────────────────────────
const HEADERS = {
  'User-Agent':      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
  'Accept':          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
  'Referer':         'https://otakudesu.blog/',
  'Cache-Control':   'no-cache',
  'Pragma':          'no-cache',
};

const httpsAgent = new https.Agent({ rejectUnauthorized: false });

// ── Cache ─────────────────────────────────────────────────────────────────────
const cache = new Map();
const anilistCache = new Map();

const CACHE_TTL = 10 * 60 * 1000;

function getCache(key) {
  const item = cache.get(key);
  if (!item) return null;
  if (Date.now() - item.time > CACHE_TTL) { cache.delete(key); return null; }
  return item.data;
}
function setCache(key, data) { cache.set(key, { data, time: Date.now() }); }

// ── Fungsi fetchHTML dengan parameter useCache ────────────────────────────
async function fetchHTML(url, extraHeaders = {}, useCache = true) {
  if (useCache) {
    const cached = getCache(url);
    if (cached) return cached;
  }

  const { data } = await axios.get(url, {
    headers: { ...HEADERS, ...extraHeaders },
    timeout: 15000,
    httpsAgent,
  });

  if (useCache) {
    setCache(url, data);
  }

  return data;
}

// ── Fungsi scrape terbaru (digunakan oleh /api/terbaru) ──────────────────────
async function scrapeTerbaru() {
  const url  = 'https://otakudesu.blog/ongoing-anime/';
  const html = await fetchHTML(url);
  const $    = cheerio.load(html);
  const results = [];

  $('.venz ul li').each((_, el) => {
    const title = $(el).find('.jdlflm').text().trim();
    const link  = $(el).find('.thumb a').attr('href');
    const thumb = $(el).find('img').attr('src');
    const ep    = $(el).find('.epz').text().trim();
    if (title) results.push({ title, link, thumb, ep });
  });

  return results;
}

// ── Fungsi scrape halaman genre ───────────────────────────────────────────
async function scrapeGenre(genreUrl) {
  const html = await fetchHTML(genreUrl);
  const $ = cheerio.load(html);

  const animeLinksSet = new Set();
  $('a').each((_, el) => {
    const href = $(el).attr('href');
    if (href && href.includes('/anime/')) {
      animeLinksSet.add(href);
    }
  });
  const animeLinks = [...animeLinksSet];

  async function scrapeAnimeInfo(animeUrl) {
    const html = await fetchHTML(animeUrl);
    const $ = cheerio.load(html);
    const title = $('.jdlrx h1').text().trim() || $('title').text().trim();
    const thumb = $('.fotoanime img').attr('src') || $('img').first().attr('src') || '';
    return { title, thumb, link: animeUrl, ep: 'Complete' };
  }

  const animeResults = await Promise.all(
    animeLinks.slice(0, 20).map(async (link) => {
      try {
        return await scrapeAnimeInfo(link);
      } catch (e) {
        return null;
      }
    })
  );

  const results = animeResults.filter(
    (anime) => anime != null
  );

  return results;
}

// ── Fungsi scrape jadwal rilis ─────────────────────────────────────────────
async function scrapeSchedule() {
  const html = await fetchHTML(
    'https://otakudesu.blog/jadwal-rilis/'
  );

  const $ = cheerio.load(html);

  const result = {
    senin: [],
    selasa: [],
    rabu: [],
    kamis: [],
    jumat: [],
    sabtu: [],
    minggu: [],
  };

  // TODO: isi jadwal dari halaman
  return result;
}

// ── Fungsi scrape genre dari halaman detail anime ─────────────────────────
async function scrapeGenres(animeUrl) {
  const html = await fetchHTML(animeUrl);
  const $ = cheerio.load(html);

  const genres = [];

  $('.infozin .infozingle').each((_, el) => {
    if ($(el).find('b').text().toLowerCase().includes('genre')) {
      $(el).find('a').each((_, a) => {
        genres.push($(a).text().trim());
      });
    }
  });

  return genres;
}

// ── Decode helper ─────────────────────────────────────────────────────────────
function decodePlayerHtml(raw) {
  let s = raw
    .replace(/&quot;/g,  '"')
    .replace(/&amp;/g,   '&')
    .replace(/&#x27;/g,  "'")
    .replace(/&lt;/g,    '<')
    .replace(/&gt;/g,    '>');

  s = s
    .replace(/\\\//g, '/')
    .replace(/\\u([\dA-Fa-f]{4})/g,
      (_, hex) => String.fromCharCode(parseInt(hex, 16)));

  return s;
}

function extractVideoUrl(rawHtml) {
  const html = decodePlayerHtml(rawHtml);

  if (isDev) console.log("\n========== EXTRACT VIDEO ==========");
  if (isDev) console.log("HTML LENGTH:", html.length);

  // Pola regex yang diperluas
  const keyPatterns = [
    /["']url["']\s*:\s*["'](https?:\/\/[^"']+\.(?:mp4|m3u8)[^"']*)["']/i,
    /["']file["']\s*:\s*["'](https?:\/\/[^"']+\.(?:mp4|m3u8)[^"']*)["']/i,
    /["']src["']\s*:\s*["'](https?:\/\/[^"']+\.(?:mp4|m3u8)[^"']*)["']/i,
    /video_url["']?\s*[:=]\s*["'](https?:\/\/[^"']+)["']/i,
    /videoUrl["']?\s*[:=]\s*["'](https?:\/\/[^"']+)["']/i,
    /streamUrl["']?\s*[:=]\s*["'](https?:\/\/[^"']+)["']/i,
    /contentUrl["']?\s*[:=]\s*["'](https?:\/\/[^"']+)["']/i,
    /sources\s*:\s*\[\s*\{\s*file\s*:\s*["'](https?:\/\/[^"']+)["']/i,
  ];

  for (const p of keyPatterns) {
    const m = html.match(p);
    if (m?.[1]) {
      if (isDev) console.log("✅ REGEX MATCH");
      if (isDev) console.log(m[1]);
      return m[1];
    }
  }

  const scriptBlocks = [...html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi)]
    .map(m => m[1]);

  for (const block of scriptBlocks) {
    const objCandidates = [
      ...block.matchAll(/(?:sources?|playerConfig|setup)\s*[=(]\s*(\[?\{[\s\S]+?\}\]?)\s*[;)]/g)
    ].map(m => m[1]);

    for (const candidate of objCandidates) {
      try {
        const parsed = JSON.parse(candidate);
        if (Array.isArray(parsed)) {
          const url = parsed[0]?.file || parsed[0]?.url || parsed[0]?.src;
          if (url) return url;
        }
        const sources = parsed.sources || parsed.playlist?.[0]?.sources;
        if (Array.isArray(sources)) {
          const url = sources[0]?.file || sources[0]?.url || sources[0]?.src;
          if (url) return url;
        }
        if (parsed.file) return parsed.file;
      } catch { /* bukan JSON valid, lanjut */ }
    }
  }

  const sourceTag = html.match(
    /<source\b[^>]*\bsrc\s*=\s*["']([^"']+)["']/i
  );
  if (sourceTag?.[1]) {
    if (isDev) console.log("✅ SOURCE TAG");
    return sourceTag[1];
  }

  // Tambahan: cek <video src="">
  const videoTag = html.match(
    /<video\b[^>]*\bsrc\s*=\s*["']([^"']+)["']/i
  );
  if (videoTag?.[1]) {
    if (isDev) console.log("✅ VIDEO TAG");
    return videoTag[1];
  }

  const fallback = html.match(/(https?:\/\/[^\s"'<>]+\.(?:mp4|m3u8)[^\s"'<>]*)/i);
  if (fallback?.[1]) {
    if (isDev) console.log("⚠ FALLBACK");
    return fallback[1];
  }

  return null;
}

// ── Fungsi resolveIframeVideo pakai Puppeteer (DIPERBARUI) ──────────────────
async function resolveIframeVideo(iframeUrl) {
  let browser;

  try {
    browser = await puppeteer.launch({
      headless: true,
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-blink-features=AutomationControlled",
      ],
    });

    const page = await browser.newPage();

    await page.setUserAgent(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"
    );

    await page.setViewport({
      width: 1280,
      height: 720,
    });

    // Interception untuk menangkap video request
    let interceptedVideo = null;
    page.on("response", async (response) => {
      const finalUrl = response.url();
      if (
        finalUrl.includes("googlevideo") ||
        finalUrl.endsWith(".mp4") ||
        finalUrl.includes(".m3u8")
      ) {
        interceptedVideo = finalUrl;
        if (isDev) console.log("🎯 INTERCEPT");
        if (isDev) console.log(finalUrl);
      }
    });

    if (isDev) console.log("🚀 Puppeteer membuka iframe...");
    if (isDev) console.log(iframeUrl);

    await page.goto(iframeUrl, {
      waitUntil: "domcontentloaded",
      timeout: 30000,
    });

    // Tunggu elemen <video> ada
    await page.waitForSelector("video", {
      timeout: 10000,
    }).catch(() => isDev && console.log("⚠️ video element not found"));

    const currentSrc = await page.evaluate(() => {
      const v = document.querySelector("video");
      return v ? v.currentSrc : null;
    });

    if (isDev) console.log("🎉 Puppeteer selesai:");
    if (isDev) console.log("currentSrc:", currentSrc);
    if (isDev) console.log("interceptedVideo:", interceptedVideo);

    // ── LOGGING COOKIES (HANYA DI DEV) ─────────────────────────────
    if (isDev) {
      const cookies = await page.cookies();
      console.log("========== COOKIES ==========");
      console.log(cookies);
      console.log("=============================");
    }
    // ─────────────────────────────────────────────────────────────────

    return interceptedVideo || currentSrc;

  } catch (e) {

    if (isDev) console.log("❌ Puppeteer gagal:");
    if (isDev) console.log(e.message);

    return null;

  } finally {

    if (browser) {
      await browser.close();
    }

  }
}

// ── Fungsi untuk mengambil data dari AniList ────────────────────────────────
async function getAniListData(title) {
  try {
    const query = `
      query ($search: String) {
        Media(search: $search, type: ANIME) {
          title {
            romaji
            english
          }
          averageScore
          description
          bannerImage
        }
      }
    `;

    const response = await axios.post(
      'https://graphql.anilist.co',
      {
        query,
        variables: {
          search: title
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }
      }
    );

    return response.data?.data?.Media || null;

  } catch (err) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 1: Anime ongoing terbaru
//  GET /api/terbaru
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/terbaru', async (req, res) => {
  try {
    const results = await scrapeTerbaru();
    res.json(results);
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil data', detail: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 2: Trending anime (anime pertama dari ongoing)
//  GET /api/trending
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/trending', async (req, res) => {
  try {
    const html = await fetchHTML(
      'https://otakudesu.blog/ongoing-anime/'
    );

    const $ = cheerio.load(html);

    const results = [];

    $('.venz ul li').slice(0, 5).each((_, el) => {
      results.push({
        title: $(el).find('.jdlflm').text().trim(),
        link:  $(el).find('.thumb a').attr('href'),
        thumb: $(el).find('img').attr('src'),
        ep:    $(el).find('.epz').text().trim(),
      });
    });

    res.json(results);

  } catch(err) {
    res.status(500).json({
      error: err.message
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 3: Detail anime + daftar episode
//  GET /api/detail?url=https://...
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/detail', async (req, res) => {
  const { url } = req.query;
  if (!url) return res.status(400).json({ error: 'Parameter url wajib diisi' });

  try {
    const html = await fetchHTML(url);
    const $    = cheerio.load(html);

    let title = $('h1.entry-title').text().trim() || $('title').text().trim();
    title = title
      .replace('| Otaku Desu', '')
      .replace(' Subtitle Indonesia', '')
      .replace(' Sub Indo', '')
      .trim();

    let anilist = anilistCache.get(title);
    if (!anilist) {
      anilist = await getAniListData(title);
      anilistCache.set(title, anilist);
    }

    let synopsis =
      $('meta[property="og:description"]').attr('content')?.trim() ||
      $('meta[name="description"]').attr('content')?.trim() ||
      $('.sinopc').text().trim() ||
      '';
    if (
      synopsis.includes('Download') ||
      synopsis.includes('Streaming Anime') ||
      synopsis.includes('Sub Indo')
    ) {
      synopsis = '';
    }

    if (!synopsis) {
      synopsis = $('.sinopsis').text().trim() || $('.entry-content').text().trim() || '';
    }

    if (anilist?.description) {
      synopsis = anilist.description
        .replace(/<[^>]*>/g, '')
        .replace(/&quot;/g, '"')
        .replace(/&#039;/g, "'")
        .trim();
    }

    const thumb    = $('.fotoanime img').attr('src') || '';
    let score = '';

    const infoText = $('.infozin').text();
    const match = infoText.match(/Skor:\s*([0-9.]+)/);
    if (match) {
      score = match[1];
    }

    const genres   = [];
    const episodes = [];

    $('.infozin .infozingle').each((_, el) => {
      if ($(el).find('b').text().toLowerCase().includes('genre')) {
        $(el).find('a').each((_, a) => genres.push($(a).text().trim()));
      }
    });

    $('.episodelist ul li').each((_, el) => {
      const epTitle = $(el).find('a').text().trim();
      const epLink  = $(el).find('a').attr('href') || '';
      const epDate  = $(el).find('.zeebr').text().trim() || '';
      if (epTitle) episodes.push({ title: epTitle, link: epLink, date: epDate });
    });

    const finalScore = anilist?.averageScore
      ? (anilist.averageScore / 10).toFixed(1)
      : score;

    res.json({
      title,
      synopsis,
      thumb,
      score: finalScore,
      genres,
      episodes,
      banner: anilist?.bannerImage || '',
    });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil detail', detail: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 4: Link streaming (DIPERBARUI – GoogleVideo dialihkan ke browser)
//  GET /api/stream?url=https://...&quality=720p
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/stream', async (req, res) => {
  const { url, quality = '720p' } = req.query;

  if (!url) {
    return res.status(400).json({ error: 'Parameter url wajib diisi' });
  }
  try {
    // ── 1. Scrape halaman episode ─────────────────────────────────────────
    const html = await fetchHTML(url, {}, false);

    const $        = cheerio.load(html);
    const sources  = [];

    $('.mirrorstream ul li').each((_, el) => {
      const q      = $(el).find('a').text().trim();
      const server = $(el).find('a').attr('data-content') || '';
      if (q && server) sources.push({ quality: q, server });
    });

    if (!sources.length) {
      return res.status(404).json({ error: 'Tidak ada sumber video ditemukan di halaman episode' });
    }

    // ── 2. Pilih source ───────────────────────────────────────────────────
    function pickSource(list, preferredQ) {
      const byQ = list.filter(s => {
        try {
          const p = JSON.parse(Buffer.from(s.server, 'base64').toString('utf8'));
          return p.q === preferredQ;
        } catch { return false; }
      });
      if (byQ.length) {
        return byQ.find(s => !['mega'].includes(s.quality)) || byQ[0];
      }
      const fallbackQ = preferredQ === '720p' ? '480p' : '360p';
      const byFb = list.filter(s => {
        try {
          const p = JSON.parse(Buffer.from(s.server, 'base64').toString('utf8'));
          return p.q === fallbackQ;
        } catch { return false; }
      });
      return byFb.find(s => !['mega'].includes(s.quality)) || list[0];
    }

    const target = pickSource(sources, quality);
    let parsed;
    try {
      parsed = JSON.parse(Buffer.from(target.server, 'base64').toString('utf8'));
    } catch (e) {
      return res.status(500).json({ error: 'Gagal decode server payload', detail: e.message });
    }

    // ── 3. Ambil nonce ────────────────────────────────────────────────────
    const nonceRes = await axios.post(
      'https://otakudesu.blog/wp-admin/admin-ajax.php',
      new URLSearchParams({ action: 'aa1208d27f29ca340c92c66d1926f13f' }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded', ...HEADERS }, httpsAgent }
    );

    const nonce = nonceRes.data?.data;
    if (!nonce) {
      return res.status(500).json({ error: 'Gagal mendapatkan nonce dari server' });
    }

    // ── 4. Ambil player HTML ──────────────────────────────────────────────
    const playerRes = await axios.post(
      'https://otakudesu.blog/wp-admin/admin-ajax.php',
      new URLSearchParams({
        id: parsed.id, i: parsed.i, q: parsed.q, nonce,
        action: '2a3505c93b0035d3f455df82bf976b84',
      }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded', ...HEADERS }, httpsAgent }
    );

    let iframeHtml = '';
    try {
      iframeHtml = Buffer.from(playerRes.data?.data || '', 'base64').toString('utf8');
    } catch {
      return res.status(500).json({ error: 'Gagal decode response player' });
    }

    // ── Decode & extract iframe URL ─────────────────────────────────────
    const decoded = decodePlayerHtml(iframeHtml);
    const iframeSrcMatch = decoded.match(/src=["']([^"']+)["']/i);
    const iframeUrl      = iframeSrcMatch?.[1] || '';

    // ── Jalur 1: Tidak ada iframe URL ──────────────────────────────────
    if (!iframeUrl) {
      const directUrl = extractVideoUrl(decoded);  // gunakan decoded
      return res.json({
        streamType: directUrl ? "mp4" : "error",
        streamUrl: directUrl || '',
        videoUrl: directUrl,
        iframeSrc: '',
        sources,
      });
    }

    // ── 5. Fetch halaman embed player ─────────────────────────────────────
    let embedHtml = '';
    try {
      embedHtml = await fetchHTML(
        iframeUrl,
        { Referer: 'https://otakudesu.blog/' },
        false,
      );
    } catch (e) {
      return res.json({
        streamType: "iframe",
        streamUrl: iframeUrl,
        videoUrl: null,
        iframeSrc: iframeUrl,
        sources,
      });
    }

    // ── ANALISIS EMBED HTML (HANYA DI DEV) ────────────────────────────
    if (isDev) {
      console.log("\n========== EMBED ANALYSIS ==========");
      console.log("Episode :", url);
      console.log("Iframe  :", iframeUrl);

      console.log("Has <video> :", embedHtml.includes("<video"));
      console.log("Has <source>:", embedHtml.includes("<source"));
      console.log("Has jwplayer:", embedHtml.toLowerCase().includes("jwplayer"));
      console.log("Has video.js:", embedHtml.toLowerCase().includes("video.js"));
      console.log("Has plyr    :", embedHtml.toLowerCase().includes("plyr"));
      console.log("Has eval()  :", embedHtml.includes("eval("));
      console.log("Has unpack  :", embedHtml.includes("p,a,c,k,e,d"));
      console.log("====================================");
    }

    // ── Simpan HTML embed untuk debugging (HANYA DI DEV) ────────────────
    if (isDev) {
      fs.writeFileSync(`debug_${Date.now()}.html`, embedHtml);
      console.log(`💾 Embed HTML disimpan → debug_${Date.now()}.html`);
    }

    // ── 6. Ekstrak direct video URL ───────────────────────────────────────
    let videoUrl = extractVideoUrl(embedHtml);

    if (!videoUrl && iframeUrl) {
      if (isDev) console.log("🚀 Regex gagal, coba Puppeteer...");
      videoUrl = await resolveIframeVideo(iframeUrl);
    }

    // ── LOGGING TAMBAHAN (HANYA DI DEV) ──────────────────────────────
    if (isDev) {
      console.log("================================");
      console.log("VIDEO URL :", videoUrl);
      console.log("IFRAME URL:", iframeUrl);
      console.log("================================");
    }
    // ──────────────────────────────────────────────────────────────────

    // ── REQUEST STREAM UNTUK CEK VIDEO (SEBELUMNYA HEAD REQUEST) ─────
    if (videoUrl) {
      try {
        const response = await axios({
          method: "GET",
          url: videoUrl,
          responseType: "stream",
          headers: {
            "User-Agent": "Mozilla/5.0",
            "Accept": "*/*",
            "Referer": "https://desustream.info/",
            "Origin": "https://desustream.info",
            "Range": "bytes=0-",
            "Connection": "keep-alive"
          },
          httpsAgent,
          maxRedirects: 5,
          validateStatus: () => true
        });
        // Kita tidak perlu mengonsumsi stream, cukup cek status
        response.data.destroy(); // Hentikan stream
        if (isDev) console.log("📊 GET stream status:", response.status);
      } catch (e) {
        if (isDev) console.log("⚠️ Gagal melakukan stream check:", e.message);
      }
    }
    // ────────────────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────────────────────
    //  PERBAIKAN LOGIC TIPE STREAM (UPDATED)
    // ─────────────────────────────────────────────────────────────────────

    // Deteksi tipe video
    const isGoogleVideo = videoUrl && 
      (videoUrl.includes('googlevideo.com') || 
       videoUrl.includes('googleusercontent.com'));

    const isCloudFlareR2 = videoUrl && 
      (videoUrl.includes('r2.cloudflare.com') ||
       videoUrl.includes('r2.cloudflarestorage.com') ||
       videoUrl.includes('filedon.co'));

    if (isDev) {
      console.log("🔍 Is Google Video?", isGoogleVideo);
      console.log("☁️  Is CloudFlare R2?", isCloudFlareR2);
      console.log("🎥 Video URL Valid?", !!videoUrl);
      console.log("📺 Iframe URL Valid?", !!iframeUrl);
    }

    // ── GOOGLE VIDEO → arahkan ke browser / WebView ──
    if (isGoogleVideo) {
      if (isDev) console.log("🎉 DETEKSI GOOGLE VIDEO → streamType = browser");
      return res.json({
        streamType: "browser",
        streamUrl: iframeUrl,
        videoUrl: null,
        iframeSrc: iframeUrl,
        sources,
        _debug: isDev ? {
          isGoogleVideo: true,
          isCloudFlareR2,
          videoUrlFound: !!videoUrl,
          iframeUrlFound: !!iframeUrl,
          htmlLength: embedHtml.length,
        } : undefined
      });
    }

    // LOGIC UNTUK MP4 / IFRAME BIASA
    let finalStreamType;
    let finalStreamUrl;

    if (videoUrl && videoUrl.length > 0) {
      // CloudFlare R2 atau CDN lain → langsung MP4
      finalStreamType = "mp4";
      finalStreamUrl = videoUrl;
      if (isDev) console.log("✅ USE DIRECT MP4");
    } else if (iframeUrl && iframeUrl.length > 0) {
      // Fallback ke iframe
      finalStreamType = "iframe";
      finalStreamUrl = iframeUrl;
      if (isDev) console.log("⚠️  FALLBACK IFRAME");
    } else {
      // Semua gagal
      finalStreamType = "error";
      finalStreamUrl = null;
      if (isDev) console.log("❌ NO STREAM FOUND");
    }

    // LOG FINAL (HANYA DI DEV)
    if (isDev) {
      console.log("═ FINAL STREAM TYPE:", finalStreamType);
      console.log("═ FINAL STREAM URL:", finalStreamUrl?.substring(0, 100));
    }

    const result = {
      streamType: finalStreamType,
      streamUrl: finalStreamUrl,
      videoUrl: (finalStreamType === "mp4") ? videoUrl : null,
      iframeSrc: iframeUrl,
      sources,
      ...(isDev && {
        _debug: {
          isGoogleVideo,
          isCloudFlareR2,
          videoUrlFound: !!videoUrl,
          iframeUrlFound: !!iframeUrl,
          htmlLength: embedHtml.length,
        }
      })
    };

    if (isDev) {
      console.log("========== RESULT ==========");
      console.log(result.streamType);
      console.log(result.streamUrl?.substring(0,120));
      console.log("============================");
    }
    return res.json(result);

  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil link stream', detail: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 5: Search anime
//  GET /api/search?q=naruto
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/search', async (req, res) => {
  const { q } = req.query;
  if (!q) return res.status(400).json({ error: 'Parameter q wajib diisi' });

  try {
    const url  = `https://otakudesu.blog/?s=${encodeURIComponent(q)}&post_type=anime`;
    const html = await fetchHTML(url);
    const $    = cheerio.load(html);
    const results = [];

    $('li').each((_, el) => {
      const title = $(el).find('h2 a').first().text().trim();
      const link  = $(el).find('h2 a').first().attr('href') || '';
      const thumb = $(el).find('img').first().attr('src') || '';
      const genre = $(el).find('.set a').map((_, a) => $(a).text().trim()).get().join(', ');
      if (title && link.includes('/anime/')) results.push({ title, link, thumb, genre });
    });

    res.json({ query: q, results });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mencari anime', detail: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 6: Home genres (diambil langsung dari halaman genre)
//  GET /api/home
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/home', async (req, res) => {
  try {
    const genres = [
      { key: 'action',   url: 'https://otakudesu.blog/genres/action/' },
      { key: 'romance',  url: 'https://otakudesu.blog/genres/romance/' },
      { key: 'comedy',   url: 'https://otakudesu.blog/genres/comedy/' },
      { key: 'fantasy',  url: 'https://otakudesu.blog/genres/fantasy/' },
      { key: 'school',   url: 'https://otakudesu.blog/genres/school/' },
      { key: 'isekai',   url: 'https://otakudesu.blog/genres/isekai/' },
      { key: 'adventure',url: 'https://otakudesu.blog/genres/adventure/' },
      { key: 'horror',   url: 'https://otakudesu.blog/genres/horror/' },
      { key: 'sci-fi',   url: 'https://otakudesu.blog/genres/sci-fi/' },
      { key: 'mystery',  url: 'https://otakudesu.blog/genres/mystery/' }
    ];

    const result = {};

    const promises = genres.map(async (genre) => {
      const data = await scrapeGenre(genre.url);
      result[genre.key] = data;
    });

    await Promise.all(promises);

    res.json(result);

  } catch (err) {
    res.status(500).json({
      error: err.message
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 7: Tes fungsi scrapeGenres (sementara)
//  GET /api/testgenre
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/testgenre', async (req, res) => {
  try {
    const genres = await scrapeGenres(
      'https://otakudesu.blog/anime/liar-game-sub-indo/'
    );

    res.json(genres);

  } catch (err) {
    res.status(500).json({
      error: err.message
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT 8: Jadwal rilis (testing)
//  GET /api/schedule
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/schedule', async (req, res) => {
  try {
    const html = await fetchHTML(
      'https://otakudesu.blog/jadwal-rilis/'
    );

   const $ = cheerio.load(html);

    res.json({
      success: true
    });

  } catch(err) {
    res.status(500).json({
      error: err.message
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT DEBUG: Uji Puppeteer
//  GET /api/test-puppeteer?url=https://...
// ─────────────────────────────────────────────────────────────────────────────
app.get("/api/test-puppeteer", async (req, res) => {
  if (!isDev) return res.status(403).json({ error: 'Debug endpoint tidak tersedia di production' });
  
  const { url } = req.query;
  if (!url) return res.status(400).json({ error: "Parameter url wajib" });

  const video = await resolveIframeVideo(url);
  res.json({
    success: !!video,
    video
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT DEBUG 1: Ekstrak video dari iframe URL
//  GET /api/debug/extract-from-iframe?iframeUrl=...
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/debug/extract-from-iframe', async (req, res) => {
  if (!isDev) return res.status(403).json({ error: 'Debug endpoint tidak tersedia di production' });
  
  const { iframeUrl } = req.query;
  
  if (!iframeUrl) {
    return res.status(400).json({ error: 'Parameter iframeUrl wajib' });
  }

  try {
    console.log("\n🔍 DEBUG: Extracting from iframe:", iframeUrl);
    
    const embedHtml = await fetchHTML(
      iframeUrl,
      { Referer: 'https://otakudesu.blog/' },
      false
    );

    console.log("📄 Embed HTML length:", embedHtml.length);
    console.log("🔎 First 1000 chars:", embedHtml.substring(0, 1000));

    const videoUrl = extractVideoUrl(embedHtml);

    console.log("🎥 Extracted Video URL:", videoUrl || 'NOT FOUND');

    res.json({
      iframeUrl,
      embedHtmlLength: embedHtml.length,
      videoUrlFound: !!videoUrl,
      videoUrl: videoUrl,
      embedHtmlSnippet: embedHtml.substring(0, 500),
    });

  } catch (err) {
    res.status(500).json({
      error: err.message,
      iframeUrl
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT DEBUG 2: Validasi video URL (DIPERBARUI DENGAN LOGGING LEBIH DETAIL)
//  GET /api/debug/validate-video-url?videoUrl=...
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/debug/validate-video-url', async (req, res) => {
  if (!isDev) return res.status(403).json({ error: 'Debug endpoint tidak tersedia di production' });
  
  const { videoUrl } = req.query;
  
  if (!videoUrl) {
    return res.status(400).json({ error: 'Parameter videoUrl wajib' });
  }

  try {
    console.log("\n✅ Validating video URL:", videoUrl);

    const head = await axios.head(videoUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
        'Referer': 'https://otakudesu.blog/'
      },
      validateStatus: () => true,
      maxRedirects: 5,
      timeout: 10000,
    });

    console.log("STATUS :", head.status);
    console.log("CONTENT TYPE :", head.headers["content-type"]);
    console.log("CONTENT DISPOSITION :", head.headers["content-disposition"]);
    console.log("ACCEPT RANGES :", head.headers["accept-ranges"]);

    res.json({
      videoUrl,
      isValid: head.status === 200,
      httpStatus: head.status,
      contentType: head.headers['content-type'],
      contentLength: head.headers['content-length'],
    });

  } catch (err) {
    res.status(500).json({
      error: err.message,
      videoUrl
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  ENDPOINT BARU: Proxy video
//  GET /api/video?url=...
// ─────────────────────────────────────────────────────────────────────────────
app.get("/api/video", async (req, res) => {

    const { url } = req.query;

    if (!url) {
        return res.status(400).send("Missing url");
    }

    try {
        const response = await axios.get(url, {
            responseType: "stream",
            headers: {
                "Referer": "https://desustream.info/",
                "User-Agent": "Mozilla/5.0"
            }
        });

        res.setHeader(
            "Content-Type",
            response.headers["content-type"] || "video/mp4"
        );

        res.setHeader(
            "Content-Length",
            response.headers["content-length"] || ""
        );

        res.setHeader(
            "Accept-Ranges",
            "bytes"
        );

        response.data.pipe(res);

    } catch (e) {
        console.log(e.message);
        res.status(500).send(e.message);
    }
});

// ── Root ──────────────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/api/test', (req, res) => {
  res.json({
    status: 'ok'
  });
});

app.listen(PORT, () => {
  // Server started silently
});