local neorg = require('neorg.core')

local module = neorg.modules.create('external.neorg-colors')

local function set_text_color(buf)
    -- Get the lines in the buffer
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    -- Iterate over each line
    for i, line in ipairs(lines) do
        local color= string.match(line, "@color:#(%x%x%x%x%x%x)")
        if color then
            -- Add a highlight for the entire line
            local ns_id = vim.api.nvim_create_namespace('set_color_namespace')
            -- create a spetial highlight for each color
            vim.api.nvim_command('highlight ColorHighlightForColor' .. tostring(color) ..' guifg=#' .. color)
            -- set the highlight on the current buffer
            vim.api.nvim_buf_add_highlight(buf, -1, "ColorHighlightForColor" .. tostring(color) , i-1, 0, -1)
            -- finding the @color property and adding the hex color itself
            local start_idx, end_idx = string.find(line, "@color:")
            -- concealing the @color property
            vim.api.nvim_buf_set_extmark(buf, ns_id, i-1, start_idx-1, {
                end_line = i-1,
                end_col = end_idx+7,
                conceal = ""
            })
        else
            -- if the line does not contain the @color property remove its namespace
            -- NOTE: i think this can conflict with other plugins
            -- mabe i need to try and find another solution
            vim.api.nvim_buf_clear_namespace(buf, -1, i, i+1)
        end
    end
end


module.load = function()
    -- Get the current buffer
    local buf = vim.api.nvim_get_current_buf()
    -- update the buffer on entering a new page
    vim.api.nvim_create_autocmd({"BufEnter", "BufNew"}, {
    pattern = {"*.norg"},
    callback= function ()
        -- update the buffer
        buf = vim.api.nvim_get_current_buf();
        set_text_color(buf)
    end
    })
    -- every time the text changes
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        pattern = { "*.norg" },
        callback = function()
            set_text_color(buf)
        end
    })
end

return module
