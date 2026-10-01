# Contributing to StillScout

Thanks for caring enough to improve this project. StillScout is a small, focused iOS app — contributions that make scouting faster, clearer, or more trustworthy are always welcome.

## Before you start

1. **Search [existing issues](https://github.com/somyahangsandesh/StillScout/issues)** — someone may already be on it.
2. **For bigger changes**, open an issue first with a short “what / why” so we don’t duplicate work.
3. **Platform scope:** iOS only. Android scaffolding in the tree is not a shipping target.

## How to contribute

1. Fork and branch from `main` (use a clear name, e.g. `fix/quota-banner-copy`).
2. Run checks locally:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```
3. Keep PRs focused — one logical change beats a kitchen-sink diff.
4. Match existing style: minimal comments, no drive-by refactors.

## What we’re especially happy to see

- Test coverage for scoring, quotas, or export edge cases  
- Copy and accessibility improvements  
- Docs that help another developer run the app without guessing  
- Performance wins on frame extraction or dedup  

## What to avoid

- Committing secrets (`secrets.local.dart`, API keys, `.p8` files)  
- Public issues with user videos or personal data  
- Scope creep (unrelated features or whole redesigns in one PR)  

## Code of conduct (short version)

Be direct, be kind, assume good intent. No harassment, no spam, no bad-faith issue filing.

Questions? **stillscout.support@gmail.com** or a GitHub issue.
