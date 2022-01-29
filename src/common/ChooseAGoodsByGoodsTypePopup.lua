--[[
通用弹窗 从某一类道具中选择一个添加到外部逻辑

-- TODO -- 目前没有卸下功能

@params table {
	goodsType GoodsType 道具类型
	callbackSignalName 回调信号
	parameter table 回传参数
	except map 除去的一些道具id
	showWaring bool 显示警告框
	waringText string 警告文字
	noThingText string 没有该类型物品的提示文字
	sticky	map	置顶的道具id
}
--]]
local ChooseAGoodsByGoodsTypePopup = class('ChooseAGoodsByGoodsTypePopup', function()
    local node = CLayout:create(display.size)
    node.name = 'ChooseAGoodsByGoodsTypePopup'
	node:enableNodeEvents()
    return node
end)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------
local RES_DICT = {
	LISTBG 			= 'ui/backpack/bag_bg_frame_gray_1.png',
	DESBG 			= 'ui/backpack/bag_bg_font.png',
	Btn_Normal 		= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 	= "ui/common/common_btn_sidebar_selected.png",
	Btn_Sale 		= "ui/common/common_btn_orange.png",
	Img_cartoon 	= "ui/common/common_ico_cartoon_1.png",
	Bg_describe 	= "ui/backpack/bag_bg_describe_1.png",
	Btn_UnEanble    = 'ui/common/common_btn_orange_disable.png'

}

