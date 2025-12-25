return {
  'alvan/vim-closetag',
  ft = { 'html', 'xml', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue', 'svelte' },
  config = function()
    vim.g.closetag_filenames = '*.html,*.xhtml,*.phtml,*.jsx,*.tsx,*.vue,*.svelte'
    vim.g.closetag_filetypes = 'html,xhtml,phtml,javascript,javascriptreact,typescript,typescriptreact,vue,svelte'
    vim.g.closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'
    vim.g.closetag_xhtml_filetypes = 'xhtml,javascript.jsx,typescript.tsx'
    vim.g.closetag_enable_react_fragment = 1
    vim.g.closetag_close_shortcut = '<leader>>'
  end,
}