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

-- Word motions with Emacs semantics (a word is a run of 'iskeyword'
-- characters; punctuation is skipped over, and motions cross line
-- boundaries).  Positions are computed directly instead of replaying
-- normal-mode motions under a temporarily modified 'virtualedit'.
local M = {}

local util = require("neovimacs.util")

local word_re = vim.regex([[\k\+]])

-- Position just past the end of the word at-or-after (row, col),
-- or nil at end of buffer.
function M.forward_word_pos(row, col)
    local total = vim.api.nvim_buf_line_count(0)
    while row <= total do
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
        if col < #line then
            local s, e = word_re:match_line(0, row - 1, col)
            if s then
                return row, col + e
            end
        end
        row, col = row + 1, 0
    end
    return nil
end

-- Position of the start of the word ending at-or-before (row, col),
-- or nil at start of buffer.
function M.backward_word_pos(row, col)
    local limit = col
    while row >= 1 do
        if limit > 0 then
            local best, init = nil, 0
            while init < limit do
                local s, e = word_re:match_line(0, row - 1, init)
                if not s then
                    break
                end
                s, e = s + init, e + init
                if s >= limit then
                    break
                end
                best = s
                init = e
            end
            if best then
                return row, best
            end
        end
        row = row - 1
        if row >= 1 then
            limit = #vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
        end
    end
    return nil
end

-- M-f: works unchanged in Insert, Visual, and Operator-pending mode; in
-- Visual mode moving the cursor extends the selection, so none of the old
-- exit-and-reenter-visual trickery is needed.
function M.forward_word()
    local row, col = util.cursor()
    local trow, tcol = M.forward_word_pos(row, col)
    if trow then
        vim.api.nvim_win_set_cursor(0, { trow, tcol })
    end
end

-- M-b
function M.backward_word()
    local row, col = util.cursor()
    local trow, tcol = M.backward_word_pos(row, col)
    if trow then
        vim.api.nvim_win_set_cursor(0, { trow, tcol })
    end
end

-- Where a normal-mode motion such as "(" or ")" would land, without
-- actually moving the cursor.
function M.normal_motion_pos(motion)
    local save = vim.api.nvim_win_get_cursor(0)
    vim.cmd("keepjumps normal! " .. motion)
    local target = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, save)
    return target[1], target[2]
end

return M
