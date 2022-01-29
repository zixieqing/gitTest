--[[
好友求助Mediator
--]]
local Mediator = mvc.Mediator

local FriendDonationMediator = class("FriendDonationMediator", Mediator)

local NAME = "FriendDonationMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local FriendMyRequestCell = require('home.FriendMyRequestCell')
local FriendRequestCell = require('home.FriendRequestCell')
local scheduler = require('cocos.framework.scheduler')

function FriendDonationMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local datas = checktable(params) or {}
	self.assistanceList   = {} -- 捐助列表
	self.myAssistanceList = datas.assistanceDoneList or {} -- 协助列表
	self.assistanceLimit  = checkint(datas.assistanceLimit) -- 协助次数上限
	self.assistanceNum    = checkint(datas.assistanceNum) -- 剩余协助次数
	for k,v in pairs(checktable(datas.assistanceList)) do
		table.insert(self.assistanceList, v)
	end
	-- 创建定时器
	if next(self.assistanceList) ~= nil then
		self.schedule = scheduler.scheduleGlobal(handler(self, self.UpdateRemainTime), 1)
		self.enterTimeStamp = os.time()
	end 
end

function FriendDonationMediator:InterestSignals()
	local signals = { 
		SIGNALNAMES.Friend_Assistance_Callback,
	}
	return signals
end

function FriendDonationMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	print(name)
	if name == SIGNALNAMES.Friend_Assistance_Callback then
		local data = checktable(signal:GetBody())
		uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(data.rewards), mainExp = checkint(data.mainExp)})
		local index = nil 
		for i,v in ipairs(self.assistanceList) do
			if v.id == data.requestData.assistanceId then
				CommonUtils.DrawRewards({{goodsId = v.goodsId, num = -1}})
				table.remove(self.assistanceList, i)
				break
			end
		end
		local viewData = self:GetViewComponent().viewData_
		viewData.friendRequestGridView:setCountOfCell(#self.assistanceList)
		viewData.friendRequestGridView:reloadData()
		-- 刷新次数
		self.assistanceNum = self.assistanceNum - 1
		self:UpdateAssistanceTimes()
		-- 刷新小红点
		if #self.assistanceList == 0 then
			local mediator = AppFacade.GetInstance():RetrieveMediator('FriendMediator')
			mediator:RefreshTabStatus(false)
		end
	end
end

function FriendDonationMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.FriendDonationView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent.viewData_.myRequestGridView:setDataSourceAdapterScriptHandler(handler(self, self.MyRequestDataSourceAction))
	viewComponent.viewData_.friendRequestGridView:setDataSourceAdapterScriptHandler(handler(self, self.FriendRequestDataSourceAction))
	viewComponent.viewData_.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	viewComponent.viewData_.myRequestGridView:setCountOfCell(#self.myAssistanceList)
	viewComponent.viewData_.myRequestGridView:reloadData()
	viewComponent.viewData_.friendRequestGridView:setCountOfCell(#self.assistanceList)
	viewComponent.viewData_.friendRequestGridView:reloadData()
	if #self.assistanceList == 0 then
	   local richLabel  = viewComponent:CreateNoFriendNeedHelp()
		viewComponent.viewData_.friendRequestLayout:addChild(richLabel,20)
	end
	self:UpdateAssistanceTimes()
end
--[[
我的求助列表处理
--]]
function FriendDonationMediator:MyRequestDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(380, 150)
    if pCell == nil then
    	pCell = FriendMyRequestCell.new(cSize)
    end
	xTry(function()
		local datas = self.myAssistanceList[index]
		if datas.assistanceFriend then
			pCell.nameLabel:setVisible(true)
			pCell.nameLabel:setString(datas.assistanceFriend.name)
			pCell.timeLabel:setString(datas.assistanceTime)
			pCell.avatarIcon:setVisible(true)
			pCell.avatarIcon:RefreshSelf({level = datas.assistanceFriend.level, avatar = datas.assistanceFriend.avatar, datas.assistanceFriend.avatarFrame})
			pCell.donateLabel:setVisible(true)
			pCell.bg:setTexture(_res('ui/home/friend/friends_bg_help_frame_2.png'))
			pCell.helpLabel:setVisible(false)

		else
			pCell.nameLabel:setString(datas.name)
			pCell.timeLabel:setString(datas.createTime)
			pCell.avatarIcon:setVisible(false)
			pCell.nameLabel:setVisible(false)
			pCell.donateLabel:setVisible(false)
			pCell.helpLabel:setVisible(true)
			pCell.bg:setTexture(_res('ui/home/friend/friends_bg_help_frame_me.png'))
		end
		
		pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, amount = 1})
		display.commonUIParams(pCell.goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = datas.goodsId, type = 1})
		end})
	end,__G__TRACKBACK__)
    return pCell
