local M = {}

function M.pick(opts, items, prompt_title, on_select)
    opts = opts or {}

    if #items == 0 then
        vim.notify("No items to pick from", vim.log.levels.WARN)
        return
    end

    vim.ui.select(items, {
        prompt = prompt_title,
        format_item = function(item)
            return tostring(item)
        end,
    }, function(choice)
        if choice and on_select then
            on_select(choice)
        end
    end)
end

function M.pick_with_display(opts, items, prompt_title, make_display, on_select)
    opts = opts or {}

    if #items == 0 then
        vim.notify("No items to pick from", vim.log.levels.WARN)
        return
    end

    local display_items = {}
    for _, item in ipairs(items) do
        local display = make_display(item)
        if type(display) == "table" then
            display = display[1][1] .. (display[2] and " " .. display[2][1] or "")
        end
        table.insert(display_items, { item = item, display = display })
    end

    vim.ui.select(display_items, {
        prompt = prompt_title,
        format_item = function(item)
            return item.display
        end,
    }, function(choice)
        if choice and on_select then
            on_select(choice.item.id or choice.item)
        end
    end)
end

return M
