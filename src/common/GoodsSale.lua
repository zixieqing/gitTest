--[[
物品出售UI
--]]
local GameScene = require( "Frame.GameScene" )

local GoodsSale = class('GoodsSale', GameScene)

local RES_DICT = {
	GOOD_RANK		= 'ui/common/common_frame_goods_1.png',
	BTN_ADD			= 'ui/common/common_btn_add.png',
	BTN_MINUS 		= 'ui/common/common_btn_minus.png',
	BTN_MAX			= 'ui/common/common_btn_orange.png',
	BG_MONEY 		= 'ui/common/bags_frame_bg_money.png',
	BG_NUM 			= 'ui/common/bag_bg_number.png',
	BTN_SALE 		= "ui/common/common_btn_orange.png",
}
local BTN_TAG = {
	MINUS = 1,
	ADD   = 2,
	MAX   = 3,
	SALE  = 4,
	OTHER = 999,
}



function GoodsSale:ctor( ... )
	local arg = unpack({...})
    self.datas = arg
    -- dump(arg)
    if arg.callback then self.callback = arg.callback end
    self.chooseNum = 1

 	local function CloseSelf(sender)
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
  	end
	--创建页面
    local cview = require("common.TitlePanelBg").new({ title = '', type = 3, cb = function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end})
	cview.viewData.closeBtn:setOnClickScriptHandler(CloseSelf)
	display.commonUIParams(cview, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(cview)
	self.cview = cview

	local function CreateTaskView( ... )
		local view = CLayout:create()
	    local frameSize = cc.size(558,639)
	    view:setContentSize(cc.size(frameSize.width,frameSize.height))

	    local pox = frameSize.width * 0.5
		--物品等级
		local reward_rank = display.newImageView(_res(RES_DICT.GOOD_RANK),0,0,{as = false})
		view:addChild(reward_rank,1)
		reward_rank:setPosition(cc.p(pox, frameSize.height * 0.75))
		reward_rank:setScale(1.5)
		--物品图片
		local reward_img = display.newImageView(('ui/home/task/task_ico_active.png'),0,0,{as = false})
		-- reward_img:setScale(1.5)
		reward_rank:addChild(reward_img,1)
		reward_img:setPosition(cc.p(reward_rank:getContentSize().width / 2 ,reward_rank:getContentSize().height / 2))


		local fragmentPath = _res('ui/common/common_ico_fragment_1.png')
	    local fragmentImg = display.newImageView(_res(fragmentPath), pox, frameSize.height * 0.75,{as = false})
	    view:addChild(fragmentImg,6)
	    fragmentImg:setScale(1.5)
	    fragmentImg:setVisible(false)

		
		local poy = reward_rank:getPositionY() - (reward_rank:getContentSize().height*reward_rank:getScale()) / 2 - 30 
		--拥有数量
		local hasNumLabel = display.newLabel(0 , 0,
			{text = ' ', fontSize = 22, color = '#7c7c7c', ap = cc.p(0.5, 0.5)})
		view:addChild(hasNumLabel)
		hasNumLabel:setPosition(cc.p(pox, poy))


		local tempLabel = display.newLabel(0 , 0,
			{text = __('选择出售数量:'), fontSize = 20, color = '#7c7c7c', ap = cc.p(0.5, 0.5)})
		view:addChild(tempLabel)
		tempLabel:setPosition(cc.p(pox*0.62, frameSize.height * 0.48))
		--减号btn
		local btn_minus = display.newButton(0, 0, {n = _res(RES_DICT.BTN_MINUS)})
		display.commonUIParams(btn_minus, {po = cc.p(tempLabel:getPositionX() - 80, tempLabel:getPositionY() - 60),ap = cc.p(0,0.5)})
		view:addChild(btn_minus)
		local label_minus = btn_minus:getLabel()
		--选择数量
		local btn_num = display.newButton(0, 0, {n = _res(RES_DICT.BG_NUM),enable = false})
		display.commonUIParams(btn_num, {po = cc.p(btn_minus:getPositionX() + btn_minus:getContentSize().width  + 15, tempLabel:getPositionY() - 60),ap = cc.p(0,0.5)})
		display.commonLabelParams(btn_num, {text = '1', fontSize = 28, color = '#7c7c7c'})
		view:addChild(btn_num)
		local label_num = btn_num:getLabel()
		--加号btn
	    local btn_add = display.newButton(0, 0, {n = _res(RES_DICT.BTN_ADD)})
		display.commonUIParams(btn_add, {po = cc.p(btn_num:getPositionX() + btn_num:getContentSize().width  + 15, tempLabel:getPositionY() - 60),ap = cc.p(0,0.5)})
		view:addChild(btn_add)
		local label_add = btn_add:getLabel()
		--最大btn
	    local btn_max = display.newButton(0, 0, {n = _res(RES_DICT.BTN_MAX)})
		display.commonUIParams(btn_max, {po = cc.p(btn_add:getPositionX() + btn_add:getContentSize().width  + 15, tempLabel:getPositionY() - 60),ap = cc.p(0,0.5)})
		display.commonLabelParams(btn_max, fontWithColor(14,{text = __('最大')}))
		view:addChild(btn_max)

		local bg_money = display.newImageView(_res(RES_DICT.BG_MONEY),0,0,{as = false})
		view:addChild(bg_money)
		bg_money:setPosition(cc.p(tempLabel:getPositionX() + 120 ,tempLabel:getPositionY() - 135))

		local bsize = bg_money:getContentSize()

		local tempLabel_1 = display.newLabel(0 , 0,
			{text = __('获得金钱:'), fontSize = 20, color = '#7c7c7c', ap = cc.p(1, 0.5)})
		bg_money:addChild(tempLabel_1)
		tempLabel_1:setPosition(cc.p(bsize.width/2 , bsize.height/2))
		--可获得金钱数量
		local getMoneyLabel = display.newLabel(0 , 0,
			{text = ' ', fontSize = 24, color = '#7c7c7c', ap = cc.p(0, 0.5)})
		bg_money:addChild(getMoneyLabel)
		getMoneyLabel:setPosition(cc.p(tempLabel_1:getPositionX() , bsize.height/2))
		--可获得金钱类型
		local img_money_type = display.newImageView(_res(string.format( "arts/goods/goods_icon_%d.png", GOLD_ID )),0,0,{ap = cc.p(0, 0.5)})
		bg_money:addChild(img_money_type)
		img_money_type:setScale(0.2)
		img_money_type:setPosition(cc.p(getMoneyLabel:getPositionX() + getMoneyLabel:getBoundingBox().width + 5 , bsize.height/2))

		--出售btn
		local btn_sure = display.newButton(0, 0, {n = _res(RES_DICT.BTN_SALE)})
		display.commonUIParams(btn_sure, {po = cc.p(pox,bg_money:getPositionY() - bg_money:getContentSize().height - 50)})
		display.commonLabelParams(btn_sure,fontWithColor(14,{text = __('确认出售')}))
		view:addChild(btn_sure)

		cview:AddContentView(view)
		return {
			view 			= view,
			reward_rank 	= reward_rank,		--物品等级
			reward_img 		= reward_img,		--物品图片
			fragmentImg		= fragmentImg,
			-- good_name_label = bg,	--标题  物品名称
			hasNumLabel	    = hasNumLabel,		--拥有数量
			btn_minus 		= btn_minus,		--减号btn
			label_num		= label_num,		--选择数量
			btn_add 		= btn_add,			--加号btn
			btn_max 		= btn_max,			--最大btn
			getMoneyLabel 	= getMoneyLabel,	--可获得金钱数量
			img_money_type 	= img_money_type,	--可获得金钱类型
			btn_sure 		= btn_sure,			--出售btn
		}
	end

	self.viewData_ = CreateTaskView()

	-- local commonBg = require('common.CloseBagNode').new(
	-- 		{callback = function ()
	-- 			self:runAction(cc.RemoveSelf:create())
	-- 		end})
	-- commonBg:setPosition(utils.getLocalCenter(self))
	-- self:addChild(commonBg)
	-- commonBg:addContentView(self.viewData_.view)

-- self:addChild(self.viewData_.btn_add,1)
	self.viewData_.btn_minus:setTag(BTN_TAG.MINUS)
	self.viewData_.btn_add:setTag(BTN_TAG.ADD)
	self.viewData_.btn_max:setTag(BTN_TAG.MAX)
	self.viewData_.btn_sure:setTag(BTN_TAG.SALE)
	self.viewData_.btn_minus:setOnClickScriptHandler(handler(self,self.ButtonActions))
	self.viewData_.btn_add:setOnClickScriptHandler(handler(self,self.ButtonActions))
	self.viewData_.btn_max:setOnClickScriptHandler(handler(self,self.ButtonActions))
	self.viewData_.btn_sure:setOnClickScriptHandler(handler(self,self.ButtonActions))

end


function GoodsSale:onTouchBegan(touch,event)
	
	local point = touch:getLocation()
    local btnAddRect = self.viewData_.btn_add:getBoundingBox()
    local btnMinusRect  = self.viewData_.btn_minus:getBoundingBox()

    local isAddTouch = false
    local isMinusTouch = false

    if cc.rectContainsPoint(btnAddRect,point) then

    	isAddTouch = true
    end

    if cc.rectContainsPoint(btnMinusRect,point) then

    	isMinusTouch = true
    end
    print('************'..point.x)
    print('************'..self.viewData_.btn_add:getPositionX())

print(cc.rectContainsPoint(btnAddRect,point))
print(cc.rectContainsPoint(btnMinusRect,point))
	return true
end
function GoodsSale:onTouchMoved(touch,event)

end
function GoodsSale:onTouchEnded(touch,event)

end
--[[
主页面按钮的事件处理逻辑
@param sender button对象
--]]
function GoodsSale:ButtonActions( sender , touch )
	local tag = sender:getTag()
	if tag == 1 then 		-- 减号
		if self.chooseNum > 1 then
			self.chooseNum = self.chooseNum - 1
		end
	elseif tag == 2 then 	-- 加号
		if self.chooseNum < self.datas.amount then
			self.chooseNum = self.chooseNum + 1
		end
	elseif tag == 3 then 	-- max
		self.chooseNum  = self.datas.amount 
	elseif tag == 4 then 	-- 确定出售
		if self.callback then
            self.callback( self.chooseNum,self.datas.id )
        end
		self:runAction(cc.RemoveSelf:create())
		return
	end
	self:RefreshUI()
end
--[[
	刷新界面信息
--]]
function GoodsSale:RefreshUI()
	local viewData 			= self.viewData_
	local reward_rank 		=  viewData.reward_rank			--物品等级
	local reward_img 		=  viewData.reward_img			--物品图片
	local good_name_label 	=  viewData.good_name_label		--标题  物品名称
	local hasNumLabel 		=  viewData.hasNumLabel			--拥有数量
	local getMoneyLabel 	=  viewData.getMoneyLabel		--可获得金钱数量
	local label_num 		=  viewData.label_num			--选择数量
	local img_money_type 	=  viewData.img_money_type		--货币类型图标
	local fragmentImg 	=  viewData.fragmentImg		--货币类型图标
	fragmentImg:setVisible(false)
	
	--物品材料等级
	reward_rank:setTexture(_res('ui/common/common_frame_goods_'..tostring(self.datas.quality or 1)..'.png'))

	local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(self.datas.quality or 1))
	fragmentImg:setTexture(_res(fragmentPath))

	if self.datas.type then
		if tostring(self.datas.type) == GoodsType.TYPE_CARD_FRAGMENT then
			fragmentImg:setVisible(true)
		end
	end
	--物品图片
	local goodsId = self.datas.id
    if checkint(goodsId) >= 140000 and checkint(goodsId) < 150000 then
    	goodsId = goodsId%140000
    	goodsId = 200000 + goodsId
    end
    local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
	reward_img:setTexture(_res(iconPath))
	reward_img:setScale(0.55)
    --物品名称
	-- good_name_label:SetText(self.datas.name)
	self.cview:SetText( self.datas.name )

	--物品数量
	hasNumLabel:setString(string.fmt(__('拥有:_value_'), {_value_ = self.datas.amount }))

	--物品价格
	if self.datas.sellCurrency == '2' then
		getMoneyLabel:setString(tostring(self.datas.goldValue*self.chooseNum))
		img_money_type:setTexture(_res(string.format( "arts/goods/goods_icon_%d.png", GOLD_ID )))
	elseif self.datas.sellCurrency == '1' then
		getMoneyLabel:setString(tostring(self.datas.diamondValue*self.chooseNum))
		img_money_type:setTexture(_res(string.format( "arts/goods/goods_icon_%d.png", DIAMOND_ID )))
	end
	
	img_money_type:setPositionX(getMoneyLabel:getPositionX() + getMoneyLabel:getBoundingBox().width + 5)

	label_num:setString(tostring(self.chooseNum))
end




return GoodsSale
