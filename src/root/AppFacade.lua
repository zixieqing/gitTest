local t = {"battle", "common", "conf", "Frame", "Game", "home", "i18n", "root", "update"}
for k,v in pairs(package.loaded) do
    for kk,vv in pairs(t) do
        if string.match( k, string.format('^%s', vv) ) then
            if k ~= 'Frame.Manager.AudioManager' and k ~= 'root.AppSDK' then
                package.loaded[k] = nil
                package.preload[k] = nil
                _G[k] = nil

            end
        end
    end
end
for k,v in pairs(package.preload) do
    for kk,vv in pairs(t) do
        if string.match( k, string.format('^%s', vv) ) then
            if k ~= 'Frame.Manager.AudioManager' and k ~= 'root.AppSDK' then
                package.loaded[k] = nil
                package.preload[k] = nil
                _G[k] = nil

            end
        end
    end
end
package.loaded['config'] = nil
package.preload['config'] = nil
_G['config'] = nil
local sharedFileUtils = cc.FileUtils:getInstance()
sharedFileUtils:purgeCachedEntries()

require('config')
require('Frame.init')
require('root.init')
require('libs.cocosWidget.init')
require('cocos.framework.display')


local socket = require('socket')
local Facade = mvc.Facade

---@class AppFacade : Facade
AppFacade = class("AppFacade", Facade)
AppFacade.NAME = "AppFacade"
AppFacade.START_UP = 'START_UP'

local Startup = require( 'Game.command.Startup')


function AppFacade:ctor( key )
    self.super.ctor(self,key)
    if package.loaded['Frame.Manager.AudioManager'] then
        -- 这段逻辑是为了兼容热更老切新时，用一个不存在的老的方法判断是否需要重载成新的 AudioManager。
        if _G['AudioManager'] and _G['AudioManager'].IsMusicPlaying then
            _G['AudioManager'] = nil
            unrequire('Frame.Manager.AudioManager')
        end
    else
        local node = cc.Node:create()
        local eventDispatcher = node:getEventDispatcher()
        local isInvoked = false
        local preTime = nil
        local customListener = cc.EventListenerCustom:create(APP_ENTER_BACKGROUND,function(event)
            preTime = os.time()
            local mediator = AppFacade.GetInstance():RetrieveMediator('AuthorMediator')
            local amediator = AppFacade.GetInstance():RetrieveMediator('AuthorTransMediator')
            if ((not mediator) and (not amediator)) and Platform.TCPHost then
                local socketMgr = AppFacade.GetInstance():GetManager('SocketManager')
                -- local chatMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')
                if socketMgr then
                    socketMgr:Release()
                end
                -- if chatMgr then
                    -- chatMgr:Release()
                -- end
            end
            self:DispatchObservers(APP_ENTER_BACKGROUND)
            isInvoked = false
        end)
        eventDispatcher:addEventListenerWithFixedPriority(customListener,1)
        local foreListener = cc.EventListenerCustom:create(APP_ENTER_FOREGROUND,function(event)
            --需要重设下socket的发送时间数据
            local mediator = AppFacade.GetInstance():RetrieveMediator('AuthorMediator')
            local amediator = AppFacade.GetInstance():RetrieveMediator('AuthorTransMediator')
            -- if not isInvoked and (not mediator) and preTime then
            if ((not mediator) and (not amediator)) and Platform.TCPHost then
                -- isInvoked = true
                local backTime = os.time()
                -- local timeDelta = math.floor(backTime - preTime)
                -- if timeDelta >= 100 then
                --8分钟不在线时的逻辑直接退出游戏
                local socketMgr = AppFacade.GetInstance():GetManager('SocketManager')
                local chatMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')
                if socketMgr then
                    socketMgr:Release()
                    socketMgr:Connect(Platform.TCPHost,Platform.TCPPort)
                end
                -- if chatMgr then
                    -- chatMgr:Release()
                    -- chatMgr:Connect(Platform.ChatTCPHost, Platform.ChatTCPPort)
                -- end
                -- local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                -- if gameMgr then
                -- gameMgr:ShowExitGameView()
                -- end
            end
            -- preTime = nil
            self:DispatchObservers(APP_ENTER_FOREGROUND)
        end)
        eventDispatcher:addEventListenerWithFixedPriority(foreListener, 1)
        if APP_WINDOW_RESIZE then
            local resizeListener = cc.EventListenerCustom:create(APP_WINDOW_RESIZE,function(event)
                local runPlatform  = cc.Application:getInstance():getTargetPlatform()
                local sizeInPixels = cc.Director:getInstance():getOpenGLView():getFrameSize()
                if runPlatform == cc.PLATFORM_OS_MAC or runPlatform == cc.PLATFORM_OS_WINDOWS then
                    display.setAutoScale(CC_DESIGN_RESOLUTION)
                end
                self:DispatchObservers(APP_WINDOW_RESIZE, {frameSize = sizeInPixels})
            end)
            eventDispatcher:addEventListenerWithFixedPriority(resizeListener, 1)
        end
        sceneWorld:getEventDispatcher():removeCustomEventListeners("APP_EXIT")
        local customListener = cc.EventListenerCustom:create("APP_EXIT",function()
            --退到进入游戏的登录页面
            AppFacade.Destroy(AppFacade.NAME) --删除实例
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
            cc.LuaLoadChunksFromZIP("res/lib/update.zip")
            require("update.UpdateApp").new("update"):run(false)
        end)
        sceneWorld:getEventDispatcher():addEventListenerWithFixedPriority(customListener,10)
    end
