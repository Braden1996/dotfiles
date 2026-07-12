local PREVIEW_DEBOUNCE_MS = 60
local PREVIEW_MAX_BYTES = 2 * 1024 * 1024

local preview_session
local sync_preview

local function session_valid(session)
  session = session or preview_session
  return session ~= nil and session.win ~= nil and session.win.valid and session.win:valid()
end

local function scroll_window(winid, delta)
  if not winid or not vim.api.nvim_win_is_valid(winid) then return end

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

local function mouse_scroll_step() return tonumber(vim.o.mousescroll:match "ver:(%d+)") or 1 end

local function stop_preview_timer(session)
  if not session or not session.timer then return end

  session.timer:stop()
  session.timer:close()
  session.timer = nil
end

local function close_preview_session()
  local session = preview_session
  if session == nil then return end

  preview_session = nil
  stop_preview_timer(session)

  if session.augroup then pcall(vim.api.nvim_del_augroup_by_id, session.augroup) end

  if session_valid(session) then session.win:close() end

  if session.bufnr and vim.api.nvim_buf_is_valid(session.bufnr) then
    pcall(vim.api.nvim_buf_delete, session.bufnr, { force = true })
  end
end

local function preview_title(path)
  local relative = vim.fn.fnamemodify(path, ":.")
  if relative == "" or relative == "." then relative = vim.fn.fnamemodify(path, ":t") end

  return " " .. relative .. " "
end

local function editor_area()
  return {
    row = 0,
    col = 0,
    width = math.max(1, vim.o.columns),
    height = math.max(1, vim.o.lines - vim.o.cmdheight - 1),
  }
end

local function preview_area(tree_winid)
  local editor = editor_area()
  if not tree_winid or not vim.api.nvim_win_is_valid(tree_winid) then return editor end

  local pos = vim.api.nvim_win_get_position(tree_winid)
  local tree_col = pos[2]
  local tree_width = vim.api.nvim_win_get_width(tree_winid)
  local gap = editor.width >= 80 and 2 or 1
  local left = {
    row = editor.row,
    col = editor.col,
    width = math.max(0, tree_col - gap),
    height = editor.height,
  }
  local right_col = math.min(editor.width, tree_col + tree_width + gap)
  local right = {
    row = editor.row,
    col = right_col,
    width = math.max(0, editor.width - right_col),
    height = editor.height,
  }

  local tree_center = tree_col + math.floor(tree_width / 2)
  local preferred = tree_center <= math.floor(editor.width / 2) and right or left
  local alternate = preferred == right and left or right

  if preferred.width < 28 and alternate.width > preferred.width then preferred = alternate end

  return preferred.width >= 12 and preferred or editor
end

local function preview_layout(tree_winid)
  local area = preview_area(tree_winid)
  local horizontal_margin = area.width >= 40 and 2 or 1
  local vertical_margin = area.height >= 16 and 2 or 1
  local max_width = math.max(1, area.width - horizontal_margin * 2)
  local max_height = math.max(1, area.height - vertical_margin * 2)
  local width = math.min(max_width, math.min(112, math.max(math.min(72, max_width), math.floor(area.width * 0.82))))
  local height = math.min(max_height, math.min(30, math.max(math.min(18, max_height), math.floor(area.height * 0.72))))

  return {
    row = area.row + math.max(0, math.floor((area.height - height) / 2)),
    col = area.col + math.max(0, math.floor((area.width - width) / 2)),
    width = width,
    height = height,
    backdrop_row = area.row,
    backdrop_col = area.col,
    backdrop_width = area.width,
    backdrop_height = area.height,
  }
end

local function selected_file_path(state)
  if not state.winid or not vim.api.nvim_win_is_valid(state.winid) then return nil end

  local node = state.tree and state.tree:get_node() or nil
  if not node then return nil end

  local path = node.path or node:get_id()
  if type(path) ~= "string" or path == "" then return nil end

  local stats = vim.uv.fs_stat(path)
  if not stats or stats.type ~= "file" then return nil end

  return path
end

local function create_preview_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "neo-tree-preview://" .. bufnr)
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].swapfile = false
  return bufnr
end

local function preview_message(message)
  return {
    "",
    message,
    "",
  }, "text"
end

