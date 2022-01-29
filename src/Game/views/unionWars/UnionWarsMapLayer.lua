--[[
 * author : kaishiqi
 * descpt : 工会战 - 地图图层
]]
local UnionConfigParser    = require('Game.Datas.Parser.UnionConfigParser')
local unionWarsSiteConfs   = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.WARS_SITE_INFO, 'union') or {}
local UnionWarsMapSiteNode = require('Game.views.unionWars.UnionWarsMapSiteNode')
local UnionWarsMapLayer    = class('UnionWarsMapLayer', function()
    return display.newLayer(0, 0, {name = 'Game.views.unionWars.UnionWarsMapLayer'})
end)

local RES_DICT = {
    SWITCH_ARROW_R  = _res('ui/home/recharge/recharge_btn_arrow.png'),
    WARS_MAP_BG_1_1 = _res('ui/union/wars/map/gvg_maps_bg_1_1.jpg'),
    WARS_MAP_BG_1_2 = _res('ui/union/wars/map/gvg_maps_bg_1_2.jpg'),
    WARS_MAP_BG_2_1 = _res('ui/union/wars/map/gvg_maps_bg_2_1.jpg'),
    WARS_MAP_BG_2_2 = _res('ui/union/wars/map/gvg_maps_bg_2_2.jpg'),
}

local MAP_SCROLL_DELAY = 0.5
local MAP_LAYER_SIZE   = cc.size(1624, 1002)
local MAP_DESIGN_SIZE  = cc.size(1334, 1002)

local CreateView    = nil
local CreateMapNode = nil


function UnionWarsMapLayer:ctor(args)
    -- init vars
    self.mapNodeList_  = {}
    self.mapSiteMap_   = {}  -- {key: siteId, value: siteNode}
    self.mapBossMap_   = {}  -- {key: pageId, value: siteNode}
    self.mapPageCount_ = 0
    self.mapPageIndex_ = 0

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    
    for pageIndex = 1, table.nums(unionWarsSiteConfs) do
        local warsMapInfoConf = unionWarsSiteConfs[tostring(pageIndex)] or {}

        -- create mapLayer
        local mapNodeIndex    = pageIndex
        local mapNodeViewData = CreateMapNode({index = mapNodeIndex})
        mapNodeViewData.view:setTag(mapNodeIndex)
        self:insertMapNode_(mapNodeViewData)

        -- craete site node
        for siteIndex, siteInfoConf in pairs(warsMapInfoConf.site or {}) do
            local sitePosConf  = checktable(siteInfoConf.pos)
            local mapSiteNode  = UnionWarsMapSiteNode.new({type = UnionWarsMapSiteNode.TYPES.SITE})
            mapSiteNode:setPositionX(checkint(sitePosConf[1]))
            mapSiteNode:setPositionY(checkint(sitePosConf[2]))
            mapSiteNode:setOnClickCB(handler(self, self.onClickMapSiteNodeHandler_))
            mapSiteNode:setTag(checkint(siteInfoConf.id))
            mapSiteNode:updateSiteStatus(siteInfoConf.id)
            mapNodeViewData.siteLayer:addChild(mapSiteNode)
            self.mapSiteMap_[tostring(siteInfoConf.id)] = mapSiteNode
        end

        -- create boss node
        local bossInfoConf = warsMapInfoConf.boss or {}
        local bossPosConf  = checktable(bossInfoConf.pos)
        local mapBossNode  = UnionWarsMapSiteNode.new({type = UnionWarsMapSiteNode.TYPES.BOSS})
        mapBossNode:setPositionX(checkint(bossPosConf[1]))
        mapBossNode:setPositionY(checkint(bossPosConf[2]))
        mapBossNode:setOnClickCB(handler(self, self.onClickMapBossNodeHandler_))
        mapBossNode:setTag(checkint(pageIndex))
        mapBossNode:updateBossStatus(pageIndex)
        mapNodeViewData.siteLayer:addChild(mapBossNode)
        self.mapBossMap_[tostring(pageIndex)] = mapBossNode
    end

    -- init views
    self:setMapPageIndex(0, true)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    local mapLayer = display.newLayer()
    view:addChild(mapLayer)

    -------------------------------------------------
    local uiLayer = display.newLayer()
    view:addChild(uiLayer)

    -- next map button
    local nextMapBtn = display.newButton(display.SAFE_R - 30, size.height/2, {n = RES_DICT.SWITCH_ARROW_R})
    uiLayer:addChild(nextMapBtn)

    -- prev map button
    local prevMapBtn = display.newButton(display.SAFE_L + 30, size.height/2, {n = RES_DICT.SWITCH_ARROW_R, isFlipX = true})
    uiLayer:addChild(prevMapBtn)

    return {
        view       = view,
        mapLayer   = mapLayer,
        uiLayer    = uiLayer,
        prevMapBtn = prevMapBtn,
        nextMapBtn = nextMapBtn,
    }
end


