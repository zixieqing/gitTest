--[[
工会狩猎活动主场景
--]]
local GameScene = require( "Frame.GameScene" )
local UnionHuntScene = class("UnionHuntScene", GameScene)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
------------ import ------------

------------ define ------------
local MaxChallengeTimes = 1

-- 唤醒消耗
local AwakeCostConfig = {
	goodsId = DIAMOND_ID,
	amount = 100
}
------------ define ------------

--[[
constructor
--]]
function UnionHuntScene:ctor(...)

	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.union.UnionHuntScene')

	self.beastsConfig = nil
	self.beastsData = nil
	self.unionLevel = nil

	self.selectedBeastIndex = nil
	self.grayFilter = nil

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function UnionHuntScene:InitUI()

	local function CreateView()
		local size = self:getContentSize()

		local eaterLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0, 0, 0, 0), animate = false, enable = true})
		display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(eaterLayer)

		local bg = display.newImageView(_res('ui/union/hunt/guild_activity_hunt_bg_l.jpg'), 0, 0)
		display.commonUIParams(bg, {po = cc.p(
			size.width * 0.5,
			size.height * 0.5
		)})
		self:addChild(bg)

		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = function (sender)
			PlayAudioByClickClose()
			AppFacade.GetInstance():DispatchObservers('CLOSE_UNION_HUNT')
		end})
		backBtn:setName('backBtn')
		display.commonUIParams(backBtn, {po = cc.p(
			display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30,
	    	display.size.height - 18 - backBtn:getContentSize().height * 0.5
		)})
		self:addChild(backBtn, 5)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'), enable = true, ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('工会狩猎'),reqW = 200, fontSize = 30, color = '473227',offset = cc.p(-10,-8)})
		self:addChild(tabNameLabel, 99)

		tabNameLabel:addChild(display.newImageView(_res('ui/common/common_btn_tips.png'), tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10))

		-- 初始化中间内容
		local centerBg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg.png'), 0, 0)
		local listViewFg = display.newImageView(_res('ui/union/hunt/guild_hunt_ico_label_fire.png'), 0, 0)
		local totalWidth = centerBg:getContentSize().width + listViewFg:getContentSize().width

		local centerLayer = display.newLayer(0, 0, {size = centerBg:getContentSize()})
		display.commonUIParams(centerLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.5 + totalWidth * 0.5 - centerBg:getContentSize().width * 0.5 - 20,
			size.height * 0.5 - 40
		)})
		self:addChild(centerLayer)
		-- centerLayer:setBackgroundColor(cc.c4b(0, 255, 65, 255))

		display.commonUIParams(centerBg, {po = cc.p(
			centerLayer:getContentSize().width * 0.5,
			centerLayer:getContentSize().height * 0.5
		)})
		centerLayer:addChild(centerBg, 1)

		local centerCover = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_inlight.png'), 0, 0)
		display.commonUIParams(centerCover, {po = cc.p(
			centerLayer:getContentSize().width * 0.5,
			centerLayer:getContentSize().height * 0.5
		)})
		centerLayer:addChild(centerCover, 10)

		display.commonUIParams(listViewFg, {po = cc.p(
			size.width * 0.5 - totalWidth * 0.5 + listViewFg:getContentSize().width * 0.5,
			centerLayer:getPositionY()
		)})
		self:addChild(listViewFg, 5)

		local centerCoverFrame = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_inlight_add.png'), 0, 0)
		display.commonUIParams(centerCoverFrame, {po = cc.p(
			centerCover:getPositionX(),
			centerCover:getPositionY()
		)})
		centerLayer:addChild(centerCoverFrame, 10)

		------------ 裁剪节点 ------------
		local spineClipNode = cc.ClippingNode:create()
		spineClipNode:setContentSize(centerCover:getContentSize())
		spineClipNode:setAnchorPoint(cc.p(0.5, 0.5))
		spineClipNode:setPosition(cc.p(
			centerLayer:getContentSize().width * 0.5,
			centerLayer:getContentSize().height * 0.5
		))
		centerLayer:addChild(spineClipNode, 5)

		local stencilLayer = display.newImageView(_res('ui/union/hunt/guile_hunt_bg_mask.png'), 0, 0)
		stencilLayer:setAnchorPoint(cc.p(0.5, 0.5))
		stencilLayer:setPosition(cc.p(spineClipNode:getContentSize().width * 0.5, spineClipNode:getContentSize().height * 0.5))
		spineClipNode:setAlphaThreshold(0)
		spineClipNode:setInverted(false)
		spineClipNode:setStencil(stencilLayer)
		------------ 裁剪节点 ------------

		local listViewBg = display.newImageView('ui/union/hunt/guild_hunt_bg_table.png', 0, 0)
		display.commonUIParams(listViewBg, {po = cc.p(
			listViewFg:getPositionX(),
			listViewFg:getPositionY()
		)})
		self:addChild(listViewBg)

		local listViewSize = cc.size(listViewBg:getContentSize().width, listViewBg:getContentSize().height - 75)
		local cellSize = cc.size(listViewSize.width, 155)

		local listView = CTableView:create(listViewSize)
		display.commonUIParams(listView, {ap = cc.p(0.5, 0.5), po = cc.p(
			listViewBg:getPositionX(),
			listViewBg:getPositionY() + 5
		)})
		self:addChild(listView, 1)

		listView:setSizeOfCell(cellSize)
		listView:setCountOfCell(0)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setDataSourceAdapterScriptHandler(handler(self, self.BeastListViewDataAdapter))
		-- listView:setBackgroundColor(cc.c4b(0, 128, 255, 100))

		return {
			tabNameLabel = tabNameLabel,
			listView = listView,
			------------ 中间内容 ------------
			centerLayer = centerLayer,
			centerCover = centerCover,
			spineClipNode = spineClipNode,
			centerBg = centerBg,
			mainBeastSpine = nil
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 弹出标题班
	local action = cc.Sequence:create(
		cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80))),
		cc.CallFunc:create(function ()
			display.commonUIParams(self.viewData.tabNameLabel, {cb = function (sender)
				uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION_HUNT)]})
			end})
		end)
	)
	self.viewData.tabNameLabel:runAction(action)

	-- 初始化中间版式的ui
	self:InitCenterUI()
