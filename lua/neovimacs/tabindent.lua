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

-- TabIndent: overload <Tab> to either insert a tab or reindent the line
-- (pure-lua port of tab-indent.vim; the cpoptions save/restore is not
-- needed for a Lua expr mapping).
local M = {}

function M.setup(opts)
    local style = opts.TabIndentStyle
    if style == nil or style == false or style == 0 or style == "none" then
        return
    end

    vim.keymap.set("i", "<Tab>", function()
        if not vim.bo.cindent and vim.bo.indentexpr == "" then
            return "<Tab>"
        end

        -- Reindenting an empty line needs a placeholder character for "==".
        local indent_blank_line = "<End>x<C-o>==<End><Left><Del>"
        local indent = "<C-o>=="

        if style == 1 or style == "emacs" or style == "always" then
            if vim.api.nvim_get_current_line():match("^%s*$") then
                return indent_blank_line
            end
            return indent
        elseif style == 2 or style == "whitespace" then
            if vim.fn.virtcol(".") <= vim.fn.indent(".") then
                return indent
            end
            return "<Tab>"
        elseif style == 3 or style == "startofline" then
            local vcol = vim.fn.virtcol(".")
            if vcol <= vim.fn.indent(".") or vcol == 1 then
                return indent
            end
            return "<Tab>"
        end
        return "<Tab>"
    end, { expr = true, silent = true })
end

return M
