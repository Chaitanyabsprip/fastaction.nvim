local M = {}
local m = {}

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_title(params)
    if params.title == nil or params.title == '' then return nil end
    local index = 1
    local increment = #params.valid_keys[1]
    params.title = string.lower(params.title)
    repeat
        local char = params.title:sub(index, index + increment - 1)
        if
            char:match '[a-z]+'
            and not vim.tbl_contains(params.invalid_keys, char)
            and vim.tbl_contains(params.valid_keys, char)
        then
            return { key = char, order = 0 }
        end
        index = index + increment
    until index >= #params.title
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_keys(params)
    if #params.valid_keys == nil or #params.valid_keys == 0 then return nil end
    for _, k in pairs(params.valid_keys) do
        if not vim.tbl_contains(params.invalid_keys, k) then return { key = k, order = 0 } end
    end
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_priorities(params)
    if params.priorities == nil or #params.priorities == 0 then return nil end
    for _, value in ipairs(params.priorities) do
        if
            not vim.tbl_contains(params.invalid_keys, value.key)
            and params.title:lower():match(value.pattern)
        then
            return value
        end
    end
end

---@param params GetActionConfigParams
---@return ActionConfig | nil
function M.get_action_config(params)
    local funcs = {
        params.override_function,
        m.get_action_config_from_priorities,
        m.get_action_config_from_title,
        m.get_action_config_from_keys,
    }
    params.override_function = nil
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

---@param dismiss_keys string[]
---@return fun(key: string): boolean
local function filter_valid(dismiss_keys)
    return function(key) return not vim.tbl_contains(dismiss_keys, key) end
end

---Generate n-letter permutations given a list of letters
---@param letters string[]
---@param n integer
---@return string[]
local function generate_permutations(letters, n)
    local permutations = {}

    -- Helper function to generate permutations recursively
    local function permute(current, remaining)
        if #current == n then
            table.insert(permutations, current)
            return
        end
        for i = 1, #remaining do
            ---@type string
            local nextCurrent = current .. remaining[i]
            local nextRemaining = {}
            for j = 1, #remaining do
                if i ~= j then table.insert(nextRemaining, remaining[j]) end
            end
            permute(nextCurrent, nextRemaining)
        end
    end
    permute('', letters)
    return permutations
end

function M.generate_keys(item_count, dismiss_keys)
    local chars = 1

    local valid_keys = vim.tbl_filter(filter_valid, dismiss_keys)
    while #valid_keys < item_count do
        chars = chars + 1
        valid_keys = generate_permutations(valid_keys, chars)
    end
    return valid_keys
end

---@param keys string[]
---@return string[]
function M.filter_alpha_keys(keys)
    local function is_alpha(k) return k:match '[a-z]+' end
    return vim.tbl_filter(is_alpha, keys)
end

return M
