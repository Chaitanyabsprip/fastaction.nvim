local M = {}
local m = {}

---@param params GetActionConfigParams
---@return ActionConfig | nil
function m.get_action_config_from_title(params)
    if params.title == nil or params.title == '' then return nil end
    local index = 1
    local increment = params.chars
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

return M
