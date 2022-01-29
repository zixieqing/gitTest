--[[
	卡牌碎片融合
--]]
local Mediator = mvc.Mediator

local CardsFragmentComposeMediator = class("CardsFragmentComposeMediator", Mediator)

local NAME = "CardsFragmentComposeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local BackpackCell = require('home.BackpackCell')
-- local GoodsSale = require('common.GoodsSale')

--可选择最大碎片数量
local ModelMaxNum = {
	3,5
}

local POST = {
	{cc.p(180,308),cc.p(310,96),cc.p(50,96)},
	{cc.p(180,308),cc.p(310,200),cc.p(260,50),cc.p(100,50),cc.p(50,200)}
}


function CardsFragmentComposeMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.backPackDatas = {}
	self.cardsFragmentData = {}
	self.chooseModel = 2 --1:同阶融合  2:进阶融合
	self.chooseFullModel = 0  -- 0 全部显示 1 只显示满星
	self.chooseData = {} --选择碎片信息
	self.showIndex = {}
	self.gridContentOffset = cc.p(0,0)
	self.composecardsFragmentData = {}--本地碎片融合数据
	self.isBatch = false --是否是批量选择模式
	self.canComposeTargetQuality = {} --同阶 进阶 可以合成的稀有度
	self.fullCardFragment = {}
	self.isDataDirty_ = false
end

function CardsFragmentComposeMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.CardsFragment_Compose_Callback,
		SIGNALNAMES.CardsFragment_MultiCompose_Callback,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}

	return signals
end

function CardsFragmentComposeMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body)
	if name == SIGNALNAMES.CardsFragment_Compose_Callback then--合成
		--更新UI

		local Trewards = {}
		for i,v in ipairs(self.chooseData) do
			local t = {}
			t.goodsId = v.goodsId
			t.num = -1
			table.insert(Trewards,t)
		end
		for i,v in ipairs(body.rewards) do
			table.insert(Trewards,v)
		end

		local goldNum = body.gold - gameMgr:GetUserInfo().gold
		table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})

		CommonUtils.DrawRewards(Trewards)


	elseif name == SIGNALNAMES.CardsFragment_MultiCompose_Callback then--批量合成

		local Trewards = {}
		for i,v in ipairs(self.chooseData) do
			local t = {}
			t.goodsId = v.goodsId
			t.num = v.amount*(-1)
			table.insert(Trewards,t)
		end
		for i,v in ipairs(body.rewards) do
			table.insert(Trewards,v)
		end

		local goldNum = body.gold - gameMgr:GetUserInfo().gold
		table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})

		for i,v in ipairs(body.overPlusGoods) do
			local t = {}
			t.goodsId = v.goodsId
			t.num = v.num
			table.insert(Trewards,t)
		end

		-- dump(body.overPlusGoods)
		-- dump(Trewards)
		CommonUtils.DrawRewards(Trewards)

	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then--刷新顶部货币
        --更新界面显示
        self:UpdateCountUI()
        return
	end


	local actionName = 'idle1'
	if self.chooseModel == 1 then--1:同阶融合  2:进阶融合
		actionName = 'idle2'
	end

	local compSpine = sp.SkeletonAnimation:create('effects/cardFragment/sprh.json', 'effects/cardFragment/sprh.atlas', 1)
	compSpine:update(0)
	compSpine:setAnimation(0, actionName, false)
	self.viewComponent.viewData_.showChooseLayout:addChild(compSpine,100)
	compSpine:setPosition(cc.p(self.viewComponent.viewData_.showChooseLayout:getContentSize().width* 0.5,self.viewComponent.viewData_.showChooseLayout:getContentSize().height* 0.5))


	compSpine:registerSpineEventHandler(function (event)
		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards ,addBackpack = false})
		compSpine:runAction(cc.RemoveSelf:create())
	end, sp.EventType.ANIMATION_END)


	--删除已选碎片信息
	for i=#self.chooseData,1,-1 do
		table.remove(self.chooseData,i)
	end
	self.chooseData = {}
	--删除显示位置信息
	for k,v in pairs(self.showIndex) do
		self.showIndex[k] = nil
	end
	self.showIndex = {}

	self:initLayer()
	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
	gridView:setContentOffset(self.gridContentOffset)
	self.isDataDirty_ = true
end


--更新数量ui值
function CardsFragmentComposeMediator:UpdateCountUI()
	local viewData = self.viewComponent.viewData_
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个金币数量
		end
	end
end

function CardsFragmentComposeMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.CardsFragmentComposeView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	-- scene:AddGameLayer(viewComponent)
	scene:AddDialog(viewComponent)

	--绑定相关的事件
	local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.Tcells ) do
		v.toggleView:setOnClickScriptHandler(handler(self,self.ButtonActions))
	end
	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

	viewData.composeBtn:setOnClickScriptHandler(handler(self,self.ComposeButtonback))

	viewData.advancedButton:setOnClickScriptHandler(handler(self,self.TabButtonAction))
	viewData.equalButton:setOnClickScriptHandler(handler(self,self.TabButtonAction))
	viewData.batchButton:setOnClickScriptHandler(handler(self,self.BatchButtonAction))
	viewData.checkBtn:setOnClickScriptHandler(function(sender)
		if sender:isChecked() then
			self.chooseFullModel = 1
			self.chooseData = {}
			self.showIndex = {}
			self:initLayer()
			self:UpdateCountUI()
			if table.nums(self.chooseData) < ModelMaxNum[self.chooseModel] then
				viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
				viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))
			else
				viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange.png"))
				viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange.png"))
			end

		else
			self.chooseFullModel = 0
			self.chooseData = {}
			self.showIndex = {}
			self:initLayer()
			self:UpdateCountUI()
			if table.nums(self.chooseData) < ModelMaxNum[self.chooseModel] then
				viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
				viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))
			else
				viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange.png"))
				viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange.png"))
			end
		end
	end)
	viewData.ruleBtn:setOnClickScriptHandler(function(sender)
		-- body
		local str = __('进阶融合规则:使用5张同品质的碎片有几率融合随机更高品质的碎片 (R卡碎片进阶融合100%获得SR卡碎片1张,SR卡碎片进阶融合60%概率获得UR卡碎片1张,40%概率获得SR卡碎片2张)\n同阶融合规则:使用3张同品质的碎片可随机融合相同品质的卡牌碎片1张')
		uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('融合规则'), descr = str, type = 6})
	end)

	self.fullCardFragment = self:GetFullStarFragment()
	self.composecardsFragmentData = {}
	local t1 = {}
	local t2 = {}
	local q1 = {}
	local q2 = {}
	local datas = CommonUtils.GetConfigAllMess('cardFragmentCompound', 'compound')
	for i,v in pairs(datas) do
		local t = {}
		t.gold = v.gold
		t.targetQualityNum = v.targetQualityNum
		t.compoundQuality = v.compoundQuality
		-- t.targetQuality = v.targetQuality
		if checkint(v.type) == 1 then
			table.insert(t1,t)
			q1[tostring(v.compoundQuality)] = v.compoundQuality
		elseif checkint(v.type) == 2 then
			table.insert(t2,t)
			q2[tostring(v.compoundQuality)] = v.compoundQuality
		end
	end
	-- dump(t1)
	-- dump(t2)
	self.composecardsFragmentData['1'] = {}
	self.composecardsFragmentData['1'] = t1

	self.composecardsFragmentData['2'] = {}
	self.composecardsFragmentData['2'] = t2

	self.canComposeTargetQuality['1'] = {}
	self.canComposeTargetQuality['1'] = q1

	self.canComposeTargetQuality['2'] = {}
	self.canComposeTargetQuality['2'] = q2
	-- dump(self.canComposeTargetQuality)
	self:initLayer()

	self:UpdateCountUI()
end


