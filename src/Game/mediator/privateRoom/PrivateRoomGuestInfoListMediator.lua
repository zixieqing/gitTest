--[[
包厢功能 贵宾信息主页面 mediator
--]]
local NAME = 'privateRoom.PrivateRoomGuestInfoListMediator'
local PrivateRoomGuestInfoListMediator = class(NAME, mvc.Mediator)
PrivateRoomGuestInfoListMediator.NAME = NAME

local uiMgr             = app.uiMgr
local gameMgr           = app.gameMgr
local privateRoomMgr    = app.privateRoomMgr



local DIALOG_TAG = {
    RANK_REWARD = 1000,
}

local BUTTON_TAG = {
    BACK     = 100, -- 返回
    RULE     = 101, --规则
}

function PrivateRoomGuestInfoListMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
end

-------------------------------------------------
-- inheritance method
function PrivateRoomGuestInfoListMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.guestListDatas  = {}

    -- create view
    local viewComponent = require('Game.views.privateRoom.PrivateRoomGuestInfoListView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)

    -- init data
    self:initData_()

    -- init view
    self:initView_()
    
end

function PrivateRoomGuestInfoListMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function PrivateRoomGuestInfoListMediator:initData_()

    self.guestListDatas = privateRoomMgr:GetGuestListDatas()
    -- logInfo.add(5, tableToString(self.guestListDatas))
end

function PrivateRoomGuestInfoListMediator:initView_()
    local viewData = self:getViewData()
    local count = #self.guestListDatas
    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
    tableView:setCountOfCell(count)
	tableView:reloadData()
end

function PrivateRoomGuestInfoListMediator:CleanupView()
end


function PrivateRoomGuestInfoListMediator:OnRegist()
    -- regPost(POST.PRIVATE_ROOM_GUESTS)
    self:enterLayer()
end
function PrivateRoomGuestInfoListMediator:OnUnRegist()
    -- unregPost(POST.PRIVATE_ROOM_GUESTS)
end


function PrivateRoomGuestInfoListMediator:InterestSignals()
    return {
        POST.PRIVATE_ROOM_GUESTS.sglName,
    }
end

function PrivateRoomGuestInfoListMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    -- if name == POST.PRIVATE_ROOM_GUESTS.sglName then
    --     logInfo.add(5, tableToString(body))
    -- end
end

-------------------------------------------------
-- get / set

function PrivateRoomGuestInfoListMediator:getViewData()
    return self.viewData_
end

function PrivateRoomGuestInfoListMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function PrivateRoomGuestInfoListMediator:enterLayer()
    -- self:SendSignal(POST.PRIVATE_ROOM_GUESTS.cmdName)
end

function PrivateRoomGuestInfoListMediator:refreshUI(isRefreshUI)
    if isRefreshUI then
        
    end
end

-------------------------------------------------
-- private method
function PrivateRoomGuestInfoListMediator:onDataSource(p_convertview, idx)
    -- logInfo.add(5, 'onDataSource --->>>')
    local pCell = p_convertview
    local index = idx + 1
    
    -- logInfo.add(5, 'index = ' .. index)
    if pCell == nil then
        local viewData = self:getViewData()
        local tableView = viewData.tableView
        local cellSize = tableView:getSizeOfCell()
        pCell = self:GetViewComponent():CreateCell(cellSize)

        local cellViewData = pCell.viewData
        local nodes = cellViewData.nodes
        for i, node in ipairs(nodes) do
            local nodeViewData = node:getViewData()
            nodeViewData.touchView:setTag(i)
            display.commonUIParams(nodeViewData.touchView, {cb = handler(self, self.onClickCellAction)})

            nodeViewData.iconTouchVieww:setTag(i)
            display.commonUIParams(nodeViewData.iconTouchVieww, {cb = handler(self, self.onClickCellIconAction)})
        end

    end

    xTry(function()

        local data = self.guestListDatas[index] or {}
        local cellViewData = pCell.viewData
        local nodes = cellViewData.nodes
        for i, node in ipairs(nodes) do
            local nodeData = data[i]
            if nodeData then
                node:refreshUI(nodeData)
            end
            node:setVisible(nodeData ~= nil)
            local nodeViewData = node:getViewData()
            nodeViewData.touchView:setUserTag(index)
            nodeViewData.iconTouchVieww:setUserTag(index)
        end
        pCell:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function PrivateRoomGuestInfoListMediator:onBtnAction(sender)
end

function PrivateRoomGuestInfoListMediator:handleBackAction(sender)
end

function PrivateRoomGuestInfoListMediator:handleRuleAction(sender)
    
end

function PrivateRoomGuestInfoListMediator:onClickCellAction(sender)
    local userTag = checkint(sender:getUserTag())
    local tag     = checkint(sender:getTag())

    -- local data = self.guestListDatas[userTag] or {}
    -- local nodeData = data[tag]
    app:DispatchObservers('PRIVATEROOMGUESTINFO_SWI_VIEW', {dataIndex = userTag, nodeIndex = tag, viewTag = 10001})    
end

function PrivateRoomGuestInfoListMediator:onClickCellIconAction(sender)
    local userTag   = checkint(sender:getUserTag())
    local tag       = checkint(sender:getTag())
    local data      = self.guestListDatas[userTag] or {}
    local nodeData  = data[tag] or {}
    local guestConf = nodeData.guestConf or {}
    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = guestConf.giftId, type = 1})
end

return PrivateRoomGuestInfoListMediator
