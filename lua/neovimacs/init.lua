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

local M = {}

-- Default options
M.options = {
    -- Enable Vimacs (if false, nothing is loaded)
    VM_Enabled = true,

    -- If set, we start in emacs edit mode
    -- (otherwise we start in vim normal mode)
    VM_StartInsert = true,

    -- Emacs-style hidden buffers; also selects ":hide edit" for C-x C-f
    VM_Hidden = true,

    -- Map <M-x> to ":" in Normal mode as well
    VM_NormalMetaXRemap = true,

    -- Load the console menu and bind <F10> to :emenu
    -- (off by default: menu.vim installs buffer-menu autocommands)
    VM_F10Menu = false,

    -- Maximum number of kills remembered for C-y / M-y
    VM_KillRingMax = 30,

    -- Tab Indent Style: "none", "emacs", "whitespace", "startofline"
    TabIndentStyle = "none",
}

M._did_setup = false

-- Setup function for user configuration
function M.setup(opts)
    -- Floor set by vim.keycode() and vim.fn.getregion(), both new in 0.10.
    if vim.fn.has("nvim-0.10") == 0 then
        vim.notify("neovimacs requires Neovim 0.10 or later", vim.log.levels.ERROR)
        return
    end
    opts = opts or {}
    if opts.VM_UnixConsoleMetaSendsEsc ~= nil then
        -- Neovim receives Meta natively; the termcap hacks this used to
        -- enable no longer exist.
        vim.notify_once("neovimacs: the VM_UnixConsoleMetaSendsEsc option is obsolete and ignored", vim.log.levels.WARN)
        opts.VM_UnixConsoleMetaSendsEsc = nil
    end
    M.options = vim.tbl_deep_extend("force", M.options, opts)
    M._did_setup = true
    if not M.options.VM_Enabled then
        return
    end

    require("neovimacs.options").setup(M.options)
    require("neovimacs.insertmode").setup(M.options)
    require("neovimacs.killring").setup(M.options)
    require("neovimacs.search").setup(M.options)
    require("neovimacs.keymaps").setup(M.options)
    require("neovimacs.tabindent").setup(M.options)
end

return M
