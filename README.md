# Email Validator (FastAPI + HTML/CSS/JavaScript)

A web app that cleans email lists. Paste addresses or upload `.txt`, `.csv` or `.xlsx`
files. Invalid, disposable, dead-domain and duplicate addresses are removed, and the clean
list can be downloaded as `.txt`, `.csv` or `.xlsx`.

- **Backend:** Python 3.10+, FastAPI, dnspython (live DNS checks), openpyxl (Excel)
- **Frontend:** HTML5, CSS3 (variables, grid, dark mode) and vanilla JavaScript. No build step.

---

## Features

| Area | What it does |
|---|---|
| Input | Paste emails (one per line, or comma / semicolon / space separated). Upload up to 10 files at once. |
| Files | `.txt`, `.csv` (delimiter auto-detected), `.xlsx` / `.xlsm` (choose a sheet). Headers and email columns are found automatically. |
| Checks | Syntax (RFC 5322 subset), disposable domains, DNS MX lookup (with A-record fallback), null MX, role inboxes (optional removal), duplicates (optional removal) |
| Results | Summary cards, reasons for each removal with bars, filter (All / Valid / Removed), search, paging |
| Downloads | Valid `.txt`, valid `.csv`, removed `.csv`, removed `.txt`, Excel report (Valid / Removed / All sheets), copy valid emails to clipboard |
| Safety | Results are rendered as text (no HTML injection). Exports neutralise spreadsheet formulas. Size and count limits. |
| Accessibility | Labelled controls, keyboard-operable drop zone, live status messages, dark mode follows the system setting |

### Why an address is removed

| Reason | Meaning |
|---|---|
| Invalid format | Not an email shape, for example missing `@`, double `@`, or a plain name |
| Disposable / temporary email | A known throwaway domain such as mailinator.com |
| Domain cannot receive email | The domain does not exist, or has no mail server (no MX and no A record), or publishes a Null MX |
| Could not verify (DNS problem) | The DNS lookup timed out or the resolver failed. These are **not** marked valid. Run the check again later. |
| Duplicate (removed) | The same address appeared earlier in the run (when *Remove duplicates* is on) |
| Role inbox (excluded) | `info@`, `sales@`, `support@` and similar, when *Remove role inboxes* is on |

> These checks confirm that a domain can receive email. They **cannot** confirm that a specific mailbox exists. That needs an SMTP verification service.

---

## Quick start

### Windows
Double-click **`run.bat`**. It creates a virtual environment, installs the packages, starts the server and opens your browser at <http://127.0.0.1:8000>.

### macOS / Linux
```bash
chmod +x run.sh
./run.sh
```

### Manual setup (any OS)
```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
Then open:
- <http://127.0.0.1:8000>: the web app
- <http://127.0.0.1:8000/docs>: interactive API documentation (Swagger UI)

---

## Using the app

1. Paste emails into the text box, or drag files onto the drop zone (or both).
2. For Excel files, optionally type a sheet name or number in *Excel sheet*. Otherwise the first sheet is used.
3. Choose options: remove duplicates (on by default), remove role inboxes (off by default).
4. Click **Validate & clean** (or press **Ctrl+Enter** in the text box).
5. Review the summary, the reasons, and the rows. Use the filters or search to narrow the list.
6. Download what you need.

To re-check a file that was validated before, upload it the same way. You get the same output.

---

## API

All endpoints return JSON except the exports.

### `POST /api/validate`
`multipart/form-data` fields:

| Field | Type | Default | Description |
|---|---|---|---|
| `text` | string | `""` | Pasted emails (max 1 MB) |
| `files` | file (repeatable) | none | `.txt`, `.csv`, `.xlsx`, `.xlsm`. Max 10 files, 10 MB each. |
| `dedup` | bool | `true` | Keep only the first copy of each address |
| `exclude_roles` | bool | `false` | Remove role-based inboxes |
| `sheet` | string | `""` | Excel sheet name or index, applied to every Excel file |

Response:
```json
{
  "summary": {
    "total": 6, "valid": 2, "invalid": 4, "duplicates": 1, "free_email": 1,
    "reasons": {"Valid": 2, "Duplicate (removed)": 1, "Invalid format": 1}
  },
  "results": [
    {
      "source": "Pasted text", "original": "aarav@google.com", "email": "aarav@google.com",
      "status": "Valid (Google Workspace)", "reason": "Valid", "is_valid": true,
      "is_duplicate": false, "is_free_email": false
    }
  ],
  "problems": ["people.csv: no email column found."]
}
```

Example with curl:
```bash
curl -X POST http://127.0.0.1:8000/api/validate \
  -F "text=aarav@google.com, not-an-email" \
  -F "files=@leads.csv" \
  -F "dedup=true"
