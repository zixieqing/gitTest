--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息中介者
]]
---@class WaterBarDeployFormulaMediator:Mediator
local WaterBarDeployFormulaMediator = class('WaterBarDeployFormulaMediator', mvc.Mediator)
local NAME = "WaterBarDeployFormulaMediator"
local waterBarMgr = app.waterBarMgr
local BAR_DEFIN_TABLE = {
	DEV               = {
		FREE_DEV          = 1, -- 自由调试
		FORMULA_DEV       = 2, --配方调试
		FORMULA_BATCH_DEV = 3  --批量开发
	},

	EVENT = {
		ADD_MATERIAL_EVENT                 = {
			eventName   = "ADD_MATERIAL_EVENT",
			callbackName = "AddMaterialEvent",
			callback    = nil
		},
		ADD_MATERIAL_CALLBACK_EVENT        = {
			eventName   = "ADD_MATERIAL_CALLBACK_EVENT",
			callbackName = "AdddMaterialCallbackEvent",
			callback    = nil
		},
		REDUCE_MATERIAL_EVENT              = {
			eventName   = "REDUCE_MATERIAL_EVENT",
			callbackName = "ReduceMaterialEvent",
			callback    = nil
		},
		CHANGE_MATERIAL_POS_EVENT          = {
			eventName   = "CHANGE_MATERIAL_POS_EVENT",
			callbackName = "ChangeMaterialPosEvent",
			callback    = nil
		},
		CHANGE_MATERIAL_POS_CALLBACK_EVENT = {
			eventName   = "CHANGE_MATERIAL_POS_CALLBACK_EVENT",
			callbackName = "ChangeMaterialPosCallbackEvent",
			callback    = nil
		},
		MATERIAL_CHANGE_EVENT              = {
			eventName   = "MATERIAL_CHANGE_EVENT",
			callbackName = "MaterialChangeEvent",
			callback    = nil
		} ,
		USE_BATCH_FORMULA_EVENT              = {
			eventName   = "USE_BATCH_FORMULA_EVENT",
			callbackName = "UerBatchFormulaEvent",
			callback    = nil
		},
		CHANGE_BATCH_NUM_EVENT = {   -- 修改批量制作的数量
			eventName   = "CHANGE_BATCH_NUM_EVENT",
			callbackName = "ChangeBatchNumEvent",
			callback    = nil
		},
		[SGL.REFRESH_NOT_CLOSE_GOODS_EVENT] = {   -- 获取材料刷新的事件
			eventName   = SGL.REFRESH_NOT_CLOSE_GOODS_EVENT ,
			callbackName = "ChangeGoodEevent",
			callback    = nil
		},
		[POST.WATER_BAR_BARTEND.sglName]= {
			eventName   = POST.WATER_BAR_BARTEND.sglName ,
			callbackName = "SglNameFormulaOrFreeEvent",
			callback    = nil
		},
		[POST.WATER_BAR_MAKE.sglName]= {
			eventName   = POST.WATER_BAR_MAKE.sglName ,
			callbackName = "SglNameMakeBatchEvent",
			callback    = nil
		}
	},
	METHOD            = {
		BUILD_METHOD   = 1,
		SHAKING_METHOD = 2,
		MIX_METHOD     = 3,
	},
	MAX_KIND_MATERIAL = 4,
	MAX_MATERIAL_NUM  = 10, -- 消耗材料最多
	HISHEST_STAR      = 3, -- 最高星级
}
local BUTTON_TAG = {
	BUILD_METHOD   = 1, -- 兑和法
	SHAKING_METHOD = 2, -- 摇和法
	MIX_METHOD     = 3, -- 搅合法
	--------------------------------------
	LEFT_SWITH         = 1001,
	RIGHT_SWITH        = 1002,
	MAKE_BTN           = 1003,
	LOOK_BATCH_FORMULA = 1004, -- 查看配方
	CLEAR_ALL          = 1007, -- 一键清空
	--------------------------------------
}

