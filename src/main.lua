local sharedFileUtils = cc.FileUtils:getInstance()
sharedFileUtils:setPopupNotify(false)
-- 清除fileCached 避免无法加载新的资源。
sharedFileUtils:purgeCachedEntries()
local writablePath = sharedFileUtils:getWritablePath()--最终写入目录 /Documents/res/lua ui

---设置搜索路径
sharedFileUtils:addSearchPath(writablePath .. 'publish')
sharedFileUtils:addSearchPath(writablePath.. 'res_sub')
sharedFileUtils:addSearchPath(writablePath.. 'res',true)

require "cocos.cocos2d.functions"

function cclog(...)
    if type(DEBUG) ~= "number" or DEBUG < 1 then return end
    print(...)
end

--[[
--获取到ip的类型
--]]
function GetIpType(ip)
    if ip == nil or type(ip) ~= 'string' then
        return 0, "Error"
    end
    local chunks = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if #chunks == 4 then
        for name,val in pairs(chunks) do
            if tonumber(val) < 0 or tonumber(val) > 255 then
                return 0, "Error"
            end
        end
        return 1, "IPv4"
    else
        return 0, "Error" end
    local _, chunks = ip:gsub("[%a%d]+%:?", "")
    if chunks == 8 then
        return 2, "IPv6"
    end

    return 3, "String"
end


--[[
-- @str 需要加密的字符串
--]]
local codec = require('codec')
local saltkey = function (  )
    return '2xx332'
end
function openssl_encrypt( str )
    if str then
        local apisalt = FTUtils:generateKey(saltkey())
        local encryptedData,iv = codec.aes_cbc_encrypt(str, apisalt)
        if encryptedData and iv then
            --进行加密
            local base64Iv = codec.base64_encode(iv)
            encryptedData = codec.base64_encode(encryptedData)
            local hashMac  = codec.hmac_sha256_encode(string.format('%s%s',base64Iv, encryptedData), apisalt)
            local cjson = require("cjson")
            local status, result = pcall(cjson.encode, {iv = base64Iv, mac = hashMac, value = encryptedData})
            if status then
                return result
            else
                return str
            end
        else
            return str
        end
    end
end


-- for module display
CC_DESIGN_RESOLUTION = {
    width     = 1334,
    height    = 750,
    autoscale = "FIXED_WIDTH",
    callback  = function(framesize)
        -- local ratio = framesize.height / framesize.width
        local ratio = framesize.width / framesize.height
        if ratio <= 1.501 then
            -- iPad 768*1024(1536*2048) is 4:3 screen
            print('iPad ratio',ratio)
            return {autoscale = "FIXED_WIDTH"}
        end
    end
}
local windowSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
local fixedWidth = windowSize.width * CC_DESIGN_RESOLUTION.height / windowSize.height
if fixedWidth > CC_DESIGN_RESOLUTION.width then
    CC_DESIGN_RESOLUTION.autoscale = "FIXED_HEIGHT"
end


function getUserPlayerId()
    local userId, playerId = 0, 0
    if AppFacade then
        local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
        userId = checkint(gameMgr.userInfo.userId)
        playerId = checkint(gameMgr.userInfo.playerId)
    end
    return userId, playerId
end


-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    local crashLog = "\n"
    crashLog = crashLog .. ("----------------------------------------\n")
    crashLog = crashLog .. ("LUA ERROR: " .. tostring(msg) .. "\n")
    crashLog = crashLog .. (debug.traceback() .. "\n")
    local uid, pid = getUserPlayerId()
    crashLog = crashLog .. (tostring(uid) .. tostring(pid) .. "\n")
    local target = cc.Application:getInstance():getTargetPlatform()
    if target > 2 and target < 6 then -- ios or andorid 记录新的上报错误
        local uploadInfo = string.format("ERROR: %s %s", tostring(uid), tostring(pid))
        buglyReportLuaException(uploadInfo .. tostring(msg), uploadInfo ..  debug.traceback())
    end
    crashLog = crashLog .. ("----------------------------------------\n")
    print(crashLog)
    if Logger then
        funLog(Logger.ERROR, crashLog ,crashLog)
    end

    return msg
end


local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end

local sharedDirector = cc.CSceneManager:getInstance()

function showTouchWave(  )
    if sharedDirector then
        if sharedDirector:getRunningScene() then
            local director = cc.Director:getInstance()
            local viewsize = director:getWinSize()
            local touchWave = require("root.TouchWave").new()
            touchWave:setPosition(cc.p(viewsize.width * 0.5, viewsize.height * 0.5))
            sharedDirector:getRunningScene():addChild(touchWave, 3048,3048)
        end
    end
end

require('i18n.init')
require("root.logInfo")

local sharedFileUtils = cc.FileUtils:getInstance()
sharedFileUtils:setPopupNotify(false)
-- 清除fileCached 避免无法加载新的资源。
sharedFileUtils:purgeCachedEntries()