function CardsFragmentComposeMediator:initLayer()
	self.backPackDatas = {}
	for k,v in pairs(gameMgr:GetUserInfo().backpack) do
		if v.amount > 0 then
			table.insert(self.backPackDatas,clone(v))
		end
	end

	local temp_data = {}
	for i=1 , 6  do
		temp_data[tostring(i)]= {
			fullBreak = {} ,
			common = {}
		}
	end
	for k, item in pairs( self.backPackDatas ) do
		local data = CommonUtils.GetConfig('goods', 'goods', item.goodsId)
		if data then
			if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
				if self.canComposeTargetQuality[tostring(self.chooseModel)][tostring(data.quality)] then
					item.quality = data.quality
					--table.insert(temp_data,item)
					if self.fullCardFragment[tostring(item.goodsId)] then
						local count = #temp_data[tostring(data.quality)].fullBreak
						temp_data[tostring(data.quality)].fullBreak[count+1] = item
					else
						local count = #temp_data[tostring(data.quality)].common
						temp_data[tostring(data.quality)].common[count+1] = item
					end
				end
			end
		end
	end
	local cardFragmentSort = {}
	for i = table.nums(temp_data) , 1 , -1 do
		for index, v in pairs(temp_data[tostring(i)].fullBreak) do
			cardFragmentSort[#cardFragmentSort+1] = v
		end
		if self.chooseFullModel == 0  then
			for index , v in pairs(temp_data[tostring(i)].common) do
				cardFragmentSort[#cardFragmentSort+1] = v
			end
		end
	end

	--卡牌碎片的排列按照品质从高到低进行排列
	--sortByMember(temp_data, "quality", false)

	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	self.cardsFragmentData = cardFragmentSort
	self.preIndex = 0
    if cardFragmentSort and table.nums(cardFragmentSort) > 0 then
        gridView:setCountOfCell(table.nums(self.cardsFragmentData))
        gridView:reloadData()
        viewData.kongBg:setVisible(false)
		viewData.bgView:setVisible(true)
		viewData.emptyLayer:setVisible(false)
    else
        self.cardsFragmentData = {}
        gridView:setCountOfCell(table.nums(self.cardsFragmentData))
        gridView:reloadData()
		if self.chooseFullModel == 0  then
			viewData.bgView:setVisible(false)
			viewData.kongBg:setVisible(false)
			viewData.emptyLayer:setVisible(false)
		else
			viewData.bgView:setVisible(true)
			viewData.kongBg:setVisible(false)
			viewData.emptyLayer:setVisible(true)
		end
    end

	for i,v in ipairs(viewData.Tcells) do
    	local cell = v
    	local addImg = cell:getChildByTag(6)
    	cell:setVisible(false)
    	addImg:setVisible(false)
    	addImg:setTexture(_res('ui/common/maps_fight_btn_pet_add.png'))
    	cell.goodsImg:setVisible(false)
    	cell.fragmentImg:setVisible(false)
    	cell.numLabel:setString(' ')
    	cell.maskImg:setVisible(false)
		cell.fragmentImg:setTexture(_res('ui/common/common_ico_fragment_1.png'))
		cell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
		cell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
		if self.isBatch then
			cell:setVisible(true)
			cell.toggleView:setNormalImage(_res('ui/common/compose_frame_unused.png'))
			cell.toggleView:setSelectedImage(_res('ui/common/compose_frame_unused.png'))
	    	-- if i <= 1 then
	    	-- 	addImg:setVisible(true)
	    	-- 	addImg:setTexture(_res('ui/common/compose_ico_selected.png'))
	    	-- 	cell.numLabel:setString(' ')
	    	-- else
	    	-- 	cell.maskImg:setVisible(true)
	    	-- end
	    	if i > ModelMaxNum[self.chooseModel] then
	    		cell:setVisible(false)
    		else
    			cell:setPosition(POST[self.chooseModel][i])
	    	end
	    else
	    	cell:setVisible(false)
	    	if i <= ModelMaxNum[self.chooseModel] then
	    		cell:setVisible(true)
	    		cell:setPosition(POST[self.chooseModel][i])
	    		addImg:setVisible(true)
	    		cell.numLabel:setString(' ')
	    	end
	    end
    end

 	-- local targetCell = viewData.targetCell
	-- targetCell.goodsImg:setVisible(false)
	-- targetCell.fragmentImg:setVisible(false)
	-- targetCell.numLabel:setString(' ')

	-- targetCell.fragmentImg:setTexture(_res('ui/common/common_ico_fragment_1.png'))
	-- targetCell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
	-- targetCell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))

	viewData.castNum:setString(tostring(0))

	viewData.desBatchLabel:setVisible(false)
	if self.isBatch then
		viewData.chooseLabel:setVisible(true)
		viewData.batchAllNum:setVisible(true)
		viewData.batchAllNum:setString('0')
	else
		viewData.batchFragmentImg:setVisible(false)
		viewData.chooseLabel:setVisible(false)
		viewData.batchAllNum:setVisible(false)
	end
end

---GetFullStarFragment 获取到满星的卡牌碎片
function CardsFragmentComposeMediator:GetFullStarFragment()
	local temp_data = {}
	local cardConf = CommonUtils.GetConfigAllMess('card' , 'card')
	for i, v in pairs(gameMgr:GetUserInfo().cards) do
		local cardOneConf = cardConf[tostring(v.cardId)]
		local breakCount = table.nums(cardOneConf.breakLevel)
		if v.breakLevel+ 1 >= breakCount then
			temp_data[tostring(cardOneConf.fragmentId)] = cardOneConf.fragmentId
		end
	end
	return temp_data
end

function CardsFragmentComposeMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local viewData = self.viewComponent.viewData_
    local bg = viewData.gridView
    local sizee = cc.size(108, 115)

    if self.cardsFragmentData and index <= table.nums(self.cardsFragmentData) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.cardsFragmentData[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
            -- pCell.checkBox:setOnClickScriptHandler(handler(self,self.BatchModelCallback))
            if index <= 20 then
				pCell.eventnode:setPositionY(sizee.height - 800)
			    pCell.eventnode:runAction(
			        cc.Sequence:create(cc.DelayTime:create(index * 0.01),
			        cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width* 0.5,sizee.height * 0.5)), 0.2))
			    )
			else
            	pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
			end
        else
            pCell.selectImg:setVisible(false)
            pCell.checkBox:setVisible(false)
            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        end
		xTry(function()
			local quality = 1
			if data then
				if data.quality then
					quality = data.quality
				end
			end
			pCell.maskImg:setVisible(false)
			local tempQuality = 0
			if next(self.chooseData) ~= nil then
				tempQuality = self.chooseData[1].quality
			end
			if checkint(tempQuality) ~= 0 then
				if checkint(quality) ~= checkint(tempQuality) then
					pCell.maskImg:setVisible(true)
				end
			end

			local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
			local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			if not utils.isExistent(drawBgPath) then
				drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
				fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(1)..'.png')
			end
			pCell.fragmentImg:setTexture(fragmentPath)
			pCell.toggleView:setNormalImage(drawBgPath)
			pCell.toggleView:setSelectedImage(drawBgPath)
			pCell.toggleView:setTag(index)
			pCell.checkBox:setTag(index)
			pCell.toggleView:setScale(0.92)
			pCell:setTag(index)

			if data then
				pCell.fragmentImg:setVisible(true)
			else
				pCell.fragmentImg:setVisible(false)
			end

			pCell.selectImg:setVisible(false)
			-- pCell.checkBox:setChecked(false)
			pCell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_select.png'))
			-- dump(self.isBatch)
			if self.isBatch then
				pCell.checkBox:setVisible(true)
			else
				pCell.checkBox:setVisible(false)
			end

			if next(self.chooseData) ~= nil then
				for i,v in ipairs(self.chooseData) do
					if checkint(self.cardsFragmentData[index].goodsId) == checkint(v.goodsId) then
						pCell.selectImg:setVisible(true)
						if self.isBatch then
							-- pCell.checkBox:setChecked(true)
							pCell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_hook.png'))
						end
						break
					end
				end
			end

			pCell.numLabel:setString(tostring(self.cardsFragmentData[index].amount))
			pCell.goodsImg:setVisible(true)
			local node = pCell.goodsImg
			local goodsId = self.cardsFragmentData[index].goodsId
			local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
			node:setTexture(_res(iconPath))

		end,__G__TRACKBACK__)
        return pCell
    end
end



function CardsFragmentComposeMediator:BatchButtonAction(sender)
	self.isBatch = sender:isChecked()
	local viewData = self.viewComponent.viewData_
	local label = sender:getChildByTag(1)
	if label then
		if self.isBatch then
			label:setString(__('返回'))
			viewData.chooseLabel:setVisible(true)
			viewData.batchAllNum:setVisible(true)
			viewData.batchAllNum:setString('0')
		else
			label:setString(__('批量融合'))
			viewData.batchFragmentImg:setVisible(false)
			viewData.chooseLabel:setVisible(false)
			viewData.batchAllNum:setVisible(false)
		end
	end



	for i,v in ipairs(self.chooseData) do
		for i,vv in ipairs(self.cardsFragmentData) do
			if checkint(vv.goodsId) == checkint(v.goodsId) then
				vv.amount = vv.amount + v.amount
				break
			end
		end
	end

	--删除已选碎片信息
	for i=#self.chooseData,1,-1 do
		table.remove(self.chooseData,i)
	end
	self.chooseData = {}
	--删除显示位置信息
	for k,v in pairs(self.showIndex) do
		self.showIndex[k] = nil
	end
	self.showIndex = {}


	local gridView = viewData.gridView
	self.gridContentOffset = gridView:getContentOffset()
	gridView:reloadData()
	self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
	gridView:setContentOffset(self.gridContentOffset)



	for i,v in ipairs(viewData.Tcells) do
    	local cell = v
    	local addImg = cell:getChildByTag(6)
    	cell:setVisible(false)
    	addImg:setVisible(false)
    	addImg:setTexture(_res('ui/common/maps_fight_btn_pet_add.png'))
    	cell.goodsImg:setVisible(false)
    	cell.fragmentImg:setVisible(false)
    	cell.numLabel:setString(' ')
		cell.maskImg:setVisible(false)
		cell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
		cell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
		if self.isBatch then
			cell:setVisible(true)
			cell.toggleView:setNormalImage(_res('ui/common/compose_frame_unused.png'))
			cell.toggleView:setSelectedImage(_res('ui/common/compose_frame_unused.png'))
	    	if i > ModelMaxNum[self.chooseModel] then
	    		cell:setVisible(false)
    		else
    			cell:setPosition(POST[self.chooseModel][i])
	    	end
	    else
	    	cell:setVisible(false)
	    	if i <= ModelMaxNum[self.chooseModel] then
	    		cell:setVisible(true)
	    		cell:setPosition(POST[self.chooseModel][i])
	    		addImg:setVisible(true)
	    		cell.numLabel:setString(' ')
	    	end
	    end
    end

	viewData.castNum:setString(tostring(0))

	viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
	viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))
	viewData.desBatchLabel:setVisible(false)

