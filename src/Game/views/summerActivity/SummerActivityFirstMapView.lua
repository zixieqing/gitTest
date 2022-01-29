--[[
活动副本地图的界面
@params table {
}
--]]
local VIEW_SIZE = display.size
local SummerActivityFirstMapView = class('SummerActivityFirstMapView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.summerActivity.SummerActivityFirstMapView'
	node:enableNodeEvents()
	return node
end)

local summerActMgr = AppFacade.GetInstance():GetManager("SummerActivityManager")

local CreateView           = nil
local CreateFacilitiesCell = nil
local CreateLotteryCell    = nil

-- 一级地图点坐标
local facilitiesConf = nil
-- 抽奖点坐标
local lotteryPos = nil

local DEBUG_SHOW_ALL = false -- 调试坐标用

local RES_DIR_ = {
    SUMMER_ACTIVITY_MAPS_ONE = "ui/home/activity/summerActivity/map/summer_activity_maps_one.jpg",
    BTN_BACK        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_title.png'),
    BTN_TIPS        = _res('ui/common/common_btn_tips.png'),
    LOCK_IMG        = _res('ui/common/common_ico_lock.png'),
    
    ONE_BTN         = _res('ui/home/activity/summerActivity/map/summer_activity_maps_one_btn.png'),
    NAME_BG         = _res('ui/home/activity/summerActivity/map/summer_activity_maps_name_bg.png'),
    -- NAME_BG_BOSS    = _res('ui/home/activity/summerActivity/map/summer_activity_maps_name_bg_boss.png'),
    TIME_UNLOCK     = _res('ui/home/activity/summerActivity/map/summer_activity_maps_time_unlock.png'),
    
    LOTTERY_LIGHT      = _res('ui/home/activity/summerActivity/map/summer_activity_maps_btn_niudan_light.png'),
    LOTTERY            = _res('ui/home/activity/summerActivity/map/summer_activity_maps_btn_niudan.png'),
    NAME_BG_BOSS       = _res('ui/home/activity/summerActivity/map/summer_activity_maps_btn_boss.png'),
    NAME_BG_BOSS_LIGHT = _res('ui/home/activity/summerActivity/map/summer_activity_maps_btn_boss_light.png'),
    NAME_BG_LOCK       = _res('ui/home/activity/summerActivity/map/summer_activity_maps_btn_unlock.png'),
    MAPS_BTN           = _res('ui/home/activity/summerActivity/map/summer_activity_maps_btn.png'),
    
    SPINE_YUN           = _spn('ui/home/activity/carnieTheme/springAct_19/entrance/entranceSpine/yun'),

    SPINE_YLY_PATH           = 'ui/home/activity/summerActivity/entrance/entranceSpine/yly',
    SPINE_ACTIVITY_JIQI_PATH = 'ui/home/activity/summerActivity/entrance/entranceSpine/summer_activity_jiqi',
    SPINE_ACTIVITY_YLY_PATH  = 'ui/home/activity/summerActivity/entrance/entranceSpine/summer_activity_yly',
}

local RES_DIR = {}

local BUTTON_TAG = {
    BACK   = 100,
    RULE   = 101,
}

local NODE_STATUS = {
    UNOPEN       = 0,
    OPEN_UNPASS  = 1,
    PASS         = 2,
}

local NODE_TYPES = {
    LOCK  = 1,
    PLOT  = 2,
    QUEST = 3,
    BOSS  = 4,
}

function SummerActivityFirstMapView:ctor( )
    facilitiesConf = summerActMgr:getFirstMapNodePostions()
    lotteryPos = summerActMgr:getFirstMapLotteryNodePostions()
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)
    RES_DIR.SPINE_YLY = _spn(RES_DIR.SPINE_YLY_PATH)
    RES_DIR.SPINE_ACTIVITY_JIQI = _spn(RES_DIR.SPINE_ACTIVITY_JIQI_PATH)
    RES_DIR.SPINE_ACTIVITY_YLY = _spn(RES_DIR.SPINE_ACTIVITY_YLY_PATH)
    
	self.viewData_ = nil
	self:initUI()
