-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- LazyVim keymap to search document symbols for classes and tags in Vue files
vim.keymap.set('n', '<leader>a', function()
  if vim.bo.filetype == 'vue' then
    require('telescope.builtin').lsp_document_symbols({
      symbols = { 'Class', 'Struct', 'Interface', 'Module', 'Tag' }
    })
  else
    require('telescope.builtin').lsp_document_symbols({
      symbols = { 'Class' }
    })
  end
end, { desc = 'Search document symbols (Vue: Classes & Tags)' })
