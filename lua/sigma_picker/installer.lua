local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local cache_path = vim.fn.stdpath("data") .. "/sigma_cache.json"

local M = {}

M.install_sigma_target = function(opts)
    opts = opts or {}
    local available_targets = {}

    local cache_exists = io.open(cache_path, "r")
    if cache_exists then
        local data = cache_exists:read("*a")
        cache_exists:close()
        available_targets = vim.fn.json_decode(data)
    else
      vim.notify("First-time setup: Fetching available sigma targets. This may take a moment...", vim.log.levels.INFO)
      vim.cmd("redraw")

      local result = vim.fn.system("sigma plugin list")
      if vim.v.shell_error ~= 0 then
          vim.notify("Failed to list Sigma plugins:\n" .. result, vim.log.levels.ERROR)
          return
      end

      for line in result:gmatch("[^\r\n]+") do
          if not line:match("^%+") and not line:match("|%s*Identifier%s*|") and line:match("%S") then
              local target = line:match("^|%s*([^|]+)%s*|")
              if target then
                  target = target:gsub("^%s+", ""):gsub("%s+$", "")
                  if target ~= "" then
                      table.insert(available_targets, target)
                  end
              end
          end
      end
      local file = io.open(cache_path, "w")
      if file then
          file:write(vim.fn.json_encode(available_targets))
          file:close()
      end
    end

    if #available_targets == 0 then
        vim.notify("No available plugins found to install", vim.log.levels.WARN)
        return
    end

    pickers.new(opts, {
        prompt_title = "Install Sigma Target",
        finder = finders.new_table { results = available_targets },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                local chosen = selection.value
                local cmd = "sigma plugin install " .. chosen
                local stdout, stderr = {}, {}

                vim.fn.jobstart(cmd, {
                    stdout_buffered = true,
                    stderr_buffered = true,
                    on_stdout = function(_, data)
                        if data then
                            for _, line in ipairs(data) do
                                if line ~= "" then
                                    table.insert(stdout, line)
                                end
                            end
                        end
                    end,
                    on_stderr = function(_, data)
                        if data then
                            for _, line in ipairs(data) do
                                if line ~= "" then
                                    table.insert(stderr, line)
                                end
                            end
                        end
                    end,
                    on_exit = function(_, code)
                        local output = table.concat(stdout, "\n")
                        local error_output = table.concat(stderr, "\n")

                        if output:match("Successfully installed plugin") then
                            vim.schedule(function()
                                vim.notify("✅ Installed: " .. chosen, vim.log.levels.INFO)
                            end)
                        elseif output:match("already installed") or error_output:match("already installed") then
                            vim.schedule(function()
                                vim.notify("ℹ️ Already installed: " .. chosen, vim.log.levels.INFO)
                            end)
                        elseif code == 0 then
                            vim.schedule(function()
                                vim.notify("⚠️ Installed, but unexpected output:\n" .. output, vim.log.levels.WARN)
                            end)
                        else
                            vim.schedule(function()
                                vim.notify("❌ Failed to install '" .. chosen .. "':\n" .. error_output, vim.log.levels.ERROR)
                            end)
                        end
                    end,
                })
            end)
            return true
        end,
    }):find()
end

return M
