--[[
卡池选择页面view
--]]
local CapsuleCardChooseView = class('CapsuleCardChooseView', function ()
    local node = CLayout:create()
    node.name = 'Game.views.drawCards.CapsuleCardChooseView'
    node:enableNodeEvents()
    return node
end)


local RES_DICT = {
    SUMMON_CHOICE_BG_1 = _res("ui/home/capsuleNew/cardChoose/summon_choice_bg_1.jpg"),
    NEWLAND_BG_BELOW = _res("ui/home/capsuleNew/skinCapsule/summon_activity_bg_bottom.png"),
    NEWLAND_BG_COUNT = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_bg_count.png"),
    NEWLAND_BG_PREVIEW = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_label_preview.png"),
    ORANGE_BTN_N = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    SELECT_TITLE_BG = _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_title_choice_skin.png'),
    LIST_CELL_FLAG = _res('ui/home/capsuleNew/skinCapsule/summon_choice_bg_get_text.png'),
    LIST_SELECT_IMAGE = _res("ui/home/capsuleNew/skinCapsule/summon_skin_bg_text_choosed.png"),

    ENTRANCE_SPINE  = _spn('ui/home/capsuleNew/cardChoose/spine/chouka'),
}

local uiMgr   = app.uiMgr
local cardMgr = app.cardMgr

-- local EntryNode = require("common.CardPreviewEntranceNode")
local CapsuleCardChooseSelectCardView = require("Game.views.drawCards.CapsuleCardChooseSelectCardView")
-- local NewPlayerRewardCell   = require("Game.views.drawCards.NewPlayerRewardCell")
local CapsuleCardChooseDrawCardView = require("Game.views.drawCards.CapsuleCardChooseDrawCardView")

local CreateView = nil
local CreateAniLayer = nil

local HEAD_POS_CONF = {
    cc.p(680, 620),
    cc.p(85, 614),
    cc.p(435, 785),
    cc.p(674, 250),
    cc.p(94, 240),
    cc.p(264, 155),
    cc.p(700, 600),
    cc.p(100, 614),
    cc.p(546.5, 122.5),
    cc.p(265, 827.5),
}


function CapsuleCardChooseView:ctor( ... )
    local args = unpack({...}) or {}
    local size = args.size
    self:setContentSize(size)
    
    self:initUI(size)
end

function CapsuleCardChooseView:initUI(size)
    xTry(function ( )
		self.viewData_ = CreateView(size)
        self:addChild(self.viewData_.view)
        self:initView()
    -- self:showUIAction()

	end, __G__TRACKBACK__)
end

function CapsuleCardChooseView:initView()
    
end

--==============================--
--desc: 更新UI显示状态
-- @params datas 卡池数据
--==============================--
function CapsuleCardChooseView:updateUIShowState(datas)
    local isSelect = checkint(datas.currentCardId) > 0

    self:hideUI()
    
    if isSelect then
        self:showDrawCardUI(datas, true)
    else
        self:showSelectCardView(datas)
    end
end

--==============================--
--desc: 隐藏UI
--==============================--
function CapsuleCardChooseView:hideUI()
    local viewData           = self:getViewData()
    local selectCardView     = viewData.selectCardView
    selectCardView:setVisible(false)

    local drawCardView       = viewData.drawCardView
    drawCardView:setVisible(false)
end

--==============================--
--desc: 更新选卡UI显示状态
--@params isSelect  bool  是否选择
--@params data      table 选卡数据
--@params index     int   选卡下标
--==============================--
function CapsuleCardChooseView:updateSelectCardUIShowState(isSelect, data)
    local selectCardView     = self:getViewData().selectCardView
    local selectButton       = selectCardView:getViewData().selectButton
    selectButton:setVisible(isSelect)

    local consumeData = CommonUtils.GetCapsuleConsume(data.consume or {})
    selectCardView:updateConsumeGood(consumeData.num, consumeData.goodsId)
end

--==============================--
--desc: 显示抽卡UI
--@params datas  table  卡池数据
--==============================--
function CapsuleCardChooseView:showDrawCardUI(datas, isUpdateData)
    if isUpdateData then
        self:updateDrawCardUI(datas)
    end
    local viewData      = self:getViewData()
    local drawCardView  = viewData.drawCardView
    drawCardView:setVisible(true)
    viewData.cardImgs[1]:setOpacity(255)
