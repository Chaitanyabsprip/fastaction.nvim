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
M.get_key = function(name, key_not_valid, key_valid)
	local index = 1
	key_valid = key_valid or keys
	name = string.lower(name)
	repeat
		local char = name:sub(index, index)
		if char:match("[a-z]") and not vim.tbl_contains(key_not_valid, char) then
			return char
		end
		index = index + 1
	until index >= #name

	for _, k in pairs(key_valid) do
		if not vim.tbl_contains(key_not_valid, k) then
			return k
		end
	end
	return nil
end

return M
