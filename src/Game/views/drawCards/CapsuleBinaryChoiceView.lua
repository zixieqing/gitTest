--[[
 * author : liuzhipeng
 * descpt : 新抽卡 双抉卡池View
--]]
local CapsuleBinaryChoiceView = class('CapsuleBinaryChoiceView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleBinaryChoiceView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BOTTOM_BG         = _res("ui/home/capsuleNew/common/summon_activity_bg_.png"),
    BOTTOM_TEXT_BG    = _res('ui/home/capsuleNew/tenTimes/summon_10_series_bg_text.png'),
    PROGRESS_BG       = _res('ui/home/capsuleNew/tenTimes/unni_activity_bg_loading_login_get_1.png'),
    PROGRESS_IMG      = _res('ui/home/capsuleNew/tenTimes/unni_activity_bg_loading_login_get_2.png'),
    COMMON_BTN_BIG    = _res('ui/common/common_btn_big_orange_2.png'),
    COMMON_BTN_BIG_D  = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    TIPS_BG           = _res('ui/home/capsuleNew/tenTimes/summon_10_series_bg_sale_tips.png'),
    SALE_BG           = _res('ui/home/capsuleNew/tenTimes/summon_10_series_bg_prize_sale.png'), 
    CARD_TEXT_BG      = _res('ui/home/capsuleNew/tenTimes/summon_goods_bg_text.png'),
    CARD_SHADOW       = _res('ui/home/capsuleNew/tenTimes/summon_bg_goods_button.png'),
    PRIZE_GOODS_BG    = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg.png'),
    PRIZE_GOODS_LIGHT = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg_light.png'),
    SALE_LINE         = _res('ui/home/capsuleNew/tenTimes/summon_img_line_sale.png'),
    BG                = _res('ui/home/capsule/draw_card_bg2.jpg'),
    TEXT_BG           = _res("ui/home/capsuleNew/binaryChoice/summon_skin_bg_title_choice_skin.png"),
    PREVIEW_BTN       = _res('ui/home/capsuleNew/binaryChoice/summon_newhand_label_highlight.png'),
    SELECTED_FRAME    = _res('ui/home/capsuleNew/binaryChoice/summon_choice_bg_selected_light.png'),
    COMMON_BTN        = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_D      = _res('ui/common/common_btn_orange_disable.png'),
}
function CapsuleBinaryChoiceView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self.selectedURCardId = nil
    self.selectedSRList = {}
    self.choiceLayout = nil
    self.choiceUILayout = nil
    self.cards = nil
    
    self:InitUI()
end
 