local BackpackCell = require('home.BackpackCell')
--[[
override
initui
--]]
function ChooseAGoodsByGoodsTypePopup:ctor(...)
    self.args = unpack({...})
    self.goodsType = self.args.goodsType

    self.cardId = self.args.cardId
    self.clickTag = 1005
    self.preIndex = 1

	local goodsTypeConfig = CommonUtils.GetConfig('goods', 'type', self.goodsType)

	self.showStarCondition = self.args.showStarCondition or {}

	self.parameter = self.args.parameter
	self.sticky = self.args.sticky or nil
	self.callbackSignalName = self.args.callbackSignalName

	self.showWaring = self.args.showWaring
	self.waringText = self.args.waringText
	self.noThingText = self.args.noThingText or nil
	self.selectedGoodsIndex = 0
	--创建页面
	local view = require("common.TitlePanelBg").new({ title = goodsTypeConfig.type, type = 11, cb = function()
        PlayAudioByClickClose()
        uiMgr:GetCurrentScene():RemoveDialog(self)
    end})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)


	local function CreateView()
        local size = cc.size(1046,590)
        local cview = CLayout:create(size)

        local kongBg = CLayout:create(cc.size(900,590))
        -- kongBg:setBackgroundColor(cc.c4b(100,100,100,100))
        display.commonUIParams(kongBg, {ap = cc.p(0,0), po = cc.p(0,0)})
        view.viewData.view:addChild(kongBg,9)

        local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
        display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(80,size.height * 0.5)})
        display.commonLabelParams(dialogue_tips,{text = __('当前页面暂无食材可选'), fontSize = 24, color = '#4c4c4c'})
        kongBg:addChild(dialogue_tips, 6)

        -- 中间小人
        local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, size.height * 0.5)
        kongBg:addChild(loadingCardQ, 6)
        loadingCardQ:setScale(0.7)
        kongBg:setVisible(false)

		--添加多个按钮功能
		local buttonGroupView = CLayout:create(size)
		display.commonUIParams(buttonGroupView, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		view.viewData.view:addChild(buttonGroupView, 30)

		local img_cartoon = display.newImageView(_res(RES_DICT.Img_cartoon), 0, 0)
	    display.commonUIParams(img_cartoon, {ap = cc.p(1,0), po = cc.p(70,510)})
	    buttonGroupView:addChild(img_cartoon,11)

		local taskCData = {
			{name = __('普通食物'), 	 	tag = 1005},
			{name = __('精致食物'), 	 	tag = 1006},
		}
        if self.goodsType == GoodsType.TYPE_MAGIC_FOOD then
            taskCData = {}
        end
		local buttons = {}
		for i,v in ipairs(taskCData) do
			local tabButton = display.newCheckBox(0,0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed),})
			local buttonSize = tabButton:getContentSize()
			display.commonUIParams(
				tabButton,
				{
					ap = cc.p(1, 0.5),
					po = cc.p(size.width + 4,
						size.height + 20 - (i) * (buttonSize.height - 30))
				})
			buttonGroupView:addChild(tabButton,-1)
			tabButton:setTag(v.tag)
			buttons[tostring( v.tag )] = tabButton


			local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 ,utils.getLocalCenter(tabButton).y,
				{ttf = true, font = TTF_GAME_FONT, text = v.name, fontSize = 22, w = 120 ,hAlign = display.TAC , color = '3c3c3c', ap = cc.p(0.5, 0.2)})--2b2017
			tabButton:addChild(tabNameLabel1)
			tabNameLabel1:setTag(3)
		end

        --滑动层背景图
		local ListBg = display.newImageView(_res(RES_DICT.LISTBG), 428, size.height - 10,--
		{scale9 = true, size = cc.size(450, 550),ap = cc.p(0, 1)})	--630, size.height - 20
		cview:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
		local taskListCellSize = cc.size(taskListSize.width/4 , 114)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		gridView:setAutoRelocate(true)
		cview:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 1.0))
		gridView:setPosition(cc.p(ListBg:getPositionX() + 4, ListBg:getPositionY() - 2))

		-- --scrollbar的功能
		-- local scrollBarBg = ccui.Scale9Sprite:create(_res('ui/home/card/rold_bg_gliding_orange'))
		-- local scrollBarBtn = cc.Sprite:create(_res('ui/home/card/rold_gliding_orange'))
		-- local scrollBar = FTScrollBar:create(scrollBarBg, scrollBarBtn)
		-- scrollBar:attachToUIScrollView(gridView)

		local Bg_describe = display.newImageView(_res(RES_DICT.Bg_describe),0,0)
		cview:addChild(Bg_describe,2)
		display.commonUIParams(Bg_describe, {ap = cc.p(0,0), po = cc.p(48, 104)})




		local reward_rank = display.newImageView(_res('ui/common/common_frame_goods_1.png'),0,1.0,{as = false})
		cview:addChild(reward_rank,1)
		reward_rank:setScale(1.1)
		display.commonUIParams(reward_rank, {ap = cc.p(0,0), po = cc.p(73, 435)})

		local reward_img = display.newImageView(('ui/home/task/task_ico_active.png'),0,0)
		reward_rank:addChild(reward_img,1)
		reward_img:setPosition(cc.p(reward_rank:getContentSize().width / 2  ,reward_rank:getContentSize().height / 2 ))
		reward_img:setVisible(false)
		local pox = reward_rank:getPositionX() + reward_rank:getContentSize().width  + 25
		local poy = reward_rank:getPositionY() + reward_rank:getContentSize().height - 8


		local fragmentPath = _res('ui/common/common_ico_fragment_1.png')
	    local fragmentImg = display.newImageView(_res(fragmentPath), reward_rank:getContentSize().width / 2  ,reward_rank:getContentSize().height / 2,{as = false})
	    reward_rank:addChild(fragmentImg,6)
	    fragmentImg:setVisible(false)
	    -- if self.goodData.type then
	    -- 	if self.goodData.type == GoodsType.TYPE_CARD_FRAGMENT then
	    -- 		self.fragmentImg:setVisible(true)
	    -- 	end
	    -- end

		local bgName = display.newImageView(('ui/backpack/bag_bg_font_name.png'),0,0)
		bgName:setAnchorPoint(cc.p(0,1))
		cview:addChild(bgName)
		bgName:setPosition(cc.p(pox - 10, poy))

		local DesNameLabel = display.newLabel(0 , 0,
			{text = ' ', fontSize = 22, color = 'be462a', ap = cc.p(0, 1)})
		cview:addChild(DesNameLabel)
		DesNameLabel:setPosition(cc.p(pox, poy))


		local DesNumLabel = display.newLabel(0, 0,
			{text = ' ', fontSize = 22, color = '#7c7c7c', ap = cc.p(0, 0.5)})
		cview:addChild(DesNumLabel)
		DesNumLabel:setPosition(cc.p(pox, poy - 80))

		local DesPriceLabel = display.newLabel(0 , 0,
			{text = ' ', fontSize = 22, color = '#7c7c7c', ap = cc.p(0, 0.5)})
		cview:addChild(DesPriceLabel)
		DesPriceLabel:setPosition(cc.p(pox  , poy - 50))



		--物品描述文字背景图
		local desBg = display.newImageView(_res(RES_DICT.DESBG), 73, 120,{scale9 = true, size = cc.size(325, 303)})
		display.commonUIParams(desBg, {ap = display.LEFT_BOTTOM})
		cview:addChild(desBg)

		local DesLabel = display.newLabel(0, 0,
			{text = '', fontSize = 22, color = '#5c5c5c', w = 275, h = 292})
		DesLabel:setPosition(cc.p(desBg:getContentSize().width * 0.5 + 5, desBg:getContentSize().height - 30))
		display.commonUIParams(DesLabel, {ap = cc.p(0.5 ,1)})
		DesLabel:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
		desBg:addChild(DesLabel)

		local getBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale), d = _res(RES_DICT.Btn_UnEanble)})
		display.commonUIParams(getBtn, {ap = cc.p(0,0), po = cc.p(180,32)})
		display.commonLabelParams(getBtn,fontWithColor(14,{text = __('确定')}))
		cview:addChild(getBtn)

		local accessBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale), d = _res(RES_DICT.Btn_UnEanble)})
		display.commonUIParams(accessBtn, {ap = cc.p(0,0), po = cc.p(100,32)})
		display.commonLabelParams(accessBtn,fontWithColor(14,{text = __('获取途径')}))
		cview:addChild(accessBtn)

		view:AddContentView(cview)

		return {
			bgView 			= cview,
			buttons 		= buttons,
			gridView 		= gridView,
			ListBg 			= ListBg,
			reward_rank		= reward_rank,
			reward_img 		= reward_img,
			DesNameLabel 	= DesNameLabel,
			DesNumLabel 	= DesNumLabel,
			DesPriceLabel 	= DesPriceLabel,
			DesLabel 		= DesLabel,
			getBtn			= getBtn,
			accessBtn		= accessBtn,
			kongBg 			= kongBg,
			img_cartoon 	= img_cartoon,

			fragmentImg 	= fragmentImg,
		}

    end

	xTry(function ( )
		self.viewData = CreateView( )
        local action = cc.Sequence:create(cc.DelayTime:create(0.1),cc.MoveBy:create(0.2,cc.p(0, - 500)))
        self.viewData.img_cartoon:runAction(action)
        local tag = 1005
        for k, v in pairs( self.viewData.buttons ) do
            local curTag = v:getTag()
            if tag == curTag then
                v:setChecked(true)
            else
                v:setChecked(false)
            end
            v:setOnClickScriptHandler(handler(self,self.ButtonActions))
		end
        self.viewData.getBtn:setOnClickScriptHandler(handler(self, self.ConfirmBtnClickHandler))
        self.viewData.accessBtn:setOnClickScriptHandler(handler(self, self.AccesstnClickHandler))
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	end, __G__TRACKBACK__)

	self:UpdateListView()
	
	AppFacade.GetInstance():RegistObserver(SIGNALNAMES.RecipeCookingMaking_Callback, mvc.Observer.new(function (_, signal)
		self:UpdateListView()
	end, self))
