#!/usr/bin/env bash
# quickchart.sh — Wrapper for QuickChart.io chart + QR code generation
# Usage: bash quickchart.sh <command> [options]
#
# Commands:
#   chart   — Generate a chart image (bar, line, pie, doughnut, radar, scatter, etc.)
#   qr      — Generate a QR code image
#   short   — Create a short URL for a chart
#
# Requires: curl, jq (optional, for JSON output parsing)

set -euo pipefail

BASE_URL="${QUICKCHART_URL:-https://quickchart.io}"
API_KEY="${QUICKCHART_API_KEY:-}"

usage() {
  cat <<'EOF'
Usage: bash quickchart.sh <command> [options]

Commands:
  chart     Generate a chart image
  qr        Generate a QR code image
  short     Create a short URL for a chart

--- chart options ---
  --type TYPE         Chart type: bar, line, pie, doughnut, radar, scatter, bubble,
                      polarArea, radialGauge, gauge, sparkline, progressBar, horizontalBar,
                      violin, boxplot, sankey, funnel (default: bar)
  --labels L1,L2,...  Comma-separated X-axis labels
  --data D1,D2,...    Comma-separated data values (first dataset)
  --data2 D1,D2,...   Second dataset values
  --data3 D1,D2,...   Third dataset values
  --label1 NAME       Label for first dataset
  --label2 NAME       Label for second dataset
  --label3 NAME       Label for third dataset
  --title TEXT        Chart title
  --config JSON       Full Chart.js config JSON (overrides --type/--labels/--data)
  --width PX          Image width in pixels (default: 500)
  --height PX         Image height in pixels (default: 300)
  --dpr N             Device pixel ratio: 1 or 2 (default: 2)
  --bg COLOR          Background color (default: white)
  --format FMT        Output format: png, webp, svg, pdf (default: png)
  --version VER       Chart.js version: 2, 3, or 4 (default: 2)
  --out FILE          Save image to file (default: chart.png)
  --url-only          Print the image URL instead of downloading

--- qr options ---
  --text TEXT         QR code content (required)
  --size PX           Width/height in pixels (default: 300)
  --margin N          Whitespace in modules (default: 4)
  --dark HEX          Dark cell color (default: 000000)
  --light HEX         Light cell color (default: ffffff)
  --ec-level L        Error correction: L, M, Q, H (default: M)
  --format FMT        Output format: png or svg (default: png)
  --center-image URL  URL of center image
  --center-ratio N    Center image size ratio 0.0-1.0 (default: 0.3)
  --caption TEXT      Caption text below QR code
  --out FILE          Save image to file (default: qr.png)
  --url-only          Print the image URL instead of downloading

--- short options ---
  --config JSON       Full Chart.js config JSON (required)
  --width PX          Image width (default: 500)
  --height PX         Image height (default: 300)
  --bg COLOR          Background color
  --version VER       Chart.js version (default: 2)

EOF
  exit 1
}

# ─── Helpers ─────────────────────────────────────────────────

urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read().strip(), safe=''))"
}

