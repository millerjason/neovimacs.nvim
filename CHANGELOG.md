# Changelog

### 1.0

- Complete rewrite in pure Lua; the vimscript sources are gone. Requires neovim 0.10+.
- Kill ring is now a real ring (Lua list, `VM_KillRingMax` entries) instead of
  shifting registers `"1`-`"9`; vim yanks land on it too, and `M-y` (yank-pop)
  replaces the last yank in place instead of using `:undo`
- Incremental search repeat (`C-s`/`C-r` inside the prompt) uses native
  incsearch navigation instead of on-the-fly remapping; on an empty prompt
  they recall the last search
- Word motions (`M-f`/`M-b` and kills) are computed directly, work in
  insert/visual/operator mode, and cross lines like Emacs; the
  'virtualedit' save/restore and visual-mode re-entry workarounds are gone
  (replaced with a global `virtualedit=onemore`)
- Insert-first behavior (`startinsert`) is limited to regular modifiable buffers
- Commands that used to leave insert mode (save, window switching, folding,
  etc.) now use `<Cmd>` mappings and stay in insert mode; the `:redraw`
  workarounds are gone
- Fixes: `C-x =` shows position info; `M-l`/`M-u`/`M-c` operate on the whole
  word; transpose-lines no longer clobbers registers; `:PointToRegister` /
  `:JumpToRegister` work
- Options: added `VM_Hidden`, `VM_NormalMetaXRemap`, `VM_F10Menu` (now
  default off), `VM_KillRingMax`; removed `VM_UnixConsoleMetaSendsEsc`
  (obsolete under neovim)
- Added a headless smoke-test suite (`tests/smoke.lua`)

### 0.97

- Undefine unwanted overlapping key bindings
- Do not set Meta keys by default (improve compatibility)
- Update documentation
- Fix repeated search
- Migrate settings from 0/1 to bool

### 0.96-nvim1.0

- Migrated to Neovim plug module format including config overrides, tested with lazy
- `insertmode.vim` vimscript provided for insert-mode like functionality under neovim
- Minor updates and guards as required for neovim
- Documentation
