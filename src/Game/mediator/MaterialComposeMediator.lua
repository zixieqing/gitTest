--[[
材料合成
]]
local Mediator = mvc.Mediator

local MaterialComposeMediator = class("MaterialComposeMediator", Mediator)

local NAME = "MaterialComposeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local materialCell = require('home.StoryMissionsCell')

function MaterialComposeMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.composeMaterialData = {} --本地材料合成数据
	self.insertNode = nil 		--显示具体合成材料
	self.selectImg = nil 		--选中框
	self.openImg = nil 			--加号减号图片显示
	self.selectData = {} 		--选中材料数据
	self.selectNum = 1 			--选择合成数量
	self.selectModel = nil 		--选择类别
	self.hasNumLabel = nil  	--所需材料拥有数量label
	self.castNumLabel = nil 	--所需材料消耗数量label
end

function MaterialComposeMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Material_Compose_Callback,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}

	return signals
end

function MaterialComposeMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	print(name)
	if name == SIGNALNAMES.Material_Compose_Callback then--合成
		--更新UI

		-- 强化动画
		uiMgr:GetCurrentScene():AddViewForNoTouch()
		local viewData 				= self.viewComponent.viewData
		local needMaterialNode 		= viewData.needMaterialNode

		local breakUpgradeSpine = sp.SkeletonAnimation:create(
			'effects/materialCompose/hecheng.json',
			'effects/materialCompose/hecheng.atlas',
			1
		)
		breakUpgradeSpine:setRotation(-90)
		breakUpgradeSpine:setPosition(cc.p(
			needMaterialNode:getPositionX(),
			needMaterialNode:getPositionY() + needMaterialNode:getContentSize().height * 0.2 - 250
		))
		needMaterialNode:getParent():addChild(
			breakUpgradeSpine,100
		)

		breakUpgradeSpine:setToSetupPose()
		breakUpgradeSpine:setAnimation(0, 'play1', false)

		breakUpgradeSpine:registerSpineEventHandler(function (event)
			uiMgr:GetCurrentScene():RemoveViewForNoTouch()
			uiMgr:AddDialog('common.RewardPopup', {rewards = { {goodsId = self.selectData.targetMaterial , num  = self.selectNum*self.selectData.targetMaterialNum } }})
			self:updateComposeUI()
			self:GetFacade():DispatchObservers(SIGNALNAMES.MaterialCompose_Callback)
			breakUpgradeSpine:runAction(cc.RemoveSelf:create())

		end, sp.EventType.ANIMATION_END)


		local Trewards = {}

		local  amount = body.baseMaterialNum - gameMgr:GetAmountByGoodId(self.selectData.compoundMaterial)
		table.insert(Trewards,{goodsId = self.selectData.compoundMaterial , num  = amount })

		local goldNum = body.gold - gameMgr:GetUserInfo().gold
		table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})

		local diamondNum = body.diamond - gameMgr:GetUserInfo().diamond
		table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})

		CommonUtils.DrawRewards(Trewards)
		local reward = clone(Trewards)
		table.insert(reward, {goodsId = self.selectData.targetMaterial , num  = self.selectNum*self.selectData.targetMaterialNum })
		AppFacade.GetInstance():DispatchObservers(EVENT_GOODS_COUNT_UPDATE, reward)

	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then--刷新顶部货币
        --更新界面显示
        self:UpdateCountUI()
        return
	end
end

--更新数量ui值
function MaterialComposeMediator:UpdateCountUI()
	local viewData = self.viewComponent.viewData
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个金币数量
		end
	end
end


function MaterialComposeMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.MaterialComposeView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	-- scene:AddGameLayer(viewComponent)
	scene:AddDialog(viewComponent)

	--绑定相关的事件
	local viewData = viewComponent.viewData
	viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.btn_num:setOnClickScriptHandler(handler(self,self.SetNumBtnCallback))
	viewData.composeBtn:setOnClickScriptHandler(handler(self,self.ComposeButtonback))

	local datas = CommonUtils.GetConfigAllMess('material', 'compound')
	for k,v in pairs(datas) do
		if not self.composeMaterialData[tostring(v.materialType)] then
			self.composeMaterialData[tostring(v.materialType)] = {}
		end
		local tempData = clone(v)
		if CommonUtils.GetConfig('goods','goods',v.targetMaterial) then
			tempData.quality = checkint(CommonUtils.GetConfig('goods','goods',v.targetMaterial).quality) or 1
		end
		table.insert(self.composeMaterialData[tostring(v.materialType)],tempData)
	end


	for k,v in pairs(self.composeMaterialData) do
		sortByMember(v, "quality", true)
	end

	self:updataview()
	self:UpdateCountUI()
end

--刷新页面
function MaterialComposeMediator:updataview( )
	local viewData = self.viewComponent.viewData
	local listView = viewData.listView
	listView:removeAllNodes()
	listView:setVisible(true)
	local cellSize = cc.size(listView:getContentSize().width, 90)
	if next(self.composeMaterialData) ~= nil then
		local index = 1
		for k,v in orderedPairs(self.composeMaterialData) do
			local data = CommonUtils.GetConfigAllMess('materialType', 'compound')[k]
			local cell = CLayout:create(cellSize)
			local materialCell = materialCell.new()
			materialCell:setTag(8888)
			cell:addChild(materialCell)
			materialCell.redPointImg:setVisible(false)
			materialCell.toggleView:setTag(k)
			materialCell.toggleView:setUserTag(index)
	        materialCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
	    	materialCell.eventnode:setPosition(cc.p(cellSize.width* 0.5 ,cellSize.height * 0.5))
	    	listView:insertNodeAtLast(cell)
	    	if data then
	    		materialCell.npcImg:setTexture(CommonUtils.GetGoodsIconPathById(data.photoId))
	    		materialCell.npcImg:setVisible(true)
	    		materialCell.npcImg:setScale(0.45)
		    	materialCell.labelName:setString(data.name)
		    	materialCell.labelName:setPositionX(94)
		    	display.commonLabelParams(materialCell.labelName, {fontSize = 28,color = '5b3c25'})
		    	materialCell.npcImg:setPositionX(45)
		    	materialCell.npcImg:setAnchorPoint(cc.p(0.5,0.5))
		    end

		    local iconBg = display.newImageView(_res('ui/backpack/materialCompose/bag_compose_bg_quan.png'),  materialCell.npcImg:getPositionX() , materialCell.npcImg:getPositionY(),
		    {ap = cc.p(0.5, 0.5)})
		    materialCell.eventnode:addChild(iconBg)

		    local openImg = display.newImageView(_res('ui/backpack/materialCompose/item_compose_bg_open.png'),  380 , materialCell.npcImg:getPositionY(),
		    {ap = cc.p(0.5, 0.5)})
		    materialCell.eventnode:addChild(openImg)
		    materialCell.openImg = openImg

	    	index = index + 1
		end
		listView:reloadData()
	else

	end
end

--合成按钮回调
function MaterialComposeMediator:ComposeButtonback(sender)
	if next(self.selectData) == nil then
		return
	end
	if checkint(self.viewComponent.viewData.castNum:getString()) > gameMgr:GetUserInfo().gold then
		uiMgr:ShowInformationTips(__('金币不足'))
		return
	end


	local data = self.selectData
	local hasNum = gameMgr:GetAmountByGoodId(data.compoundMaterial)
	local castNum = data.compoundNum*self.selectNum
	if checkint(castNum) > checkint(hasNum) then
        local temp_str = string.fmt(__('所需合成材料不足，是否消耗_num_幻晶石继续合成'),{_num_ = ((castNum-hasNum) * data.diamondPrice)})
        local CommonTip  = require( 'common.CommonTip' ).new({text = temp_str,isOnlyOK = false, callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_Material_Compose,{isDiamondCompound = 1,materialCompoundId = self.selectData.id,num = self.selectNum})
        end})
        CommonTip:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(CommonTip)
	else
		self:SendSignal(COMMANDS.COMMANDS_Material_Compose,{isDiamondCompound = 0,materialCompoundId = self.selectData.id,num = self.selectNum})
	end
