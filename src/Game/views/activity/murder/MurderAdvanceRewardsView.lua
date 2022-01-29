--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）奖励预览页签 推进奖励View
]]
local VIEW_SIZE = cc.size(950, 590)
local MurderAdvanceRewardsView = class('MurderAdvanceRewardsView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.activity.murder.MurderAdvanceRewardsView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    COMMON_BTN           = app.murderMgr:GetResPath('ui/common/common_btn_orange.png'),
    COMMON_BTN_DISABLE   = app.murderMgr:GetResPath('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_DRAWN     = app.murderMgr:GetResPath('ui/common/activity_mifan_by_ico.png'),
    TIPS_ICON            = app.murderMgr:GetResPath('ui/common/common_btn_tips.png'),
    MURDER_RANK_BG_CARD                   = app.murderMgr:GetResPath('ui/home/activity/murder/rewardBg/murder_rewards_bg_200108.png'),
    SUMMER_ACTIVITY_RANK_BG_WORDS         = app.murderMgr:GetResPath('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_words.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_LIST    = app.murderMgr:GetResPath("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_list.png"),
    MURDER_RANK_BG_QBOSS                  = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_clock_1.png'),
    SUMMER_ACTIVITY_EGG_BG_EXTRA_SHADOW   = app.murderMgr:GetResPath('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_extra_shadow.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY    = app.murderMgr:GetResPath('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_grey.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE  = app.murderMgr:GetResPath('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_active.png'),

    ANNI_REWARDS_LABEL_CARD_PREVIEW     = app.murderMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
}

local CreateView = nil
local CreateCell_ = nil

function MurderAdvanceRewardsView:ctor( ... )

    self.args = unpack({...})
    self:initialUI()
end

function MurderAdvanceRewardsView:initialUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = cc.p(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2)})
        self:initView()
	end, __G__TRACKBACK__)
end

function MurderAdvanceRewardsView:initView()
    
end

function MurderAdvanceRewardsView:refreshUI(data)
    
end

