local Profile = {}

package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"
local d = debug.getinfo(1).source:sub(2)
local srcpath = vim.fn.fnamemodify(d, ":h")
local basepath = vim.fn.fnamemodify(srcpath, ":h")

local win_max_width = vim.o.columns
local avatar_width = 20
local avatar_height = avatar_width
local avatar_x = (win_max_width - avatar_width) / 2
local avatar_y = 8

local function InsertTextLine(bufnr, linenr, text, hl)
  hl = hl or "Normal"
  vim.api.nvim_buf_set_lines(bufnr, linenr, linenr, false, { text })
  vim.api.nvim_buf_add_highlight(bufnr, -1, hl, linenr, 0, -1)
end

function Profile.avatar(path)
  return {
    type = "avatar",
    content = function()
      require("image")
        .from_file(path, {
          id = "avatar",
          inline = true,
          x = avatar_x,
          y = avatar_y,
          width = avatar_width,
          height = avatar_height,
        })
        :render()

      --[[
      require("image").from_url("https://avatars.githubusercontent.com/u/13927622?v=4", {
        id = "avatar",
        inline = true,
        x = avatar_x,
        y = avatar_y,
        width = avatar_width,
        height = avatar_height,
      }, function(img)
        if img ~= nil then
          img:render()
        end
      end)
      ]]
    end,
  }
end

function Profile.git_contributions(user)
  local cmd = string.format(
    [[curl -s -H "Authorization: bearer $GITHUB_TOKEN" -X POST -d '{"query":"query {user(login: \"%s\") {contributionsCollection {contributionCalendar {weeks {contributionDays {contributionCount\n date}}}}}}"}' https://api.github.com/graphql | jq '.data.user.contributionsCollection.contributionCalendar.weeks.[].contributionDays' | jq '{weeks: [.[].contributionCount]}' | jq -c -s 'reduce .[] as $item ({}; . + {(length + 1 | tostring): $item.weeks})' ]],
    user
  )

  local p = io.popen(cmd)
  local result = {}
  if p then
    result = p:read("*all")
    p:close()
  end

  return vim.json.decode(result)
end

function Profile.link()
  return {
    type = "text",
    content = function()
      return "https://github.com/Kurama622"
    end,
    hl = "Title",
  }
end

function Profile.sep()
  return {
    type = "sep",
    content = function()
      return ""
    end,
  }
end

function Profile.repos()
  -- curl GET https://pinned.berrysauce.me/get/kurama622
  return {
    type = "table",
    content = function()
      return {
        { name = "llm.nvim", description = "https://github.com/Kurama622/llm.nvim" },
        { name = "profile.nvim", description = "https://github.com/Kurama622/profile.nvim" },
        { name = "profile.nvim", description = "https://github.com/Kurama622/profile.nvim" },
      }
    end,
    hl = "Title",
  }
end

function Profile:pinned_repos_render(linenr, max_cols, spacing)
  local repos = self.repos()
  local element_len_table = {}
  local row_len_table = {}
  local repos_info = {}
  -- print(max_cols)
  for i, v in ipairs(repos.content()) do
    element_len_table[i] = math.max(v.name:len(), v.description:len())
    if i % max_cols == 0 then
      row_len_table[#row_len_table] = row_len_table[#row_len_table] + element_len_table[i]
    else
      row_len_table[#row_len_table + 1] = element_len_table[i]
    end
  end
  print(row_len_table[1], row_len_table[2], row_len_table[3], row_len_table[4])

  local start_pos = (win_max_width - row_len_table[table.maxn(row_len_table)] + spacing) / 2

  for i, v in ipairs(repos.content()) do
    if i % max_cols == 0 then
      repos_info["name"] = repos_info["name"] .. string.rep(" ", spacing / 2) .. v.name
    else
      repos_info["name"] = v.name
    end
  end
  local indent = string.rep(" ", start_pos)

  for i, v in ipairs(repos.content()) do
    -- InsertTextLine(0, linenr + i, indent .. name .. " " .. description)
  end
  -- table = print(#repos.content())
end

local function center_align(text)
  local text_length = #text
  local indent = string.rep(" ", (win_max_width - text_length) / 2)
  return indent .. text
end

local function set_centered_virtual_text(bufnr, ns_id, line, text)
  local text_length = #text
  local indent = string.rep(" ", (win_max_width - text_length) / 2)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line, line + 1)
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
    virt_text = { { indent .. text, "Title" } },
    virt_text_pos = "overlay",
  })
end

function Profile.format()
  local fmt = {
    Profile.avatar(basepath .. "/resources/profile.png"),
    Profile.link(),
    Profile.sep(),
    Profile.repos(),
  }
  return fmt
end

local function set_default_opts(bufnr, winid)
  vim.api.nvim_set_option_value("filetype", "plain", { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("number", false, { win = winid })
  vim.api.nvim_set_option_value("relativenumber", false, { win = winid })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = winid })
  vim.api.nvim_set_option_value("cursorline", false, { win = winid })
end

function Profile.init()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local winid = vim.api.nvim_get_current_win()
  set_default_opts(bufnr, winid)

  -- local ns_id = vim.api.nvim_create_namespace("my_namespace")
  for i = 0, avatar_height / 2 + avatar_y + 1 do
    InsertTextLine(bufnr, i, "")
  end

  for i, v in ipairs(Profile.format()) do
    if v.type == "text" then
      InsertTextLine(bufnr, avatar_height / 2 + avatar_y + i, center_align(v.content()), v.hl)
      -- set_centered_virtual_text(bufnr, ns_id, avatar_height / 2 + avatar_y + i, v.content)
    elseif v.type == "sep" then
      InsertTextLine(bufnr, avatar_height / 2 + avatar_y + i, v.content(), v.hl)
    elseif v.type == "avatar" then
      v.content()
    end
  end
  -- set_centered_virtual_text(bufnr, ns_id, 60, M.url())
end

local function buf_is_empty(bufnr)
  bufnr = bufnr or 0
  return vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == ""
end

function Profile:instance()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" or not vim.bo.modifiable then
    return
  end

  if vim.bo.modified then
    vim.cmd.write()
  end

  if not buf_is_empty(0) then
    self.bufnr = vim.api.nvim_create_buf(false, true)
  else
    self.bufnr = vim.api.nvim_get_current_buf()
  end

  self.winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.winid, self.bufnr)
  self.init()
  -- self:save_user_options()
  --
  -- buf_local()
  -- if self.opts then
  -- 	self:load_theme(self.opts)
  -- else
  -- 	self:get_opts(function(obj)
  -- 		self:load_theme(obj)
  -- 	end)
  -- end
end

return Profile