end
---@return Facade
function AppFacade.GetInstance( key )
    if not key then key = AppFacade.NAME end
    return Facade:HasInstance(key) and Facade.GetInstance(key) or AppFacade.new(key)
end

function AppFacade:StartUP( )
    unrequire('root.LogInfoPopup')
    unrequire('root.logInfo')
    require('root.logInfo')

    self:RegistSignal(AppFacade.START_UP, Startup)
	self:DispatchSignal(AppFacade.START_UP)
    self:UnRegsitSignal(AppFacade.START_UP)
    
    -- reload lang file
	i18n.addMO(cc.FileUtils:getInstance():fullPathForFilename(string.format('res/lang/%s.mo', i18n.getLang())), i18n.i18nUtils.D_DEFAULT)  -- client lang mo


    -- performance monitoring
    local platformId  = cc.Application:getInstance():getTargetPlatform()
    local isOpenTitle = platformId == 2 or platformId == 0  -- 2 is mac, 0 is win
    if isOpenTitle and cc.Director:getInstance().getRenderer then
        local noticeNode = cc.Director:getInstance():getNotificationNode()
        if noticeNode then
            noticeNode:stopAllActions()
            noticeNode:removeFromParent()
        end

        noticeNode = cc.Node:create()
        noticeNode.appViewTitle   = 'FoodApp'
        noticeNode.RATE_CHART_SET = {'　','▁','▂','▃','▄','▅','▆','▇','█'}
        noticeNode.RATE_CHART_LEN = #noticeNode.RATE_CHART_SET
        noticeNode.RATE_PROGRESS  = 100 / noticeNode.RATE_CHART_LEN
        noticeNode.SAMPLING_COUNT = 10
        noticeNode.MEMORY_MAX_NUM = 1024 * 130  -- KB
        noticeNode.MEMORY_MIN_NUM = 1024 * 40   -- KB
        noticeNode.GCALLS_MAX_NUM = 500
        noticeNode.GCALLS_MIN_NUM = 100
        noticeNode.memoryInfoList = {}
        noticeNode.gcallsInfoList = {}
        cc.Director:getInstance():setNotificationNode(noticeNode)
        for chartIndex = 1, noticeNode.SAMPLING_COUNT do
            noticeNode.memoryInfoList[chartIndex] = noticeNode.RATE_CHART_SET[1]
            noticeNode.gcallsInfoList[chartIndex] = noticeNode.RATE_CHART_SET[1]
        end

        if platformId == 2 then
            noticeNode.appViewTitle = 'FoodMac'
        elseif platformId == 0 then
            noticeNode.appViewTitle = 'FoodWin'
        end
        
        noticeNode:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.DelayTime:create(1),
            cc.CallFunc:create(function()

                -- sampling data
                local memoryNum  = tonumber(collectgarbage("count"), 10)
                local gcallsNum  = cc.Director:getInstance():getRenderer():getDrawnBatches()
                local memoryMax  = noticeNode.MEMORY_MAX_NUM  -- 搞个动态最大值？
                local gcallsMax  = noticeNode.GCALLS_MAX_NUM  -- 搞个动态最大值？
                local memoryRate = (memoryNum - noticeNode.MEMORY_MIN_NUM) / (memoryMax - noticeNode.MEMORY_MIN_NUM) * 100
                local gcallsRate = (gcallsNum - noticeNode.GCALLS_MIN_NUM) / (gcallsMax - noticeNode.GCALLS_MIN_NUM) * 100
                local memoryIdx  = math.min(math.max(1, math.ceil(memoryRate / noticeNode.RATE_PROGRESS)), noticeNode.RATE_CHART_LEN)
                local gcallsIdx  = math.min(math.max(1, math.ceil(gcallsRate / noticeNode.RATE_PROGRESS)), noticeNode.RATE_CHART_LEN)
                table.insert(noticeNode.memoryInfoList, noticeNode.RATE_CHART_SET[memoryIdx])
                table.insert(noticeNode.gcallsInfoList, noticeNode.RATE_CHART_SET[gcallsIdx])
                table.remove(noticeNode.memoryInfoList, 1)
                table.remove(noticeNode.gcallsInfoList, 1)

                -- update view title
                -- logs('>> ', gcallsNum, memoryNum)
                local glView = cc.Director:getInstance():getOpenGLView()
                local memory = string.format('%0.2fMB', memoryNum/1024)
                local gcalls = gcallsNum
                local titles = {
                    noticeNode.appViewTitle,
                    ' [gcalls:', gcalls, ' ', table.concat(noticeNode.gcallsInfoList), ']',
                    ' [memory:', memory, ' ', table.concat(noticeNode.memoryInfoList), ']',
                }
                glView:setViewName(table.concat(titles))
            end)
        )))
    end

end

--[[
    --开始进入游戏的逻辑
    --包括启动socket以及是否添加时间计时器相关功能
--]]
function AppFacade:StartGame( )
    self:DispatchSignal(COMMANDS.COMMAND_START_UP_SOCKET)
end
