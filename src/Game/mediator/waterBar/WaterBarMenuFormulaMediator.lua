--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息中介者
]]
---@class WaterBarMenuFormulaMediator:Mediator
local WaterBarMenuFormulaMediator = class('WaterBarMenuFormulaMediator', mvc.Mediator)
local NAME = "WaterBarMenuFormulaMediator"
local waterBarMgr = app.waterBarMgr
----@type  WaterBarDrinkCell
local WaterBarDrinkCell = require("Game.views.waterBar.WaterBarDrinkCell")
local BUTTON_CLICK= {
	RECONCILE_TAG = 1004 ,
}
local KIND_OF_TABLE = {
	ALL_DRINKS  = 1001, -- 全部饮料
	FRUIT_DRINT = 1002, -- 水果饮料
	WINS_DRINT  = 1003, -- 酒
}
function WaterBarMenuFormulaMediator:ctor(params, viewComponent)
	self.super.ctor(self, 'WaterBarMenuFormulaMediator', viewComponent)
	params = params or {}
	self.selectKindTag = params.selectKindTag or KIND_OF_TABLE.ALL_DRINKS
	self.selectCellTag = 1
	self.ctorArgs_ = checktable(params)
	self.formulaList = {}
	self.selectFormulaId = params.formulaId
end
-------------------------------------------------
-- inheritance

function WaterBarMenuFormulaMediator:InterestSignals()
	return {
		POST.WATER_BAR_FORMULA_LIKE.sglName
	}
end
function WaterBarMenuFormulaMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.WATER_BAR_FORMULA_LIKE.sglName  then
		local requestData = body.requestData
		local formulaIds = requestData.formulaIds
		if formulaIds and string.len(formulaIds) > 0  then
			local formulaIdsTable = string.split(formulaIds , ",")
			-- 更新数据
			for index, formulaId in pairs(formulaIdsTable) do
				if checkint(formulaId) > 0 then
					local isLike = waterBarMgr:isFormulaLike(formulaId)
					waterBarMgr:setFormulaLike(formulaId , not isLike )
				end
			end
		else
			local formulaMap_ = waterBarMgr:getFormulaMap()
			for formulaId, formulaOneData in pairs(formulaMap_) do
				waterBarMgr:setFormulaLike(formulaId  ,false)
			end
		end
		self:GetSortFormulaList()
		---@type WaterBarMenuFormulaView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.drinkGridView:reloadData()
	end
end

function WaterBarMenuFormulaMediator:Initial(key)
	self.super.Initial(self, key)
	---@type WaterBarMenuFormulaView
	local viewComponent = require("Game.views.waterBar.WaterBarMenuFormulaView").new()
	viewComponent:setPosition(display.center)
	self:SetViewComponent(viewComponent)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.closeView , {animate = false  ,  cb = function()
		 self:GetFacade():UnRegistMediator(NAME)
	end})
	for tag, btn in pairs(viewData.buttonTable) do
		display.commonUIParams(btn , {cb = handler(self, self.KindClick)})
	end
	viewData.reconcileBtn:setTag(BUTTON_CLICK.RECONCILE_TAG)
	display.commonUIParams(viewData.reconcileBtn , {cb = handler(self, self.ButtonClick) })
	self:DealWithKindBtn(self.selectKindTag)
