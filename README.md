# 💥 Neovimacs

**Neovimacs** is vimacs for the neovim age.

This project is a pure-lua rewrite of the original vimacs scripts (emacs key
emulation for vim), rebuilt on neovim APIs (`vim.keymap`, `vim.on_key`,
buffer APIs, native incsearch). Requires **neovim 0.10+** (tested on 0.12).

See [MAPPINGS.md](MAPPINGS.md) for the full keybinding reference and notes
on what changed relative to the original vimscript implementation.

## 📦 Installation

1. Prepare your shell by adding this to your startup (turn off <C-s> and <C-q> flow control, emacs uses them):

```bash
stty -ixon -ixoff
```

2. Install the plugin with your favorite neovim package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
   "millerjason/neovimacs.nvim",
   opts = {},
}
```

3. Enjoy modeless editing throughout neovim

## ⚙️ Configuration

To install the plugin with custom options (lazy example provided):

```lua
{
   "millerjason/neovimacs.nvim",
   opts = {
     VM_Enabled = true,
     VM_StartInsert = false, -- Start in normal (not insert) mode
   },
}
```

## ✨ Options

- **VM_Enabled** (default true): enable vimacs (if false, nothing is loaded)
- **VM_StartInsert** (default true): if set, start in emacs insert mode instead of vim normal mode
- **VM_Hidden** (default true): emacs-style hidden buffers; `C-x C-f` uses `:hide edit`
- **VM_NormalMetaXRemap** (default true): map `M-x` to `:` in normal mode too
- **VM_KillRingMax** (default 30): number of kills remembered for `C-y` / `M-y`
- **VM_F10Menu** (default false): load the console menu and bind `F10` to `:emenu`
- **TabIndentStyle** (default "none"): "emacs", "whitespace", or "startofline" tab indent behavior

Removed: **VM_UnixConsoleMetaSendsEsc** — neovim receives Meta natively, so
the termcap workaround this enabled no longer exists (setting it shows a
warning and is ignored). Configure your terminal to send proper Meta/Alt
key codes instead.

## 🧪 Tests

```bash
nvim --clean --headless -l tests/smoke.lua
```

## Debugging

**Warning**: there are numerous nvim plugins that will introduce conflicting key mappings.

In addition to installing [which-key](https://github.com/folke/which-key.nvim), you can use the following
nvim commands to help you track down key bindings and conflicts:

```
:verbose imap <C-n>   -- for insert mode
:verbose nmap <C-n>   -- for normal mode
:nmap <localleader>   -- to see leader commands
:WhichKey             -- see above
```

## ⚡️ Thanks and alternatives

- [vimacs](https://github.com/andrep/vimacs) _(the OG version of Vimacs, made for vim)_
- [nvimacs](https://github.com/sei40kr/nvimacs) _(a pure lua port of the basic emacs movements and buffer bindings)_
- [vim-rsi](https://github.com/tpope/vim-rsi) _(readline bindings are a similar subset)_

## 🚀 Usage

Many of the emacs control and meta keys (movement, kill buffers, file operations, marking) will work while
you're running vimacs in neovim. Neovim does not allow all bindings to work in all modes, although this module
supports most of what is possible.

Plus you still get the full power of vim moded editing as well, so vimacs can be used as a module to transition
you from emacs to vim until you have mastered the vim bindings.
