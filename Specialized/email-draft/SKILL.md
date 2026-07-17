---
name: email-draft
description: >
  Create real Gmail drafts through the Chorus-managed gws CLI (requires the google
  integration), verify them against the live mailbox, and hand back an open-able link
  to each one for review. Use when Riley invokes /email-draft, is asked to draft one or
  more Gmail messages, is asked to pick actionable inbox conversations and prepare
  replies, or is asked to prepare saved Gmail drafts for review without sending them.
metadata: {"openclaw": {"emoji": "✉️", "requires": {"cli": ["gws"], "integrations": ["google"]}}}
---

# Email Draft

Create saved Gmail drafts through the `gws` CLI (Google Workspace, already authenticated —
do not re-run setup or read connection env vars directly), verify each one against the live
mailbox, and hand back a link so the draft can be opened for review. **Never send a message
unless the user separately and explicitly asks to send it.**

This channel has no in-app browser tab to open automatically. The equivalent here is a
plain markdown link per draft — links render inline and open in a new tab on their own when
clicked, which is the direct substitute for "open every draft in a separate browser tab."

## Workflow

### 1. Determine the draft targets

- If the user names recipients or threads, use those directly.
- If the user asks to pick a number of actionable conversations from the inbox, scan with:

  ```bash
  gws gmail +triage --query 'is:unread newer_than:7d -category:promotions -category:social' --max 20
  ```

  Adjust `newer_than:` to the timeframe the user wants. Exclude newsletters and automated
  noise (unsubscribe footers, no-reply senders, marketing sends). Prioritize direct requests,
  overdue replies, customer issues, scheduling, and qualified opportunities. Widen the query
  (drop `is:unread`, extend the timeframe) if too few actionable threads turn up.

- Read each selected thread in full before drafting — do not rely on the triage snippet when
  surrounding context could change the reply:

  ```bash
  gws gmail +read --id <messageId> --headers
  ```

  For a full multi-message thread, use `gws gmail users threads get --params '{"userId":"me","id":"<threadId>"}'`
  when a single message isn't enough context.

- Before drafting a reply, check whether a draft already exists on that thread:

  ```bash
  gws gmail users drafts list --params '{"userId":"me"}'
  ```

  Match on `message.threadId` against the thread you're about to reply to. If a draft is
  already sitting there, read it (step 4 below) and decide whether it already satisfies the
  request — if so, verify and report on that draft instead of creating a second, competing one
  on the same thread. Two near-duplicate drafts on one thread is confusing for whoever reviews
  them and easy to avoid with one extra list call.

### 2. Write each draft

- Keep the language concise, natural, and ready to send as-is.
- Preserve recipients, CCs, facts, dates, and links already present in the thread.
- Do not invent commitments, completed actions, prices, availability, or missing facts.
- Check group or support aliases carefully — if the visible sender is an alias but the thread
  reveals the actual person's address, address that person directly.
- For a reply, the subject and threading are handled automatically by `+reply` (see below) —
  do not hand-construct a subject or `In-Reply-To`/`References` headers yourself.

### 3. Save each draft — always with `--draft`

New message (no existing thread):

```bash
gws gmail +send --to "<email[,email...]>" --subject "<subject>" --body "<body>" --draft \
  [--cc "<emails>"] [--bcc "<emails>"] [--html] [-a "<path>" ...]
```

Reply inside an existing thread (preferred whenever a `messageId` already exists — this
handles `In-Reply-To`, `References`, `threadId`, and subject matching automatically, and quotes
the original message):

```bash
gws gmail +reply --message-id <messageId> --body "<body>" --draft \
  [--to "<extra emails>"] [--cc "<emails>"] [--bcc "<emails>"] [--html] [-a "<path>" ...]
```

- **Never omit `--draft`.** Without it, `+send`/`+reply` sends immediately and irreversibly.
- Only call without `--draft` when the user has explicitly and separately approved sending
  that specific message — approving the draft step is not approval to send.
