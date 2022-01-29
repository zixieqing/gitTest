--[[
 * author : kaishiqi
 * descpt : 主界面 - 地图界面
]]
local HomeMapNode  = require('home.HomeMapNode')
local HomeMapPanel = class('HomeMapPanel', function()
    return display.newLayer(0, 0, {name = 'home.HomeMapPanel', enableEvent = true})
end)

local RES_DICT = {
    COM_LOCK_ICON = 'ui/common/common_ico_lock.png',
    SHIP_BUTTON   = 'ui/home/nmain/main_btn_ship_order.png',
    SHIP_LOGO     = 'ui/home/nmain/main_btn_ship_order_logo.png',
    SHIP_TIME     = 'ui/home/nmain/main_maps_bg_countdown.png',
}

local SHOW_GRID_LAYER = false
local MAP_LAYER_SIZE  = cc.size(1624, 1002)
local NODE_LAYER_SIZE = cc.size(1334, 1002)
local NODE_GRID_SIZE  = cc.size(98, 98)
local NODE_GRID_ROWS  = 5
local NODE_GRID_COLS  = 6
local NODE_ORIGIN_X   = NODE_LAYER_SIZE.width - 180
local NODE_ORIGIN_Y   = NODE_LAYER_SIZE.height/2 + NODE_GRID_SIZE.height * (NODE_GRID_ROWS/2 - 0.5)

local CreateView = nil


-------------------------------------------------
-- life cycle

function HomeMapPanel:ctor(args)
    self.questNodeMap_ = {}
    self.storyNodeMap_ = {}
    self.orderNodeMap_ = {}
    self.funcHideMap_  = args.funcHideMap or {}

    -- create view
    self.viewData_ = CreateView()
    self.viewData_.view:setName('HomeMapPanelView')
    self:addChild(self.viewData_.view)

    -- update view
    self.viewData_.airShipBtn:setScale(0)
    self:refreshAirShipStatus()
    self:refreshMapStatus()
    self:updateMapImage_()

    -- add listener
    display.commonUIParams(self.viewData_.airShipBtn, {cb = handler(self, self.onClickAirShipButtonHandler_)})
    AppFacade.GetInstance():RegistObserver(COUNT_DOWN_ACTION, mvc.Observer.new(self.onTimerCountDownHandler_, self))
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    local offY = -10
    view:add(ui.layer({color = '#FFFFFFCC'}))

    -- map img layer
    local mapImgLayer = display.newLayer(size.width/2, size.height/2, {ap = display.CENTER, size = MAP_LAYER_SIZE})
    view:addChild(mapImgLayer)

    -- airShip button
    local airShipBtn = display.newButton(size.width/2 + 450, size.height/2 - 150 + offY, {n = app.plistMgr:checkSpriteFrame(RES_DICT.SHIP_BUTTON), tag = RemindTag.AIRSHIP})
    display.commonLabelParams(airShipBtn, fontWithColor(19, {fontSize = 22, outline = '#000000', outlineSize = 1, offset = cc.p(0, -38), text = __('飞艇空港')}))
    view:addChild(airShipBtn)

    -- airShip status icon
    local airShipBtnSize = airShipBtn:getContentSize()
    local airShipOpenImg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.SHIP_LOGO), airShipBtnSize.width/2 + 5, airShipBtnSize.height/2 + 5)
    local airShipLockImg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.COM_LOCK_ICON), airShipBtnSize.width/2, airShipBtnSize.height/2 - 6)
    airShipBtn:addChild(airShipOpenImg)
    airShipBtn:addChild(airShipLockImg)

    -- airShip timerBar
    local airShipTimeBar = display.newButton(airShipBtnSize.width/2, airShipBtnSize.height/2 - 10, {n = app.plistMgr:checkSpriteFrame(RES_DICT.SHIP_TIME), enable = false})
    display.commonLabelParams(airShipTimeBar, {fontSize = 20, color = '#5b3c25', text = '--:--:--'})
    airShipBtn:addChild(airShipTimeBar)

    -- quest node layer
    local questNodeLayer = display.newLayer(size.width/2, size.height/2 + offY, {ap = display.CENTER, size = NODE_LAYER_SIZE})
    questNodeLayer:setName('QuestNodeLayer')
    view:addChild(questNodeLayer)

    -- node gride layer (debug use)
    local nodeGridLayer = display.newLayer(size.width/2, size.height/2 + offY, {ap = display.CENTER, size = NODE_LAYER_SIZE})
    view:addChild(nodeGridLayer)

    -------------------------------------------------
    -- order layer
    local orderLayer = display.newLayer()
    view:addChild(orderLayer)

    -- order node layer
    local orderNodeLayer = display.newLayer(size.width/2, size.height/2 + offY, {ap = display.CENTER, size = NODE_LAYER_SIZE})
    orderLayer:addChild(orderNodeLayer)

    return {
        view             = view,
        airShipBtn       = airShipBtn,
        airShipOpenImg   = airShipOpenImg,
        airShipLockImg   = airShipLockImg,
        airShipTimeBar   = airShipTimeBar,
        orderLayer       = orderLayer,
        mapImgLayer      = mapImgLayer,
        nodeGridLayer    = nodeGridLayer,
        questNodeLayer   = questNodeLayer,
        orderNodeLayer   = orderNodeLayer,
    }
