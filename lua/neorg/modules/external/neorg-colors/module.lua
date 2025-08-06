
local neorg = require "neorg.core"

local module = neorg.modules.create "external.neorg-colors"


local api = vim.api

module.config.public = {
  color_name = "ncolor:",
  end_name = "nend_color",

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

  get_colors_from_coloring = function(coloring)
    if #coloring ~= 4 then
      vim.error "entered coloring len is not 4"
      return nil
    end
    local color = coloring[1] and coloring[2] or ""
    local highlight = coloring[3] and coloring[4] or ""
    return { color, highlight }
  end,

  -- a function made to color a hole line
  color_line = function(colors, buf, line_num, ns_id)
    -- colors structure:
    -- {
    -- color , highlight color
    -- }
    -- both MUST be strings (if it shouldnt color it needs to be empty)
    -- you shouldnt worry bout that if your using the dedicated function get_colors_from_coloring
    -- create a spetial highlight for each color
    local highlight_name = "NeorgColorsFG." .. tostring(colors[1]) .. "BG." .. tostring(colors[2])
    local opts = {}

    -- setting the fg color
    if colors[1] ~= "" then
      opts.fg = "#" .. colors[1]
    end

    -- setting bg color
    if colors[2] ~= "" then
      opts.bg = "#" .. colors[2]
    end

    api.nvim_set_hl(0, highlight_name, opts)

    -- set the highlight on the current buffer
    vim.hl.range(buf, ns_id, highlight_name, { line_num - 1, 0 }, { line_num - 1, -1 })
  end,

  -- a function that colors a part of the txt
  color_in_line = function(colors, buf, line_num, start_offset, end_offset, ns_id)
    -- colors structure:
    -- {
    -- color , highlight color
    -- }
    -- both MUST be strings (if it shouldnt color it needs to be empty)
    -- you shouldnt worry bout that if your using the dedicated function get_colors_from_coloring
    if not line_num or not buf or not colors then
      return false
    end

    -- find the text in the line so we can color&highlight until the text is found
    -- if not found the text raise an error
    -- create a spetial highlight for each color

    local highlight_name = "NeorgColorsFG." .. tostring(colors[1]) .. "BG." .. tostring(colors[2])
    local opts = {}

    -- setting the fg color
    if colors[1] ~= "" then
      opts.fg = "#" .. colors[1]
    end

    -- setting bg color
    if colors[2] ~= "" then
      opts.bg = "#" .. colors[2]
    end

    api.nvim_set_hl(0, highlight_name, opts)

    -- set the highlight on the current buffer
    vim.hl.range(buf, ns_id, highlight_name, { line_num - 1, start_offset }, { line_num - 1, end_offset })
  end,

  -- a function that hides a word/part of a line
  conceal_on_line = function(buf, line_num, start_offset, end_offset, ns_id)
    --- concealing the word/s inside the start_offset and end_offset in line
    if not line_num or not buf then
      return false
    end

    start_offset = start_offset or 0
    end_offset = end_offset or 0

    -- hiding the specified area
    api.nvim_buf_set_extmark(buf, ns_id, line_num - 1, start_offset, {
      end_col = end_offset,
      conceal = "",
    })
  end,
  scan_line_and_update = function(buf, line, line_number, coloring, offset, continue, ns_id)
    -- NOTE: this is a recursive function, it will call itself in current line until it stopped coloring
    --       it will cut the line when it doesnt find a match
    --       returns: coloring

    -- some constants

    local COLOR_NAME = module.config.public.color_name
    COLOR_NAME = module.private.escape_lua_pattern(COLOR_NAME)
    local END_NAME = module.config.public.end_name
    END_NAME = module.private.escape_lua_pattern(END_NAME)

    -- it will be added to the next line recorsion
    local exta_col_len = 0

    -- case mach all current possibilities (see if they exsist)
    local start_coloring = string.match(line, COLOR_NAME .. "#(%x%x%x%x%x%x)")
    local start_highlighting = string.match(line, COLOR_NAME .. "[#%x%x%x%x%x%x]+,#(%x%x%x%x%x%x)")
    local end_coloring = string.match(line, END_NAME)
    if offset == 0 then
      api.nvim_buf_clear_namespace(buf, ns_id, line_number, line_number + 1)
    end

    -- set the line color if &color
    if start_coloring then
      exta_col_len = string.len(COLOR_NAME)

      -- set coloring = true and the color
      coloring[1] = true
      coloring[2] = start_coloring

      -- set highlight and set highlighting to true
      -- NOTE: color[3] and color[4] is for highlighing

      if start_highlighting then
        exta_col_len = exta_col_len + 8
        coloring[3] = true
        coloring[4] = start_highlighting
      else
        coloring[3] = false
        coloring[4] = ""
      end
      local color_start_idx, color_end_idx = string.find(line, COLOR_NAME, 0)

      -- conceal the &color property
      module.private.conceal_on_line(
        buf,
        line_number,
        color_start_idx + offset - 1,
        color_end_idx + offset + exta_col_len, -- color_end_idx is the last letter in the &color: property in the line
        -- offset is the offset that the line starts from
        -- exta_col_len is the added hex color to the &color
        ns_id
      )

      -- using recursion to fing the next string in line (yes.. i didnt belive it too, who knew? recursion has uses irl)
      local call_itself = function()
        return module.private.scan_line_and_update(
          buf,
          string.sub(line, color_end_idx + 0),
          line_number,
          coloring,
          offset + color_end_idx - 1,
          continue,
          ns_id
        )
        -- lookes like that:
        -- if i have a &color:#ffffff property
        -- offset will be now 11(length till the &color)+7(length of &color:) = 18
        -- and the text will look like that: ffffff property
      end

      -- if theres an &end_color tag in the future call the function again with the string cut till the end of the &color
      if end_coloring then
        -- find the &end_color property
        -- notify("found &end_color on line " .. line_number .. "," .. offset)
        local end_start_idx, end_end_idx = string.find(line, END_NAME, 0)

        module.private.color_in_line(
          module.private.get_colors_from_coloring(coloring),
          buf,
          line_number,
          color_end_idx + offset,
          offset + end_start_idx - 1,
          ns_id
        )
        return call_itself()
      else
        -- find the next &color to know where to start next
        local next_color_start_idx, next_color_end_idx = string.find(string.sub(line, color_end_idx + 0), COLOR_NAME, 0)
        if next_color_end_idx == nil or next_color_start_idx == nil then
          module.private.color_in_line(
            module.private.get_colors_from_coloring(coloring),
            buf,
            line_number,
            color_end_idx + offset,
            -1,
            ns_id
          )
          continue = true
          return call_itself()
        else
          -- color until next color

          module.private.color_in_line(
            module.private.get_colors_from_coloring(coloring),
            buf,
            line_number,
            color_end_idx + offset, -- starting from this color
            offset + next_color_end_idx, -- till the next color that has been found

            ns_id
          )
          continue = true
          return call_itself()
        end
      end
    elseif end_coloring then
      local start_idx, end_idx = string.find(line, END_NAME)

      module.private.conceal_on_line(
        buf,
        line_number,
        start_idx + offset - 1,
        end_idx + offset + exta_col_len, -- color_end_idx is the last letter in the &color: property in the line
        -- offset is the offset that the line starts from
        -- exta_col_len is the added hex color to the &color
        ns_id
      )
      coloring[1] = false
      coloring[2] = "000000"
      if start_coloring then
        -- if it needs coloring it will color from the offset to the start of &end_color
        return module.private.scan_line_and_update(
          buf,
          string.sub(line, end_idx + 0),
          line_number,
          coloring,
          offset + end_idx
        )

      end
      -- if theres an &color: tag in the future call the function again with the string cut till the end of the &end_color
    else
      continue = true

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
    return continue, coloring
  end,

  scan_lines_and_update = function(buf, ns_id)
    -- Get the lines in the buffer
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local coloring = {
      false, "ffffff",       -- text color
      false, "000000"        -- highlight color

    }
    local continue = false
    -- Iterate over each line
    for line_number, line in ipairs(lines) do
      -- if the line does not contain the all other color properties remove its namespace
      -- NOTE: i think this can conflict with other plugins
      -- mabe i need to try and find another solution
      continue, coloring = module.private.scan_line_and_update(buf, line, line_number, coloring, 0, continue, ns_id)
      if coloring[1] then
        if continue then
          continue = false
        else
          module.private.color_line(module.private.get_colors_from_coloring(coloring), buf, line_number, ns_id)
        end
      end
    end

  end,

}

module.load = function()
  -- Get the current buffer
  local buf = api.nvim_get_current_buf()
  -- create the ns_id
  local ns_id = api.nvim_create_namespace("neorg-color")
  -- update the buffer on entering a new page
  api.nvim_create_autocmd({"BufEnter", "BufNew", "TextChanged", "TextChangedI" }, {
    pattern = { "*.norg" },
    callback = function()
      buf = api.nvim_get_current_buf()
      module.private.scan_lines_and_update(buf, ns_id)
    end,
  })
end

return module
