--[[
战斗场景
--]]
local GameScene = require( "Frame.GameScene" )
local BattleScene = class("BattleScene", GameScene)

------------ import ------------
------------ import ------------

------------ define ------------
-- 屏幕振动的action tag
local ShakeWorldActionTag = 3715
local TargetBgBaseSize = cc.size(100, 70)

-- 全局buff
local GlobalEffectIconSize = cc.size(50, 50)
------------ define ------------

--[[
constructor
--]]
function BattleScene:ctor(...)

	local args = unpack({...})

	GameScene.ctor(self,'battle.view.BattleScene')
	self.contextName = "battle.view.BattleScene"

	self.bgId = args.backgroundId
	self.weatherId = args.weatherId
	self.questBattleType = args.questBattleType
	self.friendTeams = args.friendTeams
	self.enemyTeams = args.enemyTeams

	self.battleLayer = nil
	self:InitValue()
	self:InitUI()

	AppFacade.GetInstance():DispatchObservers('BATTLE_SCENE_CREATE_OVER', {battleScene = self})
	
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
init value
--]]
function BattleScene:InitValue()
	-- 初始化记录战斗模块显示的数据
	self.battleFunctionModuleVisible = {}
	for k,v in pairs(ConfigBattleFunctionModuleType) do
		self.battleFunctionModuleVisible[v] = true
	end

	-- 存活模式l界面上显示的倒计时
	self.aliveCountdown = nil
