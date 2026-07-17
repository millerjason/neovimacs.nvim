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

-- All Vimacs keybindings and user commands.  Sections mirror the layout of
-- the original vimacs.vim; the behaviour lives in the sibling modules
-- (killring, motion, edit, search).
--
-- Where the original chained "<C-o>:call ...<CR>" through Normal mode (and
-- then needed :redraw or startinsert to recover), these use <Cmd> or Lua
-- callbacks, which never leave Insert mode.
local M = {}

local edit = require("neovimacs.edit")
local killring = require("neovimacs.killring")
local motion = require("neovimacs.motion")
local util = require("neovimacs.util")

function M.setup(opts)
    local function map(mode, lhs, rhs, o)
        o = o or {}
        if o.silent == nil then
            o.silent = true
        end
        vim.keymap.set(mode, lhs, rhs, o)
    end

    --
    -- Insert mode <-> Normal mode <-> Command mode
    --

    map("i", "<M-x>", "<C-o>:", { silent = false })
    map("i", "<M-:>", "<C-o>:", { silent = false })
    map("i", "<F1>", "<Esc>")
    map("i", "<F2>", "<C-o>")
    map("i", "<M-`>", "<C-o>")
    map("i", "<C-z>", function()
        util.feed("<Esc>")
        util.echo("Returning to Normal mode; press <C-z> again to suspend Neovimacs")
    end)
    map("n", "<C-z>", "<Cmd>suspend<CR>")
    for n = 1, 9 do -- digit arguments for the next Normal-mode command
        map("i", ("<M-%d>"):format(n), ("<C-o>%d"):format(n))
    end
    if opts.VM_NormalMetaXRemap then
        map("n", "<M-x>", ":", { silent = false })
    end
    -- The Emacs prefix keys shadow add/subtract in Normal mode.
    map("n", "<C-a>", "<Nop>")
    map("n", "<C-x>", "<Nop>")

    --
    -- Leaving
    --

    map("i", "<C-x><C-c>", "<Cmd>confirm qall<CR>")

    --
    -- Files & Buffers
    --

    local hide = opts.VM_Hidden and "hide " or ""
    map("i", "<C-x><C-f>", "<C-o>:" .. hide .. "edit ", { silent = false })
    map("i", "<C-x><C-s>", "<Cmd>update<CR>", { silent = false })
    map("i", "<C-x>s", "<Cmd>wall<CR>", { silent = false })
    map("i", "<C-x>i", "<C-o>:read ", { silent = false })
    map("i", "<C-x><C-w>", "<C-o>:write ", { silent = false })
    map("i", "<C-x><C-q>", "<Cmd>set invreadonly<CR>")
    map("i", "<C-x><C-r>", "<C-o>:" .. hide .. "view ", { silent = false })

    --
    -- Error recovery
    --

    map("i", "<C-_>", "<Cmd>undo<CR>")
    map("i", "<C-x><C-u>", "<Cmd>undo<CR>")

    --
    -- Command-line editing
    --

    map("c", "<C-b>", "<Left>", { silent = false })
    map("c", "<C-f>", "<Right>", { silent = false })
    map("c", "<M-f>", "<S-Right>", { silent = false })
    map("c", "<M-b>", "<S-Left>", { silent = false })
    map("c", "<C-a>", "<Home>", { silent = false })
    map("c", "<C-e>", "<End>", { silent = false })
    map("c", "<M-p>", "<Up>", { silent = false })
    map("c", "<M-n>", "<Down>", { silent = false })
    map("c", "<C-d>", "<Del>", { silent = false })
    map("c", "<C-y>", '<C-r><C-o>"', { silent = false })
    map("c", "<M-w>", "<C-y>", { silent = false })
    map("c", "<M-BS>", "<C-w>", { silent = false })
    map("c", "<C-k>", function() -- kill to end of the command line
        local pos = vim.fn.getcmdpos()
        vim.fn.setcmdline(vim.fn.getcmdline():sub(1, pos - 1), pos)
    end)

    --
    -- Navigation
    --

    map({ "i", "x", "o" }, "<C-b>", "<Left>")
    map({ "i", "x", "o" }, "<C-f>", "<Right>")
    map({ "i", "x", "o" }, "<C-p>", "<Up>")
    map({ "i", "x", "o" }, "<C-n>", "<Down>")
    map({ "i", "x", "o" }, "<M-f>", motion.forward_word)
    map({ "i", "x", "o" }, "<M-b>", motion.backward_word)
    map({ "i", "x", "o" }, "<M-Right>", motion.forward_word)
    map({ "i", "x", "o" }, "<M-Left>", motion.backward_word)
    map({ "i", "x", "o" }, "<C-Right>", motion.forward_word)
    map({ "i", "x", "o" }, "<C-Left>", motion.backward_word)
    map({ "i", "x", "o" }, "<C-a>", "<Home>")
    map({ "i", "x", "o" }, "<C-e>", "<End>")
    map("i", "<M-a>", "<C-o>(")
    map({ "x", "o" }, "<M-a>", "(")
    map("i", "<M-e>", "<C-o>)")
    map({ "x", "o" }, "<M-e>", ")")
    map({ "i", "x", "o" }, "<C-d>", "<Del>")
    map("i", "<M-<>", "<C-o>gg<C-o>0")
    map({ "x", "o" }, "<M-<>", "gg0")
    map("i", "<M->>", "<C-o>G<C-o>$")
    map({ "x", "o" }, "<M->>", "G$")
    map({ "i", "x", "o" }, "<C-v>", "<PageDown>")
    map({ "i", "x", "o" }, "<M-v>", "<PageUp>")
    map("i", "<M-m>", "<C-o>^")
    map({ "x", "o" }, "<M-m>", "^")
    map("i", "<C-x>=", "<Cmd>normal! g<C-g><CR>", { silent = false })
    map({ "i", "x", "o" }, "<M-g>", edit.goto_line)
    map({ "i", "x", "o" }, "<C-x>g", edit.goto_line)
    map("i", "<C-Up>", "<C-o>{")
    map({ "x", "o" }, "<C-Up>", "{")
    map("i", "<C-Down>", "<C-o>}")
    map({ "x", "o" }, "<C-Down>", "}")

    --
    -- General editing
    --

    map("i", "<C-u>", "<C-o>d0")
    map("i", "<C-q>", "<C-v>", { silent = false }) -- quoted insert
    map("i", "<C-^>", "<C-y>", { silent = false }) -- insert char from line above
    map("i", "<M-r>", "<C-r>=", { silent = false }) -- insert expression
    map("o", "<C-g>", "<C-c>") -- abort pending operator

    --
    -- Killing and deleting
    --

    map("i", "<M-d>", killring.kill_word)
    map("i", "<M-BS>", killring.backward_kill_word)
    map("i", "<C-BS>", killring.backward_kill_word)
    map("i", "<C-k>", killring.kill_line)
    map("i", "<M-0><C-k>", killring.kill_to_bol)
    map("i", "<M-k>", killring.kill_sentence)
    map("i", "<C-x><BS>", killring.backward_kill_sentence)
    map("i", "<M-z>", killring.zap_to_char)
    map("i", "<M-\\>", edit.delete_horizontal_space)

    --
    -- Yanking
    --

    map("i", "<C-y>", killring.yank)
    map("i", "<M-y>", killring.yank_pop)
    map("i", "<S-Insert>", "<C-r><C-o>*")

    --
    -- Completion
    --

    map("i", "<M-/>", "<C-p>", { silent = false })
    map("i", "<C-M-/>", "<C-x>", { silent = false })
    map("i", "<C-M-x>", "<C-x>", { silent = false })
    map("i", "<C-]>", "<C-x>", { silent = false })

    --
    -- Marking (region) and block operations
    --

    map("i", "<C-Space>", edit.start_visual)
    map("i", "<C-@>", edit.start_visual)
    map("x", "<C-x><C-Space>", "<Esc>")
    map("x", "<C-x><C-@>", "<Esc>")
    map("x", "<C-g>", "<Esc>")
    map("x", "<M-w>", killring.copy_region)
    map("x", "<C-w>", killring.kill_region)
    map("x", "<C-Insert>", '"+y')
    map("x", "<S-Del>", '"+d')
    map("i", "<M-Space>", function()
        edit.mark("<C-o>viw")
    end)
    map("i", "<M-h>", function()
        edit.mark("<C-o>vap")
    end)
    map("i", "<C-<>", function()
        edit.mark("<C-o>v1G0o")
    end)
    map("i", "<C->>", function()
        edit.mark("<C-o>vG$o")
    end)
    map("i", "<C-x>h", function()
        edit.mark("<Esc>1G0vGo")
    end)
    map("x", "<C-x><C-x>", "o")
    map("x", "<C-x><C-u>", "U")
    map("x", "<C-x><C-l>", "u")
    map("x", "<M-x>", ":", { silent = false })

    -- Shift-selection, ala Windows/XEmacs (needs 'keymodel' to contain
    -- "startsel" to actually start the selection).
    for _, key in ipairs({ "Up", "Down", "Left", "Right", "End", "Home", "PageUp", "PageDown" }) do
        local skey = ("<S-%s>"):format(key)
        map("i", skey, function()
            edit.start_shift_sel()
            util.feed(skey)
        end)
    end

    --
    -- Windows
    --

    map("i", "<C-x>2", "<Cmd>wincmd s<CR>")
    map("i", "<C-x>3", "<Cmd>wincmd v<CR>")
    map("i", "<C-x>0", "<Cmd>wincmd c<CR>")
    map("i", "<C-x>1", "<Cmd>wincmd o<CR>")
    map("i", "<C-x>o", "<Cmd>wincmd w<CR>")
    map("i", "<C-x>O", "<Cmd>wincmd W<CR>")
    map("i", "<C-Tab>", "<Cmd>wincmd w<CR>")
    map("i", "<C-S-Tab>", "<Cmd>wincmd W<CR>")
    map("i", "<C-x>+", "<Cmd>wincmd =<CR>")
    map("i", "<C-M-v>", edit.scroll_other_window)
    map("i", "<C-x>4<C-f>", "<C-o>:FindFileOtherWindow ", { silent = false })
    map("i", "<C-x>4f", "<C-o>:FindFileOtherWindow ", { silent = false })

    --
    -- Formatting
    --

    map("i", "<M-^>", "<Up><End><C-o>J") -- join with previous line
    map("x", "<C-M-\\>", "=")
    map("x", "<C-x><Tab>", "=")

    --
    -- Case change
    --

    map("i", "<M-l>", function()
        edit.case_word("lower")
    end)
    map("i", "<M-u>", function()
        edit.case_word("upper")
    end)
    map("i", "<M-c>", function()
        edit.case_word("capitalize")
    end)

    --
    -- Buffers
    --

    map("i", "<C-x>b", edit.buffer_select)
    map("i", "<C-x><C-b>", "<Cmd>buffers<CR>", { silent = false })
    map("i", "<C-x>k", "<C-o>:bdelete ", { silent = false })
    -- Integration with the a.vim (Alternate File) plugin.
    if vim.fn.exists("*AlternateFile") == 1 then
        map("i", "<C-x><C-a>", "<Cmd>A<CR>")
        map("i", "<C-x>a", "<Cmd>A<CR>")
    end

    --
    -- Marks ("registers" in Emacs)
    --

    map("i", "<C-x>/", edit.point_to_register)
    map("i", "<C-x>r<Space>", edit.point_to_register)
    map("i", "<C-x>r<C-Space>", edit.point_to_register)
    map("i", "<C-x>r<C-@>", edit.point_to_register)
    map("i", "<C-x>rj", edit.jump_to_register)
    map("i", "<C-x>p", "<C-o><C-o>") -- not in Emacs: previous jump-list entry

    --
    -- Transposing
    --

    map("i", "<C-t>", edit.transpose_chars)
    map("i", "<M-t>", "<Esc>dawbhpi") -- approximate transpose-words, as before
    map("i", "<C-x><C-t>", edit.transpose_lines)

    --
    -- Tags
    --

    map("i", "<M-.>", "<C-o><C-]>")
    map("i", "<M-*>", "<C-o><C-t>")
    map("i", "<C-x>4.", "<C-o><C-w>}")

    --
    -- Shells
    --

    map("x", "<M-!>", "!", { silent = false })
    map("i", "<M-!>", "<C-o>:!", { silent = false })

    --
    -- Rectangles
    --

    map("x", "<C-x>r", "<C-v>")

    --
    -- Redraw (recenter)
    --

    map("i", "<C-l>", "<C-o>zz<C-o><C-l>")

    --
    -- Folding (prefix C-x C-x, as in the original)
    --

    map("i", "<C-x><C-x><C-w>", "<C-o>zM")
    map("i", "<C-x><C-x><C-x>", "<C-o>zc")
    map("i", "<C-x><C-x><C-r><C-x>", "<C-o>zC")
    map("i", "<C-x><C-x><C-s>", "<C-o>zo")
    map("i", "<C-x><C-x><C-r><C-s>", "<C-o>zO")
    map("i", "<C-x><C-x>s", "<C-o>zR")
    map("i", "<C-x><C-x>1s", "<C-o>zr")
    map("i", "<C-x><C-x><C-q>", "<C-o>za")
    map("i", "<C-x><C-x><C-r><C-q>", "<C-o>zA")
    map("i", "<C-x><C-x>q", "<C-o>zM")
    map("i", "<C-x><C-x>1q", "<C-o>zm")

    --
    -- Menus in the console, like GNU Emacs
    --

    if opts.VM_F10Menu then
        pcall(vim.cmd, "runtime menu.vim")
        map("i", "<F10>", "<C-o>:emenu <Tab>", { silent = false })
    end

    --
    -- User commands
    --

    local cmd = vim.api.nvim_create_user_command
    cmd("QueryReplace", function()
        require("neovimacs.search").query_replace()
    end, {})
    cmd("QueryReplaceRegexp", function()
        require("neovimacs.search").query_replace_regexp()
    end, {})
    cmd("GotoLine", function()
        edit.goto_line()
    end, {})
    cmd("FillParagraph", function()
        edit.fill_paragraph()
    end, {})
    cmd("IndentParagraph", function()
        edit.indent_paragraph()
    end, {})
    cmd("FindFileOtherWindow", function(a)
        edit.find_file_other_window(a.args)
    end, { nargs = 1, complete = "file" })
    cmd("ScrollOtherWindow", function()
        edit.scroll_other_window()
    end, {})
    cmd("PointToRegister", function()
        edit.point_to_register()
    end, {})
    cmd("JumpToRegister", function()
        edit.jump_to_register()
    end, {})
end

return M
