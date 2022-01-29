--[[
怪物介绍界面
@params table {
	monsterId int 怪物id
}
--]]
local GameScene = require( "Frame.GameScene" )
local MonsterIntroductionView = class("MonsterIntroductionView", GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function MonsterIntroductionView:ctor(...)
	local args = unpack({...})
	GameScene.ctor(self, 'common.MonsterIntroductionView')

	dump(args)
	self.monsterId = args.monsterId

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化界面
--]]
function MonsterIntroductionView:InitUI()
	local function CreateView()
		local size = self:getContentSize()

		-- 遮罩
		local eaterLayer = display.newLayer(0, 0,
			{size = size, color = cc.c4b(0, 0, 0, 255 * 0.75), animate = false, enable = true, cb = handler(self, self.CloseSelfClickHandler)})
		display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(eaterLayer)

		-- 返回按钮
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = handler(self, self.CloseSelfClickHandler)})
	    backBtn:setName('backBtn')
	    display.commonUIParams(backBtn, {po = cc.p(
	    	display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30,
	    	display.size.height - 18 - backBtn:getContentSize().height * 0.5
	    )})
	    self:addChild(backBtn, 5)

	    -- 列表
	    local listViewBg = display.newImageView(_res('ui/bossdetail/bosspokedex_bg.png'), 0, 0)
	    display.commonUIParams(listViewBg, {po = cc.p(
	    	size.width * 0.75,
	    	size.height * 0.5
	    )})
	    self:addChild(listViewBg, 2)

	    local listViewBgSize = listViewBg:getContentSize()
	    local listViewSize = cc.size(listViewBgSize.width, listViewBgSize.height - 10)
	    local listView = CListView:create(listViewSize)
	    listView:setDirection(eScrollViewDirectionVertical)
	    listView:setAnchorPoint(cc.p(0.5, 0.5))
	    listView:setPosition(cc.p(
	    	listViewBg:getPositionX(),
	    	listViewBg:getPositionY()
	    ))
	    self:addChild(listView, 3)
	    -- listView:setBackgroundColor(cc.c4b(255, 128, 0, 180))

		return {
			listView = listView,
			drawNode = nil
		}
	end

	xTry(function ()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	self:RefreshUIByMonsterId(self.monsterId)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据id刷新界面
@params monsterId int 怪物id
--]]
function MonsterIntroductionView:RefreshUIByMonsterId(monsterId)
	local monsterInfo = self:GetFormattedMonsterInfo(monsterId)
	if nil ~= monsterInfo then
		self:RefreshListViewByMonsterInfo(monsterInfo)
		self:RefreshDrawNodeBySkinId(monsterInfo.skinId)
	end
end
--[[
根据数据刷新listview中显示的详细信息
@params monsterInfo table 怪物信息
--]]
function MonsterIntroductionView:RefreshListViewByMonsterInfo(monsterInfo)
	local listViewSize = self.viewData.listView:getContentSize()

	-- 名字
	local titleCellSize = cc.size(listViewSize.width, 60)
	local titleCell = display.newLayer(0, 0, {size = titleCellSize})
	self.viewData.listView:insertNodeAtLast(titleCell)
	-- titleCell:setBackgroundColor(math.random(255), math.random(255), math.random(255), 128)

	local nameBg = display.newNSprite(_res('ui/bossdetail/bosspokedex_name_bg.png'), 0, 0)
	display.commonUIParams(nameBg, {po = cc.p(
		titleCellSize.width * 0.5,
		titleCellSize.height * 0.5 - 10
	)})
	titleCell:addChild(nameBg)

	local nameLabel = display.newLabel(0, 0, fontWithColor('14', {text = monsterInfo.name, fontSize = 30, color = '#ffffff'}))
	display.commonUIParams(nameLabel, {ap = cc.p(0.5, 0), po = cc.p(
		nameBg:getContentSize().width * 0.5 - 10,
		5
	)})
	nameBg:addChild(nameLabel)

	-- 描述
	local descrCell = self:GetMonsterDescrCellByDescr(monsterInfo.descr)
	self.viewData.listView:insertNodeAtLast(descrCell)

	-- 技能
	for i,v in ipairs(monsterInfo.showSkill) do
		local skillCell = self:GetSkillCellBySkillId(checkint(v))
		if nil ~= skillCell then
			self.viewData.listView:insertNodeAtLast(skillCell)
		end
	end


	self.viewData.listView:reloadData()
end
--[[
根据描述获取怪物的描述框
@params descr string 描述
@return descrCell cc.node 描述cell
--]]
function MonsterIntroductionView:GetMonsterDescrCellByDescr(descr)
	local descrCellSize = cc.size(self.viewData.listView:getContentSize().width, 0)
	local paddingX = 40 -- 相对于cell的间距
	local paddingY = 10 -- 相对于背景图的间距

	local descrBg = display.newImageView(_res('ui/bossdetail/bosspokedex_boss_bg_words.png'), 0, 0,
		{scale9 = true})
	local oriDescrBgSize = descrBg:getContentSize()
	local descrBgSize = cc.size(oriDescrBgSize.width, oriDescrBgSize.height)

	-- 获取label尺寸
	local descrLabel = display.newLabel(0, 0,
		{text = descr, fontSize = 22, color = '#cebba4', w = descrCellSize.width - 80})
	local labelSize = display.getLabelContentSize(descrLabel)

	-- 修正size大小
	descrBgSize.height = math.max(oriDescrBgSize.height, labelSize.height + paddingY * 2)
	descrCellSize.height = descrBgSize.height + 10

	-- 创建cell
	local descrCell = display.newLayer(0, 0, {size = descrCellSize})

	-- 修正背景
	descrBg:setContentSize(descrBgSize)
	display.commonUIParams(descrBg, {ap = cc.p(0.5, 0.5), po = cc.p(
		descrCellSize.width * 0.5,
		descrCellSize.height * 0.5
	)})
	descrCell:addChild(descrBg)

	-- 修正描述文字
	display.commonUIParams(descrLabel, {ap = cc.p(0, 1), po = cc.p(
		paddingX,
		descrBg:getPositionY() + descrBg:getContentSize().height * 0.5 - paddingY
	)})
	descrCell:addChild(descrLabel)

	return descrCell