end
--[[
好友求助列表处理
--]]
function FriendDonationMediator:FriendRequestDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(638, 150)
    if pCell == nil then
    	pCell = FriendRequestCell.new(cSize)
    	pCell.presentBtn:setOnClickScriptHandler(handler(self, self.PresentButtonCallback))
    end
	xTry(function()
		local datas = self.assistanceList[index]
		-- 通过id获取好友数据
		local friendDatas = {} 
		for i,v in ipairs(gameMgr:GetUserInfo().friendList) do
			if checkint(datas.playerId) == checkint(v.friendId) then
				friendDatas = v
			end
		end	
		pCell.nameLabel:setString(datas.name)
		pCell.avatarIcon:RefreshSelf({level = friendDatas.level or 1,avatar = friendDatas.avatar})
		pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, amount = 1})
		pCell.timeLabel:setString(self:ChangeTimeFormat(datas.expireTime))
		display.commonUIParams(pCell.goodsIcon, {animate = false, cb = function (sender)
			uiMgr:AddDialog("common.GainPopup", {goodId = datas.goodsId})
		end})
		pCell.amountLabel:setString(string.fmt(__('您有：_num_'), {['_num_'] = gameMgr:GetAmountByGoodId(datas.goodsId)}))
		pCell.presentBtn:setTag(index)
	end,__G__TRACKBACK__)
    return pCell
end
--[[
好友求助捐赠按钮回调
--]]
function FriendDonationMediator:PresentButtonCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local goodsId = self.assistanceList[tag].goodsId
	local nums = gameMgr:GetAmountByGoodId(tonumber(goodsId))
	if nums > 0 then
		if checkint(self.assistanceNum) <= 0 then
			uiMgr:ShowInformationTips(__('捐助次数不足'))
		else
			self:SendSignal(COMMANDS.COMMAND_Friend_Assistance, {assistanceId = self.assistanceList[tag].id})
		end
	else
		uiMgr:ShowInformationTips(__('菜品不足'))
	end
end
--[[
好友求助帮助按钮回调
--]]
function FriendDonationMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
	local descr = __('        1.御侍大人在配送外卖时，若遇到还没有研发或者制作的菜品，可以通过求助好友的形式来完成外卖的配送。\n        2.御侍大人可以同时向20个好友求助，让好友捐赠菜品。\n        3.御侍大人进行求助后，需要等待30分钟后才能进行下一次的求助。\n        4.好友捐助菜品后，御侍大人可以去邮箱领取好友捐助的菜品。\n        5.若是帮助好友进行捐赠，可以得到金币，调味料，厨力等奖励，更有幻晶石，体力，稀有资源等惊喜等你拿。')
	uiMgr:ShowIntroPopup({title = __('好友求助规则说明'), descr = descr})
end
--[[
更新捐助次数
--]]
function FriendDonationMediator:UpdateAssistanceTimes()
	local viewData = self:GetViewComponent().viewData_
	local timesLabel = viewData.timesLabel

	display.commonLabelParams(timesLabel , { text = string.fmt(__('今日捐赠次数 _num1_/_num2_'), {['_num1_'] = self.assistanceNum, ['_num2_'] = self.assistanceLimit})})
	local timesLabelSize = display.getLabelContentSize(timesLabel)
	if timesLabelSize.width > 190 then
		display.commonLabelParams(timesLabel , { fontSize = 20 , w = 200 ,hAlign = display.TAC, reqW = 190, text = string.fmt(__('今日捐赠次数 _num1_/_num2_'), {['_num1_'] = self.assistanceNum, ['_num2_'] = self.assistanceLimit})})
	end
	--timesLabel:setString(string.fmt(__('今日捐赠次数 _num1_/_num2_'), {['_num1_'] = self.assistanceNum, ['_num2_'] = self.assistanceLimit}))
end
--[[
定时器回调
--]]
function FriendDonationMediator:UpdateRemainTime()
	local curTime = os.time()
	local deltaTime = math.abs(curTime - self.enterTimeStamp)
	self.enterTimeStamp = curTime
	if next(self.assistanceList) ~= nil then
		local gridView = self:GetViewComponent().viewData_.friendRequestGridView
		for i,v in ipairs(self.assistanceList) do
			v.expireTime = checkint(v.expireTime) - deltaTime
			if checkint(v.expireTime) > 0 then
				if gridView:cellAtIndex(i-1) then
					gridView:cellAtIndex(i-1).timeLabel:setString(self:ChangeTimeFormat(v.expireTime))
				end
			else
				table.remove(self.assistanceList, i)
				gridView:setCountOfCell(#self.assistanceList)
				gridView:reloadData()
			end
		end
	end
end
--[[
时间格式转换
--]]
function FriendDonationMediator:ChangeTimeFormat( seconds )
	local str = ''
	if seconds < 60 then
		str = str .. string.fmt(__('_num_秒后过期'), {['_num_'] = seconds})
	elseif seconds < 3600 then
		str = str .. string.fmt(__('_num1_分_num2_秒后过期'), {['_num1_'] = math.ceil(seconds/60), ['_num2_'] = seconds%60})
	elseif seconds < 86400 then
		str = str .. string.fmt(__('_num_小时后过期'), {['_num_'] = math.ceil(seconds/3600)})
	else
		str = str .. string.fmt(__('_num_天后过期'), {['_num_'] = math.ceil(seconds/86400)})
	end
	return str
end
function FriendDonationMediator:OnRegist(  )
	local FriendDonationCommand = require('Game.command.FriendDonationCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_Assistance, FriendDonationCommand)
end

function FriendDonationMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	local scene = uiMgr:GetCurrentScene()
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_Assistance)
	scene:RemoveGameLayer(self.viewComponent)
	if self.schedule then
		scheduler.unscheduleGlobal(self.schedule)
	end
end

return FriendDonationMediator