end

function ChooseAGoodsByGoodsTypePopup:UpdateListView()
    --过滤数据的操作
    if self.goodsType == GoodsType.TYPE_MAGIC_FOOD then
        self.goodsData = gameMgr:GetAllGoodsDataByGoodsType(tostring(self.goodsType))
        -- 剔除不需要的道具
        if self.args.except then
            local goodsId = nil
            for i = #self.goodsData, 1, -1 do
                goodsId = self.goodsData[i].goodsId
                if nil ~= self.args.except[tostring(goodsId)] then
                    table.remove(self.goodsData, i)
                end
            end
        end
    else
        local datas = gameMgr:GetAllGoodsDataByGoodsType(tostring(self.goodsType))
        self.goodsData = {}
        local cardConfig = nil
        if self.cardId then
            cardConfig = CardUtils.GetCardConfig(self.cardId)
        end
        if self.clickTag == 1005 then
            --普通的菜
            for name,val in pairs(datas) do
                if checkint(val.goodsId) >= 150000 and checkint(val.goodsId) < 151000 then
                    if cardConfig and table.nums(checktable(cardConfig.favoriteFood)) > 0 then
                        local hasV = false
                        for name,ff in pairs(cardConfig.favoriteFood) do
                            if checkint(ff) == checkint(val.goodsId) then
                                hasV = true
                            end
                        end
                        if hasV then
                            table.insert(self.goodsData, 1, val)
                        else
                            table.insert(self.goodsData,val)
                        end
                    else
                        table.insert(self.goodsData, val)
                    end
                end
			end
			if cardConfig and table.nums(checktable(cardConfig.favoriteFood)) > 0 then
				for name,ff in pairs(cardConfig.favoriteFood) do
					if checkint(ff) >= 150000 and checkint(ff) < 151000 then
						local hasV = false
						for k, v in pairs(self.goodsData) do
							if checkint(v.goodsId) == checkint(ff) then
								hasV = true
								break
							end
						end
						if not hasV then
							table.insert(self.goodsData, 1, {amount = gameMgr:GetAmountByGoodId(ff), goodsId = ff})
						end
					end
				end
			end
			if self.sticky then
				for _, stickyId in pairs(self.sticky) do
					table.insert(self.goodsData, 1, {amount = gameMgr:GetAmountByGoodId(stickyId), goodsId = stickyId})
				end
			end
        else
            --精致的菜
            for name,val in pairs(datas) do
                if checkint(val.goodsId) >= 150000 and checkint(val.goodsId) < 151000 then
                else
                    if cardConfig and table.nums(checktable(cardConfig.favoriteFood)) > 0 then
                        local hasV = false
                        for name,ff in pairs(cardConfig.favoriteFood) do
                            if checkint(ff) == checkint(val.goodsId) then
                                hasV = true
                            end
                        end
                        if hasV then
                            table.insert(self.goodsData, 1, val)
                        else
                            table.insert(self.goodsData, val)
                        end
                    else
                        table.insert(self.goodsData, val)
                    end
                end
            end
			if cardConfig and table.nums(checktable(cardConfig.favoriteFood)) > 0 then
				for name,ff in pairs(cardConfig.favoriteFood) do
					if checkint(ff) >= 151000 then
						local hasV = false
						for k, v in pairs(self.goodsData) do
							if checkint(v.goodsId) == checkint(ff) then
								hasV = true
								break
							end
						end
						if not hasV then
							table.insert(self.goodsData, 1, {amount = gameMgr:GetAmountByGoodId(ff), goodsId = ff})
						end
					end
				end
			end
			if self.sticky then
				for _, stickyId in pairs(self.sticky) do
					table.insert(self.goodsData, 1, {amount = gameMgr:GetAmountByGoodId(stickyId), goodsId = stickyId})
				end
			end
		end

    end
	local gridView = self.viewData.gridView
	self.gridContentOffset = gridView:getContentOffset()
    if self.goodsData and table.nums(self.goodsData) > 0 then
        gridView:setCountOfCell(table.nums(self.goodsData))
        self:updateDescription(self.preIndex)
        gridView:reloadData()
        self.viewData.kongBg:setVisible(false)
        self.viewData.bgView:setVisible(true)
    else
        self.goodsData = {}
        gridView:setCountOfCell(table.nums(self.goodsData))
        gridView:reloadData()
        self.viewData.bgView:setVisible(false)
        self.viewData.kongBg:setVisible(true)
    end
	if self.goodsData[self.preIndex] and  0 >= checkint(self.goodsData[self.preIndex].amount) then
		self.viewData.accessBtn:setVisible(true)
		self.viewData.accessBtn:setPositionX(100)
		self.viewData.getBtn:setPositionX(250)
	else
		self.viewData.accessBtn:setVisible(false)
		self.viewData.getBtn:setPositionX(180)
	end

