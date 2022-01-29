--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 挂机游戏 视图
]]
---@class Anniversary20ExploreBuffDescrView :Node
local Anniversary20ExploreBuffDescrView = class('Anniversary20ExploreBuffDescrView', function()
	return CLayout:create(display.size)
end)

local RES_DICT = {
	WONDERLAND_TOWER_TEA_BUFF_TIPS = _spn("ui/anniversary20/explore/effects/wonderland_tower_tea_buff_tips")
}
function Anniversary20ExploreBuffDescrView:ctor(args)
	self.isClose = false
	self.buffId = args.buffId
	self:InitUI()
	self:UpdateView()
end

function Anniversary20ExploreBuffDescrView:InitUI()
	local closeLayer = display.newLayer(display.cx , display.cy , {ap = display.CENTER ,  size = display.size , color = cc.c4b(0,0,0,0) , enable = true })
	ui.bindClick(closeLayer , handler(self, self.CloseViewClick))
	self:addChild(closeLayer)
	local spineNode = display.newPathSpine(RES_DICT.WONDERLAND_TOWER_TEA_BUFF_TIPS)
	spineNode:setAnimation(0, "play1" , false)
	self:addChild(spineNode)
	spineNode:setPosition(display.center)
	local buffLabel = display.newLabel( display.cx  ,  display.cy ,{ color = "#F4c264" , text = "" , fontSize = 30 })
	self:addChild(buffLabel)
	self.viewData = {
		closeLayer = closeLayer ,
		spineNode = spineNode ,
		buffLabel = buffLabel
	}
end

function Anniversary20ExploreBuffDescrView:UpdateView()
	local ANNIV2020 = FOOD.ANNIV2020
	local buffConf = ANNIV2020.EXPLORE_TYPE_CONF[ANNIV2020.EXPLORE_TYPE.BUFF]:GetValue(self.buffId)
	local descr = buffConf.descr
	display.commonLabelParams(self.viewData.buffLabel, {text = descr})
end

function Anniversary20ExploreBuffDescrView:CloseViewClick()
	if not  self.isClose then
		self.isClose = true
		self:runAction(
			cc.RemoveSelf:create()
		)
	end
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------




return Anniversary20ExploreBuffDescrView
