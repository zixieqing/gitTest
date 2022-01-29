--[[
天城演武编辑队伍场景 (魔改版 PVCChangeTeamScene)
@params params table {
	teamData list 现有阵容
	title string 标题
	avatarTowards int 1 朝右 -1 朝左
	avatarShowType int 1 凹凸 2 平铺 
	teamChangeSingalName string 阵容变化回调信号
	teamTowards int 队伍朝向 1 朝右 -1 朝左
	battleTypeData table 与battleType关联的数据
	battleType int 1 不显示一些pvc专用的ui 2 天城演武
}
--]]
local GameScene = require( "Frame.GameScene" )
local TagMatchChangeTeamScene = class("TagMatchChangeTeamScene", GameScene)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function TagMatchChangeTeamScene:ctor(...)
	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.pvc.TagMatchChangeTeamScene')

    -- 当前的团队数据
    self.teamId = args.teamId or '1'
    self.teamDatas = args.teamDatas or {}
	self.teamData = clone(self.teamDatas[tostring(self.teamId)] or {})

	self.title = args.title or __('编辑队伍')
	self.avatarTowards = args.avatarTowards or 1
	self.avatarShowType = args.avatarShowType or 1
	self.teamTowards = args.teamTowards or 1
	self.teamChangeSingalName = args.teamChangeSingalName
	self.battleTypeData = args.battleTypeData or {}	
	self.battleType = args.battleType
	self.closeViewTipText = args.closeViewTipText
	
	self:InitUI()
	-- 注册信号回调
	self:RegisterSignal()

	-- 隐藏游戏顶栏
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function TagMatchChangeTeamScene:InitUI()
	local size = self:getContentSize()

	-- eater layer
	local eaterLayer = display.newLayer(0, 0, {color = cc.c4b(255, 0, 255, 0), size = size, enable = true})
	display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		size.width * 0.5,
		size.height * 0.5
	)})
	self:addChild(eaterLayer)

	-- 背景图
	local bg = display.newImageView(_res('ui/common/pvp_main_bg.jpg'), size.width/2, size.height/2, {isFull = true})
	self:addChild(bg)
	self.bg = bg

	-- 中间底
	local avatarBottom = display.newImageView(_res('ui/common/pvp_main_bg_vs.png'), 0, 0)
	display.commonUIParams(avatarBottom, {ap = display.CENTER_BOTTOM, po = cc.p(
		size.width * 0.5,
		size.height * 0.5 - 118
	)})
	self:addChild(avatarBottom)
	self.avatarBottom = avatarBottom
	-- 底色遮罩
	local cover = display.newLayer(0, 0, {size = self:getContentSize()})
	display.commonUIParams(cover, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
	self:addChild(cover)
	cover:setBackgroundColor(cc.c4b(0, 0, 0, 255 * 0.4))

	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = handler(self, self.BackBtnClickHandler)})
	backBtn:setName('backBtn')
	display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.size.height - 18 - backBtn:getContentSize().height * 0.5)})
	self:addChild(backBtn, 10)

	-- title
	local titleBg = display.newImageView(_res('ui/common/pvp_edit_subtitle.png'), 0, 0)
	display.commonUIParams(titleBg, {po = cc.p(
		size.width * 0.5,
		size.height - titleBg:getContentSize().height * 0.5
	)})
	self:addChild(titleBg, 100)

	local titleLabel = display.newLabel(0, 0, fontWithColor('19', {text = self.title}))
	display.commonUIParams(titleLabel, {po = cc.p(
		utils.getLocalCenter(titleBg).x,
		utils.getLocalCenter(titleBg).y + 23
	)})
	titleBg:addChild(titleLabel)
	-- 战斗力
	local battlePointBg = display.newImageView(_res('ui/common/pvp_edit_bg_gearscore.png'), 0, 0)	
	display.commonUIParams(battlePointBg, {po = cc.p(
		display.SAFE_R - battlePointBg:getContentSize().width * 0.5 + 60,
		size.height - 80
	)})
	self:addChild(battlePointBg, 10)

	local battlePointSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	battlePointSpine:update(0)
	battlePointSpine:setAnimation(0, 'huo', true)
	battlePointSpine:setPosition(cc.p(
		battlePointBg:getPositionX(),
		battlePointBg:getPositionY()
	))
	self:addChild(battlePointSpine, 10)

	local battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '0')
	battlePointLabel:setAnchorPoint(cc.p(0.5, 0.5))
	battlePointLabel:setHorizontalAlignment(display.TAC)
	battlePointLabel:setPosition(cc.p(
		battlePointSpine:getPositionX(),
		battlePointSpine:getPositionY() + 10
	))
	self:addChild(battlePointLabel, 10)
	battlePointLabel:setScale(0.7)

	self.battlePointLabel = battlePointLabel

	local avatarOriPos, avatarLocationInfo, teamMarkPosSign = self:GetAvatarPosConf(size)
	
	local p = nil
	self.avatarNodes = {}

	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local avatarBgPath = 'ui/common/tower_bg_team_base.png'
		p = avatarLocationInfo[i]
		if 1 == i then
			avatarBgPath = 'ui/common/tower_bg_team_base_cap.png'
		end
		local avatarBg = display.newImageView(_res(avatarBgPath),
			avatarOriPos.x + p.fixedPos.x,
			avatarOriPos.y + p.fixedPos.y)
		self:addChild(avatarBg, 20 + i % 2)

		local avatarLight = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
		display.commonUIParams(avatarLight, {po = cc.p(
			utils.getLocalCenter(avatarBg).x,
			utils.getLocalCenter(avatarBg).y + avatarLight:getContentSize().height * 0.5
		)})
		avatarBg:addChild(avatarLight, 10)

		-- 透明按钮
		local avatarBtn = display.newButton(0, 0, {size = cc.size(150, 200)})
		display.commonUIParams(avatarBtn, {po = cc.p(
			avatarBg:getPositionX(),
			avatarBg:getPositionY() + avatarBtn:getContentSize().height * 0.5
		), animate = false, cb = handler(self, self.AvatarBtnClickHandler)})
		avatarBg:getParent():addChild(avatarBtn, avatarBg:getLocalZOrder())
		avatarBtn:setTag(i)
		avatarBtn:setVisible(false)

		-- debug --
		-- local l = display.newLayer(avatarBtn:getPositionX(), avatarBtn:getPositionY(), {size = avatarBtn:getContentSize(), ap = avatarBtn:getAnchorPoint()})
		-- l:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))
		-- avatarBtn:getParent():addChild(l, avatarBtn:getLocalZOrder())
		-- debug --
		if 1 == i then
			-- 添加队长标记
			local captainMark = display.newNSprite(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
			display.commonUIParams(captainMark, {po = cc.p(
				avatarBg:getPositionX() + teamMarkPosSign * (avatarBg:getContentSize().width * 0.5 + 20),
				avatarBg:getPositionY() - 5
			)})
			captainMark:setName('captainMark')
			self:addChild(captainMark, 100)
		end

		self.avatarNodes[i] = {bg = avatarBg, avatarLight = avatarLight, avatarBtn = avatarBtn, avatarSpine = nil, connectSkillNode = nil}
	end
	
	self:EquipAllCard()

	-- 创建选人层
	local selectCardLayersize = cc.size(
		size.width,
		size.height * 0.45
	)
	local selectCardLayer = require('common.MultipleLineupSelectCardView').new({
		size = selectCardLayersize,
		-- selectedCards = self.teamData,
		teamDatas     = self.teamDatas,
		teamId        = self.teamId,
		teamChangeSingalName = self.teamChangeSingalName,
		battleType  = self.battleType  -- 战斗的类型
	})
	display.commonUIParams(selectCardLayer, {ap = cc.p(0.5, 0), po = cc.p(
		size.width * 0.5,
		0
	)})
	self:addChild(selectCardLayer, 10)
	
	self.selectCardLayer  = selectCardLayer
	self.titleBg          = titleBg
	self.battlePointBg    = battlePointBg
	self.battlePointSpine = battlePointSpine
	self.battlePointLabel = battlePointLabel
	-- debug --
	-- local testLayer = display.newLayer(0, 0, {size = cc.size(
	-- 	size.width,
	-- 	avatarBottom:getPositionY() - avatarBottom:getContentSize().height * 0.5)})
	-- testLayer:setBackgroundColor(cc.c4b(128, 128, 255, 100))
	-- display.commonUIParams(testLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, testLayer:getContentSize().height * 0.5)})
	-- self:addChild(testLayer, 999)
	-- debug --
	self:RefreshUIByBattleScriptType()
