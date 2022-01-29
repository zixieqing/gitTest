local SimpleCommand = mvc.SimpleCommand

require('Game.init')
require('Game.displayEx')
require('Game.defines.gameDefines')
require('Game.confParserDefine')
require('battleEntry.BattleGlobalDefines')
RBQN = require('battleEntry.RBQNumber')

---@type SimpleCommand 
local Startup = class("Startup", SimpleCommand)

function Startup:ctor( )
	self.super:ctor()
	self.executed = false
    if FOR_REVIEW then
        if isElexSdk() then
            Platform.serverHost = 'foodss.elexapp.com'
            Platform.ip = 'foodss.elexapp.com'
        end
    end
end


local sharedDirector  = cc.CSceneManager:getInstance()
local eventDispatcher = sharedDirector:getEventDispatcher()

function shakeCallback(event)
    local cjson = require("cjson")
    local status, result = pcall(cjson.decode, event)
    if result and result.state then
        -- dump(result)
        if result.state == 'over' then
            eventDispatcher:dispatchEvent(cc.EventCustom:new('ShakeOver'))
        else
            eventDispatcher:dispatchEvent(cc.EventCustom:new('ShakeBegin'))
        end
    end
end


function Startup:Execute( signal )
	self.executed = true
	--执行启动游戏
    cc.Director:getInstance():setDisplayStats(CC_SHOW_FPS)
    
    require('Game.utils.CommonUtils')
    require('Game.utils.GoodsUtils')
    require('Game.utils.CardUtils')
    require('Game.utils.ChatUtils')
    require('Game.utils.PetUtils')
    require('Game.utils.ArtifactUtils')
    require('Game.utils.UnionBeastUtils')
    require('Game.utils.AssetsUtils')
    require('Game.utils.ExcelUtils')
    require('Game.utils.GuideUtils')
    require('Game.utils.ActivityUtils')
    require('Game.utils.CatHouseUtils')
    require('Game.utils.RestaurantUtils')

    -- init managers
    ---@type Facade
    app = {}  -- 这样初始化，插件能识别提示。
    setmetatable(app, {__index = AppFacade.GetInstance()})
    
    app.fileUtils           = cc.FileUtils:getInstance()                       -- 文件 工具类
    app.userFile            = cc.UserDefault:getInstance()                     -- 用户 本地记录
    ---@type DataManager
    app.dataMgr             = app:AddManager('Frame.Manager.DataManager')      -- 数据 管理器
    ---@type GameManager
    app.gameMgr             = require('Frame.Manager.GameManager')             -- 游戏 管理器
    ---@type AudioManager
    app.audioMgr            = require('Frame.Manager.AudioManager')            -- 音效 管理器
    ---@type GlobalVoiceManager
    app.voiceMgr            = require('Frame.Manager.GlobalVoiceManager')      -- 语音 管理器
    ---@type HttpManager
    app.httpMgr             = require('Frame.Manager.HttpManager')             -- 短链 管理器
    ---@type SocketManager
    app.socketMgr           = require('Frame.Manager.SocketManager')           -- 长链 管理器
    ---@type ChatSocketManager
    app.chatMgr             = require('Frame.Manager.ChatSocketManager')       -- 聊天 管理器
    ---@type UIManager
    app.uiMgr               = require('Frame.Manager.UIManager')               -- UI  管理器
    ---@type PetManager
    app.petMgr              = require('Frame.Manager.PetManager')              -- 堕神 管理器
    ---@type CardManager
    app.cardMgr             = require('Frame.Manager.CardManager')             -- 卡牌 管理器
    ---@type TimerManager
    app.timerMgr            = require('Frame.Manager.TimerManager')            -- 时钟 管理器
    ---@type TakeawayManager
    app.takeawayMgr         = require('Frame.Manager.TakeawayManager')         -- 外卖 管理器
    ---@type UnionManager
    app.unionMgr            = require('Frame.Manager.UnionManager')            -- 工会 管理器
    ---@type OrderInfoManager
    app.payMgr              = require('Frame.Manager.OrderInfoManager')        -- 支付 管理器
    ---@type TastingTourManager
    app.cuisineMgr          = require('Frame.Manager.TastingTourManager')      -- 品鉴 管理器（料理本）
    ---@type ArtifactManager
    app.artifactMgr         = require('Frame.Manager.ArtifactManager')         -- 神器 管理器
    ---@type ExploreSystemManager
    app.exploresMgr         = require('Frame.Manager.ExploreSystemManager')    -- 探索 管理器
    ---@type DownloadManager
    app.downloadMgr         = require('Frame.Manager.DownloadManager')         -- 下载 管理器
    ---@type GameResManager
    app.gameResMgr          = require('Frame.Manager.GameResManager')          -- 资源 管理器
    ---@type SummerActivityManager
    app.summerActMgr        = require('Frame.Manager.SummerActivityManager')   -- 夏活 管理器
    ---@type FishingManager
    app.fishingMgr          = require('Frame.Manager.FishingManager')          -- 钓场 管理器
    ---@type PrivateRoomManager
    app.privateRoomMgr      = require('Frame.Manager.PrivateRoomManager')      -- 包厢 管理器
    ---@type WaterBarManager
    app.waterBarMgr         = require('Frame.Manager.WaterBarManager')         -- 水吧 管理器
    ---@type AnniversaryManager
    app.anniversaryMgr      = require('Frame.Manager.AnniversaryManager')      -- 年庆 管理器
    ---@type BadgeManager
    app.badgeMgr            = require('Frame.Manager.BadgeManager')            -- 红点 管理器
    ---@type ActivityManager
    app.activityMgr         = require('Frame.Manager.ActivityManager')         -- 活动 管理器
    ---@type CookingManager
    app.cookingMgr          = require('Frame.Manager.CookingManager')          -- 做菜 管理器
    ---@type RestaurantManager
    app.restaurantMgr       = require('Frame.Manager.RestaurantManager')       -- 餐厅 管理器
    ---@type PTDungeonManager
    app.ptDungeonMgr        = require('Frame.Manager.PTDungeonManager')        -- PT本 管理器
    ---@type CapsuleManager
    app.capsuleMgr          = require('Frame.Manager.CapsuleManager')          -- 抽卡 管理器
    ---@type PassTicketManager
    app.passTicketMgr       = require('Frame.Manager.PassTicketManager')       -- pass卡 管理器
    ---@type MurderManager
    app.murderMgr           = require('Frame.Manager.MurderManager')           -- 杀人案 管理器
    ---@type BlackGoldManager
    app.blackGoldMgr        = require('Frame.Manager.BlackGoldManager')        -- 黑市 管理器
    ---@type Anniversary2019Manager
    app.anniversary2019Mgr  = require('Frame.Manager.Anniversary2019Manager')  -- 2019 周年庆
    ---@type TripleTriadGameManager
    app.ttGameMgr           = require('Frame.Manager.TripleTriadGameManager')  -- 打牌游戏 管理器
    ---@type SpringActivity20Manager
    app.springActivity20Mgr = require('Frame.Manager.SpringActivity20Manager') -- 20春活 管理器
    ---@type ActivityHpManager
    app.activityHpMgr       = require('Frame.Manager.ActivityHpManager')       -- 活动体力 管理器
    ---@type GoodsManager
    app.goodsMgr            = require('Frame.Manager.GoodsManager')            -- 道具 管理器
    ---@type PlistManager
    app.plistMgr            = require('Frame.Manager.PlistManager')            -- plist 管理器
    ---@type Anniversary2020Manager
    app.anniv2020Mgr        = require('Frame.Manager.Anniversary2020Manager')  -- 2020 周年庆
    ---@type CatHouseManager
    app.catHouseMgr         = require('Frame.Manager.CatHouseManager')         -- 猫屋 管理器

    
    --[[
        为了方便给 vscode 的插件解析，语法提示只能识别 require 级别的定义。
        所以真正的初始 Manager 的任务就交给下面的 for 循环重新赋值。
        Ps：由于有些 manager 在 init 时就开始读配表了，所以 dataMgr 只能额外优先初始化。
    ]]
    for key, value in pairs(app) do
        if key ~= 'dataMgr' and string.sub(key, -3) == 'Mgr' then
            app[key] = app:AddManager('Frame.Manager.' .. value.__cname)
        end
    end

    -- init wedgets
    app.spineExt    = require('Frame.gui.SpineExt')
    app.cardSpine   = require('Frame.gui.CardSpine')
    app.loadImage   = require('Frame.gui.LoadImage')
    app.cardL2dNode = require('Frame.gui.CardL2dNode')

    ---@type Router
    app.router = require('Game.mediator.Router').new()
    app:RegistMediator(app.router)

    -- 注册事件
    if GAME_MODULE_OPEN.DOT_EVENT_LOG then
        DotEventLog = require("root.DotEventLog")
        DotEventLog.RegistObserver()
    end
    -- 如果 DotGameEvent 不存在 需要重新引入一次

    DotGameEvent = require("root.DotGameEvent")
    DotGameEvent.SendEvent(DotGameEvent.EVENTS.LAUNCH_GAME)


    -- run scene
    if DEBUG_SCENE_NAME then
        app.uiMgr:SwitchToTargetScene(DEBUG_SCENE_NAME)
    else
        local authorMdt = require('Game.mediator.AuthorMediator').new()
        app:RegistMediator(authorMdt)
    end

    showTouchWave()

    local SocketCommand = require('Game.command.SocketCommand')
    app:RegistSignal(COMMANDS.COMMAND_START_UP_SOCKET, SocketCommand)
    
    if device.platform == 'ios' then
        luaoc.callStaticMethod("ShakeSDK", "addScriptListener", {listener = shakeCallback})
    elseif device.platform == 'android' then
        luaj.callStaticMethod("com.dddwan.summer.food.ShakeSDK", "addScriptListener", {shakeCallback})
    end
    
    if device.platform == 'ios' then
        if FTUtils.isJailbroken then
            if FTUtils:isJailbroken() then
                --越狱机器
                local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")
                if httpMgr then
                    httpMgr:Post("User/exceptionLog","JAIL_BREAK",{},function()
                    end, true)
                end
            end
        end
    end

end

return Startup