end


-------------------------------------------------
-- get / set

function HomeMapPanel:getViewData()
    return self.viewData_
end


function HomeMapPanel:getMapAreaId()
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    return gameManager:GetAreaId()
end


function HomeMapPanel:isHomeControllable()
    local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    return homeMediator and homeMediator:isControllable()
end


function HomeMapPanel:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


-------------------------------------------------
-- public method

function HomeMapPanel:delayInit()
    -- self:updateMapImage_()
    self:refreshQuestLayer()

    -- airship button show action
    local airShipBtn = self.viewData_.airShipBtn
    airShipBtn:runAction(cc.ScaleTo:create(0.4, 1))

    if SHOW_GRID_LAYER then
        self:showNodeLayerGrid_()
    end

    self:refreshOrderLayer()
end


function HomeMapPanel:refreshModuleStatus()
    self:refreshAirShipStatus()
    self:refreshQuestLayer()
end


function HomeMapPanel:refreshMapStatus()
    local viewData = self:getViewData()
    viewData.orderLayer:setVisible(true)
end


function HomeMapPanel:refreshAirShipStatus()
    local isUnlock = CommonUtils.UnLockModule(RemindTag.AIRSHIP)
    local viewData = self:getViewData()
    viewData.airShipTimeBar:setVisible(false)
    viewData.airShipOpenImg:setVisible(isUnlock)
    viewData.airShipLockImg:setVisible(not isUnlock)

    local isHideFunc = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.AIRSHIP)])]
    self.viewData_.airShipBtn:setVisible(not isHideFunc and CommonUtils.GetModuleAvailable(MODULE_SWITCH.AIR_TRANSPORTATION))
end


function HomeMapPanel:refreshQuestLayer()
    self:updateQuestLayer_()
end


function HomeMapPanel:refreshStoryLayer()
    self:updateStoryLayer_()
end


function HomeMapPanel:refreshOrderLayer()
    -- 因为订单数据得到前可能剧情点就已经创建，所以需要再次刷新剧情点避
    self:updateStoryLayer_()
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAKEWAY) or CommonUtils.GetModuleAvailable(MODULE_SWITCH.PUBLIC_ORDER) then
        self:updateOrderLayer_()
    end
end


function HomeMapPanel:refreshMapImage()
    self:updateMapImage_()
end


function HomeMapPanel:eraseHideFuncAt(moduleId)
    self.funcHideMap_[tostring(moduleId)] = false
    self:refreshModuleStatus()
end


function HomeMapPanel:getFuncViewAt(moduleId)
    local viewData  = self:getViewData()
    local remindTag = checkint(REMIND_TAG_MAP[tostring(moduleId)])
    return self:getViewData().view:getChildByTag(remindTag) or self:getViewData().questNodeLayer:getChildByTag(remindTag)
end
function HomeMapPanel:getOrderViewAt(orderType, orderId)
    local orderKey = string.format('%d_%d', checkint(orderType), checkint(orderId))
    return self.orderNodeMap_ and self.orderNodeMap_[orderKey] or nil
end


-------------------------------------------------
-- private method

function HomeMapPanel:transformToGridPos_(locationId)
    local idx  = checkint(locationId)
    local col  = math.ceil(idx / NODE_GRID_ROWS)
    local row  = (idx-1) % NODE_GRID_ROWS + 1
    local posX = NODE_ORIGIN_X - (col-1) * NODE_GRID_SIZE.width
    local posY = NODE_ORIGIN_Y - (row-1) * NODE_GRID_SIZE.height
    return cc.p(posX, posY)
