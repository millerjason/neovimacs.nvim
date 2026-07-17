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

-- Emulation of Vim's removed 'insertmode' option: Insert mode is "home",
-- Normal mode is the excursion.
--
--   * <Esc> in Insert mode leaves to Normal mode as usual.
--   * <Esc> in Normal/Visual/Select mode returns to Insert mode
--     (single-Esc toggling, watched via vim.on_key).
--   * <C-c> in Insert mode stays in Insert mode; in other modes it acts
--     like <Esc>.
--   * <C-\><C-g> goes to Insert mode from anywhere (:h i_CTRL-\_CTRL-G).
local M = {}

local ns = vim.api.nvim_create_namespace("neovimacs.insertmode")

local function enter_insert()
    if vim.fn.mode() ~= "n" then
        return
    end
    -- Don't force Insert mode in help/quickfix/plugin buffers.
    if vim.bo.modifiable and vim.bo.buftype == "" then
        vim.cmd("startinsert")
    end
end

function M.setup(opts)
    local group = vim.api.nvim_create_augroup("NeovimacsInsertMode", { clear = true })
    local map = vim.keymap.set

    vim.on_key(function(key)
        if key ~= "\27" then
            return
        end
        local mode = vim.api.nvim_get_mode().mode
        if mode:find("^[nvV\22sS\19]") and vim.fn.getcmdtype() == "" then
            vim.schedule(enter_insert)
        end
    end, ns)

    map("i", "<C-c>", "<C-x><C-z>") -- dismiss completion, stay in Insert mode
    map({ "n", "x", "s", "o" }, "<C-c>", "<Esc>")
    map({ "n", "x", "o" }, "<C-\\><C-g>", "<C-\\><C-n><Cmd>startinsert<CR>")
    map("c", "<C-\\><C-g>", "<C-\\><C-n><Cmd>startinsert<CR>")
    map("i", "<C-\\><C-g>", "<C-x><C-z>")

    -- Keep <C-c> usable to leave the command-line window.
    vim.api.nvim_create_autocmd("CmdwinEnter", {
        group = group,
        callback = function(ev)
            map("n", "<C-c>", "<C-c>", { buffer = ev.buf })
            map("i", "<C-c>", "<C-c>", { buffer = ev.buf })
        end,
    })

    if opts.VM_StartInsert then
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = group,
            callback = function()
                if vim.api.nvim_win_get_config(0).relative == "" then
                    enter_insert()
                end
            end,
        })
        if vim.v.vim_did_enter == 1 then
            enter_insert()
        else
            vim.api.nvim_create_autocmd("VimEnter", {
                group = group,
                once = true,
                callback = enter_insert,
            })
        end
    end
end

return M
