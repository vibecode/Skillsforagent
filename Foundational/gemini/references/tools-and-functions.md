# Gemini Tools & Function Calling Reference

Complete reference for function calling, code execution, and grounding tools.

## Function Calling

### Declaring Functions

Functions are declared in the `tools` array:

```json
{
  "tools": [{
    "functionDeclarations": [{
      "name": "get_weather",
      "description": "Get current weather for a location",
      "parameters": {
        "type": "object",
        "properties": {
          "location": {"type": "string", "description": "City name"},
          "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
        },
        "required": ["location"]
      }
    }]
  }]
}
```

### Function Calling Lifecycle

1. **User sends message** with function declarations in `tools`
2. **Model returns** a `functionCall` part (or text if no function needed)
3. **You execute** the function and get the result
4. **You send back** the result as a `functionResponse` part
5. **Model generates** the final text response using the function result

### Multi-turn with function calls

```json
{
  "contents": [
    {"role": "user", "parts": [{"text": "What's the weather in London and Paris?"}]},
    {"role": "model", "parts": [
      {"functionCall": {"name": "get_weather", "args": {"location": "London"}}},
      {"functionCall": {"name": "get_weather", "args": {"location": "Paris"}}}
    ]},
    {"role": "function", "parts": [
      {"functionResponse": {"name": "get_weather", "response": {"temp": 15, "condition": "cloudy"}}},
      {"functionResponse": {"name": "get_weather", "response": {"temp": 22, "condition": "sunny"}}}
    ]}
  ]
}
```

### Tool Config

Control function calling behavior:

```json
{
  "toolConfig": {
    "functionCallingConfig": {
      "mode": "AUTO"
    }
  }
}
```

| Mode | Behavior |
|------|----------|
| `AUTO` | Model decides: function call or text response (default) |
| `ANY` | Model always calls a function |
| `NONE` | No function calls allowed; text-only response |

Restrict to specific functions with `ANY` mode:

```json
{
  "toolConfig": {
    "functionCallingConfig": {
      "mode": "ANY",
      "allowedFunctionNames": ["get_weather"]
    }
  }
}
```

### Parameter Schema

Function parameters use OpenAPI-compatible JSON Schema:

| Feature | Supported |
|---------|-----------|
| `type` | string, number, integer, boolean, array, object |
| `enum` | ✓ |
| `description` | ✓ (strongly recommended for all params) |
| `required` | ✓ |
| `items` (array) | ✓ |
| `properties` (object) | ✓ |
| `nullable` | ✓ |
| `format` | Partial (date-time, etc.) |
| `default` | ✗ (not supported) |
| `oneOf/anyOf/allOf` | Limited |

## Parallel Function Calls

The model may return multiple `functionCall` parts in a single response. Execute them all and return all results in a single `function` turn.

## Compositional Function Calls

The model can chain function calls across turns — using the output of one call as input to another. This requires multiple round-trips.

## Native Tools

### Code Execution

Let the model write and run Python code in a sandboxed environment:

```json
{
  "tools": [{"codeExecution": {}}]
}
```

The model returns `executableCode` parts (the code) and `codeExecutionResult` parts (the output). Useful for math, data analysis, string manipulation.

### Google Search Grounding

Ground model responses in real-time Google Search results:

```json
{
  "tools": [{"googleSearch": {}}]
}
```

Response includes `groundingMetadata` with search queries, results, and web chunks used. Also returns `groundingChunks` with source URLs.

#### Dynamic Retrieval

Control when grounding happens:

```json
{
  "tools": [{
    "googleSearch": {
      "dynamicRetrievalConfig": {
        "mode": "MODE_DYNAMIC",
        "dynamicThreshold": 0.5
      }
    }
  }]
}
```

- `dynamicThreshold`: 0.0 (always ground) to 1.0 (never ground). Default: 0.3.
- `MODE_DYNAMIC`: Model decides based on query. `MODE_UNSPECIFIED`: Always ground.

### URL Context Tool

Let the model fetch and read URL content:

```json
{
  "tools": [{"urlContext": {}}]
}
```

The model can read URLs mentioned in the prompt or discover URLs via search. Response includes `urlContextMetadata` with fetched URL details.

## Combining Tools

Multiple tools can be used together:

```json
{
  "tools": [
    {"functionDeclarations": [...]},
    {"codeExecution": {}},
    {"googleSearch": {}}
  ]
}
```

**Restrictions:**
- Code execution and function declarations can coexist
- Google Search grounding can coexist with function declarations
- Check model documentation for specific combination support

## Grounding Metadata

When using Google Search grounding, the response includes:

```json
{
  "groundingMetadata": {
    "searchEntryPoint": {
      "renderedContent": "<html>..."
    },
    "groundingChunks": [
      {"web": {"uri": "https://...", "title": "..."}}
    ],
    "groundingSupports": [
      {
        "segment": {"startIndex": 0, "endIndex": 50, "text": "..."},
        "groundingChunkIndices": [0],
        "confidenceScores": [0.95]
      }
    ],
    "webSearchQueries": ["query used"]
  }
}
```

Use `groundingChunks` for citation URLs. Use `groundingSupports` to map specific response segments to their sources.
