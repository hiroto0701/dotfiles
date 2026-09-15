---
name: llm-wiki
description: LLMがユーザーのObsidian vault / markdownナレッジベースを永続的なwikiとしてインクリメンタルに構築・保守するパターン。RAGのように毎回ゼロから検索・合成するのではなく、ソース投入ごとにwiki本体（entity page / concept page / summary / index / log）を更新し続けることで知識を複利的に蓄積する。以下の発話で必ず起動すること: 「LLM wikiを作りたい / セットアップしたい」「この記事/論文/動画メモをwikiに取り込んで」「ソースをingestして」「wikiに質問したい」「wikiをlintして / 健康診断して」「Obsidian vaultを整理して」「second brain / Zettelkasten / Memex的なものを作りたい」「ナレッジベースに新しい情報を追加したい」。英語表現も同様: "ingest this into my wiki", "add source to knowledge base", "query the wiki", "lint the wiki", "set up an LLM wiki in Obsidian", "build a second brain". 対象ドメインは個人ナレッジ / 読書ノート / 研究深掘り / チームwiki / 競合調査など幅広い。ユーザーが「ナレッジを蓄積する仕組みを作りたい」と言った時、たとえ「wiki」という単語を使わなくても本スキルの適用を検討すること。
---

# LLM Wiki

LLMがユーザーのmarkdownナレッジベース（典型的にはObsidian vault）を永続的なwikiとしてインクリメンタルに保守するパターン。

## When to Activate

以下のような発話・状況で起動する:

- **Bootstrap**: 「LLM wikiを作りたい」「Obsidianでsecond brainをセットアップしたい」「ナレッジ蓄積の仕組みが欲しい」
- **Ingest**: 「この記事をwikiに取り込んで」「raw/に入れたPDFをingestして」「読書メモをwikiに追加」
- **Query**: 「wikiに質問したい: Xについて何を読んだか」「○○と△△の違いをwikiから整理して」
- **Lint**: 「wikiをlintして」「矛盾やorphan pageがないか健康診断して」「wikiの抜け漏れを教えて」
- **Maintenance**: 「page Xを更新して」「index.mdを整理して」「log.md形式を統一して」

ユーザーが「wiki」という語を使わなくても、**ナレッジを永続的・構造的に蓄積したいという意図**が読み取れたら、本スキルの適用を検討する。

## Core Philosophy — なぜRAGではなくwikiなのか

一般的なRAG（NotebookLM / ChatGPTファイルアップロード等）は、クエリ時に raw documents から関連チャンクを都度検索・合成する。LLMは毎回ゼロから知識を再発見することになり、**蓄積しない**。

本パターンは違う:

- **永続的に複利で成長するartifact**: 新しいソースが来るたびに、LLMはそれを読み、既存のwiki全体に統合する。entity pageを更新し、概念ページのsummaryを改訂し、新旧の矛盾をフラグし、synthesisを強化する
- **cross-referenceは事前に貼られている**: クエリ時に再探索するのではなく、既にwikilinkで繋がっている
- **役割分担**: 人間は **source curation・探索の方向付け・良い問い** を担当し、LLMは **要約・cross-reference・ファイリング・bookkeeping** という「誰もやりたがらない維持作業」を担う
- **ゼロコスト維持**: 人間のwikiが廃れる理由は維持コストが価値成長より速いから。LLMは飽きない・忘れない・一度に15ファイルを触れるので、wikiは維持され続ける

Obsidianを「IDE」、LLMを「プログラマー」、wikiを「コードベース」と捉える。ユーザーはObsidianで結果をブラウズしながら、LLMに編集を指示する。

## Architecture — 3層構造

Wikiディレクトリは以下の3層で構成される:

### 1. Raw sources (`raw/`)

ユーザーがキュレーションしたソースドキュメント群。記事 / 論文 / 画像 / データファイル / PDF等。**Immutable**: LLMは読み込むだけで、絶対に書き換えない。これがsource of truth。

Obsidian Web Clipperや手動保存で集めた原文がここに入る。画像を含む場合は `raw/assets/` に保存する運用が典型。

### 2. Wiki (`wiki/`)

LLMが生成・保守する markdown ファイル群。**LLMが100%所有**する層。

- Source summary pages — ingestした各ソースの要約
- Entity pages — 人物 / 組織 / 書籍 / 製品 / 場所など
- Concept pages — 理論 / 用語 / パターン
- Comparison / synthesis pages — クエリ応答として生成され、後で再利用価値があるもの
- `wiki/index.md` — content-orientedなカタログ
- `wiki/log.md` — chronologicalな操作履歴

ユーザーが読み、LLMが書く。

