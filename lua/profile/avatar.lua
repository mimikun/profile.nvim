local api = vim.api

local function set_hl_text(bufnr, linenr, text, hl)
  hl = hl or "Normal"
  api.nvim_buf_set_lines(bufnr, linenr, linenr, false, { text })
  api.nvim_buf_add_highlight(bufnr, -1, hl, linenr, 0, -1)
end

local function center_align(text)
  local indent = string.rep(" ", math.floor((vim.o.columns - vim.api.nvim_strwidth(text)) / 2))
  return indent .. text
end

local function link()
  return {
    type = "text",
    content = function()
      return "https://github.com/Kurama622"
    end,
    hl = "Title",
  }
end

local function sep()
  return {
    type = "sep",
    content = function()
      return ""
    end,
  }
end

local function git_contributions(user)
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

local function async_get_git_contributions(opts, callback)
  vim.defer_fn(function()
    local contribute_map = {}
    local contributions = git_contributions(opts.config.user)
    for row = 1, 7 do
      contribute_map[row] = ""
      for col = 1, 53 do
        if contributions[tostring(col)][row] == nil then
          contribute_map[row] = contribute_map[row] .. " "
        elseif contributions[tostring(col)][row] == 0 then
          contribute_map[row] = contribute_map[row] .. "□ "
        else
          contribute_map[row] = contribute_map[row] .. "■ "
        end
      end
      contribute_map[row] = center_align(contribute_map[row])
    end
    callback(contribute_map)
  end, 1000)
end

local function git_contributions_render(opts, offset_y)
  async_get_git_contributions(opts, function(map)
    for row = 1, 7 do
      api.nvim_buf_set_lines(opts.bufnr, offset_y + row, offset_y + row, false, { map[row] })
    end
    api.nvim_set_option_value("modifiable", false, { buf = opts.bufnr })
    api.nvim_set_option_value("modified", false, { buf = opts.bufnr })
    for row = 0, 6 do
      api.nvim_buf_add_highlight(opts.bufnr, -1, "String", offset_y + row, 0, -1)
    end
  end)
end

local function repos()
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

local function set_centered_virtual_text(bufnr, ns_id, line, text)
  local text_length = #text
  local indent = string.rep(" ", (vim.o.columns - text_length) / 2)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line, line + 1)
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
    virt_text = { { indent .. text, "Title" } },
    virt_text_pos = "overlay",
  })
end

---@private
local function avatar_instance(opts)
  if opts.config.avatar and type(opts.config.avatar) == "function" then
    opts.config.avatar().content()
  elseif opts.config.avatar then
    local img = require("image")
    opts.obj.avatar = img.from_file(opts.avatar_path, {
      id = "avatar",
      inline = true,
      x = opts.avatar_opts.avatar_x,
      y = opts.avatar_opts.avatar_y,
      width = opts.avatar_opts.avatar_width,
      height = opts.avatar_opts.avatar_height,
    })
  end

  local offset_y = opts.avatar_opts.avatar_height / 2 + opts.avatar_opts.avatar_y
  for offset = 1, offset_y do
    set_hl_text(opts.bufnr, offset, "")
  end

  offset_y = offset_y + 1
  set_hl_text(opts.bufnr, offset_y, center_align(link().content()), link().hl)

  offset_y = offset_y + 1
  set_hl_text(opts.bufnr, offset_y, center_align(sep().content()))

  offset_y = offset_y + 1
  git_contributions_render(opts, offset_y)

  --defer until next event loop
  vim.schedule(function()
    api.nvim_exec_autocmds("User", {
      pattern = "ProfileLoaded",
      modeline = false,
    })
  end)
end

return setmetatable({}, {
  __call = function(_, t)
    return avatar_instance(t)
  end,
})
