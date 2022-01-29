--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 任务活动View
--]]
local ActivitySkinCarnivalTaskView = class('ActivitySkinCarnivalTaskView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.skinCarnival.ActivitySkinCarnivalTaskView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG_ORNAMENT_L          = _res('ui/home/activity/skinCarnival/story_common_bg_diaoshi_1.png'),
    BG_ORNAMENT_R          = _res('ui/home/activity/skinCarnival/story_common_bg_diaoshi_2.png'),
    BG                     = _res('ui/home/activity/skinCarnival/story_cap_bg.png'),
    TITLE_BG               = _res('ui/home/activity/skinCarnival/story_common_bg_head.png'),
    TIPS_ICON              = _res('ui/common/common_btn_tips.png'),
    SWITCH_BTN             = _res('ui/home/activity/skinCarnival/story_common_btn_q.png'),
    SWITCH_BTN_L2D         = _res('ui/home/activity/skinCarnival/story_common_btn_L2D.png'),
    STORY_BTN              = _res('ui/home/activity/skinCarnival/story_common_btn_story.png'),
    STORY_BTN_LOCK_MASK    = _res('ui/home/activity/skinCarnival/story_common_btn_story_lock.png'),
    STORY_BTN_LOCK         = _res('ui/common/common_ico_lock.png'),
    BUY_BTN                = _res('ui/home/activity/skinCarnival/story_cap_btn_buy.png'),
    SKIN_NAME_BG           = _res('ui/home/activity/skinCarnival/story_cap_bg_name.png'),
    SKIN_NAME_LINE         = _res('ui/home/activity/skinCarnival/story_cap_line_name.png'),
    REWARD_BG              = _res('ui/home/activity/skinCarnival/story_cinderella_bg_box.png'),
    REWARD_GOODS_BG        = _res('ui/home/activity/skinCarnival/story_cinderella_bg_box_fire.png'),
    REWARD_PROGRESS_BG     = _res('ui/home/activity/skinCarnival/story_cinderella_line_box_bg.png'),
    REWARD_PROGRESS_BAR    = _res('ui/home/activity/skinCarnival/story_cinderella_line_box.png'),
    REWARD_PROGRESS_TOP    = _res('ui/home/activity/skinCarnival/story_cinderella_line_box_top.png'),
    UNFINISHED_CELL_BG     = _res('ui/home/activity/skinCarnival/story_cinderella_bg_list.png'),
    FINISHED_CELL_BG       = _res('ui/home/activity/skinCarnival/story_cinderella_bg_gray.png'),
    FINISHED_CELL_TICK     = _res('ui/home/activity/skinCarnival/story_cinderella_ico_completed.png'),
    LIST_BOTTOM_LINE       = _res('ui/home/activity/skinCarnival/story_cinderella_line_renwu.png'),
    SKIN_GET_BG            = _res('ui/home/activity/skinCarnival/story_cap_bg_buy_get.png'),
    SKIN_GET_TEXT_BG       = _res('ui/home/activity/skinCarnival/story_cap_bg_get_name.png'),
    BUY_BTN_LINE           = _res('ui/home/activity/skinCarnival/story_common_line_buy.png'),
    REMIND_ICON            = _res('ui/common/common_hint_circle_red_ico.png'),
    COMPLETION_TITLE_BG    = _res('ui/home/activity/skinCarnival/story_cinderella_bg_get.png'),

}
function ActivitySkinCarnivalTaskView:ctor( ... )
    local args = unpack({...})
    self.theme = checkint(args.group)
    self:InitUI()
