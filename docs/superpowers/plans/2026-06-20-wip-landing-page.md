# WIP Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Docker-containerized "Work in Progress" landing page with Gemini AI visual design, runtime-configurable text via env vars, and a GitHub Actions workflow to publish the image to GHCR.

**Architecture:** Static HTML/CSS template served by nginx:alpine. At container startup, `entrypoint.sh` runs `envsubst` to inject `$WIP_TITLE` and `$WIP_SUBTITLE` into `index.html.template`, writing the final `index.html` before nginx starts. No build toolchain — final image ~15MB.

**Tech Stack:** nginx:alpine, bash (envsubst), Docker Buildx (multi-arch), GitHub Actions, MCP Google Stitch (page generation)

## Global Constraints

- nginx:alpine base image — no Node.js, no Python, no build tools in final image
- `WIP_TITLE` default: `Work in Progress`
- `WIP_SUBTITLE` default: `This website will be available soon.`
- Multi-arch build: `linux/amd64` and `linux/arm64`
- Registry: `ghcr.io/${{ github.repository }}`
- Container exposes HTTP port 80 only — no TLS
- Font stack: `'Google Sans', Inter, system-ui, sans-serif`
- Gemini colors: blue `#4285F4`, red `#EA4335`, yellow `#FBBC04`, green `#34A853`
- Background: `#050505`
- No CDN dependencies — all assets inline

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `nginx.conf` | Create | Minimal nginx config, gzip, no server_tokens |
| `entrypoint.sh` | Create | Set defaults, run envsubst, exec nginx |
| `html/index.html.template` | Create | Page HTML with `$WIP_TITLE`/`$WIP_SUBTITLE` placeholders |
| `Dockerfile` | Create | nginx:alpine + copy files + set entrypoint |
| `docker-compose.yml` | Create | Local dev: port 8080→80, example env vars |
| `.github/workflows/publish.yml` | Create | Semver compute + multi-arch build + GHCR push + release |
| `README.md` | Create | Usage, env vars table, docker run/compose examples |
| `CLAUDE.md` | Create | Dev commands, architecture notes |

---

### Task 1: nginx config + entrypoint.sh

**Files:**
- Create: `nginx.conf`
- Create: `entrypoint.sh`

**Interfaces:**
- Produces: `entrypoint.sh` — reads `$WIP_TITLE`, `$WIP_SUBTITLE` from env; calls `envsubst` on `/tmp/index.html.template` → `/usr/share/nginx/html/index.html`; execs `nginx -g "daemon off;"`

- [ ] **Step 1: Create nginx.conf**

```nginx
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    server_tokens off;
    gzip          on;
    gzip_types    text/html text/css application/javascript image/svg+xml;

    server {
        listen 80;
        root  /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
```

Save as `nginx.conf` at repo root.

- [ ] **Step 2: Create entrypoint.sh**

```bash
#!/bin/bash
set -e

export WIP_TITLE="${WIP_TITLE:-Work in Progress}"
export WIP_SUBTITLE="${WIP_SUBTITLE:-This website will be available soon.}"

envsubst '$WIP_TITLE $WIP_SUBTITLE' \
  < /tmp/index.html.template \
  > /usr/share/nginx/html/index.html

exec nginx -g "daemon off;"
```

Save as `entrypoint.sh` at repo root.

- [ ] **Step 3: Verify envsubst substitution logic manually**

```bash
export WIP_TITLE="Test Title"
export WIP_SUBTITLE="Test Subtitle"
echo '<h1>$WIP_TITLE</h1><p>$WIP_SUBTITLE</p>' | envsubst '$WIP_TITLE $WIP_SUBTITLE'
```

Expected output:
```
<h1>Test Title</h1><p>Test Subtitle</p>
```

- [ ] **Step 4: Commit**

```bash
git add nginx.conf entrypoint.sh
git commit -m "feat: add nginx config and container entrypoint"
```

---

### Task 2: Generate HTML page via MCP Stitch → html/index.html.template

