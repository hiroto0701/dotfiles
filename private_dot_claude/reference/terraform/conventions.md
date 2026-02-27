# Terraform規約

## ファイル構成
- `main.tf`: メインリソース定義
- `variables.tf`: 変数定義
- `outputs.tf`: 出力定義
- `providers.tf`: プロバイダ設定
- `backend.tf`: バックエンド設定

## モジュール化
- GCPサービスごとにモジュール分割
- `modules/[サービス名]/` に配置

## ステート管理
- リモートステート: GCSバケット
- ステートロック: 有効
- 環境ごとにワークスペース分離

## セキュリティ
- IAM最小権限の原則
- サービスアカウントの適切な管理
- 暗号化の有効化（Cloud KMS）
- VPCファイアウォールの最小公開

## ワークフロー
- `terraform plan` → レビュー → `terraform apply`
- 手動変更禁止（全てコードで管理）
