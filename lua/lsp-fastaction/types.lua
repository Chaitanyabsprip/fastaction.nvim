
---@class CodeAction: lsp.CodeAction
---@field client_id integer
---@field client_name string

---@class ActionConfig
---@field pattern string
---@field key string
---@field order? integer

---@class WindowOpts
---@field title? string
---@field divider? string
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

---@class FastActionConfig
---This configures options for the popup used by code action popup as well as
---the select popup.
---@field popup? PopupConfig
---@field priority? table<string, ActionConfig[]>

---@class PopupConfig
---@field title? string
---@field relative? string
---@field border? string | string[]
---@field hide_cursor? boolean
---@field highlight? table<string, string>
---@field dismiss_keys? string[]
