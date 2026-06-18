#!/usr/bin/env bash
# books.sh — Book discovery via Open Library (free) and Google Books (optional)
# Usage: books.sh <command> [args] [--limit N] [--max N]
set -euo pipefail

OL_BASE="https://openlibrary.org"
GB_BASE="https://www.googleapis.com/books/v1"
LIMIT=10
MAX=10

die() { echo "ERROR: $*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }
need_cmd curl
need_cmd jq

# Parse trailing flags
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    --max)   MAX="$2"; shift 2 ;;
    *)       ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

CMD="${1:-}"
[[ -z "$CMD" ]] && die "Usage: books.sh <search|author|subject|isbn|gbooks> [query] [--limit N]"
shift

# jq is already required (need_cmd jq); @uri gives RFC 3986-correct encoding
# for all special and non-ASCII characters, no python3 dependency.
urlencode() {
  printf '%s' "$1" | jq -sRr @uri
}

ol_search() {
  local type="$1" query="$2"
  local encoded
  encoded=$(urlencode "$query")
  local url="${OL_BASE}/search.json?${type}=${encoded}&limit=${LIMIT}&fields=key,title,author_name,first_publish_year,edition_count,subject,isbn"
  local resp
  resp=$(curl -sSf --connect-timeout 20 --max-time 60 "$url") || die "Open Library request failed"
  echo "$resp" | jq '[.docs[] | {
    title: .title,
    authors: (.author_name // []),
    first_publish_year: .first_publish_year,
    edition_count: .edition_count,
    subjects: (.subject // [] | .[0:5]),
    isbn: (.isbn // [] | .[0])
  }]'
}

case "$CMD" in
  search)
    QUERY="${1:-}"
    [[ -z "$QUERY" ]] && die "Usage: books.sh search <query>"
    ol_search "q" "$QUERY"
    ;;

  author)
    AUTHOR="${1:-}"
    [[ -z "$AUTHOR" ]] && die "Usage: books.sh author <author name>"
    ol_search "author" "$AUTHOR"
    ;;

  subject)
    SUBJECT="${1:-}"
    [[ -z "$SUBJECT" ]] && die "Usage: books.sh subject <subject>"
    ol_search "subject" "$SUBJECT"
    ;;

  isbn)
    ISBN="${1:-}"
    [[ -z "$ISBN" ]] && die "Usage: books.sh isbn <isbn>"
    url="${OL_BASE}/api/books?bibkeys=ISBN:${ISBN}&format=json&jscmd=data"
    resp=$(curl -sSf --connect-timeout 20 --max-time 60 "$url") || die "Open Library ISBN lookup failed"
    echo "$resp" | jq '.'
    ;;

  gbooks)
    QUERY="${1:-}"
    [[ -z "$QUERY" ]] && die "Usage: books.sh gbooks <query>"
    [[ -z "${GOOGLE_BOOKS_API_KEY:-}" ]] && die "GOOGLE_BOOKS_API_KEY not set — use 'search' for keyless Open Library search"
    encoded=$(urlencode "$QUERY")
    url="${GB_BASE}/volumes?q=${encoded}&maxResults=${MAX}&key=${GOOGLE_BOOKS_API_KEY}"
    resp=$(curl -sSf --connect-timeout 20 --max-time 60 "$url") || die "Google Books request failed"
    echo "$resp" | jq '[.items[]? | {
      title: .volumeInfo.title,
      authors: (.volumeInfo.authors // []),
      published_date: .volumeInfo.publishedDate,
      page_count: .volumeInfo.pageCount,
      ratings_average: .volumeInfo.averageRating,
      ratings_count: .volumeInfo.ratingsCount,
      description: (.volumeInfo.description // "" | .[0:200]),
      isbn: (.volumeInfo.industryIdentifiers // [] | map(select(.type == "ISBN_13")) | .[0].identifier)
    }]'
    ;;

  *)
    die "Unknown command: $CMD. Valid: search, author, subject, isbn, gbooks"
    ;;
esac
