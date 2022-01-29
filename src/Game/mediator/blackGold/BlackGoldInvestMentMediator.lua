--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class BlackGoldInvestMentMediator :Mediator
local BlackGoldInvestMentMediator = class("BlackGoldInvestMentMediator", Mediator)
local NAME = "BlackGoldInvestMentMediator"
local BUTTON_TAG = {
	CLOSE_BTN = 1001 ,
	CINVESTMENT_BTN = 1002,
	LINVESTMENT_BTN = 1003,
	TIP_BTN         = 1004,
}
local END_ACTION_EVENT = "END_ACTION_EVENT"   -- 完成事件的回调
local RIGHT_LAYOUT_SHOW_EVENT = "RIGHT_LAYOUT_SHOW_EVENT"
---@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local InvestMentConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.INVESTMENT , 'commerce')
function BlackGoldInvestMentMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.investData ={}
end

function BlackGoldInvestMentMediator:InterestSignals()
	local signals = {
		POST.COMMERCE_INVESTMENTLIST.sglName,
		POST.COMMERCE_INVESTMENT.sglName,
		POST.COMMERCE_INVESTMENT_DRAW.sglName,
		END_ACTION_EVENT
	}
	return signals
end

function BlackGoldInvestMentMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.COMMERCE_INVESTMENTLIST.sglName  then
		if app.blackGoldMgr:GetIsTrade() then
			self.investData = data
		else
			for i = #data.current, 1, -1 do
				if checkint(data.current[i].hasAttend) <= 0 then
					table.remove(data.current , i )
				end
			end
			self.investData = data
		end
		---@type BlackGoldInvestMentView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.cgridView:setCountOfCell(#data.current)
		viewData.cgridView:reloadData()
		if  #data.current == 0 then
			viewComponent:CreateCInvestmentEmpty()
		end
		viewComponent:EnterAction()
	elseif name == POST.COMMERCE_INVESTMENT.sglName  then
		local requestData = data.requestData
		local index = requestData.index
		local investmentId = requestData.investmentId
		self.investData.current[index].hasAttend = 1
		---@type BlackGoldInvestMentView
		local viewComponent = self:GetViewComponent()
		---@type BlackGoldCInvestMentCell
		local cell =  viewComponent.viewData.cgridView:cellAtIndex(index-1)
		if cell and (not (tolua.isnull(cell))) then
			cell:UpdateView(self.investData.current[index])
		end
		local gold = checkint(InvestMentConf[tostring(investmentId)].gold)
		CommonUtils.DrawRewards({{
									 goodsId = GOLD_ID , num = - gold
								 }})
		app.uiMgr:ShowInformationTips(__('投资成功'))
	elseif name == END_ACTION_EVENT  then
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.closeLayer:setOnClickScriptHandler(handler(self, self.ButtonAction))
	elseif name == POST.COMMERCE_INVESTMENT_DRAW.sglName  then
		local requestData = data.requestData
		local index = requestData.index
		self.investData.previous[index].hasDrawn = 1
		---@type BlackGoldInvestMentView
		local viewComponent = self:GetViewComponent()
		---@type BlackGoldLInvestMentCell
		local cell =  viewComponent.viewData.lgridView:cellAtIndex(index-1)
		if cell and (not (tolua.isnull(cell))) then
			cell:UpdateView(self.investData.previous[index])
		end
		app.uiMgr:ShowInformationTips(__('领取投资成功'))
		app.uiMgr:AddDialog("common.RewardPopup" , {rewards = data.rewards })
	end
end


function BlackGoldInvestMentMediator:Initial( key )
	self.super.Initial(self, key)
	---@type BlackGoldInvestMentView
	local viewComponent = require("Game.views.blackGold.BlackGoldInvestMentView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.lastInvestBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.cuurentInvestBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.tipBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.cgridView:setDataSourceAdapterScriptHandler(handler(self, self.CDataSource))
	viewData.lgridView:setDataSourceAdapterScriptHandler(handler(self, self.LDataSource))

	self:DealWithBtnClick(BUTTON_TAG.CINVESTMENT_BTN)
end

function BlackGoldInvestMentMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BUTTON_TAG.CLOSE_BTN then
		AppFacade.GetInstance():UnRegsitMediator(NAME)
	elseif tag == BUTTON_TAG.LINVESTMENT_BTN then -- 往期
		self:DealWithBtnClick(BUTTON_TAG.LINVESTMENT_BTN)
	elseif tag == BUTTON_TAG.TIP_BTN then -- 规则提示
		app.uiMgr:ShowIntroPopup({moduleId = -36 })
	elseif tag == BUTTON_TAG.CINVESTMENT_BTN then -- 当前
		self:DealWithBtnClick(BUTTON_TAG.CINVESTMENT_BTN)
	end
end
function BlackGoldInvestMentMediator:DealWithBtnClick(tag)
	---@type BlackGoldInvestMentView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local curbtn = nil
	local prebtn = nil
	local curView = nil
	local preView = nil
	if tag == BUTTON_TAG.LINVESTMENT_BTN then
		curbtn = viewData.lastInvestBtn
		prebtn = viewData.cuurentInvestBtn
		curView = viewData.LastInvestLayout
		preView = viewData.currentInvestLayout
		local children =  curView:getChildren()
		-- 没有刷刷新过
		if #children == 1  then -- 刷新界面
			if #self.investData.previous > 0  then
				viewData.lgridView:setCountOfCell(#self.investData.previous)
				viewData.lgridView:reloadData()
			else
				viewComponent:CreateLInvestmentEmpty()
			end
		end
	elseif  tag == BUTTON_TAG.CINVESTMENT_BTN then
		curbtn = viewData.cuurentInvestBtn
		prebtn = viewData.lastInvestBtn
		preView	 = viewData.LastInvestLayout
		curView = viewData.currentInvestLayout
	end
	curView:setVisible(true)
	preView:setVisible(false)
	prebtn:setEnabled(true)
	curbtn:setEnabled(false)
	curbtn:getLabel():setColor(ccc3FromInt("#d23d3d"))
	prebtn:getLabel():setColor(ccc3FromInt("#ffffff"))
end

function BlackGoldInvestMentMediator:EnterLayer()
	self:SendSignal(POST.COMMERCE_INVESTMENTLIST.cmdName , {})
end

function BlackGoldInvestMentMediator:CDataSource( p_convertview,idx )
	---@type BlackGoldCInvestMentCell
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = require("Game.views.blackGold.BlackGoldCInvestMentCell").new()
		end
		pCell.viewData.joinInvestBtn:setTag(index)
		display.commonUIParams(pCell.viewData.joinInvestBtn , {cb = handler(self , self.InvestmentClick)})
		pCell:UpdateView(self.investData.current[index])
	end, __G__TRACKBACK__)
	return pCell
end
function BlackGoldInvestMentMediator:LDataSource( p_convertview,idx )
	---@type BlackGoldLInvestMentCell
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = require("Game.views.blackGold.BlackGoldLInvestMentCell").new()
		end
		pCell:UpdateView(self.investData.previous[index])
		pCell.viewData.rewardBtn:setTag(index)
		display.commonUIParams(pCell.viewData.rewardBtn , {cb = handler(self , self.DrawInvestmentClick)})
	end, __G__TRACKBACK__)
	return pCell
end
function BlackGoldInvestMentMediator:InvestmentClick(sender)
	local index = sender:getTag()
	if not app.blackGoldMgr:GetIsTrade() then
		app.uiMgr:ShowInformationTips(__('出海中暂时不能进行投资计划'))
		return
	end
	local currentData = self.investData.current
	local investmentId =  currentData[index].investmentId
	if  checkint(currentData[index].hasAttend) == 1 then
		app.uiMgr:ShowInformationTips(__('不可重复参与投资'))
		return
	end
	local investmentOneConf = InvestMentConf[tostring(investmentId)]
	local goldNum = checkint(investmentOneConf.gold)
	local ownerNum = checkint(CommonUtils.GetCacheProductNum(GOLD_ID))
	local strs = string.split(string.fmt(__('是否消耗|_num_|\n个金币进行投资计划？'),{ _num_ = goldNum}) , "|")
	if ownerNum >=   goldNum then
		local commonTip = require('common.CommonTip').new({
			text = __('是否确认购买') ,
			descrRich =  {
				{text = strs[1], fontSize = 22, color = '#4c4c4c'},
				{text = strs[2], fontSize = 24, color = '#da3c3c'},
				{img = CommonUtils.GetGoodsIconPathById(GOLD_ID), scale = 0.2},
				{text = strs[3], fontSize = 22, color = '#4c4c4c'}
			},
			callback = function()
				self:SendSignal(POST.COMMERCE_INVESTMENT.cmdName ,{investmentId = investmentId , index = index })
			end
		})
		app.uiMgr:GetCurrentScene():AddDialog(commonTip)
		commonTip:setPosition(display.center)
	else
		app.uiMgr:ShowInformationTips(__('金币不足'))
	end
end

function BlackGoldInvestMentMediator:DrawInvestmentClick(sender)
	local index = sender:getTag()
	local previousData = self.investData.previous
	if  checkint(previousData[index].hasDrawn) == 1 then
		app.uiMgr:ShowInformationTips(__('已经领取过投资奖励'))
		return
	end
	local investmentUuid =  previousData[index].investmentUuid
	self:SendSignal(POST.COMMERCE_INVESTMENT_DRAW.cmdName ,{investmentUuid = investmentUuid , index = index })
end
function BlackGoldInvestMentMediator:OnRegist()
	regPost(POST.COMMERCE_INVESTMENTLIST)
	regPost(POST.COMMERCE_INVESTMENT)
	regPost(POST.COMMERCE_INVESTMENT_DRAW)
	self:EnterLayer()
end
function BlackGoldInvestMentMediator:OnUnRegist()
	unregPost(POST.COMMERCE_INVESTMENTLIST)
	unregPost(POST.COMMERCE_INVESTMENT)
	unregPost(POST.COMMERCE_INVESTMENT_DRAW)
	AppFacade.GetInstance():DispatchObservers(RIGHT_LAYOUT_SHOW_EVENT , {})
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return BlackGoldInvestMentMediator
