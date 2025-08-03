local M = {}

-- Function to get the language of the code block under cursor
local function get_code_block_language_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-based indexing
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find the code block boundaries
  local start_row, end_row, language = nil, nil, nil

  -- Look backwards for opening fence
  for i = row, 0, -1 do
    local line = lines[i + 1] -- Convert back to 1-based for table access
    if line and line:match("^```") then
      start_row = i
      language = line:match("^```(.*)"):gsub("%s+", "")
      if language == "" then language = nil end
      break
    end
  end

  -- Look forwards for closing fence
  if start_row then
    for i = start_row + 1, #lines - 1 do
      local line = lines[i + 1]
      if line and line:match("^```%s*$") then
        end_row = i
        break
      end
    end
  end

  if start_row and end_row and language then
    -- Return the content lines (excluding the fences)
    -- start_row is the opening ```, so content starts at start_row + 1
    -- end_row is the closing ```, so content ends at end_row - 1
    return language, start_row + 2, end_row -- Convert to 1-based, content only
  end

  return nil, nil, nil
end

-- Create scratch buffer that syncs back to original markdown
M.edit_code_block_in_scratch = function()
  local language, start_line, end_line = get_code_block_language_under_cursor()

  if not language or not start_line or not end_line then
    print("Not in a code block or language not specified")
    return
  end

  -- Get the code block content (excluding the fence lines)
  local original_bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(original_bufnr, start_line - 1, end_line, false)

  -- Create a new scratch buffer with the right filetype
  vim.cmd("new")
  local scratch_bufnr = vim.api.nvim_get_current_buf()
  vim.bo[scratch_bufnr].filetype = language
  vim.bo[scratch_bufnr].buftype = "nofile"
  vim.bo[scratch_bufnr].bufhidden = "wipe"

  -- Mark this buffer as a markdown code block scratch buffer
  vim.b[scratch_bufnr].is_markdown_code_scratch = true
  vim.b[scratch_bufnr].markdown_original_bufnr = original_bufnr
  vim.b[scratch_bufnr].markdown_start_line = start_line
  vim.b[scratch_bufnr].markdown_end_line = end_line

  -- Set the content
  vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, lines)

  -- Create unique autocmd group for this specific buffer
  local group_name = "MarkdownCodeBlockSync_" .. scratch_bufnr
  local group = vim.api.nvim_create_augroup(group_name, { clear = true })

  -- Function to sync changes back
  local function sync_to_original()
    if vim.api.nvim_buf_is_valid(original_bufnr) then
      local updated_lines = vim.api.nvim_buf_get_lines(scratch_bufnr, 0, -1, false)
      vim.api.nvim_buf_set_lines(original_bufnr, start_line - 1, end_line, false, updated_lines)
    end
  end

  -- Remove auto-sync on text changes to prevent cascade
  -- Only sync when buffer is closed or manually requested

  -- Sync and cleanup when scratch buffer is closed
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete", "BufUnload" }, {
    buffer = scratch_bufnr,
    group = group,
    callback = function()
      -- Only handle if this is our markdown code scratch buffer
      if vim.b[scratch_bufnr].is_markdown_code_scratch then
        sync_to_original()
        vim.api.nvim_del_augroup_by_id(group)
      end
    end
  })

  -- Add a command to manually sync and close
  vim.api.nvim_buf_create_user_command(scratch_bufnr, "FinishEdit", function()
    vim.cmd("close") -- This will trigger the sync via the autocmd
  end, { desc = "Finish editing and close (syncs automatically)" })

  -- Add a command to manually sync without closing
  vim.api.nvim_buf_create_user_command(scratch_bufnr, "SyncBack", function()
    sync_to_original()
    print("Synced changes back to markdown file")
  end, { desc = "Sync changes back to original markdown file" })

  print("Opened code block in scratch buffer. Use :SyncBack to sync manually, or close buffer to auto-sync.")
end

M.setup = function()
  -- Editing code in a scratch buffer
  vim.api.nvim_create_user_command('EditCodeBlock', M.edit_code_block_in_scratch,
    { desc = "Edit code block in scratch buffer with LSP" })
end

return M