end
--[[
init ui
--]]
function ActivitySkinCarnivalTaskView:InitUI()
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- 标题
        local titleBtn = display.newButton(-10, size.height - 20, {n = RES_DICT.TITLE_BG, ap = display.LEFT_TOP})
        view:addChild(titleBtn, 5)
        local titleLabel = display.newLabel(titleBtn:getContentSize().width / 2 - 20, titleBtn:getContentSize().height / 2, {text = '', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outlineSize = 1, outline = '#622A37'})
        titleBtn:addChild(titleLabel, 1)
        local tipsIcon = display.newImageView(RES_DICT.TIPS_ICON, titleBtn:getContentSize().width - 50, titleBtn:getContentSize().height / 2)
        titleBtn:addChild(tipsIcon, 3)
        -- spine切换按钮
        local switchBtn = display.newButton(60, size.height - 155, {n = RES_DICT.SWITCH_BTN})
        view:addChild(switchBtn, 5)
        -- 剧情按钮
        local storyBtn = display.newButton(60, size.height - 255, {n = RES_DICT.STORY_BTN})
        storyBtn:setVisible(false)
        view:addChild(storyBtn, 5)
        local storyBtnLockMask = display.newImageView(RES_DICT.STORY_BTN_LOCK_MASK, storyBtn:getContentSize().width / 2, storyBtn:getContentSize().height / 2)
        storyBtn:addChild(storyBtnLockMask, 1)
        local storyBtnLock = display.newImageView(RES_DICT.STORY_BTN_LOCK, storyBtnLockMask:getContentSize().width / 2, storyBtnLockMask:getContentSize().height / 2)
        storyBtnLockMask:addChild(storyBtnLock, 1)
        -- 原价购买按钮
        local buyBtn = display.newButton(-10, 35, {n = RES_DICT.BUY_BTN, ap = display.LEFT_BOTTOM})
        buyBtn:setVisible(false)
        view:addChild(buyBtn, 5) 
        local buyBtnLabel = display.newLabel(buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2 + 15, {text = __('原价购买'), fontSize = 22, color = '#784821', ttf = true, font = TTF_GAME_FONT})
        buyBtn:addChild(buyBtnLabel, 1)
        local buyBtnLine = display.newImageView(RES_DICT.BUY_BTN_LINE, buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2)
        buyBtn:addChild(buyBtnLine, 1)
        local buyBtnConsumeRichLabel = display.newRichLabel(buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2 - 15)
        buyBtn:addChild(buyBtnConsumeRichLabel, 1)
        -- 皮肤(不用cardskinDrawNode了，改为切好的图片)
        -- local cardSkinDrawNode = require( "common.CardSkinDrawNode" ).new({confId = CardUtils.DEFAULT_CARD_ID, coordinateType = COORDINATE_TYPE_CAPSULE})
        -- cardSkinDrawNode:setScale(0.7)
        -- cardSkinDrawNode:setPosition(0, 150)
        -- cardSkinDrawNode:setVisible(false)
        -- view:addChild(cardSkinDrawNode, 3)
        local cardSkinDrawNode = display.newImageView('empty', 0, 45, {ap = display.LEFT_BOTTOM})
        view:addChild(cardSkinDrawNode, 3)
        -- 皮肤名称
        local skinNameBg = display.newImageView(RES_DICT.SKIN_NAME_BG, 290, 180)
        skinNameBg:setCascadeOpacityEnabled(true)
        view:addChild(skinNameBg, 5)
        local skinNameLine = display.newImageView(RES_DICT.SKIN_NAME_LINE, skinNameBg:getContentSize().width / 2, skinNameBg:getContentSize().height / 2)
        skinNameBg:addChild(skinNameLine, 1)
        local skinDescrLabel = display.newLabel(skinNameBg:getContentSize().width / 2, skinNameBg:getContentSize().height - 30, {text = '', fontSize = 22, color = '#FFB85D', ttf = true, font = TTF_GAME_FONT, outline = '#56120D', outlineSize = 1})
        skinNameBg:addChild(skinDescrLabel, 1)
        local skinNameLabel = display.newLabel(skinNameBg:getContentSize().width / 2, 30, {text = '', fontSize = 22, color = '#FFEF82', ttf = true, font = TTF_GAME_FONT, outline = '#56120D', outlineSize = 1})
        skinNameBg:addChild(skinNameLabel, 1)

        -- rewardLayout -- 
        local rewardLayoutSize = cc.size(600, 150)
        local rewardLayout = CLayout:create(rewardLayoutSize)
        display.commonUIParams(rewardLayout, {ap = display.RIGHT_TOP, po = cc.p(size.width - 50, size.height - 38)})
        view:addChild(rewardLayout, 1)
        rewardLayout:setVisible(false)
        -- 背景
        local rewardLayoutBg = display.newImageView(RES_DICT.REWARD_BG, rewardLayoutSize.width / 2, rewardLayoutSize.height / 2)
        rewardLayout:addChild(rewardLayoutBg, 1)
        local rewardLayoutGoodsBg = display.newImageView(RES_DICT.REWARD_GOODS_BG, rewardLayoutSize.width - 80, rewardLayoutSize.height / 2 + 15)
        rewardLayout:addChild(rewardLayoutGoodsBg, 2)
        -- 描述
        local rewardDescrLabel = display.newLabel(50, rewardLayoutSize.height - 60, {text = '', fontSize = 22, color = '#ffffff', ap = display.LEFT_CENTER})
        rewardLayout:addChild(rewardDescrLabel, 1)
        -- 进度条
        local rewardProgressBar = CProgressBar:create(RES_DICT.REWARD_PROGRESS_BAR)
        rewardProgressBar:setBackgroundImage(RES_DICT.REWARD_PROGRESS_BG)
        rewardProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        rewardProgressBar:setPosition(rewardLayoutSize.width / 2 - 25, 52)
        rewardLayout:addChild(rewardProgressBar, 3)
        local rewardPorgressTop = display.newImageView(RES_DICT.REWARD_PROGRESS_TOP, rewardLayoutSize.width / 2 - 25, 52)
        rewardLayout:addChild(rewardPorgressTop, 4)
        local rewardProgressBarLabel = display.newLabel(rewardLayoutSize.width / 2 - 25, 52, {text = '', fontSize = 22, color = '#61291E'})
        rewardLayout:addChild(rewardProgressBarLabel, 5)
        local rewardGoodsNode = require('common.GoodNode').new({
			id = GOLD_ID,
			callBack = function () end
        })
        display.commonUIParams(rewardGoodsNode, {po = cc.p(rewardLayoutSize.width - 70, rewardLayoutSize.height / 2)})
        rewardGoodsNode:setScale(0.8)
        rewardGoodsNode:setVisible(false)
        rewardLayout:addChild(rewardGoodsNode, 5)
        local rewardRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, rewardGoodsNode:getContentSize().width - 3, rewardGoodsNode:getContentSize().height - 3)
        rewardRemindIcon:setVisible(false)
        rewardGoodsNode:addChild(rewardRemindIcon, 10)
        -- rewardLayout -- 
        
        -- completionLayout -- 
        local completionLayoutSize = cc.size(600, 150)
        local completionLayout = CLayout:create(completionLayoutSize)
        display.commonUIParams(completionLayout, {ap = display.RIGHT_TOP, po = cc.p(size.width - 50, size.height - 38)})
        view:addChild(completionLayout, 1)
        completionLayout:setVisible(false)
        -- 背景
        local completionLayoutBg = display.newImageView(RES_DICT.REWARD_BG, completionLayoutSize.width / 2, completionLayoutSize.height / 2)
        completionLayout:addChild(completionLayoutBg, 1)
        -- 标题
        local completionTitleBg = display.newImageView(RES_DICT.COMPLETION_TITLE_BG, completionLayoutSize.width / 2, completionLayoutSize.height / 2)
        completionLayout:addChild(completionTitleBg, 1)
        local completionTitleLabel = display.newLabel(completionLayoutSize.width / 2, completionLayoutSize.height / 2, {text = __('任务已完成'), color = '#5F1729', fontSize = 22})
        completionLayout:addChild(completionTitleLabel, 1)
        -- completionLayout -- 

        -- taskListView
        local taskListViewBg = display.newImageView('empty', size.width, 20, {ap = display.RIGHT_BOTTOM})
        view:addChild(taskListViewBg, 3)
        local taskListSize = cc.size(570, 470)
        local taskListView = CListView:create(taskListSize)
        taskListView:setPosition(cc.p(size.width - 55, 80))
        taskListView:setDirection(eScrollViewDirectionVertical)
        taskListView:setAnchorPoint(display.RIGHT_BOTTOM)
        view:addChild(taskListView, 5)
        -- 已获得提示
        local skinGetBg = display.newImageView(RES_DICT.SKIN_GET_BG, size.width - 335, size.height / 2 - 50)
        skinGetBg:setVisible(false)
        view:addChild(skinGetBg, 5)
        local skinGetTextBg = display.newImageView(RES_DICT.SKIN_GET_TEXT_BG, skinGetBg:getContentSize().width / 2, skinGetBg:getContentSize().height / 2 - 26)
        skinGetBg:addChild(skinGetTextBg, 1)
        local skinGetTextLabel = display.newLabel(skinGetTextBg:getContentSize().width / 2, skinGetTextBg:getContentSize().height / 2, {text = __('当前外观已获得'), fontSize = 24, color = '#F8E2C3', ttf = true, font = TTF_GAME_FONT})
        skinGetTextBg:addChild(skinGetTextLabel, 1)
        -- bottomLine
        local bottomLine = display.newImageView(RES_DICT.LIST_BOTTOM_LINE, size.width - 54, 75, {ap = display.RIGHT_BOTTOM})
        view:addChild(bottomLine, 5)
        return {
            view                   = view,
            titleLabel             = titleLabel,
            titleBtn               = titleBtn,
            switchBtn              = switchBtn,
            storyBtn               = storyBtn,
            storyBtnLockMask       = storyBtnLockMask,
            buyBtn                 = buyBtn,
            buyBtnConsumeRichLabel = buyBtnConsumeRichLabel,
            cardSkinDrawNode       = cardSkinDrawNode,
            skinDescrLabel         = skinDescrLabel,
            skinNameLabel          = skinNameLabel,
            skinNameBg             = skinNameBg,
            taskListSize           = taskListSize,
            taskListView           = taskListView,
            rewardGoodsNode        = rewardGoodsNode,
            rewardProgressBar      = rewardProgressBar,
            rewardProgressBarLabel = rewardProgressBarLabel,
            rewardDescrLabel       = rewardDescrLabel,
            skinGetBg              = skinGetBg,  
            taskListViewBg         = taskListViewBg,
            rewardRemindIcon       = rewardRemindIcon,
            bottomLine             = bottomLine, 
            completionLayout       = completionLayout,
            rewardLayout           = rewardLayout,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    -- 装饰品
    if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
        -- 装饰品
        local bgOrnamentL = display.newImageView(RES_DICT.BG_ORNAMENT_L, display.cx - 700, display.cy + 700, {ap = display.CENTER_TOP})
        self:addChild(bgOrnamentL, -1)
        self.bgOrnamentL = bgOrnamentL
        local bgOrnamentR = display.newImageView(RES_DICT.BG_ORNAMENT_R, display.cx + 640, display.cy + 700, {ap = display.CENTER_TOP})
        self:addChild(bgOrnamentR, -1)
        self.bgOrnamentR = bgOrnamentR
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.view:setOpacity(0)
    end, __G__TRACKBACK__)