--[[
params = {
	developWay 调制方式 1 自由 2 配方
	formulaId 配方调试下 要传formulaId
	fromData = {
		mediatorName  string ; -- 跳转的上一界面
		selectKindTag int ;  -- 选择制作配方的种类
		formulaId  int ; -- 配方
	}
}
]]
function WaterBarDeployFormulaMediator:ctor(params, viewComponent)
	self.super.ctor(self, 'WaterBarDeployFormulaMediator', viewComponent)
	local params = params or {}
	self.fromData = params.fromData or  {}
	self.fromData.mediatorName = self.fromData.mediatorName
	self.developWay  = params.developWay or BAR_DEFIN_TABLE.DEV.FORMULA_DEV
	self.formulaId = params.formulaId
	self.freeMaterialData = {}
	-- 所要消耗的食材
	self:ResetWaterBarFormula()
end
-------------------------------------------------
-- inheritance

function WaterBarDeployFormulaMediator:InterestSignals()
	local eventNameTable = {}
	for eventName , eventData in pairs(BAR_DEFIN_TABLE.EVENT) do
		eventData.callback = handler(self , self[eventData.callbackName])
		eventNameTable[#eventNameTable+1] = eventData.eventName
	end
	return eventNameTable 
end
function WaterBarDeployFormulaMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if BAR_DEFIN_TABLE.EVENT[name] then
		BAR_DEFIN_TABLE.EVENT[name].callback(body)
	end
end


function WaterBarDeployFormulaMediator:Initial(key)
	self.super.Initial(self, key)
	---@type WaterBarDeployFormulaView
	local viewComponent = require("Game.views.waterBar.WaterBarDeployFormulaView").new()
	viewComponent:setPosition(display.center)
	self:SetViewComponent(viewComponent)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:InitUI()
	self:BindBtnClick()
end

function WaterBarDeployFormulaMediator:BindBtnClick()
	---@type WaterBarDeployFormulaView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.colorView , {animate = false , cb = function()
		self:GetFacade():UnRegistMediator(NAME)
		if self.fromData.mediatorName then
			local mediator = require("Game.mediator." .. self.fromData.mediatorName).new({
				selectKindTag = self.fromData.selectKindTag,
				formulaId = self.fromData.formulaId
			})
			app:RegistMediator(mediator)
		end
	end})

	for index , mathodUIData in pairs(viewComponent.viewData.methodUITable) do
		local methodLayout =mathodUIData.methodLayout
		display.commonUIParams(methodLayout , {cb = handler(self , self.MethodClick)})
	end
	local bottomViewData =  viewComponent.bottomViewData
	display.commonUIParams(viewData.leftSwitchBtn , {cb = handler(self , self.ButtonClick)})
	display.commonUIParams(viewData.rightSwitchBtn , {cb = handler(self , self.ButtonClick)})
	display.commonUIParams(bottomViewData.makeBtn , {cb = handler(self , self.ButtonClick)})
	display.commonUIParams(bottomViewData.lookRecordBtn , {cb = handler(self , self.ButtonClick)})
	display.commonUIParams(bottomViewData.clearAllBtn , {cb = handler(self , self.ButtonClick)})
end

function WaterBarDeployFormulaMediator:InitUI()
	---@type WaterBarDeployFormulaView
	local viewComponent = self:GetViewComponent()
	viewComponent:CreateBottomLayout()
	if self.developWay > BAR_DEFIN_TABLE.DEV.FREE_DEV then
		viewComponent:CreateFormulaLayout(self.formulaId)
		viewComponent:CreateMixRatioLayout(self.formulaId)
		local highStar = waterBarMgr:getFormulaMaxStar(self.formulaId)
		if highStar == BAR_DEFIN_TABLE.HISHEST_STAR then
			self.consumeMaterialTable , self.selectMethod = self:GetThreeStarConsumMaterialAndMethodId(self.formulaId)
		end
		viewComponent:UpdateFormulaView({formulaId = self.formulaId , highStar = highStar})
		viewComponent:UpdateGoodLayout(self.consumeMaterialTable , self.batchNum )
		viewComponent:UpdateMethodLayout(self.selectMethod)
		if waterBarMgr:getFormulaMaxStar(self.formulaId) >= 0  then
			viewComponent:SwitchBtnIsVisible(true)
		else
			viewComponent:SwitchBtnIsVisible(false)
		end
	else
		viewComponent:CreateFreeLayout()

		local viewData = viewComponent.freeViewData
		viewData.materialGrideView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
		self:ReloadMaterialGridView()
	end
	viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable)
	viewComponent:UpdateFomulaDevUI(self.developWay)
