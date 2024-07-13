local M = {}

---@return CodeAction[] | nil
local request_code_action = function(params)
	---@type table<integer, {result: lsp.CodeAction[], error: lsp.ResponseError? }>?, string?
	local results_lsp, err = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 10000)
	if err then
		return vim.notify("ERROR: " .. err, vim.log.levels.ERROR)
	end
	if not results_lsp or vim.tbl_isempty(results_lsp) then
		return vim.notify("No results from textDocument/codeAction", vim.log.levels.INFO)
	end
	local commands = {}
	for client_id, response in pairs(results_lsp) do
		if response.result then
			local client = vim.lsp.get_client_by_id(client_id)
			for _, result in pairs(response.result) do
				---@class lsp.CodeAction
				---@field client_id integer
				---@field client_name string
				local res = result
				res.client_id = client_id
				res.client_name = client and client.name or ""
				table.insert(commands, result)
			end
		end
	end
	return commands
end

function M.code_action()
	M.bufnr = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(M.bufnr, lnum, {}, nil) }
	local params = vim.lsp.util.make_range_params()
	params.context = context
	return request_code_action(params)
end

function M.range_code_action()
	M.bufnr = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(M.bufnr, lnum, {}, nil) }
	local params = vim.lsp.util.make_given_range_params()
	params.context = context
	return request_code_action(params)
end

function M.execute_command(action)
	local offset_encoding = vim.lsp.get_client_by_id(action.client_id).offset_encoding
	if action.edit or type(action.command) == "table" then
		if action.edit then
			vim.lsp.util.apply_workspace_edit(action.edit, offset_encoding)
		end
		if type(action.command) == "table" then
			vim.lsp.buf.execute_command(action.command)
		end
	else
		vim.lsp.buf.execute_command(action)
	end
end

return M
