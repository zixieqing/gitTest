--[[
活动Mediator
--]]
local Mediator = mvc.Mediator

local FacebookInviteMediator = class("FacebookInviteMediator", Mediator)

local NAME = "FacebookInviteMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local ActivityTabCell = require('home.ActivityTabCell')
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local WebSprite  = require('root.WebSprite')

INVITE_FRIEND_BUTTON = 2000

local BASE_ACTIVITY = {
			{title = '邀請好友', activityId = INVITE_FRIEND_BUTTON, type = INVITE_FRIEND_BUTTON},
			{title = '邀請獎勵', activityId = INVITE_FRIEND_BUTTON + 1, type = INVITE_FRIEND_BUTTON + 1},
		}




local function CreateInviteCellView()
	local size = cc.size(1014, 110)
	local view = CLayout:create(size)
    local cellBg = display.newImageView(_res('share/facebook_invite_bg'),size.width * 0.5, size.height * 0.5)
    view:addChild(cellBg)
    local roleWebSprite = require('root.CCHeaderNode').new({bg = _res('ui/author/create_roles_head_down_default.png'), pre = 500077})
    display.commonUIParams(roleWebSprite, {po = cc.p(94, size.height * 0.5)})
    roleWebSprite:setScale(0.5)
    view:addChild(roleWebSprite,1)

    local nameLabel = display.newLabel(154, size.height/2, fontWithColor(15, {text = '', ap = display.LEFT_CENTER, fontSize = 26}))
    view:addChild(nameLabel,1)

    local pushBtn = display.newCheckBox(size.width - 100, size.height * 0.5,
        { ap = display.RIGHT_CENTER  , n = _res('share/common_btn_check_unselected') ,
        s= _res('share/common_btn_check_selected')  } )
    view:addChild(pushBtn,1)
    return {
        view = view,
        roleWebSprite = roleWebSprite,
        nameLabel  = nameLabel,
        checkButton = pushBtn,
    }
end
local function CreateInviteView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 奖励列表
    local gridViewSize = cc.size(1014, 452)
    local gridViewCellSize = cc.size(1014, 110)
    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(cc.p(0, 0))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(10, 88))
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    view:addChild(gridView, 10)
	-- 转盘按钮
	local onekeyInviteButton = display.newButton(720, 46, {n = _res('ui/common/common_btn_big_orange.png')})
	-- onekeyInviteButton:setVisible(false)
	view:addChild(onekeyInviteButton, 10)
	display.commonLabelParams(onekeyInviteButton, fontWithColor(14,{text = '壹鍵邀請', color = '#ffffff'}))
	local checkAllButton = display.newButton(896, 46, {n = _res('ui/common/common_btn_big_orange.png')})
	display.commonLabelParams(checkAllButton, fontWithColor(14,{text = '全選', color = '#ffffff'}))
	view:addChild(checkAllButton, 10)
	-- checkAllButton:setVisible(false)

	return {
		view 			 = view,
		gridView         = gridView,
        onekeyInviteButton = onekeyInviteButton,
        checkAllButton = checkAllButton
	}
end


--奖励页面显示
local function CreateRewardView()
    local size = cc.size(1035, 637)
    local view = CLayout:create(size)
	-- 奖励列表
    local gridViewSize = cc.size(1014, 518)
    local gridViewCellSize = cc.size(1014, 172)
    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(cc.p(0, 0))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(10, 18))
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    view:addChild(gridView, 10)

    local topBg = display.newImageView(_res('share/facebook_banner'),size.width * 0.5,size.height - 4)
    display.commonUIParams(topBg, {ap = display.CENTER_TOP})
    view:addChild(topBg,2)

    local numLabel = display.newLabel(topBg:getContentSize().width * 0.5, topBg:getContentSize().height * 0.5, fontWithColor(7, {fontSize = 28, color = 'a87543', text = ''}))
    topBg:addChild(numLabel,1)
    return {
		view 			 = view,
		gridView         = gridView,
        numLabel         = numLabel,
	}

end

