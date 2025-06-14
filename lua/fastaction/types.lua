---@class GetActionConfigParams
---@field title string
---@field invalid_keys string[]
---@field override_function? fun(params: GetActionConfigParams): ActionConfig | nil
---@field valid_keys? string[]
---@field kind? string

---@class GetPriorityActionConfigParams: GetActionConfigParams
---@field priorities ActionConfig[]

---@class CodeAction: lsp.CodeAction
---@field client_id integer
---@field client_name string

---@class ActionConfig
---@field pattern string
---@field key string
---@field order integer

---@class PopupLineSection
---@field text string
---@field highlight? string

---@alias PopupLine PopupLineSection[]

---@class WindowOpts
---@field title? string | boolean
---@field divider? string
---@field border? string | table
---@field window_hl? string
---@field x_offset? integer
---@field y_offset? integer
---@field dismiss_keys? string[]
---@field highlight table<string, string>
---@field relative? string
---@field hide_cursor? boolean

---@class Option
---@field name string
---@field key string
---@field item any
---@field order integer
---@field right_section string
---@field char_count integer

---@class SelectOpts
---@field prompt? string
---@field relative? boolean
---@field format_item? fun(item: any): string
---@field kind? string

---@class GetActionConfigsOpts
---@field kind? string
---@field priorities GetPriorityActionConfigParams
---@field format_item? fun(item: any): string
---@field valid_keys string[]
---@field used_keys string[]

---@class FastActionConfig
---Configures options for the code action and select popups.
---@field popup? PopupConfig
---Specifies the priority and keys to map to patterns matching code actions.
---@field priority? Priority
---Determines if the select popup should be registered as a `vim.ui.select` handler.
---@field register_ui_select? boolean
---Keys to use to map options.
---@field keys? string[] | string
---Keys to use to dismiss the popup.
---@field dismiss_keys? string[]
---Override function to map keys to actions.
---@field override_function? fun(params: GetActionConfigParams): ActionConfig | nil
---Configures number of options after which fastaction must fallback on
---`vim.ui.select`
---@field fallback_threshold? integer
---@field format_right_section? fun(item: LspCodeActionItem): string
---@field brackets? table<string, string>

---@class PopupConfig
---Title of the popup.
---@field title? string | boolean
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
---Configures the horizontal position of the popup with respect to the relative value.
---@field x_offset? integer | fun(width: integer): integer
---Configures the vertical position of the popup with respect to the relative value.
---@field y_offset? integer | fun(height: integer): integer

---@alias Priority table<string, ActionConfig[]>
