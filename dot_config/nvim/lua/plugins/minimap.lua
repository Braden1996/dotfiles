return {
  {
    "gorbit99/codewindow.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "lewis6991/gitsigns.nvim",
    },
    keys = {
      {
        "<Leader>um",
        function() require("codewindow").toggle_minimap() end,
        desc = "Toggle minimap",
      },
      {
        "<Leader>uM",
        function() require("codewindow").toggle_focus() end,
        desc = "Focus minimap",
      },
    },
    opts = {
      exclude_filetypes = {
        "alpha",
        "aerial",
        "checkhealth",
        "help",
        "lazy",
        "mason",
        "neo-tree",
        "notify",
        "qf",
        "snacks_dashboard",
        "terminal",
        "toggleterm",
        "trouble",
      },
      minimap_width = 18,
      screen_bounds = "background",
      use_git = true,
      use_lsp = true,
      use_treesitter = true,
      window_border = "single",
    },
    config = function(_, opts)
      local codewindow = require "codewindow"

      local function apply_highlights()
        vim.api.nvim_set_hl(0, "CodewindowBorder", { link = "FloatBorder" })
        vim.api.nvim_set_hl(0, "CodewindowBackground", { link = "NormalFloat" })
        vim.api.nvim_set_hl(0, "CodewindowBoundsBackground", { link = "Visual" })
        vim.api.nvim_set_hl(0, "CodewindowWarn", { link = "DiagnosticWarn" })
        vim.api.nvim_set_hl(0, "CodewindowError", { link = "DiagnosticError" })
        vim.api.nvim_set_hl(0, "CodewindowAddition", { link = "DiffAdd" })
        vim.api.nvim_set_hl(0, "CodewindowDeletion", { link = "DiffDelete" })
        vim.api.nvim_set_hl(0, "CodewindowUnderline", { link = "CursorLine" })
      end

      codewindow.setup(opts)
      apply_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("codewindow_highlights", { clear = true }),
        callback = apply_highlights,
      })
    end,
  },
}
