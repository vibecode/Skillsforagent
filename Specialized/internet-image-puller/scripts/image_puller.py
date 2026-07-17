#!/usr/bin/env python3
"""Discover and download public images through Chorus-managed SerpApi and Firecrawl."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import mimetypes
import os
import re
import sys
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode, urljoin, urlparse, urlunparse, unquote
from urllib.request import Request, urlopen


USER_AGENT = "Mozilla/5.0 (compatible; ChorusImagePuller/1.0)"
MAX_BYTES = 25 * 1024 * 1024
RESIZE_KEYS = {
    "w", "h", "width", "height", "q", "quality", "fit", "crop", "fm",
    "format", "auto", "dpr", "ixlib", "rect", "resize", "size",
}
CONTENT_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/gif": ".gif",
    "image/webp": ".webp",
    "image/avif": ".avif",
    "image/svg+xml": ".svg",
    "image/x-icon": ".ico",
    "image/vnd.microsoft.icon": ".ico",
}


def api_headers(service: str) -> dict[str, str]:
    headers = {"User-Agent": USER_AGENT, "Accept": "application/json"}
    vibecode_key = os.getenv("VIBECODE_API_KEY")
    if vibecode_key:
        headers["x-api-key"] = vibecode_key
    if service == "firecrawl":
        key = os.getenv("FIRECRAWL_API_KEY")
        if not key:
            raise RuntimeError("FIRECRAWL_API_KEY is unavailable")
        headers["Authorization"] = f"Bearer {key}"
        headers["Content-Type"] = "application/json"
    return headers


def request_json(url: str, *, headers: dict[str, str], payload: dict[str, Any] | None = None) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = Request(url, data=data, headers=headers, method="POST" if data else "GET")
    try:
        with urlopen(req, timeout=90) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:800]
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc
    except (URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise RuntimeError(str(exc)) from exc


def hostname_matches(url: str, required: str | None) -> bool:
    if not required:
        return True
    host = (urlparse(url).hostname or "").lower()
    required = required.lower().lstrip(".")
    return host == required or host.endswith("." + required)


def path_matches(path: str, pattern: str) -> bool:
    """Treat slash-prefixed values as path prefixes, globs as globs, and others as substrings."""
    if any(char in pattern for char in "*?["):
        return fnmatch.fnmatch(path, pattern)
    if pattern.startswith("/"):
        normalized = pattern.rstrip("/") or "/"
        return path == normalized or path.startswith(normalized + "/")
    return pattern in path


def strip_resize_params(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        return url
    kept = [(key, value) for key, value in parse_qsl(parsed.query, keep_blank_values=True)
            if key.lower() not in RESIZE_KEYS]
    return urlunparse(parsed._replace(query=urlencode(kept, doseq=True)))


def safe_name(url: str, content_type: str | None) -> str:
    path_name = unquote(Path(urlparse(url).path).name) or "image"
    stem = Path(path_name).stem or "image"
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", stem).strip("-._")[:80] or "image"
    ext = CONTENT_EXTENSIONS.get((content_type or "").split(";")[0].lower())
    if not ext:
        candidate = Path(path_name).suffix.lower()
        ext = candidate if candidate in {".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".svg", ".ico"} else ".img"
    digest = hashlib.sha256(url.encode("utf-8")).hexdigest()[:10]
    return f"{stem}-{digest}{ext}"


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_existing_content(out_dir: Path, digest: str) -> Path | None:
    for path in out_dir.iterdir():
        if not path.is_file() or path.name == "manifest.json":
            continue
        try:
            if file_sha256(path) == digest:
                return path
        except OSError:
            continue
    return None


def download_one(url: str, out_dir: Path, source_page: str | None, min_bytes: int = 2048) -> dict[str, Any]:
    canonical_url = strip_resize_params(url)
    item: dict[str, Any] = {"source_page": source_page, "original_url": url,
                            "canonical_url": canonical_url, "status": "failed"}
    if urlparse(url).scheme not in {"http", "https"}:
        item["error"] = "unsupported URL scheme"
        return item

    attempts = []
    cleaned = canonical_url
    for candidate in (cleaned, url):
        if candidate not in attempts:
            attempts.append(candidate)

    last_error = "download failed"
    for candidate in attempts:
        try:
            req = Request(candidate, headers={"User-Agent": USER_AGENT, "Accept": "image/*,*/*;q=0.5"})
            with urlopen(req, timeout=45) as response:
                content_type = response.headers.get_content_type()
                content_length = response.headers.get("Content-Length")
                if content_length and int(content_length) > MAX_BYTES:
                    raise RuntimeError("image exceeds 25 MB limit")
                data = response.read(MAX_BYTES + 1)
                if len(data) > MAX_BYTES:
                    raise RuntimeError("image exceeds 25 MB limit")
                if len(data) < min_bytes:
                    raise RuntimeError(f"image is smaller than {min_bytes} byte quality floor")
                if not content_type.startswith("image/"):
                    guessed, _ = mimetypes.guess_type(urlparse(candidate).path)
                    if not (guessed or "").startswith("image/"):
                        raise RuntimeError(f"non-image response: {content_type}")
                    content_type = guessed or content_type
                digest = hashlib.sha256(data).hexdigest()
                filename = safe_name(canonical_url, content_type)
                path = out_dir / filename
                existing = find_existing_content(out_dir, digest)
                if existing:
                    item.update({"status": "skipped", "reason": "identical content already downloaded",
                                 "download_url": candidate, "file": existing.name, "content_type": content_type,
                                 "bytes": len(data), "sha256": digest})
                    return item
                if path.exists():
                    path = path.with_name(f"{path.stem}-{digest[:8]}{path.suffix}")
                    filename = path.name
                path.write_bytes(data)
                item.update({"status": "downloaded", "download_url": candidate, "file": filename,
                             "content_type": content_type, "bytes": len(data), "sha256": digest})
                return item
        except Exception as exc:  # Keep each public URL failure in the manifest.
            last_error = str(exc)
    item["attempted_urls"] = attempts
    item["error"] = last_error[:500]
    return item


def load_manifest(out_dir: Path) -> dict[str, Any]:
    path = out_dir / "manifest.json"
    if not path.exists():
        return {"version": 1, "runs": []}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) and isinstance(data.get("runs"), list) else {"version": 1, "runs": []}
    except json.JSONDecodeError:
        backup = out_dir / f"manifest.invalid-{int(time.time())}.json"
        path.rename(backup)
        return {"version": 1, "runs": [], "warning": f"Invalid prior manifest moved to {backup.name}"}


def save_run(out_dir: Path, command: str, parameters: dict[str, Any], items: list[dict[str, Any]]) -> None:
    manifest = load_manifest(out_dir)
    counts = {status: sum(1 for item in items if item.get("status") == status)
              for status in ("downloaded", "skipped", "failed")}
    manifest["runs"].append({"timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                             "command": command, "parameters": parameters, "counts": counts, "items": items})
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"output_dir": str(out_dir), "counts": counts, "manifest": str(out_dir / "manifest.json")}, indent=2))


def run_downloads(command: str, parameters: dict[str, Any], urls: list[tuple[str, str | None]], out_dir: Path,
                  limit: int, min_bytes: int = 2048) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    seen: set[str] = set()
    items: list[dict[str, Any]] = []
    usable = 0
    for url, source in urls:
        canonical_url = strip_resize_params(url) if url else ""
        if not canonical_url or canonical_url in seen:
            continue
        seen.add(canonical_url)
        result = download_one(url, out_dir, source, min_bytes)
        items.append(result)
        if result.get("status") in {"downloaded", "skipped"}:
            usable += 1
        if usable >= limit:
            break
    save_run(out_dir, command, parameters, items)


def serp_search(args: argparse.Namespace) -> None:
    key = os.getenv("SERPAPI_API_KEY")
    if not key:
        raise RuntimeError("SERPAPI_API_KEY is unavailable")
    base = os.getenv("SERPAPI_BASE_URL", "https://serpapi.com.proxy.chorus.com").rstrip("/")
    params = {"engine": "google_images", "q": args.query, "api_key": key, "gl": args.gl, "hl": args.hl}
    payload = request_json(f"{base}/search.json?{urlencode(params)}", headers=api_headers("serpapi"))
    if payload.get("error"):
        raise RuntimeError(str(payload["error"]))
    rows = payload.get("images_results") or []
    urls: list[tuple[str, str | None]] = []
    for row in rows:
        original = row.get("original") or row.get("image") or row.get("thumbnail")
        source = row.get("link") or row.get("source")
        searchable = " ".join(str(row.get(key) or "") for key in ("title", "source", "link", "original", "image")).lower()
        if args.include_keyword and not any(keyword.lower() in searchable for keyword in args.include_keyword):
            continue
        if args.exclude_keyword and any(keyword.lower() in searchable for keyword in args.exclude_keyword):
            continue
        domain_target = source or original or ""
        if original and hostname_matches(domain_target, args.require_domain):
            urls.append((original, source))
    run_downloads("serp:search", {"query": args.query, "require_domain": args.require_domain,
                                  "include_keyword": args.include_keyword, "exclude_keyword": args.exclude_keyword,
                                  "gl": args.gl, "hl": args.hl, "min_bytes": args.min_bytes},
                  urls, Path(args.output_dir), args.limit, args.min_bytes)


def firecrawl_scrape_urls(url: str) -> list[str]:
    base = os.getenv("FIRECRAWL_BASE_URL", "https://api.firecrawl.dev.proxy.chorus.com/v2").rstrip("/")
    payload = request_json(f"{base}/scrape", headers=api_headers("firecrawl"),
                           payload={"url": url, "formats": ["images"], "removeBase64Images": True, "blockAds": True})
    if not payload.get("success"):
        raise RuntimeError(str(payload.get("error") or payload))
    data = payload.get("data") or {}
    variants: dict[str, str] = {}
    for value in data.get("images") or []:
        if not isinstance(value, str):
            continue
        canonical = strip_resize_params(value)
        if canonical and (canonical not in variants or value < variants[canonical]):
            variants[canonical] = value
    return [variants[key] for key in sorted(variants)]


def firecrawl_scrape(args: argparse.Namespace) -> None:
    image_urls = filter_image_urls(firecrawl_scrape_urls(args.url), args.include_keyword, args.exclude_keyword)
    urls = [(url, args.url) for url in image_urls]
    run_downloads("firecrawl:scrape", {"url": args.url, "include_keyword": args.include_keyword,
                                       "exclude_keyword": args.exclude_keyword, "min_bytes": args.min_bytes},
                  urls, Path(args.output_dir), args.limit, args.min_bytes)


def filter_image_urls(urls: list[str], includes: list[str] | None, excludes: list[str] | None) -> list[str]:
    selected = []
    for url in urls:
        lowered = unquote(url).lower()
        if includes and not any(keyword.lower() in lowered for keyword in includes):
            continue
        if excludes and any(keyword.lower() in lowered for keyword in excludes):
            continue
        selected.append(url)
    return selected


def firecrawl_map(url: str, search: str | None, limit: int) -> list[str]:
    base = os.getenv("FIRECRAWL_BASE_URL", "https://api.firecrawl.dev.proxy.chorus.com/v2").rstrip("/")
    body: dict[str, Any] = {"url": url, "limit": limit}
    if search:
        body["search"] = search
    payload = request_json(f"{base}/map", headers=api_headers("firecrawl"), payload=body)
    if not payload.get("success"):
        raise RuntimeError(str(payload.get("error") or payload))
    rows = (payload.get("data") or {}).get("links") or payload.get("links") or []
    links = []
    for row in rows:
        value = row if isinstance(row, str) else row.get("url") if isinstance(row, dict) else None
        if value:
            links.append(urljoin(url, value))
    return links


def firecrawl_site(args: argparse.Namespace) -> None:
    includes = args.include or []
    map_limit = max(args.page_limit * (20 if includes else 5), 100 if includes else args.page_limit)
    pages = firecrawl_map(args.url, args.map_search, map_limit)
    if includes:
        pages = [page for page in pages if any(path_matches(urlparse(page).path, pattern) for pattern in includes)]
    pages = pages[:args.page_limit]
    discovered: list[tuple[str, str | None]] = []
    page_errors: list[dict[str, Any]] = []
    if not pages:
        page_errors.append({"source_page": args.url, "original_url": args.url, "status": "failed",
                            "error": "No mapped pages matched the requested search and include filters"})
    for page in pages:
        try:
            page_images = filter_image_urls(firecrawl_scrape_urls(page), args.include_keyword,
                                            args.exclude_keyword)[:args.images_per_page]
            if not page_images:
                page_errors.append({"source_page": page, "original_url": page, "status": "failed",
                                    "error": "No image URLs extracted from mapped page"})
            discovered.extend((image, page) for image in page_images)
        except Exception as exc:
            page_errors.append({"source_page": page, "original_url": page, "status": "failed", "error": str(exc)[:500]})
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    seen: set[str] = set()
    items = page_errors
    for image, page in discovered:
        canonical = strip_resize_params(image)
        if canonical in seen:
            continue
        seen.add(canonical)
        items.append(download_one(image, out_dir, page, args.min_bytes))
    save_run(out_dir, "firecrawl:site", {"url": args.url, "map_search": args.map_search,
                                        "include": includes, "page_limit": args.page_limit,
                                        "images_per_page": args.images_per_page,
                                        "include_keyword": args.include_keyword,
                                        "exclude_keyword": args.exclude_keyword,
                                        "min_bytes": args.min_bytes}, items)


def config_show(_: argparse.Namespace) -> None:
    print(json.dumps({
        "serpapi": {"configured": bool(os.getenv("SERPAPI_API_KEY")),
                    "base_url": os.getenv("SERPAPI_BASE_URL", "https://serpapi.com.proxy.chorus.com")},
        "firecrawl": {"configured": bool(os.getenv("FIRECRAWL_API_KEY")),
                      "base_url": os.getenv("FIRECRAWL_BASE_URL", "https://api.firecrawl.dev.proxy.chorus.com/v2")},
    }, indent=2))


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    subs = root.add_subparsers(dest="command", required=True)
    subs.add_parser("config:show").set_defaults(func=config_show)

    serp = subs.add_parser("serp:search")
    serp.add_argument("--query", required=True)
    serp.add_argument("--output-dir", required=True)
    serp.add_argument("--limit", type=int, default=20)
    serp.add_argument("--require-domain")
    serp.add_argument("--include-keyword", action="append")
    serp.add_argument("--exclude-keyword", action="append")
    serp.add_argument("--min-bytes", type=int, default=2048)
    serp.add_argument("--gl", default="us")
    serp.add_argument("--hl", default="en")
    serp.set_defaults(func=serp_search)

    scrape = subs.add_parser("firecrawl:scrape")
    scrape.add_argument("--url", required=True)
    scrape.add_argument("--output-dir", required=True)
    scrape.add_argument("--limit", type=int, default=100)
    scrape.add_argument("--include-keyword", action="append")
    scrape.add_argument("--exclude-keyword", action="append")
    scrape.add_argument("--min-bytes", type=int, default=2048)
    scrape.set_defaults(func=firecrawl_scrape)

    site = subs.add_parser("firecrawl:site")
    site.add_argument("--url", required=True)
    site.add_argument("--output-dir", required=True)
    site.add_argument("--map-search")
    site.add_argument("--include", action="append")
    site.add_argument("--page-limit", type=int, default=8)
    site.add_argument("--images-per-page", type=int, default=100)
    site.add_argument("--include-keyword", action="append")
    site.add_argument("--exclude-keyword", action="append")
    site.add_argument("--min-bytes", type=int, default=2048)
    site.set_defaults(func=firecrawl_site)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        args.func(args)
        return 0
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
