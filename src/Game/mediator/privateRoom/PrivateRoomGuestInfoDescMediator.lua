--[[
包厢功能 贵宾信息详情 mediator
--]]
local NAME = 'privateRoom.PrivateRoomGuestInfoDescMediator'
local PrivateRoomGuestInfoDescMediator = class(NAME, mvc.Mediator)
PrivateRoomGuestInfoDescMediator.NAME = NAME

local uiMgr             = app.uiMgr
local gameMgr           = app.gameMgr
local privateRoomMgr    = app.privateRoomMgr

local PrivateRoomGuestInfoDescView      = require('Game.views.privateRoom.PrivateRoomGuestInfoDescView')
local PrivateRoomPlotDialogueRecordView = require('Game.views.privateRoom.PrivateRoomPlotDialogueRecordView')


function PrivateRoomGuestInfoDescMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
end

-------------------------------------------------
-- inheritance method
function PrivateRoomGuestInfoDescMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.dataIndex = 1
    self.nodeIndex = 1
    self.guestUnlockCount = 0
    
    -- create view
    local viewComponent = PrivateRoomGuestInfoDescView.new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)

    -- init data
    self:initData_()

    -- init view
    self:initView_()
    
end


function PrivateRoomGuestInfoDescMediator:initData_()

    self.guestListDatas = privateRoomMgr:GetGuestListDatas()
end

function PrivateRoomGuestInfoDescMediator:initView_()
    local viewData = self:getViewData()
    local roleInfoLayer          = viewData.roleInfoLayer
    local roleInfoLayerViewData  = roleInfoLayer.viewData
    local leftSwitchBtn   = roleInfoLayerViewData.leftSwitchBtn
    local rightSwitchBtn  = roleInfoLayerViewData.rightSwitchBtn

    display.commonUIParams(leftSwitchBtn, {cb = handler(self, self.onclickLeftSwiBtnAction)})
    display.commonUIParams(rightSwitchBtn, {cb = handler(self, self.onclickRightSwiBtnAction)})

    local guestPlotLayer         = viewData.guestPlotLayer
    local guestPlotLayerViewData = guestPlotLayer.viewData
    local gridView       = guestPlotLayerViewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))

    local iconTouchView = guestPlotLayerViewData.iconTouchView
    display.commonUIParams(iconTouchView, {cb = handler(self, self.onClickIconAction)})
end

function PrivateRoomGuestInfoDescMediator:CleanupView()
end


function PrivateRoomGuestInfoDescMediator:OnRegist()
    regPost(POST.PRIVATE_ROOM_GUEST_DIALOGUE_DRAW)
    self:enterLayer()
end
function PrivateRoomGuestInfoDescMediator:OnUnRegist()
    unregPost(POST.PRIVATE_ROOM_GUEST_DIALOGUE_DRAW)
end


function PrivateRoomGuestInfoDescMediator:InterestSignals()
    return {
        POST.PRIVATE_ROOM_GUEST_DIALOGUE_DRAW.sglName,
    }
end

function PrivateRoomGuestInfoDescMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.PRIVATE_ROOM_GUEST_DIALOGUE_DRAW.sglName then
        local rewards = body.rewards or {}
        CommonUtils.DrawRewards(rewards)
        if next(rewards) ~= nil then
            local scene = uiMgr:GetCurrentScene()
            local view = require('Game.views.privateRoom.PrivateRoomGuestInfoRewardPopView').new({tag = 12021, goodsId = rewards[1].goodsId})
            view:setTag(12021)
            display.commonUIParams(view, {ap = display.CENTER, po = display.center})
            scene:AddDialog(view)
        end

        local guestsData = self.nodeData.guestsData or {}
        guestsData.hasDrawn = 1
    end
end

-------------------------------------------------
-- get / set

function PrivateRoomGuestInfoDescMediator:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public method
function PrivateRoomGuestInfoDescMediator:enterLayer()
end

function PrivateRoomGuestInfoDescMediator:refreshUI(data)
    self.dataIndex = data.dataIndex or 1
    self.nodeIndex = data.nodeIndex or 1
    
    local guestListData = self.guestListDatas[self.dataIndex] or {}
    self.nodeData = guestListData[self.nodeIndex] or {}
    local guestsData = self.nodeData.guestsData or {}
    local guestConf  = self.nodeData.guestConf or {}

    self.curGuestGrade = checkint(guestsData.grade or 1)
    self.guestId = guestsData.guestId

    if self.nodeData.storyDatas == nil then
        local dialogues = guestsData.dialogues or {}
        local storys     = guestConf.story or {}
        self.nodeData.storyDatas = privateRoomMgr:InitStoryDatas(storys, dialogues)
    end
    -- logInfo.add(5, tableToString(guestsData))
    -- logInfo.add(5, tableToString(self.nodeData.storyDatas))

   self:GetViewComponent():refreshUI(self.nodeData)
   self:updateSwiBtnShowState()
end

--==============================--
--desc: 更新切换按钮显示状态
--==============================--
function PrivateRoomGuestInfoDescMediator:updateSwiBtnShowState()
    -- 1.获取pre数据下标
    local preDataIndex, preNodeIndex = self:getPreDataIndex()
    
    -- 2.获取next数据下标
    local nextDataIndex, nextNodeIndex = self:getNextDataIndex()

    self:GetViewComponent():updateSwiBtnShowState(self:getDataUnlockState(preDataIndex, preNodeIndex), self:getDataUnlockState(nextDataIndex, nextNodeIndex))
