return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "vue", "css" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Volar "Take Over Mode": handle Vue + TS/JS in one server
      opts.servers.vue_ls = opts.servers.vue_ls or {}
      opts.servers.vue_ls.filetypes = { "vue", "typescript", "javascript", "javascriptreact", "typescriptreact" }
      opts.servers.vue_ls.settings = opts.servers.vue_ls.settings or {}
      opts.servers.vue_ls.settings.typescript = opts.servers.vue_ls.settings.typescript or {}
      opts.servers.vue_ls.settings.typescript.tsdk = vim.fn.stdpath("data")
        .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"

      -- Optionally, inject @vue/typescript-plugin for vtsls if you use it
      if opts.servers.vtsls then
        table.insert(opts.servers.vtsls.filetypes, "vue")
        LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
          {
            name = "@vue/typescript-plugin",
            location = LazyVim.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
            languages = { "vue" },
            configNamespace = "typescript",
            enableForWorkspaceTypeScriptVersions = true,
            vue_ls = {
              filetypes = { "vue", "typescript", "javascript", "javascriptreact", "typescriptreact" },
            },
          },
        })
      end
    end,
  },
}

-- return {
--   {
--     "neovim/nvim-lspconfig",
--     opts = function(_, opts)
--       opts.servers.vue_ls = {
--         filetypes = { "vue", "typescript", "javascript", "javascriptreact", "typescriptreact" },
--         settings = {
--           typescript = {
--             tsdk = "/home/adam/.nvm/versions/node/v22.2.0/lib/node_modules/typescript/lib",
--           },
--         },
--       }
--     end,
--   },
-- }
