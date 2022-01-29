--[[
团队信息界面
@params params table {
    teamData      list 现有阵容
    avatarTowards int 1 朝右 -1 朝左
    teamTowards   int 队伍朝向 1 朝右 -1 朝左
    avatarOriPos  table avatar基准坐标
	avatarLocationInfo table avatar位置信息
    tag                int   当前view的tag
}
--]]
------------ import ------------
local appFacadeIns = AppFacade.GetInstance()
local uiMgr        = appFacadeIns:GetManager("UIManager")
local gameMgr      = appFacadeIns:GetManager("GameManager")
local cardMgr      = appFacadeIns:GetManager('CardManager')
------------ import ------------

local VIEW_SIZE = display.size
local TeamInfoView = class('TeamInfoView', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.TeamInfoView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    TEAM_BASE_IMG     = _res('ui/common/tower_bg_team_base.png'),
    TEAM_BASE_CAP_IMG = _res('ui/common/tower_bg_team_base_cap.png'),
    ICO_CAPTAIN       = _res('ui/home/teamformation/team_ico_captain.png')
}

local BUTTON_TAG = {
    BACK      = 100,
    RULE      = 101,
    EDIT      = 102,
    EXPLORE   = 103,
}

local AVATAR_STATE = {
    IDLE = 0,
    RUN  = 1,
}

------------ signal name ------------

local LOCAL_SIGNAL_NAME = {
	-- 卸下一张卡牌
	UNEQUIP_A_CARD    = 'UNEQUIP_A_CARD',
	-- 装备一张卡牌
	EQUIP_A_CARD      = 'EQUIP_A_CARD',
	-- 装备所有卡牌
	EQUIP_ALL_CARDS   = 'EQUIP_ALL_CARDS',
	-- 装备清理所有卡牌
	CLEAR_ALL_CARDS   = 'CLEAR_ALL_CARDS',
	-- 控制视图启用
	VIEW_CONTROLLABLE = 'VIEW_CONTROLLABLE',
	-- 卸下一个avatar
	UNEQUIP_A_AVATAR  = 'UNEQUIP_A_AVATAR',
}

------------ signal name ------------

function TeamInfoView:ctor( ... )
    self.args                = unpack({...}) or {}
    self.teamData            = self.args.teamData or {}
    self.teamTowards         = self.args.teamTowards or 1
    self.avatarTowards       = self.args.avatarTowards or 1
	self.avatarOriPos        = self.args.avatarOriPos
	self.avatarLocationInfo  = self.args.avatarLocationInfo
	self.tag                 = self.args.tag
	self.disableClick        = self.args.disableClick
	self.disableConnectSkill = self.args.disableConnectSkill

	self.maxCardNum          = self.args.maxCardNum or MAX_TEAM_MEMBER_AMOUNT

    self.isControllable_     = true
    
    self.avatarState         = AVATAR_STATE.IDLE

    self:initialUI()

    -- 注册信号回调
	self:RegisterSignal()
end

