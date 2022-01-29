--[[
探索系统更改编队界面
--]]
local ExplorationTeamView = class('ExplorationTeamView', function()
	local node = CLayout:create(display.size)
	node.name = 'common.ExplorationTeamView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function ExplorationTeamView:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData = nil
	local function CreateView()
		local size = (cc.size(display.width, 600))
		local view = CLayout:create(size)
		view:setAnchorPoint(0.5, 1)
		view:setPosition(cc.p(size.width/2, 260))
		self:addChild(view)
		-- mask
		local mask = CColorView:create(cc.c4b(0, 0, 0, 100))
		mask:setTouchEnabled(true)
		mask:setContentSize(cc.size(size.width, size.height-15))
		mask:setAnchorPoint(cc.p(0.5, 0))
		mask:setPosition(cc.p(size.width/2, 0))
		view:addChild(mask, -10)
		-- bg
		local bg = display.newImageView(_res('ui/common/discovery_ready_dg.png'), size.width/2, size.height/2, {scale9 = true, size = size})
		view:addChild(bg, -5)
		-- 顶部提示条
		local topTipsBg = display.newImageView(_res('ui/common/common_bg_float_text.png'), size.width/2, 554, {scale9 = true, size = cc.size(560, 35)})
		view:addChild(topTipsBg, 5)
		local topTipsLabel = display.newLabel(size.width/2, 554, {text = '', fontSize = 22, fontColor = '#ffffff'})
		view:addChild(topTipsLabel, 10)
		-- 编队背景
		local teamBg = display.newImageView(_res('ui/common/discovery_main_bg_team.png'), size.width/2, 410)
		view:addChild(teamBg, 5)
		-- 调整按钮
		local changeBtn = display.newButton(72 + display.SAFE_L, 500, {n = _res('ui/common/common_btn_orange.png'), tag = 1101})
		view:addChild(changeBtn, 10)
		display.commonLabelParams(changeBtn, fontWithColor(14, {text = __('调整')}))
		-- 队伍名称
		local teamNameLabel = display.newLabel(size.width/2 - 380, 502, fontWithColor(18, {text = '', ap = cc.p(0, 0.5)}))
		view:addChild(teamNameLabel, 10)
		-- 探索按钮
		local explorationBtn = require('common.CommonBattleButton').new({pattern = 3})
		explorationBtn:setPosition(cc.p(size.width - 100 - display.SAFE_L, 410))
		explorationBtn:setTag(1102)
		view:addChild(explorationBtn, 10)
		-- 队伍战斗力
		local pointBg = display.newImageView(_res('ui/common/maps_fight_bg_sword1.png'), size.width/2 + 400, 510, {ap = cc.p(1, 0.5)})
		view:addChild(pointBg, 10)
		local battlePoint = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
		battlePoint:setAnchorPoint(cc.p(1, 0.5))
		battlePoint:setHorizontalAlignment(display.TAR)
		battlePoint:setPosition(display.cx + 378, 503)
		view:addChild(battlePoint, 10)
		battlePoint:setScale(0.7)
		-- 切换按钮
		local switchBtnL = display.newButton(size.width / 2 - 448, 410, {n = _res('ui/common/battle_btn_fullstar.png'), tag = 1103})
		switchBtnL:setScaleX(-1)
		view:addChild(switchBtnL, 10)
		local switchBtnR = display.newButton(size.width / 2 + 448, 410, {n = _res('ui/common/battle_btn_fullstar.png'), tag = 1104})
		view:addChild(switchBtnR, 10)
		-- 选中标示
		local teamFormationDatas = gameMgr:GetUserInfo().teamFormation
		local dotDatas = {}
		local dotLayout = CLayout:create(cc.size((table.nums(teamFormationDatas)*2-1)*20, 20))
		dotLayout:setPosition(cc.p(size.width/2, 320))
		view:addChild(dotLayout, 10)
		for i = 1, table.nums(teamFormationDatas) do
			local dot = display.newImageView(_res('ui/common/maps_fight_ico_round_default.png'), 10+(i-1)*40, 10)
			dotLayout:addChild(dot, 10)
			table.insert(dotDatas, i, dot)
		end
		-- 喂食
		local bottomLayout = CLayout:create(cc.size(size.width, 260))
		bottomLayout:setAnchorPoint(cc.p(0.5, 0))
		bottomLayout:setPosition(cc.p(size.width/2, 0))
		view:addChild(bottomLayout ,10)
		local bottomBg = display.newImageView(_res('ui/iceroom/refresh_bg_foods.png'), size.width/2, 0, {ap = cc.p(0.5, 0)})
		bottomLayout:addChild(bottomBg)
		local plate = display.newImageView(_res('ui/iceroom/refresh_bg_goods.png'), size.width/2, 100)
		bottomLayout:addChild(plate, 5)
		local goodsDatas = {}
		for i,v in ipairs(VIGOUR_RECOVERY_GOODS_ID) do
			local goodsIcon = display.newImageView(_res('arts/goods/goods_icon_' .. tostring(v) .. '.png'), size.width/2+(i-2)*145 - 50, 165)
			bottomLayout:addChild(goodsIcon, 10)
			local numBg = display.newImageView(_res('ui/common/common_bg_number_1.png'), size.width/2+(i-2)*145 - 50, 85)
			bottomLayout:addChild(numBg, 10)
			local goodsNum = gameMgr:GetAmountByGoodId(v)
			local numLabel = display.newLabel(size.width/2+(i-2)*145-60, 85, fontWithColor(9, {text = goodsNum, tag = 2700+i}))
			bottomLayout:addChild(numLabel, 10)
			table.insert(goodsDatas, i, goodsIcon)
		end
		bottomLayout:setVisible(false)
		-- 快速回复
		local quickRecoveryBg = display.newImageView(_res('ui/common/discovery_ready_dg_2.png'),size.width - 100, 120)
		view:addChild(quickRecoveryBg, 10)
		local quickRecoveryBtn = display.newButton(size.width - 110, 100, {ap = cc.p(0.5, 0.5), n = _res('ui/common/common_btn_green.png')})
		view:addChild(quickRecoveryBtn, 10)
		local recoveryLabel = display.newLabel(size.width - 110, 150, fontWithColor(3, {text = __('恢复全队')}))
		view:addChild(recoveryLabel, 10)
		local recoveryIcon = display.newImageView(_res('ui/home/lobby/cooking/refresh_ico_quick_recovery.png'), 25, quickRecoveryBtn:getContentSize().height/2)
		quickRecoveryBtn:addChild(recoveryIcon, 10)
		local diamondNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '100')
		diamondNum:setAnchorPoint(cc.p(0.5, 0.5))
		diamondNum:setHorizontalAlignment(display.TAR)
		diamondNum:setPosition(64, 25)
		quickRecoveryBtn:addChild(diamondNum, 10)
		local diamondIcon = display.newImageView(_res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'),105, 30)
		quickRecoveryBtn:addChild(diamondIcon, 10)
		diamondIcon:setScale(0.2)
		-- 底部提示
		local bottomTipsLabel = display.newLabel(size.width/2, 18, fontWithColor(18, {text = __('拖拽飨果到对应飨灵，可恢复其新鲜度')}))
		bottomLayout:addChild(bottomTipsLabel, 10)
		local bottomIcon = display.newImageView(_res('ui/common/common_btn_tips.png'), size.width/2 - 210, 18)
		bottomLayout:addChild(bottomIcon, 10)
		-- 箭头动画
		for i = 1, 3 do
			bottomLayout:runAction(
				cc.Sequence:create(
					cc.DelayTime:create(0.4 - 0.1*i),
					cc.CallFunc:create(function ()
						local arrow = display.newImageView(_res('ui/common/discovery_ico_arrow_up.png'), size.width/2, 285 - i*20)
						bottomLayout:addChild(arrow, 10)
						arrow:setOpacity(0)
						arrow:runAction(
							cc.RepeatForever:create(
								cc.Sequence:create(
									cc.FadeIn:create(0.2),
									cc.DelayTime:create(1),
									cc.FadeOut:create(0.2),
									cc.DelayTime:create(0.4)
								)

							)
						)
					end)
				)
			)
		end
		-- tips
		local tipsBtn = display.newButton(size.width/2 - 405, 504, {n = _res('ui/common/common_btn_tips.png'), tag = 1105})
		view:addChild(tipsBtn, 10)
		tipsBtn:setVisible(false)

		return {
			view             = view,
			size     	     = size,
			dotDatas         = dotDatas,
			switchBtnL       = switchBtnL,
			switchBtnR       = switchBtnR,
			battlePoint      = battlePoint,
			changeBtn        = changeBtn,
			explorationBtn   = explorationBtn,
			bottomLayout     = bottomLayout,
			goodsDatas       = goodsDatas,
			dotLayout        = dotLayout,
			teamNameLabel    = teamNameLabel,
			quickRecoveryBtn = quickRecoveryBtn,
			tipsBtn          = tipsBtn,
			diamondNum       = diamondNum,
			topTipsLabel     = topTipsLabel
		}
	end
	xTry(function ( )
		-- eaterLayer
		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
		eaterLayer:setTouchEnabled(true)
		eaterLayer:setContentSize(display.size)
		eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
		eaterLayer:setPosition(cc.p(display.cx, display.height))
		self:addChild(eaterLayer, -10)
		self.eaterLayer = eaterLayer
		self.viewData_ = CreateView( )
	end, __G__TRACKBACK__)
end

return ExplorationTeamView
