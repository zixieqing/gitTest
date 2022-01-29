--[[
 * author : liuzhipeng
 * descpt : 活动 全能活动 路线node
--]]
local ActivityAllRoundPathNode = class('ActivityAllRoundPathNode', function ()
    local node = CLayout:create()
    node.name = 'ActivityAllRoundPathNode'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG_CIRCLE               = _res('ui/home/allround/allround_bg_circle.png'),
    ALLROUND_ICO_BOOK_1     = _res('ui/home/allround/allround_ico_book_1.png'),
    ALLROUND_ICO_BOOK_2     = _res('ui/home/allround/allround_ico_book_2.png'),
    ALLROUND_ICO_BOOK_3     = _res('ui/home/allround/allround_ico_book_3.png'),
    ALLROUND_ICO_BOOK_4     = _res('ui/home/allround/allround_ico_book_4.png'),
    NAME_LABEL_BG           = _res('ui/home/allround/allround_label_subtitle.png'),
    TICK_ICON               = _res('ui/common/raid_room_ico_ready.png'),
    PROGRESS_BAR_BG         = _res('ui/home/allround/allround_btn_path_name.png'),
    PROGRESS_BAR            = _res('ui/home/allround/allround_bg_bar_active.png'),
    PROGRESS_BAR_GREY       = _res('ui/home/allround/allround_bg_bar_grey.png'),
    COMMON_REWARD_LIGHT     = _res('ui/common/common_reward_light.png'),
    CHEST_TITLE_BG          = _res('ui/home/allround/allround_label_box.png'),
    CARD_SPINE_FRAME        = _res('ui/home/allround/allround_bg_frame_final.png'),
    CARD_INFO_BG            = _res('ui/artifact/card_weapon_base_s_bg.png'),
    CARD_NAME_BG            = _res('ui/artifact/card_weapon_label_name.png'),
    REMIND_ICON             = _res('ui/common/common_hint_circle_red_ico.png'),
    
}
local PATH_TYPE = {
    DAILY    = 1, -- 养成路线
    BATTLE   = 2, -- 战斗路线
    BUSINESS = 3, -- 经营模式
    PET      = 4, -- 堕神路线
}
local PATH_CONFIG = {
    [tostring(PATH_TYPE.DAILY)]    = {name = __('养成路线') , image = RES_DICT.ALLROUND_ICO_BOOK_4 ,pos = cc.p(display.cx + 407, display.cy + -148)},
    [tostring(PATH_TYPE.BATTLE)]   = {name = __('战斗路线') , image = RES_DICT.ALLROUND_ICO_BOOK_3 ,pos = cc.p(display.cx + 452, display.cy + 228)},
    [tostring(PATH_TYPE.BUSINESS)] = {name = __('经营路线') , image = RES_DICT.ALLROUND_ICO_BOOK_1 ,pos = cc.p(display.cx + -412, display.cy + 120)},
    [tostring(PATH_TYPE.PET)]      = {name = __('堕神路线') , image = RES_DICT.ALLROUND_ICO_BOOK_2 ,pos = cc.p(display.cx + -331, display.cy + -198)}
}
function ActivityAllRoundPathNode:ctor( params )
    self.pathData = params.pathData or {}
    self.activityId = params.activityId
    self.pathData.routeId = self.pathData.pathId
    self:InitUI()
