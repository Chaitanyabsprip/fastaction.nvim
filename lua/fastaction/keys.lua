local M = {}
local m = {}
local config = require 'fastaction.config'

M.AUTO_ORDER = 10

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_title(params)
    if
        params.title == nil
        or params.title == ''
        or not params.valid_keys
        or #params.valid_keys == 0
    then
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

---@param params GetPriorityActionConfigParams
---@return ActionConfig | nil
function M.get_priority_action_config(params)
    return m.get_action_config_from_funcs(params, { m.get_action_config_from_priorities })
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function M.get_action_config(params)
    return m.get_action_config_from_funcs(params, vim.list_extend(
        params.override_function and { params.override_function } or {},
        { m.get_action_config_from_title, m.get_action_config_from_keys }
    ))
end

---@param keys string[]
---@return fun(key: string): boolean
local function filter_valid(keys)
    return function(key) return not vim.tbl_contains(keys, key) end
end

---Generate n-letter permutations given a list of letters
---@param letters string[]
---@param n integer
---@param taken string[]
---@return string[]
local function generate_permutations(letters, n, taken)
    local permutations = {}
    taken = taken or {}

    ---@param current string
    ---@param remaining string[]
    local function permute(current, remaining)
        if #current == n then
            table.insert(permutations, current)
            return
        end
        for i = 1, #remaining do
            local nextLetter = remaining[i]
            if not (string.len(current) == 0 and vim.tbl_contains(taken, nextLetter)) then
                permute(
                    current .. nextLetter,
                    vim.list_extend({ unpack(remaining, 1, i - 1) }, { unpack(remaining, i + 1) })
                )
            end
        end
    end
    permute('', letters)
    return permutations
end

---@param n integer
---@return integer
local function factorial(n)
    assert(n >= 0, 'n must be non-negative')
    if n < 2 then return 1 end
    local result = 1
    for i = 2, n do
        result = result * i
    end
    return result
end

---@param k integer
---@param p integer
---@return integer
local function permutations(k, p)
    if p > k then return 0 end
    return factorial(k) / factorial(k - p)
end

---@param allowed_key_count integer
---@param item_count integer
---@return integer
local function calculate_min_keymap_length(allowed_key_count, item_count)
    local length = 1
    while permutations(allowed_key_count, length) < item_count do
        length = length + 1
    end
    return length
end

---@param item_count integer
---@param allowed_keys string[]
---@param dismiss_keys string[]
---@return string[]
function M.generate_keys(item_count, allowed_keys, dismiss_keys)
    dismiss_keys = M.filter_alpha_keys(dismiss_keys)
    local chars = calculate_min_keymap_length(#allowed_keys, item_count)

    ---@type string[]
    local taken_keys = config.get_prioritised_keys(vim.bo.filetype)
    local valid_keys = vim.tbl_filter(
        filter_valid(dismiss_keys),
        generate_permutations(allowed_keys, chars, taken_keys)
    )
    return valid_keys
end

---@param keys string[]
---@return string[]
function M.filter_alpha_keys(keys)
    local function is_alpha(k) return k:match '^[a-z]+$' end
    return vim.tbl_filter(is_alpha, keys)
end

return M