**Files:**
- Create: `html/index.html.template`

**Interfaces:**
- Consumes: Gemini design spec (colors, blobs, SVG, typography from Global Constraints)
- Produces: `html/index.html.template` — complete self-contained HTML file with `$WIP_TITLE` and `$WIP_SUBTITLE` as literal envsubst placeholders (not filled values)

- [ ] **Step 1: Create html/ directory**

```bash
mkdir -p html
```

- [ ] **Step 2: Generate page via MCP Stitch**

Use the `mcp__stitch__create_project` tool followed by `mcp__stitch__generate_screen_from_text` with this prompt:

```
Design a "Work in Progress" landing page with Gemini AI visual design language.

Requirements:
- Dark background: #050505
- 2-3 soft radial gradient glow blobs (heavily blurred, blur(80px), opacity 0.15) positioned off-center using Google's four colors: blue #4285F4, red #EA4335, yellow #FBBC04, green #34A853
- Centered layout (flex, min-height 100vh)
- SVG illustration (~200px) using a hard-hat / construction / work-zone motif built from circles and rounded shapes in the Google four colors. Include a slow float animation (translateY, 3s ease-in-out infinite) and a pulse-ring animation on an outer circle.
- Large bold white headline: $WIP_TITLE (this must be the literal string "$WIP_TITLE" as a placeholder)
- A thin 3px horizontal gradient accent bar below headline: linear-gradient(90deg, #4285F4, #EA4335, #FBBC04, #34A853)
- Subtitle paragraph: $WIP_SUBTITLE (literal placeholder string)
- Font: 'Google Sans', Inter, system-ui, sans-serif
- No external CDN dependencies — all CSS inline in <style>, SVG inline in HTML
- Fully self-contained single HTML file
```

- [ ] **Step 3: Retrieve generated HTML from Stitch**

Use `mcp__stitch__get_screen` to retrieve the generated HTML content.

- [ ] **Step 4: Adapt output to template**

Take the Stitch-generated HTML and:
1. Ensure the title text is the literal string `$WIP_TITLE` (not substituted)
2. Ensure the subtitle text is the literal string `$WIP_SUBTITLE` (not substituted)
3. Set `<title>$WIP_TITLE</title>` in the `<head>`
4. Verify no external URLs (Google Fonts CDN, etc.) — if any exist, remove them and use the font-stack fallback instead
5. Save the result as `html/index.html.template`