end
--[[
初始化中间版式的ui
--]]
function UnionHuntScene:InitCenterUI()
	local centerLayer = self.viewData.centerLayer
	local centerCover = self.viewData.centerCover
	local spineClipNode = self.viewData.spineClipNode
	local layerSize = centerLayer:getContentSize()
	local borderW = 10
	local borderH = 4

	-- 伤害排名
	local damageRankingBtn = display.newButton(0, 0,
		{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), scale9 = true , cb = handler(self, self.DamageRankingBtnClickHandler)})
	display.commonLabelParams(damageRankingBtn, fontWithColor('18', {text = __('伤害排名') , paddingW = 10}))
	display.commonUIParams(damageRankingBtn, {ap = display.RIGHT_CENTER ,  po = cc.p(
		layerSize.width  - 27,
		layerSize.height - damageRankingBtn:getContentSize().height * 0.5 - 7
	)})

	centerLayer:addChild(damageRankingBtn, 20)

	------------ 顶部倒计时信息 ------------
	local killCountdownBg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_recovery_counttime.png'), 0, 0,
		{scale9 = true, size = cc.size(centerCover:getContentSize().width, 51)})
	display.commonUIParams(killCountdownBg, {po = cc.p(
		layerSize.width * 0.5,
		layerSize.height - killCountdownBg:getContentSize().height * 0.5 - borderH
	)})
	centerLayer:addChild(killCountdownBg, 15)

	local killCountdownDescrLabel = display.newLabel(0, 0, fontWithColor('18', {w  = 500 , hAlig = display.TAL ,  text = __('距离远古堕神血量恢复满血状态剩余:')}))
	display.commonUIParams(killCountdownDescrLabel, {ap = cc.p(1, 0.5), po = cc.p(
		killCountdownBg:getContentSize().width * 0.525,
		killCountdownBg:getContentSize().height * 0.5
	)})
	killCountdownBg:addChild(killCountdownDescrLabel)

	local killCountdownLabel = display.newLabel(0, 0, fontWithColor('7', {text = '2h2m2s', fontSize = 40 , reqW = 180 }))
	display.commonUIParams(killCountdownLabel, {ap = cc.p(0, 0.5), po = cc.p(
		killCountdownDescrLabel:getPositionX() + 5,
		killCountdownDescrLabel:getPositionY()
	)})
	killCountdownBg:addChild(killCountdownLabel)

	-- 幼崽预览
	local beastBabyIconBg = display.newImageView(_res('ui/common/common_frame_goods_1.png'), 0, 0, {enable = true, cb = handler(self, self.BeastBabyPreviewClickHandler)})
	display.commonUIParams(beastBabyIconBg, {po = cc.p(
		damageRankingBtn:getPositionX() -damageRankingBtn:getContentSize().width/2  ,
		damageRankingBtn:getPositionY() - damageRankingBtn:getContentSize().height * 0.5 - beastBabyIconBg:getContentSize().height * 0.5 - 20
	)})
	centerLayer:addChild(beastBabyIconBg, 21)

	local beastBabyIcon = display.newImageView(CardUtils.GetCardHeadPathByCardId(300061), 0, 0)
	local beastBabyIconScale = (beastBabyIconBg:getContentSize().width - 14) / beastBabyIcon:getContentSize().width
	beastBabyIcon:setScale(beastBabyIconScale)
	display.commonUIParams(beastBabyIcon, {po = utils.getLocalCenter(beastBabyIconBg)})
	beastBabyIconBg:addChild(beastBabyIcon)

	local beastBabyLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('首杀奖励') , w = 140 , hAlign = display.TAC }))
	display.commonUIParams(beastBabyLabel, {ap = cc.p(0.5, 1), po = cc.p(
		beastBabyIconBg:getPositionX(),
		beastBabyIconBg:getPositionY() - beastBabyIconBg:getContentSize().height * 0.5 - 5
	)})
	centerLayer:addChild(beastBabyLabel, 21)

	local beastBabyFg = display.newImageView(_res('ui/common/common_frame_mask.png'), 0, 0)
	display.commonUIParams(beastBabyFg, {po = cc.p(
		beastBabyIconBg:getPositionX(),
		beastBabyIconBg:getPositionY()
	)})
	centerLayer:addChild(beastBabyFg, 30)

	local beastBabyFgLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('已获得')}))
	display.commonUIParams(beastBabyFgLabel, {po = utils.getLocalCenter(beastBabyFg)})
	beastBabyFg:addChild(beastBabyFgLabel)
	------------ 顶部倒计时信息 ------------

	------------ 底部信息 ------------
	local bottomBg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_moster_info.png'), 0, 0)
	display.commonUIParams(bottomBg, {po = cc.p(
		layerSize.width * 0.5,
		borderH + bottomBg:getContentSize().height * 0.5
	)})
	centerLayer:addChild(bottomBg, 20)

	-- 底部等级
	local bottomBeastLevelLabel = display.newLabel(0, 0, fontWithColor('7', {text = '等级0', fontSize = 24}))
	display.commonUIParams(bottomBeastLevelLabel, {ap = cc.p(0, 0), po = cc.p(
		5,
		bottomBg:getContentSize().height - 40
	)})
	bottomBg:addChild(bottomBeastLevelLabel)

	local bottomBeastNameLabel = display.newLabel(0, 0, fontWithColor('7', {text = '等级等级等级等级', fontSize = 48}))
	display.commonUIParams(bottomBeastNameLabel, {ap = cc.p(0, 1), po = cc.p(
		bottomBeastLevelLabel:getPositionX(),
		bottomBeastLevelLabel:getPositionY() - 5
	)})
	bottomBg:addChild(bottomBeastNameLabel)

	-- 掉落
	local fixX = -15
	-- local dropDescrBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png'), cb = handler(self, self.RewardsHintBtnClickHandler)})
	-- display.commonUIParams(dropDescrBtn, {po = cc.p(
	-- 	bottomBg:getPositionX() - dropDescrBtn:getContentSize().width * 0.5 + fixX,
	-- 	bottomBg:getPositionY() + bottomBg:getContentSize().height * 0.5 - 22
	-- )})
	-- centerLayer:addChild(dropDescrBtn, 21)

	local dropDescrLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('参与奖励')}))
	display.commonUIParams(dropDescrLabel, {ap = cc.p(0.5, 0.5), po = cc.p(
		bottomBg:getPositionX(),
		bottomBg:getPositionY() + bottomBg:getContentSize().height * 0.5 - 22
	)})
	centerLayer:addChild(dropDescrLabel, 21)

	-- 战斗按钮
	local battleBtn = require('common.CommonBattleButton').new({pattern = 1, clickCallback = handler(self, self.HuntBtnClickHandler)})
	display.commonUIParams(battleBtn, {po = cc.p(
		layerSize.width - battleBtn:getContentSize().width * 0.5 - 10,
		bottomBg:getPositionY() + bottomBg:getContentSize().height * 0.5
	)})
	centerLayer:addChild(battleBtn, 22)

	-- 挑战次数
	local challengeTimesLabel = display.newLabel(0, 0, fontWithColor('3', {text = '(5/5)'}))
	display.commonUIParams(challengeTimesLabel, {ap = cc.p(1, 0.5), po = cc.p(
		battleBtn:getPositionX() + 35,
		battleBtn:getPositionY() - battleBtn:getContentSize().height * 0.5 - 5
	)})
	centerLayer:addChild(challengeTimesLabel, 21)

	-- 血条
	local hpBar = CProgressBar:create(_res('ui/union/hunt/guild_hunt_bg_loading_blood_l.png'))
	hpBar:setAnchorPoint(cc.p(0, 0.5))
	hpBar:setBackgroundImage(_res('ui/union/hunt/guild_hunt_bg_blood_l.png'))
	hpBar:setDirection(eProgressBarDirectionLeftToRight)
	hpBar:setPosition(cc.p(
		bottomBg:getPositionX() - bottomBg:getContentSize().width * 0.5 + 5,
		bottomBg:getPositionY() + bottomBg:getContentSize().height * 0.5 + hpBar:getContentSize().height * 0.5 + 5
	))
	centerLayer:addChild(hpBar, 20)

	local hpPercentLabel = display.newLabel(0, 0, fontWithColor('14', {text = '88.88%', fontSize = 22}))
	display.commonUIParams(hpPercentLabel, {po = cc.p(
		hpBar:getPositionX() + hpBar:getContentSize().width * 0.5,
		hpBar:getPositionY()
	)})
	centerLayer:addChild(hpPercentLabel, 21)

	local hpLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('当前血量'), color = '#eacbb9'}))
	display.commonUIParams(hpLabel, {ap = cc.p(0, 0), po = cc.p(
		hpBar:getPositionX() + 5,
		hpBar:getPositionY() + hpBar:getContentSize().height * 0.5
	)})
	centerLayer:addChild(hpLabel, 25)
	------------ 底部信息 ------------

	------------ 唤醒信息 ------------
	local awakeBg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_wake_up.png'), 0, 0)
	local awakeLayer = display.newLayer(0, 0, {size = awakeBg:getContentSize()})
	display.commonUIParams(awakeLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		bottomBg:getPositionX() + bottomBg:getContentSize().width * 0.5 - awakeBg:getContentSize().width * 0.5,
		bottomBg:getPositionY()
	)})
	centerLayer:addChild(awakeLayer, 30)

	display.commonUIParams(awakeBg, {po = utils.getLocalCenter(awakeLayer)})
	awakeLayer:addChild(awakeBg)

	local awakeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_green.png'), cb = handler(self, self.AwakeBtnClickHandler)})
	display.commonUIParams(awakeBtn, {po = cc.p(
		awakeLayer:getContentSize().width - 25 - awakeBtn:getContentSize().width * 0.5,
		awakeLayer:getContentSize().height * 0.5
	)})
	awakeLayer:addChild(awakeBtn)

	local awakeBtnSize = awakeBtn:getContentSize()

	-- 加速消耗
	local awakeIcon = display.newNSprite(_res('ui/home/lobby/cooking/refresh_ico_quick_recovery.png'), 0, 0)
	display.commonUIParams(awakeIcon, {po = cc.p(
		8 + awakeIcon:getContentSize().width * 0.5,
		awakeBtnSize.height * 0.5)})
	awakeBtn:addChild(awakeIcon)

	local costIconScale = 0.15
	local awakeCostIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(AwakeCostConfig.goodsId)), 0, 0)
	awakeCostIcon:setScale(costIconScale)
	display.commonUIParams(awakeCostIcon, {po = cc.p(
		awakeBtnSize.width - 5 - awakeCostIcon:getContentSize().width * 0.5 * costIconScale,
		awakeBtnSize.height * 0.5
	)})
	awakeBtn:addChild(awakeCostIcon)

	local awakeCostLabel = display.newLabel(0, 0,
		{text = 888, fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441', hAlign = display.TAR})
	display.commonUIParams(awakeCostLabel, {ap = cc.p(1, 0.5), po = cc.p(
		awakeCostIcon:getPositionX() - awakeCostIcon:getContentSize().width * 0.5 * costIconScale,
		awakeCostIcon:getPositionY()
	)})
	awakeBtn:addChild(awakeCostLabel)

	local awakeCountdownDescrLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('距离下一次苏醒剩余:')}))
	display.commonUIParams(awakeCountdownDescrLabel, {ap = cc.p(1, 0), po = cc.p(
		awakeBtn:getPositionX() - awakeBtn:getContentSize().width * 0.5 - 10,
		awakeLayer:getContentSize().height * 0.5 + 8
	)})
	awakeLayer:addChild(awakeCountdownDescrLabel)

	local awakeCountdownLabel = display.newLabel(0, 0, fontWithColor('7', {text = '2h2m2s', fontSize = 40}))
	display.commonUIParams(awakeCountdownLabel, {ap = cc.p(1, 1), po = cc.p(
		awakeBtn:getPositionX() - awakeBtn:getContentSize().width * 0.5 - 15,
		awakeLayer:getContentSize().height * 0.5 + 5
	)})
	awakeLayer:addChild(awakeCountdownLabel)
	------------ 唤醒信息 ------------

	self.viewData.killCountdownBg = killCountdownBg
	self.viewData.killCountdownDescrLabel = killCountdownDescrLabel
	self.viewData.killCountdownLabel = killCountdownLabel
	self.viewData.beastBabyIconBg = beastBabyIconBg
	self.viewData.beastBabyIcon = beastBabyIcon
	self.viewData.beastBabyFg = beastBabyFg
	self.viewData.bottomBg = bottomBg
	self.viewData.bottomBeastLevelLabel = bottomBeastLevelLabel
	self.viewData.bottomBeastNameLabel = bottomBeastNameLabel
	self.viewData.bottomDropGoodsNodes = {}
	self.viewData.challengeTimesLabel = challengeTimesLabel
	self.viewData.hpBar = hpBar
	self.viewData.hpLabel = hpLabel
	self.viewData.hpPercentLabel = hpPercentLabel
	self.viewData.battleBtn = battleBtn
	self.viewData.awakeLayer = awakeLayer
	self.viewData.awakeCountdownDescrLabel = awakeCountdownDescrLabel
	self.viewData.awakeCountdownLabel = awakeCountdownLabel
	self.viewData.dropDescrBtn = dropDescrBtn
	self.viewData.dropDescrLabel = dropDescrLabel
	self.viewData.awakeCountdownLabel = awakeCountdownLabel
	self.viewData.awakeCostLabel = awakeCostLabel

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
data adapter
--]]
function UnionHuntScene:BeastListViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local cellSize = self.viewData.listView:getSizeOfCell()
	local beastConfig = self:GetBeastConfigByIndex(index)
	local beastData = self:GetBeastDataById(checkint(beastConfig.id))

	local bg = nil
	local beastNameLabelBg = nil
	local beastNameLabel = nil
	local levelLabel = nil
	local titleLabel = nil
	local lockIcon = nil
	local lockLabel = nil
	local beastIcon = nil

	if nil == cell then
		cell = CTableViewCell:new()
		cell:setContentSize(cellSize)

		local cellBtn = display.newButton(0, 0, {size = cellSize, cb = handler(self, self.CellClickHandler)})
		display.commonUIParams(cellBtn, {po = cc.p(
			cellSize.width * 0.5,
			cellSize.height * 0.5
		)})
		cell:addChild(cellBtn)
		cellBtn:setTag(3)

		bg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_moster_lock.png'), 0, 0)
		display.commonUIParams(bg, {po = cc.p(
			cellSize.width * 0.5,
			cellSize.height * 0.5
		)})
		cell:addChild(bg)
		bg:setTag(5)

		local bgSize = bg:getContentSize()

		beastIcon = FilteredSpriteWithOne:create()
		beastIcon:setTexture(_res(self:GetBeastCellIconPathById(checkint(beastConfig.id))))
		beastIcon:setPosition(cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5
		))
		bg:addChild(beastIcon)
		beastIcon:setTag(13)

		beastNameLabelBg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_moster_name.png'), 0, 0)
		display.commonUIParams(beastNameLabelBg, {po = cc.p(
			bgSize.width * 0.5,
			12 + beastNameLabelBg:getContentSize().height * 0.5
		)})
		bg:addChild(beastNameLabelBg)
		beastNameLabelBg:setTag(3)

		beastNameLabel = display.newLabel(0, 0, fontWithColor('5', {text = tostring(beastConfig.name)}))
		display.commonUIParams(beastNameLabel, {po = cc.p(
			utils.getLocalCenter(beastNameLabelBg).x,
			utils.getLocalCenter(beastNameLabelBg).y - 2
		)})
		beastNameLabelBg:addChild(beastNameLabel)
		beastNameLabel:setTag(3)

		levelLabel = display.newLabel(0, 0, fontWithColor('16', {text = 'test'}))
		display.commonUIParams(levelLabel, {ap = cc.p(1, 1), po = cc.p(
			bgSize.width - 10,
			bgSize.height - 5
		)})
		bg:addChild(levelLabel)
		levelLabel:setTag(5)

		titleLabel = display.newLabel(0, 0,
			{text = 'testtt', fontSize = 22, color = '#ffeb44', ttf = true, font = TTF_GAME_FONT, outline = '#4e3838'})
		display.commonUIParams(titleLabel, {ap = cc.p(1, 0), po = cc.p(
			bgSize.width - 10,
			beastNameLabelBg:getPositionY() + beastNameLabelBg:getContentSize().height * 0.5
		)})
		bg:addChild(titleLabel)
		titleLabel:setTag(7)

		lockIcon = display.newNSprite(_res('ui/common/common_ico_lock.png'), 0, 0)
		display.commonUIParams(lockIcon, {po = cc.p(
			bgSize.width - 80,
			bgSize.height - 40
		)})
		bg:addChild(lockIcon)
		lockIcon:setTag(9)

		lockLabel = display.newLabel(0, 0, fontWithColor('6', {text = 'testlock'}))
		display.commonUIParams(lockLabel, {ap = cc.p(0.5, 1), po = cc.p(
			lockIcon:getPositionX(),
			lockIcon:getPositionY() - lockIcon:getContentSize().height * 0.5 - 2
		)})
		bg:addChild(lockLabel)
		lockLabel:setTag(11)

	else

		bg = cell:getChildByTag(5)
		beastNameLabelBg = bg:getChildByTag(3)
		beastNameLabel = beastNameLabelBg:getChildByTag(3)
		levelLabel = bg:getChildByTag(5)
		titleLabel = bg:getChildByTag(7)
		lockIcon = bg:getChildByTag(9)
		lockLabel = bg:getChildByTag(11)

		beastIcon = bg:getChildByTag(13)

	end

	local lock = not self:CheckBeastUnlock(checkint(beastConfig.id), self.unionLevel)

	local bgPath = 'ui/union/hunt/guild_hunt_bg_kill_moster.png'
	local nameLabelBg = 'ui/union/hunt/guild_hunt_bg_moster_name.png'
	local nameLabelColor = ccc3FromInt(fontWithColor('5').color)
	local titleLabelColor = ccc3FromInt('#ff5f34')
	local titleLabelStr = ''
	local levelStr = __('捕获中...')

	beastIcon:setTexture(self:GetBeastCellIconPathById(checkint(beastConfig.id)))

	if lock then
		bgPath = 'ui/union/hunt/guild_hunt_bg_moster_lock.png'
		nameLabelBg = 'ui/union/hunt/guild_hunt_bg_moster_name_lock.png'
		nameLabelColor = ccc3FromInt('#ffffff')

		if nil == self.grayFilter then
			self.grayFilter = GrayFilter:create()
		end
		beastIcon:setFilter(self.grayFilter)
	else
		beastIcon:clearFilter()
	end

	if nil ~= beastData and 1 == checkint(beastData.captured) then
		bgPath = 'ui/union/hunt/guild_hunt_bg_get_energy.png'

		titleLabelStr = __('掠夺能量')
		titleLabelColor = ccc3FromInt('#ffeb44')
		levelStr = string.format(__('等级:%d'), checkint(beastData.level))
	end

	bg:setTexture(_res(bgPath))
	beastNameLabelBg:setTexture(_res(nameLabelBg))
	beastNameLabel:setString(tostring(beastConfig.name))

	beastNameLabel:setColor(nameLabelColor)

	titleLabel:setString(titleLabelStr)
	titleLabel:setColor(titleLabelColor)
	titleLabel:setVisible(not lock)

	lockIcon:setVisible(lock)
	lockLabel:setVisible(lock)
	lockLabel:setString(string.format(__('工会%d级解锁'), checkint(beastConfig.openUnionLevel)))

	levelLabel:setString(levelStr)
	levelLabel:setVisible(not lock)

	cell:setTag(index)

	return cell
