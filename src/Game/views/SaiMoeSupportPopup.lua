--[[
    燃战选择应援道具界面
--]]
local CommonDialog = require('common.CommonDialog')
local SaiMoeSupportPopup = class('SaiMoeSupportPopup', CommonDialog)

local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local gameMgr = shareFacade:GetManager("GameManager")

local RES_DICT = {
	COMMON_BG_3                 = _res('ui/common/common_bg_3.png'),
	COMMON_BG_TITLE_2           = _res('ui/common/common_bg_title_2.png'),
	BUY_BG_INFO                 = _res('ui/home/market/market_buy_bg_info.png'),
	BTN_SUB                     = _res('ui/home/market/market_sold_btn_sub.png'),
	BTN_PLUS                    = _res('ui/home/market/market_sold_btn_plus.png'),
    BTN_MAX_BG                  = _res('ui/home/market/market_sold_btn_zuida.png'),
    COMMON_BTN_ORANGE           = _res('ui/common/common_btn_orange.png'),


    COMMON_FONT_1               = 'font/common_num_1.fnt',
}

function SaiMoeSupportPopup:InitialUI()
	local itemData = self.args.data
    local btnTag = self.args.btnTag
	local goodsId = itemData.goodsId[btnTag]
	self.goodsId = goodsId
    self.selectNum = 1
    self.perValue = checkint(itemData.goodsPoints[tostring(goodsId)])
	self.goodsAmount = math.min(99, gameMgr:GetAmountByGoodId(goodsId))
    local goodsData = CommonUtils.GetConfig('goods', 'goods', goodsId)
	local function CreateView()
		-- bg
		local bg = display.newImageView(RES_DICT.COMMON_BG_3, 0, 0)
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title
		local titleBg = display.newButton(0, 0, {n = RES_DICT.COMMON_BG_TITLE_2, animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 4)})
		display.commonLabelParams(titleBg,
			{text = __('赠送'),
            fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
            ttf = true, font = TTF_GAME_FONT,
			offset = cc.p(0, -2)})
        bg:addChild(titleBg)
        
		-- 物品
	    local goodNode = require('common.GoodNode').new({id = goodsId,showAmount = false})
	    goodNode:setAnchorPoint(cc.p(0.5,0))
	    goodNode:setPosition(cc.p(bgSize.width/2, 440))
	    view:addChild(goodNode, 10)
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			PlayAudioByClickNormal()
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
		end})
	    
		local goodsName = display.newLabel(bgSize.width/2, 556, fontWithColor(16, {ap = cc.p(0.5, 0), text = goodsData.name}))
        view:addChild(goodsName, 10)

		local goodsNum = display.newLabel(bgSize.width/2, 410, fontWithColor(16, {ap = cc.p(0.5, 0), text = __('当前拥有:') .. CommonUtils.GetCacheProductNum(goodsId)}))
		view:addChild(goodsNum, 10)

		-- 应援票数增加
		local priceLabel = display.newLabel(212, 370, fontWithColor(16, {ap =display.RIGHT_CENTER, text = __('应援票数增加') , reqW = 187 }))
		view:addChild(priceLabel, 10)
		local priceBg = display.newImageView(RES_DICT.BUY_BG_INFO, bgSize.width * 0.5, 370, {ap = cc.p(0.5, 0.5), scale9 = true, size = cc.size(120, 30)})
		view:addChild(priceBg, 5)
		local priceNum = cc.Label:createWithBMFont(RES_DICT.COMMON_FONT_1, tostring(self.perValue * self.selectNum))
		priceNum:setAnchorPoint(cc.p(0.5, 0.5))
		priceNum:setHorizontalAlignment(display.TAR)
		priceNum:setPosition(bgSize.width * 0.5, 370)
		view:addChild(priceNum, 10)
        priceNum:setScale(1)
        
		-- 赠送数量
		local purchaseNumLabel = display.newLabel(150, 260, fontWithColor(16 , {ap = display.RIGHT_CENTER, text = __('赠送数量'),w = 120  , hAlign = display.TAL}))
        view:addChild(purchaseNumLabel, 10)

		local chooseNumLayout = display.newLayer(0, 0, {size = cc.size(400, 60), ap = cc.p(0.5, 0.5)})--display.newLayer(purchaseNumBg:getContentSize())
		view:addChild(chooseNumLayout,11)
		chooseNumLayout:setPosition(cc.p(bgSize.width * 0.5, 270))
		--选择数量
		local btn_num = display.newButton(0, 0, {n = RES_DICT.BUY_BG_INFO,scale9 = true, size = cc.size(180, 44)})
		display.commonUIParams(btn_num, {po = cc.p(chooseNumLayout:getContentSize().width*0.5, -5),ap = cc.p(0.5,0)})
		display.commonLabelParams(btn_num, {text = '1', fontSize = 28, color = '#7c7c7c'})
		chooseNumLayout:addChild(btn_num)

		--减号btn
		local btn_minus = display.newButton(0, 0, {n = RES_DICT.BTN_SUB})
		display.commonUIParams(btn_minus, {po = cc.p(chooseNumLayout:getContentSize().width*0.5 - 90, -10),ap = cc.p(0.5,0)})
		chooseNumLayout:addChild(btn_minus)
		btn_minus:setTag(1)

		--加号btn
	    local btn_add = display.newButton(0, 0, {n = RES_DICT.BTN_PLUS})
		display.commonUIParams(btn_add, {po = cc.p(chooseNumLayout:getContentSize().width*0.5 + 90, -10),ap = cc.p(0.5,0)})
		chooseNumLayout:addChild(btn_add)
		btn_add:setTag(2)

        local maxBtn = display.newButton(chooseNumLayout:getContentSize().width*0.5 + 120, -10, {ap = display.LEFT_BOTTOM, n = RES_DICT.BTN_MAX_BG})
        display.commonLabelParams(maxBtn, fontWithColor(14, {text = __('最大')}))
        chooseNumLayout:addChild(maxBtn)
        maxBtn:setTag(3)

		-- 赠送按钮
		local supportBtn = display.newButton(bgSize.width/2, 120, {tag = btnTag, n = RES_DICT.COMMON_BTN_ORANGE})
		view:addChild(supportBtn, 10)
		display.commonLabelParams(supportBtn, fontWithColor(14, {text = __('赠送')}))
		supportBtn:setUserTag(self.selectNum or 1)
        
		return {
			view        = view,
			supportBtn  = supportBtn,

			chooseNumLayout = chooseNumLayout,
			btn_num 	= btn_num,
			btn_minus 	= btn_minus,
			btn_add 	= btn_add,
			maxBtn 	    = maxBtn,
			priceNum    = priceNum
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )
        self.viewData.supportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnCallback))
        
		self.viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
		self.viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
		self.viewData.maxBtn:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
		self.viewData.btn_num:setOnClickScriptHandler(handler(self,self.SetNumBtnCallback))

	end, __G__TRACKBACK__)
