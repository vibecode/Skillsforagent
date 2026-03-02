---
name: domainer-cli
description: Check domain name availability individually or in bulk.
metadata:
  author: vibecode-dev
  version: "1.0"
---

<tool>
<name>domainer-cli</name>
<description>Command line client for checking domain name availability.</description>

<download>
- macOS (Apple Silicon): https://domains.vibecodeapp.com/download/darwin/arm64/domainer-cli
- macOS (Intel): https://domains.vibecodeapp.com/download/darwin/amd64/domainer-cli
- Linux (x86_64): https://domains.vibecodeapp.com/download/linux/amd64/domainer-cli
- Windows (x86_64): https://domains.vibecodeapp.com/download/windows/amd64/domainer-cli

After downloading, make the binary executable (macOS/Linux):

    chmod +x domainer-cli
    mv domainer-cli /usr/local/bin/domainer-cli
</download>

<!-- Everything below is the output of: domainer-cli --help -->

<global-flags>
      --debug           Enable debug logging to stderr
      --output string   Output format: "text" or "json" (default "text")
</global-flags>

<output-formats>
The --output flag controls output for all commands:
- text (default): logfmt style key=value pairs, one line per result. Designed for grep and cut.
- json: single JSON object per invocation. Designed for jq.
</output-formats>

<command name="check">
<synopsis>Check whether a single domain name is available for registration.</synopsis>
<usage>domainer-cli check &lt;domain&gt;</usage>
<examples>
  # Check if a domain is available
  domainer-cli check example.com

  # Output as JSON
  domainer-cli check --output json example.com

  # Extract just the availability boolean
  domainer-cli check --output json example.com | jq '.available'

  # Conditionally print a message based on availability
  domainer-cli check --output json example.com | jq --raw-output 'if .available then "GO: \(.name)" else "TAKEN: \(.name)" end'

  # Filter for available domains in a shell loop
  domainer-cli check example.com | grep --fixed-strings "status=available"
</examples>
<text-output>
domain=example.com status=available
</text-output>
<json-output>
{"name":"example.com","available":true}
</json-output>
</command>

<command name="check-bulk">
<synopsis>Check availability of domain names listed in a file (one per line). Pass - or omit the file to read from stdin.</synopsis>
<usage>domainer-cli check-bulk [file] [flags]</usage>
<flags>
      --append-tld strings   TLDs to append to each name (e.g. --append-tld com --append-tld ai)
</flags>
<examples>
  # Check all domains in a file
  domainer-cli check-bulk domains.txt

  # Output as JSON
  domainer-cli check-bulk --output json domains.txt

  # Check names with specific TLDs (file contains bare names like "myapp")
  domainer-cli check-bulk --append-tld com --append-tld ai names.txt

  # Filter for only available domains
  domainer-cli check-bulk domains.txt | grep --fixed-strings "status=available"

  # Filter for unavailable domains
  domainer-cli check-bulk domains.txt | grep --fixed-strings "status=unavailable"

  # Extract just the available domain names
  domainer-cli check-bulk domains.txt | grep --fixed-strings "status=available" | cut --delimiter="=" --fields=2 | cut --delimiter=" " --fields=1

  # List only available domains as JSON
  domainer-cli check-bulk --output json domains.txt | jq --raw-output '.available[]'

  # Count available vs total
  domainer-cli check-bulk --output json domains.txt | jq '{total: ((.available | length) + (.unavailable | length)), available: (.available | length)}'

  # List only unavailable domains as JSON
  domainer-cli check-bulk --output json domains.txt | jq --raw-output '.unavailable[]'

  # Read domain names from stdin
  echo -e "a.com\nb.com" | domainer-cli check-bulk

  # Pipe names through with TLD expansion
  cat names.txt | domainer-cli check-bulk --append-tld com --append-tld ai -
</examples>
<text-output>
domain=a.com status=available
domain=b.com status=unavailable
domain=c.com status=available
</text-output>
<json-output>
{"available":["a.com","c.com"],"unavailable":["b.com"]}
</json-output>
</command>

</tool>