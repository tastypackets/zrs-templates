# Contributing

Submit one template per pull request.

## Adding a template

Choose a catalog under `catalogs/` and copy an existing template as a starting point. The [app schema](https://templates.zrs.dev/v1/zrs-app.schema.json) describes the JSON structure. CI also checks template rules that the schema cannot express.

1. Write `catalogs/<catalog>/templates/<id>.json`. Use a slug of at most 63 characters for `id`, matching the filename. Keep the ID unchanged after the template is merged.
2. Add the file to that catalog's `manifest.json`.
3. If the CLI is installed locally, run `zrs-template --lint-only --strict --allow=unpinned_image` from the catalog directory.
4. Open a pull request. CI builds the catalogs and validates individual documents, including excluded templates.

Use a versioned image tag, such as a major release tag. Explain any use of `latest` in the pull request.
