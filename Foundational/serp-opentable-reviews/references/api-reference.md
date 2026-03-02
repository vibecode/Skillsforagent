# SerpApi OpenTable Reviews — API Reference

Complete endpoint documentation, full response schemas, and extended examples.

## Table of Contents

1. [Endpoint](#endpoint)
2. [Complete Parameters](#complete-parameters)
3. [Full Response Schema](#full-response-schema)
4. [Complete JSON Example](#complete-json-example)

---

## Endpoint

```
GET https://serpapi.com/search?engine=open_table_reviews
```

## Complete Parameters

### Search Parameters

| Parameter | Required | Type | Default | Description |
|-----------|----------|------|---------|-------------|
| `engine` | Yes | String | — | Must be `open_table_reviews` |
| `rid` | Yes | String | — | OpenTable Restaurant ID. Found in URL path after the first `/`. Example: `r/central-park-boathouse-new-york-2` |
| `open_table_domain` | No | String | `opentable.com` | OpenTable domain for localization |
| `page` | No | Integer | `1` | Page number. Each page returns 10 reviews |

### SerpApi Parameters

| Parameter | Required | Type | Default | Description |
|-----------|----------|------|---------|-------------|
| `api_key` | Yes | String | — | SerpApi private key |
| `no_cache` | No | Boolean | `false` | Force fresh results. Cache expires after 1h. Do not combine with `async` |
| `async` | No | Boolean | `false` | Submit search and retrieve later via Searches Archive API. Do not combine with `no_cache` |
| `output` | No | String | `json` | Output format: `json` or `html` |
| `json_restrictor` | No | String | — | Restrict output fields for smaller responses |
| `zero_trace` | No | Boolean | `false` | Enterprise only. Skip storing search data on SerpApi servers |

---

## Full Response Schema

### Top-Level Fields

```json
{
  "search_metadata": { ... },
  "search_parameters": { ... },
  "search_information": { ... },
  "reviews_summary": { ... },
  "awards": [ ... ],
  "reviews": [ ... ],
  "serpapi_pagination": { ... }
}
```

### `search_metadata`

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | SerpApi search ID |
| `status` | String | `"Processing"` → `"Success"` or `"Error"` |
| `json_endpoint` | String | URL to retrieve JSON results |
| `created_at` | String | When the search was created |
| `processed_at` | String | When the search completed |
| `open_table_reviews_url` | String | The OpenTable URL that was scraped |
| `raw_html_file` | String | URL to raw HTML |
| `total_time_taken` | Float | Processing time in seconds |

### `search_parameters`

Echo of submitted parameters:

| Field | Type | Description |
|-------|------|-------------|
| `engine` | String | `"open_table_reviews"` |
| `rid` | String | Restaurant ID used |
| `open_table_domain` | String | Domain used |
| `page` | String | Page number requested |

### `search_information`

| Field | Type | Description |
|-------|------|-------------|
| `page` | Integer | Current page number |
| `total_pages` | Integer | Total pages available |

### `reviews_summary`

| Field | Type | Description |
|-------|------|-------------|
| `reviews_count` | Integer | Total number of reviews |
| `ratings_count` | Integer | Total number of ratings |
| `ratings_summary` | Object | See below |
| `ratings` | Array | Star distribution |
| `ai_summary` | String | AI-generated summary of all reviews |

#### `reviews_summary.ratings_summary`

| Field | Type | Description |
|-------|------|-------------|
| `overall` | Float | Overall average rating (1.0–5.0) |
| `food` | Float | Average food rating (1.0–5.0) |
| `service` | Float | Average service rating (1.0–5.0) |
| `ambience` | Float | Average ambience rating (1.0–5.0) |
| `value` | Float | Average value rating (1.0–5.0) |
| `noise` | String | Noise level: `"Quiet"`, `"Moderate"`, `"Energetic"`, `"Loud"` |

#### `reviews_summary.ratings[]`

| Field | Type | Description |
|-------|------|-------------|
| `stars` | Integer | Star rating (1–5) |
| `count` | Integer | Number of ratings with this star value |

### `awards[]`

Optional. Present when the restaurant has OpenTable awards.

| Field | Type | Description |
|-------|------|-------------|
| `location` | String | Location of the award (e.g., city) |
| `name` | String | Award name |

### `reviews[]`

Array of review objects (10 per page).

| Field | Type | Presence | Description |
|-------|------|----------|-------------|
| `id` | String | Always | Unique review identifier (e.g., `"OT-1294132-115898-100028063230"`) |
| `content` | String | Always | Review text. May contain HTML tags |
| `dined_at` | String | Always | ISO 8601 datetime of the dining occasion |
| `submitted_at` | String | Always | ISO 8601 datetime of review submission |
| `user` | Object | Always | Reviewer information (see below) |
| `rating` | Object | Always | Review ratings (see below) |
| `helpfulness` | Object | Optional | Helpful vote counts |
| `images` | Array | Optional | Photos attached to the review |
| `response` | Object | Optional | Restaurant's response to the review |

#### `reviews[].user`

| Field | Type | Presence | Description |
|-------|------|----------|-------------|
| `name` | String | Always | Reviewer's display name |
| `number_of_reviews` | Integer | Always | Total reviews by this user on OpenTable |
| `location` | String | Optional | Reviewer's location |
| `vip` | Boolean | Optional | `true` if the reviewer is an OpenTable VIP diner |
| `avatar` | String | Optional | URL to the reviewer's profile photo |

#### `reviews[].rating`

| Field | Type | Description |
|-------|------|-------------|
| `overall` | Integer | Overall rating (1–5) |
| `food` | Integer | Food quality rating (1–5) |
| `service` | Integer | Service quality rating (1–5) |
| `ambience` | Integer | Ambience rating (1–5) |
| `value` | Integer | Value for money rating (1–5) |
| `noise` | String | Noise level during visit |

#### `reviews[].helpfulness`

| Field | Type | Description |
|-------|------|-------------|
| `up` | Integer | Number of "helpful" votes |
| `score` | Integer | Net helpful score |

#### `reviews[].images[]`

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Image ID |
| `timestamp` | String | ISO 8601 datetime of upload |
| `variants` | Array | Image variants in different sizes |

#### `reviews[].images[].variants[]`

| Field | Type | Description |
|-------|------|-------------|
| `size` | String | Size key: `"small"`, `"medium"`, `"xlarge"`, `"wideMedium"`, `"wideLarge"` |
| `url` | String | Direct URL to the image |

#### `reviews[].response`

Present when the restaurant has replied to the review.

| Field | Type | Description |
|-------|------|-------------|
| `content` | String | Restaurant's response text |
| `date` | String | ISO 8601 datetime of the response |

### `serpapi_pagination`

| Field | Type | Presence | Description |
|-------|------|----------|-------------|
| `previous` | String | Optional | Full SerpApi URL for the previous page |
| `next` | String | Optional | Full SerpApi URL for the next page |

---

## Complete JSON Example

```json
{
  "search_metadata": {
    "id": "691d9554c9472f070bdeba2e",
    "status": "Success",
    "json_endpoint": "http://serpapi.com/searches/0f2e162a9cc910ef/691d9554c9472f070bdeba2e.json",
    "created_at": "2025-11-19 10:00:52 UTC",
    "processed_at": "2025-11-19 10:00:52 UTC",
    "open_table_reviews_url": "https://www.opentable.com/r/central-park-boathouse-new-york-2?page=36",
    "raw_html_file": "https://serpapi.com/searches/0f2e162a9cc910ef/691d9554c9472f070bdeba2e.html",
    "total_time_taken": 0.70
  },
  "search_parameters": {
    "engine": "open_table_reviews",
    "rid": "r/central-park-boathouse-new-york-2",
    "open_table_domain": "opentable.com",
    "page": "34"
  },
  "search_information": {
    "page": 34,
    "total_pages": 168
  },
  "reviews_summary": {
    "reviews_count": 1662,
    "ratings_count": 950,
    "ratings_summary": {
      "overall": 4.6,
      "food": 4.4,
      "service": 4.5,
      "ambience": 4.7,
      "value": 4.1,
      "noise": "Moderate"
    },
    "ratings": [
      { "stars": 1, "count": 14 },
      { "stars": 2, "count": 20 },
      { "stars": 3, "count": 79 },
      { "stars": 4, "count": 149 },
      { "stars": 5, "count": 688 }
    ],
    "ai_summary": "Central Park Boathouse offers a \"magical experience\" with \"wonderful food, service, views, and ambiance\" that enhances its iconic location. Guests praise the \"excellent service\" and \"delicious food\", while relishing the \"stunning\" lakeside views. \"Highly recommended\" for special occasions or a quintessential New York dining experience."
  },
  "reviews": [
    {
      "id": "OT-1294132-115898-100028063230",
      "content": "The view of the lake is stunning. A beautiful vibe. The BBQ brisket special was delicious. Our cocktails were refreshing & a perfect way to spend a sunny afternoon in Central Park.",
      "dined_at": "2025-07-04T15:30:00Z",
      "submitted_at": "2025-07-05T17:49:51Z",
      "user": {
        "name": "Julie",
        "number_of_reviews": 13,
        "location": "Nashville",
        "avatar": "https://resizer.otstatic.com/v2/photos/xsmall/1/58195520.jpg"
      },
      "rating": {
        "overall": 5,
        "food": 5,
        "service": 5,
        "ambience": 5,
        "value": 4,
        "noise": "Moderate"
      },
      "images": [
        {
          "id": "79221177",
          "timestamp": "2025-07-05T17:49:58Z",
          "variants": [
            { "size": "small", "url": "https://resizer.otstatic.com/v2/photos/small/1/79221177.jpg" },
            { "size": "medium", "url": "https://resizer.otstatic.com/v2/photos/medium/1/79221177.jpg" },
            { "size": "xlarge", "url": "https://resizer.otstatic.com/v2/photos/xlarge/1/79221177.jpg" },
            { "size": "wideMedium", "url": "https://resizer.otstatic.com/v2/photos/wide-medium/1/79221177.jpg" },
            { "size": "wideLarge", "url": "https://resizer.otstatic.com/v2/photos/wide-large/1/79221177.jpg" }
          ]
        }
      ]
    },
    {
      "id": "OT-1294132-114437-130038305383",
      "content": "The food and service were excellent. The BBQ brisket special was delicious. Our cocktails were refreshing.",
      "dined_at": "2025-07-03T17:30:00Z",
      "submitted_at": "2025-07-04T17:35:36Z",
      "user": {
        "name": "Lucy",
        "number_of_reviews": 37,
        "location": "New York City",
        "vip": true
      },
      "rating": {
        "overall": 5,
        "food": 5,
        "service": 5,
        "ambience": 5,
        "value": 5,
        "noise": "Quiet"
      },
      "response": {
        "content": "Thank you for the feedback, Lucy! We look forward to serving you again soon.\n\nBest,\nCentral Park Boathouse Team",
        "date": "2025-07-07T17:42:46Z"
      }
    }
  ],
  "serpapi_pagination": {
    "previous": "https://serpapi.com/search.json?engine=open_table_reviews&open_table_domain=opentable.com&page=35&rid=r/central-park-boathouse-new-york-2",
    "next": "https://serpapi.com/search.json?engine=open_table_reviews&open_table_domain=opentable.com&page=37&rid=r/central-park-boathouse-new-york-2"
  }
}
```
