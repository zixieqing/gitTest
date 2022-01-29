--[[
 * author : kaishiqi
 * descpt : 世界地图中介者
]]
local BossConfigParser = require('Game.Datas.Parser.WorldBossQuestConfigParser')
local WorldMediator    = class('WorldMediator', mvc.Mediator)
local RemindIcon =  require('common.RemindIcon')
local RES_DICT = {
    TOP_FRAME_1                  = 'ui/world/blobal_bg_up_01.png',
    TOP_FRAME_2                  = 'ui/world/blobal_bg_up_02.png',
    LEFT_NAME_FRAME              = 'ui/world/global_bg_name.png',
    LEFT_NAME_WORDS              = 'ui/world/world_ico_words.png',
    RIGHT_NAME_FRAME             = 'ui/world/global_bg_name_area.png',
    RIGHT_BACK_BUTTON            = 'ui/world/global_btn_back_home.png',
    MAP_FOG_MASK                 = 'ui/world/global_bg_light_inner.png',
    CITY_NODE_LOCKED             = 'ui/world/global_bg_name_area_lock.png',
    CITY_NODE_NORMAL             = 'ui/world/global_bg_name_city_default.png',
    CITY_NODE_SELECT             = 'ui/world/global_bg_name_city_selected.png',
    CITY_UNLOCK_INFO             = 'ui/world/global_bg_text_ock.png',
    BOSS_OFF_FRAME               = 'ui/world/worldboss_map_label_off.png',
    BOSS_ON_FRAME                = 'ui/world/worldboss_map_label_on.png',
    BOSS_HISTORY_BTN             = 'ui/world/worldboss_map_btn_history.png',
    BOSS_TIME_FRAME              = 'ui/world/worldboss_map_frame_timer.png',
    BOSS_TIME_BAR                = 'ui/world/worldboss_map_label_timer.png',
    GOLD_HOME_ENTRY_BOX          = 'ui/world/gold_home_entry_box.png',
    GOLD_HOME_ENTRY_TIME         = 'ui/world/gold_home_entry_time.png',
    GOLD_HOME_BG_TIME_ENTRY_BOAT = 'ui/world/gold_home_bg_time_entry_boat.png',
    MAPS_BTN_EXPLOR              = 'ui/world/maps_btn_explor.png',
}

local BOSS_STATUS = {
    NONE = 1,  -- 没BOSS
    OFF  = 2,  -- 未开启
    ON   = 3,  -- 出现中
}

local MODULE_CONFS = {
    {name = __('探索'), spinePath = 'ui/exploreSystem/spine/tansuo', tag = RemindTag.EXPLORE_SYSTEM, pos = cc.p(display.width - 350, 160)}
}

local CreateView     = nil
local CreateCityCell = nil
local CreateBossCell = nil
local CreateModuleCell = nil

function WorldMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'WorldMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function WorldMediator:Initial(key)
    self.super.Initial(self, key)

    self.bossCellMap_ = {}

    -- create view
    self.viewData_  = CreateView()
    local uiManager = self:GetFacade():GetManager('UIManager')
    uiManager:SwitchToScene(self.viewData_.view)
    self:SetViewComponent(self.viewData_.view)

    -- init views
    display.commonUIParams(self:getViewData().backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self:getViewData().bossHistoryBtn, {cb = handler(self, self.onClickBossHistoryButtonHandler_)})

    -- init city cells
    self.cityCellMap_   = {}
    local currentAreaId = app.gameMgr:GetAreaId()
    
    local cityLayerSize = self:getViewData().cityLayer:getContentSize()
    local cityAreaConfs = CommonUtils.GetConfigAllMess('area', 'common') or {}
    for _, areaConf in pairs(cityAreaConfs) do
        local areaId   = checkint(areaConf.id)
        local cityPos  = checktable(areaConf.location)
        local cityCell = CreateCityCell()
        cityCell.view:setTag(areaId)
        cityCell.view:setName(string.format('AREA_%d', areaId))
        RemindIcon.addRemindIcon({parent = cityCell.view , tag = RemindTag["WORLD_AREA_" .. tostring(areaId)] ,imgPath =_res('ui/card_preview_ico_new_2') , po = cc.p(180, 60)})
        cityCell.view:setPosition(checkint(cityPos.x), cityLayerSize.height - checkint(cityPos.y))
        display.commonUIParams(cityCell.view, {cb = handler(self, self.onClickCityCellHandler_)})
        display.commonLabelParams(cityCell.unlockBar, {text = self:getUnlockDescr(areaId), paddingW = 50, safeW = 50})
        display.commonLabelParams(cityCell.nameLabel, {text = tostring(areaConf.name)})
        self:getViewData().cityLayer:addChild(cityCell.view)
        self.cityCellMap_[tostring(areaId)] = cityCell

        RemindIcon.addRemindIcon({parent = cityCell.view , tag = RemindTag["WORLD_AREA_" .. tostring(areaId)] ,imgPath =_res('ui/card_preview_ico_new_2') , po = cc.p(180, 60)})
        RemindIcon.addRemindIcon({parent = cityCell.view , tag = app.badgeMgr:GetZreaRemindTag(areaId), po = cc.p(20, 35)})

        if currentAreaId == areaId then
            local homeCardUuid   = checkint(app.gameMgr:GetUserInfo().signboardId)
            local homeCardData   = app.gameMgr:GetCardDataById(homeCardUuid) or {}
            local homeCardAvatar = AssetsUtils.GetCardSpineNode({skinId = homeCardData.defaultSkinId, scale = 0.25})
            homeCardAvatar:setAnimation(0, 'idle', true)
            homeCardAvatar:setPosition(cc.p(0,0))
            cityCell.avatarLayer:addChild(homeCardAvatar)
        end
    end
    for i, funcConf in ipairs(MODULE_CONFS) do
        local tag       = funcConf.tag
        if tag and CommonUtils.UnLockModule(tag, false) and CommonUtils.GetModuleAvailable(MODULE_REFLECT[tostring(MODULE_DATA[tostring(tag)])]) then
            local img       = funcConf.img
            local spinePath = funcConf.spinePath
            local funcCell = CreateModuleCell(img, spinePath)
            
            local pos = funcConf.pos
            display.commonUIParams(funcCell.view, {po = pos, cb = handler(self, self.onClickFuncCellHandler_)})
    
            if tag then
                funcCell.view:setTag(tag)
                local viewSize = funcCell.view:getContentSize()
                RemindIcon.addRemindIcon({parent = funcCell.view, tag = tag, po = cc.p(viewSize.width - 40, viewSize.height - 25)})
            end
            self:getViewData().funcLayer:addChild(funcCell.view)
            display.commonLabelParams(funcCell.nameLabel, {text = tostring(funcConf.name)})
        end
    end


    -- update views
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) then
        self:updateWorldBossStatus_()
    end
    self:updateCurrentCityName_()
    self:updateAllCityStatus_()
    self:UpdateBlackSpine()

    -- 全区域 剧情点快速检测
    app.badgeMgr:CheckAreaPlotRemindAll()
end
function WorldMediator:CleanupView()
    self:stopWorldBossCountdown_()
end


function WorldMediator:OnRegist()
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    
    if GuideUtils.HasModule(GUIDE_MODULES.MODULE_WORLDMAP) then
        GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_WORLDMAP)
    end
    if app.gameMgr:GetUserInfo().level > 16  then
        GuideUtils.DispatchStepEvent()
    end
end
function WorldMediator:OnUnRegist()
end


function WorldMediator:InterestSignals()
	return {
        SGL.WORLDMAP_UNLOCK_SIGNALS,
        SGL.FRESH_WORLD_BOSS_MAP_DATA,
        POST.COMMERCE_HOME.sglName,
        SGL.FRESH_BLACK_GOLD_COUNT_DOWN_EVENT
    }
