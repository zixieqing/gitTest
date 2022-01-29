local Mediator = mvc.Mediator
local CastleCardBounsMediator = class("CastleCardBounsMediator", Mediator)
local NAME = "CastleCardBounsMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local CarnieExCapsuleCell = require( 'Game.views.summerActivity.carnie.CarnieExCapsuleCell' )
function CastleCardBounsMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.day = checkint(params.day) or 1
	self.keysTableSort = nil
	self.cardAdditionTable = nil
end


function CastleCardBounsMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function CastleCardBounsMediator:ProcessSignal( signal )
	local name = signal:GetName()
end

function CastleCardBounsMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent = require( 'Game.views.castle.CastleCardBounsView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)

	viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
	self.cardAdditionTable = self:GetData()
	self.keysTableSort = table.keys(self.cardAdditionTable)
	if #self.keysTableSort >= 2  then
		table.sort(self.keysTableSort , function(a, b )
			if checkint(a) < checkint(b)then
				return true
			end
			return false
		end)
	end
	-- dump(self.keysTableSort)
	-- dump(self.cardAdditionTable)
	self:RefreshGridView()
end

function CastleCardBounsMediator:GetData()
	local cardAdditionConf =clone(CommonUtils.GetConfigAllMess('cardAddition' , 'springActivity'))
	local cardAdditionTable = {}
	for i, v in pairs(cardAdditionConf) do
		if not  cardAdditionTable[v.to] then
			cardAdditionTable[ v.to] = {
				essentialCards = {
				}
			}
		end
		for index, cardId in pairs(v.essentialCards) do
			cardAdditionTable[v.to].essentialCards[#cardAdditionTable[v.to].essentialCards+1] =cardId
		end
		cardAdditionTable[v.to].from = v.from
		cardAdditionTable[v.to].to = v.to
	end

	return cardAdditionTable
end
function CastleCardBounsMediator:RefreshGridView()
	local viewData =self:GetViewComponent().viewData
	viewData.gridView:setCountOfCell(#self.keysTableSort)
	viewData.gridView:reloadData()

end
--[[
列表处理
--]]
function CastleCardBounsMediator:GridViewDataSource( p_convertview, idx )
	---@type CarnieExCapsuleCell
	local pCell = p_convertview
	local index = idx +1
	local data = self.cardAdditionTable[tostring(self.keysTableSort[index])]
	local cSize = self:GetViewComponent().viewData.gridViewCellSize
	if not pCell then
		pCell = CarnieExCapsuleCell.new(cSize)
	end
	xTry(function()
		display.commonLabelParams(pCell.dateLabel , {text = string.fmt(app.activityMgr:GetCastleText(__('第_num1_-_num2_天')) , { _num1_ = data.from , _num2_ = data.to }) })
		if self.day >= checkint(data.from) and self.day <= checkint(data.to)  then
			pCell.selectedBg:setVisible(true)
		else
			pCell.selectedBg:setVisible(false)
		end
		pCell.rewardsLayout:removeAllChildren()
		local essentialCards = data.essentialCards
		local count = #essentialCards
		for i =1 , count  do
			-- print("--------------------->>>")
			local cardHeadNode = require("common.CardHeadNode").new({cardData = {cardId =essentialCards[i] }})
			cardHeadNode:setPosition( ((i - 0.5)  - count/2) * 98   +  cSize.width/2 , 50 )
			cardHeadNode:setScale(0.5)
			pCell.rewardsLayout:addChild(cardHeadNode)
		end
	end,__G__TRACKBACK__)
	return pCell

end
function CastleCardBounsMediator:OnRegist(  )
end

function CastleCardBounsMediator:OnUnRegist(  )
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return CastleCardBounsMediator