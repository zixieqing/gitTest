--[[
 * author : liuzhipeng
 * descpt : 活动 连续活跃活动 view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityContinousActiveView = class('ActivityContinousActiveView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.continuousActive.ActivityContinousActiveView'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    BG_TOP                       = _res('ui/home/activity/continuousActive/activeness_bg_top_bar.png'), 
    TIPS_BTN                     = _res('ui/common/common_btn_tips.png'),
    ACTIVE_LABEL_BG              = _res('ui/home/activity/continuousActive/activeness_bg_title_day.png'),
    SUPPLEMENT_BTN               = _res('ui/home/activity/continuousActive/activeness_btn_patch.png'),
    PROGRESS_BG                  = _res('ui/home/activity/continuousActive/activeness_bg_progress.png'),
    PROGRESS_CONTINUOUS          = _res('ui/home/activity/continuousActive/activeness_img_progress_2.png'),
    PROGRESS_SUPPLEMENT          = _res('ui/home/activity/continuousActive/activeness_img_progress.png'),
    REWARD_BG                    = _res('ui/home/activity/continuousActive/activeness_bg_total_prize.png'),
    WEEKLY_BG                    = _res('ui/home/activity/continuousActive/activeness_bg_week.png'),
    WEEKLY_LINE                  = _res('ui/home/activity/continuousActive/activeness_bg_week_line.png'),
    WEEKLY_REWAWD_BG             = _res('ui/home/activity/continuousActive/activeness_bg_week_prize.png'),
    WEEKLY_TIPS_BG               = _res('ui/home/activity/continuousActive/activeness_bg_week_tips.png'),
    COMMON_BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_DISABLE           = _res('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_DRAWN             = _res('ui/common/common_btn_check_selected.png'),
    COMMON_BTN_DIRECT            = _res('ui/common/common_btn_direct_s.png'),
    COMMON_BTN_DIRECT_BG         = _res('ui/common/common_bg_direct_s.png'),
    PRIZE_GOODS_BG               = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg.png'),
    PRIZE_GOODS_BG_LIGHT         = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg_light.png'),
}
function ActivityContinousActiveView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityContinousActiveView:InitUI()
    local CreateView = function (size)
        local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        -- 背景
        local bg = display.newImageView(RES_DICT.BG_TOP, size.width / 2, size.height - 5, {ap = display.CENTER_TOP})
        view:addChild(bg, 1)
        -- 标题
        local dailyTitleLabel = display.newLabel(20, size.height - 20, {text = __('长期活跃'), fontSize = 30, color = '#4e4e4e', ap = display.LEFT_CENTER, ttf = true, font = TTF_GAME_FONT})
        view:addChild(dailyTitleLabel, 5)
        local dailyDescrLabel = display.newLabel(20, size.height - 60, fontWithColor(5, {text = __('保持连续活跃可领取以下奖励，每档奖励仅可领取一次。'), w = 800 , hAlign = display.TAL ,  ap = display.LEFT_CENTER}))
        view:addChild(dailyDescrLabel, 5)
        local tipsBtn = display.newButton(display.getLabelContentSize(dailyTitleLabel).width + 50, size.height - 20, {n = RES_DICT.TIPS_BTN})
        view:addChild(tipsBtn, 5)
        -- 活跃天数
        local activeDaysLabel = display.newLabel(size.width - 135, size.height - 25, {text = __('连续活跃天数'), fontSize = 20, color = '#ffffff', ap = display.RIGHT_CENTER})
        view:addChild(activeDaysLabel, 5)
        local activeBg = display.newImageView(RES_DICT.ACTIVE_LABEL_BG, size.width - 120, size.height - 25, {ap = display.RIGHT_CENTER, scale9 = true, size = cc.size(display.getLabelContentSize(activeDaysLabel).width + 30, 27)})
        view:addChild(activeBg, 3)
        local activeDaysNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 0)
        activeDaysNum:setAnchorPoint(display.RIGHT_BOTTOM)
        activeDaysNum:setHorizontalAlignment(display.TAR)
        activeDaysNum:setPosition(size.width - 170, size.height - 83)
        view:addChild(activeDaysNum, 5)
        local targetDaysLabel = display.newLabel(size.width - 122, size.height - 80, fontWithColor(5, {text = '/365', ap = display.RIGHT_BOTTOM}))
        view:addChild(targetDaysLabel, 5)
        local supplementProgressBar = CProgressBar:create(RES_DICT.PROGRESS_SUPPLEMENT)
        supplementProgressBar:setBackgroundImage(RES_DICT.PROGRESS_BG)
        supplementProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        supplementProgressBar:setPosition(cc.p(15, size.height - 95))
        supplementProgressBar:setAnchorPoint(display.LEFT_CENTER)
        view:addChild(supplementProgressBar, 3)
        local continuousProgressBar = CProgressBar:create(RES_DICT.PROGRESS_CONTINUOUS)
        continuousProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        continuousProgressBar:setPosition(cc.p(15, size.height - 95))
        continuousProgressBar:setAnchorPoint(display.LEFT_CENTER)
        view:addChild(continuousProgressBar, 5)
        -- 补签
        local supplementBtn = display.newButton(size.width - 60, size.height - 58, {n = RES_DICT.SUPPLEMENT_BTN})
        view:addChild(supplementBtn, 5)
        display.commonLabelParams(supplementBtn, fontWithColor(5, {text = __('补签'), reqW  = 90 ,  offset = cc.p(0.5, -30)}))
        -- 奖励Layout -- 
        local rewardsLayoutSize = cc.size(size.width, 220)
        local rewardsLayout = CLayout:create(rewardsLayoutSize)
        rewardsLayout:setPosition(cc.p(size.width / 2, size.height - 220))
        view:addChild(rewardsLayout, 5)
        local rewardsLayoutBg = display.newImageView(RES_DICT.REWARD_BG, rewardsLayoutSize.width / 2, rewardsLayoutSize.height - 2, {ap = display.CENTER_TOP})
        rewardsLayout:addChild(rewardsLayoutBg, 1)
        local rewardNodeList = {}
        for i = 1, 5 do 
            local rewardNode = require('Game.views.activity.continuousActive.ActivityContinuousActiveRewardNode').new()
            rewardNode:setPosition(cc.p(- 90 + i * 200, rewardsLayoutSize.height / 2 + 8))
            rewardsLayout:addChild(rewardNode, 1)
            table.insert(rewardNodeList, rewardNode)
        end
        -- 每周活跃Layout --
        local weeklyLayoutSize = cc.size(size.width, 300)
        local weeklyLayout = CLayout:create(weeklyLayoutSize)
        weeklyLayout:setPosition(cc.p(size.width / 2, 0))
        weeklyLayout:setAnchorPoint(display.CENTER_BOTTOM)
        view:addChild(weeklyLayout, 5)
        local weeklyBg = display.newImageView(RES_DICT.WEEKLY_BG, weeklyLayoutSize.width / 2, weeklyLayoutSize.height, {ap = display.CENTER_TOP})
        weeklyLayout:addChild(weeklyBg, 1)
        local weeklyTitleLabel = display.newLabel(24, weeklyLayoutSize.height - 22, {text = __('周活跃'), fontSize = 36, color = '#4e4e4e', ap = display.LEFT_CENTER, ttf = true, font = TTF_GAME_FONT})
        weeklyLayout:addChild(weeklyTitleLabel, 5)
        local weeklyDescrLabel = display.newLabel(24, weeklyLayoutSize.height - 55, fontWithColor(5, {text = __('每天日常任务达到100活跃即可激活当天活跃状态'), ap = display.LEFT_CENTER}))
        weeklyLayout:addChild(weeklyDescrLabel, 5)
        local weeklyLine = display.newImageView(RES_DICT.WEEKLY_LINE, -265, -140, {ap = display.LEFT_BOTTOM})
        weeklyLayout:addChild(weeklyLine, 5)
        -- 周奖励
        local weeklyRewardBg = display.newImageView(RES_DICT.WEEKLY_REWAWD_BG, weeklyLayoutSize.width - 20, weeklyLayoutSize.height + 5, {ap = display.RIGHT_TOP})
        weeklyLayout:addChild(weeklyRewardBg, 3)
        local weeklyRewardTitleLabel = display.newLabel(weeklyRewardBg:getContentSize().width / 2, weeklyRewardBg:getContentSize().height - 30, {text = __('周奖励'), fontSize = 26,reqW = 140 ,  color = '#ffcf3d'})
        weeklyRewardBg:addChild(weeklyRewardTitleLabel, 1)
        local weeklyTipsLabel = display.newLabel(0, 0, {text = __('连续一周保持活跃可领取'), fontSize = 20, color = '#ffffff', ap = display.RIGHT_CENTER})
        local weeklyTipsBg = display.newImageView(RES_DICT.WEEKLY_TIPS_BG, weeklyLayoutSize.width - 170, weeklyLayoutSize.height - 20, {ap = display.RIGHT_CENTER, size = cc.size(40 + display.getLabelContentSize(weeklyTipsLabel).width, 44), capInsets = cc.rect(40, 10, 217, 24)})
        weeklyLayout:addChild(weeklyTipsBg, 5)
        weeklyTipsBg:addChild(weeklyTipsLabel, 1)
        display.commonUIParams(weeklyTipsLabel, {ap = display.RIGHT_CENTER, po = cc.p(weeklyTipsBg:getContentSize().width - 30, weeklyTipsBg:getContentSize().height / 2)})

        local rewardGoodsBg = display.newImageView(RES_DICT.PRIZE_GOODS_BG, weeklyLayoutSize.width - 103, weeklyLayoutSize.height - 122)
        weeklyLayout:addChild(rewardGoodsBg, 3)
        local rewardGoodsBgLight = display.newImageView(RES_DICT.PRIZE_GOODS_BG_LIGHT, weeklyLayoutSize.width - 103, weeklyLayoutSize.height - 122)
        weeklyLayout:addChild(rewardGoodsBgLight, 4)
        rewardGoodsBgLight:runAction(
            cc.RepeatForever:create(
                cc.RotateBy:create(10, 180)
            )
        )
        local rewardGoodsBtn = display.newButton(weeklyLayoutSize.width - 103, weeklyLayoutSize.height - 122, {n = CommonUtils.GetGoodsIconPathById(195136), cb = handler(self, self.WeeklyGoodsBtnCallback)})
        weeklyLayout:addChild(rewardGoodsBtn, 5)

        -- 每周奖励领取按钮
        local weeklyDrawBtn = display.newButton(weeklyLayoutSize.width - 103, weeklyLayoutSize.height - 240, {n = RES_DICT.COMMON_BTN_ORANGE})
        weeklyLayout:addChild(weeklyDrawBtn, 5)
        display.commonLabelParams(weeklyDrawBtn, fontWithColor(14, {text = __('领取')}))
        local switchBtnBg = display.newImageView(RES_DICT.COMMON_BTN_DIRECT_BG, 70, 140)
        switchBtnBg:setScaleX(-1)
        weeklyLayout:addChild(switchBtnBg, 3)
        -- 切换按钮
        local weeklySwitchBtn = display.newButton(70, 140, {n = RES_DICT.COMMON_BTN_DIRECT})
        weeklySwitchBtn:setScaleX(-1)
        weeklyLayout:addChild(weeklySwitchBtn, 5)
        local switchLabel = display.newLabel(80, 65, fontWithColor(4, {text = ''}))
        weeklyLayout:addChild(switchLabel, 5)
        local weeklyNodeList = {}
        for i = 1, 7 do
            local rewardNode = require('Game.views.activity.continuousActive.ActivityContinuousActiveWeeklyNode').new()
            rewardNode:setPosition(cc.p(85 + i * 100, 120))
            weeklyLayout:addChild(rewardNode, 1)
            table.insert(weeklyNodeList, rewardNode)
        end
        return {
            view                    = view,
            tipsBtn                 = tipsBtn,
            activeDaysNum           = activeDaysNum,
            supplementProgressBar   = supplementProgressBar,
            continuousProgressBar   = continuousProgressBar,
            supplementBtn           = supplementBtn,
            rewardsLayout           = rewardsLayout,
            weeklyLayout            = weeklyLayout,
            rewardGoodsBtn          = rewardGoodsBtn,
            weeklyDrawBtn           = weeklyDrawBtn,
            switchBtnBg             = switchBtnBg,
            weeklySwitchBtn         = weeklySwitchBtn,
            switchLabel             = switchLabel,
            rewardNodeList          = rewardNodeList,
            weeklyNodeList          = weeklyNodeList,
            targetDaysLabel         = targetDaysLabel,
        }
    end
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
刷新进度条
@params continuousDays int 连续签到天数
@params totalDays      int 总共可补签天数
@params maxDays        int 最大天数
--]]
function ActivityContinousActiveView:RefreshProgressBar( continuousDays, totalDays, maxDays )
    local viewData = self:GetViewData()
    viewData.continuousProgressBar:setMaxValue(maxDays)
    viewData.continuousProgressBar:setValue(continuousDays)
    viewData.supplementProgressBar:setMaxValue(maxDays)
    viewData.supplementProgressBar:setValue(totalDays)
    viewData.activeDaysNum:setString(continuousDays)
    viewData.targetDaysLabel:setString('/' .. maxDays)
