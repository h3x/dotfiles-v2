-- plugins/copilot.lua
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      panel = {
        enabled = true, -- floating panel with multiple suggestions
        auto_refresh = true,
        keymap = {
          jump_prev = "<A-p>", -- Alt+p to avoid duplicate keys
          jump_next = "<A-n>", -- Alt+n
          refresh = "<C-r>",
          open = "<C-o>",
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = false, -- do NOT auto-insert
        debounce = 75,
        keymap = {
          accept = "<C-y>", -- insert suggestion into file manually
          next = "<C-n>",
          prev = "<C-p>",
          dismiss = "<C-c>", -- ignore suggestion
        },
      },
      filetypes = { ["*"] = true },
      copilot_node_command = "node",
    })

    -- Optional manual trigger for inline suggestion
    vim.api.nvim_set_keymap("i", "<C-Space>", "copilot#Accept('<CR>')", { expr = true, noremap = true })
  end,
}
