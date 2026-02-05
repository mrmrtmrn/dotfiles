-- ============================================
-- 基本設定
-- ============================================
vim.opt.number = true
vim.opt.termguicolors = true

-- Leader キーをスペースに設定
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- マウス操作を有効化
vim.opt.mouse = "a"

-- クリップボード連携（yでヤンク時にクリップボードにコピー）
vim.opt.clipboard = "unnamedplus"

-- インデント設定（Tabをスペースに変換）
vim.opt.expandtab = true      -- Tabをスペースに変換
vim.opt.tabstop = 2           -- Tab表示幅
vim.opt.shiftwidth = 2        -- インデント幅
vim.opt.softtabstop = 2       -- Tab入力時のスペース数

-- ファイル末尾に改行を追加
vim.opt.fixendofline = true
vim.opt.endofline = true

-- ============================================
-- IME / キーマップ設定
-- ============================================

-- IMEを英語に切り替える関数
local function switch_to_english()
  vim.fn.system("im-select com.apple.keylayout.ABC")
end

-- jj, kk でIME切り替え + Esc + 移動
vim.keymap.set("i", "jj", function()
  switch_to_english()
  return "<Esc>j"
end, { expr = true })

vim.keymap.set("i", "kk", function()
  switch_to_english()
  return "<Esc>k"
end, { expr = true })

-- Shift+H/J/K/L で移動（normal + visual/select モード）
vim.keymap.set({"n", "v"}, "H", "b") -- 前の単語
vim.keymap.set({"n", "v"}, "J", "}") -- 次の空行
vim.keymap.set({"n", "v"}, "K", "{") -- 前の空行
vim.keymap.set({"n", "v"}, "L", "w") -- 次の単語

-- ターミナルモードの設定（LazyGit等で正常に動作するように）
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    -- ターミナルバッファではH/J/K/Lのマッピングを無効化
    vim.keymap.set("n", "H", "H", { buffer = true })
    vim.keymap.set("n", "J", "J", { buffer = true })
    vim.keymap.set("n", "K", "K", { buffer = true })
    vim.keymap.set("n", "L", "L", { buffer = true })
    -- ターミナルに入ったら自動でインサートモードに
    vim.cmd("startinsert")
  end,
})

-- ============================================
-- lazy.nvim ブートストラップ
-- ============================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================
-- プラグイン設定
-- ============================================
require("lazy").setup({

  -- ==========================================
  -- tokyonight (カラースキーム)
  -- ==========================================
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- ==========================================
  -- nvim-tree (ファイルツリー)
  -- ==========================================
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30,
        },
      })
      -- <Space>e でファイルツリーにフォーカス（閉じるときはツリー内で q）
      vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "Focus file tree" })
    end,
  },

  -- ==========================================
  -- telescope (ファジーファインダー)
  -- ==========================================
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      -- fzf拡張を読み込む
      telescope.load_extension("fzf")

      -- <Space>ff でファイル検索
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      -- <Space>fg でgrep検索
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      -- <Space>fb でバッファ一覧
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
    end,
  },

  -- ==========================================
  -- lazygit (Git TUI)
  -- ==========================================
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- <Space>gg でLazyGitを開く
      vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })
    end,
  },

  -- ==========================================
  -- markdown-preview (Markdownプレビュー)
  -- ==========================================
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npx --yes yarn install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown preview" },
    },
  },

  -- ==========================================
  -- bullets.vim (箇条書き自動継続)
  -- ==========================================
  {
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text" },
    config = function()
      -- Tab/Shift-Tab で箇条書きのインデント操作
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "text" },
        callback = function()
          vim.keymap.set("i", "<Tab>", "<C-t>", { buffer = true })
          vim.keymap.set("i", "<S-Tab>", "<C-d>", { buffer = true })
        end,
      })
    end,
  },

  -- ==========================================
  -- vim-markdown (Markdown機能強化)
  -- ==========================================
  {
    "preservim/vim-markdown",
    ft = "markdown",
    dependencies = { "godlygeek/tabular" },
    config = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_auto_insert_bullets = 0  -- 箇条書きはbullets.vimに任せる
      vim.g.vim_markdown_new_list_item_indent = 0
    end,
  },

  -- ==========================================
  -- emmet-vim (HTML/CSS省略記法)
  -- ==========================================
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascriptreact", "typescriptreact", "vue", "svelte" },
    config = function()
      -- Emmet展開キー: <C-y>, (Ctrl+y, カンマ)
      vim.g.user_emmet_leader_key = "<C-y>"
    end,
  },

  -- ==========================================
  -- which-key (キーマップヒント表示)
  -- ==========================================
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        delay = 300, -- 300ms後にポップアップ表示
      })
      -- グループ名を設定
      wk.add({
        { "<leader>f", group = "Find (Telescope)" },
        { "<leader>g", group = "Git" },
        { "<leader>m", group = "Markdown" },
        { "<leader>l", group = "LSP" },
      })
    end,
  },

  -- ==========================================
  -- nvim-autopairs (括弧の自動補完)
  -- ==========================================
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,  -- treesitterと連携
      })
    end,
  },

  -- ==========================================
  -- mason.nvim (LSPサーバー管理)
  -- ==========================================
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- ==========================================
  -- mason-lspconfig (mason と lspconfig の連携)
  -- ==========================================
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",        -- TypeScript/JavaScript
          "tailwindcss",     -- Tailwind CSS
          "cssls",           -- CSS
          "html",            -- HTML
          "jsonls",          -- JSON
          "lua_ls",          -- Lua
        },
      })
    end,
  },

  -- ==========================================
  -- nvim-lspconfig (LSP設定) - Neovim 0.11+ API
  -- ==========================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- LspAttach イベントでキーマップを設定
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          -- 定義へジャンプ
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          -- 型定義へジャンプ
          vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
          -- 参照一覧
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          -- ホバー情報
          vim.keymap.set("n", "gK", vim.lsp.buf.hover, opts)
          -- リネーム
          vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)
          -- コードアクション
          vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
          -- フォーマット
          vim.keymap.set("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
          -- 診断（エラー）表示
          vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts)
          -- 次/前のエラーへ
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

          -- 保存時に自動フォーマット
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = args.buf,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end,
      })

      -- 各LSPサーバーの設定（vim.lsp.config API）
      local servers = { "ts_ls", "tailwindcss", "cssls", "html", "jsonls", "lua_ls" }
      for _, server in ipairs(servers) do
        local config = { capabilities = capabilities }
        -- lua_ls用の追加設定
        if server == "lua_ls" then
          config.settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
            },
          }
        end
        vim.lsp.config[server] = config
      end
      -- LSPを有効化
      vim.lsp.enable(servers)
    end,
  },

  -- ==========================================
  -- nvim-cmp (補完エンジン)
  -- ==========================================
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP補完
      "hrsh7th/cmp-buffer",    -- バッファ内の単語
      "hrsh7th/cmp-path",      -- ファイルパス
      "L3MON4D3/LuaSnip",      -- スニペットエンジン
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          -- Ctrl+Space で補完メニューを開く
          ["<C-Space>"] = cmp.mapping.complete(),
          -- Ctrl+e で補完をキャンセル
          ["<C-e>"] = cmp.mapping.abort(),
          -- Enter で確定
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          -- Tab で次の候補
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          -- Shift+Tab で前の候補
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          -- Ctrl+j/k でも上下移動
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },  -- LSPからの補完（優先）
          { name = "luasnip" },   -- スニペット
        }, {
          { name = "buffer" },    -- バッファ内の単語
          { name = "path" },      -- ファイルパス
        }),
      })
    end,
  },

})