function TeamInfoView:initialUI()
    local CreateView = function (teamTowards)
        local view = display.newLayer()
        local size = view:getContentSize()
       
        local avatarOriPos, teamMarkPosSign, avatarLocationInfo = self:GetAvatarPosConf(size)

        local p = nil
        local avatarNodes = {}
		
		local captainMark = nil
        for i = 1, MAX_TEAM_MEMBER_AMOUNT do
            local isCaptain = 1 == i
            local avatarBgPath = isCaptain and RES_DIR.TEAM_BASE_CAP_IMG or RES_DIR.TEAM_BASE_IMG
            p = avatarLocationInfo[i]
            
            local avatarBg = display.newImageView(_res(avatarBgPath),
                avatarOriPos.x + p.fixedPos.x,
                avatarOriPos.y + p.fixedPos.y)
            view:addChild(avatarBg, 20 + i % 2)
            -- avatarBg:setOpacity(0)
			avatarBg:setVisible(false)
			
			local avatarBgLayer = display.newLayer(avatarBg:getPositionX(), avatarBg:getPositionY(), {ap = avatarBg:getAnchorPoint(), size = avatarBg:getContentSize()})
			view:addChild(avatarBgLayer, 20 + i % 2)

            local avatarLight = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
            display.commonUIParams(avatarLight, {po = cc.p(
                utils.getLocalCenter(avatarBg).x,
                utils.getLocalCenter(avatarBg).y + avatarLight:getContentSize().height * 0.5
            )})
            avatarBgLayer:addChild(avatarLight, 10)
    
            -- 透明按钮
            local avatarBtn = display.newButton(0, 0, {size = cc.size(150, 200)})
            display.commonUIParams(avatarBtn, {po = cc.p(
                avatarBg:getPositionX(),
                avatarBg:getPositionY() + avatarBtn:getContentSize().height * 0.5
            ), animate = false})
            avatarBg:getParent():addChild(avatarBtn, avatarBg:getLocalZOrder())
            avatarBtn:setTag(i)
            avatarBtn:setVisible(false)
    
            -- debug --
            -- local l = display.newLayer(avatarBtn:getPositionX(), avatarBtn:getPositionY(), {size = avatarBtn:getContentSize(), ap = avatarBtn:getAnchorPoint()})
            -- l:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))
            -- avatarBtn:getParent():addChild(l, avatarBtn:getLocalZOrder())
            -- debug --
    
            if isCaptain then
                -- 添加队长标记
                captainMark = display.newNSprite(RES_DIR.ICO_CAPTAIN, 0, 0)
                display.commonUIParams(captainMark, {po = cc.p(
                    avatarBg:getPositionX() + teamMarkPosSign * (avatarBg:getContentSize().width * 0.5 + 20),
                    avatarBg:getPositionY() - 5
                )})
                view:addChild(captainMark, 100)
            end
			
            avatarNodes[i] = {avatarBgLayer = avatarBgLayer, bg = avatarBg, avatarLight = avatarLight, avatarBtn = avatarBtn, avatarSpine = nil, connectSkillNode = nil}
        end
		
		self.captainMark = captainMark
        self.avatarNodes = avatarNodes
        self.view = view

    end
    xTry(function ( )
        CreateView()
        self:addChild(self.view)

        self:initView()
	end, __G__TRACKBACK__)
end

function TeamInfoView:initView()
    for i, avatarNode in ipairs(self.avatarNodes) do
        display.commonUIParams(avatarNode.avatarBtn, {cb = handler(self, self.avatarBtnClickHandler)})
    end

    if next(self.teamData) ~= nil then
		-- self:RefreshUI(self.teamData)
		self:EquipAllCard()
    end
end

-- function TeamInfoView:RefreshUI()
    
-- end

---------------------------------------------------
-- view control begin --
---------------------------------------------------
function TeamInfoView:EquipAllCard()
	if not self:GetIsControllable() then return end
	-- self:SetIsControllable(false)

	local isOwnTeamData = next(self.teamData) ~= nil
	local maxCardNum = self:GetMaxCardNum()

	local actionList = {}
	local refreshActionLists = {}
    local baseActionLists = {}
	local bgActionLists = {}
	
    -- local isFromEquipAll = true
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		if i > maxCardNum then
			-- 隐藏卡牌
			self:HideAvatar(i)
		else
			local v = self.teamData[i]
			if isOwnTeamData and v and nil ~= v.id and 0 ~= checkint(v.id) then

				local cardData = gameMgr:GetCardDataById(v.id)
				if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
					local skinId = self:GetSkinId(cardData)
					local refreshActionList, bgActionList = self:RefreshAvatarSpine(i, skinId, cardData.cardId, true)
                    table.insert(refreshActionLists, refreshActionList)
                    table.insert(bgActionLists, bgActionList)
				end
			else
				-- 移除卡牌
				local removeActionList, baseActionList, bgActionList = self:ClearAvatarNode(i)
				for i, v in ipairs(removeActionList) do
					table.insert(actionList, v)
				end
                table.insert(baseActionLists, baseActionList)
                table.insert(bgActionLists, bgActionList)
			end
		end

	end
	
	for i, bgActionList in ipairs(bgActionLists) do
		for i, bgAction in ipairs(bgActionList) do
			table.insert(actionList, bgAction)
		end
	end

	for i, baseActionList in ipairs(baseActionLists) do
		for i, baseAction in ipairs(baseActionList) do
			table.insert(actionList, baseAction)
		end
    end


	for i, refreshActionList in ipairs(refreshActionLists) do
		for i, refreshAction in ipairs(refreshActionList) do
			table.insert(actionList, refreshAction)
		end
	end

	self:ShowAvatarAction(actionList)
	
end

