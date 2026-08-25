local utils = require("sigma_picker.utils")
local config = require("sigma_picker.config")
local picker_strategy = require("sigma_picker.picker_strategy")

local M = {}

M.sigma_picker = function(opts)
    opts = opts or {}

    if not config.user_config or not config.user_config.sigma_cli_check then
        vim.notify("sigma_cli_check function not found in sigma_picker.config.user_config", vim.log.levels.ERROR)
        return
    end

    if not config.user_config.sigma_cli_check() then
        return
    end

    local targets = config.user_config.get_sigma_targets()
    if targets.error then
        vim.notify(targets.error, vim.log.levels.ERROR)
        return
    end
    if not next(targets) then
        vim.notify("No Sigma backends available", vim.log.levels.WARN)
        return
    end

    local sigma_rules = config.user_config.sigma_rules()
    if not next(sigma_rules) then
        vim.notify("No Sigma pipelines available", vim.log.levels.WARN)
        return
    end

    local strategy = picker_strategy.get()
    if not strategy then
        return
    end

    local function pick_config(selected_backend)
        local configs = sigma_rules[selected_backend] or {}
        if not next(configs) then
            vim.notify("No pipelines available for " .. selected_backend, vim.log.levels.WARN)
            return
        end

        strategy.pick(opts, configs, "Choose Pipeline for " .. selected_backend, function(selected_config)
            local current_file = vim.api.nvim_buf_get_name(0)

            if current_file == "" or not current_file:match("%.ya?ml$") then
                vim.notify("Please open a Sigma rule (.yml or .yaml) file", vim.log.levels.ERROR)
                return
            end

            local command = config.user_config.backend_command(selected_backend, selected_config, current_file)

            vim.fn.jobstart(command, {
                stdout_buffered = true,
                on_stdout = function(_, data)
                    if data and #data > 0 then
                        local filtered_data = vim.tbl_filter(function(line)
                            return line ~= nil and line ~= ""
                        end, data)
                        utils.create_floating_window(filtered_data)
                    end
                end,
                on_stderr = function(_, data)
                    if data and #data > 0 then
                        local filtered_data = vim.tbl_filter(function(line)
                            return line ~= nil and line:match("%S") and line ~= "Error:"
                        end, data)
                        if #filtered_data > 0 then
                            local message = table.concat(filtered_data, "\n")
                            if message:match("Parsing Sigma rules") then
                                vim.notify("Warning: " .. message, vim.log.levels.WARN)
                            else
                                vim.notify("Error: " .. message, vim.log.levels.ERROR)
                            end
                        end
                    end
                end,
                on_exit = function(_, code)
                    if code == 0 then
                        vim.notify("Backend converter completed successfully!", vim.log.levels.INFO)
                    else
                        vim.notify("Backend converter exited with code: " .. code, vim.log.levels.ERROR)
                    end
                end,
            })
        end)
    end

    strategy.pick(opts, vim.tbl_keys(sigma_rules), "Sigma Rules Backend Picker", function(selected_backend)
        pick_config(selected_backend)
    end)
end

return M