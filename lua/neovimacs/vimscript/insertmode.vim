
" Ensure VM_Enabled has been set
"
if !exists("g:VM_Enabled") || g:VM_Enabled == 0
  finish
endif

" insertmode equivalent (see :h insertmode) in neovim
"
autocmd BufWinEnter * startinsert
inoremap <Esc> <C-X><C-Z><C-]>
inoremap <C-C> <C-X><C-Z>
inoremap <C-L> <C-X><C-Z><C-]><Esc>
inoremap <C-Z> <C-X><C-Z><Cmd>suspend<CR>
noremap <C-C> <Esc>
snoremap <C-C> <Esc>
noremap <C-\><C-G> <C-\><C-N><Cmd>startinsert<CR>
cnoremap <C-\><C-G> <C-\><C-N><Cmd>startinsert<CR>
inoremap <C-\><C-G> <C-X><C-Z>
autocmd CmdWinEnter * noremap <buffer> <C-C> <C-C>
autocmd CmdWinEnter * inoremap <buffer> <C-C> <C-C>

lua << EOF
  vim.on_key(function(c)
    if c == '\27' then
      local mode = vim.api.nvim_get_mode().mode
      if mode:find('^[nvV\22sS\19]') and vim.fn.getcmdtype() == '' then
        vim.schedule(function()
          vim.cmd('startinsert')
        end)
      end
    end
  end)
EOF

" If VM_StartInsert is set, we start in emacs edit mode
" (otherwise we start in vim normal mode)
"
if !exists("g:VM_StartInsert") || g:VM_StartInsert == 0
  finish
endif
startinsert
