local M = {}
local m = {}
local config = require 'fastaction.config'
local keys = require 'fastaction.keys'
local window = require 'fastaction.window'

---@type string[]
m.keys = {}

---Get action configs from the given items, checking priority configs first
---to reserve keys before trying remaining heuristics first-come-first-serve.
---@param items any[] Arbitrary items
---@param opts GetActionConfigsOpts Additional options
---@param skip_priority? boolean Iff true, skip checking for priority configs. Used internally.
---@param options? Option[] Currently-generated options. Used internally.
---@param largest_char_count? integer Largest char count for the items. Used internally.
---@return Option[] options Action config options
---@return integer largest_char_count Largest char count for the items
---@return any[] remaining_items Remaining items to be processed
function m.get_action_configs(items, opts, skip_priority, options, largest_char_count)
    local conf = config.get()
    options = options or {}
    largest_char_count = largest_char_count or 0
    local check_priority = not skip_priority and #opts.priorities > 0
    local remaining_items = {} ---@type any[]
    vim.iter(items):each(function (item)
        local item_name = opts.format_item(item)
        local action_config = { ---@type GetPriorityActionConfigParams
            kind = opts.kind,
            title = item_name,
            priorities = opts.priorities,
            valid_keys = opts.valid_keys,
            invalid_keys = opts.used_keys,
            override_function = conf.override_function,
        }

        local match ---@type ActionConfig
        if check_priority then
            -- Not all items will have a *priority* match. Skip assignment if there is none.
            local priority_match = keys.get_priority_action_config(action_config)
            if not priority_match then
                remaining_items[#remaining_items+1] = item
                return
            end
            match = priority_match
        else
            -- All items should have a *standard* match. If there is none, bail and error.
            match = assert(keys.get_action_config(action_config), 'Failed to find a key to map to "' .. item_name .. '"')
        end

        local item_right_section = conf.format_right_section and conf.format_right_section(item) or ""
        local item_char_count = #item_name + #item_right_section
        largest_char_count = math.max(item_char_count, largest_char_count)
        options[#options+1] = {
            item = item,
            name = item_name,
            key = match.key,
            order = match.order,
            right_section = item_right_section,
            char_count = item_char_count,
        }
    end)

    if check_priority then
        return m.get_action_configs(remaining_items, opts, true, options, largest_char_count)
    end
    return options, largest_char_count, remaining_items
end

--- Show a selection prompt with the code actions available for the cursor
--- position.
function M.code_action(code_action_opts)
    code_action_opts = code_action_opts or {}
    local select_first = code_action_opts.select_first or false
    local code_action_args = vim.tbl_deep_extend('force', {}, code_action_opts)
    code_action_args.select_first = nil

    m.select_cb = vim.ui.select
    vim.g.fastaction_code_action = true
    local code_action_select = function(items, opts, on_choice)
        opts['relative'] = config.get().popup.relative or 'cursor'
        items = M.sort_items(items)
        if select_first and #items then
            on_choice(items[1], 1)
        else
            M.select(items, opts, on_choice)
        end
    end
    vim.ui.select = code_action_select
    vim.lsp.buf.code_action(code_action_args)
end

--- Prompts the user to pick from a list of items, allowing arbitrary (potentially asynchronous)
--- work until `on_choice`.
---
--- Example:
---
--- ```lua
--- vim.ui.select({ 'tabs', 'spaces' }, {
---     prompt = 'Select tabs or spaces:',
---     format_item = function(item)
---         return "I'd like to choose " .. item
---     end,
--- }, function(choice)
---     if choice == 'spaces' then
---         vim.o.expandtab = true
---     else
---         vim.o.expandtab = false
---     end
--- end)
--- ```
---
---@param items any[] Arbitrary items
---@param opts SelectOpts Additional options
---     - prompt (string|nil)
---               Text of the prompt. Defaults to `Select one of:`
---     - format_item (function item -> text)
---               Function to format an
---               individual item from `items`. Defaults to `tostring`.
---     - kind (string|nil)
---               Arbitrary hint string indicating the item shape.
---               Plugins reimplementing `vim.ui.select` may wish to
---               use this to infer the structure or semantics of
---               `items`, or the context in which select() was called.
---@param on_choice fun(item: any|nil, idx: integer|nil)
---               Called once the user made a choice.
---               `idx` is the 1-based index of `item` within `items`.
---               `nil` if the user aborted the dialog.
function M.select(items, opts, on_choice)
    local conf = config.get()
    if #items > conf.fallback_threshold then return m.select(items, opts, on_choice) end
    ---@type PopupLine[]
    local content = {}

    local options, largest_char_count, remaining_items = m.get_action_configs(items, {
        kind = opts.kind,
        priorities = config.get_priorities(conf.priority, true),
        valid_keys = keys.generate_keys(#items, m.keys, conf.dismiss_keys),
        used_keys = vim.tbl_extend('force', {}, conf.dismiss_keys),
        format_item = opts.format_item or tostring,
    })
    assert(0 == #remaining_items, 'Failed to generate options for ' .. #remaining_items .. ' actions')

    local brackets = config.get().brackets or { '[', ']' }
    for i, option in ipairs(options) do
        local spacing = largest_char_count + 1 - option.char_count

        local source_text = ''
        local action_text = option.name:gsub('(%[[a-z_-]+%])%s*$', function(source)
            source_text = source
            return ''
        end)

        content[i] = {
            {
                text = string.format('%s%s%s', brackets[1], option.key, brackets[2]),
                highlight = conf.popup.highlight.key,
            },
            { text = ' ' },
            { text = action_text, highlight = conf.popup.highlight.action },
            { text = source_text, highlight = conf.popup.highlight.source },
            { text = string.rep(' ', spacing) },
            { text = option.right_section },
        }
    end

    ---@param buffer integer
    local function setup_keymaps(buffer)
        local kopts = { buffer = buffer, noremap = true, silent = true, nowait = true }
        for i, option in ipairs(options) do
            vim.keymap.set('n', option.key, function()
                window.popup_close()
                on_choice(option.item, i)
            end, kopts)
        end
    end

    ---@type WindowOpts | SelectOpts
    local winopts = vim.tbl_deep_extend('keep', opts, conf.popup)
    winopts.relative = opts.relative or winopts.relative or 'editor'
    winopts.dismiss_keys = conf.dismiss_keys
    window.popup_window(content, setup_keymaps, winopts)
end

---@param opts FastActionConfig
function M.setup(opts)
    config.resolve(opts)
    local conf = config.get()
    m.select = vim.ui.select
    if conf.register_ui_select then vim.ui.select = M.select end
    m.keys = config.get_configured_keys()
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'fastaction_popup',
        callback = function()
            vim.api.nvim_create_autocmd('WinLeave', {
                group = vim.api.nvim_create_augroup('fastaction_close_popup', {}),
                once = true,
                pattern = '*',
                callback = function()
                    if not vim.g.fastaction_code_action then return end
                    vim.ui.select = m.select_cb
                    vim.g.fastaction_code_action = false
                end,
            })
        end,
    })
end

--- Sort code action items based on priorities defined in FastActionConfig
function M.sort_items(items)
    local priorities = config.get_priorities(config.get().priority, true)

    for _, item in ipairs(items) do
        for _, priority in ipairs(priorities) do
            if item.action.title:lower():match(priority.pattern) then
                item['__order'] = priority.order or 0
                break
            end
        end
    end

    table.sort(items, function(a, b) return (a.__order or math.huge) < (b.__order or math.huge) end)

    return items
end

return M