end
--[[
根据配表内容以及神兽信息刷新界面
@params beastsConfig list 格式化后的所有神兽信息
@params beastsData list 所有的神兽信息
@params unionLevel int 工会等级
@parmas initIndex int 初始化选中的序号
--]]
function UnionHuntScene:RefreshUI(beastsConfig, beastsData, unionLevel, initIndex)
	self.beastsConfig = beastsConfig
	self.beastsData = beastsData or {}
	self.unionLevel = unionLevel

	self:RefreshListView()

	self:RefreshCenterContentByIndex(initIndex or 1)
end
--[[
自动刷新界面信息的逻辑
@params beastsConfig list 格式化后的所有神兽信息
@params beastsData list 所有的神兽信息
@params unionLevel int 工会等级
--]]
function UnionHuntScene:AutoRefreshUI(beastsConfig, beastsData, unionLevel)
	self.beastsConfig = beastsConfig
	self.beastsData = beastsData or {}
	self.unionLevel = unionLevel

	-- 记录一些列表的数据
	self.viewData.listView:stopContainerAnimation()
	local offset = self.viewData.listView:getContentOffset()
	-- 刷新列表
	self:RefreshListView()
	-- 恢复列表
	self.viewData.listView:setContentOffset(offset)

	-- debug --
	local tmpIndex = self.selectedBeastIndex
	self.selectedBeastIndex = nil
	self:RefreshCenterContentByIndex(tmpIndex)
	-- debug --