local function CreateRewardCellView()
	local size = cc.size(1014, 172)
	local view = CLayout:create(size)
    local cellBg = display.newImageView(_res('share/facebook_gifts_bg'),size.width * 0.5, size.height * 0.5)
    view:addChild(cellBg)

    local numLabel = display.newRichLabel(24, size.height - 14,{ ap = display.LEFT_TOP, r = true, c = {
            {fontSize = 24 , color = "6c6c6c" , text =  string.fmt('邀请数达到num1_/num2_', {num1_ = '0', num2_ = '0'}) }
        }})
    view:addChild(numLabel,1)

    local rewardView = CLayout:create(cc.size(824,128))
    display.commonUIParams(rewardView, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
    view:addChild(rewardView,2)

    local rewardButton = display.newButton(size.width - 24, size.height * 0.5, {
            n = _res('ui/common/common_btn_orange'), ap = display.RIGHT_CENTER
        })
    display.commonLabelParams(rewardButton, fontWithColor(14, {text = '领取'}))
    view:addChild(rewardButton,2)
    return {
        view = view,
        numLabel = numLabel,
        rewardView = rewardView,
        rewardButton = rewardButton
    }
end

function FacebookInviteMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local datas = params or {}
	self.showLayer = {}
    self.selectedTab = INVITE_FRIEND_BUTTON
    self.indexes = {} --选中的所有列表
    self.isAll = false --是否是选中所有的逻辑
    self.datas = {}
    self.rewardDatas = {} --奖励数据列表的数据
	local scene = uiMgr:GetCurrentScene()
	local viewComponent = uiMgr:SwitchToTargetScene('Game.views.FacebookInviteView')
	self:SetViewComponent(viewComponent)
end

function FacebookInviteMediator:InterestSignals()
	local signals = {
        'FACEBOOK_EVENT',
        POST.FACEBOOK_REWARD_HOME.sglName,
        POST.FACEBOOK_INVITE_FRIENDS.sglName,
        POST.FACEBOOK_DRAW_REWARDS.sglName,
	}
	return signals
end

function FacebookInviteMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local body = signal:GetBody()
	if name == 'FACEBOOK_EVENT' then
        if body.type == 'facebook' and body.cmd == 'invitable' then
            --可邀请的好友列表
            if body.state == 'failed' then
                --失败的情况
                uiMgr:ShowInformationTips('拉取邀請好友失敗~~')
            else
                --成功的情况
                self.datas = checktable(body.friends)
                self:TabButtonCallback(self.selectedTab)
                if self.selectedTab == INVITE_FRIEND_BUTTON then
                    local inviteViewData = self.showLayer[tostring(INVITE_FRIEND_BUTTON)]
                    if inviteViewData then
                        inviteViewData.view:setVisible(true)
                        if table.nums(self.datas) > 0 then
                            inviteViewData.gridView:setCountOfCell(table.nums(self.datas))
                            inviteViewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.InviteDatasource))
                            inviteViewData.gridView:reloadData()
                            inviteViewData.checkAllButton:setName('CHECKALL')
                            inviteViewData.onekeyInviteButton:setName('ONEKEY')
                            inviteViewData.onekeyInviteButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
                            inviteViewData.checkAllButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
                        end
                    end
                end
            end
        end
    elseif name == POST.FACEBOOK_REWARD_HOME.sglName then
        self.rewardDatas = checktable(body)
        self:TabButtonCallback(INVITE_FRIEND_BUTTON + 1)
    elseif name == POST.FACEBOOK_INVITE_FRIENDS.sglName then
        --邀请好友的结果请求
        uiMgr:ShowInformationTips('邀請好友請求已發送~~')
    elseif name == POST.FACEBOOK_DRAW_REWARDS.sglName then
        --领取奖励请求响应
        local inviteRewardId = checkint(body.requestData.inviteRewardId)
        CommonUtils.DrawRewards(checktable(body.rewards))
        local data = nil
        for name,val in pairs(checktable(self.rewardDatas.inviteRewards)) do
            if inviteRewardId == checkint(val.id) then
                data = val
                return
            end
        end
        uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(body.rewards),addBackpack = false})
        if data then
            data.hasDrawn = 1
			local viewData = self.showLayer[tostring(self.selectedTab)]
            viewData.gridView:reloadData()
        end
	end
end

function FacebookInviteMediator:ActivityTabDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(212, 88)

    if pCell == nil then
        pCell = ActivityTabCell.new(cSize)
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
    end
	xTry(function()
		-- if self.activityTabDatas[index].showRemindIcon > 0 then
		-- 	pCell.tipsIcon:setVisible(true)
		-- else
		pCell.tipsIcon:setVisible(false)
		-- end
		pCell.nameLabel:setString(BASE_ACTIVITY[index].title)
		pCell.bgBtn:setTag(checkint(BASE_ACTIVITY[index].activityId))
		if checkint(BASE_ACTIVITY[index].activityId) == checkint(self.selectedTab) then
			pCell.bgBtn:setChecked(true)
		else
			pCell.bgBtn:setChecked(false)
		end
	end,__G__TRACKBACK__)
    return pCell
