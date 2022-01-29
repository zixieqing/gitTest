--[[
探索等级提升界面

-- @param data table {
	level 			int boss等级
	exploreModuleId int 探索模块id
	nextBossLevelLeftDiscoveryTimes int BOSS下次升级剩余发现次数
}
--]]
local display = display
local Anniversary19ExploreLevelUpgradeView = class('Anniversary19ExploreLevelUpgradeView', function ()
	local node = CLayout:create(display.size)
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'Game.views.anniversary19.Anniversary19ExploreLevelUpgradeView'
	node:enableNodeEvents()
	return node
end)

local CreateView

local RES_DICT = {
	WONDERLAND_EXPLORE_BG_COMMON = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_bg_common.png'),
	COMMON_BTN_ORANGE            = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange.png'),
}

function Anniversary19ExploreLevelUpgradeView:ctor( ... )
	local args = unpack({...}) or {}
	self.descText = string.split(app.anniversary2019Mgr:GetPoText(__('在|_chapterName_|中，能探索到的|_bossName_|的等级提升了')), '|')
	local data = self:InitData_(args)
	self.viewData_ = CreateView(data)
	self:addChild(self.viewData_.view, 1)

	display.commonUIParams(self.viewData_.confirmBtn,{cb = function (params)
		app.uiMgr:GetCurrentScene():RemoveDialog(self)
	end, animate = false})
end

function Anniversary19ExploreLevelUpgradeView:InitData_(args)
	local level                           = args.level
	local exploreModuleId                 = args.exploreModuleId
	local nextBossLevelLeftDiscoveryTimes = args.nextBossLevelLeftDiscoveryTimes
	
	local chapterConf = CommonUtils.GetConfig('anniversary2', 'chapter', exploreModuleId) or {}
	local exploreConf = CommonUtils.GetConfig('anniversary2', 'explore', exploreModuleId) or {}
	local desc = {}
	for index, text in ipairs(self.descText) do
		if text == '_chapterName_' then
			table.insert(desc, {color = '#ffaa6e', fontSize = 22, text = tostring(exploreConf.name)})
		elseif text == '_bossName_' then
			table.insert(desc, {color = '#ffffff', fontSize = 26, text = tostring(chapterConf.bossName)})
		else
			table.insert(desc, {color = '#ffaa6e', fontSize = 22, text = text})
		end
	end

	return {
		level = level,
		exploreModuleId = exploreModuleId,
		nextBossLevelLeftDiscoveryTimes = nextBossLevelLeftDiscoveryTimes,
		desc = desc,
	}
end


CreateView = function (data)
	local view = display.newLayer()
	local size = view:getContentSize()

	-- block layer
	local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
	view:addChild(blockLayer)

	local bgSize = cc.size(480, 530)
	local middleX, middleY = bgSize.width * 0.5, bgSize.height * 0.5

	local bgLayer = display.newLayer(size.width * 0.5, size.height * 0.5, {ap = display.CENTER, size = bgSize})
	view:addChild(bgLayer)

	bgLayer:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,0)}))

	local bg = display.newImageView(RES_DICT.WONDERLAND_EXPLORE_BG_COMMON, middleX, middleY, 
		{scale9 = true, size = bgSize, capInsets = cc.rect(200, 100, 10, 10)})
	bgLayer:addChild(bg)
	
	-- 等级提示标签
	local upgradeTipLabel = display.newLabel(middleX, bgSize.height - 25, {text = app.anniversary2019Mgr:GetPoText(__('等级提升')), fontSize = 24, color = '#e5b156'})
	bgLayer:addChild(upgradeTipLabel)

	-- boss 头像节点
	local bossHeadNode = require('Game.views.anniversary19.Anniversary19ExploreBossHeadNode').new(data)
	display.commonUIParams(bossHeadNode, {ap = display.CENTER, po = cc.p(middleX, bgSize.height - 130)})
	bgLayer:addChild(bossHeadNode)

	-- 描述标签
	local descLabel = display.newRichLabel(middleX, middleY + 40, {ap = display.CENTER_TOP, r = true, w = 26, c = data.desc})
	-- if isElexSdk() or isJapanSdk() then
	-- 	descLabel = display.newLabel(middleX, middleY + 40, {ap = display.CENTER_TOP, w = 300, fontSize = 22, color = '#ffaa6e'})
	-- else
	-- 	descLabel = display.newRichLabel(middleX, middleY + 40, {ap = display.CENTER_TOP, w = 26, c = data.desc})
	-- end
	bgLayer:addChild(descLabel)

	-- 下次升级提示
	local isShowUpgradeTip = nextBossLevelLeftDiscoveryTimes ~= 0
	local nextBossLevelLeftDiscoveryTimes = checkint(data.nextBossLevelLeftDiscoveryTimes)
	local nextUpgradeTip = isShowUpgradeTip and string.format(app.anniversary2019Mgr:GetPoText(__('距离下次升级还需要发现：%s')), checkint(data.nextBossLevelLeftDiscoveryTimes)) or app.anniversary2019Mgr:GetPoText(__('已达到最大等级'))
	local nextUpgradeTipLabel = display.newLabel(middleX, 140, {
		hAlign = display.TAC, color = '#ffbf56', fontSize = 22, w = 295, text = nextUpgradeTip})
	nextUpgradeTipLabel:setVisible(isShowUpgradeTip)
	bgLayer:addChild(nextUpgradeTipLabel)

	-- 确定按钮
	local confirmBtn = display.newButton(middleX, 60, {n = RES_DICT.COMMON_BTN_ORANGE})
	display.commonLabelParams(confirmBtn, fontWithColor('14', {text = app.anniversary2019Mgr:GetPoText(__('确定'))}))
	bgLayer:addChild(confirmBtn)

	return {
		view                = view,
		blockLayer          = blockLayer,
		bossHeadNode        = bossHeadNode,
		descLabel           = descLabel,
		nextUpgradeTipLabel = nextUpgradeTipLabel,
		confirmBtn          = confirmBtn,
	}
end

function Anniversary19ExploreLevelUpgradeView:GetViewData()
	return self.viewData_
end

return Anniversary19ExploreLevelUpgradeView
