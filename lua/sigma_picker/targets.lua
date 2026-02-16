local utils = require("sigma_picker.utils")

local M = {}

local function fetch_sigma_list(resource_type)
    local cmd = "sigma list " .. resource_type
    local result = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to list Sigma " .. resource_type .. ":\n" .. result, vim.log.levels.ERROR)
        return {}
    end

    local items = {}
    for line in result:gmatch("[^\r\n]+") do
        if not line:match("^%+") and not line:match("|%s*Identifier%s*|") and line:match("%S") then
            local item = line:match("^|%s*([^|]+)%s*|")
            if item then
                item = vim.trim(item)
                if item ~= "" then
                    table.insert(items, item)
                end
            end
        end
    end

    utils.create_floating_window(items)
    return items
end

M.list_targets = function()
    return fetch_sigma_list("targets")
end

M.list_pipelines = function()
    return fetch_sigma_list("pipelines")
end

return M
