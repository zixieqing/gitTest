--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖 奖池预览view
--]]
local MurderMirrorPoolView = class('MurderMirrorPoolView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.MurderMirrorPoolView'
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local RES_DICT = {
    COMMON_BG_4 =  app.murderMgr:GetResPath('ui/common/common_bg_4'),
    COMMON_TITLE_5 =  app.murderMgr:GetResPath('ui/common/common_title_5'),
    COMMON_BG_GOODS =  app.murderMgr:GetResPath('ui/common/common_bg_goods'),
    SEASON_LOOTS_LINE_1 =  app.murderMgr:GetResPath('ui/common/season_loots_line_1.png'),
    DRAW_PROBABILITY_BTN =  app.murderMgr:GetResPath('ui/home/capsule/draw_probability_btn.png'),
    TOWER_BTN_QUIT =  app.murderMgr:GetResPath('ui/common/tower_btn_quit.png'),
    RESTAURANT_BTN_FESTIVAL_NOTICE =  app.murderMgr:GetResPath('avatar/ui/restaurant_btn_festival_notice'),
    SUMMER_ACTIVITY_EGGREWARDS_BG_CARD = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_preview_bg_card_200108.png'),
    ANNI_REWARDS_LABEL_CARD_PREVIEW     = app.murderMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
}

function MurderMirrorPoolView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function MurderMirrorPoolView:InitUI()
    local function CreateView()
        local bgSize = cc.size(982, 652)
        local view = CLayout:create(bgSize)
        -- mask
		local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
		mask:setTouchEnabled(true)
		mask:setContentSize(bgSize)
		mask:setAnchorPoint(cc.p(0.5, 0.5))
		mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
		view:addChild(mask, -1)
        -- 背景
        local bgImg = display.newImageView(RES_DICT.COMMON_BG_4, bgSize.width / 2, bgSize.height / 2, {scale9 = true, size = bgSize})
        bgImg:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        view:addChild(bgImg, 1)
        -- 分割线
        local linePos = cc.p(680, bgSize.height/2)
        local lineImg = display.newImageView(RES_DICT.SEASON_LOOTS_LINE_1, linePos.x, linePos.y)
        lineImg:setRotation(90)
        view:addChild(lineImg, 3)
        -- 左侧Layout -- 
        local leftLayoutSize = cc.size(linePos.x, bgSize.height)
        local leftLayout = CLayout:create(leftLayoutSize)
        display.commonUIParams(leftLayout, {po = cc.p(0, bgSize.height / 2), ap = cc.p(0, 0.5)})
        view:addChild(leftLayout, 5)
        -- 标题
        local leftLayoutTitle = display.newButton(leftLayoutSize.width / 2, leftLayoutSize.height - 35, {scale9 = true ,  n = RES_DICT.COMMON_TITLE_5})
        leftLayout:addChild(leftLayoutTitle, 1)
        display.commonLabelParams(leftLayoutTitle, fontWithColor('6', {text = app.murderMgr:GetPoText(__('本轮奖励'))}))
        -- 剩余数目
        local leftNumTitle = display.newLabel(26, bgSize.height - 50, fontWithColor('8', {ap = cc.p(0, 0.5), text = ''}))
        leftLayout:addChild(leftNumTitle, 5)
        -- 概率
        local probabilityBtn = display.newButton(660, bgSize.height - 46, {ap = cc.p(1, 0.5) ,  n = RES_DICT.DRAW_PROBABILITY_BTN , s = RES_DICT.DRAW_PROBABILITY_BTN , scale9 = true })
        leftLayout:addChild(probabilityBtn, 10)
        display.commonLabelParams(probabilityBtn, fontWithColor(18, {text = app.murderMgr:GetPoText(__('概率')) ,reqW = 140}))
        probabilityBtn:setVisible(false)
        -- 列表Layout
        local listViewLayoutSize = cc.size(645, 540)
        local listViewLayout = CLayout:create(listViewLayoutSize)
        display.commonUIParams(listViewLayout, {po = cc.p(leftLayoutSize.width/2, 42), ap = cc.p(0.5, 0)})
        leftLayout:addChild(listViewLayout, 5)
        -- 列表背景
        local listViewBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, listViewLayoutSize.width / 2, listViewLayoutSize.height / 2
        , { size = cc.size(listViewLayoutSize.width, listViewLayoutSize.height + 4), scale9 = true } )
        listViewLayout:addChild(listViewBg)
        -- 列表
        local rewardListView = CListView:create(listViewLayoutSize)
        rewardListView:setDirection(eScrollViewDirectionVertical)
        rewardListView:setPosition(cc.p(listViewLayoutSize.width / 2, listViewLayoutSize.height / 2))
        listViewLayout:addChild(rewardListView)
        -- 左侧Layout -- 
        -- 右侧Layout --
        local rightLayoutSize = cc.size(bgSize.width - leftLayoutSize.width, bgSize.height)
        local rightLayout = CLayout:create(rightLayoutSize)
        display.commonUIParams(rightLayout, {po = cc.p(leftLayoutSize.width, bgSize.height / 2), ap = cc.p(0, 0.5)})
        view:addChild(rightLayout, 5)
        -- 预告按钮
        local forenoticeBtn = display.newButton(rightLayoutSize.width - 34, rightLayoutSize.height - 75, {n = RES_DICT.TOWER_BTN_QUIT, ap = cc.p(1, 0)})
        display.commonLabelParams(forenoticeBtn, {text = app.murderMgr:GetPoText(__('稀有奖励一览')), fontSize = 22, color = '#ffffff'})
        rightLayout:addChild(forenoticeBtn, 5)
        local forenoticeImg = display.newImageView(RES_DICT.RESTAURANT_BTN_FESTIVAL_NOTICE, -10, 23)
        forenoticeBtn:addChild(forenoticeImg, 5)
        local roleImg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGGREWARDS_BG_CARD, 7, 2, {ap = cc.p(0, 0)})
        rightLayout:addChild(roleImg, 5)

        -- card preview btn
        local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
        display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(rightLayoutSize.width - 10, 24)})
        rightLayout:addChild(cardPreviewBtn, 5)
        cardPreviewBtn:setVisible(false)

        local cardPreviewTip = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
        cardPreviewTip:setScaleX(-1)
        cardPreviewBtn:addChild(cardPreviewTip)
        
        cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.murderMgr:GetPoText(__('卡牌详情'))})))

        -- 右侧Layout --
        return {
            view             = view,
            probabilityBtn   = probabilityBtn,
            forenoticeBtn    = forenoticeBtn,
            rewardListView   = rewardListView,
            listViewLayoutSize = listViewLayoutSize,
            leftNumTitle     = leftNumTitle,
            forenoticeImg    = forenoticeImg,
            cardPreviewBtn   = cardPreviewBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("activity.murder.MurderMirrorPoolMediator")
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
return MurderMirrorPoolView