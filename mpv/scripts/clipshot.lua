-- Screenshot to ~/Pictures/screenshots/<parent_folder>/<filename>-<timestamp>.png
-- and copy to clipboard via wl-copy

local utils = require('mp.utils')

local base_dir = os.getenv('HOME') .. '/Pictures/screenshots'

local function get_screenshot_path()
    local path = mp.get_property('path', '')
    if path == '' then return nil end

    local dir, file = utils.split_path(path)
    -- parent folder name (strip trailing slash then get last component)
    dir = dir:gsub('/$', '')
    local _, parent = utils.split_path(dir)
    if parent == '' then parent = 'unknown' end

    -- strip extension from filename
    local name = file:gsub('%.[^%.]+$', '')

    -- timestamp from video position
    local pos = mp.get_property_number('time-pos', 0)
    local h = math.floor(pos / 3600)
    local m = math.floor((pos % 3600) / 60)
    local s = math.floor(pos % 60)
    local ms = math.floor((pos % 1) * 1000)
    local timestamp = string.format('%02d-%02d-%02d-%03d', h, m, s, ms)

    local out_dir = utils.join_path(base_dir, parent)
    mp.command_native({'run', 'mkdir', '-p', out_dir})

    return utils.join_path(out_dir, name .. '-' .. timestamp .. '.png')
end

local function clipshot(mode)
    return function()
        local filepath = get_screenshot_path()
        if not filepath then
            mp.osd_message('No file playing', 1)
            return
        end

        mp.commandv('screenshot-to-file', filepath, mode)
        mp.command_native_async(
            {'run', 'sh', '-c', string.format('wl-copy < %q', filepath)},
            function(suc, _, err)
                local msg = suc and 'Screenshot saved & copied' or (err or 'clipboard failed')
                mp.osd_message(msg, 1)
            end
        )
    end
end

mp.add_key_binding(nil, 'clipshot-subs',   clipshot('subtitles'))
mp.add_key_binding(nil, 'clipshot-video',  clipshot('video'))
mp.add_key_binding(nil, 'clipshot-window', clipshot('window'))
