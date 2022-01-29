--[[
 * descpt : 夏活 home 界面
]]
local VIEW_SIZE = display.size
local SummerActivityHomeView = class('SummerActivityHomeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.summerActivity.SummerActivityHomeView'
	node:enableNodeEvents()
	return node
end)

local appIns   = AppFacade.GetInstance()
local summerActMgr = appIns:GetManager("SummerActivityManager")

local CreateView = nil

local RES_DIR_ = {
    BACK             = _res("ui/common/common_btn_back"),
    BTN_TIPS         = _res('ui/common/common_btn_tips.png'),
    ARROW_IMG        = _res('ui/common/common_btn_switch.png'),
    RNAK_IMG         = _res('ui/home/nmain/main_btn_rank.png'),
    RULE_TITLE       = _res('ui/home/activity/activity_exchange_bg_rule_title.png'),
    
    SUMMER_ACTIVITY_ENTRANCE_LIGHT   = _res('ui/home/activity/summerActivity/entrance/summer_activity_entrance_light.png'),
    SUMMER_ACTIVITY_ENTRANCE_LABEL_TITLE = _res('ui/home/activity/summerActivity/entrance/summer_activity_entrance_label_title.png'),
    SUMMER_ACTIVITY_ENTRANCE_BG               = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_bg.png"),
    SUMMER_ACTIVITY_ENTRANCE_BTN_BOOK         = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_btn_book.png"),
    SUMMER_ACTIVITY_ENTRANCE_BTN_ENTER        = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_btn_enter.png"),
    SUMMER_ACTIVITY_ENTRANCE_ICO_REWARDS      = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_ico_rewards.png"),

    SUMMER_ACTIVITY_ICO_POINT        = _res('ui/home/activity/summerActivity/entrance/summer_activity_ico_point.png'),

    REWARD_PREVIEW_ENTER_BTN   = _res('ui/common/tower_btn_quit.png'),

    SPINE_WUYA_PATH       = 'ui/home/activity/summerActivity/entrance/entranceSpine/wuya',
}
local RES_DIR = {}

local BUTTON_TAG = {
    BACK                 = 100,   -- 返回
    RULE                 = 101,   -- 规则
    PLOT                 = 102,   -- 剧情
    REWARD_PREVIEW_ENTER = 103,   -- 排行榜奖励
    CARNIE_ENTER         = 104,   -- 游乐场
    RANK                 = 105,   -- 排行榜
}

function SummerActivityHomeView:ctor( ... ) 
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)
    RES_DIR.SPINE_WUYA = _spn(RES_DIR.SPINE_WUYA_PATH)

    self.args = unpack({...}) or {}
    self:initialUI()
end

function SummerActivityHomeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function SummerActivityHomeView:refreshUI(data, pointData)
    local viewData = self:getViewData()
    self:updateRankRewardCell(viewData, data)

    self:updatePointLabel(viewData, data)
end

function SummerActivityHomeView:updateRankRewardCell(viewData, data)
    local rankRewardCell = viewData.rankRewardCell
    rankRewardCell:refreshUI(data)
end

