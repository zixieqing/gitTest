--[[
堕神列表弹窗
@params table {
	id int card id
	lv int card level
	breakLv int breakLvp
	exp int card exp
}
--]]
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local GameScene = require( "Frame.GameScene" )

local ChooesePetListView = class('ChooesePetListView', GameScene)
local ChoosePetCell = require('home.ChoosePetCell')


local screenType = {
	{descr = __('全部'), 	typeDescr = __('全部'), tag = 99},
	{descr = __('攻击力'), 	typeDescr = __('攻击力'), tag = 1},
	{descr = __('防御力'), 	typeDescr = __('防御力'), tag = 2},
	{descr = __('生命值'), 	typeDescr = __('生命值'), tag = 3},
	{descr = __('暴击值'), 	typeDescr = __('暴击值'), tag = 4},
	{descr = __('暴伤值'), 	typeDescr = __('暴伤值'), tag = 5},
	{descr = __('攻速值'), 	typeDescr = __('攻速值'), tag = 6}
}

function ChooesePetListView:ctor( ... )
	local arg = unpack({...})
    self.args = arg
    if arg.callback then self.callback = arg.callback end
    if arg.showCallback then self.showCallback = arg.showCallback end
    if arg.backCallback then self.backCallback = arg.backCallback end
    self.useItemsNum = 0
    -- dump(self.args)
	--------------------------------------
	-- ui

	--------------------------------------
	-- ui data
	self.clickTag = 0 --当前选择第几个堕神

	--------------------------------------
	-- ui
	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	self:initUI()
end