end

--==============================--
--desc: 更新抽卡UI
--@params datas  table  卡池数据
--==============================--
function CapsuleCardChooseView:updateDrawCardUI(datas)
    local currentCardId      = checkint(datas.currentCardId)
    local option             = datas.option or {}
    local data               = nil
    -- local dataIndex          = 0
    -- get select card index and data
    for i, v in ipairs(option) do
        if checkint(v.cardId) == currentCardId then
            data = v
            -- dataIndex = i
            break
        end
    end

    if data == nil then return end

    self:updateCardImgs(currentCardId)

    local drawCardView       = self:getViewData().drawCardView

    local maxGamblingTimes  = checkint(data.maxGamblingTimes)
    local hasGamblingTimes  = checkint(data.hasGamblingTimes)
    local leftGamblingTimes = maxGamblingTimes - hasGamblingTimes

    -- update left times
    drawCardView:updateCountNumLabel(string.fmt(__("剩余抽卡次数：_num_"), {_num_ = leftGamblingTimes}))
    
    -- update draw one draw much
    local isOwnLeftTimes = leftGamblingTimes > 0
    local oneConsumeData = CommonUtils.GetCapsuleConsume(datas.oneConsume or {})
    drawCardView:updateDrawOne(isOwnLeftTimes, oneConsumeData.num, oneConsumeData.goodsId)

    local tenConsumeData = CommonUtils.GetCapsuleConsume(datas.tenConsume or {})
    drawCardView:updateDrawMuch(isOwnLeftTimes, tenConsumeData.num, tenConsumeData.goodsId)
    
end

--==============================--
--desc: 更新cell
--@params cell  userdata 
--@params data  table    cell data
--==============================--
function CapsuleCardChooseView:updateCell(cell, data)
    local cardId = data.cardId
    local viewData = cell.viewData
    local imgHero  = viewData.imgHero
    imgHero:setTexture(CardUtils.GetCardDrawPathByCardId(cardId))

    local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardId)
    if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
        print('\n**************\n', '立绘坐标信息未找到', cardId, '\n**************\n')
        locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
    else
        locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
    end
    imgHero:setScale(locationInfo.scale/100)
    imgHero:setRotation((locationInfo.rotate))
    imgHero:setPosition(cc.p(locationInfo.x,(-1)*(locationInfo.y-540)))

    viewData.heroBg:setTexture(CardUtils.GetCardTeamBgPathByCardId(cardId))
    --更新技能相关的图标
    viewData.skillFrame:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
    viewData.skillIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
    viewData.qualityIcon:setTexture(CardUtils.GetCardQualityIconPathByCardId(cardId))
    viewData.entryHeadNode:RefreshUI({confId = cardId})

    local node = cell:getChildByName("LIST_CELL_FLAG")
    
    if node then node:removeFromParent() end
    
end

--==============================--
--desc: 更新cell 选择状态
--@params cell     userdata 
--@params isSelect bool     是否选择
--==============================--
function CapsuleCardChooseView:updateCellSelectState(cell, isSelect)
    local viewData = cell.viewData
    viewData.highlightBg:setVisible(isSelect)
    viewData.spineNode:setVisible(isSelect)
end

--==============================--
--desc: 显示选择卡牌视图
--@params datas   table 卡池数据
--==============================--
function CapsuleCardChooseView:showSelectCardView(datas)
    local viewData           = self:getViewData()
    local selectCardView     = viewData.selectCardView
    self:updateSelectCardView(datas)
    selectCardView:setVisible(true)

    viewData.cardImgs[1]:setOpacity(0)
end

