# Neovimacs functionality map

This documents everything the plugin provides, where it lives in the Lua
source, and what changed in the port from the original vimscript
(`vimacs.vim`, `insertmode.vim`, `tab-indent.vim`) to pure Lua.

Modes: `i` = Insert, `n` = Normal, `x` = Visual, `o` = Operator-pending,
`c` = Command-line.

## Insert-mode emulation (`lua/neovimacs/insertmode.lua`)

Emulates Vim's removed `'insertmode'` option: Insert mode is "home".

| Key | Modes | Action |
|-----|-------|--------|
| `<Esc>` | i | Leave to Normal mode (as usual) |
| `<Esc>` | n x s | Return to Insert mode (single-Esc toggling, via `vim.on_key`) |
| `<C-c>` | i | Stay in Insert mode (dismisses completion) |
| `<C-c>` | n x s o | Acts like `<Esc>` |
| `<C-\><C-g>` | n x o c i | Go to Insert mode from anywhere |

With `VM_StartInsert`, buffers open in Insert mode — but only regular,
modifiable buffers (help, quickfix, and plugin buffers are left alone; the
old version tried `startinsert` everywhere).

## Mode switching & digit arguments (`keymaps.lua`)

| Key | Modes | Action |
|-----|-------|--------|
| `<M-x>` `<M-:>` | i | Enter command line (`<C-o>:`) |
| `<M-x>` | n | `:` (option `VM_NormalMetaXRemap`) |
| `<M-x>` | x | `:` on the region |
| `<F1>` | i | To Normal mode |
| `<F2>` `<M-`>` | i | One Normal-mode command (`<C-o>`) |
| `<M-1>`…`<M-9>` | i | Digit argument for the next Normal command |
| `<C-z>` | i | To Normal mode (with hint message) |
| `<C-z>` | n | Suspend |
| `<C-a>` `<C-x>` | n | Disabled (they are Emacs prefix keys) |

## Files, buffers, quitting

| Key | Action |
|-----|--------|
| `<C-x><C-c>` | `:confirm qall` |
| `<C-x><C-f>` | Find file (`:hide edit`, or `:edit` if `VM_Hidden=false`) |
| `<C-x><C-s>` | Save (`:update`) |
| `<C-x>s` | Save all (`:wall`) |
| `<C-x>i` | Insert file (`:read`) |
| `<C-x><C-w>` | Write as (`:write`) |
| `<C-x><C-q>` | Toggle read-only |
| `<C-x><C-r>` | Open read-only (`:view`) |
| `<C-x>b` | Switch buffer (BufExplorer if installed, else `:buffer` wildmenu) |
| `<C-x><C-b>` | List buffers |
| `<C-x>k` | Kill buffer (`:bdelete`) |
| `<C-x><C-a>` / `<C-x>a` | Alternate file (only if a.vim is installed) |

## Undo

`<C-_>` and `<C-x><C-u>` (insert) undo; `<C-x><C-u>` / `<C-x><C-l>` in
Visual mode upcase/downcase the region.

## Incremental search & replace (`search.lua`)

| Key | Modes | Action |
|-----|-------|--------|
| `<C-s>` / `<C-r>` | i | Incremental search forward / backward |
| `<C-s>` / `<C-r>` | c (search prompt) | Next / previous match; on an empty prompt, recall the last search |
| `<C-g>` `<Esc>` | c | Abort search, cursor restored to start |
| `<CR>` | c | Accept search, return to Insert mode |
| `<M-s>` | i | Toggle `hlsearch` |
| `<M-%>` / `<C-M-%>` | i | Query replace (literal / regexp), point to end of buffer |
| `<M-n>` / `<M-p>` | i | QuickFix next / previous (not in Emacs) |

Commands: `:QueryReplace`, `:QueryReplaceRegexp`.

## Command-line editing

`<C-b>`/`<C-f>`/`<C-a>`/`<C-e>` char/line movement, `<M-f>`/`<M-b>` word
movement, `<M-p>`/`<M-n>` history, `<C-d>` delete char, `<C-k>` kill to end,
`<M-BS>` kill word back, `<C-y>` yank, `<C-g>` abort.

## Navigation (`motion.lua` + `keymaps.lua`)

Available in Insert, Visual, and Operator-pending mode unless noted.

| Key | Action |
|-----|--------|
| `<C-b>` `<C-f>` `<C-p>` `<C-n>` | Char left/right, line up/down |
| `<M-f>` `<M-b>` (also `<M-Left>`/`<M-Right>`, `<C-Left>`/`<C-Right>`) | Word forward/backward (Emacs word = `'iskeyword'` run; crosses lines) |
| `<C-a>` `<C-e>` | Beginning / end of line |
| `<M-a>` `<M-e>` | Sentence backward / forward |
| `<M-m>` | First non-blank |
| `<M-<>` `<M->>` | Beginning / end of buffer |
| `<C-v>` `<M-v>` | Page down / up |
| `<C-Up>` `<C-Down>` | Paragraph backward / forward |
| `<M-g>` `<C-x>g` | Goto line (also `:GotoLine`) |
| `<C-x>=` | Cursor position info (`g<C-g>`) |
| `<C-x>p` | Previous jump-list entry (not in Emacs) |

## Kill ring (`killring.lua`)

The kill ring is a Lua list (default 30 entries, `VM_KillRingMax`).
Consecutive kills accumulate into one entry. Every Vim yank also lands on
the ring, so `y`-commands integrate with `C-y`/`M-y`.

| Key | Modes | Action |
|-----|-------|--------|
| `<C-d>` | i x o | Delete char (not on the ring, like Emacs `delete-char`) |
| `<M-d>` | i | Kill word |
| `<M-BS>` `<C-BS>` | i | Kill word backward |
| `<C-k>` | i | Kill to end of line; at end of line, kill the newline |
| `<M-0><C-k>` | i | Kill to beginning of line |
| `<C-u>` | i | Delete to beginning of line (not on the ring, as before) |
| `<M-k>` / `<C-x><BS>` | i | Kill sentence forward / backward |
| `<M-z>` | i | Zap: kill up to a typed character |
| `<M-\>` | i | Delete horizontal space around point |
| `<C-y>` | i | Yank (paste the last kill) |
| `<M-y>` | i | Yank-pop: replace the last yank with the next older kill |
| `<C-w>` | x | Kill region, return to Insert mode |
| `<M-w>` | x | Copy region to the ring, return to Insert mode |

## Marking / region

| Key | Modes | Action |
|-----|-------|--------|
| `<C-Space>` (`<C-@>`) | i | Set mark, start Visual selection |
| `<C-g>`, `<C-x><C-Space>` | x | Cancel region |
| `<M-Space>` | i | Mark word |
| `<M-h>` | i | Mark paragraph |
| `<C-<>` / `<C->>` | i | Mark to beginning / end of buffer |
| `<C-x>h` | i | Mark whole buffer |
| `<C-x><C-x>` | x | Exchange point and mark |
| `<S-Movement>` | i | Shift selection (needs `keymodel` containing `startsel`) |
| `<C-Insert>` / `<S-Del>` | x | Copy / cut to system clipboard |
| `<C-x>r` | x | Switch to rectangle (blockwise) selection |

## Windows

`<C-x>2`/`<C-x>3` split, `<C-x>0`/`<C-x>1` close/only, `<C-x>o`/`<C-x>O`
(also `<C-Tab>`/`<C-S-Tab>`) cycle, `<C-x>+` equalize, `<C-M-v>` scroll
other window (`:ScrollOtherWindow`), `<C-x>4f` find file in other window
(`:FindFileOtherWindow`). All stay in Insert mode via `<Cmd>`.

## Editing helpers (`edit.lua`)

| Key | Action |
|-----|--------|
| `<C-t>` / `<M-t>` / `<C-x><C-t>` | Transpose chars / words / lines |
| `<M-l>` `<M-u>` `<M-c>` | Downcase / upcase / capitalize word (moves past it) |
| `<M-^>` | Join with previous line |
| `<C-M-\>` / `<C-x><Tab>` | Indent region (Visual) |
| `<C-q>` | Quoted insert |
| `<M-r>` | Insert expression register |
| `<M-/>` / `<C-]>` | Completion (`<C-p>` / `<C-x>` prefix) |
| `<C-x>/`, `<C-x>r<Space>` | Point to register (mark); `<C-x>rj` jump to it |
| `<M-.>` / `<M-*>` / `<C-x>4.` | Jump to tag / back / tag in other window |
| `<M-!>` | Shell command (filter in Visual mode) |
| `<C-l>` | Recenter |
| `<C-x><C-x>…` (insert) | Folding operations (open/close/toggle, recursive with `<C-r>`) |

Commands: `:FillParagraph`, `:IndentParagraph`, `:PointToRegister`,
`:JumpToRegister`.

## Tab indent (`tabindent.lua`)

With `TabIndentStyle` set, `<Tab>` in Insert mode reindents instead of
inserting a tab: always (`"emacs"`), only inside leading whitespace
(`"whitespace"`), or also at column 1 (`"startofline"`).

---

# Changes from the vimscript implementation

Mechanisms that existed to work around Vim limitations and are unnecessary
(or counterproductive) in Neovim 0.12+:

- **`<C-o>:call ...<CR>` chains → `<Cmd>` / Lua callbacks.** Commands like
  save, window switching, and folding no longer bounce through Normal mode,
  so the `:redraw` calls and `startinsert` recovery dances are gone.
- **Kill ring registers → Lua list.** The old code hand-shifted registers
  `"1`–`"9` around every kill and scribbled on `@w`/`@x`/`@y`/`@z`. Kills now
  edit the buffer through the API and only set the unnamed register. The
  numbered registers no longer emulate the ring — use `M-y`.
- **Yank-pop via `:undo` → in-place replacement.** `M-y` rewrites the just
  yanked region instead of undoing the previous paste.
- **Kill accumulation state machine → changedtick + cursor check.** The
  `CursorMovedI`/`InsertEnter`/`InsertLeave` autocmds tracking `"k"/"ke"/
  "kem"/"kel"/"keml"` states existed only because every kill left Insert
  mode; kills no longer do.
- **Search remap trickery → native incsearch.** Repeat-search inside the
  prompt used on-the-fly `cnoremap`/`cunmap` of five keys plus
  `'lazyredraw'`/`'wrapscan'`/`'incsearch'` toggling and a hand-rolled
  mark/restore (`Mark()` with `normal! H`/`zt`). Neovim's `c_CTRL-G`/
  `c_CTRL-T` provide match navigation, and aborting the command line
  already restores the cursor and view.
- **`'virtualedit'` save/restore around word motions → `'onemore'` +
  direct cursor positioning.** Word motions compute the target with
  `vim.regex` and `nvim_win_set_cursor`; the Visual-mode exit/re-enter
  gymnastics (`VForwardWord1/2`, `AdjustVisualModeExitPosition`) are gone
  because moving the cursor inside a mapping callback simply extends the
  selection. `virtualedit=onemore` is set so exclusive selections can
  include the last character of a line.
- **`:set <M-x>=x` termcap hacks removed.** Neovim receives Meta natively;
  `VM_UnixConsoleMetaSendsEsc` is obsolete (a warning is shown if set).
  Likewise `VM_SingleEscToNormal`: single-Esc is simply the behavior.
- **Timeout juggling simplified.** Just `timeout=false` so prefix keys
  (`C-x ...`) wait indefinitely, like Emacs; `ttimeout`/`ttimeoutlen` keep
  their Neovim defaults (key codes are handled by the TUI).
- **Options that are Neovim defaults or obsolete are no longer set:**
  `backspace`, `incsearch`, `winaltkeys`, `esckeys`, `cpoptions`
  save/restore, and the `cmdheight=2` bump.
- **`&insertmode` checks removed.** The option doesn't exist in Neovim
  (it evaluates as a dead `0`), so all branches guarded by it were dead
  code.
- **Small fixes along the way:** `C-x =` now shows position info
  (`g<C-g>`) instead of inserting a literal `<C-g>`; `M-l`/`M-u`/`M-c`
  operate on the whole word rather than one character; `S-Del` in Visual
  mode consistently cuts to the clipboard (the original mapped it twice,
  to `"+d` and `"_d`); `:PointToRegister`/`:JumpToRegister` commands call
  functions that exist; transpose-lines no longer clobbers registers;
  `F10` menu loading is now opt-in (`VM_F10Menu`), since `menu.vim`
  installs global buffer-menu autocommands.
