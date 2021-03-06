---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/10/17 10:40 AM
---
local Anniversary19DreamCommonView = require("Game.views.anniversary19.Anniversary19DreamCommonView")
---@class Anniversary19PlotStoryView : Anniversary19DreamCommonView
local Anniversary19PlotStoryView = class('Anniversary19PlotStoryView',Anniversary19DreamCommonView)
local anniversary2019Mgr = app.anniversary2019Mgr
function Anniversary19PlotStoryView:AddDiffView()
	local storySpinePath = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_STORY
	anniversary2019Mgr:AddSpineCacheByPath(storySpinePath)
	local storySpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(storySpinePath)
	storySpine:setAnimation(0,"idle" , true )
	storySpine:setPosition(300, 280)
	storySpine:setAnchorPoint(display.center)
	local viewData = self.viewData
	viewData.centerLayout:addChild(storySpine)
	viewData.centerLayout:setVisible(true)
	viewData.storySpine = storySpine
end

function Anniversary19PlotStoryView:UpdateUI(exploreModuleId ,  exploreId)
	local anniversary2019Mgr = app.anniversary2019Mgr
	local rewardData = anniversary2019Mgr:GetDreamTypeReward(exploreModuleId ,anniversary2019Mgr.dreamQuestType.GUAN_PLOT , exploreId)
	local viewData = self.viewData
	display.commonLabelParams(viewData.resultLabel , {text = app.anniversary2019Mgr:GetPoText(__('观看故事可获得'))})
	display.commonLabelParams(viewData.descrLabel , {text  = app.anniversary2019Mgr:GetPoText(__('这里有着盛大的舞台，舞台上站着美丽的人偶。\n快来看看会上演怎样的故事吧~')) })
	display.commonLabelParams(viewData.titleBtn , {text = app.anniversary2019Mgr:GetPoText(__('童话剧'))})
	display.commonLabelParams(viewData.rightButton , fontWithColor(14 , {text = app.anniversary2019Mgr:GetPoText(__('观看'))}))
	viewData.goodNode:RefreshSelf(rewardData)
	self:SetRightCenterLayoutVisible(true)
	self:SetOnlyOneBtn()
end

return Anniversary19PlotStoryView

