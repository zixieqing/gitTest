
---
--- Created by xingweihao.
--- DateTime: 27/09/2017 2:35 PM
--- 交易和探索的修改

local Mediator = mvc.Mediator
---@class UnionApplyMediator :Mediator
local UnionApplyMediator = class("UnionApplyMediator", Mediator)
local NAME = "UnionApplyMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type UnionManager
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function UnionApplyMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.datas           = params or {}
    self.applyList       = {}   -- 申请列表
    self.applylistKey    = {}   -- 申请列表的key列表
    self.collectMediator = {}   -- 用于收集和管理mediator
    self.gradeCellCount  = 0    -- cell 的数量
end

function UnionApplyMediator:InterestSignals()
    local signals = {
        POST.UNION_APPLYREJECT.sglName,
        POST.UNION_APPLYAGREE.sglName ,
        POST.UNION_CHANGEINFO.sglName ,
        POST.UNION_APPLYCLEAR.sglName ,
        POST.UNION_APPLYLIST.sglName
    }
    return signals
end
function UnionApplyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if  name == POST.UNION_APPLYREJECT.sglName then
        local requestData  = data.requestData
        local index = self:GetApplyIdIndex(requestData.applyPlayerId)
        self:DeleteApplyPlayerByIndex(index)
        self:ReloadDataGrideView()
    elseif  name == POST.UNION_APPLYAGREE.sglName  then
        if checkint(data.errcode)  == 0 then
            local requestData  = data.requestData
            local index = self:GetApplyIdIndex(requestData.applyPlayerId)
            local data  = self.applyList[tostring(requestData.applyPlayerId)]
            self.applyList[tostring(requestData.applyPlayerId)] = nil
            data.contributionPoint = 0
            self:DeleteApplyPlayerByIndex(index)
            self:ReloadDataGrideView()
        else
            self:SendSignal(POST.UNION_APPLYLIST.cmdName , {})
        end
    elseif name == POST.UNION_CHANGEINFO.sglName then
        local requestData = data.requestData
        local applyPermission = requestData.applyPermission
        if applyPermission and unionMgr:getUnionData() then
            unionMgr:getUnionData().applyPermission = applyPermission
        end
        uiMgr:ShowInformationTips(__('修改请求权限成功'))
    elseif name == POST.UNION_APPLYLIST.sglName then
        local applyList = data.applyList
        self:MergeApplylistTable(applyList)
        self:ReloadDataGrideView()
    elseif name == POST.UNION_APPLYCLEAR.sglName then
        self:DeleteAllApplyPlayer()
        self:ReloadDataGrideView()
    end
end
function UnionApplyMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type UnionApplyView
    self.viewComponent = require("Game.views.UnionApplyView").new()
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    local viewData = self.viewComponent.viewData
    if checkint(gameMgr:getUnionData().job)   == UNION_JOB_TYPE.PRESIDENT then
        viewData.applySetUpBtn:setOnClickScriptHandler(handler(self,self.ApplySetClick))
    else
        viewData.applySetUpBtn:setVisible(false)
    end
    viewData.deleteMessage:setOnClickScriptHandler(handler(self,self.DeleteAllPlayerClick))
    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
end

--[[
    刷新cell的界面信息
--]]
function UnionApplyMediator:OnDataSource(cell, idx)
    local index = idx +1
    local pcell = cell
    local data = self.applyList[tostring(self.applylistKey[index])]

    if index >= 1 and index <= self.gradeCellCount  then
        if not pcell then
            pcell = self.viewComponent:CreateGridCell()
        end
        pcell.refuseBtn:setTag(index)
        pcell.passBtn:setTag(index)
        pcell.refuseBtn:setOnClickScriptHandler(handler(self, self.ApplyRefuesClick))
        pcell.passBtn:setOnClickScriptHandler(handler(self, self.ApplyAgreeClick))
        data.playerAvatarFrame = CommonUtils.GetAvatarFrame(data.playerAvatarFrame)
        pcell.headerNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(data.playerAvatarFrame))
        pcell.headerNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(data.playerAvatar))
        display.commonLabelParams(pcell.playerName ,{text = data.playerName or ""})
        display.commonLabelParams(pcell.playerLevel ,{text = string.format(__('%s级' ) ,data.playerLevel  ) })
    end
    return pcell