local function read_preview(path)
  local stats = vim.uv.fs_stat(path)
  if not stats or stats.type ~= "file" then return preview_message "Preview unavailable: not a regular file" end

  if stats.size > PREVIEW_MAX_BYTES then
    return preview_message(
      ("Preview unavailable: file exceeds the %d MiB limit"):format(PREVIEW_MAX_BYTES / 1024 / 1024)
    )
  end

  local fd, open_err = vim.uv.fs_open(path, "r", 438)
  if not fd then return preview_message("Preview unavailable: " .. (open_err or "cannot open file")) end

  local contents, read_err = vim.uv.fs_read(fd, stats.size, 0)
  vim.uv.fs_close(fd)
  if not contents then return preview_message("Preview unavailable: " .. (read_err or "cannot read file")) end
  if contents:find("\0", 1, true) then return preview_message "Preview unavailable: binary file" end

  local lines = vim.split(contents, "\n", { plain = true })
  if contents:sub(-1) == "\n" then table.remove(lines) end
  if #lines == 0 then lines = { "" } end
  for index, line in ipairs(lines) do
    lines[index] = line:gsub("\r$", "")
  end

  return lines, vim.filetype.match { filename = path } or "text"
end

local function load_preview_buffer(session, path)
  if not session.bufnr or not vim.api.nvim_buf_is_valid(session.bufnr) then session.bufnr = create_preview_buffer() end

  local lines, filetype = read_preview(path)
  vim.bo[session.bufnr].modifiable = true
  vim.bo[session.bufnr].readonly = false
  vim.api.nvim_buf_set_lines(session.bufnr, 0, -1, false, lines)
  vim.bo[session.bufnr].filetype = filetype
  vim.bo[session.bufnr].modified = false
  vim.bo[session.bufnr].modifiable = false
  vim.bo[session.bufnr].readonly = true
end

local function create_preview_window(session, path)
  local Snacks = require "snacks"
  local layout = function() return preview_layout(session.tree_winid) end

  local win
  win = Snacks.win {
    buf = session.bufnr,
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
      if session.win == win then session.win = nil end
    end,
  }
  session.win = win
end

sync_preview = function(session)
  if preview_session ~= session then return end
  if not session.tree_winid or not vim.api.nvim_win_is_valid(session.tree_winid) then
    close_preview_session()
    return
  end

  local path = selected_file_path(session.state)
  if path == nil then
    if session_valid(session) then
      session.win:close()
      session.win = nil
    end
    session.last_path = nil
    return
  end

  if session.last_path ~= path then
    load_preview_buffer(session, path)
    session.last_path = path
  end

  if session.win == nil or not session.win.valid or not session.win:valid() then
    create_preview_window(session, path)
    return
  end

  session.win:update()
  session.win:set_title(preview_title(path))
end

local function schedule_sync(session, delay_ms)
  if preview_session ~= session then return end

  if session.timer == nil then session.timer = vim.uv.new_timer() end
  session.timer:stop()
  session.timer:start(
    delay_ms or PREVIEW_DEBOUNCE_MS,
    0,
    vim.schedule_wrap(function()
      if preview_session == session then sync_preview(session) end
    end)
  )
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
    bufnr = create_preview_buffer(),
    win = nil,
    last_path = nil,
    timer = nil,
  }

  preview_session = session

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = session.augroup,
    buffer = tree_bufnr,
    callback = function() schedule_sync(session) end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    group = session.augroup,
    buffer = tree_bufnr,
    callback = function()
      vim.schedule(function()
        if preview_session == session then close_preview_session() end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = session.augroup,
    pattern = tostring(session.tree_winid),
    callback = function()
      if preview_session == session then close_preview_session() end
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = session.augroup,
    callback = function() schedule_sync(session, 20) end,
  })

  sync_preview(session)
end

local function scroll_preview_or_tree(state, delta)
  if
    preview_session ~= nil
    and preview_session.tree_bufnr == vim.api.nvim_win_get_buf(state.winid)
    and session_valid(preview_session)
  then
    scroll_window(preview_session.win.win, delta)
    return
  end

  scroll_window(state.winid, delta)
end

local function scroll_tree_preview_down(state) scroll_preview_or_tree(state, 10) end

local function scroll_tree_preview_up(state) scroll_preview_or_tree(state, -10) end

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