end
function WorldMediator:ProcessSignal(signal)
	local name = signal:GetName()
    local body = signal:GetBody()

    -- unlock worldMap area
    if name == SGL.WORLDMAP_UNLOCK_SIGNALS then
        local uiManager = AppFacade.GetInstance():GetManager('UIManager')
        uiManager:ShowInformationTips(__('恭喜解锁成功~~'))

        -- update newestAreaId
        local newestAreaId = checkint(body.requestData.areaId)
        local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
        gameManager:GetUserInfo().newestAreaId = newestAreaId
        local areaTag =  RemindTag["WORLD_AREA_" .. tostring(newestAreaId)]
        app.dataMgr:ClearRedDotNofication(tostring(areaTag) , tostring(areaTag))
        app:DispatchObservers(COUNT_DOWN_ACTION , {countdown = 0  , tag = areaTag})
        -- update all city status
        self:updateAllCityStatus_()

        -- 新地图解锁 做刷新外卖的请求
        app.takeawayMgr:FreshTakeawayData()

        -- 引导的下一步的逻辑
        GuideUtils.DispatchStepEvent()


    -------------------------------------------------
    -- fresh worldBoss map
    elseif name == POST.COMMERCE_HOME.sglName then
        self:UpdateBlackSpine()
    elseif name == SGL.FRESH_BLACK_GOLD_COUNT_DOWN_EVENT then
        self:updateBlackGoldTime()
    elseif name == SGL.FRESH_WORLD_BOSS_MAP_DATA then
        if CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) then
            self:updateWorldBossStatus_()
        end
    
    end
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = require('Frame.GameScene').new()

    -- background
    local backgroundPath = 'arts/maps/world/global_bg'
    local slicBackground = require('common.SliceBackground').new({size = cc.size(1624, 1002), pic_path_name = backgroundPath, count = 2, cols = 2})
    display.commonUIParams(slicBackground, {ap = display.CENTER, po = display.center})
    view:addChild(slicBackground)

    -- cityNode layer
    local cityLayer = display.newLayer(display.cx, display.cy, {size = cc.size(1334, 1002), ap = display.CENTER})
    cityLayer:setName('WORLDVIEW')
    view:addChild(cityLayer)

    -- bossNode layer
    local bossLayer = display.newLayer(cityLayer:getPositionX(), cityLayer:getPositionY(), {size = cityLayer:getContentSize(), ap = display.CENTER})
    view:addChild(bossLayer)

    -- fogMask image
    local fogMaskImg = display.newImageView(_res(RES_DICT.MAP_FOG_MASK), display.cx, display.cy, {isFull = true})
    view:addChild(fogMaskImg)

    -------------------------------------------------
    -- top layer
    local topSize  = display.size
    local topLayer = display.newLayer(display.cx, display.height, {ap = display.CENTER_TOP, size = topSize})
    topLayer:addChild(display.newImageView(_res(RES_DICT.TOP_FRAME_1), topSize.width/2, topSize.height, {ap = display.RIGHT_TOP}))
    topLayer:addChild(display.newImageView(_res(RES_DICT.TOP_FRAME_2), topSize.width/2, topSize.height, {ap = display.LEFT_TOP}))
    view:addChild(topLayer)


    -------------------------------------------------
    -- bossInfo layer
    local bossInfoSize = nil
    local bossInfoLayer = nil
    local bossOnFrame = nil
    local bossOffFrame = nil
    local bossTimeFrame = nil
    local bossTimeBar = nil
    local bossOnLabel = nil
    local bossOffLabel = nil
    local bossHistoryBtn = nil
    local bossHistoryBtnSize = nil
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) then
        bossInfoSize  = display.size
        bossInfoLayer = display.newLayer(topSize.width, topSize.height, {ap = display.RIGHT_TOP, size = bossInfoSize})
        view:addChild(bossInfoLayer)

        bossOnFrame  = display.newButton(bossInfoSize.width/2 + 527, bossInfoSize.height - 23, {n = _res(RES_DICT.BOSS_ON_FRAME), enable = false})
        bossOffFrame = display.newButton(bossOnFrame:getPositionX(), bossInfoSize.height - 23, {n = _res(RES_DICT.BOSS_OFF_FRAME), enable = false})
        display.commonLabelParams(bossOffFrame, fontWithColor(1, {fontSize = 22, color = '#E4D5C0', text = __('灾祸平息中')}))
        display.commonLabelParams(bossOnFrame, fontWithColor(1, {fontSize = 22, color = '#E4D5C0', text = __('灾祸出现中！')}))
        bossInfoLayer:addChild(bossOffFrame)
        bossInfoLayer:addChild(bossOnFrame)

        bossTimeFrame = display.newImageView(_res(RES_DICT.BOSS_TIME_FRAME), bossOnFrame:getPositionX() +130 , bossInfoSize.height - 82 ,{scale9 = true , ap = display.RIGHT_CENTER })
        bossInfoLayer:addChild(bossTimeFrame)
        bossTimeFrame:setContentSize(cc.size(300,70))

        bossTimeBar = display.newButton(bossTimeFrame:getPositionX() - 180, bossTimeFrame:getPositionY() - 3, {n = _res(RES_DICT.BOSS_TIME_BAR) ,scale9 = true , enable = false})
        display.commonLabelParams(bossTimeBar, fontWithColor(1, {fontSize = 20, color = '#FFFFFF', offset = cc.p(0, -11), text = '--:--:--'}))
        bossTimeBar:setContentSize(cc.size(200,47))
        bossInfoLayer:addChild(bossTimeBar)

        bossOnLabel  = display.newLabel(bossTimeBar:getPositionX(), bossTimeBar:getPositionY() + 9, fontWithColor(9, {text = __('剩余时间')}))
        bossOffLabel = display.newLabel(bossTimeBar:getPositionX(), bossOnLabel:getPositionY(), fontWithColor(9, {text = __('距离下次出现') ,reqW = 190}))
        bossInfoLayer:addChild(bossOffLabel)
        bossInfoLayer:addChild(bossOnLabel)

        bossHistoryBtn = display.newButton(bossTimeBar:getPositionX() + 135, bossTimeBar:getPositionY(), {n = _res(RES_DICT.BOSS_HISTORY_BTN)})
        bossHistoryBtnSize = bossHistoryBtn:getContentSize()
        bossInfoLayer:addChild(bossHistoryBtn)
        RemindIcon.addRemindIcon({parent = bossHistoryBtn, tag = RemindTag.WORLD_BOSS_MANUAL, po = cc.p(bossHistoryBtnSize.width - 25, bossHistoryBtnSize.height - 15)})
    end
    local blackGoldLayer = nil
    local blackSpine = nil
    local blackImage = nil
    local blackLabel = nil
    local blackGoldDescr = nil
    local blackTimeLabel = nil
    local tipLayer = nil
    local tipImage = nil
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.BLACK_GOLD) and (CommonUtils.UnLockModule(RemindTag.BLACK_GOLD)) then
        local blackGoldLayerSize = cc.size(150 , 150)
        blackGoldLayer= display.newLayer(display.cx +254, display.cy + 91 , {ap = display.CENTER , color = cc.c4b(0,0,0,0), enable = true ,  size = blackGoldLayerSize} )
        blackSpine = sp.SkeletonAnimation:create('ui/world/effect/gold_home_boat.json', 'ui/world/effect/gold_home_boat.atlas', 1)
        blackSpine:update(0)
        view:addChild(blackGoldLayer)

        blackImage = display.newImageView(RES_DICT.GOLD_HOME_ENTRY_BOX , blackGoldLayerSize.width/2 , blackGoldLayerSize.height/2)
        blackGoldLayer:addChild(blackImage)

        blackGoldLayer:addChild(blackSpine)
        blackSpine:setAnchorPoint(display.CENTER)
        blackSpine:setPosition(blackGoldLayerSize.width/2 , blackGoldLayerSize.height/2 -20)
        blackSpine:setScaleX(-1)
        blackLabel = display.newLabel(blackGoldLayerSize.width/2 , 15 ,  fontWithColor(10 , {text = ""}))
        blackGoldLayer:addChild(blackLabel)
        blackLabel:setVisible(false)

        local tipLayerSize = cc.size(313, 91)
        tipLayer = display.newLayer(blackGoldLayerSize.width/2 , blackGoldLayerSize.height/2 -20, {ap = display.CENTER_TOP ,  size = tipLayerSize })
        tipImage = display.newImageView(RES_DICT.GOLD_HOME_BG_TIME_ENTRY_BOAT ,tipLayerSize.width/2 , tipLayerSize.height/2 )
        tipLayer:addChild(tipImage)
        tipImage:setScale(1.2)
        blackGoldLayer:addChild(tipLayer)
        tipLayer:setVisible(false)

        blackGoldDescr = display.newLabel(tipLayerSize.width/2 , tipLayerSize.height /2,
                fontWithColor(10, fontWithColor(6,{text = "" , fontSize = 24})))
        tipLayer:addChild(blackGoldDescr)

        blackTimeLabel = display.newLabel(tipLayerSize.width/2 , tipLayerSize.height /2 -35 , fontWithColor('10', {text = "" }))
        tipLayer:addChild(blackTimeLabel)
    end
    -------------------------------------------------
    -- left layer
    local leftLayer = display.newLayer(display.SAFE_L, -5, {ap = display.LEFT_BOTTOM})
    leftLayer:addChild(display.newImageView(_res(RES_DICT.LEFT_NAME_FRAME), -60, 0, {ap = display.LEFT_BOTTOM}))
    leftLayer:addChild(display.newImageView(_res(RES_DICT.LEFT_NAME_WORDS), 200, 56))
    view:addChild(leftLayer)


    -------------------------------------------------
    -- right layer
    local rightSize  = display.size
    local rightLayer = display.newLayer(display.SAFE_R + 60, -5, {ap = display.RIGHT_BOTTOM, size = rightSize})
    rightLayer:addChild(display.newImageView(_res(RES_DICT.RIGHT_NAME_FRAME), display.width, 0, {ap = display.RIGHT_BOTTOM}))
    view:addChild(rightLayer)

    -- back button
    local backBtn = display.newButton(rightSize.width - 125, 63, {n = _res(RES_DICT.RIGHT_BACK_BUTTON)})
    display.commonLabelParams(backBtn, fontWithColor(20, {fontSize = 28, outline = '#654536', text = __('返回')}))
    rightLayer:addChild(backBtn)

    -- city label
    local cityLabel = display.newLabel(rightSize.width - 320, 38, fontWithColor(1, {fontSize = 26, color = '#ffe3e8'}))
    rightLayer:addChild(cityLabel)

    -------------------------------------------------
    -- func layer
    local funcSize  = display.size
    local funcLayer = display.newLayer(0, 0, {size = funcSize})
    view:addChild(funcLayer)

    return {
        view           = view,
        backBtn        = backBtn,
        cityLabel      = cityLabel,
        cityLayer      = cityLayer,
        bossLayer      = bossLayer,
        bossInfoLayer  = bossInfoLayer,
        bossOnFrame    = bossOnFrame,
        bossOffFrame   = bossOffFrame,
        bossOnLabel    = bossOnLabel,
        bossOffLabel   = bossOffLabel,
        bossTimeBar    = bossTimeBar,
        bossHistoryBtn = bossHistoryBtn,
        funcLayer      = funcLayer,
        blackGoldLayer = blackGoldLayer,
        blackLabel     = blackLabel,
        blackImage     = blackImage,
        blackSpine     = blackSpine,
        tipLayer       = tipLayer,
        blackGoldDescr = blackGoldDescr,
        blackTimeLabel = blackTimeLabel,
    }
