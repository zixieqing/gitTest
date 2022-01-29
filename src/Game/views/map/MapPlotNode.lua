--[[
地图上关卡node
@params table {
	stageId int 关卡id
	lock bool 是否解锁
	no int 关卡在章节上的序号
	star int 星级
	cb function 点击回调
	isCurrentStage bool 是否是当前最新的关卡
}
--]]
local MapPlotNode = class('MapPlotNode', function ()
	local node = CColorView:create()
	node.name = 'Game.views.map.MapPlotNode'
	node:enableNodeEvents()
	return node
end)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local RES_DICT = {
	MAPS_BTN_PLOT  = _res('ui/map/maps_btn_plot.png')
}
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
contructor
--]]
function MapPlotNode:ctor( ... )
	local args = unpack({...})

	self.stageId        = args.stageId
	self.questPlotId    = args.questPlotId
	self.no             = args.no
	self.lock           = args.lock
	self.star           = args.star
	self.isCurrentStage = args.isCurrentStage
	self.plotConf       = args.plotConf or {}

	self:InitUI()
end
--[[
init ui
--]]
function MapPlotNode:InitUI()

	local stageConf = CommonUtils.GetConfig('quest', 'quest', checkint(self.stageId))

	local function CreateView()

		local bg = nil
		local bgPos = nil
		local size = nil
		local scale = 1
		
		local path = _res(string.format('ui/map/%s', self.plotConf.icon))
		local icon = utils.isExistent(path) and path or RES_DICT.MAPS_BTN_PLOT
		local bg = FilteredSpriteWithOne:create(icon)
		bg:setAnchorPoint(display.LEFT_BOTTOM)
		local size = bg:getContentSize()
		self:setContentSize(size)

		display.commonUIParams(bg, {ap = cc.p(0.5, 0), po = bgPos or cc.p(size.width * 0.5, -10)})
		self:addChild(bg, 5)

		-- 节点阴影
		local shadow = display.newNSprite(_res('ui/common/maps_ico_monster_shadow.png'), size.width * 0.5, 0)
		shadow:setScale(0.5)
		self:addChild(shadow, 1)

		
		-- local stageNoBg = display.newNSprite(_res('ui/map/maps_bg_checkpoint_number.png'), 0, 0)
		-- display.commonUIParams(stageNoBg, {po = cc.p(
		-- 	size.width * 0.5,
		-- 	-15 - stageNoBg:getContentSize().height * 0.5
		-- )})
		-- self:addChild(stageNoBg, 20)

		-- local stageNoLabel = display.newLabel(utils.getLocalCenter(stageNoBg).x, utils.getLocalCenter(stageNoBg).y,
		-- 	fontWithColor(9,{text = string.format('%s-%s', stageConf.cityId, tostring(self.no)) }))
		-- stageNoBg:addChild(stageNoLabel)

		local stageNoBg = display.newButton(0, 0, {n = _res('ui/map/maps_bg_checkpoint_number.png'), scale9 = true, enable = false})
		display.commonUIParams(stageNoBg, {po = cc.p(
			size.width * 0.5,
			-15 - stageNoBg:getContentSize().height * 0.5
		)})
		display.commonLabelParams(stageNoBg, fontWithColor(9, {text = tostring(self.plotConf.name), paddingW = 15}))
		self:addChild(stageNoBg, 20)

		self.cityId = stageConf.cityId

        local view = CLayout:create(cc.size(160,140))
        view:setName('CELL_IMAGE')
        view:setAnchorPoint(cc.p(0.5, 0))
        view:setPosition(cc.p(size.width * 0.5, 0))
		self:addChild(view, 20)
		
		require('common.RemindIcon').addRemindIcon({parent = bg, tag = app.badgeMgr:GetPlotRemindTag(self.questPlotId), po = cc.p(size.width - 20, size.height - 25)})

		return {
			bg = bg,
			stageNoLabel = stageNoBg:getLabel()
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)


	------------ 设置回调 ------------

	self:setTouchEnabled(true)
	self:setOnClickScriptHandler(function (sender)
		app:DispatchObservers('MAP_PLOT_CLICK_EVENT', {stageId = self.stageId, questPlotId = self.questPlotId, stageName = string.format('%s-%s', stageConf.cityId, tostring(self.no))})
	end)
	------------ 设置回调 ------------

	------------ 设置灰化 ------------
	if self.lock then
		-- if
		self.viewData.bg:setFilter(filter.newFilter('GRAY'))
	end
	------------ 设置灰化 ------------

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------

---------------------------------------------------
-- view control end --
---------------------------------------------------

return MapPlotNode
