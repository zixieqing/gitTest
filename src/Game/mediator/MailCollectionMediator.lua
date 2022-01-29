--[[
邮箱mediator
--]]
local Mediator = mvc.Mediator
local MailCollectionMediator = class("MailCollectionMediator", Mediator)
local NAME = "MailCollectionMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')
local MailCell = require('home.MailCell')
local MailRewardsCell = require('home.MailRewardsCell')
local MAILTYPE = {
	prize = 1,
	notice = 2
}
function MailCollectionMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.mailDatas = {}
	self.preIndex = 1
	self.type = MAILTYPE.prize
end


function MailCollectionMediator:InterestSignals()
	local signals = {
		POST.PRIZE_ENTER_COLLECT.sglName ,
		POST.PRIZE_DELETE_COLLECT.sglName
	}
	return signals
end
local date = require("cocos.framework.date")

function MailCollectionMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data  = signal:GetBody()
	if name == POST.PRIZE_ENTER_COLLECT.sglName  then
		self.mailDatas = checktable(checktable(signal:GetBody()).prizes)
		self.preIndex = 1
		self:RefreshMailList()
	elseif name == POST.PRIZE_DELETE_COLLECT.sglName then
		local prizeId = data.requestData.prizeId
		if prizeId and checkint(prizeId) == 0   then
			self.mailDatas = {}
			self.preIndex = 1
		else
			prizeId = checkint(prizeId)
			for i , v in pairs(self.mailDatas) do
				if checkint(v.prizeId) == prizeId  then
					table.remove(self.mailDatas , i)
					break
				end
			end
		end
		self.preIndex = 1
		self:RefreshMailList()
	end
end

function MailCollectionMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	-- 创建MailPopup
	local viewComponent = require( 'Game.views.MailCollectView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent.viewData.mailListGridView:setDataSourceAdapterScriptHandler(handler(self, self.MailListDataSource))
	viewComponent.viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.DataSourceAction))
	viewComponent.viewData.delColBtn:setOnClickScriptHandler(handler(self, self.GetButtonCallback))
end
--[[
邮件列表处理
--]]
function MailCollectionMediator:MailListDataSource( p_convertview, idx )
	local pCell = p_convertview
	local index = idx + 1
	local cSize = cc.size(306, 106)
	if pCell == nil then
		pCell = MailCell.new(cSize)
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CellButtonAction))
	end
	xTry(function()
		local datas = self.mailDatas[index]
		pCell.nameLabel:setString(datas.title)
		display.commonLabelParams(pCell.nameLabel, {text = datas.title, maxL = 2, w = 200})
		-- 判断是否显示选中框
		pCell.frame:setVisible(index == self.preIndex)
		-- 判断奖励是否领取
		if checkint(datas.hasDrawn) == 1 then
			pCell.unreadIcon:setVisible(false)
			pCell.readIcon:setVisible(true)
			pCell.bgBtn:setNormalImage(_res('ui/mail/mail_bg_list_readed.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/mail/mail_bg_list_readed.png'))
			pCell.nameLabel:setColor(ccc3FromInt('#978888'))
		else
			pCell.unreadIcon:setVisible(true)
			pCell.readIcon:setVisible(false)
			pCell.bgBtn:setNormalImage(_res('ui/mail/mail_bg_list_enread.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/mail/mail_bg_list_enread.png'))
			pCell.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
		end
		pCell.bgBtn:setTag(index)
	end,__G__TRACKBACK__)
	return pCell
end
--[[
领取按钮回调
--]]
function MailCollectionMediator:GetButtonCallback(sender)
	PlayAudioByClickNormal()
	local mailData = self.mailDatas[self.preIndex]
	local prizeId = checkint(mailData.prizeId)
	self:SendSignal(POST.PRIZE_DELETE_COLLECT.cmdName, {prizeId = prizeId})
end
--[[
删除已读按钮回调
--]]
function MailCollectionMediator:DeleteAllBtnCallback(sender)
	PlayAudioByClickNormal()
	local canDelete = false
	-- 判断是否存在已读邮件
	for i, v in ipairs(self.mailDatas) do
		if checkint(v.hasDrawn) == 1 then
			canDelete = true
			break
		end
	end
	if canDelete then
		self:SendSignal(POST.PRIZE_DELETE_COLLECT.cmdName, {prizeId = 0})-- prizeId为0时为删除已读
	else
		uiMgr:ShowInformationTips(__('无已读邮件'))
	end
end

-- 列表单元格点击处理
function MailCollectionMediator:CellButtonAction( sender )
	PlayAudioClip(AUDIOS.UI.ui_click_confirm.id)
	local index = sender:getTag()
	if index == self.preIndex then return end
	--更新按钮状态
	local viewComponent = self:GetViewComponent()
	local mailListGridView = viewComponent.viewData.mailListGridView
	local cell = mailListGridView:cellAtIndex(self.preIndex - 1)
	if cell then
		cell.frame:setVisible(false)
	end
	local selectedCell = mailListGridView:cellAtIndex(index - 1)
	if selectedCell then
		selectedCell.frame:setVisible(true)
	end
	self.preIndex = index
	self:updateDescription(self.preIndex)
