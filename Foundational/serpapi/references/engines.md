# SerpApi Engine Reference

Complete parameter reference for all supported engines. Each engine section documents required/optional parameters and key response fields.

All requests use `https://serpapi.com/search` with `engine=<engine_name>&api_key=$SERPAPI_API_KEY`.

---

## Table of Contents

- [Google Web Search](#google-web-search)
- [Google Images](#google-images)
- [Google Maps](#google-maps)
- [Google Flights](#google-flights)
- [Google Hotels](#google-hotels)
- [Google Scholar](#google-scholar)
- [Google News](#google-news)
- [Google Shopping](#google-shopping)
- [Google Jobs](#google-jobs)
- [Google Finance](#google-finance)
- [Google Trends](#google-trends)
- [Google Autocomplete](#google-autocomplete)
- [Google Ads Transparency Center](#google-ads-transparency-center)
- [Google Local Services](#google-local-services)
- [Google Events](#google-events)
- [YouTube](#youtube)
- [Tripadvisor](#tripadvisor)
- [OpenTable Reviews](#opentable-reviews)
- [Bing](#bing)
- [DuckDuckGo](#duckduckgo)
- [Yahoo](#yahoo)
- [Baidu](#baidu)
- [Yandex](#yandex)
- [Naver](#naver)
- [Walmart](#walmart)
- [eBay](#ebay)
- [Home Depot](#home-depot)
- [Apple App Store](#apple-app-store)
- [Google Play](#google-play)

---

## Google Web Search

**Engine:** `google`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query. Supports `site:`, `inurl:`, `intitle:` operators |
| `location` | No | Origin location (city-level recommended) |
| `gl` | No | Country code (e.g., `us`, `uk`, `fr`) |
| `hl` | No | Language code (e.g., `en`, `es`) |
| `num` | No | Number of results (max 100) |
| `start` | No | Result offset for pagination |
| `tbs` | No | Time-based and other filters |
| `device` | No | `desktop` (default), `mobile`, `tablet` |
| `tbm` | No | Search type: `nws` (news), `shop` (shopping), `isch` (images) |

**Key response fields:** `organic_results[]`, `ads[]`, `shopping_results[]`, `local_results`, `knowledge_graph`, `answer_box`, `related_questions[]`, `serpapi_pagination`

---

## Google Images

**Engine:** `google_images` (full) or `google_images_light` (faster, fewer fields)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `gl`, `hl`, `location` | No | Localization |
| `imgsz` | No | Size: `l` (large), `m` (medium), `i` (icon), or megapixels: `2mp`, `4mp`, `8mp` etc. |
| `imgtype` | No | `photo`, `clipart`, `lineart`, `animated` |
| `image_color` | No | `color`, `gray`, `trans` (transparent) |
| `licenses` | No | `cl` (Creative Commons), `ol` (commercial) |
| `period_unit` | No | Time filter: `s` (sec), `n` (min), `h` (hour), `d` (day), `w` (week), `m` (month), `y` (year) |
| `period_value` | No | Multiplier for period_unit (default 1) |
| `start_date`, `end_date` | No | Date range filter (YYYYMMDD format) |

**Related content:** Use `google_images_related_content` engine with `related_content_id` from image results.

**Key response fields:** `images_results[]` (title, original, thumbnail, source, link, original_width, original_height), `suggested_searches[]`

---

## Google Maps

**Engines:** `google_maps` (search/place), `google_maps_reviews`, `google_maps_photos`, `google_maps_posts`

### google_maps

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | For search | Search query (required when `type=search`) |
| `type` | No | `search` (default) or omit for place lookup |
| `ll` | No | GPS coords: `@lat,lon,zoom` (e.g., `@40.7455,-74.0083,14z`) |
| `location` | No | Named location (alternative to ll) |
| `place_id` | No | Google Place ID for direct lookup |
| `data_cid` | No | Google CID for direct lookup |
| `gl`, `hl` | No | Localization |
| `nearby` | No | Force nearby results (use with `ll`) |

**Key response fields:** `local_results[]` (title, rating, reviews, address, gps_coordinates, place_id, data_id, phone, website, hours, type), `place_results` (for single place)

### google_maps_reviews

| Parameter | Required | Description |
|-----------|----------|-------------|
| `data_id` | Yes | From `local_results[].data_id` |
| `sort_by` | No | `qualityScore` (default), `newestFirst`, `ratingHigh`, `ratingLow` |
| `hl` | No | Language |
| `next_page_token` | No | Pagination token |

### google_maps_photos / google_maps_posts

Use `data_id` from maps results. Photos returns image URLs; posts returns business posts.

---

## Google Flights

**Engines:** `google_flights`, `google_flights_autocomplete`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `departure_id` | No | Airport code (e.g., `JFK`) or location kgmid (e.g., `/m/0vzm`). Comma-separate multiple. |
| `arrival_id` | No | Same format as departure_id |
| `outbound_date` | No | YYYY-MM-DD format |
| `return_date` | No | YYYY-MM-DD (required for round trip) |
| `type` | No | `1` round trip (default), `2` one-way, `3` multi-city |
| `travel_class` | No | `1` economy, `2` premium economy, `3` business, `4` first |
| `adults` | No | Default 1 |
| `children`, `infants_in_seat`, `infants_on_lap` | No | Passenger counts |
| `stops` | No | `0` nonstop, `1` ≤1 stop, `2` ≤2 stops |
| `max_price` | No | Maximum price filter |
| `bags` | No | Number of checked bags |
| `exclude_airlines`, `include_airlines` | No | Comma-separated airline codes |
| `currency` | No | Default USD |
| `gl`, `hl` | No | Localization |
| `multi_city_json` | No | JSON array for type=3 multi-city flights |
| `departure_token` | No | Token for return flight details (from outbound results) |
| `booking_token` | No | Token for booking link details |
| `deep_search` | No | `true` for more thorough results (slower) |

**Key response fields:** `best_flights[]`, `other_flights[]` (each with `flights[]` containing airline, departure/arrival airport, duration, etc.), `price_insights`, `airports[]`

**Autocomplete:** `google_flights_autocomplete` with `q=city_name` returns airport codes and kgmids.

---

## Google Hotels

**Engines:** `google_hotels`, `google_hotels_autocomplete`, `google_hotels_reviews`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query (e.g., "hotels in Paris") |
| `check_in_date` | Yes | YYYY-MM-DD |
| `check_out_date` | Yes | YYYY-MM-DD |
| `adults` | No | Default 2 |
| `children` | No | Default 0 |
| `children_ages` | No | Comma-separated ages (1-17) |
| `sort_by` | No | `3` lowest price, `8` highest rating, `13` most reviewed |
| `min_price`, `max_price` | No | Price range |
| `property_types` | No | Comma-separated type IDs |
| `amenities` | No | Comma-separated amenity IDs |
| `rating` | No | `7` (3.5+), `8` (4.0+), `9` (4.5+) |
| `vacation_rentals` | No | `true` for vacation rentals instead of hotels |
| `property_token` | No | For specific property details |
| `gl`, `hl`, `currency` | No | Localization |

**Key response fields:** `properties[]` (name, description, total_rate, rate_per_night, hotel_class, overall_rating, reviews, amenities, images, gps_coordinates, property_token)

**Reviews:** `google_hotels_reviews` with `property_token`. Optional `category_token` for filtered reviews.

**Autocomplete:** `google_hotels_autocomplete` with `q` returns hotel/location suggestions.

---

## Google Scholar

**Engine:** `google_scholar`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query (supports `author:`, `source:` operators) |
| `as_ylo` | No | Year from (e.g., `2020`) |
| `as_yhi` | No | Year to |
| `cites` | No | Article ID for "Cited by" searches |
| `cluster` | No | Article ID for "All versions" |
| `scisbd` | No | `1` abstracts sorted by date, `2` everything sorted by date |
| `hl` | No | Language |
| `lr` | No | Language filter (e.g., `lang_en\|lang_fr`) |
| `start` | No | Result offset for pagination |
| `num` | No | Results per page |

**Key response fields:** `organic_results[]` (title, link, snippet, publication_info, inline_links.cited_by, inline_links.versions, resources[])

---

## Google News

**Engine:** `google_news`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | No | Search query (supports `when:`, `site:` operators) |
| `gl`, `hl` | No | Localization |
| `topic_token` | No | For browsing specific topics (from news_results) |

**Key response fields:** `news_results[]` (title, link, source, date, snippet, thumbnail)

---

## Google Shopping

**Engine:** `google_shopping`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `location`, `gl`, `hl` | No | Localization |
| `tbs` | No | Filters (price range, condition, etc.) |

**Key response fields:** `shopping_results[]` (title, link, source, price, extracted_price, rating, reviews, thumbnail)

---

## Google Jobs

**Engine:** `google_jobs`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Job search query |
| `location` | No | Job location |
| `gl`, `hl` | No | Localization |
| `chips` | No | Filter chips (from initial results) |
| `ltype` | No | `1` fulltime, `2` parttime, `3` contractor, `4` internship |

**Key response fields:** `jobs_results[]` (title, company_name, location, description, detected_extensions, job_highlights[])

---

## Google Finance

**Engine:** `google_finance`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Ticker or instrument (e.g., `GOOGL:NASDAQ`, `BTC:USD`) |
| `hl` | No | Language |
| `window` | No | Chart timeframe: `1D`, `5D`, `1M`, `6M`, `YTD`, `1Y`, `5Y`, `MAX` |

**Key response fields:** `summary` (title, stock, exchange, price, currency, previous_close), `graph[]`, `financials`, `news_results[]`

---

## Google Trends

**Engine:** `google_trends`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Query or queries (comma-separated, max 5 for TIMESERIES/GEO_MAP) |
| `data_type` | No | `TIMESERIES` (default), `GEO_MAP`, `GEO_MAP_0`, `RELATED_TOPICS`, `RELATED_QUERIES` |
| `geo` | No | Location code (e.g., `US`, `US-NY`) |
| `date` | No | Time range: `now 1-H`, `now 4-H`, `now 1-d`, `now 7-d`, `today 1-m`, `today 3-m`, `today 12-m`, `today 5-y`, `all` |
| `cat` | No | Category ID |
| `tz` | No | Timezone offset in minutes (default 420/PDT) |
| `hl` | No | Language |

**Key response fields:** Depends on data_type. TIMESERIES: `interest_over_time.timeline_data[]`; GEO_MAP: `compared_breakdown_by_region[]`; RELATED: `related_topics/queries.rising[]`, `.top[]`

---

## Google Autocomplete

**Engine:** `google_autocomplete`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Partial query |
| `gl`, `hl` | No | Localization |

**Key response fields:** `suggestions[]` (value, type)

---

## Google Ads Transparency Center

**Engines:** `google_ads_transparency_center`, `google_ads_transparency_center_ad_details`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `advertiser_id` | No | Advertiser ID (e.g., `AR17828074650563772417`) |
| `text` | No | Free-text domain search (alternative to advertiser_id) |
| `platform` | No | `PLAY`, `MAPS`, `SEARCH`, `SHOPPING`, `YOUTUBE` |
| `creative_format` | No | `text`, `image`, `video` |
| `region` | No | Region filter |
| `start_date`, `end_date` | No | YYYYMMDD format |
| `political_ads` | No | `true` for political ads only (requires `region`) |

**Ad details:** Use `google_ads_transparency_center_ad_details` with `advertiser_id` + `creative_id`.

---

## Google Local Services

**Engine:** `google_local_services`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Service query (e.g., "electrician") |
| `data_cid` | No | Business CID for details |
| `place_id` | No | Google Place ID |

---

## Google Events

**Engine:** `google_events`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Event search query |
| `location` | No | Location |
| `gl`, `hl` | No | Localization |

---

## YouTube

**Engines:** `youtube`, `youtube_video`, `youtube_video_transcript`

### youtube (Search)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `search_query` | Yes | Search query |
| `gl`, `hl` | No | Localization |
| `sp` | No | Filter/pagination token |

**Common sp filters:** `CAI%3D` (sort by upload date), `EgIIAg%3D%3D` (today), `EgIIAw%3D%3D` (this week), `EgIIBA%3D%3D` (this month), `EgIQAQ%3D%3D` (videos only), `EgIQAg%3D%3D` (channels only), `EgIYAQ%3D%3D` (under 4 min), `EgIYAw%3D%3D` (4-20 min), `EgIYAg%3D%3D` (over 20 min), `EgJwAQ%3D%3D` (4K), `EgJAAQ%3D%3D` (live). Custom filters: apply on YouTube, copy `sp` from URL.

**Key response fields:** `video_results[]`, `channel_results[]`, `shorts_results[]`, `playlist_results[]`, `serpapi_pagination.next_page_token`

### youtube_video (Details)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `v` | Yes | Video ID |
| `gl`, `hl` | No | Localization |
| `next_page_token` | No | For comments/related video pagination |

**Key response fields:** `title`, `channel`, `views`, `likes`, `published_date`, `description`, `chapters[]`, `comments[]`, `related_videos[]`, pagination tokens

### youtube_video_transcript

| Parameter | Required | Description |
|-----------|----------|-------------|
| `v` | Yes | Video ID |
| `language_code` | No | Default `en` |
| `title` | No | Specific transcript name |
| `type` | No | `asr` for auto-generated |

**Key response fields:** `transcript[]` (start_ms, end_ms, snippet, start_time_text), `chapters[]`, `available_transcripts[]`

---

## Tripadvisor

**Engines:** `tripadvisor`, `tripadvisor_place`

### tripadvisor (Search)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `lat`, `lon` | No | GPS coordinates for location bias |
| `tripadvisor_domain` | No | Default `tripadvisor.com` |
| `ssrc` | No | Filter: `a` all, `r` restaurants, `A` things to do, `h` hotels, `g` destinations, `f` forums |

**Key response fields:** `results[]` (title, place_id, rating, reviews, address, type)

### tripadvisor_place (Details)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `place_id` | Yes | Tripadvisor place ID (from search results) |

**Key response fields:** Full place details including reviews, photos, hours, price_range, cuisine

---

## OpenTable Reviews

**Engine:** `open_table_reviews`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `rid` | Yes | Restaurant ID from URL path (e.g., `r/central-park-boathouse-new-york-2`) |
| `page` | No | Page number (10 reviews per page) |
| `open_table_domain` | No | Default `www.opentable.com` |

**Key response fields:** `reviews[]` (rating, text, date, reviewer), `restaurant_info`, `total_reviews`

---

## Bing

**Engine:** `bing`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `cc` | No | Country code |
| `setlang` | No | Language |
| `first` | No | Result offset for pagination |
| `count` | No | Results per page |

---

## DuckDuckGo

**Engine:** `duckduckgo`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `kl` | No | Region and language (e.g., `us-en`) |

---

## Yahoo

**Engine:** `yahoo`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `p` | Yes | Search query (note: `p`, not `q`) |
| `pz` | No | Results per page |

---

## Baidu

**Engine:** `baidu`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |

---

## Yandex

**Engine:** `yandex`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `text` | Yes | Search query (note: `text`, not `q`) |

---

## Naver

**Engine:** `naver`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `query` | Yes | Search query (note: `query`, not `q`) |

---

## Walmart

**Engine:** `walmart`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `query` | Yes | Search query (note: `query`, not `q`) |

---

## eBay

**Engine:** `ebay`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `_nkw` | Yes | Search query (note: `_nkw`, not `q`) |

---

## Home Depot

**Engine:** `home_depot`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |

---

## Apple App Store

**Engine:** `apple_app_store`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `term` | Yes | Search query (note: `term`, not `q`) |

---

## Google Play

**Engine:** `google_play`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `store` | No | `apps`, `books`, `movies` |
| `gl`, `hl` | No | Localization |
