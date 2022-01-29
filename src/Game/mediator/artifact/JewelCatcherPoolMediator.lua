--[[
	宝石抽取卡池
--]]
local Mediator = mvc.Mediator
---@class JewelCatcherPoolMediator:Mediator
local JewelCatcherPoolMediator = class("JewelCatcherPoolMediator", Mediator)

local NAME = "artifact.JewelCatcherPoolMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function JewelCatcherPoolMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.catchers = {}
    if params then
		self.catchers = params.consume or {}
	end
end

function JewelCatcherPoolMediator:InterestSignals()
	local signals = {
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT
	}

	return signals
end

function JewelCatcherPoolMediator:ProcessSignal(signal )
	local name = signal:GetName()
	if name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateCatcherNum()
	end
end

function JewelCatcherPoolMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.artifact.JewelCatcherPoolView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewData = viewComponent.viewData_
	viewData.shopBtn:setOnClickScriptHandler(handler(self, self.ShopButtonCallback))

	viewData.backBtn:setOnClickScriptHandler(function (sender)
		PlayAudioByClickClose()
		AppFacade.GetInstance():UnRegsitMediator(NAME)
	end)

	local catcherTabsView = viewData.catcherTabsView

	local cellSize = cc.size(350, 390)
	local firstCellSize = cc.size(350 + 100 + display.SAFE_L, 390)

	local isFirstResize = false
	if table.nums(self.catchers) * cellSize.width <= display.SAFE_RECT.width then
		catcherTabsView:setContentSize(cc.size(table.nums(self.catchers) * cellSize.width, cellSize.height))
	else
		isFirstResize = true
		catcherTabsView:setBounceable(true)
	end

	for k, v in orderedPairs(self.catchers) do
		local pCell = viewComponent:createCatcherTab(v, isFirstResize and firstCellSize or cellSize)
		isFirstResize = false
		local clickLayer = pCell:getChildByTag(123)
		clickLayer:setOnClickScriptHandler(function (sender)
			PlayAudioByClickNormal()

			pCell:runAction(
				cc.Sequence:create(
					cc.Spawn:create(
						cc.FadeOut:create(0.2),
						cc.MoveBy:create(0.2, cc.p(30, 30))
					),
					cc.CallFunc:create(function (  )
						local JewelCatcherMediator = require( 'Game.mediator.artifact.JewelCatcherMediator')
						local mediator = JewelCatcherMediator.new(v)
						self:GetFacade():RegistMediator(mediator)

						self:JumpToCatcherView()

						pCell:setOpacity(255)
						pCell:setPosition(cc.p(pCell:getPositionX() - 30, pCell:getPositionY() - 30))
					end)
				)
			)
		end)
		catcherTabsView:insertNodeAtLast(pCell)
		pCell:setOpacity(0)
	end
	
	catcherTabsView:reloadData()
	for i=1,table.nums(self.catchers) do
		local pCell = catcherTabsView:getNodeAtIndex(i - 1)
		pCell:setPosition(cc.p(pCell:getPositionX() - 30, pCell:getPositionY() - 30))
		pCell:runAction(
			cc.Sequence:create(
				-- cc.DelayTime:create((i - 1) * 0.1),
				cc.Spawn:create(
					cc.FadeIn:create(0.2),
					cc.MoveBy:create(0.2, cc.p(30, 30))
				)
			)
		)
	end
end

function JewelCatcherPoolMediator:ShopButtonCallback( sender )
	PlayAudioByClickNormal()
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.PROPS})
	else
		app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'goods'}})
	end
end

-- 跳转到夹娃娃界面
function JewelCatcherPoolMediator:JumpToCatcherView(  )
	local viewData = self.viewComponent.viewData_
	viewData.backBtn:setVisible(false)
	viewData.shopBtn:setVisible(false)
	viewData.catcherTabsView:setVisible(false)
end

-- 从夹娃娃界面回来
function JewelCatcherPoolMediator:JumpBack(  )
	local viewData = self.viewComponent.viewData_
	viewData.backBtn:setVisible(true)
	viewData.shopBtn:setVisible(true)
	viewData.catcherTabsView:setVisible(true)


	for i=1,table.nums(self.catchers) do
		local pCell = viewData.catcherTabsView:getNodeAtIndex(i - 1)
		pCell:setOpacity(0)
		pCell:setPosition(cc.p(pCell:getPositionX() - 30, pCell:getPositionY() - 30))
		pCell:runAction(
			cc.Sequence:create(
				-- cc.DelayTime:create((i - 1) * 0.1),
				cc.Spawn:create(
					cc.FadeIn:create(0.2),
					cc.MoveBy:create(0.2, cc.p(30, 30))
				)
			)
		)
	end
end

function JewelCatcherPoolMediator:OnRegist(  )

end

function JewelCatcherPoolMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end


return JewelCatcherPoolMediator
