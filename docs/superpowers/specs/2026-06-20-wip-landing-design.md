# WIP Landing Page — Design Spec
**Date:** 2026-06-20
**Status:** Approved

## Overview

A Docker-containerized "Work in Progress" landing page used as a fallback across multiple products while their real websites are in development. Static HTML + CSS served by nginx, with runtime-configurable text injected via environment variables.

---

## Architecture

**Stack:** Pure static HTML/CSS + nginx:alpine. No build toolchain, no Node.js, no framework.

**Runtime text injection:** `envsubst` runs at container startup, substituting env var placeholders in `index.html.template` before nginx starts. Defaults are set in `entrypoint.sh`.

**Deployment model:** Container exposes HTTP on port 80. TLS termination handled upstream by a reverse proxy (nginx, Traefik, Caddy, etc.).

---

## File Structure

```
wip-landing-page/
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
├── entrypoint.sh
├── README.md
├── CLAUDE.md
├── html/
│   └── index.html.template
└── .github/
    └── workflows/
        └── publish.yml
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WIP_TITLE` | `Work in Progress` | Main headline displayed on page |
| `WIP_SUBTITLE` | `This website will be available soon.` | Secondary message below title |

---

## Visual Design

Follows Gemini AI visual design language (https://design.google/library/gemini-ai-visual-design).

**Background:** Near-black canvas (`#050505`).

**Gradient blobs:** 2–3 soft radial glow orbs in Google's four-color family:
- Blue `#4285F4`
- Red `#EA4335`
- Yellow `#FBBC04`
- Green `#34A853`

Each blob is a heavily blurred (`filter: blur(80px)`) circle at low opacity, positioned off-center. Creates the ambient "energy transfer" glow characteristic of Gemini — distinct soft orbs, not a flat gradient.

**SVG illustration:** Construction/work-zone motif. Built from circles and rounded shapes (Gemini's primary shape language). Two CSS animations:
- Slow radial pulse-expand (Gemini "pulsing gradient guiding attention")
- Subtle vertical float (3s ease-in-out infinite)

**Typography:**
- Font stack: `'Google Sans', Inter, system-ui, sans-serif`
- Title (`$WIP_TITLE`): large, bold, white
- Subtitle (`$WIP_SUBTITLE`): medium, `rgba(255,255,255,0.6)`, normal weight

**Accent bar:** thin horizontal multi-stop gradient line below title using the four Gemini colors (blue → red → yellow → green) — references the Google 4-dot signature.

**Shape language:** Rounded corners on all container elements, echoing Gemini's circle motif.

**Layout:** Fully centered vertically and horizontally. No nav, no footer. Single focal point.

---

## Docker Setup

### Dockerfile

```dockerfile
FROM nginx:alpine
RUN apk add --no-cache bash
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/index.html.template /tmp/index.html.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
```

### entrypoint.sh

```bash
#!/bin/bash
export WIP_TITLE="${WIP_TITLE:-Work in Progress}"
export WIP_SUBTITLE="${WIP_SUBTITLE:-This website will be available soon.}"
envsubst '$WIP_TITLE $WIP_SUBTITLE' \
  < /tmp/index.html.template \
  > /usr/share/nginx/html/index.html
exec nginx -g "daemon off;"
```

### nginx.conf

Minimal config: serve `/usr/share/nginx/html`, gzip enabled, `server_tokens off`, port 80. No default.conf overhead.

### docker-compose.yml

Local dev shortcut. Maps host `8080` → container `80`. Sets example env vars for local testing.

---

## GitHub Workflow

File: `.github/workflows/publish.yml`

Mirrors `inll-booking` pattern exactly:

- **Trigger:** `workflow_dispatch` with `bump` input (choices: `patch`, `minor`, `major`, `latest`)
- **`compute-version` job:** Reads latest GitHub release tag, computes next semver. If no releases exist, starts at `0.0.1` / `0.1.0` / `1.0.0` depending on bump level. `latest` tag bypasses semver.
- **`publish` job:** Multi-arch build (`linux/amd64`, `linux/arm64`) via Docker Buildx + QEMU. Pushes to `ghcr.io/${{ github.repository }}`. Uses GHA layer cache.
- **`release` job:** Creates GitHub release with auto-generated notes. Skips if tag already exists. Skips entirely when bump is `latest`.
- **Auth:** `GITHUB_TOKEN` only — no external secrets needed.

---

## Generation Notes

Page HTML will be generated using MCP Google Stitch (already configured), then adapted to `index.html.template` format with `$WIP_TITLE` / `$WIP_SUBTITLE` placeholders.

---

## README Contents

- Project purpose
- Env var table
- `docker run` example with env var overrides
- `docker-compose up` for local dev
- Link to GitHub workflow for publishing

## CLAUDE.md Contents

- Dev commands (`docker build`, `docker-compose up`, local test URL)
- Architecture summary (envsubst flow)
- How to update the visual design (edit `html/index.html.template`)
