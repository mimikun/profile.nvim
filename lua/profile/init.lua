local api, fn = vim.api, vim.fn
local utils = require("profile.utils")
local ctx = {}
local db = {}

db.__index = db
db.__newindex = function(t, k, v)
  rawset(t, k, v)
end

local function clean_avatar(obj)
  if obj then
    obj:clear()
    obj = nil
  end
end

local function show_avatar(obj)
  if obj then
    obj:render()
  end
end

local function clean_ctx()
  for k, _ in pairs(ctx) do
    ctx[k] = nil
  end
end

local function cache_dir()
  local dir = utils.path_join(vim.fn.stdpath("cache"), "profile")
  if fn.isdirectory(dir) == 0 then
    fn.mkdir(dir, "p")
  end
  return dir
end

local function cache_path()
  local dir = cache_dir()
  return utils.path_join(dir, "cache")
end

local function conf_cache_path()
  return utils.path_join(cache_dir(), "conf")
end

local function plugin_path()
  local d = debug.getinfo(1).source:sub(2)
  return vim.fn.fnamemodify(d, ":h")
end

local function default_options()
  return {
    avatar_path = plugin_path() .. "/../../resources/profile.png",
    avatar_opts = {
      avatar_width = 20,
      avatar_height = 20,
      avatar_x = (vim.o.columns - 20) / 2,
      avatar_y = 8,
    },
    config = {
      avatar = true,
      contributions = true,
      user = "Kurama622",
    },
    obj = {
      avatar = nil,
    },
    hide = {
      statusline = true,
      tabline = true,
    },
  }
end

local function buf_local()
  local opts = {
    ["bufhidden"] = "wipe",
    ["colorcolumn"] = "",
    ["foldcolumn"] = "0",
    ["matchpairs"] = "",
    ["buflisted"] = false,
    ["cursorcolumn"] = false,
    ["cursorline"] = false,
    ["list"] = false,
    ["number"] = false,
    ["relativenumber"] = false,
    ["spell"] = false,
    ["swapfile"] = false,
    ["readonly"] = false,
    ["filetype"] = "profile",
    ["wrap"] = false,
    ["signcolumn"] = "no",
  }
  for opt, val in pairs(opts) do
    vim.opt_local[opt] = val
  end
  if fn.has("nvim-0.9") == 1 then
    vim.opt_local.stc = ""
  end
end

function db:new_file()
  vim.cmd("enew")
end

function db:save_user_options()
  self.user_cursor_line = vim.opt.cursorline:get()
  self.user_laststatus_value = vim.opt.laststatus:get()
  self.user_tabline_value = vim.opt.showtabline:get()
  self.user_winbar_value = vim.opt.winbar:get()
end

function db:set_ui_options(opts)
  if opts.hide.statusline then
    vim.opt.laststatus = 0
  end
  if opts.hide.tabline then
    vim.opt.showtabline = 0
  end
  if opts.hide.winbar then
    vim.opt.winbar = ""
  end

  if opts.obj.avatar then
    show_avatar(opts.obj.avatar)
  end
end

function db:restore_user_options(opts)
  if self.user_cursor_line then
    vim.opt.cursorline = self.user_cursor_line
  end

  if opts.hide.statusline and self.user_laststatus_value then
    vim.opt.laststatus = tonumber(self.user_laststatus_value)
  end

  if opts.hide.tabline and self.user_tabline_value then
    vim.opt.showtabline = tonumber(self.user_tabline_value)
  end

  if opts.hide.winbar and self.user_winbar_value then
    vim.opt.winbar = self.user_winbar_value
  end
end