end
function WaterBarDeployFormulaMediator:ReloadMaterialGridView()
	self.freeMaterialData = self:GetMaterialList()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.freeViewData
	viewData.materialGrideView:setCountOfCell(#self.freeMaterialData)
	viewData.materialGrideView:reloadData()
	if #self.freeMaterialData == 0 then
		viewComponent:SetVisible(true)
	else
		viewComponent:SetVisible(false)
	end
end
function WaterBarDeployFormulaMediator:GetMaterialList()
	local materials = waterBarMgr:getAllMaterials()
	local materialList = {}
	local consumeDta = {}
	for index, materialData in pairs(self.consumeMaterialTable) do
		if checkint(materialData.materialId) > 0 then
			consumeDta[tostring(materialData.materialId)] = materialData.num  * self.batchNum
		end
	end
	local count = 1
	for materialId, materialNum in pairs(materials) do
		if consumeDta[tostring(materialId)] then
			materialNum = materialNum - consumeDta[tostring(materialId)]
			materialNum = materialNum > 0 and materialNum or materialNum
		end
		materialList[count] = { materialId = materialId ,num = materialNum }
		count = count +1
	end
	return materialList
end
function WaterBarDeployFormulaMediator:ButtonClick(sender)
	local tag = sender:getTag()
	if tag == BUTTON_TAG.LEFT_SWITH or tag == BUTTON_TAG.RIGHT_SWITH then
		self.developWay = (self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_DEV and BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV or BAR_DEFIN_TABLE.DEV.FORMULA_DEV)
		local viewComponent = self:GetViewComponent()
		self:ResetWaterBarFormula()
		if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV then
			if not viewComponent.viewData.batchViewData then
				viewComponent:CreateBatachLayout()
			end
		end
		viewComponent:UpdateFomulaDevUI(self.developWay)
		viewComponent:UpdateBatchNum(self.batchNum)
		self:GetFacade():DispatchObservers(BAR_DEFIN_TABLE.EVENT.MATERIAL_CHANGE_EVENT.eventName ,{} )
	elseif tag == BUTTON_TAG.MAKE_BTN then
		local isEnough = self:JudageMaterialEnough(self.consumeMaterialTable , self.batchNum)
		if not isEnough then
			app.uiMgr:ShowInformationTips(__('材料不足'))
			return
		end
		if self.consumeMaterialTable[1].num <= 0 then
			app.uiMgr:ShowInformationTips(__('请添加材料'))
			return
		end
		if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV then
			if checkint(self.batchDrinkId) <= 0  then
				app.uiMgr:ShowInformationTips(__('请选择批量制作的配方'))
				return
			end
			local material = {}

			for index, consumeData in pairs(self.consumeMaterialTable) do
				if checkint(consumeData.materialId)  > 0 and checkint(consumeData.num)  > 0 then
					material[tostring(consumeData.materialId)] = consumeData.num
				end
			end
			self:SendSignal(POST.WATER_BAR_MAKE.cmdName , {material = json.encode(material) , drinkId = self.batchDrinkId , num = self.batchNum })
		elseif self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_DEV then
			if not self.selectMethod then
				app.uiMgr:ShowInformationTips(__('请选择手法'))
				return
			end
			local material = {}
			for index, consumeData in pairs(self.consumeMaterialTable) do
				if checkint(consumeData.materialId)  > 0 and checkint(consumeData.num)  > 0 then
					material[#material+1] = {goodsId = consumeData.materialId , num = consumeData.num}
				end
			end
			self:SendSignal(POST.WATER_BAR_BARTEND.cmdName , {method = self.selectMethod , material = json.encode(material) ,formulaId = self.formulaId})
		elseif self.developWay == BAR_DEFIN_TABLE.DEV.FREE_DEV then
			if not self.selectMethod then
				app.uiMgr:ShowInformationTips(__('请选择手法'))
				return
			end
			local drinkId = waterBarMgr:GetDrinkIdByMaterials(self.consumeMaterialTable , self.selectMethod)
			local drinkConf = CONF.BAR.DRINK:GetValue(drinkId)
			local star = checkint(drinkConf.star)
			local isHave = waterBarMgr:hasFormulaStar(drinkConf.formulaId ,star )
			if isHave then
				app.uiMgr:ShowInformationTips(__('已经拥有该饮品'))
				return
			end
			local material = {}
			for index, consumeData in pairs(self.consumeMaterialTable) do
				if checkint(consumeData.materialId)  > 0 and checkint(consumeData.num)  > 0 then
					material[#material+1] = {goodsId = consumeData.materialId , num = consumeData.num}
				end
			end
			self:SendSignal(POST.WATER_BAR_BARTEND.cmdName , {method = self.selectMethod , material = json.encode(material) })
		end
	elseif tag == BUTTON_TAG.LOOK_BATCH_FORMULA then
		local mediator = require('Game.mediator.waterBar.WaterBarChooseBatchFormulaMediator').new({
			formulaId = self.formulaId
		})
		app:RegistMediator(mediator)
	elseif tag == BUTTON_TAG.CLEAR_ALL then
		self:ResetWaterBarFormula()
	end
end

function WaterBarDeployFormulaMediator:MethodClick(sender)
	local tag = sender:getTag()
	self.selectMethod = tag
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateMethodLayout(self.selectMethod)
end
function WaterBarDeployFormulaMediator:OnDataSource(pcell , idx)
	local index = idx +1
	local data = self.freeMaterialData[index]
	if pcell == nil  then
		local cellSize = cc.size(97,97)
		local cell =  CGridViewCell:new()
		cell:setContentSize(cellSize)
		local goodNode = require("common.GoodNode").new({goodsId = DIAMOND_ID , num = 0 ,showAmount = true  })
		cell:addChild(goodNode)
		goodNode:setPosition(cellSize.width/2 , cellSize.height/2 )
		cell.viewData = {
			goodNode = goodNode
		}
		goodNode:setScale(0.8)
		pcell = cell
	end
	xTry(function()
		local goodNode = pcell.viewData.goodNode
		goodNode:RefreshSelf({goodsId = data.materialId , num = data.num})
		goodNode:setTag(checkint(data.materialId))
		display.commonUIParams(goodNode , {  animate  = false ,  cb = function(sender)
			app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.ADD_MATERIAL_EVENT.eventName , { materialId = sender:getTag()})
		end})
	end, __G__TRACKBACK__)
	return pcell
end
function WaterBarDeployFormulaMediator:GetAddConsumeMaterialIdIndexAndNum(materialId)
	local index = 0
	local materialNum = 0
	materialId = checkint(materialId)
	for i, goodData in pairs(self.consumeMaterialTable) do
		if checkint(goodData.num) == 0 or checkint(goodData.materialId) == materialId  then
			index = i
			materialNum = goodData.num
			break
		end
	end
	return index , materialNum
end
----=======================----
--@author : xingweihao
--@date : 2020/4/3 10:46 AM
--@Description 重置调酒设置
--@params
--@return
---=======================----
function WaterBarDeployFormulaMediator:ResetWaterBarFormula()
	local materialTable = {}
	for i, v in pairs(self.consumeMaterialTable or {}) do
		if checkint( v.materialId) > 0  then
			materialTable[#materialTable+1] = v.materialId
		end
	end
	local materialId = table.concat(materialTable , ",")
	self.consumeMaterialTable = {
		{materialId = 0 , num = 0} ,
		{materialId = 0 , num = 0} ,
		{materialId = 0 , num = 0},
		{materialId = 0 , num = 0}
	}
	self.batchNum = 1
	self.batchDrinkId = nil
	self.selectMethod = nil
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:UpdateMethodLayout(self.selectMethod )
		self:GetFacade():DispatchObservers(BAR_DEFIN_TABLE.EVENT.MATERIAL_CHANGE_EVENT.eventName , {materialId = materialId })
		viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable , self.developWay)

		if self.developWay ~= BAR_DEFIN_TABLE.DEV.FORMULA_DEV then
			viewComponent:UpdateBatchNum(self.batchNum)
		end
	end
end
function WaterBarDeployFormulaMediator:AddConsumeMaterial(materialId , num  , index )
	materialId = checkint(materialId)
	local totalNum = 0
	if num > 0  then
		for index, goodData in pairs(self.consumeMaterialTable) do
			if checkint(goodData.materialId) ~= materialId then
				totalNum = totalNum + goodData.num
			end
		end
		totalNum = num + totalNum
		if totalNum > BAR_DEFIN_TABLE.MAX_MATERIAL_NUM  then return false end
	end
	self.consumeMaterialTable[index].num = self.consumeMaterialTable[index].num + num
	self.consumeMaterialTable[index].materialId = materialId
	-- 当消耗材料减少为零时候 ，删除数据 并在末尾添加上初始数据
	if self.consumeMaterialTable[index].num == 0  then
		table.remove(self.consumeMaterialTable, index)
		table.insert(self.consumeMaterialTable, BAR_DEFIN_TABLE.MAX_KIND_MATERIAL, { materialId = 0 , num = 0 })
	end
	self:GetFacade():DispatchObservers(BAR_DEFIN_TABLE.EVENT.MATERIAL_CHANGE_EVENT.eventName , {materialId = materialId} )
	return true
end

function WaterBarDeployFormulaMediator:GetThreeStarConsumMaterialAndMethodId(formulaId)
	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	local materialTable = {}
	local consumeTable = {}
	for i = 1 , BAR_DEFIN_TABLE.MAX_MATERIAL_NUM do
		consumeTable[i] = {materialId = 0 , num = 0  }
	end
	for i, v in pairs(formulaConf.materials) do
		materialTable[tostring(v)] = { materialId = v , num = checkint(formulaConf.matching[i])}
	end
	local orderTable = string.split(formulaConf.order, ";")
	for i = 1, 	#orderTable do
		if checkint(orderTable[i]) > 0  then
			consumeTable[i].materialId = materialTable[tostring(orderTable[i])].materialId
			consumeTable[i].num = materialTable[tostring(orderTable[i])].num
		end
	end
	return consumeTable ,formulaConf.method
end

function WaterBarDeployFormulaMediator:JudageMaterialEnough(consumeMaterialData , batchNum)
	for index, consumeData in pairs(consumeMaterialData) do
		if  checkint(consumeData.materialId) > 0  then
			local needNum = consumeData.num * batchNum
			local ownerNum = waterBarMgr:getMaterialNum(consumeData.materialId)
			if needNum > ownerNum then
				return false
			end
		end
	end
	return true
end

function WaterBarDeployFormulaMediator:AddMaterialEvent(body)
	local materialId = checkint(body.materialId)
	local materialNum = waterBarMgr:getMaterialNum(materialId)
	-- 如果为零直接跳转到所需可以购买材料的地方
	if materialNum == 0  then
		app.uiMgr:AddDialog("common.GainPopup", {goodId = materialId})
	else
		-- 不为零的时候 批量模式直接返回
		if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV  then return end
		local index ,_ = self:GetAddConsumeMaterialIdIndexAndNum(materialId)
		if index == 0  then
			app.uiMgr:ShowInformationTips(__('最多四种材料'))
			return
		end
		local otherTotalNum = 0
		local curentMaterialNum = 1
		for index , materialTable in pairs(self.consumeMaterialTable) do
			local oneMaterialId = checkint(materialTable.materialId)
			if oneMaterialId > 0 and materialId ~= oneMaterialId then
				otherTotalNum = otherTotalNum + materialTable.num
			elseif oneMaterialId > 0 and materialId == oneMaterialId then
				curentMaterialNum = materialTable.num
			end
		end
		local maxNum = BAR_DEFIN_TABLE.MAX_MATERIAL_NUM - otherTotalNum
		local addMaterialView = require("Game.views.waterBar.WaterBarAddMaterialView").new({
			maxNum     = maxNum,
			currentNum = curentMaterialNum ,
			materialId = materialId,
			event      = BAR_DEFIN_TABLE.EVENT.ADD_MATERIAL_CALLBACK_EVENT.eventName
		})
		addMaterialView:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(addMaterialView)
	end
end
function WaterBarDeployFormulaMediator:AdddMaterialCallbackEvent(body)
	local materialId = checkint(body.materialId)
	local num = checkint(body.num)
	local isEnough = self:JudageMaterialEnough({ {materialId = materialId  ,num = num }}, self.batchNum)
	if not isEnough  then
		app.uiMgr:ShowInformationTips(__('材料不足'))
		return
	end
	local otherTotalNum = 0
	for index , materialTable in pairs(self.consumeMaterialTable) do
		local oneMaterialId = checkint(materialTable.materialId)
		if oneMaterialId > 0 and (oneMaterialId ~= materialId)  then
			otherTotalNum = otherTotalNum + materialTable.num
		end
	end
	if otherTotalNum + num <= BAR_DEFIN_TABLE.MAX_MATERIAL_NUM  then
		local index , nowHave  = self:GetAddConsumeMaterialIdIndexAndNum(materialId)
		self:AddConsumeMaterial(materialId , num -nowHave  , index)
		---@type WaterBarDeployFormulaView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable , self.developWay)
	else
		app.uiMgr:ShowInformationTips(__('添加材料已超上限'))
	end
end

function WaterBarDeployFormulaMediator:ReduceMaterialEvent(body)
	-- 批量模式不可以增加或者减少材料
	if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV then return end
	local materialId = body.materialId
	local index , num = self:GetAddConsumeMaterialIdIndexAndNum(materialId)
	if num > 0  then
		---@type WaterBarDeployFormulaView
		local viewComponent = self:GetViewComponent()
		self:AddConsumeMaterial(materialId ,-1 , index )
		viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable)
	end
