--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）棋盘Mediator
]]
local MurderClueMediator = class('MurderClueMediator', mvc.Mediator)

local CLUE_POPUP_TYPE = {
    DRAW = 1,
    LOCK = 2
}
function MurderClueMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderClueMediator', viewComponent)
    self.btnList = {} -- 线索按钮list
    self.clueData = {} -- 线索数据
end
-------------------------------------------------
-- inheritance method

function MurderClueMediator:Initial(key)
    self.super.Initial(self, key)
	local viewComponent = require('Game.views.activity.murder.MurderClueView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    self:InitView()
end

function MurderClueMediator:InterestSignals()
    local signals = {
        POST.MURDER_DRAW_PUZZLE_REWARDS.sglName,
        MURDER_CLUE_DRAW_EVENT,
	}
	return signals
end
function MurderClueMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.MURDER_DRAW_PUZZLE_REWARDS.sglName then 
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        self.clueData[body.requestData.rewardId].isDrawn = true
        app.murderMgr:DrawClueRewards(body.requestData.rewardId)
        self:RefreshBtnState()
    elseif name == MURDER_CLUE_DRAW_EVENT then
        self:SendSignal(POST.MURDER_DRAW_PUZZLE_REWARDS.cmdName, {rewardId = body.clueId})
    end
end

function MurderClueMediator:OnRegist()
    regPost(POST.MURDER_DRAW_PUZZLE_REWARDS)
end
function MurderClueMediator:OnUnRegist()
    unregPost(POST.MURDER_DRAW_PUZZLE_REWARDS)
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
-------------------------------------------------
-- handler method
--[[
返回按钮回调
--]]
function MurderClueMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator("MurderClueMediator")
end
--[[
提示按钮回调
--]]
function MurderClueMediator:TipsButtonCallback( sender )
    PlayAudioByClickClose()
    app.uiMgr:ShowIntroPopup({moduleId = '-39'})
end
--[[
线索按钮点击回调
--]]
function MurderClueMediator:ClueButtonCallback( sender )
    local tag = sender:getTag()
    local data = self.clueData[tag]
    local btnComponent = self.btnList[tag]
    local canClick = checkint(app.murderMgr:GetUnlockModuleByType(MURDER_MOUDLE_TYPE.CLUE).subType) * 2 + 1
    local lastClickId = self:GetLastClickId()
    if tag > math.min(canClick, lastClickId + 1) then -- 不可点击
        return 
    end
    if tag == canClick then -- 未解锁
        -- todo -- 未解锁)
        local key = string.format('MURDER_CLUE_%d_IS_CLICK_%d_%d', tag, app.gameMgr:GetUserInfo().playerId, app.murderMgr:GetActivityId())
        data.isClick = true
        cc.UserDefault:getInstance():setBoolForKey(key, true)
        self:ShowCluePopup(tag, CLUE_POPUP_TYPE.LOCK)
        self:RefreshBtnState()
        return 
    end
    if data.isDrawn then -- 已领取
        -- todo -- 已领取
        self:ShowCluePopup(tag, CLUE_POPUP_TYPE.DRAW)
        return 
    end
    if data.isClick then -- 已点击
        -- todo -- 已点击
        self:ShowCluePopup(tag, CLUE_POPUP_TYPE.DRAW)
        return 
    end
    -- 未点击
    self.tag = tag
    local key = string.format('MURDER_CLUE_%d_IS_CLICK_%d_%d', tag, app.gameMgr:GetUserInfo().playerId, app.murderMgr:GetActivityId())
    data.isClick = true
    cc.UserDefault:getInstance():setBoolForKey(key, true)
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    btnComponent.clueSpine:setToSetupPose()
    btnComponent.clueSpine:setAnimation(0, 'play', false)
    btnComponent.clueSpine:addAnimation(0, 'idle1', true)
    btnComponent.clueSpine:setVisible(true)
    btnComponent.titleBg:setVisible(true)
end
--[[
线索spine结束事件
--]]
function MurderClueMediator:SpineEndHandler( event )
    if event.animation == 'play' then
        app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        self:ShowCluePopup(self.tag, CLUE_POPUP_TYPE.DRAW)
	end
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
初始化view
--]]
function MurderClueMediator:InitView()
    self.btnList = {}
    local viewComponent = self:GetViewComponent()
    local clueData = app.murderMgr:GetClueData()
    self.clueData = clueData
    for i, v in ipairs(clueData) do
        local btnComponent = viewComponent:CreateClueButton(v)
        btnComponent.clueBtn:setTag(i)
        btnComponent.titleLabel:setString(string.fmt(app.murderMgr:GetPoText(__('线索_num_')), {['_num_'] = i}))
        btnComponent.clueBtn:setOnClickScriptHandler(handler(self, self.ClueButtonCallback))
        btnComponent.clueSpine:registerSpineEventHandler(handler(self, self.SpineEndHandler), sp.EventType.ANIMATION_END)
        table.insert(self.btnList, btnComponent)
    end
    self:RefreshBtnState()
end
--[[
刷新按钮状态
--]]
function MurderClueMediator:RefreshBtnState()
    local viewComponent = self:GetViewComponent()
    for i, v in ipairs(self.clueData) do
        local btnComponent = self.btnList[i]
        btnComponent.btnIcon:setVisible(true)
        btnComponent.clueSpine:setVisible(false)
        btnComponent.titleBg:setVisible(false)
        if v.isDrawn then
            -- 已领取
            viewComponent:ChangeBtnIcon(btnComponent.btnIcon)
            btnComponent.titleBg:setVisible(true)
        elseif v.isClick then
            if v.isUnlock then
                -- 点击过，已解锁
                btnComponent.clueSpine:setToSetupPose()
                btnComponent.clueSpine:setAnimation(0, 'idle1', true)
                btnComponent.clueSpine:setVisible(true)
                btnComponent.btnIcon:setVisible(false)
                btnComponent.titleBg:setVisible(true)
            else    
                -- 点击过，未解锁
                viewComponent:ChangeBtnIcon(btnComponent.btnIcon, true)
                btnComponent.titleBg:setVisible(true)
            end
        else
            -- 未点击
            btnComponent.btnIcon:setVisible(false)
            if i == 1 then
                btnComponent.clueSpine:setToSetupPose()
                btnComponent.clueSpine:setAnimation(0, 'idle0', true)
                btnComponent.clueSpine:setVisible(true)
            end
        end
    end
end
--[[
获取最后点击的线索id
--]]
function MurderClueMediator:GetLastClickId()
    for i = #self.clueData, 1, -1 do
        if self.clueData[i].isClick then
            return i
        end
    end
    return 0
end
--[[
线索点击弹窗
--]]
function MurderClueMediator:ShowCluePopup( clueId, type )
    local data = self.clueData[clueId]
    local view = require('Game.views.activity.murder.MurderCluePopup').new({data = data, isLock = type == CLUE_POPUP_TYPE.LOCK})
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(view)
    view:setPosition(display.center)
end
-------------------------------------------------
-- public method


return MurderClueMediator
