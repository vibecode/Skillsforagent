---
name: books
display_name: Books
description: >
  Skill for book discovery, catalog lookups, author searches, and themed recommendations.
  Uses Open Library (free, no key required) for catalog data — titles, authors, publish
  dates, subjects, and ISBNs. Falls back to Google Books API when GOOGLE_BOOKS_API_KEY
  is set for ratings and enhanced metadata. Use when: (1) finding books by topic, genre,
  or theme, (2) author lookups and bibliography, (3) finding books similar to a given
  title, (4) subject browsing, (5) any book-discovery or catalog task.
metadata:
  openclaw:
    emoji: "📚"
---

# Books

Book discovery and catalog lookups via Open Library (free, no key required) with optional Google Books for ratings and cover art.

## Data Sources

### Open Library (always available — no key required)

```
Base URL: https://openlibrary.org
```

Open Library covers 20M+ books. No API key needed. Returns titles, authors, publish dates, subjects, ISBNs, edition counts, and cover image references.

### Google Books (optional, enhanced metadata)

```
Base URL: https://www.googleapis.com/books/v1
```

Set `GOOGLE_BOOKS_API_KEY` for ratings, descriptions, page counts, and thumbnail images. Free tier: 1,000 requests/day.

## Wrapper Script

Use `scripts/books.sh` for all searches. Handles both Open Library and Google Books, with automatic fallback.

```bash
SCRIPT="$(dirname "$0")/scripts/books.sh"
```

### Commands

```bash
# Search by keyword, title, or topic (Open Library)
bash $SCRIPT search "behavioral economics"
bash $SCRIPT search "sapiens yuval harari"

# Search by author
bash $SCRIPT author "Yuval Noah Harari"

# Search by subject/genre
bash $SCRIPT subject "science fiction"
bash $SCRIPT subject "mystery" --limit 10

# Look up a specific book by ISBN
bash $SCRIPT isbn "9780062316097"

# Search with Google Books (requires GOOGLE_BOOKS_API_KEY)
bash $SCRIPT gbooks "behavioral economics 2020"
bash $SCRIPT gbooks "dune frank herbert" --max 5
```

### Output Format

All commands output JSON. Key fields per book:

| Field | Source | Notes |
|-------|--------|-------|
| `title` | Both | Book title |
| `authors` | Both | Author name(s) |
| `first_publish_year` | Open Library | Year of first publication |
| `edition_count` | Open Library | Number of editions (popularity signal) |
| `subjects` | Open Library | Genre/subject tags |
| `isbn` | Both | ISBN-13 when available |
| `ratings_average` | Google Books | Rating (1–5), only with API key |
| `description` | Google Books | Publisher description, only with API key |
| `page_count` | Google Books | Page count, only with API key |

## Usage Examples

### Find recent books on a topic

```bash
bash $SCRIPT search "machine learning 2023"
```

### Author bibliography

```bash
bash $SCRIPT author "Nassim Nicholas Taleb"
```

### Genre browsing

```bash
bash $SCRIPT subject "historical fiction" --limit 15
```

### Similar-book discovery

Search for the subject tags of a known book, then search those subjects:

```bash
# Step 1: get subjects of the reference book
bash $SCRIPT isbn "9780062316097"

# Step 2: search those subjects
bash $SCRIPT subject "popular science"
bash $SCRIPT subject "evolution"
```

### With Google Books for ratings

```bash
# Set GOOGLE_BOOKS_API_KEY first
bash $SCRIPT gbooks "best science fiction 2024" --max 10
```

## Notes

- Open Library is entirely free and requires no API key — it is the default and covers most use cases.
- Google Books ratings and descriptions add signal when a key is available; never required.
- `edition_count` from Open Library is a useful proxy for a book's popularity and staying power.
- For the most recent releases (last 6 months), Open Library coverage may lag; prefer Google Books for very new titles.
