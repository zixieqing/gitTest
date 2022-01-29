---@class DeliveryAndExploreView
local DeliveryAndExploreView = class('DeliveryAndExploreView', function()
	local node =  display.newLayer(0,0, {size = cc.size(555,display.height)})
	node.name = 'DeliveryAndExploreView'
	return node
end)
function DeliveryAndExploreView:ctor()
	self:InitUI()
end
--- 初始化UI
function DeliveryAndExploreView:InitUI()
	-- 内容层
	local bgSize = cc.size(555,display.height)
	local bgLayer = display.newLayer(0,0 , {size = bgSize , ap = display.LEFT_BOTTOM  })
	--bgLayer:setPosition(cc.p(display.width+ 555, display.height/2))
	self:addChild(bgLayer)

	-- 吞噬层
	local swalowLayer =display.newLayer(bgSize.width /2 , bgSize.height/2 , {size = bgSize , ap = display.CENTER , enable = true })
	bgLayer:addChild(swalowLayer)
	-- 背景图片
	local chestHight = 0
	if app:RetrieveMediator("OrderChestMediator") then
		chestHight = 0
	end

	-- listview 的修改
	local listSize =  cc.size(550, bgSize.height -180 -chestHight)
	local listView = CListView:create(listSize)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.CENTER_TOP)
	listView:setPosition(cc.p(bgSize.width/2 , bgSize.height -63 - chestHight))
	bgLayer:addChild(listView)

	-- 一键领取
	local oneKeyBtn = display.newButton(bgSize.width/2, 55, { n = _res('ui/common/common_btn_orange_big')})
	display.commonLabelParams(oneKeyBtn, fontWithColor(14, {text = __('一键领取'), fontSize = 28}))
	bgLayer:addChild(oneKeyBtn)
	oneKeyBtn:setEnabled(false)

	self.viewData = {
		bgLayer = bgLayer ,
		listView = listView ,
		oneKeyBtn = oneKeyBtn,
		swalowLayer = swalowLayer
	}
end

return DeliveryAndExploreView