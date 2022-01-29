
--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息视图
]]
---@class WaterBarAddMaterialView
local WaterBarAddMaterialView = class('WaterBarAddMaterialView', function()
	return CLayout:create(display.size)
end)
local RES_DICT= {
	COMMON_BG_8                              = _res("ui/common/common_bg_8.png"),
	MARKET_CHOICE_BG_PRIZCE                  = _res("ui/home/market/market_choice_bg_prizce.png"),
	MARKET_SOLD_BTN_PLUS                     = _res("avatar/ui/market_sold_btn_plus.png"),
	MARKET_SOLD_BTN_SUB                      = _res("ui/home/market/market_sold_btn_sub.png"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png")
}
function WaterBarAddMaterialView:ctor(param)
	self.materialId = param.materialId
	self.event = param.event
	self.maxNum =checkint(param.maxNum)
	self.totalNum = app.waterBarMgr:getMaterialNum(self.materialId)
	self.currentNum = checkint(param.currentNum)
	self:InitUI()
	display.commonUIParams(self.viewData.closeLayer , {cb = handler(self, self.CloseClick)})
	display.commonUIParams(self.viewData.addBtn , {cb = handler(self, self.AddClick)})
	display.commonUIParams(self.viewData.reduceBtn , {cb = handler(self, self.ReduceClick)})
	display.commonUIParams(self.viewData.makeSureBtn , {cb = handler(self, self.MakeSureClick)})
	display.commonUIParams(self.viewData.makeNumBg , {cb = handler(self, self.ShowKeyBordClick)})
end
function WaterBarAddMaterialView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size ,color = cc.c4b(0,0,0,175),enable = true})
	self:addChild(closeLayer)
	local centerLayerSize = cc.size(435,308)
	local centerLayer = display.newLayer(display.cx + 0, display.cy  + 0 ,{ap = display.CENTER,size = centerLayerSize})
	self:addChild(centerLayer)
	local swalllowLayer = display.newLayer(217.5, 154 ,{color = cc.c4b(0,0,0,0), enable = true ,  ap = display.CENTER,size = cc.size(435,308)})
	centerLayer:addChild(swalllowLayer)
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_8 ,217.5, 154,{ap = display.CENTER})
	centerLayer:addChild(bgImage)
	local makeNumImage = display.newImageView( RES_DICT.MARKET_CHOICE_BG_PRIZCE ,219.4975, 186,{ap = display.CENTER , enable = false })
	centerLayer:addChild(makeNumImage)
	local makeNumBg = display.newButton(219.4975, 186,{ ap = display.CENTER,  enable = true , size = cc.size(105,44)} )
	centerLayer:addChild(makeNumBg)
	local makeNum = display.newLabel(219.5, 186.2 , {fontSize = 24,ttf = true,font = TTF_GAME_FONT,text = '',color = '#5b3c12',ap = display.CENTER})
	centerLayer:addChild(makeNum)
	makeNum:setString(tostring(self.currentNum))
	local addBtn = display.newImageView( RES_DICT.MARKET_SOLD_BTN_PLUS ,296.5, 186,{ap = display.CENTER, enable = true })
	centerLayer:addChild(addBtn)
	local reduceBtn = display.newImageView( RES_DICT.MARKET_SOLD_BTN_SUB ,138.5, 186,{ap = display.CENTER, enable = true })
	centerLayer:addChild(reduceBtn)
	local makeSureBtn = display.newButton(217.5, 71 , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER})
	centerLayer:addChild(makeSureBtn)
	display.commonLabelParams(makeSureBtn ,fontWithColor(14 , {fontSize = 24,text = __('确定'),color = '#ffffff'}))
	local materialConf = CONF.BAR.MATERIAL:GetValue(self.materialId)
	local name = materialConf.name
	local materialLabel = display.newLabel(centerLayerSize.width/2 , centerLayerSize.height - 70 , {fontSize = 28 , ttf = true , font = TTF_GAME_FONT , text  = name ,color = "#5b3c15" })
	centerLayer:addChild(materialLabel)
	self.viewData = {
		closeLayer                = closeLayer,
		centerLayer               = centerLayer,
		swalllowLayer             = swalllowLayer,
		bgImage                   = bgImage,
		makeNumBg                 = makeNumBg,
		makeNum                   = makeNum,
		addBtn                    = addBtn,
		reduceBtn                 = reduceBtn,
		makeSureBtn               = makeSureBtn
	}
end
function WaterBarAddMaterialView:CloseClick()
	self:runAction(cc.RemoveSelf:create())
end
function WaterBarAddMaterialView:AddClick()
	local num = checkint(self.viewData.makeNum:getString())
	if num < self.totalNum and num < self.maxNum then
		num = num +1
		self.viewData.makeNum:setString(tostring(num))
	else
		app.uiMgr:ShowInformationTips(__('已到达最大上限'))
	end
end
function WaterBarAddMaterialView:ReduceClick()
	local num = checkint(self.viewData.makeNum:getString())
	if  num > 0  then
		num = num -1
		self.viewData.makeNum:setString(tostring(num))
	end
end

function WaterBarAddMaterialView:ShowKeyBordClick()
	app.uiMgr:ShowNumberKeyBoard(
{
			nums 			= 1, 				-- 最大输入位数
			model 			= NumboardModel.freeModel, 				-- 输入模式 1为n位密码模式 2为自由模式
			callback 		= handler(self , self.NumKeyBordCallBackClick), 						-- 回调函数 确定之后接收输入字符的处理回调
			titleText 		= __('请输入需要消耗的材料数量'), 					-- 标题
			defaultContent 	= string.fmt(__('所需材料最多_num_个') , {_num_ = self.maxNum}) 				-- 输入框中默认显示的文字
		}
	)
end
function WaterBarAddMaterialView:NumKeyBordCallBackClick(num )
	num = checkint(num)
	if num <= self.totalNum and num <= self.maxNum then
		num = num
		self.viewData.makeNum:setString(tostring(num))
	else
		app.uiMgr:ShowInformationTips(__('已到达最大上限'))
	end
end

function WaterBarAddMaterialView:MakeSureClick()
	if self.event then
		app:DispatchObservers(self.event , { materialId = self.materialId , num = checkint(self.viewData.makeNum:getString()) })
	end
	self:CloseClick()
end
return WaterBarAddMaterialView
