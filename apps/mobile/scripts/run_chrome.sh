#!/usr/bin/env bash
# Local Chrome run with secrets from gitignored .env (not bundled in the binary).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="${HOME}/flutter/bin:${PATH}"
if [[ ! -f .env ]]; then
  echo "Missing apps/mobile/.env — copy from .env.example and fill keys."
  exit 1
fi
exec flutter run -d chrome --dart-define-from-file=.env "$@"