end
--[[
init ui
--]]
function BattleScene:InitUI()

	local function CreateView()
		local actionButtons = {}

		local fieldLayer = display.newLayer(0, 0, {size = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)})
		display.commonUIParams(fieldLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.SAFE_CX,
			display.SAFE_CY
		)})
		self.childDatas.gameNode:addChild(fieldLayer, BATTLE_E_ZORDER.BATTLE_LAYER)

		------------ bg group ------------
		local mapId = self.bgId
		local bgIdx = 10

		-- 处理地图文件夹路径
		local bgPathPrefix = BattleUtils.GetBgFolderPath(mapId)

		-- 处理文件路径
		local bgPath = string.format('%s/%s', bgPathPrefix, 'main_map_bg_%d_%d')

		-- 初始化参数
		local bgDesignSize = cc.size(1334, 1002)
		local bgSize = bgDesignSize
		local bgScaleX = display.width / bgSize.width
		local bgScaleY = bgScaleX
		if display.height > bgSize.height * bgScaleY then
			bgScaleY = display.height / bgSize.height
			bgScaleX = bgScaleY
		end

		-- 创建地图图片的父节点
		-- 地图层父节点
		local mainMapLayer = display.newLayer(0, 0, {size = bgSize})
		mainMapLayer:setScaleX(bgScaleX)
		mainMapLayer:setScaleY(bgScaleY)
		display.commonUIParams(mainMapLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(fieldLayer)})

		-- 背景层父节点
		local bgLayer = display.newLayer(0, 0, {size = bgSize})
		bgLayer:setScaleX(bgScaleX)
		bgLayer:setScaleY(bgScaleY)
		display.commonUIParams(bgLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(fieldLayer)})
		fieldLayer:addChild(bgLayer, BATTLE_E_ZORDER.BATTLE_LAYER - 1)

		-- 前景层父节点
		local fgLayer = display.newLayer(0, 0, {size = bgSize})
		fgLayer:setScaleX(bgScaleX)
		fgLayer:setScaleY(bgScaleY)
		display.commonUIParams(fgLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(fieldLayer)})
		fieldLayer:addChild(fgLayer, BATTLE_E_ZORDER.BATTLE_LAYER + 2)

		local function CreateBgImage(path, mapId, bgIdx)
			-- 检查静态图是否存在
			local image = nil
			local imagePath = path .. '.png'
			local isSpine = false

			if utils.isExistent(_res(imagePath)) then

				image = display.newImageView(_res(imagePath), 0, 0)

			elseif utils.isExistent(_res(path .. '.json')) then

				-- 不存在图片但是存在spine动画
				-- image = sp.SkeletonAnimation:create(
				-- 	path .. '.json',
				-- 	path .. '.atlas',
				-- 	1
				-- )

				image = SpineCache(SpineCacheName.BATTLE):createWithName(BattleUtils.GetBgSpineCacheName(mapId, bgIdx))
				image:update(0)
				image:setAnimation(0, sp.AnimationName.idle, true)

			end
			return image, isSpine
		end

		-- 创建中景图片
		local sceneSpineNodes = {}
		local mainField = CreateBgImage(string.format(bgPath, mapId, bgIdx), mapId, bgIdx)
		if nil ~= mainField then
			display.commonUIParams(mainField, {po = utils.getLocalCenter(mainMapLayer)})
			-- /***********************************************************************************************************************************\
			--  * 为了实现人物和地板层一起抖动 将地板层加到人物的父节点
			mainMapLayer:addChild(mainField, BATTLE_E_ZORDER.BATTLE_LAYER)
			-- \***********************************************************************************************************************************/

			if BattleUtils.IsSpineNode(mainField) then
				table.insert(sceneSpineNodes, mainField)
			end
		end

		-- 创建前景图片
		local i = bgIdx
		while true do
			i = i + 1
			local fg = CreateBgImage(string.format(bgPath, mapId, i), mapId, i)
			print(fg, string.format(bgPath, mapId, i))
			if nil ~= fg then
				display.commonUIParams(fg, {po = cc.p(mainField:getPositionX(), mainField:getPositionY())})
				fgLayer:addChild(fg, i)

				if BattleUtils.IsSpineNode(fg) then
					table.insert(sceneSpineNodes, fg)
				end
			else
				break
			end
		end

		-- 创建背景图片
		local i = bgIdx
		while true do
			i = i - 1
			local bg = CreateBgImage(string.format(bgPath, mapId, i), mapId, i)
			if nil ~= bg then
				display.commonUIParams(bg, {po = cc.p(mainField:getPositionX(), mainField:getPositionY())})
				bgLayer:addChild(bg, i)

				if BattleUtils.IsSpineNode(bg) then
					table.insert(sceneSpineNodes, bg)
				end
			else
				break
			end
		end
		------------ bg group ------------

		-- battle layer
		-- local battleLayer = display.newLayer(mainField:getPositionX(), mainField:getPositionY(), {size = mainField:getContentSize(), ap = mainField:getAnchorPoint()})
		-- 战斗区域是大小定死的矩形 @see BattleLogicManager:InitBattleConfig
		local battleLayer = display.newLayer(0, 0, {size = cc.size(1334, 750)})
		display.commonUIParams(battleLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(fieldLayer)})
		-- battleLayer:setBackgroundColor(cc.c4b(128, 255, 255, 100))
		fieldLayer:addChild(battleLayer, BATTLE_E_ZORDER.BATTLE_LAYER)
		self.battleLayer = battleLayer
		-- battleLayer:setScale(0.5)

		-- /***********************************************************************************************************************************\
		--  * 为了实现人物和地板层一起抖动 将地板层加到人物的父节点
		mainMapLayer:setPosition(utils.getLocalCenter(battleLayer))
		battleLayer:addChild(mainMapLayer)
		-- \***********************************************************************************************************************************/

		-- effect layer
		local effectLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.7))
		effectLayer:setContentSize(display.size)
		effectLayer:setAnchorPoint(cc.p(0.5, 0.5))
		effectLayer:setPosition(utils.getLocalCenter(battleLayer))
		battleLayer:addChild(effectLayer, BATTLE_E_ZORDER.SPECIAL_EFFECT)
		effectLayer:setVisible(false)

		-- ui layer
		local uiSize = display.size
		local uiLayer = display.newLayer(display.cx, display.cy, {size = uiSize, ap = cc.p(0.5, 0.5)})
		self.childDatas.gameNode:addChild(uiLayer, BATTLE_E_ZORDER.UI)

		-- battle time label
		local battleTimeLabelPos = cc.p(uiSize.width * 0.5, uiSize.height - 35)
		local battleTimeLabel = CLabelBMFont:create(
			string.format('%0d:%02d', 0, 0),
			'font/battle_ico_time_1.fnt')
		battleTimeLabel:setBMFontSize(36)
		battleTimeLabel:setAnchorPoint(cc.p(0.5, 0.5))
		battleTimeLabel:setPosition(battleTimeLabelPos)
		uiLayer:addChild(battleTimeLabel)

		-- top battle info 
		local battleInfoBg = display.newImageView(_res('ui/battle/battle_bg_wave.png'), 0, 0) 
		display.commonUIParams(battleInfoBg, {po = cc.p(display.SAFE_R - battleInfoBg:getContentSize().width * 0.5, battleTimeLabelPos.y + 5)})
		uiLayer:addChild(battleInfoBg)

		-- wave 
		local waveLabel = CLabelBMFont:create(
			string.format('%d:%d', 0, 0),
			'font/battle_ico_time_3.fnt')
		waveLabel:setBMFontSize(30)
		waveLabel:setAnchorPoint(cc.p(1, 0.5))
		waveLabel:setPosition(cc.p(battleInfoBg:getContentSize().width - 10, battleInfoBg:getContentSize().height * 0.5 - 5))
		battleInfoBg:addChild(waveLabel)

		local waveIcon = nil
		if BattleConfigUtils:UseElexLocalize() or BattleConfigUtils:UseJapanLocalize() then
			waveIcon = display.newLabel(
				waveLabel:getPositionX() - waveLabel:getContentSize().width, waveLabel:getPositionY() + 4,
				fontWithColor(4, {ap = display.RIGHT_CENTER, text = __('回合'), fontSize = 28, color = '#f5f0d8', outlinesize = 2, outline = '#5b3c25'})
			)
	        waveIcon:setAlignment(cc.TEXT_ALIGNMENT_RIGHT)
	    else
	    	waveIcon = display.newNSprite(_res('ui/battle/battle_ico_wave.png'), 0, 0)
			display.commonUIParams(waveIcon, {ap = cc.p(1, 0.5), po = cc.p(
				waveLabel:getPositionX() - waveLabel:getContentSize().width,
				waveLabel:getPositionY() + 4
			)})
		end
        battleInfoBg:addChild(waveIcon)

		-- weather
		local weatherIcons = {}
		if nil ~= self.weatherId then
			local weatherId = nil
			local weatherBtnScale = 0.35
			local pos = cc.p(display.cx, battleInfoBg:getPositionY())
			for i,v in ipairs(self.weatherId) do
				weatherId = checkint(v)
				local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
				local weatherBtnBg = display.newNSprite(_res('ui/battle/battle_bg_weather.png'), 0, 0)
				pos.x = uiSize.width * 0.5 - battleTimeLabel:getContentSize().width * 0.5 - (weatherBtnBg:getContentSize().width * 0.5) - (i - 1) * (weatherBtnBg:getContentSize().width + 5)
				display.commonUIParams(weatherBtnBg, {po = pos})
				uiLayer:addChild(weatherBtnBg)

				table.insert(weatherIcons, weatherBtnBg)

				local weatherBtn = display.newButton(pos.x, pos.y, {
					n = _res(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
					cb = function (sender)
						-- 判断是否可以触摸
						if not G_BattleRenderMgr:IsBattleTouchEnable() then return end

						app.uiMgr:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
					end
				})
				weatherBtn:setScale(weatherBtnScale)
				uiLayer:addChild(weatherBtn)
			end
		end

		-- pause btn
		local pauseButton = display.newButton(0, 0, {n = _res('ui/battle/battle_btn_stop.png')})
		display.commonUIParams(pauseButton, {po = cc.p(display.SAFE_L + 15 + pauseButton:getContentSize().width * 0.5, uiSize.height - 15 - pauseButton:getContentSize().height * 0.5)})
		uiLayer:addChild(pauseButton)
		pauseButton:setTag(1001)
		table.insert(actionButtons, pauseButton)

		-- accelerate btn
		local accelerateButton = display.newButton(0, 0, {n = _res('ui/battle/battle_btn_accelerate_1.png')})
		display.commonLabelParams(accelerateButton, fontWithColor(19, {fontSize = 34, offset = cc.p(0,-18)}))
		display.commonUIParams(accelerateButton, {po = cc.p(
			display.SAFE_L + 4 + accelerateButton:getContentSize().width * 0.5,
			13 + accelerateButton:getContentSize().height * 0.5 - 5)})
		uiLayer:addChild(accelerateButton, 5)
		accelerateButton:setTag(1002)
		table.insert(actionButtons, accelerateButton)

		-- 屏蔽触摸层
		local eaterLayer = display.newLayer(0, 0, {size = display.size, ap = cc.p(0, 0), color = '#ffffff', enable = true})
		eaterLayer:setOpacity(0)
		self.childDatas.gameNode:addChild(eaterLayer, BATTLE_E_ZORDER.UI + 1)

		-- debug --
		if 2 == DEBUG then
			local debugBattleFolderLabel = display.newLabel(0, 0, fontWithColor('2', {text = __('当前使用新战斗')}))
			display.commonUIParams(debugBattleFolderLabel, {ap = cc.p(0, 1), po = cc.p(
				pauseButton:getPositionX(),
				pauseButton:getPositionY() - 50
			)})
			uiLayer:addChild(debugBattleFolderLabel)
		end
		-- debug --

		-- debug btn --
		-- debugmark = 1
		-- isscaleing = false
		-- local debugBtn = display.newButton(0, 0, {n = _res('ui/battle/battle_btn_stop.png'), cb = function (sender)
		-- 	cc.Director:getInstance():getScheduler():setTimeScale(1)
		-- 	if not isscaleing then

		-- 		local staticShakeTime = 1
		-- 		local scaleTime = 1.75
		-- 		debugmark = 1.5 - debugmark
		-- 		local scale = debugmark

		-- 		local fgShakeAction = cc.Sequence:create(
		-- 			ShakeAction:create(staticShakeTime + scaleTime, 20, 10)
		-- 		)
		-- 		fgLayer:runAction(fgShakeAction)

		-- 		local bgShakeAction = cc.Sequence:create(
		-- 			ShakeAction:create(staticShakeTime + scaleTime, 10, 5)
		-- 		)
		-- 		bgLayer:runAction(bgShakeAction)

		-- 		local battleLayerShakeAction = cc.Sequence:create(
		-- 			ShakeAction:create(staticShakeTime + scaleTime, 15, 7)
		-- 		)
		-- 		battleLayer:runAction(battleLayerShakeAction:clone())

		-- 		local sceneActionSeq = cc.Sequence:create(
		-- 			cc.DelayTime:create(staticShakeTime),
		-- 			cc.EaseIn:create(cc.ScaleTo:create(scaleTime, scale), 3)
		-- 		)
		-- 		fieldLayer:runAction(sceneActionSeq)

		-- 	end
		-- end})
		-- display.commonUIParams(debugBtn, {po = cc.p(
		-- 	pauseButton:getPositionX(),
		-- 	pauseButton:getPositionY() - pauseButton:getContentSize().height - 20
		-- )})
		-- pauseButton:getParent():addChild(debugBtn)
		-- debug btn --
		
		return {
			fieldLayer = fieldLayer,
			mainMapLayer = mainMapLayer,
			bgLayer = bgLayer,
			fgLayer = fgLayer,
			mainField = mainField,
			battleLayer = battleLayer,
			battleTimeLabel = battleTimeLabel,
			waveLabel = waveLabel,
			waveIcon = waveIcon,
			actionButtons = actionButtons,
			accelerateButton = accelerateButton,
			pauseButton = pauseButton,
			effectLayer = effectLayer,
			uiLayer = uiLayer,
			eaterLayer = eaterLayer,
			battleInfoBg = battleInfoBg,
			weatherIcons = weatherIcons,
			targetDescrBg = nil,
			targetDescrBgArrow = nil,
			targetDescrBgSplitLine = nil,
			targetDescrLabel = nil,
			targetBtn = nil,
			aliveTimeBg = nil,
			aliveCountdownLabel = nil,
			globalEffectBuffIcons = {},
			friendTeamNodes = {},
			enemyTeamNodes = {},
			currentFriendTeamMark = nil,
			currentEnemyTeamMark = nil,
			connectButtons = {},
			sceneSpineNodes = sceneSpineNodes,
			screenRecordBtn = nil,
			recordLabel = nil,
			recordMark = nil
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
	
	self:PlayBattleBgm()

	self:InitStageClearTargetUI()

	-- 初始化录屏模块
	self:InitScreenRecord()
end
--[[
初始化过关目标
--]]
function BattleScene:InitStageClearTargetUI()
	local parentNode = self.viewData.uiLayer

	-- 目标按钮
	local waveBgRBPos = self:GetTargetPosByBorderPos(self.viewData.battleInfoBg, display.RIGHT_BOTTOM)
	local targetBtn = display.newButton(0, 0, {n = 'ui/battle/battletarget/battle_target_btn_target.png', cb = handler(self, self.StageClearBtnClickHandler)})
	display.commonUIParams(targetBtn, {po = cc.p(
		waveBgRBPos.x - targetBtn:getContentSize().width * 0.5 - 10 - 30,
		waveBgRBPos.y - targetBtn:getContentSize().height * 0.5 - 10
	)})
	parentNode:addChild(targetBtn, BATTLE_E_ZORDER.UI_CLEAR_TARGET)

	local targetBtnLabel = display.newLabel(0, 0,
		{text = __('目标'), fontSize = 22, color = '#fffbe2', ttf = true, font = TTF_GAME_FONT, outline = '#483635', outlineSize = 2})
	display.commonUIParams(targetBtnLabel, {po = utils.getLocalCenter(targetBtn)})
	targetBtn:addChild(targetBtnLabel)

	-- 详细描述层
	local targetDescrBg = display.newImageView(_res('ui/battle/battletarget/battle_target_bg_detail.png'), 0, 0,
		{scale9 = true, size = TargetBgBaseSize})
	display.commonUIParams(targetDescrBg, {ap = cc.p(1, 0.5), po = cc.p(
		targetBtn:getPositionX() + targetBtn:getContentSize().width * 0.5,
		targetBtn:getPositionY() - 3
	)})
	parentNode:addChild(targetDescrBg, BATTLE_E_ZORDER.UI_CLEAR_TARGET - 1)

	local targetDescrBgCY = targetDescrBg:getContentSize().height * 0.5 + 2

	local targetDescrBgArrow = display.newNSprite(_res('ui/battle/battletarget/battle_target_ico_back.png'), 0, 0)
	display.commonUIParams(targetDescrBgArrow, {po = cc.p(
		targetDescrBg:getContentSize().width - targetBtn:getContentSize().width - 10,
		targetDescrBgCY
	)})
	targetDescrBg:addChild(targetDescrBgArrow)

	local targetDescrBgSplitLine = display.newNSprite(_res('ui/battle/battletarget/battle_target_ico_line1.png'), 0, 0)
	display.commonUIParams(targetDescrBgSplitLine, {po = cc.p(
		targetDescrBgArrow:getPositionX() - targetDescrBgArrow:getContentSize().width,
		targetDescrBgArrow:getPositionY()
	)})
	targetDescrBg:addChild(targetDescrBgSplitLine)

	local targetDescrLabel = display.newLabel(0, 0, fontWithColor('18', {text = '测试测试测试测试测试'}))
	display.commonUIParams(targetDescrLabel, {ap = cc.p(0, 0.5), po = cc.p(
		20,
		targetDescrBgCY
	)})
	targetDescrBg:addChild(targetDescrLabel)

	self.viewData.targetBtn = targetBtn
	self.viewData.targetDescrBg = targetDescrBg
	self.viewData.targetDescrBgArrow = targetDescrBgArrow
	self.viewData.targetDescrBgSplitLine = targetDescrBgSplitLine
	self.viewData.targetDescrLabel = targetDescrLabel

end
--[[
初始化过关目标的倒计时模块
@params countdown int 倒计时 秒
--]]
function BattleScene:InitAliveStageClear(countdown)
	if nil == self.viewData.aliveTimeBg then
		local parentNode = self.viewData.uiLayer
		local targetBtnRBPos = self:GetTargetPosByBorderPos(self.viewData.targetBtn, display.RIGHT_BOTTOM)

		local aliveTimeBg = display.newImageView(_res('ui/battle/battletarget/battle_target_bg_time.png'), 0, 0)
		display.commonUIParams(aliveTimeBg, {po = cc.p(
			targetBtnRBPos.x - aliveTimeBg:getContentSize().width * 0.5,
			targetBtnRBPos.y - aliveTimeBg:getContentSize().height * 0.5 - 10
		)})
		parentNode:addChild(aliveTimeBg, BATTLE_E_ZORDER.UI_CLEAR_TARGET)

		local aliveLabel = display.newLabel(0, 0,
			{text = __('存活'), fontSize = 22, color = '#fffbe2', ttf = true, font = TTF_GAME_FONT, outline = '#483635', outlineSize = 2})
		display.commonUIParams(aliveLabel, {ap = cc.p(1, 1), po = cc.p(
			aliveTimeBg:getContentSize().width - 15,
			aliveTimeBg:getContentSize().height - 5
		)})
		aliveTimeBg:addChild(aliveLabel)

		local aliveCountdownLabel = CLabelBMFont:create(
			string.format('%d:%02d', 0, 0),
			'font/battle_ico_time_1.fnt')
		aliveCountdownLabel:setBMFontSize(28)
		aliveCountdownLabel:setAnchorPoint(cc.p(1, 0))
		aliveCountdownLabel:setPosition(cc.p(
			aliveLabel:getPositionX(),
			0
		))
		aliveTimeBg:addChild(aliveCountdownLabel)

		self.viewData.aliveTimeBg = aliveTimeBg
		self.viewData.aliveCountdownLabel = aliveCountdownLabel
	end

	self.viewData.aliveCountdownLabel:stopAllActions()

	local m = math.floor(countdown / 60)
	local s = math.floor(countdown - m * 60)
	self.viewData.aliveCountdownLabel:setString(string.format('%d:%02d', m, s))

	self.viewData.aliveTimeBg:setVisible(
		self:GetFunctionModuleVisible(ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET)
	)

	self.aliveCountdown = countdown
end
--[[
初始化车轮战ui
@params friendTeams list 友军队伍
@params enemyTeams list 敌军队伍
--]]
function BattleScene:InitTagMatchView(friendTeams, enemyTeams)
	local parentNode = self.viewData.uiLayer

	-- 创建友方阵容预览
	for teamIdx, teamInfo in ipairs(friendTeams) do
		local cardHeadBg = display.newImageView(_res('ui/battle/battletagmatch/3v3_fighting_head_bg.png'), 0, 0)
		display.commonUIParams(cardHeadBg, {po = cc.p(
			display.SAFE_L + cardHeadBg:getContentSize().width * 0.5 + 20,
			display.height * 0.5 + ((cardHeadBg:getContentSize().height + 10) * (#friendTeams * 0.5 - (teamIdx - 0.5)))
		)})
		parentNode:addChild(cardHeadBg, BATTLE_E_ZORDER.UI_TAGMATCH)

		local wipeOutMarkBg = display.newImageView(_res('ui/battle/battletagmatch/3v3_fighting_head_bg_die.png'), 0, 0)
		display.commonUIParams(wipeOutMarkBg, {po = utils.getLocalCenter(cardHeadBg)})
		cardHeadBg:addChild(wipeOutMarkBg, 10)
		wipeOutMarkBg:setVisible(false)

		local wipeOutMark = display.newNSprite(_res('ui/battle/battletagmatch/3v3_fighting_head_ico_die.png'), 0, 0)
		display.commonUIParams(wipeOutMark, {po = cc.p(
			wipeOutMarkBg:getContentSize().width * 0.5,
			wipeOutMarkBg:getContentSize().height * 0.5 + 15
		)})
		wipeOutMarkBg:addChild(wipeOutMark)

		local wipeOutLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('阵亡'), fontSize = 20, outline = '#5b3c25'}))
		display.commonUIParams(wipeOutLabel, {ap = cc.p(0.5, 1), po = cc.p(
			wipeOutMark:getPositionX(),
			wipeOutMark:getPositionY() - wipeOutMark:getContentSize().height * 0.5 - 5
		)})
		wipeOutMarkBg:addChild(wipeOutLabel)

		local cardHeadNode = nil
		for _, cardInfo in ipairs(teamInfo) do
			cardHeadNode = require('common.CardHeadNode').new({
				cardData = {
					cardId = cardInfo.cardId,
					level = cardInfo.level,
					breakLevel = cardInfo.breakLevel,
					skinId = cardInfo.skinId
				},
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
			cardHeadNode:setScale((cardHeadBg:getContentSize().width - 20) / cardHeadNode:getContentSize().width)
			display.commonUIParams(cardHeadNode, {po = utils.getLocalCenter(cardHeadBg)})
			cardHeadBg:addChild(cardHeadNode)
			break
		end

		self.viewData.friendTeamNodes[teamIdx] = {
			cardHeadBg = cardHeadBg,
			wipeOutMarkBg = wipeOutMarkBg,
			cardHeadNode = cardHeadNode
		}
	end

	for teamIdx, teamInfo in ipairs(enemyTeams) do
		local cardHeadBg = display.newImageView(_res('ui/battle/battletagmatch/3v3_fighting_head_bg.png'), 0, 0)
		display.commonUIParams(cardHeadBg, {po = cc.p(
			display.SAFE_R - cardHeadBg:getContentSize().width * 0.5 - 20,
			display.height * 0.5 + ((cardHeadBg:getContentSize().height + 10) * (#enemyTeams * 0.5 - (teamIdx - 0.5)))
		)})
		parentNode:addChild(cardHeadBg, BATTLE_E_ZORDER.UI_TAGMATCH)

		local wipeOutMarkBg = display.newImageView(_res('ui/battle/battletagmatch/3v3_fighting_head_bg_die.png'), 0, 0)
		display.commonUIParams(wipeOutMarkBg, {po = utils.getLocalCenter(cardHeadBg)})
		cardHeadBg:addChild(wipeOutMarkBg, 10)
		wipeOutMarkBg:setVisible(false)

		local wipeOutMark = display.newNSprite(_res('ui/battle/battletagmatch/3v3_fighting_head_ico_die.png'), 0, 0)
		display.commonUIParams(wipeOutMark, {po = cc.p(
			wipeOutMarkBg:getContentSize().width * 0.5,
			wipeOutMarkBg:getContentSize().height * 0.5 + 15
		)})
		wipeOutMarkBg:addChild(wipeOutMark)

		local wipeOutLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('阵亡'), fontSize = 20, outline = '#5b3c25'}))
		display.commonUIParams(wipeOutLabel, {ap = cc.p(0.5, 1), po = cc.p(
			wipeOutMark:getPositionX(),
			wipeOutMark:getPositionY() - wipeOutMark:getContentSize().height * 0.5 - 5
		)})
		wipeOutMarkBg:addChild(wipeOutLabel)

		local cardHeadNode = nil
		for _, cardInfo in ipairs(teamInfo) do
			cardHeadNode = require('common.CardHeadNode').new({
				cardData = {
					cardId = cardInfo.cardId,
					level = cardInfo.level,
					breakLevel = cardInfo.breakLevel,
					skinId = cardInfo.skinId
				},
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
			cardHeadNode:setScale((cardHeadBg:getContentSize().width - 20) / cardHeadNode:getContentSize().width)
			display.commonUIParams(cardHeadNode, {po = utils.getLocalCenter(cardHeadBg)})
			cardHeadBg:addChild(cardHeadNode)
			break
		end

		self.viewData.enemyTeamNodes[teamIdx] = {
			cardHeadBg = cardHeadBg,
			wipeOutMarkBg = wipeOutMarkBg,
			cardHeadNode = cardHeadNode
		}
	end

	-- 敌友方队伍特效
	local friendTeamMark = sp.SkeletonAnimation:create(
		'battle/effect/fight.json',
		'battle/effect/fight.atlas',
		1
	)
	friendTeamMark:update(0)
	friendTeamMark:setPosition(cc.p(
		self.viewData.friendTeamNodes[1].cardHeadBg:getPositionX(),
		self.viewData.friendTeamNodes[1].cardHeadBg:getPositionY()
	))
	parentNode:addChild(friendTeamMark, BATTLE_E_ZORDER.UI_TAGMATCH)
	friendTeamMark:setAnimation(0, 'idle', true)

	self.viewData.currentFriendTeamMark = friendTeamMark

	local enemyTeamMark = sp.SkeletonAnimation:create(
		'battle/effect/fight.json',
		'battle/effect/fight.atlas',
		1
	)
	enemyTeamMark:update(0)
	enemyTeamMark:setPosition(cc.p(
		self.viewData.enemyTeamNodes[1].cardHeadBg:getPositionX(),
		self.viewData.enemyTeamNodes[1].cardHeadBg:getPositionY()
	))
	parentNode:addChild(enemyTeamMark, BATTLE_E_ZORDER.UI_TAGMATCH)
	enemyTeamMark:setAnimation(0, 'idle', true)

	self.viewData.currentEnemyTeamMark = enemyTeamMark
end
--[[
初始化录像ui
--]]
function BattleScene:InitScreenRecord()
	if not BattleConfigUtils.IsScreenRecordEnable() then return end

	local posTargetNode = self.viewData.pauseButton
	local parentNode = posTargetNode:getParent()
	local zorder = posTargetNode:getLocalZOrder()

	local btnSize = cc.size(100, 100)

	local screenRecordBtn = display.newButton(0, 0, {size = btnSize, animate = true})
	display.commonUIParams(screenRecordBtn, {po = cc.p(
		posTargetNode:getPositionX() + 5,
		posTargetNode:getPositionY() - posTargetNode:getContentSize().height * 0.5 - btnSize.height * 0.5 - 20
	)})
	parentNode:addChild(screenRecordBtn, zorder)

	-- 录像机图标
	local recordIcon = display.newNSprite(_res('ui/battle/battle_btn_video_start.png'), 0, 0)
	display.commonUIParams(recordIcon, {po = cc.p(
		btnSize.width * 0.5,
		btnSize.height - recordIcon:getContentSize().height * 0.5
	)})
	screenRecordBtn:addChild(recordIcon)

	-- 录像机文字
	local recordLabel = display.newNSprite(_res('ui/battle/battle_btn_video_under_unlock.png'), 0, 0)
	local recordMark = display.newNSprite(_res('ui/battle/battle_ico_video_state_unlock.png'), 0, 0)
	local recordLabelSize = recordLabel:getContentSize()
	local recordMarkSize = recordMark:getContentSize()
	local totalW = recordLabelSize.width + recordMarkSize.width + 5
	display.commonUIParams(recordLabel, {po = cc.p(
		recordIcon:getPositionX() - totalW * 0.5 + recordLabelSize.width * 0.5,
		recordIcon:getPositionY() - recordIcon:getContentSize().height * 0.5 - 10 - math.max(recordLabelSize.height, recordMarkSize.height) * 0.5
	)})
	screenRecordBtn:addChild(recordLabel)

	display.commonUIParams(recordMark, {po = cc.p(
		recordIcon:getPositionX() + totalW * 0.5 - recordMarkSize.width * 0.5,
		recordLabel:getPositionY()
	)})
	screenRecordBtn:addChild(recordMark)

	self.viewData.screenRecordBtn = screenRecordBtn
	self.viewData.recordLabel = recordLabel
	self.viewData.recordMark = recordMark
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
抖屏幕
@params callback function 动作结束后的回调函数
@return duration number 执行动作的时间长短
--]]
function BattleScene:ShakeWorld(callback)
	local duration = 0.5
	local scene = cc.CSceneManager:getInstance():getRunningScene()

	local shakeAction = cc.Sequence:create(
		ShakeAction:create(duration, 20, 10),
		cc.CallFunc:create(function ()
			if nil ~= callback then
				callback()
			end
			-- 强制回复场景位置
			scene:setPosition(cc.p(0, 0))
		end)
	)
	shakeAction:setTag(ShakeWorldActionTag)

	scene:runAction(shakeAction)
	return duration
end
--[[
根据模块类型隐藏显示模块
@params battleFunctionModuleType ConfigBattleFunctionModuleType 战斗模块类型
@params show bool 是否显示
--]]
function BattleScene:ShowBattleFunctionModule(battleFunctionModuleType, show)
	if ConfigBattleFunctionModuleType.ACCELERATE_GAME == battleFunctionModuleType then

		-- 隐藏加速模块
		self.viewData.accelerateButton:setVisible(show)

	elseif ConfigBattleFunctionModuleType.PLAYER_SKILL == battleFunctionModuleType then

		-- 隐藏主角技模块
		G_BattleRenderMgr:ShowPlayerObjectView(show)

	elseif ConfigBattleFunctionModuleType.PAUSE_GAME == battleFunctionModuleType then

		-- 隐藏暂停模块
		self.viewData.pauseButton:setVisible(show)

	elseif ConfigBattleFunctionModuleType.WAVE == battleFunctionModuleType then

		-- 隐藏波数
		self.viewData.battleInfoBg:setVisible(show)

	elseif ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET == battleFunctionModuleType then

		-- 隐藏过关目标
		self.viewData.targetDescrBg:setVisible(show)
		self.viewData.targetBtn:setVisible(show)
		if nil ~= self.viewData.aliveTimeBg then
			self.viewData.aliveTimeBg:setVisible(show)
			self:StopAliveCountdown()
		end

	elseif ConfigBattleFunctionModuleType.CONNECT_SKILL == battleFunctionModuleType then

		-- 隐藏连携技
		G_BattleRenderMgr:ShowConnectObjectView(show)

	end
	self:SetFunctionModuleVisible(battleFunctionModuleType, show)
end
--[[
隐藏所有模块
--]]
function BattleScene:HideAllBattleFunctionModule()
	for k,v in pairs(ConfigBattleFunctionModuleType) do
		self:ShowBattleFunctionModule(v, false)
	end
end
--[[
显示ui
@params show bool 显示ui
--]]
function BattleScene:ShowUILayer(show)
	self.viewData.uiLayer:setVisible(show)
end
--[[
刷新过关条件
@params descr string 过关条件文字
--]]
function BattleScene:RefreshBattleClearTargetDescr(descr)
	self.viewData.targetDescrLabel:setString(descr)
	self:RefreshBattleClearTargetBgSize()
end
--[[
刷新过关条件底图大小
--]]
function BattleScene:RefreshBattleClearTargetBgSize()
	local labelSize = display.getLabelContentSize(self.viewData.targetDescrLabel)
	local fixedTargetSize = cc.size(
		math.max(TargetBgBaseSize.width, labelSize.width + TargetBgBaseSize.width + 10),
		TargetBgBaseSize.height
	)
	-- 设置底图大小
	self.viewData.targetDescrBg:setContentSize(fixedTargetSize)
	-- 刷新底图子节点坐标
	self.viewData.targetDescrLabel:setPositionX(20)
	self.viewData.targetDescrBgArrow:setPositionX(self.viewData.targetDescrBg:getContentSize().width - self.viewData.targetBtn:getContentSize().width - 10)
	self.viewData.targetDescrBgSplitLine:setPositionX(self.viewData.targetDescrBgArrow:getPositionX() - self.viewData.targetDescrBgArrow:getContentSize().width)
end
--[[
显示过关条件层
@params show bool 是否显示
--]]
function BattleScene:ShowStageClearView(show)
	self.viewData.targetDescrBg:setVisible(show)
end
--[[
过关条件是否显示
@return _ bool 过关条件是否显示
--]]
function BattleScene:IsStageClearViewShow()
	return self.viewData.targetDescrBg:isVisible()
end
--[[
显示过关条件
@params delayTime int 持续时间 秒
--]]
function BattleScene:AutoShowStageClearView(delayTime)
	if not self:GetFunctionModuleVisible(ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET) then return end

	self.viewData.targetDescrBg:stopAllActions()
	self:ShowStageClearView(true)
	local actionSeq = cc.Sequence:create(
		cc.DelayTime:create(delayTime),
		cc.CallFunc:create(function ()
			self:ShowStageClearView()
		end)
	)
	self.viewData.targetDescrBg:runAction(actionSeq)
end
--[[
开始刷新存活倒计时
--]]
function BattleScene:StartAliveCountdown()
	if nil ~= self.aliveCountdown and nil ~= self.viewData.aliveCountdownLabel then

		local interval = 1

		local countdownActionTag = 1001
		self.viewData.aliveCountdownLabel:stopActionByTag(countdownActionTag)

		-- local actionSeq = cc.RepeatForever:create(cc.Sequence:create(
		-- 	cc.DelayTime:create(interval),
		-- 	cc.CallFunc:create(function ()
		-- 		local countdown = math.max(0, math.ceil(self.aliveCountdown - interval))
		-- 		self.aliveCountdown = countdown
		-- 		local m = math.floor(countdown / 60)
		-- 		local s = math.floor(countdown - m * 60)
		-- 		self.viewData.aliveCountdownLabel:setString(string.format('%d:%02d', m, s))
		-- 	end)
		-- ))
		-- actionSeq:setTag(countdownActionTag)
		-- self.viewData.aliveCountdownLabel:runAction(actionSeq)

	end
end
--[[
结束刷新存活倒计时
--]]
function BattleScene:StopAliveCountdown()
	if nil ~= self.viewData.aliveCountdownLabel then
		self.viewData.aliveCountdownLabel:stopAllActions()
		self.aliveCountdown = nil
	end
end
--[[
刷新存活倒计时
@params countdown int 倒计时 秒
--]]
function BattleScene:RefreshAliveCountdown(countdown)
	if nil ~= self.viewData.aliveCountdownLabel then
		local m = math.floor(countdown / 60)
		local s = math.floor(countdown - m * 60)
		self.viewData.aliveCountdownLabel:setString(string.format('%d:%02d', m, s))
	end
end
--[[
根据类型隐藏附加的过关条件ui
@params completeType ConfigStageCompleteType 过关类型
--]]
function BattleScene:HideStageClearByStageCompleteType(completeType)
	if completeType == ConfigStageCompleteType.ALIVE then
		if nil ~= self.viewData.aliveTimeBg then
			self.viewData.aliveTimeBg:setVisible(
				self:GetFunctionModuleVisible(ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET)
			)
		end
	else
		if nil ~= self.viewData.aliveTimeBg then
			self.viewData.aliveTimeBg:setVisible(false)
			self:StopAliveCountdown()
		end
	end
end
--[[
根据技能id添加一个全局buff的技能图标
@params skillId int 技能id
--]]
function BattleScene:AddAGlobalEffect(skillId)
	-- if not self:GetGlobalEffectNodes(skillId) then
	if true then

		local skillIconPath = CardUtils.GetSkillIconBySkillId(skillId)
		if not utils.isExistent(_res(skillIconPath)) then return end

		local skillIconBtn = display.newButton(0, 0, {size = GlobalEffectIconSize, cb = function (sender)
			PlayAudioByClickNormal()
			-- 判断是否可以触摸
			if not G_BattleRenderMgr:IsBattleTouchEnable() then return end

			local skillId = sender:getTag()
			local skillConfig = CommonUtils.GetSkillConf(skillId)
			if nil ~= skillConfig then
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, title = skillConfig.name, descr = skillConfig.descr, type = 5})
			end
		end})
		self.viewData.uiLayer:addChild(skillIconBtn)
		skillIconBtn:setTag(skillId)

		local skillIcon = display.newImageView(_res(skillIconPath), 0, 0)
		display.commonUIParams(skillIcon, {po = utils.getLocalCenter(skillIconBtn)})
		skillIconBtn:addChild(skillIcon)

		skillIcon:setScale(GlobalEffectIconSize.width / skillIcon:getContentSize().width)

		local skillIconCover = display.newImageView(_res('ui/worldboss/home/world_boss_icon_skill_frame.png'), 0, 0)
		display.commonUIParams(skillIconCover, {po = utils.getLocalCenter(skillIcon)})
		skillIcon:addChild(skillIconCover)

		table.insert(self.viewData.globalEffectBuffIcons, {
			skillId = skillId,
			skillIconBtn = skillIconBtn
		})

		self:RefreshAllGlobalEffect()
		
	end