end

function WaterBarDeployFormulaMediator:ChangeMaterialPosEvent(body)
	if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV  then return end
	local materialId = body.materialId
	---@type WaterBarDeployFormulaView
	local viewComponent = self:GetViewComponent()
	viewComponent:SetAddMaterialLayoutTag(materialId)
	viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable , self.developWay)
end

function WaterBarDeployFormulaMediator:ChangeMaterialPosCallbackEvent(body)
	if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV  then return end
	local metarialId = body.materialId
	local currentIndex , materialNum  = self:GetAddConsumeMaterialIdIndexAndNum(metarialId)
	if materialNum > 0 then
		local index = currentIndex + body.moveIndex
		if index <= 0  then
			for i = #self.consumeMaterialTable , 1, -1 do
				if checkint(self.consumeMaterialTable[i].materialId) > 0
						and checkint(self.consumeMaterialTable[i].num) > 0 then
					index = i
					break
				end
			end
		elseif index > 0  then
			local materialTable = self.consumeMaterialTable[index]
			if not (checkint(materialTable.materialId) and checkint(materialTable.num) > 0) then
				index = 1
			end
		end
		if currentIndex ~= index  then
			self.consumeMaterialTable[currentIndex] , self.consumeMaterialTable[index] = self.consumeMaterialTable[index] , self.consumeMaterialTable[currentIndex]
			local viewComponent = self:GetViewComponent()
			viewComponent:SetAddMaterialLayoutTag(metarialId)
			viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable)
		end
	end