end


CreateCityCell = function()
    local size = cc.size(192, 68)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true, ap = display.CENTER})

    local avatarLayer = display.newLayer(size.width/2, 50)
    view:addChild(avatarLayer)

    local normalImg = display.newImageView(_res(RES_DICT.CITY_NODE_NORMAL), size.width/2, size.height/2)
    local selectImg = display.newImageView(_res(RES_DICT.CITY_NODE_SELECT), size.width/2, size.height/2)
    local lockedImg = display.newImageView(_res(RES_DICT.CITY_NODE_LOCKED), size.width/2, size.height/2)
    view:addChild(normalImg)
    view:addChild(selectImg)
    view:addChild(lockedImg)

    local unlockBar = display.newButton(size.width/2, size.height/2 - 24, {n = _res(RES_DICT.CITY_UNLOCK_INFO), ap = display.CENTER_TOP, enable = false})
    display.commonLabelParams(unlockBar, fontWithColor(18))
    view:addChild(unlockBar)

    local nameLabel = display.newLabel(size.width/2, size.height/2 - 5, fontWithColor(1, {fontSize = 20, color = '#b4601d'}))
    view:addChild(nameLabel)

    return {
        view        = view,
        normalImg   = normalImg,
        selectImg   = selectImg,
        lockedImg   = lockedImg,
        nameLabel   = nameLabel,
        unlockBar   = unlockBar,
        avatarLayer = avatarLayer,
    }
