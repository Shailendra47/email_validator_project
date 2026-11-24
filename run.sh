#!/usr/bin/env bash
# Email Validator launcher for macOS / Linux
set -e
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

if ! python -c "import fastapi, uvicorn, dns, openpyxl, multipart" >/dev/null 2>&1; then
  echo "Installing requirements, please wait..."
  python -m pip install --upgrade pip >/dev/null
  python -m pip install -r requirements.txt
fi

echo "Starting server at http://127.0.0.1:8000  (Ctrl+C to stop)"
( sleep 3; (command -v open >/dev/null && open http://127.0.0.1:8000) || (command -v xdg-open >/dev/null && xdg-open http://127.0.0.1:8000) ) >/dev/null 2>&1 &
exec python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
