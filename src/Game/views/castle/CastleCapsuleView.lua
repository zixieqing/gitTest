--[[
古堡迷踪抽奖界面
--]]
local CastleCapsuleView = class('CastleCapsuleView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.castle.CastleCapsuleView'
    node:enableNodeEvents()
    return node
end)
local uiMgr = app.uiMgr
local GoodPurchaseNode = require('common.GoodPurchaseNode')

local RES_DICT = {
    COMMON_BTN_BACK                 = app.activityMgr:CastleResEx('ui/common/common_btn_back.png'),
    COMMON_BTN_ORANGE               = app.activityMgr:CastleResEx('ui/common/common_btn_orange.png'),
    COMMON_BTN_TIPS                 = app.activityMgr:CastleResEx('ui/common/common_btn_tips.png'),
    COMMON_TITLE                    = app.activityMgr:CastleResEx('ui/common/common_title_new.png'),

    GOODS_ICON_880161               = app.activityMgr:CastleResEx('arts/goods/goods_icon_880161.png'),
    GOODS_ICON_880162               = app.activityMgr:CastleResEx('arts/goods/goods_icon_880162.png'),
    GOODS_ICON_880164               = app.activityMgr:CastleResEx('arts/goods/goods_icon_880164.png'),
    CASTLE_DRAW_BG_BELOW            = app.activityMgr:CastleResEx('ui/castle/capsule/castle_draw_bg_below.png'),
    CASTLE_DRAW_BG_CORNER           = app.activityMgr:CastleResEx('ui/castle/capsule/castle_draw_bg_corner.png'),
    CASTLE_DRAW_BG_DESK             = app.activityMgr:CastleResEx('ui/castle/capsule/castle_draw_bg_desk.png'),
    CASTLE_DRAW_BG                  = app.activityMgr:CastleResEx('ui/castle/capsule/castle_draw_bg.jpg'),
    CASTLE_DRAW_BTN_REWARDS_PREVIEW = app.activityMgr:CastleResEx('ui/castle/capsule/castle_draw_btn_rewards_preview.png'),
    SUMMON_NEWHAND_BTN_DRAW         = app.activityMgr:CastleResEx('ui/home/capsuleNew/common/summon_newhand_btn_draw.png'),
    CASTLE_MAP_BG                   = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_bg.png'),
    JINGHUA                         = app.activityMgr:CastleSpnEx('ui/castle/effect/jinghua'),
    
}

local SPINE_CONF = {
    BOOM       = {aniName = "baozha", zOrder = 0, pos = cc.p(-3, 372)},
    BACKGROUND = {aniName = "dizuohou", zOrder = 0, pos = cc.p(554, 323)},
    PROSPECT   = {aniName = "dizuoqian", zOrder = 2, pos = cc.p(538, 326)},
}

local CreateView       = nil
local CreateSpine      = nil

function CastleCapsuleView:ctor( ... )
    self.args = unpack({...}) or {}
    self:InitUI()
    if GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN then
        self.PlayCapsuleAnimateByTimes = self.PlayCapsuleOneAnimateByTimes
    end
end
--[[
init ui
--]]
function CastleCapsuleView:InitUI()
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self:UpdateFragmentIcon()
    end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新抽卡消耗
--@params data        table 抽卡消耗数据
--@return 
--==============================--
function CastleCapsuleView:UpdateCapsuleConsume(data)
    local viewData  = self:GetViewData()
    local consumeDatas = data.consume or {}
    local imgView = nil
    local numLabel = nil
    for i, consumeData in ipairs(consumeDatas) do
        local goodsId = consumeData.goodsId
        local num = checkint(consumeData.num)
        if i == 1 then
            imgView = viewData.flowerImg
            numLabel = viewData.flowerNum
        else
            imgView = viewData.needleImg
            numLabel = viewData.needleNum
        end
        imgView:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
        imgView:setTag(goodsId)
        display.reloadRichLabel(numLabel, {c = self:GetRichTable(goodsId, num)})
    end

end

