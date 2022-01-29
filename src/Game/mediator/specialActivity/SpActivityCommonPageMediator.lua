--[[
 * author : liuzhipeng
 * descpt : 特殊活动 通用跳转页签mediator
]]
local SpActivityCommonPageMediator = class('SpActivityCommonPageMediator', mvc.Mediator)

local SpActivityCommonPageView = require("Game.views.specialActivity.SpActivityCommonPageView")

function SpActivityCommonPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityCommonPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityCommonPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local centerPos = self.ownerNode_:convertToNodeSpace(cc.p(display.cx, display.cy))
        local view = SpActivityCommonPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    end
end


function SpActivityCommonPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityCommonPageMediator:OnRegist()
end
function SpActivityCommonPageMediator:OnUnRegist()
end


function SpActivityCommonPageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityCommonPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
end


-------------------------------------------------
-- handler method

-------------------------------------------------
-- get /set
-------------------------------------------------
-- private method
--[[
前往按钮回调
--]]
function SpActivityCommonPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
    local type = self.typeData_.type
    local activityId = self.typeData_.activityId
    if type == ACTIVITY_TYPE.DRAW_RANDOM_POOL then -- 铸池抽卡
        app:RetrieveMediator("Router"):Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
    elseif type == ACTIVITY_TYPE.BINARY_CHOICE then -- 双择卡池
        app:RetrieveMediator("Router"):Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
    elseif type == ACTIVITY_TYPE.SKIN_CARNIVAL then -- 皮肤嘉年华
        app:RetrieveMediator('Router'):Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'activity.skinCarnival.ActivitySkinCarnivalMediator', params = {activityId = activityId, backMediatorName = 'specialActivity.SpActivityMediator'}})
    elseif type == ACTIVITY_TYPE.ANNIVERSARY19 then -- 周年庆19
        app:RetrieveMediator('Router'):Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'anniversary19.Anniversary19HomeMediator', params = {activityId = activityId}})
    elseif type == ACTIVITY_TYPE.ARTIFACT_ROAD then -- 神器之路
        if 40 <= checkint(app.gameMgr:GetUserInfo().level) then
            app:RetrieveMediator("Router"):Dispatch({name = 'specialActivity.SpActivityMediator', params = { activityId = activityId}}, {name = 'activity.ArtifactRoad.ArtifactRoadMediator', params = { activityId = activityId}}, {isBack = true})
        else
            app.uiMgr:ShowInformationTips(__('等级达到40级解锁该活动'))
        end
    elseif type == ACTIVITY_TYPE.DRAW_SUPER_GET then -- 超得抽卡
        app:RetrieveMediator("Router"):Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
    elseif type == ACTIVITY_TYPE.JUMP_JEWEL then -- 塔可跳转活动
        app:RetrieveMediator("Router"):Dispatch({} , { name ="artifact.JewelCatcherPoolMediator" })
    elseif type == ACTIVITY_TYPE.SUMMER_ACTIVITY then -- 夏活
	    if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.SUMMER_ACTIVITY, true) then return end
	    app.summerActMgr:InitCarnieTheme()
	    local callback = function ()
	    	if app.gameMgr:GetUserInfo().summerActivity > 0 then
	    		AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'summerActivity.SummerActivityHomeMediator', params = {fromMediator = 'specialActivity.SpActivityMediator', activityId = activityId}})
	    	end
	    end
	    local storyTag = checkint(CommonUtils.getLocalDatas(app.summerActMgr:getCarnieThemeActivityStoryFlagByChapterId('1')))
	    if storyTag > 0 then
	    	callback()
	    else
	    	CommonUtils.setLocalDatas(1, app.summerActMgr:getCarnieThemeActivityStoryFlagByChapterId('1'))
	    	local path = string.format("conf/%s/summerActivity/summerStory.json",i18n.getLang())
	    	local stage = require( "Frame.Opera.OperaStage" ).new({id = 1, path = path, guide = true, isHideBackBtn = true, cb = callback})
	    	stage:setPosition(cc.p(display.cx,display.cy))
	    	sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
        end
    elseif type == ACTIVITY_TYPE.CYCLIC_TASKS then -- 循环任务
        local tempData = clone(self.typeData_)
        tempData.leftSeconds = self:CalculateTypeLeftSeconds(self.typeData_)
        local mediator = require('Game.mediator.activity.cyclicTask.ActivityCyclicTaskMediator').new({activityHomeData = tempData})
        app:RegistMediator(mediator)
    elseif type == ACTIVITY_TYPE.SCRATCHER then -- 飨灵刮刮乐
        app:RetrieveMediator("AppMediator"):SendSignal(POST.FOOD_COMPARE_HOME.cmdName, {activityId = activityId})
    elseif type == ACTIVITY_TYPE.SPRING_ACTIVITY_20 then -- 20春活
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'ActivityMediator'}, {name = 'springActivity20.SpringActivity20HomeMediator', params = {animation = 1}})
    elseif type == ACTIVITY_TYPE.ANNIVERSARY_20 then -- 20周年庆
        app.router:Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'anniversary20.Anniversary20HomeMediator'})
    elseif type == ACTIVITY_TYPE.BATTLE_CARD then -- 战牌
        app.router:Dispatch({name = "specialActivity.SpActivityMediator"}, {name = "ttGame.TripleTriadGameHomeMediator"})
    elseif type == ACTIVITY_TYPE.CASTLE_ACTIVITY then -- 古堡迷踪
        local extraParams = {activityId = activityId, activityType = ACTIVITY_TYPE.CASTLE_ACTIVITY}
        app:RetrieveMediator("Router"):Dispatch({name = 'ActivityMediator', params = extraParams}, {name = 'castle.CastleMainMediator', params = extraParams}, {isBack = true})
    end
end

function SpActivityCommonPageMediator:CalculateTypeLeftSeconds(typeData)
    local targetTime = typeData and checkint(typeData.closeTimestamp_) or 0
    return checkint(targetTime - os.time())
end
-------------------------------------------------
-- public method
function SpActivityCommonPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
end


return SpActivityCommonPageMediator
