return {
  "max397574/better-escape.nvim",
  config = function()
    require("better_escape").setup({
      mappings = {
        i = {
          j = {
            -- These can all also be functions
            k = "<Esc>",
            j = "<Esc>",
          },
          k = {
            j = "<Esc>",
          },
        },
        c = {
          j = {
            k = "<C-c>",
            j = "<C-c>",
          },
          k = {
            j = "<Esc>",
          },
        },
        t = {
          j = {
            k = "<C-\\><C-n>",
          },
          k = {
            j = "<C-\\><C-n>",
          },
        },
        v = {
          j = {
            k = "<Esc>",
          },
          k = {
            j = "<Esc>",
          },
        },
        s = {
          j = {
            k = "<Esc>",
          },
          k = {
            j = "<Esc>",
          },
        },
      },
    })
  end,
}
