# Page Templates

LLM wikiで頻繁に生成する各種pageの雛形集。ingestやbootstrap時に、この雛形を下敷きにpageを生成する。placeholder (`{{...}}`) は実際の値に置換する。

## Index（`wiki/index.md`）

```markdown
# Index

このwikiの全pageをカテゴリ別にカタログ化したもの。新規page作成時は必ず該当カテゴリに追記する。

_Last updated: {{YYYY-MM-DD}}_

## Sources

<!-- source summary pages（ingestした各原典） -->
- [[sources/<slug>]] — 1行要約（著者名・発表年を含めると検索しやすい）

## Entities

<!-- 人物・書籍・組織・製品・場所 -->

### 人物
- [[entities/<slug>]] — 1行要約（職業・所属・代表作など）

### 書籍
- [[entities/<slug>]] — 1行要約（著者・発行年）

### 組織
- [[entities/<slug>]] — 1行要約

## Concepts

<!-- 理論・用語・パターン -->
- [[concepts/<slug>]] — 1行定義

## Synthesis

<!-- 比較・統合・filing backされたquery回答 -->
- [[synthesis/<slug>]] — 何を統合したものか

---

## Statistics

- Total sources: {{N}}
- Total entity pages: {{N}}
- Total concept pages: {{N}}
- Total synthesis pages: {{N}}
- Last ingest: {{YYYY-MM-DD}}
- Last lint: {{YYYY-MM-DD}}
```

## Log（`wiki/log.md`）

Append-only。**各エントリのprefix形式を厳守**（`grep "^## \[" log.md` でパース可能にするため）。

```markdown
# Log

このwikiへの操作履歴（append-only, 時系列降順は禁止 — 常に追記）。

prefix形式:
- ingest: `## [YYYY-MM-DD] ingest | <source title>`
- query:  `## [YYYY-MM-DD] query | <query要旨>`
- lint:   `## [YYYY-MM-DD] lint | <検出件数>`
- misc:   `## [YYYY-MM-DD] misc | <操作内容>`

---

## [2026-04-23] ingest | Example Article by Jane Doe

**Source**: [[sources/example-article]]
**Updated pages**:
- [[entities/jane-doe]] — 新規作成
- [[concepts/foo-bar]] — 既存概念に実例を追記
- [[concepts/baz]] — 新規作成
**Index updated**: Sources / Entities (人物) / Concepts に追記
**Notes**: Jane Doe の主張 X は [[concepts/foo-bar]] の既存記述と矛盾するため並記。要lint。
```

## Source summary page（`wiki/sources/<slug>.md`）

原典1つに対して1つ作成。ingestの最初の成果物。

```markdown
---
type: source
tags: [{{tag1}}, {{tag2}}]
created: {{YYYY-MM-DD}}
updated: {{YYYY-MM-DD}}
source_url: {{URL or "local raw/xxx.pdf"}}
source_author: {{著者名}}
source_year: {{YYYY}}
source_type: article | paper | book | podcast | video | dataset | other
---

# {{Source Title}}

> 1〜2文のsummary（クエリ時にindexから見て「これ読む価値あるか」判断できる粒度）。

## Metadata

- **Author**: {{...}}
- **Published**: {{YYYY-MM-DD}}
- **Source**: {{URL or raw/path}}
- **Type**: {{article / paper / ...}}
- **Language**: {{ja/en/...}}

## Key Takeaways

1. {{主要論点1 — 1〜2文}}
2. {{主要論点2}}
3. {{主要論点3}}

（3〜7点。多すぎるなら重要度で削る）

## Detailed Notes

{{原典の論の流れに沿った詳細ノート。引用は blockquote で}}

> {{直接引用}} (p. {{N}})

{{コメント・解釈}}

## Connections

このソースが触れている / このソースから生まれたpage:

- [[entities/<slug>]] — 何について言及されているか
- [[concepts/<slug>]] — どの概念を展開しているか
- [[sources/<another>]] — 関連ソース（反論・補強など）

## Open Questions

このソースを読んで生まれた次の問い（後のingest / query候補）:

- {{Q1}}
- {{Q2}}

## My Thoughts

{{ユーザーとの対話で得られた個人的解釈・批判・次アクション。LLMは勝手に書かず、対話で合意した内容のみを記録する}}
```

## Entity page（`wiki/entities/<slug>.md`）

人物・書籍・組織・製品・場所など。複数sourceから言及される可能性が高い。

```markdown
---
type: entity
entity_kind: person | book | organization | product | place | other
tags: [{{...}}]
created: {{YYYY-MM-DD}}
updated: {{YYYY-MM-DD}}
sources: [[[sources/<slug1>]], [[sources/<slug2>]]]
---

# {{Entity Name}}

> 1〜2文の要約。このentityが何者/何であるか。

## Basic Info

<!-- entity_kind に応じて適切な項目 -->
### 人物の場合
- **所属**: {{...}}
- **活動時期**: {{...}}
- **専門領域**: {{...}}
- **代表作 / 業績**: {{...}}

### 書籍の場合
- **著者**: [[entities/<author-slug>]]
- **発行年**: {{YYYY}}
- **出版社**: {{...}}
- **ジャンル**: {{...}}

### 組織の場合
- **設立**: {{YYYY}}
- **本部**: {{...}}
- **主要活動**: {{...}}

## Mentions

このentityに言及しているソース:

- [[sources/<slug1>]] — 文脈メモ（どんな論点で言及されたか）
- [[sources/<slug2>]] — 文脈メモ

## Related