end
--[[
根据技能id获取技能cell
@params skillId int 技能id
@return skillCell cc.node 技能cell
--]]
function MonsterIntroductionView:GetSkillCellBySkillId(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	if nil == skillConfig then
		return nil
	end

	local skillCellSize = cc.size(self.viewData.listView:getContentSize().width, 0)

	local skillBgT = display.newImageView(_res('ui/bossdetail/bosspokedex_titile_skill.png'), 0, 0)
	local skillBgTSize = skillBgT:getContentSize()

	local skillBgB = display.newImageView(_res('ui/bossdetail/bosspokedex_skill_bg_words.png'), 0, 0, {scale9 = true, capInsets = cc.rect(80, 50, 10, 10)})
	local skillBgBSize = skillBgB:getContentSize()

	local skillDescr = cardMgr.GetSkillDescr(skillId, 1)
	local skillDescrLabel = display.newLabel(0, 0, fontWithColor('16', {text = skillDescr, w = skillCellSize.width - 80}))
	local skillDescrLabelSize = display.getLabelContentSize(skillDescrLabel)

	local skillDescrPaddingT = 20
	local skillDescrPaddingB = 20

	-- 检查大小 修正背景图的大小
	if skillDescrLabelSize.height > skillBgBSize.height - skillDescrPaddingT - skillDescrPaddingB then
		skillBgBSize.height = skillDescrLabelSize.height + skillDescrPaddingT + skillDescrPaddingB
	end
	skillBgB:setContentSize(skillBgBSize)

	-- 计算cell大小
	local spaceTB = -10
	skillCellSize.height = skillBgTSize.height + skillBgBSize.height + spaceTB + 10

	local skillCell = display.newLayer(0, 0, {size = skillCellSize})

	-- 修正两张底图
	display.commonUIParams(skillBgT, {po = cc.p(
		skillCellSize.width * 0.5,
		skillCellSize.height * 0.5 + (skillBgTSize.height + skillBgBSize.height + spaceTB) * 0.5 - skillBgTSize.height * 0.5
	)})
	skillCell:addChild(skillBgT, 5)

	display.commonUIParams(skillBgB, {po = cc.p(
		skillCellSize.width * 0.5,
		skillCellSize.height * 0.5 - (skillBgTSize.height + skillBgBSize.height + spaceTB) * 0.5 + skillBgBSize.height * 0.5
	)})
	skillCell:addChild(skillBgB)

	-- 修正文字位置
	display.commonUIParams(skillDescrLabel, {ap = cc.p(0, 1), po = cc.p(
		40,
		skillBgB:getPositionY() + skillBgB:getContentSize().height * 0.5 - skillDescrPaddingT
	)})
	skillCell:addChild(skillDescrLabel)

	-- 技能名字
	local skillNameLabel = display.newLabel(0, 0, fontWithColor('3', {text = tostring(skillConfig.name)}))
	display.commonUIParams(skillNameLabel, {ap = cc.p(0, 0.5), po = cc.p(
		40,
		skillBgT:getPositionY()
	)})
	skillCell:addChild(skillNameLabel, 10)

	return skillCell
end
--[[
根据怪物皮肤id刷新立绘
--]]
function MonsterIntroductionView:RefreshDrawNodeBySkinId(skinId)
	if nil == self.viewData.drawNode then
		local drawNode = require('common.CardSkinDrawNode').new({
			skinId = skinId,
			coordinateType = COORDINATE_TYPE_HOME
		})
		self:addChild(drawNode, 1)

		self.viewData.drawNode = drawNode
	else
		self.viewData.drawNode:RefreshAvatar({
			skinId = skinId
		})
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
关闭按钮回调
--]]
function MonsterIntroductionView:CloseSelfClickHandler(sender)
	PlayAudioByClickClose()
	uiMgr:GetCurrentScene():RemoveDialog(self)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据怪物id获取格式化后的怪物信息
@params monsterId int 怪物id
@return monsterInfo table 怪物信息
--]]
function MonsterIntroductionView:GetFormattedMonsterInfo(monsterId)
	local config_ = nil
	if monsterId >= 990000 then
		-- 神兽幼崽
		config_ = cardMgr.GetBeastBabyConfig(monsterId)
	else
		config_ = CardUtils.GetCardConfig(monsterId)
	end

	if nil ~= config_ then
		local monsterInfo = {
			name = tostring(config_.name),
			descr = tostring(config_.descr),
			showSkill = checktable(config_.showSkill),
			skinId = checkint(config_.skinId)
		}
		return monsterInfo
	else
		return nil
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return MonsterIntroductionView
