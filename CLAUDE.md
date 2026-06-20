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
