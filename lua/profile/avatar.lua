local api = vim.api

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

local function center_align(text)
  local text_length = #text
  local indent = string.rep(" ", (vim.o.columns - text_length) / 2)
  return indent .. text
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
local function avatar_instance(config)
  if config.avatar and type(config.avatar) == "function" then
    config.avatar().content()
  elseif config.avatar then
    local img = require("image")
    config.obj.avatar = img.from_file(config.avatar_path, {
      id = "avatar",
      inline = true,
      x = config.avatar_opts.avatar_x,
      y = config.avatar_opts.avatar_y,
      width = config.avatar_opts.avatar_width,
      height = config.avatar_opts.avatar_height,
    })
  end

  api.nvim_set_option_value("modifiable", false, { buf = config.bufnr })
  api.nvim_set_option_value("modified", false, { buf = config.bufnr })
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
