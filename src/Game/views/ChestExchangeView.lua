--[[
宝箱兑换活动view
--]]
local ChestExchangeView = class('ChestExchangeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ChestExchangeView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local MAX_EXCHANGE_NUM = 999
local function CreateView(  )
	local view = CLayout:create(display.size)
	-- 提示
	local tipsLabel = display.newLabel(display.cx, display.cy + 300, fontWithColor(18, {text = __('集齐不同食材可煮出不同的粥，食材越多可煮的粥越多'), w = 1100, hAlign = display.TAC}))
	view:addChild(tipsLabel, 10)
	return {
		view 			   = view,
	}
end

function ChestExchangeView:ctor( ... )
	self.args = unpack({...}) or {}
	self.exchangeDatas = self.args.exchangeDatas or {}
	self.exchangeCallback = self.args.exchangeCallback
	self.exViewTable = {}
	self.activityId = checkint(self.args.activityId)
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(handler(self, self.RemoveSelf_))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	self:InitUi()
end
--[[
更新Ui
--]]
function ChestExchangeView:InitUi()
	local widthMax = 380 * #self.exchangeDatas
	for i=1, #self.exchangeDatas do
		local goodDatas = self.exchangeDatas[i]
		local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodDatas.rewards[1].goodsId)
		local cell = require('home.ChestExchangeTaskCell').new()
		cell:setAnchorPoint(cc.p(0.5, 0.5))
		cell:setPosition(cc.p(display.cx - (widthMax / 2) - 190 + 380 * i, display.cy - 40))
		self.viewData_.view:addChild(cell, 10)
		table.insert(self.exViewTable, cell)

		cell.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodDatas.rewards[1].goodsId))
		cell.goodsName:setString(goodsConfig.name)
		for k=1, 2 do
			if goodDatas.require[k] then
				cell.goodsTable[k].goodsNode:RefreshSelf({goodsId = goodDatas.require[k].goodsId})
				cell.goodsTable[k].goodsNode.callBack = function ()
					uiMgr:AddDialog("common.GainPopup", {goodId = goodDatas.require[k].goodsId})
				end
				cell.goodsTable[k].goodsNode:setVisible(true)
				self:RefreshMaterialNums(i)
			end
		end

		cell.minusBtn:setTag(i)
		cell.minusBtn:setOnClickScriptHandler(handler(self, self.MinusBtnCallback))
		cell.addBtn:setTag(i)
		cell.addBtn:setOnClickScriptHandler(handler(self, self.AddBtnCallback))
		cell.numBtn:setTag(i)
		cell.numBtn:setOnClickScriptHandler(handler(self, self.NumBtnCallback))
		cell.exchangeBtn:setTag(i)
		cell.exchangeBtn:setOnClickScriptHandler(handler(self, self.ExchangeBtnCallback))
	end
end
--[[
刷新道具数目
@params index int 任务编号
--]]
function ChestExchangeView:RefreshMaterialNums( index )
	local goodDatas = self.exchangeDatas[index]
	local cell = self.exViewTable[index]
	local exchangeNum = checkint(cell.exchangeNum)
	for i,v in ipairs(goodDatas.require) do
		local hasNum = gameMgr:GetAmountByGoodId(v.goodsId) 
		local requireNum = checkint(v.num) * exchangeNum
		cell.goodsTable[i].goodsNum:setString(string.format('%d/%d', hasNum, requireNum))
	end
end
--[[
刷新兑换数目
@params index int 任务编号
newNums int 新的兑换数目
--]]
function ChestExchangeView:RefreshExchangeNums( index, newNums )
	local cell = self.exViewTable[index]
	cell.exchangeNum = checkint(newNums)
	cell.exchangeNumLabel:setString(tostring(newNums))
	self:RefreshMaterialNums(index)
end
--[[
刷新所有兑换界面
--]]
function ChestExchangeView:RefreshAllExchangeCell()
	for i,v in ipairs(self.exchangeDatas) do
		self:RefreshMaterialNums(i)
	end
end
--[[
删除按钮回调
--]]
function ChestExchangeView:MinusBtnCallback( sender )
	local index = sender:getTag()
	local cell = self.exViewTable[index]
	local exchangeNum = checkint(cell.exchangeNum)
	if exchangeNum > 1 then
		exchangeNum = exchangeNum - 1
	end
	self:RefreshExchangeNums(index, exchangeNum)
end
--[[
添加按钮回调
--]]
function ChestExchangeView:AddBtnCallback( sender )
	local index = sender:getTag()
	local cell = self.exViewTable[index]
	local exchangeNum = checkint(cell.exchangeNum)
	if exchangeNum < 999 then
		exchangeNum = exchangeNum + 1
	end
	self:RefreshExchangeNums(index, exchangeNum)
end
--[[
输入数量
--]]
function ChestExchangeView:NumBtnCallback( sender )
	local index = sender:getTag()
    local function inputCallback ( str )
        if checkint(str) >= 1 and checkint(str) <= MAX_EXCHANGE_NUM then
            self:RefreshExchangeNums(index, checkint(str))
        else
            uiMgr:ShowInformationTips(string.fmt(__('请输入1到_num_之间的数字'), {['_num_'] = MAX_EXCHANGE_NUM}))
        end
    end
    -- 房间号位数限制
    uiMgr:ShowNumberKeyBoard({nums = 3, model = 2, titleText = __('请输入数量:'), callback = inputCallback, defaultContent = string.fmt(__('输入数字1-_num_'), {['_num_'] = MAX_EXCHANGE_NUM})})
end
--[[
兑换回调
--]]
function ChestExchangeView:ExchangeBtnCallback( sender )
	local index = sender:getTag()
	local goodDatas = self.exchangeDatas[index]
	local cell = self.exViewTable[index]
	local exchangeNum = checkint(cell.exchangeNum)
	local canExchange = true
	for i,v in ipairs(goodDatas.require) do
		local hasNum = checkint(gameMgr:GetAmountByGoodId(v.goodsId)) 
		local requireNum = checkint(v.num) * exchangeNum
		if hasNum < requireNum then
			canExchange = false
			break
		end
	end
	if canExchange then
		self.exchangeCallback(self.activityId, goodDatas.id, exchangeNum)
	else
		uiMgr:ShowInformationTips(__('材料不足'))
	end

end
function ChestExchangeView:RemoveSelf_()
	self:runAction(cc.RemoveSelf:create())
end
return ChestExchangeView