end


--加减选择数量按钮回调
function MaterialComposeMediator:ChooseNumBtnCallback( sender )
	local tag = sender:getTag()
	if next(self.selectData) == nil then
		return
	end

	local viewData = self.viewComponent.viewData
	local btn_num = viewData.btn_num
	if tag == 1 then--减
		if self.selectNum <= 0 then
			return
		end
		if checkint(self.selectNum) > 1 then
			self.selectNum = self.selectNum - 1
		end
	elseif tag == 2 then--加
		if self.selectNum >= 999 then
			uiMgr:ShowInformationTips(__('已达最大合成上限'))
			return
		end
		self.selectNum = self.selectNum + 1
	end

	btn_num:getLabel():setString(tostring(self.selectNum))
	local data = self.selectData
	-- viewData.targetMaterialNode.numLabel:setString(btn_num:getLabel():getString())
	viewData.targetMaterialNode.numLabel:setString(tostring(self.selectNum*data.targetMaterialNum))

	viewData.castNum:setString(tostring(data.compoundPrice*self.selectNum or '0'))
	-- viewData.needMaterialNode.numLabel:setString(gameMgr:GetAmountByGoodId(data.compoundMaterial)..'/'..tostring(data.compoundNum*self.selectNum))

	if self.hasNumLabel then
		self.hasNumLabel:removeFromParent()
		self.hasNumLabel = nil
	end
	local fontName = 'common_text_num'
	if checkint(gameMgr:GetAmountByGoodId(data.compoundMaterial)) < checkint(data.compoundNum*self.selectNum) then
		fontName = 'common_num_unused'
	end

	if not self.hasNumLabel then
	    self.hasNumLabel = cc.Label:createWithBMFont('font/small/'..fontName..'.fnt', '')--
	    self.hasNumLabel:setAnchorPoint(cc.p(1, 1))
	    self.hasNumLabel:setScale(1.2)
	    self.hasNumLabel:setHorizontalAlignment(display.TAR)
	    self.hasNumLabel:setPosition(98  ,viewData.needMaterialNode.toggleView:getPositionY() - 20)
	    viewData.needMaterialNode.eventnode:addChild(self.hasNumLabel,1)
	end
	self.hasNumLabel:setString(gameMgr:GetAmountByGoodId(data.compoundMaterial))
	self.castNumLabel:setString('/'..tostring(data.compoundNum*self.selectNum))
	self.hasNumLabel:setPositionX(98 - self.castNumLabel:getContentSize().width*self.castNumLabel:getScaleX() )
end

