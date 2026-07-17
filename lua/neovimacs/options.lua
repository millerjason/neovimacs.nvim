-- This file is part of Neovimacs, Emacs key emulation for Neovim.
--
-- Neovimacs is a derivative work of Vimacs ("Vim-Improved eMACS", by
-- Andre Pang, https://github.com/andrep/vimacs), ported to Neovim and
-- rewritten in Lua.
--
-- Copyright (C) 2002 Andre Pang <ozone@vimacs.cx>
-- Copyright (C) 2024-2026 Jason Miller
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the
-- Free Software Foundation; either version 2 of the License, or (at your
-- option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License (in the LICENSE file) for more details.

-- Editor options needed for Emacs-ish behaviour.
--
-- Options the original vimacs.vim set that are neovim defaults or obsolete
-- are no longer touched: 'backspace' (default indent,eol,start), 'incsearch'
-- (default on), 'winaltkeys' (GUI-only), 'cmdheight' bumping (message
-- handling is fine in nvim), and the ':set <M-x>=x' termcap hacks (nvim
-- receives Meta natively).
local M = {}

function M.setup(opts)
    -- Emacs wraps all movement across line boundaries.
    vim.o.whichwrap = "b,s,<,>,[,],~,h,l"

    -- Emacs always has hidden buffers.
    if opts.VM_Hidden then
        vim.o.hidden = true
    end

    -- The Emacs region excludes the character at point; 'onemore' lets the
    -- cursor (and so the region end) sit just past end-of-line in Normal and
    -- Visual mode.  This replaces the old save/restore 'virtualedit'
    -- juggling that wrapped every word motion.
    vim.o.selection = "exclusive"
    vim.opt.virtualedit:append("onemore")

    -- Let <Tab> open the wildmenu from inside a mapping (used by C-x b).
    vim.o.wildcharm = 9 -- <Tab>

    -- Emacs waits indefinitely after a prefix key (C-x ...).  Key-code
    -- timeout ('ttimeout') keeps its nvim default and still applies.
    vim.o.timeout = false
end

return M
