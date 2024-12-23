local neorg = require('neorg.core')

local module = neorg.modules.create('external.neorg-colors')

module.config.public = {
        color_name = "&color:",
        end_name = "&end_color"
}

module.private = {

    color_line = function(color, buf, line_num)
        -- create a spetial highlight for each color
        vim.api.nvim_command('highlight ColorHighlightForColor-' .. tostring(color) .. ' guifg=#' .. color)
        -- set the highlight on the current buffer
        vim.api.nvim_buf_add_highlight(buf, -1, "ColorHighlightForColor-" .. tostring(color), line_num - 1, 0, -1)
    end,

    color_in_line = function(color, buf, line_num, start_offset, end_offset)
        -- find the text in the line so we can color until the text is found
        -- if not found the text raise an error
        -- create a spetial highlight for each color
        vim.api.nvim_command('highlight ColorHighlightForColor-' .. tostring(color) .. ' guifg=#' .. color)
        -- set the highlight on the current buffer
        vim.api.nvim_buf_add_highlight(buf, -1, "ColorHighlightForColor-" .. tostring(color), line_num - 1,
            start_offset, end_offset)
    end,

    conceal_on_line = function(what, buf, line_num, line_txt, offset, start_offset, ns_id)
        if not offset then
            offset = 0
        end
        if not start_offset then
            start_offset = 0
        end
        -- finding the &color property and adding the hex color itself
        local start_idx, end_idx = string.find(line_txt, what)
        -- concealing the &color property
        print(ns_id)
        vim.api.nvim_buf_set_extmark(buf, ns_id, line_num - 1,
            start_offset + start_idx-1,
            {
                end_line = line_num - 1,
                end_col = end_idx + offset + start_offset,
                conceal = ""
            })
    end,
    scan_line_and_update = function(buf, line, line_number, coloring, offset, continue)
        -- NOTE: this is a recursive function, it will call itself in current line until it stopped coloring
        --       it will cut the line when it doesnt find a match
        --       returns: coloring

        -- some constants
        -- Add a highlight for the entire line
        local ns_id = vim.api.nvim_create_namespace('set_color_namespace')
        local COLOR_NAME = module.config.public.color_name
        local END_NAME = module.config.public.end_name
        local COLOR_LEN = string.len(COLOR_NAME)
        local END_LEN = string.len(END_NAME)

        -- case mach all current possibilities
        local start_coloring = string.match(line, COLOR_NAME .. "#(%x%x%x%x%x%x)")
        local end_coloring = string.match(line, END_NAME)
        -- set the line color if &color
        if start_coloring then
            if (offset == 0) then
                vim.api.nvim_buf_clear_namespace(buf, -1, line_number, line_number)
            end
            --           print("found &color on line" .. line_number)
            -- conceal the &color property
            module.private.conceal_on_line(COLOR_NAME, buf, line_number, line, COLOR_LEN, offset, ns_id)
            -- set coloring = true and the color
            coloring[0] = true
            coloring[1] = start_coloring
            local color_start_idx, color_end_idx = string.find(line, COLOR_NAME)
            local call_itself = function ()
                return module.private.scan_line_and_update(buf, string.sub(line, color_end_idx + COLOR_LEN+1), line_number,
                    coloring, offset + color_end_idx + COLOR_LEN, continue)
            end
            -- if theres an &end_color tag in the future call the function again with the string cut till the end of the &color
            if (end_coloring) then
                -- find the &color property
                -- notify("found &end_color on line " .. line_number .. "," .. offset)
                local end_start_idx, end_end_idx = string.find(line, END_NAME)
                module.private.color_in_line(coloring[1], buf, line_number, color_end_idx + offset, offset+end_start_idx)
                return call_itself()
            else
                local next_color_start_idx, next_color_end_idx = string.find(string.sub(line, color_end_idx+0), COLOR_NAME)
                if (next_color_end_idx == nil or next_color_start_idx == nil) then
                    module.private.color_in_line(coloring[1], buf, line_number, color_end_idx + offset, -1)
                    continue = true
                    return call_itself()
                else
                    module.private.color_in_line(coloring[1], buf, line_number, color_end_idx + offset, 6+offset + next_color_end_idx)
                    return call_itself()
                end
            end
        elseif end_coloring then
            module.private.conceal_on_line(END_NAME, buf, line_number, line, 0, offset, ns_id)
            local start_idx, end_idx = string.find(line, END_NAME)
            coloring[0] = false
            coloring[1] = "ffffff"
            if (start_coloring) then
                -- if it needs coloring it will color from the offset to the start of &end_color
                return module.private.scan_line_and_update(buf, string.sub(line, end_idx + 0), line_number, coloring,
                    offset + end_idx)
            end
            -- if theres an &color: tag in the future call the function again with the string cut till the end of the &end_color
        else
            if (coloring[0]) then
                module.private.color_in_line(coloring[1], buf, line_number, offset, -1)
            end
        end
        return continue, coloring
    end
    ,

    scan_lines_and_update = function(buf)
        -- Get the lines in the buffer
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local coloring = { false, "ffffff" }
        local continue = false
        -- Iterate over each line
        for line_number, line in ipairs(lines) do
            -- if the line does not contain the all other color properties remove its namespace
            -- NOTE: i think this can conflict with other plugins
            -- mabe i need to try and find another solution
--             vim.api.nvim_buf_clear_namespace(buf, -1, line_number, line_number + 1)
            continue, coloring = module.private.scan_line_and_update(buf, line, line_number, coloring, 0)
            if coloring[0] then
                if continue then
                    continue = false
                else
                    module.private.color_line(coloring[1], buf, line_number)
                end
            end
        end
    end
}

module.load = function()
    -- Get the current buffer
    local buf = vim.api.nvim_get_current_buf()
    -- update the buffer on entering a new page
    vim.api.nvim_create_autocmd({ "BufEnter", "BufNew" }, {
        pattern = { "*.norg" },
        callback = function()
            -- update the buffer
            buf = vim.api.nvim_get_current_buf();
            module.private.scan_lines_and_update(buf)
        end
    })
    -- every time the text changes
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        pattern = { "*.norg" },
        callback = function()
            module.private.scan_lines_and_update(buf)
        end
    })
end

return module