function db:cache_opts()
  if not self.opts then
    return
  end
  local uv = vim.loop
  local path = conf_cache_path()
  if self.opts.config.shortcut then
    for _, item in pairs(self.opts.config.shortcut) do
      if type(item.action) == "function" then
        ---@diagnostic disable-next-line: param-type-mismatch
        local dump = assert(string.dump(item.action))
        item.action = dump
      end
    end
  end

  if self.opts.config.project and type(self.opts.config.project.action) == "function" then
    ---@diagnostic disable-next-line: param-type-mismatch
    local dump = assert(string.dump(self.opts.config.project.action))
    self.opts.config.project.action = dump
  end

  if self.opts.config.center then
    for _, item in pairs(self.opts.config.center) do
      if type(item.action) == "function" then
        ---@diagnostic disable-next-line: param-type-mismatch
        local dump = assert(string.dump(item.action))
        item.action = dump
      end
    end
  end

  if self.opts.config.footer and type(self.opts.config.footer) == "function" then
    ---@diagnostic disable-next-line: param-type-mismatch
    local dump = assert(string.dump(self.opts.config.footer))
    self.opts.config.footer = dump
  end

  local dump = vim.json.encode(self.opts)
  uv.fs_open(path, "w+", tonumber("664", 8), function(err, fd)
    assert(not err, err)
    ---@diagnostic disable-next-line: redefined-local
    uv.fs_write(fd, dump, 0, function(err, _)
      assert(not err, err)
      uv.fs_close(fd)
    end)
  end)
end

function db:get_opts(callback)
  utils.async_read(
    conf_cache_path(),
    vim.schedule_wrap(function(data)
      if not data or #data == 0 then
        return
      end
      local obj = vim.json.decode(data)
      if obj then
        callback(obj)
      end
    end)
  )
end

function db:render(opts)
  local config = vim.tbl_extend("force", opts.config, {
    avatar = function()
      return {
        type = "avatar",
        content = function()
          local img = require("image")
          opts.obj.avatar = img.from_file(opts.avatar_path, {
            id = "avatar",
            inline = true,
            x = opts.avatar_opts.avatar_x,
            y = opts.avatar_opts.avatar_y,
            width = opts.avatar_opts.avatar_width,
            height = opts.avatar_opts.avatar_height,
          })
        end,
      }
    end,
    path = cache_path(),
    bufnr = self.bufnr,
    winid = self.winid,
  })

  require("profile.avatar")(config)

  self:set_ui_options(opts)

  api.nvim_create_autocmd("VimResized", {
    buffer = self.bufnr,
    callback = function()
      require("profile.avatar")(config)
      vim.bo[self.bufnr].modifiable = false
    end,
  })

  api.nvim_create_autocmd("BufLeave", {
    callback = function()
      clean_avatar(opts.obj.avatar)
    end,
  })
  api.nvim_create_autocmd("WinEnter", {
    callback = function()
      if api.nvim_win_get_number(0) > 1 then
        clean_avatar(opts.obj.avatar)
      end
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    callback = function(opt)
      if vim.bo.filetype == "profile" then
        self:set_ui_options(opts)
        return
      end

      local bufs = api.nvim_list_bufs()

      bufs = vim.tbl_filter(function(k)
        return vim.bo[k].filetype == "profile"
      end, bufs)

      -- restore the user's UI settings is no profile buffers are visible
      local wins = api.nvim_tabpage_list_wins(0)
      wins = vim.tbl_filter(function(k)
        return vim.tbl_contains(bufs, api.nvim_win_get_buf(k))
      end, wins)

      if #wins == 0 then
        self:restore_user_options(opts)
        clean_avatar(opts.obj.avatar)
      end

      -- clean up if there are no profile buffers at all
      if #bufs == 0 then
        -- self:cache_opts()
        clean_avatar(opts.obj.avatar)
        -- clean_ctx()
        pcall(api.nvim_del_autocmd, opt.id)
      end
    end,
    desc = "[Profile] clean profile data reduce memory",
  })
end

-- create profile instance
function db:instance()
  local mode = api.nvim_get_mode().mode
  if mode == "i" or not vim.bo.modifiable then
    return
  end

  if not vim.o.hidden and vim.bo.modified then
    --save before open
    vim.cmd.write()
    return
  end

  if not utils.buf_is_empty(0) then
    self.bufnr = api.nvim_create_buf(false, true)
  else
    self.bufnr = api.nvim_get_current_buf()
  end

  self.winid = api.nvim_get_current_win()
  api.nvim_win_set_buf(self.winid, self.bufnr)

  self:save_user_options()

  buf_local()
  if self.opts then
    self:render(self.opts)
  else
    self:get_opts(function(obj)
      self:render(obj)
    end)
  end
end

function db.setup(opts)
  opts = opts or {}
  ctx.opts = vim.tbl_deep_extend("force", default_options(), opts)
end

return setmetatable(ctx, db)
