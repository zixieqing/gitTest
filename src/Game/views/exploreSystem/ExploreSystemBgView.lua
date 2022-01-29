--[[
探索系统探索页面UI
--]]
local ExploreSystemBgView = class('ExploreSystemBgView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.exploreSystem.ExploreSystemBgView'
	node:enableNodeEvents()
	node:setAnchorPoint(cc.p(0, 0))
	return node
end)

local scheduler = require('cocos.framework.scheduler')

local BG_SIZE = cc.size(2000, 1002)

-- 背景移动速度
local BG_MOVE_SPEED = {
	8,
	4,
	3,
	2,
	4
}

local POS_Z = {
    15,
    5,
    5,
    3,
    1
}

local CreateView = nil
local createBg = nil

function ExploreSystemBgView:ctor( ... )
	self.viewData_ = nil
	self.args = unpack({...})
	self.photo = self.args.photo
	local function CreateView()
		local view = CLayout:create(cc.size(display.width, 1002))
    	view:setPosition(cc.p(display.cx, display.cy))
    	
    	local bgTable = {}
    	
    	local function createBg( type, posZ )
            
            bgTable[type] = {}
            local img = self:getExploreMapImg(self.photo, type)

            local bg = display.newImageView(img, 0, 0, {ap = cc.p(0, 0)})
    		view:addChild(bg, posZ)
            table.insert(bgTable[type], bg)
            
    		local bgNext = display.newImageView(img, BG_SIZE.width, 0, {ap = cc.p(0, 0)})
    		view:addChild(bgNext, posZ)
    		table.insert(bgTable[type], bgNext)

    	end
    	for i=5, 1, -1 do
    		createBg(i, POS_Z[i])
    	end
		return {
			view  		= view,
			bgTable     = bgTable,
			-- bgSize  	= bgSize,
		}
    end
    
	xTry(function ( )
		self.viewData_ = CreateView( )
		self:addChild(self.viewData_.view, 1)
	end, __G__TRACKBACK__)
	
end

-- function ExploreSystemBgView:createAllBg(parent)
--     local bgTable = {}
--     for type=5, 1, -1 do
--         bgTable[type] = {}
--         local img = self:getExploreMapImg(self.photo, type)
        
--         local posZ = POS_Z[type]
--         local bg = display.newImageView(img, 0, 0, {ap = cc.p(0, 0)})
--         parent:addChild(bg, posZ)
--         table.insert(bgTable[type], bg)
        
--         local bgNext = display.newImageView(img, BG_SIZE.width, 0, {ap = cc.p(0, 0)})
--         parent:addChild(bgNext, posZ)
--         table.insert(bgTable[type], bgNext)
--     end

--     return bgTable
-- end

function ExploreSystemBgView:getPhoto()
    return self.photo
end

function ExploreSystemBgView:setPhoto(photo)
    photo = checkint(photo)
    if self:getPhoto() ~= photo then
        self.photo = photo == 0 and '1' or tostring(photo)

        self:updateBgTable()
    end
end

function ExploreSystemBgView:updateBgTable()
    local viewData = self:getViewData()
    local photo = self:getPhoto()
    local bgTable = viewData.bgTable or {}
    
    for type_, v in ipairs(bgTable) do
        local img = self:getExploreMapImg(photo, type_)
        for __, bg in ipairs(v) do
            bg:setTexture(img)
        end
    end
end

function ExploreSystemBgView:createBgScheduler()
    self:removeBgScheduler()
    self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1/60)
end

function ExploreSystemBgView:scheduleCallback()
    local viewData = self:getViewData()
    local w = BG_SIZE.width
    for i, layer in ipairs(viewData.bgTable) do
        for _,bg in ipairs(layer) do
            if bg:getPositionX() - BG_MOVE_SPEED[i] <= -w then
                bg:setPositionX(bg:getPositionX() - BG_MOVE_SPEED[i] + 2 * w)
            else
                bg:setPositionX(bg:getPositionX() - BG_MOVE_SPEED[i])
            end
        end
    end
end

function ExploreSystemBgView:removeBgScheduler()
    -- 关闭定时器
	if self.scheduler then
        scheduler.unscheduleGlobal(self.scheduler)
        self.scheduler = nil
	end
end

function ExploreSystemBgView:getExploreMapImg(mapsNum, type)
   return  _res(string.format('ui/home/exploration/maps/explore_maps_%s_%s.png', tostring(mapsNum), tostring(type)))
end

function ExploreSystemBgView:getViewData()
    return self.viewData_
end

function ExploreSystemBgView:onCleanup()
    self:removeBgScheduler()
end

return ExploreSystemBgView