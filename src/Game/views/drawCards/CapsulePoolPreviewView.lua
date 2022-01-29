--[[
卡池详情页面view
--]]
local CapsulePoolPreviewView = class('CapsulePoolPreviewView', function ()
    local node = CLayout:create(display.size)
    node.name = 'CapsulePoolPreviewView'
    node:setPosition(display.center)
    node:enableNodeEvents()
    return node
end)
local PRIZE_TYPE = {
    NORMAL = 1,             -- 通常
    TOP_PRIZE = 2,          -- 九宫格奖励预览
    RANDOM_POOL = 3,        -- 随机卡池奖励预览
    BASIC_SKIN_CAPSULE = 4, -- 常驻皮肤卡池
}
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local CapsuleRandomPoolPreviewView = require('Game.views.drawCards.CapsuleRandomPoolPreviewView')
function CapsulePoolPreviewView:ctor( ... )
    self.args = unpack({...})
    self.cardPoolDatas = self.args.cardPoolDatas
    self.prizeType = PRIZE_TYPE.NORMAL
    if self.cardPoolDatas.activityType == ACTIVITY_TYPE.DRAW_NINE_GRID then
        self.prizeType = PRIZE_TYPE.TOP_PRIZE
        self:InitUI()
    elseif self.cardPoolDatas.activityType == ACTIVITY_TYPE.DRAW_RANDOM_POOL then
        self.prizeType = PRIZE_TYPE.RANDOM_POOL
        local capsuleRandomPoolPreviewView = CapsuleRandomPoolPreviewView.new(self.args)
        self:addChild(capsuleRandomPoolPreviewView)
        capsuleRandomPoolPreviewView:setPosition(display.center)
    elseif self.cardPoolDatas.activityType == ACTIVITY_TYPE.BASIC_SKIN_CAPSULE then
        self.prizeType = PRIZE_TYPE.BASIC_SKIN_CAPSULE
        self:InitUI()
    else
        self:InitUI()
    end
    
    self:EnterAction()
end
--[[
init ui
--]]
function CapsulePoolPreviewView:InitUI()
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

        display.commonLabelParams(title, fontWithColor(4, { text = __('卡池详情') , paddingW  = 30 }))
        local probabilityBtn = display.newButton(600, bgSize.height - 46, {ap = display.RIGHT_CENTER ,  n = _res('ui/home/capsule/draw_probability_btn.png') , s = _res('ui/home/capsule/draw_probability_btn.png') , scale9 = true , size = cc.size(140,30) })
        view:addChild(probabilityBtn, 10)

        display.commonLabelParams(probabilityBtn, fontWithColor(18, {text = __('概率') ,reqW = 120  }))
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

function CapsulePoolPreviewView:UpdateListView()
    local viewData = self.viewData_
    if self.prizeType == PRIZE_TYPE.NORMAL then
        local preview = self:SortPreviewData(self.cardPoolDatas.preview)
        local layout = self:CreateRewardListViewLayout(preview)
        viewData.rewardList:insertNodeAtFront(layout)
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
    elseif self.prizeType == PRIZE_TYPE.BASIC_SKIN_CAPSULE then
        local previewData = self:ConvertBasicSkinPreviewData(self.cardPoolDatas.preview)
        for i, v in ipairs(previewData) do
            local layout = self:CreateBasicSkinListViewLayout(v)
            viewData.rewardList:insertNodeAtLast(layout)
        end
        viewData.rewardList:reloadData()
    end
end
--[[
排序
--]]
function CapsulePoolPreviewView:SortPreviewData( preview )
    local previewData = clone(preview)
    table.sort(previewData, function (a, b)
        local confA = CommonUtils.GetConfig('goods', 'goods', a.cardId) or {}
        local confB = CommonUtils.GetConfig('goods', 'goods', b.cardId) or {}
        if checkint(a.isGuaranteed) ~= checkint(b.isGuaranteed) then
            return checkint(a.isGuaranteed) > checkint(b.isGuaranteed)
        end
        if checkint(a.probabilityUp) ~= checkint(b.probabilityUp) then
            return checkint(a.probabilityUp) > checkint(b.probabilityUp)
        end
        if checkint(a.rare) ~= checkint(b.rare) then
            return checkint(a.rare) > checkint(b.rare)
        end
        if checkint(confA.quality) ~= checkint(confB.quality) then
            return checkint(confA.quality) > checkint(confB.quality)
        end
        return checkint(a.cardId) > checkint(b.cardId)
    end)
    return previewData
