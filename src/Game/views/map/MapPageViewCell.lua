--[[
地图标签页
@params table {
	size cc.size 页签大小
}
--]]
local MapPageViewCell = class('MapPageViewCell', function ()
	local node = CPageViewCell:new()
    node.name = 'Game.views.map.MapPageViewCell'
    node:setName('MapPageViewCell')
    return node
end)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
constructor
--]]
function MapPageViewCell:ctor( ... )
	self.args = unpack({...})

	self.mapData    = nil
	self.cellSize   = self.args.size
	self.stageNodes = {}
	self.plotNodes  = {}



	self:setContentSize(self.cellSize)

	self:InitUI()
end
--[[
初始化
--]]
function MapPageViewCell:InitUI()

	local function CreateView()

		return {
			bg = nil,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新所有ui
@params data table 刷新数据 {
	chapterId int 章节id
	diffType DifficultyLevel
	starDatas table 星级信息
	newestStageId int 此难度最新关卡
}
--]]
function MapPageViewCell:RefresUI(data)
	self.mapData = data
	if nil == self.mapData then return end
	if nil == self.mapData.starDatas then
		self.mapData.starDatas = {}
	end
	self:RefreshPage()
end
--[[
刷新整张地图page
--]]
function MapPageViewCell:RefreshPage()
	local cityConf = CommonUtils.GetConfig('quest', 'city', checkint(self.mapData.chapterId))
	local cellSize = self:getContentSize()

	-- 刷新背景图
	local bgId = checkint(cityConf.backgroundId[tostring(self.mapData.diffType)])
	local bgPath = string.format('arts/maps/maps_bg_%s', bgId)
	local bgImg = self:getChildByTag(1223)
	if bgImg then bgImg:removeFromParent() end
    local bgView = CLayout:create(cc.size(1336,1002))
    local leftImage = display.newImageView(_res(string.format('%s_01', bgPath)), 0, 0, {ap = display.LEFT_BOTTOM})
    bgView:addChild(leftImage)
    local rightImage = display.newImageView(_res(string.format('%s_02', bgPath)), 1336, 0, {ap = display.RIGHT_BOTTOM})
    bgView:addChild(rightImage)
    display.commonUIParams(bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
    fullScreenFixScale(bgView)
    self:addChild(bgView)
	local bgSize = cc.size(1334,1002)

	-- 刷新关卡节点 先移除 后创建
	if table.nums(self.stageNodes) > 0 then
		for i,v in ipairs(self.stageNodes) do
			v:removeFromParent()
		end
		self.stageNodes = {}
	end
	if next(self.plotNodes) then
		for index, value in ipairs(self.plotNodes) do
			value:removeFromParent()
		end
		self.plotNodes = {}
	end
	local stageId = 0
	local stageConf = nil
	local stageLocation = cc.p(0, 0)
	local plotConf = nil
	local plotLocation = cc.p(0, 0)
	local questConf = cityConf.quests[tostring(self.mapData.diffType)]
	if questConf then
		
		for i,v in ipairs(questConf) do
			stageId = checkint(v)
			stageConf = CommonUtils.GetConfig('quest', 'quest', stageId)
			local star = 0
			if self.mapData.starDatas[tostring(stageId)] then
				star = checkint(self.mapData.starDatas[tostring(stageId)])
			end
			local stageNode = require('Game.views.map.MapStageNode').new({
				stageId = stageId,
				lock = stageId > checkint(self.mapData.newestStageId),
				no = i,
				star = star,
				isCurrentStage = stageId == checkint(self.mapData.newestStageId)
			})
            stageNode:setName(string.format('QUEST_%d', stageId))
			stageNode:setTag(stageId)
			self:addChild(stageNode)
			stageLocation.x = checkint(stageConf.location.x) + (cellSize.width - bgSize.width) * 0.5
			stageLocation.y = bgSize.height - checkint(stageConf.location.y) + (cellSize.height - bgSize.height) * 0.5
			display.commonUIParams(stageNode, {
				ap = cc.p(0.5, 0),
				po = stageLocation
			})
			stageNode:setLocalZOrder(display.height - math.round(stageLocation.y))
			table.insert(self.stageNodes, stageNode)

			local plotQuestConfData = checktable(app.gameMgr:GetUserInfo().plotQuestConfDatas)[tostring(stageId)]
			if app.gameMgr:IsOpenMapPlot() and plotQuestConfData and next(plotQuestConfData) then
				for index, plotConf in ipairs(plotQuestConfData) do
					local questPlotId = checkint(plotConf.id)
					
					local plotNode = require('Game.views.map.MapPlotNode').new({
						stageId        = stageId,
						questPlotId    = questPlotId,
						plotConf       = plotConf,
						lock           = not app.gameMgr:JudgePassedStageByStageId(stageId),
						no             = i,
						star           = star,
						isCurrentStage = stageId == checkint(self.mapData.newestStageId)
					})
					plotNode:setName(string.format('PLOT_%d', questPlotId))
					plotNode:setTag(questPlotId)
					self:addChild(plotNode)
					local position = checktable(plotConf.position)
					plotLocation = cc.p(checkint(position[1]), checkint(position[2]))
					plotLocation.x = checkint(plotLocation.x) + (cellSize.width - bgSize.width) * 0.5
					plotLocation.y = bgSize.height - checkint(plotLocation.y) + (cellSize.height - bgSize.height) * 0.5
					display.commonUIParams(plotNode, {
						ap = cc.p(0.5, 0),
						po = plotLocation
					}) 
					local zOrder = display.height - math.round(plotLocation.y)
					plotNode:setLocalZOrder(zOrder < 0 and 1 or zOrder)
					table.insert(self.plotNodes, plotNode)
				end
				
			end
		end
	end

end
---------------------------------------------------
-- view control end --
---------------------------------------------------


return MapPageViewCell
