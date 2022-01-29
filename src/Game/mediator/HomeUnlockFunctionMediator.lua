--[[
 * author : kaishiqi
 * descpt : 主界面功能解锁 中介者
]]
local HomeUnlockFunctionMediator = class('HomeUnlockFunctionMediator', mvc.Mediator)

local FUNC_EFFECT_TYPE_MAP = {
	[MODULE_DATA[tostring(RemindTag.STORY_TASK)]]    = 'attack4', -- 主线任务
	[MODULE_DATA[tostring(RemindTag.CAPSULE)]]       = 'attack1', -- 召唤  1: func bar
	[MODULE_DATA[tostring(RemindTag.CARDS)]]         = 'attack1', -- 飨灵
	[MODULE_DATA[tostring(RemindTag.TEAMS)]]         = 'attack1', -- 编队
	[MODULE_DATA[tostring(RemindTag.TALENT)]]        = 'attack1', -- 天赋
	[MODULE_DATA[tostring(RemindTag.PET)]]           = 'attack1', -- 堕神
	[MODULE_DATA[tostring(RemindTag.UNION)]]         = 'attack1', -- 工会
	[MODULE_DATA[tostring(RemindTag.DISCOVER)]]      = 'attack4', -- 研究  4: rect
	[MODULE_DATA[tostring(RemindTag.ICEROOM)]]       = 'attack4', -- 冰场
	[MODULE_DATA[tostring(RemindTag.MARKET)]]        = 'attack4', -- 市场
	[MODULE_DATA[tostring(RemindTag.TASTINGTOUR)]]   = 'attack3', -- 品鉴
}

local RAY_SPINE_W = 550
local CreateView = nil


function HomeUnlockFunctionMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'HomeUnlockFunctionMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function HomeUnlockFunctionMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = false

    -- create view
    self.viewData_   = CreateView()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- add listen
    self.touchEventListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener_:setSwallowTouches(true)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.touchEventListener_, -98)
end


function HomeUnlockFunctionMediator:CleanupView()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.touchEventListener_)

    if self:getViewData() and self:getViewData().view and (not tolua.isnull(self:getViewData().view)) then
        self:getViewData().view:stopAllActions()
        self:getViewData().view:runAction(cc.RemoveSelf:create())
    end
end


function HomeUnlockFunctionMediator:OnRegist()
end
function HomeUnlockFunctionMediator:OnUnRegist()
end


function HomeUnlockFunctionMediator:InterestSignals()
    return {
    }
end
function HomeUnlockFunctionMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = display.newLayer()

    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,100), enable = false})
    view:addChild(blockLayer)
    blockLayer:setVisible(false)

    return {
        view       = view,
        blockLayer = blockLayer,
    }
end


-------------------------------------------------
-- get / set

function HomeUnlockFunctionMediator:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public method

function HomeUnlockFunctionMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function HomeUnlockFunctionMediator:showUnlockFunciton(moduleId, moduleData)
    local moduleData     = moduleData and clone(moduleData) or nil
    self.isControllable_ = false

    -- 历练功能内的功能都指向历练按钮
    if (moduleId == MODULE_DATA[tostring(RemindTag.TOWER)] or        -- 31 邪神遗迹
        moduleId == MODULE_DATA[tostring(RemindTag.PVC)] or          -- 42 皇家对决
        moduleId == MODULE_DATA[tostring(RemindTag.THREETWORAID)] or -- 46 协力作战
        moduleId == MODULE_DATA[tostring(RemindTag.MATERIAL)]) then  -- 47 学院补给
        -- 检测历练按钮是否显示着
        local targetId = MODULE_DATA[tostring(RemindTag.MODELSELECT)]
        local homeMdt  = self:GetFacade():RetrieveMediator('HomeMediator')
        local funcView = homeMdt and homeMdt:getFuncViewAt(targetId) or nil
        if funcView and funcView:isVisible() then
            moduleId = targetId
        end
    end

    local viewData = self:getViewData()
    viewData.blockLayer:setVisible(true)

    viewData.view:stopAllActions()
    viewData.view:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.4),
        cc.CallFunc:create(function()
            local funcView = nil
            local homeMdt  = self:GetFacade():RetrieveMediator('HomeMediator')
            if moduleId == MODULE_DATA[tostring(RemindTag.PUBLIC_ORDER)] and moduleData then
                funcView = homeMdt and homeMdt:getHomeScene():getMapPanel():getOrderViewAt(Types.TYPE_TAKEAWAY_PRIVATE, checkint(moduleData.orderId)) or nil
            else
                funcView = homeMdt and homeMdt:getFuncViewAt(moduleId) or nil
            end

            if funcView then
                local viewBBox  = funcView:getBoundingBox()
                local viewWPos  = funcView:getParent():convertToWorldSpace(viewBBox)
                local viewNPos  = self:getViewData().view:convertToNodeSpace(viewWPos)
                local viewSize  = funcView:getContentSize()
                local originPos = display.center
                local targetPos = cc.p(viewNPos.x + viewSize.width/2, viewNPos.y + viewSize.height/2)
                local distPos   = cc.p(targetPos.x - originPos.x, targetPos.y - originPos.y)

                -- raySpine
                local rayPath  = 'ui/home/nmain/jiesuo_sx'
                local raySpine = sp.SkeletonAnimation:create(rayPath .. '.json', rayPath .. '.atlas', 1.0)
                raySpine:setScaleX(math.sqrt(math.pow(distPos.x, 2) + math.pow(distPos.y, 2)) / RAY_SPINE_W)
                raySpine:setRotation(-(math.atan2(distPos.y, distPos.x) * 180 / math.pi))
                raySpine:setAnimation(0, 'idle', false)
                raySpine:setPosition(originPos)
                viewData.view:addChild(raySpine)

                -- listen event
                raySpine:registerSpineEventHandler(function(event)
                    local eventName = event.eventData.name
                    if eventName == sp.CustomEvent.cause_effect then
                        local mainFuncConf = CommonUtils.GetConfig('common', 'mainInterfaceFunction', moduleId) or {}
                        local isNeedGuide  = checkint(mainFuncConf.guide) == 1

                        -- unlockSpine
                        local unlockPath    = 'ui/home/nmain/jiesuo_bk'
                        local unlockSpine   = sp.SkeletonAnimation:create(unlockPath .. '.json', unlockPath .. '.atlas', 1.0)
                        local animationName = FUNC_EFFECT_TYPE_MAP[moduleId] or 'attack2' -- 2: cycle
                        unlockSpine:setAnimation(0, animationName, isNeedGuide)
                        unlockSpine:setPosition(targetPos)
                        viewData.view:addChild(unlockSpine)

                        if isNeedGuide then
                            -- need click funciton
                            self.isControllable_   = true
                            self.checkBoundingBox_ = cc.rect(viewNPos.x, viewNPos.y, viewBBox.width, viewBBox.height)

                            -- guild finger spine
                            local fingerPath  = 'ui/guide/guide_ico_hand'
                            local fingerSpine = sp.SkeletonAnimation:create(fingerPath .. '.json', fingerPath .. '.atlas', 1)
                            fingerSpine:setScaleX(viewNPos.x < display.cx and 1 or -1)
                            fingerSpine:setScaleY(viewNPos.y < display.cy and -1 or 1)
                            fingerSpine:setAnimation(0, 'idle', true)
                            fingerSpine:setPosition(targetPos)
                            viewData.view:addChild(fingerSpine)

                        else
                            -- clean unlockSpine
                            unlockSpine:registerSpineEventHandler(function(event)
                                unlockSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
                                unlockSpine:runAction(cc.RemoveSelf:create())
                                
                                -- to next function
                                self.isControllable_ = true
                                viewData.blockLayer:setVisible(false)
                                AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
                            end, sp.EventType.ANIMATION_COMPLETE)
                        end
                    end
                end, sp.EventType.ANIMATION_EVENT)

                -- clean raySpine
                raySpine:registerSpineEventHandler(function(event)
                    raySpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
                    raySpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
                    raySpine:runAction(cc.RemoveSelf:create())
                end, sp.EventType.ANIMATION_COMPLETE)


            else
                -- to next function
                AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
            end
        end)
    ))
end


-------------------------------------------------
-- handler

function HomeUnlockFunctionMediator:onTouchBegan_(touch, event)
    if not self.isControllable_ then return true end

    local viewData   = self:getViewData()
    local touchPoint = viewData.view:convertToNodeSpace(touch:getLocation())

    if self.checkBoundingBox_ then
        -- check click boundingBox
        if cc.rectContainsPoint(self.checkBoundingBox_, touchPoint) then
            self:close()
            return false
        else
            return true
        end
    else
        self:close()
    end

    return false
end
function HomeUnlockFunctionMediator:onTouchMoved_(touch, event)
end
function HomeUnlockFunctionMediator:onTouchEnded_(touch, event)
end


return HomeUnlockFunctionMediator