---@type cc.CSceneExtension
sceneWorld = cc.CSceneExtension:create()
sceneWorld:setMultiTouchEnabled(false)
if sharedDirector:getRunningScene() then
    sharedDirector:replaceScene(sceneWorld)
else
    sharedDirector:runWithScene(sceneWorld)
end


local OFFSET = 90
local function getDirection(x,y)
    local direct = nil
    if type(display) == 'table' then
        if x <= OFFSET and y <= OFFSET then
            direct = "left_bottom"
        elseif x > (display.width - OFFSET) and y > (display.height - OFFSET) then
            direct = "right_top"
        elseif x > (display.width - OFFSET) and y < OFFSET then
            direct = "right_bottom"
        elseif x < OFFSET and y > (display.height - OFFSET) then
            direct = "left_top"
        end
    end
    return direct
end


function showLogView(tabIndex)
    local logViewTag = 100000
    if sceneWorld:getChildByTag(logViewTag) then
        if sceneWorld:getChildByTag(logViewTag).setTabIndex and tabIndex then
            sceneWorld:getChildByTag(logViewTag):setTabIndex(tabIndex)
        end
        return
    end

    if string.formattedTime then
        if checkint(DEBUG) > 0 then
            sceneWorld:addChild(require("root.LogInfoPopup").new({tabIndex = tabIndex}), logViewTag, logViewTag)
        else
            sceneWorld:addChild(require("root.LogInfoPopup").new({tabIndex = tabIndex}), logViewTag, logViewTag)
        end
    else
        sceneWorld:addChild(require("root.ErrorPopup").new(), logViewTag, logViewTag)
    end
end

--添加点击事件
local directions = {}
local touchListener_ = cc.EventListenerTouchOneByOne:create()
touchListener_:registerScriptHandler(function (touch, event)
    return true
end, 40)
touchListener_:registerScriptHandler(function (touch, event)
    local p = touch:getLocation()
    local direction = getDirection(p.x, p.y)
    if direction then
        if directions[tostring( direction )] then
            --与上次点击在同一区域 清除
            directions = {}
        end
        directions[tostring(direction)] = direction
        local len = table.nums(directions)
        if len == 4 then
            showLogView()
            directions = {}
        end
    else
        --不在指定的位置
        directions = {}
    end
end, 42)
sceneWorld:getEventDispatcher():addEventListenerWithFixedPriority(touchListener_, -1)


local mouseEventListener = cc.EventListenerMouse:create()
mouseEventListener:registerScriptHandler(function(event)
    -- mouse right button
    if event:getMouseButton() == 1 then
        showLogView()
    end
end, 49)  -- cc.Handler.EVENT_MOUSE_UP = 49
sceneWorld:getEventDispatcher():addEventListenerWithFixedPriority(mouseEventListener, -2)


-- local src = 'workEventListenerTouchOneByOne'
-- print(openssl_encrypt(src))

-- local isSuccess = cc.UserDefault:getInstance():getBoolForKey('AndroidUpgrade' .. tostring(FTUtils:getAppVersion()), false)
-- local tVersion,channelId = FTUtils:getTargetAPIVersion()
-- -- version 10 时添加isToDownloader 方法
-- if 85 == channelId or (1003 < channelId and channelId < 2000) then
--     local sharedDirector = cc.CSceneManager:getInstance()
--     if sharedDirector then
--         local __scene = require('download.Welcome')
--         if sharedDirector:getRunningScene() then
--             sharedDirector:replaceScene(__scene:create())
--         else
--             sharedDirector:runWithScene(__scene:create())
--         end
--     end
-- else
--     local toDownloader = FTUtils:isToDownloader()
--     if true == toDownloader and isSuccess == false then  -- is to Downloader page
--         local sharedDirector = cc.CSceneManager:getInstance()
--         if sharedDirector then
--             local __scene = require('download.Downloader')
--             if sharedDirector:getRunningScene() then
--                 sharedDirector:replaceScene(__scene:create())
--             else
--                 sharedDirector:runWithScene(__scene:create())
--             end
--         end
--     else
        -- 控制游戏是加载加密包还是原始文件
        --start game logical
        -- require( "root.AppFacade" )
        -- AppFacade.GetInstance():StartUP()
        -- local __scene = require('download.Welcome')
        -- local sharedDirector = cc.CSceneManager:getInstance()
        -- if sharedDirector:getRunningScene() then
        --     sharedDirector:replaceScene(__scene:create())
        -- else
        --     sharedDirector:runWithScene(__scene:create())
        -- end
        -- require('root.root').new().run()

        -- local shareInstance = CriAtom:GetInstance();
        -- shareInstance:SetAcfFileName("res/audio/NewProject.acf")
        -- shareInstance:Setup()
        -- -- shareInstance:AddCueSheet("SFX", "res/audio/SFX.acb", "")
        -- shareInstance:AddCueSheet("Music", "res/audio/Music.acb", "res/audio/Music.awb")

        -- local exPlayer = shareInstance:CreatePlayer()
        -- shareInstance:Play("Music", "SFX_Test")
        --
        --
