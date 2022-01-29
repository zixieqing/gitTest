--[[
卡池选择页面view
--]]
local CapsuleNewPlayerView = class('CapsuleNewPlayerView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleNewPlayerView'
    node:enableNodeEvents()
    return node
end)


local RES_DICT = {
	NEWLAND_BG_BELOW = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_bg_below.png"),
	NEWLAND_BG_COUNT = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_bg_count.png"),
	NEWLAND_BG_PREVIEW = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_bg_preview.png"),
	NEWLAND_BTN_DRAW_LOCK = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_btn_draw_locked.png"),
	NEWLAND_BTN_DRAW = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_btn_draw.png"),
	NEWLAND_FRAME_LIGHT = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_frame_light.png"),
	NEWLAND_LABEL_HIGHTLIGHT = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_highlight.png"),
	NEWLAND_LABEL_NUM = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_num.png"),
	NEWLAND_LABEL_PREVIEW = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_preview.png"),
	NEWLAND_LABEL_SALE = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_sale.png"),
	NEWLAND_LINE_ONE = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_line_1.png"),
	NEWLAND_LINE_SALE = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_line_delete.png"),
	NEWLAND_REWARDS_PROGRESS = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_rewards_bar_active.png"),
	NEWLAND_REWARDS_PROGRESS_BG = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_rewards_bar_gray.png"),
	NEWLAND_REWARDS_BG = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_rewards_bg.png"),
	NEWLAND_REWARDS_FRAME_BG = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_rewards_frame_light.png"),
	NEWLAND_REWARDS_LABEL = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_rewards_label_text.png"),
    GIFT_ICON_IMAGE = _res('arts/goods/goods_icon_701023.png')
}

local CapsuleButton = require("Game.views.drawCards.CapsuleButton")
local EntryNode = require("common.CardPreviewEntranceNode")

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")