end

--[[
活动页签点击回调
--]]
function FacebookInviteMediator:TabButtonCallback( sender )
	local tag = 0
	local viewData = self:GetViewComponent().viewData
	local gridView = viewData.gridView
	if type(sender) == 'number' then
		tag = sender
	else
        PlayAudioByClickNormal()
		tag = sender:getTag()
		if self.selectedTab == tag then
			gridView:cellAtIndex(tag - INVITE_FRIEND_BUTTON).bgBtn:setChecked(true)
			return
		else
			-- 添加点击音效
			PlayAudioByClickNormal()
			if self.showLayer[tostring(self.selectedTab)] then
				self.showLayer[tostring(self.selectedTab)].view:setVisible(false)
			end
			self.selectedTab = tag

			local offset = gridView:getContentOffset()
			gridView:reloadData()
			gridView:setContentOffset(offset)
		end
	end
	if self.showLayer[tostring(self.selectedTab)] then
        if self.selectedTab == INVITE_FRIEND_BUTTON then
            local inviteViewData = self.showLayer[tostring(INVITE_FRIEND_BUTTON)]
            inviteViewData.view:setVisible(true)
            if table.nums(self.datas) > 0 then
                inviteViewData.gridView:setCountOfCell(table.nums(self.datas))
                inviteViewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.InviteDatasource))
                inviteViewData.gridView:reloadData()
                inviteViewData.checkAllButton:setName('CHECKALL')
                inviteViewData.onekeyInviteButton:setName('ONEKEY')
                inviteViewData.onekeyInviteButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
                inviteViewData.checkAllButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
            end
        else
            local inviteViewData = self.showLayer[tostring(INVITE_FRIEND_BUTTON + 1)]
            inviteViewData.view:setVisible(true)
            if table.nums(checktable(self.rewardDatas.inviteRewards)) > 0 then
                inviteViewData.gridView:setCountOfCell(table.nums(checktable(self.rewardDatas.inviteRewards)))
                inviteViewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.InviteRewardDatasource))
                inviteViewData.gridView:reloadData()
                inviteViewData.numLabel:setString(string.fmt('成功邀請facebook好友：__num', {__num = checkint(self.rewardDatas.inviteFaceBookNum)}))
                -- inviteViewData.rewardButton:setName('REWARDBUTTON')
                -- inviteViewData.rewardButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
            end
        end
    else
        self:SwitchView(tag)
    end
end

function FacebookInviteMediator:ButtonActions(sender)
    PlayAudioByClickNormal()
    local name = sender:getName()
    if name == 'CHECKALL' then
        --选中把有
        local viewData = self.showLayer[tostring(self.selectedTab)]
        if not self.isAll then
            --更新列表,与选中的数据集合
            self.isAll = true
            viewData.checkAllButton:setText('取消全選')
            viewData.gridView:reloadData()
        else
            self.isAll = false
            viewData.checkAllButton:setText('全選')
            viewData.gridView:reloadData()
        end
    elseif name == 'ONEKEY' then
        --一键邀请
        if table.nums(self.indexes) > 0 then
            if isEfunSdk() then
                local datas = {}
                for index,val in pairs(self.indexes) do
                    table.insert(datas, self.datas[checkint(index)].id)
                end
                require('root.AppSDK').GetInstance():efunInvitFriendsRequest(datas)
            end
        else
            local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
            uiMgr:ShowInformationTips('請選中要邀請的好友')
        end
    elseif name == 'ITEM_CHECK' then
        local index = sender:getUserTag()
        if sender:isChecked() then
            self.indexes[tostring(index)] = index
        else
            self.indexes[tostring(index)] = nil
        end
        dump(self.indexes)
    elseif name == 'REWARDBUTTON' then
        local index = sender:getUserTag()
        if table.nums(checktable(self.rewardDatas.inviteRewards)) > 0 then
            local data = self.rewardDatas.inviteRewards[index]
            if data then
                if checkint(data.hasDrawn) == 1 then
                    uiMgr:ShowInformationTips('獎勵已領取~~')
                else
                    if checkint(data.inviteNum) <= checkint(self.rewardDatas.inviteFaceBookNum) then
                        --可领取的逻辑
                        self:SendSignal(POST.FACEBOOK_DRAW_REWARDS.cmdName, {inviteRewardId = checkint(data.id)})
                    else
                        local viewData = self:GetViewComponent().viewData
                        local gridView = viewData.gridView
                        local tab = gridView:cellAtIndex(0)
                        self:TabButtonCallback(tab.bgBtn)
                    end
                end
            end
        end
    end