end
--[[
进入动画
@params pos pos 动画起始坐标
--]]
function ActivitySkinCarnivalTaskView:EnterAction( pos )
    local viewData = self:GetViewData()
    viewData.view:setPosition(pos)
    viewData.view:setScale(0)
    local spawnAct = {
        cc.FadeIn:create(0.2),
        cc.MoveTo:create(0.2, display.center),
        cc.ScaleTo:create(0.2, 1)
    }
    if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentL, cc.EaseBackOut:create(cc.MoveBy:create(0.2, cc.p(0, - 200)))))
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentR, cc.EaseBackOut:create(cc.MoveBy:create(0.2, cc.p(0, - 200)))))
    end
    viewData.view:runAction(
        cc.Sequence:create(
            cc.Spawn:create(spawnAct),
            cc.CallFunc:create(function()
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
end
--[[
返回动画
--]]
function ActivitySkinCarnivalTaskView:BackAction( pos )
    local viewData = self:GetViewData()
    -- 屏蔽所有点击事件
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local spawnAct = {
        cc.FadeOut:create(0.2),
        cc.MoveTo:create(0.2, pos),
        cc.ScaleTo:create(0.2, 0)
    }
    if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentL, cc.EaseBackIn:create(cc.MoveBy:create(0.2, cc.p(0, 200)))))
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentR, cc.EaseBackIn:create(cc.MoveBy:create(0.2, cc.p(0, 200)))))
    end
    viewData.view:runAction(
        cc.Sequence:create(
            cc.Spawn:create(spawnAct),
            cc.CallFunc:create(function()
                app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_BACK_HOME)
                app:UnRegsitMediator('activity.skinCarnival.ActivitySkinCarnivalTaskMediator')
            end)
        )
    )