function ChooesePetListView:initUI()
	-- self:setBackgroundColor(cc.c4b(0, 255, 128, 128))
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function (sender)
        PlayAudioByClickNormal()
		if self.backCallback then
	        self.backCallback()
	    end
	    self:runAction(cc.RemoveSelf:create())
	end)

	local bgSize = cc.size(771, display.size.height)


    local view = CLayout:create()
    -- view:setPosition(0, 0)
    view:setAnchorPoint(cc.p(0,0.5))
    view:setContentSize(bgSize)
    view:setPosition(cc.p(-6 + display.SAFE_L, display.height * 0.5))
	view:setName('view')
    self:addChild(view)
    -- view:setBackgroundColor(cc.c4b(0, 255, 128, 128))


	local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0,
		{ap = cc.p(0, 0),scale9 = true, size = bgSize})--scale9 = true, size = bgSize,
	view:addChild(bg)
	bg:setTouchEnabled(true)

	local titleBtn = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_3.png'),enable = false})
 	display.commonUIParams(titleBtn, {po = cc.p( bgSize.width * 0.5,bgSize.height- 6),ap = cc.p(0.5,1)})
 	display.commonLabelParams(titleBtn, {text = __('堕神列表'), fontSize = 24, color = '#7e6454',offset = cc.p(0,-4)})
 	view:addChild(titleBtn)

	local listBg = display.newImageView(_res('ui/backpack/bag_bg_frame_gray_1.png'), 0, 0,
		{ap = cc.p(0, 0),scale9 = true, size = cc.size(729,587)})
	view:addChild(listBg)
	listBg:setPosition(cc.p(10,95))
	--
	local frameSize = listBg:getContentSize()

	local taskListSize = cc.size(frameSize.width - 10, frameSize.height - 10)
	local taskListCellSize = cc.size(taskListSize.width/2, 192)--taskListSize.height/5

   	local gridView = CGridView:create(taskListSize)
	gridView:setName('gridView')
    gridView:setSizeOfCell(taskListCellSize)
    gridView:setColumns(2)
    gridView:setAutoRelocate(false)
    gridView:setBounceable(true)
	view:addChild(gridView, 3)
	gridView:setAnchorPoint(cc.p(0, 0))
    gridView:setPosition(cc.p(14 ,100))
    -- gridView:setBackgroundColor(cc.c4b(0, 255, 128, 128))
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    self.gridView = gridView



	self.iconIds = {}
	local sss = string.split(self.cardData.exclusivePet, ';')
	for i,v in ipairs(sss) do
		self.iconIds[tostring(v)] = v
	end


	self.Tdata =  {}
	for k,v in pairs(gameMgr:GetUserInfo().pets) do
		local v = clone(v)
		v.quality = 1
		local localPetData = CommonUtils.GetConfig('goods','pet',v.petId)
		if localPetData then
			v.quality = checkint(localPetData.quality)
		end
		v.playerPetId = v.id

		if self.iconIds[tostring(v.petId)] then
			if checkint(self.args.playerPetId) ~= checkint(v.id) then
				v.sortIndex = 2 -- 本命第二位
			else
				v.sortIndex = 1 -- 已选择第一位
			end
		else
			if checkint(self.args.playerPetId) ~= checkint(v.id) then
				v.sortIndex = 3 --其他
			else
				v.sortIndex = 1 -- 已选择第一位
			end
		end
		table.insert(self.Tdata,v)
	end

	table.sort(self.Tdata, function(a, b)
    	local r
		local al = tonumber(a.level)
		local bl = tonumber(b.level)
		local aid = tonumber(a.petId)
		local bid = tonumber(b.petId)
		local aq = tonumber(a.quality)
		local bq = tonumber(b.quality)
		local ab = tonumber(a.breakLevel)
		local bb = tonumber(b.breakLevel)

		local ai = tonumber(a.sortIndex)
		local bi = tonumber(b.sortIndex)
		if ai == bi then
			if al == bl then
				if aq == bq then
					if ab == bb then
						r = aid < bid--petId
					else
						r = ab > bb--卡牌等级降序
					end
				else
					r = aq > bq--卡牌品质降序
				end
			else
				r = al > bl--卡牌等级降序
			end
		else
			r = ai < bi--卡牌等级降序
		end
		return r
    end)


	self.clickType = 1

    local upBtn = display.newButton(0, 0,
    	{n = _res('ui/common/common_btn_orange_disable.png'),enabel = true, animate = true, cb = handler(self, self.ButtonCallback)})
	upBtn:setName('upBtn')
    display.commonUIParams(upBtn, {ap = cc.p(0.5,0),po = cc.p( bgSize.width * 0.5,  20)})
    display.commonLabelParams(upBtn, fontWithColor(14,{text = __('装备'), ap = cc.p(0.5,0.5)}))
    view:addChild(upBtn)
    upBtn:setTag(1)
    self.upBtn = upBtn


    local operationPetBtn = display.newButton(0, 0,
    	{n = _res('ui/common/common_btn_orange_disable.png'),enabel = true, animate = true, cb = handler(self, self.ButtonCallback)})
    display.commonUIParams(operationPetBtn, {ap = cc.p(0.5,0),po = cc.p( bgSize.width * 0.5 - 200,  20)})
    display.commonLabelParams(operationPetBtn, fontWithColor(14,{text = __('培养'), ap = cc.p(0.5,0.5)}))
    view:addChild(operationPetBtn)
    operationPetBtn:setTag(2)
    self.operationPetBtn = operationPetBtn


	local screenBtn = display.newCheckBox(0, 0,
		{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
	display.commonUIParams(screenBtn, {po = cc.p(170, view:getContentSize().height - 10),ap = cc.p(1,1)})--view:getContentSize().width - 180
	view:addChild(screenBtn, 10)
	screenBtn:setOnClickScriptHandler(handler(self, self.ScreenBtnCallback))
	self.screenBtn = screenBtn

    local arrowImg = display.newImageView(_res("ui/home/cardslistNew/card_ico_direction.png"),utils.getLocalCenter(screenBtn).x + 38,utils.getLocalCenter(screenBtn).y )
    arrowImg:setAnchorPoint(cc.p(0,0.5))
    screenBtn:addChild(arrowImg)


	local screenLabel = display.newLabel(utils.getLocalCenter(screenBtn).x, utils.getLocalCenter(screenBtn).y ,
		fontWithColor(5,{text = __('筛选'),color = 'ffffff',fontSize = 22}))
	screenBtn:addChild(screenLabel)
	self.screenLabel = screenLabel

	local screenBoardImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_frame_1.png'), screenBtn:getPositionX() + 20, screenBtn:getPositionY() - screenBtn:getContentSize().height * 0.5 - 30
		,{scale9 = true,size = cc.size(160,56*table.nums(screenType))})
	local screenBoard = display.newLayer(screenBoardImg:getPositionX() , screenBoardImg:getPositionY()  ,
		{size = cc.size(screenBoardImg:getContentSize().width,screenBoardImg:getContentSize().height - 16), ap = cc.p(1, 1)})
	-- screenBoard:setBackgroundColor(cc.c4b(0, 128, 0, 100))
	view:addChild(screenBoard, 15)
	display.commonUIParams(screenBoardImg, {po = utils.getLocalCenter(screenBoard)})
	screenBoard:addChild(screenBoardImg)
	screenBoard:setVisible(false)
	self.screenBoard = screenBoard
	-- 排序类型
	local topPadding = 2
	local bottomPadding = 0
	local listSize = cc.size(screenBoard:getContentSize().width, screenBoard:getContentSize().height - topPadding - bottomPadding)
	local cellSize = cc.size(listSize.width, listSize.height / (table.nums(screenType)))
	local centerPos = nil
	local screenTab = {}
	for i,v in ipairs(screenType) do
		-- centerPos = cc.p(listSize.width * 0.5, listSize.height + bottomPadding - (i - 0.5) * cellSize.height)
		centerPos = cc.p(listSize.width * 0.5, listSize.height  - (i * cellSize.height) + cellSize.height *0.5 )
		local sortTypeBtn = display.newButton(0, 0, {size = cellSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(sortTypeBtn, {po = cc.p(centerPos)})
		screenBoard:addChild(sortTypeBtn)
		sortTypeBtn:setTag(v.tag)
		-- table.insert(screenTab,sortTypeBtn)
		sortTypeBtn:setOnClickScriptHandler(handler(self, self.ScreenTypeBtnCallback))
		if v.bgPath then
			local descrLabel = display.newLabel(0, 0,
				fontWithColor(5,{text = v.typeDescr, ap = cc.p(0, 0.5),fontSize = 22}))

			local careerBg = display.newNSprite(_res(v.bgPath), centerPos.x - 25, centerPos.y)

			local totalWidth = careerBg:getContentSize().width * careerBg:getScale() + display.getLabelContentSize(descrLabel).width
			display.commonUIParams(careerBg, {po = cc.p(
				centerPos.x - totalWidth * 0.5 + careerBg:getContentSize().width * 0.5 * careerBg:getScale(),
				centerPos.y)})
			screenBoard:addChild(careerBg)

			local careerIcon = display.newNSprite(_res(v.iconPath), utils.getLocalCenter(careerBg).x, utils.getLocalCenter(careerBg).y + 2)
			careerIcon:setScale(0.65)
			careerBg:addChild(careerIcon)

			display.commonUIParams(descrLabel, {po = cc.p(careerBg:getPositionX() + careerBg:getContentSize().width * 0.5, careerBg:getPositionY())})
			screenBoard:addChild(descrLabel)


		else
			local descrLabel = display.newLabel(0, 0,
				fontWithColor(5,{text = v.typeDescr, ap = cc.p(0.5, 0.5),fontSize = 22}))
			display.commonUIParams(descrLabel, {po = centerPos})
			screenBoard:addChild(descrLabel)
		end

		if i < table.nums(screenType) then
			local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), centerPos.x, centerPos.y - cellSize.height * 0.5)
			screenBoard:addChild(splitLine)
		end
	end

    -- dump(table.nums(self.Tdata))
    if table.nums(self.Tdata) == 0 then
		local showLabel = display.newLabel(bgSize.width * 0.5,bgSize.height * 0.5,
			{ttf = true, font = TTF_GAME_FONT,text = __('      暂无更多堕神\n去堕神界面孵化更多堕神吧'), fontSize = 26, color = '6c6c6c', ap = cc.p(0.5, 0.5)})
		view:addChild(showLabel)
    else
	    gridView:setCountOfCell(table.nums(self.Tdata))
	    gridView:reloadData()


	    if self.args.playerPetId then
		    self.clickTag = 1
		    local cell = gridView:cellAtIndex(0)
		    if cell then
		    	self:cellCallBackActions(cell.rankBg)
		    end
		end
	end
end


--[[
筛选按钮回调
--]]
function ChooesePetListView:ScreenBtnCallback(sender)
    PlayAudioByClickNormal()
	local checked = sender:isChecked()
	self:ShowScreenBoard(checked)
end
--[[
显示筛选排序板
@params visible bool 是否显示排序板
--]]
function ChooesePetListView:ShowScreenBoard(visible)
	self.screenBtn:setChecked(visible)
	if visible == true then
		self.screenBoard:setScaleY(0)
		for i=1,10 do
			self.screenBoard:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.01),cc.CallFunc:create(function ()
					self.screenBoard:setScaleY(i*0.1)
				end)))
		end
		self.screenBoard:setVisible(visible)
	else
		self.screenBoard:setScaleY(1)
		self.screenBoard:setVisible(visible)
	end

