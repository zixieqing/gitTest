--[[
 * author : liuzhipeng
 * descpt : 神器引导 View
--]]
local ArtifactGuideView = class('ArtifactGuideView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.artifactGuide.ArtifactGuideView'
	node:enableNodeEvents()
	return node
end)
local DEFAULT_CARD_ID = 200012 -- 默认的卡牌id
local RES_DICT = {
    LEFT_LAYOUT_FRAME = _res('ui/artifactGuide/guide_bg_frame_artifact.png'),
    CARD_NAME_BG      = _res('ui/home/activity/newPlayerSevenDay/activity_novice_seven_day_card_name.png'),
    REWARD_BG         = _res('ui/artifactGuide/guide_bg_list.png'),
    RIGHT_LAYOUT_BG   = _res('ui/artifactGuide/guide_bg_frame_artifact1.png'),
    TICK_ICON         = _res('ui/common/raid_room_ico_ready.png'),
}
function ArtifactGuideView:ctor( ... )
    self:InitUI()
end

function ArtifactGuideView:InitUI()
    local function CreateView( )
    	local size = cc.size(1034, 634)
        local view = CLayout:create(size)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        
        -- leftLayout --
        local leftLayoutSize = cc.size(335, 629)
        local leftLayout = CLayout:create(leftLayoutSize)
        leftLayout:setAnchorPoint(display.LEFT_CENTER)
        leftLayout:setPosition(cc.p(0, size.height / 2))
        view:addChild(leftLayout, 1)
        -- 背景
        local leftBg = display.newImageView('empty', leftLayoutSize.width / 2, leftLayoutSize.height / 2)
        leftLayout:addChild(leftBg, 1)
        -- 背景边框
        local leftBgFrame = display.newImageView(RES_DICT.LEFT_LAYOUT_FRAME, leftLayoutSize.width / 2, leftLayoutSize.height / 2)
        leftLayout:addChild(leftBgFrame, 1)
        -- 标题
        local title = display.newLabel(20, leftLayoutSize.height - 45, {text = __('神器引导'), fontSize = 36, color = '#ffd954', ttf = true, font = TTF_GAME_FONT, outline = '#593522', outlineSize = 1, ap = display.LEFT_CENTER})
        leftLayout:addChild(title, 5)
        -- 卡牌名称
        local cardNameBg = display.newImageView(RES_DICT.CARD_NAME_BG, leftLayoutSize.width / 2, 205)
        leftLayout:addChild(cardNameBg, 5)
        local cardQualityIcon = display.newImageView('empty', 40,  cardNameBg:getContentSize().height / 2)
        cardQualityIcon:setScale(0.35)
        cardNameBg:addChild(cardQualityIcon, 5)
        local cardNameLabel = display.newLabel(120, cardNameBg:getContentSize().height / 2, fontWithColor(14, {text = ''}))
        cardNameBg:addChild(cardNameLabel, 5)
        -- 奖励背景
        local rewardBg = display.newImageView(RES_DICT.REWARD_BG, leftLayoutSize.width / 2, 5, {ap = display.CENTER_BOTTOM})
        leftLayout:addChild(rewardBg, 1)
        local rewardTipsLabel = display.newLabel(rewardBg:getContentSize().width / 2, rewardBg:getContentSize().height - 15, fontWithColor(12, {text = __('完成右侧任务可获得')}))
        leftLayout:addChild(rewardTipsLabel, 5)
        -- leftLayout --

        -- rightLayout --
        local rightLayoutSize = cc.size(697, 637)
        local rightLayout = CLayout:create(rightLayoutSize)
        rightLayout:setAnchorPoint(display.RIGHT_CENTER)
        rightLayout:setPosition(cc.p(size.width, size.height / 2))
        view:addChild(rightLayout, 1)
        local rightLayoutBg = display.newImageView(RES_DICT.RIGHT_LAYOUT_BG, rightLayoutSize.width / 2, rightLayoutSize.height / 2)
        rightLayout:addChild(rightLayoutBg, 1)
        -- taskGridView
        local taskListSize = cc.size(rightLayoutSize.width - 15, rightLayoutSize.height - 25)
        local taskListCellSize = cc.size(taskListSize.width, 145)
        local taskGridView = CGridView:create(taskListSize)
        taskGridView:setSizeOfCell(taskListCellSize)
        taskGridView:setPosition(cc.p(rightLayoutSize.width / 2, rightLayoutSize.height / 2))
        taskGridView:setColumns(1)
        rightLayout:addChild(taskGridView, 5)
        -- rightLayout --

    	return {  
            view                   = view,
            leftBg                 = leftBg,
            cardQualityIcon        = cardQualityIcon,
            cardNameLabel          = cardNameLabel,
            taskListSize           = taskListSize,
            taskListCellSize       = taskListCellSize,
            taskGridView           = taskGridView,
            leftLayoutSize         = leftLayoutSize,
            leftLayout             = leftLayout,  
    	}
    end
    local eaterLayer = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self.viewData.view:setPosition(display.center)
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
刷新最终奖励
@params isDraw  bool 是否领取
@params canDraw bool 是否可以领取
@params rewards list 奖励列表
--]]
function ArtifactGuideView:RefreshFinalRewards( isDraw, canDraw, rewards )
    local viewData = self:GetViewData()
    local cardConfig = CommonUtils.GetConfig('card', 'card', DEFAULT_CARD_ID)
    -- 刷新背景
    viewData.leftBg:setTexture(_res(string.format('ui/artifactGuide/guide_bg_%d.png', DEFAULT_CARD_ID)))
    -- 卡牌名称
    viewData.cardNameLabel:setString(cardConfig.name)
    -- 卡牌稀有度
    viewData.cardQualityIcon:setTexture(CardUtils.GetCardQualityTextPathByCardId(DEFAULT_CARD_ID))
    -- 刷新奖励
    if viewData.leftLayout:getChildByName('rewardLayout') then
        viewData.leftLayout:removeChildByName('rewardLayout')
    end
    local rewardLayout = self:CreateRewardsLayout(isDraw, rewards)
    rewardLayout:setName('rewardLayout')
    rewardLayout:setPosition(cc.p(viewData.leftLayoutSize.width / 2, 70))
    viewData.leftLayout:addChild(rewardLayout, 5)
    
end
--[[
创建奖励Layout
@params isDraw  bool 是否领取
@params rewards list 奖励列表
--]]
function ArtifactGuideView:CreateRewardsLayout( isDraw, rewards )
    local size = cc.size(98 * #rewards +  24 * (#rewards - 1), 100)
    local layout = CLayout:create(size)
    for i, v in ipairs(rewards) do
        local goodsIcon = require('common.GoodNode').new({
            id = v.goodsId,
            showAmount = true,
            amount = v.num, 
            callBack = function (sender)
                PlayAudioByClickNormal()
                AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
            end
        })
        goodsIcon:setScale(0.9)
        local pos = cc.p(49 + (i - 1) * 122, size.height / 2)
        goodsIcon:setPosition(pos)  
        layout:addChild(goodsIcon, 1)
        if isDraw then  
            local tickIcon = display.newImageView(RES_DICT.TICK_ICON, 0, 0)
            tickIcon:setPosition(pos)
            tickIcon:SetScale(0.9)
            layout:addChild(tickIcon, 5)
        end
    end
    return layout
end
--[[
进入动画
--]]
function ArtifactGuideView:EnterAction()
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function ArtifactGuideView:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )

    )
end
--[[
获取viewData
--]]
function ArtifactGuideView:GetViewData()
    return self.viewData
end
return ArtifactGuideView