--[[
 * descpt : pt本 home 界面
]]
local VIEW_SIZE = display.size

local GameScene = require( "Frame.GameScene" )
---@class PTDungeonHomeView :GameScene
local PTDungeonHomeView = class("PTDungeonHomeView", GameScene)


local CreateView = nil
local CreateCell_ = nil

local RES_DICT = {
    TITLE_BAR                       = _res('ui/common/common_title_new.png'),
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_DISABLE              = _res('ui/common/common_btn_orange_disable.png'),
    ACTIVITY_MIFAN_BY_ICO           = _res('ui/common/activity_mifan_by_ico'),
    BTN_TIPS                        = _res('ui/common/common_btn_tips.png'),
    DISCOVERY_BG_FIGHT              = _res('ui/common/discovery_bg_fight.png'),
    POKEDEX_CARD_BG_NAME            = _res('ui/home/handbook/pokedex_card_bg_name.png'),
    ACTIVITY_PTFB_BG                = _res('ui/home/activity/ptDungeon/activity_ptfb_bg.jpg'),
    ACTIVITY_PTFB_FRAME_RUMBER_BG   = _res('ui/home/activity/ptDungeon/activity_ptfb_frame_rumber_bg.png'),
    ACTIVITY_PTFB_FRAME_TITLE_BG    = _res('ui/home/activity/ptDungeon/activity_ptfb_frame_title_bg.png'),
    ACTIVITY_PTFB_TIME_BG           = _res('ui/home/activity/ptDungeon/activity_ptfb_time_bg.png'),
    ACTIVITY_PTFB_TITLE_BG          = _res('ui/home/activity/ptDungeon/activity_ptfb_title_bg.png'),
    ACTIVITY_PTFB_TITLE_WORDS_BG    = _res('ui/home/activity/ptDungeon/activity_ptfb_title_words_bg.png'),
    PTFB_FRAME_BG_BLACK             = _res('ui/home/activity/ptDungeon/ptfb_frame_bg_black.png'),
    STARPLAN_MAIN_FRAME_BTN_NAME    = _res('ui/home/activity/ptDungeon/activity_ptfb_main_frame_btn_name.png'),
    STARPLAN_MAIN_ICON_LIGHT        = _res('ui/common/starplan_main_icon_light.png'),
    MAIN_BTN_RANK                   = _res('ui/home/nmain/main_btn_rank.png'),
    TASK_BTN_PLAYBACK               = _res('ui/home/activity/ptDungeon/starplan_vs_btn_playback.png'),
}

function PTDungeonHomeView:ctor( ... ) 
    
    self.args = unpack({...})
    self:initialUI()
end

function PTDungeonHomeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function PTDungeonHomeView:refreshUI(datas, questId)
    local section = datas.section
    local viewData = self:getViewData()

    self:updateMoneyBarGoodList(viewData, datas)

    -- update list
    self:updateList(viewData, section)

    -- update card draw
    self:updateCardDraw(viewData, datas)

    self:updateGoodConsume(viewData, datas, questId)

    self:updatePtPoint(viewData, datas)
end

function PTDungeonHomeView:updateTimeTip(viewData, seconds)
    display.commonLabelParams(viewData.LeftTimeLabel, { reqW = 340 ,  text = __('活动剩余时间：') ..  CommonUtils.getTimeFormatByType(seconds)})
end

