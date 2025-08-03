# nvim-markdown-codeblocks

A Neovim plugin for editing markdown code blocks in scratch buffers, with auto-sync back to the original markdown file.

## Features

- Opens markdown code blocks in a scratch buffer for isolated editing
- Auto-syncs changes to the original markdown on buffer close or with a command
- Sets correct filetype for the scratch buffer (enables LSP, etc.)
- Manual sync and finish commands: `:SyncBack` and `:FinishEdit`
- Only acts on code blocks under the cursor with a specified language

## Installation

Using [lazy.nvim]:

```lua
{
  'xpcoffee/nvim-markdown-codeblocks',
  config = function()
    require('nvim-markdown-codeblocks').setup()
  end,
}
```

## Usage

Place your cursor inside a markdown code block with a language fence (e.g., ```lua). Then run:

```
:EditCodeBlock
```

This opens the block in a scratch buffer. You can:

- Use `:SyncBack` to manually sync changes to your markdown file
- Use `:FinishEdit` (or simply close the buffer) to sync and finish editing
