--[[
探索boss头像节点
--]]
local display = display
local VIEW_SIZE = cc.size(130, 130)
local Anniversary19ExploreBossHeadNode = class('Anniversary19ExploreBossHeadNode', function ()
	local node = CLayout:create(VIEW_SIZE)
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'Game.views.anniversary19.Anniversary19ExploreBossHeadNode'
	node:enableNodeEvents()
	return node
end)

local CreateView

local RES_DICT = {
	WONDERLAND_EXPLORE_MAIN_ICO_BOSS_1  = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_boss_1.png'),
	WONDERLAND_EXPLORE_MAIN_ICO_BOSS_2  = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_boss_2.png'),
	WONDERLAND_EXPLORE_MAIN_ICO_BOSS_3  = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_boss_3.png'),
	WONDERLAND_EXPLORE_MAIN_LABEL_LEVEL = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_label_level.png'),
}

function Anniversary19ExploreBossHeadNode:ctor( ... )
	local args = unpack({...}) or {}
	self.viewData_ = CreateView(VIEW_SIZE)
	self:addChild(self.viewData_.view, 1)
	
	if next(args) then
		self:UpdateUI(args)
	end
end

function Anniversary19ExploreBossHeadNode:UpdateUI(params)
	local exploreModuleId = checkint(params.exploreModuleId)
	local level           = checkint(params.level)

	local viewData = self:GetViewData()
	if exploreModuleId > 0 then
		viewData.bossIcon:setTexture(RES_DICT[string.format('WONDERLAND_EXPLORE_MAIN_ICO_BOSS_%s', exploreModuleId)])
	end

	if level > 0 then
		self:UpdateBossLevel(level)
	end
end

function Anniversary19ExploreBossHeadNode:UpdateBossLevel(level)
	local viewData = self:GetViewData()
	viewData.bossLevel:setString(level)
end

CreateView = function (size)
	local view = display.newLayer(0, 0, {size = size})

	local touchView = display.newLayer(0, 0, {size = size, color = cc.c4b(0, 0, 0, 0), enable = true})
	view:addChild(touchView)

	--boss 图标
    local bossIcon = display.newImageView(RES_DICT.WONDERLAND_EXPLORE_MAIN_ICO_BOSS_1,
            size.width * 0.5, size.height * 0.5, {ap = display.CENTER})
    view:addChild(bossIcon, 1)

    --boss 等级背景
    local bossLevelBg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_MAIN_LABEL_LEVEL, 65, -5,
            {ap = display.CENTER_BOTTOM})
    bossIcon:addChild(bossLevelBg)

    --boss 等级
    local bossLevel = CLabelBMFont:create('1', 'font/small/common_text_num.fnt')
    bossLevel:setBMFontSize(28)
    display.commonUIParams(bossLevel, {ap = display.CENTER, po = cc.p(20, 20)})
    bossLevelBg:addChild(bossLevel)

	return {
		view      = view,
		touchView = touchView,
		bossIcon  = bossIcon,
		bossLevel = bossLevel,
	}
end

function Anniversary19ExploreBossHeadNode:GetViewData()
	return self.viewData_
end

return Anniversary19ExploreBossHeadNode
