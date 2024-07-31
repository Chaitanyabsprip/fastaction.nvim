local M = {}

---Generate n-letter permutations given a list of letters
---@param letters string[]
---@param n integer
---@return string[]
function M.generatePermutations(letters, n)
    local permutations = {}

    -- Helper function to generate permutations recursively
    local function permute(current, remaining)
        if #current == n then
            table.insert(permutations, current)
            return
        end
        for i = 1, #remaining do
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

return M
