local CommonDialog = require('common.CommonDialog')
---@class AnniversaryRewardPreviewView
local AnniversaryRewardPreviewView = class('common.AnniversaryRewardPreviewView', CommonDialog)


local RES_DICT = {
    COMMON_BG_4                                = app.anniversaryMgr:GetResPath('ui/common/common_bg_4.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_UNUSED   = app.anniversaryMgr:GetResPath('ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_unused.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_SELECTED = app.anniversaryMgr:GetResPath('ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_selected.png'),
    ANNI_REWARDS_LABEL_CARD_PREVIEW            = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
}

local CreateView = nil

local TAB_TAG = {
    PLOT_UNLOCK = 100,
    CHALLENGE   = 101,
    RANK        = 102,
}

local TAB_CONFS = {
    {name = app.anniversaryMgr:GetPoText(__('剧情解锁奖励')), tag = TAB_TAG.PLOT_UNLOCK},
    {name = app.anniversaryMgr:GetPoText(__('庆典积分奖励')), tag = TAB_TAG.CHALLENGE},
    {name = app.anniversaryMgr:GetPoText(__('排名奖励')),    tag = TAB_TAG.RANK},
}

function AnniversaryRewardPreviewView:InitialUI()
    xTry(function ( )
        
		self.viewData = CreateView(self.args.tabConfs)
	end, __G__TRACKBACK__)
end

function AnniversaryRewardPreviewView:updateTab(tag, isSelect)
    local viewData = self:getViewData()
    local tabs     = viewData.tabs
    local tab      = tabs[tostring(tag)]
    if tab then
        local img = isSelect and RES_DICT.SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_SELECTED or RES_DICT.SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_UNUSED
        tab:setNormalImage(img)
        tab:setSelectedImage(img)
    end
end

function AnniversaryRewardPreviewView:updateCardPreview(confId)
    local isShow = confId ~= nil
    local viewData = self:getViewData()
    local cardPreviewLayer = viewData.cardPreviewLayer
    cardPreviewLayer:setVisible(isShow) 

    if isShow == false then return end
    
    local cardPreviewBtn = viewData.cardPreviewBtn
    local oldConfId = checkint(cardPreviewBtn:getTag())
    if oldConfId == checkint(confId) then return end
    if CommonUtils.GetGoodTypeById(confId) == GoodsType.TYPE_CARD_SKIN then
        cardPreviewBtn:RefreshUI({skinId = confId})
    else
        cardPreviewBtn:RefreshUI({confId = confId})
    end
end

function AnniversaryRewardPreviewView:updateCardPreviewBySkinId(skinId, cb)
    local isShow = skinId ~= nil
    local viewData = self:getViewData()
    local cardPreviewLayer = viewData.cardPreviewLayer
    cardPreviewLayer:setVisible(isShow) 

    if isShow == false then return end
    
    local cardPreviewBtn = viewData.cardPreviewBtn
    local oldConfId = checkint(cardPreviewBtn:getTag())
    if oldConfId == checkint(skinId) then return end
    cardPreviewBtn:RefreshUI({skinId = skinId, cb = cb})
end

function AnniversaryRewardPreviewView:updateCardPreviewTipLabel(text)
    display.commonLabelParams(self:getViewData().cardPreviewTipLabel, {text = text})
end

function AnniversaryRewardPreviewView:getViewData()
    return self.viewData
end

function AnniversaryRewardPreviewView:CloseHandler()

	local currentScene = app.uiMgr:GetCurrentScene()
    if currentScene and self.args.mediatorName then
        app:UnRegsitMediator(self.args.mediatorName)
    end
end

CreateView = function (tabConfs)
    local size = cc.size(1000, 640)
    local view  = display.newLayer(display.cx + 40, display.cy - 317, {ap = display.CENTER_BOTTOM, size = size})

    local bg = display.newImageView(RES_DICT.COMMON_BG_4, 500, 0, {
        ap = display.CENTER_BOTTOM,
        scale9 = true, size = cc.size(950, 590),
    })
    view:addChild(bg)

    local tabs = {}
    for i, tabConf in ipairs(tabConfs or TAB_CONFS) do
        local btn = display.newButton(165 + (i - 1) * 236, 587,
        {
            ap = display.CENTER_BOTTOM,
            n = RES_DICT.SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_UNUSED,
            scale9 = true, size = cc.size(219, 55),
            enable = true,
        })
        display.commonLabelParams(btn, fontWithColor(14, {text = tabConf.name, offset = cc.p(0, -3), fontSize = 20, w = 220 , hAlign = display.TAC , color = '#ffffff'}))
        view:addChild(btn)

        btn:setTag(tabConf.tag)

        tabs[tostring(tabConf.tag)] = btn
    end

    local contentLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = size})
    view:addChild(contentLayer)

    local cardPreviewLayerSize = cc.size(300,130)
    local cardPreviewLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = cardPreviewLayerSize})
    view:addChild(cardPreviewLayer)
    cardPreviewLayer:setVisible(false)

    local cardPreviewTipBg = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, 30, 10, {ap = display.LEFT_BOTTOM})
    cardPreviewLayer:addChild(cardPreviewTipBg)

    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
    display.commonUIParams(cardPreviewBtn, {ap = display.CENTER_BOTTOM, po = cc.p(96, 18)})
    cardPreviewLayer:addChild(cardPreviewBtn)

    local cardPreviewTipLabel = display.newLabel(cardPreviewTipBg:getPositionX() + 15, 13, fontWithColor(14, {ap = display.LEFT_BOTTOM, text = app.anniversaryMgr:GetPoText(__("卡牌详情"))}))
    cardPreviewLayer:addChild(cardPreviewTipLabel)

    return {
        view                = view,
        tabs                = tabs,
        contentLayer        = contentLayer,
        cardPreviewLayer    = cardPreviewLayer,
        cardPreviewBtn      = cardPreviewBtn,
        cardPreviewTipLabel = cardPreviewTipLabel
    }
end


return  AnniversaryRewardPreviewView