--[[
根据序号 卡牌皮肤 刷新卡牌spine小人
@params teamIdx int 编队序号
@params skinId int 皮肤id
@params cardId int 卡牌id
--]]
function TeamInfoView:RefreshAvatarSpine(teamIdx, skinId, cardId, isDisableBgAction)
	local nodes = self.avatarNodes[teamIdx]
	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(false)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(true)
    end

	-- if nil ~= nodes.bg then
	-- 	nodes.bg:setVisible(true)
	-- end
    
    -- local isHideBgAction = (nil ~= nodes.avatarSpine)
    local bgActionList = self:GetAvatarBgActionList(teamIdx, isDisableBgAction)
    
	local actionList = self:GetCreateAvatarActionList(teamIdx, skinId, cardId)

	return actionList, bgActionList
end

--[[
获得创建 avatar action list
@params teamIdx int 编队序号
@params skinId  int 皮肤id
@params cardId int 卡牌id
--]]
function TeamInfoView:GetCreateAvatarActionList(teamIdx, skinId, cardId)
	local nodes = self.avatarNodes[teamIdx]
	local actionList = {}
	-- cc.TargetedAction:create(self.avatarNodes[teamIdx].avatarSpine, cc.ScaleTo:create(0.1, 1)),
	-- cc.TargetedAction:create(self.avatarNodes[teamIdx].avatarSpine, cc.MoveTo:create(0.2, cc.p(self.avatarNodes[teamIdx].avatarSpine:getPositionX(), self.avatarNodes[teamIdx].avatarSpine:getPositionX() + 200))),

	-- local avatar self:CreateAvatar(teamIdx, skinId)

	-- local createAvatarActionList = {
	-- 	cc.DelayTime:create((teamIdx - 1) * 0.05),
	-- 	cc.CallFunc:create(function()
	-- 		self:CreateAvatar(teamIdx, skinId)
	-- 		self:RefreshConnectSkillNode(teamIdx, checkint(cardId))
	-- 	end),
	-- }
	local avatarSpine = self:CreateAvatar(teamIdx, skinId)
	local createAvatarActionList = {
		-- cc.DelayTime:create((teamIdx - 1) * 0.02),
		cc.CallFunc:create(function()
			local offsetY = 180
			local defPos = cc.p(avatarSpine:getPositionX(), avatarSpine:getPositionY())
			avatarSpine:setPosition(cc.p(
				avatarSpine:getPositionX(), avatarSpine:getPositionY() + offsetY
			))
			self.avatarNodes[teamIdx].avatarSpine = avatarSpine
			
			avatarSpine:setVisible(true)
		end),
		cc.TargetedAction:create(avatarSpine, cc.MoveTo:create(0.18, cc.p(avatarSpine:getPositionX(), avatarSpine:getPositionY()))),
		cc.CallFunc:create(function ()
			self:RefreshConnectSkillNode(teamIdx, checkint(cardId))
		end)
	}

	if nodes.avatarSpine == nil then
		actionList = createAvatarActionList
	else
		local avatarSpine = nodes.avatarSpine
		local tag = avatarSpine:getTag()
		-- 检查皮肤ID是否相同 不同 则 先移除 在 创建
		if skinId ~= tag then
			actionList = self:GetRemoveAvatarActionList(teamIdx)
			for i, action in ipairs(createAvatarActionList) do
				table.insert(actionList, action)
			end
		end
	end
	return actionList
end

--[[
获得移除 avatar action list
@params teamIdx int 编队序号
--]]
function TeamInfoView:GetRemoveAvatarActionList(teamIdx)
	local nodes = self.avatarNodes[teamIdx]
	if nodes == nil or nodes.avatarSpine == nil then return {} end
	local avatarSpine = nodes.avatarSpine
	return {
		-- cc.TargetedAction:create(avatarSpine, cc.MoveTo:create(0.2, cc.p(avatarSpine:getPositionX(), avatarSpine:getPositionX() + 200))),
		cc.TargetedAction:create(avatarSpine, cc.ScaleTo:create(0.1, 0, 1)),
		cc.TargetedAction:create(avatarSpine, cc.RemoveSelf:create()),
		cc.CallFunc:create(function()
			self.avatarNodes[teamIdx].avatarSpine = nil
            PlayAudioClip(AUDIOS.UI.ui_relic_cut.id)
		end)
	}
end

