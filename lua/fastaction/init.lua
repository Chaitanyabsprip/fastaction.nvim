local M = {}
local m = {}
local lsp = require("fastaction.lsp")
local window = require("fastaction.window")
local keys = require("fastaction.keys")

m.config = {}
---@type FastActionConfig
m.defaults = {
	popup = {
		dismiss_keys = { "j", "k", "<c-c>", "q" },
		border = "rounded",
		hide_cursor = true,
		highlight = {
			divider = "FloatBorder",
			key = "MoreMsg",
			title = "Title",
			window = "NormalFloat",
		},
		title = "Select one of:",
	},
	priority = {},
	register_ui_select = false,
}

function M.code_action()
	local code_actions = lsp.code_action()
	if code_actions == nil or vim.tbl_isempty(code_actions) then
		return vim.notify("No code actions available", vim.log.levels.INFO)
	end
	M.select(code_actions, {
		prompt = "Code Actions:",
		format_item = function(item)
			return item.title
		end,
		relative = "cursor",
	}, lsp.execute_command)
end

function M.range_code_action()
	local code_actions = lsp.range_code_action()
	if code_actions == nil or vim.tbl_isempty(code_actions) then
		return vim.notify("No code actions available", vim.log.levels.WARN)
	end
	local opts = {
		prompt = "Code Actions:",
		format_item = function(item)
			return item.title
		end,
		relative = "cursor",
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
	local used_keys = {}
	---@type {name: string, key: string, item: any, order: integer}[]}
	local options = {}

	---@type string[]
	local content = {}

	for i, item in ipairs(items) do
		local option = { item = item, order = 0, name = opts.format_item(item) }

		local match = keys.get_action_key(option.name, m.config.priority or {}, used_keys)
		if match then
			option.key = match.key
			option.order = match.order
		else
			option.key = keys.get_key(option.name, used_keys)
		end
		options[i] = option
		content[i] = string.format("[%s] %s", option.key, option.name)
	end

	table.sort(options, function(a, b)
		return a.order < b.order
	end)

	---@param buffer integer
	local function setup_keymaps(buffer)
		local kopts = { buffer = buffer, noremap = true, silent = true, nowait = true }
		for i, option in ipairs(options) do
			vim.keymap.set("n", option.key, function()
				on_choice(option.item, i)
				window.popup_close()
			end, kopts)
		end
	end

	---@type WindowOpts | SelectOpts
	local winopts = vim.tbl_extend("keep", opts, m.config.popup)
	winopts.relative = opts["relative"] or "editor"
	window.popup_window(content, setup_keymaps, winopts)
end

---@param opts FastActionConfig
function M.setup(opts)
	m.config = vim.tbl_extend("force", m.defaults, opts)
	if m.config.register_ui_select then
		vim.ui.select = M.select
	end
end

return M
