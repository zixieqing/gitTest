local CommonDialog = require('common.CommonDialog')
---@class PTDungeonRewardPreviewView
local PTDungeonRewardPreviewView = class('PTDungeonRewardPreviewView', CommonDialog)


local RES_DICT = {
    COMMON_BG_4                                 = _res('ui/common/common_bg_4.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_UNUSED    = _res('ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_unused.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_SELECTED  = _res('ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_selected.png'),
    ANNI_REWARDS_LABEL_CARD_PREVIEW             = _res('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
    COMMON_BTN_TIPS                             = _res('ui/common/common_btn_tips.png'),
    TUJIAN_SELECTION_SELECT_BTN_FILTER_SELECTED = _res('ui/common/tujian_selection_select_btn_filter_selected.png'),
    CELL_SELECT                                 = _res('ui/mail/common_bg_list_selected.png'),
    ACTIVITY_PTFB_CARD_200079                   = _res('ui/home/activity/ptDungeon/activity_ptfb_card_200079.png'),
    ANNI_REWARDS_BG_RANK                        = _res('ui/home/activity/ptDungeon/anni_rewards_bg_rank.png'),
    ANNI_REWARDS_LABEL_RANK                     = _res('ui/home/activity/ptDungeon/anni_rewards_label_rank.png'),
    ANNI_REWARDS_BG_LIST                        = _res('ui/home/activity/ptDungeon/anni_rewards_bg_list.png'),
    ANNI_REWARDS_LABEL_PRESENT                  = _res('ui/home/activity/ptDungeon/anni_rewards_label_present.png'),
    STARPLAN_MAIN_FRAME_BTN_NAME                = _res('ui/home/activity/ptDungeon/activity_ptfb_main_frame_btn_name.png'),
    STARPLAN_MAIN_ICON_LIGHT                    = _res('ui/common/starplan_main_icon_light.png'),
    MAIN_BTN_RANK                               = _res('ui/home/nmain/main_btn_rank.png'),
}

local CreateView = nil

local TAB_TAG = {
    SCORE_RANKING       = 100,
    HIGHEST_DAMAGE      = 101,
}

local TAB_CONFS = {
    {name = __('pt点数排行奖励'), tag = TAB_TAG.SCORE_RANKING},
    {name = __('累计伤害奖励'), tag = TAB_TAG.HIGHEST_DAMAGE}
}

function PTDungeonRewardPreviewView:InitialUI()
    local function CreateView( ... )
        local size = cc.size(1000, 640)
        local view  = display.newLayer(display.cx + 40, display.cy - 317, {ap = display.CENTER_BOTTOM, size = size})
    
        local bg = display.newImageView(RES_DICT.COMMON_BG_4, 500, 0, {
            ap = display.CENTER_BOTTOM,
            scale9 = true, size = cc.size(950, 590),
        })
        view:addChild(bg)
    
        local tabs = {}
        for i, tabConf in ipairs(TAB_CONFS) do
            local btn = display.newButton(165 + (i - 1) * 236, 587,
            {
                ap = display.CENTER_BOTTOM,
                n = RES_DICT.SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_UNUSED,
                scale9 = true, size = cc.size(219, 55),
                enable = true,
            })
            display.commonLabelParams(btn, fontWithColor(14, {text = tabConf.name, reqW = 200 ,  offset = cc.p(0, -3), fontSize = 24, color = '#ffffff'}))
            view:addChild(btn)
    
            btn:setTag(tabConf.tag)
    
            tabs[tostring(tabConf.tag)] = btn
        end
    
        local contentLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = size})
        view:addChild(contentLayer)

        local rewardBg = display.newNSprite(RES_DICT.ACTIVITY_PTFB_CARD_200079, 26, 6, {ap = display.LEFT_BOTTOM})
        contentLayer:addChild(rewardBg)
    
        local listSize = cc.size(534, 524)
        local listCellSize = cc.size(listSize.width, 148 + 24)
        local tableView = CTableView:create(listSize)
        display.commonUIParams(tableView, {po = cc.p(698, 276), ap = display.CENTER})
        tableView:setDirection(eScrollViewDirectionVertical)
        -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
        tableView:setSizeOfCell(listCellSize)
        contentLayer:addChild(tableView)
    
        contentLayer:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_BG_RANK, 140, 522, {ap = display.CENTER}))
    
        local integralTipBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_RANK, 33, 563, {ap = display.LEFT_CENTER})
        contentLayer:addChild(integralTipBg)
    
        local title1 = display.newLabel(14, 14,
        {
            text = __('当前pt点数'),
            ap = display.LEFT_CENTER,
            fontSize = 20,
            color = '#fee1b3',
        })
        integralTipBg:addChild(title1)
    
        local integralLabel = display.newLabel(49, 533,
        {
            ap = display.LEFT_CENTER,
            fontSize = 20,
            color = '#ffffff',
        })
        contentLayer:addChild(integralLabel)
    
        local rankTipBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_RANK, 33, 507,
        {
            ap = display.LEFT_CENTER,
        })
        contentLayer:addChild(rankTipBg)
    
        local title2 = display.newLabel(14, 14,
        {
            text = __('当前段位'),
            ap = display.LEFT_CENTER,
            fontSize = 20,
            color = '#fee1b3',
        })
        rankTipBg:addChild(title2)
    
        local rankLabel = display.newLabel(49, 480,
        {
            ap = display.LEFT_CENTER,
            fontSize = 20,
            color = '#ffffff',
        })
        contentLayer:addChild(rankLabel)

        local ligthImg = display.newImageView(RES_DICT.STARPLAN_MAIN_ICON_LIGHT, 902, 598,
        {
            ap = display.CENTER,
        })
        contentLayer:addChild(ligthImg)

        local rankingBtn = display.newButton(902, 598,
        {
            ap = display.CENTER,
            n = RES_DICT.MAIN_BTN_RANK,
            s = RES_DICT.MAIN_BTN_RANK,
            enable = true,
        })
        -- display.commonLabelParams(rankingBtn, fontWithColor(14, {text = ''})
        contentLayer:addChild(rankingBtn)
    
        local rankingBG = display.newButton(902, 598 - 39,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_MAIN_FRAME_BTN_NAME, 
            scale9 = true,
            size = cc.size(116, 36)
        })
        display.commonLabelParams(rankingBG, fontWithColor(14, 
        {
            text = __('排行榜'),
            ap = display.CENTER,
            fontSize = 26,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        }))
        contentLayer:addChild(rankingBG)
    
        local cardPreviewLayerSize = cc.size(300,130)
        local cardPreviewLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = cardPreviewLayerSize})
        view:addChild(cardPreviewLayer)
        -- cardPreviewLayer:setVisible(false)
    
        local cardPreviewTipBg = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, 30, 10, {ap = display.LEFT_BOTTOM})
        cardPreviewLayer:addChild(cardPreviewTipBg)
    
        local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
        display.commonUIParams(cardPreviewBtn, {ap = display.CENTER_BOTTOM, po = cc.p(96, 18)})
        cardPreviewLayer:addChild(cardPreviewBtn)
    
        local cardPreviewTipLabel = display.newLabel(cardPreviewTipBg:getPositionX() + 15, 13, fontWithColor(14, {ap = display.LEFT_BOTTOM, text = __("卡牌详情")}))
        cardPreviewLayer:addChild(cardPreviewTipLabel)
    
        return {
            view                = view,
            tabs                = tabs,
            contentLayer        = contentLayer,
            cardPreviewLayer    = cardPreviewLayer,
            cardPreviewBtn      = cardPreviewBtn,
            rewardBg            = rewardBg,
            tableView           = tableView,
            integralLabel       = integralLabel,
            rankLabel           = rankLabel,
            rankingBtn          = rankingBtn,
            title1              = title1,
            title2              = title2,
        }
    end
    xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

