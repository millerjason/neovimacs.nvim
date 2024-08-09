local M = {}

-- Default options
M.options = {
    -- Enable vimacs
    VM_Enabled = 1,

    -- If set, we start in emacs edit mode
    -- (otherwise we start in vim normal mode)
    VM_StartInsert = 1,

    -- Tab Style: emacs, whitespace, startofline
    TabIndentStyle = "emacs"
}

-- Find plugin root
local function find_plugin_root()
    local path = debug.getinfo(1, "S").source:sub(2)
    path = vim.fn.fnamemodify(path, ":h")
    return path
end
M.plugin_root = find_plugin_root()

-- Set vimscript globals from configuration
function M.set_vim_globals()
    vim.g.VM_Enabled = M.options.VM_Enabled
    vim.g.VM_StartInsert = M.options.VM_StartInsert
    vim.g.TabIndentStyle = M.options.TabIndentStyle
end

-- Setup function for user configuration
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
    M.set_vim_globals()
    local vimscript_path = M.plugin_root .. "/vimscript/"
    vim.cmd("source " .. vimscript_path .. "insertmode.vim")
    vim.cmd("source " .. vimscript_path .. "vimacs.vim")
    vim.cmd("source " .. vimscript_path .. "tab-indent.vim")
end

return M