end

function CardsFragmentComposeMediator:TabButtonAction(sender)
	local tag = sender:getTag()
	sender:setChecked(true)
	if self.chooseModel == tag then return end
	self.chooseModel = tag

	for i,v in ipairs(self.chooseData) do
		for i,vv in ipairs(self.cardsFragmentData) do
			if checkint(vv.goodsId) == checkint(v.goodsId) then
				vv.amount = vv.amount + v.amount
				break
			end
		end
	end


	--删除已选碎片信息
	for i=#self.chooseData,1,-1 do
		table.remove(self.chooseData,i)
	end
	self.chooseData = {}
	--删除显示位置信息
	for k,v in pairs(self.showIndex) do
		self.showIndex[k] = nil
	end
	self.showIndex = {}



	local temp_data = {}
	for i=1 , 6  do
		temp_data[tostring(i)]= {
			fullBreak = {} ,
			common = {}
		}
	end
	for k, item in pairs( self.backPackDatas ) do
		local data = CommonUtils.GetConfig('goods', 'goods', item.goodsId)
		if data then
			if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
				if self.canComposeTargetQuality[tostring(self.chooseModel)][tostring(data.quality)] then
					item.quality = data.quality
					--table.insert(temp_data,item)
					if self.fullCardFragment[tostring(item.goodsId)] then
						local count = #temp_data[tostring(data.quality)].fullBreak
						temp_data[tostring(data.quality)].fullBreak[count+1] = item
					else
						local count = #temp_data[tostring(data.quality)].common
						temp_data[tostring(data.quality)].common[count+1] = item
					end
				end
			end
		end
	end
	local cardFragmentSort = {}
	for i = table.nums(temp_data) , 1 , -1 do
		for index, v in pairs(temp_data[tostring(i)].fullBreak) do
			cardFragmentSort[#cardFragmentSort+1] = v
		end
		if self.chooseFullModel == 0  then
			for index , v in pairs(temp_data[tostring(i)].common) do
				cardFragmentSort[#cardFragmentSort+1] = v
			end
		end
	end


	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	self.cardsFragmentData = {}
	self.cardsFragmentData = cardFragmentSort
	self.preIndex = 0
    if cardFragmentSort and table.nums(cardFragmentSort) > 0 then
		viewData.emptyLayer:setVisible(false)
        gridView:setCountOfCell(table.nums(self.cardsFragmentData))
        gridView:reloadData()
    else
        self.cardsFragmentData = {}
		viewData.emptyLayer:setVisible(true)
        gridView:setCountOfCell(table.nums(self.cardsFragmentData))
        gridView:reloadData()
    end



	local viewData = self.viewComponent.viewData_

	viewData.advancedButton:setChecked(false)
	viewData.equalButton:setChecked(false)
	sender:setChecked(true)

	local gridView = viewData.gridView
	gridView:reloadData()



	viewData.batchFragmentImg:setVisible(false)
	viewData.chooseLabel:setVisible(false)
	viewData.batchAllNum:setVisible(false)

	if self.isBatch then
		viewData.chooseLabel:setVisible(true)
		viewData.batchAllNum:setVisible(true)
		viewData.batchAllNum:setString('0')
	end


	for i,v in ipairs(viewData.Tcells) do
    	local cell = v
    	local addImg = cell:getChildByTag(6)
    	cell:setVisible(false)
    	addImg:setVisible(false)
    	addImg:setTexture(_res('ui/common/maps_fight_btn_pet_add.png'))
    	cell.goodsImg:setVisible(false)
    	cell.fragmentImg:setVisible(false)
    	cell.numLabel:setString(' ')
		cell.maskImg:setVisible(false)
		cell.fragmentImg:setTexture(_res('ui/common/common_ico_fragment_1.png'))
		cell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
		cell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
		if self.isBatch then
			cell:setVisible(true)
			cell.toggleView:setNormalImage(_res('ui/common/compose_frame_unused.png'))
			cell.toggleView:setSelectedImage(_res('ui/common/compose_frame_unused.png'))
	    	if i > ModelMaxNum[self.chooseModel] then
	    		cell:setVisible(false)
    		else
    			cell:setPosition(POST[self.chooseModel][i])
	    	end
	    else
	    	cell:setVisible(false)
	    	if i <= ModelMaxNum[self.chooseModel] then
	    		cell:setVisible(true)
	    		cell:setPosition(POST[self.chooseModel][i])
	    		addImg:setVisible(true)
	    		cell.numLabel:setString(' ')
	    	end
	    end
    end

	viewData.castNum:setString(tostring(0))
	viewData.desBatchLabel:setVisible(false)
	viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
	viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))