function CapsuleBinaryChoiceView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.BG, size.width / 2 - 145, size.height / 2 + 40)
        view:addChild(bg, 1)
        local roleImg = display.newImageView('empty', size.width / 2 - 80, size.height / 2)
        view:addChild(roleImg, 1)
        local resetBtn = display.newButton(size.width - 60 - display.SAFE_L, size.height  - 150, {n = RES_DICT.COMMON_BTN_D})
        view:addChild(resetBtn, 5)
        display.commonLabelParams(resetBtn, fontWithColor(14, {text = __('重置')}))
        -- bottomLayout
        local bottomLayoutSize = cc.size(1076, 250)
        local bottomLayout = CLayout:create(bottomLayoutSize)
        bottomLayout:setAnchorPoint(cc.p(0.5, 0))
        bottomLayout:setPosition(cc.p(size.width / 2, 15))
        view:addChild(bottomLayout, 1)
        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, bottomLayoutSize.width / 2, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(bottomBg, 1)
        local titleBg = display.newImageView(RES_DICT.BOTTOM_TEXT_BG, bottomLayoutSize.width / 2 - 10, 163, {scale9 = true, size = cc.size(966, 32)})
        bottomLayout:addChild(titleBg, 4)
        local titleLabel = display.newLabel(50, 163, fontWithColor(18, {text = __('完成一定数量十连可领取对应限定奖励'), ap = cc.p(0, 0.5)}))
        bottomLayout:addChild(titleLabel, 5)
        
        -- 进度条
        local progressBar = CProgressBar:create(RES_DICT.PROGRESS_IMG)
        progressBar:setBackgroundImage(RES_DICT.PROGRESS_BG)
        progressBar:setDirection(eProgressBarDirectionLeftToRight)
        progressBar:setAnchorPoint(cc.p(0, 0.5))
        progressBar:setPosition(cc.p(50, 70))
        bottomLayout:addChild(progressBar, 2)
        local rewardLayoutSize = cc.size(700, 150)
        local rewardLayout = CLayout:create(rewardLayoutSize)
        rewardLayout:setAnchorPoint(cc.p(0, 0.5))
        rewardLayout:setPosition(cc.p(50, 70))
        bottomLayout:addChild(rewardLayout, 3)
        -- 抽奖按钮
        local capsuleBtn = display.newButton(900, 90, {n = RES_DICT.COMMON_BTN_BIG})
        bottomLayout:addChild(capsuleBtn, 10)
        local btnLabel = display.newLabel(capsuleBtn:getContentSize().width / 2, capsuleBtn:getContentSize().height / 2, fontWithColor(14, {text = __('10连召唤')}))
        capsuleBtn:addChild(btnLabel, 1)
        local consumeText = display.newLabel(900, 30, {text = __('消耗'), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
        bottomLayout:addChild(consumeText, 5)
        local consumeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        consumeNum:setHorizontalAlignment(display.TAR)
        consumeNum:setPosition(cc.p(885, 30))
        bottomLayout:addChild(consumeNum, 5)
        consumeNum:setAnchorPoint(cc.p(0, 0.5))
        local consumeGoods = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 900, 30, {ap = cc.p(0, 0.5)})
        consumeGoods:setScale(0.2)
        bottomLayout:addChild(consumeGoods, 5)
        local saleLine = display.newImageView(RES_DICT.SALE_LINE, 900 + display.getLabelContentSize(consumeText).width / 2, 30, {})
        bottomLayout:addChild(saleLine, 5)
        -- tips
        local tipsBg = display.newImageView(RES_DICT.TIPS_BG, 900, 115, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(tipsBg, 10)
        local tipsLabel = display.newLabel(tipsBg:getContentSize().width / 2, 90, {text = __('首次召唤'), fontSize = 26, color = '#ffcf5b', font = TTF_GAME_FONT, ttf = true, outline = '#694343', outlineSize = 2})
        tipsBg:addChild(tipsLabel, 1)
        local saleBg = display.newImageView(RES_DICT.SALE_BG, tipsBg:getContentSize().width / 2, 50)
        tipsBg:addChild(saleBg, 3)
        local saleConsumeText = display.newLabel(tipsBg:getContentSize().width / 2, 90, {text = __('消耗'), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
        tipsBg:addChild(saleConsumeText, 5)
        local saleConsumeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        saleConsumeNum:setHorizontalAlignment(display.TAR)
        saleConsumeNum:setPosition(cc.p(0, 0.5))
        saleConsumeNum:setPosition(cc.p(tipsBg:getContentSize().width / 2 - 15, 50))
        tipsBg:addChild(saleConsumeNum, 5)
        local saleConsumeGoods = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), tipsBg:getContentSize().width / 2, 50, {ap = cc.p(0, 0.5)})
        saleConsumeGoods:setScale(0.2)
        tipsBg:addChild(saleConsumeGoods, 5)
        return {      
            view             = view,
            capsuleBtn       = capsuleBtn,
            tipsBg           = tipsBg,
            saleBg           = saleBg,
            consumeText      = consumeText,
            consumeNum       = consumeNum,
            consumeGoods     = consumeGoods,
            saleConsumeText  = saleConsumeText,
            saleConsumeNum   = saleConsumeNum,
            saleConsumeGoods = saleConsumeGoods,
            rewardLayout     = rewardLayout,
            progressBar      = progressBar,
            saleLine         = saleLine,
            bottomLayout     = bottomLayout,
            resetBtn         = resetBtn, 
            roleImg          = roleImg, 
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
        self:HideUI()
	end, __G__TRACKBACK__)
end
--[[
隐藏UI
--]]
function CapsuleBinaryChoiceView:HideUI()
    local viewData = self:GetViewData()
    viewData.resetBtn:setVisible(false)
    viewData.bottomLayout:setVisible(false)
    viewData.consumeText:setVisible(false)
    viewData.consumeNum:setVisible(false)
    viewData.consumeGoods:setVisible(false)
    viewData.saleLine:setVisible(false)
    viewData.tipsBg:setVisible(false)
    viewData.roleImg:setVisible(false)
end
--[[
刷新重置按钮状态
@params enabled bool 是否可以点击
--]]
function CapsuleBinaryChoiceView:RefreshResetBtnState( enabled )
    local viewData = self:GetViewData()
    if enabled then
        viewData.resetBtn:setNormalImage(RES_DICT.COMMON_BTN)
        viewData.resetBtn:setSelectedImage(RES_DICT.COMMON_BTN)
        viewData.capsuleBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_D)
        viewData.capsuleBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_D)
        viewData.capsuleBtn:setEnabled(false)
    else
        viewData.resetBtn:setNormalImage(RES_DICT.COMMON_BTN_D)
        viewData.resetBtn:setSelectedImage(RES_DICT.COMMON_BTN_D)
        viewData.capsuleBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG)
        viewData.capsuleBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG)
        viewData.capsuleBtn:setEnabled(true)
    end
