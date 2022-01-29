local CommonDialog = require('common.CommonDialog')
local NewPlayerDrawRewardPanel = class('NewPlayerDrawRewardPanel', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local NewPlayerRewardCell = require("Game.views.drawCards.NewPlayerRewardCell")
--[[
override
initui
--]]
function NewPlayerDrawRewardPanel:InitialUI()
    self.preIndex = 0
    self:setName('NewPlayerDrawRewardPanel')
    self.cardDatas = self.args.datas
    local function CreateView()
        local size = cc.size(1126, 634)
        ---正式的内容页面
        local cview = CLayout:create(size)
        local bg = display.newImageView(_res(string.format( "ui/common/common_bg_%d.png", 5)), 0, 0)
        display.commonUIParams(bg, { ap = display.LEFT_BOTTOM, po = cc.p(0, 0)})
        cview:setName("CONTENT_VIEW")
        cview:addChild(bg)
        -- title
        local offsetY = 4
        local titleBg = display.newButton(bg:getContentSize().width * 0.5 + 12, size.height - offsetY, {n = _res('ui/common/common_bg_title_2.png'), enable = false})
        display.commonUIParams(titleBg, {ap = display.CENTER_TOP})
        titleBg:setEnabled(false)
        display.commonLabelParams(titleBg, fontWithColor(1,{fontSize = 24, text = __('选择奖励'), color = 'ffffff',offset = cc.p(0, -2)}))
        bg:addChild(titleBg,2)
        -- cview:setBackgroundColor(cc.c4b(100,100,100,100))
                -- 领取按钮
        local drawRewardButton = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'),
            d = _res("ui/common/common_btn_orange_disable.png")})
        display.commonUIParams(drawRewardButton, {po = cc.p(936, 82)})
        display.commonLabelParams(drawRewardButton, fontWithColor(14,{text = __('确定')}))
        drawRewardButton:setName('GET_BUTTON')
        cview:addChild(drawRewardButton)
        drawRewardButton:setEnabled(false)
        drawRewardButton:setTag(103)
        drawRewardButton:setOnClickScriptHandler(handler(self, self.ButtonAction))


        local bgImage = display.newImageView(_res("ui/common/common_bg_goods.png"),42,20,{ap = display.LEFT_BOTTOM, scale9 = true , size = cc.size(720,560)})
        cview:addChild(bgImage)
        local taskListSize =cc.size(690, 560)
        local gridView = CTableView:create(taskListSize)
        gridView:setName('gridView')
        gridView:setSizeOfCell(cc.size(230, 560))
        gridView:setAutoRelocate(true)
        gridView:setDirection(eScrollViewDirectionHorizontal)
        cview:addChild(gridView,2)
        gridView:setAnchorPoint(cc.p(0, 0))
        gridView:setDragable(false)
        gridView:setPosition(cc.p(42, 20))

        local showSelectedLabel = display.newLabel(936, 474, {fontSize = 24, color = "5b3c25", text = __("已选择飨灵")})
        cview:addChild(showSelectedLabel, 2)
        showSelectedLabel:setVisible(false)

        local lineOne = display.newImageView(_res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_line_1.png"),936, 452)
        cview:addChild(lineOne,2)

        local lineTwo = display.newImageView(_res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_line_1.png"),936, 176)
        cview:addChild(lineTwo,2)

        local selectLabel = display.newLabel(936, 314, fontWithColor(7,{fontSize = 24, color = '5b3c25', text = __('请选择想要获得的飨灵'), w = 122}))
        cview:addChild(selectLabel, 20)
        -- selectLabel:setVisible(false)

        local headIconView = CLayout:create(cc.size(308,226))
        -- headIconView:setBackgroundColor(cc.c4b(100,100,100,100))
        display.commonUIParams(headIconView, {po = cc.p(936, 314)})
        cview:addChild(headIconView,2)
        headIconView:setVisible(false)
        local headBg = display.newImageView(_res("ui/common/common_bg_tips_common.png"), 154, 134, {scale9= true, size = cc.size(140, 140)})
        headIconView:addChild(headBg)
        local goodsNode = require('common.GoodNode').new({
                id = CardUtils.DEFAULT_CARD_ID,
                -- callBack = function (sender)
                    -- PlayAudioByClickNormal()
                -- end
            })
        goodsNode:setPosition(utils.getLocalCenter(headBg))
        headBg:addChild(goodsNode)

        local cardNameLabel = display.newLabel(154, 36, fontWithColor(14,{fontSize = 24, color = "ffffff", text = '', outline = "5b3c25", outlineSize = 2}))
        headIconView:addChild(cardNameLabel,2)
        return {
            view = cview,
            drawRewardButton = drawRewardButton,
            gridView = gridView,
            showSelectedLabel = showSelectedLabel,
            headIconView = headIconView,
            selectLabel = selectLabel,
            goodsNode = goodsNode,
        }
    end

    self.viewData = CreateView()
    self:UpdateGridView(self.cardDatas)
end


function NewPlayerDrawRewardPanel:UpdateGridView( datas )
    if datas and #datas > 0 then
        self.viewData.gridView:setCountOfCell(#datas)
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
        self.viewData.gridView:reloadData()
    end
end


function NewPlayerDrawRewardPanel:CellButtonAction(sender)
    PlayAudioByClickNormal()
    local index = sender:getTag()
    if index == self.preIndex then return end
    local cell = self.viewData.gridView:cellAtIndex(index - 1)
    if cell then
        self.preIndex = index
        self.viewData.drawRewardButton:setEnabled(true)
        local cardId = sender:getUserTag()
        self.viewData.gridView:reloadData()
        --更新右侧的内容
        self.viewData.showSelectedLabel:setVisible(true)
        self.viewData.selectLabel:setVisible(false)
        self.viewData.headIconView:setVisible(true)
        --更橷goodsNode
        self.viewData.goodsNode:RefreshSelf({goodsId = cardId})
    end
end

function NewPlayerDrawRewardPanel:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local sizee = cc.size(230 , 560)
    if pCell == nil then
        pCell = NewPlayerRewardCell.new(sizee)
        display.commonUIParams(pCell.viewData.toggleView, {animate = false, cb = handler(self, self.CellButtonAction)})
    end

    xTry(function()
        local data = self.cardDatas[index]
        local cardId = data.goodsId
        local drawPath = CardUtils.GetCardDrawPathByCardId(cardId)
        pCell.viewData.imgHero:setTexture(drawPath)

        -- local cardConf = CardUtils.GetCardConfig(cardId) or {}

        local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardId)
        if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
            print('\n**************\n', '立绘坐标信息未找到', cardId, '\n**************\n')
            locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
        else
            locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
        end
        pCell.viewData.imgHero:setScale(locationInfo.scale/100)
        pCell.viewData.imgHero:setRotation( (locationInfo.rotate))
        pCell.viewData.imgHero:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) - 148))

        pCell.viewData.heroBg:setTexture(CardUtils.GetCardTeamBgPathByCardId(cardId))
        --更新技能相关的图标
        pCell.viewData.skillFrame:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
        pCell.viewData.skillIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
        pCell.viewData.qualityIcon:setTexture(CardUtils.GetCardQualityIconPathByCardId(cardId))
        pCell.viewData.entryHeadNode:RefreshUI({confId = cardId})

        if self.preIndex == index then
            pCell.viewData.highlightBg:setVisible(true)
            pCell.viewData.spineNode:setVisible(true)
        else
            pCell.viewData.highlightBg:setVisible(false)
            pCell.viewData.spineNode:setVisible(false)
        end
        pCell.viewData.toggleView:setTag(index)
        pCell.viewData.toggleView:setUserTag(cardId)
        pCell:setTag(index)
    end,function()
        pCell = CGridViewCell:new()
    end)

    return pCell
end


function NewPlayerDrawRewardPanel:ButtonAction(sender)
    PlayAudioByClickNormal()
    if self.preIndex > 0 then
        local data = self.cardDatas[self.preIndex]
        local rewardId = data.rewardId
        AppFacade.GetInstance():DispatchSignal(POST.GAMBLING_NEWBIE_FINAL_DRAW.cmdName , {rewardId = rewardId})
    end
end

return NewPlayerDrawRewardPanel