end


function HomeMapPanel:showNodeLayerGrid_()
    local nodeGridLayer = self.viewData_.nodeGridLayer
    nodeGridLayer:removeAllChildren()

    -- build useable location map
    local currentAreaId       = self:getMapAreaId()
    local useableLocationMap  = {}
    local useableLocationList = HOME_MAP_LOCATION_MAP[tostring(currentAreaId)] or {}
    for _, locationId in ipairs(useableLocationList) do
        useableLocationMap[tostring(locationId)] = locationId
    end

    -- add each grid rect
    for i = 1, NODE_GRID_ROWS * NODE_GRID_COLS do
        local rectPos   = self:transformToGridPos_(i)
        local rectColor = useableLocationMap[tostring(i)] and cc.c4b(0,255,0,255) or cc.c4b(255,0,0,255)
        local gridRect  = display.newLayer(rectPos.x, rectPos.y, {size = NODE_GRID_SIZE, color = rectColor, ap = display.CENTER})
        gridRect:addChild(display.newLabel(NODE_GRID_SIZE.width/2, NODE_GRID_SIZE.height/2, fontWithColor(20, {text = tostring(i)})))
        gridRect:setCascadeOpacityEnabled(true)
        gridRect:setOpacity(100)
        nodeGridLayer:addChild(gridRect)
    end
end


function HomeMapPanel:updateAirShipTimeCountdown_()
    local timerMgr  = AppFacade.GetInstance():GetManager('TimerManager')
    local timerInfo = timerMgr:RetriveTimer(COUNT_DOWN_TAG_AIR_SHIP) or {}
    local nowTime   = checkint(timerInfo.countdown)
    local endTime   = checkint(timerInfo.timeNum)
    local viewData  = self:getViewData()

    if nowTime <= 0 then
        viewData.airShipOpenImg:setVisible(true)
        viewData.airShipTimeBar:setVisible(false)
    else
        viewData.airShipOpenImg:setVisible(false)
        viewData.airShipTimeBar:setVisible(true)
        display.commonLabelParams(viewData.airShipTimeBar, {text = string.formattedTime(nowTime, '%02i:%02i:%02i')})
    end
end


function HomeMapPanel:updateMapImage_()
    -- clean map iamge layer
    local mapImgLayer = self.viewData_.mapImgLayer
    mapImgLayer:removeAllChildren()

    -- create map image
    local mapImgSize = mapImgLayer:getContentSize()
    local mapImgView = require('common.SliceBackground').new({size = mapImgSize, count = 2, cols = 2,
        pic_path_name = string.format('arts/maps/world/cityBgm_00%d', self:getMapAreaId())
    })
    mapImgView:setAnchorPoint(display.LEFT_BOTTOM)
    mapImgLayer:addChild(mapImgView)

    -- mapImgLayer:stopAllActions()
    -- mapImgLayer:setOpacity(0)
    -- mapImgLayer:runAction(cc.FadeIn:create(0.8))
end