end
--[[
转换基础皮肤卡池的数据
--]]
function CapsulePoolPreviewView:ConvertBasicSkinPreviewData( data )
    local previewData = {}
    local previewData = {
        {title = __('飨灵外观'), preview = {}}, 
        {title = __('家具'), preview = {}}
    }
    -- 分类
    for i, v in ipairs(data) do
        local type = GoodsUtils.GetGoodsTypeById(v.cardId)
        if type == GoodsType.TYPE_CARD_SKIN then
            table.insert(previewData[1].preview, v)
        else
            table.insert(previewData[2].preview, v)
        end
    end
    -- 排序
    for i, v in ipairs(previewData) do
        v.preview = self:SortPreviewData(v.preview)
    end
    return previewData
end
--[[
创建奖励列表Layout
@params cardDatas table 卡牌数据
title string 标题
--]]
function CapsulePoolPreviewView:CreateRewardListViewLayout( cardDatas )
    local cardNum = #checktable(cardDatas) -- 卡牌数目
    local layout_W = self.viewData_.listSize.width -- 容器宽
    local cardSpace = 18 -- 卡牌间距
    local verticalSpace = 16 -- 卡牌行间距
    local column = 4 -- 列
    local row = math.ceil(cardNum/column) -- 行
    local cardSize = cc.size(108, 108) -- 卡牌头像尺寸
    local scale = 1 -- 头像缩放比
    local space_H = 10 -- 留空高度
    local space_W = (layout_W - (column * (cardSize.width * scale)) - ((column - 1) * cardSpace)) / 2 -- 留空宽度
    local layoutSize = cc.size(layout_W, space_H + (row * (cardSize.height * scale + 16)))
    
    local layout = CLayout:create(layoutSize)
    local CreateGoodsNode = function ( i )
        local v = cardDatas[i]
        local goodsNode = require('common.GoodNode').new({
            id = v.cardId,
            showAmount = false,
            highlight = checkint(v.rare),
            callBack = function (sender) -- icon点击回调
                local goodsConf = CommonUtils.GetConfig('goods', 'goods', v.cardId)
                if tostring(goodsConf.type) == GoodsType.TYPE_CARD then
                    -- 卡牌类型
                    local cardPreviewView = require('common.CardPreviewView').new({
                        confId = v.cardId
                    })
                    display.commonUIParams(cardPreviewView, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(cardPreviewView)
                elseif tostring(goodsConf.type) == GoodsType.TYPE_CARD_SKIN then
                    -- 皮肤类型
                    local layer = require('common.CommonCardGoodsDetailView').new({
                        goodsId = v.cardId
                    })
                    display.commonUIParams(layer, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(layer)
                else
                    -- 其他
                    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.cardId, type = 1})
                end

            end,
        })
        local cardRow = math.ceil(i/column)
        local cardColumn = i - (cardRow - 1) * column
        goodsNode:setAnchorPoint(cc.p(0, 1))
        goodsNode:setPosition(cc.p(space_W + (cardColumn - 1) * (cardSize.width * scale + cardSpace), layoutSize.height - space_H - (cardRow - 1) * (cardSize.height * scale + verticalSpace)))
        layout:addChild(goodsNode, 1)
        -- 概率up
        if checkint(v.probabilityUp) == 1 then
            local upBg = display.newImageView(_res('ui/home/capsuleNew/common/summon_detail_bg_up.png'), goodsNode:getContentSize().width / 2, 20)
            upBg:setScale(0.9)
            goodsNode:addChild(upBg, 10)
            local upLabel = display.newLabel(upBg:getContentSize().width / 2, upBg:getContentSize().height / 2, {text = __('出现率up'), fontSize = 22, reqW = 120 ,  color = '#ffe08b'})
            upBg:addChild(upLabel, 1)
        end
        -- 保底
        if checkint(v.isGuaranteed) == 1 then
            local upBg = display.newImageView(_res('ui/home/capsuleNew/common/summon_detail_bg_up.png'), goodsNode:getContentSize().width / 2, 20)
            upBg:setScale(0.9)
            goodsNode:addChild(upBg, 10)
            local upLabel = display.newLabel(upBg:getContentSize().width / 2, upBg:getContentSize().height / 2, {text = __('保底'), fontSize = 22, color = '#ffe08b'})
            upBg:addChild(upLabel, 1)
        end
    end

    local count = cardNum
    local index = 16
    if count > 16 then
        for i =1 , 16 do
            CreateGoodsNode(i)
        end
        self.viewData_.roleImg:runAction(cc.Repeat:create(
            cc.Sequence:create(
                cc.DelayTime:create(0.04),
                cc.CallFunc:create(
                    function()
                        index = index +1
                        CreateGoodsNode(index)
                    end
                )
            ) , count - 16
        )
        )
    else
        for i =1 , count do
            CreateGoodsNode(i)
        end
    end

    return layout