function SummerActivityHomeView:updatePointLabel(viewData, data)
    local summerPoint = tonumber(data.summerPoint)
    local pointLabel = viewData.pointLabel
    pointLabel:setVisible(true)
    display.commonLabelParams(pointLabel, {text =  string.format(summerActMgr:getThemeTextByText(__('已有点数: %s')), summerPoint)})

    local pointIcon = viewData.pointIcon
    local pointIconSize = pointIcon:getContentSize()
    pointIcon:setVisible(true)
    
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()


    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true}))
    
    local actionBtns = {}
    -- back button
    local backBtn = display.newButton(size.width / 2 - 608, size.height - 52, {n = RES_DIR.BACK})
    view:addChild(backBtn)
    actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn

    local bgSize = cc.size(1215, 750)
    local bgLayer = display.newLayer(size.width / 2 + 45, size.height / 2, {ap = display.CENTER, size = bgSize})
    view:addChild(bgLayer)
    local bg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_BG, bgSize.width / 2, bgSize.height / 2)
    bgLayer:addChild(bg)
    
    -- 活动规则
    local tipsBtn = display.newButton(82, bgSize.height - 74, {n = RES_DIR.BTN_TIPS})
    actionBtns[tostring(BUTTON_TAG.RULE)] = tipsBtn
    bgLayer:addChild(tipsBtn, 2)
    local ruleTitleBg = display.newButton(tipsBtn:getPositionX() + 4, tipsBtn:getPositionY(), {ap = display.LEFT_CENTER, n = RES_DIR.RULE_TITLE, scale9 = true})
    display.commonLabelParams(ruleTitleBg, fontWithColor(14, { text = summerActMgr:getThemeTextByText(__('规则说明')), fontSize = 24, color = '#ffffff', paddingW = 30}))
	bgLayer:addChild(ruleTitleBg, 1)
    
    -- title
    bgLayer:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_LABEL_TITLE, 200, bgSize.height - 138, {ap = display.CENTER}))
    local titleLabel = display.newLabel(70, bgSize.height - 138, fontWithColor(20, {outline = '#8f6711', outlineSize = 4,fontSize = 60, text = summerActMgr:getThemeTextByText(__('恐怖游乐园')), ap = display.LEFT_CENTER}))
    bgLayer:addChild(titleLabel)


    -- 乐园入口
    local enterCarnieLightBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_LIGHT, 
        bgSize.width - 482 - 68, bgSize.height / 2 + 18, {ap = display.CENTER})
    bgLayer:addChild(enterCarnieLightBg)

    local enterCarnieBtn = display.newButton(bgSize.width - 248, bgSize.height / 2 - 48, {ap = display.CENTER, n = RES_DIR.SUMMER_ACTIVITY_ENTRANCE_BTN_ENTER, enable = false})
    display.commonLabelParams(enterCarnieBtn, fontWithColor(14, {fontSize = 32, w = 250, ap = display.CENTER, text = summerActMgr:getThemeTextByText(__('进入游乐园')), offset = cc.p(28, 4)}))
    bgLayer:addChild(enterCarnieBtn, 1)
    
    local arrow = display.newImageView(RES_DIR.ARROW_IMG, bgSize.width / 2 + 203, enterCarnieBtn:getPositionY() + 5, {ap = display.CENTER})
    arrow:setRotation(180)
    bgLayer:addChild(arrow, 1)

    local size = cc.size(330, 120)
    local enterCarnieTouchLayer = display.newLayer(enterCarnieBtn:getPositionX(), enterCarnieBtn:getPositionY(), {ap = display.CENTER, enable = true, size = size, color = cc.c4b(0,0,0,0)})
    actionBtns[tostring(BUTTON_TAG.CARNIE_ENTER)] = enterCarnieTouchLayer
    bgLayer:addChild(enterCarnieTouchLayer)

    -- 剧情入口
    local plotBtn = display.newButton(bgSize.width - 120, 87, {n = RES_DIR.SUMMER_ACTIVITY_ENTRANCE_BTN_BOOK})
    display.commonLabelParams(plotBtn, fontWithColor(14, {outline = '#491d1d', outlineSize = 2, text = summerActMgr:getThemeTextByText(__('剧情')), fontSize = 18, color = '#ffffff', offset = cc.p(0, -38) }))
    actionBtns[tostring(BUTTON_TAG.PLOT)] = plotBtn
    bgLayer:addChild(plotBtn)

    --  排行榜
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.RANKING) then
        local rankBtn = display.newButton(980, 89, {n = RES_DIR.RNAK_IMG, ap = display.CENTER})
		display.commonLabelParams(rankBtn, fontWithColor(14, {outline = '#491d1d', outlineSize = 2, fontSize = 18, text = summerActMgr:getThemeTextByText(__('排行榜')), offset = cc.p(0, -38)}))
        actionBtns[tostring(BUTTON_TAG.RANK)] = rankBtn
        bgLayer:addChild(rankBtn)
    end

     -- 夏活点数
     local pointIcon = display.newImageView(RES_DIR.ICO_POINT, 915, 52, {ap = display.RIGHT_CENTER, enable = true})
     pointIcon:setScale(0.2)
     pointIcon:setVisible(false)
     bgLayer:addChild(pointIcon)
 
     local pointLabel = display.newLabel(pointIcon:getPositionX() - pointIcon:getContentSize().width * 0.2 - 3, pointIcon:getPositionY() - 2, fontWithColor(9, {text = '111', ap = display.RIGHT_CENTER}))
     pointLabel:setVisible(false)
     bgLayer:addChild(pointLabel)



    -- rank bg layer
    local rankBgSize = cc.size(789, 313)
    local rankBgLayer = display.newLayer(10, 23, {size = rankBgSize})
    bgLayer:addChild(rankBgLayer)
    
    local rankEnterBtnSize = cc.size(230, 47)
    local rankEnterBtn = display.newButton(80, rankBgSize.height - 126, {scale9 = true, size = rankEnterBtnSize, ap = display.LEFT_CENTER, n = RES_DIR.REWARD_PREVIEW_ENTER_BTN})
    display.commonLabelParams(rankEnterBtn, fontWithColor(14, {outline = '#491d1d', outlineSize = 2, fontSize = 22, text = summerActMgr:getThemeTextByText(__('奖励一览')), paddingW = 40 }))
    actionBtns[tostring(BUTTON_TAG.REWARD_PREVIEW_ENTER)] = rankEnterBtn
    rankBgLayer:addChild(rankEnterBtn)

    rankEnterBtn:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_ICO_REWARDS, 0, 0, {ap = display.CENTER_BOTTOM}))
    
    local rankRewardCell = require('Game.views.summerActivity.SummerActivityRankRewardCell').new()
    display.commonUIParams(rankRewardCell, {ap = display.LEFT_CENTER, po = cc.p(10, 82)})
    rankBgLayer:addChild(rankRewardCell)
    
    local spineJson = RES_DIR.SPINE_WUYA.json
    local spineAtlas = RES_DIR.SPINE_WUYA.atlas
    local paradiseLayer = display.newLayer()
    view:addChild(paradiseLayer)
    if CommonUtils.checkIsExistsSpine(spineJson,spineAtlas) then
        local spine = sp.SkeletonAnimation:create(spineJson, spineAtlas, 1)
        spine:update(0)
        spine:addAnimation(0, 'idle', true)
        spine:setPosition(cc.p(display.width / 2 + 46, display.height / 2 - 4))
        paradiseLayer:addChild(spine, 5)
    end

    return {
        view               = view,
        actionBtns         = actionBtns,
        rankRewardCell     = rankRewardCell,
        pointLabel         = pointLabel,
        pointIcon          = pointIcon,
        enterCarnieLightBg = enterCarnieLightBg,
        arrow              = arrow,
    }
end

function SummerActivityHomeView:getViewData()
	return self.viewData_
end

function SummerActivityHomeView:showAction()
    local viewData = self:getViewData()
    local enterCarnieLightBg = viewData.enterCarnieLightBg
    local arrow              = viewData.arrow

    arrow:runAction(cc.RepeatForever:create(cc.Sequence:create(
        {
            cc.MoveBy:create(0.5, cc.p(10, 0)),
            cc.MoveBy:create(0.5, cc.p(-10, 0)),
        }
    )))

    enterCarnieLightBg:runAction(cc.RepeatForever:create(cc.Sequence:create(
        {
            cc.FadeOut:create(1.5),
            cc.FadeIn:create(1.5)
        }
    )))
    
end

return SummerActivityHomeView