function HomeMapPanel:updateQuestLayer_()
    -- clean quest layer
    self.questNodeMap_   = {}
    local currentAreaId  = self:getMapAreaId()
    local questNodeLayer = self.viewData_.questNodeLayer
    local oldNodeNameMap = {}
    for i, node in ipairs(questNodeLayer:getChildren()) do
        oldNodeNameMap[tostring(node:getName())] = tostring(node:getName())
    end
    questNodeLayer:removeAllChildren()

    -------------------------------------------------
    -- calculate quest grades
    local gradesInfoMap   = { currentMap = {}, totalMap = {} }
    local gameManager     = AppFacade.GetInstance():GetManager('GameManager')
    local questGrades     = gameManager:GetUserInfo().questGrades or {}
    local currentAreaConf = CommonUtils.GetConfig('common', 'area', currentAreaId) or {}
    for _, cityId in ipairs(currentAreaConf.cities or {}) do

        -- calculate current grades
        local cityGradesMap = checktable(questGrades[tostring(cityId)]).grades or {}
        for questId, grades in pairs(cityGradesMap) do
            local questConf = CommonUtils.GetQuestConf(checkint(questId)) or {}
            if checkint(questConf.repeatChallenge) == QuestRechallenge.QR_CAN then  -- can repeate
                local questDifficulty = checkint(questConf.difficulty)
                local currentGrades   = checkint(gradesInfoMap.currentMap[tostring(questDifficulty)])
                gradesInfoMap.currentMap[tostring(questDifficulty)] = currentGrades + checkint(grades)
            end
        end

        -- calculate total grades
        local cityConf = CommonUtils.GetConfig('quest', 'city', cityId) or {}
        for difficultyId, questIdList in pairs(cityConf.quests or {}) do
            for _, questId in ipairs(questIdList or {}) do
                local questConf = CommonUtils.GetQuestConf(checkint(questId)) or {}
                if checkint(questConf.repeatChallenge) == QuestRechallenge.QR_CAN then  -- can repeate
                    local totalGrades = checkint(gradesInfoMap.totalMap[tostring(difficultyId)])
                    gradesInfoMap.totalMap[tostring(difficultyId)] = totalGrades + table.nums(questConf.allClean or {})
                end
            end
        end
    end

    -------------------------------------------------
    -- create quest map node
    local areaPointConfs = CommonUtils.GetConfigAllMess('areaFixedPoint', 'common') or {}
    for _, areaPointConf in pairs(areaPointConfs) do
        if checkint(areaPointConf.areaId) == currentAreaId then

            -- fix conf type
            local nodeId     = checkint(areaPointConf.id)
            local confType   = checkint(areaPointConf.type)
            local nodeType   = Types.TYPE_ARMY
            local nodeTag    = RemindTag.QUEST_ARMY
            local nodeName   = string.fmt('TYPE_ARMY_%1', nodeId)
            local isHideFunc = self.funcHideMap_[tostring(MODULE_DATA[tostring(nodeTag)])] or not CommonUtils.GetModuleAvailable(MODULE_SWITCH.EXPLORATIN)
            if confType == 1 then
                nodeTag    = RemindTag.MAP
                nodeType   = Types.TYPE_QUEST
                nodeName   = string.fmt('TYPE_QUEST_%1', nodeId)
                isHideFunc = self.funcHideMap_[tostring(MODULE_DATA[tostring(nodeTag)])] or not CommonUtils.GetModuleAvailable(MODULE_SWITCH.NORMAL_MAP)
            elseif confType == 7 then
                nodeTag    = RemindTag.DIFFICULT_MAP
                nodeType   = Types.TYPE_QUEST_HARD
                nodeName   = string.fmt('TYPE_QUEST_HARD_%1', nodeId)
                isHideFunc = self.funcHideMap_[tostring(MODULE_DATA[tostring(nodeTag)])] or not CommonUtils.GetModuleAvailable(MODULE_SWITCH.DIFFICULTY_MAP)
            end

            if not isHideFunc then
                -- create map node
                local mapData = {
                    id      = nodeId,
                    name    = areaPointConf.name,
                    photoId = areaPointConf.photoId,
                }
                local mapNode = HomeMapNode.new({type = nodeType, areaId = checkint(areaPointConf.areaId), data = mapData})
                mapNode:setPositionX(checkint(checktable(areaPointConf.location).x))
                mapNode:setPositionY(checkint(checktable(areaPointConf.location).y))
                mapNode:setName(nodeName)
                mapNode:setTag(nodeTag)
                questNodeLayer:addChild(mapNode)
                self.questNodeMap_[tostring(nodeId)] = mapNode

                -- update map node
                local mapNodeViewData = mapNode:getViewData()
                mapNodeViewData.clickArea:setTag(nodeId)
                display.commonUIParams(mapNodeViewData.clickArea, {cb = handler(self, self.onClickQuestMapNodeHandler_) , animationNode = mapNode})

                if mapNodeViewData.nodeInfoBar then
                    local difficultyType = 0
                    if nodeType == Types.TYPE_QUEST then
                        difficultyType = QUEST_DIFF_NORMAL
                    elseif nodeType == Types.TYPE_QUEST_HARD then
                        difficultyType = QUEST_DIFF_HARD
                    end
                    local totalGrades   = checkint(gradesInfoMap.totalMap[tostring(difficultyType)])
                    local currentGrades = checkint(gradesInfoMap.currentMap[tostring(difficultyType)])
                    display.commonLabelParams(mapNodeViewData.nodeInfoBar, {text = string.fmt('%1 / %2', currentGrades, totalGrades)})
                end

                -- show action
                if not oldNodeNameMap[nodeName] then
                    mapNode:showAction()
                end
            end
        end
    end
