local preview_session

local function session_valid()
  return preview_session ~= nil
    and preview_session.win ~= nil
    and preview_session.win.valid
    and preview_session.win:valid()
end

local function scroll_window(winid, delta)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  vim.api.nvim_win_call(winid, function()
    local view = vim.fn.winsaveview()
    local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(winid))
    local height = math.max(1, vim.api.nvim_win_get_height(winid))
    local max_topline = math.max(1, line_count - height + 1)
    local next_topline = math.max(1, math.min(max_topline, view.topline + delta))

    view.topline = next_topline
    view.lnum = math.max(next_topline, math.min(line_count, view.lnum + delta))
    vim.fn.winrestview(view)
  end)
end

local function mouse_scroll_step()
  return tonumber(vim.o.mousescroll:match("ver:(%d+)")) or 1
end

local function close_preview_session()
  if preview_session == nil then
    return
  end

  if preview_session.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, preview_session.augroup)
  end

  if session_valid() then
    preview_session.win:close()
  end

  preview_session = nil
end

local function preview_title(path)
  local relative = vim.fn.fnamemodify(path, ":.")
  if relative == "" or relative == "." then
    relative = vim.fn.fnamemodify(path, ":t")
  end

  return " " .. relative .. " "
end

local function editor_area()
  return {
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = math.max(1, vim.o.lines - vim.o.cmdheight - 1),
  }
end

local function preview_area(tree_winid)
  local editor = editor_area()
  if not tree_winid or not vim.api.nvim_win_is_valid(tree_winid) then
    return editor
  end

  local pos = vim.api.nvim_win_get_position(tree_winid)
  local tree_col = pos[2]
  local tree_width = vim.api.nvim_win_get_width(tree_winid)
  local gap = 2

  if tree_col <= math.floor(editor.width / 2) then
    local col = math.min(editor.width - 1, tree_col + tree_width + gap)
    return {
      row = editor.row,
      col = col,
      width = math.max(24, editor.width - col - 1),
      height = editor.height,
    }
  end

  return {
    row = editor.row,
    col = 1,
    width = math.max(24, tree_col - gap - 1),
    height = editor.height,
  }
end

local function preview_layout(tree_winid)
  local area = preview_area(tree_winid)
  local width = math.min(112, math.max(72, math.floor(area.width * 0.78)))
  width = math.max(24, math.min(width, area.width - 4))

  local height = math.min(30, math.max(18, math.floor(area.height * 0.72)))
  height = math.max(8, math.min(height, area.height - 4))

  return {
    row = area.row + math.max(1, math.floor((area.height - height) / 2) - 1),
    col = area.col + math.max(2, math.floor((area.width - width) / 2)),
    width = width,
    height = height,
    backdrop_row = area.row,
    backdrop_col = area.col,
    backdrop_width = area.width,
    backdrop_height = area.height,
  }
end

local function selected_file_path(state)
  local node = state.tree and state.tree:get_node() or nil
  if not node then
    return nil
  end

  local path = node.path or node:get_id()
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local stats = vim.uv.fs_stat(path)
  if not stats or stats.type ~= "file" then
    return nil
  end

  return path
end

local function ensure_file_buffer(path)
  local bufnr = vim.fn.bufadd(path)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end
  return bufnr
end

local function create_preview_window(session, path)
  local Snacks = require "snacks"
  local layout = function()
    return preview_layout(session.tree_winid)
  end

  local bufnr = ensure_file_buffer(path)
  local filetype = vim.filetype.match({ filename = path }) or vim.bo[bufnr].filetype or "text"

  session.win = Snacks.win({
    buf = bufnr,
    enter = false,
    focusable = false,
    title = preview_title(path),
    border = "rounded",
    row = function() return layout().row end,
    col = function() return layout().col end,
    width = function() return layout().width end,
    height = function() return layout().height end,
    backdrop = {
      blend = 60,
      win = {
        row = function() return layout().backdrop_row end,
        col = function() return layout().backdrop_col end,
        width = function() return layout().backdrop_width end,
        height = function() return layout().backdrop_height end,
      },
    },
    ft = filetype,
    wo = {
      number = true,
      relativenumber = false,
      signcolumn = "no",
      foldcolumn = "0",
      wrap = false,
      spell = false,
      cursorline = false,
    },
    on_close = function()
      session.win = nil
    end,
  })
