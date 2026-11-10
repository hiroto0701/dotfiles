"""Parse a mock-exam export (Udemy-style Markdown) into JSON and print a summary.

usage: python3 -I parse_mock.py <mock.md> [--out q.json] [--domains map.json] [--snippet ID] [--prev FILE [--prev-id ID]]

--out      full JSON (question text, options, explanations) for writing cards
--domains  JSON {"<question no>": "<guide subsection, e.g. 1.4>"}; adds the
           per-domain score to the summary and "d" to each question
--snippet  also print <script type="application/json" id="mock-ID"> with the
           answers only; paste it into the sheet so later retakes can compare
           even after the export file is gone
--prev     compare with an earlier attempt at the same mock: a JSON from --out,
           or the sheet HTML (reads the mock-ID script; --prev-id picks which)
"""
import hashlib
import json
import re
import sys

FLAG_TERMS = ["既存の想定解", "唯一解とは断定", "旧想定", "採点キー", "満たす選択肢はなく", "厳密には満たし", "根拠が不足"]


def parse(path):
    text = open(path, encoding="utf-8").read()
    title = re.search(r"(?m)^#\s+(.+)$", text)
    blocks = re.split(r"(?m)^(?=##\s+.*?問題\s*\d+)", text)[1:]
    qs = []
    for b in blocks:
        head = re.match(r"##\s+(.*?)問題\s*(\d+)\s*（(.+?)）", b)
        if not head:
            continue
        n = int(head.group(2))
        body_q = re.search(r"(?m)^問題\s*\d+\s*[：:]\s*(.+)$", b)
        options = {}
        for m in re.finditer(r"(?m)^- \*\*([A-Z])\.\*\*\s*(?:[A-Z]\.\s*)?(.*)$", b):
            options[m.group(1)] = re.sub(r"\s*【[^】]*】\s*$", "", m.group(2)).strip()
        corr = re.search(r"(?m)^- 正解:\s*(.+)$", b)
        mine = re.search(r"(?m)^- 自分の回答:\s*(.+)$", b)
        correct = re.findall(r"[A-Z]", corr.group(1)) if corr else []
        mine_l = [] if not mine or "なし" in mine.group(1) else re.findall(r"[A-Z]", mine.group(1))
        per_opt = {}
        sec = re.search(r"### 選択肢ごとの解説(.*?)(?=###|\Z)", b, re.S)
        if sec:
            for m in re.finditer(r"(?m)^- \*\*([A-Z])[^*]*\*\*\s*(.*)$", sec.group(1)):
                per_opt[m.group(1)] = m.group(2).strip()
        expl = re.search(r"### 全体的な説明(.*?)(?=\n---|\Z)", b, re.S)
        expl_t = expl.group(1).strip() if expl else ""
        flags = sorted({t for t in FLAG_TERMS if t in b})
        is_correct = sorted(correct) == sorted(mine_l) and bool(correct)
        qtext = body_q.group(1).strip() if body_q else ""
        qs.append({
            "n": n,
            "h": hashlib.sha1(re.sub(r"\s+", "", qtext).encode("utf-8")).hexdigest()[:8],
            "correct": correct,
            "mine": mine_l,
            "is_correct": is_correct,
            "multi": len(correct) > 1,
            "unanswered": not mine_l,
            "under_selected": len(correct) > 1 and 0 < len(mine_l) < len(correct),
            "question": body_q.group(1).strip() if body_q else "",
            "options": options,
            "per_option": per_opt,
            "explanation": expl_t,
            "key_flags": flags,
        })
    return {"title": title.group(1).strip() if title else path, "questions": qs}


