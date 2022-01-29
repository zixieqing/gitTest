---@class UnionWarsResultView : Node
local UnionWarsResultView = class('common.UnionWarsResultView', function ()
	local node = CLayout:create(display.size)
	node.name = 'unionWars.UnionWarsResultView'
	node:enableNodeEvents()
	return node
end)

local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newLayer = display.newLayer
local RES_DICT = {
	GVG_BG_SETTLEMENT             = _res('ui/union/wars/rewards/gvg_bg_settlement.png'),
	AAA                           = _res('acb/union/wars/aaa.png'),
	GUILD_HEAD_FRAME_DEFAULT      = _res('ui/union/guild_head_frame_default.png'),
	COMMON_REWARD_LIGHT           = _res('ui/common/common_reward_light.png'),
	COMMON_ARROW                  = _res('ui/common/common_arrow.png'),
	GUILD_HEAD_111                = _res('arts/union/head/guild_head_111.png'),
}

function UnionWarsResultView:ctor(param)
	local pastWarsResult = param.warsResultData or {}
	self:InitUI()
	local unionMgr = app.unionMgr
	local unionData = unionMgr:getUnionData()
	local myselfUnionName = unionData.name
	local myselfUnionAvatar = unionData.avatar
	-- 处理组合数据
	local attackData  = {
		attack       = {
			unionName   = myselfUnionName,
			unionAvatar = myselfUnionAvatar,
			isResult =  pastWarsResult.attackResult
		},
		defence      = {
			unionName   = pastWarsResult.attackEnemyUnionName or "",
			unionAvatar = pastWarsResult.attackEnemyUnionAvatar or "",
			isResult =  (pastWarsResult.attackResult == 1 and 0) or 1
		},
		isResult = pastWarsResult.attackResult
	}

	local defenceData = {
		attack       = {
			unionName   = pastWarsResult.defendEnemyUnionName or "",
			unionAvatar = pastWarsResult.defendEnemyUnionAvatar or "",
			isResult = pastWarsResult.defendResult
		},
		defence      = {
			unionName   = myselfUnionName,
			unionAvatar = myselfUnionAvatar,
			isResult =  (pastWarsResult.defendResult == 1 and 0) or 1

		},
		isResult = pastWarsResult.defendResult
	}
	local attackUnionTable = self.viewData.attackUnionTable
	self:UpdateUnionNode(attackUnionTable.attack , attackData.attack)
	self:UpdateUnionNode(attackUnionTable.defence , attackData.defence)
	self:UpdateAttackLabel(attackData.isResult)

	local defenceUnionTable = self.viewData.defenceUnionTable
	self:UpdateUnionNode(defenceUnionTable.attack , defenceData.attack)
	self:UpdateUnionNode(defenceUnionTable.defence , defenceData.defence)
	self:UpdateDefenceLabel(defenceData.isResult)

end

function UnionWarsResultView:InitUI()
	local closeLayer = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size, color = cc.c4b(0,0,0,175) , cb = function()
			self:removeFromParent()
	end , enable = true  })
	self:addChild(closeLayer)


	local contentLayout = newLayer(display.cx , display.cy ,
			{ ap = display.CENTER, color1 = cc.c4b(0,0,0,0), size = cc.size(1334, 380), enable = true })
	contentLayout:setPosition(display.cx, display.cy + -48)
	self:addChild(contentLayout)

	local listSize = cc.size(380,380)
	local scrollView =  CScrollView:create(listSize)
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(display.CENTER)
	scrollView:setPosition(667, 560)
	contentLayout:addChild(scrollView)

	local rewardLight = newNSprite(RES_DICT.COMMON_REWARD_LIGHT, 190,0,
			{ ap = display.CENTER, tag = 45 })
	rewardLight:setScale(1, 1)
	scrollView:addChild(rewardLight)

	local bgIMage = newImageView(RES_DICT.GVG_BG_SETTLEMENT, 667, 190,
			{ ap = display.CENTER, tag = 30, enable = false })
	contentLayout:addChild(bgIMage)

	local attentionLabel = newLabel(1322, 31,
			{ ap = display.RIGHT_CENTER, color = '#ffda45', text = __('奖励已经通过邮件发放,请注意查收'), fontSize = 22, tag = 37 })
	contentLayout:addChild(attentionLabel)

	local resultTitle = newLabel(667, 412,
			fontWithColor('14', { ap = display.CENTER, outline = '#6f360c', ttf = true, font = TTF_GAME_FONT, color = '#ffce5a', fontSize = 40, text = "", tag = 44 }))
	contentLayout:addChild(resultTitle)

	local attackResultLabel = newLabel(684, 312,
			fontWithColor(14,{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 24, tag = 46 }))
	contentLayout:addChild(attackResultLabel ,20)

	local defencesResultLabel = newLabel(684, 157,
			fontWithColor(14,{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 24, tag = 47 }))
	contentLayout:addChild(defencesResultLabel,20)

	local resultTitle = newLabel(667, 412,
			fontWithColor('14', { ap = display.CENTER, outline = '#6f360c', ttf = true, font = TTF_GAME_FONT, color = '#ffce5a', fontSize = 40, text = __("上场竞赛结果"), tag = 44 }))
	contentLayout:addChild(resultTitle)


	local attackUnionTable = {
		attack = "", defence = "" , attackLabel = ""
	}
	local defenceUnionTable = {
		attack = "", defence = "" , attackLabel = ""
	}
	local attackPosTable = {
		attackPos = cc.p(667-250 ,310),
		defencePos = cc.p(667+250 ,310)
	}

	local defencePosTable = {
		attackPos = cc.p(667-250 ,150),
		defencePos = cc.p(667+250 ,150)
	}
	-- 进攻栏工会信息
	attackUnionTable.attack = self:CreateUnionNode(attackPosTable.attackPos)
	attackUnionTable.defence = self:CreateUnionNode(attackPosTable.defencePos)
	attackUnionTable.attackLabel = attackResultLabel
	contentLayout:addChild(attackUnionTable.attack.unionPanel)
	contentLayout:addChild(attackUnionTable.defence.unionPanel)
	-- 防守栏工会信息
	defenceUnionTable.attack = self:CreateUnionNode(defencePosTable.attackPos)
	defenceUnionTable.defence = self:CreateUnionNode(defencePosTable.defencePos)
	defenceUnionTable.attackLabel = defencesResultLabel
	contentLayout:addChild(defenceUnionTable.attack.unionPanel)
	contentLayout:addChild(defenceUnionTable.defence.unionPanel)
	contentLayout:setOpacity(0)
	self.viewData =  {
		contentLayout       = contentLayout,
		rewardLight         = rewardLight,
		bgIMage             = bgIMage,
		attentionLabel      = attentionLabel,
		resultTitle         = resultTitle,
		attackResultLabel   = attackResultLabel,
		attackUnionTable    = attackUnionTable,
		defenceUnionTable   = defenceUnionTable,
		defencesResultLabel = defencesResultLabel,
		scrollView          = scrollView,
	}
	self:EnterAction()
