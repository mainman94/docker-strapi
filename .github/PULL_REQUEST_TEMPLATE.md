## What

<!-- One or two sentences. -->

## Why

<!-- The problem this solves. Link the issue if there is one. -->

## Checklist

- [ ] Built and smoke-tested the affected variant(s) locally
      (`docker build ... && ./smoke-test.sh <tag>`)
- [ ] Entrypoint changes applied to **both** alpine and debian (CI enforces
      they stay identical)
- [ ] READMEs updated if behaviour, env vars or tags changed