end
--[[
    删除所有的申请者
--]]
function UnionApplyMediator:DeleteAllApplyPlayer()
    self.applylistKey ={}
    self.applyList    =  {}
end
-- 申请设置
function  UnionApplyMediator:ApplySetClick(sender)
    PlayAudioByClickNormal()
    ---@type UnionApplySystemView
    local viewComponent = require("Game.views.UnionApplySystemView").new()
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    viewComponent:UpdateView(checkint( gameMgr:getUnionData().applyPermission))
end
function UnionApplyMediator:DeleteAllPlayerClick()
    local data = {}
    data.descr = __('确认清除全部申请吗？')
    data.callback = function ()
        self:SendSignal(POST.UNION_APPLYCLEAR.cmdName ,{})
    end
    app.uiMgr:AddCommonTipDialog(data)
end
--[[
    同意点击的事件
--]]
function UnionApplyMediator:ApplyAgreeClick(sender)
    local tag = sender:getTag()
    local playerId = self.applylistKey[tag]
    local isAddMember =  unionMgr:CheckUnionMemberIsFull()

    if isAddMember then
        uiMgr:ShowInformationTips( __('工会人数已经满了'))
        return
    else
        if playerId then
            self:SendSignal(POST.UNION_APPLYAGREE.cmdName, {applyPlayerId = playerId})
        end
    end
end
--[[
    拒绝点击的事件
--]]
function UnionApplyMediator:ApplyRefuesClick(sender)
    local tag = sender:getTag()
    local playerId = self.applylistKey[tag]
    if playerId then
        self:SendSignal(POST.UNION_APPLYREJECT.cmdName, {applyPlayerId = playerId})
    end
end
--[[
    删除玩家根据Index
--]]
function UnionApplyMediator:DeleteApplyPlayerByIndex(index)
    if index <=  self.gradeCellCount and index > 0  then
        self.applyList[tostring(self.applylistKey[index])] = nil
        table.remove(self.applylistKey , index)
    end
    self.gradeCellCount = #self.applylistKey
end
--[[
    刷新GrideView
--]]
function UnionApplyMediator:ReloadDataGrideView()
    local viewData = self.viewComponent.viewData
    self.gradeCellCount = #self.applylistKey
    if self.gradeCellCount == 0 then
        viewData.richLabel:setVisible(true)
    else
        viewData.richLabel:setVisible(false)
    end
    viewData.gridView:setCountOfCell(self.gradeCellCount)
    viewData.gridView:reloadData()
end
--[[
    合并列表的数据
--]]
function UnionApplyMediator:MergeApplylistTable(data)
    local  count  = #self.applylistKey
    for k , v in pairs(data) do
        if  not self.applyList[tostring(v.playerId)] then -- 如果没有该玩家就插入数据
            self.applyList[tostring(v.playerId)] = v
            count = count +1
            self.applylistKey[count] = v.playerId
        end
    end
end

--[[
    获取到申请的玩家的index 若为零就没有发现申请玩家
--]]
function UnionApplyMediator:GetApplyIdIndex(playerId)
    for  i =1 , #self.applylistKey do
        if checkint(self.applylistKey[i])  == checkint(playerId) then
            return i
        end
    end
    return 0
end

function UnionApplyMediator:EnterLayer()
    self:SendSignal(POST.UNION_APPLYLIST.cmdName,{})
end
function UnionApplyMediator:OnRegist()
    regPost(POST.UNION_APPLYREJECT)
    regPost(POST.UNION_APPLYAGREE , true )
    regPost(POST.UNION_CHANGEINFO)
    regPost(POST.UNION_APPLYLIST)
    regPost(POST.UNION_APPLYCLEAR)
    self:EnterLayer()
end

function UnionApplyMediator:OnUnRegist()
    unregPost(POST.UNION_APPLYREJECT)
    unregPost(POST.UNION_APPLYAGREE)
    unregPost(POST.UNION_CHANGEINFO)
    unregPost(POST.UNION_APPLYLIST)
    unregPost(POST.UNION_APPLYCLEAR)
    if self.viewComponent and ( not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return UnionApplyMediator



