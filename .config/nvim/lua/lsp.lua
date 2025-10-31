local lspconfig = require("lspconfig")

if vim.fn.filereadable("package.json") == 1 then
  local pkg = vim.fn.json_decode(vim.fn.readfile("package.json"))
  local vueVersion = pkg.devDependencies.vue or pkg.dependencies.vue
  if vueVersion:match("^2") then
    lspconfig.vuels.setup({})
  else
    lspconfig.tsserver.setup({})
  end
end