end

function SummerActivityFirstMapView:initUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self:initLotteryCell()
	end, __G__TRACKBACK__)
end

function SummerActivityFirstMapView:initLotteryCell()
    local viewData = self:getViewData()
    -- local lotteryCell = viewData.lotteryCell

end

function SummerActivityFirstMapView:refreshUI(chapter, nextChapterId, passChapterId)
    local viewData = self:getViewData()
    local paradiseSpines = viewData.paradiseSpines
    local facilitiesCells = viewData.facilitiesCells
    
    -- logInfo.add(5, tableToString(chapter))
    -- logInfo.add(5, tostring(nextChapterId))
    -- logInfo.add(5, tostring(passChapterId))
    -- nextChapterId = '5'
    -- for i, v in pairs(chapter) do
    --     v.isPassed = true
    --     v.remainUnlockTime = 0
    -- end
    for k, facilitiesCell in pairs(facilitiesCells) do

        local isPlayAni = false
        local chapterId = checkint(k)

        local curChapterData = chapter[tostring(chapterId)] or {}

        if chapterId == 1 then
            isPlayAni = true
            self:updateCellQuestStatus(facilitiesCell, curChapterData)
        elseif passChapterId and checkint(passChapterId) ~= 5 and (checkint(passChapterId) + 1) == chapterId then
            self:updateCellLockStatus(facilitiesCell, checkint(nextChapterId) >= checkint(chapterId), curChapterData)
            self:showUnlockUI(curChapterData, chapterId)
        else
            local preChapterData = chapter[tostring(chapterId - 1)] or {}
            local preIsPassed = preChapterData.isPassed
            local curRemainUnlockTime = checkint(curChapterData.remainUnlockTime)
            if preIsPassed then
                isPlayAni = true
                if chapterId == 5 then
                    self:updateCellBossStatus(facilitiesCell)
                else
                    self:updateCellQuestStatus(facilitiesCell, curChapterData)
                end
            else
                self:updateCellLockStatus(facilitiesCell, checkint(nextChapterId) >= checkint(chapterId), curChapterData)
            end
        end

        if DEBUG_SHOW_ALL then
            facilitiesCell:setVisible(true)
        else
            facilitiesCell:setVisible(checkint(nextChapterId) >= checkint(chapterId))
        end

        local paradiseSpine = paradiseSpines[k]
        if isPlayAni and paradiseSpine then
            paradiseSpine:setVisible(true)
            paradiseSpine:addAnimation(0, 'idle' .. k, true)
        end

    end

end

--==============================--
--desc: 更新cell 解锁状态
--@params cell 
--@params isNextChapter 是否是下一章节
--@params chapterData   章节数据
--@return 
--==============================--
function SummerActivityFirstMapView:updateCellLockStatus(cell, isNextChapter, chapterData)
    local viewData = cell.viewData
    if viewData.unopenLayer == nil then
        local bgLayer = viewData.bgLayer
        local bgSize = viewData.bgSize
        
        local unopenLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2,{size = bgSize, ap = display.CENTER})
        bgLayer:addChild(unopenLayer)
        unopenLayer:setCascadeOpacityEnabled(true)
        unopenLayer:setVisible(true)

        -- 解锁 tip
        local lockTipBgSize = cc.size(188, 33)
        local lockTipBg = display.newImageView(RES_DIR.NAME_BG_LOCK, bgSize.width / 2, 2, {scale9 = true, size = lockTipBgSize, ap = display.CENTER_BOTTOM})
        lockTipBg:setCascadeOpacityEnabled(true)
        unopenLayer:addChild(lockTipBg)
        
        local lockTipLabel = display.newLabel(0, 0, fontWithColor(18, {hAlign = display.TAC, ap = display.CENTER}))
        local lockImg = display.newImageView(RES_DIR.LOCK_IMG, 0, 0, {ap = display.CENTER})
        local lockImgScale = 0.65
        lockImg:setOpacity(178)
        lockImg:setScale(lockImgScale)
        lockTipBg:addChild(lockTipLabel) 
        lockTipBg:addChild(lockImg)

        viewData.lockTipBg = lockTipBg
        viewData.lockTipLabel = lockTipLabel
        viewData.lockImg = lockImg
        viewData.unopenLayer = unopenLayer
    end

    local unopenLayer = viewData.unopenLayer
    if DEBUG_SHOW_ALL then
        unopenLayer:setVisible(true)
    else
        unopenLayer:setVisible(isNextChapter)
    end

    self:updateLockTipLabel(viewData, chapterData)
    
