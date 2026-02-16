local utils = require("sigma_picker.utils")

local M = {}

M.list_targets = function()
    local result = vim.fn.system("sigma list targets")
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to list Sigma targets:\n" .. result, vim.log.levels.ERROR)
        return {}
    end

    local targets = {}
    for line in result:gmatch("[^\r\n]+") do
        if not line:match("^%+") and not line:match("|%s*Identifier%s*|") and line:match("%S") then
            local target = line:match("^|%s*([^|]+)%s*|")
            if target then
                target = target:gsub("^%s+", ""):gsub("%s+$", "")
                if target ~= "" then
                    table.insert(targets, target)
               end
            end
        end
    end
    utils.create_floating_window(targets)
    return targets
end

M.list_pipelines = function()
    local result = vim.fn.system("sigma list pipelines")
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to list Sigma pipelines:\n" .. result, vim.log.levels.ERROR)
        return {}
    end

    local pipelines = {}
    for line in result:gmatch("[^\r\n]+") do
        if not line:match("^%+") and not line:match("|%s*Identifier%s*|") and line:match("%S") then
            local pipeline = line:match("^|%s*([^|]+)%s*|")
            if pipeline then
                pipeline = pipeline:gsub("^%s+", ""):gsub("%s+$", "")
                if pipeline ~= "" then
                    table.insert(pipelines, pipeline)
                end
            end
        end
    end
    utils.create_floating_window(pipelines)
    return pipelines
end

return M
