"""Structural check for a review sheet built from template.html.

usage: python3 -I check_sheet.py <sheet.html>

Fails (exit 1) on: unclosed or stray tags, duplicate ids, links or markers that
point to a missing id, CSS classes used but not defined, SVG rects without a
fill, a card without its "next time" checkbox, template placeholders left in.
"""
import re
import sys
from html.parser import HTMLParser

VOID = {"meta", "link", "br", "img", "input", "hr", "source", "col", "wbr", "area", "base", "embed", "param", "track"}
SVG_TEXT = {"text", "rect", "line", "polyline", "path", "tspan", "circle", "polygon"}


class P(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.ids, self.refs, self.classes, self.err = [], {}, [], set(), []

    def _attrs(self, tag, attrs):
        d = dict(attrs)
        if d.get("id"):
            self.ids[d["id"]] = self.ids.get(d["id"], 0) + 1
        if (d.get("href") or "").startswith("#") and len(d["href"]) > 1:
            self.refs.append(d["href"][1:])
        for k in ("marker-end", "marker-start"):
            m = re.match(r"url\(#(.+)\)", d.get(k) or "")
            if m:
                self.refs.append(m.group(1))
        for c in (d.get("class") or "").split():
            self.classes.add((tag, c))

    def handle_starttag(self, tag, attrs):
        self._attrs(tag, attrs)
        if tag not in VOID:
            self.stack.append((tag, self.getpos()))

    def handle_startendtag(self, tag, attrs):
        self._attrs(tag, attrs)

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        names = [t for t, _ in self.stack]
        if tag not in names:
            self.err.append(f"stray </{tag}> at line {self.getpos()[0]}")
            return
        while self.stack[-1][0] != tag:
            t, pos = self.stack.pop()
            self.err.append(f"unclosed <{t}> from line {pos[0]}")
        self.stack.pop()


def main(path):
    src = open(path, encoding="utf-8").read()
    p = P()
    p.feed(src)
    problems = list(p.err) + [f"unclosed <{t}> from line {pos[0]}" for t, pos in p.stack]
    problems += [f"duplicate id: {k}" for k, v in p.ids.items() if v > 1]
    problems += [f"link to missing id: #{r}" for r in sorted(set(p.refs)) if r not in p.ids]
    css = "\n".join(re.findall(r"<style>(.*?)</style>", src, re.S))
    for tag, c in sorted(p.classes):
        if not re.search(r"\." + re.escape(c) + r"(?![\w-])", css):
            problems.append(f"class not defined in CSS: .{c} (on <{tag}>)")
    for m in re.finditer(r"<rect\b[^>]*>", src):
        if "class=" not in m.group(0) and "fill=" not in m.group(0):
            problems.append(f"rect without fill: {m.group(0)[:70]}")
    cards = re.findall(r'<article class="q[^"]*" id="([^"]+)"', src)
    boxes = set(re.findall(r'data-q="([^"]+)"', src))
    problems += [f"card without checkbox: {c}" for c in cards if c not in boxes]
    for ph in sorted(set(re.findall(r"\{\{[^}]*\}\}", src))):
        problems.append(f"template placeholder left in: {ph}")
    print(f"cards: {len(cards)}  figures: {len(re.findall(r'<figure', src))}  svg: {len(re.findall(r'<svg', src))}")
    for x in problems:
        print("PROBLEM", x)
    print("OK" if not problems else f"{len(problems)} problem(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
