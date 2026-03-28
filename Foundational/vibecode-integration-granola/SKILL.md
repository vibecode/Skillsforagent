---
name: vibecode-integration-granola
display_name: Granola
description: >
  Granola API for accessing meeting notes, transcripts, and summaries.
  Consult this skill:
  1. When the user asks about recent meetings or meeting notes
  2. When the user needs a transcript or summary of a specific meeting
  3. When the user wants to search for meetings by date or keyword
  4. When the user mentions meeting notes, transcripts, or Granola
metadata: {"openclaw": {"emoji": "🎙️", "requires": {"env": ["GRANOLA_API_KEY"]}}}
---

# Granola Integration

Meeting notes, transcripts, and summaries via the Granola public API.

**Auth**: Bearer token via `GRANOLA_API_KEY`.
**Base URL**: `https://public-api.granola.ai`
**Rate limit**: 25 requests per 5-second burst, 5 req/s sustained.

## List meetings

```bash
# List recent notes (default: 10 most recent)
curl -s https://public-api.granola.ai/v1/notes \
  -H "Authorization: Bearer $GRANOLA_API_KEY"

# List with date filter
curl -s "https://public-api.granola.ai/v1/notes?created_after=2026-03-20&page_size=20" \
  -H "Authorization: Bearer $GRANOLA_API_KEY"

# Filter by update date
curl -s "https://public-api.granola.ai/v1/notes?updated_after=2026-03-24&page_size=30" \
  -H "Authorization: Bearer $GRANOLA_API_KEY"

# List notes before a date
curl -s "https://public-api.granola.ai/v1/notes?created_before=2026-03-15" \
  -H "Authorization: Bearer $GRANOLA_API_KEY"

# Paginate (when hasMore is true, use cursor)
curl -s "https://public-api.granola.ai/v1/notes?cursor=CURSOR_VALUE&page_size=10" \
  -H "Authorization: Bearer $GRANOLA_API_KEY"
```

Response:
```json
{
  "notes": [{"id": "not_abc123...", "title": "Weekly standup", "owner": {"name": "...", "email": "..."}, "created_at": "...", "updated_at": "..."}],
  "hasMore": true,
  "cursor": "next_cursor_value"
}
```

## Get meeting details

```bash
# Get note with summary
curl -s https://public-api.granola.ai/v1/notes/{note_id} \
  -H "Authorization: Bearer $GRANOLA_API_KEY"

# Get note with full transcript
curl -s "https://public-api.granola.ai/v1/notes/{note_id}?include=transcript" \
  -H "Authorization: Bearer $GRANOLA_API_KEY"
```

Note IDs follow the pattern `not_[a-zA-Z0-9]{14}`.

Response includes:
- `title`, `owner`, `created_at`, `updated_at`
- `calendar_event` — event title, invitees, organiser, scheduled start/end
- `attendees` — array of `{name, email}`
- `folder_membership` — folders the note belongs to
- `summary_text` — plain text summary
- `summary_markdown` — markdown summary
- `transcript` (if requested) — array of `{speaker_source, text, start_time, end_time}`

Speaker sources: `"microphone"` (the user) or `"speaker"` (others in the meeting).

## Tips

- **Page size**: 1–30, default 10.
- **Note IDs** match pattern `not_[a-zA-Z0-9]{14}`.
- **Transcripts are large** — only fetch with `?include=transcript` when needed.
- **Timestamps are UTC** in ISO 8601 format.
- **Date filters accept both date and datetime**: `2026-03-25` or `2026-03-25T10:00:00Z`.
- **No search endpoint** in the public API — filter by date range and scan titles client-side.
- **Only 2 endpoints**: list notes and get note. The API is simple but covers the core use case.

---

*Extracted from [joelhooks/joelclaw/granola](https://skills.sh/joelhooks/joelclaw/granola) and [Granola API Reference](https://docs.granola.ai/introduction).*