end

--==============================--
--desc: 更新解锁提示
--@params viewData  table  视图数据
--@params chapterData  table 章节数据
--@return 
--==============================--
function SummerActivityFirstMapView:updateLockTipLabel(viewData, chapterData)
    local lockTipLabel = viewData.lockTipLabel
    local lockImg = viewData.lockImg
    local lockTipBg = viewData.lockTipBg

    local chapterConf = chapterData.chapterConf or {}
    display.commonLabelParams(lockTipLabel, {text = tostring(chapterConf.name)})

    local lockTipBgSize = lockTipBg:getContentSize()
    local lockTipLabelSize = display.getLabelContentSize(lockTipLabel)
    local lockImgSize = lockImg:getContentSize()
    local lockTipW = lockTipLabelSize.width + lockImgSize.width * 0.65
    
    if lockTipW > lockTipBgSize.width then
        lockTipBgSize = cc.size(lockTipW + 50, lockTipBgSize.height)
        lockTipBg:setContentSize(lockTipBgSize)
    end

    display.commonUIParams(lockTipLabel, {po = cc.p(lockTipBgSize.width / 2 + lockImgSize.width / 2 * 0.65 + 5, lockTipBgSize.height / 2)})
    display.commonUIParams(lockImg, {po = cc.p(lockTipBgSize.width / 2 - lockTipLabelSize.width / 2 - 5, lockTipBgSize.height / 2 + 3)})
end

--==============================--
--desc: 更新解锁时间
--@params viewData  table  视图数据
--@params remainUnlockTime  int 剩余解锁时间
--@return 
--==============================--
function SummerActivityFirstMapView:updateTimeLable(viewData, remainUnlockTime)
    local timeBg    = viewData.timeBg
    local timeLabel = viewData.timeLabel
    local isShowTime = remainUnlockTime and remainUnlockTime ~= 0
    
    timeBg:setVisible(isShowTime)
    timeLabel:setVisible(isShowTime)
    if isShowTime then
        local text = string.format( summerActMgr:getThemeTextByText(__("%s后开放")), CommonUtils.getTimeFormatByType(remainUnlockTime))
        display.commonLabelParams(timeLabel, {text = text})
        local timeLabelSize = display.getLabelContentSize(timeLabel)
        local timeBgSize = timeBg:getContentSize()
        if timeLabelSize.width > (timeBgSize.width - 10) then
            timeBgSize = cc.size(timeLabelSize.width + 10, timeLabelSize.height + 8)
            timeBg:setContentSize(timeBgSize)
        end
        display.commonUIParams(timeLabel, {po = cc.p(timeBgSize.width / 2, timeBgSize.height / 2)})
    end
end

--==============================--
--desc: 更新关卡cell视图状态
--@params cell  userdata  视图
--@params data  table 
--@return 
--==============================--
function SummerActivityFirstMapView:updateCellQuestStatus(cell, data)
    -- logInfo.add(5, tableToString(data))
    local viewData = cell.viewData
    if viewData.nameBg == nil then
        local bgLayer = viewData.bgLayer
        local bgSize = viewData.bgSize
        local namebgSize = cc.size(202, 39)
        local nameBg = display.newImageView(RES_DIR.MAPS_BTN, bgSize.width / 2, 0, {scale9 = true, size = namebgSize, ap = display.CENTER_BOTTOM})
        nameBg:setCascadeOpacityEnabled(true)
        bgLayer:addChild(nameBg)

        local nameLabel = display.newLabel(namebgSize.width / 2, namebgSize.height / 2, fontWithColor(16, {ap = display.CENTER, hAlign = display.TAC}))
        nameBg:addChild(nameLabel)

        viewData.nameBg = nameBg
        viewData.nameLabel = nameLabel
    end

    self:updateNameLabel(viewData, data)