end
--[[
创建大奖cell
--]]
function CapsulePoolPreviewView:CreateTopPrizeListViewLayout( index, goodsData ) 
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
创建常驻皮肤卡池Layout
@params params map {
    name    string 名称
    preview list   道具列表
}
--]]
function CapsulePoolPreviewView:CreateBasicSkinListViewLayout( params )
    local cardNum = #checktable(params.preview) -- 卡牌数目
    local layout_W = self.viewData_.listSize.width -- 容器宽
    local cardSpace = 18 -- 卡牌间距
    local verticalSpace = 16 -- 卡牌行间距
    local column = 4 -- 列
    local row = math.ceil(cardNum/column) -- 行
    local cardSize = cc.size(108, 108) -- 卡牌头像尺寸
    local scale = 1 -- 头像缩放比
    local space_H = 10 -- 留空高度
    local title_H = 44 -- 标题高度

    local space_W = (layout_W - (column * (cardSize.width * scale)) - ((column - 1) * cardSpace)) / 2 -- 留空宽度
    local layoutSize = cc.size(layout_W, space_H + title_H + (row * (cardSize.height * scale + 16)))
    
    local layout = CLayout:create(layoutSize)
    local CreateGoodsNode = function ( i )
        local v = params.preview[i]
        local goodsNode = require('common.GoodNode').new({
            id = v.cardId,
            showAmount = false,
            highlight = checkint(v.rare),
            callBack = function (sender) -- icon点击回调
                local goodsConf = CommonUtils.GetConfig('goods', 'goods', v.cardId)
                if tostring(goodsConf.type) == GoodsType.TYPE_CARD then
                    -- 卡牌类型
                    local cardPreviewView = require('common.CardPreviewView').new({
                        confId = v.cardId
                    })
                    display.commonUIParams(cardPreviewView, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(cardPreviewView)
                elseif tostring(goodsConf.type) == GoodsType.TYPE_CARD_SKIN then
                    -- 皮肤类型
                    local layer = require('common.CommonCardGoodsDetailView').new({
                        goodsId = v.cardId
                    })
                    display.commonUIParams(layer, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(layer)
                else
                    -- 其他
                    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.cardId, type = 1})
                end

            end,
        })
        local cardRow = math.ceil(i/column)
        local cardColumn = i - (cardRow - 1) * column
        goodsNode:setAnchorPoint(cc.p(0, 1))
        goodsNode:setPosition(cc.p(space_W + (cardColumn - 1) * (cardSize.width * scale + cardSpace), layoutSize.height - space_H - title_H - (cardRow - 1) * (cardSize.height * scale + verticalSpace)))
        layout:addChild(goodsNode, 1)
        -- 概率up
        if checkint(v.probabilityUp) == 1 then
            local upBg = display.newImageView(_res('ui/home/capsuleNew/common/summon_detail_bg_up.png'), goodsNode:getContentSize().width / 2, 20)
            upBg:setScale(0.9)
            goodsNode:addChild(upBg, 10)
            local upLabel = display.newLabel(upBg:getContentSize().width / 2, upBg:getContentSize().height / 2, {text = __('出现率up'), fontSize = 22, color = '#ffe08b'})
            upBg:addChild(upLabel, 1)
        end
        -- 保底
        if checkint(v.isGuaranteed) == 1 then
            local upBg = display.newImageView(_res('ui/home/capsuleNew/common/summon_detail_bg_up.png'), goodsNode:getContentSize().width / 2, 20)
            upBg:setScale(0.9)
            goodsNode:addChild(upBg, 10)
            local upLabel = display.newLabel(upBg:getContentSize().width / 2, upBg:getContentSize().height / 2, {text = __('保底'), fontSize = 22, color = '#ffe08b'})
            upBg:addChild(upLabel, 1)
        end
    end

    local  title = display.newLabel(20, layoutSize.height - 24, {text = params.title, color = '#846766', fontSize = 22, ap = display.LEFT_CENTER})
    layout:addChild(title, 1)
    local splitLine = display.newImageView(_res('ui/common/season_loots_line_1'), layoutSize.width / 2, layoutSize.height - 42)
    splitLine:setScale(0.9)
    layout:addChild(splitLine, 1)

    local count = cardNum
    local index = 16
    if count > 16 then
        for i =1 , 16 do
            CreateGoodsNode(i)
        end
        self.viewData_.roleImg:runAction(cc.Repeat:create(
            cc.Sequence:create(
                cc.DelayTime:create(0.04),
                cc.CallFunc:create(
                    function()
                        index = index +1
                        CreateGoodsNode(index)
                    end
                )
            ) , count - 16
        )
        )
    else
        for i =1 , count do
            CreateGoodsNode(i)
        end
    end

    return layout 
end
--[[
概率按钮点击回调
--]]
function CapsulePoolPreviewView:ProbabilityBtnCallback( sender )
    PlayAudioByClickNormal()
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = self.cardPoolDatas.rate})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
function CapsulePoolPreviewView:EnterAction()
    self:setOpacity(0)
    self:runAction(cc.FadeIn:create(0.2))
end
return CapsulePoolPreviewView