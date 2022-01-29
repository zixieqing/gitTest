--[[
奖励mediator
    @params editMode 0, 1   0 是 只读模式 1 编辑模式
--]]
local Mediator = mvc.Mediator
---@class UnionWarsApplyMembersMediator :Mediator
local UnionWarsApplyMembersMediator = class("UnionWarsApplyMembersMediator", Mediator)
local NAME = "unionWars.UnionWarsApplyMembersMediator"
UnionWarsApplyMembersMediator.NAME = NAME


function UnionWarsApplyMembersMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

    self.isEditMode        = self.ctorArgs_.isEditMode and app.unionMgr:IsCanSignUpUnionWars()
    self.setApplySucceedCB = self.ctorArgs_.setApplySucceedCB
end

-------------------------------------------------
-- inheritance method
function UnionWarsApplyMembersMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas           = {}
    self.isControllable_ = true

    local unionWarsConfigs = CommonUtils.GetConfigAllMess('warsParam' , 'union') or {}
    local unionWarsConfig  = unionWarsConfigs['1'] or {}

    -- WARS_DEFINES
    self.maxPlayerNumber = checkint(unionWarsConfig.maxPlayerNumber)
    self.minPlayerNumber = checkint(unionWarsConfig.minPlayerNumber)

    -- create view
    local viewComponent = require('Game.views.unionWars.UnionWarsApplyMembersView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(viewComponent)

    -- init view
    self:InitView_()
    
end

function UnionWarsApplyMembersMediator:InitData_(body)
    self.datas     = body
    self.joinCount = 0
    
    local joinCount          = 0
    local applyMemberPlayers = {}
    -- init 加入个数
    local applyMembers = body.applyMembers or {}
    if next(applyMembers) == nil then return end
    
    for index, value in ipairs(applyMembers) do
        -- init battle point
        local playerCards = value.playerCards or {}
        local battlePoint = 0
        for _, cardData in ipairs(playerCards) do
            battlePoint = battlePoint + app.cardMgr.GetCardStaticBattlePointByCardData(cardData)
        end
        applyMembers[index].battlePoint = battlePoint

        value.isJoin = checkint(value.isJoin)
        local isJoin = value.isJoin > 0
        if isJoin then
            joinCount = joinCount + 1
            local playerId = value.playerId
            applyMemberPlayers[tostring(playerId)] = {battlePoint = battlePoint, playerId = playerId}
        end
    end
    
    table.sort(applyMembers, function (a, b)
        local aBattlePoint = a.battlePoint
        local bBattlePoint = b.battlePoint
        local aIsJoin      = a.isJoin
        local bIsJoin      = b.isJoin
        if aIsJoin ~= bIsJoin then
            return aIsJoin > bIsJoin
        elseif aBattlePoint ~= bBattlePoint then
            return aBattlePoint > bBattlePoint
        else
            return a.playerId > b.playerId
        end
    end)

    self.applyMemberPlayers = applyMemberPlayers
    self.joinCount = joinCount
end

function UnionWarsApplyMembersMediator:InitView_()
    local viewData = self:GetViewData()
    display.commonUIParams(viewData.blockLayer, {cb = handler(self, self.OnClickBlockLayerAction), animate = false})
    display.commonUIParams(viewData.sortBtn, {cb = handler(self, self.OnClickSortBtnAction)})
    display.commonUIParams(viewData.oneKeySelectMemberBtn, {cb = handler(self, self.OnClickOneKeySelectMemberBtnAction)})
    display.commonUIParams(viewData.submitBtn, {cb = handler(self, self.OnClickSubmitBtnAction)})

    viewData.tableList:setDataSourceAdapterScriptHandler(handler(self, self.OnTableListDataAdapter))

    viewData.oneKeySelectMemberBtn:setVisible(self.isEditMode)
    viewData.submitBtn:setVisible(self.isEditMode)
end

function UnionWarsApplyMembersMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function UnionWarsApplyMembersMediator:CleanupView_()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function UnionWarsApplyMembersMediator:OnRegist()
    regPost(POST.UNION_WARS_APPLY_MEMBERS)
    regPost(POST.UNION_WARS_APPLY_WARS)
    self:EnterLayer()
end
function UnionWarsApplyMembersMediator:OnUnRegist()
    unregPost(POST.UNION_WARS_APPLY_MEMBERS)
    unregPost(POST.UNION_WARS_APPLY_WARS)
    self:CleanupView_()
end


function UnionWarsApplyMembersMediator:InterestSignals()
    return {
        -- "CASTLE_CAPSULE_SHOW_REWARD",
        POST.UNION_WARS_APPLY_MEMBERS.sglName,
        POST.UNION_WARS_APPLY_WARS.sglName,
    }
end

function UnionWarsApplyMembersMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.UNION_WARS_APPLY_MEMBERS.sglName then
        self:InitData_(body)
        self:RefreshUI()
    elseif name == POST.UNION_WARS_APPLY_WARS.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "87-01"})
        if self.setApplySucceedCB then
            self.setApplySucceedCB()
        end
        app.uiMgr:ShowInformationTips(__('报名成功'))
        app:UnRegsitMediator(NAME)
    end
end

-------------------------------------------------
-- get / set

function UnionWarsApplyMembersMediator:GetViewData()
    return self.viewData_
end

function UnionWarsApplyMembersMediator:GetOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function UnionWarsApplyMembersMediator:EnterLayer()
    self:SendSignal(POST.UNION_WARS_APPLY_MEMBERS.cmdName)
end

