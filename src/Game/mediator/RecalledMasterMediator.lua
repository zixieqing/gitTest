--[[
    召回的玩家列表Mediator
--]]
local Mediator = mvc.Mediator

local RecalledMasterMediator = class("RecalledMasterMediator", Mediator)

local NAME = "RecalledMasterMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecalledMasterMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.args = checktable(params) or {}
    if not self.args.recallPlayers then
        self.args.recallPlayers = {}
    end
end

function RecalledMasterMediator:InterestSignals()
	local signals = { 
        SIGNALNAMES.Friend_PopupAddFriend_Callback
	}

	return signals
end

function RecalledMasterMediator:ProcessSignal( signal )
	local name = signal:GetName() 
    local datas = signal:GetBody()
    if name == SIGNALNAMES.Friend_PopupAddFriend_Callback then
        uiMgr:ShowInformationTips(__('好友邀请已发送'))
    end
end

function RecalledMasterMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecalledMasterView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData_

    local gridView = viewData.gridView
    gridView:setCountOfCell(table.nums(self.args.recallPlayers) or 0)
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    gridView:reloadData()
end

function RecalledMasterMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(520, 124)
    local tempData = self.args.recallPlayers[index]
   	if pCell == nil then
        pCell = CGridViewCell:new()
        pCell:setContentSize(sizee)

        local cellBg = display.newImageView(_res('ui/common/common_bg_list'), 260, 62, {scale9 = true, size = cc.size(252*2, 58*2)})
        pCell:addChild(cellBg)

		local nameLabel = display.newLabel(136, 92, {fontSize = 24, color = '#5b3c25', ap = display.LEFT_CENTER})
        pCell:addChild(nameLabel)
        pCell.nameLabel = nameLabel

		local desrLabel = display.newLabel(138, 72, fontWithColor(6, {w = 220, hAlign = display.TAL, ap = display.LEFT_TOP, text = ''}))
        pCell:addChild(desrLabel)
        pCell.desrLabel = desrLabel

        -- 玩家信息
	    local playerHeadNodeScale = 0.6
	    local playerHeadNode = require('common.PlayerHeadNode').new({
	    	avatar = 1,
            avatarFrame = 500143,
            playerLevel = 33,
	    	showLevel = true,
	    })
	    playerHeadNode:setScale(playerHeadNodeScale)
	    display.commonUIParams(playerHeadNode, {po = cc.p(70, 62)})
        pCell:addChild(playerHeadNode)
        pCell.playerHeadNode = playerHeadNode

        local addFriendButton = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(addFriendButton, {po = cc.p(
			440,
			sizee.height / 2
		)})
		display.commonLabelParams(addFriendButton, fontWithColor('14', {text = __('打招呼')}))
        pCell:addChild(addFriendButton)
        addFriendButton:setOnClickScriptHandler(handler(self,self.CellButtonAction))
        pCell.addFriendButton = addFriendButton
    end
    xTry(function()
        pCell.addFriendButton:setTag(index)
        pCell.nameLabel:setString(tempData.name)
        pCell.desrLabel:setString(__('填写了你的召回码回到了缇尔菈大陆'))
        pCell.playerHeadNode:RefreshUI({
	    	avatar = tempData.avatar,
            avatarFrame = tempData.avatarFrame,
            playerLevel = tempData.level,
	    })
	end,__G__TRACKBACK__)
    return pCell
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function RecalledMasterMediator:CellButtonAction( sender )
    PlayAudioByClickNormal()
	local index = sender:getTag()
    local tempData = self.args.recallPlayers[index]
    for k,v in pairs(gameMgr:GetUserInfo().friendList) do
        if checkint(v.friendId) == checkint(tempData.playerId) then
            uiMgr:ShowInformationTips(__('你们已经是好友了~'))
            return
        end
    end
    if checkint(gameMgr:GetUserInfo().playerId) ~= checkint(tempData.playerId) then
        httpManager:Post("friend/addFriend", SIGNALNAMES.Friend_PopupAddFriend_Callback, {friendId = checkint(tempData.playerId)})
    end
end

function RecalledMasterMediator:OnRegist(  )
end

function RecalledMasterMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecalledMasterMediator