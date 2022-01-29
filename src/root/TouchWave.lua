--[[
-- 将之前点击的效果的界面移植过来
--]]
local TouchWave = class("TouchWave", function (  )
    local scene =  CLayout:create(display.size)
    scene.name  = 'root.TouchWave'
    scene:enableNodeEvents()
    return scene
end)

function TouchWave:ctor(...)
    -- self:setBackgroundColor(cc.c4b(100,100,100,100))
    --添加一个网络状态时间
    self.backSuccess = false
    self.startClock = os.clock()
    --[[ local wifi = CLayout:create(cc.size(40,48)) ]]
    -- -- wifi:setBackgroundColor(cc.c4b(100,100,100,100))
    -- display.commonUIParams(wifi, {po = cc.p(display.width - 20, display.height - 24)})
    -- self:addChild(wifi, 20)
    -- wifi:setTag(112)
    -- wifi:setVisible(false)
    -- local wifiIcon = display.newImageView(_res('root/wifi'),20,24)
    -- wifi:addChild(wifiIcon,1)
    -- local label = display.newLabel(20,8, {
        -- fontSize = 16, text = "", color = 'ffffff'
    -- })
    -- wifi:addChild(label,2)
    --[[ label:setTag(113) ]]

    local layer = cc.Layer:create()
    layer:setKeyboardEnabled(true)
    self:addChild(layer)
    local target = cc.Application:getInstance():getTargetPlatform()

    if target >= 2 and target < 6 then
        layer:registerScriptKeypadHandler(handler(self, self.handleKeypadEvent))
    end
end


function TouchWave:handleKeypadEvent(callback)
    -- 后退按键
    if callback == 'menuClicked' then
        -- 菜单按键
    else
        if isQuickSdk() then
            --是quick渠道的逻辑
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():QuickExit()
        elseif checkint(Platform.id) == XipuAndroid then
            luaj.callStaticMethod('com.duobaogame.summer.SummerPaySDK','showExit',{})
        else
            xTry(function()
                local platformId = checkint(checktable(Platform).id)
                if isElexSdk() or isKoreanSdk() or isJapanSdk() then
                -- if true then
                    if self.backSuccess then return end
                    --efun android平台的逻辑
                    local loadingView = sceneWorld:getChildByTag(2024)
                    if loadingView then
                        return
                    end
                    --是否在引导过程中的逻辑
                    if require('Frame.lead_visitor.LDirector').GetInstance():IsInGuiding() then
                        self:promoteExit() --提示是否退出游戏的逻辑
                        return
                    end
                    local authorMediator = AppFacade.GetInstance():RetrieveMediator("AuthorMediator")
                    local transMediator  = AppFacade.GetInstance():RetrieveMediator("AuthorTransMediator")
                    local downloadResMdt = AppFacade.GetInstance():RetrieveMediator("ResourceDownloadMediator")
                    local recallMdt = AppFacade.GetInstance():RetrieveMediator("RecallMediator")
                    if authorMediator or transMediator or downloadResMdt or recallMdt then
                        self:promoteExit() --提示是否退出游戏的逻辑
                        return
                    end
                    self.backSuccess = true
                    if AppFacade and AppFacade.GetInstance():CanGoogleBack() then --(router appMediator, other)
                        --有返回的逻辑
                        --是否存在对白框
                        if sceneWorld:getChildByName('Frame.Opera.OperaStage') then
                            -- sceneWorld:removeChildByName('Frame.Opera.OperaStage')
                        elseif sceneWorld:getChildByName('Game.views.LoadingView') then
                            --加载中的逻辑不做任务处理
                        elseif sceneWorld:getChildByName("common.GuideNode") then
                            sceneWorld:removeChildByName('common.GuideNode')
                        elseif sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag) then
                            local ChatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                            local ret =   ChatView:GoogleBack()
                            if ret then
                                ChatView:RemoveChatView()
                            end
                        elseif G_BattleMgr and (not tolua.isnull(G_BattleMgr:GetViewComponent())) and G_BattleMgr:GetViewComponent():GetUIByTag(2322) then
                            -- 伤害统计页面是否存在
                                G_BattleMgr:GetViewComponent():RemoveUILayerByTag(2322)
                        elseif G_BattleMgr and (not tolua.isnull(G_BattleMgr:GetViewComponent())) and G_BattleMgr:GetViewComponent():GetUIByTag(2321) then
                            local view = G_BattleMgr:GetViewComponent():GetUIByTag(2321)
                            if view.BackClickCallback then
                                view:BackClickCallback()
                            end
                        elseif G_BattleMgr and (not tolua.isnull(G_BattleMgr:GetViewComponent())) and G_BattleMgr:GetViewComponent():getChildByTag(1001) then
                            local view = G_BattleMgr:GetViewComponent():getChildByTag(1001)
                            if view.GoogleBack then
                                view:GoogleBack()
                            end
                        else

                            if table.nums(AppFacade.GetInstance().viewManager.mediatorStack) == 1 and AppFacade.GetInstance().viewManager.mediatorStack[1] == 'HomeMediator' then
                                if paltformId == EfunAndroid or platformId == ElexAndroid then
                                    local mediator = AppFacade.GetInstance():RetrieveMediator("HomeMediator")
                                    if mediator and mediator.GoogleBack then
                                        local ret = mediator:GoogleBack()
                                        if ret then
                                            self:promoteExit()
                                        end
                                    else
                                        self:promoteExit()
                                    end
                                else
                                    self:promoteExit()
                                end
                            else
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
                                -- AppFacade.GetInstance():BackMediator()
                            end
                        end
                    else
                        self:promoteExit()
                    end
                else
                    self:promoteExit()
                end
                self.backSuccess = false
            end,__G__TRACKBACK__)
        end
    end
