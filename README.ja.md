# Shared Context Git Skill

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

複数のAIエージェントがGitベースのリモートリポジトリを通じてプロジェクトのコンテキストを共有するための標準化されたワークフローを提供するスキルです。エージェントはMarkdownファイルで構成された共有メモリを読み書きし、Gitの履歴をレビュートレイルとして活用します。

## 主な機能

- 標準ドキュメントテンプレートを使った共有コンテキストリポジトリの初期化
- 読み書き前のローカルクローンの安全な同期
- 安定した事実、アクティブコンテキスト、意思決定、未解決の質問の記録
- ブランチベースのコンテキスト更新によるdiffレビューのサポート
- ローカル状態が古くなっているか競合している場合の安全な停止

## リポジトリ構造

```
├── SKILL.md                    # スキル定義とコアルール
├── agents/
│   ├── openai.yaml             # OpenAIエージェント連携設定
│   ├── claude.yaml             # Claude Codeエージェント連携設定
│   └── codex.yaml              # OpenAI Codexエージェント連携設定
├── scripts/                    # 自動化Bashスクリプト
│   ├── bootstrap_repo.sh       # テンプレートから初期ドキュメントを生成
│   ├── check_divergence.sh     # コンテキストブランチの乖離と古いブランチを報告
│   ├── cleanup_branches.sh     # 古いマージ済みcontext/*ブランチを削除
│   ├── sync_context.sh         # リモート変更をfetchしてfast-forward
│   ├── prepare_branch.sh       # コンテキストブランチを作成
│   ├── validate_context.sh     # ドキュメント構造を検証
│   └── summarize_context.sh    # ステータスサマリーと圧縮ヒントを出力
├── tests/                      # BATSによるリグレッションテスト
│   ├── *.bats                  # スクリプト別の動作テスト
│   ├── test_helper.bash        # 共有テストヘルパー
│   ├── run_tests.sh            # フルテストランナー
│   └── lib/bats-core/          # Gitサブモジュールで管理されるBATSランナー
├── assets/
│   └── templates/              # ドキュメントスタータテンプレート
│       ├── CONTEXT.md           # 共有状態ドキュメント
│       ├── HANDOFF.md           # 引き継ぎノート（任意）
│       └── POLICY.md            # 協働ポリシー（任意）
└── references/                 # 詳細リファレンスドキュメント
    ├── schema.md               # ドキュメント構造仕様
    ├── update-rules.md         # 更新ルール
    ├── git-workflows.md        # Gitワークフローパターン
    ├── conflict-policy.md      # 競合処理ポリシー
    └── handoff-guidelines.md   # 引き継ぎガイドライン
```

## ドキュメント構成

### 必須ドキュメント

| ドキュメント | 説明 |
|-------------|------|
| `CONTEXT.md` | 現在のプロジェクト状態を要約するコアドキュメント。概要、安定した事実、アクティブコンテキスト、意思決定、未解決の質問セクションで構成。 |

### 任意ドキュメント

| ドキュメント | 説明 |
|-------------|------|
| `HANDOFF.md` | 次のエージェントへの引き継ぎノート。 |
| `POLICY.md` | チームの協働ポリシーとガイドライン。 |

## コアルール

1. **読み優先**: fetchまたはsync後、`CONTEXT.md`を読んでから編集します。
2. **共有メモリはリポジトリに保存**: セッションローカルのノートではなく、リポジトリに共有メモリを保管します。
3. **ブランチベースの更新を優先**: デフォルトブランチへの直接pushは避け、ブランチを通じて更新します。
4. **競合の自動解決禁止**: リポジトリがdirtyまたはブランチが乖離している場合は、停止して調整します。
5. **事実と推論を分離**: 検証済みの事実は安定セクションに、不確実な内容は未解決の質問に記録します。
6. **変更履歴はコミットメッセージに記録**: 別ファイルではなく、構造化されたコミットメッセージ（Trigger/Applied/Unresolved）を使用します。

## 使い方

### ワークフロー

