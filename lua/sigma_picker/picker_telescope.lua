local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

function M.pick(opts, items, prompt_title, on_select)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = prompt_title,
        finder = finders.new_table({ results = items }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection and on_select then
                    on_select(selection.value)
                end
            end)
            return true
        end,
    }):find()
end

function M.pick_with_display(opts, items, prompt_title, make_display, on_select)
    opts = opts or {}
    local entry_display = require("telescope.pickers.entry_display")

    local displayer = entry_display.create({
        separator = " ",
        items = { { width = 25 }, { remaining = true } },
    })

    local function make_display_wrapper(entry)
        local display_parts = make_display(entry)
        return displayer(display_parts)
    end

    pickers.new(opts, {
        prompt_title = prompt_title,
        finder = finders.new_table({
            results = items,
            entry_maker = function(entry)
                return {
                    value = entry.id or entry,
                    display = make_display_wrapper,
                    ordinal = entry.id or entry,
                    id = entry.id or entry,
                    compatible = entry.compatible,
                }
            end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection and on_select then
                    on_select(selection.value)
                end
            end)
            return true
        end,
    }):find()
end

return M
