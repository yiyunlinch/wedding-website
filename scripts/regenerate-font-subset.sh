#!/bin/bash
# Regenerate the Long Cang font subset to cover all characters used in *.html.
# Run this after adding new Chinese text to any page, then commit the fonts/ changes.
# Requires: python3 with fonttools and brotli (pip3 install fonttools brotli)
set -euo pipefail
cd "$(dirname "$0")/.."

FULL_TTF=/tmp/LongCang-Regular.ttf
if [ ! -f "$FULL_TTF" ]; then
  curl -sL -o "$FULL_TTF" "https://github.com/google/fonts/raw/main/ofl/longcang/LongCang-Regular.ttf"
fi

python3 - <<'EOF'
import glob
chars = set()
for f in glob.glob('*.html'):
    chars |= set(open(f, encoding='utf-8').read())
chars |= set('，。！？：；、（）《》【】“”‘’—…·～&0123456789')
chars = {c for c in chars if not c.isspace() or c == ' '}
open('/tmp/chars.txt', 'w', encoding='utf-8').write(''.join(sorted(chars)))
print('unique chars:', len(chars))
EOF

python3 -m fontTools.subset "$FULL_TTF" --text-file=/tmp/chars.txt --layout-features='*' --flavor=woff2 --output-file=fonts/long-cang-v5-chinese-simplified-regular.woff2
python3 -m fontTools.subset "$FULL_TTF" --text-file=/tmp/chars.txt --layout-features='*' --flavor=woff  --output-file=fonts/long-cang-v5-chinese-simplified-regular.woff
python3 -m fontTools.subset "$FULL_TTF" --text-file=/tmp/chars.txt --layout-features='*' --output-file=fonts/long-cang-v5-chinese-simplified-regular.ttf
ls -la fonts/