end
--[[
刷新奖励layout
@params {
    yearRewards    list 奖励数据
    continuousDays int  已连续签到天数
    callback       function 领取按钮点击回调
}
--]]
function ActivityContinousActiveView:RefreshRewardsLayout( params )
    local viewData = self:GetViewData()
    for i, v in ipairs(checktable(params.yearRewards)) do
        if viewData.rewardNodeList[i] then
            local state = 1
            local showArrow = i < #checktable(params.yearRewards) and params.continuousDays >= checkint(v.day) or false
            if checkint(v.hasDrawn) == 1 then
                state = 1
            elseif params.continuousDays >= checkint(v.day) then
                state = 2
            else
                state = 3
                showArrow = false
            end
            local data = {
                rewards = v.rewards[1],
                callback = params.callback,
                state = state,
                day = checkint(v.day)
            }
            viewData.rewardNodeList[i]:RefreshNode(data)
        end
    end
end
--[[
刷新周奖励layout
@params {
    weeklyRewards  list 周奖励（标准奖励格式）
    weeklyProgress list 周签到进度
    isLastWeek     bool 是否为上周数据
    callback       function 领取按钮点击回调
    hasDrawn       bool 奖励是否领取
}
--]]
function ActivityContinousActiveView:RefreshWeeklyLayout( params )
    local viewData = self:GetViewData()
    local convertProgress = {}
    for i, v in ipairs(params.weeklyProgress) do
        convertProgress[tostring(v)] = v
    end
    local title = {
        __('周一'),
        __('周二'),
        __('周三'),
        __('周四'),
        __('周五'),
        __('周六'),
        __('周日'),
    }
    local data = {}
    if params.isLastWeek then
        -- 上周
        for i = 1, 7 do
            data[i] = {
                state = convertProgress[tostring(i)] and 1 or 2,
                callback = params.callback,
                title = title[i],
                tag = i,
            }
        end
        viewData.switchBtnBg:setScaleX(1)
        viewData.weeklySwitchBtn:setScaleX(1)
        viewData.switchLabel:setString(__('返回'))
    else
        -- 本周
        local date = os.date('!*t', getServerTime() + getServerTimezone())
        local wday = date.wday - 1
        if date.wday == 1 then
            wday = 7
        end
        for i = 1, 7 do
            if i < wday then
                data[i] = {
                    state = convertProgress[tostring(i)] and 1 or 2,
                    callback = params.callback,
                    title = title[i],
                    tag = i
                }
            elseif i == wday then
                data[i] = {
                    state = convertProgress[tostring(i)] and 1 or 3,
                    callback = params.callback,
                    title = __('今天'),
                    tag = i
                }
            else
                data[i] = {
                    state = 3,
                    callback = params.callback,
                    title = title[i],
                    tag = i
                }
            end
        end
        viewData.switchBtnBg:setScaleX(-1)
        viewData.weeklySwitchBtn:setScaleX(-1)
        --viewData.switchLabel:setString(__('上一周'))
        display.commonLabelParams(viewData.switchLabel , { text = __('上一周') , w = 100   })
    end
    for i, v in ipairs(data) do
        viewData.weeklyNodeList[i]:RefreshNode(v)
    end
    if params.weeklyRewards then
        viewData.rewardGoodsBtn:setNormalImage(CommonUtils.GetGoodsIconPathById(params.weeklyRewards[1].goodsId))
        viewData.rewardGoodsBtn:setSelectedImage(CommonUtils.GetGoodsIconPathById(params.weeklyRewards[1].goodsId))
        self.weeklyGoodsId = params.weeklyRewards[1].goodsId
    end
    if params.hasDrawn then
        viewData.weeklyDrawBtn:setEnabled(false)
        viewData.weeklyDrawBtn:setNormalImage(RES_DICT.COMMON_BTN_DRAWN)
        viewData.weeklyDrawBtn:setSelectedImage(RES_DICT.COMMON_BTN_DRAWN)
        display.commonLabelParams(viewData.weeklyDrawBtn, fontWithColor(14, {text = ''}))
    else
        if table.nums(convertProgress) >= 7 then
            viewData.weeklyDrawBtn:setEnabled(true)
            viewData.weeklyDrawBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE)
            viewData.weeklyDrawBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE)
            display.commonLabelParams(viewData.weeklyDrawBtn, fontWithColor(14, {text = __('领取')}))
        else
            viewData.weeklyDrawBtn:setEnabled(false)
            viewData.weeklyDrawBtn:setNormalImage(RES_DICT.COMMON_BTN_DISABLE)
            viewData.weeklyDrawBtn:setSelectedImage(RES_DICT.COMMON_BTN_DISABLE)
            display.commonLabelParams(viewData.weeklyDrawBtn, fontWithColor(14, {text = __('领取')}))
        end
    end
end
--[[
周奖励宝箱点击回调
--]]
function ActivityContinousActiveView:WeeklyGoodsBtnCallback( sender )
    if not self.weeklyGoodsId then return end
    PlayAudioByClickNormal()
    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = self.weeklyGoodsId, type = 1})
end
--[[
获取viewData
--]]
function ActivityContinousActiveView:GetViewData()
    return self.viewData
end
return ActivityContinousActiveView