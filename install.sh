#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Setup ==="
echo "Dotfiles directory: $DOTFILES_DIR"

# バックアップ用ディレクトリ
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

backup_and_link() {
  local src="$1"
  local dest="$2"
  local backup_path

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup_path="$BACKUP_DIR${dest#$HOME}"
    echo "Backing up $dest -> $backup_path"
    mkdir -p "$(dirname "$backup_path")"
    mv "$dest" "$backup_path"
  fi

  echo "Linking $src -> $dest"
  ln -sf "$src" "$dest"
}

# ~/.config ディレクトリがなければ作成
mkdir -p "$HOME/.config"

# Neovim
backup_and_link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Ghostty
backup_and_link "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# Claude Code
mkdir -p "$HOME/.claude"
backup_and_link "$DOTFILES_DIR/claude/skills" "$HOME/.claude/skills"
backup_and_link "$DOTFILES_DIR/claude/hooks" "$HOME/.claude/hooks"
backup_and_link "$DOTFILES_DIR/claude/settings.local.json" "$HOME/.claude/settings.local.json"
backup_and_link "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# Codex CLI
mkdir -p "$HOME/.codex"
backup_and_link "$DOTFILES_DIR/codex/skills" "$HOME/.codex/skills"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "1. Install required software (see README.md)"
echo "2. Restart your terminal"
echo "3. Open nvim to install plugins automatically"