end


function CardsFragmentComposeMediator:ComposeButtonback(sender)
	if not self.isBatch then
		if table.nums(self.chooseData) < ModelMaxNum[self.chooseModel] then
			uiMgr:ShowInformationTips(__('所需飨灵碎片不足，无法融合'))
			return
		end
	else
		local fragmentNums = 0
		for i,v in ipairs(self.chooseData) do
			fragmentNums = fragmentNums + v.amount
		end
		if fragmentNums < ModelMaxNum[self.chooseModel] then
			uiMgr:ShowInformationTips(__('所需飨灵碎片不足，无法融合'))
			return
		end
	end
	if checkint(self.viewComponent.viewData_.castNum:getString()) > gameMgr:GetUserInfo().gold then
		uiMgr:ShowInformationTips(__('金币不足'))
		return
	end

    -- local descr = __('是否使用')
	local str = ''
	for i,v in ipairs(self.chooseData) do
        -- local fragConfig = CommonUtils.GetConfig('goods', 'cardFragment',v.goodsId)
        -- if fragConfig then
            -- if i == #self.chooseData then
                -- descr = descr .. string.fmt(__('__name_进行融合操作'), {__name_ = tostring(fragConfig.name)})
            -- else
                -- descr = descr .. string.fmt(__('__name_,'), {__name_ = tostring(fragConfig.name)})
            -- end
        -- end
		if i == 1 then
			str = v.goodsId
		else
			str = str..','..v.goodsId
		end
	end
    --添加一个融合判断提示
    local uiMgr = self:GetFacade():GetManager("UIManager")
    -- uiMgr:ShowInformationTips(__('幻晶石不足'))
    local scene = uiMgr:GetCurrentScene()
    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否使用碎片进行融合操作'),
            isOnlyOK = false, callback = function ()
                if not self.isBatch then
                    self:SendSignal(COMMANDS.COMMANDS_CardsFragment_Compose,{conversionType = self.chooseModel,cardFragments = str})
                else
                    self:SendSignal(COMMANDS.COMMANDS_CardsFragment_MultiCompose,{conversionType = self.chooseModel,cardFragments = str})
                end

    end})
    CommonTip:setPosition(display.center)
    scene:AddDialog(CommonTip)

end


