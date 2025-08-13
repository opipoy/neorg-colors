local neorg = require "neorg.core"

local module = neorg.modules.create "external.neorg-colors"

local api = vim.api

module.config.public = {
  color_name = "ncolor",
  end_name = "nend_color",
}

module.config.private = {
  COLOR_SEPARATOR = ":",
  COLOR_NAME = nil,
  END_NAME = nil,
}

module.private = {
  -- credit: @bucdany
  escape_lua_pattern = function(s)
    local matches = {
      ["^"] = "%^",
      ["$"] = "%$",
      ["("] = "%(",
      [")"] = "%)",
      ["%"] = "%%",
      ["."] = "%.",
      ["["] = "%[",
      ["]"] = "%]",
      ["*"] = "%*",
      ["+"] = "%+",
      ["-"] = "%-",
      ["?"] = "%?",
    }

    return (s:gsub(".", matches))
  end,

  init_color_patterns = function()
    module.config.private.COLOR_NAME = module.private.escape_lua_pattern(module.config.public.color_name)
      .. module.config.private.COLOR_SEPARATOR
    module.config.private.END_NAME = module.private.escape_lua_pattern(module.config.public.end_name)
  end,

  get_colors_from_coloring = function(coloring)
    if #coloring ~= 4 then
      vim.error "entered coloring len is not 4"
      return nil
    end

    local color = coloring[1] and coloring[2] or ""
    local highlight = coloring[3] and coloring[4] or ""

    return { color, highlight }
  end,

  -- A function created to color a whole line
  color_line = function(colors, buf, line_num, ns_id)
    -- colors structure:
    -- {
    -- color , highlight color
    -- }
    -- Both must be strings (leave empty if no color is needed).
    -- You shouldn’t worry about this if you’re using the dedicated function get_colors_from_coloring.
    -- Create a special highlight for each color.
    local highlight_name = "NeorgColorsFG." .. tostring(colors[1]) .. "BG." .. tostring(colors[2])
    local opts = {}

    -- Setting the foreground color
    if colors[1] ~= "" then
      opts.fg = "#" .. colors[1]
    end

    -- Setting the background color
    if colors[2] ~= "" then
      opts.bg = "#" .. colors[2]
    end

    api.nvim_set_hl(0, highlight_name, opts)

    -- Set the highlight on the current buffer
    vim.hl.range(buf, ns_id, highlight_name, { line_num - 1, 0 }, { line_num - 1, -1 })
  end,

  -- a function that colors a part of the txt
  color_in_line = function(colors, buf, line_num, start_offset, end_offset, ns_id)
    -- colors structure:
    -- {
    -- color , highlight color
    -- }
    -- Both must be strings (leave empty if no color is needed).
    -- You shouldn’t worry about this if you’re using the dedicated function get_colors_from_coloring.
    if not line_num or not buf or not colors then
      return false
    end

    -- Find the text in the line so we can color & highlight until the text is found.
    -- If the text is not found, raise an error.
    -- Create a special highlight for each color.

    local highlight_name = "NeorgColorsFG." .. tostring(colors[1]) .. "BG." .. tostring(colors[2])
    local opts = {}

    -- Create a special highlight for each color.
    if colors[1] ~= "" then
      opts.fg = "#" .. colors[1]
    end

    -- Setting the background color
    if colors[2] ~= "" then
      opts.bg = "#" .. colors[2]
    end

    api.nvim_set_hl(0, highlight_name, opts)

    -- Set the highlight on the current buffer
    vim.hl.range(buf, ns_id, highlight_name, { line_num - 1, start_offset }, { line_num - 1, end_offset })
  end,

  -- a function that hides a word/part of a line
  conceal_on_line = function(buf, line_num, start_offset, end_offset, ns_id)
    --- Concealing the word(s) between the start_offset and end_offset in the line
    if not line_num or not buf then
      return false
    end

    start_offset = start_offset or 0
    end_offset = end_offset or 0

    -- Hiding the specified area
    api.nvim_buf_set_extmark(buf, ns_id, line_num - 1, start_offset, {
      end_col = end_offset,
      conceal = "",
    })
  end,

  detect_color_tags = function(line, COLOR_NAME, END_NAME)
    -- Match all current possibilities (ensure they exist)
    local start_coloring = string.match(line, COLOR_NAME .. "#(%x%x%x%x%x%x)")
    local start_highlighting = string.match(line, COLOR_NAME .. "[#%x%x%x%x%x%x]+,#(%x%x%x%x%x%x)")
    local end_coloring = string.match(line, END_NAME)

    return start_coloring, start_highlighting, end_coloring
  end,

  process_start_color_tag = function(
    buf,
    line,
    line_number,
    coloring,
    offset,
    start_coloring,
    start_highlighting,
    COLOR_NAME,
    ns_id
  )
    local exta_col_len = string.len(COLOR_NAME)

    coloring[1] = true
    coloring[2] = start_coloring

    if start_highlighting then
      exta_col_len = exta_col_len + 8
      coloring[3] = true
      coloring[4] = start_highlighting
    else
      coloring[3] = false
      coloring[4] = ""
    end

    local color_start_idx, color_end_idx = string.find(line, COLOR_NAME, 0)

    -- Masquer le tag de couleur
    module.private.conceal_on_line(
      buf,
      line_number,
      color_start_idx + offset - 1,
      color_end_idx + offset + exta_col_len,
      ns_id
    )

    return color_end_idx
  end,

  process_end_color_tag = function(buf, line, line_number, coloring, offset, END_NAME, ns_id)
    local start_idx, end_idx = string.find(line, END_NAME)

    module.private.conceal_on_line(
      buf,
      line_number,
      start_idx + offset - 1,
      end_idx + offset, -- end_idx is the index of the last character in the &color: property on the line
      -- offset is the line’s starting offset
      -- exta_col_len is the length of the hex color appended to &color
      ns_id
    )

    -- Color until reaching &end_color
    if coloring[1] then
      module.private.color_in_line(
        module.private.get_colors_from_coloring(coloring),
        buf,
        line_number,
        offset,
        start_idx + offset - 1,
        ns_id
      )
    end

    coloring[1] = false
    coloring[2] = "000000"

    return end_idx
  end,

  handle_coloring_between_tags = function(
    buf,
    line,
    line_number,
    coloring,
    offset,
    color_end_idx,
    end_coloring,
    COLOR_NAME,
    ns_id
  )
    -- If there’s an &end_color tag ahead, call the function again with the substring up to the end of &color
    if end_coloring then
      -- Find the &end_color property
      -- notify("Found &end_color on line " .. line_number .. "," .. offset)
      local end_start_idx, _ = string.find(line, module.config.private.END_NAME, 0)

      module.private.color_in_line(
        module.private.get_colors_from_coloring(coloring),
        buf,
        line_number,
        color_end_idx + offset,
        offset + end_start_idx - 1,
        ns_id
      )
    else
      -- Find the next &color to determine where to start next
      local _, next_color_end_idx = string.find(string.sub(line, color_end_idx + 0), COLOR_NAME, 0)

      if not next_color_end_idx then
        module.private.color_in_line(
          module.private.get_colors_from_coloring(coloring),
          buf,
          line_number,
          color_end_idx + offset,
          -1,
          ns_id
        )
      else
        -- Color until the next color
        module.private.color_in_line(
          module.private.get_colors_from_coloring(coloring),
          buf,
          line_number,
          color_end_idx + offset, -- Starting from this color
          offset + next_color_end_idx, -- up to the next detected color
          ns_id
        )
      end
    end
  end,

  scan_line_and_update = function(buf, line, line_number, coloring, offset, ns_id)
    -- NOTE: This is a recursive function that calls itself repeatedly on the current line until coloring is complete
    --       It truncates the line when no match is found
    --       returns: coloring

    -- Several constants
    local COLOR_NAME = module.config.private.COLOR_NAME
    local END_NAME = module.config.private.END_NAME

    -- It will be added in the next recursion step for the line.
    local exta_col_len = 0

    local start_coloring, start_highlighting, end_coloring =
      module.private.detect_color_tags(line, COLOR_NAME, END_NAME)

    if offset == 0 then
      api.nvim_buf_clear_namespace(buf, ns_id, line_number, line_number + 1)
    end

    -- Using recursion to find the next string in the line (yeah… I didn’t believe it either — who knew recursion is useful IRL?)
    local call_itself = function(end_idx)
      return module.private.scan_line_and_update(
        buf,
        string.sub(line, end_idx + 0),
        line_number,
        coloring,
        offset + end_idx - 1,
        ns_id
      )
      -- Looks like this:
      -- If I have a &color:#ffffff property,
      -- offset will now be 11 (length up to &color) + 7 (length of &color:) = 18,
      -- and the text will look like this: ffffff property
    end

    -- Set the line color if &color is set.
    if start_coloring then
      local color_end_idx = module.private.process_start_color_tag(
        buf,
        line,
        line_number,
        coloring,
        offset,
        start_coloring,
        start_highlighting,
        COLOR_NAME,
        ns_id
      )

      module.private.handle_coloring_between_tags(
        buf,
        line,
        line_number,
        coloring,
        offset,
        color_end_idx,
        end_coloring,
        COLOR_NAME,
        ns_id
      )

      return call_itself(color_end_idx)
    elseif end_coloring then
      if start_coloring then
        local end_idx = module.private.process_end_color_tag(buf, line, line_number, coloring, offset, END_NAME, ns_id)
        -- If coloring is needed, color from the offset to the start of &end_color
        return call_itself(end_idx)
      end
      -- If there’s an &color: tag ahead, call the function again with the string cut until the end of &end_color.
    else
      if coloring[1] then
        module.private.color_in_line(
          module.private.get_colors_from_coloring(coloring),
          buf,
          line_number,
          offset,
          -1,
          ns_id
        )
      end
    end

    return coloring
  end,

  scan_lines_and_update = function(buf, ns_id)
    -- Get the lines in the buffer
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local coloring = {
      false,
      "ffffff", -- text color
      false,
      "000000", -- highlight color
    }

    -- Iterate over each line
    for line_number, line in ipairs(lines) do
      -- If the line doesn’t contain all the other color properties, remove its namespace.
      -- NOTE: This might conflict with other plugins. Maybe I should find another solution.
      coloring = module.private.scan_line_and_update(buf, line, line_number, coloring, 0, ns_id)

      if coloring[1] then
        module.private.color_line(module.private.get_colors_from_coloring(coloring), buf, line_number, ns_id)
      end
    end
  end,
}

module.load = function()
  local ns_id = api.nvim_create_namespace "neorg-colors-namespace"

  module.private.init_color_patterns()

  api.nvim_create_autocmd({ "BufEnter", "BufNew", "TextChanged", "TextChangedI" }, {
    pattern = { "*.norg" },
    callback = function()
      local buf = api.nvim_get_current_buf()
      module.private.scan_lines_and_update(buf, ns_id)
    end,
  })
end

return module