end


CreateBossCell = function()
    local size = cc.size(128, 128)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true, ap = display.CENTER})

    -- add red point
   RemindIcon.addRemindIcon({parent = view, tag = RemindTag.WORLD_BOSS_MANUAL, po = cc.p(size.width - 16, size.height - 15)})

    -- boss spine
    local bossPath  = 'ui/worldboss/spine/wb_bg_spine'
    local bossSpine = sp.SkeletonAnimation:create(bossPath .. '.json', bossPath .. '.atlas', 1.0)
    bossSpine:setPosition(size.width/2, 20)
    bossSpine:setAnimation(0, 'play1', true)
    view:addChild(bossSpine)

    -- fork spine
    local forkPath  = 'ui/worldboss/spine/wb_battle_mark'
    local forkSpine = sp.SkeletonAnimation:create(forkPath .. '.json', forkPath .. '.atlas', 1.0)
    forkSpine:setPosition(size.width/2, size.height - 0)
    forkSpine:setAnimation(0, 'idle', true)
    view:addChild(forkSpine)
    
    return {
        view      = view,
        bossSpine = bossSpine,
        forkSpine = forkSpine,
    }
end

CreateModuleCell = function (img, spinePath)
    local size = cc.size(180, 180)
    -- local size = cc.size(244, 214)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true, ap = display.CENTER})
    
    local img = nil
    if img then
        img  = display.newImageView(_res(img), size.width / 2, size.height / 2, {ap = display.CENTER})
        view:addChild(img)
    end

    local spine = nil
    if spinePath and utils.isExistent(string.format('%s.atlas', spinePath)) then
        spine = sp.SkeletonAnimation:create(
            string.format('%s.json', spinePath),
            string.format('%s.atlas', spinePath),
            1
        )
        spine:update(0)
        spine:setPosition(cc.p(size.width / 2, size.height * 0.25))
        spine:addAnimation(0, 'idle', true)
        view:addChild(spine)
    end

    local nameLabel = display.newLabel(size.width / 2, 30, fontWithColor(14, {ap = display.CENTER_BOTTOM}))
    view:addChild(nameLabel)

    return {
        view      = view,
        img       = img,
        spine     = spine,
        nameLabel = nameLabel,
    }
end

