
require "Cocos2d"

-- cclog
local cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end

local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    cc.FileUtils:getInstance():addSearchPath("src")
    cc.FileUtils:getInstance():addSearchPath("res")
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(320,480,cc.ResolutionPolicy.SHOW_ALL)

    --create scene
    local scene = require("PuzzleScene")
    local NUM_ROWS = 5      -- パズルの行数
    local NUM_COLUMNS = 6   -- パズルの列数
    local NUM_COLORS =  5   -- ドロップの最大色数
    local puzzleScene = scene.create(NUM_ROWS,NUM_COLUMNS, NUM_COLORS)
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(puzzleScene:render())
    else
        cc.Director:getInstance():runWithScene(puzzleScene:render())
    end

end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