end
--[[
根据技能id移除一个全局buff的技能图标
@params skillId int 技能id
--]]
function BattleScene:RemoveAGlobalEffect(skillId)
	local nodes, index = self:GetGlobalEffectNodes(skillId)
	if nil ~= nodes then
		nodes.skillIconBtn:setVisible(false)
		nodes.skillIconBtn:runAction(cc.Sequence:create(
			cc.DelayTime:create(0.05),
			cc.RemoveSelf:create()
		))
		table.remove(self.viewData.globalEffectBuffIcons, index)

		self:RefreshAllGlobalEffect()
	end
end
--[[
根据技能id判断是否存在全局buff技能图标
@params skillId int 技能 id
--]]
function BattleScene:GetGlobalEffectNodes(skillId)
	for i,v in ipairs(self.viewData.globalEffectBuffIcons) do
		if skillId == v.skillId then
			return v, index
		end
	end
	return nil
end
--[[
重排所有全局buff图标
--]]
function BattleScene:RefreshAllGlobalEffect()
	local cellSize = cc.size(GlobalEffectIconSize.width + 15, GlobalEffectIconSize.height + 15)
	local cellPerLine = 4

	for i,v in ipairs(self.viewData.globalEffectBuffIcons) do
		display.commonUIParams(v.skillIconBtn, {po = cc.p(
			self.viewData.pauseButton:getPositionX() + self.viewData.pauseButton:getContentSize().width * 0.5 + 20 + (cellSize.width * (0.5 + (i - 1) % cellPerLine)),
			self.viewData.pauseButton:getPositionY() - cellSize.height * (math.floor((i - 1) / cellPerLine))
		)})
	end
