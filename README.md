# FastAction.nvim

FastAction.nvim is a sleek, efficiency plugin designed to optimize code actions
in Neovim. By leveraging Neovim's built-in LSP capabilities, it offers a simple
and intuitive interface that enhances your coding experience.

## Features

- **Popup Interface**: Display code actions in a customizable popup window.
- **Keybindings**: Configure keys to quickly dismiss or select code actions,
  making your workflow more efficient.
- **Priority Handling**: Customize the display order of actions based on
  priority, ensuring the most used actions are always visible on top.
- **Flexible Selection**: Extendable selection prompt that can replace Neovim's
  built-in `vim.ui.select`, providing more versatility in how you interact with lists

## Installation

Using `lazy.nvim`

```lua
  {
      'Chaitanyabsprip/fastaction.nvim',
      ---@type FastActionConfig
      opts = {},
  }
```

## Configuration

**fastaction.nvim** comes with sensible defaults to get you started quickly:

```lua
{
  dismiss_keys = { "j", "k", "<c-c>", "q" },
  override_function = function(_) end,
  keys = "qwertyuiopasdfghlzxcvbnm",
  popup = {
    border = "rounded",
    hide_cursor = true,
    highlight = {
      divider = "FloatBorder",
      key = "MoreMsg",
      title = "Title",
      window = "NormalFloat",
    },
    title = "Select one of:",
  },
  priority = {
    -- dart = {
    --   { pattern = "organize import", key ="o", order = 1 },
    --   { pattern = "extract method", key ="x", order = 2 },
    --   { pattern = "extract widget", key ="e", order = 3 },
    -- },
  },
 register_ui_select = false,
}
```

The order key in the priority table determines the position of that match in the
code actions selection prompt. Lower number means higher up in the prompt.

<details>
<summary>Example Configuration</summary>

```lua
{
  dismiss_keys = { "j", "k", "<c-c>", "q" },
  override_function = function(params) -- to retain built-in style keymaps
      params.invalid_keys[#params.invalid_keys + 1] = tostring(#params.invalid_keys + 1)
      return { key = tostring(#params.invalid_keys), order = 0 }
  end,
  keys = "asdfghlzxcvbnm",
  popup = {
    border = "rounded",
    hide_cursor = true,
    highlight = {
      divider = "FloatBorder",
      key = "MoreMsg",
      title = "Title",
      window = "NormalFloat",
    },
    title = "Select one of:",
  },
  priority = {
    dart = {
      { pattern = "organize import", key ="o", order = 1 },
      { pattern = "extract method", key ="x", order = 2 },
      { pattern = "extract widget", key ="e", order = 3 },
    },
    typescript = {
      { pattern = 'to existing import declaration', key = 'a', order = 2 },
      { pattern = 'from module', key = 'i', order = 1 },
    }
  }
}
```

</details>

## Usage

**fastaction.nvim** exposes three function apart from setup.

- `code_action()`: Displays code actions in a popup window.
- `range_code_action()`: Displays code actions in a popup window for a visual range.
- `select(items: any, opts: SelectOpts, on_choice: fun(item: any))`: Displays a
  selection prompt window for items.

To integrate these functions with your LSP mappings, add the following to your configuration:

```lua
    vim.keymap.set(
        'n',
        '<leader>a',
        '<cmd>lua require("fastaction").code_action()<CR>',
        { buffer = bufnr }
    )
    vim.keymap.set(
        'v',
        '<leader>a',
        "<esc><cmd>lua require('fastaction').range_code_action()<CR>",
        { buffer = bufnr }
    )
```

You can also use `require('fastaction').select` as a replacement for `vim.ui.select`.

![code-action](https://github.com/user-attachments/assets/18aadd07-73fe-4d62-885e-b5e4d3a4bfc4)

## How it works

**fastaction.nvim** enhances the selection process by assigning key mappings to each
option in the selection prompt. Here's how it achieves this:

### Intelligent key mapping

For each option, the plugin selects a key mapping based on the priority
configuration. If no priority is set, it falls back to using the letters in the
option's title. For example, if the option is "organize imports," the plugin
first checks if the 'o' key is available. If 'o' is taken, it moves to the next
letter, 'r,' and so on, until it finds an available key
The code_action and range_code_action functions are essentially using the
stylised prompt to choose from the code actions.

### Streamlined Code Actions

The code_action and range_code_action functions utilize this intelligent prompt
to display and select from the available code actions efficiently. By leveraging
this stylized prompt, FastAction.nvim ensures a smoother and more intuitive
selection process, making your coding experience more fluid and enjoyable.

## Credit

This repository is a fork of
[nvim-pack/lsp-fastaction.nvim](https://github.com/nvim-pack/lsp-fastaction.nvim)
building on its foundations to provide an even more streamlined and efficient experience.
