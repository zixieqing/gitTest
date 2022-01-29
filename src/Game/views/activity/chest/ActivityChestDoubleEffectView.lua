--[[
 * author : xingweihao
 * descpt : 宝箱活动
--]]
---@class ActivityChestDoubleEffectView
local ActivityChestDoubleEffectView = class('ActivityChestDoubleEffectView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.view.activity.chest.ActivityChestDoubleEffectView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT={
	BOX_GOOD_BG                              = _res("ui/home/activity/chest/box_good_bg.png"),
	BOX_GOOD_HEAD_BG                         = _res("ui/home/activity/chest/box_good_head_bg.png"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png"),
	BOX_GOOD_ZI_BG                           = _res("ui/home/activity/chest/box_good_zi_bg.png"),
	COMMON_BTN_GREEN                         = _res("ui/common/common_btn_green.png")
}

function ActivityChestDoubleEffectView:ctor( ... )
	self:InitUI()
end

function ActivityChestDoubleEffectView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,175),enable = true})
	self:addChild(closeLayer)
	local centerLayer = display.newLayer(display.cx + 0, display.cy  + 35 ,{ap = display.CENTER,size = cc.size(490.9,535.1)})
	self:addChild(centerLayer)
	local swallowLayer = display.newLayer(245.45, 267.55 ,{ap = display.CENTER,size = cc.size(490.9,535.1),color = cc.c4b(0,0,0,0),enable = true})
	centerLayer:addChild(swallowLayer)
	local bgImage = display.newImageView( RES_DICT.BOX_GOOD_BG ,245.45, 267.55,{ap = display.CENTER})
	centerLayer:addChild(bgImage)
	local titleBtn = display.newButton(245.45, 495.55 , {n = RES_DICT.BOX_GOOD_HEAD_BG,ap = display.CENTER,scale9 = true,size = cc.size(354,30)})
	centerLayer:addChild(titleBtn)
	display.commonLabelParams(titleBtn ,{fontSize = 24,ttf = true,font = TTF_GAME_FONT,text = "",color = '#7e2b1a',paddingW  = 20,safeW = 314})
	local effectImage = display.newImageView( RES_DICT.BOX_GOOD_ZI_BG ,245.45, 296.55,{ap = display.CENTER})
	centerLayer:addChild(effectImage)
	local effectLabel = display.newLabel(37.5, 424.1 , {fontSize = 22,text = '',color = '#52332c',w = 400,hAlign = display.TAL,ap = display.LEFT_TOP})
	centerLayer:addChild(effectLabel)
	local buyBtn = display.newButton(245.45, 59.34999 , {n = RES_DICT.COMMON_BTN_GREEN,ap = display.CENTER,scale9 = true,size = cc.size(123,59)})
	centerLayer:addChild(buyBtn)
	self.viewData = {
		closeLayer                = closeLayer,
		centerLayer               = centerLayer,
		swallowLayer              = swallowLayer,
		bgImage                   = bgImage,
		titleBtn                  = titleBtn,
		effectImage               = effectImage,
		effectLabel               = effectLabel,
		buyBtn                    = buyBtn
	}
end

function ActivityChestDoubleEffectView:UpdateEffectLabel()
	local moduleExplainConf = CONF.BASE.MODULE_DESCR:GetValue("-64")
	display.commonLabelParams(self.viewData.effectLabel , {
		fontSize = 22,text = moduleExplainConf.descr,color = '#52332c',w = 400,hAlign = display.TAL,ap = display.LEFT_TOP
	})
	display.commonLabelParams(self.viewData.titleBtn ,{fontSize = 24,ttf = true,font = TTF_GAME_FONT,text = moduleExplainConf.title ,color = '#7e2b1a',paddingW  = 20,safeW = 314})
end

function ActivityChestDoubleEffectView:UpdateBuyBtn(hasPurchased , price)
	if hasPurchased == 1 then
		display.commonLabelParams(self.viewData.buyBtn ,fontWithColor(14, {text = __('已购买'), paddingW = 20 , safeW = 84}) )
		return
	end
	display.commonLabelParams(self.viewData.buyBtn ,fontWithColor(14, {text = string.format(__('￥ %s') ,tostring(price) ), paddingW = 20 , safeW = 84}) )
end

return ActivityChestDoubleEffectView