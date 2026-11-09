# setup-ssqch

A GitHub Action that installs a prebuilt [SiteSquatch](https://github.com/reverentgeek/sitesquatch) (`ssqch`), the static site generator, and adds it to the `PATH`. It downloads the release archive for the runner, checks it against the release's SHA-256 checksum, and keeps it in the runner's tool cache.

```yaml
- uses: reverentgeek/setup-ssqch@v1
  with:
    version: 0.3.0
- run: ssqch build
```

Pin a `version` so a new ssqch release can't change your build. Leave it out (or use `latest`) to install the newest release.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `version` | `latest` | The ssqch version to install, like `0.3.0` (a leading `v` is fine). |
| `token` | `github.token` | A GitHub token, used only to look up the latest release without hitting the API rate limit. |

## Outputs

| Output | Description |
| --- | --- |
| `version` | The version that was installed, like `0.3.0`. |
| `path` | The folder that holds the `ssqch` binary. |

## Runners

Linux x86_64 (a static binary, so any distro), macOS on Apple silicon and Intel (signed and notarized), and Windows x86_64. Other platforms fail with an error that names them.

## Example: build and deploy to GitHub Pages

```yaml
name: Deploy

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: reverentgeek/setup-ssqch@v1
        with:
          version: 0.3.0
      - run: ssqch build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist
      - id: deployment
        uses: actions/deploy-pages@v4
```

## License

MIT
