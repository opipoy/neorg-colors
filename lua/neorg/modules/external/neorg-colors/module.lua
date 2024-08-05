local neorg = require('neorg.core')

local module = neorg.modules.create('external.neorg-colors')

module.private = {

    color_line = function(color, buf, line_num)
        -- create a spetial highlight for each color
        vim.api.nvim_command('highlight ColorHighlightForColor' .. tostring(color) .. ' guifg=#' .. color)
        -- set the highlight on the current buffer
        vim.api.nvim_buf_add_highlight(buf, -1, "ColorHighlightForColor" .. tostring(color), line_num - 1, 0, -1)
    end,

    conceal_on_line = function(what, buf, line_num, line_txt, offset)
        if not offset then
            offset = 0
        end
        -- Add a highlight for the entire line
        local ns_id = vim.api.nvim_create_namespace('set_color_namespace')
        -- finding the @color property and adding the hex color itself
        local start_idx, end_idx = string.find(line_txt, what)
        -- concealing the @color property
        vim.api.nvim_buf_set_extmark(buf, ns_id, line_num - 1, start_idx - 1, {
            end_line = line_num - 1,
            end_col = end_idx + offset,
            conceal = ""
        })
    end,

    scan_lines_and_update = function(buf)
        -- Get the lines in the buffer
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local is_coloring = {false, "#ffffff"}
        -- Iterate over each line
        for i, line in ipairs(lines) do
            -- case mach all current possibilities
            local line_color = string.match(line, "@color:#(%x%x%x%x%x%x)")
            local start_coloring = string.match(line, "&color:#(%x%x%x%x%x%x)")
            local end_coloring = string.match(line, "&end_color")
            -- set the line color if @color
            if line_color then
                module.private.color_line(line_color, buf, i)
                module.private.conceal_on_line("@color:", buf, i, line, 7)
            -- start coloring next lines on &color
            elseif start_coloring then
                is_coloring[0] = true
                is_coloring[1] = start_coloring
                module.private.conceal_on_line("&color:", buf, i, line, 7)
            -- stop coloring on next lines on &stop_color
            elseif end_coloring then
                is_coloring[0] = false
                is_coloring[1] = ""
                module.private.conceal_on_line("&end_color", buf, i, line)
            -- if is corrently on a diffrent color on &color change it
            elseif is_coloring[0] then
                module.private.color_line(is_coloring[1], buf, i)
            else
                -- if the line does not contain the all other color properties remove its namespace
                -- NOTE: i think this can conflict with other plugins
                -- mabe i need to try and find another solution
                vim.api.nvim_buf_clear_namespace(buf, -1, i, i + 1)
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
