---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    init = function()
      local group = vim.api.nvim_create_augroup("BradenProjectConfig", { clear = true })
      local loaded_paths = {}

      local function normalize(path) return path and vim.fs.normalize(path) or nil end

      local function git_root(start)
        local marker = vim.fs.find(".git", {
          path = start or vim.fn.getcwd(),
          upward = true,
          limit = 1,
        })[1]

        return marker and vim.fs.dirname(marker) or nil
      end

      local function config_path(root)
        if not root then return nil end

        local path = root .. "/.nvim.lua"
        return vim.uv.fs_stat(path) and path or nil
      end

      local function sourced(path)
        if loaded_paths[path] then return true end

        local scriptnames = vim.api.nvim_exec2("scriptnames", { output = true }).output
        if scriptnames:find(path, 1, true) then
          loaded_paths[path] = true
          return true
        end

        return false
      end

      local function source_trusted(path)
        local source = vim.secure.read(path)
        if type(source) ~= "string" then return false end

        local chunk, err = load(source, "@" .. path)
        if not chunk then
          vim.notify(err, vim.log.levels.ERROR, { title = "Project config" })
          return false
        end

        local ok, exec_err = pcall(chunk)
        if not ok then
          vim.notify(exec_err, vim.log.levels.ERROR, { title = "Project config" })
          return false
        end

        loaded_paths[path] = true
        return true
      end

      local function load_git_root_config(opts)
        opts = opts or {}

        local cwd = normalize(vim.fn.getcwd())
        local root = normalize(git_root(cwd))
        local path = normalize(config_path(root))

        if not root or not path then return false end
        if opts.skip_root and cwd == root then return false end
        if not opts.force and sourced(path) then return true end

        return source_trusted(path)
      end

      vim.api.nvim_create_user_command("TrustG", function()
        local cwd = normalize(vim.fn.getcwd())
        local root = normalize(git_root(cwd))
        local path = normalize(config_path(root))

        if not root then
          vim.notify("No git root found from current directory", vim.log.levels.WARN, { title = "TrustG" })
          return
        end

        if not path then
          vim.notify("No .nvim.lua found at git root: " .. root, vim.log.levels.WARN, { title = "TrustG" })
          return
        end

        loaded_paths[path] = nil
        if source_trusted(path) then
          vim.notify("Trusted and loaded " .. path, vim.log.levels.INFO, { title = "TrustG" })
        end
      end, {
        bang = true,
        desc = "Trust and load .nvim.lua from the current git root",
      })

      vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
        group = group,
        callback = function() load_git_root_config { skip_root = true } end,
      })

      vim.schedule(function() load_git_root_config { skip_root = true } end)
    end,
  },
}