end

--==============================--
--desc: 更新关卡名称
--@params viewData  table  视图数据
--@params data  table 
--@return 
--==============================--
function SummerActivityFirstMapView:updateNameLabel(viewData, data)
    local nameBg    = viewData.nameBg
    local nameLabel = viewData.nameLabel

    local chapterConf = data.chapterConf or {}
    display.commonLabelParams(nameLabel, {text = tostring(chapterConf.name)})
    local nameLabelSize = display.getLabelContentSize(nameLabel)
    local nameBgSize = nameBg:getContentSize()
    
    if (nameLabelSize.width + 46) > nameBgSize.width then
        nameBgSize = cc.size(nameLabelSize.width + 46, 39)
        nameBg:setContentSize(nameBgSize)
    end
    nameLabel:setPositionX(nameBgSize.width / 2)
    -- nameBg:setVisible(false)
end

--==============================--
--desc: 更新boss cell
--@params cell  userdata  视图
--@return 
--==============================--
function SummerActivityFirstMapView:updateCellBossStatus(cell)
    local viewData = cell.viewData
    local bgSize = viewData.bgSize
    local bgLayer = viewData.bgLayer

    local bossNameBgFrameSize = cc.size(220, 71)
    local bossNameBgFrame = display.newImageView(RES_DIR.NAME_BG_BOSS_LIGHT, bgSize.width / 2, 12, {ap = display.CENTER_TOP, scale9 = true, size = bossNameBgFrameSize})
    bgLayer:addChild(bossNameBgFrame)
    
    local bossNameBgSize = cc.size(190, 39)
    local bossNameBg = display.newImageView(RES_DIR.NAME_BG_BOSS, bossNameBgFrameSize.width / 2, bossNameBgFrameSize.height / 2, {
        ap = display.CENTER, scale9 = true, size = bossNameBgSize})
    bossNameBgFrame:addChild(bossNameBg)

    local bossNameTip = display.newLabel(0, 0, fontWithColor(18, {color = '#ffbd3f', hAlign = display.TAC, ap = display.CENTER, text = summerActMgr:getThemeTextByText(__('首领')) }))
    local bossNameLabel = display.newLabel(0, 0, fontWithColor(18, {hAlign = display.TAC, ap = display.CENTER, text = summerActMgr:getThemeTextByText(__('马戏团'))}))
    local bossNameTipSize = display.getLabelContentSize(bossNameTip)
    local bossNameLabelSize = display.getLabelContentSize(bossNameLabel)
    
    local sizeW = bossNameTipSize.width + bossNameLabelSize.width + 10
    if sizeW > bossNameBgSize.width then
        bossNameBgFrameSize = cc.size(sizeW + 30, 71)
        bossNameBgFrame:setContentSize(bossNameBgFrameSize)

        bossNameBgSize = cc.size(sizeW + 10, 39)
        bossNameBg:setContentSize(bossNameBgSize)

        display.commonUIParams(bossNameBg, {po = cc.p(bossNameBgFrameSize.width / 2, bossNameBgFrameSize.height / 2)})
    end

    display.commonUIParams(bossNameTip, {po = cc.p(bossNameBgSize.width / 2 - bossNameLabelSize.width / 2 - 5, bossNameBgSize.height / 2 + 3)})
    display.commonUIParams(bossNameLabel, {po = cc.p(bossNameBgSize.width / 2 + bossNameTipSize.width / 2 + 5 , bossNameBgSize.height / 2 + 3)})

    bossNameBg:addChild(bossNameTip)
    bossNameBg:addChild(bossNameLabel)
