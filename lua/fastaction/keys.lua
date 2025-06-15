local M = {}
local m = {}
local config = require 'fastaction.config'
local util = require 'fastaction.utils'

M.AUTO_ORDER = 10

---@param item_count integer
---@param allowed_keys string[]
---@param dismiss_keys string[]
---@return string[]
function M.generate_keys(item_count, allowed_keys, dismiss_keys)
    local chars = util.calculate_min_keymap_length(#allowed_keys, item_count)
    local taken_keys = config.get_prioritised_keys(vim.bo.filetype)
    if taken_keys then taken_keys = vim.tbl_extend('force', taken_keys, dismiss_keys) end
    taken_keys = util.filter_alpha_keys(taken_keys)
    local valid_keys = vim.tbl_filter(
        m.filter_valid(taken_keys),
        m.generate_permutations(allowed_keys, chars, item_count + #taken_keys)
    )
    return valid_keys
end

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
function M.get_action_configs(items, opts, skip_priority, options, largest_char_count)
    local conf = config.get()
    options = options or {}
    largest_char_count = largest_char_count or 0
    local check_priority = not skip_priority and #opts.priorities > 0
    local remaining_items = {} ---@type any[]
    vim.iter(items):each(function(item)
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
            local priority_match = m.get_priority_action_config(action_config)
            if not priority_match then
                remaining_items[#remaining_items + 1] = item
                return
            end
            match = priority_match
        else
            -- All items should have a *standard* match. If there is none, bail and error.
            local k = m.get_action_config(action_config)
            if not k then
                remaining_items[#remaining_items + 1] = item
                return
            end
            match = assert(k, 'Failed to find a key to map to "' .. item_name .. '"')
        end

        local item_right_section = conf.format_right_section and conf.format_right_section(item)
            or ''
        local item_char_count = #item_name + #item_right_section
        largest_char_count = math.max(item_char_count, largest_char_count)
        options[#options + 1] = {
            item = item,
            name = item_name,
            key = match.key,
            order = match.order,
            right_section = item_right_section,
            char_count = item_char_count,
        }
    end)

    if check_priority then
        return M.get_action_configs(remaining_items, opts, true, options, largest_char_count)
    end
    return options, largest_char_count, remaining_items
end

---@param keys string[]
---@return fun(key: string): boolean
function m.filter_valid(keys)
    return function(key) return type(key) == 'string' and not vim.tbl_contains(keys, key) end
end

--- Lazily generates up to `max_results` permutations of length `n` from `letters`.
---@param letters string[]
---@param n integer
---@param max_results integer
---@return string[]
function m.generate_permutations(letters, n, max_results)
    local results = {}

    ---@type fun(current: string, used: table<string, boolean>): boolean
    local function backtrack(current, used)
        if #results >= max_results then return true end
        if #current == n then
            table.insert(results, current)
            return false
        end

        for i = 1, #letters do
            local ch = letters[i]
            if not used[ch] then
                used[ch] = true
                local stop = backtrack(current .. ch, used)
                used[ch] = nil
                if stop then return true end
            end
        end
        return false
    end

    backtrack('', {})
    return results
end

---@param params GetPriorityActionConfigParams
---@return ActionConfig | nil
function m.get_priority_action_config(params)
    return m.get_action_config_from_funcs(params, { m.get_action_config_from_priorities })
end

---@param params GetActionConfigParams
---@param funcs table<fun(params: GetActionConfigParams): ActionConfig | nil>
---@return ActionConfig | nil
function m.get_action_config_from_funcs(params, funcs)
    for _, f in ipairs(funcs) do
        if f then
            local a = f(params)
            if a then
                params.invalid_keys[#params.invalid_keys + 1] = a.key
                return a
            end
        end
    end
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_priorities(params)
    if params.priorities == nil or #params.priorities == 0 then return nil end
    for _, priority in ipairs(params.priorities) do
        if
            not vim.tbl_contains(params.invalid_keys, priority.key)
            and params.title:lower():match(priority.pattern)
        then
            priority.order = priority.order or M.AUTO_ORDER
            return priority
        end
    end
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config(params)
    if params.override_function ~= nil then print 'Using override function for action config' end
    return m.get_action_config_from_funcs(
        params,
        vim.list_extend(
            params.override_function and { params.override_function } or {},
            { m.get_action_config_from_title, m.get_action_config_from_keys }
        )
    )
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_title(params)
    if
        params.title == nil
        or params.title == ''
        or not params.valid_keys
        or #params.valid_keys == 0
    then
        print 'No valid keys or title provided for action config from title'
        return nil
    end
    local index = 1
    local increment = #params.valid_keys[1]
    params.title = string.lower(params.title):lower()
    repeat
        local char = params.title:sub(index, index + increment - 1)
        if
            char:match '[a-z]+'
            and not vim.tbl_contains(params.invalid_keys, char)
            and vim.tbl_contains(params.valid_keys, char)
        then
            return { key = char, order = M.AUTO_ORDER }
        end
        index = index + increment
    until index >= #params.title
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_keys(params)
    if not params.valid_keys or #params.valid_keys == 0 then return nil end
    for _, k in pairs(params.valid_keys) do
        if not vim.tbl_contains(params.invalid_keys, k) then
            return { key = k, order = M.AUTO_ORDER }
        end
    end
end

return M