end
--[[
刷新左侧神兽列表
--]]
function UnionHuntScene:RefreshListView()
	self.viewData.listView:setCountOfCell(#self.beastsConfig)
	self.viewData.listView:reloadData()
end
--[[
根据选中的cell index 刷新中间板
@params index int cell序号
--]]
function UnionHuntScene:RefreshCenterContentByIndex(index)
	if index == self.selectedBeastIndex then return end

	self.selectedBeastIndex = index

	local beastConfig = self:GetBeastConfigByIndex(index)
	-- 刷新神兽spine
	self:RefreshCenterSpineBySkinId(checkint(beastConfig.skinId))
	-- 刷新神兽配表信息
	self:RefreshCenterBeastDataById(checkint(beastConfig.id))
end
--[[
根据神兽id刷新中间神兽基础信息
@params id int 神兽id
--]]
function UnionHuntScene:RefreshCenterBeastDataById(id)
	local beastConfig = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.GODBEAST, id)
	local beastData = self:GetBeastDataById(id)
	local beastQuestConfig = CommonUtils.GetBeastQuestConfByIdAndLevel(id, checkint(beastData.level))
	local gotBaby = 1 == checkint(beastData.captured)
	local needAwake = (1 == checkint(beastData.captured)) and (0 < checkint(beastData.leftSeconds))

	if needAwake then
		PlayAudioClip(AUDIOS.UI.ui_shoutun_sleep.id)
	else
		PlayAudioClip(AUDIOS.UI.ui_shoutun_idle.id)
	end

	-- 等级
	self.viewData.bottomBeastLevelLabel:setString(string.format(__('等级%d'), checkint(beastData.level)))
	self.viewData.bottomBeastLevelLabel:setVisible(gotBaby)

	-- 神兽名字
	--self.viewData.bottomBeastNameLabel:setString(tostring(beastConfig.name))
	self.viewData.beastBabyFg:setVisible(gotBaby)
	display.commonLabelParams(self.viewData.bottomBeastNameLabel , {text = beastConfig.name , reqW = 300 })

	-- 唤醒样式
	self.viewData.awakeLayer:setVisible(needAwake)
	self.viewData.battleBtn:setVisible(not needAwake)
	self.viewData.challengeTimesLabel:setVisible(not needAwake)
	self.viewData.hpBar:setVisible(not needAwake)
	self.viewData.hpPercentLabel:setVisible(not needAwake)
	self.viewData.hpLabel:setVisible(not needAwake)
	-- self.viewData.dropDescrBtn:setVisible(not needAwake)
	self.viewData.dropDescrLabel:setVisible(not needAwake)

	if nil ~= self.viewData.mainBeastSpine then
		if needAwake then
			self.viewData.mainBeastSpine:setToSetupPose()
			self.viewData.mainBeastSpine:setAnimation(0, 'sleep', true)
		else
			self.viewData.mainBeastSpine:setToSetupPose()
			self.viewData.mainBeastSpine:setAnimation(0, 'idle', true)
		end
	end

	if gotBaby then
		-- 已击杀 刷新血条样式
		self.viewData.hpBar:setProgressImage(_res('ui/union/hunt/guild_hunt_bg_loading_energy_l.png'))
	else
		self.viewData.hpBar:setProgressImage(_res('ui/union/hunt/guild_hunt_bg_loading_blood_l.png'))
	end

	-- 可能掉落
	for i,v in ipairs(self.viewData.bottomDropGoodsNodes) do
		v:removeFromParent()
	end
	self.viewData.bottomDropGoodsNodes = {}

	local goodsNodeScale = 0.65
	local rewardsInfo = CommonUtils.GetBeastQuestRewards(checkint(beastQuestConfig.id), 1 == checkint(beastData.captured))
	local rewardsAmount = #rewardsInfo
	for i,v in ipairs(rewardsInfo) do
		local goodsNode = require('common.GoodNode').new({
			goodsId = checkint(v.goodsId),
			showAmount = v.showAmount,
			amount = checkint(v.num),
			callBack = function (sender)
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
		})
		goodsNode:setScale(goodsNodeScale)
		display.commonUIParams(goodsNode, {po = cc.p(
			self.viewData.bottomBg:getPositionX() + (i - 0.5 - rewardsAmount * 0.5) * (goodsNode:getContentSize().width * goodsNodeScale + 10),
			self.viewData.bottomBg:getPositionY() - 17
		)})
		goodsNode:setVisible(not needAwake)
		self.viewData.centerLayer:addChild(goodsNode, 26)

		table.insert(self.viewData.bottomDropGoodsNodes, goodsNode)
	end

	-- 刷新宝宝信息
	local beastBabyConfig = cardMgr.GetBeastBabyConfigByBeastId(id)
	local skinId = checkint(beastBabyConfig.skinId)
	local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
	self.viewData.beastBabyIconBg:setTexture(_res(string.format('ui/common/common_frame_goods_%d.png', checkint(beastBabyConfig.quality or 7))))
	self.viewData.beastBabyIcon:setTexture(headPath)
	self.viewData.beastBabyIcon:setScale((self.viewData.beastBabyIconBg:getContentSize().width - 14) / self.viewData.beastBabyIcon:getContentSize().width)

	-- 刷新倒计时
	self:RefreshBeastRefreshCountdown(checkint(beastData.leftSeconds), beastData.captured, beastData.level)

	-- 刷新剩余挑战次数
	self:RefreshChallengeTimes(checkint(beastData.leftHuntTimes), MaxChallengeTimes)

	-- 刷新神兽血条
	self:RefreshBeastHpBar(checknumber(beastData.remainHp), cardMgr.GetBeastTotalHpByIdAndLevel(checkint(id), checkint(beastData.level)))