function TeamInfoView:GetShowAvatarBaseActionList(teamIdx)
	local nodes = self.avatarNodes[teamIdx]

	if nodes == nil then return {} end

	local actionList = {}
	
	local connectSkillNode = nodes.connectSkillNode
	if connectSkillNode ~= nil then
		-- table.insert(actionList, cc.DelayTime:create(0.1))
		table.insert(actionList, cc.TargetedAction:create(connectSkillNode, cc.RemoveSelf:create()))
		table.insert(actionList, cc.CallFunc:create(function()
			self.avatarNodes[teamIdx].connectSkillNode = nil
		end))
	end
	
	local deltaTime = 0.1
	local avatarLight = nodes.avatarLight
	if avatarLight ~= nil then 
		avatarLight:setOpacity(0)
		table.insert(actionList, cc.TargetedAction:create(avatarLight, cc.FadeIn:create(deltaTime)))
	end

	return actionList
end

function TeamInfoView:GetAvatarBgActionList(teamIdx, isDisableBgAction)
    local nodes = self.avatarNodes[teamIdx]

	if nodes == nil then return {} end

    local actionList = {}

    local bg = nodes.bg
    if bg ~= nil then
        table.insert(actionList, cc.CallFunc:create(function ()
            bg:setVisible(self.avatarState == AVATAR_STATE.IDLE)
        end))

        if not isDisableBgAction then
            local deltaTime = 0.1
            bg:setOpacity(0)
            bg:setScale(0)

            table.insert(actionList, cc.TargetedAction:create(bg, cc.Spawn:create({
                cc.FadeIn:create(deltaTime),
                cc.ScaleTo:create(deltaTime, 1)
            })))
        end
        
    end
    
    return actionList
end

--[[
创建 avatar
@params teamIdx int 编队序号
@params skinId  int 皮肤id
--]]
function TeamInfoView:CreateAvatar(teamIdx, skinId)
	local nodes = self.avatarNodes[teamIdx]
	if nodes == nil then return end
	------------ 卡牌spine小人 ------------
	local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
	avatarSpine:update(0)
	avatarSpine:setScaleX(self.avatarTowards)
	avatarSpine:setAnimation(0, 'idle', true)
	avatarSpine:setPosition(cc.p(
		nodes.avatarBgLayer:getContentSize().width * 0.5,
		nodes.avatarBgLayer:getContentSize().height * 0.5 + 5
	))
	nodes.avatarBgLayer:addChild(avatarSpine, 5)
	avatarSpine:setTag(skinId)
	-- avatarSpine:setScaleX(0)
	avatarSpine:setVisible(false)
	------------ 卡牌spine小人 ------------
	
	-- self.avatarNodes[teamIdx].avatarSpine = avatarSpine
	-- local defPos = cc.p(avatarSpine:getPositionX(), avatarSpine:getPositionY())
	-- local offsetY = 180
	-- avatarSpine:setPosition(cc.p(
	-- 	defPos.x, defPos.y + offsetY
	-- ))
	-- self.avatarNodes[teamIdx].avatarSpine:runAction(cc.TargetedAction:create(avatarSpine, cc.MoveTo:create(0.2, defPos)))

	return avatarSpine
end

--[[
根据序号 卡牌id 刷新卡牌连携技按钮
@params teamIdx int 编队序号
@params cardId int 卡牌id
--]]
function TeamInfoView:RefreshConnectSkillNode(teamIdx, cardId)
	if self.disableConnectSkill then return end
	
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
function TeamInfoView:RefreshAllConnectSkillState()
	if self.disableConnectSkill then return end
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

end
--[[
刷新连携技状态
@params teamIdx int 队伍序号
@params cardId int 卡牌id
--]]
function TeamInfoView:RefreshConnectSkillNodeState(teamIdx, cardId)
	if self.disableConnectSkill then return end
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
function TeamInfoView:EquipACard(teamIdx, id)
	local cardData = gameMgr:GetCardDataById(id)
	------------ data ------------
	self:UpdateTeamData(teamIdx, id)
	------------ data ------------

	------------ view ------------
	local skinId = checkint(cardData.defaultSkinId or CardUtils.GetCardSkinId(checkint(cardData.cardId)))
	
    local actionList, bgActionList = self:RefreshAvatarSpine(teamIdx, skinId, cardData.cardId)
    for i, v in ipairs(bgActionList) do
        table.insert(actionList, v)
    end
	self:ShowAvatarAction(actionList)

	
	-- 刷新一次连携技按钮状态
	self:RefreshAllConnectSkillState()
	------------ view ------------
	-- appFacadeIns:DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {self:GetTeamId()}})