end

function WaterBarDeployFormulaMediator:MaterialChangeEvent(body)
	if self.developWay > BAR_DEFIN_TABLE.DEV.FREE_DEV then
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateGoodLayout(self.consumeMaterialTable , self.batchNum)
	elseif self.developWay == BAR_DEFIN_TABLE.DEV.FREE_DEV then
		local materialIdStr = body.materialId
		local materialTable  = string.split(materialIdStr , ",")
		local materialId = checkint(materialTable[1])
		local materials = {}
		if  materialId > 0  then
			for i, mId in pairs(materialTable) do
				materials[tostring(mId)] = {num = 0 , index = nil}
			end
		else
			for i, v in pairs(self.consumeMaterialTable) do
				if checkint(v.materialId) > 0  then
					materials[tostring(v.materialId)] = {num = 0 , index = nil}
				end
			end
		end
		for i, v in pairs(self.consumeMaterialTable) do
			if materials[tostring(v.materialId)] then
				materials[tostring(v.materialId)].num  = checkint(v.num) * self.batchNum
			end
		end
		for index , materialsData in pairs(self.freeMaterialData) do
			local materialId = tostring(materialsData.materialId)
			if materials[materialId] then
				materials[materialId].index = index
				materialsData.num = waterBarMgr:getMaterialNum(materialId) - materials[materialId].num
				materialsData.num = materialsData.num > 0 and materialsData.num or 0
			end
		end
		---@type WaterBarDeployFormulaView
		local viewComponent = self:GetViewComponent()
		local materialGrideView = viewComponent.freeViewData.materialGrideView
		for materialId, materialData in pairs(materials) do
			if materialData.index then
				local index = checkint(materialData.index)
				---@type WaterBarMaterialCell
				local cell = materialGrideView:cellAtIndex(index-1)
				if cell then
					cell.viewData.goodNode:RefreshSelf({goodsId = materialId , num = self.freeMaterialData[index].num})
				end
			end
		end
	end
