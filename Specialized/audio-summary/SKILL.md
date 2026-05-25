---
name: audio-summary
description: >
  Turn articles, videos, or text into short two-host audio summaries using multi-voice dialogue.
  NotebookLM-style conversational recaps, not full podcasts. Use when: (1) converting a YouTube
  video into a short audio summary, (2) turning an article or blog post into a listenable recap,
  (3) creating a conversational audio digest from text content, (4) generating a two-host audio
  discussion of source material, (5) producing a quick audio briefing from a URL, (6) making
  content listenable as a short dialogue, (7) creating audio summaries of any length from 30
  seconds to 10+ minutes, (8) generating NotebookLM-style audio overviews. Default output is
  ~1 minute. Builds on: supadata, yt-dlp (source extraction), elevenlabs (multi-voice TTS).
metadata:
  openclaw:
    emoji: "🎙️"
    os: [linux]
---

# Audio Summary

Two-host conversational audio summaries from any source — articles, videos, or raw text. Think NotebookLM-style but short-form by default (~1 minute). Length adjustable from 30 seconds to 10+ minutes.

## Dependencies

This skill builds on three foundational skills:

- **supadata** — Transcript extraction and web scraping
- **yt-dlp** — Video metadata (title, description, chapters)
- **elevenlabs** — Multi-voice dialogue TTS

Load those skills when you need their API endpoints or CLI syntax. This skill focuses on the **workflow logic**.

## Workflow

### Step 1: Extract Source Content

Determine the source type and extract text content.

**YouTube video:**
1. Use **yt-dlp** to get metadata (title, description, chapters, channel name, duration)
2. Use **supadata** transcript endpoint to get the full transcript as plain text (`text=true`)
3. If supadata fails, try supadata's AI-generated transcript (`mode=generate`)

**Article / web page:**
1. Use **supadata** web scrape endpoint to get the page as markdown
2. Extract title, author, and body text from the result

**Raw text:**
1. Use the text as-is. The user provides it directly.

**Important:** Always capture the source title and author/channel — you'll use these in the dialogue intro.

### Step 2: Determine Target Length

Map the user's request to a dialogue word count. Spoken English averages ~150 words per minute.

| Target Duration | Word Count | Best For |
|----------------|-----------|----------|
| 30 seconds | ~75 words | Single-point highlight |
| 1 minute (default) | ~150 words | Quick recap of one source |
| 2-3 minutes | ~300-450 words | Solid overview with key points |
| 5 minutes | ~750 words | Detailed discussion with examples |
| 10+ minutes | ~1500+ words | Deep dive, multiple angles |

If the user doesn't specify a length, default to **1 minute (~150 words)**. If the source is very short (under 200 words), match the output to the source length — don't pad thin content.

### Step 3: Write the Dialogue Script

This is the core creative step. Transform the source material into a natural two-host conversation.

**The two hosts:**
- **Host A** — The explainer. Drives the narrative, introduces topics, delivers the key information.
- **Host B** — The reactor. Asks clarifying questions, expresses surprise or interest, adds brief commentary, keeps it conversational.

**Dialogue structure:**

1. **Hook** (1-2 exchanges): Host A teases the topic. Host B reacts with curiosity. Never start with "Welcome to..." — jump straight into the content.
2. **Core content** (bulk of dialogue): Host A explains key points. Host B interjects naturally — asking "wait, really?", rephrasing for clarity, or connecting to broader context.
3. **Wrap** (1 exchange): One host delivers a punchy takeaway or "the thing to remember here is..." moment. Keep it tight, no drawn-out goodbyes.

**Writing rules:**

