--[[
邮箱mediator
--]]
local Mediator = mvc.Mediator
local MailMediator = class("MailMediator", Mediator)
local NAME = "MailMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')
local MailCell = require('home.MailCell')
local MailRewardsCell = require('home.MailRewardsCell')
local MAILTYPE = {
	prize = 1,
	notice = 2
}
function MailMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.mailDatas = {}
	self.preIndex = 1
	self.type = MAILTYPE.prize
end


function MailMediator:InterestSignals()
	local signals = {
	SIGNALNAMES.Mail_Name_Callback,
	SIGNALNAMES.Mail_Get_Callback,
	SIGNALNAMES.Mail_Delete_Callback,
	POST.PRIZE_COLLECT.sglName
	}
	return signals
end

local date = require("cocos.framework.date")

function MailMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Mail_Name_Callback then
		self.mailDatas = checktable(checktable(signal:GetBody()).prizes)
		self.preIndex = 1
		self:SortMailDatas()
		self:RefreshMailList()
		local viewComponent = self:GetViewComponent()
		if GAME_MODULE_OPEN.MAIL_COLLECTION and (not tolua.isnull(viewComponent)) then
			local viewData = viewComponent.viewData
			viewData.collectBtn:setEnabled(true)
			viewData.collectBtn:setChecked(false)
		end

	elseif name == SIGNALNAMES.Mail_Get_Callback then
		local body = signal:GetBody() or {}
		if body.requestData.prizeId == 0 or self.type == MAILTYPE.prize then
			-- 更新月卡
			gameMgr:UpdateMember(body.member)
			
			--奖励的列表的逻辑
			local reward = body.rewards or {}
			--弹卡的逻辑页面展示
			uiMgr:AddDialog('common.RewardPopup', {rewards = reward, mainExp = checkint(signal:GetBody().mainExp)})
			CommonUtils.RefreshDiamond(body)
		end
		self:SendSignal(COMMANDS.COMMAND_Mail)
	elseif name == SIGNALNAMES.Mail_Delete_Callback then
		self:SendSignal(COMMANDS.COMMAND_Mail)
	elseif name == POST.PRIZE_COLLECT.sglName then
		app.uiMgr:ShowInformationTips(__('收藏成功'))


		self:SendSignal(COMMANDS.COMMAND_Mail)

	end
end

function MailMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	-- 创建MailPopup
	local viewComponent = require( 'Game.views.MailView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent.viewData.mailListGridView:setDataSourceAdapterScriptHandler(handler(self, self.MailListDataSource))
	viewComponent.viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.DataSourceAction))
	viewComponent.viewData.getBtn:setOnClickScriptHandler(handler(self, self.GetButtonCallback))
	viewComponent.viewData.deleteAllBtn:setOnClickScriptHandler(handler(self, self.DeleteAllBtnCallback))
	viewComponent.viewData.drawAllBtn:setOnClickScriptHandler(handler(self, self.DrawAllBtnCallback))
	if GAME_MODULE_OPEN.MAIL_COLLECTION then
		viewComponent.viewData.collectBtn:setOnClickScriptHandler(handler(self, self.CollectMailBtnCallback))
	end
	if not self.updateHandler then
		self.updateHandler = scheduler.scheduleGlobal(handler(self, self.TimeUpdate), 1)
	end
end
--[[
邮件列表处理
--]]
function MailMediator:MailListDataSource( p_convertview, idx )
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
		-- pCell.fromLabel:setString(datas.from or '')
		local effectLabelText = self:ChangeEffectTimeFormat(datas.effectTime)
		pCell.dateLabel:setString(tostring(effectLabelText))
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
function MailMediator:GetButtonCallback(sender)
	PlayAudioByClickNormal()
	local mailData = self.mailDatas[self.preIndex] or {}
	local prizeId = checkint(mailData.prizeId)
	if checkint(mailData.hasDrawn) == 1 then
		self:SendSignal(COMMANDS.COMMAND_Mail_Delete, {prizeId = prizeId})
	else	
		self:SendSignal(COMMANDS.COMMAND_Mail_Draw, {prizeId = prizeId})
	end
end

function MailMediator:CollectMailBtnCallback(sender)
	PlayAudioByClickNormal()
	local mailData = self.mailDatas[self.preIndex]
	local prizeId = checkint(mailData.prizeId)
	if checkint(mailData.hasDrawn)  == 1 then
		sender:setEnabled(false)
		self:SendSignal(POST.PRIZE_COLLECT.cmdName, {prizeId = prizeId})
	else
		app.uiMgr:ShowInformationTips(__('领取奖励后才可以收藏邮件'))
		sender:setChecked(false)
	end