end
--[[
刷新当前车轮战队伍状态
@params currentFriendTeamIndex int 当前友方队伍序号
@params currentEnemyTeamIndex int 当前敌方队伍序号
--]]
function BattleScene:RefreshTagMatchTeamStatus(currentFriendTeamIndex, currentEnemyTeamIndex)
	for i,v in ipairs(self.viewData.friendTeamNodes) do
		-- 阵亡显示
		v.wipeOutMarkBg:setVisible(i < currentFriendTeamIndex)
		-- 当前mark
		if currentFriendTeamIndex == i then
			self.viewData.currentFriendTeamMark:setPosition(cc.p(
				v.cardHeadBg:getPositionX(),
				v.cardHeadBg:getPositionY()
			))
		end
	end

	for i,v in ipairs(self.viewData.enemyTeamNodes) do
		-- 阵亡显示
		v.wipeOutMarkBg:setVisible(i < currentEnemyTeamIndex)
		-- 当前mark
		if currentEnemyTeamIndex == i then
			self.viewData.currentEnemyTeamMark:setPosition(cc.p(
				v.cardHeadBg:getPositionX(),
				v.cardHeadBg:getPositionY()
			))
		end
	end
end
--[[
暂停场景动画
--]]
function BattleScene:PauseScene()
	if nil ~= self.viewData.currentFriendTeamMark then
		self.viewData.currentFriendTeamMark:setTimeScale(0)
	end

	if nil ~= self.viewData.currentEnemyTeamMark then
		self.viewData.currentEnemyTeamMark:setTimeScale(0)
	end

	for i,v in ipairs(self.viewData.sceneSpineNodes) do
		v:setTimeScale(0)
	end