end
--[[
刷新标题
@params title string 标题
--]]
function ActivitySkinCarnivalTaskView:RefreshTitle( title )
    local viewData = self:GetViewData()
    viewData.titleLabel:setString(tostring(title))
end
--[[
刷新皮肤购买消耗
@params consume map {
    goodsId int 道具id
    num     int 数量
}
--]]
function ActivitySkinCarnivalTaskView:RefreshBuyBtnConsumeRichlabel( consume )
    local viewData = self:GetViewData()
    display.reloadRichLabel(viewData.buyBtnConsumeRichLabel, {c = {
        {text = consume.num, fontSize = 22, color = '#FFEF82', ttf = true, font = TTF_GAME_FONT, outline = '#56120D', outlineSize = 2},
        {img = CommonUtils.GetGoodsIconPathById(consume.goodsId), scale = 0.18},
    }})
    CommonUtils.AddRichLabelTraceEffect(viewData.buyBtnConsumeRichLabel, '#56120D', 2, {1})
end
--[[
刷新皮肤节点
@params skinId int 皮肤id
@params effect string 皮肤spine特效
--]]
function ActivitySkinCarnivalTaskView:RefreshSkinDrawNode( skinId, effect )
    local viewData = self:GetViewData()
    -- viewData.cardSkinDrawNode:RefreshAvatar({skinId = skinId})
    -- viewData.cardSkinDrawNode:setVisible(true)
    viewData.cardSkinDrawNode:setTexture(__(string.format('ui/home/activity/skinCarnival/skinImg/story_skin_%d.png', checkint(skinId))))
    if CardUtils.IsShowCardLive2d(skinId) then
        viewData.switchBtn:setNormalImage(RES_DICT.SWITCH_BTN_L2D)
        viewData.switchBtn:setSelectedImage(RES_DICT.SWITCH_BTN_L2D)
    else
        viewData.switchBtn:setNormalImage(RES_DICT.SWITCH_BTN)
        viewData.switchBtn:setSelectedImage(RES_DICT.SWITCH_BTN)
    end
    local skinConfig = CardUtils.GetCardSkinConfig(skinId)
    local cardConfig = CardUtils.GetCardConfig(skinConfig.cardId)
    viewData.skinDescrLabel:setString(string.fmt(__('_name_外观'), {['_name_'] = cardConfig.name}))
    viewData.skinNameLabel:setString(skinConfig.name)
    -- 判断是否需要添加皮肤特效spine
    if effect and effect ~= '' then
        if viewData.view:getChildByName('skinEffect') then
            viewData.view:getChildByName('skinEffect'):runAction(cc.RemoveSelf:create())
        end
        local skinEffectSpine = sp.SkeletonAnimation:create(
            string.format('ui/home/activity/skinCarnival/spineEffect/%s.json', effect),
            string.format('ui/home/activity/skinCarnival/spineEffect/%s.atlas', effect),
        1)
        skinEffectSpine:setAnimation(0, 'play', true)
        skinEffectSpine:setName('skinEffect')
        skinEffectSpine:setPosition(cc.p(280, 320))
        viewData.view:addChild(skinEffectSpine, 3)
    end
    -- 刷新列表背景
    local bgSkinId = skinId
    if not utils.isExistent(__(string.format('ui/home/activity/skinCarnival/listBg/story_list_bg_%d.png', checkint(bgSkinId)))) then
        bgSkinId = 251724
    end
    viewData.taskListViewBg:setTexture(__(string.format('ui/home/activity/skinCarnival/listBg/story_list_bg_%d.png', checkint(bgSkinId))))
