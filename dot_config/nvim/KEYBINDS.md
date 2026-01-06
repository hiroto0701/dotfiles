# Neovim キーバインド一覧

## 基本設定

- **リーダーキー**: `Space`

## バッファ操作 (barbar.nvim)

| キー | 機能 |
|------|------|
| `Tab` | 次のバッファへ |
| `Shift+Tab` | 前のバッファへ |
| `Shift+h` | バッファを左に移動 |
| `Shift+l` | バッファを右に移動 |
| `<leader>x` | バッファを閉じる |
| `<leader>X` | バッファを強制的に閉じる |
| `<leader>p` | バッファをピン留め |
| `<leader>b` | バッファを選択（ジャンプモード） |
| `<leader>1~9` | バッファ1〜9へジャンプ |
| `<leader>0` | 最後のバッファへ |
| `<leader>bd` | バッファを削除 (Snacks) |

## ファイル検索 (Telescope)

| キー | 機能 |
|------|------|
| `Ctrl+p` | ファイル検索 |
| `<leader>fg` | テキスト検索 (live_grep) |

## ファイルエクスプローラー (Neo-tree)

| キー | 機能 |
|------|------|
| `<leader>e` | Neo-treeをトグル |
| `<leader>o` | Neo-treeにフォーカス |
| `<leader>gs` | Git Statusをフロート表示 |

## ターミナル

### ToggleTerm

| キー | 機能 |
|------|------|
| `Ctrl+\` | ターミナルをトグル |
| `<leader>tt` | ターミナルをトグル |
| `<leader>t1` | ターミナル1 |
| `<leader>t2` | ターミナル2 |
| `<leader>t3` | ターミナル3 |

#### ターミナルモード内

| キー | 機能 |
|------|------|
| `Esc` | ノーマルモードに戻る |
| `Ctrl+h/j/k/l` | ウィンドウ移動 |

### Snacks Terminal

| キー | 機能 |
|------|------|
| `Ctrl+/` | ターミナルをトグル |

## LSP

| キー | 機能 |
|------|------|
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gt` | 型定義へジャンプ |
| `gi` | 実装へジャンプ |
| `<leader>gr` | 参照一覧 |
| `K` | ホバー（ドキュメント表示） |
| `Ctrl+k` | シグネチャヘルプ |
| `<leader>rn` | リネーム |
| `<leader>ca` | コードアクション |
| `<leader>f` | フォーマット |
| `<leader>d` | 診断（エラー）表示 |
| `[d` | 前のエラーへ |
| `]d` | 次のエラーへ |
| `<leader>cR` | ファイル名変更 (Snacks) |

## 診断・トラブルシューティング (Trouble)

| キー | 機能 |
|------|------|
| `<leader>xx` | 診断リスト |
| `<leader>xX` | バッファ診断リスト |
| `<leader>cs` | シンボルリスト |
| `<leader>cl` | LSP定義/参照リスト |
| `<leader>xL` | ロケーションリスト |
| `<leader>xQ` | クイックフィックスリスト |

## コード分割・結合 (Treesj)

| キー | 機能 |
|------|------|
| `<leader>m` | トグル |
| `<leader>j` | トグル |
| `<leader>s` | トグル |

## Picker (Snacks)

| キー | 機能 |
|------|------|
| `,<CR>` | Pickerアクション |
| `,<Space>` | Grep |
| `,b` | バッファ内Grep |
| `,s` | カーソル下の単語を検索 |
| `,P` | プロジェクト選択 |
| `,B` | バッファ選択 |
| `,c` | カラースキーム選択 |
| `,f` | ファイル検索 |
| `,g` | Gitブランチ選択 |
| `,h` | ヘルプページ検索 |
| `,j` | ジャンプリスト |
| `,l` | Lazy |
| `,m` | マーク |
| `,p` | コマンド |
| `,q` | クイックフィックスリスト |
| `,r` | Resume |
| `,t` | TODO |
| `,i` | アイコン |
| `,z` | Zoxide |
| `,d` | バッファ診断 |
| `,D` | 診断 |

## Git (Lazygit & Snacks)

| キー | 機能 |
|------|------|
| `<leader>g` | Lazygit |
| `<leader>gg` | Lazygit |
| `<leader>gl` | Lazygit Log |
| `<leader>gk` | Lazygit Log File |
| `<leader>gB` | Git Browse |

## その他 (Snacks)

| キー | 機能 |
|------|------|
| `<leader>z` | Zen Mode |
| `<leader>.` | スクラッチバッファをトグル |
| `<leader>S` | スクラッチバッファ選択 |
| `<leader>n` | 通知履歴 |
| `<leader>un` | すべての通知を消去 |
| `]]` | 次の参照へ |
| `[[` | 前の参照へ |

## 補完 (nvim-cmp)

### Insert/Command モード

| キー | 機能 |
|------|------|
| `Ctrl+b` | ドキュメントを上にスクロール |
| `Ctrl+f` | ドキュメントを下にスクロール |
| `Ctrl+Space` | 補完を表示 |
| `Ctrl+e` | 補完を中止 |
| `Enter` | 補完を確定 |
| `Tab` | 次の候補/スニペット展開・ジャンプ |
| `Shift+Tab` | 前の候補/スニペットバックジャンプ |

## テキストオブジェクト操作

### nvim-surround

デフォルトのキーマップを使用:

- `ys{motion}{char}`: テキストを囲む
  - 例: `ysiw"` - カーソル下の単語を `"` で囲む
  - 例: `yss)` - 行全体を `()` で囲む
- `ds{char}`: 囲みを削除
  - 例: `ds"` - `"` を削除
- `cs{old}{new}`: 囲みを変更
  - 例: `cs"'` - `"` を `'` に変更

### various-textobjs

デフォルトのキーマップを使用（多数のテキストオブジェクト）:

- `ii` / `ai`: インデント
- `iS` / `aS`: サブワード
- `iv` / `av`: 値
- その他多数のカスタムテキストオブジェクト

## フォーマット (Conform)

保存時に自動フォーマット（設定済み言語: Lua, JavaScript, TypeScript, JSON, GraphQL）