- Use `--html` only when formatting materially helps; plain text is the default and matches
  the original skill's `content_type="text/plain"` preference.
- Attach files with repeated `-a <path>` flags (25MB total limit).

The create call returns the draft `id` (e.g. `r-5950458566971184765`) and `message.id`
(e.g. `19f6c1663ffcdfad`) — keep both; they are used differently in the next step.

### 4. Verify each draft against the live mailbox

Never trust the create response alone — confirm what Gmail actually stored:

```bash
gws gmail users drafts get --params '{"userId":"me","id":"<draft id>","format":"full"}'
```

Use the draft `id` here (the `r-...` value), not the message id. Confirm:

- `message.labelIds` includes `DRAFT`.
- The `To`, `Subject`, and body content match what was intended.
- If something doesn't match, `gws gmail users drafts update --params '{"userId":"me","id":"<draft id>"}' --json '{"message": {...}}'`
  to fix it, then re-verify — don't leave a mismatched draft and report it as correct.

### 5. Build a review link for each verified draft

Gmail's `#drafts?compose=<id>` deep-link format has changed and broken multiple times over
the years and is not reliable. Use a **Gmail search link on the message's RFC822 `Message-Id`
header** instead — this is a plain search query, not an undocumented deep-link hack, so it
does not rot the same way:

1. From the `drafts.get` response above, find the `Message-Id` header inside
   `message.payload.headers` (value looks like `<CAC7XN-...@mail.gmail.com>`).
2. Strip the surrounding `<` `>` angle brackets.
3. Build: `https://mail.google.com/mail/u/0/#search/rfc822msgid:<message-id-no-brackets>`

If the `Message-Id` header is missing for any reason, fall back to reporting the Gmail draft
`id` and telling the user to check the Drafts folder directly — do not invent or guess a link.

### 6. Validate summaries, then return results

- Lead with the fact that the drafts are saved, unsent, and linked below for review.
- Return exactly one bullet per draft in this format:

  `- Recipient - Subject - twenty-word summary`

  Make the subject a markdown link to the review URL from step 5, e.g.
  `- Jordan - [Project Sync Call](https://mail.google.com/mail/u/0/#search/rfc822msgid:...) - <20-word summary>`

- The summary must describe what the **drafted reply** says, not the incoming message.
- Every summary must be exactly 20 whitespace-delimited words. Hyphenated terms count as one
  word. The recipient and subject are not part of the word count.
- Validate every summary before responding:

  ```bash
  python3 ~/.chorus/skills/email-draft/scripts/check_summaries.py "- Recipient - Subject - <summary>"
  ```

  or batch-check a file with one line per draft via `--file <path>`. Revise and re-check any
  line that isn't exactly 20 words — do not eyeball the count.
- End with a brief reminder that nothing was sent. Don't add inbox-triage commentary unless
  the user asks for it.

## Example

`- Jordan - [Project Sync Call](https://mail.google.com/mail/u/0/#search/rfc822msgid:CAC7XN-example@mail.gmail.com) - Confirms tomorrow's meeting time, shares the video call link from the calendar invite, and says no advance preparation is required.`

The example summary is exactly 20 words — verified with `check_summaries.py`.

## Tips

- **`--draft` is the safety switch.** It is the only thing standing between "saved for review"
  and "sent to a real person." Treat its absence as equivalent to an explicit send command.
- **Use `+reply`, not `+send`, whenever a `messageId` already exists.** It gets threading,
  subject matching, and quoting right automatically — hand-building these is error-prone.
- **`drafts.get` takes the draft `id`, not the message `id`.** Mixing these up returns the
  wrong object or a 404.
- **Deep-link formats to Gmail drafts rot.** Don't hand-roll a `#drafts?compose=` URL from a
  raw id — Google has changed this encoding multiple times. The `rfc822msgid:` search link is
  the stable option because it's an ordinary search query.
- **This is a review tool, not a send tool.** If the user's request implies sending, stop and
  ask for explicit send approval before ever calling `+send`/`+reply` without `--draft`.
