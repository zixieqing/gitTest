--[[
卡池选择页面view
--]]
local CapsuleSkinEntryView = class('CapsuleSkinEntryView', function ()
    local node = CLayout:create()
    node.name = 'Game.views.drawCards.CapsuleSkinEntryView'
    node:enableNodeEvents()
    return node
end)


local RES_DICT = {
    NEWLAND_BG_BELOW = _res("ui/home/capsuleNew/skinCapsule/summon_activity_bg_bottom.png"),
    NEWLAND_BG_COUNT = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_bg_count.png"),
    NEWLAND_BG_PREVIEW = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_label_preview.png"), ORANGE_BTN_N = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    SELECT_TITLE_BG = _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_title_choice_skin.png'),
    LIST_CELL_FLAG = _res('ui/home/capsuleNew/skinCapsule/summon_choice_bg_get_text.png'),
    LIST_SELECT_IMAGE = _res("ui/home/capsuleNew/skinCapsule/summon_skin_bg_text_choosed.png"),
    MAIN_BTN_SHOP = _res("ui/home/nmain/main_btn_shop"),
}

local EntryNode = require("common.CardPreviewEntranceNode")

local NewPlayerRewardCell = require("Game.views.drawCards.NewPlayerRewardCell")

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local cardMgr = AppFacade.GetInstance():GetManager('CardManager')

local CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})


    local selectCardView = display.newLayer(0, 0, {size = size})
    view:addChild(selectCardView, 10)
    selectCardView:setVisible(false)

    -- eaterLayer
    local eaterLayer = display.newLayer(size.width / 2 - 145, size.height / 2 + 42.5, {size = display.size, color = cc.c4b(0,0,0,150), ap = display.CENTER})
    eaterLayer:setTouchEnabled(true)
    selectCardView:addChild(eaterLayer, -1)

    local taskListSize =cc.size(510, 560)
    local gridView = CTableView:create(taskListSize)
    gridView:setName('gridView')
    gridView:setSizeOfCell(cc.size(230, 560))
    gridView:setAutoRelocate(true)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    selectCardView:addChild(gridView,2)
    gridView:setAnchorPoint(cc.p(0.5, 0))
    gridView:setDragable(false)
    gridView:setPosition(cc.p(size.width * 0.5, 30))

    local topTitleBg = display.newButton(size.width * 0.5, size.height, {
            n = RES_DICT.SELECT_TITLE_BG, ap = display.CENTER_TOP
        })
    topTitleBg:setEnabled(false)
    display.commonLabelParams(topTitleBg, fontWithColor(2,{text = __('选择一个外观加入卡池'), fontSize = 22, color = "ffffff", offset = cc.p(0, -12)}))
    selectCardView:addChild(topTitleBg, 10)

    local selectButton = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'),
            d = _res("ui/common/common_btn_orange_disable.png")})
    display.commonUIParams(selectButton, {po = cc.p(size.width * 0.5 + 340, 94)})
    display.commonLabelParams(selectButton, fontWithColor(14,{text = __('投入')}))
    selectButton:setName('GET_BUTTON')
    selectButton:setVisible(false)
    selectCardView:addChild(selectButton)

    local rSize = cc.size(162, 190)
    local rightView = CLayout:create(rSize)
    local topNameLabel = display.newButton(rSize.width * 0.5, rSize.height -40 ,{
            n = RES_DICT.NEWLAND_BG_PREVIEW, ap = display.CENTER_BOTTOM, scale9 = true , size = cc.size(180,60)
        })
    display.commonLabelParams(topNameLabel, fontWithColor(14, {text = __('外观预览') ,hAlign = display.TAC ,w = 180}))
    topNameLabel:setEnabled(false)
    rightView:addChild(topNameLabel,1)
    rightView:setVisible(false)

    --bg
    local bgImage = display.newImageView(_res("ui/home/capsuleNew/skinCapsule/summon_skin_bg_text_choosed.png"), rSize.width, rSize.height - 40,{ap = display.RIGHT_TOP,scale9 = true, size = cc.size(rSize.width - 14, 130)})
    rightView:addChild(bgImage)
    local previewNode = EntryNode.new({skinId = CardUtils.DEFAULT_CARD_ID, cardDrawChangeType = 1})
    display.commonUIParams(previewNode, { po = cc.p(80,90)})
    rightView:addChild(previewNode)
    display.commonUIParams(rightView, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width - 16, 154)})
    view:addChild(rightView,1)
    --最下方

    local bottomView = CLayout:create(cc.size(size.width, 186))
    local bgImageView = display.newImageView(RES_DICT.NEWLAND_BG_BELOW, size.width * 0.5, 186 * 0.5, {scale9 = true, size = cc.size(size.width, 186)})
    bottomView:addChild(bgImageView)
    bottomView:setVisible(false)

    local countLabelBg = display.newImageView(RES_DICT.NEWLAND_BG_COUNT, size.width * 0.5, 0, {ap = display.CENTER_BOTTOM, size = cc.size(size.width, 34), scale9 = true})
    local countNumLabel = display.newLabel(size.width * 0.5, 17,{text = string.fmt(__("剩余抽卡次数：_num_"), {_num_ = 0}), fontSize = 22, color = 'd9c198'})
    countLabelBg:addChild(countNumLabel,2)
    bottomView:addChild(countLabelBg)
    display.commonUIParams(bottomView, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.5, 0)})
    view:addChild(bottomView)

    local baseY = 72
    -------------------------------------------------
    -- once info
    local drawOncePos = cc.p(size.width/2 - 200, baseY + 37)
    local drawOnceBtn = display.newButton(drawOncePos.x, drawOncePos.y, {n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    display.commonLabelParams(drawOnceBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\nX_num_'), {_num_ = 1})}))
    drawOnceBtn:setEnabled(false)
    bottomView:addChild(drawOnceBtn)

    local onceConsumeRLable = display.newRichLabel(drawOncePos.x, drawOncePos.y - 58)
    bottomView:addChild(onceConsumeRLable)

    -- local onceLeftLable = display.newLabel(drawOncePos.x, drawOncePos.y + 70, fontWithColor(14))
    -- view:addChild(onceLeftLable)

    -------------------------------------------------
    -- much info
    local drawMuchPos = cc.p(size.width/2 + 200, drawOncePos.y)
    local drawMuchBtn = display.newButton(drawMuchPos.x, drawMuchPos.y, {n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    display.commonLabelParams(drawMuchBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\nX_num_'), {_num_ = 10})}))
    drawMuchBtn:setEnabled(false)
    bottomView:addChild(drawMuchBtn)

    local muchConsumeRLable = display.newRichLabel(drawMuchPos.x, onceConsumeRLable:getPositionY())
    bottomView:addChild(muchConsumeRLable)

    -- local muchLeftLable = display.newLabel(drawMuchPos.x, onceLeftLable:getPositionY(), fontWithColor(14))
    -- view:addChild(muchLeftLable)

    -- 商店
	local shopBtn = display.newButton(size.width - display.SAFE_L - 50, size.height - 140, {n = RES_DICT.MAIN_BTN_SHOP})
    display.commonLabelParams(shopBtn, fontWithColor(14, {fontSize = 24, hAlign = display.TAC, offset = cc.p(0, -30), text = __('兑换')}))
    view:addChild(shopBtn, 8)


    return {
        view              = view,
        selectCardView    = selectCardView,
        selectButton      = selectButton,
        rightView         = rightView,
        gridView          = gridView,
        bottomView        = bottomView,
        countLabelBg      = countLabelBg,
        countNumLabel     = countNumLabel,
        drawOnceBtn       = drawOnceBtn,
        drawMuchBtn       = drawMuchBtn,
        onceConsumeRLable = onceConsumeRLable,--消耗钻石多少的条
        muchConsumeRLable = muchConsumeRLable,
        previewNode       = previewNode,
        shopBtn           = shopBtn,
        topTitleBg        = topTitleBg,
    }
end


function CapsuleSkinEntryView:ctor( ... )
	local args = unpack({...})
    self.preIndex = -1
    self.datas = {}
	local size = args.size
	self:setContentSize(size)

    self.viewData = CreateView(size)
    self:addChild(self.viewData.view, 1)
    -- display.reloadRichLabel(self.viewData.muchConsumeRLable, {c = {
    --     fontWithColor(7, {fontSize = 24, text = __('消耗'), }) ,
    --     fontWithColor(7, {fontSize = 24, text = string.fmt(' %1 ', 100)}),
    --     {img = CommonUtils.GetGoodsIconPathById(GOLD_ID), scale = 0.2},
    -- }})
    self.viewData.previewNode:ResetClickAction(handler(self, self.ResetPoolAction))
end


function CapsuleSkinEntryView:UpdateGridView( datas )
    if datas and #datas > 0 then
        self.viewData.gridView:setCountOfCell(#datas)
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
        self.viewData.gridView:reloadData()
    end
end


function CapsuleSkinEntryView:CellButtonAction(sender)
    if self:GetSelectedState() or self:IsAllObtained() then return end
    PlayAudioByClickNormal()
    self:UpdatePreviewBtnShowState(true)
    local index = sender:getTag()
    if index == self.preIndex then return end
    local cell = self.viewData.gridView:cellAtIndex(index - 1)
    if cell then
        self.preIndex = index
        local skinId = sender:getUserTag()
        self.viewData.gridView:reloadData()
        --更新右侧的内容
        if cardMgr.IsHaveCardSkin(skinId) then
            self.viewData.selectButton:setVisible(false)
            display.commonLabelParams(self.viewData.selectButton, fontWithColor(14,{text = __('关闭')}))
        else
            self.viewData.selectButton:setVisible(true)
            local serverSkinId = 0
            if checkint(self.datas.currentCardSkin) > 0 and self.datas.cardSkins[checkint(self.datas.currentCardSkin)] then
                serverSkinId = self.datas.cardSkins[checkint(self.datas.currentCardSkin)].rareCardSkinId
            end
            if skinId == checkint(serverSkinId) then
                display.commonLabelParams(self.viewData.selectButton, fontWithColor(14,{text = __('关闭')}))
            else
                display.commonLabelParams(self.viewData.selectButton, fontWithColor(14,{text = __('投入')}))
            end
        end
    end
end

function CapsuleSkinEntryView:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local sizee = cc.size(230 , 560)
    if pCell == nil then
        pCell = NewPlayerRewardCell.new(sizee)
        display.commonUIParams(pCell.viewData.toggleView, {animate = false, cb = handler(self, self.CellButtonAction)})
    end

    xTry(function()
        local skinId = checkint(self.datas.cardSkins[index].rareCardSkinId)
        local drawPath = CardUtils.GetCardDrawPathBySkinId(skinId)
        pCell.viewData.imgHero:setTexture(drawPath)

        local cardConf = CardUtils.GetCardSkinConfig(skinId) or {}

        local cardId = cardConf.cardId
        local cardDrawName = CardUtils.GetCardDrawNameBySkinId(skinId)
        local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
        if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
            print('\n**************\n', '立绘坐标信息未找到', cardId, '\n**************\n')
            locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
        else
            locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
        end
        pCell.viewData.imgHero:setScale(locationInfo.scale/100)
        pCell.viewData.imgHero:setRotation( (locationInfo.rotate))
        pCell.viewData.imgHero:setPosition(cc.p(locationInfo.x,(-1)*(locationInfo.y-540)))

        pCell.viewData.heroBg:setTexture(CardUtils.GetCardTeamBgPathBySkinId(skinId))
        --更新技能相关的图标
        pCell.viewData.skillFrame:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
        pCell.viewData.skillIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
        pCell.viewData.qualityIcon:setTexture(CardUtils.GetCardQualityIconPathByCardId(cardId))
        pCell.viewData.entryHeadNode:RefreshUI({skinId = skinId, cb = function ()
            local layer = require('common.CommonCardGoodsDetailView').new({
                goodsId = skinId
            })
            display.commonUIParams(layer, {ap = display.CENTER, po = display.center})
            app.uiMgr:GetCurrentScene():AddDialog(layer)
        end})

        local node = pCell:getChildByName("LIST_CELL_FLAG")
        if node then node:removeFromParent() end
        if self.preIndex == index then
            pCell.viewData.highlightBg:setVisible(true)
            pCell.viewData.spineNode:setVisible(true)
        else
            pCell.viewData.highlightBg:setVisible(false)
            pCell.viewData.spineNode:setVisible(false)
        end
        if cardMgr.IsHaveCardSkin(skinId) then
            local cellFlagNode = display.newButton(sizee.width * 0.5 + 12, 240,{
                    n = RES_DICT.LIST_CELL_FLAG
                })
            cellFlagNode:setName("LIST_CELL_FLAG")
            local label  = cellFlagNode:getLabel()
            label:setRotation(-15)
            display.commonLabelParams(label, {fontSize = 26, color = "4c4c4c", text = __("已获得")})
            cellFlagNode:setEnabled(false)
            pCell:addChild(cellFlagNode, 20)
        else
            if checkint(self.datas.currentCardSkin) > 0 then
                local serverSkinId = checkint(self.datas.currentCardSkin)
                if checkint(skinId) == checkint(serverSkinId) then
                    --当前选择的卡池
                    local cellFlagNode = display.newButton(sizee.width * 0.5 + 12, 180,{
                            n = RES_DICT.LIST_SELECT_IMAGE
                        })
                    cellFlagNode:setName("LIST_CELL_FLAG")
                    display.commonLabelParams(cellFlagNode, {fontSize = 26, color = "ffffff", text = __("本轮选择")})
                    cellFlagNode:setEnabled(false)
                    pCell:addChild(cellFlagNode, 20)
                end
            end
        end

        pCell.viewData.toggleView:setTag(index)
        pCell.viewData.toggleView:setUserTag(skinId)
        pCell:setTag(index)
    end,function()
        pCell = CGridViewCell:new()
    end)

    return pCell
end


function CapsuleSkinEntryView:GetSelectSkinId()
    local skinId = 0
    if self.preIndex > 0 and self.datas.cardSkins then
        skinId = self.datas.cardSkins[self.preIndex].rareCardSkinId
    end
    return tonumber(skinId)
end

--[[
--显示抽卡相关的ui
--]]
function CapsuleSkinEntryView:ShowDrawCardUI(datas)
    self.datas = datas
    self:UpdatePreIndex(datas)
    self:UpdatePreviewBtnShowState(true)
    self.viewData.bottomView:setVisible(true)
    self.viewData.rightView:setVisible(true)
    self.viewData.selectCardView:setVisible(false)
    local leftGamblingTimes = checkint(datas.leftGamblingTimes)
    self.viewData.countLabelBg:setVisible(leftGamblingTimes >= 0 )
    self.viewData.countNumLabel:setString(string.fmt(__("剩余抽卡次数：_num_"), {_num_ = leftGamblingTimes}))
    local currentSkinId = datas.currentCardSkin
    self:UpdateDrawButtonState()
    local oneData = CommonUtils.GetCapsuleConsume(datas.oneConsume)
    local tenData = CommonUtils.GetCapsuleConsume(datas.tenConsume)
    local oncePropNum = checkint(oneData.num)
    local muchPropNum = checkint(tenData.num)
    self.viewData.drawOnceBtn:setTag(oncePropNum)
    self.viewData.drawOnceBtn:setUserTag(checkint(oneData.goodsId))
    self.viewData.drawMuchBtn:setTag(muchPropNum)
    self.viewData.drawMuchBtn:setUserTag(checkint(tenData.goodsId))
    display.reloadRichLabel(self.viewData.onceConsumeRLable, {c = {
                fontWithColor(7, {fontSize = 26, text = __('消耗'), }) ,
                fontWithColor(7, {fontSize = 26, text = string.fmt(' %1 ', oncePropNum)}),
                {img = CommonUtils.GetGoodsIconPathById(oneData.goodsId), scale = 0.2},
        }})
    display.reloadRichLabel(self.viewData.muchConsumeRLable, {c = {
                fontWithColor(7, {fontSize = 26, text = __('消耗'), }) ,
                fontWithColor(7, {fontSize = 26, text = string.fmt(' %1 ', muchPropNum)}),
                {img = CommonUtils.GetGoodsIconPathById(tenData.goodsId), scale = 0.2},
        }})

    local currentSkinId = checkint(self.datas.currentCardSkin)
    if currentSkinId == 0 then
        currentSkinId = checkint(self.datas.cardSkins[1].rareCardSkinId)
    end
    self.viewData.previewNode:RefreshUI({skinId = currentSkinId})
end

function CapsuleSkinEntryView:ResetPoolAction(sender)
    PlayAudioByClickNormal()
    --重新出现选择卡池的界面
    self:ShowSelectCard(self.datas)
end

--[[
--显示选择卡牌的页面
--]]
function CapsuleSkinEntryView:ShowSelectCard(datas)
    self.datas = datas
    -- 刷新卡池详情状态
    local isSelect = checkint(datas.currentCardSkin) > 0
    self:UpdatePreviewBtnShowState(isSelect)
    self.viewData.bottomView:setVisible(false)
    self.viewData.rightView:setVisible(false)
    self.viewData.selectCardView:setVisible(true)
    if checkint(self.datas.currentCardSkin) > 0 or self:IsAllObtained() then
        self.viewData.topTitleBg:setVisible(false)
    else
        self.viewData.topTitleBg:setVisible(true)
    end
    if self:GetSelectedState() then
        self.viewData.selectButton:setVisible(true)
        display.commonLabelParams(self.viewData.selectButton, fontWithColor(14,{text = __('关闭')}))
    else
        if self:IsAllObtained() then
            self.viewData.selectButton:setVisible(true)
            display.commonLabelParams(self.viewData.selectButton, fontWithColor(14,{text = __('关闭')}))
        else
            self.viewData.selectButton:setVisible(false)
        end
    end
    self:UpdatePreIndex(datas)
    self:UpdateGridView(datas.cardSkins)
end
--[[
更新卡池信息按钮状态
--]]
function CapsuleSkinEntryView:UpdatePreviewBtnShowState( show )
    local CapsuleNewMediator = app:RetrieveMediator("CapsuleNewMediator")
    if CapsuleNewMediator then
        CapsuleNewMediator:updatePreviewBtnShowState(show)
    end
end
--[[
获取列表选中状态
--]]
function CapsuleSkinEntryView:GetPreIndex()
    return self.preIndex
end
--[[
更新列表选中状态
--]]
function CapsuleSkinEntryView:UpdatePreIndex( data )
    self.preIndex = self:GetPreIndexByPoolData(data)
end
--[[
获取列表选中状态
--]]
function CapsuleSkinEntryView:GetPreIndexByPoolData( data )
    local currentCardSkin = checkint(data.currentCardSkin)
    for i, v in ipairs(data.cardSkins) do
        if checkint(v.rareCardSkinId) == currentCardSkin then
            return i
        end
    end
    return -1
end
--[[
获取卡池选中状态
return isSelected bool 是否选择过皮肤
--]]
function CapsuleSkinEntryView:GetSelectedState()
    return checkint(self.datas.currentCardSkin) > 0
end
--[[
是否所有皮肤全部获得
--]]
function CapsuleSkinEntryView:IsAllObtained()
    local allObtained = true
    for i, v in ipairs(self.datas.cardSkins) do
        if not app.cardMgr.IsHaveCardSkin(checkint(v.rareCardSkinId)) then
            allObtained = false
            break
        end
    end
    return allObtained
end
--[[
更新按钮状态
--]]
function CapsuleSkinEntryView:UpdateDrawButtonState()
    local leftGamblingTimes = self.datas.leftGamblingTimes
    if leftGamblingTimes < 0 then
        self.viewData.drawMuchBtn:setEnabled(true)
        self.viewData.drawOnceBtn:setEnabled(true)
    else
        self.viewData.drawOnceBtn:setEnabled(leftGamblingTimes > 0)
        self.viewData.drawMuchBtn:setEnabled(leftGamblingTimes >= 10)
    end
end
return CapsuleSkinEntryView
