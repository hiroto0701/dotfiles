# Next.js規約

## App Router
- `page.tsx`: ルートのUI
- `layout.tsx`: 共有レイアウト
- `loading.tsx`: ローディングUI
- `error.tsx`: エラーハンドリング
- `not-found.tsx`: 404ページ
- `route.ts`: APIルートハンドラ

## Server Components vs Client Components
- デフォルトはServer Components
- `use client`は以下の場合のみ:
  - `useState`, `useEffect`などのフックが必要
  - ブラウザAPIが必要
  - イベントハンドラが必要
- Client Componentsの範囲は最小限にする（葉ノードに押し込む）

## Route Handlers
- `src/app/api/[リソース名]/route.ts` に配置
- Zodで入力バリデーション
- エラーレスポンスは統一形式: `{ error: { code: string, message: string } }`
- 成功レスポンス: `{ data: T }`

## Server Actions
- `src/actions/[アクション名].ts` に配置
- `'use server'` ディレクティブ
- Zodで入力バリデーション
- `revalidatePath` / `revalidateTag` で適切にキャッシュ無効化

## メタデータ
- 各`page.tsx`で`generateMetadata`を定義
- OGP画像の設定
- `robots`と`sitemap`の設定
