--[[
世界Boss界面 选buff层
@params table {
	questId int 关卡id
	buyBuffId int 购买的buff id
}
--]]
local GameScene = require( "Frame.GameScene" )
local WorldBossBuffView = class("WorldBossBuffView", GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
local cardHeadNodeSize = cc.size(96, 96)

local WB_CHANGE_TEAM_MEMBER_SIGNAL = 'WB_CHANGE_TEAM_MEMBER_SIGNAL'
------------ define ------------

--[[
constructor
--]]
function WorldBossBuffView:ctor(...)
	local args = unpack({...})

	self.questId = args.questId
	self.buyBuffId = args.buyBuffId
	self.selectedBuffId = nil

	self:InitUI()
	self:RegistSignal()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function WorldBossBuffView:InitUI()

	local function CreateView()
		local size = self:getContentSize()

		-- 遮罩
		local eaterLayer = display.newLayer(0, 0,
			{size = size, color = cc.c4b(0, 0, 0, 255 * 0.75), animate = false, enable = true})
		display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(eaterLayer, 1)

		-- 返回按钮
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = handler(self, self.CloseSelfClickHandler)})
	    backBtn:setName('backBtn')
	    display.commonUIParams(backBtn, {po = cc.p(
	    	display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30,
	    	display.size.height - 18 - backBtn:getContentSize().height * 0.5
	    )})
	    self:addChild(backBtn, 5)

	    -- 底部选卡界面
		local bottomBg = display.newImageView(_res('ui/worldboss/home/worldboss_bg_below.png'), 0, 0, {scale9 = true})
		local bottomLayer = display.newLayer(0, 0, {size = cc.size(size.width, bottomBg:getContentSize().height)})
		display.commonUIParams(bottomLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.5,
			bottomBg:getContentSize().height * 0.5
		)})
		self:addChild(bottomLayer, 5)

		display.commonUIParams(bottomBg, {po = utils.getLocalCenter(bottomLayer)})
		bottomLayer:addChild(bottomBg)
		bottomBg:setContentSize(cc.size(size.width, bottomBg:getContentSize().height))

		local teamBg = display.newImageView(_res('ui/worldboss/home/worldboss_team_bg.png'), 0, 0)
		display.commonUIParams(teamBg, {po = cc.p(
			display.SAFE_L - 60 + teamBg:getContentSize().width * 0.5,
			teamBg:getContentSize().height * 0.5
		)})
		bottomLayer:addChild(teamBg)

		local emptyCardNodes = {}
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local emptyCardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'))
			local scale = cardHeadNodeSize.width / emptyCardHeadBg:getContentSize().width
			emptyCardHeadBg:setScale(scale)
			display.commonUIParams(emptyCardHeadBg, {po = cc.p(
				teamBg:getPositionX() + (emptyCardHeadBg:getContentSize().width * scale + 10) * (i - 0.5 - MAX_TEAM_MEMBER_AMOUNT * 0.5),
				teamBg:getPositionY() - 30
			)})
			bottomLayer:addChild(emptyCardHeadBg)

			local emptyCardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), 0, 0)
			display.commonUIParams(emptyCardHeadFrame, {po = utils.getLocalCenter(emptyCardHeadBg)})
			emptyCardHeadBg:addChild(emptyCardHeadFrame)

			local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
			display.commonUIParams(addIcon, {po = utils.getLocalCenter(emptyCardHeadBg)})
			addIcon:setScale(1 / scale)
			emptyCardHeadBg:addChild(addIcon)

			local btn = display.newButton(0, 0, {size = cardHeadNodeSize, cb = handler(self, self.EditTeamMemberClickHandler)})
			display.commonUIParams(btn, {po = cc.p(
				emptyCardHeadBg:getPositionX(),
				emptyCardHeadBg:getPositionY()
			)})
			bottomLayer:addChild(btn, 99)

			-- 添加队长标识
			if 1 == i then
				local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
				display.commonUIParams(captainMark, {po = cc.p(
					emptyCardHeadBg:getPositionX(),
					emptyCardHeadBg:getPositionY() + emptyCardHeadBg:getContentSize().height * 0.5 * scale
				)})
				bottomLayer:addChild(captainMark, 99)
			end

			emptyCardNodes[i] = {emptyCardHeadBg = emptyCardHeadBg}
		end

		-- 战斗按钮
		local battleBtnBg = display.newImageView(_res('ui/common/discovery_bg_fight.png'), 0, 0)
		display.commonUIParams(battleBtnBg, {po = cc.p(
			display.SAFE_R + 60 - battleBtnBg:getContentSize().width * 0.5,
			display.SAFE_B + battleBtnBg:getContentSize().height * 0.5
		)})
		bottomLayer:addChild(battleBtnBg)

		local battleBtn = require('common.CommonBattleButton').new({
			pattern = 1,
			clickCallback = handler(self, self.BattleBtnClickHandler)
		})
		display.commonUIParams(battleBtn, {po = cc.p(
			battleBtnBg:getPositionX() + 10,
			battleBtnBg:getPositionY() + 15
		)})
		bottomLayer:addChild(battleBtn)

		-- 剩余次数
		local leftChallengeTimeLabel = display.newLabel(0, 0, fontWithColor('9', {text = '今日剩余次数:8'}))
		display.commonUIParams(leftChallengeTimeLabel, {po = cc.p(
			battleBtn:getPositionX(),
			display.SAFE_B + 15
		)})
		bottomLayer:addChild(leftChallengeTimeLabel)

		return {
			bottomLayer = bottomLayer,
			leftChallengeTimeLabel = leftChallengeTimeLabel,
			emptyCardNodes = emptyCardNodes,
			teamCardHeadNodes = {},
			buffNodes = nil
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 初始化buff层
	self:InitWBBuff()
	-- 初始化购买状态
	self:RefreshByBuyBuffId(self.buyBuffId)
end
--[[
初始化战斗buff
--]]
function WorldBossBuffView:InitWBBuff()
	local size = self:getContentSize()

	-- 初始化buff信息
	local buffTitleLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('战前祝福'), fontSize = 40, color = '#ffd273', outline = '#5b3c25', outlineSize = 2}))
	display.commonUIParams(buffTitleLabel, {po = cc.p(
		size.width * 0.5,
		size.height * 0.85
	)})
	self:addChild(buffTitleLabel, 10)

	local buffNodes = {}

	local stageConfig = CommonUtils.GetQuestConf(self.questId)
	if nil ~= stageConfig then
		local buffConfig = CommonUtils.GetConfig('worldBossQuest', 'buffInfo', self.questId)

		if nil ~= buffConfig then
			for i, buffId_ in ipairs(buffConfig.buffId) do
				local buffId = checkint(buffId_)
				local buffInfo = CommonUtils.GetConfig('common', 'payBuff', buffId)
				if nil ~= buffInfo then
					local costGoodsId = checkint(buffInfo.goodsConsume)
					local costGoodsAmount = checkint(buffInfo.goodsConsumeNum)
					local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)

					local bg = display.newImageView(_res('ui/worldboss/home/team_fight_flop_btn_select.png'), 0, 0)
					local bgSize = bg:getContentSize()
					local layer = display.newLayer(0, 0, {size = bgSize})
					display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(
						size.width * 0.5 + (bgSize.width + 25) * ((i - 0.5) - (#buffConfig.buffId * 0.5)),
						size.height * 0.55
					)})
					self:addChild(layer, 2)

					display.commonUIParams(bg, {po = utils.getLocalCenter(layer)})
					layer:addChild(bg, 1)

					local shine = display.newImageView(_res('ui/worldboss/home/team_fight_flop_btn_light.png'), 0, 0)
					display.commonUIParams(shine, {po = cc.p(
						bg:getPositionX(),
						bg:getPositionY()
					)})
					layer:addChild(shine)
					shine:setVisible(false)

					local btn = display.newButton(0, 0, {size = bgSize, cb = handler(self, self.SelectBuffBtnClickHandler)})
					display.commonUIParams(btn, {po = utils.getLocalCenter(layer)})
					layer:addChild(btn)
					btn:setTag(checkint(buffId))

					-- 消耗信息
					local consumeBg = display.newImageView(_res('ui/worldboss/home/world_boss_bg_price.png'), 0, 0)
					display.commonUIParams(consumeBg, {po = cc.p(
						bgSize.width * 0.5 - 1,
						13 + consumeBg:getContentSize().height * 0.5
					)})
					bg:addChild(consumeBg)

					local consumeLabel = display.newLabel(0, 0, fontWithColor('19', {text = tostring(costGoodsAmount)}))
					consumeBg:addChild(consumeLabel)

					local consumeIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(costGoodsId)), 0, 0)
					consumeBg:addChild(consumeIcon)
					consumeIcon:setScale(0.18)

					if 0 == costGoodsAmount then
						-- 消耗为0 显示免费
						consumeLabel:setString(__('免费'))
						consumeIcon:setVisible(false)
						display.commonUIParams(consumeLabel, {po = utils.getLocalCenter(consumeBg)})
					else
						display.setNodesToNodeOnCenter(consumeBg, {consumeLabel, consumeIcon})
					end

					-- 技能信息
					local skillIconScale = 0.5
					local skillIcon = display.newImageView(_res(CardUtils.GetSkillIconBySkillId(checkint(buffInfo.skillId))))
					skillIcon:setScale(skillIconScale)
					display.commonUIParams(skillIcon, {po = cc.p(
						bgSize.width * 0.5,
						bgSize.height * 0.5 + 50
					)})
					layer:addChild(skillIcon, 10)

					local skillIconCover = display.newImageView(_res('ui/worldboss/home/world_boss_icon_skill_frame.png'), 0, 0)
					display.commonUIParams(skillIconCover, {po = utils.getLocalCenter(skillIcon)})
					skillIcon:addChild(skillIconCover)

					local skillBtn = display.newButton(0, 0, {
						size = cc.size(skillIcon:getContentSize().width * skillIconScale, skillIcon:getContentSize().height * skillIconScale),
						cb = handler(self, self.SkillIconBtnClickHandler)
					})
					display.commonUIParams(skillBtn, {po = cc.p(
						skillIcon:getPositionX(),
						skillIcon:getPositionY()
					)})
					layer:addChild(skillBtn, 12)
					skillBtn:setTag(buffId)

					local skillNameLabel = display.newLabel(0, 0, fontWithColor('5', {text = tostring(buffInfo.name), color = '#b83d00'}))
					display.commonUIParams(skillNameLabel, {po = cc.p(
						skillIcon:getPositionX(),
						skillIcon:getPositionY() - skillIcon:getContentSize().height * 0.5 * skillIconScale - 20
					)})
					bg:addChild(skillNameLabel)

					local skillDescrLabel = display.newLabel(0, 0, fontWithColor('16', {text = buffInfo.descr, w = bgSize.width - 30, hAlign = display.TAC}))
					display.commonUIParams(skillDescrLabel, {po = cc.p(
						skillNameLabel:getPositionX(),
						skillNameLabel:getPositionY() - 50
					)})
					bg:addChild(skillDescrLabel)

					buffNodes[tostring(buffId)] = {
						layer = layer,
						shine = shine,
						skillIcon = skillIcon
					}
				end
			end
		end
	end

	self.viewData.buffNodes = buffNodes
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据数据刷新界面
@params leftChallengeTime int 剩余挑战次数
@params teamData table 阵容数据
--]]
function WorldBossBuffView:RefreshUI(leftChallengeTime, teamData)
	self:RefreshLeftChallengeTime(leftChallengeTime)
	self:RefreshTeamMember(teamData)
