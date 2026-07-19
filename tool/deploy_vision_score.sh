#!/usr/bin/env bash
# Deploy the vision-score Edge Function (Gemini 3.1 Flash Lite proxy).
# Requires: supabase login  OR  SUPABASE_ACCESS_TOKEN=sbp_…
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/.local/bin:${PATH}"

PROJECT_REF="${SUPABASE_PROJECT_REF:-zyadgkgumdgussvkgtsr}"

if ! command -v supabase >/dev/null 2>&1; then
  echo "ERROR: supabase CLI not found. Install from https://supabase.com/docs/guides/cli"
  exit 1
fi

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "==> No SUPABASE_ACCESS_TOKEN — opening interactive login…"
  supabase login
fi

echo "==> Deploying vision-score to $PROJECT_REF"
supabase functions deploy vision-score --project-ref "$PROJECT_REF"

if [[ -n "${GEMINI_API_KEY:-}" ]]; then
  echo "==> Setting GEMINI_API_KEY secret"
  supabase secrets set "GEMINI_API_KEY=$GEMINI_API_KEY" --project-ref "$PROJECT_REF"
else
  cat <<EOF

OK — function deployed.

If the Gemini secret is not set yet, run:
  export GEMINI_API_KEY='your_key'
  supabase secrets set GEMINI_API_KEY="\$GEMINI_API_KEY" --project-ref $PROJECT_REF

EOF
fi