build_chart_config() {
  local chart_type="$1" labels="$2" title="$3"
  shift 3
  local -a data_arrays=()
  local -a data_labels=()

  # Collect remaining args as paired (data, label)
  while [[ $# -ge 2 ]]; do
    data_arrays+=("$1")
    data_labels+=("$2")
    shift 2
  done

  # Build datasets JSON
  local datasets="["
  local colors=('rgba(54,162,235,0.7)' 'rgba(255,99,132,0.7)' 'rgba(75,192,192,0.7)' 'rgba(255,206,86,0.7)' 'rgba(153,102,255,0.7)')
  local border_colors=('rgba(54,162,235,1)' 'rgba(255,99,132,1)' 'rgba(75,192,192,1)' 'rgba(255,206,86,1)' 'rgba(153,102,255,1)')

  for i in "${!data_arrays[@]}"; do
    [[ $i -gt 0 ]] && datasets+=","
    local bg="${colors[$((i % ${#colors[@]}))]}"
    local bc="${border_colors[$((i % ${#border_colors[@]}))]}"
    local lbl="${data_labels[$i]:-Dataset $((i+1))}"
    datasets+="{\"label\":\"${lbl}\",\"data\":[${data_arrays[$i]}],\"backgroundColor\":\"${bg}\",\"borderColor\":\"${bc}\",\"borderWidth\":1"
    # Line charts: no fill by default
    if [[ "$chart_type" == "line" || "$chart_type" == "sparkline" ]]; then
      datasets+=",\"fill\":false"
    fi
    datasets+="}"
  done
  datasets+="]"

  # Build options
  local options=""
  if [[ -n "$title" ]]; then
    options=",\"options\":{\"title\":{\"display\":true,\"text\":\"${title}\"}}"
  fi

  # Build labels array
  local labels_json=""
  if [[ -n "$labels" ]]; then
    labels_json="\"labels\":[$(echo "$labels" | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')],"
  fi

  echo "{\"type\":\"${chart_type}\",\"data\":{${labels_json}\"datasets\":${datasets}}${options}}"
}

# ─── chart command ───────────────────────────────────────────

cmd_chart() {
  local chart_type="bar" labels="" title="" config=""
  local width=500 height=300 dpr=2 bg="white" format="png" version="2"
  local out="chart.png" url_only=false
  local data1="" data2="" data3=""
  local label1="" label2="" label3=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type)     chart_type="$2"; shift 2 ;;
      --labels)   labels="$2"; shift 2 ;;
      --data)     data1="$2"; shift 2 ;;
      --data2)    data2="$2"; shift 2 ;;
      --data3)    data3="$2"; shift 2 ;;
      --label1)   label1="$2"; shift 2 ;;
      --label2)   label2="$2"; shift 2 ;;
      --label3)   label3="$2"; shift 2 ;;
      --title)    title="$2"; shift 2 ;;
      --config)   config="$2"; shift 2 ;;
      --width)    width="$2"; shift 2 ;;
      --height)   height="$2"; shift 2 ;;
      --dpr)      dpr="$2"; shift 2 ;;
      --bg)       bg="$2"; shift 2 ;;
      --format)   format="$2"; shift 2 ;;
      --version)  version="$2"; shift 2 ;;
      --out)      out="$2"; shift 2 ;;
      --url-only) url_only=true; shift ;;
      *) echo "Unknown option: $1" >&2; usage ;;
    esac
  done

  # Build config if not provided directly
  if [[ -z "$config" ]]; then
    if [[ -z "$data1" ]]; then
      echo "Error: --data or --config is required" >&2
      exit 1
    fi
    # Collect datasets
    local -a ds=() dl=()
    ds+=("$data1"); dl+=("${label1:-Dataset 1}")
    [[ -n "$data2" ]] && { ds+=("$data2"); dl+=("${label2:-Dataset 2}"); }
    [[ -n "$data3" ]] && { ds+=("$data3"); dl+=("${label3:-Dataset 3}"); }

    # Build args for build_chart_config
    local -a build_args=("$chart_type" "$labels" "$title")
    for i in "${!ds[@]}"; do
      build_args+=("${ds[$i]}" "${dl[$i]}")
    done
    config=$(build_chart_config "${build_args[@]}")
  fi

  # Use POST endpoint (avoids URL encoding issues)
  local body
  body=$(cat <<ENDJSON
{
  "chart": ${config},
  "width": ${width},
  "height": ${height},
  "devicePixelRatio": ${dpr},
  "backgroundColor": "${bg}",
  "format": "${format}",
  "version": "${version}"
ENDJSON
)
  # Add API key if set
  if [[ -n "$API_KEY" ]]; then
    body="${body}, \"key\": \"${API_KEY}\""
  fi
  body="${body}}"

  if [[ "$url_only" == true ]]; then
    # Use short URL endpoint to get a link
    local resp
    resp=$(curl -sf -X POST "${BASE_URL}/chart/create" \
      -H "Content-Type: application/json" \
      -d "$body")
    if command -v jq &>/dev/null; then
      echo "$resp" | jq -r '.url'
    else
      echo "$resp" | grep -o '"url":"[^"]*"' | cut -d'"' -f4
    fi
  else
    # Download directly
    local http_code
    http_code=$(curl -s -o "$out" -w "%{http_code}" -X POST "${BASE_URL}/chart" \
      -H "Content-Type: application/json" \
      -d "$body")
    if [[ "$http_code" -ge 400 ]]; then
      echo "Error: HTTP ${http_code}" >&2
      # If output is text (error message), show it
      if file "$out" 2>/dev/null | grep -q text; then
        cat "$out" >&2
      fi
      rm -f "$out"
      exit 1
    fi
    echo "Saved: $out (${width}x${height} @ ${dpr}x, ${format})"
  fi
}