If Stitch is unavailable, use this fallback template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$WIP_TITLE</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      min-height: 100vh;
      background: #050505;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'Google Sans', Inter, system-ui, sans-serif;
      overflow: hidden;
      position: relative;
    }

    .blob {
      position: fixed;
      border-radius: 50%;
      filter: blur(80px);
      opacity: 0.15;
      pointer-events: none;
    }
    .blob-blue  { width: 600px; height: 600px; background: #4285F4; top: -150px; left: -200px; }
    .blob-red   { width: 400px; height: 400px; background: #EA4335; bottom: -100px; right: -100px; }
    .blob-yellow{ width: 300px; height: 300px; background: #FBBC04; bottom: 80px; left: 80px; opacity: 0.1; }

    .container {
      text-align: center;
      z-index: 1;
      padding: 2rem;
      max-width: 600px;
    }

    .illustration {
      width: 200px;
      height: 200px;
      margin: 0 auto 2.5rem;
      animation: float 3s ease-in-out infinite;
    }

    @keyframes float {
      0%, 100% { transform: translateY(0px); }
      50%       { transform: translateY(-12px); }
    }

    @keyframes pulse-ring {
      0%   { transform: scale(0.9); opacity: 0.6; }
      100% { transform: scale(1.15); opacity: 0; }
    }

    .pulse-ring { animation: pulse-ring 2s ease-out infinite; transform-origin: center; }

    h1 {
      font-size: clamp(2rem, 5vw, 3.5rem);
      font-weight: 700;
      color: #ffffff;
      letter-spacing: -0.02em;
      line-height: 1.1;
      margin-bottom: 0.5rem;
    }

    .accent-bar {
      width: 80px;
      height: 3px;
      background: linear-gradient(90deg, #4285F4, #EA4335, #FBBC04, #34A853);
      border-radius: 2px;
      margin: 1rem auto 1.5rem;
    }

    p {
      font-size: clamp(1rem, 2.5vw, 1.2rem);
      color: rgba(255,255,255,0.6);
      line-height: 1.6;
    }
  </style>
</head>
<body>
  <div class="blob blob-blue"></div>
  <div class="blob blob-red"></div>
  <div class="blob blob-yellow"></div>

  <div class="container">
    <svg class="illustration" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
      <!-- Pulse ring -->
      <circle class="pulse-ring" cx="100" cy="100" r="90" stroke="#4285F4" stroke-width="2" fill="none" opacity="0.3"/>
      <!-- Outer circle -->
      <circle cx="100" cy="100" r="80" fill="#0d0d0d" stroke="#4285F4" stroke-width="1.5" opacity="0.4"/>
      <!-- Hard hat brim -->
      <ellipse cx="100" cy="98" rx="44" ry="10" fill="#F5A623"/>
      <!-- Hard hat dome -->
      <ellipse cx="100" cy="88" rx="32" ry="22" fill="#FBBC04"/>
      <!-- Hat highlight -->
      <ellipse cx="100" cy="84" rx="20" ry="8" fill="#FFD54F" opacity="0.5"/>
      <!-- Wrench handle -->
      <rect x="90" y="115" width="7" height="28" rx="3.5" fill="#34A853" transform="rotate(-25 90 115)"/>
      <!-- Wrench head -->
      <circle cx="85" cy="113" r="9" fill="none" stroke="#34A853" stroke-width="4"/>
      <!-- Gear outer -->
      <circle cx="120" cy="132" r="11" fill="none" stroke="#4285F4" stroke-width="3"/>
      <!-- Gear center -->
      <circle cx="120" cy="132" r="4" fill="#4285F4"/>
      <!-- Gear teeth -->
      <rect x="118" y="118" width="4" height="6" rx="1" fill="#4285F4"/>
      <rect x="118" y="140" width="4" height="6" rx="1" fill="#4285F4"/>
      <rect x="106" y="130" width="6" height="4" rx="1" fill="#4285F4"/>
      <rect x="128" y="130" width="6" height="4" rx="1" fill="#4285F4"/>
      <!-- Sparkle dots -->
      <circle cx="58" cy="68" r="4" fill="#EA4335" opacity="0.8"/>
      <circle cx="148" cy="63" r="3" fill="#34A853" opacity="0.8"/>
      <circle cx="158" cy="115" r="3" fill="#FBBC04" opacity="0.8"/>
      <circle cx="48" cy="130" r="3" fill="#4285F4"  opacity="0.8"/>
    </svg>

    <h1>$WIP_TITLE</h1>
    <div class="accent-bar"></div>
    <p>$WIP_SUBTITLE</p>
  </div>
</body>
</html>
```

- [ ] **Step 5: Verify placeholders are literal strings**

```bash
grep -c '\$WIP_TITLE\|\$WIP_SUBTITLE' html/index.html.template
```

Expected: `3` (title tag + h1 + p)

- [ ] **Step 6: Commit**

```bash
git add html/index.html.template
git commit -m "feat: add Gemini-styled WIP page template"
```

---

### Task 3: Dockerfile + build verification

**Files:**
- Create: `Dockerfile`

**Interfaces:**
- Consumes: `nginx.conf`, `html/index.html.template`, `entrypoint.sh` (all from prior tasks)
- Produces: Docker image `wip-landing-page:local` — nginx:alpine serving the WIP page

- [ ] **Step 1: Create Dockerfile**

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

- [ ] **Step 2: Build image locally**

```bash
docker build -t wip-landing-page:local .
```

Expected: build completes with no errors, final image listed.

- [ ] **Step 3: Verify image size**

```bash
docker image ls wip-landing-page:local --format "{{.Size}}"
```

Expected: under 30MB.

- [ ] **Step 4: Commit**

```bash
git add Dockerfile
git commit -m "feat: add Dockerfile"
```

---

### Task 4: docker-compose.yml + end-to-end smoke test

**Files:**
- Create: `docker-compose.yml`

**Interfaces:**
- Consumes: `wip-landing-page:local` image (built in Task 3)
- Produces: local dev shortcut — `docker compose up` → page reachable at `http://localhost:8080`

- [ ] **Step 1: Create docker-compose.yml**

```yaml
services:
  wip:
    build: .
    ports:
      - "8080:80"
    environment:
      WIP_TITLE: "My Product — Coming Soon"
      WIP_SUBTITLE: "We're building something amazing. Check back soon."
```

- [ ] **Step 2: Start container**

```bash
docker compose up -d
```

Expected: container starts, no errors in `docker compose logs`.

- [ ] **Step 3: Test default env vars**

Stop the compose stack, run with no env vars, verify defaults:

```bash
docker compose down
docker run --rm -d -p 8081:80 --name wip-test wip-landing-page:local
sleep 1
curl -s http://localhost:8081 | grep -c "Work in Progress"
```

Expected output: `1`

```bash
curl -s http://localhost:8081 | grep -c "This website will be available soon"
```

Expected output: `1`

```bash
docker stop wip-test
```

- [ ] **Step 4: Test custom env var override**

```bash
docker run --rm -d -p 8082:80 --name wip-custom \
  -e WIP_TITLE="Acme Corp — Coming Soon" \
  -e WIP_SUBTITLE="Launching Q3 2026." \
  wip-landing-page:local
sleep 1
curl -s http://localhost:8082 | grep -c "Acme Corp"
```

Expected output: `1`

```bash
curl -s http://localhost:8082 | grep -c "Launching Q3 2026"
```

Expected output: `1`

```bash
docker stop wip-custom
```

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml
git commit -m "feat: add docker-compose for local dev"
```

---

### Task 5: GitHub publish workflow

**Files:**
- Create: `.github/workflows/publish.yml`

**Interfaces:**
- Produces: manual `workflow_dispatch` workflow — computes semver, builds multi-arch image, pushes to `ghcr.io/<owner>/<repo>`, creates GitHub release

- [ ] **Step 1: Create .github/workflows/ directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Create publish.yml**

```yaml
name: Publish Docker Image

on:
  workflow_dispatch:
    inputs:
      bump:
        description: "Semver bump level"
        required: true
        default: "patch"
        type: choice
        options:
          - patch
          - minor
          - major
          - latest

env:
  REGISTRY: ghcr.io
  IMAGE: ghcr.io/${{ github.repository }}

jobs:
  compute-version:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      tag: ${{ steps.version.outputs.tag }}

    steps:
      - name: Compute next version
        id: version
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          if [ "${{ inputs.bump }}" = "latest" ]; then
            echo "tag=latest" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          LATEST=$(gh release list \
            --repo "$GITHUB_REPOSITORY" \
            --limit 1 \
            --json tagName \
            --jq '.[0].tagName // ""' 2>/dev/null || echo "")

          if [ -z "$LATEST" ]; then
            case "${{ inputs.bump }}" in
              major) NEXT="1.0.0" ;;
              minor) NEXT="0.1.0" ;;
              patch) NEXT="0.0.1" ;;
            esac
          else
            if [[ ! "$LATEST" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
              echo "ERROR: latest tag '$LATEST' is not valid semver" >&2
              exit 1
            fi
            MAJOR="${BASH_REMATCH[1]}"
            MINOR="${BASH_REMATCH[2]}"
            PATCH="${BASH_REMATCH[3]}"
            case "${{ inputs.bump }}" in
              major) NEXT="$((MAJOR + 1)).0.0" ;;
              minor) NEXT="${MAJOR}.$((MINOR + 1)).0" ;;
              patch) NEXT="${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
            esac
          fi

          echo "Computed next tag: $NEXT"
          echo "tag=$NEXT" >> "$GITHUB_OUTPUT"

  publish:
    runs-on: ubuntu-latest
    needs: compute-version
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.IMAGE }}
          tags: |
            type=raw,value=${{ needs.compute-version.outputs.tag }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  release:
    runs-on: ubuntu-latest
    needs: [compute-version, publish]
    if: needs.compute-version.outputs.tag != 'latest'
    permissions:
      contents: write

    env:
      TAG: ${{ needs.compute-version.outputs.tag }}
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Create GitHub release
        run: |
          if gh release view "$TAG" &>/dev/null; then
            echo "Release $TAG already exists — skipping."
          else
            gh release create "$TAG" \
              --title "$TAG" \
              --generate-notes
          fi
```

- [ ] **Step 3: Validate YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/publish.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/publish.yml
git commit -m "feat: add GitHub Actions workflow for GHCR publish"
```

---

### Task 6: README.md + CLAUDE.md

**Files:**
- Create: `README.md`
- Create: `CLAUDE.md`

- [ ] **Step 1: Create README.md**

```markdown
# wip-landing-page

A Docker-containerized "Work in Progress" landing page with Gemini AI visual design. Used as a fallback page across multiple products while real websites are in development.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WIP_TITLE` | `Work in Progress` | Main headline |
| `WIP_SUBTITLE` | `This website will be available soon.` | Secondary message |

## Usage

### Docker run

```bash
docker run -d -p 80:80 \
  -e WIP_TITLE="My Product — Coming Soon" \
  -e WIP_SUBTITLE="Launching soon. Stay tuned." \
  ghcr.io/<owner>/wip-landing-page:latest
```

### docker-compose (local dev)

```bash
docker compose up
```

Page available at http://localhost:8080

## Publishing

Trigger the **Publish Docker Image** workflow from GitHub Actions → choose a semver bump level (`patch`, `minor`, `major`) or `latest`. Image is pushed to `ghcr.io/<owner>/wip-landing-page`.
```

- [ ] **Step 2: Create CLAUDE.md**

```markdown
# CLAUDE.md

## Dev Commands

```bash
docker build -t wip-landing-page:local .   # build image
docker compose up                           # start local dev (http://localhost:8080)
docker compose down                         # stop
```

## Architecture

Static HTML + CSS served by nginx:alpine. No build step.

At container start, `entrypoint.sh` runs `envsubst` on `html/index.html.template`, substituting `$WIP_TITLE` and `$WIP_SUBTITLE`, and writes the result to `/usr/share/nginx/html/index.html`. Then nginx starts.

## Updating the Page

Edit `html/index.html.template`. The only dynamic parts are the literal strings `$WIP_TITLE` and `$WIP_SUBTITLE` — these are replaced at container startup by envsubst. Do not use other `$VAR` patterns in the template unless you add them to the envsubst call in `entrypoint.sh`.

## Publishing

Run the **Publish Docker Image** GitHub Actions workflow with a semver bump. Pushes multi-arch image to GHCR and creates a GitHub release.
```

- [ ] **Step 3: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: add README and CLAUDE.md"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|-----------------|------|
| Centered text configurable via env vars with defaults | Task 2 (template), Task 4 (smoke test) |
| Gemini visual design — dark bg, gradient blobs, SVG, colors | Task 2 |
| SVG construction illustration with animation | Task 2 |
| Docker container (nginx:alpine + envsubst) | Tasks 1, 3 |
| docker-compose for local dev | Task 4 |
| GitHub workflow (matches inll-booking pattern) | Task 5 |
| Multi-arch (amd64 + arm64) | Task 5 |
| Push to GHCR | Task 5 |
| Semver + GitHub release | Task 5 |
| README | Task 6 |
| CLAUDE.md | Task 6 |
| No external CDN deps | Task 2 (global constraint + placeholder check) |

All requirements covered. No placeholders. No type inconsistencies (no shared types — static project).