function PTDungeonHomeView:updateList(viewData, listDatas)
    local tableView = viewData.tableView
    tableView:setCountOfCell(#listDatas)
    tableView:reloadData()
    local cur = 1
    for i,v in ipairs(listDatas) do
        if checkint(v.hasDrawn) == 0 then
            cur = i
            break
        end
    end
    local size = tableView:getSizeOfCell()
    local OffsetHeight = self.viewData_.listSize.height - size.height * (#listDatas - cur + 1)
    tableView:setContentOffset(cc.p(0, math.min(OffsetHeight, 0)))
end

function PTDungeonHomeView:updatePtPoint(viewData, datas)
    display.commonLabelParams(viewData.ptNumLabel, {text = datas.point or 0})
end

function PTDungeonHomeView:updateMoneyBarGoodList(viewData, datas)
    local args = {}
    local currency = checkint(datas.hpGoodsId)
    if currency > 0 then
        args.moneyIdMap = {}
        args.moneyIdMap[tostring(currency)] = currency
    end
    viewData.moneyBar:RefreshUI(args)
end

function PTDungeonHomeView:updateMoneyBarGoodNum()
    self:getViewData().moneyBar:updateMoneyBar()
end

function PTDungeonHomeView:updateCardDraw(viewData, datas)
    local confId   = checkint(datas.bossImage)
    local cardConf = CardUtils.GetCardConfig(confId)
    if cardConf == nil then return end
    local cardDraw    = viewData.cardDraw
    cardDraw:RefreshAvatar({confId = confId})
    cardDraw:setVisible(true)

    local nameLabelBg = viewData.nameLabelBg
    local baseNameLabelBgSize = nameLabelBg:getContentSize()
    display.commonLabelParams(nameLabelBg, {text = tostring(cardConf.name), paddingW = 40})
    local nameLabelBgSize = nameLabelBg:getContentSize()
    if nameLabelBgSize.width < baseNameLabelBgSize.width then
        nameLabelBgSize = baseNameLabelBgSize
        nameLabelBg:setContentSize(baseNameLabelBgSize)
    end
end

function PTDungeonHomeView:updateGoodConsume(viewData, datas, questId)
    local consumeLabel   = viewData.consumeLabel
    local consumeGoodImg = viewData.consumeGoodImg
    consumeGoodImg:setTexture(CommonUtils.GetGoodsIconPathById(datas.hpGoodsId))

    local questConf = CommonUtils.GetConfig('pt', 'quest', questId) or {}
    display.commonLabelParams(consumeLabel, {text = string.format(__('消耗%d') , tonumber(questConf.consumeNum))})

    local consumeGoodImgSize = consumeGoodImg:getContentSize()
    local consumeLabelSize   = display.getLabelContentSize(consumeLabel)

    consumeLabel:setPositionX(180 - consumeGoodImgSize.width / 2 * consumeGoodImg:getScale())
    consumeGoodImg:setPositionX(180 + consumeLabelSize.width / 2)
    if isJapanSdk() then
        display.setNodesToNodeOnCenter(viewData.fightBg, {consumeGoodImg, consumeLabel}, {y = 16})
    end

end

function PTDungeonHomeView:updateCell(viewData, data, curPoint)
    local chapterName     = viewData.chapterName
    local plotId          = data.plot
    local storyConf       = CommonUtils.GetConfig('pt', 'story', plotId) or {}
    local storyData       = storyConf[1] or {}

    if storyData.title then
        display.commonLabelParams(chapterName, {text = tostring(storyData.title)})
    else
        display.commonLabelParams(chapterName, {text = __('奖励')})
    end

    display.commonLabelParams(viewData.ptPointTipLabel, 
        {text = string.fmt(__('_num_/_num1_ pt点数可以领取'), {_num_ = tostring(curPoint) , _num1_ = tostring(data.targetNum)})})

    self:updateStoryImgShowState(viewData, data, curPoint)

    self:updateDrawBtnShowState(viewData, data, curPoint)
    
    self:updateRewardLayer(viewData, data)
end

function PTDungeonHomeView:updateStoryImgShowState(viewData, data, curPoint)
    local storyTouchView = viewData.storyTouchView
    local plotId         = checkint(data.plot)
    if plotId <= 0 then
        storyTouchView:setVisible(false)
        return 
    end
    storyTouchView:setVisible(true)

    local storyImg   = viewData.storyImg
    local interviewBtnSpine   = viewData.interviewBtnSpine
    local targetNum  = checknumber(data.targetNum)
    local isSatisfyCondition = curPoint >= targetNum
    if isSatisfyCondition then
        storyImg:setVisible(false)
        interviewBtnSpine:setVisible(true)
        -- storyImg:clearFilter()
    else
        storyImg:setVisible(true)
        interviewBtnSpine:setVisible(false)
        -- storyImg:setFilter(filter.newFilter('GRAY'))
    end
end

function PTDungeonHomeView:updateDrawBtnShowState(viewData, data, curPoint)
    local drawBtn   = viewData.drawBtn
    local targetNum  = checknumber(data.targetNum)
    local hasDrawn   = checkint(data.hasDrawn) > 0
    local imgPth     = nil
    local name       = nil
    if hasDrawn then
        imgPth = RES_DICT.ACTIVITY_MIFAN_BY_ICO
        name   = __("已领取")
    else
        name   = __("领取")
        if curPoint >= targetNum then
            imgPth = RES_DICT.COMMON_BTN_ORANGE
        else
            imgPth = RES_DICT.COMMON_BTN_DISABLE
        end
    end
    drawBtn:setSelectedImage(imgPth)
    drawBtn:setNormalImage(imgPth)
    drawBtn:setEnabled(not hasDrawn)
    display.commonLabelParams(drawBtn, {text = name})
end

function PTDungeonHomeView:updateRewardLayer(viewData, data)
    local rewardLayer = viewData.rewardLayer
    local rewardList = viewData.rewardList
    local rewards = data.rewards or {}

    if rewardLayer:getChildrenCount() > 0 then
        rewardLayer:removeAllChildren()
    end

    if next(rewards) ~= nil then
        local callBack = function(sender)
            app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
        end
        local h = rewardLayer:getContentSize().height / 2 - 2
        local goodNodeSize = nil
        local scale = 0.72
        local goodsNodes = {}
        for i, v in ipairs(rewards) do
            local goodNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
            goodNode:setScale(scale)
            goodNode:setPosition(72 + (i - 1) * 86, h)
            rewardLayer:addChild(goodNode)
            table.insert(goodsNodes, goodNode)
        end

        -- display.setNodesToNodeOnCenter(rewardLayer, goodsNodes, {spaceW = 10})
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true}))

    view:addChild(display.newNSprite(RES_DICT.ACTIVITY_PTFB_BG, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COMMON_BTN_BACK})
    view:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.TITLE_BAR, ap = display.LEFT_TOP, enable = true, scale9 = true, capInsets = cc.rect(100, 70, 80, 1)})
    if isJapanSdk() then
        titleBtn:setContentSize(cc.size(340, 78))
        display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('PT本'), offset = cc.p(-16, -10), ttf = true, font = TTF_GAME_FONT}))
    else
        display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('PT本'), reqW = 220 ,  offset = cc.p(0, -10), ttf = true, font = TTF_GAME_FONT}))
    end
    view:addChild(titleBtn)
    local titleSize = titleBtn:getContentSize()

    local tipsIcon  = display.newImageView(_res(RES_DICT.BTN_TIPS), titleSize.width - 50, titleSize.height/2 - 10)
    titleBtn:addChild(tipsIcon)

    local cardDraw = require( "common.CardSkinDrawNode" ).new({confId = 300059, coordinateType = COORDINATE_TYPE_CAPSULE})
    -- cardDraw:setPosition(display.SAFE_L + 520, -42)
    cardDraw:setPositionX(display.cx - 300)
    -- display.commonUIParams(cardDraw, {po = cc.p(display.width * 0.6, -42), ap = cc.p(0.3,0)})
    view:addChild(cardDraw)
    cardDraw:setVisible(false)

    local moneyUILayer = display.newLayer()
    view:addChild(moneyUILayer, 2)
    -- CommonMoneyBar
    local moneyBar = require("common.CommonMoneyBar").new()
    moneyUILayer:addChild(moneyBar)

    ----------------listTitleBg start-----------------
    local listTitleBg = display.newNSprite(RES_DICT.ACTIVITY_PTFB_TITLE_BG, display.SAFE_L - 66, display.height - 122,
    {
        ap = display.LEFT_TOP,
    })
    view:addChild(listTitleBg, 2)

    local offset = 80
    local titleWordsBg = display.newNSprite(RES_DICT.ACTIVITY_PTFB_TITLE_WORDS_BG, 245 + offset, 50,
    {
        ap = display.CENTER,
    })
    listTitleBg:addChild(titleWordsBg)

    local ptPointTipLabel = display.newLabel(47 + offset, 48,
    {
        text = __('拥有pt点数：'),
        ap = display.LEFT_CENTER,
        fontSize = 22,
        color = '#5b3c25',
    })
    listTitleBg:addChild(ptPointTipLabel)

    local ptNumLabel = display.newLabel(242 + offset, 48,
    {
        ap = display.LEFT_CENTER,
        fontSize = 36,
        color = '#862c04',
        font = TTF_GAME_FONT, ttf = true,
    })
    listTitleBg:addChild(ptNumLabel)

    -----------------listTitleBg end------------------
    local listBg = display.newNSprite(RES_DICT.PTFB_FRAME_BG_BLACK, display.SAFE_L - 18, display.height - 163,
    {
        ap = cc.p(0, 1.0),
        scale9 = true,
        size = cc.size(566, math.max(display.height - 100, 587))
    })
    view:addChild(listBg)

    local listSize = cc.size(526, display.height - 205)
    local tableView = CTableView:create(listSize)
    display.commonUIParams(tableView, {po = cc.p(display.SAFE_L, display.height - 205), ap = display.LEFT_TOP})
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(cc.size(523, 236))
    view:addChild(tableView)

    local nameLabelBgSize = cc.size(260, 40)
    local nameLabelBg = display.newButton(display.cx + 230, display.cy - 200, 
        {scale9 = true, size = nameLabelBgSize, n = RES_DICT.POKEDEX_CARD_BG_NAME, ap = display.CENTER, enable = false})
    view:addChild(nameLabelBg)
    display.commonLabelParams(nameLabelBg, fontWithColor(19, {color = '#ffffff', offset = cc.p(-5,0), fontSize = 26}))
    local cardTipImg = display.newButton(display.cx + 370, display.cy - 200, {n = RES_DICT.BTN_TIPS})
    view:addChild(cardTipImg)
    
    local timeTip = display.newImageView(RES_DICT.ACTIVITY_PTFB_TIME_BG, display.width, display.height - 116,
    {
        ap = display.RIGHT_CENTER,
        scale9 = true, size = cc.size(388, 79),
        enable = false,
    })
    view:addChild(timeTip)

    local LeftTimeLabel = display.newLabel(display.width - 360, display.height - 116,
    {
        text = __('活动剩余时间：'),
        ap = display.LEFT_CENTER,
        fontSize = 26,
        color = '#fec325',
    })
    view:addChild(LeftTimeLabel)

    local timeTipLabel = display.newLabel(display.width - 360 + display.getLabelContentSize(LeftTimeLabel).width, display.height - 116,
    {
        ap = display.LEFT_CENTER,
        fontSize = 26,
        color = '#fec325',
    })
    view:addChild(timeTipLabel)

    local ligthImg = display.newImageView(RES_DICT.STARPLAN_MAIN_ICON_LIGHT, display.SAFE_R - 100, display.height - 205 - 19,
        {
            ap = display.CENTER,
        })
    view:addChild(ligthImg)
    ligthImg:setScale(1.3)

    -----------------rankingBtn start-----------------
    local rankingBtn = display.newButton(display.SAFE_R - 100, display.height - 205,
    {
        ap = display.CENTER,
        n = CommonUtils.GetGoodsIconPathById(701029),
        s = CommonUtils.GetGoodsIconPathById(701029),
        enable = true,
    })
    rankingBtn:setScale(0.8)
    -- display.commonLabelParams(rankingBtn, fontWithColor(14, {text = ''})
    view:addChild(rankingBtn)

    local rankingBG = display.newButton(display.SAFE_R , display.height - 205 - 69,
    {
        ap = display.RIGHT_CENTER ,
        n = RES_DICT.STARPLAN_MAIN_FRAME_BTN_NAME, 
        scale9 = true,
        enable = false,
        size = cc.size(116, 42) ,scale9 = true
    })
    display.commonLabelParams(rankingBG, fontWithColor(14, 
    {
        text = __('排行奖励'),
        paddingW = 10 ,
        ap = display.CENTER,
        fontSize = 26,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
        outline = '#5b3c25',
    }))
    view:addChild(rankingBG)
    local rankingBGSize = rankingBG:getContentSize()
    if rankingBGSize.width < 150 then
        rankingBG:setPositionX(display.SAFE_R-30)
    end
    local resetBtn
    if DEBUG > 0 then
        resetBtn = display.newButton(display.SAFE_R - 100, display.height - 205 - 69 - 200,
        {
            ap = display.CENTER,
            n = _res('ui/common/common_btn_orange_big.png'), 
        })
        display.commonLabelParams(resetBtn, fontWithColor(14, 
        {
            text = __('去掉今日推荐'),
            w = 200,
            ap = display.CENTER,
            fontSize = 20,
            hAlign = display.TAC ,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        }))
        view:addChild(resetBtn)
    end

    ------------------fightBg start-------------------
    local fightBg = display.newNSprite(RES_DICT.DISCOVERY_BG_FIGHT, display.SAFE_R + 60, 0,
    {
        ap = display.RIGHT_BOTTOM,
    })
    view:addChild(fightBg)

    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(display.SAFE_R - 96, 106)
    -- fightBtn:setEnabled(false)
    view:addChild(fightBtn)

    local consumeLabel = display.newLabel(180, 16,
    {
        ap = display.CENTER,
        fontSize = 22,
        color = '#ffffff',
    })
    fightBg:addChild(consumeLabel)

    local consumeGoodImg = display.newNSprite(_res('arts/goods/goods_icon_900002.png'), 180, 16, {ap = display.CENTER})
    consumeGoodImg:setScale(0.2)
    fightBg:addChild(consumeGoodImg)

    -------------------fightBg end--------------------
   
    --------------------view end--------------------
    return {
        view                    = view,
        backBtn                 = backBtn,
        titleBtn                = titleBtn,
        moneyBar                = moneyBar,
        listTitleBg             = listTitleBg,
        titleWordsBg            = titleWordsBg,
        ptPointTipLabel         = ptPointTipLabel,
        LeftTimeLabel         = LeftTimeLabel,
        ptNumLabel              = ptNumLabel,
        listBg                  = listBg,
        tableView               = tableView,
        cardDraw                = cardDraw,
        timeTip                 = timeTip,
        timeTipLabel            = timeTipLabel,
        nameLabelBg             = nameLabelBg,
        cardTipImg              = cardTipImg,
        rankingBtn              = rankingBtn,
        fightBg                 = fightBg,
        fightBtn                = fightBtn,
        consumeLabel            = consumeLabel,
        consumeGoodImg          = consumeGoodImg,
        listSize                = listSize,
        resetBtn                = resetBtn,
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

     --------------------cell start--------------------
     local chapterName = display.newLabel(255, 193,
     {
         ap = display.CENTER,
         fontSize = 30,
         color = '#5b3c25',
         font = TTF_GAME_FONT, ttf = true,
     })
     cell:addChild(chapterName, 1)
 
    local storyTouchViewSize = cc.size(50, 50)
    local storyTouchView = display.newLayer(450, 189, {color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER, size = storyTouchViewSize})
    cell:addChild(storyTouchView, 1)
    
    local storyImg = FilteredSpriteWithOne:create(RES_DICT.TASK_BTN_PLAYBACK)
    storyImg:setFilter(filter.newFilter('GRAY'))
    display.commonUIParams(storyImg, {po = cc.p(storyTouchViewSize.width / 2 + 10, storyTouchViewSize.height / 2 + 4), ap = display.CENTER})
    storyImg:setScale(0.56)
    storyTouchView:addChild(storyImg)
    
    local interviewBtnSpine = sp.SkeletonAnimation:create("effects/activity/saimoe/Button.json","effects/activity/saimoe/Button.atlas", 0.56)
    interviewBtnSpine:setPosition(cc.p(storyTouchViewSize.width / 2 + 10, storyTouchViewSize.height / 2 + 4))
    interviewBtnSpine:update(0)
    interviewBtnSpine:setAnimation(0, 'idle', true)
    storyTouchView:addChild(interviewBtnSpine)

     ------------------rewordBg start------------------
     local rewordBg = display.newNSprite(RES_DICT.ACTIVITY_PTFB_FRAME_TITLE_BG, 0, 229 ,
     {
         ap = display.LEFT_TOP,
     })
     cell:addChild(rewordBg)
 
     local activity_ptfb_frame_rumber_bg_12 = display.newNSprite(RES_DICT.ACTIVITY_PTFB_FRAME_RUMBER_BG, 264, 128,
     {
         ap = display.CENTER,
     })
     rewordBg:addChild(activity_ptfb_frame_rumber_bg_12)
 
     local ptPointTipLabel = display.newLabel(264, 128,
     {
         ap = display.CENTER,
         fontSize = 20,
         color = '#d23d3d',
     })
     rewordBg:addChild(ptPointTipLabel)
 
     -------------------rewordBg end-------------------
     local drawBtn = display.newButton(425, 60,
     {
         ap = display.CENTER,
         n = RES_DICT.COMMON_BTN_ORANGE,
         scale9 = true, size = cc.size(110, 55),
         enable = true,
     })
     display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取')}))
     cell:addChild(drawBtn)
 
     local rewardLayer = display.newLayer(0, 12,
     {
         ap = display.LEFT_BOTTOM,
         size = cc.size(346, 100),
     })
     cell:addChild(rewardLayer)
 
     ---------------------cell end---------------------

    cell.viewData = {
        chapterName             = chapterName,
        storyTouchView          = storyTouchView,
        storyImg                = storyImg,
        interviewBtnSpine       = interviewBtnSpine,
        rewordBg                = rewordBg,
        activity_ptfb_frame_rumber_bg_12 = activity_ptfb_frame_rumber_bg_12,
        ptPointTipLabel         = ptPointTipLabel,
        drawBtn                 = drawBtn,
        rewardLayer             = rewardLayer,

        rewardList              = {},
    }

    return cell
end

function PTDungeonHomeView:CreateCell(size)
    return CreateCell_(size)
end

function PTDungeonHomeView:getViewData()
	return self.viewData_
end

return PTDungeonHomeView