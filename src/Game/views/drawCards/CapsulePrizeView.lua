--[[
卡池获得列表页面view
--]]
local CapsulePrizeView = class('CapsulePrizeView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsulePrizeView'
    node:setPosition(display.center)
    node:enableNodeEvents()
    return node
end)
local PRIZE_TYPE = {
    NORMAL = 1,
    TOP_PRIZE = 2
}
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function CapsulePrizeView:ctor( ... )
    self.args = unpack({...})
    self.cardPoolDatas = self.args.cardPoolDatas
    self.prizeType = PRIZE_TYPE.NORMAL
    if self.cardPoolDatas.activityType == ACTIVITY_TYPE.DRAW_NINE_GRID then
        self.prizeType = PRIZE_TYPE.TOP_PRIZE
    end
    self:InitUI()
    self:EnterAction()
end
--[[
init ui
--]]
function CapsulePrizeView:InitUI()
    local function CreateView()
        local bg = display.newImageView(_res('ui/home/capsule/draw_probability_bg.png'), 0, 0, {enable = true})
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        local roleImg = display.newImageView(_res('ui/home/capsule/draw_probability_role'), 616, 0, {ap = cc.p(0, 0)})
        view:addChild(roleImg, 10)
        local title = display.newButton(308, bgSize.height - 38, {enable = false, n = _res("ui/common/common_title_5.png"), s  = _res("ui/common/common_title_5.png") , scale9 = true  })
        view:addChild(title, 10)

        display.commonLabelParams(title, fontWithColor(4, { text = __('卡池详情') , paddingW  = isJapanSdk() and 30 or 20 }))
        local probabilityBtn = display.newButton(600, bgSize.height - 46, {ap = display.RIGHT_CENTER ,  n = _res('ui/home/capsule/draw_probability_btn.png') , s = _res('ui/home/capsule/draw_probability_btn.png')  , scale9 = true , size = cc.size(140,30) })
        view:addChild(probabilityBtn, 10)

        display.commonLabelParams(probabilityBtn, fontWithColor(18, {text = __('概率') ,reqW = 120 }))
        local probabilityBtnLabelSize = display.getLabelContentSize(probabilityBtn:getLabel())
        local probabilityBtnSize = probabilityBtn:getContentSize()
        local width = probabilityBtnSize.width > probabilityBtnLabelSize.width+ 10 and probabilityBtnSize.width
        if probabilityBtnLabelSize.width > 150 then
            width = 150
        else    
            width = 120
        end
        probabilityBtn:setContentSize(cc.size(width ,probabilityBtnSize.height ))
        -- 掉落列表
        local listSize = cc.size(578, 540)
        local rewardList = CListView:create(listSize)
        rewardList:setDirection(eScrollViewDirectionVertical)
        rewardList:setAnchorPoint(cc.p(0, 0))
        rewardList:setPosition(cc.p(19, 45))
        view:addChild(rewardList, 5)
        -- 列表
        return {
            view           = view, 
            listSize       = listSize,
            rewardList     = rewardList,
            probabilityBtn = probabilityBtn,
            roleImg        = roleImg,
            title          = title,
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
        if self.args.closeAction then
            AppFacade.GetInstance():DispatchObservers(CAPSULE_SHOW_CAPSULE_UI)
        end
        self:stopAllActions()
        self:runAction(cc.RemoveSelf:create())
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        self.viewData_.probabilityBtn:setOnClickScriptHandler(handler(self, self.ProbabilityBtnCallback))
        self.viewData_.probabilityBtn:setVisible(self.cardPoolDatas.rate ~= nil)
        if self.cardPoolDatas.slaveView then
            self.viewData_.roleImg:setTexture(_res('ui/home/capsule/activityCapsule/' .. tostring(self.cardPoolDatas.slaveView) .. '.png'))
        end
        self:UpdateListView()
    end, __G__TRACKBACK__)
end
function CapsulePrizeView:UpdateListView()
    local viewData = self.viewData_
    if self.prizeType == PRIZE_TYPE.NORMAL then
        local title = {
            isJapanSdk() and __('超稀有・稀有') or __('其他'),
            isJapanSdk() and __('超超稀有') or __('稀有')
        }
        for i, v in ipairs(self.cardPoolDatas.preview) do
            local isNowAdd = false
            if i ==2 then
                isNowAdd = true
            end
            local layout = self:CreateRewardListViewLayout(v, title[i],isNowAdd)
            viewData.rewardList:insertNodeAtFront(layout)
        end
        local spaceLayout = CLayout:create(cc.size(viewData.listSize.width, 10))
        viewData.rewardList:insertNodeAtFront(spaceLayout)
        viewData.rewardList:reloadData()
    elseif self.prizeType == PRIZE_TYPE.TOP_PRIZE then
        viewData.title:getLabel():setString(__('大奖'))
        for i, v in ipairs(self.cardPoolDatas.preview) do
            local layout = self:CreateTopPrizeListViewLayout(i, v[1])
            viewData.rewardList:insertNodeAtLast(layout)
        end
        viewData.rewardList:reloadData()
    end