end
--[[
刷新角色图片
@params cardId int 卡牌Id
--]]
function CapsuleBinaryChoiceView:RefreshRoleImg( cardId )
    local viewData = self:GetViewData()
    viewData.roleImg:setTexture(__(string.format('ui/home/capsuleNew/cardChoose/choicRole/summon_choice_role_%d.png', checkint(cardId))))
end
--[[
刷新价格
@params data map {
    consume map 抽卡消耗 {
        goodsId int 道具id
        num     int 道具数量
    }
    discountConsume map 折扣消耗 {
        goodsId int 道具id
        num     int 道具数量
    }
    isDiscount int 当前次数是否打折(1:打折, 0:不打折)
}
--]]
function CapsuleBinaryChoiceView:RefreshPrice( data )
    if not data then return end
    local consume = checktable(data.consume)
    local discountConsume = checktable(data.discountConsume)
    local isDiscount = checkint(data.isDiscount)
    local viewData = self.viewData
    -- 原价
    
    viewData.consumeNum:setString(consume.num)
    viewData.consumeGoods:setTexture(CommonUtils.GetGoodsIconPathById(consume.goodsId))
    local w1 = display.getLabelContentSize(viewData.consumeText).width
    local w2 = viewData.consumeNum:getContentSize().width
    local w3 = 30
    viewData.consumeText:setPositionX(900 - (w1 + w2 + w3) / 2)
    viewData.consumeNum:setPositionX(900 - (w1 + w2 + w3) / 2 + w1)
    viewData.consumeGoods:setPositionX(900 - (w1 + w2 + w3) / 2 + w1 + w2)
    viewData.consumeText:setVisible(true)
    viewData.consumeNum:setVisible(true)
    viewData.consumeGoods:setVisible(true)
    if isDiscount == 1 then
        viewData.tipsBg:setVisible(true)
        viewData.saleConsumeNum:setString(discountConsume.num)
        viewData.saleConsumeGoods:setTexture(CommonUtils.GetGoodsIconPathById(discountConsume.goodsId))
        local centerX = viewData.tipsBg:getContentSize().width / 2
        local w1 = display.getLabelContentSize(viewData.saleConsumeText).width
        local w2 = viewData.saleConsumeNum:getContentSize().width
        local w3 = 30
        viewData.saleConsumeText:setPositionX(centerX - (w1 + w2 + w3) / 2)
        viewData.saleConsumeNum:setPositionX(centerX - (w1 + w2 + w3) / 2 + w1)
        viewData.saleConsumeGoods:setPositionX(centerX - (w1 + w2 + w3) / 2 + w1 + w2)
        viewData.saleLine:setPosition(900 + display.getLabelContentSize(viewData.consumeText).width / 2, 30)
        viewData.saleLine:setScaleX((viewData.consumeNum:getContentSize().width + 50) / 98)
        viewData.saleLine:setVisible(true)
    else
        viewData.tipsBg:setVisible(false)
        viewData.saleLine:setVisible(false)
    end