end
--[[
删除已读按钮回调
--]]
function MailMediator:DeleteAllBtnCallback( sender )
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
		self:SendSignal(COMMANDS.COMMAND_Mail_Delete, {prizeId = 0})-- prizeId为0时为删除已读
	else
		uiMgr:ShowInformationTips(__('无已读邮件'))
	end
end
--[[
一键领取按钮回调
--]]
function MailMediator:DrawAllBtnCallback( sender )
	PlayAudioByClickNormal()
	local canDraw = false
	-- 判断是否存在已读邮件
	for i, v in ipairs(self.mailDatas) do
		if checkint(v.hasDrawn) == 0 then
			canDraw = true
			break
		end
	end
	if canDraw then
		self:SendSignal(COMMANDS.COMMAND_Mail_Draw, {prizeId = 0}) -- prizeId为0时为一键领取
	else
		uiMgr:ShowInformationTips(__('无可领取邮件'))
	end
end

-- 列表单元格点击处理
function MailMediator:CellButtonAction( sender )
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

function MailMediator:DataSourceAction(pcell, idx)
	local pos = idx + 1
	local cSize = cc.size(110, 106)
	local pCell = pcell
    if pCell == nil then
        pCell = MailRewardsCell.new(cSize)
    end
	xTry(function()
        local datas = self.mailDatas[self.preIndex].reward[pos]
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
function MailMediator:RefreshMailList()
	local viewData = self:GetViewComponent().viewData
	if next(self.mailDatas) ~= nil then
		-- 存在邮件
		viewData.emptyView:setVisible(false)
		viewData.cview:setVisible(true)
		viewData.mailListGridView:setCountOfCell(#self.mailDatas)
		viewData.mailListGridView:reloadData()
		self:updateDescription(self.preIndex)
	else
		-- 不存在邮件
		if self.updateHandler then
			scheduler.unscheduleGlobal(self.updateHandler)
		end
		viewData.emptyView:setVisible(true)
		viewData.cview:setVisible(false)
	end
	self:UpdateRedPoint()
end
--更新邮件详情
function MailMediator:updateDescription( index )
	local viewData = self:GetViewComponent().viewData
	viewData.getBtn:setEnabled(true)
	if GAME_MODULE_OPEN.MAIL_COLLECTION then
		viewData.collectBtn:setChecked(false)
	end
	if self.mailDatas and table.nums(self.mailDatas) > 0 then
		viewData.getBtn:setVisible(true)
		-- 邮件标题
		display.fixLabelText(viewData.titleLabel,{text = tostring(self.mailDatas[index].title), maxW = 464})
		if self.mailDatas[index].reward and table.nums(self.mailDatas[index].reward) > 0 then
			self.type = MAILTYPE.prize
		else
			self.type = MAILTYPE.notice
		end
		-- 更新剩余时间
		viewData.timeLabel:setString(self:ChangeTime(self.mailDatas[index].expirationTime))
		-- 判断邮件类型
		if self.type == MAILTYPE.prize then -- 奖励类型
			viewData.awardBg:setVisible(true)
			local lsize = viewData.scrollView:getContentSize()
			display.commonUIParams(viewData.descrLabel, { po = cc.p(10,212)})
			viewData.scrollView:setContentSize(cc.size(lsize.width, 280))
			if checkint(self.mailDatas[index].hasDrawn) == 1 then
				viewData.getBtn:setText(__('删除'))
				viewData.getBtn:setNormalImage(_res('ui/common/common_btn_white_default.png'))
				viewData.getBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
			else
				viewData.getBtn:setText(__('领取'))
				viewData.getBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
				viewData.getBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			end
			viewData.tableView:setVisible(true)
			viewData.tableView:setCountOfCell(table.nums(checktable(self.mailDatas[index].reward)))
			viewData.tableView:reloadData()
		elseif self.type == MAILTYPE.notice then -- 通知类型
			if checkint(self.mailDatas[index].hasDrawn) == 1 then
				viewData.getBtn:setText(__('删除'))
				viewData.getBtn:setNormalImage(_res('ui/common/common_btn_white_default.png'))
				viewData.getBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
			else
				viewData.getBtn:setText(__('我知道了'))
				viewData.getBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
				viewData.getBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			end
			viewData.awardBg:setVisible(false)
			viewData.tableView:setVisible(false)
			local lsize = viewData.scrollView:getContentSize()
			display.commonUIParams(viewData.descrLabel, { po = cc.p(10,376)})
			viewData.scrollView:setContentSize(cc.size(lsize.width, 422))
		end
		-- 判断是否为常驻邮件（prizeId小于0为常驻邮件）
		if tonumber(self.mailDatas[index].prizeId) < 0 then
			viewData.getBtn:setVisible(false)
		else
			viewData.getBtn:setVisible(true)
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
		self:RefreshListBtnState()
	end
end
--[[
更新列表按钮状态
--]]
function MailMediator:RefreshListBtnState()
	local canDelete = false
	local canDraw = false
	for i, v in ipairs(self.mailDatas) do
		if checkint(v.hasDrawn) == 1 then
			canDelete = true
		else 
			canDraw = true
		end
		if canDelete and canDraw then break end
	end
	local viewData = self:GetViewComponent().viewData
	if canDraw then
		viewData.drawAllBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
		viewData.drawAllBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
	else
		viewData.drawAllBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		viewData.drawAllBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	end
	if canDelete then
		viewData.deleteAllBtn:setNormalImage(_res('ui/common/common_btn_white_default.png'))
		viewData.deleteAllBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
	else
		viewData.deleteAllBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		viewData.deleteAllBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	end
end
-- 定时器回调函数
function MailMediator:TimeUpdate(  )
	for i,v in ipairs(self.mailDatas) do
		v.expirationTime = v.expirationTime - 1
	end
    local deadline = checkint(checktable(self.mailDatas[self.preIndex]).expirationTime)
	if self.preIndex ~= 0 and deadline > 0 then
		local deadline = checkint(checktable(self.mailDatas[self.preIndex]).expirationTime)
		local viewData = self:GetViewComponent().viewData
		viewData.timeLabel:setString(self:ChangeTime(deadline))
	end
end
function MailMediator:ChangeTime( seconds )
	local c = nil
	if checkint(seconds) >= 86400 then
		local day = math.floor(seconds/86400)
		local hour = math.floor((seconds%86400)/3600)
		c = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day),['_num2_'] = tostring(hour)})
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	end
	return c
