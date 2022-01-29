---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/10/17 10:40 AM
---
local Anniversary20DreamCommonView = require("Game.views.anniversary20.Anniversary20DreamCommonView")
---@class Anniversary20ChestView : Anniversary20DreamCommonView
local Anniversary20ChestView = class('Anniversary20ChestView',Anniversary20DreamCommonView)
function Anniversary20ChestView:AddDiffView()

	local chestSpanData = _spn(string.format("ui/anniversary20/explore/effects/wonderland_tower_tea_reward_%d" , app.anniv2020Mgr:getExploringId()))
	local chestSpine = display.newPathSpine(chestSpanData)
	chestSpine:setAnimation(0, "idle" , true )
	chestSpine:setPosition(250, 140)
	chestSpine:setAnchorPoint(display.center)
	local viewData = self.viewData
	viewData.centerLayout:addChild(chestSpine)
	viewData.centerLayout:setVisible(true)
	viewData.chestSpine = chestSpine
end

function Anniversary20ChestView:UpdateUI(mapGridId)
	local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(mapGridId)
	local refId = app.anniv2020Mgr:getExploreingMapRefIdAt(mapGridId)
	local ANNIV2020 = FOOD.ANNIV2020
	local chestConf = ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
	local rewardData = chestConf.rewards
	local viewData = self.viewData
	display.commonLabelParams(viewData.resultLabel , {text = __('打开宝箱可获得')})
	display.commonLabelParams(viewData.descrLabel , {text  = __('偶然发现了在路边的箱子，走近一看，居然没有上锁。\n要不要打开看一下呢？') , w = 300 , hAlign = display.TAL })
	display.commonLabelParams(viewData.titleBtn , {text = __('神秘的宝箱')})
	display.commonLabelParams(viewData.rightButton, fontWithColor(14, {text = __('打开')}))
	self:AddGoodNodes(rewardData)
	self:SetRightCenterLayoutVisible(true)
	self:SetOnlyOneBtn()
end
return Anniversary20ChestView