end
--[[
创建奖励列表Layout
@params cardDatas table 卡牌数据
title string 标题
--]]
function CapsulePrizeView:CreateRewardListViewLayout( cardDatas, title ,isTrue )
    local cardNum = #checktable(cardDatas) -- 卡牌数目
    local layout_W = self.viewData_.listSize.width -- 容器宽
    local title_H = 34 -- 标题高度
    local line_H = 2 -- 分割线高度
    local space_H = 22 -- 留空高度
    local space_W = 40 -- 留空宽度
    local cardSpace = 18 -- 卡牌间距
    local verticalSpace = 16 -- 卡牌行间距
    local column = 4 -- 列
    local row = math.ceil(cardNum/column) -- 行
    local cardSize = cc.size(190, 190) -- 卡牌头像尺寸
    local scale = 0.6 -- 头像缩放比
    local layout = nil
    if cardNum ~= 0 then
        local layout_H = title_H + line_H + (space_H * 2) + (cardSize.width * scale * row) + (verticalSpace * (row - 1))
        layout = CLayout:create(cc.size(layout_W, layout_H))
        -- title
        local posY = layout_H - title_H/2
        local titleLabel = display.newLabel(20, posY, {text = '', fontSize = 22, color = '#765b4e', ap = cc.p(0, 0.5)})
        layout:addChild(titleLabel)
        -- line 
        posY = posY - title_H/2
        local line = display.newImageView(_res('ui/home/capsule/draw_probability_line_1.png'), layout_W/2, posY, {ap = cc.p(0.5, 1)})
        layout:addChild(line)
        posY = posY - line_H - space_H
        -- cardHeadNode
        local callfunc = function(index)
            local i = index
            local v  = cardDatas[index]
            local cardHeadNode = require('common.CardHeadNode').new({
                cardData = {cardId = checkint(v)}
            })
            cardHeadNode:setScale(scale)
            local cardRow = math.ceil(i/column)
            local cardColumn = i - (cardRow - 1) * column
            cardHeadNode:setAnchorPoint(cc.p(0, 1))
            cardHeadNode:setPosition(space_W + (cardColumn - 1) * (cardSize.width * scale + cardSpace), posY - (cardRow - 1) * (cardSize.width * scale + verticalSpace))
            layout:addChild(cardHeadNode)
            -- 判断是否拥有
            local cardData = AppFacade.GetInstance():GetManager("GameManager"):GetCardDataByCardId(checkint(v))
            if not cardData then
                cardHeadNode:SetGray(true)
            end
        end
        if isTrue then
            for i,v in ipairs(checktable(cardDatas)) do
                callfunc(i)
            end
        else
            local  count  =  table.nums(cardDatas)
            local index = 8
            if count > 8 then
                for i =1 , 8 do
                    callfunc(i)
                end
                self.viewData_.roleImg:runAction(cc.Repeat:create(
                    cc.Sequence:create(
                        cc.DelayTime:create(0.04),
                        cc.CallFunc:create(
                            function()
                                index = index +1
                                callfunc(index)
                            end
                        )
                    ) , count -8
                )
                )
            else
                for i =1 , count do
                    callfunc(i)
                end
            end
        end
        -- 计算拥有的数量
        local hasNum = 0
        for i,v in ipairs(checktable(cardDatas)) do
            local cardData = AppFacade.GetInstance():GetManager("GameManager"):GetCardDataByCardId(checkint(v))
            if cardData then
                hasNum = hasNum + 1
            end
        end
        titleLabel:setString(string.format('%s（%d/%d）', tostring(title), checkint(hasNum), checkint(cardNum) ))
    end
    return layout or CLayout:create(cc.size(0,0))
end
--[[
创建大奖cell
--]]
function CapsulePrizeView:CreateTopPrizeListViewLayout( index, goodsData ) 
    local size = cc.size(578, 160)
    local layout = CLayout:create(size)
    local title = display.newLabel(size.width / 2, size.height - 24, fontWithColor(5, {text = string.fmt(__('第_num_轮'), {['_num_'] = index})}))
    layout:addChild(title, 1)
    local icon = require('common.GoodNode').new({
        id = goodsData.goodsId,
        showAmount = true,
        num = goodsData.num,
        callBack = function (sender)
            AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = goodsData.goodsId, type = 1})
        end,
    })
    icon:setAnchorPoint(cc.p(0.5, 0))
    icon:setPosition(cc.p(size.width / 2, 12))
    layout:addChild(icon, 1) 
    local line = display.newImageView(_res('ui/home/capsule/draw_probability_line_1.png'), size.width / 2, 2, {ap = cc.p(0.5, 0)})
    layout:addChild(line, 1)
    return layout
end
--[[
概率按钮点击回调
--]]
function CapsulePrizeView:ProbabilityBtnCallback( sender )
    PlayAudioByClickNormal()
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = self.cardPoolDatas.rate})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
function CapsulePrizeView:EnterAction()
    self:setOpacity(0)
    self:runAction(cc.FadeIn:create(0.2))
end
return CapsulePrizeView