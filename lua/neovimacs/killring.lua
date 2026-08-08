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

-- The Emacs kill ring, held in a Lua list (newest entry first).
--
-- This replaces the original implementation's register games: shifting
-- registers "1-"9 by hand around every kill, spilling into the w/x/y/z
-- registers, and emulating yank-pop with :undo followed by a paste from the
-- next register.  Kills edit the buffer through the API, so registers other
-- than '"' are never disturbed, and M-y replaces the last yank in place.
--
-- Consecutive kills accumulate into a single ring entry, tracked with the
-- buffer changedtick and cursor position instead of the old
-- CursorMovedI/InsertEnter/InsertLeave state machine (whose extra states
-- only existed because every kill briefly left Insert mode via <C-o>).
local M = {}

local motion = require("neovimacs.motion")
local util = require("neovimacs.util")

local ring = {}
local max_size = 30
local last_kill = nil -- { tick, row, col }: state right after the previous kill
local last_yank = nil -- region of the last C-y / M-y, for yank-pop

local function tick()
    return vim.api.nvim_buf_get_changedtick(0)
end

local function trim()
    while #ring > max_size do
        table.remove(ring)
    end
end

-- Add text to the front of the ring (most recent kill).
function M.push(text)
    if text == "" or ring[1] == text then
        return
    end
    table.insert(ring, 1, text)
    trim()
end

function M.contents()
    return ring
end

-- Delete [start, end) from the buffer and put it on the kill ring.
local function kill_range(srow, scol, erow, ecol, backwards)
    if srow > erow or (srow == erow and scol >= ecol) then
        return
    end
    local text = table.concat(vim.api.nvim_buf_get_text(0, srow - 1, scol, erow - 1, ecol, {}), "\n")
    if text == "" then
        return
    end
    local crow, ccol = util.cursor()
    local continuing = last_kill ~= nil and last_kill.tick == tick() and last_kill.row == crow and last_kill.col == ccol
    vim.api.nvim_buf_set_text(0, srow - 1, scol, erow - 1, ecol, {})
    vim.api.nvim_win_set_cursor(0, { srow, scol })
    if continuing and ring[1] then
        ring[1] = backwards and (text .. ring[1]) or (ring[1] .. text)
    else
        table.insert(ring, 1, text)
        trim()
    end
    vim.fn.setreg('"', ring[1], "c")
    last_kill = { tick = tick(), row = srow, col = scol }
end

-- M-d
function M.kill_word()
    local row, col = util.cursor()
    local trow, tcol = motion.forward_word_pos(row, col)
    if not trow then
        trow = vim.api.nvim_buf_line_count(0)
        tcol = #vim.api.nvim_buf_get_lines(0, trow - 1, trow, true)[1]
    end
    kill_range(row, col, trow, tcol, false)
end

-- M-BS / C-BS
function M.backward_kill_word()
    local row, col = util.cursor()
    local trow, tcol = motion.backward_word_pos(row, col)
    if not trow then
        trow, tcol = 1, 0
    end
    kill_range(trow, tcol, row, col, true)
end

-- C-k: kill to end of line, or join when already at end of line.
function M.kill_line()
    local row, col = util.cursor()
    local line = vim.api.nvim_get_current_line()
    if col >= #line then
        if row < vim.api.nvim_buf_line_count(0) then
            kill_range(row, #line, row + 1, 0, false)
        end
    else
        kill_range(row, col, row, #line, false)
    end
end

-- M-0 C-k
function M.kill_to_bol()
    local row, col = util.cursor()
    kill_range(row, 0, row, col, true)
end

-- M-k
function M.kill_sentence()
    local row, col = util.cursor()
    local trow, tcol = motion.normal_motion_pos(")")
    kill_range(row, col, trow, tcol, false)
end

-- C-x BS
function M.backward_kill_sentence()
    local row, col = util.cursor()
    local trow, tcol = motion.normal_motion_pos("(")
    kill_range(trow, tcol, row, col, true)
end

-- M-z: kill up to (not including) the next occurrence of a typed character
-- on the current line, like the original's "dt".
function M.zap_to_char()
    util.echo("Zap to char: ")
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == "" or char == "\27" then
        return
    end
    local row, col = util.cursor()
    local line = vim.api.nvim_get_current_line()
    local idx = line:find(char, col + 2, true)
    if idx then
        kill_range(row, col, row, idx - 1, false)
    end
end

-- C-y: insert the unnamed register at point (kills and vim yanks both land
-- there) and remember the region for yank-pop.
function M.yank()
    local text = vim.fn.getreg('"')
    if text == "" then
        return
    end
    local srow, scol = util.cursor()
    vim.api.nvim_put(vim.split(text, "\n", { plain = true }), "c", false, true)
    local erow, ecol = util.cursor()
    last_yank = {
        tick = tick(),
        srow = srow,
        scol = scol,
        erow = erow,
        ecol = ecol,
        index = 1,
    }
end

-- M-y: replace the text just yanked with the next older kill.  Editing the
-- recorded region in place replaces the old ":undo + paste next register"
-- emulation.
function M.yank_pop()
    local crow, ccol = util.cursor()
    if not last_yank or last_yank.tick ~= tick() or last_yank.erow ~= crow or last_yank.ecol ~= ccol then
        util.echo("Previous command was not a yank")
        return
    end
    if #ring == 0 then
        return
    end
    local index = last_yank.index % #ring + 1
    local lines = vim.split(ring[index], "\n", { plain = true })
    vim.api.nvim_buf_set_text(0, last_yank.srow - 1, last_yank.scol, last_yank.erow - 1, last_yank.ecol, lines)
    local erow = last_yank.srow + #lines - 1
    local ecol = #lines == 1 and last_yank.scol + #lines[1] or #lines[#lines]
    vim.api.nvim_win_set_cursor(0, { erow, ecol })
    last_yank.index = index
    last_yank.erow, last_yank.ecol = erow, ecol
    last_yank.tick = tick()
end

-- Text of the current Visual selection, honouring 'selection'.
local function region_text()
    local text = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() }), "\n")
    if vim.fn.mode() == "V" then
        text = text .. "\n"
    end
    return text
end

-- M-w in Visual mode: save the region and return to Insert mode.
function M.copy_region()
    local text = region_text()
    M.push(text)
    vim.fn.setreg('"', text, "c")
    util.feed("<Esc>") -- insertmode's on_key handler re-enters Insert mode
end

-- C-w in Visual mode: kill the region and return to Insert mode at its
-- start.  The visual selection is still active inside the mapping callback,
-- so the delete happens synchronously; only the black-hole register is
-- touched.
function M.kill_region()
    local text = region_text()
    M.push(text)
    vim.fn.setreg('"', text, "c")
    vim.cmd([[normal! "_d]])
    vim.cmd("startinsert")
end

function M.setup(opts)
    max_size = opts.VM_KillRingMax or max_size

    -- Every vim yank (M-w maps to plain "y", but also yy etc.) lands on the
    -- kill ring, so C-y / M-y see it.  Our own kills edit the buffer through
    -- the API and do not re-trigger this.
    vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("NeovimacsKillRing", { clear = true }),
        callback = function()
            local ev = vim.v.event
            if ev.operator ~= "y" then
                return
            end
            local text = table.concat(ev.regcontents, "\n")
            if ev.regtype == "V" then
                text = text .. "\n"
            end
            M.push(text)
        end,
    })
end

return M
