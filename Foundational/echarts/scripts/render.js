#!/usr/bin/env node
// ECharts server-side renderer — JSON option → PNG/SVG image
// Usage:
//   echo '{"xAxis":{"data":["A","B"]},"series":[{"type":"bar","data":[10,20]}]}' | node render.js --out chart.png
//   node render.js --file option.json --out chart.png --width 1000 --height 600 --theme dark --bg '#1a1a2e'
//   node render.js --file option.json --out chart.svg --format svg

const echarts = require('echarts');
const fs = require('fs');

// --- Parse args ---
const args = process.argv.slice(2);
function getArg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && i + 1 < args.length ? args[i + 1] : fallback;
}

const outPath = getArg('out', 'chart.png');
const width = parseInt(getArg('width', '800'), 10);
const height = parseInt(getArg('height', '600'), 10);
const theme = getArg('theme', null);
const bgColor = getArg('bg', null);
const filePath = getArg('file', null);
const format = getArg('format', outPath.endsWith('.svg') ? 'svg' : 'png');

// --- Read option JSON ---
async function readInput() {
  if (filePath) {
    return fs.readFileSync(filePath, 'utf-8');
  }
  // Read from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf-8');
}

(async () => {
  try {
    const raw = await readInput();
    const option = JSON.parse(raw);

    if (bgColor && !option.backgroundColor) {
      option.backgroundColor = bgColor;
    }

    if (format === 'svg') {
      // SVG path — zero dependencies beyond echarts
      const chart = echarts.init(null, theme, {
        renderer: 'svg',
        ssr: true,
        width,
        height
      });
      chart.setOption(option);
      const svgStr = chart.renderToSVGString();
      fs.writeFileSync(outPath, svgStr, 'utf-8');
      chart.dispose();
    } else {
      // PNG path — requires canvas (node-canvas)
      const { createCanvas } = require('canvas');
      echarts.setPlatformAPI({
        createCanvas() { return createCanvas(); }
      });
      const canvas = createCanvas(width, height);
      const chart = echarts.init(canvas, theme);
      chart.setOption(option);
      const buffer = canvas.toBuffer('image/png');
      fs.writeFileSync(outPath, buffer);
      chart.dispose();
    }

    const stat = fs.statSync(outPath);
    console.log(JSON.stringify({ ok: true, path: outPath, format, width, height, bytes: stat.size }));
  } catch (err) {
    console.error(JSON.stringify({ ok: false, error: err.message }));
    process.exit(1);
  }
})();
