--[[
探索系统探索页面UI
--]]
local ExplorationBattleView = class('ExplorationBattleView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ExplorationBattleView'
	node:enableNodeEvents()
	node:setAnchorPoint(cc.p(0, 0))
	return node
end)

function ExplorationBattleView:ctor( ... )
	self.viewData_ = nil
	self.args = unpack({...})
	local mapsNum = self.args.photo
	local function CreateView()
		local view = CLayout:create(cc.size(display.width, 1002))
    	view:setPosition(cc.p(display.cx, display.cy))
    	local bgSize = cc.size(2000, 1002)
    	local bgTable = {}
    	local POS_Z = {
    		15,
    		5,
    		5,
    		3,
    		1
 	   }
    	local function createBg( type, posZ )
    		bgTable[type] = {}
    		local bg = display.newImageView(_res('ui/home/exploration/maps/explore_maps_' .. tostring(mapsNum) .. '_' .. tostring(type) ..'.png'), 0, 0, {ap = cc.p(0, 0)})
    		view:addChild(bg, posZ)
    		table.insert(bgTable[type], bg)
    		local bgNext = display.newImageView(_res('ui/home/exploration/maps/explore_maps_' .. tostring(mapsNum) .. '_' .. tostring(type) .. '.png'), bgSize.width, 0, {ap = cc.p(0, 0)})
    		view:addChild(bgNext, posZ)
    		table.insert(bgTable[type], bgNext)

    	end
    	for i=5, 1, -1 do
    		createBg(i, POS_Z[i])
    	end
		return {
			view  		= view,
			-- bg   		= bg,
			bgTable     = bgTable,
			-- bgNext  	= bgNext,
			bgSize  	= bgSize,
			-- retreatBtn  = retreatBtn,
			-- continueBtn = continueBtn
		}
	end
	xTry(function ( )
		self.viewData_ = CreateView( )
		self:addChild(self.viewData_.view, 1)
	end, __G__TRACKBACK__)
	
end

return ExplorationBattleView