end
--[[
卸下一张卡
@params teamIdx int 队伍序号
--]]
function TeamInfoView:UnequipACard(teamIdx, callback)
	------------ data ------------
	self:UpdateTeamData(teamIdx)
	------------ data ------------

	------------ view ------------
	local nodes = self.avatarNodes[teamIdx]
	local actionList = self:GetRemoveAvatarActionList(teamIdx)
	
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
	-- -- 刷新一次连携技按钮状态
	-- self:RefreshAllConnectSkillState()
	------------ view ------------

	-- appFacadeIns:DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {self:GetTeamId()}})
	return actionList
end
--[[
清空卡牌节点
--]]
function TeamInfoView:ClearAvatarNode(teamIndex)
	
    local nodes = self.avatarNodes[teamIndex]
    -- local isNeedRemoveAvatar = nil ~= nodes.avatarSpine
	-- if nil ~= nodes.avatarSpine then
	-- 	nodes.avatarSpine:removeFromParent()
	-- 	self.avatarNodes[teamIndex].avatarSpine = nil
	-- end
	local removeActionList = self:GetRemoveAvatarActionList(teamIndex)

	local bgActionList = self:GetAvatarBgActionList(teamIndex, false)
	
    local baseActionList = self:GetShowAvatarBaseActionList(teamIndex)
    

	-- if nil ~= nodes.connectSkillNode then
	-- 	nodes.connectSkillNode:removeFromParent()
	-- 	self.avatarNodes[teamIndex].connectSkillNode = nil
	-- end
	-- if nil ~= nodes.avatarLight then
	-- 	nodes.avatarLight:setVisible(true)
	-- end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(false)
	end
	-- if nil ~= nodes.bg then
	-- 	nodes.bg:setVisible(true)
	-- end

	return removeActionList, baseActionList, bgActionList
end
--[[
清空所有选择卡牌
--]]
function TeamInfoView:ClearAllCards()
	local actionList      = {}
    local baseActionLists = {}
    local bgActionLists   = {}
	for i,v in ipairs(self.teamData) do
		------------ data ------------
		self:UpdateTeamData(i)
		------------ data ------------

		------------ view ------------
		local removeActionList, baseActionList, bgActionList = self:ClearAvatarNode(i)
		for i, v in ipairs(removeActionList) do
			table.insert(actionList, v)
		end
        table.insert(baseActionLists, baseActionList)
        table.insert(bgActionLists, bgActionList)
		------------ view ------------
	end

	for i, bgActionList in ipairs(bgActionLists) do
		for i, bgAction in ipairs(bgActionList) do
			table.insert(actionList, bgAction)
		end
	end

	for i, baseActionList in ipairs(baseActionLists) do
		for i, baseAction in ipairs(baseActionList) do
			table.insert(actionList, baseAction)
		end
    end
	
	self:ShowAvatarAction(actionList)
	-- -- 刷新一次连携技按钮状态
	-- self:RefreshAllConnectSkillState()
	-- appFacadeIns:DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {self:GetTeamId()}})
end

function TeamInfoView:HideAvatar(teamIndex)
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
		nodes.avatarLight:setVisible(false)
	end

	if nil ~= nodes.bg then
		nodes.bg:setVisible(false)
	end
end

--[[
根据技能id获取一个连携技图标
@params skillId int 技能id
--]]
function TeamInfoView:GetAConnectSkillNodeBySkillId(skillId)
	local node = display.newImageView(_res('ui/home/teamformation/team_ico_skill_circle.png'), 0, 0)

	local skillIcon = display.newImageView(_res(CommonUtils.GetSkillIconPath(skillId)), 0, 0)
	skillIcon:setScale((node:getContentSize().width - 10) / skillIcon:getContentSize().width)
	display.commonUIParams(skillIcon, {po = utils.getLocalCenter(node)})
	skillIcon:setTag(3)
	node:addChild(skillIcon, -1)

	skillIcon:setColor(cc.c4b(100, 100, 100, 100))

	return node
end

