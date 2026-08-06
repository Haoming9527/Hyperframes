# HyperFrames local kit

Make video with **HyperFrames** + **Devin**: skills guide the agent; the CLI checks and renders HTML → MP4.

**CMD only** (no PowerShell). Devin must follow [`AGENTS.md`](AGENTS.md).

---

## Check env first

Open [`.env.example`](.env.example) and confirm the paths. **HyperFrames does not load `.env` automatically** — copy those values into CMD with `set` each session (below), then run `doctor`.

---

## Setup (CMD, every session)

From the repo root:

```bat
set "HYPERFRAMES_BROWSER_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "PRODUCER_HEADLESS_SHELL_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "HYPERFRAMES_FFMPEG_PATH=%CD%\vendor\ffmpeg\bin\ffmpeg.exe"
set "HYPERFRAMES_FFPROBE_PATH=%CD%\vendor\ffmpeg\bin\ffprobe.exe"
set HYPERFRAMES_NO_TELEMETRY=1
set HYPERFRAMES_SKIP_SKILLS=1
```

```bat
npx hyperframes doctor
```

---

## Use with Devin

1. Read `AGENTS.md`
2. Read `.skills/hyperframes/skills/hyperframes/SKILL.md` (**router** — always first)
3. Follow the matching skill under `.skills/hyperframes/skills/<name>/`
4. Use the CLI below (`npx hyperframes …` against this repo’s `node_modules` — no registry download)

**Example:**  
> Follow AGENTS.md and `faceless-explainer`. Topic: *[one sentence]*. Build, `check`, `render`. Deliver HTML + MP4.

---

## Router

| Skill | Use when |
|-------|----------|
| `/hyperframes` | **Read first** for any request to make / create / edit / animate / render a video, animation, or motion graphic. Capability map for domain skills, intent layer for every creation brief, and router for the workflows below. |

Skill files: `.skills/hyperframes/skills/<name>/SKILL.md` (folder name without the leading `/`).

### Creation workflows

| Skill | Use when |
|-------|----------|
| `/product-launch-video` | Any website — marketing / launching / promoting a product (URL, brief, or script), or a site tour / showcase / social clip from the site’s own visuals. Up to ~3 min (sweet spot 30–90s). |
| `/faceless-explainer` | Explain a topic from text — no product, no URL, no website capture; visuals are invented (typography / abstract / diagram / data-viz). |
| `/pr-to-video` | A GitHub PR (URL, `owner/repo#N`, or “this PR”) → changelog / feature-reveal / fix / refactor explainer (needs `gh` + PR access). |
| `/embedded-captions` | Captions / subtitles on an existing talking-head video (footage untouched). |
| `/talking-head-recut` | Package talking-head / interview / podcast footage with graphic overlays — lower-thirds, callouts, kinetic titles, quotes, side panels, PiP. |
| `/motion-graphics` | Short unnarrated motion (~under 10s) — kinetic type, stat / chart, logo sting, lower-third, animated headline. MP4 or transparent overlay. |
| `/music-to-video` | Music track → beat-synced video (lyric / slideshow / kinetic promo). |
| `/slideshow` | Pitch / interactive deck — slides, fragments, branching, presenter mode. **Deck, not MP4.** |
| `/general-video` | Anything else — longer / multi-scene, sizzle, title card, static loop, freeform. Fallback + companion mode. |
| `/remotion-to-hyperframes` | Port an existing Remotion (React) composition to HyperFrames HTML (migration, not creation). |

### Domain skills (load on demand)

| Skill | Covers |
|-------|--------|
| `/hyperframes-core` | Composition contract — `data-*` timing, `class="clip"`, tracks, sub-compositions, variables, media playback, determinism. |
| `/hyperframes-animation` | Motion rules, scene blueprints, transitions, runtimes (GSAP / Lottie / Three.js / Anime.js / CSS / WAAPI / TypeGPU). |
| `/hyperframes-keyframes` | Seek-safe keyframes across runtimes + `hyperframes keyframes` diagnostics. |
| `/hyperframes-creative` | Design direction — `frame.md` / `design.md`, palettes, type, narration, beats, audio-reactive. |
| `/media-use` | Media OS — BGM / SFX / image / icon / logo / voice / grade; TTS/music/image when needed; transcribe, caption, background removal. |
| `/hyperframes-cli` | CLI loop — init, lint, check, snapshot, preview, render, doctor (+ cloud / lambda when networked). |
| `/hyperframes-registry` | Install / wire registry blocks via `hyperframes add`. |
| `/figma` | Import Figma assets / tokens / storyboards into a composition (needs Figma access). |

---

## How much can you use locally?

This kit is **local**. Skills files are all present; **runtime** depends on tools on the PC.

| Works well locally | Limited / needs extra |
|--------------------|------------------------|
| `/faceless-explainer`, `/motion-graphics`, `/general-video`, `/slideshow` | `/product-launch-video` site crawl (no live URL capture without network) |
| `/embedded-captions`, `/talking-head-recut` (with local Whisper if installed) | `/pr-to-video` (needs `gh` + GitHub) |
| Author HTML → `check` → `preview` → `render` | `/figma` (needs Figma API / MCP) |
| `/hyperframes-core`, `-animation`, `-keyframes`, `-creative`, `-cli` | `/media-use` online catalogs / cloud TTS (local assets still fine) |
| `/music-to-video` if the audio file is already in the repo | `cloud render` / `lambda` / `publish` (not for this kit) |
| `/remotion-to-hyperframes` if Remotion source is in-repo | Fresh `npm install` from the registry / GitHub skill updates |

**Practical default for Devin here:** router → `faceless-explainer` / `motion-graphics` / `general-video` / `embedded-captions` / `slideshow`, then local `check` + `render`.

---

## CLI

Node and **npm/`npx` are fine**. This kit already has `hyperframes` in `node_modules`, so `npx hyperframes` runs **locally** and does not need GitHub or the public registry.

Do **not** run a fresh `npm install` that would fetch packages, and do not download Chromium / skill updates.

### Everyday commands

```bat
npx hyperframes doctor
npx hyperframes check
npx hyperframes preview
npx hyperframes render
```

```bat
npx hyperframes init my-video
cd my-video
npx hyperframes preview
npx hyperframes render
```

| Command | What it does |
|---------|----------------|
| `doctor` | Node / Chrome / FFmpeg OK? |
| `init` | Scaffold a project folder |
| `check` | Validate the composition |
| `preview` | Watch in the browser with live reload (`Ctrl+C` to stop) |
| `render` | Export MP4 |

```bat
npx hyperframes --help
npx hyperframes render --help
```

### Fallback (if `npx` misbehaves)

```bat
node node_modules\hyperframes\bin\hyperframes.mjs doctor
node node_modules\hyperframes\bin\hyperframes.mjs preview
node node_modules\hyperframes\bin\hyperframes.mjs render
```

---

## What’s in the kit

| Path | Role |
|------|------|
| `.skills/hyperframes/skills/` | All skills above |
| `node_modules/hyperframes/` | CLI (what `npx hyperframes` uses) |
| `vendor/ffmpeg/bin/` | FFmpeg + ffprobe |
| `AGENTS.md` | Rules for Devin |
| `.env.example` | Env template — check yourself |

Needs on the PC: **Node.js**, **npm**, and **Chrome**.

---

## Notes

- Local Chrome via env — don’t download Chromium.
- Keep media and fonts in the repo.
- No cloud render / no registry installs in this kit.

HyperFrames CLI **0.7.94**.
