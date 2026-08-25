local config = require("sigma_picker.config")

local M = {}

local strategies = {}

local function load_telescope()
    local ok, telescope = pcall(require, "telescope")
    if not ok then
        return nil
    end
    local ok2, picker_telescope = pcall(require, "sigma_picker.picker_telescope")
    if not ok2 then
        return nil
    end
    return picker_telescope
end

local function load_native()
    local ok, picker_native = pcall(require, "sigma_picker.picker_native")
    if not ok then
        return nil
    end
    return picker_native
end

function M.get()
    local backend = config.user_config.picker_backend or "auto"
    
    if backend == "telescope" then
        local strat = load_telescope()
        if strat then
            return strat
        end
        vim.notify("Telescope not available, falling back to native picker", vim.log.levels.WARN)
    elseif backend == "native" then
        local strat = load_native()
        if strat then
            return strat
        end
        vim.notify("Native picker not available", vim.log.levels.ERROR)
        return nil
    end
    
    local strat = load_telescope()
    if strat then
        return strat
    end
    
    strat = load_native()
    if strat then
        return strat
    end
    
    vim.notify("No picker backend available", vim.log.levels.ERROR)
    return nil
end

function M.register(name, strategy)
    strategies[name] = strategy
end

return M