function CardsFragmentComposeMediator:BatchModelCallback(sender)
	local index = sender:getTag()
	-- dump(index)
	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	local cell = gridView:cellAtIndex(index- 1)
	if cell.selectImg:isVisible() then
		cell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_select.png'))
		cell.selectImg:setVisible(false)

		for i,v in ipairs(self.chooseData) do
			if checkint(self.cardsFragmentData[index].goodsId) == checkint(v.goodsId) then
				self.cardsFragmentData[index].amount = v.amount
				break
			end
		end

    	--删除已选碎片信息
    	for i=#self.chooseData,1,-1 do
			if checkint(self.chooseData[i].goodsId) == checkint(self.cardsFragmentData[index].goodsId) then
				table.remove(self.chooseData,i)
				break
			end
		end

		local gridView = viewData.gridView
	    gridView:reloadData()

		self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
		gridView:setContentOffset(self.gridContentOffset)
	end
	self:updateBatchMess()
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function CardsFragmentComposeMediator:CellButtonAction( sender )
    -- sender:setChecked(true)
    local index = sender:getTag()
    uiMgr:ShowInformationTipsBoard({targetNode = sender,type = 1, iconId = self.cardsFragmentData[index].goodsId})
	local tempQuality = 0
	if next(self.chooseData) ~= nil then
		tempQuality = self.chooseData[1].quality
	end
	if checkint(tempQuality) ~= 0 then
		if checkint(self.cardsFragmentData[index].quality) ~= checkint(tempQuality) then
			uiMgr:ShowInformationTips(__('只能放入稀有度相同的飨灵碎片'))
			return
		end
	end
	if self.isBatch ~= true then
		if self.cardsFragmentData[index].amount <= 0 then
			return
		end
	end

	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView

    local cell = gridView:cellAtIndex(index- 1)
	if self.isBatch == true then
		if cell.selectImg:isVisible() then
			self:BatchModelCallback(cell.checkBox)
			return
		end
	else
	    if table.nums(self.chooseData) >= ModelMaxNum[self.chooseModel] then
	    	uiMgr:ShowInformationTips(__('选择飨灵碎片数量已满，可以进行融合'))
	    	return
	    end
	end


    if cell then
        cell.selectImg:setVisible(true)
    end


    --更新按钮状态
    self.preIndex = index
    self.gridContentOffset = gridView:getContentOffset()
    if not self.isBatch then

	    self.cardsFragmentData[index].amount = self.cardsFragmentData[index].amount - 1
	    local v = {}
	    v = clone(self.cardsFragmentData[index])
	    local tempIndex = 0
		for i=1,ModelMaxNum[self.chooseModel] do
			if not self.showIndex[tostring(i)] then
				tempIndex = i
				break
			end
		end
	    v.index = tempIndex
	    v.amount = 1
	    table.insert(self.chooseData,v)
	    self:updateDescription(self.preIndex)
		self.showIndex[tostring(tempIndex)] = tempIndex

	else

	    local v = {}
	    v.amount = self.cardsFragmentData[index].amount
	    v = clone(self.cardsFragmentData[index])
	    self.cardsFragmentData[index].amount = 0
		table.insert(self.chooseData,v)
		self:updateBatchMess()
	end

	local gridView = viewData.gridView
    gridView:reloadData()

	self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
	gridView:setContentOffset(self.gridContentOffset)

end
--[[
已选择卡牌碎片按钮
@param sender button对象
--]]
function CardsFragmentComposeMediator:ButtonActions( sender )
	if self.isBatch then return end
	local tag = sender:getTag()
	local index = sender:getUserTag()

	local clickData = nil
	for i,v in ipairs(self.chooseData) do
		if checkint(v.goodsId) == checkint(tag) and checkint(v.index) == checkint(index) then
			clickData = v
			break
		end
	end

	if clickData then
		local viewData = self.viewComponent.viewData_
    	local cell = viewData.Tcells[clickData.index]
    	local addImg = cell:getChildByTag(6)
    	addImg:setVisible(true)
    	cell.goodsImg:setVisible(false)
    	cell.fragmentImg:setVisible(false)
    	cell.numLabel:setString(' ')
    	for i,v in ipairs(self.cardsFragmentData) do
    		if checkint(v.goodsId) == checkint(tag) then
    			v.amount = v.amount + 1
    			break
    		end
    	end

    	--删除已选碎片信息
    	for i=#self.chooseData,1,-1 do
			if checkint(self.chooseData[i].goodsId) == checkint(tag) and checkint(self.chooseData[i].index) == checkint(index) then
				table.remove(self.chooseData,i)
				break
			end
		end
		--删除显示位置信息
		for k,v in pairs(self.showIndex) do
			if v == index then
				self.showIndex[k] = nil
				break
			end
		end


		local drawBgPath = _res('ui/common/common_frame_goods_1.png')
		local fragmentPath = _res('ui/common/common_ico_fragment_1.png')
		cell.fragmentImg:setTexture(fragmentPath)
		cell.toggleView:setNormalImage(drawBgPath)
		cell.toggleView:setSelectedImage(drawBgPath)


		if next(self.chooseData) == nil then
			viewData.castNum:setString(tostring(0))
		end

		local gridView = viewData.gridView
   		gridView:reloadData()

		self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
		gridView:setContentOffset(self.gridContentOffset)


		viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
		viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))

	end
