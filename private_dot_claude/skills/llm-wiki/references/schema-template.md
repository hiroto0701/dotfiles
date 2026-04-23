# Schema Template

このファイルの内容を、新規作成したwikiディレクトリの直下に `CLAUDE.md`（Claude Code利用時）または `AGENTS.md`（OpenAI Codex等利用時）としてコピーし、`{{PLACEHOLDER}}` をユーザー情報で置換して使う。

SKILL.mdが「LLM wikiパターン全般の振る舞い」を定義するのに対し、このschemaファイルは「この個別wikiの具体的な運用ルール」を定義する。個別wikiの事情（ドメイン特有の命名・カテゴリ・ワークフロー調整）は、このschemaファイルに追記してSKILL.mdの指示を上書きしてよい。

---

（以下、雛形本体。ここから下をwikiルートに配置）

# {{WIKI_NAME}} — LLM Wiki Schema

## Purpose / Domain

このwikiは **{{DOMAIN}}** を対象とする。

目的: {{PURPOSE — e.g., 読書メモと関連資料を統合して自分の思考の第二の脳を育てる / 特定技術領域の研究thesisを構築する / チーム内ドキュメントを集約する}}

対象期間・スコープ: {{SCOPE — e.g., 個人用・無期限 / 2026年Q2の競合調査プロジェクト / etc.}}

## Directory Structure

```
{{WIKI_ROOT}}/
├── CLAUDE.md           # このファイル（schema）
├── raw/                # 原典ソース（immutable）
│   └── assets/         # 画像・PDFなど
└── wiki/               # LLM-owned markdown
    ├── index.md        # content-orientedカタログ
    ├── log.md          # chronological操作履歴
    ├── sources/        # source summary pages
    ├── entities/       # 人物・書籍・組織など
    ├── concepts/       # 理論・用語・パターン
    └── synthesis/      # 比較・統合・query回答のfiling back
```

カテゴリディレクトリは必要に応じて追加してよい（例: `wiki/projects/`, `wiki/people/`, `wiki/books/`）。追加したらこのschemaに記載する。

## Page Naming Convention

- ファイル名は **kebab-case**: `richard-feynman.md`, `bayesian-inference.md`
- Obsidian wikilink `[[slug]]` で参照可能にする（拡張子 `.md` 不要）
- 曖昧な略称は避け、検索可能な自然語に寄せる

## Page Frontmatter

すべてのwiki pageに以下のYAML frontmatterを付ける:

```yaml
---
type: entity | concept | source | synthesis
tags: [{{TAG_EXAMPLES}}]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [[[source-slug-1]], [[source-slug-2]]]
---
```

`sources` はそのpageが依拠する source summary pageへのリンク群。entity / conceptは複数sourceを持ちうる。source summary自体は `sources: []` で空、代わりに `source_url` / `source_author` / `source_type` フィールドを持つ（page-templates.md 参照）。

## Ingest Workflow（個別カスタマイズ）

SKILL.mdの標準ingestワークフローに従う。このwikiでの追加ルール:

- {{CUSTOM_INGEST_RULES — e.g., 「本」をingestする際は chapter単位でsource summaryを分割する / 論文をingestする際は必ずmethodsセクションを要約に含める / etc.}}
- 主要takeawayの合意は {{DISCUSS_OR_AUTO — e.g., 毎回ユーザーと短く対話 / 明白なソースは自動要約のみ等}}

## Query Workflow

- デフォルト回答形式: {{DEFAULT_FORMAT — e.g., markdown本文 + 引用 / 3-bullet サマリ / 比較表 等}}
- Filing back判断: {{FILING_POLICY — e.g., 「将来再利用しそう」と判断したら必ず聞く / 明示指示時のみ}}

## Lint Cadence

- {{LINT_FREQUENCY — e.g., 月1回 / 20ソース取り込むごと / 明示指示時のみ}}
- 重点チェック項目: {{LINT_FOCUS — e.g., 矛盾 > orphan pages > cross-reference不足 の優先度}}

## Tooling

- Obsidian vault: {{YES/NO, path}}
- Web Clipper: {{USE/NOT}}
- Dataview: {{USE/NOT — 使う場合はfrontmatter tagsを積極的に活用}}
- 検索CLI: {{NONE / qmd / custom}}
- Git管理: {{YES/NO, repo path}}

## Notes for the LLM

- このwikiでは {{DOMAIN_SPECIFIC_CONVENTIONS — e.g., 人名は姓-名順 / 書名は原題と邦題を両方記載 / 数式はKaTeX形式 等}}
- 避けるべき操作: {{DONTS — e.g., raw/ を書き換える / 未確認情報を断定的に書く / ユーザー確認なしに synthesis page を大量生成する 等}}
- エスカレーション: {{ESCALATION — e.g., 矛盾検出時は必ずユーザーに相談 / 新カテゴリ追加は必ず確認 等}}

---

## Placeholder 一覧（bootstrap時に置換）

| Placeholder | 例 |
|---|---|
| `{{WIKI_NAME}}` | `My Knowledge Wiki` / `AI Safety Research Wiki` |
| `{{DOMAIN}}` | 個人ナレッジ全般 / AI安全性研究 / 日本近代文学 |
| `{{PURPOSE}}` | 〜を整理して思考を深める |
| `{{SCOPE}}` | 個人・無期限 / プロジェクトY期間中 |
| `{{WIKI_ROOT}}` | `~/Documents/Obsidian/MyVault` |
| `{{TAG_EXAMPLES}}` | `[book, note, 2026]` |
| `{{CUSTOM_INGEST_RULES}}` | ドメイン固有のingest追加ルール |
| `{{DISCUSS_OR_AUTO}}` | 対話粒度の設定 |
| `{{DEFAULT_FORMAT}}` | query回答の既定形式 |
| `{{FILING_POLICY}}` | filing back判断基準 |
| `{{LINT_FREQUENCY}}` | lintの頻度 |
| `{{LINT_FOCUS}}` | lint重点項目 |
| `{{DOMAIN_SPECIFIC_CONVENTIONS}}` | ドメイン固有規約 |
| `{{DONTS}}` | 避けるべき操作 |
| `{{ESCALATION}}` | ユーザー相談が必要な状況 |
