# Neovim

This is an AstroNvim v5 configuration managed by chezmoi. `lazy-lock.json`
pins the resolved plugin graph; update it intentionally with `:Lazy update`.

The active customizations are deliberately small:

- `lua/plugins/neo-tree.lua` adds a debounced, scrollable file preview.
- `lua/plugins/project_config.lua` loads trusted `.nvim.lua` files from Git roots.
- `lua/lazy_setup.lua` contains the AstroNvim and lazy.nvim baseline.

After applying the dotfiles, start Neovim once and let lazy.nvim install the
locked plugins. Use `:checkhealth` to diagnose local runtime dependencies.
