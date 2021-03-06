---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/10/17 10:40 AM
---
local Anniversary20ExploreMonsterBaseView = require("Game.views.anniversary20.Anniversary20ExploreMonsterBaseView")
---@class Anniversary20ExploreMonsterView : Anniversary20ExploreMonsterBaseView
local Anniversary20ExploreMonsterView = class('Anniversary20ExploreMonsterView',Anniversary20ExploreMonsterBaseView)
function Anniversary20ExploreMonsterView:AddDiffView(mapGridId)
	local ANNIV2020 = FOOD.ANNIV2020
	local refId = app.anniv2020Mgr:getExploreingMapRefIdAt(mapGridId)
	local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(mapGridId)
	local monsterConf = ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
	local questConf = CONF.ANNIV2020.EXPLORE_QUEST:GetValue(monsterConf.questId)
	local showMonster = questConf.showMonster or {}
	local monsterId = showMonster[1] or 300150
	local monsterConf = CommonUtils.GetConfigAllMess('monster' , 'monster')
	local monsterOneConf = monsterConf[tostring(monsterId)]
	local skinId = monsterOneConf.skinId
	local qAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 1})
	qAvatar:setAnimation(0, 'idle', true)
	qAvatar:setPosition(cc.p(250, 50))
	self.viewData.centerLayout:addChild(qAvatar)
end

function Anniversary20ExploreMonsterView:UpdateUI(mapGridId)
	local ANNIV2020 = FOOD.ANNIV2020
	local refId = app.anniv2020Mgr:getExploreingMapRefIdAt(mapGridId)
	local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(mapGridId)
	local exploreEliteMonsterConf = ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
	local rewardData = exploreEliteMonsterConf.rewards
	local viewData = self.viewData
	local textTable = {
		[ANNIV2020.EXPLORE_TYPE.MONSTER_NORMAL] = {
			title =  __('战斗') ,
			result = __('战斗胜利可获得') ,
			descr =  __('在梦境中遇到了神秘怪物，不知为何却感受到了敌意。')
		},
		[ANNIV2020.EXPLORE_TYPE.MONSTER_ELITE] = {
			title =  __('困难战斗') ,
			result = __('战斗胜利可获得') ,
			descr =  __('在梦境中隐隐觉察到了某种不知名的力量，这力量的来源难道来自于它吗？')
		},
		[ANNIV2020.EXPLORE_TYPE.MONSTER_BOSS] = {
			title =  __('困难战斗') ,
			result = __('战斗胜利可获得') ,
			descr =  __('在梦境中隐隐觉察到了某种不知名的力量，这力量的来源难道来自于它吗？')
		},
	}
	local oneTextTable = textTable[mapGridType]
	display.commonLabelParams(viewData.resultLabel , {text = oneTextTable.result})
	display.commonLabelParams(viewData.descrLabel , {text  = oneTextTable.descr, w = 300 , hAlign = display.TAC })
	display.commonLabelParams(viewData.titleBtn , {text = oneTextTable.title})
	self:AddGoodNodes(rewardData)
	self:SetRightCenterLayoutVisible(true)
	self:UpdateStartUI()
	self:UpdateBuffView()
end

function Anniversary20ExploreMonsterView:UpdateFailureUI()
	local viewData = self.viewData
	self:SetTwoBtn()
	display.commonLabelParams(viewData.leftButton , fontWithColor(14 , {text = __('放弃')}))
	display.commonLabelParams(viewData.rightButton , fontWithColor(14 , {text = __('挑战')}))
end

function Anniversary20ExploreMonsterView:UpdateStartUI()
	local viewData = self.viewData
	self:SetOnlyOneBtn()
	display.commonLabelParams(viewData.rightButton , fontWithColor(14 , {text = __('挑战')}))
end
return Anniversary20ExploreMonsterView

