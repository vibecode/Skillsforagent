# SerpApi TripAdvisor — API Reference

Complete parameter tables, response schemas, and JSON examples for both TripAdvisor engines.

## Table of Contents

1. [TripAdvisor Search Engine](#1-tripadvisor-search-engine)
2. [TripAdvisor Place Engine](#2-tripadvisor-place-engine)
3. [Response Schemas by Place Type](#3-response-schemas-by-place-type)
4. [Localization Domains](#4-localization-domains)

---

## 1. TripAdvisor Search Engine

**Endpoint:** `GET https://serpapi.com/search?engine=tripadvisor`

### All Parameters

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `q` | Yes | string | Search query |
| `ssrc` | No | string | Category filter: `a` (All), `r` (Restaurants), `A` (Things to Do), `h` (Hotels), `g` (Destinations), `f` (Forums) |
| `lat` | No | float | GPS latitude for location-based search |
| `lon` | No | float | GPS longitude for location-based search |
| `tripadvisor_domain` | No | string | Localized domain (default: `tripadvisor.com`) |
| `offset` | No | int | Result offset for pagination (0, 30, 60, ...) |
| `limit` | No | int | Max results per page (default: 30, max: 100) |
| `no_cache` | No | boolean | Force fresh results (`true`/`false`) |
| `async` | No | boolean | Submit and retrieve later via Search Archive |
| `api_key` | Yes | string | SerpApi API key |
| `output` | No | string | `json` (default) or `html` |

### Search Response Schema

```json
{
  "search_metadata": {
    "id": "...",
    "status": "Success",
    "tripadvisor_url": "https://www.tripadvisor.com/Search?q=Rome&ssrc=a&geo=1&offset=0&limit=10",
    "total_time_taken": 1.28
  },
  "search_parameters": {
    "engine": "tripadvisor",
    "q": "Rome",
    "tripadvisor_domain": "www.tripadvisor.com",
    "ssrc": "a",
    "offset": 0
  },
  "places": [
    {
      "position": 1,
      "title": "Rome",
      "place_id": 187791,
      "place_type": "GEO",
      "link": "https://www.tripadvisor.com/Tourism-g187791-Rome_Lazio-Vacations.html",
      "description": "Rome wasn't built in a day...",
      "location": "Lazio, Italy",
      "thumbnail": "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/..."
    },
    {
      "position": 2,
      "title": "Rome: Colosseum, Roman Forum and Palatine Hill Guided Tour",
      "place_id": 11449756,
      "place_type": "ATTRACTION_PRODUCT",
      "link": "https://www.tripadvisor.com/AttractionProductReview-g187791-d11449756-...",
      "description": "The Colosseum is one of Rome's most popular landmarks...",
      "rating": 4.5,
      "reviews": 5785,
      "location": "Rome, Lazio, Italy",
      "thumbnail": "https://...",
      "highlighted_review": {
        "text": "From the awe-inspiring Colosseum to the serene majesty...",
        "highlighted_texts": ["Rome's"],
        "mention_count": 1160
      }
    }
  ],
  "serpapi_pagination": {
    "next": "https://serpapi.com/search.json?engine=tripadvisor&limit=10&offset=10&q=Rome&ssrc=a"
  }
}
```

### Place Types

| `place_type` | Meaning |
|--------------|---------|
| `GEO` | Destination (city, region, country) |
| `ACCOMMODATION` | Hotel / lodging |
| `RESTAURANT` | Restaurant |
| `EATERY` | Quick eat / café |
| `ATTRACTION` | Attraction |
| `ATTRACTION_PRODUCT` | Tour or experience product |

---

## 2. TripAdvisor Place Engine

**Endpoint:** `GET https://serpapi.com/search?engine=tripadvisor_place`

### All Parameters

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `place_id` | Yes | int | TripAdvisor place ID (from search results) |
| `tripadvisor_domain` | No | string | Localized domain (default: `tripadvisor.com`) |
| `no_cache` | No | boolean | Force fresh results |
| `async` | No | boolean | Submit and retrieve later |
| `api_key` | Yes | string | SerpApi API key |
| `output` | No | string | `json` (default) or `html` |

---

## 3. Response Schemas by Place Type

### Destination (type: "destination")

```json
{
  "place_result": {
    "type": "destination",
    "name": "Paris, France",
    "images": ["https://..."],
    "travel_advice": [
      { "title": "Best area to stay", "link": "https://..." },
      { "title": "Best time to visit", "link": "https://..." },
      { "title": "Multi-day itineraries", "link": "https://..." }
    ],
    "attraction_suggestions": {
      "items": [
        {
          "name": "Eiffel Tower",
          "place_id": "188151",
          "link": "https://...",
          "serpapi_link": "https://serpapi.com/search.json?place_id=188151&...",
          "thumbnail": "https://...",
          "rating": 4.6,
          "reviews": 143709,
          "address": "Av. Gustave Eiffel, 75007 Paris France",
          "categories": ["Observation Decks & Towers", "Points of Interest & Landmarks"]
        }
      ],
      "link": "https://www.tripadvisor.com/Attractions-g187147-Activities-Paris_Ile_de_France.html"
    },
    "hotel_suggestions": {
      "items": [
        {
          "name": "Grand Hotel Du Palais Royal",
          "place_id": "617625",
          "rating": 4.8,
          "reviews": 1886,
          "price": 411.42,
          "address": "4 Rue de Valois, 75001 Paris France"
        }
      ],
      "link": "https://..."
    },
    "restaurant_suggestions": {
      "items": [
        {
          "name": "La Table De Colette",
          "place_id": "19318900",
          "rating": 4.8,
          "reviews": 1409,
          "address": "17 Rue Laplace, 75005 Paris France",
          "cuisines": ["French", "European", "Healthy", "Contemporary"],
          "diets": ["Vegetarian friendly"]
        }
      ],
      "link": "https://..."
    }
  }
}
```

### Restaurant (type: "restaurant")

```json
{
  "place_result": {
    "type": "restaurant",
    "name": "Brasserie Les Deux Palais",
    "rating": 3.9,
    "reviews": 1243,
    "is_claimed": true,
    "ranking": "#863 of 20,004 Restaurants in Paris",
    "categories": [
      { "name": "Mid-range", "link": "https://..." },
      { "name": "French", "link": "https://..." }
    ],
    "images": ["https://..."],
    "website": "http://www.brasserielesdeuxpalais.fr/",
    "menu": {
      "link": "https://...",
      "provider": "SinglePlatform",
      "categories": [
        {
          "name": "Menu standard",
          "sections": [
            {
              "name": "ŒUFS",
              "description": "EGGS / Servis par 3 pièces...",
              "items": [
                {
                  "name": "Omelette mixte",
                  "description": "Ham and cheese omelette",
                  "price": 14.5
                }
              ]
            }
          ]
        }
      ],
      "popular_dishes": [
        { "name": "quiche lorraine maison, salade", "images": ["https://..."] }
      ]
    },
    "phone": "+33 1 43 54 20 86",
    "email": "reservationdeuxpalais@gmail.com",
    "description": "In the heart of historic Paris...",
    "cuisines": ["French", "Bar", "European"],
    "diets": ["Vegetarian friendly", "Gluten free options"],
    "meal_types": ["Breakfast", "Lunch", "Dinner"],
    "dining_options": ["Takeout", "Reservations", "Outdoor Seating"],
    "address": "3 Boulevard du Palais, 75004 Paris France",
    "address_link": "https://maps.google.com/maps?...",
    "neighborhood": "Ile de la Cité",
    "neighborhood_description": "Two islands sit in the middle of the Seine...",
    "operation_hours": {
      "currently_open": true,
      "hours": [
        { "day": "Monday", "hours": "07:00:00 - 23:00:00" },
        { "day": "Tuesday", "hours": "07:00:00 - 23:00:00" }
      ]
    },
    "reviews_summary": "Brasserie Les Deux Palais offers a charming dining experience...",
    "reviews_highlights": [
      {
        "category": "Wait time",
        "value": "Short",
        "summary": "For many travelers, wait times for a table are minimal...",
        "reviews_quotes": ["We needed a restaurant for an early dinner..."]
      },
      {
        "category": "Service",
        "value": "Varied",
        "summary": "For many travelers, the service stands out as friendly..."
      },
      {
        "category": "Food",
        "value": "Delicious",
        "summary": "Many travelers praise the restaurant's delicious French classics..."
      }
    ],
    "reviews_list": [
      {
        "title": "Great spot",
        "snippet": "For such a busy bistro the staff are amazing...",
        "link": "https://www.tripadvisor.com/ShowUserReviews-...",
        "rating": 5,
        "date": "2025-12-14",
        "author": {
          "username": "laurapA3925QX",
          "link": "https://www.tripadvisor.com/Profile/laurapA3925QX",
          "avatar": "https://...",
          "hometown": "London, United Kingdom"
        }
      }
    ]
  }
}
```

### Hotel (type: "hotel")

```json
{
  "place_result": {
    "type": "hotel",
    "name": "Hotel Rochester Champs Élysée",
    "rating": 4.4,
    "reviews": 1409,
    "ranking": "#454 of 1,873 hotels in Paris",
    "images": ["https://..."],
    "prices": {
      "check_in": "2025-12-28",
      "check_out": "2025-12-29",
      "rooms": 1,
      "guests": 2,
      "offers": [
        {
          "price": "$417",
          "extracted_price": 417,
          "provider": "Expedia.com",
          "additional_info": "Earn rewards for every stay",
          "link": "https://..."
        },
        {
          "price": "$330",
          "extracted_price": 330,
          "original_price": "$417",
          "extracted_original_price": 417,
          "lowest_price": true,
          "provider": "Agoda.com",
          "additional_info": "Multiple ways to pay",
          "rooms_remaining": 6,
          "link": "https://..."
        }
      ]
    },
    "price_trends": [
      { "date": "2025-12-17", "price": 343 },
      { "date": "2025-12-18", "price": 331 },
      { "date": "2025-12-19", "price": 293 }
    ],
    "subratings": [
      { "category": "Location", "score": 4.7 },
      { "category": "Rooms", "score": 4.4 },
      { "category": "Value", "score": 4.1 }
    ],
    "description": "Located only two steps from the Champs Elysées...",
    "operation_hours": { "...": "..." },
    "address": "92 Rue La Boetie, 75008 Paris France",
    "phone": "+33 ...",
    "website": "https://...",
    "neighborhood": "Champs-Élysées",
    "neighborhood_description": "...",
    "reviews_summary": "...",
    "reviews_highlights": ["... same structure as restaurant ..."],
    "reviews_list": ["... same structure as restaurant ..."]
  }
}
```

### Attraction (type: "attraction")

```json
{
  "place_result": {
    "type": "attraction",
    "name": "Louvre Museum",
    "rating": 4.6,
    "reviews": 104218,
    "ranking": "#15 of 4,211 things to do in Paris",
    "images": ["https://..."],
    "description": "With five floors, 500,000 artworks, and one glass pyramid...",
    "duration": "2-3 hours",
    "price": "$18",
    "extracted_price": 18,
    "operation_hours": {
      "currently_open": true,
      "hours": [
        { "day": "Monday", "hours": "9:00 AM - 6:00 PM" },
        { "day": "Tuesday", "hours": "Closed" },
        { "day": "Wednesday", "hours": "9:00 AM - 9:00 PM" }
      ]
    },
    "address": "99 Rue de Rivoli, 75001 Paris France",
    "neighborhood": "Louvre / Palais-Royal",
    "neighborhood_description": "...",
    "getting_here": [
      "Palais Royal – Musée du Louvre • 3 min walk",
      "Louvre – Rivoli • 5 min walk"
    ],
    "website": "http://www.louvre.fr",
    "phone": "+33 1 40 20 53 17",
    "email": "mailto:info@louvre.fr",
    "highlights": [
      {
        "title": "The Louvre Pyramid",
        "snippet": "A modern 1989 addition, this glass entrance structure...",
        "image": "https://..."
      },
      {
        "title": "Mona Lisa",
        "snippet": "The Louvre's star attraction, Leonardo da Vinci's masterpiece..."
      }
    ],
    "attraction_listings": [
      {
        "title": "Featured experiences",
        "list": [
          {
            "name": "Louvre Museum - Exclusive Guided Tour (Entry Included)",
            "place_id": "11457682",
            "link": "https://...",
            "serpapi_link": "https://serpapi.com/search.json?place_id=11457682&...",
            "thumbnail": "https://...",
            "rating": 5,
            "reviews": 3217,
            "type": "Private and Luxury",
            "duration": "2h 30m",
            "free_cancellation": true,
            "labels": ["Best Seller"],
            "price": "$180",
            "extracted_price": 180
          }
        ]
      },
      {
        "title": "Art Tours",
        "list": ["..."]
      },
      {
        "title": "Also popular with travelers",
        "list": ["..."]
      }
    ],
    "reviews_summary": "...",
    "reviews_highlights": ["... same structure as restaurant ..."],
    "reviews_list": ["... same structure as restaurant ..."]
  }
}
```

---

## 4. Localization Domains

All domains use `www.` prefix. Common options:

| Domain | Country |
|--------|---------|
| `www.tripadvisor.com` | United States |
| `www.tripadvisor.co.uk` | United Kingdom |
| `www.tripadvisor.ca` | Canada (English) |
| `fr.tripadvisor.ca` | Canada (French) |
| `www.tripadvisor.com.br` | Brazil |
| `www.tripadvisor.com.mx` | Mexico |
| `www.tripadvisor.com.ar` | Argentina |
| `www.tripadvisor.cl` | Chile |
| `www.tripadvisor.co` | Colombia |
| `www.tripadvisor.it` | Italy |
| `www.tripadvisor.es` | Spain |
| `www.tripadvisor.de` | Germany |
| `www.tripadvisor.fr` | France |
| `www.tripadvisor.se` | Sweden |
| `www.tripadvisor.nl` | Netherlands |
| `www.tripadvisor.com.tr` | Turkey |
| `www.tripadvisor.dk` | Denmark |
| `www.tripadvisor.ie` | Ireland |
| `www.tripadvisor.at` | Austria |
| `www.tripadvisor.com.gr` | Greece |

Full list downloadable from SerpApi's TripAdvisor domains page.
