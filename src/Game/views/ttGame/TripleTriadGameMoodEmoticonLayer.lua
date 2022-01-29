--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 心情文字图层
]]
local TTGameMoodLayer = class('TripleTriadGameMoodEmoticonLayer', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameMoodEmoticonLayer'})
end)

local RES_DICT = {
    TALK_FRAME_BG = _res('ui/ttgame/common/cardgame_common_bg_talk.png'),
    CUTTING_LINE  = _res('ui/ttgame/common/cardgame_common_line_talk.png'),
    TALK_HORN_IMG = _res('ui/ttgame/common/cardgame_common_bg_talk_horn.png'),
}

local CreateView      = nil
local CreateMoodCell  = nil
local MOOD_CELL_SIZE  = cc.size(260, 60)
local MOOD_ENTRY_SIZE = cc.size(260, 60)


function TTGameMoodLayer:ctor(args)
    -- init vars
    local initArgs       = args or {}
    self.closeCallback_  = initArgs.closeCB
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self:getViewData().view)
    
    self.moodCellVDList_ = {}
    local moodCellMaxW   = MOOD_CELL_SIZE.width
    local insertMoodCell = function(moodId, moodName)
        local cellViewData = CreateMoodCell()
        self:getMoodCellLayer():addChild(cellViewData.view)
        table.insert(self.moodCellVDList_, cellViewData)
        cellViewData.hotspot:setTag(moodId)
        cellViewData.view:setTag(moodId)
        
        display.commonLabelParams(cellViewData.moodLabel, {text = tostring(moodName)})
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickMoodCellHandler_)})

        moodCellMaxW = math.max(moodCellMaxW, display.getLabelContentSize(cellViewData.moodLabel).width + 80)
    end
    
    -- mood conf
    local moodConfFile = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CHAT_MOOD)
    for moodId = 1, table.nums(moodConfFile) do
        local moodConfInfo = moodConfFile[tostring(moodId)] or {}
        insertMoodCell(checkint(moodId), tostring(moodConfInfo.message))
    end

    -- add listener
    display.commonUIParams(self:getViewData().blockLayer, {cb = handler(self, self.onClickBlockLayerHandler_), animate = false})

    -- update views
    local MOOD_LAYER_SPACE_H    = 0
    local MOOD_LAYER_BORDER_W   = 10
    local MOOD_LAYER_BORDER_T   = 10
    local MOOD_LAYER_BORDER_B   = 10
    local MOOD_CELL_DISTANCE_H  = MOOD_LAYER_SPACE_H + MOOD_CELL_SIZE.height
    local totalMoodCellSize     = cc.size(moodCellMaxW, #self:getMoodCellVDList() * MOOD_CELL_DISTANCE_H - MOOD_LAYER_SPACE_H)
    local fullMoodCellLayerSize = cc.size(totalMoodCellSize.width + MOOD_LAYER_BORDER_W*2, totalMoodCellSize.height + MOOD_LAYER_BORDER_T + MOOD_LAYER_BORDER_B)
    self:getViewData().moodCellLayer:setContentSize(fullMoodCellLayerSize)
    self:getViewData().moodCellBgImg:setContentSize(fullMoodCellLayerSize)

    for cellIndex, cellViewData in ipairs(self:getMoodCellVDList()) do
        cellViewData.updateSize(cc.size(moodCellMaxW, MOOD_CELL_SIZE.height))
        cellViewData.view:setPositionX(fullMoodCellLayerSize.width/2)
        cellViewData.view:setPositionY(fullMoodCellLayerSize.height - MOOD_LAYER_BORDER_T - (cellIndex-1) * MOOD_CELL_DISTANCE_H)

        if cellIndex > 1 then
            local splitLine = display.newImageView(RES_DICT.CUTTING_LINE, cellViewData.view:getPositionX(), cellViewData.view:getPositionY(), {scale9 = true, size = cc.size(moodCellMaxW - 20, 2)})
            self:getMoodCellLayer():addChild(splitLine)
        end
    end
end


CreateView = function(size)
    local view = display.newLayer()

    -- block layer
    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(blockLayer)
    
    local moodCellLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, color1 = cc.c4b(100)})
    view:addChild(moodCellLayer)

    local moodCellBgImg = display.newImageView(RES_DICT.TALK_FRAME_BG, 0, 0, {scale9 = true, ap = display.LEFT_BOTTOM})
    moodCellLayer:addChild(moodCellBgImg)

    return {
        view          = view,
        blockLayer    = blockLayer,
        moodCellLayer = moodCellLayer,
        moodCellBgImg = moodCellBgImg,
    }
end


CreateMoodCell = function()
    local size = MOOD_CELL_SIZE
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER_TOP, color1 = cc.r4b(50)})

    local moodLabel = display.newLabel(0, 0, fontWithColor(3, {color = '#f7cc8f'}))
    view:addChild(moodLabel)

    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view       = view,
        hotspot    = hotspot,
        moodLabel  = moodLabel,
        updateSize = function(newSize)
            view:setContentSize(newSize)
            hotspot:setContentSize(newSize)
            moodLabel:setPosition(newSize.width/2, newSize.height/2)
        end,
    }
end


-------------------------------------------------
-- mood entry