function UnionWarsApplyMembersMediator:RefreshUI()
    local viewData = self:GetViewData()
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateTableList(viewData, self.datas.applyMembers or {})

    viewComponent:UpdateSelectMemberNum(self:GetViewData(), self.joinCount, self.maxPlayerNumber)
end


-------------------------------------------------
-- private method

function UnionWarsApplyMembersMediator:OnTableListDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local tableList = self:GetViewData().tableList
        pCell = viewComponent:CreateCell(tableList:getSizeOfCell())
        display.commonUIParams(pCell.viewData.selectMemberBtn, {cb = handler(self, self.OnClickSelectMemberBtnAction), animate = false})
    end

    local data = self.datas.applyMembers[index]
    local playerId = data.playerId
    viewComponent:UpdateCell(pCell.viewData, data, self.applyMemberPlayers[tostring(playerId)] ~= nil)
    pCell.viewData.selectMemberBtn:setTag(data.playerId)
    pCell.viewData.selectMemberBtn:setUserTag(data.battlePoint)
    return pCell
end


function UnionWarsApplyMembersMediator:UpdateTableList_(applyMembers)
    -- local tableList = self:GetViewData().tableList
    -- local oldOffset = tableList:getContentOffset()
    self:GetViewComponent():UpdateTableList(self:GetViewData(), applyMembers)
    -- tableList:setContentOffset(oldOffset)
end

-------------------------------------------------
-- check


-------------------------------------------------
-- handler
function UnionWarsApplyMembersMediator:OnClickBlockLayerAction(sender)
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end

function UnionWarsApplyMembersMediator:OnClickSelectMemberBtnAction(sender)
    local isCheck = sender:isChecked()
    
    if not self.isEditMode or isCheck and self.joinCount >= self.maxPlayerNumber then 
        sender:setChecked(not isCheck)
        return 
    end
    PlayAudioByClickNormal()

    local playerId = sender:getTag()
    local battlePoint = sender:getUserTag()
    
    if isCheck then
        self.joinCount = self.joinCount + 1
        self.applyMemberPlayers[tostring(playerId)] = {battlePoint = battlePoint, playerId = playerId}
    else
        self.joinCount = self.joinCount - 1
        self.applyMemberPlayers[tostring(playerId)] = nil
    end

    self:GetViewComponent():UpdateSelectState(sender:getParent().viewData, isCheck, self.joinCount, self.maxPlayerNumber)
end

function UnionWarsApplyMembersMediator:OnClickSortBtnAction(sender)
    PlayAudioByClickNormal()

    local applyMembers = self.datas.applyMembers  or {}
    table.sort(applyMembers, function (a, b)
        local aBattlePoint = a.battlePoint
        local bBattlePoint = b.battlePoint
        local aIsJoin      = a.isJoin
        local bIsJoin      = b.isJoin
        if aBattlePoint ~= bBattlePoint then
            return aBattlePoint > bBattlePoint
        elseif aIsJoin ~= bIsJoin then
            return aIsJoin > bIsJoin
        else
            return a.playerId > b.playerId
        end
    end)

    self:UpdateTableList_(applyMembers)
end

function UnionWarsApplyMembersMediator:OnClickOneKeySelectMemberBtnAction(sender)
    if self.joinCount > self.maxPlayerNumber then
        app.uiMgr:ShowInformationTips(__('选择玩家超过最大参战人数'))
        return
    end
    if self.joinCount == self.maxPlayerNumber then
        return
    end
    PlayAudioByClickNormal()

    local applyMembers = self.datas.applyMembers
    local applyMemberPlayers = self.applyMemberPlayers
    for index, value in ipairs(applyMembers) do
        local playerId = value.playerId
        if applyMemberPlayers[tostring(playerId)] == nil then
            applyMemberPlayers[tostring(playerId)] = {battlePoint = value.battlePoint, playerId = playerId}
            self.joinCount = self.joinCount + 1
            if self.joinCount >= self.maxPlayerNumber then
                break
            end
        end
    end

    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateSelectMemberNum(self:GetViewData(), self.joinCount, self.maxPlayerNumber)
    viewComponent:UpdateTableList(self:GetViewData(), applyMembers)
end

function UnionWarsApplyMembersMediator:OnClickSubmitBtnAction(sender)
    if self.joinCount < self.minPlayerNumber then
        app.uiMgr:ShowInformationTips(string.format(__('最少选择%d人参加'), self.minPlayerNumber))
        return
    elseif self.joinCount > self.maxPlayerNumber then
        app.uiMgr:ShowInformationTips(__('选择玩家超过最大参战人数'))
        return
    end
    PlayAudioByClickNormal()

    local text = __('提交报名成功后，<b>不可更改</b>。')
    local labelparser = require('Game.labelparser')
    local parsedtable = labelparser.parse(text)
    local result = {}
	for name, val in ipairs(parsedtable) do
		if val.labelname == 'b' then
            table.insert(result, fontWithColor(14, {text = val.content , fontSize = 24, color = '#ff2222', descr = val.labelname}))
        else
            table.insert(result, fontWithColor(4, {text = val.content , fontSize = 24, descr = val.labelname}))
        end
	end
    local commonTip = require('common.NewCommonTip').new({
		richTextW = 28,
        richtext = result,
        callback = function ()
            local temp = table.values(self.applyMemberPlayers)
            table.sort(temp, function (a, b)
                return a.battlePoint > b.battlePoint
            end)

            local members = {}
            for index, value in ipairs(temp) do
                table.insert(members, value.playerId)
            end
            
            self:SendSignal(POST.UNION_WARS_APPLY_WARS.cmdName, {members = table.concat(members, ',')})
        end
    })
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
    
end


return UnionWarsApplyMembersMediator