local GAME_RELEASE = true
-- local SKIP_UPDATE  = true
-- DEBUG_SCENE_NAME   = 'debug.DebugScene'  -- 单元测试的场景名
--单元测试的场景名
-- DEBUG_SCENE_NAME   = 'debug.DebugScene'
------------ debug工具 ------------
-- DEBUG_SCENE_NAME = 'debug.DebugZZCardResourceScene' -- 卡牌spine debug工具
-- DEBUG_SCENE_NAME = 'debug.DebugConfigScene' -- 配表debug工具
-- DEBUG_SCENE_NAME = 'debug.DebugCardSoundEffectScene' -- 音效debug工具
------------ debug工具 ------------
local launchApp = function()
    if GAME_RELEASE then
        cc.LuaLoadChunksFromZIP("res/lib/update.zip")
    end
    if SKIP_UPDATE then
        require("update.UpdateApp").new("update"):runRootScene()
    else
        require("update.UpdateApp").new("update"):run(true)
    end
end

EVENTLOG = require('root.EventLog')
EVENTLOG.Log(EVENTLOG.EVENTS.launchGame)

local channelId = FTUtils:getChannelId()
if channelId >= 4003 and channelId <= 4006 then
    --智明平台的需要请求代理服务器
    ZM_MIN_TTL_IP = {["80"] = "zmfoodapi.17atv.elexapp.com"}
    ZM_MIN_TTL = 5000
end

local isSuccess = cc.UserDefault:getInstance():getBoolForKey('AndroidGoogleObbUpgrade' .. tostring(FTUtils:getAppVersion()), false)
local toDownloader = FTUtils:isToDownloader()
if true == toDownloader and isSuccess == false then  -- is to Downloader page
    --去下载页面
    local sceneNode = require('root.Downloader').new()
    sceneNode:setPosition(display.center)
    sceneNode:setName('root.Downloader')
    sceneWorld:addChild(sceneNode,20,20)
    EVENTLOG = require('root.EventLog')
    EVENTLOG.Log(EVENTLOG.EVENTS.launchGame)
else
    launchApp()
    EVENTLOG = require('root.EventLog')
    EVENTLOG.Log(EVENTLOG.EVENTS.launchGame)
end

DotGameEvent = require("root.DotGameEvent")
DotGameEvent.SendEvent(DotGameEvent.EVENTS.LAUNCH_GAME)

sceneWorld:getEventDispatcher():removeCustomEventListeners("APP_EXIT")
local customListener = cc.EventListenerCustom:create("APP_EXIT",function()
    --退到进入游戏的登录页面
    AppFacade.Destroy('AppFacade') --删除实例
    --清除缓存数据
    local t = {"battle", "common", "conf", "Frame", "Game", "home", "i18n", "root", "update"}
    for k,v in pairs(package.loaded) do
        for kk,vv in pairs(t) do
            if string.match( k, string.format('^%s', vv) ) then
                if k ~= 'Frame.Manager.AudioManager' and k ~= 'root.AppSDK' then
                    unrequire(k)
                end
            end
        end
    end
    for k,v in pairs(package.preload) do
        for kk,vv in pairs(t) do
            if string.match( k, string.format('^%s', vv) ) then
                if k ~= 'Frame.Manager.AudioManager' and k ~= 'root.AppSDK' then
                    unrequire(k)
                end
            end
        end
    end
    -- launchApp()
    cc.LuaLoadChunksFromZIP("res/lib/update.zip")
    require("update.UpdateApp").new("update"):run(false)
end)
sceneWorld:getEventDispatcher():addEventListenerWithFixedPriority(customListener,10)

local ApplicationType = cc.Application:getInstance():getTargetPlatform()
if ApplicationType == 4 or ApplicationType == 5 then
    --ios and ipad
    ECServiceCocos2dx:init("MR_app_f3244fa5c56c4187a935512043b68286","MR@aihelp.net", "MR_platform_6d3158ac-c032-4108-abf6-1f510d9a197a")
elseif ApplicationType == 3 then --android
    if FTUtils:getTargetAPIVersion() < 16 then
        ECServiceCocos2dx:init("MR_app_f3244fa5c56c4187a935512043b68286","MR@aihelp.net", "MR_platform_2199dec1-37c4-4df0-8e4c-1756201de38d")
    end
end

if cc.Application:getInstance():getTargetPlatform() == 2 then  -- 2 is mac
    require_ = require
    require = function(modname)
        if DEBUG and DEBUG > 0 and string.find(modname, '[\.]') then
            local blockList = {
                'i18n.',
                'root.',
                'conf.',
                'cocos.',
                'battle.',
                'update.',
                'Frame.Log.',
                'Frame.Opera.',
                'Frame.lead_visitor.',
            }
            local isBlock = false
            for i,v in ipairs(blockList) do
                if v == string.sub(modname, 1, string.len(v)) then
                    isBlock = true
                    break
                end
            end
            if not isBlock then
                package.loaded[modname]  = nil
                package.preload[modname] = nil
            end
        end
        return require_(modname)
    end
end