end

local function sync_preview(session)
  if preview_session ~= session then
    return
  end

  local path = selected_file_path(session.state)
  if path == nil then
    if session_valid() then
      session.win:close()
      session.win = nil
    end
    session.last_path = nil
    return
  end

  if session.win == nil or not session.win.valid or not session.win:valid() then
    create_preview_window(session, path)
    session.last_path = path
    return
  end

  session.win:update()

  if session.last_path == path then
    return
  end

  session.last_path = path
  session.win:set_buf(ensure_file_buffer(path))
  session.win:set_title(preview_title(path))
end

local function toggle_tree_preview(state)
  local tree_bufnr = vim.api.nvim_win_get_buf(state.winid)

  if preview_session ~= nil and preview_session.tree_bufnr == tree_bufnr then
    close_preview_session()
    return
  end

  close_preview_session()

  local session = {
    state = state,
    tree_bufnr = tree_bufnr,
    tree_winid = state.winid,
    augroup = vim.api.nvim_create_augroup("BradenNeoTreePreview_" .. tree_bufnr, { clear = true }),
    win = nil,
    last_path = nil,
  }

  preview_session = session

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = session.augroup,
    buffer = tree_bufnr,
    callback = function()
      vim.schedule(function() sync_preview(session) end)
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = session.augroup,
    buffer = tree_bufnr,
    callback = function()
      vim.schedule(function()
        if preview_session == session then
          close_preview_session()
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = session.augroup,
    callback = function()
      vim.schedule(function()
        if preview_session == session and session_valid() then
          session.win:update()
        end
      end)
    end,
  })

  sync_preview(session)
end

local function scroll_preview_or_tree(state, delta)
  if preview_session ~= nil and preview_session.tree_bufnr == vim.api.nvim_win_get_buf(state.winid) and session_valid() then
    scroll_window(preview_session.win.win, delta)
    return
  end

  scroll_window(state.winid, delta)
end

local function scroll_tree_preview_down(state)
  scroll_preview_or_tree(state, 10)
end

local function scroll_tree_preview_up(state)
  scroll_preview_or_tree(state, -10)
end

local function scroll_tree_preview_wheel_down(state)
  scroll_preview_or_tree(state, mouse_scroll_step())
  return ""
end

local function scroll_tree_preview_wheel_up(state)
  scroll_preview_or_tree(state, -mouse_scroll_step())
  return ""
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    opts.commands = opts.commands or {}
    opts.commands.toggle_tree_preview = toggle_tree_preview
    opts.commands.scroll_tree_preview_down = scroll_tree_preview_down
    opts.commands.scroll_tree_preview_up = scroll_tree_preview_up
    opts.commands.scroll_tree_preview_wheel_down = scroll_tree_preview_wheel_down
    opts.commands.scroll_tree_preview_wheel_up = scroll_tree_preview_wheel_up

    opts.window = opts.window or {}
    opts.window.mappings = opts.window.mappings or {}
    opts.window.mappings["P"] = "toggle_tree_preview"
    opts.window.mappings["<C-f>"] = "scroll_tree_preview_down"
    opts.window.mappings["<C-b>"] = "scroll_tree_preview_up"
    opts.window.mappings["<ScrollWheelDown>"] = {
      command = "scroll_tree_preview_wheel_down",
      desc = "scroll preview down",
      expr = true,
      silent = true,
    }
    opts.window.mappings["<ScrollWheelUp>"] = {
      command = "scroll_tree_preview_wheel_up",
      desc = "scroll preview up",
      expr = true,
      silent = true,
    }
    opts.filesystem = opts.filesystem or {}
    opts.filesystem.use_libuv_file_watcher = false

    return opts
  end,
}