end


function HomeMapPanel:updateStoryLayer_()
    local currentAreaId   = self:getMapAreaId()
    local orderNodeLayer  = self.viewData_.orderNodeLayer
    local oldStoryNodeMap = self.storyNodeMap_ or {}

    -------------------------------------------------
    -- build useable location map
    local useableLocationMap  = {}
    local useableLocationList = HOME_MAP_LOCATION_MAP[tostring(currentAreaId)] or {}
    for _, locationId in ipairs(useableLocationList) do
        useableLocationMap[tostring(locationId)] = locationId
    end

    -- filter order location
    local takeawayManager  = AppFacade.GetInstance():GetManager('TakeawayManager')
    local allTakeawayDatas = takeawayManager:GetDatas() or {}
    for _, orderData in pairs(allTakeawayDatas.publicOrder or {}) do
        if checkint(orderData.areaId) == currentAreaId then
            useableLocationMap[tostring(orderData.location)] = nil
        end
    end
    for _, orderData in pairs(allTakeawayDatas.privateOrder or {}) do
        if checkint(orderData.areaId) == currentAreaId then
            useableLocationMap[tostring(orderData.location)] = nil
        end
    end

    -------------------------------------------------
    -- filter maoNode location
    local gameManager       = AppFacade.GetInstance():GetManager('GameManager')
    local storyTaskMap      = gameManager:GetUserInfo().storyTasks or {}
    local mapNodeLoationMap = {}

    -- check same oldMapNode location
    for storyTaskKey, storyTaskData in pairs(storyTaskMap) do
        local oldMapNode = oldStoryNodeMap[storyTaskKey]
        if oldMapNode and useableLocationMap[tostring(oldMapNode:getNodeData().location)] then
            mapNodeLoationMap[storyTaskKey] = oldMapNode:getNodeData().location
            useableLocationMap[tostring(oldMapNode:getNodeData().location)] = nil
        end
    end

    -- fill left new mapNode location
    local leftLocationList = table.values(useableLocationMap)
    for storyTaskKey, storyTaskData in pairs(storyTaskMap) do
        if not mapNodeLoationMap[storyTaskKey] then
            if #leftLocationList > 0 then
                mapNodeLoationMap[storyTaskKey] = table.remove(leftLocationList, #leftLocationList)
            else
                mapNodeLoationMap[storyTaskKey] = 0
            end
        end
    end

    -------------------------------------------------
    -- each story map
    self.storyNodeMap_ = {}
    for storyTaskKey, storyTaskData in pairs(storyTaskMap) do
        local mapData    = nil
        local taskType   = checkint(storyTaskData.type)
        local locationId = mapNodeLoationMap[storyTaskKey]
        local oldMapNode = oldStoryNodeMap[storyTaskKey]

        if oldMapNode == nil or checkint(oldMapNode:getNodeData().location) ~= locationId then

            -- create story map data
            if taskType == Types.TYPE_STORY then
                local storyConf = CommonUtils.GetConfig('quest', 'questPlot', storyTaskData.id) or {}
                if checkint(storyConf.areaId) == currentAreaId then
                    mapData = {
                        id       = storyConf.id,
                        story    = storyConf.story,
                        roleId   = storyConf.roleId,
                        location = locationId,
                    }
                end

            -- create branch map data
            elseif taskType == Types.TYPE_BRANCH then
                local branchConf = CommonUtils.GetConfig('quest', 'branch', storyTaskData.id) or {}
                if checkint(branchConf.areaId) == currentAreaId then
                    mapData = {
                        id       = branchConf.id,
                        story    = branchConf.story,
                        roleId   = branchConf.roleId,
                        location = locationId,
                    }
                end
            end

            -- create map node
            if mapData then
                local mapNode = HomeMapNode.new({type = taskType, data = mapData})
                mapNode:setPosition(self:transformToGridPos_(locationId))
                orderNodeLayer:addChild(mapNode, locationId)
                self.storyNodeMap_[storyTaskKey] = mapNode

                -- update map node
                local mapNodeViewData = mapNode:getViewData()
                mapNodeViewData.clickArea:setName(storyTaskKey)
                display.commonUIParams(mapNodeViewData.clickArea, {cb = handler(self, self.onClickStoryMapNodeHandler_)})

                -- show action
                mapNode:showAction()
            end

        else
            -- re-mark mapNode
            self.storyNodeMap_[storyTaskKey] = oldMapNode
            oldStoryNodeMap[storyTaskKey]    = nil
        end
    end

    -- clean story nodes
    for _, mapNode in pairs(oldStoryNodeMap) do
        mapNode:hideAction()
    end
end


function HomeMapPanel:updateOrderLayer_()
    local currentAreaId    = self:getMapAreaId()
    local takeawayManager  = AppFacade.GetInstance():GetManager('TakeawayManager')
    local allTakeawayDatas = takeawayManager:GetDatas() or {}
    local orderNodeLayer   = self.viewData_.orderNodeLayer
    local oldOrderNodeMap  = self.orderNodeMap_ or {}

    -------------------------------------------------
    -- filter order list
    local takeawayDataList = {}

    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PUBLIC_ORDER) then
        for _, orderData in pairs(allTakeawayDatas.publicOrder or {}) do
            if checkint(orderData.areaId) == currentAreaId then
                table.insert(takeawayDataList, {type = Types.TYPE_TAKEAWAY_PUBLIC, data = orderData})
            end
        end
    end
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAKEWAY) then
        for _, orderData in pairs(allTakeawayDatas.privateOrder or {}) do
            if checkint(orderData.areaId) == currentAreaId then
                table.insert(takeawayDataList, {type = Types.TYPE_TAKEAWAY_PRIVATE, data = orderData})
            end
        end
    end

    -------------------------------------------------
    -- each order list
    self.orderNodeMap_ = {}
    for _, takeawayData in ipairs(takeawayDataList) do
        local orderData  = checktable(takeawayData.data)
        local locationId = checkint(orderData.location)
        local orderKey   = string.format('%d_%d', takeawayData.type, checkint(orderData.orderId))
        local oldMapNode = oldOrderNodeMap[tostring(orderKey)]

        -- check need new
        if oldMapNode == nil or checkint(oldMapNode:getNodeData().location) ~= locationId then

            -- create map node
            local mapNode = HomeMapNode.new({type = takeawayData.type, data = orderData})
            mapNode:setPosition(self:transformToGridPos_(locationId))
            orderNodeLayer:addChild(mapNode, locationId)
            self.orderNodeMap_[orderKey] = mapNode

            -- update map node
            local mapNodeViewData = mapNode:getViewData()
            mapNodeViewData.clickArea:setName(orderKey)
            display.commonUIParams(mapNodeViewData.clickArea, {cb = handler(self, self.onClickOrderMapNodeHandler_)})

            -- show action
            mapNode:showAction()

        else
            -- re-mark mapNode
            self.orderNodeMap_[orderKey] = oldMapNode
            oldOrderNodeMap[orderKey]    = nil

            -- check update status
            if oldMapNode and checkint(oldMapNode:getOrderStatus()) ~= checkint(orderData.status) then
                oldMapNode:setOrderStatus(orderData.status)
            end
        end
    end

    -- clean order nodes
    for _, mapNode in pairs(oldOrderNodeMap) do
        mapNode:hideAction()
    end
