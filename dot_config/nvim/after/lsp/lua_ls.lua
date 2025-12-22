-- Lua Language Server 設定
-- 参考: https://zenn.dev/uga_rosa/articles/afe384341fc2e1
---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        pathStrict = true,
        path = { "?.lua", "?/init.lua" },
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.list_extend(
          vim.api.nvim_get_runtime_file("lua", true),
          {
            "${3rd}/luv/library",
            vim.fn.stdpath("config") .. "/lua",
          }
        ),
        checkThirdParty = "Disable",
      },
      completion = {
        callSnippet = "Replace",
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