end
-- 根据相应的type 刷新UI
function TagMatchChangeTeamScene:RefreshUIByBattleScriptType()
	if self.battleType == BATTLE_SCRIPT_TYPE.MATERIAL_TYPE then
		self.titleBg:setVisible(false)
		self.bg:setTexture(_res('ui/home/materialScript/material_bg')) -- 设置背景颜色
		self.avatarBottom:setVisible(false)
		local x, y  =  self.selectCardLayer:getPosition()
	elseif self.battleType == BATTLE_SCRIPT_TYPE.TAG_MATCH then
		self.titleBg:setVisible(false)
		self.avatarBottom:setVisible(false)
		self.bg:setTexture(_res("ui/tagMatch/3v3_bg.png")) -- 设置背景颜色
		self.battlePointBg:setVisible(false)
		
		-- 重新设置 战力位置
		local size = self:getContentSize()
		display.commonUIParams(self.battlePointSpine, {po = cc.p(100, size.height - 170)})
		display.commonUIParams(self.battlePointLabel, {po = cc.p(100, size.height - 160)})

		-- 重新设置 节点坐标
		local isTeamRight = self.teamTowards == 1
		for i, avatarNode in ipairs(self.avatarNodes) do
			local bg = avatarNode.bg
			local index = isTeamRight and MAX_TEAM_MEMBER_AMOUNT - i + 1 or i
			local bgSize = bg:getContentSize()
			local goodParams = {index = i, goodNodeSize = bgSize, midPointX = size.width / 2 - 18, midPointY = size.height * 0.475, col = 5, maxCol = 5, scale = 1, goodGap = 30}
			display.commonUIParams(bg, {po = CommonUtils.getGoodPos(goodParams)})

			if i == 1 then
				local captainMark = self:getChildByName('captainMark')
				if captainMark then
					local teamMarkPosSign = isTeamRight and 1 or -1
					display.commonUIParams(captainMark, {po = cc.p(
						bg:getPositionX() + teamMarkPosSign * (bgSize.width * 0.5 + 20),
						bg:getPositionY() - 5
					)})
				end		
			end
		end

		-- todo  show 
		local view = require('Game.views.tagMatch.TagMatchChangeTeamView').new({
			battleTypeData = self.battleTypeData,
			teamDatas      = self.selectCardLayer:GetTeamDatas(),
			teamId         = self.teamId,
		})
		display.commonUIParams(view, {po = display.center, ap = display.CENTER})
		self:addChild(view, 100)
		self.tagMatchView = view
	end
