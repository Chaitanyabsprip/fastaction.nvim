local M = {}

local keys = {
	"q",
	"w",
	"e",
	"r",
	"t",
	"y",
	"u",
	"i",
	"o",
	"p",
	"a",
	"s",
	"d",
	"f",
	"g",
	"h",
	"l",
	"z",
	"x",
	"c",
	"v",
	"b",
	"n",
	"m",
}

--- this function will create a key from name
--- if a key_is exist on key_used then it will go to next character
--- in name
---@param name string
---@param invalid_keys string[]
---@param valid_keys? string[]
---@return string?
M.get_key = function(name, invalid_keys, valid_keys)
	local index = 1
	valid_keys = valid_keys or keys
	name = string.lower(name)
	repeat
		local char = name:sub(index, index)
		if char:match("[a-z]") and not vim.tbl_contains(invalid_keys, char) then
			invalid_keys[#invalid_keys + 1] = char
			return char
		end
		index = index + 1
	until index >= #name

	for _, k in pairs(valid_keys) do
		if not vim.tbl_contains(invalid_keys, k) then
			return k
		end
	end
	return nil
end

---@param title string
---@param config ActionConfig[]
---@param invalid_keys string[]
---@return ActionConfig | nil
function M.get_action_key(title, config, invalid_keys)
	for _, value in pairs(config) do
		if not vim.tbl_contains(invalid_keys, value.key) and title:lower():match(value.pattern) then
			return value
		end
	end
end

return M
