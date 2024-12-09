local M = {}

-- Default options
M.options = {
    -- Enable Vimacs
    VM_Enabled = true,

    -- If set, we start in emacs edit mode
    -- (otherwise we start in vim normal mode)
    VM_StartInsert = true,

    -- Should meta send escape
    -- (required for some terminals, incompatible with others)
    VM_UnixConsoleMetaSendsEsc = false,

    -- Tab Indent Style: none, emacs, whitespace, startofline
    TabIndentStyle = "none",
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
    vim.g.VM_Enabled = M.options.VM_Enabled and 1 or 0
    vim.g.VM_StartInsert = M.options.VM_StartInsert and 1 or 0
    vim.g.VM_UnixConsoleMetaSendsEsc = M.options.VM_UnixConsoleMetaSendsEsc and 1 or 0
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
    --- Undefine unwanted overlaps
    vim.api.nvim_set_keymap("i", "<Esc>", "<Esc>", { noremap = true })
    vim.api.nvim_set_keymap("n", "<C-a>", "<Nop>", { noremap = true })
    vim.api.nvim_set_keymap("n", "<C-x>", "<Nop>", { noremap = true })
end

return M
