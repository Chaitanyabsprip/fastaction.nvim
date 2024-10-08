local M = {}
local m = {}

---@type FastActionConfig
m.defaults = {
    dismiss_keys = { 'j', 'k', '<c-c>', 'q' },
    keys = 'fjdkslaghrueiwocnxvbmztyqp',
    override_function = function(_) end,
    popup = {
        border = 'rounded',
        hide_cursor = true,
        highlight = {
            divider = 'FloatBorder',
            key = 'MoreMsg',
            title = 'Title',
            window = 'NormalFloat',
        },
        title = 'Select one of:',
    },
    priority = { default = {} },
    register_ui_select = false,
    fallback_threshold = 26,
}

---@type FastActionConfig
m.config = {}

---@param opts FastActionConfig
function M.resolve(opts) m.config = vim.tbl_deep_extend('force', m.defaults, opts) end

---@return FastActionConfig
function M.get() return m.config end

---@param filetype string
---@return string[]
function M.get_prioritised_keys(filetype)
    local priorities = m.config.priority[filetype]
    if not priorities then return {} end
    ---@type string[]
    local keys = {}
    for _, v in ipairs(priorities) do
        keys[#keys + 1] = v.key
    end
    return keys
end

---@return string[]
function M.get_configured_keys()
    ---@type string[]
    local keys
    if type(m.config.keys) == 'table' then
        keys = m.config.keys --[=[@as string[]]=]
    elseif type(m.config.keys) == 'string' then
        keys = vim.split(m.config.keys --[=[@as string]=], '', { trimempty = true })
    end
    return keys
end

return M