def summary(data, prev=None):
    qs = data["questions"]
    doms = {}
    for q in qs:
        if q.get("d"):
            top = q["d"].split(".")[0]
            doms.setdefault(top, [0, 0])
            doms[top][0] += q["is_correct"]
            doms[top][1] += 1
    wrong = [q for q in qs if not q["is_correct"]]
    multi = [q for q in qs if q["multi"]]
    out = [f"# {data['title']}",
           f"score: {len(qs) - len(wrong)} / {len(qs)}",
           "wrong: " + ", ".join(f"Q{q['n']}" for q in wrong),
           f"multi-select: {len(multi)} total, {sum(not q['is_correct'] for q in multi)} wrong",
           "  under-selected (picked fewer than required): " + (", ".join(f"Q{q['n']}({''.join(q['mine'])}/{''.join(q['correct'])})" for q in qs if q["under_selected"]) or "none"),
           "unanswered: " + (", ".join(f"Q{q['n']}" for q in qs if q["unanswered"]) or "none"),
           "answer key flagged by the explanation itself: " + (", ".join(f"Q{q['n']}" for q in qs if q["key_flags"]) or "none")]
    if doms:
        out.append("by domain: " + ", ".join(f"{k}: {v[0]}/{v[1]}" for k, v in sorted(doms.items(), key=lambda x: int(x[0]) if x[0].isdigit() else 99)))
        miss = [f"Q{q['n']}" for q in qs if not q.get("d")]
        if miss:
            out.append("no domain assigned: " + ", ".join(miss))
    if prev:
        fmt = lambda xs: ", ".join(f"Q{x}" for x in xs) or "none"
        p = {q["n"]: q for q in prev["questions"]}
        same, repeat, fixed, new, kept, differ = [], [], [], [], [], []
        for q in qs:
            o = p.get(q["n"])
            if not o:
                continue
            if o.get("h") and o["h"] != q["h"]:
                differ.append(q["n"])
                continue
            if not q["is_correct"] and not o["is_correct"]:
                (same if q["mine"] == o["mine"] else repeat).append(q["n"])
            elif q["is_correct"] and not o["is_correct"]:
                fixed.append(q["n"])
            elif not q["is_correct"] and o["is_correct"]:
                new.append(q["n"])
            else:
                kept.append(q["n"])
        if differ:
            out.append("WARNING question text differs from the previous attempt (not the same question; skipped): " + fmt(differ))
        compared = [q for q in qs if q["n"] in p and q["n"] not in differ]
        if compared and all(q["mine"] == p[q["n"]]["mine"] for q in compared):
            out.append("NOTE every compared answer is identical to the previous attempt; this file may already be imported")
        out += ["-- compared with previous attempt --",
                f"previous score: {sum(q['is_correct'] for q in prev['questions'])} / {len(prev['questions'])}",
                "same wrong choice twice: " + fmt(same),
                "wrong twice, different choice: " + fmt(repeat),
                "fixed: " + fmt(fixed),
                "new misses: " + fmt(new),
                "correct both times: " + fmt(kept)]
    return "\n".join(out)


def load_prev(path, prev_id):
    text = open(path, encoding="utf-8").read()
    if not path.endswith(".html"):
        return json.loads(text)
    found = dict(re.findall(r'<script type="application/json" id="mock-([^"]+)">(.*?)</script>', text, re.S))
    if not found:
        sys.exit(f"no <script type=\"application/json\" id=\"mock-...\"> in {path}")
    key = prev_id or list(found)[-1]
    if key not in found:
        sys.exit(f"--prev-id {key} not found; available: {', '.join(found)}")
    return json.loads(found[key])


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    arg = lambda k: argv[argv.index(k) + 1] if k in argv else None
    data = parse(argv[1])
    if arg("--domains"):
        dmap = json.load(open(arg("--domains"), encoding="utf-8"))
        for q in data["questions"]:
            if str(q["n"]) in dmap:
                q["d"] = dmap[str(q["n"])]
    prev = load_prev(arg("--prev"), arg("--prev-id")) if arg("--prev") else None
    if arg("--out"):
        with open(arg("--out"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
    print(summary(data, prev))
    if arg("--snippet"):
        slim = {"title": data["title"], "questions": [
            {k: q[k] for k in ("n", "h", "d", "correct", "mine", "is_correct") if k in q} for q in data["questions"]]}
        print(f'\n<script type="application/json" id="mock-{arg("--snippet")}">'
              + json.dumps(slim, ensure_ascii=False, separators=(",", ":")) + "</script>")


if __name__ == "__main__":
    main(sys.argv)
