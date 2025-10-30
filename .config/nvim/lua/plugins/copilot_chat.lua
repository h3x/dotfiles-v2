-- plugins/copilotchat.lua
local buffer_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
local folder_glob = buffer_dir .. "/**/*"

return {
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = {
    "zbirenbaum/copilot.lua",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("CopilotChat").setup({
      chat = {
        welcome_message = "Hello! Copilot Chat is ready.",
        keymaps = {
          close = "<C-c>", -- close chat window
          yank_last = "<C-y>", -- copy last suggestion to clipboard
          scroll_up = "<C-u>", -- scroll chat up
          scroll_down = "<C-d>", -- scroll chat down
        },
      },
      panel_layout = {
        position = "center", -- floating panel
        width = 0.8,
        height = 0.7,
      },
      popup_window = {
        border = {
          style = "rounded",
          text = { top = " Copilot Chat ", top_align = "center" },
        },
      },
      system_prompt = "You are a coding assistant. Only provide code snippets when asked.",
      sticky = {
        "#buffer", -- current buffer
        "#gitdiff:HEAD", -- all changed files
        "#file_glob:" .. folder_glob,
        -- "#file_glob:src/**/*.ts" -- all TS files under src/
      },
    })

    -- Optional keymaps
    vim.api.nvim_set_keymap("n", "<leader>cc", "<Cmd>CopilotChatToggle<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<leader>cf", "<Cmd>CopilotChatEdit<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<leader>cf", "<Cmd>CopilotChatEdit<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<leader>ce", "<Cmd>CopilotChatExplain<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<leader>ce", "<Cmd>CopilotChatExplain<CR>", { noremap = true, silent = true })
  end,
}