end
--[[
刷新按钮状态
@params hasSkin bool 是否拥有皮肤
@params canDraw bool 任务奖励是否可领取
@params skinId  int  皮肤Id
--]]
function ActivitySkinCarnivalTaskView:RefreshBtnState( hasSkin, canDraw, skinId )
    local viewData = self:GetViewData()
    viewData.storyBtn:setVisible(true)
    if hasSkin then
        viewData.storyBtnLockMask:setVisible(false)
        viewData.buyBtn:setVisible(false)
        viewData.skinGetBg:setVisible(true)
        viewData.taskListView:setVisible(false)
        viewData.bottomLine:setVisible(false)
        viewData.rewardLayout:setVisible(false)
        viewData.completionLayout:setVisible(true)
        return 
    end
    viewData.storyBtnLockMask:setVisible(true)
    viewData.buyBtn:setVisible(true)
    viewData.skinGetBg:setVisible(false)
    viewData.taskListView:setVisible(true)
    viewData.bottomLine:setVisible(true)
    viewData.rewardLayout:setVisible(true)
    viewData.completionLayout:setVisible(false)
    if canDraw then
        viewData.rewardGoodsNode:RefreshSelf({goodsId = skinId, highlight = 1})
    else
        viewData.rewardGoodsNode:RefreshSelf({goodsId = skinId})
    end
