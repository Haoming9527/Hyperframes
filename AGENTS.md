# HyperFrames — Devin

**CMD only** — no PowerShell.

Node / npm / `npx` are OK. Package is already in `node_modules` — do **not** `npm install` from the registry, skill updates, upgrades, or `browser ensure`.

## Skills

`.skills/hyperframes/skills/` — start with `hyperframes/SKILL.md`, then the workflow you need.

## Env (see `.env.example` — then `set` in CMD; not auto-loaded)

```bat
set "HYPERFRAMES_BROWSER_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "PRODUCER_HEADLESS_SHELL_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "HYPERFRAMES_FFMPEG_PATH=%CD%\vendor\ffmpeg\bin\ffmpeg.exe"
set "HYPERFRAMES_FFPROBE_PATH=%CD%\vendor\ffmpeg\bin\ffprobe.exe"
set HYPERFRAMES_NO_TELEMETRY=1
set HYPERFRAMES_SKIP_SKILLS=1
```

Use system Chrome only.

## CLI

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

## Rules

1. Local assets / fonts — no CDN.
2. `check` before done.
3. Deliver HTML + MP4 when asked for video.
