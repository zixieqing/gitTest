-- update.zip
-- cc.LuaLoadChunksFromZIP = function() end


-- 跳过更新
SKIP_UPDATE = true


-- 调试场景
-- DEBUG_SCENE_NAME = 'debug.DebugScene3'


-- 调试依赖
-- require("LuaPanda").start("127.0.0.1", 8818)


-- 闪屏界面
while true do
    local sceneManager = cc.CSceneManager:getInstance()
    local splashScene  = cc.CSceneExtension:create()
    splashScene:setClassName('splashScene')
    sceneManager:runWithScene(splashScene)
    
    local frameSize   = cc.Director:getInstance():getWinSize()
    local centerPos   = {x = frameSize.width/2, y = frameSize.height/2}
    local centerLayer = CLayout:create(frameSize)
    centerLayer:setBackgroundColor({r = 200, g = 200, b = 200, a = 255})
    centerLayer:setPosition(centerPos)
    splashScene:addChild(centerLayer)
    
    local logoImage = CImageView:create('res/update/splash_ico_funtoy.png')
    logoImage:setPosition(centerPos)
    centerLayer:addChild(logoImage)
    break
end


-- 目前还弄不清gc参数原理，main里的5000确实会变慢不少。
-- 默认值是 200 时，加载 cardStory.json 和 json.decode 仅需 0.03 左右，而 main 中的 5000 下，耗时会变为 0.2多
while true do
    local globalCollectgarbage = _G.collectgarbage
    _G.collectgarbage = function(opt, arg)
        if opt == "setstepmul" then
            return globalCollectgarbage("setstepmul", 200)
        else
            return globalCollectgarbage(opt, arg)
        end
    end
    break
end


-- 将真正的 main 延迟在下一帧创建，可以让窗口立刻先出现。
local scheduler = require('cocos.framework.scheduler')
scheduler.performWithDelayGlobal(function()

    
    -- real main
    require('main')
    

    -------------------------------------------------------------------------------
    -- keyboard listener
    -------------------------------------------------------------------------------

    -- 好像是 glfw 的bug，唯独 command 键按下时其他按键就不发送抬起事件了。
    -- 所以组合按键的话就避开 command 建的组合检测吧。
    local keyboardStatusMap = {}

    local onKeyboardReleasedHandler = function(keyCode, event)
        keyboardStatusMap[tostring(keyCode)] = false
    end
    local onKeyboardPressedHandler = function(keyCode, event)
        keyboardStatusMap[tostring(keyCode)] = true
        logs('main2.keyCode', keyCode, type(keyCode))
        
        -------------------------------------------------
        -- 战斗相关控制
        -- [0] keyCode = 76
        -- [-] keyCode = 73
        -- [+] keyCode = 89
        -- [p] keyCode = 139
        -- [q] keyCode = 140
        -- [r] keyCode = 141
        if keyCode == 73 or keyCode == 76 or keyCode == 89 or keyCode == 139 or keyCode == 140 or keyCode == 141 then
            if G_BattleLogicMgr then
                
                -- p : 暂停/恢复 战斗
                if keyCode == 139 then
                    if G_BattleRenderMgr:IsReplay() then
                        if G_BattleLogicMgr:IsMainLogicPause() then
                            G_BattleLogicMgr:RenderResumeBattleHandler() -- 恢复
                        else
                            G_BattleLogicMgr:RenderPauseBattleHandler()  -- 暂停
                        end
                    else
                        if G_BattleLogicMgr:IsMainLogicPause() then
                            G_BattleRenderMgr:ResumeBattleButtonClickHandler() -- 恢复
                        else
                            G_BattleRenderMgr:PauseBattleButtonClickHandler()  -- 暂停
                        end
                    end
                    
                -- q : 退出战斗
                elseif keyCode == 140 then
                    G_BattleRenderMgr:QuitGameButtonClickHandler()
                    
                -- r : 重新开始
                elseif keyCode == 141 then
                    G_BattleRenderMgr:RestartGameButtonClickHandler()
                    
                -- 0|+|- : 控制速度
                else
                    local currentTimeScale = G_BattleLogicMgr:GetBData():GetTimeScale()
                    local targetTimeScale  = currentTimeScale
                    if keyCode == 89 then
                        targetTimeScale = currentTimeScale * 2
                    elseif keyCode == 73 then
                        targetTimeScale = currentTimeScale / 2
                    else
                        targetTimeScale = 1
                    end
                    G_BattleLogicMgr:SetTimeScale(targetTimeScale)
                    G_BattleRenderMgr:SetBattleTimeScale(targetTimeScale)
                    app.gameMgr:UpdatePlayer({localBattleAccelerate = targetTimeScale})
                end
            end
        end

        -------------------------------------------------
        -- [control] keyCode = 14
        if keyboardStatusMap['14'] then
            -- [1] keyCode = 77
            if keyCode == 77 then
                local popupTag = 2000
                if not sceneWorld:getChildByTag(popupTag) then
                    sceneWorld:addChild(require("interfaces.SocketNoticePopup").new(), popupTag, popupTag)
                end

            -- [2] keyCode = 78
            elseif keyCode == 78 then
                -- TODO
                logs('-----', touchWave)
                local len = AppFacade.GetInstance().viewManager.mediatorStack
                local mediatorName = AppFacade.GetInstance().viewManager.mediatorStack[#len]
                local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
                if mediator and mediator.GoogleBack then
                    local ret = mediator:GoogleBack()
                    if ret then
                        AppFacade.GetInstance():BackMediator('HomeMediator')
                    end
                else
                    AppFacade.GetInstance():BackMediator('HomeMediator')
                    local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
                    local children = dialogNodeLayer:getChildren()
                    for idx,val in ipairs(children) do
                        if val and not tolua.isnull(val) and not val.contextName and val.name and val.name ~= "GameScene" then
                            val:runAction(cc.RemoveSelf:create())
                        end
                    end
                end
            end
        end

    end

    local keyboardEventListener = cc.EventListenerKeyboard:create()
    keyboardEventListener:registerScriptHandler(onKeyboardPressedHandler, cc.Handler.EVENT_KEYBOARD_PRESSED)
    keyboardEventListener:registerScriptHandler(onKeyboardReleasedHandler, cc.Handler.EVENT_KEYBOARD_RELEASED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(keyboardEventListener, -1)
end, 0)


-------------------------------------------------------------------------------
-- test use
-------------------------------------------------------------------------------

local socket  = require('socket')
local oldTime = 0
local newTime = 0
function ptime(descr)
    oldTime = newTime
    newTime = socket:gettime()
    local consume = oldTime > 0 and (newTime - oldTime) or 0
    local logFunc = logs ~= nil and logs or print
    logFunc('~~~~~~~~~~~~~~~ ' .. tostring(descr), string.format('%0.6f', consume))
end


function conftest()
    require "cocos.cocos2d.functions"
    local json = require('cocos.framework.json')
    local path = cc.FileUtils:getInstance():getWritablePath()
    local jsonPath = path .. 'src/conf/zh-cn/collection/cardStory.json'
    ptime(jsonPath)
    local jsonData = io.readfile(jsonPath)
    ptime('readfile')
    local luaTable = json.decode(jsonData)
    ptime('json.decode')
    local keysList = table.keys(luaTable)
    print(table.nums(keysList))
end