# ─── qr command ──────────────────────────────────────────────

cmd_qr() {
  local text="" size=300 margin=4 dark="000000" light="ffffff" ec_level="M"
  local format="png" center_image="" center_ratio="" caption=""
  local out="qr.png" url_only=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --text)         text="$2"; shift 2 ;;
      --size)         size="$2"; shift 2 ;;
      --margin)       margin="$2"; shift 2 ;;
      --dark)         dark="$2"; shift 2 ;;
      --light)        light="$2"; shift 2 ;;
      --ec-level)     ec_level="$2"; shift 2 ;;
      --format)       format="$2"; shift 2 ;;
      --center-image) center_image="$2"; shift 2 ;;
      --center-ratio) center_ratio="$2"; shift 2 ;;
      --caption)      caption="$2"; shift 2 ;;
      --out)          out="$2"; shift 2 ;;
      --url-only)     url_only=true; shift ;;
      *) echo "Unknown option: $1" >&2; usage ;;
    esac
  done

  if [[ -z "$text" ]]; then
    echo "Error: --text is required" >&2
    exit 1
  fi

  local encoded_text
  encoded_text=$(echo -n "$text" | urlencode)

  local url="${BASE_URL}/qr?text=${encoded_text}&size=${size}&margin=${margin}&dark=${dark}&light=${light}&ecLevel=${ec_level}&format=${format}"

  [[ -n "$center_image" ]] && {
    local enc_img
    enc_img=$(echo -n "$center_image" | urlencode)
    url+="&centerImageUrl=${enc_img}"
  }
  [[ -n "$center_ratio" ]] && url+="&centerImageSizeRatio=${center_ratio}"
  [[ -n "$caption" ]] && {
    local enc_cap
    enc_cap=$(echo -n "$caption" | urlencode)
    url+="&caption=${enc_cap}"
  }

  if [[ "$url_only" == true ]]; then
    echo "$url"
  else
    local http_code
    http_code=$(curl -s -o "$out" -w "%{http_code}" "$url")
    if [[ "$http_code" -ge 400 ]]; then
      echo "Error: HTTP ${http_code}" >&2
      rm -f "$out"
      exit 1
    fi
    echo "Saved: $out (${size}px, ${format})"
  fi
}

# ─── short command ───────────────────────────────────────────

cmd_short() {
  local config="" width=500 height=300 bg="" version="2"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)   config="$2"; shift 2 ;;
      --width)    width="$2"; shift 2 ;;
      --height)   height="$2"; shift 2 ;;
      --bg)       bg="$2"; shift 2 ;;
      --version)  version="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; usage ;;
    esac
  done

  if [[ -z "$config" ]]; then
    echo "Error: --config is required" >&2
    exit 1
  fi

  local body="{\"chart\":${config},\"width\":${width},\"height\":${height},\"version\":\"${version}\""
  [[ -n "$bg" ]] && body+=",\"backgroundColor\":\"${bg}\""
  [[ -n "$API_KEY" ]] && body+=",\"key\":\"${API_KEY}\""
  body+="}"

  local resp
  resp=$(curl -sf -X POST "${BASE_URL}/chart/create" \
    -H "Content-Type: application/json" \
    -d "$body")

  if command -v jq &>/dev/null; then
    local url
    url=$(echo "$resp" | jq -r '.url')
    echo "$url"
  else
    echo "$resp" | grep -o '"url":"[^"]*"' | cut -d'"' -f4
  fi
}

# ─── Main dispatcher ────────────────────────────────────────

[[ $# -lt 1 ]] && usage
CMD="$1"; shift

case "$CMD" in
  chart)  cmd_chart "$@" ;;
  qr)     cmd_qr "$@" ;;
  short)  cmd_short "$@" ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $CMD" >&2; usage ;;
esac