```bash
# 1. リポジトリが存在しない場合は初期化
scripts/bootstrap_repo.sh

# 2. ローカルクローンで同期
scripts/sync_context.sh

# 3. CONTEXT.md、HANDOFF.md（存在する場合）を読む

# 4. 更新を共有する場合はブランチを作成
scripts/prepare_branch.sh --actor <name> --slug <topic>

# 5. Markdownファイルを更新

# 6. ドキュメント構造を検証
scripts/validate_context.sh

# 7. diffを確認して現在の状態を要約
scripts/summarize_context.sh

# 8. 変更が意味のある正確なものであればコミット & プッシュ
```

### スクリプトガイド

| スクリプト | 説明 |
|-----------|------|
| `bootstrap_repo.sh` | テンプレートから初期ドキュメントセットを作成します。 |
| `check_divergence.sh` | `context/*`ブランチのベースブランチからの乖離と古いブランチを報告します。 |
| `cleanup_branches.sh` | マージ済みの古い`context/*`ブランチをローカルおよびオプションで`origin`から削除します。 |
| `sync_context.sh` | リモート変更をfetchし、安全な場合にベースブランチをfast-forwardします。 |
| `prepare_branch.sh` | `context/<actor>/<YYYY-MM-DD>-<slug>`という名前のブランチを作成または切り替えます。 |
| `validate_context.sh` | 必須ファイルと見出しを確認します。 |
| `summarize_context.sh` | コンパクトなステータスサマリーと圧縮ヒントを出力します。 |

## テスト

```bash
git submodule update --init --recursive
./tests/run_tests.sh
```

- テストはBATSを使用して`scripts/`配下のワークフロースクリプトの正常/エラーパスを検証します。
- `tests/run_tests.sh`はバンドルされた`tests/lib/bats-core`サブモジュールを使って`.bats`スイート全体を実行します。

## 協働モード

- **ローカル草稿のみ**: 同期、読み込み、ローカル編集、検証後にコミットなしで停止。
- **ブランチへのコミット & プッシュ**: コンテキストブランチを作成し、ドキュメントを更新、検証、コミット、プッシュ。
- **PRプロポーザル**: Gitの作業を行い、PR作成はこのスキルの外のプロバイダー固有ツールに委任。

## リファレンスドキュメント

- [schema.md](references/schema.md) — ドキュメント構造仕様
- [update-rules.md](references/update-rules.md) — 更新ルール
- [git-workflows.md](references/git-workflows.md) — Gitワークフローパターン
- [conflict-policy.md](references/conflict-policy.md) — 競合処理ポリシー
- [handoff-guidelines.md](references/handoff-guidelines.md) — 引き継ぎガイドライン

## エージェント設定

各エージェントフレームワーク向けの設定ファイルが`agents/`ディレクトリに含まれています。

| 設定ファイル | エージェント | デフォルトアクター名 | ブランチプレフィックス |
|-------------|-------------|-------------------|-------------------|
| `agents/openai.yaml` | OpenAI Agents | `openai` | `context/openai` |
| `agents/claude.yaml` | Claude Code | `claude` | `context/claude` |
| `agents/codex.yaml` | OpenAI Codex | `codex` | `context/codex` |

各設定にはスキル参照パス（`skill_paths`）、デフォルトパラメータ（`parameters`）、ワークフローヒント（`workflow_hints`）が含まれています。

### OpenAI Agentsの使い方

```bash
# 設定ファイルパス: agents/openai.yaml
# ブランチ作成例:
scripts/prepare_branch.sh --actor openai --slug my-topic
```

### Claude Codeの使い方

```bash
# 設定ファイルパス: agents/claude.yaml
# ブランチ作成例:
scripts/prepare_branch.sh --actor claude --slug my-topic
```

### Codexの使い方

```bash
# 設定ファイルパス: agents/codex.yaml
# ブランチ作成例:
scripts/prepare_branch.sh --actor codex --slug my-topic
```

## 要件

- Git CLI
- Bashシェル
- 標準Unixユーティリティ（grep、awkなど）

外部パッケージやライブラリの依存関係はありません。
