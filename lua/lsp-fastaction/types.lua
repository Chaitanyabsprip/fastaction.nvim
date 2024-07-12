
---@class CodeAction: lsp.CodeAction
---@field client_id integer
---@field client_name string

---@class ActionConfig
---@field pattern string
---@field key string
---@field order integer

---@class WindowOpts
---@field title? string
---@field divider? string
---@field width? integer
---@field height? integer
---@field border? string | table
---@field window_hl? string
---@field x_offset? integer
---@field y_offset? integer
---@field dismiss_keys? string[]
---@field highlight table<string, string>
---@field relative? string
---@field hide_cursor? boolean

---@class SelectOpts
---@field prompt? string
---@field format_item? fun(item: any): string
---@field kind? string
