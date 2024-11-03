# profile.nvim

Your personal profile page in Neovim.

![profile1](https://github.com/user-attachments/assets/ec627c79-ebac-46f5-8728-57472836642a)
![profile2](https://github.com/user-attachments/assets/24f8d775-f484-47a1-a278-b011817db08b)


## Dependencies

- ["3rd/image.nvim"](https://github.com/3rd/image.nvim) - see [image.nvim:Installation](https://github.com/3rd/image.nvim?tab=readme-ov-file#installation)
- curl, jq

## Installation

- lazy.nvim

```lua
{
  "Kurama622/profile.nvim",
  dependencies = { "3rd/image.nvim" },
  config = function()
    require("profile").setup({
      avatar_path = "<your avatar path>", -- default: profile.nvim/resources/profile.png
    })
    vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>Profile<cr>", { silent = true })
  end
}
```


Complete configuration

```lua
  {
    "Kurama622/profile.nvim",
    dependencies = { "3rd/image.nvim" },
    config = function()
      local comp = require("profile.components")
      require("profile").setup({
        avatar_path = "/home/arch/Github/profile.nvim/resources/profile.png",
        -- avatar position options
        avatar_opts = {
          avatar_width = 20,
          avatar_height = 20,
          avatar_x = (vim.o.columns - 20) / 2,
          avatar_y = 7,
        },

        -- git user
        user = "Kurama622",
        git_contributions = {
          start_week = 1, -- The minimum is 1
          end_week = 53, -- The maximum is 53
          empty_char = " ",
          full_char = { "", "󰧞", "", "", "" },
          fake_contributions = nil,
          --[[
          -- If you want to fake git's contribution information,
          -- you can pass a function to fake_contributions.
          fake_contributions = function()
            local ret = {}
            for i = 1, 53 do
              ret[tostring(i)] = {}
              for j = 1, 7 do
                ret[tostring(i)][j] = math.random(0, 5)
              end
            end
            return ret
          end,
          ]]
        },
        hide = {
          statusline = true,
          tabline = true,
        },

        -- Customize the content to render
        format = function()
          -- render avatar
          comp:avatar()
          -- customize text component
          comp:text_component_render({
            comp:text_component("git@github.com:Kurama622/profile.nvim", "center", "ProfileRed"),
            comp:text_component("──── By Kurama622", "right", "ProfileBlue"),
          })
          comp:seperator_render()

          -- Custom card component, render git repository by default
          comp:card_component_render({
            type = "table",
            content = function()
              return {
                {
                  title = "kurama622/llm.nvim",
                  description = [[LLM Neovim Plugin: Effortless Natural
           Language Generation with LLM's API]],
                },
                {
                  title = "kurama622/profile.nvim",
                  description = [[A Neovim plugin: Your Personal Homepage]],
                },
              }
            end,
            hl = {
              border = "ProfileYellow",
              text = "ProfileYellow",
            },
          })
          comp:seperator_render()

          -- git contributions, Considering network latency, the module will render asynchronously.
          -- you can also configure `fake_contributions`, so it won't fetch data from the Github
          comp:git_contributions_render("ProfileGreen")
        end,
      })
      vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>Profile<cr>", { silent = true })
    end,
  },
```

## References

- [dashboard-nvim](https://github.com/nvimdev/dashboard-nvim)
