# HyperFrames: Agent-Native Video Composition — Research Note

**Document type:** Research overview  
**Subject:** HyperFrames local composition & render stack; integration with Devin  
**Status:** Exploratory  

---

## 1. Introduction

HyperFrames is an open-source framework for producing video from **HTML**. A composition is a web document whose layout, typography, and motion are declared in the DOM (including timing via `data-*` attributes) and whose animation runtimes are seekable. The framework owns media playback and provides a CLI to validate, preview, and **render deterministic MP4** (or related formats) using a headless browser capture path plus FFmpeg.

This matters for agent-assisted engineering because the deliverable is **code and files in a repository**—HTML, assets, configs—rather than an opaque binary timeline. Coding agents such as **Devin** already operate on that surface: read instructions, edit files, run commands, open reviews. HyperFrames therefore sits naturally in an agent loop: skills (markdown playbooks) encode *how* to build a piece of video; the agent authors the composition; the CLI produces the artefact humans can review.

This note summarises HyperFrames’ distinctive features, the pain points it addresses, concrete use cases, and recommended next research steps—including how to integrate HyperFrames into a Devin-centred workflow on a **local** toolkit (Node/npm, vendored CLI, system Chrome, local FFmpeg; no dependency on cloud render for the core path).

---

## 2. Key Features

### 2.1 HTML as the timeline

Compositions are standard HTML/CSS/JS structured for video export. Timing, clips, tracks, and sub-compositions follow a documented contract. Motion can use established web runtimes (notably GSAP, with support surfaces for CSS, Lottie, Three.js, and others) under the requirement that timelines remain **seek-safe** for frame-accurate capture.

### 2.2 Deterministic local render

The CLI drives a local render pipeline: Chromium/Chrome for frame capture, FFmpeg for encode. The same project can be linted and gate-checked (`check`) before preview or render, which reduces silent failures in agent-authored HTML.

### 2.3 Skill-oriented agent workflows

HyperFrames ships a catalog of **skills**—structured instructions for agents—organised as:

| Layer | Role |
|-------|------|
| **Router** (`/hyperframes`) | First read for “make / edit / render video”; routes intent to a creation workflow |
| **Creation workflows** | End-to-end recipes (e.g. faceless explainers, embedded captions, motion graphics, slideshows, music-to-video, general video) |
| **Domain skills** | On-demand depth (composition contract, animation, keyframes, creative direction, media, CLI, registry) |

Agents do not invent the whole pipeline from scratch; they follow a pinned playbook and produce reviewable diffs.

### 2.4 Local kit posture

For environments where outbound package registries or SaaS render endpoints are restricted, HyperFrames can still be used when:

- the **CLI and dependencies** are pre-vendored (`node_modules`);
- **FFmpeg** is available locally;
- **Chrome** on the machine is pointed at via environment variables;
- **skills** are present on disk under a known path.

Node and `npx` remain usable against the local install; fresh registry installs and cloud features are optional, not required for basic HTML → MP4.

### 2.5 Fit with Devin’s operating model

Devin’s strengths—repository understanding, multi-step coding, CLI execution, PR-style delivery—map cleanly onto HyperFrames:

| Devin capability | HyperFrames counterpart |
|------------------|-------------------------|
| Read project docs / skills | `AGENTS.md` + `.skills/.../SKILL.md` |
| Edit source | Composition HTML, styles, assets |
| Run tools | `npx hyperframes doctor \| check \| preview \| render` |
| Deliver for review | Diff + MP4 artefact |

Integration is primarily **procedural and documentary**, not a proprietary Devin plugin: pin skills and agent rules in-repo; require env setup for Chrome/FFmpeg; constrain the agent away from network installs and cloud render when operating locally.

---

## 3. Pain Points and Use-Case Description

### 3.1 Pain points

**Opaque generative video.** Text-to-video models produce clips quickly but are difficult to surgically edit, version, brand-constrain, or regenerate with small, intentional changes.

**Tooling mismatch for agents.** Traditional NLEs and motion tools are UI-centric. Coding agents are file- and CLI-centric. Bridging those worlds usually means human operators, not autonomous loops.

**Controllability and review.** Organisations that need inspectable pipelines prefer artefacts that can be diffed, gated in CI-style checks, and rendered repeatedly with the same inputs.