end


function SaiMoeSupportPopup:ChooseNumBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()

	local viewData = self.viewData
	local btn_num = viewData.btn_num
	if tag == 1 then --减
		if self.selectNum <= 0 then
			return
		end
		if checkint(self.selectNum) > 1 then
			self.selectNum = self.selectNum - 1
		end
	elseif tag == 2 then --加
		if self.selectNum >= self.goodsAmount then
			return
		end
		self.selectNum = self.selectNum + 1
	elseif tag == 3 then --最大
		self.selectNum = self.goodsAmount
	end

	btn_num:getLabel():setString(tostring(self.selectNum))
	self.viewData.supportBtn:setUserTag(self.selectNum)
	self.viewData.priceNum:setString(tostring(self.perValue * self.selectNum))
end

function SaiMoeSupportPopup:SetNumBtnCallback( sender )
	PlayAudioByClickNormal()
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入需要应援的道具的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	shareFacade:RegistMediator(mediator)
end

function SaiMoeSupportPopup:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = '1'
		end
		if checkint(data) <= 0 then
			data = 1
		end

		if checkint(data) > checkint(self.goodsAmount) then
			data = self.goodsAmount
		end

		self.selectNum = checkint(data)
		self.viewData.btn_num:getLabel():setString(tostring(self.selectNum))
		self.viewData.supportBtn:setUserTag(self.selectNum)

		self.viewData.priceNum:setString(tostring(self.perValue * self.selectNum))
	end
end

function SaiMoeSupportPopup:SupportBtnCallback( sender )
	PlayAudioByClickNormal()
	shareFacade:DispatchObservers(SUPPORT_ITEM_SELECTED_EVENT, {goodsId = self.goodsId, num = self.selectNum})
	self:CloseHandler()
end

return SaiMoeSupportPopup