end

function MailCollectionMediator:DataSourceAction(pcell, idx)
	local pos = idx + 1
	local cSize = cc.size(110, 106)
	local pCell = pcell
	if pCell == nil then
		pCell = MailRewardsCell.new(cSize)
	end
	xTry(function()
		local datas = self.mailDatas[self.preIndex].rewards[pos]
		pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, amount = datas.num})
		pCell.goodsIcon.callBack = function ( sender )
			PlayAudioByClickNormal()
			AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = datas.goodsId, type = 1})
		end
		pCell.drawnLabel:setVisible(checkint(self.mailDatas[self.preIndex].hasDrawn) == 1)
	end,function(err)
		pCell = CTableViewCell:new()
		__G__TRACKBACK__(err)
	end)
	return pCell
end
--[[
刷新邮件列表
--]]
function MailCollectionMediator:RefreshMailList()
	local viewData = self:GetViewComponent().viewData
	if viewData == nil then return end
	if next(self.mailDatas) ~= nil then
		-- 存在邮件
		viewData.emptyView:setVisible(false)
		viewData.cview:setVisible(true)
		viewData.mailListGridView:setCountOfCell(#self.mailDatas)
		viewData.mailListGridView:reloadData()
		self:updateDescription(self.preIndex)
	else
		-- 不存在邮件
		viewData.emptyView:setVisible(true)
		viewData.cview:setVisible(false)
	end
end
--更新邮件详情
function MailCollectionMediator:updateDescription( index )
	local viewData = self:GetViewComponent().viewData
	viewData.delColBtn:setEnabled(true)
	if self.mailDatas and table.nums(self.mailDatas) > 0 then
		viewData.delColBtn:setVisible(true)
		-- 邮件标题
		display.commonLabelParams(viewData.titleLabel,{text = tostring(self.mailDatas[index].title), ap = cc.p(0, 1), fontSize = 24, color = '#ba5c5c', maxW = 380})
		if self.type == MAILTYPE.prize then -- 奖励类型
			viewData.awardBg:setVisible(true)
			local lsize = viewData.scrollView:getContentSize()
			display.commonUIParams(viewData.descrLabel, { po = cc.p(10,212)})
			viewData.scrollView:setContentSize(cc.size(lsize.width, 280))
			viewData.tableView:setVisible(true)
			self:CheckGoodsIsExist(index)
			viewData.tableView:setCountOfCell(table.nums(checktable(self.mailDatas[index].rewards)))
			viewData.tableView:reloadData()
		elseif self.type == MAILTYPE.notice then -- 通知类型
			viewData.awardBg:setVisible(false)
			viewData.tableView:setVisible(false)
			local lsize = viewData.scrollView:getContentSize()
			display.commonUIParams(viewData.descrLabel, { po = cc.p(10,376)})
			viewData.scrollView:setContentSize(cc.size(lsize.width, 422))
		end
		-- 正文
		local content = tostring(self.mailDatas[index].content)
		display.commonLabelParams(viewData.descrLabel, fontWithColor(6, {text = content}))
		-- scroll to top
		local descrSize  = display.getLabelContentSize(viewData.descrLabel)
		local scrollSize = viewData.scrollView:getContentSize()
		viewData.descrLabel:setPositionY(math.max(0, scrollSize.height - descrSize.height))
		viewData.scrollView:setContainerSize(cc.size(scrollSize.width, math.max(descrSize.height, scrollSize.height)))
		viewData.scrollView:setContentOffsetToTop()
	end
end
-- 检测道具是否存在
function MailCollectionMediator:CheckGoodsIsExist(index)
	local rewards = self.mailDatas[index].rewards or {}
	if  #rewards > 0  then
		for i = #rewards , 1, -1 do
			local goodsId = rewards[i].goodsId
			local goodConf = CommonUtils.GetConfig('goods','goods',goodsId )
			if goodConf and table.nums(goodConf) > 0  then

			else
				table.remove(rewards , i )
			end
		end
		self.mailDatas[index].rewards = rewards
	end

end

function MailCollectionMediator:OnRegist(  )
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	regPost(POST.PRIZE_ENTER_COLLECT)
	regPost(POST.PRIZE_DELETE_COLLECT)
	--发前请求
	self:SendSignal(POST.PRIZE_ENTER_COLLECT.cmdName, {})
end

function MailCollectionMediator:OnUnRegist(  )
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	unregPost(POST.PRIZE_ENTER_COLLECT)
	unregPost(POST.PRIZE_DELETE_COLLECT)
end
return MailCollectionMediator