end

--[[
筛选按钮点击回调
--]]
function ChooesePetListView:ScreenTypeBtnCallback(sender)
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:ScreenCards(tag)
	local str = ''
	if tag == 99 then
		str = screenType[1].descr
	else
		str = screenType[tag+1].descr
	end
	self.screenLabel:setString(str)
	self:ShowScreenBoard(false)
end

--[[
排序整个界面
@params pattern int 排序模式
0 默认所有卡牌按照 id 排序
1 所有防御型
2 所有近战 dps
3 所有远程 dps
4 所有辅助型
5 碎片
--]]
function ChooesePetListView:ScreenCards(pattern)
	self.Tdata = {}
	local index = 1
	for k,v in pairs(gameMgr:GetUserInfo().pets) do
		local v = clone(v)
		v.quality = 1
		local localPetData = CommonUtils.GetConfig('goods','pet',v.petId)
		if localPetData then
			v.quality = checkint(localPetData.quality)
		end
		v.playerPetId = v.id

		if self.iconIds[tostring(v.petId)] then
			if checkint(self.args.playerPetId) ~= checkint(v.id) then
				v.sortIndex = 2 -- 本命第二位
			else
				v.sortIndex = 1 -- 已选择第一位
			end
		else
			if checkint(self.args.playerPetId) ~= checkint(v.id) then
				v.sortIndex = 3 --其他
			else
				v.sortIndex = 1 -- 已选择第一位
			end
		end
		v.messNums = 0
		if pattern ~= 99 then
			for j=1,4 do
		 		local petMess = petMgr.GetPetAFixedProp(v.id, j)
		 		if petMess.unlock == true then
		 			-- dump(pattern)
		 			-- dump(petMess.ptype)
		 			if checkint(pattern) == checkint(petMess.ptype) then
		 				v.messNums = v.messNums + checkint(petMess.pvalue)
		 			end
		 		end
			end
		else
			table.insert(self.Tdata,v)
		end

		if v.messNums ~= 0 then
			table.insert(self.Tdata,v)
		end
		index = index + 1
	end

	table.sort(self.Tdata, function(a, b)
    	local r
		local am = tonumber(a.messNums)
		local bm = tonumber(b.messNums)
		local al = tonumber(a.level)
		local bl = tonumber(b.level)
		local aid = tonumber(a.petId)
		local bid = tonumber(b.petId)
		local aq = tonumber(a.quality)
		local bq = tonumber(b.quality)
		local ab = tonumber(a.breakLevel)
		local bb = tonumber(b.breakLevel)
		local ai = tonumber(a.sortIndex)
		local bi = tonumber(b.sortIndex)
		if am == bm then
			if ai == bi then
				if al == bl then
					if aq == bq then
						if ab == bb then
							r = aid < bid--petId
						else
							r = ab > bb--卡牌等级降序
						end
					else
						r = aq > bq--卡牌品质降序
					end
				else
					r = al > bl--卡牌等级降序
				end
			else
				r = ai < bi--卡牌等级降序
			end
		else
			r = am > bm--卡牌等级降序
		end
		return r
    end)


    self.gridView:setCountOfCell(table.nums(self.Tdata))
    self.gridView:reloadData()
    self.clickTag = 1
    local cell = self.gridView:cellAtIndex(0)
    if cell then
    	self:cellCallBackActions(cell.rankBg)
    end