end
--[[
刷新剩余次数
@params leftChallengeTime int 剩余次数
--]]
function WorldBossBuffView:RefreshLeftChallengeTime(leftChallengeTime)
	self.viewData.leftChallengeTimeLabel:setString(string.format(__('今日剩余次数:%d'), leftChallengeTime))
end
--[[
刷新阵容
@params teamData table
--]]
function WorldBossBuffView:RefreshTeamMember(teamData)
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local cardHeadNode = self.viewData.teamCardHeadNodes[i]
		if nil ~= cardHeadNode then
			cardHeadNode:removeFromParent()
		end
	end
	self.viewData.teamCardHeadNodes = {}

	for i,v in ipairs(teamData) do
		local nodes = self.viewData.emptyCardNodes[i]
		if nil ~= v.id and 0 ~= checkint(v.id) then
			local c_id = checkint(v.id)
			local cardHeadNode = require('common.CardHeadNode').new({
				id = c_id,
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
			local scale = (cardHeadNodeSize.width) / cardHeadNode:getContentSize().width
			cardHeadNode:setScale(scale)
			display.commonUIParams(cardHeadNode, {po = cc.p(
				nodes.emptyCardHeadBg:getPositionX(),
				nodes.emptyCardHeadBg:getPositionY()
			)})
			self.viewData.bottomLayer:addChild(cardHeadNode)

			self.viewData.teamCardHeadNodes[i] = cardHeadNode
		end
	end
end
--[[
根据购买的buff id刷新界面
@params buffId int 
--]]
function WorldBossBuffView:RefreshByBuyBuffId(buffId)
	for buffId_, nodes in pairs(self.viewData.buffNodes) do
		if nil == buffId then
			nodes.layer:setLocalZOrder(2)
			nodes.shine:setVisible(false)
		elseif buffId == checkint(buffId_) then
			nodes.layer:setLocalZOrder(2)
			nodes.shine:setVisible(true)
		else
			nodes.layer:setLocalZOrder(0)
			nodes.shine:setVisible(false)
		end
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
关界面回调
--]]
function WorldBossBuffView:CloseSelfClickHandler(sender)
	PlayAudioByClickClose()
	uiMgr:GetCurrentScene():RemoveDialog(self)
