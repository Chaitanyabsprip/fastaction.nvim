local M = {}
local m = {}

---@param allowed_key_count integer
---@param item_count integer
---@@return integer
function M.calculate_min_keymap_length(allowed_key_count, item_count)
    local length = 1
    while m.permutations(allowed_key_count, length) < item_count do
        length = length + 1
    end
    return length
end

---@param keys string[]
---@return string[]
function M.filter_alpha_keys(keys)
    local function is_alpha(k) return k:match '^[a-z]+$' end
    return vim.tbl_filter(is_alpha, keys)
end

---@param n integer
---@return integer
function m.factorial(n)
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
function m.permutations(k, p)
    if p > k then return 0 end
    return m.factorial(k) / m.factorial(k - p)
end

return M