--==============================--
--desc: 获得富文本
--@params goodsId  int 道具id
--@params num      int 消耗数量
--@return 
--==============================--
function CastleCapsuleView:GetRichTable(goodsId, num)
    local richTable = {}
    
    local ownNum = app.gameMgr:GetAmountByGoodId(goodsId)
    table.insert(richTable, {text = ownNum, fontSize = 24, color = ownNum >= num and '#ffffff' or '#ef3c4c'})
    table.insert(richTable, {fontSize = 24, text = '/' .. num, color = '#ffffff'})

    return richTable
end

--==============================--
--desc: 根据抽卡次数 播放抽卡动画
--@params times  int 抽卡次数
--@return 
--==============================--
function CastleCapsuleView:PlayCapsuleAnimateByTimes(times)
    local viewData  = self:GetViewData()
    local spines = viewData.spines

    local isNotExist = next(spines) == nil

    for k, spineConf in pairs(SPINE_CONF) do
        local aniName = spineConf.aniName
        local pos = spineConf.pos
        local zOrder = spineConf.zOrder
        if isNotExist then
            local spine = CreateSpine()
            local parent
            if aniName == "baozha" then
                parent = viewData.connerLayer
            elseif aniName == "dizuoqian" then
                parent = viewData.deskBg
                spine:registerSpineEventHandler(function ()
                    app:DispatchObservers("CASTLE_CAPSULE_SHOW_REWARD", {times = times})
                end, sp.EventType.ANIMATION_END)
            else
                parent = viewData.deskBg
            end
            spine:setPosition(pos)
            parent:addChild(spine, zOrder)

            spines[k] = spine
        end
        
        local realAniName = checkint(times) > 1 and string.format( "%s%s", aniName, "2") or aniName
        spines[k]:setAnimation(0, realAniName, false)
    end
    viewData.qAvatar:setAnimation(0, sp.AnimationName.attacked, false)
    viewData.qAvatar:addAnimation(0, sp.AnimationName.idle, true)
end
function CastleCapsuleView:UpdateFragmentIcon()
    ---@type SpringActivityConfigParser
    local SpringActivityConfigParser = require('Game.Datas.Parser.SpringActivityConfigParser').new()
    local goodsPointMainShowConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.GOODS_POINT_MAIN_SHOW , "springActivity")
    local goodsId  = DIAMOND_ID
    local totalValue = 100
    for key , goodsData  in pairs(goodsPointMainShowConfig) do
        totalValue = checkint(goodsData.limit)
        goodsId = goodsData.goodsId
        break
    end
    local goodsPath = CommonUtils.GetGoodsIconPathById(goodsId)
    self.viewData.fragmentIcon:setTexture(goodsPath)
end
function CastleCapsuleView:PlayCapsuleOneAnimateByTimes(times)
    local viewData = self.viewData
    local aniName = "dizuoqian"
    local realAniName = checkint(times) > 1 and string.format( "%s%s", aniName, "2") or aniName
    viewData.qAvatar:setAnimation(0, realAniName, false)
    viewData.qAvatar:registerSpineEventHandler(function (event)
        if event.animation == "dizuoqian" or  "dizuoqian2"  == event.animation then
            app:DispatchObservers("CASTLE_CAPSULE_SHOW_REWARD", {times = times})
        end
    end, sp.EventType.ANIMATION_END)
    viewData.qAvatar:addAnimation(0, sp.AnimationName.idle, true)