end
--[[
刷新一次倒计时
--]]
function UnionHuntScene:RefreshCenterCountdown()
	local selectedBeastId = checkint(self:GetBeastConfigByIndex(self.selectedBeastIndex).id)
	local selectedBeastData = self:GetBeastDataById(selectedBeastId)

	self:RefreshBeastRefreshCountdown(
		checkint(selectedBeastData.leftSeconds),
		selectedBeastData.captured,
		checkint(selectedBeastData.level)
	)
end
--[[
刷新中间顶部的倒计时
@params leftTime int 刷新剩余秒数
@params captured int 是否捕获
@params level int 神兽当前等级
--]]
function UnionHuntScene:RefreshBeastRefreshCountdown(leftTime, captured, level)
	self.viewData.killCountdownBg:setVisible(0 == checkint(captured))
	local str = self:GetFormattedTimeStr(leftTime)
	--self.viewData.killCountdownLabel:setString(str)
	display.commonLabelParams(self.viewData.killCountdownLabel , {text = str , reqW = 200 })
	self.viewData.awakeCountdownLabel:setString(str)
	self:RefreshBeastRefreshCost(leftTime)
end
--[[
刷新中间消耗
@params leftTime int 刷新剩余秒数
--]]
function UnionHuntScene:RefreshBeastRefreshCost(leftTime)
	-- 一分钟一钻
	local min = math.ceil(leftTime / 60)
	self.viewData.awakeCostLabel:setString(tostring(min))
