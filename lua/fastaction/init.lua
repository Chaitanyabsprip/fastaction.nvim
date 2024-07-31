local M = {}
local m = {}
local lsp = require 'fastaction.lsp'
local window = require 'fastaction.window'
local keys = require 'fastaction.keys'
local util = require 'fastaction.util'

m.config = {}
---@type string[]
m.keys = {}
---@type FastActionConfig
m.defaults = {
    dismiss_keys = { 'j', 'k', '<c-c>', 'q' },
    keys = 'qwertyuiopasdfghlzxcvbnm',
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
    priority = {},
    register_ui_select = false,
}

--- Show a selection prompt with the code actions available for the cursor
--- position.
function M.code_action()
    local code_actions = lsp.code_action()
    if code_actions == nil or vim.tbl_isempty(code_actions) then
        return vim.notify('No code actions available', vim.log.levels.INFO)
    end
    M.select(code_actions, {
        prompt = 'Code Actions:',
        format_item = function(item) return item.title end,
        relative = 'cursor',
    }, lsp.execute_command)
end

--- Show a selection prompt with the code actions available for the visual
--- selection range.
function M.range_code_action()
    local code_actions = lsp.range_code_action()
    if code_actions == nil or vim.tbl_isempty(code_actions) then
        return vim.notify('No code actions available', vim.log.levels.WARN)
    end
    local opts = {
        prompt = 'Code Actions:',
        format_item = function(item) return item.title end,
        relative = 'cursor',
    }
    M.select(code_actions, opts, lsp.execute_command)
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
    opts.format_item = opts.format_item or tostring
    local used_keys = vim.tbl_extend('force', {}, m.config.dismiss_keys)
    ---@type {name: string, key: string, item: any, order: integer}[]}
    local options = {}

    ---@type string[]
    local content = {}

    local chars = 1

    local valid_keys = vim.tbl_filter(
        function(key) return not vim.list_contains(m.config.dismiss_keys, key) end,
        m.keys
    )
    while #valid_keys < #items do
        chars = chars + 1
        valid_keys = util.generatePermutations(valid_keys, chars)
    end
    for i, item in ipairs(items) do
        local option = { item = item, order = 0, name = opts.format_item(item) }
        local match = assert(
            keys.get_action_config {
                title = option.name,
                priorities = m.config.priority[vim.bo.filetype],
                valid_keys = valid_keys,
                invalid_keys = used_keys,
                override_function = m.config.override_function,
                chars = chars,
            },
            'Failed to find a key to map to "' .. option.name .. '"'
        )
        option.key = match.key
        option.order = match.order
        options[i] = option
        content[i] = string.format('[%s] %s', option.key, option.name)
    end

    table.sort(options, function(a, b) return a.order < b.order end)

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
    local winopts = vim.tbl_deep_extend('keep', opts, m.config.popup)
    winopts.relative = opts['relative'] or winopts.relative or 'editor'
    winopts.dismiss_keys = m.config.dismiss_keys
    winopts.chars = chars
    window.popup_window(content, setup_keymaps, winopts)
end

---@param opts FastActionConfig
function M.setup(opts)
    m.config = vim.tbl_deep_extend('force', m.defaults, opts)
    if m.config.register_ui_select then vim.ui.select = M.select end
    if type(m.config.keys) == 'table' then
        m.keys = m.config.keys --[=[@as string[]]=]
    elseif type(m.config.keys) == 'string' then
        m.keys = vim.split(m.config.keys --[=[@as string]=], '', { trimempty = true })
    end
end

return M
