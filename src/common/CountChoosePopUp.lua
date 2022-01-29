--[[
    使用道具选择数量
--]]
local GameScene = require( "Frame.GameScene" )

local CountChoosePopUp = class('CountChoosePopUp', GameScene)

local app = app
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

function CountChoosePopUp:ctor( ... )
    local arg = unpack({...})
    self.args = arg
	self.selectNum = 1
    self:init()
end

function CountChoosePopUp:init()
    self.goodsId    = self.args.goodsId
    self.callback   = self.args.callback
    self.num        = gameMgr:GetAmountByGoodId(self.goodsId)
    self.data       = CommonUtils.GetConfig('goods', 'goods', self.goodsId)

    local function CreateView(  )
        self:setName("CountChoosePopUp")
        self:setPosition(display.center)
    
        local commonBG = require('common.CloseBagNode').new({callback = function()
            PlayAudioByClickClose()
            self:runAction(cc.RemoveSelf:create())
        end})
        commonBG:setPosition(utils.getLocalCenter(self))
        commonBG:setName('commonBG')
        self:addChild(commonBG)
    
        --view
        local view = CLayout:create()
        view:setPosition(display.cx, display.cy)
        view:setAnchorPoint(display.CENTER)
        self.view = view
        view:setName('view')
    
        local outline = display.newImageView(_res('ui/common/common_bg_8.png'))
        local size = outline:getContentSize()
        outline:setAnchorPoint(display.LEFT_BOTTOM)
        view:addChild(outline)
        view:setContentSize(size)
        commonBG:addContentView(view)
    
        local tip = display.newLabel(utils.getLocalCenter(view).x, size.height - 40, { fontSize = 26, color = '#4c4c4c', text = __('选择使用的数量')})
        tip:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        tip:setAnchorPoint(cc.p(0.5 ,1))
        view:addChild(tip)
    
        local oneBtn = display.newButton(size.width * 0.5 - 80,50,{
            n = _res('ui/common/common_btn_white_default.png'),
        })
        display.commonLabelParams(oneBtn,fontWithColor(14,{text = __('使用一个')}))
        oneBtn:setName('oneBtn')
        view:addChild(oneBtn)
        oneBtn:setTag(1)
     
        local allBtn = display.newButton(size.width * 0.5 + 80,50,{
           n = _res('ui/common/common_btn_orange.png'),
        })
        display.commonLabelParams(allBtn,fontWithColor(14,{text = __('确定')}))
        allBtn:setName('allBtn')
        view:addChild(allBtn)
        allBtn:setTag(2)
    
        local purchaseNumBgSize = cc.size(120, 49)
        local purchaseNumBg = display.newButton(size.width * 0.5 - 40, size.height / 2 + 10, {n = _res('ui/home/market/market_buy_bg_info.png'), scale9 = true, size = cc.size(120, 49)})
        view:addChild(purchaseNumBg)
     
        local purchaseNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 1)
        purchaseNum:setAnchorPoint(cc.p(0.5, 0.5))
        purchaseNum:setHorizontalAlignment(display.TAR)
        purchaseNum:setPosition(purchaseNumBgSize.width / 2, purchaseNumBgSize.height / 2)
        purchaseNumBg:addChild(purchaseNum)
        
        --减号btn
        local btn_minus = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_sub.png')})
        display.commonUIParams(btn_minus, {po = cc.p(purchaseNumBg:getPositionX() - purchaseNumBgSize.width / 2 + 5, purchaseNumBg:getPositionY()), ap = display.RIGHT_CENTER})
        view:addChild(btn_minus)
        btn_minus:setTag(1)
     
        --加号btn
        local btn_add = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_plus.png')})
        display.commonUIParams(btn_add, {po = cc.p(purchaseNumBg:getPositionX() + purchaseNumBgSize.width / 2 - 5, purchaseNumBg:getPositionY()), ap = display.LEFT_CENTER})
        view:addChild(btn_add)
        btn_add:setTag(2)
    
        --全部btn
        local btn_max = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_zuida.png')})
        display.commonUIParams(btn_max, {po = cc.p(btn_add:getPositionX() + btn_add:getContentSize().width  + 15, btn_add:getPositionY()),ap = cc.p(0,0.5)})
        display.commonLabelParams(btn_max, fontWithColor(14,{text = __('全部')}))
        view:addChild(btn_max)
        btn_max:setTag(3)
        
		return {
            oneBtn          = oneBtn,
            allBtn          = allBtn,
			btn_minus		= btn_minus,
			btn_add			= btn_add,
			btn_max			= btn_max,
			btn_num 		= purchaseNumBg,
			purchaseNum 	= purchaseNum,
		}
    end
    xTry(function()
        local viewData = CreateView()
        self.viewData = viewData
        
        viewData.btn_num:setOnClickScriptHandler(handler(self,self.SetNumBtnCallback))
        viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
        viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
        viewData.btn_max:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))

        viewData.allBtn:setOnClickScriptHandler(handler(self,self.UseBtnCallback))
        viewData.oneBtn:setOnClickScriptHandler(handler(self,self.UseBtnCallback))
	end, __G__TRACKBACK__)
end

--[[
	打开模拟数字键盘
--]]
function CountChoosePopUp:SetNumBtnCallback( sender )
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入要使用的道具数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	app:RegistMediator(mediator)
end

--[[
	加减最大选择数量按钮回调
--]]
function CountChoosePopUp:ChooseNumBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()

	local viewData = self.viewData
	if tag == 1 then--减
		if self.selectNum <= 1 then
			return
		end
		if checkint(self.selectNum) > 1 then
			self.selectNum = self.selectNum - 1
		end
	elseif tag == 2 then--加
		if self.selectNum >= 999 then
			uiMgr:ShowInformationTips(__('已达使用上限'))
			return
		end
		if (self.selectNum + 1) > self.num then
			uiMgr:ShowInformationTips(__('已达使用上限'))
			return
		end
		self.selectNum = self.selectNum + 1
	elseif tag == 3 then--最大
		self.selectNum = self.num
		self.selectNum = math.max(1, self.selectNum)
	end

	viewData.purchaseNum:setString(tostring(self.selectNum))
end

--[[
	使用按钮回调
--]]
function CountChoosePopUp:UseBtnCallback( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
    if self.callback then
        self.callback(tag == 1 and 1 or self.selectNum)
    end
    self:runAction(cc.RemoveSelf:create())
end

--[[
	数字键盘输入完之后的回调
--]]
function CountChoosePopUp:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = '1'
		end
		if checkint(data) <= 0 then
			data = 1
        end
        local viewData = self.viewData
		self.selectNum = math.min(self.num, math.max(1, checkint(data)))
		viewData.purchaseNum:setString(self.selectNum)
	end
end


return CountChoosePopUp
