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
