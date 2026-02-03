# dotfiles

Neovim と Ghostty の設定ファイル

## 必要なソフトウェア

### macOS (Homebrew)

```bash
# Homebrew がなければインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 必須
brew install neovim
brew install --cask ghostty

# Neovim プラグインの依存
brew install ripgrep      # telescope live_grep 用
brew install lazygit      # Git TUI
brew install im-select    # IME 切り替え用（jj/kk でESC時に英語入力に切り替え）

# Node.js（markdown-preview 用）
# 各自の環境に合わせてインストールしてください
# 例: Volta, nvm, nodenv, brew など

# フォント
brew tap homebrew/cask-fonts
brew install --cask font-plemol-jp       # 通常版
brew install --cask font-plemol-jp-hs    # Hidden Space版（全角スペース非表示）
brew install --cask font-plemol-jp-nf    # Nerd Fonts版（アイコン対応）
```

### フォント設定

[PlemolJP](https://github.com/yuru7/PlemolJP) を使用しています。

| フォント | 説明 |
|----------|------|
| PlemolJP | 通常版（半角1:全角2） |
| PlemolJP HS | 全角スペースの可視化を削除 |
| PlemolJP NF | Nerd Fonts対応（アイコン表示用） |

Ghostty では `PlemolJP Console NF` を設定しています。

## インストール

```bash
# リポジトリをクローン
git clone https://github.com/mrmrtmrn/dotfiles.git ~/dotfiles

# セットアップスクリプトを実行
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## 含まれる設定

### Neovim (`nvim/`)

- **カラースキーム**: tokyonight
- **プラグイン管理**: lazy.nvim
- **ファイルツリー**: nvim-tree
- **ファジーファインダー**: telescope
- **Git**: lazygit.nvim
- **LSP**: mason + lspconfig (TypeScript, CSS, HTML, JSON, Lua)
- **補完**: nvim-cmp
- **その他**: autopairs, which-key, markdown-preview

#### キーマップ

| キー | 動作 |
|------|------|
| `Space` | Leader キー |
| `jj` / `kk` | ESC + IME英語切替 |
| `H` / `L` | 前/次の単語 |
| `J` / `K` | 次/前の空行 |
| `<Leader>e` | ファイルツリー |
| `<Leader>ff` | ファイル検索 |
| `<Leader>fg` | grep検索 |
| `<Leader>gg` | LazyGit |
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |

### Ghostty (`ghostty/`)

- **テーマ**: tokyonight
- **フォント**: PlemolJP Console NF (18pt)
- **画面分割**: Cmd+Enter (下), Cmd+Shift+Enter (右)
- **分割移動**: Cmd+H/J/K/L
- **分割サイズ調整**: Cmd+Shift+矢印

## ディレクトリ構成

```
dotfiles/
├── README.md
├── install.sh
├── ghostty/
│   └── config
└── nvim/
    ├── init.lua
    └── lazy-lock.json
```