--数字键盘输入完之后的回调
function MaterialComposeMediator:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = '1'
		end
		if checkint(data) <= 0 then
			data = 1
		end

		self.selectNum = checkint(data)
		local viewData = self.viewComponent.viewData
		local btn_num = viewData.btn_num
		btn_num:getLabel():setString(tostring(self.selectNum))
		local data = self.selectData
		-- viewData.targetMaterialNode.numLabel:setString(btn_num:getLabel():getString())
		viewData.targetMaterialNode.numLabel:setString(tostring(self.selectNum*data.targetMaterialNum))
		local data = self.selectData
		viewData.castNum:setString(tostring(data.compoundPrice*self.selectNum or '0'))
		-- viewData.needMaterialNode.numLabel:setString(gameMgr:GetAmountByGoodId(data.compoundMaterial)..'/'..tostring(data.compoundNum*self.selectNum))

		if self.hasNumLabel then
			self.hasNumLabel:removeFromParent()
			self.hasNumLabel = nil
		end
		local fontName = 'common_text_num'
		if checkint(gameMgr:GetAmountByGoodId(data.compoundMaterial)) < checkint(data.compoundNum*self.selectNum) then
			fontName = 'common_num_unused'
		end

		if not self.hasNumLabel then
		    self.hasNumLabel = cc.Label:createWithBMFont('font/small/'..fontName..'.fnt', '')--
		    self.hasNumLabel:setAnchorPoint(cc.p(1, 1))
		    self.hasNumLabel:setScale(1.2)
		    self.hasNumLabel:setHorizontalAlignment(display.TAR)
		    self.hasNumLabel:setPosition(98  ,viewData.needMaterialNode.toggleView:getPositionY() - 20)
		    viewData.needMaterialNode.eventnode:addChild(self.hasNumLabel,1)
		end
		self.hasNumLabel:setString(gameMgr:GetAmountByGoodId(data.compoundMaterial))
		self.castNumLabel:setString('/'..tostring(data.compoundNum*self.selectNum))
		self.hasNumLabel:setPositionX(98 - self.castNumLabel:getContentSize().width*self.castNumLabel:getScaleX() )

	end
end

--打开模拟数字键盘
function MaterialComposeMediator:SetNumBtnCallback( sender )
	if next(self.selectData) == nil then
		return
	end
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入需要合成材料的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	self:GetFacade():RegistMediator(mediator)
end
--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function MaterialComposeMediator:CellButtonAction( sender )
    local tag = sender:getTag()
    local index = sender:getUserTag()
	local viewData = self.viewComponent.viewData
	local listView = viewData.listView
    if self.selectModel then
	    if checkint(self.selectModel) == checkint(tag) then
    		if self.insertNode then
				listView:removeNode(self.insertNode)
				-- self.selectData = {}
				self.selectImg = nil
				self.insertNode = nil
			end
			listView:reloadData()
			if self.openImg then
				self.openImg:setTexture(_res('ui/backpack/materialCompose/item_compose_bg_open.png'))
				self.openImg = nil
			end
			self.selectModel = nil
			-- self:updateComposeUI( true )
	    	return
	    end
	end
	self.selectModel = tag

	if self.insertNode then
		listView:removeNode(self.insertNode)
		-- self.selectData = {}
		self.selectImg = nil
	end

	local num = table.nums(self.composeMaterialData[tostring(tag)])

	local cellSize = cc.size(listView:getContentSize().width, 72)

	local size = cc.size(392,72)
	local cell = CLayout:create(cc.size(cellSize.width,72*num))
	local tempIndex = 1
	for k,v in pairs(self.composeMaterialData[tostring(tag)]) do
		local tempLayout = CLayout:create(size)
		tempLayout:setAnchorPoint(cc.p(1,0))
		tempLayout:setPosition(cc.p(cellSize.width - 10,cell:getContentSize().height - tempIndex*72))


	    local bgImg = display.newButton(size.width * 0.5,size.height * 0.5,{--
	        n = _res('ui/backpack/materialCompose/item_compose_bg_list.png')
	    })
	    tempLayout:addChild(bgImg)
	    bgImg:setTag(v.id)
	    bgImg:setOnClickScriptHandler(handler(self,self.MaterialBtnCallback))

        local selectImg = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'),0,0,{as = false,scale9 = true,size = cc.size(400,80)})
		selectImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
		-- selectImg:setScale(0.92)
		bgImg:addChild(selectImg)
		selectImg:setTag(9999)
		selectImg:setVisible(false)

	    -- local d = CommonUtils.GetConfig('goods','goods',v.targetMaterial) or {name = '道具表没找到'..v.targetMaterial}
	    local labelName = display.newLabel(78, size.height * 0.5,fontWithColor(4,{ text = v.name  }))
	    display.commonUIParams(labelName, {ap = cc.p(0, 0.5)})
	    tempLayout:addChild(labelName,5)


	    local goodNode = require('common.GoodNode').new({id = v.targetMaterial, showAmount = false })
	    goodNode:setPosition(cc.p(41,size.height * 0.5))
	    goodNode:setScale(0.5)
	    tempLayout:addChild(goodNode)


		cell:addChild(tempLayout)
		tempIndex = tempIndex + 1
	end
    listView:insertNode(cell,index)

    self.insertNode = cell
    listView:reloadData()

	if self.openImg then
		self.openImg:setTexture(_res('ui/backpack/materialCompose/item_compose_bg_open.png'))
	end


	local cell = listView:getNodeAtIndex(index - 1)
	if cell then
		if cell:getChildByTag(8888) then
			cell:getChildByTag(8888).openImg:setTexture(_res('ui/backpack/materialCompose/item_compose_bg_close.png'))
			self.openImg = cell:getChildByTag(8888).openImg
		end
	end