end

function FacebookInviteMediator:SwitchView(tab)
    local viewData = self:GetViewComponent().viewData
    if tab == INVITE_FRIEND_BUTTON then
        local inviteViewData = CreateInviteView()
        display.commonUIParams(inviteViewData.view,{ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
        viewData.ActivityLayout:addChild(inviteViewData.view, 10)
		self.showLayer[tostring(tab)] = inviteViewData
        inviteViewData.view:setVisible(false)
    else
        local inviteViewData = CreateRewardView()
        display.commonUIParams(inviteViewData.view,{ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
        viewData.ActivityLayout:addChild(inviteViewData.view, 10)
        self.showLayer[tostring(tab)] = inviteViewData
        inviteViewData.view:setVisible(false)
        -- inviteViewData.rewardButton:setName('REWARDBUTTON')
        -- inviteViewData.rewardButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    end
end

function FacebookInviteMediator:InviteDatasource(p_cell, idx)
    local pCell = p_cell
    local index = idx + 1
    local cSize = cc.size(1014, 110)
    if pCell == nil then
        pCell = CGridViewCell:new()
    end
    xTry(function()
        pCell:removeChildByName('INVITECELL')
        local viewData = CreateInviteCellView()
        display.commonUIParams(viewData.view,{po = cc.p(cSize.width * 0.5, cSize.height * 0.5)})
        viewData.view:setName('INVITECELL')
        pCell:setContentSize(cSize)
        pCell:addChild(viewData.view)
        --更新其他数据
        if self.isAll then
            viewData.checkButton:setChecked(true)
        else
            if self.indexes[tostring(index)] then
                viewData.checkButton:setChecked(true)
            else
                viewData.checkButton:setChecked(false)
            end
        end
        viewData.checkButton:setName("ITEM_CHECK")
        viewData.checkButton:setUserTag(index)
        viewData.checkButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
        local data = self.datas[index]
        if data then
            viewData.roleWebSprite.headerSprite:setWebURL(data.thumbnail)
            viewData.nameLabel:setString(data.name)
        end
    end,__G__TRACKBACK__)
    return pCell
end

function FacebookInviteMediator:InviteRewardDatasource(p_cell, idx)
    local pCell = p_cell
    local index = idx + 1
    local cSize = cc.size(1014, 172)
    if pCell == nil then
        pCell = CGridViewCell:new()
    end
    xTry(function()
        pCell:removeChildByName('REWARDCELL')
        local viewData = CreateRewardCellView()
        display.commonUIParams(viewData.view,{po = cc.p(cSize.width * 0.5, cSize.height * 0.5)})
        viewData.view:setName('REWARDCELL')
        pCell:setContentSize(cSize)
        pCell:addChild(viewData.view)
        --更新其他数据
        local data = checktable(self.rewardDatas.inviteRewards)[index]
        if data then
            display.reloadRichLabel(viewData.numLabel,{c = {
                {fontSize = 24 , color = "6c6c6c" , text =  string.fmt('邀请数达到num1_/num2_', {num1_ = tostring(self.rewardDatas.inviteFaceBookNum), num2_ = checkint(data.inviteNum)}) } }
            })
            viewData.rewardButton:setName('REWARDBUTTON')
            viewData.rewardButton:setUserTag(index)
            if checkint(data.hasDrawn) == 1 then
                viewData.rewardButton:setText('已領取')
            else
                if checkint(data.inviteNum) <= checkint(self.rewardDatas.inviteFaceBookNum) then
                    --可领取的逻辑
                    viewData.rewardButton:setText('領取')
                else
                    viewData.rewardButton:setText('去邀請')
                end
            end
            viewData.rewardButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
            viewData.rewardView:removeAllChildren()
            if table.nums(data.rewards) > 0 then
                --添加奖励节点
                local x,y = 0,70
                for idx,v in ipairs(data.rewards) do
                    x = 66 + (idx - 1) * 116
                    local goodsNode = require('common.GoodNode').new({id = checkint(v.goodsId), showAmount = false,callBack = function(sender)
                        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender:getTag(), type = 1})
                    end})
                    goodsNode:setTag(checkint(v.goodsId))
                    display.commonUIParams(goodsNode, {po = cc.p(x, y)})
                    goodsNode:setScale(0.8)
                    viewData.rewardView:addChild(goodsNode, 5)
                end
            end
        end
    end,__G__TRACKBACK__)
    return pCell
end


function FacebookInviteMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	local viewData = self:GetViewComponent().viewData
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ActivityTabDataSource))
	viewData.gridView:setCountOfCell(#BASE_ACTIVITY)
	viewData.gridView:reloadData()
    if isEfunSdk() then
        require('root.AppSDK').GetInstance():efunGetInvitableFriends()
    end
    regPost(POST.FACEBOOK_REWARD_HOME)
    regPost(POST.FACEBOOK_INVITE_FRIENDS)
    regPost(POST.FACEBOOK_DRAW_REWARDS)

    self:SendSignal(POST.FACEBOOK_REWARD_HOME.cmdName)
    --[[
    AppFacade.GetInstance():DispatchObservers(POST.FACEBOOK_REWARD_HOME.sglName, {
            inviteFaceBookNum = 4, inviteRewards = {
                {id = 1, inviteNum = 1,hasDrawn = 0, rewards = {
                        {goodsId = 900001,goodsNum = 29},
                        {goodsId = 900001,goodsNum = 29},
                }},
                {id = 2, inviteNum = 5,hasDrawn = 0, rewards = {
                        {goodsId = 900001,goodsNum = 29},
                        {goodsId = 900001,goodsNum = 29},
                }}

            }
        })
    AppFacade.GetInstance():DispatchObservers('FACEBOOK_EVENT', {
            type = 'facebook', cmd = 'invitable', state = '1',
            friends = {
                {id = 'AVm_nQII5t0iRxmuqYAMPMAokkTodcdT_mboyoGeLwjqbxahiuiFbS9My1ZKgS69GAzTI1ZeIS9WMoywlvsSGFQ-Vz6vWkrqpkyh5uq_ms_I4g',name = 'debugger',
                thumbnail = "https://scontent.xx.fbcdn.net/v/t1.0-1/p320x320/1465291_1374870526099551_31915585_n.jpg?oh=9caff3481a07326454e20d9867449192&oe=5AE00D31"},
                {id = 'AVm_nQII5t0iRxmuqYAMPMAokkTodcdT_mboyoGeLwjqbxahiuiFbS9My1ZKgS69GAzTI1ZeIS9WMoywlvsSGFQ-Vz6vWkrqpkyh5uq_ms_I4g',name = 'debugger',
                thumbnail = "https://scontent.xx.fbcdn.net/v/t1.0-1/p320x320/1465291_1374870526099551_31915585_n.jpg?oh=9caff3481a07326454e20d9867449192&oe=5AE00D31"},
                {id = 'AVm_nQII5t0iRxmuqYAMPMAokkTodcdT_mboyoGeLwjqbxahiuiFbS9My1ZKgS69GAzTI1ZeIS9WMoywlvsSGFQ-Vz6vWkrqpkyh5uq_ms_I4g',name = 'debugger',
                thumbnail = "https://scontent.xx.fbcdn.net/v/t1.0-1/p320x320/1465291_1374870526099551_31915585_n.jpg?oh=9caff3481a07326454e20d9867449192&oe=5AE00D31"},
                {id = 'AVm_nQII5t0iRxmuqYAMPMAokkTodcdT_mboyoGeLwjqbxahiuiFbS9My1ZKgS69GAzTI1ZeIS9WMoywlvsSGFQ-Vz6vWkrqpkyh5uq_ms_I4g',name = 'debugger',
                thumbnail = "https://scontent.xx.fbcdn.net/v/t1.0-1/p320x320/1465291_1374870526099551_31915585_n.jpg?oh=9caff3481a07326454e20d9867449192&oe=5AE00D31"},
            }
        })
        --]]
end

function FacebookInviteMediator:OnUnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.FACEBOOK_REWARD_HOME)
    unregPost(POST.FACEBOOK_INVITE_FRIENDS)
    unregPost(POST.FACEBOOK_DRAW_REWARDS)
end
return FacebookInviteMediator
