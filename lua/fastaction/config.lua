local M = {}
local m = {}

---@type FastActionConfig
m.defaults = {
    brackets = { '[', ']' },
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
    format_right_section = nil,
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

---@param priority Priority
---@param check_lsp? boolean
---@return ActionConfig[]
function M.get_priorities(priority, check_lsp)
    if not priority then return {} end
    local ft_priorities = priority[vim.bo.filetype]
    vim.list_extend(ft_priorities or {}, priority.default or {})
    if not check_lsp then return ft_priorities end
    local clients = vim.lsp.get_clients { bufnr = 0 }
    local lsps = m.map(clients, function(client) return client.name end)
    local lsp_priorities = m.map(lsps, function(p) return priority[p] end)
    return vim.list_extend(ft_priorities or {}, lsp_priorities or {})
end

---@generic K, V, R
---@param tbl table<K, V>
---@param f fun(value: V): R
---@return table<K, R>
function m.map(tbl, f)
    if not tbl then return {} end
    local t = {}
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(tbl) do
        ---@diagnostic disable-next-line: no-unknown
        t[k] = f(v)
    end
    return t
end

return M