end

-- 根据相应的type 刷新UI
function TagMatchChangeTeamScene:RefreshBattleScriptTypeUI(data)
	if self.battleType == BATTLE_SCRIPT_TYPE.TAG_MATCH then
		if self.tagMatchView then
			self.tagMatchView:setTeamId(data.newTeamId)
		end
	end
end

---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据序号 卡牌皮肤 刷新卡牌spine小人
@params teamIdx int 编队序号
@params skinId int 皮肤id
--]]
function TagMatchChangeTeamScene:RefreshAvatarSpine(teamIdx, skinId)
	local nodes = self.avatarNodes[teamIdx]
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:removeFromParent()
		self.avatarNodes[teamIdx].avatarSpine = nil
	end

	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(false)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(true)
	end

	------------ 卡牌spine小人 ------------
	local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
	avatarSpine:update(0)
	avatarSpine:setScaleX(self.avatarTowards)
	avatarSpine:setAnimation(0, 'idle', true)
	avatarSpine:setPosition(cc.p(
		nodes.bg:getContentSize().width * 0.5,
		nodes.bg:getContentSize().height * 0.5 + 5
	))
	nodes.bg:addChild(avatarSpine, 5)

	self.avatarNodes[teamIdx].avatarSpine = avatarSpine
	------------ 卡牌spine小人 ------------
