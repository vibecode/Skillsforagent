---
name: vibecode-integration-buffer
display_name: Buffer
provider_skill: true
integration_dependencies:
  - buffer
description: >
  Buffer social media scheduling API for reading account/channel info and
  creating, editing, deleting, queuing, or scheduling posts.
  Consult this skill:
  1. When the user asks to schedule, queue, draft, publish, edit, or delete a
     social media post
  2. When the user asks which social channels are connected to their Buffer account
  3. When the user wants to see their Buffer queue or previously sent posts
  4. When the user mentions Buffer, social scheduling, or posting to Twitter/X,
     LinkedIn, Instagram, Facebook, etc. and has Buffer connected
metadata: {"openclaw": {"emoji": "📮", "requires": {"env": ["BUFFER_ACCESS_TOKEN"]}}}
---

# Buffer Integration

Buffer's API is a single GraphQL endpoint: **`https://api.buffer.com`**. Every
request is a `POST` to that base URL (no `/graphql` path).

**Auth**: Bearer token via `BUFFER_ACCESS_TOKEN`.

**Data model**: an `account` has one or more `organizations`. Each organization
has `channels` (connected social profiles). Posts are created on a specific
channel. So most calls need an **organization id** and/or a **channel id** — get
those first with the account and channels queries below.

**Rate limit**: 60 requests/minute.

GraphQL over `curl` uses a JSON body `{"query":"..."}`. Enum values
(`automatic`, `addToQueue`, `sent`, …) are **unquoted** inside the query.

## Get account and organizations

Start here — the organization id feeds every other call.

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { account { id name organizations { id name } } }"}'
```

## List connected channels

Needs an organization id. `service` is the platform (e.g. `twitter`,
`linkedin`, `instagram`). If `channels` is empty, the user has not connected any
social profiles inside Buffer yet — tell them to connect one at buffer.com.

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { channels(input:{organizationId:\"ORG_ID\"}) { id name service displayName isDisconnected } }"}'
```

## List posts (queue / sent)

Filter by `status` and `channelIds`. `PostStatus` values: `scheduled`, `sent`,
`error` (and `draft`). Results are a Relay connection (`edges { node { … } }`).

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { posts(first:20, input:{organizationId:\"ORG_ID\", filter:{status:[scheduled], channelIds:[\"CHANNEL_ID\"]}}) { edges { node { id text status dueAt channelId } } pageInfo { hasNextPage endCursor } } }"}'
```

## Create a post

Requires the `posts:write` scope. Creating a post is a real action on the user's
Buffer account — **confirm the exact text and the target channel with the user
before calling this.**

Required input fields: `channelId`, `text`, `schedulingType`, `mode`.

- `schedulingType`: `automatic` (Buffer picks the slot / publishes) or
  `notification` (Buffer reminds the user to post manually).
- `mode`: `addToQueue` (next open slot in the channel's schedule),
  `customScheduled` (at a specific `dueAt`), `shareNow`, or `shareNext`.

The response is a union — `PostActionSuccess` on success, `MutationError` on a
user-facing error — so always request both branches.

**Add to the queue** (next available slot):

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { createPost(input:{ text:\"Hello from the Buffer API\", channelId:\"CHANNEL_ID\", schedulingType:automatic, mode:addToQueue }) { ... on PostActionSuccess { post { id text dueAt } } ... on MutationError { message } } }"}'
```

**Schedule for a specific time** — use `mode:customScheduled` with an ISO 8601
`dueAt`:

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { createPost(input:{ text:\"Scheduled via API\", channelId:\"CHANNEL_ID\", schedulingType:automatic, mode:customScheduled, dueAt:\"2026-03-10T15:00:00.000Z\" }) { ... on PostActionSuccess { post { id text status dueAt } } ... on MutationError { message } } }"}'
```

If the API returns an error that `assets` is required, add `assets:[]` to the
input for a text-only post (`assets` is a non-null list in the schema).

## Edit a post

`editPost` requires `id`, `schedulingType`, and `mode` (same enums as
`createPost`) — re-send them alongside the fields you're changing. Same
`PostActionSuccess` / `MutationError` payload. Confirm the change with the user
first.

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { editPost(input:{ id:\"POST_ID\", text:\"Updated text\", schedulingType:automatic, mode:addToQueue }) { ... on PostActionSuccess { post { id text dueAt } } ... on MutationError { message } } }"}'
```

## Delete a post

`deletePost` takes only the post `id`. Its payload is a different union
(`DeletePostPayload`), so select `__typename` plus the success branch and check
the top-level `errors` array for failures. This is destructive — confirm with
the user first.

```bash
curl -s -X POST https://api.buffer.com \
  -H "Authorization: Bearer $BUFFER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { deletePost(input:{ id:\"POST_ID\" }) { __typename ... on DeletePostSuccess { id } } }"}'
```

## Beyond posts

Buffer exposes more operations, not detailed here — introspect the schema or see
the [docs](https://developers.buffer.com/reference.html) for exact input shapes
before using them:

- `movePostInQueue` — reorder a queued post (`id` + `position: QueuePosition!`; experimental)
- `post` / `channel` — fetch a single post or channel by id
- `aggregatedPostMetrics`, `dailyPostingLimits` — analytics
- **Ideas** library — `ideas`, `ideaGroups`, `createIdea`
- **Post templates** — `postTemplates`, `createPostTemplate`, `updatePostTemplate`, `deletePostTemplate`

## Notes

- Do not ask the user to paste tokens or read the environment — `BUFFER_ACCESS_TOKEN`
  is injected by the Buffer connection. If it is missing, the user has not
  connected Buffer; have them connect it in the app first.
- GraphQL always returns HTTP 200; check the JSON `errors` array and the
  `MutationError` branch rather than the HTTP status.
- Report a `MutationError` `message` back to the user verbatim — it is
  user-facing (e.g. missing scope, disconnected channel).