function TeamInfoView:RunAvatarNodes()
	local maxCardNum = self:GetMaxCardNum()

	for i = 1, maxCardNum do
		local nodes = self.avatarNodes[i]
		
		if nodes then
			if nil ~= nodes.avatarLight then
				nodes.avatarLight:setVisible(false)
			end
			
			if nil ~= nodes.bg then
				nodes.bg:setVisible(false)
			end

			if nil ~= nodes.avatarSpine then
				nodes.avatarSpine:setAnimation(0, 'run', true)
			end
		end
	end

	self.captainMark:setVisible(false)
end

function TeamInfoView:StopAvatarNodes()
	local maxCardNum = self:GetMaxCardNum()

	for i = 1, maxCardNum do
		local nodes = self.avatarNodes[i]
		
		if nodes then
			if nil ~= nodes.avatarLight then
				nodes.avatarLight:setVisible(not (nil ~= nodes.avatarSpine))
			end
	
			if nil ~= nodes.bg then
				nodes.bg:setVisible(true)
			end

			if nil ~= nodes.avatarSpine then
				nodes.avatarSpine:setAnimation(0, 'idle', true)
			end
		end
	end

	self.captainMark:setVisible(true)
end

---------------------------------------------------
-- view control end --
---------------------------------------------------

function TeamInfoView:avatarBtnClickHandler(sender)
	if self.disableClick then return end
	if not self.isControllable_ then return end
	-- self:SetIsControllable(false)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	appFacadeIns:DispatchObservers(LOCAL_SIGNAL_NAME.UNEQUIP_A_AVATAR, {position = index, tag = self.tag})
	local actionList = self:UnequipACard(index)
	self:ShowAvatarAction(actionList)
end

function TeamInfoView:CreateCell()
    return CreateCell_()
end

--[[
注册信号回调
--]]
function TeamInfoView:RegisterSignal()

	------------ 卸下一张卡 ------------
	appFacadeIns:RegistObserver(LOCAL_SIGNAL_NAME.UNEQUIP_A_CARD, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		if data.tag ~= self.tag then return end
	
		local actionList = self:UnequipACard(checkint(data.position))
		self:ShowAvatarAction(actionList)
	end, self))
	------------ 卸下一张卡 ------------

	------------ 装备一张卡 ------------
	appFacadeIns:RegistObserver(LOCAL_SIGNAL_NAME.EQUIP_A_CARD, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		if data.tag ~= self.tag then return end

		local teamIdx = checkint(data.position)
		
		local callback = data.callback
		if callback then
			local nodes = self.avatarNodes[teamIdx]
			local avatarBgLayer = nodes.avatarBgLayer
			local avatarBgLayerSize = avatarBgLayer:getContentSize()
			local toNodePos = avatarBgLayer:convertToWorldSpace(cc.p(avatarBgLayerSize.width/2, avatarBgLayerSize.height))
			callback(data.id, data.listIndex, toNodePos, function ()
				self:EquipACard(teamIdx, checkint(data.id))
			end)
		else
			self:EquipACard(teamIdx, checkint(data.id))
		end
	end, self))
	------------ 装备一张卡 ------------

	------------ 清空所有卡牌 ------------
	appFacadeIns:RegistObserver(LOCAL_SIGNAL_NAME.CLEAR_ALL_CARDS, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		if data.tag ~= self.tag then return end

		-- self:SetIsControllable(false)
		self:ClearAllCards()
	end, self))
	------------ 清空所有卡牌 ------------
	
	------------ 装备所有卡牌 ------------
	appFacadeIns:RegistObserver(LOCAL_SIGNAL_NAME.EQUIP_ALL_CARDS, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		if data.tag ~= self.tag then return end

		self:SetTeamData(data.selectedCards or {})
	end, self))
	------------ 装备所有卡牌 ------------

	
	
end
--[[
注销信号
--]]
function TeamInfoView:UnRegistSignal()
	appFacadeIns:UnRegistObserver(LOCAL_SIGNAL_NAME.UNEQUIP_A_CARD  , self)
	appFacadeIns:UnRegistObserver(LOCAL_SIGNAL_NAME.EQUIP_A_CARD    , self)
	appFacadeIns:UnRegistObserver(LOCAL_SIGNAL_NAME.CLEAR_ALL_CARDS , self)
	appFacadeIns:UnRegistObserver(LOCAL_SIGNAL_NAME.EQUIP_ALL_CARDS , self)
end

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据站位序号刷新队伍信息
@params teamIdx int 站位序号
@params id int 卡牌数据库id
--]]
function TeamInfoView:UpdateTeamData(teamIdx, id)
	-- id为nil时置空
	self.teamData[teamIdx] = {id = id}