-------------------------------------------------
-- get / set
function WorldMediator:UpdateBlackSpine()
    if self.viewData_.blackSpine and (not tolua.isnull(self.viewData_.blackSpine)) then

        self.viewData_.blackSpine:unregisterSpineEventHandler( sp.EventType.ANIMATION_COMPLETE)
        display.commonUIParams(self.viewData_.blackGoldLayer , {cb =handler(self, self.GoToBlackGold) })
        self.viewData_.blackSpine:registerSpineEventHandler(handler(self, self.BlackSpineAction), sp.EventType.ANIMATION_COMPLETE)
        if app.blackGoldMgr:GetIsTrade() then
            display.commonLabelParams(self.viewData_.blackGoldDescr , {text = __('商船离开倒计时')})
            self.viewData_.blackImage:setVisible(false)
        else
            self.viewData_.blackImage:setVisible(true)
            self.viewData_.blackImage:setOpacity(0)
            self.viewData_.tipLayer:setVisible(true)
            display.commonLabelParams(self.viewData_.blackGoldDescr , {text = __('商船靠岸倒计时')})
        end
        self.viewData_.blackGoldLayer:setVisible(true)
        if self.viewData_.blackSpine then
            if app.blackGoldMgr:GetIsTrade() then
                self.viewData_.blackSpine:setScaleX(1)
                self.viewData_.blackSpine:setToSetupPose()
                self.viewData_.blackSpine:setAnimation(0, 'play', false)
            else
                self.viewData_.blackSpine:setScaleX(1)
                self.viewData_.blackImage:runAction(cc.Sequence:create(
                        cc.DelayTime:create(0.6),
                        cc.FadeIn:create(0.5)
                ))
                self.viewData_.blackSpine:setToSetupPose()
                self.viewData_.blackSpine:setAnimation(0, 'play2', false)
            end

        end
    end
end
function WorldMediator:GoToBlackGold()
    PlayAudioByClickNormal()
    display.loadImage(_res('ui/home/blackShop/gold_home_fg_boat.png'))
    display.loadImage(_res('ui/home/blackShop/gold_home_bg_leave.png'))
    display.loadImage(_res('ui/home/blackShop/gold_home_bg.png'))
    display.loadImage(_res('ui/home/blackShop/gold_home_bg_boat.png'))
    app.blackGoldMgr:AddSpineCache()
    local router = AppFacade.GetInstance():RetrieveMediator('Router')
    router:Dispatch({name = 'HomeMediator'}, {name = 'blackGold.BlackGoldHomeMeditor'})
end
function WorldMediator:BlackSpineAction(event)
    if event.animation ==  'play'then
        local scaleX = 1
        self.viewData_.blackSpine:setScaleX(scaleX)
        self.viewData_.blackSpine:setToSetupPose()
        self.viewData_.blackSpine:setAnimation(0, 'idle', true)
        self.viewData_.tipLayer:setVisible(true)
    end
end
function WorldMediator:getViewData()
    return self.viewData_
end


function WorldMediator:getUnlockDescr(areaId)
    local areaConf    = CommonUtils.GetConfig('common', 'area', areaId) or {}
    local unlockConfs = CommonUtils.GetConfigAllMess('unlockType') or {}
    local unlockInfos = {}
    for unlockId, unlockData in pairs(areaConf.unlockType or {}) do
        table.insert(unlockInfos, CommonUtils.GetBufferDescription(unlockConfs[tostring(unlockId)], unlockData))
    end
    return table.concat(unlockInfos, '\n')
end


-------------------------------------------------
-- private method

function WorldMediator:updateCurrentCityName_()
    local gameManager   = self:GetFacade():GetManager('GameManager')
    local cityAreaConfs = CommonUtils.GetConfigAllMess('area', 'common') or {}
    local currAreaConf  = cityAreaConfs[tostring(gameManager:GetAreaId())] or {}
    display.commonLabelParams(self:getViewData().cityLabel, {text = tostring(currAreaConf.name)})
end


function WorldMediator:updateAllCityStatus_()
    local gameManager   = AppFacade.GetInstance():GetManager('GameManager')
    local newestAreaId  = checkint(gameManager:GetUserInfo().newestAreaId)
    local currentAreaId = gameManager:GetAreaId()

    for areaId, cityCell in pairs(self.cityCellMap_ or {}) do
        if checkint(areaId) > newestAreaId then
            cityCell.normalImg:setVisible(false)
            cityCell.selectImg:setVisible(false)
            cityCell.lockedImg:setVisible(true)
            cityCell.unlockBar:setVisible(false)
        else
            local isCurrentArea = checkint(areaId) == currentAreaId
            cityCell.normalImg:setVisible(not isCurrentArea)
            cityCell.selectImg:setVisible(isCurrentArea)
            cityCell.lockedImg:setVisible(false)
            cityCell.unlockBar:setVisible(false)
        end
    end
end