### 3. Schema (`CLAUDE.md` or `AGENTS.md` — wikiルート直下)

このwiki特化の設定ファイル。wikiの目的 / ディレクトリ構成 / page命名規約 / ingest-query-lintワークフロー / frontmatter規約などを定義する。

SKILL.mdは「LLM wikiパターン全般の振る舞い」を定義し、schemaファイルは「この個別wikiの具体的な運用ルール」を定義する。両者は併存し、個別wikiのschemaがより具体的な指示を与える。

schemaの雛形は `references/schema-template.md` にある。

## Bootstrap — 新規wikiの立ち上げ

ユーザーが「wikiを作りたい」と言ったら以下を対話で確認してから作業する:

1. **ドメイン**: 個人ナレッジ全般 / 特定テーマの研究 / 読書 / チームwiki 等 — 何のためのwikiか
2. **Vault path**: どこに作るか（新規Obsidian vault / 既存vault内のフォルダ / 単独の git repo 等）
3. **初期カテゴリ**: 最初に想定するエンティティ種別（例: 人物・書籍・概念・プロジェクト）

その後:

1. `raw/` と `wiki/` を作成（`raw/assets/` も画像用に作成）
2. `references/schema-template.md` の内容を wikiルートの `CLAUDE.md` にコピーし、`{{DOMAIN}}` などのplaceholderをユーザー情報で置換
3. `wiki/index.md` と `wiki/log.md` を初期化（`references/page-templates.md` の雛形を使用）
4. 既にraw sourcesがある場合は、最初の1つをサンプルとしてingestし、wikiが育っていく様子をユーザーに見せる

## Operations

### Ingest — ソースを取り込む

1つのソースの取り込みは **10〜15ファイルに波及する可能性がある** ことを念頭に置く。

**手順**:

1. **Read**: `raw/` の対象ソースを読む（PDFや画像がある場合は、まず本文を読み、その後必要に応じて画像を個別に view する）
2. **Discuss**: 主要なtakeawayをユーザーと短く対話して合意する（LLMが勝手に要点を決めない）。「何を強調すべきか」「新規エンティティはどれか」を確認
3. **Summary page を作成**: `wiki/sources/<slug>.md` に source summary page を作成（`references/page-templates.md` の雛形）
4. **Entity / Concept pages を更新**: ソースで言及された既存のentity/concept pageを更新。存在しなければ新規作成。新規情報と既存記述が矛盾する場合は、古い記述を消さずに **両方並記** し、矛盾フラグを付ける
5. **Cross-reference**: Obsidianの `[[page-name]]` wikilink形式で双方向リンクを張る。「このpageで言及されているpageは、逆向きにも言及されるべきか」を自問する
6. **Index を更新**: `wiki/index.md` の該当カテゴリに追記
7. **Log を追記**: `wiki/log.md` に `## [YYYY-MM-DD] ingest | <source title>` 形式で、変更した全pageのリストを記録

**Ingest粒度の判断**: ユーザーが「じっくり1つずつ」派か「まとめてbatch ingest」派かを最初に確認する。前者がdefault（品質が高い）。

### Query — wikiに質問する

1. **index.md を先に読む** — 関連pageを特定する。中規模wiki（数百page）までは index だけで十分
2. 関連page群を読む
3. 引用付きで回答する（「<page名>によれば...」「<source名>で言及されている...」）
4. **回答形式**: markdown / 比較表 / スライド（Marp） / チャート（matplotlib） / canvas など、質問に応じた形式を選ぶ
5. **Filing back**: 回答が**将来再利用される価値がある**と判断したら、ユーザーに「この回答を `wiki/synthesis/<slug>.md` として保存しますか？」と聞き、同意が得られればfilingする。これで探索結果もwikiに蓄積される

### Lint — 健康診断

定期的に（ユーザー依頼時に）wikiの健全性をチェックする。以下を検出:

- **矛盾**: 異なるpage間で相反する主張（例: 人物Xの所属が page A では「MIT」page B では「Stanford」）
- **Stale claims**: 新しいソースにより古くなった記述
- **Orphan pages**: どこからもリンクされていないpage
- **Cross-reference不足**: 言及されているがwikilinkされていないエンティティ
- **概念の不在**: 複数ソースで言及されているのに独立pageが無い概念
- **Data gaps**: wikiに欠けているがweb検索で補完できそうな情報
- **index / log の整合性**: 実ファイルとindexの記載ズレ

検出した問題をユーザーに提示し、どれを修正するかを対話で決める。**勝手に修正しない**（特に矛盾解決は事実判断を伴うため）。

## File conventions

### `wiki/index.md`（content-oriented）