end
--[[
init ui
--]]
function ActivityAllRoundPathNode:InitUI()
    local args = self.pathData
    local type = args.type
    local config = PATH_CONFIG[tostring(type)]
    local function CreatePathView()
        local size = cc.size(400, 270)
        local view = CLayout:create(size)
        -- 背景的圆圈
        local bgCircle = display.newImageView(RES_DICT.BG_CIRCLE, size.width / 2, size.height / 2)
        view:addChild(bgCircle, 1)
        bgCircle:runAction(
            cc.RepeatForever:create(
                cc.RotateBy:create(10, 180)
            )
        )
        -- 任务按钮
        local taskBtn = display.newButton(size.width / 2, size.height / 2, {n = config.image})
        view:addChild(taskBtn, 5)
        local taskRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, taskBtn:getContentSize().width - 10, taskBtn:getContentSize().height - 5)
        taskRemindIcon:setVisible(false)
        taskBtn:addChild(taskRemindIcon, 5)
        -- 名称
        local nameLabelBg = display.newImageView(RES_DICT.NAME_LABEL_BG, size.width / 2 - 10, 61)
        view:addChild(nameLabelBg, 5)
        local nameLabel = display.newLabel(size.width / 2 - 10, 61, fontWithColor(14, { ap = display.CENTER, color = '#ffffff', text = config.name, fontSize = 24, outline ="#5e0e0e", outlineSize = 2,  tag = 110 }))
        view:addChild(nameLabel, 5)
        -- 任务完成标记
        local tickIcon = display.newImageView(RES_DICT.TICK_ICON, size.width / 2 + 30, size.height / 2  - 25)
        view:addChild(tickIcon, 5)
        -- 任务进度条
        local taskProgressBarBg = display.newImageView(RES_DICT.PROGRESS_BAR_BG, size.width / 2, 40)
        view:addChild(taskProgressBarBg, 2)
        local taskProgressBar = CProgressBar:create(RES_DICT.PROGRESS_BAR)
        taskProgressBar:setBackgroundImage(RES_DICT.PROGRESS_BAR_GREY)
        taskProgressBar:setPosition(size.width / 2 - 10, 35)
        taskProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        view:addChild(taskProgressBar, 3)
        local taskProgressLabel = display.newLabel(size.width / 2 - 10, 35, {text = '', color = '#FFFFFF', fontSize = 20})
        view:addChild(taskProgressLabel, 5)
        -- 宝箱
        local chestLight = display.newImageView(RES_DICT.COMMON_REWARD_LIGHT, size.width / 2 + 135, 55)
        view:addChild(chestLight, 1)
        chestLight:setScale(0.6)
        chestLight:runAction(
            cc.RepeatForever:create(
                cc.RotateBy:create(10, 180)
            )
        )
        local chestRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, size.width / 2 + 180, 90)
        chestRemindIcon:setVisible(false)
        view:addChild(chestRemindIcon, 5)
        local chestImg = display.newImageView(self:GetChestImageByPathId(type), size.width / 2 + 135, 55)
        chestImg:setScale(0.8)
        view:addChild(chestImg, 3)
        local chestBtn = display.newButton(size.width / 2 + 135, 55, {n = 'empty', size = cc.size(140, 130)})
        view:addChild(chestBtn, 5)
        local chestTitleBg = display.newImageView(RES_DICT.CHEST_TITLE_BG, size.width / 2 + 135, 20)
        view:addChild(chestTitleBg, 5)
        local chestTitleLabel = display.newLabel(size.width / 2 + 135, 20, fontWithColor('14', { ap = display.CENTER, outline = '#5e0e0e', ttf = true, font = TTF_GAME_FONT, color = '#fbdd95', fontSize = 22, text = __('点击领取'), tag = 873 }) )
        view:addChild(chestTitleLabel, 5)

        return {
            view                = view,
            size                = size,
            bgCircle            = bgCircle,
            taskBtn             = taskBtn,
            tickIcon            = tickIcon,
            taskProgressBar     = taskProgressBar,
            taskProgressLabel   = taskProgressLabel,
            chestLight          = chestLight,
            chestImg            = chestImg,
            chestBtn            = chestBtn,
            chestTitleBg        = chestTitleBg,
            chestTitleLabel     = chestTitleLabel,
            taskRemindIcon      = taskRemindIcon,
            chestRemindIcon     = chestRemindIcon,
        }
    end
    local function CreateRewardsView()
        local size = cc.size(500, 500)
        local view = CLayout:create(size)
        -- 卡牌spine边框
        local cardSpineFrame = display.newImageView(RES_DICT.CARD_SPINE_FRAME, size.width / 2, size.height / 2 + 30)
        view:addChild(cardSpineFrame, 2)
        -- 领取按钮
        local drawBtn = display.newButton(size.width / 2, size.height / 2 + 30, {n = 'empty', size = cc.size(300, 300)})
        view:addChild(drawBtn, 1)
        -- 点击领取
        local chestTitleBg = display.newImageView(RES_DICT.CHEST_TITLE_BG, size.width / 2 , size.height / 2 - 95)
        view:addChild(chestTitleBg, 5)
        local chestTitleLabel = display.newLabel(chestTitleBg:getContentSize().width / 2, chestTitleBg:getContentSize().height / 2 + 5, fontWithColor('14', { ap = display.CENTER, outline = '#5e0e0e', ttf = true, font = TTF_GAME_FONT, color = '#fbdd95', fontSize = 22, text = __('点击领取'), tag = 873 }) )
        chestTitleBg:addChild(chestTitleLabel, 5)
        -- 卡牌信息背景
        local cardInfoBg = display.newImageView(RES_DICT.CARD_INFO_BG, size.width / 2 , size.height / 2 - 110)
        cardInfoBg:setScaleX(0.8)
        cardInfoBg:setScaleY(0.61)
        view:addChild(cardInfoBg, 2)
        -- 卡牌预览
        local cardPreviewEntranceNode = require('common.CardPreviewEntranceNode').new()
        cardPreviewEntranceNode:setPosition(size.width / 2 + 160, size.height / 2 - 95)
        view:addChild(cardPreviewEntranceNode , 10 )
        -- 卡牌名称
        local cardDescrLabel = display.newLabel(size.width / 2, size.height / 2 - 140, { text = __('当前展示飨灵'), ap = display.CENTER, color = '#fbdd95', fontSize = 20, tag = 870})
        view:addChild(cardDescrLabel, 5)
        local cardNameBg = display.newImageView(RES_DICT.CARD_NAME_BG, size.width / 2 - 5, size.height / 2 - 175)
        cardNameBg:setScale(0.8, 0.8)
        view:addChild(cardNameBg, 3)
        local cardNameLabel = display.newLabel(size.width / 2 - 5, size.height / 2 - 175, fontWithColor('14', { ap = display.CENTER, outline = '#5e0e0e', ttf = true, font = TTF_GAME_FONT, color = '#ffffff', fontSize = 24, text = ""}))
        view:addChild(cardNameLabel, 5)
        local qualityImg = display.newImageView('', size.width / 2 - 120, size.height / 2 - 175)
        qualityImg:setScale(0.5)
        view:addChild(qualityImg, 5)
        return {
            view                    = view,
            size                    = size,
            drawBtn                 = drawBtn,
            chestTitleBg            = chestTitleBg,
            cardPreviewEntranceNode = cardPreviewEntranceNode,
            cardNameLabel           = cardNameLabel,
            qualityImg              = qualityImg,
        }
    end
    xTry(function ( )
        local viewData = nil 
        if checkint(type) == 0 then
            viewData = CreateRewardsView()
            self:setContentSize(viewData.size)
            self:setPosition(display.cx, display.cy + 50)
            viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
        else
            viewData = CreatePathView()
            self:setContentSize(viewData.size)
            self:setPosition(config.pos)
            viewData.taskBtn:setOnClickScriptHandler(handler(self, self.TaskButtonCallback))
            viewData.chestBtn:setOnClickScriptHandler(handler(self, self.ChestButtonCallback))
        end
        self.viewData = viewData
        self.viewData.view:setPosition(cc.p(viewData.size.width / 2, viewData.size.height / 2))
        self:addChild(self.viewData.view)
        self:RefreshNode(args)
    end, __G__TRACKBACK__)
