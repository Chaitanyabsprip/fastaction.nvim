
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
---Configures options for the code action and select popups.
---@field popup? PopupConfig
---Specifies the priority and keys to map to patterns matching code actions.
---@field priority? table<string, ActionConfig[]>
---Determines if the select popup should be registered as a `vim.ui.select` handler.
---@field register_ui_select? boolean
---Keys to use to map options.
---@field keys? string[] | string
---Keys to use to dismiss the popup.
---@field dismiss_keys? string[]

---@class PopupConfig
---Title of the popup.
---@field title? string
---Specifies what the popup is relative to.
---@field relative? string
---Style of the popup border. Can be "single", "double", "rounded", "thick", or
---a table of strings in the format
---{"top left", "top", "top right", "right", "bottom right", "bottom", "bottom left", "left"}.
---@field border? string | string[]
---Whether to hide the cursor when the popup is shown.
---@field hide_cursor? boolean
---Configures the highlights of different aspects of the popup.
---@field highlight? table<string, string>