end
--[[
刷新剩余挑战次数
@params leftChallengeTimes int 剩余挑战次数
@params maxChallengeTimes int 最大挑战次数
--]]
function UnionHuntScene:RefreshChallengeTimes(leftChallengeTimes, maxChallengeTimes)
	self.viewData.challengeTimesLabel:setString(string.format(__('今日剩余参与次数：%d次'), leftChallengeTimes, maxChallengeTimes))
end
--[[
刷新神兽血条
@params curHp int 当前血量
@params totalHp int 总血量
--]]
function UnionHuntScene:RefreshBeastHpBar(curHp, totalHp)
	self.viewData.hpBar:setMaxValue(totalHp)
	self.viewData.hpBar:setValue(curHp)
	self.viewData.hpPercentLabel:setString(string.format('%s%%', tostring(math.max(0.01, math.ceil(curHp / totalHp * 10000) * 0.01))))
end
--[[
根据皮肤id刷新中间神兽spine
@params skinId int 皮肤id
--]]
function UnionHuntScene:RefreshCenterSpineBySkinId(skinId)
	local parentNode = self.viewData.spineClipNode
	if nil ~= self.viewData.mainBeastSpine then
		self.viewData.mainBeastSpine:removeFromParent()
		self.viewData.mainBeastSpine = nil
	end

	local spineNode = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.9})
	self.viewData.mainBeastSpine = spineNode
	spineNode:setScaleX(-1)
	spineNode:update(0)
	spineNode:setAnimation(0, 'idle', true)
	spineNode:setPosition(cc.p(
		parentNode:getContentSize().width * 0.5 + 100,
		100
	))
	parentNode:addChild(spineNode)

