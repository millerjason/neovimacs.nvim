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

-- Editing, marking, and window helpers behind the keybindings.
local M = {}

local motion = require("neovimacs.motion")
local util = require("neovimacs.util")

--
-- Case change (M-l / M-u / M-c): operate from point to the end of the
-- next word and leave the cursor there, like Emacs downcase/upcase/
-- capitalize-word.
--

function M.case_word(kind)
    local row, col = util.cursor()
    local trow, tcol = motion.forward_word_pos(row, col)
    if not trow then
        return
    end
    local text = table.concat(vim.api.nvim_buf_get_text(0, row - 1, col, trow - 1, tcol, {}), "\n")
    local replaced
    if kind == "lower" then
        replaced = vim.fn.tolower(text)
    elseif kind == "upper" then
        replaced = vim.fn.toupper(text)
    else -- capitalize
        replaced = vim.fn.substitute(text, [[\(\k\)\(\_.*\)]], [[\u\1\L\2]], "")
    end
    local lines = vim.split(replaced, "\n", { plain = true })
    vim.api.nvim_buf_set_text(0, row - 1, col, trow - 1, tcol, lines)
    local erow = row + #lines - 1
    local ecol = #lines == 1 and col + #lines[1] or #lines[#lines]
    vim.api.nvim_win_set_cursor(0, { erow, ecol })
end

--
-- Transposing
--

-- C-t: interchange the characters around point and move past them; at end
-- of line, swap the two characters before point.
function M.transpose_chars()
    local row, col = util.cursor()
    local line = vim.api.nvim_get_current_line()
    if #line < 2 then
        return
    end
    if col >= #line then
        local c1 = vim.fn.matchstr(line, [[.$]])
        local c2 = vim.fn.matchstr(line:sub(1, #line - #c1), [[.$]])
        if c2 == "" then
            return
        end
        vim.api.nvim_buf_set_text(0, row - 1, #line - #c1 - #c2, row - 1, #line, { c1 .. c2 })
    else
        if col == 0 then
            return
        end
        local before = vim.fn.matchstr(line:sub(1, col), [[.$]])
        local at = vim.fn.matchstr(line:sub(col + 1), [[^.]])
        if before == "" or at == "" then
            return
        end
        local start = col - #before
        vim.api.nvim_buf_set_text(0, row - 1, start, row - 1, col + #at, { at .. before })
        vim.api.nvim_win_set_cursor(0, { row, start + #at + #before })
    end
end

-- C-x C-t: exchange the current line with the one above, ending up below,
-- as the original's "<Up>dd<End>p<Down>" did -- but without touching any
-- register.
function M.transpose_lines()
    local row = util.cursor()
    if row < 2 then
        return
    end
    local lines = vim.api.nvim_buf_get_lines(0, row - 2, row, true)
    vim.api.nvim_buf_set_lines(0, row - 2, row, true, { lines[2], lines[1] })
    local last = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_cursor(0, { math.min(row + 1, last), 0 })
end

-- M-\: delete spaces and tabs around point.
function M.delete_horizontal_space()
    local row, col = util.cursor()
    local line = vim.api.nvim_get_current_line()
    local s, e = col, col
    while s > 0 and line:sub(s, s):match("[ \t]") do
        s = s - 1
    end
    while e < #line and line:sub(e + 1, e + 1):match("[ \t]") do
        e = e + 1
    end
    if e > s then
        vim.api.nvim_buf_set_text(0, row - 1, s, row - 1, e, {})
    end
end

--
-- Navigation
--

-- M-g / C-x g / :GotoLine
function M.goto_line()
    local target = vim.fn.input("Goto line: ")
    if target:match("^%d+$") then
        vim.cmd("normal! " .. target .. "G0")
    elseif target:match("^%d+%%$") then
        vim.cmd("normal! " .. target:sub(1, -2) .. "%")
    elseif target == "" then
        util.echo("(cancelled)")
    else
        util.echo(target .. " <- Not a Number")
    end
end

--
-- Marks ("registers" in Emacs)
--

function M.point_to_register()
    util.echo("Point to mark: ")
    local ok, c = pcall(vim.fn.getcharstr)
    if ok and c:match("^%w$") then
        vim.cmd("normal! m" .. c)
    end
end

function M.jump_to_register()
    util.echo("Jump to mark: ")
    local ok, c = pcall(vim.fn.getcharstr)
    if ok and c:match("^%w$") then
        pcall(vim.cmd, "normal! `" .. c)
    end
end

--
-- Marking (aka "region"): the keymodel/stopsel adjustments only matter for
-- users who have set 'selectmode' to include "key".
--

local function start_mark_sel()
    if vim.o.selectmode:find("key") then
        vim.opt.keymodel:remove("stopsel")
    end
end

function M.start_shift_sel()
    if vim.o.selectmode:find("key") then
        vim.opt.keymodel:append("stopsel")
    end
end

-- C-Space: start marking at point.  At end of line, start one character
-- to the right so the exclusive selection can include the last character.
function M.start_visual()
    start_mark_sel()
    local row, col = util.cursor()
    local line = vim.api.nvim_get_current_line()
    if col >= #line and row < vim.api.nvim_buf_line_count(0) then
        util.feed("<Right><C-o>v<Left>")
    else
        util.feed("<C-o>v")
    end
end

-- M-Space (mark word), M-h (mark paragraph), C-< / C-> / C-x h.
function M.mark(keys)
    start_mark_sel()
    util.feed(keys)
end

--
-- Formatting
--

-- :FillParagraph (M-q in Emacs)
function M.fill_paragraph()
    local view = vim.fn.winsaveview()
    vim.cmd("normal! gqip")
    vim.fn.winrestview(view)
end

-- :IndentParagraph
function M.indent_paragraph()
    local view = vim.fn.winsaveview()
    vim.cmd("normal! =ip")
    vim.fn.winrestview(view)
end

--
-- Windows
--

-- C-M-v / :ScrollOtherWindow
function M.scroll_other_window()
    if vim.fn.winnr("$") < 2 then
        return
    end
    vim.cmd([[wincmd w | execute "normal! \<C-f>" | wincmd p]])
end

-- C-x 4 f / :FindFileOtherWindow
function M.find_file_other_window(filename)
    if vim.fn.winnr("$") <= 1 then
        vim.cmd("wincmd s")
    end
    vim.cmd("wincmd w")
    vim.cmd("edit " .. vim.fn.fnameescape(filename))
    vim.cmd("wincmd p")
end

--
-- Buffers
--

-- C-x b: BufExplorer when available, otherwise the wildmenu on :buffer.
function M.buffer_select()
    if vim.fn.exists(":BufExplorer") == 2 then
        if vim.g.bufExplorerSortBy == nil then
            -- Default to MRU, as Emacs buffer lists do.
            vim.g.bufExplorerSortBy = "mru"
        end
        util.feed("<C-o>:BufExplorer<CR>")
    else
        util.feed("<C-o>:buffer <Tab>")
    end
end

return M