**Local operational constraints.** Where external GitHub/npm/SaaS calls are limited, video tooling must still run with pre-bundled binaries and system browsers—or it will not land in practice.

### 3.2 Use cases (research-relevant)

| Use case | HyperFrames angle | Devin role |
|----------|-------------------|------------|
| **Faceless explainers** | Typography / diagram-led short videos from a brief | Follow `/faceless-explainer`; author HTML; `check` + `render` |
| **Captioned talking-head** | Captions composited onto existing footage | Follow `/embedded-captions` (Whisper optional locally) |
| **Graphic packaging** | Lower-thirds, callouts, titles over interview footage | Follow `/talking-head-recut` |
| **Short motion hits** | Logo stings, stat beats, kinetic type (~under 10s) | Follow `/motion-graphics` |
| **Internal decks** | Navigable slideshow (not necessarily MP4) | Follow `/slideshow` |
| **Custom / longer pieces** | Multi-scene brand or research demos | Follow `/general-video` |

**Illustrative Devin brief:**  
*“Follow `AGENTS.md` and the `faceless-explainer` skill. Topic: [one sentence]. Build a HyperFrames composition, run `npx hyperframes check`, then `npx hyperframes render`. Deliver HTML + MP4.”*

### 3.3 Integrating HyperFrames into Devin

Recommended integration pattern:

1. **Repository contract** — Commit (or ship alongside) skills, `AGENTS.md`, `.env.example`, and vendored CLI/FFmpeg as needed for the target machine.  
2. **Session environment** — Devin (or the operator) sets Chrome and FFmpeg paths in CMD before CLI use; HyperFrames does not auto-load `.env`.  
3. **Skill routing** — Devin always opens `/hyperframes` first, then the selected creation workflow.  
4. **Execution loop** — Edit composition → `npx hyperframes check` → optional `preview` → `npx hyperframes render`.  
5. **Human gate** — Review PR or folder containing HTML + MP4; iterate by re-tasking Devin with skill constraints.  
6. **Guardrails** — No browser re-download, no registry reinstall, no cloud render for the local research path; prefer in-repo fonts and media.

This treats Devin as the **orchestration layer** and HyperFrames as the **video compile toolchain**, analogous to “agent writes code → compiler/toolchain produces binary,” with MP4 as the build product.

---

## 4. Summary and Next Steps in Research

### 4.1 Summary

HyperFrames reframes video production as an **HTML composition + local render** problem. Combined with Devin, it enables an agent-native loop: skills provide procedure; the agent produces editable source; the CLI emits reviewable MP4. The approach addresses pain around opacity of generative video, agent/tooling mismatch, and the need for controllable, local-first pipelines—without requiring HyperFrames cloud features for a minimum viable path.

### 4.2 Next steps

| Step | Objective | Success signal |
|------|-----------|----------------|
| **1. Environment baseline** | Confirm `doctor` green on the target PC (Node, npm, Chrome, FFmpeg, env vars) | Documented baseline checklist passed |
| **2. Controlled Devin spike** | Two tasks: one `/faceless-explainer`, one `/embedded-captions` or `/motion-graphics` | MP4s delivered with passing `check`; human repair time recorded |
| **3. Quality rubric** | Score brand fit, editability (time-to-revise via Devin), and failure modes | Written rubric + scored runs |
| **4. Skill adherence study** | Measure how often Devin follows router/workflow vs. improvises | Diff against skill steps; refine `AGENTS.md` |
| **5. Scope decision** | Adopt for prototype/research demos, park, or compare (e.g. Remotion) | Short decision memo |
| **6. Optional depth** | Local Whisper for captions; asset conventions; CI `check` on compositions | Capability note if pursued |

### 4.3 Out of scope for early spikes

Live website crawl for product-launch capture, Figma API import, GitHub PR ingestion, cloud/Lambda render, and registry-backed `npm install` from the public network—unless those dependencies are deliberately enabled in a later phase.

---

## References (local kit)

- HyperFrames skills: `.skills/hyperframes/skills/`  
- Agent rules: `AGENTS.md`  
- Operator guide: `README.md`  
- Env template: `.env.example`  
- Upstream project: [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)  

