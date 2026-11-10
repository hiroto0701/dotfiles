"""Render every <figure> of a sheet with headless Chrome so label overflow can be seen.

usage: python3 -I render_figs.py <sheet.html> <out_dir> [--only fig-id,fig-id] [--ids id,id]

Writes figs<N>.png (5 figures per image, 860px wide) and top.png (first screen
at 1280px). --ids renders the cards or chapters with those ids instead
(parts<N>.png), to look at what an update changed. Read the PNGs and fix any
text that leaves its box.
"""
import os
import re
import subprocess
import sys

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def shot(html_path, png_path, size):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--virtual-time-budget=4000", f"--window-size={size}",
                    f"--screenshot={png_path}", "file://" + html_path],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    src_path, out = os.path.abspath(argv[1]), os.path.abspath(argv[2])
    os.makedirs(out, exist_ok=True)
    src = open(src_path, encoding="utf-8").read()
    head = src[: src.index("</style>") + len("</style>")]
    if "--ids" in argv:
        figs = []
        for i in argv[argv.index("--ids") + 1].split(","):
            m = re.search(r'<(article|section|figure)\b[^>]*id="' + re.escape(i) + r'".*?</\1>', src, re.S)
            if m:
                figs.append(m.group(0))
            else:
                print(f"id not found: {i}")
    else:
        figs = re.findall(r"<figure.*?</figure>", src, re.S)
    if "--only" in argv:
        want = set(argv[argv.index("--only") + 1].split(","))
        figs = [f for f in figs if (re.search(r'id="([^"]+)"', f) or [None, None])[1] in want]
    for i in range(0, len(figs), 5):
        page = os.path.join(out, f"{'parts' if '--ids' in argv else 'figs'}{i // 5}.html")
        body = '<body style="padding:16px;max-width:820px;display:grid;gap:16px"><main>' + "".join(figs[i:i + 5]) + "</main></body>"
        open(page, "w", encoding="utf-8").write('<!doctype html><html lang="ja"><head><meta charset="utf-8">' + head + "</head>" + body + "</html>")
        shot(page, page[:-5] + ".png", "860,2200")
    shot(src_path, os.path.join(out, "top.png"), "1280,1100")
    kind = "parts" if "--ids" in argv else "figs"
    print(f"{len(figs)} block(s) -> {out}/{kind}*.png, top.png")


if __name__ == "__main__":
    main(sys.argv)