end
function WaterBarMenuFormulaMediator:ReloadGrideView()
	self:GetSortFormulaList()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	if self.selectFormulaId then
		local formulaIndex = self:GetFormulaIndexByFormulaId(self.selectFormulaId)
		self.selectCellTag = checkint(formulaIndex)
		viewData.drinkGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDatSources))
		viewData.drinkGridView:setCountOfCell(#self.formulaList)
		viewData.drinkGridView:reloadData()
		if formulaIndex then
			if formulaIndex > 6 then
				local cellNum = math.ceil((formulaIndex - 6) /2)

				local pos  = cc.p(0, -215* (math.ceil(#self.formulaList/2) - cellNum - 3 ) + 40 )
				viewData.drinkGridView:setContentOffset(pos)
			end
		end
		self.selectFormulaId = nil
	else
		viewData.drinkGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDatSources))
		viewData.drinkGridView:setCountOfCell(#self.formulaList)
		viewData.drinkGridView:reloadData()
	end
	viewComponent:UpdateView(self.formulaList[self.selectCellTag])
end
function WaterBarMenuFormulaMediator:GetFormulaIndexByFormulaId(formulaId)
	formulaId = checkint(formulaId)
	if formulaId <= 0 then return end
	local formulaIndex = nil
	for index, formulaData in pairs(self.formulaList) do
		if checkint(formulaData.formulaId) == formulaId then
			formulaIndex = index
		end
	end
	return formulaIndex
end
function WaterBarMenuFormulaMediator:GetSortFormulaList()
	self.formulaList = {}
	-- kindofTag 默认为 -1  就是全部 ， 0 . 是非酒类 1. 是酒类
	local kindofTag = self.selectKindTag - KIND_OF_TABLE.FRUIT_DRINT
	local formulaMap_     = waterBarMgr:getFormulaMap()
	local likeFormulas    = {}
	local notLikeFormulas = {}
	local lockFormulas    = {}
	local hideFormulas    = {}
	--local mergeTableArray = function(dest , src)
	--	for i, v in pairs(src) do
	--		dest[#dest+1] = v
	--	end
	--	return dest
	--end
	local formulaConf = CONF.BAR.FORMULA:GetAll()
	for i, v in pairs(formulaMap_) do
		local formulaOneConf = formulaConf[tostring(v.formulaId)]
		if formulaOneConf then
			if kindofTag < 0 or checkint(formulaOneConf.alcohol) == kindofTag then
				if checkint(v.like)  == 1 then
					likeFormulas[#likeFormulas +1] = {like =1 , formulaId = v.formulaId ,  highStar = waterBarMgr:getFormulaMaxStar(v.formulaId) }
				else
					notLikeFormulas[#notLikeFormulas +1] =  {like =0 , formulaId = v.formulaId ,  highStar = waterBarMgr:getFormulaMaxStar(v.formulaId) }
				end
			end
		end

	end

	for formulaId, formulaOneData in pairs(formulaConf) do
		local formulaData = waterBarMgr:getFormulaData(formulaId)
		if not formulaData then
			local formulaOneConf = formulaConf[tostring(formulaId)]
			if formulaOneConf then
				if kindofTag < 0 or checkint(formulaConf[tostring(formulaId)].alcohol) == kindofTag then
					if checkint(formulaOneData.hide)== 1 then
						hideFormulas[#hideFormulas+1] = { formulaId = formulaId   }
					else
						lockFormulas[#lockFormulas+1] = {formulaId = formulaId , barLevel =  checkint(formulaOneData.openBarLevel)}
					end
				end
			end
		end
	end
	local sortTableKey  = {
		{sortkey =  {"highStar" , "formulaId"}  , isReverse = false },
		{sortkey = {"barLevel" , "formulaId"} , isReverse = true }
	}

	local sortfunction = function(sortTable , sortTag )
		if #sortTable == 0  then return end
		local sortkey = sortTableKey[sortTag].sortkey
		local isReverse = sortTableKey[sortTag].isReverse
		table.sort(sortTable ,
	function(aFormula , bFormula)
				if checkint(aFormula[sortkey[1]])  ==  checkint(bFormula[sortkey[1]])  then
					return checkint(aFormula[sortkey[2]]) >  checkint(bFormula[sortkey[2]])
				end
				if isReverse then
					return checkint(aFormula[sortkey[1]]) < checkint(bFormula[sortkey[1]])
				else
					return checkint(aFormula[sortkey[1]]) > checkint(bFormula[sortkey[1]])
				end

			end
		)
	end
	sortfunction(likeFormulas , 1)
	sortfunction(notLikeFormulas , 1)
	sortfunction(lockFormulas , 2)
	table.insertto(self.formulaList , likeFormulas)
	table.insertto(self.formulaList , notLikeFormulas)
	-- 取出可以制作的
	local makeFormula = {}
	for i = #self.formulaList , 1 , -1 do
		local isEnough = waterBarMgr:CheckMaterialEnoughByFormulaId(self.formulaList[i].formulaId)
		if isEnough then
			table.insert(makeFormula ,1 , table.remove(self.formulaList , i))
		end
	end
	--把可以制作的插入到最前面的位置
	table.insertto(makeFormula , self.formulaList)
	self.formulaList = makeFormula
	table.insertto(self.formulaList , lockFormulas)
	table.insertto(self.formulaList , hideFormulas)

end
function WaterBarMenuFormulaMediator:OnDatSources(cell , idx)
	---@type WaterBarDrinkCell
	local pcell = cell
	local index = idx+1
	local data = self.formulaList[index]
	if pcell == nil  then
		pcell = WaterBarDrinkCell.new()
		display.commonUIParams(pcell.viewData.clickBtn , {cb = handler(self , self.CellIndex)})
		pcell.viewData.focusOnBtn:setTouchEnabled(true)
		display.commonUIParams(pcell.viewData.focusOnBtn , {cb = handler(self , self.LikeFomulaClick)})
	end
	local viewComponent = self:GetViewComponent()
	if (not viewComponent.viewData.lightNode) and self.selectCellTag == index then
		viewComponent:UpdateSelectFormuSpine(pcell.viewData.drinkLayout)
	end
	local lightNode = pcell.viewData.drinkLayout:getChildByName("lightNode")
	if lightNode and (not tolua.isnull(lightNode)) then
		if self.selectCellTag == index then
			lightNode:setVisible(true)
		else
			lightNode:setVisible(false)
		end
	end
	pcell.viewData.clickBtn:setTag(index)
	pcell:UpdateCell(data , index)
	return pcell
end
function WaterBarMenuFormulaMediator:ButtonClick(sender)
	local tag = sender:getTag()
	if tag == BUTTON_CLICK.RECONCILE_TAG then
		local formulaId  = self.formulaList[self.selectCellTag].formulaId
		local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
		if  checkint(formulaConf.openBarLevel) >  waterBarMgr:getBarLevel() then
			app.uiMgr:ShowInformationTips(__('酒吧等级不足，不能制作该配方'))
			return
		end
		-- 开始调和
		local mediator = require("Game.mediator.waterBar.WaterBarDeployFormulaMediator").new({
			developWay = 2,
			formulaId  = self.formulaList[self.selectCellTag].formulaId,
			fromData   = {
				mediatorName  = "waterBar.WaterBarMenuFormulaMediator",
				selectKindTag = self.selectKindTag,
				formulaId     = self.formulaList[self.selectCellTag].formulaId,
			}
		})
		self:GetFacade():RegistMediator(mediator)
		self:GetFacade():UnRegistMediator(NAME)
	end
end
function WaterBarMenuFormulaMediator:KindClick(sender)
	local tag = sender:getTag()
	self:DealWithKindBtn(tag)
end
function WaterBarMenuFormulaMediator:DealWithKindBtn(tag)
	---@type WaterBarMenuFormulaView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	for btnTag, btn in pairs(viewData.buttonTable) do
		if checkint(btnTag) == tag  then
			btn:setEnabled(false)
			display.commonLabelParams(btn ,{text = btn:getText() , color = "#a74760"})
		else
			btn:setEnabled(true)
			display.commonLabelParams(btn ,{text = btn:getText() , color = "#5b3c25"})
		end
	end
	self.selectKindTag = tag
	self.selectCellTag = 1
	self:ReloadGrideView()
end
-- 选择配方的回调事件
function WaterBarMenuFormulaMediator:CellIndex(sender)
	local tag = sender:getTag()
	if self.selectCellTag == tag then
		return
	end
	local formulaId = self.formulaList[tag].formulaId
	local formulaData = waterBarMgr:getFormulaData(formulaId)
	if not formulaData then
		if self.formulaList[tag].barLevel then
			app.uiMgr:ShowInformationTips( string.fmt(__('该配方水吧_num_级解锁') , { _num_ = self.formulaList[tag].barLevel}))
		else
			app.uiMgr:ShowInformationTips(__('该配方为饮品配方，请前往自由调制进行研发'))
		end
	else
		self.selectCellTag = tag
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateView(self.formulaList[tag])
		viewComponent:UpdateSelectFormuSpine(sender:getParent())
	end
end


--喜欢配方回调事件
function WaterBarMenuFormulaMediator:LikeFomulaClick(sender)
	---@type WaterBarDrinkCell
	local cellLayout = sender:getParent():getParent()
	local clickBtn = cellLayout.viewData.clickBtn
	local tag = clickBtn:getTag()
	local formulaId = self.formulaList[tag].formulaId
	local formulaData = waterBarMgr:getFormulaData(formulaId)
	if not formulaData then
		if self.formulaList[tag].barLevel then
			app.uiMgr:ShowInformationTips( string.fmt(__('该配方水吧_num_级解锁') , { _num_ = self.formulaList[tag].barLevel}))
		else
			app.uiMgr:ShowInformationTips(__('该配方为饮品配方，请前往自由调制进行研发'))
		end
	else
		local highStar = waterBarMgr:getFormulaMaxStar(formulaId)
		if highStar < 0  then
			app.uiMgr:ShowInformationTips(__('该配方为饮品配方，请前往自由调制进行研发'))
			return
		end
		self:SendSignal(POST.WATER_BAR_FORMULA_LIKE.cmdName , { formulaIds = tostring(formulaId) })
	end
end


function WaterBarMenuFormulaMediator:CleanupView()

end


function WaterBarMenuFormulaMediator:OnRegist()
	regPost(POST.WATER_BAR_FORMULA_LIKE)
end

function WaterBarMenuFormulaMediator:OnUnRegist()
	unregPost(POST.WATER_BAR_FORMULA_LIKE)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		if viewComponent.viewData.lightNode then
			viewComponent.viewData.lightNode:release()
			viewComponent.viewData.lightNode = nil
		end
		viewComponent:stopAllActions()
		viewComponent:runAction(
			cc.RemoveSelf:create()
		)
	end
end
return WaterBarMenuFormulaMediator