end

--[[
--分类切换的逻辑
--]]
function ChooseAGoodsByGoodsTypePopup:ButtonActions(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if self.clickTag == tag then
        return
    else
        self.preIndex = 1
    end
	self.clickTag = tag
    for k, v in pairs( self.viewData.buttons ) do
        local curTag = v:getTag()
        if tag == curTag then
            v:setChecked(true)
            v:setEnabled(false)
        else
            v:setChecked(false)
            v:setEnabled(true)
        end
	end
    self:UpdateListView()
end

--[[
主页面详情描述页面
@param index int下标
--]]
function ChooseAGoodsByGoodsTypePopup:updateDescription( index )
	if self.goodsData and table.nums(self.goodsData) > 0 then
		if not self.goodsData[index] then
			self.preIndex = self.preIndex - 1
			self:updateDescription( self.preIndex )
			local pCell = self.viewData.gridView:cellAtIndex(table.nums(self.goodsData) - 1)
			if pCell then
	            pCell.selectImg:setVisible(true)
	        end
			-- gridView:setContentOffset(self.gridContentOffset)
			return
		end

        local goodsId = self.goodsData[index].goodsId
		local data = CommonUtils.GetConfig('goods', 'goods', goodsId)
		local viewData = self.viewData
		local reward_rank 	=  viewData.reward_rank
		local reward_img 	=  viewData.reward_img
		local DesNameLabel 	=  viewData.DesNameLabel
		local DesNumLabel 	=  viewData.DesNumLabel
		local DesLabel 		=  viewData.DesLabel
		local fragmentImg 	=  viewData.fragmentImg
		fragmentImg:setVisible(false)
		if data then
			--物品材料等级
			local quality = checkint(data.quality) % CARD_BREAK_MAX
			if quality <= 0 then
				quality = 1
			end
			local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(data.quality or 1))
			reward_rank:setTexture(_res(bgPath))
			reward_rank:setTexture(_res(bgPath))

			local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(data.quality or 1))
			fragmentImg:setTexture(_res(fragmentPath))

			if data.type then
				if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
					fragmentImg:setVisible(true)
				end
			end
			--物品图片
			reward_img:setVisible(true)
            local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)

			reward_img:setTexture(_res(iconPath))
			reward_img:setScale(0.55)
	        --物品名称
			display.commonLabelParams(DesNameLabel , {text = data.name , w = 200 , hAlign = display.TAL })

			--物品类型
	        local temp_type_src = ''
	        local ttype = CommonUtils.GetGoodTypeById(goodsId)
	        temp_type_src = CommonUtils.GetConfig('goods', 'type', ttype).type

			--物品数量
			DesNumLabel:setString(string.fmt(__('数量: _name_'), {_name_ = self.goodsData[index].amount}))
			DesLabel:setString(data.descr)

			self.viewData.getBtn:setEnabled(0 < self.goodsData[index].amount)
		else
			DesLabel:setString(__('物品不存在。'))
		end
	end