end


CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    view:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_MAPS_ONE, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local actionBtns      = {}
    local facilitiesCells = {}
    -------------------------------------------------
    -- top layer
    local paradiseLayerSize = cc.size(1624, 1002)
    local paradiseLayer = display.newLayer(size.width / 2, size.height / 2, {size = cc.size(1624, 1002), ap = display.CENTER})
    view:addChild(paradiseLayer)

    local facilitiesLayer = display.newLayer(size.width / 2, size.height / 2, {size = cc.size(1624, 1002), ap = display.CENTER})
    view:addChild(facilitiesLayer)
    

    local paradiseSpineJson = RES_DIR.SPINE_YLY.json
    local paradiseSpineAtlas = RES_DIR.SPINE_YLY.atlas
    local paradiseSpines = {}

    for i, conf in ipairs(facilitiesConf) do
        local cell = CreateFacilitiesCell()
        local location = conf.location
        display.commonUIParams(cell, {po = cc.p(location.x, location.y)})
        facilitiesLayer:addChild(cell)

        if CommonUtils.checkIsExistsSpine(paradiseSpineJson, paradiseSpineAtlas) then
            local paradiseSpine = sp.SkeletonAnimation:create(paradiseSpineJson, paradiseSpineAtlas, 1)
            paradiseSpine:update(0)
            paradiseSpine:setPosition(cc.p(paradiseLayerSize.width / 2, paradiseLayerSize.height / 2))
            paradiseLayer:addChild(paradiseSpine, 5)
            paradiseSpines[tostring(i)] = paradiseSpine
            paradiseSpine:setVisible(false)
        end
        facilitiesCells[tostring(i)] = cell
    end

    local spineJson = RES_DIR.SPINE_ACTIVITY_JIQI.json
    local spineAtlas = RES_DIR.SPINE_ACTIVITY_JIQI.atlas
    if CommonUtils.checkIsExistsSpine(spineJson,spineAtlas) then
        local spine = sp.SkeletonAnimation:create(spineJson, spineAtlas, 1)
        spine:update(0)
        spine:addAnimation(0, 'idle', true)
        spine:setPosition(cc.p(paradiseLayerSize.width / 2, paradiseLayerSize.height / 2))
        paradiseLayer:addChild(spine, 5)
    end

    local lotteryCell = CreateLotteryCell()
    display.commonUIParams(lotteryCell, {po = lotteryPos})
    facilitiesLayer:addChild(lotteryCell)

    if summerActMgr:IsSpringAct19() or summerActMgr:IsSpringAct20() then
        local yunLayer = display.newLayer(size.width / 2, size.height / 2, {size = cc.size(1624, 1002), ap = display.CENTER})
        view:addChild(yunLayer)
        local paradisetYunSpineJson = RES_DIR.SPINE_YUN.json
        local paradisetYunSpineAtlas = RES_DIR.SPINE_YUN.atlas
        if CommonUtils.checkIsExistsSpine(paradisetYunSpineJson, paradisetYunSpineAtlas) then
            local spine = sp.SkeletonAnimation:create(paradisetYunSpineJson, paradisetYunSpineAtlas, 1)
            spine:update(0)
            spine:setPosition(cc.p(paradiseLayerSize.width / 2, paradiseLayerSize.height / 2))
            spine:setAnimation(0, 'idle', true)
            yunLayer:addChild(spine, 5)
            -- paradiseSpine:setVisible(false)
        end
    end

    return {
        view            = view,
        actionBtns      = actionBtns,
        facilitiesLayer = facilitiesLayer,
        facilitiesCells = facilitiesCells,
        paradiseSpines  = paradiseSpines,
        lotteryCell     = lotteryCell,
        paradiseLayer   = paradiseLayer,
    }
end