function WorldMediator:updateWorldBossStatus_()
    local bossStatus  = BOSS_STATUS.NONE
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    local bossMapData = gameManager:getWorldBossMapData() or {}
    local currentTime = getServerTime()

    -- check boss status
    if next(bossMapData) ~= nil then
        bossStatus = BOSS_STATUS.OFF

        for _, bossData in pairs(bossMapData) do
            if currentTime >= checkint(bossData.startTime) then
                bossStatus = BOSS_STATUS.ON
                break
            end
        end
    end

    -- update bossInfo status
    if self.bossStatus_ ~= bossStatus then
        self.bossStatus_ = bossStatus
        self:updateWorldBossInfo_()
        self:updateWorldBossNode_()
    end

    -- boss time countdown
    if self.bossStatus_ == BOSS_STATUS.NONE then
        self:stopWorldBossCountdown_()
    else
        self:startWorldBossCountdown_()
    end
end
function WorldMediator:updateWorldBossInfo_()
    local viewData = self:getViewData()

    -- BOSS 未出现
    if self.bossStatus_ == BOSS_STATUS.NONE then
        viewData.bossInfoLayer:setVisible(false)

    -- BOSS 未开启
    elseif self.bossStatus_ == BOSS_STATUS.OFF then
        viewData.bossInfoLayer:setVisible(true)
        viewData.bossOnFrame:setVisible(false)
        viewData.bossOffFrame:setVisible(true)
        viewData.bossOnLabel:setVisible(false)
        viewData.bossOffLabel:setVisible(true)
        self:updateWorldBossCountdownTime_()

    -- BOSS 已出现
    elseif self.bossStatus_ == BOSS_STATUS.ON then
        viewData.bossInfoLayer:setVisible(true)
        viewData.bossOnFrame:setVisible(true)
        viewData.bossOffFrame:setVisible(false)
        viewData.bossOnLabel:setVisible(true)
        viewData.bossOffLabel:setVisible(false)
        self:updateWorldBossCountdownTime_()

    end
end
function WorldMediator:updateWorldBossNode_()
    local viewData       = self:getViewData()
    local bossLayer      = viewData.bossLayer
    local bossLayerSize  = bossLayer:getContentSize()
    local gameManager    = AppFacade.GetInstance():GetManager('GameManager')
    local bossMapData    = gameManager:getWorldBossMapData() or {}
    local oldBossCellMap = self.bossCellMap_
    self.bossCellMap_    = {}

    -- check bossCell
    local bossLocationConfs = CommonUtils.GetConfigAllMess(BossConfigParser.TYPE.LOCATION, 'worldBossQuest') or {}
    for _, bossData in pairs(bossMapData) do
        local bossQuestId  = checkint(bossData.questId)
        local loctionConf  = bossLocationConfs[tostring(bossData.position)] or {}
        local bossLocation = string.split2(tostring(loctionConf.location), ',')
        local bossCellNode = oldBossCellMap[tostring(bossQuestId)]

        if bossCellNode then
            self.bossCellMap_[tostring(bossQuestId)] = bossCellNode
            oldBossCellMap[tostring(bossQuestId)]    = nil
        else
            -- create bossCell
            bossCellNode = CreateBossCell()
            bossCellNode.view:setTag(bossQuestId)
            bossCellNode.view:setPosition(checkint(bossLocation[1]), bossLayerSize.height - checkint(bossLocation[2]))
            display.commonUIParams(bossCellNode.view, {cb = handler(self, self.onClickBossCellHandler_)})
            self.bossCellMap_[tostring(bossQuestId)] = bossCellNode
            bossLayer:addChild(bossCellNode.view)
        end

        -- update bossCell
        local isEnableBattle = checkint(bossData.leftTimes) > 0
        bossCellNode.forkSpine:setVisible(isEnableBattle)
    end

    -- clean old bossCell
    for _, bossCell in pairs(oldBossCellMap) do
        if bossCell.getParent and bossCell:getParent() then
            bossCell:removeFromParent()
        end
    end
    bossLayer:setVisible(self.bossStatus_ == BOSS_STATUS.ON)
end
function WorldMediator:updateBlackGoldTime()
    local viewData_ =   self.viewData_
    if viewData_.blackLabel then
        display.commonLabelParams(viewData_.blackLabel , {text = CommonUtils.getTimeFormatByType(app.blackGoldMgr:GetLeftSeconds())})
        display.commonLabelParams(viewData_.blackTimeLabel , {text = CommonUtils.getTimeFormatByType(app.blackGoldMgr:GetLeftSeconds())})
    end
end

function WorldMediator:startWorldBossCountdown_()
    if self.worldBossCountdownHandler_ then return end
    self.worldBossCountdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateWorldBossCountdownTime_()
        self:updateWorldBossStatus_()
    end, 0.5)