--==============================--
--desc: 更新选择卡牌视图
--@params datas   table 卡池数据
--==============================--
function CapsuleCardChooseView:updateSelectCardView(datas)
    local option             = datas.option or {}
    local selectCardView     = self:getViewData().selectCardView
    local selectCardViewData = selectCardView:getViewData()
    
    self:updateSelectCardUIShowState(false, {})

    local gridView           = selectCardViewData.gridView
    gridView:setCountOfCell(#option)
    gridView:reloadData()
end

function CapsuleCardChooseView:updateCardImgs(cardId)
    local cardImgs = self:getViewData().cardImgs
    local cardImgPath = _res(string.format("ui/home/capsuleNew/cardChoose/choicRole/summon_choice_role_%s.png", cardId))
    if not utils.isExistent(cardImgPath) then
        cardImgPath = _res("ui/home/capsuleNew/cardChoose/choicRole/summon_choice_role_200082.png")
    end
    for i, cardImg in ipairs(cardImgs) do
        cardImg:setTexture(cardImgPath)
    end
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    local selectCardView = CapsuleCardChooseSelectCardView.new({size = size})
    selectCardView:setPosition(cc.p(size.width / 2, size.height / 2))
    selectCardView:setVisible(false)
    view:addChild(selectCardView, 2)

    local drawCardView = CapsuleCardChooseDrawCardView.new({size = size})
    drawCardView:setPosition(cc.p(size.width / 2, size.height / 2))
    drawCardView:setVisible(false)
    view:addChild(drawCardView, 2)

    local cardImgs = {}
    for i = 1, 3 do
        local cardImg = display.newNSprite('', size.width / 2 - 120, size.height / 2 + 28, {ap = display.CENTER})
        cardImg:setOpacity(0)
        view:addChild(cardImg, 1)
        table.insert(cardImgs, cardImg)
    end

    return {
        view           = view,
        selectCardView = selectCardView,
        drawCardView   = drawCardView,
        cardImgs       = cardImgs,
    }
end

CreateAniLayer = function (size)
    local aniLayer = display.newLayer(0, 0, {size = size})

    local particleSpine = sp.SkeletonAnimation:create(
        RES_DICT.ENTRANCE_SPINE.json,
        RES_DICT.ENTRANCE_SPINE.atlas,
        1)
    particleSpine:setPosition(cc.p(size.width / 2 - 120, size.height / 2 + 28))
    aniLayer:addChild(particleSpine, 1)
    -- particleSpine:setAnimation(0, 'idle', false)
    particleSpine:update(0)
    particleSpine:setToSetupPose()
    -- particleSpine:setVisible(false)
    
    local aniHeadLayerSize = cc.size(870, 870)
    local aniHeadLayer = display.newLayer(size.width / 2 - 120, size.height / 2 + 28, {ap = display.CENTER, size = aniHeadLayerSize})
    aniLayer:addChild(aniHeadLayer)
    
    local cardHeadImgs = {}
    for i, pos in ipairs(HEAD_POS_CONF) do
        local cardHeadImg = display.newNSprite('', pos.x, pos.y, {ap = display.CENTER})
        aniHeadLayer:addChild(cardHeadImg)
        table.insert(cardHeadImgs, cardHeadImg)
    end

    return {
        aniLayer       = aniLayer,
        particleSpine  = particleSpine,
        aniHeadLayer   = aniHeadLayer,
        cardHeadImgs   = cardHeadImgs,
        
    }
end

function CapsuleCardChooseView:showUIAction(cardId, cb)
    local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()

    local viewData     = self:getViewData()
    local view = viewData.view
    if viewData.aniLayer == nil then
        local size = view:getContentSize()
        local aniLayerViewData = CreateAniLayer(size)
        table.merge(viewData, aniLayerViewData)
        view:addChild(aniLayerViewData.aniLayer)
        -- viewData.aniLayer:setVisible(false)
    end

    local cardHeadImgs         = viewData.cardHeadImgs
    local aniHeadLayer = viewData.aniHeadLayer
    local particleSpine  = viewData.particleSpine
    local aniHeadLayerSize = aniHeadLayer:getContentSize()
    local aniHeadLayerCenterPos = cc.p(aniHeadLayerSize.width / 2, aniHeadLayerSize.height / 2)

    local headActionList = {}
    local headStartFrame = {
        15 / 30, 23 / 30, 30 / 30, 34 / 30, 38 / 30,
        43 / 30, 46 / 30, 50 / 30, 52 / 30, 56 / 30,
    }
    local firstImgMoveFrane  = 5 / 30
    local secondImgMoveFrane = 8 / 30
    local thirdImgMoveFrane  = 3 / 30
    local headImgPath = CardUtils.GetCardHeadPathByCardId(cardId)
    for i, img in ipairs(cardHeadImgs) do
        img:setTexture(headImgPath)
        img:setScale(0.75)
        img:setOpacity(255)
        local curImgPos = HEAD_POS_CONF[i]
        local firstMoveOffsetPos  = cc.p((aniHeadLayerCenterPos.x - curImgPos.x) / 2, (aniHeadLayerCenterPos.y - curImgPos.y ) / 2)
        local secondMoveOffsetPos = cc.p(firstMoveOffsetPos.x * 0.9, firstMoveOffsetPos.y * 0.9)
        img:setPosition(curImgPos.x, curImgPos.y)
        img:setVisible(false)
        
        table.insert(headActionList, cc.TargetedAction:create(img, cc.Sequence:create({
            cc.DelayTime:create(headStartFrame[i]),
            cc.Show:create(),
            cc.EaseExponentialIn:create(cc.MoveBy:create(firstImgMoveFrane, firstMoveOffsetPos)),
            cc.MoveBy:create(secondImgMoveFrane, secondMoveOffsetPos),
            cc.Spawn:create({
                cc.MoveTo:create(thirdImgMoveFrane, aniHeadLayerCenterPos),
                cc.FadeOut:create(thirdImgMoveFrane)
            }),
        })))
    end

    local cardImgs       = viewData.cardImgs
    local cardStartFrame = {
        64 / 30, 67 / 30, 70 / 30,
    }

    for i, cardImg in ipairs(cardImgs) do
        cardImg:setScale(0.5)
        cardImg:setOpacity(0)

        local actionList = nil
        if i == 1 then
            actionList = {
                cc.DelayTime:create(cardStartFrame[i]),
                cc.Spawn:create({
                    cc.ScaleTo:create(4 / 30, 1),
                    cc.FadeTo:create(4 / 30, 255 / 2),
                }),
                cc.FadeTo:create(2 / 30, 255),
            }
        elseif i == 2 then
            actionList = {
                cc.DelayTime:create(cardStartFrame[i]),
                cc.Spawn:create({
                    cc.ScaleTo:create(4 / 30, 1.2),
                    cc.FadeTo:create(4 / 30, 255 * 0.8),
                }),
                cc.FadeTo:create(1 / 30, 0),
            }
        elseif i == 3 then
            actionList = {
                cc.DelayTime:create(cardStartFrame[i]),
                cc.Spawn:create({
                    cc.ScaleTo:create(4 / 30, 1.3),
                    cc.FadeTo:create(4 / 30, 255 / 2),
                }),
                cc.FadeTo:create(1 / 30, 0),
            }
        end
        if actionList then
            table.insert(headActionList, cc.TargetedAction:create(cardImg, cc.Sequence:create(actionList)))
        end
    end
    
    local drawCardView = viewData.drawCardView
    local drawCardViewData = drawCardView:getViewData()
    local quitBtn    = drawCardViewData.quitBtn
    local bottomView = drawCardViewData.bottomView
    quitBtn:setVisible(false)
    bottomView:setPositionY(bottomView:getPositionY() - 186)
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(viewData.aniLayer, cc.FadeIn:create(0.3)),
        cc.CallFunc:create(function ()
            particleSpine:setVisible(true)
            particleSpine:setAnimation(0, 'idle', false)
        end),
        cc.TargetedAction:create(aniHeadLayer, cc.Spawn:create(headActionList)),
        cc.DelayTime:create(0.5),
        cc.TargetedAction:create(particleSpine, cc.Hide:create()),
        cc.TargetedAction:create(drawCardView, cc.Sequence:create({
            cc.Show:create(),
            cc.TargetedAction:create(bottomView, cc.MoveBy:create(0.3, cc.p(0, 186))),
            cc.TargetedAction:create(quitBtn, cc.Show:create())
        })),
        cc.DelayTime:create(0.2),
        -- cc.TargetedAction:create(viewData.aniLayer, cc.FadeOut:create(0.3)),
        cc.CallFunc:create(function ()
            -- particleSpine:setVisible(false)
            -- logInfo.add(5, 'aniHeadLayer ')
            if cb then
                cb()
            end
            scene:RemoveViewForNoTouch()
        end)
        -- cc.DelayTime:create(10)
    }))

end

function CapsuleCardChooseView:getViewData()
    return self.viewData_
end

return CapsuleCardChooseView
