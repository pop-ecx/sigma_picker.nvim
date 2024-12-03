local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local utils = require("sigma_picker.utils")
local config = require("sigma_picker.config")

local M = {}

M.sigma_picker = function(opts)
    opts = opts or {}

    local function pick_config(selected_backend)
        local configs = config.user_config.sigma_rules[selected_backend]

        pickers.new(opts, {
            prompt_title = "Choose Configuration for " .. selected_backend,
            finder = finders.new_table({ results = configs }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)

                    local selected_config = selection.value
                    local current_file = vim.api.nvim_buf_get_name(0)

                    if current_file == "" then
                        print("No file opened in the current buffer!")
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
                                print("Error:", table.concat(data, "\n"))
                            end
                        end,
                        on_exit = function(_, code)
                            if code == 0 then
                                print("Backend converter completed successfully!")
                            else
                                print("Backend converter exited with code:", code)
                            end
                        end,
                    })
                end)
                return true
            end,
        }):find()
    end

    pickers.new(opts, {
        prompt_title = "Sigma Rules Backend Picker",
        finder = finders.new_table({ results = vim.tbl_keys(config.user_config.sigma_rules) }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                local selected_backend = selection.value
                pick_config(selected_backend)
            end)
            return true
        end,
    }):find()
end

return M