end
--[[
根据序号 卡牌id 刷新卡牌连携技按钮
@params teamIdx int 编队序号
@params cardId int 卡牌id
--]]
function TagMatchChangeTeamScene:RefreshConnectSkillNode(teamIdx, cardId)
	local nodes = self.avatarNodes[teamIdx]

	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		self.avatarNodes[teamIdx].connectSkillNode = nil
	end

	------------ 卡牌连携技按钮 ------------
	local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
	if nil ~= connectSkillId then
		local skillNode = self:GetAConnectSkillNodeBySkillId(connectSkillId)
		display.commonUIParams(skillNode, {po = cc.p(
			nodes.bg:getContentSize().width * 0.5,
			nodes.bg:getContentSize().height * 0.5 + 5
		)})
		nodes.bg:addChild(skillNode, 10)

		self.avatarNodes[teamIdx].connectSkillNode = skillNode
	end
	------------ 卡牌连携技按钮 ------------
end
--[[
刷新一次所有连携技状态
--]]
function TagMatchChangeTeamScene:RefreshAllConnectSkillState()
	local battlePoint = 0
	for i,v in ipairs(self.teamData) do
		if v.id then
			local cardData = gameMgr:GetCardDataById(v.id)
			if cardData then
				-- 连携技状态
				self:RefreshConnectSkillNodeState(i, checkint(cardData.cardId))

				-- 计算一次战斗力
				battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(v.id)
			end
		end
	end

	-- 设置战斗力标签
	self.battlePointLabel:setString(tostring(battlePoint))
end
--[[
刷新连携技状态
@params teamIdx int 队伍序号
@params cardId int 卡牌id
--]]
function TagMatchChangeTeamScene:RefreshConnectSkillNodeState(teamIdx, cardId)
	local nodes = self.avatarNodes[teamIdx]
	if nil ~= nodes.connectSkillNode then
		local skillEnable = app.cardMgr.IsConnectSkillEnable(cardId, self.teamData)
		if skillEnable then
			nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(255, 255, 255, 255))
		else
			nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(100, 100, 100, 100))
		end
	end
end
--[[
装备一张卡
@params teamIdx int 队伍序号
@params id int 卡牌数据库id
--]]
function TagMatchChangeTeamScene:EquipACard(teamIdx, id)
	local cardData = gameMgr:GetCardDataById(id)
	------------ data ------------
	self:UpdateTeamData(teamIdx, id)
	------------ data ------------

	------------ view ------------
	local skinId = checkint(cardData.defaultSkinId or CardUtils.GetCardSkinId(checkint(cardData.cardId)))
	self:RefreshAvatarSpine(teamIdx, skinId)
	self:RefreshConnectSkillNode(teamIdx, checkint(cardData.cardId))
	-- 刷新一次连携技按钮状态
	self:RefreshAllConnectSkillState()
	------------ view ------------
	AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {self:GetTeamId()}})
end
--[[
装备所有卡牌
--]]
function TagMatchChangeTeamScene:EquipAllCard()
	-- logInfo.add(5, tableToString(self.teamData))
	if next(self.teamData) == nil then
		for i, v in ipairs(self.avatarNodes) do
			self:ClearAvatarNode(i)
		end
	else
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local v = self.teamData[i]
			if v and nil ~= v.id and 0 ~= checkint(v.id) then
				local cardData = gameMgr:GetCardDataById(v.id)
				if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
					local skinId = nil
					if nil == cardData.defaultSkinId then
						skinId = CardUtils.GetCardSkinId(checkint(cardData.cardId))
					else
						skinId = checkint(cardData.defaultSkinId)
					end

					self:RefreshAvatarSpine(i, skinId)
					self:RefreshConnectSkillNode(i, checkint(cardData.cardId))
				end
			else
				-- 移除卡牌
				self:ClearAvatarNode(i)
			end
		end
	end
	
	-- 刷新一次连携技按钮
	self:RefreshAllConnectSkillState()
end
--[[
卸下一张卡
@params teamIdx int 队伍序号
--]]
function TagMatchChangeTeamScene:UnequipACard(teamIdx)
	------------ data ------------
	self:UpdateTeamData(teamIdx)
	------------ data ------------

	------------ view ------------
	local nodes = self.avatarNodes[teamIdx]
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:removeFromParent()
		self.avatarNodes[teamIdx].avatarSpine = nil
	end
	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		self.avatarNodes[teamIdx].connectSkillNode = nil
	end
	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(true)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(false)
	end
	-- 刷新一次连携技按钮状态
	self:RefreshAllConnectSkillState()
	------------ view ------------

	AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {self:GetTeamId()}})
