#!/usr/bin/env python3
"""Make the dark workflow diagram from the light one: python3 make_dark_workflow.py light.svg dark.svg"""
import base64, os, re, sys

src, dst = sys.argv[1:3]
s = open(src).read()
BG, FG = '#2b2b2b', '#f2f2f2'
for prop, old, new in [('fill', '#ffffff', BG), ('fill', '#000000', FG), ('stroke', '#ffffff', BG), ('stroke', '#000000', FG)]:
    s, n = re.subn(rf'(?i)((?<![-\w]){prop}\s*[:=]\s*"?){old}\b', lambda m: m.group(1) + new, s)
    print(f'{prop} {old} -> {new}: {n}')
# paths and text without a fill default to black
s = s.replace('<svg\n', f'<svg\n   fill="{FG}"\n', 1)
s = s.replace('pagecolor="#ffffff"', f'pagecolor="{BG}"')
s = re.sub(r'sodipodi:docname="[^"]*"', f'sodipodi:docname="{os.path.basename(dst)}"', s)
logo = os.path.join(os.path.dirname(os.path.abspath(src)), 'nf-core-phyloplace_logo_dark.png')
s, n = re.subn(r'data:image/png;base64,[^"]+', 'data:image/png;base64,' + base64.b64encode(open(logo, 'rb').read()).decode(), s)
print('logos replaced:', n)
x, y, w, h = re.search(r'viewBox="([^"]+)"', s).group(1).split()
i = s.index('<g', s.index('</sodipodi:namedview>'))
s = s[:i] + f'<rect id="background" x="{x}" y="{y}" width="{w}" height="{h}" fill="{BG}"/>\n  ' + s[i:]
open(dst, 'w').write(s)