end
--背包列表数据源
function ChooseAGoodsByGoodsTypePopup:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local bg = self.viewData.gridView
    local sizee = cc.size(108, 115)

    if self.goodsData and index <= table.nums(self.goodsData) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.goodsData[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))

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
            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        end
		xTry(function()

            pCell.newIcon:setVisible(false)
			local quality = 1
			if data then
				if data.quality then
					quality = data.quality
				end
			end

			local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
			local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			if not utils.isExistent(drawBgPath) then
				drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
				fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			end
			pCell.fragmentImg:setTexture(fragmentPath)
			pCell.toggleView:setNormalImage(drawBgPath)
			pCell.toggleView:setSelectedImage(drawBgPath)
			pCell.toggleView:setTag(index)
			pCell.toggleView:setScale(0.92)
			pCell:setTag(index)

			if data then
				if self.showStarCondition[tostring(data.id)] then
					pCell.feedStar:setVisible(true)
				else
					pCell.feedStar:setVisible(false)
				end
				if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
					pCell.fragmentImg:setVisible(true)
				else
					pCell.fragmentImg:setVisible(false)
				end
			else
				pCell.fragmentImg:setVisible(false)
			end
			if index == self.preIndex then
				pCell.selectImg:setVisible(true)
			else
				pCell.selectImg:setVisible(false)
			end
			pCell.numLabel:setString(tostring(self.goodsData[index].amount))

			local node = pCell.toggleView:getChildByTag(111)
			if node then node:removeFromParent() end
			local goodsId = self.goodsData[index].goodsId
			local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
			local sprite = FilteredSpriteWithOne:create()
			sprite:setTexture(_res(iconPath))
			sprite:setPosition(cc.p( 0,0))
			sprite:setScale(0.55)
			local lsize = pCell.toggleView:getContentSize()
			sprite:setPosition(cc.p(lsize.width * 0.5,lsize.height *0.5))
			sprite:setTag(111)
			pCell.toggleView:addChild(sprite)
			if 0 == self.goodsData[index].amount then
				local grayFilter = GrayFilter:create()
				sprite:setFilter(grayFilter)

				-- drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
				-- pCell.toggleView:setNormalImage(drawBgPath)
				-- pCell.toggleView:setSelectedImage(drawBgPath)
			end
		end,__G__TRACKBACK__)
        return pCell
    end