end


-------------------------------------------------
-- handler

function HomeMapPanel:onCleanup()
    AppFacade.GetInstance():UnRegistObserver(COUNT_DOWN_ACTION, self)
end


function HomeMapPanel:onTimerCountDownHandler_(signal)
    local dataBody = signal:GetBody()
    local timerTag = dataBody.tag

    if timerTag == RemindTag.AIRSHIP then
        self:updateAirShipTimeCountdown_()
    end
end


function HomeMapPanel:onClickAirShipButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    if CommonUtils.UnLockModule(RemindTag.AIRSHIP, true) then
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'AirShipHomeMediator'})
    end
end


function HomeMapPanel:onClickQuestMapNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    local nodeId   = sender:getTag()
    local mapNode  = self.questNodeMap_[tostring(nodeId)]
    local nodeType = mapNode and mapNode:getNodeType() or 0
    local nodeData = mapNode and mapNode:getNodeData() or nil
    if not mapNode then return end

    if nodeType == Types.TYPE_ARMY then
        if CommonUtils.UnLockModule(RemindTag.QUEST_ARMY, true) then
            self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ExplorationMediator', params = {id = nodeData.id}})
        end


    elseif nodeType == Types.TYPE_QUEST then
        local gameManager = AppFacade.GetInstance():GetManager('GameManager')
        if GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_MAP_PANEL_NORMAL_QUEST) then
            -- reset cache data
            gameManager:UpdatePlayer({localCurrentQuestId = 0})
            self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'MapMediator', params = {currentAreaId = self:getMapAreaId()}})
        end


    elseif nodeType == Types.TYPE_QUEST_HARD then
        if CommonUtils.UnLockModule(RemindTag.DIFFICULT_MAP, true) then
            local gameManager = AppFacade.GetInstance():GetManager('GameManager')
            gameManager:UpdatePlayerNewestQuestId()

            -- check can enter
            local hardQuestId = checkint(gameManager:GetUserInfo().newestHardQuestId)
            local ret, errLog = CommonUtils.CanEnterChapterByChapterIdAndDiff(self:getMapAreaId(), QUEST_DIFF_HARD)
            if hardQuestId == 0 or ret == false then
                local uiManager = AppFacade.GetInstance():GetManager('UIManager')
                uiManager:AddCommonTipDialog({text = errLog, hideAllButton = true})

            else
                -- reset cache data
                gameManager:UpdatePlayer({localCurrentQuestId = 0})
                self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'MapMediator', params = {currentAreaId = self:getMapAreaId(), type = QUEST_DIFF_HARD}})
            end
        end
    end
