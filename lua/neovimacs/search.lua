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

-- Incremental search and query-replace.
--
-- The original emulated repeat-search-inside-the-prompt by remapping <C-s>,
-- <C-r>, <CR>, <C-g>, and <Esc> on the fly every time a search started, and
-- toggled 'lazyredraw'/'wrapscan'/'incsearch' around it.  Neovim's native
-- incsearch offsets (c_CTRL-G / c_CTRL-T) do the same job with two static
-- mappings, and aborting the command line already restores the cursor.
local M = {}

local util = require("neovimacs.util")

function M.setup()
    local map = vim.keymap.set

    -- C-s / C-r: incremental search forward/backward, returning to Insert
    -- mode when the search is accepted or aborted.
    map("i", "<C-s>", "<C-o>/", { desc = "Isearch forward" })
    map("i", "<C-r>", "<C-o>?", { desc = "Isearch backward" })
    map("i", "<C-M-s>", "<C-o>/", { desc = "Isearch forward (regexp)" })
    map("i", "<C-M-r>", "<C-o>?", { desc = "Isearch backward (regexp)" })

    -- Inside the search prompt, C-s / C-r step to the next/previous match;
    -- on an empty prompt they recall the previous search, like Emacs C-s C-s.
    map("c", "<C-s>", function()
        local t = vim.fn.getcmdtype()
        if t == "/" or t == "?" then
            return vim.fn.getcmdline() == "" and "<Up>" or "<C-g>"
        end
        return "<C-s>"
    end, { expr = true })
    map("c", "<C-r>", function()
        local t = vim.fn.getcmdtype()
        if t == "/" or t == "?" then
            return vim.fn.getcmdline() == "" and "<Up>" or "<C-t>"
        end
        return "<C-r>" -- keep c_CTRL-R (insert register) for : and friends
    end, { expr = true })

    -- C-g aborts the command line; with 'incsearch' the cursor is restored
    -- to where the search started.
    map("c", "<C-g>", "<C-c>")

    map("i", "<M-s>", "<Cmd>set invhlsearch<CR>", { desc = "Toggle search highlight" })

    -- Not in Emacs: QuickFix navigation.
    map("i", "<M-n>", "<Cmd>cnext<CR>")
    map("i", "<M-p>", "<Cmd>cprevious<CR>")

    map(
        "i",
        "<M-%>",
        "<C-o>:lua require('neovimacs.search').query_replace()<CR>",
        { silent = true, desc = "Query replace" }
    )
    map(
        "i",
        "<C-M-%>",
        "<C-o>:lua require('neovimacs.search').query_replace_regexp()<CR>",
        { silent = true, desc = "Query replace regexp" }
    )
end

local function substitute(pattern, replacement)
    local ok, err = pcall(vim.cmd, string.format(".,$s/%s/%s/cg", pattern, replacement))
    if not ok then
        util.echo(vim.trim(tostring(err):gsub(".*Vim%S*:", "")))
    end
end

-- M-%: literal query replace from point to end of buffer.
function M.query_replace()
    local search = vim.fn.input("Query replace: ")
    if search == "" then
        util.echo("(no text entered): exiting to Insert mode")
        return
    end
    local replace = vim.fn.input("Query replace " .. search .. " with: ")
    substitute([[\V]] .. vim.fn.escape(search, [[/\]]), vim.fn.escape(replace, [[/\&~]]))
end

-- C-M-%: query replace with a vim regexp.
function M.query_replace_regexp()
    local search = vim.fn.input("Query replace regexp: ")
    if search == "" then
        util.echo("(no text entered): exiting to Insert mode")
        return
    end
    local replace = vim.fn.input("Query replace regexp " .. search .. " with: ")
    substitute(vim.fn.escape(search, "/"), vim.fn.escape(replace, "/"))
end

return M
