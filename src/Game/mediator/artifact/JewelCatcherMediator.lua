--[[
	宝石抽取
--]]
local Mediator = mvc.Mediator

local JewelCatcherMediator = class("JewelCatcherMediator", Mediator)

local NAME = "artifact.JewelCatcherMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
local parseConfig = artiMgr:GetConfigParse()

function JewelCatcherMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.catcher = {}
    if params then
		self.catcher = params or {}
	end
end

function JewelCatcherMediator:InterestSignals()
	local signals = {
		POST.ARTIFACT_GEM_LUCKY.sglName,
		EVENT_GOODS_COUNT_UPDATE
	}
	return signals
end

function JewelCatcherMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.ARTIFACT_GEM_LUCKY.sglName then
		local viewData = self.viewComponent.viewData_
		local catcherSpine = viewData.catcherSpine
		local mouseSpine = viewData.mouseSpine

		local function showEvolResult( isSkip )
			catcherSpine:setToSetupPose()
			catcherSpine:setAnimation(0, "idle", true)
			
			CommonUtils.DrawRewards({{goodsId = tostring(body.consume[1].goodsId), num = 0 - checkint(body.consume[1].num)}})
			body.blingLimit = self.catcher.highLight
			if 1 == body.requestData.times then -- 单抽
				CommonUtils.DrawRewards(body.rewards)

				local JewelCatcherRewardsView = require("Game.views.artifact.JewelCatcherRewardsView")
				local layer = JewelCatcherRewardsView.new(body)
				layer:updateData(body.rewards)
				layer:setPosition(display.center)
				uiMgr:GetCurrentScene():AddDialog(layer)
			else -- 十连
				if isSkip then
					uiMgr:AddDialog('common.RewardPopup', body)
				else
					local JewelCatcherTenRewardsView = require("Game.views.artifact.JewelCatcherTenRewardsView")
					local layer = JewelCatcherTenRewardsView.new(body)
					layer:updateData(body.rewards)
					layer:setPosition(display.center)
					uiMgr:GetCurrentScene():AddDialog(layer)
				end
			end

			self:UpdateCatcherNum(  )
		end

		local playAniName = 'play1'
		if 1 ~= body.requestData.times then
			playAniName = 'play2'
		end
		catcherSpine:setAnimation(0, playAniName, false)
		
		catcherSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)

		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    	eaterLayer:setTouchEnabled(true)
    	eaterLayer:setContentSize(display.size)
    	eaterLayer:setPosition(cc.p(display.cx, display.cy))
		self.viewComponent:addChild(eaterLayer, 1000)
		eaterLayer:setOnClickScriptHandler(function(sender)
			showEvolResult(true)
			if eaterLayer and  (not tolua.isnull(eaterLayer)) then
				eaterLayer:removeFromParent()
				eaterLayer = nil 
			end
		end)
	
		catcherSpine:registerSpineEventHandler(function (event)
			if event.animation == 'play1' or event.animation == 'play2' then
				showEvolResult()
				if eaterLayer and  (not tolua.isnull(eaterLayer)) then
					eaterLayer:removeFromParent()
					eaterLayer = nil 
				end
			end
		end, sp.EventType.ANIMATION_COMPLETE)
	elseif name == EVENT_GOODS_COUNT_UPDATE then
		self:UpdateCatcherNum(  )
	end
end

function JewelCatcherMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.artifact.JewelCatcherView' ).new(self.catcher)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewData = viewComponent.viewData_
	viewData.shopBtn:setOnClickScriptHandler(handler(self, self.ShopButtonCallback))
	viewData.backBtn:setOnClickScriptHandler(function (sender)
		PlayAudioByClickClose()

		local mediator = AppFacade.GetInstance():RetrieveMediator("artifact.JewelCatcherPoolMediator")
		if mediator then
			mediator:JumpBack()
		end

		AppFacade.GetInstance():UnRegsitMediator(NAME)
	end)

	viewData.tenBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
	viewData.oneBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))

	viewData.ruleBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickNormal()
		local gemstoneRate = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_RATE)[self.catcher.pool]
		local available = {}
		local function pairsByKeys(t)      
			local a = {}      
			for n in pairs(t) do          
				a[#a+1] = n      
			end      
			table.sort(a, function ( a, b )
				return checkint(a) < checkint(b)
			end)      
			local i = 0      
			return function()          
			i = i + 1          
			return a[i], t[a[i]]      
			end  
		end
		for k,v in pairsByKeys(gemstoneRate) do
			table.insert( available,{descr = v.descr, rate = v.displayPro} )
		end

		local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = available})
		display.commonLabelParams(capsuleProbabilityView.viewData_.title, fontWithColor(18, {text = __('塔可概率')}))
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(capsuleProbabilityView)
	end)

	self:UpdateCatcherNum(  )
end

function JewelCatcherMediator:DrawButtonCallback( sender )
	PlayAudioByClickNormal()
	local times = {1, 10}
	local cost = {}
	if 1 == sender:getTag() then -- 单抽出奇迹
		cost = self.catcher.oneConsumeGoods[1]
	else	-- 十连有保底
		cost = self.catcher.tenConsumeGoods[1]
	end
	if next(cost) then
		if gameMgr:GetAmountByGoodId(cost.goodsId) < cost.num then
			uiMgr:AddDialog("common.GainPopup", {goodId = cost.goodsId})
			uiMgr:ShowInformationTips(__('道具不足'))
			return 
		end
	end
	self:SendSignal(POST.ARTIFACT_GEM_LUCKY.cmdName, {clipId = self.catcher.id, times = times[sender:getTag()]})
end

-- 更新夹子数量	
function JewelCatcherMediator:UpdateCatcherNum(  )
	local cost = self.catcher.oneConsumeGoods[1].goodsId
	local viewData = self.viewComponent.viewData_
	viewData.ownLabel:setString(gameMgr:GetAmountByGoodId(cost))
end

function JewelCatcherMediator:ShopButtonCallback( sender )
	PlayAudioByClickNormal()
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.PROPS})
	else
		app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'goods'}})
	end
end

function JewelCatcherMediator:OnRegist(  )
	regPost(POST.ARTIFACT_GEM_LUCKY)

end

function JewelCatcherMediator:OnUnRegist(  )
	unregPost(POST.ARTIFACT_GEM_LUCKY)

	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return JewelCatcherMediator
