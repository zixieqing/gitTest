---@class ScratcherSouvenirMediator : Mediator
---@field viewComponent ScratcherSouvenirView
local ScratcherSouvenirMediator = class('ScratcherSouvenirMediator', mvc.Mediator)

local NAME = "ScratcherSouvenirMediator"

function ScratcherSouvenirMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
    local data = checktable(params) or {}
	self.activityHomeData = data.activityHomeData
	self.stampHomeData = data.stampHomeData
	local parameter = CONF.FOOD_VOTE.PARMS:GetValue(self.activityHomeData.groupId)
	self.parameter = parameter
end

function ScratcherSouvenirMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherSouvenirView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    
	viewData.eaterLayer:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))

	local haveStampMap = {}
	for _, value in ipairs(self.stampHomeData.stamp or {}) do
		haveStampMap[tostring(value)] = true
	end

	local collectted = 0
	for i, v in ipairs(self.parameter.stamp) do
		local goodsConfig = CommonUtils.GetConfig('goods', 'goods', v) or {}
		local x = 88 + (i-1)%6*147
		local y = 584 - math.floor( (i-1)/6 )*167
		
		if haveStampMap[tostring(v)] ~= true then
			local lockImage = display.newImageView(_res('ui/scratcher/cardmatch_ticket_head_bg_lock.png'), x, y,
			{
				ap = display.CENTER,
			})
			viewData.Panel_1:addChild(lockImage)
		else
			collectted = collectted + 1
			local gainImage = display.newImageView(_res('ui/scratcher/cardmatch_ticket_head_bg.png'), x, y,
			{
				ap = display.CENTER,
			})
			viewData.Panel_1:addChild(gainImage, 1)
			
			local goodsIcon = CommonUtils.GetGoodsIconNodeById(v, x, y)
			viewData.Panel_1:addChild(goodsIcon, 2)
		end

		local nameLabel = display.newLabel(x, y - 70, fontWithColor('16', {fontSize = 20, text = goodsConfig.name, w = 140, ap = cc.p(0.5, 1), hAlign = display.TAC}))
		viewData.Panel_1:addChild(nameLabel, 3)
	end
	
	viewData.reward1:RefreshSelf(self.parameter.stampRewards1[1])
	viewData.reward2:RefreshSelf(self.parameter.stampRewards2[1])
	viewData.reward1:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
	viewData.reward2:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))

	viewData.target1:setString(string.format( "%d/%d", collectted, self.parameter.stampTarget1 ))
	viewData.target2:setString(string.format( "%d/%d", collectted, self.parameter.stampTarget2 ))
	viewData.progressBar:setMaxValue(#self.parameter.stamp)
	viewData.progressBar:setValue(collectted)

	viewData.reward1GainImage:setVisible(self.parameter.stampTarget1 <= collectted)
	viewData.reward2GainImage:setVisible(self.parameter.stampTarget2 <= collectted)
end

function ScratcherSouvenirMediator:OnRegist()
end

function ScratcherSouvenirMediator:OnUnRegist()
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherSouvenirMediator:InterestSignals()
    local signals = {
	}
	return signals
end

function ScratcherSouvenirMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
end

function ScratcherSouvenirMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickClose()
	
    app:UnRegsitMediator(NAME)
end

function ScratcherSouvenirMediator:OnCellRewardBtnClickHandler( sender )
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconId = checkint(sender.goodId), type = 1
	})
end

return ScratcherSouvenirMediator
