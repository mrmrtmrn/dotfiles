# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 概要

macOS 向けの Neovim と Ghostty の個人用 dotfiles。

## コマンド

```bash
# インストール（~/.config/ にシンボリックリンクを作成）
./install.sh

# Neovim を起動（初回起動時に lazy.nvim がプラグインを自動インストール）
nvim
```

## アーキテクチャ

### ディレクトリ構成
- `nvim/init.lua` - lazy.nvim を使った単一ファイルの Neovim 設定
- `nvim/lazy-lock.json` - プラグインのバージョンロックファイル（自動生成）
- `ghostty/config` - Ghostty ターミナルの設定
- `Codex/skills/` - Codex のカスタムスキル（全プロジェクト共通）
- `Codex/hooks/` - Codex の PreToolUse フック（git commit/push 前のセキュリティチェック）
- `Codex/settings.local.json` - Codex のユーザー設定（許可コマンド、hooks 設定など）
- `install.sh` - シンボリックリンク作成スクリプト（既存設定は `~/.dotfiles_backup/` にバックアップ）

### TIL 連携スキル
- `codex/skills/til-send/` - TIL へ学びを送るグローバル入口
- `codex/skills/session-note/` - `til-send` への互換用エイリアス
- 詳細手順の正本は TIL リポジトリ側にあり、dotfiles 側では再定義しない

### 設計方針
- **単一 init.lua**: Neovim 設定は分割せず1ファイル（約400行）に集約
- **統一テーマ**: Neovim と Ghostty で tokyonight を使用
- **日本語キーボード対応**: `jj`/`kk` でESC時に im-select で英語入力に切り替え
- **Leader キー**: Space

### Neovim プラグイン構成
- プラグイン管理: lazy.nvim（自動ブートストラップ）
- LSP: mason + mason-lspconfig (ts_ls, tailwindcss, cssls, html, jsonls, lua_ls)
- 補完: nvim-cmp（LSP, スニペット, バッファ, パス）
- ファイル操作: nvim-tree, telescope（ripgrep 必須）
- Git: lazygit.nvim（lazygit CLI 必須）

### 依存関係 (Homebrew)
必須: `neovim`, `ghostty`, `ripgrep`, `lazygit`, `im-select`
任意: Node.js（markdown-preview 用）
フォント: PlemolJP Console NF