```

Error responses use `{"detail": "..."}`:
- `400`: no addresses found, or too many files
- `413`: too many addresses (limit 20,000 per run) or pasted text over 1 MB

### `POST /api/export/xlsx`
Send the `results` array from `/api/validate` as JSON. You get back an `.xlsx` workbook with three sheets: *Valid*, *Invalid* and *All results*.

```bash
curl -X POST http://127.0.0.1:8000/api/export/xlsx \
  -H "Content-Type: application/json" \
  -d '{"results": [...]}' -o report.xlsx
```

### `GET /api/health`
Returns `{"status": "ok"}`.

---

## Configuration

Set these as environment variables before starting the server (optional):

| Variable | Default | Purpose |
|---|---|---|
| `DNS_SERVERS` | system resolvers | Comma-separated resolvers, e.g. `8.8.8.8,1.1.1.1` |
| `DNS_TIMEOUT` | `3` | Seconds per DNS query |
| `DNS_LIFETIME` | `5` | Total seconds per lookup, including retries |

Limits (edit `app/main.py`):

| Constant | Default |
|---|---|
| `MAX_FILES` | 10 |
| `MAX_FILE_BYTES` | 10 MB |
| `MAX_TEXT_BYTES` | 1 MB |
| `MAX_ADDRESSES` | 20,000 per run |

DNS results are cached in memory for one hour (`CACHE_TTL_SECONDS` in `app/validator_core.py`). Timeouts are not cached.

---

## Project structure

```text
email_validator_fastapi/
├── app/
│   ├── __init__.py
│   ├── main.py            # FastAPI app, routes, limits, security headers
│   ├── validator_core.py  # Syntax, disposable, role, DNS checks, batch validation
│   ├── parsing.py         # Pasted text and txt / csv / xlsx parsers
│   └── exporter.py        # Excel report builder
├── static/
│   ├── index.html         # Single page (HTML5)
│   ├── css/style.css      # Styles (CSS3, dark mode)
│   └── js/app.js          # Front-end logic (vanilla JavaScript)
├── tests/
│   ├── conftest.py        # Replaces live DNS with stubs for offline tests
│   ├── test_core.py
│   ├── test_parsing.py
│   └── test_api.py
├── requirements.txt
├── requirements-dev.txt
├── run.bat                # Windows launcher
├── run.sh                 # macOS / Linux launcher
└── README.md
```

---

## Running the tests

```bash
pip install -r requirements-dev.txt
pytest -q
```

The tests run offline. DNS is stubbed, so results do not depend on your network.

---

## Environment and MongoDB Atlas Configuration

Integration credentials and configuration are managed via the `.env` file.

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env     # Windows: copy .env.example .env
   ```
2. Update `.env` with your MongoDB Atlas connection string:
   ```env
   MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.abcde.mongodb.net/?retryWrites=true&w=majority
   MONGODB_DB_NAME=email_validator
   PORT=8000
   HOST=0.0.0.0
   ```
3. When MongoDB Atlas is configured, validation batch histories are automatically saved and retrievable via `/api/history`. If the connection is not configured or offline, the application operates gracefully in standalone/offline mode.
4. Check database status at `/api/db/status` or `/api/health?details=true`.

---

## Notes and limits

- **Live DNS is required for real results.** Without network access to DNS, domains show as "Domain cannot receive email". Set `DNS_SERVERS` if your network blocks the default resolver.
- **Pasted text is limited to 1 MB** (about 50,000 addresses). For larger lists, upload a file.
- **Only the first Excel sheet is read by default.** Use the sheet option to choose another.
- **Old `.xls` files are not supported.** Save as `.xlsx`.
- **No data is stored.** Uploads are processed in memory and discarded after the response.