CreateMapNode = function(mapData)
    local size = MAP_LAYER_SIZE
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER})

    local index = checkint(mapData.index)

    local unionMapBgImg = display.newImageView(RES_DICT['WARS_MAP_BG_1_' .. index], size.width/2, size.height/2)
    local enemyMapBgImg = display.newImageView(RES_DICT['WARS_MAP_BG_2_' .. index], size.width/2, size.height/2)
    view:addChild(unionMapBgImg)
    view:addChild(enemyMapBgImg)

    local sizeOffX  = (MAP_LAYER_SIZE.width - MAP_DESIGN_SIZE.width) / 2
    local sizeOffY  = (MAP_LAYER_SIZE.height - MAP_DESIGN_SIZE.height) / 2
    local siteLayer = display.newLayer(sizeOffX, sizeOffY)
    view:addChild(siteLayer)

    return {
        view          = view,
        siteLayer     = siteLayer,
        unionMapBgImg = unionMapBgImg,
        enemyMapBgImg = enemyMapBgImg,
    }
end


-------------------------------------------------
-- get / set

function UnionWarsMapLayer:getViewData()
    return self.viewData_
end


function UnionWarsMapLayer:getMapPageCount()
    return self.mapPageCount_
end


function UnionWarsMapLayer:getMapPageIndex()
    return self.mapPageIndex_
end
function UnionWarsMapLayer:setMapPageIndex(index, isFast, finishCB)
    self.mapPageIndex_ = checkint(index)
    
    self:scrollMapLayer_(self:getMapPageIndex(), isFast, finishCB)
    
    if self:getMapPageCount() > 0 and self:getMapPageIndex() > 0 then
        self:getViewData().prevMapBtn:setVisible(self:getMapPageIndex() > 1)
        self:getViewData().nextMapBtn:setVisible(self:getMapPageIndex() < self:getMapPageCount())
    else
        self:getViewData().prevMapBtn:setVisible(false)
        self:getViewData().nextMapBtn:setVisible(false)
    end
end


---@param callback function(sideId) end
function UnionWarsMapLayer:setClickMapSiteCB(callback)
    self.clickMapSiteCB_ = callback
end
function UnionWarsMapLayer:getClickMapSiteCB()
    return self.clickMapSiteCB_
end


---@param callback function(pageId) end
function UnionWarsMapLayer:setClickMapBossCB(callback)
    self.clickMapBossCB_ = callback
end
function UnionWarsMapLayer:getClickMapBossCB()
    return self.clickMapBossCB_
end


function UnionWarsMapLayer:getMapSiteMap()
    return self.mapSiteMap_
end
function UnionWarsMapLayer:getMapBossMap()
    return self.mapBossMap_
end


function UnionWarsMapLayer:getMapSiteNode(siteId)
    return self:getMapSiteMap()[tostring(siteId)]
end
function UnionWarsMapLayer:getMapBossNode(pageId)
    return self:getMapBossMap()[tostring(pageId)]
end


-------------------------------------------------
-- public

function UnionWarsMapLayer:updateMapBgCampState(isEnemy)
    for _, mapNodeViewData in ipairs(self.mapNodeList_) do
        mapNodeViewData.unionMapBgImg:setVisible(isEnemy ~= true)
        mapNodeViewData.enemyMapBgImg:setVisible(isEnemy == true)
    end
end


-------------------------------------------------
-- private

function UnionWarsMapLayer:insertMapNode_(mapNodeViewData)
    if not mapNodeViewData then return end

    local mapNode  = mapNodeViewData.view
    local mapLayer = self:getViewData().mapLayer
    mapLayer:addChild(mapNode)

    local mapLayerSize = mapLayer:getContentSize()
    local mapNodeSize  = mapNode:getContentSize()
    mapLayer:setContentSize(cc.size(display.width + mapNodeSize.width * self.mapPageCount_, display.height))
    mapNodeViewData.view:setPositionX(display.cx + mapNodeSize.width * self.mapPageCount_)
    mapNodeViewData.view:setPositionY(display.cy)

    self.mapPageCount_ = self.mapPageCount_ + 1
    self.mapNodeList_[self.mapPageCount_] = mapNodeViewData
end


function UnionWarsMapLayer:scrollMapLayer_(index, isFast, finishCB)
    local mapLayer  = self:getViewData().mapLayer
    local scrollPos = cc.p(-MAP_LAYER_SIZE.width * checkint(index - 1), 0)
    mapLayer:stopAllActions()

    if isFast then
        mapLayer:setPosition(scrollPos)
        if finishCB then finishCB() end
    else
        mapLayer:runAction(cc.Sequence:create(
            cc.EaseCubicActionOut:create(cc.MoveTo:create(MAP_SCROLL_DELAY, scrollPos)),
            cc.CallFunc:create(function()
                if finishCB then finishCB() end
            end)
        ))
    end
end


-------------------------------------------------
-- handler

function UnionWarsMapLayer:onClickMapSiteNodeHandler_(sender)
    local siteId = checkint(sender:getTag())
    if self:getClickMapSiteCB() then
        self:getClickMapSiteCB()(siteId)
    end
end


function UnionWarsMapLayer:onClickMapBossNodeHandler_(sender)
    local pageId = checkint(sender:getTag())
    if self:getClickMapBossCB() then
        self:getClickMapBossCB()(pageId)
    end
end


return UnionWarsMapLayer