- [[entities/<slug>]] — 関係性（同僚 / 師匠 / 共著者 / 前身組織 等）
- [[concepts/<slug>]] — このentityが関わる概念

## Contradictions

<!-- 異なるソース間で記述が食い違う場合、両方を並記してフラグ -->

- **{{論点}}**: [[sources/A]] では「X」[[sources/B]] では「Y」— 要確認
```

## Concept page（`wiki/concepts/<slug>.md`）

理論・用語・パターン・方法論など抽象概念。

```markdown
---
type: concept
tags: [{{...}}]
created: {{YYYY-MM-DD}}
updated: {{YYYY-MM-DD}}
sources: [[[sources/<slug1>]], [[sources/<slug2>]]]
---

# {{Concept Name}}

> 1〜2文の定義（wiki内で一貫して参照される「標準定義」）。

## 詳細

{{概念の構成要素・動作原理・典型例を2〜6段落で}}

## Origins

この概念を提唱 / 発展させた人物・ソース:

- [[entities/<slug>]]（[[sources/<slug>]] で提唱）

## Variants / Related Concepts

- [[concepts/<slug>]] — 類似・対比関係の説明
- [[concepts/<slug>]] — 上位 / 下位概念

## Examples

1. {{具体例1}} — 出典 [[sources/<slug>]]
2. {{具体例2}}

## Applications

この概念が適用されうる領域・ユースケース。

## Critiques

この概念への批判・限界（ある場合のみ記載）。

- {{批判1}} — [[sources/<slug>]]

## Contradictions

<!-- 異なるソース間で定義や位置付けが食い違う場合 -->
```

## Synthesis page（`wiki/synthesis/<slug>.md`）

比較・統合・query応答のfiling back先。「再利用価値あり」と判断したquery回答をここに残す。

```markdown
---
type: synthesis
tags: [{{...}}]
created: {{YYYY-MM-DD}}
updated: {{YYYY-MM-DD}}
sources: [[[sources/...]]]
triggered_by: "{{元のqueryテキスト or トリガー文脈}}"
---

# {{Synthesis Title}}

> この統合pageが答える問い / 扱う観点。

## Context

なぜこの統合を作ったか。元のquery / motivation。

## Synthesis

{{比較表・観点整理・論点マップ・thesisドラフト など、目的に応じた形式}}

### 例: 比較表

| 観点 | {{A}} | {{B}} | {{C}} |
|---|---|---|---|
| 定義 | ... | ... | ... |
| 強み | ... | ... | ... |
| 弱み | ... | ... | ... |
| 代表ソース | [[sources/a]] | [[sources/b]] | [[sources/c]] |

## Key Insights

このsynthesisから得られた洞察（箇条書き3〜5点）。

## Open Questions

このsynthesisで解決しなかった / 新たに生まれた問い。

## References

- [[sources/...]]
- [[entities/...]]
- [[concepts/...]]
```

## Log Entry（`wiki/log.md` に append）

prefix形式を厳守する:

```markdown
## [YYYY-MM-DD] <op> | <title>
```

各操作の書き方:

### Ingest

```markdown
## [2026-04-23] ingest | <Source Title>

**Source**: [[sources/<slug>]]
**Created pages**:
- [[entities/<slug>]]
- [[concepts/<slug>]]
**Updated pages**:
- [[entities/<existing-slug>]] — 追記内容の要約
**Index**: Sources / Entities / Concepts に追記
**Notes**: 特記事項（矛盾検出など）
```

### Query

```markdown
## [2026-04-23] query | <query要旨（1行）>

**Answer form**: markdown | table | slides | chart | canvas
**Pages consulted**: [[...]], [[...]]
**Filed back to**: [[synthesis/<slug>]]（filingした場合のみ）
**Notes**: 
```

### Lint

```markdown
## [2026-04-23] lint | <検出件数>件

**Contradictions**: {{N}}
- [[page-x]] と [[page-y]] の {{論点}} — {{対応方針}}
**Stale claims**: {{N}}
- [[page-z]] の記述が [[sources/newer]] と矛盾
**Orphan pages**: {{N}}
- [[orphan-a]], [[orphan-b]]
**Missing cross-refs**: {{N}}
- [[page]] で [[entity]] に言及あるがリンク無し
**Suggested new pages**: {{N}}
- "{{concept名}}" が {{M}}ソースで言及されているが独立pageなし
**Actions taken**: どれを修正したか / 保留にしたか
```

### Misc

```markdown
## [2026-04-23] misc | <操作内容>

{{一括リネーム / カテゴリ再構成 / schema更新 など、ingest/query/lintに収まらない操作の記録}}
```

## Index Entry（`wiki/index.md` への1行追記）

カテゴリ見出し配下に以下の形式で1行追加:

```markdown
- [[<category>/<slug>]] — 1行要約（検索時にこの1行で「読む価値あるか」判断できる粒度）
```

良い例:
```markdown
- [[entities/richard-feynman]] — 米物理学者(1918-1988)、量子電磁力学でノーベル賞、教育家としても著名
- [[concepts/bayesian-inference]] — 事前分布と観測から事後分布を更新する確率的推論の枠組み
- [[sources/feynman-lectures-vol1]] — R. Feynman『ファインマン物理学 第I巻』(1963), 古典力学・熱・波動
```

悪い例（要約が抽象的すぎる / エモジや装飾が多い / 長すぎる）:
```markdown
- [[entities/richard-feynman]] — すごい物理学者
- [[concepts/bayesian-inference]] — ベイズについての重要な概念で、様々な分野で使われる統計手法の一種であり、...
```
