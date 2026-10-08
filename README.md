# ZRS templates

App templates for [ZRS](https://zrs.dev), organized into independent catalogs. Each template describes the container settings and fields used during deployment.

| Catalog                             | Contents                                 |
| ----------------------------------- | ---------------------------------------- |
| [Networking](catalogs/networking)               | Network and home server services         |
| [Media](catalogs/media)             | Media servers                            |
| [Development](catalogs/development) | Developer tools, databases, and local AI |
| [Gaming](catalogs/gaming)           | Gaming servers and voice chat            |

Each catalog has a `manifest.json` listing its templates. Entries with `carried: false` are excluded from the built catalog.

## Build or lint

With `zrs-template` installed, run these commands from a catalog directory:

```sh
cd catalogs/networking
zrs-template
```

This validates the manifest and its included templates, then writes `templates.source.json`. To validate without writing a file:

```sh
zrs-template --lint-only
```

Add `--strict --allow=unpinned_image` to use the same warning policy as this repository's CI.

## GitHub Action

Use the Action in your own repository to build a catalog from its `manifest.json`:

```yaml
name: Templates
on: [push, pull_request]
permissions:
  contents: read
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: tastypackets/zrs-templates@main
```

The Action supports Linux x86-64 and ARM64 runners. It writes `templates.source.json` after validation succeeds. Set `lint-only: "true"` to validate without writing, or `working-directory` to select a catalog in a subdirectory. Set `files` to newline-separated glob patterns to lint individual documents without a manifest.

By default, the Action downloads the current v1 CLI and fails on warnings except `unpinned_image`. Its `version` input can select an exact CLI release ID. Only three releases per CLI major are retained, so older pins can expire. The CLI version is separate from a template's `format_version`.

See [action.yml](action.yml) for all inputs and [CONTRIBUTING.md](CONTRIBUTING.md) to submit a template.