end

function TeamInfoView:GetAvatarPosConf(size)
    local avatarOriPos = self.avatarOriPos ~= nil and self.avatarOriPos or cc.p(size.width * 0.5 - 500, size.height * 0.35)
    
    local avatarLocationInfo = nil
    local teamMarkPosSign = self.teamTowards
    if self.avatarLocationInfo then
        avatarLocationInfo = self.avatarLocationInfo
    else
        avatarLocationInfo = -1 == self.teamTowards and {
            [1] = {fixedPos = cc.p(0, 0)},
            [2] = {fixedPos = cc.p(155, 65)},
            [3] = {fixedPos = cc.p(310, 0)},
            [4] = {fixedPos = cc.p(465, 65)},
            [5] = {fixedPos = cc.p(620, 0)}
        } or {
            [1] = {fixedPos = cc.p(620, 0)},
            [2] = {fixedPos = cc.p(465, 65)},
            [3] = {fixedPos = cc.p(310, 0)},
            [4] = {fixedPos = cc.p(155, 65)},
            [5] = {fixedPos = cc.p(0, 0)}
        }

    end

    return avatarOriPos, teamMarkPosSign, avatarLocationInfo
end

function TeamInfoView:RemoveAvatarAction(teamIdx, callback, skinId)
	local nodes = self.avatarNodes[teamIdx]
	if nodes and nil ~= nodes.avatarSpine then
		local tag = nodes.avatarSpine:getTag()
		if skinId ~= tag then
			self:runAction(cc.Sequence:create({
				cc.Spawn:create({
					cc.TargetedAction:create(nodes.avatarSpine, cc.MoveTo:create(0.2, cc.p(nodes.avatarSpine:getPositionX(), nodes.avatarSpine:getPositionX() + 200))),
				}),
				-- cc.DelayTime:create(0.1),
				cc.TargetedAction:create(nodes.avatarSpine, cc.ScaleTo:create(0.1, 0, 1)),
				cc.TargetedAction:create(nodes.avatarSpine, cc.RemoveSelf:create()),
				cc.CallFunc:create(function()
					self.avatarNodes[teamIdx].avatarSpine = nil
					PlayAudioClip(AUDIOS.UI.ui_relic_cut.id)
				end),
				cc.CallFunc:create(function()
					if callback then
						callback(teamIdx)
					end
				end)
			}))
		end

	else
		if callback then
			callback(teamIdx)
		end
	end
end

function TeamInfoView:DispatchControllable()
	appFacadeIns:DispatchObservers(LOCAL_SIGNAL_NAME.VIEW_CONTROLLABLE, {isControllable = self.isControllable_, tag = self.tag})
end

function TeamInfoView:GetIsControllable()
	return self.isControllable_
end
function TeamInfoView:SetIsControllable(isControllable)
	self.isControllable_ = isControllable
	
	self:DispatchControllable()
end

function TeamInfoView:GetTeamData()
	return self.teamData
end
function TeamInfoView:SetTeamData(teamData, callback, avatarRunState)
	self.teamData = teamData
	self.callback = callback

	self.avatarState = checkint(avatarRunState) 

	self:EquipAllCard()
end

function TeamInfoView:GetMaxCardNum()
	return self.maxCardNum
end
function TeamInfoView:SetMaxCardNum(maxCardNum)
	self.maxCardNum = math.min(maxCardNum, MAX_TEAM_MEMBER_AMOUNT)
end

function TeamInfoView:GetSkinId(cardData)
	local skinId = nil
	if nil == cardData.defaultSkinId then
		skinId = CardUtils.GetCardSkinId(checkint(cardData.cardId))
	else
		skinId = checkint(cardData.defaultSkinId)
	end
	return skinId
end

function TeamInfoView:getViewData()
	return self.viewData_
end

function TeamInfoView:ShowAvatarAction(actionList)
	if actionList == nil and next(actionList) == nil then return end
	self:stopAllActions()
	table.insert(actionList, cc.CallFunc:create(function ()
		-- 刷新一次连携技按钮
		self:RefreshAllConnectSkillState()
		
		self:SetIsControllable(true)

		if self.callback then
			self.callback()
			self.callback = nil
		end
		
	end))
	self:runAction(cc.Sequence:create(actionList))
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

function TeamInfoView:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
end


return TeamInfoView