end
--[[
刷新限定奖励列表
@params stapData list {
    hasDrawn int 是否领取(1:已领取, 0:未领取)
    highlight int 是否高亮(1:高亮, 0:不高亮)
}
--]]
function CapsuleBinaryChoiceView:RefreshRewardList( stapData )
    if not stapData then return end
    local viewData = self.viewData
    local rewardLayout = viewData.rewardLayout
    rewardLayout:removeAllChildren()
    local progress = 0
    for i, v in ipairs(checktable(stapData)) do
        if checkint(v.progress) >= checkint(v.targetNum) then
            progress = i 
        end
        local goodsId = v.rewards[1].goodsId
        local cardHeadIcon = require('common.GoodNode').new({
            id = goodsId,
            showAmount = true,
            num = v.rewards[1].num,
            callBack = function (sender)
                local goodsType = CommonUtils.GetGoodTypeById(goodsId)
                if goodsType == GoodsType.TYPE_CARD then
                    -- 显示卡牌预览
                    local cardPreviewView = require('common.CardPreviewView').new({
                        confId = goodsId
                    })
                    display.commonUIParams(cardPreviewView, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(cardPreviewView)
                else
                    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
                end
            end,
            highlight = i == #stapData and v.highlight or 0
        })
        local posX = (592 * (i - 1) / (#stapData - 1)) - 10
        local cardW = cardHeadIcon:getContentSize().width
        local cardH = cardHeadIcon:getContentSize().height 
        if i ~= #stapData then
            cardHeadIcon:setScale(0.8)
            cardW = cardW * 0.8
            cardH = cardH * 0.8
        end
        display.commonUIParams(cardHeadIcon, {ap = cc.p(0, 0), po = cc.p(posX, 45)})
        rewardLayout:addChild(cardHeadIcon, 5)
        if checkint(v.hasDrawn) == 1 then
            local hasDrawnBg = display.newImageView(RES_DICT.CARD_TEXT_BG, cardHeadIcon:getContentSize().width / 2, cardHeadIcon:getContentSize().height / 2)
            hasDrawnBg:setCascadeOpacityEnabled(true)
            cardHeadIcon:addChild(hasDrawnBg, 10)
            local hasDrawnLabel = display.newLabel(hasDrawnBg:getContentSize().width / 2, hasDrawnBg:getContentSize().height / 2, fontWithColor(18, {text = __('已领取')}))
            hasDrawnBg:addChild(hasDrawnLabel, 1)
        end
        if checkint(v.highlight) == 1 and i ~= #stapData then
            local lightBg = display.newImageView(RES_DICT.PRIZE_GOODS_BG, posX + cardW / 2, 45 + cardH / 2)
            rewardLayout:addChild(lightBg, 1)
            local light = display.newImageView(RES_DICT.PRIZE_GOODS_LIGHT, posX + cardW / 2, 45 + cardH / 2)
            rewardLayout:addChild(light, 2)
            light:runAction(cc.RepeatForever:create(
                cc.RotateBy:create(1, 30)
            ))
        end
        local shadow = display.newImageView(RES_DICT.CARD_SHADOW, posX + cardW / 2, 45)
        rewardLayout:addChild(shadow, 4)
        local progressBg = display.newImageView(RES_DICT.CARD_TEXT_BG, posX + cardH / 2, 20)
        progressBg:setCascadeOpacityEnabled(true)
        rewardLayout:addChild(progressBg, 5)
        local progressLabel = display.newLabel(progressBg:getContentSize().width / 2, progressBg:getContentSize().height / 2, fontWithColor(9, {
            text = string.format('%d/%d', math.min(checkint(v.progress), checkint(v.targetNum)), checkint(v.targetNum))
        }))
        progressBg:addChild(progressLabel, 5)

        local progress = checkint(math.max(0, progress - 1))
        local maxValue = checkint(#stapData - 1)
        viewData.progressBar:setMaxValue(maxValue)
        viewData.progressBar:setValue(progress)
    end
end
--[[
创建选取卡牌页面
cards list 卡牌数据
--]]
function CapsuleBinaryChoiceView:CreateChoiceView( cards )
    local viewData = self:GetViewData()
    -- choiceLayout
    local size = self.size
    local choiceLayout = CLayout:create(size)
    choiceLayout:setPosition(utils.getLocalCenter(viewData.view))
    viewData.view:addChild(choiceLayout, 5)
    if not tolua.isnull(self.choiceLayout) then self.choiceLayout:runAction(cc.RemoveSelf():create()) end
    self.choiceLayout = choiceLayout

    -- choiceUILayout 
    local size = self.size
    local choiceUILayout = CLayout:create(size)
    choiceUILayout:setPosition(utils.getLocalCenter(viewData.view))
    viewData.view:addChild(choiceUILayout, 1)
    if not tolua.isnull(self.choiceUILayout) then self.choiceUILayout:runAction(cc.RemoveSelf():create()) end
    self.choiceUILayout = choiceUILayout
    
    local mask = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	mask:setTouchEnabled(true)
	mask:setContentSize(display.size)
	mask:setPosition(cc.p(size.width / 2 - 145, size.height / 2 + 40))
	choiceUILayout:addChild(mask, -1)
    
    local previewBtn = display.newButton(size.width - 10, size.height / 2 + 210, {n = RES_DICT.PREVIEW_BTN, ap = display.RIGHT_CENTER})
    choiceUILayout:addChild(previewBtn, 5)
    previewBtn:setOnClickScriptHandler(handler(self, self.PreviewButtonCallback))
    display.commonLabelParams(previewBtn, {text = __('飨灵预览'), fontSize = 20, color = '#ffffff', offset = cc.p(- 30, 5)})

    local confirmBtn = display.newButton(size.width - 120, size.height / 2 - 240, {n = RES_DICT.COMMON_BTN})
    confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
    choiceUILayout:addChild(confirmBtn, 5)
    display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确定')}))
    

    local cardNodeList = {}
    -- 选择UR
    local urTextBg = display.newImageView(RES_DICT.TEXT_BG, size.width / 2, size.height / 2 + 315)
    choiceUILayout:addChild(urTextBg, 1)
    local urTextLabel = display.newLabel(size.width / 2, size.height / 2 + 285, {text = __("请选择1个UR投入卡池"), color = '#FDF3D2', fontSize = 28})
    choiceUILayout:addChild(urTextLabel, 1)
    for i = 1, 2 do
        local cardId = checkint(cards[i])
        local node = require('common.GoodNode').new({id = cardId, showAmount = false, callBack = handler(self, self.CardNodeCallback)})
        node:setTag(i)
		node:setPosition(cc.p(size.width / 2 + math.pow(-1, i) * 90, size.height / 2 + 180))
        choiceLayout:addChild(node, 5) 
        table.insert(cardNodeList, node)
    end
    -- 选择SR
    local srTextBg = display.newImageView(RES_DICT.TEXT_BG, size.width / 2, size.height / 2 + 100)
    choiceUILayout:addChild(srTextBg, 1)
    local srTextLabel = display.newLabel(size.width / 2, size.height / 2 + 70, {text = __("请选择2个SR投入卡池"), color = '#FDF3D2', fontSize = 28})
    choiceUILayout:addChild(srTextLabel, 1)
    for i = 3, 10 do
        local cardId = checkint(cards[i])
        local node = require('common.GoodNode').new({id = cardId, showAmount = false, callBack = handler(self, self.CardNodeCallback)})
        node:setTag(i)
        local index = i - 3
		node:setPosition(cc.p(size.width / 2 - 225 + (index % 4) * 150, size.height / 2 - 30 - math.floor(index / 4) * 146))
        choiceLayout:addChild(node, 5) 
        table.insert(cardNodeList, node)
    end
    self.cardNodeList = cardNodeList
    self.cards = cards
    self.selectedURCardId = nil
    self.selectedSRList = {}
end
--[[
卡牌node点击回调
--]]
function CapsuleBinaryChoiceView:CardNodeCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag > 2 then
        -- SR
        for i, v in ipairs(self.selectedSRList) do
            if tag == v then
                self:RemoveSelectedFrameByTag(tag)
                table.remove(self.selectedSRList, i)
                return 
            end
        end
        if #self.selectedSRList == 2 then
            app.uiMgr:ShowInformationTips(__('已选中2张SR卡牌'))
        else
            self:AddSelectedFrameByTag(tag)
            table.insert(self.selectedSRList, tag)
        end
    else
        -- UR
        if tag == self.selectedURCardId then return end
        if self.selectedURCardId then
            -- 移除失效的选中框
            self:RemoveSelectedFrameByTag(self.selectedURCardId)
        end
        -- 添加选中框
        self:AddSelectedFrameByTag(tag)
        self.selectedURCardId = tag
    end
end
--[[
添加卡牌选中框
@params tag int tag
--]]
function CapsuleBinaryChoiceView:AddSelectedFrameByTag( tag )
    if self.choiceLayout:getChildByName(string.format('cardNode%d', tag)) then return end
    local node = self.cardNodeList[tag]
    local selectedFrame = display.newImageView(RES_DICT.SELECTED_FRAME, node:getPositionX(), node:getPositionY())
    selectedFrame:setName(string.format('cardNode%d', tag))
    self.choiceLayout:addChild(selectedFrame, 1)
end
--[[
移除卡牌选中框
@params tag int tag
--]]
function CapsuleBinaryChoiceView:RemoveSelectedFrameByTag( tag ) 
    local frame = self.choiceLayout:getChildByName(string.format('cardNode%d', tag))
    if frame then
        frame:runAction(cc.RemoveSelf:create())
    end
end
--[[
预览按钮点击回调
--]]
function CapsuleBinaryChoiceView:PreviewButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:AddDialog("Game.views.drawCards.CapsuleBinaryChoicePreviewView", {cards = self.cards})
end
--[[
确认按钮点击回调
--]]
function CapsuleBinaryChoiceView:ConfirmButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 检测选中卡牌是否合法
    if not self.selectedURCardId then
        app.uiMgr:ShowInformationTips(__('请选择UR卡牌'))
        return 
    end
    if #self.selectedSRList < 2 then
        app.uiMgr:ShowInformationTips(__('请选择SR卡牌'))
        return
    end
    -- 确认提示框
    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('一旦选择需召唤一定次数后才能重置，请慎重考虑。'),
    isOnlyOK = false, callback = function ()
        local cardIds = tostring(self.cards[self.selectedURCardId])
        for i, v in ipairs(self.selectedSRList) do
            cardIds = cardIds .. ',' .. tostring(self.cards[v])
        end
        sender:setEnabled(false)
        app:DispatchObservers(CAPSULE_BINARY_CHOICE_CONFIRM, {cardIds = cardIds})
    end})
    CommonTip:setPosition(display.center)
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(CommonTip)


end
--[[
卡牌选中动画
@params priceData map 价格数据
@params step list 奖励数据
--]]
function CapsuleBinaryChoiceView:ChooseAction( priceData, step )
    -- 刷新底部
    self:RefreshPrice(priceData)
    self:RefreshRewardList(step)
    local selectedNodeDict = {}
    -- 移除动画方法
    local function RemoveAction( node )
        node:runAction(cc.Sequence:create(
            cc.FadeOut:create(0.5),
            cc.RemoveSelf:create()
        ))
    end
    -- 移除未选中UR
    for i = 1, 2 do
        self.cardNodeList[i]:setEnabled(false)
        if i == self.selectedURCardId then
            local frame = self.choiceLayout:getChildByName(string.format('cardNode%d', i))
            if frame then
                RemoveAction(frame)
            end
            selectedNodeDict[tostring(i)] = self.cardNodeList[i]
        else
            RemoveAction(self.cardNodeList[i])
        end
    end
    -- 移除未选中SR
    for i = 3, 10 do
        local isSelected = false
        for _, v in ipairs(self.selectedSRList) do
            if i == v then
                isSelected = true
                break
            end
        end
        self.cardNodeList[i]:setEnabled(false)
        if isSelected then
            local frame = self.choiceLayout:getChildByName(string.format('cardNode%d', i))
            if frame then
                RemoveAction(frame)
            end
            selectedNodeDict[tostring(i)] = self.cardNodeList[i]
        else
            RemoveAction(self.cardNodeList[i])
        end
    end
    -- 移除无用UI
    RemoveAction(self.choiceUILayout)
    -- 移动选中卡牌到奖励处
    local viewData = self:GetViewData()
    for k, node in pairs(selectedNodeDict) do
        for i, v in ipairs(step) do
            local cardId = app.capsuleMgr:GetCardIdByFragmentId(v.rewards[1].goodsId)
            if checkint(self.cards[tonumber(k)]) == checkint(cardId) or checkint(self.cards[tonumber(k)]) == checkint(v.rewards[1].goodsId) then
                node:setAnchorPoint(display.LEFT_BOTTOM)
                node:setPosition(cc.p(node:getPositionX() - node:getContentSize().width / 2, node:getPositionY() - node:getContentSize().height / 2))
                local tmp = viewData.rewardLayout:convertToWorldSpace(cc.p((592 * (i - 1) / (#step - 1)) - 10, 45))
                local pos = self.choiceLayout:convertToNodeSpace(tmp)
                node:runAction(
                    cc.Sequence:create(
                        cc.DelayTime:create(0.5),
                        cc.Spawn:create(
                            cc.MoveTo:create(1, pos),
                            cc.ScaleTo:create(1, 0.8)
                        )
                    )
                )
                break
            end
        end
    end
    viewData.bottomLayout:setOpacity(0)
    viewData.bottomLayout:setVisible(true)
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(1.5),
            cc.TargetedAction:create(viewData.bottomLayout, cc.FadeIn:create(0.5)),
            cc.TargetedAction:create(self.choiceLayout, cc.RemoveSelf:create()),
            cc.CallFunc:create(function ()
                viewData.resetBtn:setVisible(true)
                viewData.roleImg:setVisible(true)
                app:DispatchObservers(CAPSULE_BINARY_CHOICE_ACTION_END)
            end)
        )
    )
    self.choiceLayout = nil
    self.choiceUILayout = nil 
end
--[[
获取viewData
--]]
function CapsuleBinaryChoiceView:GetViewData()
    return self.viewData
end
return CapsuleBinaryChoiceView