end
function WorldMediator:stopWorldBossCountdown_()
    if self.worldBossCountdownHandler_ then
        scheduler.unscheduleGlobal(self.worldBossCountdownHandler_)
        self.worldBossCountdownHandler_ = nil
    end
end
function WorldMediator:updateWorldBossCountdownTime_()
    local viewData    = self:getViewData()
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    local bossMapData = gameManager:getWorldBossMapData() or {}
    local currentTime = getServerTime()
    local leftSeconds = 0

    -- BOSS 未开启
    if self.bossStatus_ == BOSS_STATUS.OFF then
        local minStartTime = 0
        for _, bossData in pairs(bossMapData) do
            if minStartTime == 0 then
                minStartTime = checkint(bossData.startTime)
            else
                minStartTime = math.min(checkint(bossData.startTime), minStartTime)
            end
        end
        leftSeconds = minStartTime - currentTime


    -- BOSS 已出现
    elseif self.bossStatus_ == BOSS_STATUS.ON then
        local minEndedTime = 0
        for _, bossData in pairs(bossMapData) do
            if minEndedTime == 0 then
                minEndedTime = checkint(bossData.endTime)
            else
                minEndedTime = math.min(checkint(bossData.endTime), minEndedTime)
            end
        end
        leftSeconds = minEndedTime - currentTime
        viewData.bossInfoLayer:setVisible(leftSeconds >= 0)
    end

    -- update leftSeconds
    display.commonLabelParams(viewData.bossTimeBar, {text = string.formattedTime(leftSeconds, '%02i:%02i:%02i')})
end


-------------------------------------------------
-- handler

function WorldMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickNormal()

    GuideUtils.DispatchStepEvent()
    self:GetFacade():BackMediator()
end


function WorldMediator:onClickCityCellHandler_(sender)
    PlayAudioByClickNormal()

    local clickAreaId  = sender:getTag()
    local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
    local newestAreaId = checkint(gameManager:GetUserInfo().newestAreaId)

    -- check area unlock
    if clickAreaId > newestAreaId then
        local clickAreaConf = CommonUtils.GetConfig('common', 'area', clickAreaId) or {}
        
        -- check unlock info
        if CommonUtils.CheckLockCondition(clickAreaConf.unlockType) then
            -- show unlock tips
            local unlockDescr = string.fmt(__('解锁条件不满足：_descr_'), {_descr_ = self:getUnlockDescr(clickAreaId)})
            app.uiMgr:ShowInformationTips(unlockDescr)
        else
            AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_WOLDMAP_UNLOCK, {areaId = clickAreaId})
        end

    else
        -- switch area
        gameManager:SwitchAreaId(clickAreaId)

        -- close self
        GuideUtils.DispatchStepEvent()
        self:GetFacade():BackMediator()
    end
end


function WorldMediator:onClickBossCellHandler_(sender)
    PlayAudioByClickNormal()
    
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    local bossMapData = gameManager:getWorldBossMapData() or {}
    local currentTime = getServerTime()
    local clickBossId = sender:getTag()

    for _, bossData in pairs(bossMapData) do
        if checkint(bossData.questId) == clickBossId then
            -- check isOpening
            if currentTime >= checkint(bossData.startTime) and currentTime < checkint(bossData.endTime) then

                -- enter worldBoss
                local router = AppFacade.GetInstance():RetrieveMediator('Router')
                router:Dispatch({name = self:GetMediatorName()}, {name = 'WorldBossMediator', params = {questId = clickBossId}})

            else
                -- show tips
                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                if currentTime >= checkint(bossData.endTime) then
                    uiMgr:ShowInformationTips(__('灾祸已经平息，请耐心下次出现'))
                else
                    uiMgr:ShowInformationTips(__('灾祸即将出现，请耐心等待'))
                end
            end
            break
        end
    end
end


function WorldMediator:onClickBossHistoryButtonHandler_(sender)
    PlayAudioByClickNormal()

    local bossHistoryMdt = nil
    if CommonUtils.UnLockModule(RemindTag.WORLD_BOSS_MANUAL, false) then
        bossHistoryMdt = require('Game.mediator.WorldBossManualMediator').new()
    else
        bossHistoryMdt = require('Game.mediator.WorldBossHistoryMediator').new()
    end
    self:GetFacade():RegistMediator(bossHistoryMdt)
end

function WorldMediator:onClickFuncCellHandler_(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()

    if tag == RemindTag.EXPLORE_SYSTEM then
        self:GetFacade():RetrieveMediator("Router"):Dispatch({name = 'WorldMediator'}, {name = 'exploreSystem.ExploreSystemMediator'}, {isBack = true})
    end
end


return WorldMediator