function MurderAdvanceRewardsView:updateUI(data)
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    RES_DIR.MURDER_RANK_BG_CARD = app.murderMgr:GetChangeImagePath("MURDER_RANK_BG_CARD" , 200108 , "ui/home/activity/murder/rewardBg/murder_rewards_bg_") 
    view:addChild(display.newImageView(RES_DIR.MURDER_RANK_BG_CARD, size.width - 110, size.height / 2 - 20, {ap = display.CENTER}))
    -- 奖励
    local rewardLayoutSize = cc.size(600, 200)
    local rewardLayout = CLayout:create(rewardLayoutSize)
    display.commonUIParams(rewardLayout, {po = cc.p(90, 480), ap = cc.p(0, 0.5)})
    view:addChild(rewardLayout, 3)
    local rewardBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_RANK_LIST, rewardLayoutSize.width / 2 - 30, 5, {ap = cc.p(0.5, 0)})
    rewardLayout:addChild(rewardBg, 1)
    local rewardTitle = display.newLabel(210, 115, {text = app.murderMgr:GetPoText(__('推进时钟奖励')), fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2})
    rewardBg:addChild(rewardTitle, 1)
    local rewardConf = CommonUtils.GetConfig('newSummerActivity', 'overTimeReward', 1)
    local confId = nil
    if rewardConf then
        for i, v in ipairs(rewardConf.rewards) do
            local callBack = function(sender)
                app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = v.goodsId, type = 1 })
            end
            if CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD then
                confId = v.goodsId
            end
            local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack, highlight = 1})
            goodsNode:setScale(0.8)
            rewardLayout:addChild(goodsNode, 5)
            local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = goodsNode:getContentSize(), scale = 0.8, midPointX = 228, midPointY = 55, col = #rewardConf.rewards, maxCol = 3, goodGap = 10})
            display.commonUIParams(goodsNode, {po = pos})
        end
    end
    local jokerImg = display.newImageView(RES_DIR.MURDER_RANK_BG_QBOSS, 25, 100)
    rewardLayout:addChild(jokerImg, 5)
    -- 进度条
    local progressBarBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_EGG_BG_EXTRA_SHADOW, 30, 10)
    progressBarBg:setScaleX(0.7)
    rewardLayout:addChild(progressBarBg, 3)
    local progressBar = CProgressBar:create(RES_DIR.SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE)
    progressBar:setBackgroundImage(RES_DIR.SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setPosition(cc.p(30, 10))
    progressBar:setScaleX(0.7)
    rewardLayout:addChild(progressBar, 5)
    local progressLabel = display.newLabel(30, 10, {text = '1/1', fontSize = 20, color = '#ffffff'})
    rewardLayout:addChild(progressLabel, 10)
    progressBarBg:setVisible(false)
    progressBar:setVisible(false)
    progressLabel:setVisible(false)
    --规则
    local ruleLayoutSize = cc.size(600, 120)
    local ruleLayout = CLayout:create(ruleLayoutSize)
    display.commonUIParams(ruleLayout, {po = cc.p(40, 323), ap = cc.p(0, 0.5)})
    view:addChild(ruleLayout)
    local tipsIcon = display.newImageView(RES_DIR.TIPS_ICON, 64, ruleLayoutSize.height - 30)
    ruleLayout:addChild(tipsIcon, 5)
    local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))['-32'] or {}
    local ruleLabel = display.newLabel(90, ruleLayoutSize.height - 12, fontWithColor(15, {text = moduleExplainConf.descr, ap = cc.p(0, 1), w = 460}))
    ruleLayout:addChild(ruleLabel, 5)
    -- 领取按钮
    local drawBtn = display.newButton(320, 225, {n = RES_DIR.COMMON_BTN})
    view:addChild(drawBtn, 5)
    -- 对话
    local dialogueBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_WORDS, size.width / 2, 28, {ap = cc.p(0.5, 0)})
    view:addChild(dialogueBg, 5)
    local dialogueLabel = display.newLabel(32, dialogueBg:getContentSize().height - 36, fontWithColor(4, {text = app.murderMgr:GetPoText(__('整件事似乎慢慢变成了奇怪的走向。\n但愿能早点结束吧，毕竟比起这些，我们还有更重要的事情要去做。')), ap = cc.p(0, 1)}))
    dialogueBg:addChild(dialogueLabel)

    -- 卡牌预览
    if confId then
        -- card preview btn
        local cardPreviewBtn = require("common.CardPreviewEntranceNode").new({confId = confId})
        display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width - 24, 38)})
        view:addChild(cardPreviewBtn, 5)
        -- cardPreviewBtn:setVisible(false)
    
        local cardPreviewTip = display.newImageView(RES_DIR.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
        cardPreviewTip:setScaleX(-1)
        cardPreviewBtn:addChild(cardPreviewTip)
        
        cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.murderMgr:GetPoText(__('卡牌详情'))})))
    end

    return {
        view      = view,
        drawBtn   = drawBtn,
        progressBar = progressBar,
        progressLabel = progressLabel
    }
end

function MurderAdvanceRewardsView:getViewData()
    return self.viewData
end
--[[
改变领取按钮状态
@params state int 状态 （1--可领取  2--不可领取  3-- 已领取）
--]]
function MurderAdvanceRewardsView:ChangeDrawBtnState( state )
    local viewData = self:getViewData()
    if state == 1 then
        viewData.drawBtn:setNormalImage(RES_DIR.COMMON_BTN)
        viewData.drawBtn:setSelectedImage(RES_DIR.COMMON_BTN)
        viewData.drawBtn:setEnabled(true)
        display.commonLabelParams(viewData.drawBtn,fontWithColor(14, {text = app.murderMgr:GetPoText(__('领取'))}))
    elseif state == 2 then
        viewData.drawBtn:setNormalImage(RES_DIR.COMMON_BTN_DISABLE)
        viewData.drawBtn:setSelectedImage(RES_DIR.COMMON_BTN_DISABLE)
        viewData.drawBtn:setEnabled(true)
        display.commonLabelParams(viewData.drawBtn,fontWithColor(14, {text = app.murderMgr:GetPoText(__('领取'))}))
    elseif state == 3 then
        viewData.drawBtn:setNormalImage(RES_DIR.COMMON_BTN_DRAWN)
        viewData.drawBtn:setSelectedImage(RES_DIR.COMMON_BTN_DRAWN)
        viewData.drawBtn:setEnabled(false)
        display.commonLabelParams(viewData.drawBtn,fontWithColor(14, {text = app.murderMgr:GetPoText(__('已领取'))}))
    end
end
return MurderAdvanceRewardsView