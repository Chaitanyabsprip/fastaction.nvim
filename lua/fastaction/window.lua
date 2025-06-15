local M = {}
local m = {}

m.namespace = vim.api.nvim_create_namespace 'windmenu'
m.window_border_chars_thick = {
    { '▛', 'FloatBorder' },
    { '▀', 'FloatBorder' },
    { '▜', 'FloatBorder' },
    { '▐', 'FloatBorder' },
    { '▟', 'FloatBorder' },
    { '▄', 'FloatBorder' },
    { '▙', 'FloatBorder' },
    { '▌', 'FloatBorder' },
}

m.cursor_hl_grp = 'FastActionHiddenCursor'
m.guicursor = vim.o.guicursor

-- Hide cursor whilst menu is open
function M.hide_cursor()
    if vim.o.termguicolors and vim.o.guicursor ~= '' then
        local fmt = string.format
        if vim.fn.hlexists(m.cursor_hl_grp) == 0 then
            vim.cmd(fmt('highlight %s gui=reverse blend=100', m.cursor_hl_grp))
        end
        vim.o.guicursor = fmt('a:%s/lCursor', m.cursor_hl_grp)
    end
end

function M.restore_cursor() vim.o.guicursor = m.guicursor end

function M.popup_close()
    M.restore_cursor()
    pcall(vim.api.nvim_win_close, vim.api.nvim_get_current_win(), true)
end

---@param height integer
---@param width integer
---@param opts WindowOpts | SelectOpts
function m.make_winopts(height, width, opts)
    vim.validate { opts = { opts, 't', true } }
    opts = opts or {}
    local lines_above = vim.fn.winline() - 1
    local lines_below = vim.fn.winheight(0) - lines_above
    ---@type integer
    local maxcols = vim.api.nvim_get_option_value('columns', {})

    local isTopHalf = lines_above < lines_below
    local isLeftHalf = vim.fn.wincol() + width <= maxcols

    local x_offset, y_offset = m.get_offsets(opts.x_offset, opts.y_offset, opts.relative)
    local col = (x_offset or 0) + (isLeftHalf and 1 or 0)
    local row = (y_offset or 0) + (isTopHalf and 1 or -1)
    if opts.relative == 'editor' then
        col = maxcols - (x_offset or 0)
        row = y_offset or 0
    end
    return {
        col = col,
        height = height or 1,
        relative = opts.relative or 'cursor',
        row = row,
        style = 'minimal',
        width = width,
    }
end

---@param x_offset integer | fun(width: integer): integer
---@param y_offset integer | fun(height: integer): integer
---@param relative 'editor' | 'cursor' | 'win' | 'mouse'
---@return integer | nil, integer | nil
function m.get_offsets(x_offset, y_offset, relative)
    vim.validate {
        ['opts.x_offset'] = { x_offset, { 'n', 'f' }, true },
        ['opts.y_offset'] = { y_offset, { 'n', 'f' }, true },
    }
    ---@type integer, integer
    local width, height
    if relative == 'editor' then
        width = vim.api.nvim_get_option_value('columns', {})
        height = vim.api.nvim_get_option_value('lines', {})
    elseif relative == 'win' then
        width = vim.api.nvim_win_get_width(0)
        height = vim.api.nvim_win_get_height(0)
    else
        return nil, nil
    end

    if type(x_offset) == 'function' then x_offset = x_offset(width) end
    if type(y_offset) == 'function' then y_offset = y_offset(height) end
    return x_offset, y_offset
end

---@param content PopupLine[]
---@param on_buf_create fun(buffer: integer) | nil
---@param opts WindowOpts | SelectOpts
---@return integer, integer
function M.popup_window(content, on_buf_create, opts)
    vim.validate {
        content = { content, 't' },
        on_buf_create = { on_buf_create, 'f' },
        opts = { opts, 't', true },
    }
    opts = opts or {}
    if opts.border == 'thick' then opts.border = m.window_border_chars_thick end

    ---@param line PopupLine
    ---@return string
    local function assemble_line(line)
        local combined = ''
        for _, part in ipairs(line) do
            combined = combined .. part.text
        end
        return combined
    end

    local width = 0
    for i, line in ipairs(content) do
        -- Clean up the input and add left pad.
        table.insert(line, 1, { text = ' ' })
        local line_str = assemble_line(line)
        local line_width = vim.fn.strdisplaywidth(line_str)
        width = math.max(line_width, width)
        content[i] = line
    end

    -- Add right padding of 1 each.
    width = width + 1
    opts.divider = opts.divider or '─'
    if opts.title ~= false then
        ---@type PopupLine[]
        content = vim.list_extend({
            ---@type PopupLine
            {
                { text = ' ' .. (opts.prompt or opts.title), highlight = opts.highlight.title },
            },
            ---@type PopupLine
            {
                { text = string.rep(opts.divider, width), highlight = opts.highlight.divider },
            },
        }, content)
    end

    ---@param lines PopupLine[]
    ---@return string[]
    local function assemble_content(lines)
        local combined = {}
        for i, line in ipairs(lines) do
            combined[i] = assemble_line(line)
        end
        return combined
    end

    ---@type string[]
    local assembled_content = assemble_content(content)

    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, true, assembled_content)
    vim.bo[buffer].filetype = 'fastaction_popup'
    vim.bo[buffer].buftype = 'nofile'

    for i, segments in ipairs(content) do
        local line = i - 1
        local from = 0
        for _, segment in ipairs(segments) do
            local to = from + #segment.text
            vim.api.nvim_buf_add_highlight(
                buffer,
                m.namespace,
                segment.highlight or 'Normal',
                line,
                from,
                to
            )
            from = to -- + 1
        end
    end

    vim.api.nvim_set_option_value('modifiable', false, { buf = buffer })

    for _, key in ipairs(opts.dismiss_keys) do
        vim.keymap.set(
            { 'n', 'v' },
            key,
            M.popup_close,
            { noremap = true, silent = true, buffer = buffer }
        )
    end
    if opts.hide_cursor then M.hide_cursor() end
    if on_buf_create ~= nil then on_buf_create(buffer) end

    local height = #content
    local winopts = m.make_winopts(height, width, opts)
    winopts.border = opts.border
    local win = vim.api.nvim_open_win(buffer, true, winopts)
    if opts.window_hl then
        vim.api.nvim_set_option_value('winhighlight', 'Normal:' .. opts.window_hl, { win = win })
    end

    vim.api.nvim_create_autocmd({ 'BufHidden', 'InsertCharPre', 'WinLeave', 'FocusLost' }, {
        group = vim.api.nvim_create_augroup('', { clear = true }),
        buffer = buffer,
        once = true,
        callback = M.popup_close,
    })
    return buffer, win
end

return M