end
--[[
根据路线id获取宝箱图片
--]]
function ActivityAllRoundPathNode:GetChestImageByPathId( pathId )
    local imagePath = nil
    pathId = checkint(pathId)
    if pathId == PATH_TYPE.DAILY then
        imagePath =190100
    elseif pathId == PATH_TYPE.BATTLE then
        imagePath = 190003
    elseif pathId == PATH_TYPE.BUSINESS then
        imagePath = 190101
    elseif pathId == PATH_TYPE.PET then
        imagePath = 191003
    end
    imagePath = _res(string.format('arts/goods/goods_icon_%s' ,imagePath))
    return imagePath
end
--[[
刷新node
--]]
function ActivityAllRoundPathNode:RefreshNode( args )  
    self.pathData = args
    if checkint(args.type) == 0 then
        self:RefreshRewardsView(args)
    else
        self:RefreshPathView(args)
    end

end
--[[
刷新路线
--]]
function ActivityAllRoundPathNode:RefreshPathView( args )
    local viewData = self:GetViewData()
    if checkint(args.hasDrawn) == 0 then
        -- 未领取
        viewData.chestBtn:setEnabled(true)
        if self:CheckIsAllTaskCompleted(args.tasks) then
            -- 可领取
            viewData.bgCircle:setVisible(false)
            viewData.tickIcon:setVisible(true)
            viewData.chestLight:setVisible(true)
            viewData.chestRemindIcon:setVisible(true)
            viewData.chestTitleBg:setVisible(true)
            viewData.chestTitleLabel:setVisible(true)
            viewData.taskRemindIcon:setVisible(false)
            
            viewData.taskProgressBar:setMaxValue(#args.tasks)
            viewData.taskProgressBar:setValue(#args.tasks)
            viewData.taskProgressLabel:setString(string.format('%d/%d', #args.tasks, #args.tasks))
            viewData.taskBtn:setEnabled(true)
            viewData.chestImg:setColor(cc.c3b(255,255,255))
            viewData.chestImg:setScale(1)
            viewData.chestTitleLabel:setString(__("点击领取"))
        else
            -- 不可领取
            viewData.bgCircle:setVisible(true)
            viewData.tickIcon:setVisible(false)
            viewData.chestLight:setVisible(false)
            viewData.chestRemindIcon:setVisible(false)
            viewData.chestTitleBg:setVisible(false)
            viewData.chestTitleLabel:setVisible(false)

            viewData.chestImg:setColor(cc.c3b(255,255,255))
            viewData.taskProgressBar:setMaxValue(#args.tasks)
            local count = 0 
            for i, v in ipairs(checktable(args.tasks)) do
                if checkint(v.hasDrawn) == 1 then
                    count = count + 1
                end
            end
            viewData.taskProgressBar:setValue(count)
            viewData.taskProgressLabel:setString(string.format('%d/%d', count, #args.tasks))
            viewData.taskBtn:setEnabled(true)
            viewData.chestImg:setScale(0.8)
            local isShowRemindicon = false
            for i, v in ipairs(args.tasks) do
                if checkint(v.progress) >= checkint(v.targetNum) and checkint(v.hasDrawn) == 0 then
                    isShowRemindicon = true
                    break
                end
            end
            viewData.taskRemindIcon:setVisible(isShowRemindicon)
        end
    else
        -- 已领取
        viewData.bgCircle:setVisible(false)
        viewData.tickIcon:setVisible(true)
        viewData.chestLight:setVisible(false)
        viewData.chestRemindIcon:setVisible(false)
        viewData.chestTitleBg:setVisible(true)
        viewData.chestTitleLabel:setVisible(true)
        viewData.taskRemindIcon:setVisible(false)
        viewData.chestBtn:setEnabled(false)
        
        viewData.taskProgressBar:setMaxValue(#args.tasks)
        viewData.taskProgressBar:setValue(#args.tasks)
        viewData.taskBtn:setEnabled(false)
        viewData.chestImg:setColor(cc.c3b(80,80,80))
        viewData.chestImg:setScale(0.8)
        viewData.chestTitleLabel:setString(__("已领取"))
    end
end
--[[
刷新奖励
--]]
function ActivityAllRoundPathNode:RefreshRewardsView( args )
    local cardId = args.rewards[1].goodsId or 200001
    local cardConf = CardUtils.GetCardConfig(cardId)
    if not cardConf or next(cardConf) == nil then return end
    local viewData = self:GetViewData()
    if viewData.view:getChildByName('cardSpine') then
        viewData.view:getChildByName('cardSpine'):runAction(cc.RemoveSelf:create())
    end
    local qAvatar = AssetsUtils.GetCardSpineNode({confId = cardId, scale = 0.6})
    qAvatar:setAnimation(0, 'idle', true)
    qAvatar:setName('cardSpine')
    qAvatar:setScaleX(-1)
    qAvatar:setPosition(cc.p(viewData.size.width / 2, viewData.size.height / 2 - 110))
    viewData.view:addChild(qAvatar, 1)
    viewData.cardPreviewEntranceNode:RefreshUI({confId = cardId})
    viewData.cardNameLabel:setString(cardConf.name)
    local qualityPath = CardUtils.GetCardQualityTextPathByCardId(cardId)
    viewData.qualityImg:setTexture(qualityPath)
    if args.taskCompletion and checkint(args.hasDrawn) == 0 then
        viewData.chestTitleBg:setVisible(true)
        viewData.drawBtn:setEnabled(true)
    else
        viewData.chestTitleBg:setVisible(false)
        viewData.drawBtn:setEnabled(false)
    end
end
--[[
检测任务是否全部完成
--]]
function ActivityAllRoundPathNode:CheckIsAllTaskCompleted( taskList )
    local isCompleted = true
    for i, v in ipairs(checktable(taskList)) do
        if checkint(v.hasDrawn) == 0 then
            isCompleted = false
            break
        end
    end
    return isCompleted
end
--[[
奖励node领取按钮点击回调
--]]
function ActivityAllRoundPathNode:DrawButtonCallback( sender )
    self:GetFacade():DispatchObservers( "ACTIVITY_ALL_ROUND_PATH_DRAW_EVENT", { pathId = self.pathData.pathId})
end
--[[
路线node任务按钮点击回调
--]]
function ActivityAllRoundPathNode:TaskButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require('Game.mediator.activity.allRound.ActivityAllRoundTaskMediator').new({routeData = self.pathData, activityId = self.activityId})
    app:RegistMediator(mediator)
end
--[[
路线node宝箱按钮点击回调
--]]
function ActivityAllRoundPathNode:ChestButtonCallback( sender )
    PlayAudioByClickNormal()
    if self:CanDrawChestRewards() then 
        -- 领取宝箱奖励
        app:DispatchObservers( "ACTIVITY_ALL_ROUND_PATH_DRAW_EVENT", { pathId = self.pathData.pathId})
    else
        -- 查看宝箱奖励
        app.uiMgr:AddDialog('Game.views.activity.allRound.ActivityAllRoundRewardsPreviewView', self.pathData)
    end
end
--[[
是否可以领取宝箱奖励
--]]
function ActivityAllRoundPathNode:CanDrawChestRewards()
    local taskList = self.pathData.tasks
    if not taskList or next(taskList) == nil then return false end 
    local canDraw = true 
    for i, v in ipairs(taskList) do
        if checkint(v.hasDrawn) ~= 1 then
            canDraw = false
            break
        end
    end
    return canDraw
end
--[[
获取viewData
--]]
function ActivityAllRoundPathNode:GetViewData()
    return self.viewData
end
return ActivityAllRoundPathNode