# Working in this repository

Read CONTRIBUTING.md before making changes.

## Scope

- Keep each PR focused on one app or one tooling change.
- Follow the published JSON schema and existing catalog structure.
- Preserve existing template IDs.
- Do not add unrelated documentation, dependencies, or formatting changes.

## Template configuration

- Verify image tags, ports, storage paths, and environment variables against
  upstream documentation. Do not rely on memory.
- Never invent supported settings or first-run behavior.
- Flag anything you cannot verify.
- Ask before adding privileged mode, host networking, device access, or
  sensitive host mounts. Explain what requires them.

## Writing

- Keep labels and descriptions short, factual, and useful during setup.
- Explain choices users need to make, including relevant limitations.
- Avoid marketing, generic advice, repeated explanations, and unsupported
  claims about security or performance.
- Put research links and testing details in the PR, not template descriptions.

## Validation and review

- Run the validation described in CONTRIBUTING.md.
- Distinguish validation from deployment testing. Report what actually ran.
- Before submitting a PR, show the user the proposed settings and defaults,
  security-sensitive choices, and anything untested or uncertain.
- Get the user's confirmation before submitting. Never check the PR's
  human-review checkbox on their behalf.
- Use `.github/pull_request_template.md` when creating a PR, including through
  the GitHub CLI or API. Fill in each section and leave the human-review
  checkbox unchecked for the contributor.