end


function HomeMapPanel:onClickStoryMapNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    local taskKey  = sender:getName()
    local mapNode  = self.storyNodeMap_[tostring(taskKey)]
    local nodeType = mapNode and mapNode:getNodeType() or 0
    local nodeData = mapNode and mapNode:getNodeData() or nil
    if not mapNode then return end

    local confPath = nil
    local finishCB = nil
    if nodeType == Types.TYPE_STORY then
        confPath = string.format('conf/%s/quest/questStory.json', i18n.getLang())
        finishCB = function(tag)
            AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Story_SubmitMissions, {type = nodeType, plotTaskId = nodeData.id})
        end

    elseif nodeType == Types.TYPE_BRANCH then
        confPath = string.format('conf/%s/quest/branchStory.json', i18n.getLang())
        finishCB = function(tag)
            AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Regional_SubmitMissions, {type = nodeType, branchTaskId = nodeData.id})
        end
    end

    if confPath then
        local operaDoneId = checkint(checktable(nodeData.story).done)
        if operaDoneId > 0 then
            local operaStage = require('Frame.Opera.OperaStage').new({id = operaDoneId, path = confPath, isHideBackBtn = true, cb = finishCB})
            operaStage:setPosition(display.center)
            sceneWorld:addChild(operaStage, GameSceneTag.Dialog_GameSceneTag)
        else
            if finishCB then finishCB() end
        end
    end
end


function HomeMapPanel:onClickOrderMapNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    local orderKey = sender:getName()
    local mapNode  = self.orderNodeMap_[tostring(orderKey)]

    -- 当 状态1 的 公众订单 临近消失时，忽略点击操作。
    -- 目的是防止 刚点开订单界面还没来得及接受订单，实际服务器订单就已经消失，这时 点击派遣 会提示订单已消失 的不良体验。
    if (not mapNode) or (tolua.isnull(mapNode))  then return end

    local nodeType = mapNode and mapNode:getNodeType() or 0
    local nodeData = mapNode and mapNode:getNodeData() or {}


    local takeawayManager = AppFacade.GetInstance():GetManager('TakeawayManager')
    local orderTimerInfo  = takeawayManager:GetOrderTimerINfo(nodeData.areaId, nodeData.orderType, nodeData.orderId) or {}
    if nodeType == Types.TYPE_TAKEAWAY_PUBLIC and checkint(nodeData.status) == 1 and checkint(orderTimerInfo.countdown) < 3 then
        return
    end

    if next(nodeData) ~= nil then
        local orderMediator = require('Game.mediator.LargeAndOrdinaryMediator').new(nodeData)
        AppFacade.GetInstance():RegistMediator(orderMediator)
    else
        app.uiMgr:ShowInformationTips(__('订单已经不存在了'))
    end
end


return HomeMapPanel