end
--[[
@param index int下标
--]]
function CardsFragmentComposeMediator:updateDescription( index )
	local data = self.cardsFragmentData[index]
	local localData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
	local viewData = self.viewComponent.viewData_
	viewData.desBatchLabel:setVisible(false)
	local tempIndex = 0
	if table.nums(self.chooseData) == 1 then
		tempIndex = 1
	else
		for i=1,ModelMaxNum[self.chooseModel] do
			if not self.showIndex[tostring(i)] then
				tempIndex = i
				break
			end
		end
	end

	local cell = viewData.Tcells[tempIndex]
	if not cell then return end
	local quality = 1
	if localData then
		if localData.quality then
			quality = localData.quality
		end
	end
	cell.toggleView:setTag(data.goodsId)
	cell.toggleView:setUserTag(tempIndex)
	local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
	local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
	if not utils.isExistent(drawBgPath) then
		drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
		fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(1)..'.png')
	end
	cell.fragmentImg:setTexture(fragmentPath)
	cell.toggleView:setNormalImage(drawBgPath)
	cell.toggleView:setSelectedImage(drawBgPath)
	cell.fragmentImg:setVisible(true)

	cell.numLabel:setString('1')

	local goodsId = data.goodsId
	local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
	cell.goodsImg:setTexture(_res(iconPath))
	cell.goodsImg:setVisible(true)
	local addImg = cell:getChildByTag(6)
	addImg:setVisible(false)

	local needGold = 0
	for i,v in ipairs(self.composecardsFragmentData[tostring(self.chooseModel)]) do
		if checkint(v.compoundQuality) == checkint(quality) then
			needGold = v.gold
			break
		end
	end

	viewData.castNum:setString(tostring(needGold))


	if table.nums(self.chooseData) < ModelMaxNum[self.chooseModel] then
		viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
		viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))
	else
		viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange.png"))
		viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange.png"))
	end

end

function CardsFragmentComposeMediator:updateBatchMess(  )
	-- dump(self.chooseData)
	local localData = nil

	if self.chooseData[1] then
		localData = CommonUtils.GetConfig('goods', 'goods', self.chooseData[1].goodsId)
	end
	local viewData = self.viewComponent.viewData_
	viewData.desBatchLabel:setVisible(true)


	viewData.batchFragmentImg:setVisible(true)
	viewData.chooseLabel:setVisible(true)
	viewData.batchAllNum:setVisible(true)

	local quality = 1
	if localData then
		if localData.quality then
			quality = localData.quality
		end
	else
		viewData.batchFragmentImg:setVisible(false)
	end


	local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
	if not utils.isExistent(fragmentPath) then
		fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(1)..'.png')
	end
	viewData.batchFragmentImg:setTexture(fragmentPath)

	local fragmentNums = 0
	for i,v in ipairs(self.chooseData) do
		fragmentNums = fragmentNums + v.amount
	end


	local needGold = 0
	for i,v in ipairs(self.composecardsFragmentData[tostring(self.chooseModel)]) do
		if checkint(v.compoundQuality) == checkint(quality) then
			needGold = v.gold
			break
		end
	end

	viewData.batchAllNum:setString(tostring(fragmentNums))

	if fragmentNums < ModelMaxNum[self.chooseModel] then
		viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange_disable.png"))
		viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange_disable.png"))
		viewData.desBatchLabel:setString(__('可批量融合0次'))
		viewData.castNum:setString('0')
	else
		viewData.composeBtn:setNormalImage(_res("ui/common/common_btn_orange.png"))
		viewData.composeBtn:setSelectedImage(_res("ui/common/common_btn_orange.png"))

		local num = math.floor(fragmentNums / ModelMaxNum[self.chooseModel])
		viewData.castNum:setString(tostring(needGold*num))
		viewData.desBatchLabel:setString(string.fmt(__('可批量融合_num_次'),{_num_ = num}))
	end
end
--[[
	第一个是移动的距离，容量大小，第三个是内容大小
--]]
function CardsFragmentComposeMediator:returnsetContentOffset(point,contentSize,containerSize)
	if math.abs(point.y) + contentSize.height > containerSize.height then
		return cc.p(0,contentSize.height - containerSize.height)
	else
		return point
	end
end

function CardsFragmentComposeMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	local CardsFragmentComposeCommand = require( 'Game.command.CardsFragmentComposeCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_CardsFragment_Compose, CardsFragmentComposeCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_CardsFragment_MultiCompose, CardsFragmentComposeCommand)

end
function CardsFragmentComposeMediator:OnUnRegist(  )
	--称出命令
	if self.isDataDirty_ then
		self:GetFacade():DispatchObservers(CardsFragmentCompose_Callback)
	end
	
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)

	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_CardsFragment_Compose)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_CardsFragment_MultiCompose)
end


return CardsFragmentComposeMediator