end
function CastleCapsuleView:EnterAction()
    local viewData  = self:GetViewData()
    local titleBtn      = viewData.titleBtn
    local belowLayer    = viewData.belowLayer
    local belowAction = cc.Sequence:create(
        cc.CallFunc:create(function ()
            belowLayer:setVisible(true)
            belowLayer:setPosition(cc.p(belowLayer:getPositionX(), -400))
            -- titleBtn:setPosition(cc.p(belowLayer:getPositionX(), belowLayer:getPositionY() - 400))
        end),
        cc.Spawn:create(
        cc.FadeIn:create(0.2),
        cc.JumpBy:create(0.2, cc.p(0, 400 ) ,100, 1)
        )
    )
    local titleBtnPosX = titleBtn:getPositionX()
    local titleBtnPosY = titleBtn:getPositionY()
    local titleBtnAction = cc.Sequence:create(
        cc.CallFunc:create(function ()
            titleBtn:setVisible(true)
            titleBtn:setOpacity(0)
            titleBtn:setPosition(cc.p(titleBtnPosX, titleBtnPosY + 400))
        end),
        cc.Spawn:create(
            cc.EaseBackOut:create(
                cc.MoveBy:create(0.5 , cc.p(0, -400))
            ),
            cc.FadeIn:create(0.5)
        )
    )
    
    self:runAction(cc.Spawn:create({
        cc.TargetedAction:create(titleBtn, titleBtnAction),
        cc.TargetedAction:create(belowLayer, belowAction),
    }))
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    local path = RES_DICT.CASTLE_MAP_BG
    if GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN then
        path = RES_DICT.CASTLE_DRAW_BG
    end
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0, 0, 0, 0), enable = true}))
    view:addChild(display.newNSprite(path, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local posConf = app.activityMgr:GetCastleDrawPosConf()

    local actionBtns = {}
    -- back btn
    local backBtn = display.newButton(display.SAFE_L + 57, display.height - 55,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_BACK,
        enable = true,
    })
    view:addChild(backBtn)

    local titleBtn = display.newButton(display.SAFE_L + 130, size.height, {n = RES_DICT.COMMON_TITLE, enable = true, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, {ttf = true, font = TTF_GAME_FONT, reqW = 190, text = app.activityMgr:GetCastleText(__('记忆之宿')), fontSize = 30, color = '#473227',offset = cc.p(-15,-8)})
    view:addChild(titleBtn,22)
    titleBtn:setVisible(false)

    local tipsImg = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 250, 30,
            {
                ap = display.CENTER,
            })
    titleBtn:addChild(tipsImg)

    local deskBg = display.newNSprite(RES_DICT.CASTLE_DRAW_BG_DESK, size.width / 2, size.height / 2,
            {
                ap = display.CENTER,
            })
    view:addChild(deskBg)

    local qAvatar
    if GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN then
        qAvatar = CreateSpine()
        deskBg:addChild(qAvatar, 1)
    else
        qAvatar  = AssetsUtils.GetCardSpineNode({confId = 300179})
        -- qAvatar:setAnimation(0, 'idle', true)
        qAvatar:setName("spine")
        qAvatar:setVisible(true)
        qAvatar:setScaleX(-1)
        qAvatar:setAnimation(0, sp.AnimationName.idle, true)
        deskBg:addChild(qAvatar, 1)
    end
    qAvatar:setPosition(app.activityMgr:GetCastleDrawSpinePos())

    local belowLayer = display.newLayer()
    view:addChild(belowLayer)
    belowLayer:setVisible(false)

    local belowBg = display.newNSprite(RES_DICT.CASTLE_DRAW_BG_BELOW, posConf.belowBgPos.x, posConf.belowBgPos.y,
    {
        ap = posConf.belowBgAP,
    })
    belowLayer:addChild(belowBg, 0)

    local rewardPreview = display.newButton(posConf.rewardPreviewPos.x, posConf.rewardPreviewPos.y,
    {
        ap = display.CENTER,
        n = RES_DICT.CASTLE_DRAW_BTN_REWARDS_PREVIEW,
        scale9 = true, size = cc.size(240, 70),
        enable = true,
    })
    display.commonLabelParams(rewardPreview, fontWithColor(19, {outlineSize = 2, outline = '#420505', text = app.activityMgr:GetCastleText(__('奖励一览'))}))
    belowLayer:addChild(rewardPreview)

    ----------------connerLayer start-----------------
    local connerLayer = display.newLayer(posConf.connerLayerPos.x, posConf.connerLayerPos.y,
    {
        ap = posConf.connerLayerAP,
        size = cc.size(725, 296),
    })
    belowLayer:addChild(connerLayer)

    if GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN ~= "two" then
        local connerBg = display.newNSprite(RES_DICT.CASTLE_DRAW_BG_CORNER, 0, 0,
        {
            ap = display.LEFT_BOTTOM,
        })
        connerLayer:addChild(connerBg)
    end

    local flowerImg = display.newImageView('', posConf.flowerImgPos.x, posConf.flowerImgPos.y,
    {
        ap = display.CENTER,
        enable = true
    })
    flowerImg:setScale(posConf.flowerImgScale)
    connerLayer:addChild(flowerImg)

    local needleImg = display.newImageView('', posConf.needleImgPos.x, posConf.needleImgPos.y,
    {
        ap = display.CENTER,
        enable = true
    })
    needleImg:setScale(posConf.needleImgScale)
    connerLayer:addChild(needleImg)

    local flowerNum = display.newRichLabel(posConf.flowerNumPos.x, posConf.flowerNumPos.y, {ap = display.CENTER})
    connerLayer:addChild(flowerNum)

    local needleNum = display.newRichLabel(posConf.needleNumPos.x, posConf.needleNumPos.y, {ap = display.CENTER})
    connerLayer:addChild(needleNum)

    local purifyOneTimesBtn = display.newButton(posConf.purifyOneTimesBtnPos.x, posConf.purifyOneTimesBtnPos.y,
    {
        ap = display.CENTER,
        n = RES_DICT.SUMMON_NEWHAND_BTN_DRAW,
        enable = true,
    })
    display.commonLabelParams(purifyOneTimesBtn, fontWithColor(14, {outlineSize = 2, outline = '#420505', text = string.fmt(app.activityMgr:GetCastleText(__('净化_num_次')), {_num_ = 1})}))
    purifyOneTimesBtn:setScale(0.8)
    connerLayer:addChild(purifyOneTimesBtn)

    local purifyTenTimesBtn = display.newButton(posConf.purifyTenTimesBtnPos.x, posConf.purifyTenTimesBtnPos.y,
    {
        ap = display.CENTER,
        n = RES_DICT.SUMMON_NEWHAND_BTN_DRAW,
        enable = true,
    })
    display.commonLabelParams(purifyTenTimesBtn, fontWithColor(14, {outlineSize = 2, outline = '#420505', text = string.fmt(app.activityMgr:GetCastleText(__('净化_num_次')), {_num_ = 10})}))
    purifyTenTimesBtn:setScale(0.8)
    connerLayer:addChild(purifyTenTimesBtn)

    local purifyTipLabel = display.newLabel(posConf.purifyTipLabelPos.x, posConf.purifyTipLabelPos.y,
    {
        text = app.activityMgr:GetCastleText(__('每净化1次可获得1个记忆碎片')),
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    connerLayer:addChild(purifyTipLabel)

    local fragmentIcon = display.newNSprite(RES_DICT.GOODS_ICON_880164, posConf.fragmentIconPos.x, posConf.fragmentIconPos.y,
    {
        ap = display.CENTER,
    })
    fragmentIcon:setScale(0.2, 0.2)
    connerLayer:addChild(fragmentIcon)

    return {
        view = view,
        backBtn = backBtn,
        titleBtn                = titleBtn,
        belowLayer              = belowLayer,
        belowBg                 = belowBg,
        rewardPreview           = rewardPreview,
        deskBg                  = deskBg,
        connerLayer             = connerLayer,
        -- connerBg                = connerBg,
        purifyTipLabel          = purifyTipLabel,
        purifyOneTimesBtn       = purifyOneTimesBtn,
        purifyTenTimesBtn       = purifyTenTimesBtn,
        flowerImg               = flowerImg,
        needleImg               = needleImg,
        flowerNum               = flowerNum,
        needleNum               = needleNum,
        fragmentIcon            = fragmentIcon,
        qAvatar                 = qAvatar,

        spines                  = {},
    }
end

CreateSpine = function ()
    local spine = sp.SkeletonAnimation:create(
        RES_DICT.JINGHUA.json,
        RES_DICT.JINGHUA.atlas,
    1)
    spine:setAnimation(0, 'idle' , true)

    return spine
end

function CastleCapsuleView:GetViewData()
    return self.viewData
end

return CastleCapsuleView