end


function UnionWarsResultView:CreateUnionNode(pos)
	local unionPanel = newLayer(0, 0,
			{ ap = display.CENTER, color1 = cc.r4b(0), size = cc.size(128, 128), enable = true })
	unionPanel:setPosition(pos)
	local unonIconImage = newImageView(RES_DICT.GUILD_HEAD_111, 64, 64,
			{ ap = display.CENTER, tag = 33, enable = false })
	unionPanel:addChild(unonIconImage)
	unonIconImage:setScale(0.8)

	local unonIconFrame = newImageView(RES_DICT.GUILD_HEAD_FRAME_DEFAULT, 64, 64,
			{ ap = display.CENTER, tag = 34, enable = false })
	unionPanel:addChild(unonIconFrame)
	unonIconFrame:setScale(0.85)

	local unonIconResultImage = newImageView(RES_DICT.COMMON_ARROW, 64, 64,
			{ ap = display.CENTER, tag = 35, enable = false })
	unionPanel:addChild(unonIconResultImage)
	unonIconResultImage:setVisible(false)

	local unionName = newLabel(64, -15,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 28, tag = 36 })
	unionPanel:addChild(unionName)
	unionPanel:setScale(0.8)
	return {
		unionPanel = unionPanel ,
		unionName = unionName ,
		unonIconImage = unonIconImage ,
		unonIconResultImage = unonIconResultImage ,
	}
end

function UnionWarsResultView:UpdateUnionNode(unionNode  , unionData )
	local unionName = unionData.unionName
	local unionAvatar = unionData.unionAvatar
	display.commonLabelParams(unionNode.unionName, {text = unionName})
	unionNode.unonIconImage:setTexture(CommonUtils.GetGoodsIconPathById(unionAvatar))
	unionNode.unonIconResultImage:setVisible(unionData.isResult == 1)
end

function UnionWarsResultView:UpdateAttackLabel(isResult )
	local isResult = checkint(isResult)
	local text = nil
	local color = nil
	if isResult == 1 then
		text = __('进攻成功')
		color = "#ffd736"
	else
		text = __('进攻失败')
		color = "#ffffff"
	end
	display.commonLabelParams(self.viewData.attackResultLabel , {text = text , color = color})
end

function UnionWarsResultView:UpdateDefenceLabel(isResult)
	local isResult = checkint(isResult)
	local text = nil
	local color = nil
	if isResult == 1 then
		text = __('防守失败')
		color = "#ffffff"
	else
		text = __('防守成功')
		color = "#ffd736"
	end
	display.commonLabelParams(self.viewData.defencesResultLabel , {text = text , color = color})
end
function UnionWarsResultView:EnterAction()
	local contentLayout = self.viewData.contentLayout
	local rewardLight = self.viewData.rewardLight
	contentLayout:runAction(
		cc.Sequence:create(
			cc.FadeIn:create(0.5) ,
			cc.CallFunc:create(
				function()
					rewardLight:runAction(
						cc.RepeatForever:create(
							cc.Spawn:create(
								cc.Sequence:create(
									cc.FadeTo:create(2.25,100),
									cc.FadeTo:create(2.25,255)
								),
								cc.RotateBy:create(4.5,180)
							)
						)
					)
				end
			)
		)

	)
end
return  UnionWarsResultView