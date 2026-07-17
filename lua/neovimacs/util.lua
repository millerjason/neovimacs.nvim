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

-- Small shared helpers.
local M = {}

-- Feed keys (noremap, untyped) into the input queue.
function M.feed(keys)
    vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
end

-- Cursor position as (row, col): 1-based row, 0-based byte column.
function M.cursor()
    local pos = vim.api.nvim_win_get_cursor(0)
    return pos[1], pos[2]
end

function M.echo(msg)
    vim.api.nvim_echo({ { msg } }, false, {})
end

return M
