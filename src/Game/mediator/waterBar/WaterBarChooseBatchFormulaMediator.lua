--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息中介者
]]
---@class WaterBarChooseBatchFormulaMediator:Mediator
local WaterBarChooseBatchFormulaMediator = class('WaterBarChooseBatchFormulaMediator', mvc.Mediator)
local NAME = "WaterBarChooseBatchFormulaMediator"
local waterBarMgr = app.waterBarMgr
local BuTTON_CLICK_TAGS = {
	ZERO_STAR   = 1000,
	ONE_STAR    = 1001,
	TWO_STAR    = 1002,
	THREE_STAR  = 1003,
	CLOSE_LAYER = 1004,
}
function WaterBarChooseBatchFormulaMediator:ctor(params, viewComponent)
	self.super.ctor(self, 'WaterBarChooseBatchFormulaMediator', viewComponent)
	params = params or  {}
	self.formulaId = params.formulaId
	self.oneFormulas = {}
	self.formulas = {
		["0"] = {formula = {} , count = 0},
		["1"] = {formula = {} , count = 0} ,
		["2"] = {formula = {} , count = 0} ,
		["3"] = {formula = {} , count = 0}

	} -- 调酒的配方
end
-------------------------------------------------
-- inheritance

function WaterBarChooseBatchFormulaMediator:InterestSignals()
	return {
		POST.WATER_BAR_FORMULA.sglName
	}
end
function WaterBarChooseBatchFormulaMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.WATER_BAR_FORMULA.sglName  then
		local formulas = body.formula
		for index, formula in pairs(formulas) do
			local star = tostring(formula.star)
			self.formulas[star].count =  self.formulas[star].count+1
			self.formulas[star].formula[self.formulas[star].count] = formula
		end
		local selectStarTag =  BuTTON_CLICK_TAGS.THREE_STAR
		for i = 3 , 0 , -1 do
			if self.formulas[tostring(i)].count > 0  then
				self.oneFormulas = self.formulas[tostring(i)]
				selectStarTag = 1000 + i
				break
			end
		end
		self:DealWithStarFormula(selectStarTag)
	end
end

function WaterBarChooseBatchFormulaMediator:Initial(key)
	self.super.Initial(self, key)
	---@type WaterBarChooseBatchFormulaView
	local viewComponent = require("Game.views.waterBar.WaterBarChooseBatchFormulaView").new()
	viewComponent:setPosition(display.center)
	self:SetViewComponent(viewComponent)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.closeLayer , { cb = handler(self, self.ButtonClick)})
	for i, btn in pairs(viewData.selectFormulaTable) do
		display.commonUIParams(btn, { cb = handler(self, self.StarFormulaClick)})
	end
end
function WaterBarChooseBatchFormulaMediator:ButtonClick(sender)
	local tag = sender:getTag()
	if tag == BuTTON_CLICK_TAGS.CLOSE_LAYER then
		self:GetFacade():UnRegistMediator(NAME)
	end
end
function WaterBarChooseBatchFormulaMediator:StarFormulaClick(sender)
	local tag = sender:getTag()
	self:DealWithStarFormula(tag)
end
function WaterBarChooseBatchFormulaMediator:ReloadDataGride()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.formulaGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDatSources))
	viewData.formulaGridView:setCountOfCell(self.oneFormulas.count)
	viewData.formulaGridView:reloadData()
	if self.oneFormulas.count == 0 then
		viewComponent:SetVisible(true)
	else
		viewComponent:SetVisible(false)
	end
end
function WaterBarChooseBatchFormulaMediator:DealWithStarFormula(tag)
	---@type WaterBarChooseBatchFormulaView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	for btnTag, btn  in pairs(viewData.selectFormulaTable) do
		if checkint(btnTag) == tag then
			display.commonLabelParams(btn , {color ="#dc5817"  , text = btn:getText()})
			btn:setEnabled(false)
		else
			display.commonLabelParams(btn , {color ="#dbc5b8"  , text = btn:getText()})
			btn:setEnabled(true)
		end
	end
	local star = tostring(tag -1000)
	self.oneFormulas = self.formulas[star]
	self:ReloadDataGride()
end

function WaterBarChooseBatchFormulaMediator:OnDatSources(cell , idx)
	local pcell = cell
	local index = idx +1
	local data = self.oneFormulas.formula[index]
	---@type WaterBarChooseBatchFormulaView
	local viewComponent =self:GetViewComponent()
	if not  pcell then
		pcell = viewComponent:CreateCell()
		local viewData = pcell.viewData
		local useFormulaBtn = viewData.useFormulaBtn
		display.commonUIParams(useFormulaBtn , { cb = handler(self, self.CellClcik)})
	end
	viewComponent:UpdateCell(pcell , data.material)
	local viewData = pcell.viewData
	local useFormulaBtn = viewData.useFormulaBtn
	useFormulaBtn:setTag(index)
	return pcell
end



function WaterBarChooseBatchFormulaMediator:CellClcik(sender)
	local index = sender:getTag()
	local consumeMaterialData = {
		{materialId = 0 , num = 0 } ,
		{materialId = 0 , num = 0 } ,
		{materialId = 0 , num = 0 } ,
		{materialId = 0 , num = 0 } ,
	}
	local formula = self.oneFormulas.formula
	local materials = formula[index].material
	for i = 1, #materials do
		consumeMaterialData[i].materialId = materials[i].goodsId
		consumeMaterialData[i].num = materials[i].num
	end
	self:GetFacade():DispatchObservers("USE_BATCH_FORMULA_EVENT" , {
		drinkId = formula[index].drinkId ,
		consumeMaterialData = consumeMaterialData
	})
	self:GetFacade():UnRegistMediator(NAME)
end



function WaterBarChooseBatchFormulaMediator:CleanupView()

end

function WaterBarChooseBatchFormulaMediator:EnterLayer()
	self:SendSignal(POST.WATER_BAR_FORMULA.cmdName , {formulaId = self.formulaId})
end
function WaterBarChooseBatchFormulaMediator:OnRegist()
	regPost(POST.WATER_BAR_FORMULA)
	self:EnterLayer()
end

function WaterBarChooseBatchFormulaMediator:OnUnRegist()
	unregPost(POST.WATER_BAR_FORMULA)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end
return WaterBarChooseBatchFormulaMediator