end
--[[
刷新奖励layout
@params completionNum int 任务完成个数
@params targetNum     int 任务目标个数
@params skinId        int 皮肤id
--]]
function ActivitySkinCarnivalTaskView:RefreshRewardLayout( completionNum, targetNum, skinId )
    local viewData = self:GetViewData()
    viewData.rewardProgressBar:setMaxValue(checkint(targetNum))
    viewData.rewardProgressBar:setValue(checkint(completionNum))
    viewData.rewardProgressBarLabel:setString(string.format('%d/%d', math.min(completionNum, targetNum), targetNum))
    viewData.rewardGoodsNode:setVisible(true)
    viewData.rewardGoodsNode:RefreshSelf({goodsId = skinId})
    local skinConfig = CardUtils.GetCardSkinConfig(skinId)
    display.commonLabelParams(viewData.rewardDescrLabel , {
        text = string.fmt(__('完成所有任务可获得_name_外观'), {['_name_'] = skinConfig.name}),
        w = 400 ,hAlign = display.TAL
    })
    viewData.rewardDescrLabel:setString(string.fmt(__('完成所有任务可获得_name_外观'), {['_name_'] = skinConfig.name}))
end
--[[
刷新任务列表
@params taskData map {
    progress  int    任务完成进度
    targetNum int    任务目标
    descr     string 任务描述
    name      string 任务名称
    taskType  int    任务类型
}
--]]
function ActivitySkinCarnivalTaskView:RefreshTaskListView( taskData )
    local viewData = self:GetViewData()
    viewData.taskListView:removeAllNodes()
    for i, v in ipairs(checktable(taskData)) do
        local cell = nil
        if checkint(v.progress) >= checkint(v.targetNum) then
            -- 任务完成
            cell = self:CreateFinishedCell(v)
        else
            -- 任务未完成
            cell = self:CreateUnfinishedCell(v)
        end
        viewData.taskListView:insertNodeAtLast(cell)
    end
    viewData.taskListView:reloadData()