end
--[[
选卡按钮回调
--]]
function WorldBossBuffView:EditTeamMemberClickHandler(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_EDIT_TEAM_MEMBER')
end
--[[
战斗按钮回调
--]]
function WorldBossBuffView:BattleBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_ENTER_BATTLE', {buffId = self.buyBuffId})
end
--[[
注册信号
--]]
function WorldBossBuffView:RegistSignal()
	------------ 阵容变更 ------------
	AppFacade.GetInstance():RegistObserver(WB_CHANGE_TEAM_MEMBER_SIGNAL, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:RefreshTeamMember(data.teamData)
	end, self))
	------------ 阵容变更 ------------
end
--[[
注销信号
--]]
function WorldBossBuffView:UnregistSignal()
	AppFacade.GetInstance():UnRegistObserver(WB_CHANGE_TEAM_MEMBER_SIGNAL, self)
end
--[[
选buff按钮回调
--]]
function WorldBossBuffView:SelectBuffBtnClickHandler(sender)
	PlayAudioByClickNormal()

	if nil ~= self.buyBuffId then return end

	local buffId = sender:getTag()
	self:SelectBuff(buffId)
end
--[[
选buff回调
@params buffId int buffid
--]]
function WorldBossBuffView:SelectBuff(buffId)
	if nil ~= self.selectedBuffId then
		local preNodes = self.viewData.buffNodes[tostring(self.selectedBuffId)]
		if nil ~= preNodes then
			preNodes.shine:setVisible(false)
		end
	end

	if nil ~= buffId and buffId ~= self.selectedBuffId then
		-- 选中了一个buff
		local curNodes = self.viewData.buffNodes[tostring(buffId)]
		if nil ~= curNodes then
			curNodes.shine:setVisible(true)
		end
	end

	if buffId == self.selectedBuffId then
		self.selectedBuffId = nil
	else
		self.selectedBuffId = buffId

		-- 显示购买弹窗
		local buffInfo = CommonUtils.GetConfig('common', 'payBuff', buffId)
		local costGoodsId = checkint(buffInfo.goodsConsume)
		local costGoodsAmount = checkint(buffInfo.goodsConsumeNum)

		if 0 < costGoodsAmount then
			local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)
			-- 有消耗
			local layer = require('common.CommonTip').new({
				defaultRichPattern = true,
				textRich = {
					{text = __('是否消耗')},
					{text = string.format('%d%s', costGoodsAmount, tostring(costGoodsConfig.name)), color = '#ff0000'},
					{text = __('购买祝福')},
				},
				descr = __('（警告：祝福一旦购买不可更改，有效期为一次战斗）'),
				costInfo = {goodsId = costGoodsId, num = costGoodsAmount},
				callback = function (sender)
					self:BuyBuff(buffId)
				end
			})
			layer:setPosition(display.center)
			uiMgr:GetCurrentScene():AddDialog(layer)
		else
			-- 无消耗
			local layer = require('common.CommonTip').new({
				text = __('是否确定选择该祝福？'),
				descr = __('（警告：一旦选择不可更改，有效期为一次战斗）'),
				callback = function (sender)
					self:BuyBuff(buffId)
				end
			})
			layer:setPosition(display.center)
			uiMgr:GetCurrentScene():AddDialog(layer)
		end
	end