end
--[[
展开合成材料btn
@param sender button对象
--]]
function MaterialComposeMediator:MaterialBtnCallback( sender )
	local tag = sender:getTag()
	local data = CommonUtils.GetConfigAllMess('material', 'compound')[tostring(tag)]
	if data then

		if self.selectData then
			if checkint(self.selectData.id) == checkint(data.id)then
				return
			end
		end
		self.selectData = clone(data)
		-- dump(self.selectData)
		if self.selectImg then
			self.selectImg:setVisible(false)
		end
		if sender:getChildByTag(9999)  then
			sender:getChildByTag(9999):setVisible(true)
			self.selectImg =  sender:getChildByTag(9999)
		end

		self:updateComposeUI()

	end

end


--[[
合成材料信息操作界面
--]]
function MaterialComposeMediator:updateComposeUI( isInit )
	local viewData 				= self.viewComponent.viewData
	local nameLabel 			= viewData.nameLabel
	local needMaterialNode 		= viewData.needMaterialNode
	local targetMaterialNode	= viewData.targetMaterialNode
	local btn_num				= viewData.btn_num
	local btn_minus				= viewData.btn_minus
	local btn_add				= viewData.btn_add
	local castNum				= viewData.castNum
	local targetNum				= viewData.targetNum

	self.selectNum = 1
	if isInit then
		castNum:setString('0')
		targetNum:setString(' ')
		nameLabel:getLabel():setString(__('名字'))
		btn_num:getLabel():setString('0')
		local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')

		targetMaterialNode.toggleView:setNormalImage(drawBgPath)
		targetMaterialNode.toggleView:setSelectedImage(drawBgPath)
		targetMaterialNode.goodsImg:setVisible(false)
		targetMaterialNode.numLabel:setString(' ')

		needMaterialNode.toggleView:setNormalImage(drawBgPath)
		needMaterialNode.toggleView:setSelectedImage(drawBgPath)
		needMaterialNode.goodsImg:setVisible(false)


		if self.hasNumLabel then
			self.hasNumLabel:setString(' ')
		end
		if self.castNumLabel then
			self.castNumLabel:setString(' ')
		end

		needMaterialNode.toggleView:setTouchEnabled(false)
		targetMaterialNode.toggleView:setTouchEnabled(false)
		return
	end


	btn_num:getLabel():setString(tostring(self.selectNum))

	local data = self.selectData
	castNum:setString(tostring(data.compoundPrice*self.selectNum or '0'))
	local d = CommonUtils.GetConfig('goods','goods',data.targetMaterial) or {name = '道具表没找到'..data.targetMaterial}
	nameLabel:getLabel():setString(data.name)
    local lwidth = display.getLabelContentSize(nameLabel:getLabel()).width
    if lwidth > 186 then
        nameLabel:setContentSize(cc.size(lwidth + 50, 32))
    end

	local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(d.quality)..'.png')
	if not utils.isExistent(drawBgPath) then
		drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
	end
	targetMaterialNode.toggleView:setNormalImage(drawBgPath)
	targetMaterialNode.toggleView:setSelectedImage(drawBgPath)
	targetMaterialNode.goodsImg:setTexture(CommonUtils.GetGoodsIconPathById(data.targetMaterial))
	targetMaterialNode.goodsImg:setVisible(true)
	--btn_num:getLabel():getString()
	targetMaterialNode.numLabel:setString(tostring(self.selectNum*data.targetMaterialNum))--
	targetNum:setString( string.fmt(__('拥有：_num_'),{_num_ = gameMgr:GetAmountByGoodId(data.targetMaterial)}) )

	local dd = CommonUtils.GetConfig('goods','goods',data.compoundMaterial) or {quality = '道具表没找到'..data.compoundMaterial}
	local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(dd.quality)..'.png')
	if not utils.isExistent(drawBgPath) then
		drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
	end
	needMaterialNode.toggleView:setNormalImage(drawBgPath)
	needMaterialNode.toggleView:setSelectedImage(drawBgPath)

	needMaterialNode.goodsImg:setTexture(CommonUtils.GetGoodsIconPathById(data.compoundMaterial))
	needMaterialNode.goodsImg:setVisible(true)


	if  self.hasNumLabel then
		self.hasNumLabel:removeFromParent()
		self.hasNumLabel = nil
	end

	local fontName = 'common_text_num'
	if checkint(gameMgr:GetAmountByGoodId(data.compoundMaterial)) < checkint(data.compoundNum*self.selectNum) then
		fontName = 'common_num_unused'
	end

	if not self.castNumLabel then
	    self.castNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--common_text_num
	    self.castNumLabel:setAnchorPoint(cc.p(1, 1))
	    self.castNumLabel:setHorizontalAlignment(display.TAR)
	    self.castNumLabel:setScale(1.2)
	    self.castNumLabel:setPosition(98  ,viewData.needMaterialNode.toggleView:getPositionY() - 20)
	    viewData.needMaterialNode.eventnode:addChild(self.castNumLabel,1)
	end

	if not self.hasNumLabel then
	    self.hasNumLabel = cc.Label:createWithBMFont('font/small/'..fontName..'.fnt', '')--
	    self.hasNumLabel:setAnchorPoint(cc.p(1, 1))
	    self.hasNumLabel:setHorizontalAlignment(display.TAR)
	    self.hasNumLabel:setScale(1.2)
	    self.hasNumLabel:setPosition(98 ,viewData.needMaterialNode.toggleView:getPositionY() - 20)
	    viewData.needMaterialNode.eventnode:addChild(self.hasNumLabel,1)
	end

	self.hasNumLabel:setString(gameMgr:GetAmountByGoodId(data.compoundMaterial))
	self.castNumLabel:setString('/'..tostring(data.compoundNum*self.selectNum))
	self.hasNumLabel:setPositionX(98 - self.castNumLabel:getContentSize().width*self.castNumLabel:getScaleX() )


	needMaterialNode.toggleView:setTouchEnabled(true)
	targetMaterialNode.toggleView:setTouchEnabled(true)
	targetMaterialNode.toggleView:setOnClickScriptHandler(function()
		uiMgr:AddDialog('common.GainPopup', {goodId = data.targetMaterial,isFrom = 'MaterialComposeMediator'})
	end)

	needMaterialNode.toggleView:setOnClickScriptHandler(function()
		uiMgr:AddDialog('common.GainPopup', {goodId = data.compoundMaterial,isFrom = 'MaterialComposeMediator'})
	end)

end

function MaterialComposeMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	local MaterialComposeCommand = require( 'Game.command.MaterialComposeCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Material_Compose, MaterialComposeCommand)

end
function MaterialComposeMediator:OnUnRegist(  )
	--称出命令
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Material_Compose)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_BackPack_Sale)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_BackPack_Use)
end

return MaterialComposeMediator