end
--[[
刷新奖励小红点
@params state bool 
--]]
function ActivitySkinCarnivalTaskView:RefreshRewardRemindIcon( state )
    local viewData = self:GetViewData()
    viewData.rewardRemindIcon:setVisible(state)
end
--[[
展示卡牌皮肤
--]]
function ActivitySkinCarnivalTaskView:ShowCardSkin()
    local viewData = self:GetViewData()
    viewData.cardSkinDrawNode:setVisible(true)
end
--[[
创建进度未完成的cell
--]]
function ActivitySkinCarnivalTaskView:CreateUnfinishedCell( taskData )
    local viewData = self:GetViewData()
    local size = cc.size(viewData.taskListSize.width, 106)
    local layout = CLayout:create(size)
    -- 背景
    local bg = display.newImageView(RES_DICT.UNFINISHED_CELL_BG, size.width / 2, size.height / 2)
    layout:addChild(bg, 1)
    -- 名称
    -- local nameLabel = display.newLabel(40, size.height - 30, {text = taskData.name, fontSize = 20, color = '#76553b', ap = display.LEFT_CENTER})
    -- layout:addChild(nameLabel, 3)
    -- 描述
    local descr = string.split(taskData.descr, '_target_num_')
    local descrRichLabel = display.newRichLabel(40, size.height / 2, {ap = display.LEFT_CENTER })
    display.reloadRichLabel(descrRichLabel, {width = 400, c = {
        {text = descr[1], fontSize = 20, color = '#76553b'},
        {text = tostring(taskData.targetNum), fontSize = 20, color = '#d23d3d'},
        {text = descr[2], fontSize = 20, color = '#76553b'},
    }})
    layout:addChild(descrRichLabel, 3)
    -- 进度
    local progressLabel = display.newRichLabel(size.width - 40, size.height / 2, {r = true, ap = display.RIGHT_CENTER, c = {
        {text = tostring(taskData.progress), fontSize = 20, color = '#d23d3d'},
        {text = string.format('/%s', tostring(taskData.targetNum)), fontSize = 20, color = '#76553b'},
    }})
    layout:addChild(progressLabel, 3)
    return layout
end
--[[
创建进度已完成的cell
--]]
function ActivitySkinCarnivalTaskView:CreateFinishedCell( taskData )
    local viewData = self:GetViewData()
    local size = cc.size(viewData.taskListSize.width, 74)
    local layout = CLayout:create(size)
    -- 背景
    local bg = display.newImageView(RES_DICT.FINISHED_CELL_BG, size.width / 2, size.height / 2)
    layout:addChild(bg, 1)
    -- 描述
    local descr = string.split(taskData.descr, '_target_num_')
    local descrRichLabel = display.newRichLabel(40, size.height / 2, {ap = display.LEFT_CENTER })
    display.reloadRichLabel(descrRichLabel, { width = 400, c = {
        {text = descr[1], fontSize = 20, color = '#76553b'},
        {text = tostring(taskData.targetNum), fontSize = 20, color = '#d23d3d'},
        {text = descr[2], fontSize = 20, color = '#76553b'},
    }})

    layout:addChild(descrRichLabel, 3)
    -- 获取标识
    local tickIcon = display.newImageView(RES_DICT.FINISHED_CELL_TICK, size.width - 70, size.height / 2)
    layout:addChild(tickIcon, 3)
    return layout
end
--[[
获取viewData
--]]
function ActivitySkinCarnivalTaskView:GetViewData()
    return self.viewData
end
return ActivitySkinCarnivalTaskView