function PTDungeonRewardPreviewView:refreshUI( data )
    local viewData = self.viewData
    viewData.title1:setString(data[1].title)
    viewData.integralLabel:setString(data[1].num)
    viewData.title2:setString(data[2].title)
    viewData.rankLabel:setString(data[2].num)
end

function PTDungeonRewardPreviewView:updateTab(tag, isSelect)
    local viewData = self:getViewData()
    local tabs     = viewData.tabs
    local tab      = tabs[tostring(tag)]
    if tab then
        local img = isSelect and RES_DICT.SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_SELECTED or RES_DICT.SUMMER_ACTIVITY_ENTRANCE_RANK_TAB_UNUSED
        tab:setNormalImage(img)
        tab:setSelectedImage(img)
    end
end

function PTDungeonRewardPreviewView:updateCardPreview(confId)
    local isShow = confId ~= nil
    local viewData = self:getViewData()
    local cardPreviewLayer = viewData.cardPreviewLayer
    cardPreviewLayer:setVisible(isShow) 

    if isShow == false then return end
    
    local cardPreviewBtn = viewData.cardPreviewBtn
    local oldConfId = checkint(cardPreviewBtn:getTag())
    if oldConfId == checkint(confId) then return end
    cardPreviewBtn:RefreshUI({confId = confId})
