---
name: vibecode-integration-dropbox
display_name: Dropbox
provider_skill: true
integration_dependencies:
  - dropbox
description: >
  Dropbox API for managing files, folders, and sharing links.
  Consult this skill:
  1. When the user asks to upload, download, or manage files in Dropbox
  2. When the user needs to search for files or folders
  3. When the user wants to create sharing links or check storage usage
  4. When the user mentions cloud storage or file sharing and has Dropbox connected
metadata: {"openclaw": {"emoji": "📦", "requires": {"env": ["DROPBOX_ACCESS_TOKEN"]}}}
---

# Dropbox Integration

File storage API with two base URLs: `api.dropboxapi.com` for metadata operations, `content.dropboxapi.com` for file content.

**Auth**: Bearer token via `DROPBOX_ACCESS_TOKEN`.

**Important**: Dropbox API uses POST for everything (including reads). Paths are case-insensitive. Root folder = empty string `""`.

## List files

```bash
# List root folder
curl -s -X POST https://api.dropboxapi.com/2/files/list_folder \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path":"","limit":50}'

# List specific folder
curl -s -X POST https://api.dropboxapi.com/2/files/list_folder \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path":"/Documents","limit":100}'

# Paginate (when has_more is true)
curl -s -X POST https://api.dropboxapi.com/2/files/list_folder/continue \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cursor":"CURSOR_FROM_PREVIOUS"}'
```

## Search

```bash
curl -s -X POST https://api.dropboxapi.com/2/files/search_v2 \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"quarterly report","options":{"max_results":20}}'
```

## Download

```bash
# Download file (content endpoint, path in header)
curl -s -X POST https://content.dropboxapi.com/2/files/download \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Dropbox-API-Arg: {\"path\":\"/Documents/report.pdf\"}" \
  -o report.pdf

# Get file metadata only
curl -s -X POST https://api.dropboxapi.com/2/files/get_metadata \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path":"/Documents/report.pdf"}'
```

## Upload

```bash
# Upload file (<150MB, content endpoint, metadata in header)
curl -s -X POST https://content.dropboxapi.com/2/files/upload \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  -H "Dropbox-API-Arg: {\"path\":\"/Documents/newfile.txt\",\"mode\":\"add\",\"autorename\":true}" \
  --data-binary @localfile.txt
```

Upload modes: `add` (don't overwrite), `overwrite`, `update` (with rev).

## Folders, move, copy, delete

```bash
# Create folder
curl -s -X POST https://api.dropboxapi.com/2/files/create_folder_v2 \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path":"/Projects/New Folder","autorename":false}'

# Move/rename
curl -s -X POST https://api.dropboxapi.com/2/files/move_v2 \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"from_path":"/old/path.txt","to_path":"/new/path.txt"}'

# Copy
curl -s -X POST https://api.dropboxapi.com/2/files/copy_v2 \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"from_path":"/source.txt","to_path":"/dest.txt"}'

# Delete
curl -s -X POST https://api.dropboxapi.com/2/files/delete_v2 \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path":"/file-to-delete.txt"}'
```

## Sharing

```bash
# Create shared link
curl -s -X POST https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path":"/Documents/report.pdf","settings":{"requested_visibility":"public"}}'
```

## Account info

```bash
# Get current user
curl -s -X POST https://api.dropboxapi.com/2/users/get_current_account \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN"

# Check storage usage
curl -s -X POST https://api.dropboxapi.com/2/users/get_space_usage \
  -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN"
```

## Tips

- **All calls are POST** — even listing and downloading. This is a Dropbox API convention.
- **Two base URLs**: `api.dropboxapi.com` for metadata, `content.dropboxapi.com` for file content (upload/download).
- **Upload/download use headers for metadata**: `Dropbox-API-Arg` header contains the JSON path/options, body is the file content.
- **Files >150MB** need upload sessions (`upload_session/start` → `append_v2` → `finish`).
- **Rate limit**: Back off on 429 with exponential delay.

---

*Extracted from [vm0-ai/vm0-skills/dropbox](https://skills.sh/vm0-ai/vm0-skills/dropbox) and [Dropbox HTTP API docs](https://www.dropbox.com/developers/documentation/http/documentation).*
