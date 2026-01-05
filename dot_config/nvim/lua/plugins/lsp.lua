return {
  -- Mason（LSPサーバーのインストーラー）
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  -- Mason と lspconfig の連携
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "html",
          "cssls",
          "jsonls",
        },
        automatic_installation = true,
      })
    end,
  },

  -- Mason Tool Installer（LSP、フォーマッター、リンターを一括管理）
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- LSP servers
          "lua_ls",
          "ts_ls",
          "html",
          "cssls",
          "jsonls",
          "dockerls",
          "postgres-language-server",
          "prismals",
          "eslint",
          "docker_compose_language_service",
          "biome",

          -- Formatters
          "jq",
          "prettier",
          "biome",
          "doctoc",

          -- Linter
          "eslint_d",
          "jsonlint",
          "htmlhint",
          "biome",
        },
        auto_update = false,
        run_on_start = true,
        start_delay = 3000,
      })
    end,
  },

  -- nvim-lspconfig（after/lsp と連携）
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      -- nvim-cmpのLSP capabilities を追加
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- LSPがアタッチされたときのキーマップ設定
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf, noremap = true, silent = true }

          -- 定義へジャンプ
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          -- 宣言へジャンプ
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          -- 型定義へジャンプ
          vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
          -- 実装へジャンプ
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          -- 参照一覧
          vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
          -- ホバー（ドキュメント表示）
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          -- シグネチャヘルプ
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          -- リネーム
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          -- コードアクション
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          -- フォーマット
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
          -- 診断（エラー）表示
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
          -- 前のエラーへ
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          -- 次のエラーへ
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })

      -- 診断（エラー）表示の設定
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- 診断アイコンの設定
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- after/lsp の設定を有効化
      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "html",
        "cssls",
        "jsonls",
      })
    end,
  },
}
