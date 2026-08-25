local cache_path = vim.fn.stdpath("data") .. "/sigma_cache.json"
local picker_strategy = require("sigma_picker.picker_strategy")

local M = {}

local function read_cache()
    local file = io.open(cache_path, "r")
    if not file then return nil end
    local data = file:read("*a")
    file:close()
    local ok, decoded = pcall(vim.fn.json_decode, data)
    return ok and decoded or nil
end

local function write_cache(cache)
    local file = io.open(cache_path, "w")
    if file then
        file:write(vim.fn.json_encode(cache))
        file:close()
    end
end

local function make_install_display(entry)
    local compat = entry.compatible and "" or " (Incompatible)"
    local hl = entry.compatible and "TelescopeResultsIdentifier" or "ErrorMsg"
    return { { entry.id, hl }, { compat, "Comment" } }
end

local function make_uninstall_display(entry)
    return { { entry.id, "TelescopeResultsIdentifier" }, { " (installed)", "Comment" } }
end

M.install_sigma_target = function(opts)
    opts = opts or {}
    local available_targets = {}

    local cache = read_cache()
    if cache then
        available_targets = cache
    else
        vim.notify("First-time setup: Fetching available sigma targets. This may take a moment...", vim.log.levels.INFO)
        vim.cmd("redraw")

        local result = vim.fn.system("sigma plugin list")
        if vim.v.shell_error ~= 0 then
            vim.notify("Failed to list Sigma plugins:\n" .. result, vim.log.levels.ERROR)
            return
        end

        for line in result:gmatch("[^\r\n]+") do
            if line:match("^|") and not line:match("Identifier") then
                local id, _, _, _, compat = line:match("^|%s*([^|]+)%s*|%s*([^|]+)%s*|%s*([^|]+)%s*|%s*([^|]+)%s*|%s*([^|]+)%s*|")
                if id and id:match("%S") then
                    table.insert(available_targets, {
                        id = id:gsub("%s+", ""),
                        compatible = compat:gsub("%s+", ""):lower() == "yes",
                    })
                end
            end
        end
        write_cache(available_targets)
    end

    if #available_targets == 0 then
        vim.notify("No available plugins found to install", vim.log.levels.WARN)
        return
    end

    local strategy = picker_strategy.get()
    if not strategy then
        return
    end

    strategy.pick_with_display(opts, available_targets, "Install Sigma Target", make_install_display, function(chosen)
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
end

M.uninstall_sigma_target = function(opts)
    opts = opts or {}

    local result = vim.fn.system("sigma list targets")
    if vim.v.shell_error ~= 0 or result:match("No backends installed") then
        vim.notify("No installed Sigma plugins found to uninstall.", vim.log.levels.WARN)
        return
    end

    local seen = {}
    local installed_plugins = {}
    for line in result:gmatch("[^\r\n]+") do
        if not line:match("^%+") and not line:match("|%s*Identifier%s*|") and line:match("%S") then
            local col1, col2, col3, col4 = line:match("^|%s*([^|]-)%s*|%s*([^|]-)%s*|%s*([^|]-)%s*|%s*([^|]-)%s*|")
            if col1 and col1:match("%S") and col4 then
                local plugin = vim.trim(col4)
                if plugin ~= "" and plugin:lower() ~= "yes" and plugin:lower() ~= "no" and not seen[plugin] then
                    seen[plugin] = true
                    table.insert(installed_plugins, { id = plugin })
                end
            end
        end
    end

    if #installed_plugins == 0 then
        vim.notify("No installed Sigma plugins found to uninstall.", vim.log.levels.WARN)
        return
    end

    local strategy = picker_strategy.get()
    if not strategy then
        return
    end

    strategy.pick_with_display(opts, installed_plugins, "Uninstall Sigma Plugin", make_uninstall_display, function(chosen)
        local cmd = "sigma plugin uninstall " .. chosen
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

                if output:match("Successfully uninstalled plugin") then
                    vim.schedule(function()
                        vim.notify("✅ Uninstalled: " .. chosen, vim.log.levels.INFO)
                    end)
                elseif code == 0 then
                    vim.schedule(function()
                        vim.notify("⚠️ Uninstalled, but unexpected output:\n" .. output, vim.log.levels.WARN)
                    end)
                else
                    vim.schedule(function()
                        vim.notify("❌ Failed to uninstall '" .. chosen .. "':\n" .. error_output, vim.log.levels.ERROR)
                    end)
                end
            end,
        })
    end)
end

M.refresh_cache = function()
    local success, err = os.remove(cache_path)
    if success then
        vim.notify("✅ Sigma plugin cache cleared successfully", vim.log.levels.INFO)
    else
        vim.notify("ℹ️ Failed to clear sigma plugin cache: " .. (err or "unknown"), vim.log.levels.WARN)
    end
end

return M