CreateFacilitiesCell = function ()
    local size = cc.size(220, 205)
    local layer = display.newLayer(0,0,{size = size, ap = display.CENTER})

    local bgSize = cc.size(220, 173)
    local bgLayer = display.newLayer(size.width / 2, size.height,{size = bgSize, ap = display.CENTER_TOP, enable = true, color = cc.c4b(0, 0, 0, DEBUG_SHOW_ALL and 150 or 0)})
    layer:addChild(bgLayer)

    local timeBg = display.newImageView(RES_DIR.TIME_UNLOCK, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER, scale9 = true})
    bgLayer:addChild(timeBg)

    local timeLabel = display.newLabel(0, 0, fontWithColor(11, {color = '#7c0000', ap = display.CENTER}))
    timeBg:addChild(timeLabel)
    timeBg:setVisible(false)

    layer.viewData = {
        bgLayer   = bgLayer,
        bgSize    = bgSize,
        timeBg    = timeBg,
        timeLabel = timeLabel,
    }

    return layer
end

CreateLotteryCell = function ()
    local layer = CreateFacilitiesCell()
    local viewData = layer.viewData
    local bgLayer = viewData.bgLayer
    local bgSize  = viewData.bgSize

    local lotteryBgFrameSize = cc.size(220, 71)
    local lotteryBgFrame = display.newImageView(RES_DIR.LOTTERY_LIGHT, bgSize.width / 2, -26, {ap = display.CENTER_TOP, scale9 = true, size = lotteryBgFrameSize})
    bgLayer:addChild(lotteryBgFrame)
    
    local lotteryBgSize = cc.size(190, 39)
    local lotteryBg = display.newImageView(RES_DIR.LOTTERY, lotteryBgFrameSize.width / 2, lotteryBgFrameSize.height / 2, {
        ap = display.CENTER, scale9 = true, size = lotteryBgSize})
    lotteryBgFrame:addChild(lotteryBg)

    local lotteryName = display.newLabel(0, 0, fontWithColor(10, {text = summerActMgr:getThemeTextByText(__('扭蛋机')), ap = display.CENTER}))
    local lotteryNameSize = display.getLabelContentSize(lotteryName)

    if (lotteryNameSize.width + 40) > lotteryBgSize.width then
        lotteryBgSize = cc.size(lotteryNameSize.width + 40, 39)
        lotteryBg:setContentSize(lotteryBgSize)
    end
    display.commonUIParams(lotteryName, {po = cc.p(lotteryBgSize.width / 2, lotteryBgSize.height / 2 + 3)})
    lotteryBg:addChild(lotteryName)

    return layer
end

function SummerActivityFirstMapView:getViewData()
    return self.viewData_
end

function SummerActivityFirstMapView:CreateYlySpine(facilitiesCell, isPlay)
    local cellViewData = facilitiesCell.viewData
    if cellViewData.ylySpine == nil then
        local spineJson1 = RES_DIR.SPINE_ACTIVITY_YLY.json
        local spineAtlas1 = RES_DIR.SPINE_ACTIVITY_YLY.atlas
        if CommonUtils.checkIsExistsSpine(spineJson1, spineAtlas1) then
            local spine = sp.SkeletonAnimation:create(spineJson1, spineAtlas1, 0.75)
            spine:update(0)
            -- spine:addAnimation(0, 'attack', false)
            spine:setPosition(cc.p(facilitiesCell:getContentSize().width / 2, facilitiesCell:getContentSize().height / 2 + 50))
            facilitiesCell:addChild(spine, 5)
            spine:setVisible(false)
            cellViewData.ylySpine = spine
        end
    end

    if isPlay then
        local cellViewData = facilitiesCell.viewData
        self:playYlySpine(cellViewData.ylySpine)
    end
end

function SummerActivityFirstMapView:playYlySpine(spine)
    if spine then
        spine:setVisible(true)
        spine:addAnimation(0, 'attack', false)
    end
end