end

function WaterBarDeployFormulaMediator:UerBatchFormulaEvent(body)
	local consumeMaterialTable =  body.consumeMaterialData
	if self.batchNum ~= 1 then
		local isEnough = self:JudageMaterialEnough(consumeMaterialTable , self.batchNum)
		if not isEnough then
			app.uiMgr:ShowInformationTips(__('材料不足'))
			return
		end
	end
	self.consumeMaterialTable = consumeMaterialTable
	self.batchDrinkId = body.drinkId
	self:GetFacade():DispatchObservers(BAR_DEFIN_TABLE.EVENT.MATERIAL_CHANGE_EVENT.eventName , {})
	---@type WaterBarDeployFormulaView
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable , self.developWay)
	if self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_DEV then
		self.developWay = BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV
		viewComponent:UpdateFomulaDevUI(self.developWay)
		local formulaConf = CONF.BAR.FORMULA:GetValue(self.formulaId) or {}
		viewComponent:UpdateMethodLayout(formulaConf.method or 1)
	end
end
function WaterBarDeployFormulaMediator:ChangeBatchNumEvent(body)
	local batchNum = checkint(body.num)
	if  checkint(batchNum) <= 0 then return  end
	if batchNum >1 then
		local isHaveMaterial = false
		for index, materialData in pairs(self.consumeMaterialTable) do
			if checkint(materialData.materialId) > 0 and
			checkint(materialData.num) > 0 then
				isHaveMaterial = true 
				break 
			end
		end
		if not isHaveMaterial then
			app.uiMgr:ShowInformationTips(__("请先添加材料"))
			return
		end
	end
	local isEnough = self:JudageMaterialEnough(self.consumeMaterialTable , batchNum)
	if not isEnough then
		app.uiMgr:ShowInformationTips(__('材料不足'))
		return
	end
	self.batchNum = batchNum
	self:GetFacade():DispatchObservers(BAR_DEFIN_TABLE.EVENT.MATERIAL_CHANGE_EVENT.eventName , {})
	---@type WaterBarDeployFormulaView
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateBatchNum(batchNum)
end
function WaterBarDeployFormulaMediator:SglNameMakeBatchEvent(body)
	local rewards = body.rewards
	local requestData = body.requestData
	local materials = json.decode(requestData.material)
	local batchNum = requestData.num
	local rewardTwo =  clone(rewards)
	local consumeDta = {}
	for materialId,num in pairs(materials) do
		consumeDta[#consumeDta+1] = {goodsId = materialId , num = - (batchNum * num)  }
	end
	app.uiMgr:AddDialog("common.RewardPopup", {rewards = rewards , addBackpack =false })
	self:ResetWaterBarFormula()
	table.insertto(consumeDta ,rewardTwo)
	CommonUtils.DrawRewards(consumeDta)
	--self:GetFacade():DispatchObservers(BAR_DEFIN_TABLE.EVENT.MATERIAL_CHANGE_EVENT.eventName , {})
end

function WaterBarDeployFormulaMediator:SglNameFormulaOrFreeEvent(body)
	local rewards = body.rewards
	local rFormulaId = checkint(body.formulaId)
	if rFormulaId > 0 then
		app.uiMgr:ShowInformationTips(__("调配出了正确的配方！但因为酒吧等级过低，不能解锁该配方"))
		return
	end
	local requestData = body.requestData
	local materials = json.decode(requestData.material)
	local method = requestData.method
	local batchNum = 1
	local consumeDta = {}
	local rewardTwo =  clone(rewards)
	for index, materialData in pairs(materials) do
		consumeDta[#consumeDta+1] = {goodsId = materialData.goodsId  , num = -(batchNum * materialData.num)  }
	end
	local drinkConf = CONF.BAR.DRINK:GetAll()
	local isHave = false
	local viewComponent = self:GetViewComponent()
	for i, v in pairs(rewards) do
		local goodsType = CommonUtils.GetGoodTypeById(v.goodsId)
		if goodsType == GoodsType.TYPE_WATERBAR_DRINKS then
			viewComponent:PlayMakeMethodLayoutAnimate(method ,
				function()
					app.uiMgr:AddDialog("Game.views.waterBar.WaterBarRewardFormulaView" , {
						drinkId = v.goodsId
					})
				end
			)
			local drinkOneConf = drinkConf[tostring(v.goodsId)]
			local star = drinkOneConf.star
			waterBarMgr:addFormulaStar(drinkOneConf.formulaId , star)
			isHave = true
		end
	end
	self:ResetWaterBarFormula()
	table.insertto(consumeDta , rewardTwo)
	if not isHave then
		viewComponent:PlayMakeMethodLayoutAnimate(method ,
			function()
				app.uiMgr:AddDialog('common.RewardPopup', {
					rewards = rewards ,
					addBackpack = false
				})
			end
		)
	elseif isHave and self.developWay == BAR_DEFIN_TABLE.DEV.FORMULA_DEV then
		local highStar = waterBarMgr:getFormulaMaxStar(self.formulaId)
		viewComponent:UpdateFormulaView({formulaId = self.formulaId , highStar = highStar})
	end
	if self.developWay > BAR_DEFIN_TABLE.DEV.FREE_DEV  then
		local viewComponent = self:GetViewComponent()
		if waterBarMgr:getFormulaMaxStar(self.formulaId) >= 0  then
			viewComponent:SwitchBtnIsVisible(true)
		else
			viewComponent:SwitchBtnIsVisible(false)
		end
	end
	CommonUtils.DrawRewards(consumeDta)
end
function WaterBarDeployFormulaMediator:ChangeGoodEevent(body)
	---@type WaterBarDeployFormulaView
	local viewComponent = self:GetViewComponent()
	if self.developWay == BAR_DEFIN_TABLE.DEV.FREE_DEV then
		self:ReloadMaterialGridView()
		viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable , self.developWay)
	else
		viewComponent:UpdateGoodLayout(self.consumeMaterialTable , self.batchNum)
		viewComponent:UpdateBottomMaterialView(self.consumeMaterialTable , self.developWay)
	end
end
function WaterBarDeployFormulaMediator:CleanupView()

end

function WaterBarDeployFormulaMediator:OnRegist()
	regPost(POST.WATER_BAR_BARTEND)
	regPost(POST.WATER_BAR_MAKE)
end

function WaterBarDeployFormulaMediator:OnUnRegist()
	unregPost(POST.WATER_BAR_BARTEND)
	unregPost(POST.WATER_BAR_MAKE)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
		viewComponent:runAction(
				cc.RemoveSelf:create()
		)
	end
end
return WaterBarDeployFormulaMediator
