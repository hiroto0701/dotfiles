return {
  "pocco81/auto-save.nvim",
  event = { "InsertLeave", "TextChanged" },
  config = function()
    require("auto-save").setup({
      enabled = true,
      execution_message = {
        message = function()
          return "AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S")
        end,
        dim = 0.18,
        cleaning_interval = 1250,
      },
      trigger_events = { "InsertLeave", "TextChanged" },
      debounce_delay = 135,
    })

    vim.keymap.set("n", "<leader>as", ":ASToggle<CR>", { desc = "Toggle Auto-Save" })
  end,
}