function SummerActivityFirstMapView:showUnlockUI(chapterData, chapterId)
    local viewData = self:getViewData()
    local facilitiesCells = viewData.facilitiesCells
    local facilitiesCell = facilitiesCells[tostring(chapterId)]
    
    self:updateCellQuestStatus(facilitiesCell, chapterData)

    self:CreateYlySpine(facilitiesCell)
    
    local cellViewData = facilitiesCell.viewData
    local remainUnlockTime = checkint(chapterData.remainUnlockTime)
    
    cellViewData.nameBg:setOpacity(0)
    local action = nil
    if remainUnlockTime <= 0 then
        action = cc.Sequence:create(
            cc.CallFunc:create(function ()
                self:playYlySpine(cellViewData.ylySpine)
            end),
            cc.TargetedAction:create(cellViewData.unopenLayer, cc.FadeOut:create(0.8)),
            cc.TargetedAction:create(cellViewData.nameBg, cc.FadeTo:create(0.8, 255))
        )
    else
        action = cc.Sequence:create(
            cc.TargetedAction:create(cellViewData.unopenLayer, cc.FadeOut:create(0.8)),
            cc.TargetedAction:create(cellViewData.nameBg, cc.FadeTo:create(0.8, 255))
        )
    end
    if action then
        self:runAction(action)
    end

end

function SummerActivityFirstMapView:CreateHideStoryCell()
    local viewData = self:getViewData()
    local hideStoryCell = viewData.hideStoryCell
    if hideStoryCell then
        return 
    end
    local pos = app.summerActMgr:GetHideStoryPos()

    local paradiseLayer = viewData.paradiseLayer
    local size = cc.size(220, 205)
    hideStoryCell = display.newLayer(pos.x, pos.y, {size = size, ap = display.CENTER})
    paradiseLayer:addChild(hideStoryCell, 5)

    local bgSize = cc.size(220, 173)
    local bgLayer = display.newLayer(size.width / 2, size.height,{size = bgSize, ap = display.CENTER_TOP, enable = true, color = cc.c4b(0, 0, 0, 0), cb = handler(self, self.OnClickHideStoryCcll)})
    hideStoryCell:addChild(bgLayer)

    local paradiseLayerSize = paradiseLayer:getContentSize()
    local paradiseSpineJson = RES_DIR.SPINE_YLY.json
    local paradiseSpineAtlas = RES_DIR.SPINE_YLY.atlas
    local paradiseSpine = sp.SkeletonAnimation:create(paradiseSpineJson, paradiseSpineAtlas, 1)
    paradiseSpine:update(0)
    paradiseSpine:setPosition(cc.p(paradiseLayerSize.width / 2, paradiseLayerSize.height / 2))
    paradiseLayer:addChild(paradiseSpine, 5)
    paradiseSpine:addAnimation(0, 'idle6', true)
    
    local confs = CommonUtils.GetConfigAllMess('mainStoryCollection', 'summerActivity') or {}
    local hideStoryId = summerActMgr:GetHideStoryId()
    local name = ''
    for i, conf in ipairs(confs) do
        if checkint(conf.storyId) == hideStoryId then
            name = tostring(conf.name)
        end
    end
    local nameBg = display.newButton(bgSize.width / 2, 0, {n = RES_DIR.LOTTERY, scale9 = true, enable = false, ap = display.CENTER_BOTTOM})
    display.commonLabelParams(nameBg, fontWithColor(16, {ap = display.CENTER, offset = cc.p(0, 2), hAlign = display.TAC, text = name, paddingW = 40}))
    bgLayer:addChild(nameBg)

    hideStoryCell.viewData = {
        bgLayer   = bgLayer,
        bgSize    = bgSize,
        nameBg    = nameBg,
    }

end

function SummerActivityFirstMapView:OnClickHideStoryCcll()
    local hideStoryId = summerActMgr:GetHideStoryId()
    if summerActMgr:CheckMainStoryIsUnlock(storyId) == nil then
        app:DispatchSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = hideStoryId, storyTag = 0})
    end 
    
    summerActMgr:ShowOperaStage(hideStoryId, nil, 1)
end

return SummerActivityFirstMapView