--[[
    通用 活动页
    @params bg 默认背景
    @params ruleBg 规则背景
--]]
local CommonActivityChestView = class('CommonActivityChestView', function ()
	local node = CLayout:create(display.size)
	node:setAnchorPoint(display.CENTER)
	node.name = 'common.CommonActivityChestView'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
	HOME_BOX_1                               = _spn("ui/home/activity/chest/animate/home_box_1"),
	HOME_BOX_2                               = _spn("ui/home/activity/chest/animate/home_box_2"),
	HOME_BOX_3                               = _spn("ui/home/activity/chest/animate/home_box_3"),
	HOME_BOX_4                               = _spn("ui/home/activity/chest/animate/home_box_4"),
	HOME_BOX_5                               = _spn("ui/home/activity/chest/animate/home_box_5"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png"),
	COMMON_BTN_WHITE_DEFAULT                 = _res("ui/common/common_btn_white_default"),

}
function CommonActivityChestView:ctor(params)
	self.chestDatas = params
	self.isClose = true
	self:InitUI()
end

function CommonActivityChestView:InitUI()
	local closeLayer = display.newLayer(display.cx , display.cy , {
		ap = display.CENTER , size = display.size ,
		color = cc.c4b(0,0,0,175),
		enable = true , cb = handler(self , self.CloseView)
	})
	self:addChild(closeLayer)

	local count = #self.chestDatas
	local centerLayerSize = cc.size(340 * count , 390 )
	local centerLayer = display.newLayer(display.cx , display.cy , {
		size = centerLayerSize , ap = display.CENTER
	})
	self:addChild(centerLayer)
	local swallowLayer = display.newButton(centerLayerSize.width/2 , centerLayerSize.height/2 , {
		size = centerLayerSize , ap = display.CENTER , enable = true
	})
	centerLayer:addChild(swallowLayer)
	for i = 1 , count do
		local chestNode = self:CreateChestNode(self.chestDatas[i])
		chestNode:setPosition((i -0.5) *340 , 195 )
		centerLayer:addChild(chestNode)
	end
end

function CommonActivityChestView:CreateChestNode(chestData)
	local goodsId = chestData.goodsId
	local activityId = chestData.activityId
	local chestNodeSize = cc.size(340 , 390)
	local crBoxConf = CONF.GOODS.CR_BOX:GetValue(goodsId)
	local photoId = string.upper(crBoxConf.photoId)

	local chestNode = display.newLayer(chestNodeSize.width/2 , chestNodeSize.height/2 , {
		size = chestNodeSize , ap = display.CENTER
	})

	local chestSpine = sp.SkeletonAnimation:create(RES_DICT[photoId].json ,RES_DICT[photoId].atlas ,1)

	chestSpine:runAction(cc.Sequence:create(
		cc.CallFunc:create(function()
			chestSpine:setAnimation(0, 'play4' , false)
		end),
		cc.DelayTime:create(1.2),
		cc.CallFunc:create(function()
			chestSpine:addAnimation(1, 'idle2' , true)
		end)
	))
	chestSpine:setPosition(170, chestNodeSize.height/2)
	chestSpine:setAnchorPoint(display.CENTER)
	chestNode:addChild(chestSpine)

	local closeBtn = display.newButton(chestNodeSize.width/4 , 40 , {n = RES_DICT.COMMON_BTN_WHITE_DEFAULT})
	display.commonLabelParams(closeBtn, fontWithColor(14, {text = __('关闭')}))
	chestNode:addChild(closeBtn)
	display.commonUIParams(closeBtn , {cb = handler(self, self.CloseView)})
	local goToBtn = display.newButton(chestNodeSize.width/4*3 , 40 , {n = RES_DICT.COMMON_BTN_ORANGE})
	display.commonLabelParams(goToBtn, fontWithColor(14, {text = __('解锁宝箱')}))
	chestNode:addChild(goToBtn)
	goToBtn:setTag(checkint(activityId))
	display.commonUIParams(goToBtn , {cb = handler(self, self.GoToActivity)})
	return chestNode
end

function CommonActivityChestView:CloseView()
	if self.isClose then
		self.isClose = false
		self:runAction(cc.RemoveSelf:create())
	end
end

function CommonActivityChestView:GoToActivity(sender)
	local tag = sender:getTag()
	self:CloseView()
	app:RetrieveMediator('Router'):Dispatch(
			{name = "HomeMediator"},
			{ name = "ActivityMediator", params = {activityId = tag}}
	)
end

return CommonActivityChestView