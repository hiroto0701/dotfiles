"""Build a tap-to-answer quiz page from a review sheet and the exports' parse JSON.

usage: python3 -I build_quiz.py <sheet.html> <out.html> m1=<m1.json> [m2=<m2.json> ...] [--slug <slug>]

Every card in the sheet becomes one question. Question text, options, the
per-option explanations and the mock's own explanation come verbatim from the
parse_mock.py --out JSON (any attempt of that mock; the latest is fine). The
card supplies 決め手 / 引っかかり / 補足 / 採点キー注. The answers of each attempt
come from the sheet's embedded mock-mK, mock-mKr2, ... blocks, and the last two
attempts decide the category (same / diff / lost / fixed / marked, or wrong /
marked when the mock was taken once). Keep --slug stable: it names the
localStorage keys that hold the viewer's record.
"""
import json
import os
import re
import sys

TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "quiz-template.html")
RANK = {"same": 0, "diff": 1, "lost": 2, "wrong": 3, "fixed": 4, "marked": 5}


def clean(h):
    h = re.sub(r"<a\b[^>]*>(.*?)</a>", r"\1", h, flags=re.S)
    return re.sub(r"\s+", " ", h).strip()


def first(pat, s):
    m = re.search(pat, s, re.S)
    return clean(m.group(1)) if m else ""


def mock_range(titles):
    parts = [re.match(r"^(.*?)(\d+)$", t) for t in titles]
    if len(titles) > 1 and all(parts) and len({p.group(1) for p in parts}) == 1:
        return f"{parts[0].group(1)}{parts[0].group(2)}〜{parts[-1].group(2)}"
    return "・".join(titles)


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    slug = argv[argv.index("--slug") + 1] if "--slug" in argv else None
    if slug:
        args.remove(slug)
    if len(args) < 3:
        sys.exit(__doc__)
    sheet_path, out_path, pairs = args[0], args[1], args[2:]
    src = open(sheet_path, encoding="utf-8").read()

    attempts = {}
    for m in re.finditer(r'<script type="application/json" id="mock-m(\d+)(?:r(\d+))?">(.*?)</script>', src, re.S):
        d = json.loads(m.group(3))
        attempts.setdefault(int(m.group(1)), []).append((int(m.group(2) or 1), d))
    if not attempts:
        sys.exit("no mock-mN blocks in the sheet; paste parse_mock.py --snippet output first")
    titles = {k: sorted(v, key=lambda x: x[0])[0][1]["title"] for k, v in attempts.items()}
    attempts = {k: [{q["n"]: q for q in d["questions"]} for _, d in sorted(v, key=lambda x: x[0])] for k, v in attempts.items()}

    text = {}
    for p in pairs:
        k, _, path = p.partition("=")
        if not re.fullmatch(r"m\d+", k) or not path:
            sys.exit(f"bad argument {p!r}: expected mK=<parse json>")
        text[int(k[1:])] = {q["n"]: q for q in json.load(open(path, encoding="utf-8"))["questions"]}

    h1 = first(r"<h1[^>]*>(.*?)</h1>", src)
    short = re.sub(r"\s*模試復習帳$", "", h1) or h1
    slug = slug or re.sub(r"[^a-z0-9]+", "-", short.lower()).strip("-") or "exam"
    domains = {}
    for m in re.finditer(r'<section class="chap d(\d)" id="d\1">(.*?)</section>', src, re.S):
        domains[m.group(1)] = first(r"<h2[^>]*>(.*?)</h2>", m.group(2))

    items, problems, no_json = [], [], {}
    for m in re.finditer(r'<article class="q[^"]*" id="m(\d+)-q(\d+)">(.*?)</article>', src, re.S):
        k, n, a = int(m.group(1)), int(m.group(2)), m.group(3)
        if k not in text:
            no_json[k] = no_json.get(k, 0) + 1
            continue
        t = text[k].get(n)
        att = [x[n] for x in attempts.get(k, []) if n in x]
        if not t or not att:
            problems.append(f"m{k}-q{n}: question missing from the JSON or the sheet's mock blocks")
            continue
        if any(x["h"] != t["h"] for x in att):
            problems.append(f"m{k}-q{n}: question text differs between the JSON and the sheet")
            continue
        if len(att) >= 2:
            p, q = att[-2], att[-1]
            if not p["is_correct"] and not q["is_correct"]:
                cat = "same" if sorted(p["mine"]) == sorted(q["mine"]) else "diff"
            elif p["is_correct"] and not q["is_correct"]:
                cat = "lost"
            elif not p["is_correct"] and q["is_correct"]:
                cat = "fixed"
            else:
                cat = "marked"
        else:
            cat = "marked" if att[0]["is_correct"] else "wrong"
        ans = a[a.index('<div class="ans">'):] if '<div class="ans">' in a else ""
        items.append({
            "id": f"m{k}-q{n}", "m": k, "n": n, "src": f"{titles[k]} · Q{n}",
            "dom": int(str(att[0].get("d", "0")).split(".")[0] or 0),
            "sub": first(r'<span class="chip d\d">([^<]*)</span>', a), "cat": cat,
            "q": t["question"], "o": t["options"],
            "po": {x: re.sub(r"^\s*\[(正解|不正解)\]\s*", "", y or "") for x, y in (t.get("per_option") or {}).items()},
            "ex": t.get("explanation", ""), "c": sorted(t["correct"]),
            "att": [sorted(x["mine"]) for x in att],
            "trap": first(r'<p class="row trap"><span class="lab">[^<]*</span><span>(.*?)</span></p>', ans),
            "key": first(r'<p class="row key"><span class="lab">[^<]*</span><span>(.*?)</span></p>', ans),
            "extra": [clean(x) for x in re.findall(r"\n\s*<p>(.*?)</p>", ans, re.S)],
            "note": first(r'<p class="note">(.*?)</p>', ans),
        })
    problems += [f"m{k}: {c} card(s) but no parse JSON given (pass m{k}=<parse_mock --out json>)" for k, c in sorted(no_json.items())]
    if problems:
        print("\n".join("PROBLEM " + p for p in problems))
        sys.exit(1)
    items.sort(key=lambda it: (RANK[it["cat"]], it["m"], it["n"]))

    page = open(TEMPLATE, encoding="utf-8").read()
    for ph, val in [("{{QUIZ_TITLE}}", f"{short} 苦手問題集"), ("{{SHEET_TITLE}}", h1),
                    ("{{MOCK_RANGE}}", mock_range([titles[k] for k in sorted(titles)])), ("{{SLUG}}", slug)]:
        page = page.replace(ph, val)
    left = sorted(set(re.findall(r"\{\{[A-Z_]+\}\}", page)))
    if left:
        sys.exit(f"placeholders left in the template: {left}")
    data = json.dumps({"domains": domains, "items": items}, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    if page.count("/*__DATA__*/") != 1:
        sys.exit("template must contain /*__DATA__*/ exactly once")
    open(out_path, "w", encoding="utf-8").write(page.replace("/*__DATA__*/", data))
    cats = {c: sum(1 for it in items if it["cat"] == c) for c in RANK if any(it["cat"] == c for it in items)}
    print(f"questions: {len(items)}  {cats}  slug: {slug}  missing 決め手: {[it['id'] for it in items if not it['key']]}")


if __name__ == "__main__":
    main(sys.argv)