end

--==============================--
--desc: 获得pre数据下标
--==============================--
function PrivateRoomGuestInfoDescMediator:getPreDataIndex()
    local preNodeIndex = self.nodeIndex - 1
    local preDataIndex = self.dataIndex
    if preNodeIndex <= 0 then
        preNodeIndex = 2
        preDataIndex = preDataIndex - 1 
    end
    return preDataIndex, preNodeIndex
end

--==============================--
--desc: 获得next数据下标
--==============================--
function PrivateRoomGuestInfoDescMediator:getNextDataIndex()
    -- 2.获取right数据下标
    local nextNodeIndex = self.nodeIndex + 1
    local nextDataIndex = self.dataIndex
    if nextNodeIndex >= 3 then
        nextNodeIndex = 1
        nextDataIndex = nextDataIndex + 1 
    end
    return nextDataIndex, nextNodeIndex
end

--==============================--
--desc: 获得解锁状态
--@params dataIndex  int   数据下标
--@params nodeIndex  int   节点数据下标
--==============================--
function PrivateRoomGuestInfoDescMediator:getDataUnlockState(dataIndex, nodeIndex)
    local guestListData = self.guestListDatas[dataIndex]
    local isUnlock = false
    if guestListData then
        local nodeData = guestListData[nodeIndex]
        if nodeData then
            isUnlock = nodeData.isUnlock
        end
    end
    return isUnlock
end

-------------------------------------------------
-- private method
function PrivateRoomGuestInfoDescMediator:onDataSource(p_convertview, idx)
    -- logInfo.add(5, 'onDataSource --->>>')
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local viewData = self:getViewData()
        local guestPlotLayer         = viewData.guestPlotLayer
        local guestPlotLayerViewData = guestPlotLayer.viewData
        local gridView               = guestPlotLayerViewData.gridView
        local cellSize               = gridView:getSizeOfCell()
        pCell = self:GetViewComponent():CreateCell(cellSize)

        local touchView = pCell.viewData.touchView
        display.commonUIParams(touchView, {cb = handler(self, self.onClickCellAction)})
    end

    xTry(function()
        
        local storyData = self.nodeData.storyDatas[index]
        local viewData = pCell.viewData
        
        self:GetViewComponent():updateCell(viewData, storyData, self.curGuestGrade)

        local touchView = viewData.touchView
        touchView:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function PrivateRoomGuestInfoDescMediator:onBtnAction(sender)
end

function PrivateRoomGuestInfoDescMediator:handleBackAction(sender)
end

function PrivateRoomGuestInfoDescMediator:handleRuleAction(sender)
    
end

function PrivateRoomGuestInfoDescMediator:onclickLeftSwiBtnAction(sender)
    -- 1.获取pre数据下标
    local preDataIndex, preNodeIndex = self:getPreDataIndex()
    self:refreshUI({dataIndex = preDataIndex, nodeIndex = preNodeIndex})
end

function PrivateRoomGuestInfoDescMediator:onclickRightSwiBtnAction(sender)
    local nextDataIndex, nextNodeIndex = self:getNextDataIndex()
    self:refreshUI({dataIndex = nextDataIndex, nodeIndex = nextNodeIndex})
end

function PrivateRoomGuestInfoDescMediator:onClickCellAction(sender)
    local tag       = sender:getTag()
    local storyData = self.nodeData.storyDatas[tag] or {}
    local dialogueConf = storyData.dialogueConf or {}
    local guestGrade = checkint(dialogueConf.guestGrade)
    local isSatisfyGrade = self.curGuestGrade >= guestGrade

    if not isSatisfyGrade then
        uiMgr:ShowInformationTips(string.format(__('此剧情需客人星级达到%s才有可能触发'), guestGrade - 1))
        return
    end
    local dialogue = storyData.dialogue
    if dialogue == nil then
        uiMgr:ShowInformationTips(__('未触发该剧情'))
        return
    end
    
    local scene = uiMgr:GetCurrentScene()
    local view = require('Game.views.privateRoom.PrivateRoomPlotDialogueRecordView').new({
        tag = 12020, storyData = storyData, npcId = dialogueConf.npcId, guestId = self.guestId, title = dialogueConf.name
    })
    view:setTag(12020)
    display.commonUIParams(view, {ap = display.CENTER, po = display.center})
    scene:AddDialog(view)

end

function PrivateRoomGuestInfoDescMediator:onClickIconAction(sender)
    -- logInfo.add(5, tableToString(self.nodeData))
    local guestsData = self.nodeData.guestsData or {}
    
    local dialogues = guestsData.dialogues or {}
    local value = table.nums(dialogues)
    local storyCount      = checkint(self.nodeData.storyCount)
    local isSatisfyProgress = value >= storyCount
    local isDrawn = checkint(guestsData.hasDrawn) > 0

    if isSatisfyProgress and not isDrawn then
        self:SendSignal(POST.PRIVATE_ROOM_GUEST_DIALOGUE_DRAW.cmdName, {guestId = self.guestId})
    else
        local guestConf  = self.nodeData.guestConf or {}
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = guestConf.giftId, type = 1})
    end
    
end

return PrivateRoomGuestInfoDescMediator