end

--[[
装备，卸下按钮回调
tag： 1为装备。2为卸下
@param sender button对象
--]]
function ChooesePetListView:ButtonCallback( sender  )

	if next(self.Tdata) == nil then
		uiMgr:ShowInformationTips(__('未选择堕神'))
		return
	end

	local tag = sender:getTag()
	if tag == 1 then

		if self.clickType == 1 then-- 装
			-- print(self.clickTag)
			if self.clickTag ~= 0 then

				if self.Tdata[self.clickTag].playerCardId then--选择的堕神为已装备状态
					local scene = uiMgr:GetCurrentScene()
					local temp_str =  __('该堕神已经携带在其他\n飨灵身上，是否将其移至\n当前飨灵。')
					local CommonTip  = require( 'common.CommonTip' ).new({text = temp_str,isOnlyOK = false, callback = function ()
						if self.callback then
							self.datas = {}
							self.datas = clone(self.Tdata[self.clickTag])
							self.datas.operation = self.clickType--tag
					        self.callback(self.datas)
					    end
					    self:runAction(cc.RemoveSelf:create())
				    end})
					CommonTip:setPosition(display.center)
					scene:AddDialog(CommonTip)
				else
					if self.callback then
						self.datas = {}
						self.datas = clone(self.Tdata[self.clickTag])
						self.datas.operation = self.clickType --tag
				        self.callback(self.datas)
				    end
				    self:runAction(cc.RemoveSelf:create())
				end
			else
				uiMgr:ShowInformationTips(__('未选择堕神'))
			end
		elseif self.clickType == 2 then--卸
			if self.args.playerPetId then
				if self.callback then
					self.datas = {}
					self.datas.playerPetId = self.args.playerPetId
					self.datas.operation = self.clickType--tag
			        self.callback(self.datas)
			    end
			    self:runAction(cc.RemoveSelf:create())
			else
				uiMgr:ShowInformationTips(__('未装备堕神'))
			end
		end
	elseif tag == 2 then
		if self.clickTag ~= 0 then
			AppFacade.GetInstance():DispatchObservers(EVENT_UPGRADE_PET, {id = checktable(self.Tdata[self.clickTag]).playerPetId})
		else
			uiMgr:ShowInformationTips(__('未选择堕神'))
		end
	end
	GuideUtils.DispatchStepEvent()