end

function TouchWave:promoteExit()
    if device.platform == 'ios' or device.platform == 'android' then
        device.showAlert(__('警告'), __('(TvT)真的要退出游戏吗？'),{__('确定'), __('取消')},function(event)
            if device.platform == 'android' then
                if event.buttonIndex == 1 then --表示登录
                    self:quitGame_()
                end
            else
                if event.buttonIndex == 2 then
                    self:quitGame_()
                end
            end
        end)
    else
        print('--------------->>>mac -------->>显示退出游戏的界面的逻辑')
    end
end

function TouchWave:quitGame_()
    --退出游戏关闭
    cc.Director:getInstance():endToLua()
    os.exit()
end

function TouchWave:onTouchBegan(touch,event)
    self.startClock = FTUtils:currentTimeMillis()
    return true
end

function TouchWave:onTouchEnded(touch,event)
    local point  = touch:getLocation()
    local deltaT = FTUtils:currentTimeMillis() - self.startClock
    touch_info = {touch_x = point.x, touch_y = point.y, touch_t = deltaT}
	-- 圈圈动画
    local demo1Avatar = sp.SkeletonAnimation:create("root/skeleton.json", "root/skeleton.atlas", 0.6)
    if IS_CHINA_GRAY_MODE then
        demo1Avatar = sp.SkeletonAnimation:create("root/gray/skeleton.json", "root/gray/skeleton.atlas", 0.6)
    end
    demo1Avatar:setPosition(point)
    self:addChild(demo1Avatar,2)
    demo1Avatar:setAnimation(0, 'idle', false)
    demo1Avatar:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.RemoveSelf:create()))
end
function TouchWave:onEnter()
	self.touchEventListener = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener:registerScriptHandler(handler(self,self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener:registerScriptHandler(handler(self,self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchEventListener,self)
end

function TouchWave:onCleanup()
    touch_info = {touch_x = 0, touch_y = 0, touch_t = 0}
    if self.touchEventListener then
        self:getEventDispatcher():removeEventListener(self.touchEventListener)
    end
end

return TouchWave