カテゴリ別に全pageをカタログ化する。各エントリは1行:

```markdown
## Entities
- [[page-name]] — 1行要約
```

詳細は `references/page-templates.md` の Index entry セクションを参照。

### `wiki/log.md`（chronological, append-only）

操作履歴を時系列で append する。**各エントリは一貫したprefix**で始めること:

```markdown
## [2026-04-23] ingest | <source title>
- Created: [[sources/xxx]]
- Updated: [[entities/yyy]], [[concepts/zzz]]
```

このprefix形式を守ると `grep "^## \[" wiki/log.md | tail -10` で最新10件が即座に取れる。

### Page types

| 種別 | path例 | 雛形 |
|---|---|---|
| Source summary | `wiki/sources/<slug>.md` | `references/page-templates.md` |
| Entity | `wiki/entities/<slug>.md` | 〃 |
| Concept | `wiki/concepts/<slug>.md` | 〃 |
| Comparison / Synthesis | `wiki/synthesis/<slug>.md` | 〃 |

ファイル名は kebab-case。Obsidian wikilink `[[slug]]` で参照可能にする。

### YAML frontmatter

すべてのwiki pageには以下のfrontmatterを付ける（Dataviewプラグインで集計可能にするため）:

```yaml
---
type: entity | concept | source | synthesis
tags: [...]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [[[source-slug-1]], [[source-slug-2]]]
---
```

## Obsidian 連携 Tips

- **Obsidian Web Clipper**: ブラウザ拡張でweb記事をmarkdownに変換して `raw/` に保存できる。ingest元として強力
- **画像のローカル保存**: Settings → Files and links → "Attachment folder path" を `raw/assets/` に設定。Hotkeys で "Download attachments for current file" をキーバインド（例: Ctrl+Shift+D）。Web Clip後にhotkeyを押すと画像がローカル保存されてLLMがviewできる
- **Graph view**: wikiの構造を俯瞰するのに最適。hub pageとorphan pageが一目でわかる
- **Marp**: markdown ベースのスライド形式。Obsidianプラグイン経由で、wikiの内容から直接プレゼン資料を生成できる
- **Dataview**: page frontmatter を SQL-like query で集計するプラグイン。tags / dates / source-count による動的リスト生成に有用
- **git管理**: wiki本体は git repo として扱う。version管理・branch・collaborationが無料で手に入る

**画像を含むソースの扱い**: LLMはmarkdown内のinline imageをone passでは読めない。まず本文を読み、その後 referenced image を個別に Read して追加コンテキストを得る運用にする。

## Optional: CLI tools

Wikiが大規模化（〜数百page超）したら、indexファイルだけでは探索効率が落ちる。その場合:

- **[qmd](https://github.com/tobi/qmd)**: ローカルmarkdown向けBM25 + vector hybrid検索、LLM re-ranking付き。CLIとMCP serverの両対応。Claude Codeから shell-out または MCP 経由で使える
- **自作の検索スクリプト**: naive な grep wrapper でも十分な場合が多い。必要になってから書く

最初から構築しない。「indexが追いつかなくなってから」導入する。

## Red flags — 避けるべきこと

- **`raw/` を書き換える**: 絶対にしない。source of truthが腐る
- **schemaを無視したpage構造**: wikiルートの `CLAUDE.md` に定義されたpath / 命名 / frontmatter規約を逸脱しない
- **index / log の更新漏れ**: ingestで10ファイル書いたのにindex / logを更新し忘れるのは最悪。wikiのナビゲーションが壊れる
- **stale claimを放置**: 矛盾を検出したのに並記・フラグせず古いまま残すと、wiki全体の信頼性が下がる
- **LLMが勝手にsourceを追加**: source curationは**常にユーザー主導**。LLMがweb検索で勝手にraw/にファイルを作らない
- **「全pageのトーンを統一しよう」等の過剰リファクタ**: 必要最小限の変更のみ。一度に大量のpageを触ると差分レビューが破綻する
- **query回答を全てfiling**: filing backは「再利用価値がある」場合のみ。単なる会話ログをwiki化すると index が腐る

## Related

- `references/schema-template.md` — 新規wikiルートに置く `CLAUDE.md` / `AGENTS.md` 雛形
- `references/page-templates.md` — source / entity / concept / synthesis / log / index entry の雛形
- Vannevar Bush の Memex (1945) — 本パターンの精神的先祖。associative trailsを手動でやっていた時代の夢を、LLMが維持コストゼロで実現する
- 具体例: [Tolkien Gateway](https://tolkiengateway.net/wiki/Main_Page) のようなfan wikiを個人規模で構築できる