end

--[[ cc.ui RichText
cell事件处理逻辑
@param sender button对象
--]]
function ChooesePetListView:cellCallBackActions( sender  )
	local tag = sender:getTag()

	if self.showCallback then
		self.datas = {}
		self.datas = clone(self.Tdata[tag])
        self.showCallback(self.datas)
    end


	local cell = self.gridView:cellAtIndex(self.clickTag - 1)
	if cell then
		cell.rankBg:setTexture(_res('ui/cards/petNew/card_pet_bg_card.png'))
        if self.iconIds[tostring(self.Tdata[self.clickTag].petId)] then
        	cell.rankBg:setTexture(_res('ui/cards/petNew/card_pet_bg_card_sp.png'))
        end
	end

    self.clickTag = tag

 	local cell = self.gridView:cellAtIndex(self.clickTag - 1)
	if cell then
		cell.rankBg:setTexture(_res('ui/cards/petNew/card_pet_bg_card_selected.png'))
	end

    self.upBtn:getLabel():setString(__('装备'))

    self.clickType = 1
    if self.args.playerPetId then
    	if checkint(self.args.playerPetId) == checkint(self.Tdata[tag].playerPetId) then
    		self.upBtn:getLabel():setString(__('卸下'))
    		self.clickType = 2
    	end

    -- else
    -- 	self.clickType = 1
    end

  	self.upBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
  	self.upBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))

  	self.operationPetBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
  	self.operationPetBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))

	  GuideUtils.DispatchStepEvent()
    -- self:runAction(cc.RemoveSelf:create())