end
--[[
清空卡牌节点
--]]
function TagMatchChangeTeamScene:ClearAvatarNode(teamIndex)
	local nodes = self.avatarNodes[teamIndex]
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:removeFromParent()
		self.avatarNodes[teamIndex].avatarSpine = nil
	end
	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		self.avatarNodes[teamIndex].connectSkillNode = nil
	end
	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(true)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(false)
	end
end
--[[
清空所有选择卡牌
--]]
function TagMatchChangeTeamScene:ClearAllCards()
	for i,v in ipairs(self.teamData) do
		------------ data ------------
		self:UpdateTeamData(i)
		------------ data ------------

		------------ view ------------
		self:ClearAvatarNode(i)
		-- local nodes = self.avatarNodes[i]
		-- if nil ~= nodes.avatarSpine then
		-- 	nodes.avatarSpine:removeFromParent()
		-- 	self.avatarNodes[i].avatarSpine = nil
		-- end
		-- if nil ~= nodes.connectSkillNode then
		-- 	nodes.connectSkillNode:removeFromParent()
		-- 	self.avatarNodes[i].connectSkillNode = nil
		-- end
		-- if nil ~= nodes.avatarLight then
		-- 	nodes.avatarLight:setVisible(true)
		-- end
		-- if nil ~= nodes.avatarBtn then
		-- 	nodes.avatarBtn:setVisible(false)
		-- end
		------------ view ------------
	end
	-- 刷新一次连携技按钮状态
	self:RefreshAllConnectSkillState()
	AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {self:GetTeamId()}})
end
--[[
根据技能id获取一个连携技图标
@params skillId int 技能id
--]]
function TagMatchChangeTeamScene:GetAConnectSkillNodeBySkillId(skillId)
	local node = display.newImageView(_res('ui/home/teamformation/team_ico_skill_circle.png'), 0, 0)

	local skillIcon = display.newImageView(_res(CommonUtils.GetSkillIconPath(skillId)), 0, 0)
	skillIcon:setScale((node:getContentSize().width - 10) / skillIcon:getContentSize().width)
	display.commonUIParams(skillIcon, {po = utils.getLocalCenter(node)})
	skillIcon:setTag(3)
	node:addChild(skillIcon, -1)

	skillIcon:setColor(cc.c4b(100, 100, 100, 100))

	return node
end

---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
返回按钮回调
--]]
function TagMatchChangeTeamScene:BackBtnClickHandler(sender)
	-- 弹提示
	local commonTip = require('common.NewCommonTip').new({
		text = self.closeViewTipText or __('返回将无法保存编队 是否继续?'),
		callback = function ()
			-- self:runAction(cc.RemoveSelf:create())
			AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE', {isAttack = self.battleTypeData.isAttack})
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end
--[[
小人按钮回调
--]]
function TagMatchChangeTeamScene:AvatarBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	self.selectCardLayer:UnequipACardByTeamIndex(index)
	self:UnequipACard(index)
end
--[[
注册信号回调
--]]
function TagMatchChangeTeamScene:RegisterSignal()
	------------ 卸下一张卡 ------------
	AppFacade.GetInstance():RegistObserver('UNEQUIP_A_CARD', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:UnequipACard(checkint(data.position))
	end, self))
	------------ 卸下一张卡 ------------

	------------ 装备一张卡 ------------
	AppFacade.GetInstance():RegistObserver('EQUIP_A_CARD', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:EquipACard(checkint(data.position), checkint(data.id))
	end, self))
	------------ 装备一张卡 ------------

	------------ 清空所有卡牌 ------------
	AppFacade.GetInstance():RegistObserver('CLEAR_ALL_CARDS', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:ClearAllCards()
	end, self))
	------------ 清空所有卡牌 ------------

	------------ 关闭本界面 ------------
	AppFacade.GetInstance():RegistObserver('CLOSE_CHANGE_TEAM_SCENE', mvc.Observer.new(function (_, signal)
		self:setVisible(false)
		self:runAction(cc.RemoveSelf:create())
	end, self))
	------------ 关闭本界面 ------------