end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
cell 点击回调
--]]
function UnionHuntScene:CellClickHandler(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	-- 判断是否解锁
	local beastConfig = self:GetBeastConfigByIndex(index)
	local beastId = checkint(beastConfig.id)
	local unlock = self:CheckBeastUnlock(beastId, self.unionLevel)
	if not unlock then
		uiMgr:ShowInformationTips(__('神兽未解锁!!!'))
		return
	end
	self:RefreshCenterContentByIndex(index)
end
--[[
伤害排名点击回调
--]]
function UnionHuntScene:DamageRankingBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local beastId = self:GetCurrentSelectedBeastId()
	AppFacade.GetInstance():DispatchObservers('SHOW_UNION_BEAST_DAMAGE_RANKING', {beastId = beastId})
end
--[[
战斗按钮点击回调
--]]
function UnionHuntScene:HuntBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local beastId = self:GetCurrentSelectedBeastId()
	AppFacade.GetInstance():DispatchObservers('HUNT_UNION_BEAST', {beastId = beastId})
end
--[[
奖励提示按钮回调
--]]
function UnionHuntScene:RewardsHintBtnClickHandler(sender)
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('奖励'), descr = '...', type = 5})
end
--[[
加速按钮回调
--]]
function UnionHuntScene:AwakeBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local beastId = self:GetCurrentSelectedBeastId()
	AppFacade.GetInstance():DispatchObservers('AWAKE_UNION_BEAST', {beastId = beastId})