end
--[[
购买buff
@params buffId int buff id
--]]
function WorldBossBuffView:BuyBuff(buffId)
	AppFacade.GetInstance():DispatchObservers('WB_BUY_BUFF', {buffId = buffId})
end
--[[
购买了buff的回调
--]]
function WorldBossBuffView:BuyBuffCallback(buffId)
	self.buyBuffId = buffId
	self:RefreshByBuyBuffId(self.buyBuffId)
end
--[[
技能按钮回调
--]]
function WorldBossBuffView:SkillIconBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local buffId = sender:getTag()
	self:ShowSkillDetail(buffId)
end
--[[
根据buffid显示技能详情
@params buffId int buff id
--]]
function WorldBossBuffView:ShowSkillDetail(buffId)
	local buffConfig = CommonUtils.GetConfig('common', 'payBuff', buffId)
	if nil ~= buffConfig then
		local skillId = checkint(buffConfig.skillId)
		local skillConfig = CommonUtils.GetSkillConf(skillId)
		if nil ~= skillConfig then
			local nodes = self.viewData.buffNodes[tostring(buffId)]
			uiMgr:ShowInformationTipsBoard({
				targetNode = nodes.skillIcon,
				title = tostring(skillConfig.name),
				descr = tostring(skillConfig.descr),
				type = 5
			})
		end
	end
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- get set end --
---------------------------------------------------

function WorldBossBuffView:onCleanup()
	self:UnregistSignal()
end

return WorldBossBuffView