end
--[[
恢复场景动画
--]]
function BattleScene:ResumeScene()
	if nil ~= self.viewData.currentFriendTeamMark then
		self.viewData.currentFriendTeamMark:setTimeScale(1)
	end

	if nil ~= self.viewData.currentEnemyTeamMark then
		self.viewData.currentEnemyTeamMark:setTimeScale(1)
	end

	for i,v in ipairs(self.viewData.sceneSpineNodes) do
		v:setTimeScale(1)
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- bgm control end --
---------------------------------------------------

function BattleScene:PlayBattleBgm(sheetName, cueName)
	if not G_BattleRenderMgr then return end
	local defaultBGMInfo = G_BattleRenderMgr:GetDefaultBattleBGMInfo()
	local bgmCueName     = cueName or defaultBGMInfo.CUE_NAME
	local bgmSheetName   = sheetName or defaultBGMInfo.SHEET_NAME
	app.audioMgr:PlayBGMusic(bgmSheetName, bgmCueName)
end

---------------------------------------------------
-- bgm control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
战斗过关条件点击回调
--]]
function BattleScene:StageClearBtnClickHandler(sender)
	PlayAudioByClickNormal()
	self.viewData.targetDescrBg:stopAllActions()
	self:ShowStageClearView(not self:IsStageClearViewShow())
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取对应节点边界在父节点的修正坐标
@params targetNode cc.node 目标节点
@params borderPos cc.p 边界坐标
@return fixedPos cc.p 修正后的坐标
--]]
function BattleScene:GetTargetPosByBorderPos(targetNode, borderPos)
	-- 先计算左下原点
	local targetBoundingBox = targetNode:getBoundingBox()
	local targetOriPos = cc.p(
		targetNode:getPositionX() + targetBoundingBox.width * (-targetNode:getAnchorPoint().x),
		targetNode:getPositionY() + targetBoundingBox.height * (-targetNode:getAnchorPoint().y)
	)
	local fixedPos = cc.p(
		targetOriPos.x + targetBoundingBox.width * borderPos.x,
		targetOriPos.y + targetBoundingBox.height * borderPos.y
	)
	return fixedPos
