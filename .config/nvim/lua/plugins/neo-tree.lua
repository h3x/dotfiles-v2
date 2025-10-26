return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- this makes hidden files *always* visible
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = false, -- works on Windows too
      },
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
    },
  },
}
