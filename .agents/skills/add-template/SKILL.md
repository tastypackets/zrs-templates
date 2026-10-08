---
name: add-template
description: Write or update a ZRS app template using upstream container documentation and the published format.
---

# Write an app template

Use AGENTS.md and CONTRIBUTING.md for scope, validation, and human review.

## Establish the app's setup

Start with the official image's installation guide or registry README. Use its documented container settings and terminology. Open and read the source, a search snippet is not enough to establish configuration behavior. Check the Dockerfile or entrypoint when documentation leaves first-run behavior unclear.

Choose a current stable release from upstream release metadata, then verify its container tag exists. Use documentation for that version. Explain an older release choice rather than silently using a tag from an old example or search result.

Identify the image tag, persistent paths, process user, listening ports, configuration inputs, and first-run account creation. Distinguish settings read only on first initialization from settings applied on every restart.

## Map it to ZRS

Read the published [app schema](https://templates.zrs.dev/v1/zrs-app.schema.json) and a relevant existing template before writing JSON. Examples under catalogs/:

- networking/templates/nginx.json: optional ports and existing read-only mounts.
- development/templates/postgres.json: persistent data and a generated secret.
- development/templates/valkey.json: optional command groups.

Copy the relevant pattern, not every option in the example. A simple service may need only an image and a port. Put required setup choices in basic fields and optional tuning in advanced fields. Start with a usable standalone deployment: a web app normally needs a host-port default. Omit it only when the requested setup has a supported way to reach the container. Leave CPU, memory, and other normal container controls to the deployment form.

- Default app-owned storage to `{{zrs_app_folder}}`, with subfolders when needed. Use `{{zrs_appdata}}` only for intentionally shared data.
- Use `secret` for a generated value and `password` for a value the user chooses or supplies. Do not add a secret that bypasses upstream's setup wizard.
- A blank optional port or mount source can omit that entry. Keep optional placeholders as whole values, embedding them in longer strings may not omit the setting. Follow the existing command-group pattern for optional flags.
- Mounting an empty folder over image-provided files hides them. Existing config files or directories should not be silently created as empty replacements.
- Set only fields the format supports. If a required upstream feature cannot be expressed, explain the gap rather than presenting a broken deployment.

## Write useful content

Prefer upstream's factual description and image-specific terminology, shortened or paraphrased for the form. Do not infer blank-value behavior, fallback values, or logging behavior from a setting name. If upstream does not establish a detail, leave it out or flag it for review. Describe the app, then add only setup details the user needs. Avoid promotional copy, emojis, em-dash chains, and repeated hints. For example: "Sets the password on first initialization. Changing this later does not reset it." Not "Seamlessly secure your powerful database experience."

## Check the result

Use the CLI commands in CONTRIBUTING.md. On Linux, if the CLI is missing, `bash scripts/download-cli.sh <binary-path>` downloads and verifies it. Set RUNNER_OS=Linux, RUNNER_ARCH=X64 or ARM64, RUNNER_TEMP to a temporary directory, and GITHUB_OUTPUT to a temporary file.

Validate a catalog containing the proposed entry and lint the new or edited JSON individually, including entries excluded from the manifest build. For a draft-only request, use a temporary copy of the catalog and update its manifest; validating the unchanged catalog does not check the proposed addition. Trace every input to the container field it controls, and check what happens when optional inputs are blank. From the catalog directory, lint the draft directly with `zrs-template --strict --allow=unpinned_image templates/<id>.json`. Check the command's exit status: an explicitly allowed `unpinned_image` warning is not a failed check. Report individual and catalog results separately. Before handoff, check each behavior claim in labels and descriptions against the upstream text or code you read and the actual JSON. A required field cannot claim that leaving it blank disables a feature. Remove unsupported fallback claims rather than filling gaps from intuition. Then hand off as described in AGENTS.md. Lint does not prove the image starts or that first-run setup works.