end
--[[
模块是否可见
@params module ConfigBattleFunctionModuleType 模块类型
@return _ bool 是否可见
--]]
function BattleScene:GetFunctionModuleVisible(module)
	return self.battleFunctionModuleVisible[module]
end
--[[
设置模块是否可见
@params module ConfigBattleFunctionModuleType 模块类型
@params visible bool 是否可见
--]]
function BattleScene:SetFunctionModuleVisible(module, visible)
	self.battleFunctionModuleVisible[module] = visible
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

function BattleScene:onEnter()

end
function BattleScene:onCleanup()
	print('remove cache')
	SpineCache(SpineCacheName.BATTLE):clearCache()
	display.removeUnusedSpriteFrames()

	local sceneWorld = cc.CSceneManager:getInstance():getRunningScene()
	-- 恢复场景的action
	cc.Director:getInstance():getActionManager():resumeTarget(sceneWorld)
	-- 移除场景的振动action
	sceneWorld:stopActionByTag(ShakeWorldActionTag)
	-- 恢复一次场景位置
	sceneWorld:setPosition(cc.p(0, 0))

	-- 恢复一次全局加速和fps
	cc.Director:getInstance():getScheduler():setTimeScale(1)
	cc.Director:getInstance():setAnimationInterval(UI_FPS)

	-- 回收lua内存
	collectgarbage('collect')
	collectgarbage('collect')
	collectgarbage('collect')
end

return BattleScene