end

function PTDungeonRewardPreviewView:CreateRankTabCell()
    local size = self.viewData.tableView:getSizeOfCell()
    local cell = CTableViewCell:new()
    cell:setContentSize(size)
    -- cell:setBackgroundColor(cc.c4b(23, 67, 128, 128))

    local bg = display.newNSprite(RES_DICT.ANNI_REWARDS_BG_LIST, 262, 75 + 24,
    {
        ap = display.CENTER,
    })
    cell:addChild(bg)

    local titleLabel = display.newLabel(243, 122 + 24,
    {
        ap = display.CENTER,
        fontSize = 20,
        color = '#aa7522',
    })
    cell:addChild(titleLabel)

    local rewardLayer = display.newLayer(242, 59 + 24,
    {
        ap = display.CENTER,
        size = cc.size(460, 100),
    })
    cell:addChild(rewardLayer)

    local cellSelectImg = display.newImageView(RES_DICT.CELL_SELECT, size.width / 2 - 2, size.height / 2 + 12, {ap = display.CENTER, scale9 = true, size = cc.size(size.width - 26, 145)})
    cell:addChild(cellSelectImg)
    cellSelectImg:setVisible(false)
    
    local tipsBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_PRESENT, 527, 124.5 + 24,
    {
        ap = display.RIGHT_CENTER,
    })
    cell:addChild(tipsBg)
    tipsBg:setVisible(false)

    tipsBg:addChild(display.newLabel(60, 15,
    {
        text = __('当前'),
        ap = display.CENTER,
        fontSize = 20,
        color = '#ffffff',
    }))

    local curDotLabel = display.newLabel(243, 12, {fontSize = 20, color = '#ad8136', ap = display.CENTER, text = ''})
    cell:addChild(curDotLabel)

    cell.viewData = {
        titleLabel    = titleLabel,
        rewardLayer   = rewardLayer,
        cellSelectImg = cellSelectImg,
        tipsBg        = tipsBg,
        rewardNodes   = {},
        curDotLabel   = curDotLabel,
    }
    return cell
end

function PTDungeonRewardPreviewView:getViewData()
    return self.viewData
end

function PTDungeonRewardPreviewView:CloseHandler()

	local currentScene = app.uiMgr:GetCurrentScene()
    if currentScene and self.args.mediatorName then
        app:UnRegsitMediator(self.args.mediatorName)
    end
end

return  PTDungeonRewardPreviewView