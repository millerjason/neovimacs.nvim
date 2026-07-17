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

-- Headless smoke tests.  Run from the repo root with:
--
--   nvim --clean --headless -l tests/smoke.lua
--
-- Exits non-zero on the first failure.

vim.opt.runtimepath:prepend(vim.fn.getcwd())

local failures = 0
local function check(desc, got, want)
    if vim.deep_equal(got, want) then
        io.write("ok   - " .. desc .. "\n")
    else
        failures = failures + 1
        io.write(("FAIL - %s\n  want: %s\n  got:  %s\n"):format(desc, vim.inspect(want), vim.inspect(got)))
    end
end

local function set_buffer(lines, row, col)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
    vim.api.nvim_win_set_cursor(0, { row, col })
end

local function buf_lines()
    return vim.api.nvim_buf_get_lines(0, 0, -1, true)
end

require("neovimacs").setup({ TabIndentStyle = "emacs" })

local motion = require("neovimacs.motion")
local killring = require("neovimacs.killring")
local edit = require("neovimacs.edit")

-- Options applied
check("selection is exclusive", vim.o.selection, "exclusive")
check("timeout disabled", vim.o.timeout, false)
check("virtualedit has onemore", vim.o.virtualedit:find("onemore") ~= nil, true)

-- Word motions
set_buffer({ "hello world", "  foo_bar baz", "", "last" }, 1, 0)
check("forward_word_pos from BOL", { motion.forward_word_pos(1, 0) }, { 1, 5 })
check("forward_word_pos mid-word", { motion.forward_word_pos(1, 2) }, { 1, 5 })
check("forward_word_pos at word end", { motion.forward_word_pos(1, 5) }, { 1, 11 })
check("forward_word_pos crosses lines", { motion.forward_word_pos(1, 11) }, { 2, 9 })
check("forward_word_pos skips blank line", { motion.forward_word_pos(2, 13) }, { 4, 4 })
check("forward_word_pos at EOB", motion.forward_word_pos(4, 4), nil)
check("backward_word_pos to prev line", { motion.backward_word_pos(2, 2) }, { 1, 6 })
check("backward_word_pos mid-word", { motion.backward_word_pos(2, 5) }, { 2, 2 })
check("backward_word_pos at word start", { motion.backward_word_pos(1, 6) }, { 1, 0 })
check("backward_word_pos at BOB", motion.backward_word_pos(1, 0), nil)

-- Kill word + consecutive-kill accumulation
set_buffer({ "hello world here" }, 1, 0)
killring.kill_word()
check("kill_word removes word", buf_lines(), { " world here" })
check("kill_word ring entry", vim.fn.getreg('"'), "hello")
killring.kill_word()
check("second kill accumulates", vim.fn.getreg('"'), "hello world")
check("buffer after two kills", buf_lines(), { " here" })

-- Non-consecutive kills make separate entries
set_buffer({ "one two three" }, 1, 0)
killring.kill_word()
vim.api.nvim_win_set_cursor(0, { 1, 4 })
killring.kill_word()
check("separate kill has own entry", killring.contents()[1], " three")
check("previous kill kept below it", killring.contents()[2], "one")

-- Backward kill word, including across lines
set_buffer({ "alpha beta", "  gamma" }, 2, 2)
killring.backward_kill_word()
check("backward_kill_word joins lines", buf_lines(), { "alpha gamma" })
check("backward_kill_word ring entry", vim.fn.getreg('"'), "beta\n  ")

-- Kill line: to EOL, then join
set_buffer({ "keep killme", "next" }, 1, 5)
killring.kill_line()
check("kill_line to EOL", buf_lines(), { "keep ", "next" })
killring.kill_line()
check("kill_line at EOL joins", buf_lines(), { "keep next" })
check("kill_line accumulated", vim.fn.getreg('"'), "killme\n")

-- Kill to beginning of line
set_buffer({ "front back" }, 1, 6)
killring.kill_to_bol()
check("kill_to_bol", buf_lines(), { "back" })
check("kill_to_bol ring entry", vim.fn.getreg('"'), "front ")

-- Yank and yank-pop
set_buffer({ "" }, 1, 0)
vim.fn.setreg('"', "newest", "c")
killring.push("older")
killring.push("newest")
killring.yank()
check("yank inserts register", buf_lines(), { "newest" })
killring.yank_pop()
check("yank_pop replaces with older kill", buf_lines(), { "older" })
check("cursor after yank_pop", vim.api.nvim_win_get_cursor(0), { 1, 5 })

-- Multi-line yank
set_buffer({ "ab" }, 1, 1)
vim.fn.setreg('"', "1\n2", "c")
killring.yank()
check("multiline yank", buf_lines(), { "a1", "2b" })
check("cursor after multiline yank", vim.api.nvim_win_get_cursor(0), { 2, 1 })

-- TextYankPost feeds the ring
set_buffer({ "yanked text" }, 1, 0)
vim.cmd("normal! yiw")
check("vim yank lands on ring", require("neovimacs.killring").contents()[1], "yanked")

