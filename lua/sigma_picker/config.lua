local M = {}

M.default_config = {
    backend_command = function(backend, pipeline, file)
        return "sigma convert -t " .. backend .. " -p " .. pipeline .. " " .. file
    end,
    sigma_cli_check = function()
        if vim.fn.executable("sigma") == 1 then
            return true
        else
            vim.notify("sigma-cli not found. Please install it from https://github.com/SigmaHQ/sigma-cli", vim.log.levels.ERROR)
            return false
        end
    end,
    get_sigma_targets = function()
        if not M.default_config.sigma_cli_check() then
            return {}
        end
        local result = vim.fn.system("sigma list targets")
        if vim.v.shell_error ~= 0 or result:match("No backends installed") then
            local plugin_list = vim.fn.system("sigma plugin list")
            return { error = "No backends installed. Use 'sigma plugin list' to list available plugins:\n" .. plugin_list }
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
        return targets
    end,
    get_sigma_pipelines = function()
        if not M.default_config.sigma_cli_check() then
            return {}
        end
        local result = vim.fn.system("sigma list pipelines")
        if vim.v.shell_error ~= 0 then
            vim.notify("Failed to fetch Sigma pipelines: " .. result, vim.log.levels.ERROR)
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
        local sigma_rules = {}
        local targets = M.default_config.get_sigma_targets()
        if targets.error then
            vim.notify(targets.error, vim.log.levels.ERROR)
            return {}
        end
        for _, target in ipairs(targets) do
            sigma_rules[target] = pipelines
        end
        return sigma_rules
    end,
    sigma_rules = function()
        return M.default_config.get_sigma_pipelines()
    end,
}

M.setup = function(config)
    M.user_config = vim.tbl_deep_extend("force", M.default_config, config or {})
end

return M
