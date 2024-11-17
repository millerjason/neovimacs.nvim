# 💥 Neovimacs

**Neovimacs** is vimacs for the neovim age.

This project ports the original vimacs scripts (emacs key emulation for vim) to neovim,
along with some simplifications to the setup.

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
}
```
3. Enjoy modeless editing throughout neovim

## ⚙️  Configuration

To install the plugin with custom options (lazy example provided):

```lua
{
   "millerjason/neovimacs.nvim",
   config = function()
        require("neovimacs").setup({
            VM_Enabled = 1,
            VM_StartInsert = 0,
        })
   end,
}
```

## ✨ Options

- **VM_Enabled** (default 1): enabled vimacs (if not set, no modules will be loaded)
- **VM_StartInsert** (default 1): if set start in emacs insert mode instead of vim normal mode
  **VM_UnixConsoleMetaSendsEsc** (default 0): also set Meta key (required in certain terminals, requires nvim >= 0.10)
- **TabIndentStyle**: (default "emacs"): options for "emacs", "whitespace", and "startofline" tab indent behavior

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
your running viamcs in neovim.  Neovim does not allow all bindings to work in all modes, although this module
supports most of what is possible.

Plus you still get the full power of vim moded editing as well, so vimacs can be used as a module to transition
you from emacs to vim until you have mastered the vim bindings.