end

function ChooesePetListView:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local bg = self.gridView
    local sizee = cc.size(bg:getContentSize().width/2,192)
    -- if self.Tdata and index <= table.nums(self.Tdata) then --  self.Tdata and
        if pCell == nil then
            pCell = ChoosePetCell.new(sizee)
            pCell.eventnode:setScale(0.5)
            pCell.eventnode:runAction(cc.Sequence:create(
            	cc.Spawn:create(cc.FadeIn:create(0.4), cc.ScaleTo:create(0.4,1.0)),
            	cc.CallFunc:create(function ()
					pCell.rankBg:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
				end))
	            )
        else
	       	pCell.eventnode:setScale(1.0)
    		pCell.eventnode:setOpacity(255)
    		pCell.rankBg:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
        end
        xTry(function()
	        pCell:updataUi(self.Tdata[index],self.args.playerPetId)
	        pCell.rankBg:setTag(index)


	        pCell.exclusivePetStarImage:setVisible(false)


	        if self.clickTag == index then
	        	pCell.rankBg:setTexture(_res('ui/cards/petNew/card_pet_bg_card_selected.png'))
	        else
	        	pCell.rankBg:setTexture(_res('ui/cards/petNew/card_pet_bg_card.png'))
		        if self.iconIds[tostring(self.Tdata[index].petId)] then
		        	pCell.rankBg:setTexture(_res('ui/cards/petNew/card_pet_bg_card_sp.png'))
					pCell.exclusivePetStarImage:setVisible(true)
		        end
	        end


        end,__G__TRACKBACK__)
        return pCell
    -- end
end


function ChooesePetListView:UpdataUI()
	self.Tdata =  {}
	self.cardData =  CommonUtils.GetConfig('cards', 'card', self.args.cardId)


	self.iconIds = {}
	local sss = string.split(self.cardData.exclusivePet, ';')
	for i,v in ipairs(sss) do
		self.iconIds[tostring(v)] = v
	end

	self.Tdata =  {}
	for k,v in pairs(gameMgr:GetUserInfo().pets) do
		local v = clone(v)
		v.quality = 1
		local localPetData = CommonUtils.GetConfig('goods','pet',v.petId)
		if localPetData then
			v.quality = checkint(localPetData.quality)
		end
		v.playerPetId = v.id

		if self.iconIds[tostring(v.petId)] then
			if checkint(self.args.playerPetId) ~= checkint(v.id) then
				v.sortIndex = 2 -- 本命第二位
			else
				v.sortIndex = 1 -- 已选择第一位
			end
		else
			if checkint(self.args.playerPetId) ~= checkint(v.id) then
				v.sortIndex = 3 --其他
			else
				v.sortIndex = 1 -- 已选择第一位
			end
		end
		table.insert(self.Tdata,v)
	end

	table.sort(self.Tdata, function(a, b)
    	local r
		local al = tonumber(a.level)
		local bl = tonumber(b.level)
		local aid = tonumber(a.petId)
		local bid = tonumber(b.petId)
		local aq = tonumber(a.quality)
		local bq = tonumber(b.quality)
		local ab = tonumber(a.breakLevel)
		local bb = tonumber(b.breakLevel)

		local ai = tonumber(a.sortIndex)
		local bi = tonumber(b.sortIndex)
		if ai == bi then
			if al == bl then
				if aq == bq then
					if ab == bb then
						r = aid < bid--petId
					else
						r = ab > bb--卡牌等级降序
					end
				else
					r = aq > bq--卡牌品质降序
				end
			else
				r = al > bl--卡牌等级降序
			end
		else
			r = ai < bi--卡牌等级降序
		end
		return r
    end)


 	self.gridView:setCountOfCell(table.nums(self.Tdata))
	self.gridView:reloadData()
end


return ChooesePetListView