end
--[[
转换生效时间格式
--]]
function MailMediator:ChangeEffectTimeFormat( effectTime )
	local timeVal = math.abs( date.diff(os.time(), effectTime):spanseconds() )
	local lDay     = math.floor(timeVal / 86400)
	local lHour    = math.floor((timeVal - 86400 * lDay) / 3600)
	local lMinute  = math.floor((timeVal - 86400 * lDay - lHour*3600) / 60)
	local timeText = ''
	if lDay ~= 0  then
		timeText = string.fmt(__('_num_天前'), {_num_ = lDay})
	elseif lHour ~= 0 then
		timeText = string.fmt(__('_num_小时前'), {_num_ = lHour})
	elseif lMinute ~= 0 then
		timeText = string.fmt(__('_num_分钟前'), {_num_ = lMinute})
	else
		timeText = string.fmt(__('_num_秒前'), {_num_ = timeVal})
	end
	return timeText
end
--[[
更新邮件功能小红点
--]]
function MailMediator:UpdateRedPoint()
	local status = false
    local noDrawRewardNum = 0
	for i, v in ipairs(self.mailDatas) do
        if checkint(v.hasDrawn) == 0 then
            noDrawRewardNum = noDrawRewardNum + 1
        end
	end
    if noDrawRewardNum > 0 then
        AppFacade.GetInstance():GetManager("DataManager"):AddRedDotNofication(tostring(RemindTag.MAIL), RemindTag.MAIL)
    else
        AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.MAIL), RemindTag.MAIL)
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MAIL})
end
--[[
邮件排序
--]]
function MailMediator:SortMailDatas()
	table.sort(self.mailDatas, function (a, b)
		if checkint(a.hasDrawn) == checkint(b.hasDrawn) then
			return checkint(a.effectTime) > checkint(b.effectTime)
		else
			return checkint(a.hasDrawn) < checkint(b.hasDrawn)
		end
	end)
end
function MailMediator:OnRegist(  )
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	local MailCommand = require( 'Game.command.MailCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Mail, MailCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Mail_Draw, MailCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Mail_Delete, MailCommand)
	regPost(POST.PRIZE_COLLECT)
	--发前请求
	self:SendSignal(COMMANDS.COMMAND_Mail)
end

function MailMediator:OnUnRegist(  )
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Mail)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Mail_Draw)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Mail_Delete)
	unregPost(POST.PRIZE_COLLECT)
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end
return MailMediator