- **Sound human.** Use contractions (it's, that's, don't). Use sentence fragments. People don't speak in complete paragraphs.
- **Vary turn length.** Host A gets longer turns (2-4 sentences) when explaining. Host B gets shorter turns (1-2 sentences) when reacting. Occasionally flip this.
- **No filler.** Cut "that's a great point" and "absolutely" — these waste audio time. Every line should advance the content or add genuine reaction.
- **Include natural speech markers.** "So basically...", "Here's the thing—", "Wait, so you're saying...", "Right, and the wild part is..."
- **Distill, don't transcribe.** For video/article sources, extract the 3-5 most interesting/important points. Don't try to cover everything — that's what the source is for.
- **Attribution in dialogue.** Work the source naturally into the conversation: "So this researcher at MIT found that..." or "There's this video from [channel] where they show..."

**Example (1-minute script, ~150 words):**

```
A: So apparently, the reason we feel more creative in the shower isn't about the water — it's about being in a state of low cognitive load.
B: Wait, so it's not the warm water relaxing you?
A: Nope. It's that your brain switches to default mode network — the same thing that happens when you're walking or doing dishes. You're not actively focused on anything.
B: So your mind is free to make connections it can't when you're staring at a problem.
A: Exactly. And the key finding here — this is from a neuroscience study at UPenn — is that forcing yourself to "think harder" about a creative problem actually makes it worse.
B: So the advice is literally "stop trying."
A: Pretty much. Step away, do something mindless, and let your brain do the work in the background.
```

### Step 4: Select Voices

Choose two contrasting voices from ElevenLabs that work well in dialogue.

**Voice selection criteria:**
- Pick one male, one female — or two voices with clearly different tones/pitches
- Avoid two voices that sound similar; the listener needs to instantly distinguish speakers
- Match the tone to the content: casual/warm voices for general interest, authoritative voices for technical/news content

**Recommended voice pairings** (use the elevenlabs skill's voice list command to discover current voices):

| Content Tone | Host A (Explainer) | Host B (Reactor) |
|-------------|-------------------|------------------|
| Casual / general | "Brian" or "Daniel" | "Lily" or "Jessica" |
| Professional / news | "Chris" or "George" | "Laura" or "Alice" |
| Energetic / fun | "Will" or "Charlie" | "Aria" or "Sarah" |

These are suggestions — the user may request specific voices, or you can discover better matches via the elevenlabs skill's voice search.

### Step 5: Generate Audio

Use the **elevenlabs** skill's dialogue command to generate the multi-voice audio file.

**Build the inputs array** from your dialogue script: each line becomes an entry with the text and the voice_id of the assigned speaker.

**Key settings:**
- Use the `eleven_v3` model for dialogue (it's the default and most expressive)
- Output format: `mp3_44100_128` (standard quality, good for most uses)
- Save to the user's requested path, or default to a descriptive filename like `summary-[source-title].mp3`

### Step 6: Deliver

Present the output to the user:
- File path to the generated audio
- Duration estimate (word count ÷ 150 wpm)
- Brief note on what was covered (2-3 bullet points)

If the user wants to iterate — different length, different angle, different voices — regenerate from Step 3 (you already have the source content).

## Handling Edge Cases

**Source is very long (>10,000 words):** Summarize the source to key points before writing dialogue. Focus on the most surprising, actionable, or important findings. Don't try to cover everything.

**Source is very short (<100 words):** The dialogue should be proportionally short. Don't fabricate detail. A tweet-length source gets a 20-30 second audio clip, not a 5-minute discussion.

**Source is a list/listicle:** Pick the top 3-5 items. Have Host A introduce each, Host B react. Don't mechanically go through every item.

**Multiple sources:** The user may provide several URLs or texts. Synthesize them into a unified dialogue that draws connections between sources. This naturally works better at 3-5 minute lengths.

**Non-English sources:** Use supadata's transcript translation or just work with the original language. For the dialogue, match the language of the source unless the user specifies otherwise. Use elevenlabs' multilingual model if generating non-English audio.

**User wants background music:** Generate the dialogue first, then use the elevenlabs skill's music generation to create a short background track. The user will need to mix them externally (or use ffmpeg to overlay with reduced music volume).

## Tips

- **Front-load the hook.** The first 10 seconds determine whether someone keeps listening. Start with the most surprising or compelling point.
- **Read it aloud mentally.** Before generating, read your dialogue script in your head. If any line sounds unnatural when spoken, rewrite it.
- **Shorter is almost always better.** A tight 1-minute summary that nails the key point beats a meandering 5-minute one. Only go long if the content warrants it.
- **The reactor matters.** Host B isn't decoration. Good reactor lines make the explainer's points land harder. "Wait, so that means..." forces the next line to be a clear payoff.
- **Don't summarize the summary.** Skip "So in summary..." or "To wrap up..." endings. Just end on the strongest point.
