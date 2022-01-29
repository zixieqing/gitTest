---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/10/17 10:40 AM
---
local Anniversary19DreamCommonView = require("Game.views.anniversary19.Anniversary19DreamCommonView")
---@class Anniversary19EliteBossView : Anniversary19DreamCommonView
local Anniversary19EliteBossView = class('Anniversary19EliteBossView',Anniversary19DreamCommonView)
local anniversary2019Mgr = app.anniversary2019Mgr
function Anniversary19EliteBossView:AddDiffView(exploreModuleId , exploreId)
	local conf = anniversary2019Mgr:GetDreamQuestTypeConfByDreamQuestType(anniversary2019Mgr.dreamQuestType.ELITE_SHUT)
	local oneConf = conf[tostring(exploreModuleId)][tostring(exploreId)]
	local questId = oneConf.questId
	local parseConf = anniversary2019Mgr:GetConfigParse()
	local questConf = anniversary2019Mgr:GetConfigDataByName(parseConf.TYPE.QUEST)
	local showMonster = questConf[tostring(questId)].showMonster or {}
	local monsterId = showMonster[1] or 300150
	local monsterConf = CommonUtils.GetConfigAllMess('monster' , 'monster')
	local monsterOneConf = monsterConf[tostring(monsterId)]
	local skinId = monsterOneConf.skinId
	local qAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 1})
	qAvatar:setAnimation(0, 'idle', true)
	qAvatar:setPosition(cc.p(300, 50))
	self.viewData.centerLayout:addChild(qAvatar)
end

function Anniversary19EliteBossView:UpdateUI(exploreModuleId ,  exploreId , isPassed)
	local rewardData = anniversary2019Mgr:GetDreamTypeReward(exploreModuleId ,anniversary2019Mgr.dreamQuestType.ELITE_SHUT , exploreId)
	local viewData = self.viewData
	display.commonLabelParams(viewData.resultLabel , {text = app.anniversary2019Mgr:GetPoText(__('战斗胜利可获得'))})
	display.commonLabelParams(viewData.descrLabel , {text  = app.anniversary2019Mgr:GetPoText(__('在梦境中隐隐觉察到了某种不知名的力量，这力量的来源难道来自于它吗？'))  })
	display.commonLabelParams(viewData.titleBtn , {text = app.anniversary2019Mgr:GetPoText(__('困难战斗'))})
	viewData.goodNode:RefreshSelf(rewardData)
	self:SetRightCenterLayoutVisible(true)
	if isPassed then
		self:UpdateFailureUI()
	else
		self:UpdateStartUI()
	end
end

function Anniversary19EliteBossView:UpdateFailureUI()
	local viewData = self.viewData
	self:SetTwoBtn()
	display.commonLabelParams(viewData.leftButton , fontWithColor(14 , {text = app.anniversary2019Mgr:GetPoText(__('放弃'))}))
	display.commonLabelParams(viewData.rightButton , fontWithColor(14 , {text = app.anniversary2019Mgr:GetPoText(__('挑战'))}))
end

function Anniversary19EliteBossView:UpdateStartUI()
	local viewData = self.viewData
	self:SetOnlyOneBtn()
	display.commonLabelParams(viewData.rightButton , fontWithColor(14 , {text = app.anniversary2019Mgr:GetPoText(__('挑战'))}))
end
return Anniversary19EliteBossView