function TTGameMoodLayer.CreateMoodEntry(direction)
    local view = display.newLayer(0, 0, {color1 = cc.r4b(150)})
    view:setName('TTGameMoodLayer.CreateMoodEntry_' .. direction)

    local moodFrame = display.newImageView(RES_DICT.TALK_FRAME_BG, 0, 0, {scale9 = true, ap = display.LEFT_BOTTOM})
    view:addChild(moodFrame)
    
    local moodHorn = display.newImageView(RES_DICT.TALK_HORN_IMG)
    view:addChild(moodHorn)
    
    local moodLabel = display.newLabel(0, 0, fontWithColor(3))
    view:addChild(moodLabel)
    
    view.direction = tostring(direction)
    view:setVisible(false)
    return {
        view      = view,
        moodFrame = moodFrame,
        moodHorn  = moodHorn,
        moodLabel = moodLabel,
    }
end


function TTGameMoodLayer.UpdateMoodEntry(moodEntryVD, moodId)
    if not moodEntryVD then return end
    
    local moodConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CHAT_MOOD, moodId)
    display.commonLabelParams(moodEntryVD.moodLabel, {text = tostring(moodConfInfo.message)})

    local ENTRY_BORDER_W = 10
    local ENTRY_BORDER_T = 10
    local ENTRY_BORDER_B = 10
    local moodLabelSize  = display.getLabelContentSize(moodEntryVD.moodLabel)
    local moodEntryMaxW  = math.max(MOOD_CELL_SIZE.width, moodLabelSize.width + 80)
    local moodEntrySize  = cc.size(moodEntryMaxW + ENTRY_BORDER_W*2, MOOD_CELL_SIZE.height + ENTRY_BORDER_T + ENTRY_BORDER_B)
    moodEntryVD.view:setContentSize(moodEntrySize)
    moodEntryVD.moodFrame:setContentSize(moodEntrySize)
    moodEntryVD.moodLabel:setPositionX(moodEntrySize.width/2)
    moodEntryVD.moodLabel:setPositionY(moodEntrySize.height/2)
    
    if moodEntryVD.view.direction == 'r' then
        moodEntryVD.moodHorn:setRotation(90)
        moodEntryVD.moodHorn:setPositionX(moodEntrySize.width + 1)
        moodEntryVD.moodHorn:setPositionY(moodEntrySize.height/2)
    else
        moodEntryVD.moodHorn:setRotation(-90)
        moodEntryVD.moodHorn:setPositionX(-1)
        moodEntryVD.moodHorn:setPositionY(moodEntrySize.height/2)
    end

    moodEntryVD.isAnimateRunning = true
    TTGameMoodLayer.ShowMoodEntry(moodEntryVD)
end


function TTGameMoodLayer.isMoodEntryShowing(moodEntryVD)
    return moodEntryVD and moodEntryVD.isAnimateRunning == true
end
function TTGameMoodLayer.ShowMoodEntry(moodEntryVD)
    if not moodEntryVD then return end
    moodEntryVD.view:setScaleX(0)
    moodEntryVD.view:setScaleY(1)
    moodEntryVD.view:setOpacity(0)
    moodEntryVD.view:setRotation(moodEntryVD.view.direction == 'r' and 45 or -45)
    moodEntryVD.view:stopAllActions()
    moodEntryVD.view:runAction(cc.Sequence:create(
        cc.Show:create(),
        cc.Spawn:create(
            cc.EaseCubicActionOut:create(cc.FadeIn:create(0.3)),
            cc.EaseCubicActionOut:create(cc.ScaleTo:create(0.3, 1, 1)),
            cc.EaseCubicActionOut:create(cc.RotateTo:create(0.3, 0))
        ),
        cc.DelayTime:create(1.7),
        cc.CallFunc:create(function()
            TTGameMoodLayer.HideMoodEntry(moodEntryVD)
        end)
    ))
end
function TTGameMoodLayer.HideMoodEntry(moodEntryVD)
    if not moodEntryVD then return end
    moodEntryVD.view:setScaleX(1)
    moodEntryVD.view:setScaleY(1)
    moodEntryVD.view:setRotation(0)
    moodEntryVD.view:setOpacity(255)
    moodEntryVD.view:stopAllActions()
    moodEntryVD.view:runAction(cc.Sequence:create(
        cc.Show:create(),
        cc.EaseCubicActionIn:create(cc.ScaleTo:create(0.2, 0, 1)),
        cc.Hide:create(),
        cc.CallFunc:create(function()
            moodEntryVD.isAnimateRunning = false
        end)
    ))
end


-------------------------------------------------
-- get / set

function TTGameMoodLayer:getViewData()
    return self.viewData_
end


function TTGameMoodLayer:getMoodCellLayer()
    return self:getViewData().moodCellLayer
end


function TTGameMoodLayer:getMoodCellVDList()
    return self.moodCellVDList_
end


function TTGameMoodLayer:getClickMoodCellCB()
    return self.onClickMoodCellCB_
end
function TTGameMoodLayer:setClickMoodCellCB(callback)
    self.onClickMoodCellCB_ = callback
end


-------------------------------------------------
-- public

function TTGameMoodLayer:close()
    self:runAction(cc.RemoveSelf:create())
end


function TTGameMoodLayer:showMoodEmoticonView()
    self:getViewData().view:setVisible(true)
end


function TTGameMoodLayer:closeMoodEmoticonView()
    self:getViewData().view:setVisible(false)
    if self.closeCallback_ then
        self.closeCallback_()
    end
end


-------------------------------------------------
-- private


-------------------------------------------------
-- private

function TTGameMoodLayer:onClickBlockLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:closeMoodEmoticonView()
end


function TTGameMoodLayer:onClickMoodCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getClickMoodCellCB() then
        self:getClickMoodCellCB()(sender:getTag())
    end
end


return TTGameMoodLayer