end
--[[
幼崽奖励预览
--]]
function UnionHuntScene:BeastBabyPreviewClickHandler(sender)
	PlayAudioByClickNormal()
	local beastId = self:GetCurrentSelectedBeastId()
	AppFacade.GetInstance():DispatchObservers('SHOW_UNION_BEAST_BABY_DETAIL', {beastId = beastId})
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据序号获取神兽配置
@params index int 序号
@return _ table 神兽配置
--]]
function UnionHuntScene:GetBeastConfigByIndex(index)
	return self.beastsConfig[index]
end
--[[
根据神兽id获取神兽信息
@params id int 神兽id
@params result table 神兽信息
--]]
function UnionHuntScene:GetBeastDataById(id)
	return self.beastsData[tostring(id)]
end
--[[
设置神兽数据
@params beastsData list 神兽数据
--]]
function UnionHuntScene:SetBeastsData(beastsData)
	self.beastsData = beastsData
end
--[[
根据神兽id获取神兽cell icon path
@params id int 神兽id
@params path string path
--]]
function UnionHuntScene:GetBeastCellIconPathById(id)
	local path = 'cards/beasticon/card_label_300065.png'
	local beastConfig = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.GODBEAST, id)
	if nil == beastConfig then
		return path
	else
		local skinConfig = CardUtils.GetCardSkinConfig(checkint(beastConfig.skinId))
		local drawId = tostring(skinConfig.drawId)
		path = string.format('cards/beasticon/card_label_%s.png', drawId)
	end
	return path
end
--[[
根据秒数获取格式化后的中文时间文字
@params second int 秒数
@return str string
--]]
function UnionHuntScene:GetFormattedTimeStr(second)
	local str = ''
	local d = math.floor(second / (3600 * 24))
	local h = math.floor((second - d * (3600 * 24)) / 3600)
	local m = math.floor((second - d * (3600 * 24) - h * 3600) / 60)
	if d > 0 then
		if h > 0 then
			str = string.format(__('%d天%d小时'), d, h)
		else
			str = string.format(__('%d天'), d)
		end
	else
		if h > 0 then
			str = string.format(__('%d小时'), h)
		else
			if second > 60 then
				str = string.format(__('%d分'), m)
			else
				str = string.format(__('%d秒'), second)
			end
		end
	end
	return str
end
--[[
获取当前选中的神兽id
@return _ int 当前选中的神兽id
--]]
function UnionHuntScene:GetCurrentSelectedBeastId()
	return checkint(self:GetBeastConfigByIndex(self.selectedBeastIndex).id)
end
--[[
根据神兽id 工会等级判断神兽是否解锁
@params beastId int 神兽id
@params unionLevel int 工会等级
@return _ bool 是否解锁
--]]
function UnionHuntScene:CheckBeastUnlock(beastId, unionLevel)
	local beastConfig = cardMgr.GetBeastConfig(beastId)
	if nil == beastConfig then
		return false
	else
		if unionLevel < checkint(beastConfig.openUnionLevel) or nil == self:GetBeastDataById(beastId) then
			return false
		end
	end
	return true
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function UnionHuntScene:onCleanup()
	StopAudioClip(AUDIOS.UI.name)
end

return UnionHuntScene