-- Zap to char
set_buffer({ "abc,def" }, 1, 0)
vim.api.nvim_feedkeys(",", "n", false) -- answer the getcharstr() prompt
killring.zap_to_char()
check("zap_to_char kills up to char", buf_lines(), { ",def" })

-- Case change
set_buffer({ "hello there" }, 1, 0)
edit.case_word("upper")
check("upcase word", buf_lines(), { "HELLO there" })
check("cursor after upcase", vim.api.nvim_win_get_cursor(0), { 1, 5 })
set_buffer({ "hELLO there" }, 1, 0)
edit.case_word("capitalize")
check("capitalize word", buf_lines(), { "Hello there" })
set_buffer({ "x WORLD" }, 1, 1)
edit.case_word("lower")
check("downcase next word", buf_lines(), { "x world" })

-- Transpose chars: around point, then at EOL
set_buffer({ "abcd" }, 1, 2)
edit.transpose_chars()
check("transpose_chars around point", buf_lines(), { "acbd" })
check("cursor after transpose_chars", vim.api.nvim_win_get_cursor(0), { 1, 3 })
set_buffer({ "abcd" }, 1, 4)
edit.transpose_chars()
check("transpose_chars at EOL", buf_lines(), { "abdc" })

-- Transpose lines
set_buffer({ "first", "second", "third" }, 2, 3)
edit.transpose_lines()
check("transpose_lines swaps", buf_lines(), { "second", "first", "third" })

-- Delete horizontal space
set_buffer({ "word   \t  next" }, 1, 6)
edit.delete_horizontal_space()
check("delete_horizontal_space", buf_lines(), { "wordnext" })

-- Kill region (characterwise visual, exclusive selection)
set_buffer({ "pick this up" }, 1, 5)
vim.cmd("normal! v")
vim.api.nvim_win_set_cursor(0, { 1, 9 })
killring.kill_region()
vim.cmd("stopinsert")
check("kill_region removes selection", buf_lines(), { "pick  up" })
check("kill_region ring entry", vim.fn.getreg('"'), "this")

-- Copy region
set_buffer({ "copy that text" }, 1, 5)
vim.cmd("normal! v")
vim.api.nvim_win_set_cursor(0, { 1, 9 })
killring.copy_region()
vim.api.nvim_feedkeys("", "x", false) -- drain the fed <Esc>
check("copy_region leaves buffer alone", buf_lines(), { "copy that text" })
check("copy_region ring entry", vim.fn.getreg('"'), "that")

-- Tab indent expr behavior (no indentexpr -> plain tab)
set_buffer({ "x" }, 1, 1)
vim.bo.indentexpr = ""
vim.bo.cindent = false
local tab_rhs = vim.fn.maparg("<Tab>", "i", false, true)
check("TabIndentStyle mapping exists", tab_rhs.callback ~= nil, true)
check("tab without indentexpr is a tab", tab_rhs.callback(), "<Tab>")
vim.bo.cindent = true
check("tab with cindent reindents", tab_rhs.callback(), "<C-o>==")

-- Key bindings wired up
for _, spec in ipairs({
    { "i", "<M-d>" },
    { "i", "<C-k>" },
    { "i", "<C-y>" },
    { "i", "<M-y>" },
    { "i", "<C-s>" },
    { "c", "<C-s>" },
    { "i", "<C-x><C-s>" },
    { "i", "<C-Space>" },
    { "x", "<M-w>" },
    { "x", "<C-w>" },
    { "o", "<M-f>" },
    { "n", "<C-z>" },
    { "i", "<M-%>" },
    { "i", "<C-x>o" },
    { "i", "<Tab>" },
}) do
    check(("mapping %s %s exists"):format(spec[1], spec[2]), vim.fn.maparg(spec[2], spec[1]) ~= "", true)
end

-- Commands registered
for _, name in ipairs({ "QueryReplace", "GotoLine", "FillParagraph", "FindFileOtherWindow", "ScrollOtherWindow" }) do
    check("command " .. name .. " exists", vim.fn.exists(":" .. name) == 2, true)
end

-- Insert-mode bindings end-to-end through feedkeys.  Mode "x" appends an
-- <Esc> when done, which moves the cursor one column left, so expected
-- columns are one less than the Insert-mode position.
set_buffer({ "one two three" }, 1, 0)
vim.api.nvim_feedkeys(vim.keycode("i<M-f><M-f>"), "tx", false)
check("M-f M-f in insert mode", vim.api.nvim_win_get_cursor(0), { 1, 6 })
vim.api.nvim_feedkeys(vim.keycode("i<M-b>"), "tx", false)
check("M-b in insert mode", vim.api.nvim_win_get_cursor(0), { 1, 3 })
set_buffer({ "one two three" }, 1, 4)
vim.api.nvim_feedkeys(vim.keycode("i<C-k>"), "tx", false)
check("C-k through keymap", buf_lines(), { "one " })

if failures > 0 then
    io.write(("\n%d test(s) failed\n"):format(failures))
    os.exit(1)
end
io.write("\nall tests passed\n")
os.exit(0)