function CapsuleNewPlayerView:ctor( ... )
	local args = unpack({...})

	local size = args.size
	self:setContentSize(size)
	-- self:setBackgroundColor(cc.c4b(255,255,255,100)) --调试用

    self.viewData = nil
    --右侧面板
    local rSize = cc.size(162, 380)
	local view = CLayout:create(rSize)
    if not isJapanSdk() then
        local topNameLabel = display.newButton(rSize.width * 0.5 +75, rSize.height,{
            n = RES_DICT.NEWLAND_LABEL_PREVIEW, ap = display.RIGHT_TOP , scale9 = true
        })
        display.commonLabelParams(topNameLabel, fontWithColor(14, {paddingW = 10 ,  text = __('飨灵预览')}))
        topNameLabel:setEnabled(false)
        view:addChild(topNameLabel,1)
    end

    --bg
    if isJapanSdk() then
        local bgImage = display.newImageView(RES_DICT.NEWLAND_BG_PREVIEW, rSize.width, rSize.height - 26,{ap = display.RIGHT_TOP, scale9 = true, size = cc.size(136, 350)})
        view:addChild(bgImage)
    else
        local bgImage = display.newImageView(RES_DICT.NEWLAND_BG_PREVIEW, rSize.width, rSize.height,{ap = display.RIGHT_TOP})
        view:addChild(bgImage)
    end

    local listSize = cc.size(120, 330)
    local previewListView = CListView:create(listSize)
    previewListView:setPosition(cc.p(rSize.width, 10))
    previewListView:setDirection(eScrollViewDirectionVertical)
    previewListView:setAnchorPoint(display.RIGHT_BOTTOM)
    previewListView:setBounceable(false)
    view:addChild(previewListView)

    display.commonUIParams(view, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width - 16, 184)})
    self:addChild(view,1)
    --最下方

    local bottomView = CLayout:create(cc.size(size.width, 186))
    local bgImageView = display.newImageView(RES_DICT.NEWLAND_BG_BELOW, size.width * 0.5, 186 * 0.5, {scale9 = true, size = cc.size(size.width, 186)})
    bottomView:addChild(bgImageView)
    if isJapanSdk() then
        display.commonUIParams(bgImageView, {po = cc.p(size.width * 0.5, 0), ap = display.CENTER_BOTTOM})
        bgImageView:setContentSize(cc.size(size.width, 170))
    end

    local countLabelBg = display.newImageView(RES_DICT.NEWLAND_BG_COUNT, size.width * 0.5, 0, {ap = display.CENTER_BOTTOM, size = cc.size(size.width, 34), scale9 = true})
    local countNumLabel = display.newLabel(size.width * 0.5, 17,{text = string.fmt(__("剩余抽卡次数：_num_"), {_num_ = 0}), fontSize = 22, color = 'd9c198'})
    countLabelBg:addChild(countNumLabel,2)
    if isJapanSdk() then
        countLabelBg:setVisible(false)
    end
    bottomView:addChild(countLabelBg)
    display.commonUIParams(bottomView, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.5, 0)})
    self:addChild(bottomView)


    --[[ local oneshotButton = CapsuleButton.new({ ]]
            -- id = 1,
            -- iconId = GOLD_ID,
            -- discount = 0,
            -- discountedValue = 0,
            -- text = __("抽一次")
        -- })
    -- display.commonUIParams(oneshotButton, {po = cc.p(size.width * 0.25, 120)})
    -- bottomView:addChild(oneshotButton)

    local tenShotButton = CapsuleButton.new({
            id = 10,
            iconId = DIAMOND_ID,
            discount = 0,
            discountedValue = 0,
            text = __("十连召唤"),
            descr = __("首次必出"),
            type = CardUtils.QUALITY_TYPE.SR
        })
    display.commonUIParams(tenShotButton, {po = cc.p(size.width * 0.5, 120)})
    bottomView:addChild(tenShotButton)

    if isJapanSdk() then
        display.commonUIParams(oneshotButton, {po = cc.p(size.width * 0.25, 100)})
        display.commonUIParams(tenShotButton, {po = cc.p(size.width * 0.71, 100)})
    end
    --[[
    --中间抽卡进度相关的页面
    --]]
    local cSize = cc.size(562, 128)
    local centerView = CLayout:create(cSize)
    -- centerView:setBackgroundColor(cc.c4b(200,100,200,100))
    display.commonUIParams(centerView, {po = cc.p(size.width * 0.5 - 65, 218-20), ap = display.CENTER_BOTTOM})
    if isJapanSdk() then
        display.commonUIParams(centerView, {po = cc.p(size.width * 0.5 - 65, 218-40)})
    end
    self:addChild(centerView,2)
    local bgGrow = display.newImageView(RES_DICT.NEWLAND_REWARDS_FRAME_BG, cSize.width * 0.5, cSize.height * 0.5)
    centerView:addChild(bgGrow)
    bgGrow:setVisible(false)

    local bgGrowButton = display.newButton(cSize.width * 0.5, cSize.height * 0.5,{
            n = RES_DICT.NEWLAND_REWARDS_BG,
            s = RES_DICT.NEWLAND_REWARDS_BG,
        })
    centerView:addChild(bgGrowButton,2)
    -- centerView:addChild(bgGrow)
    -- local bgNoGrow = display.newImageView(RES_DICT.NEWLAND_REWARDS_BG, cSize.width * 0.5, cSize.height * 0.5)
    -- centerView:addChild(bgNoGrow)

    local topTitleButton = display.newButton(cSize.width * 0.5, cSize.height - 30, {
            n = RES_DICT.NEWLAND_REWARDS_LABEL, ap = display.CENTER_TOP
        })
    display.commonLabelParams(topTitleButton, {fontSize = 20, color = 'ffffff', text = string.fmt(__('累计抽卡_num_ 次奖励'), {_num_ = 100})})
    topTitleButton:setEnabled(false)
    centerView:addChild(topTitleButton, 10)
    local progressBar = CProgressBar:create(RES_DICT.NEWLAND_REWARDS_PROGRESS)
    progressBar:setBackgroundImage(RES_DICT.NEWLAND_REWARDS_PROGRESS_BG)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setAnchorPoint(cc.p(0.5, 1))
    progressBar:setMaxValue(100)
    progressBar:setValue(0)
    progressBar:setShowValueLabel(true)
    display.commonLabelParams(progressBar:getLabel(),{fontSize = 20})
    progressBar:setPosition(cc.p(cSize.width * 0.5, cSize.height - 66))
    centerView:addChild(progressBar,5)

    local giftIcon = display.newImageView(RES_DICT.GIFT_ICON_IMAGE, 510, cSize.height * 0.76, {enable = true})
    giftIcon:setRotation(10)
    centerView:addChild(giftIcon,10)
    giftIcon:setOnClickScriptHandler(function(sender)
        uiMgr:ShowInformationTipsBoard({targetNode = giftIcon, type = 1, iconId = 889999})
    end)

    view:setVisible(false)
    bottomView:setVisible(false)

    self.viewData = {
        rightView = view,
        previewListView = previewListView,
        rewardDrawNumLabel = topTitleButton,
        progressBar = progressBar,
        centerView = centerView,
        bgGrow     = bgGrow,
        bgGrowButton = bgGrowButton,
        bottomView = bottomView,
        countNumLabel = countNumLabel,
        oneshotButton = oneshotButton,
        tenShotButton = tenShotButton,
    }
end

--[[
--刷新卡牌小头像列表
--]]
function CapsuleNewPlayerView:RefreshCardList(datas)
    if datas and next(datas) ~= nil then
        self.viewData.previewListView:removeAllNodes()
        for _, v in pairs(datas) do
            local cell = CLayout:create(cc.size(106,108))
            local node = EntryNode.new({confId = v.goodsId, cardDrawChangeType = 1})
            node:setPosition(utils.getLocalCenter(cell))
            cell:addChild(node)
            self.viewData.previewListView:insertNodeAtLast(cell)
        end
        self.viewData.previewListView:reloadData()
    end
end

return CapsuleNewPlayerView