end
--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function ChooseAGoodsByGoodsTypePopup:CellButtonAction( sender )
    PlayAudioByClickNormal()
	local gridView = self.viewData.gridView
    local index = sender:getTag()
    local cell = gridView:cellAtIndex(index- 1)
    if cell then
        cell.selectImg:setVisible(true)
        cell.newIcon:setVisible(false)
    end

    if index == self.preIndex then return end
    --更新按钮状态
    local cell = gridView:cellAtIndex(self.preIndex - 1)
    if cell then
        cell.selectImg:setVisible(false)
    end
    self.preIndex = index
    -- self.gridContentOffset = gridView:getContentOffset()
    -- dump(self.gridContentOffset)
	self:updateDescription(self.preIndex)

	if 0 >= self.goodsData[self.preIndex].amount then
		self.viewData.accessBtn:setVisible(true)
		self.viewData.accessBtn:setPositionX(100)
		self.viewData.getBtn:setPositionX(250)
	else
		self.viewData.accessBtn:setVisible(false)
		self.viewData.getBtn:setPositionX(180)
	end
end

--[[
确定选择道具点击回调
--]]
function ChooseAGoodsByGoodsTypePopup:ConfirmBtnClickHandler(sender)
    PlayAudioByClickNormal()
	if self.showWaring then
		-- 显示警告
		local commonTip = require('common.NewCommonTip').new({
			text = self.waringText,
			callback = function ()
				self:OnChooseOverCallback()
			end
		})
		commonTip:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(commonTip)
	else
		self:OnChooseOverCallback()
	end
end
--[[
获取途径按钮点击回调
--]]
function ChooseAGoodsByGoodsTypePopup:AccesstnClickHandler(sender)
    PlayAudioByClickNormal()
	app.uiMgr:AddDialog("common.GainPopup", {goodId = self.goodsData[self.preIndex].goodsId})
end
--[[
最后一步 回调上一层
--]]
function ChooseAGoodsByGoodsTypePopup:OnChooseOverCallback()
	local goodsData = self.goodsData[self.preIndex]
	local data = {
		goodsId = checkint(goodsData.goodsId)
	}

	if nil ~= self.parameter then
		table.merge(data, self.parameter)
	end

	AppFacade.GetInstance():DispatchObservers(self.callbackSignalName, data)
    uiMgr:GetCurrentScene():RemoveDialog(self)
end

function ChooseAGoodsByGoodsTypePopup:onCleanup()
	AppFacade.GetInstance():UnRegistObserver(SIGNALNAMES.RecipeCookingMaking_Callback, self)
end

return ChooseAGoodsByGoodsTypePopup