end
--[[
注销信号
--]]
function TagMatchChangeTeamScene:UnRegistSignal()
	AppFacade.GetInstance():UnRegistObserver('UNEQUIP_A_CARD', self)
	AppFacade.GetInstance():UnRegistObserver('EQUIP_A_CARD', self)
	AppFacade.GetInstance():UnRegistObserver('CLEAR_ALL_CARDS', self)
	AppFacade.GetInstance():UnRegistObserver('CLOSE_CHANGE_TEAM_SCENE', self)
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据站位序号刷新队伍信息
@params teamIdx int 站位序号
@params id int 卡牌数据库id
--]]
function TagMatchChangeTeamScene:UpdateTeamData(teamIdx, id)
	-- id为nil时置空
	self.teamData[teamIdx] = {id = id}
end

--[[
根据团队id 获得选择的卡牌数据
@return 选择的卡牌
--]]
function TagMatchChangeTeamScene:GetSelectedCardsByTeamId(teamId)
	return self.selectCardLayer:GetSelectedCardsByTeamId(teamId)
end

--[[
获得 选择列表中所有团队卡牌的数据
@return 选择的卡牌
--]]
function TagMatchChangeTeamScene:GetSelecteLayerTeamDatas()
	return self.selectCardLayer:GetTeamDatas()
end

--[[
交换 选择的卡牌
--]]
function TagMatchChangeTeamScene:SwapSelectedCards(oldTeamId, newTeamId)
	return self.selectCardLayer:SwapSelectedCards(oldTeamId, newTeamId)
end

function TagMatchChangeTeamScene:GetTeamId()
	return self.teamId
end

function TagMatchChangeTeamScene:SetTeamId(teamId)
	self.teamId = teamId

	-- self.teamData = self:GetSelectedCardsByTeamId(teamId)

	if self.selectCardLayer then
		self.selectCardLayer:SetTeamId(teamId)
	end
end

function TagMatchChangeTeamScene:SetTeamDataByTeamId(teamId, teamData)
	self.teamDatas[tostring(teamId)] = teamData or {}
	return self.teamDatas[tostring(teamId)]
end

function TagMatchChangeTeamScene:SetTeamData(teamData)
	self.teamData = clone(teamData or {})
	
	-- 重新装备卡牌
	self:EquipAllCard()
end

function TagMatchChangeTeamScene:GetAvatarPosConf(size)
	local avatarOriPos = nil
	local avatarLocationInfo = nil
	local teamMarkPosSign = 1
	if self.avatarShowType == 2 then
		avatarOriPos = cc.p(
			size.width * 0.5 - 310 - 46,
			size.height * 0.49
		)
		
		if -1 == self.teamTowards then
			avatarLocationInfo = {
				[1] = {fixedPos = cc.p(0, 0)},
				[2] = {fixedPos = cc.p(170, 0)},
				[3] = {fixedPos = cc.p(340, 0)},
				[4] = {fixedPos = cc.p(510, 0)},
				[5] = {fixedPos = cc.p(675, 0)}
			}
		else
			avatarLocationInfo = {
				[1] = {fixedPos = cc.p(675, 0)},
				[2] = {fixedPos = cc.p(510, 0)},
				[3] = {fixedPos = cc.p(340, 0)},
				[4] = {fixedPos = cc.p(170, 0)},
				[5] = {fixedPos = cc.p(0, 0)}
			}
		end
	else
		avatarOriPos = cc.p(
			size.width * 0.5 - 310,
			size.height * 0.55
		)
		
		if -1 == self.teamTowards then
			avatarLocationInfo = {
				[1] = {fixedPos = cc.p(0, 0)},
				[2] = {fixedPos = cc.p(155, 65)},
				[3] = {fixedPos = cc.p(310, 0)},
				[4] = {fixedPos = cc.p(465, 65)},
				[5] = {fixedPos = cc.p(620, 0)}
			}
			teamMarkPosSign = -1
		else
			avatarLocationInfo = {
				[1] = {fixedPos = cc.p(620, 0)},
				[2] = {fixedPos = cc.p(465, 65)},
				[3] = {fixedPos = cc.p(310, 0)},
				[4] = {fixedPos = cc.p(155, 65)},
				[5] = {fixedPos = cc.p(0, 0)}
			}
		end
	end

	return avatarOriPos, avatarLocationInfo, teamMarkPosSign
end

function TagMatchChangeTeamScene:ResetAllCardSelectState()
	if self.selectCardLayer then
		self.selectCardLayer:ResetAllCardSelectState()
	end
end

---------------------------------------------------
-- get set end --
---------------------------------------------------
function TagMatchChangeTeamScene:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
end

return TagMatchChangeTeamScene
