--[[
卡池选择页面view
--]]
local CapsuleCardChooseDrawCardView = class('CapsuleCardChooseDrawCardView', function ()
    local node = CLayout:create()
    node.name = 'Game.views.drawCards.CapsuleCardChooseDrawCardView'
    node:enableNodeEvents()
    return node
end)


local RES_DICT = {
    SUMMON_CHOICE_BG_1 = _res("ui/home/capsuleNew/cardChoose/summon_choice_bg_1.jpg"),
    NEWLAND_BG_BELOW = _res("ui/home/capsuleNew/skinCapsule/summon_activity_bg_bottom.png"),
    NEWLAND_BG_COUNT = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_bg_count.png"),
    NEWLAND_BG_PREVIEW = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_label_preview.png"),
    ORANGE_BTN_N = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    COMMON_BTN_WHITE_DEFAULT = _res('ui/common/common_btn_white_default.png'),
    SELECT_TITLE_BG = _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_title_choice_skin.png'),
    LIST_CELL_FLAG = _res('ui/home/capsuleNew/skinCapsule/summon_choice_bg_get_text.png'),
    LIST_SELECT_IMAGE = _res("ui/home/capsuleNew/skinCapsule/summon_skin_bg_text_choosed.png"),
    NEWLAND_LABEL_HIGHTLIGHT = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_highlight.png"),
    
}

local uiMgr   = app.uiMgr
local cardMgr = app.cardMgr

local EntryNode = require("common.CardPreviewEntranceNode")

local NewPlayerRewardCell = require("Game.views.drawCards.NewPlayerRewardCell")

local CreateView = nil

function CapsuleCardChooseDrawCardView:ctor( ... )
    local args = unpack({...}) or {}
    local size = args.size
    self:setContentSize(size)
    
    self:initUI(size)
end

function CapsuleCardChooseDrawCardView:initUI(size)
    xTry(function ( )
		self.viewData_ = CreateView(size)
        self:addChild(self.viewData_.view)
        self:initView()
	end, __G__TRACKBACK__)
end

function CapsuleCardChooseDrawCardView:initView()
    
end

function CapsuleCardChooseDrawCardView:updateCountNumLabel(text)
    local viewData          = self:getViewData()
    display.commonLabelParams(viewData.countNumLabel, {text = tostring(text)})
end

function CapsuleCardChooseDrawCardView:updateDrawOne(isEnabled, num, goodsId)
    local viewData          = self:getViewData()
    self:updateDrawBtnState(viewData.drawOnceBtn, isEnabled, num, goodsId)
    self:updateDrawConsume(viewData.onceConsumeRLable, num, goodsId)
end

function CapsuleCardChooseDrawCardView:updateDrawMuch(isEnabled, num, goodsId)
    local viewData = self:getViewData()
    self:updateDrawBtnState(viewData.drawMuchBtn, isEnabled, num, goodsId)
    self:updateDrawConsume(viewData.muchConsumeRLable, num, goodsId)
end

function CapsuleCardChooseDrawCardView:updateDrawBtnState(drawBtn, isEnabled, num, goodsId)
    drawBtn:setEnabled(isEnabled)
    drawBtn:setTag(checkint(goodsId))
    drawBtn:setUserTag(checkint(num))
end

function CapsuleCardChooseDrawCardView:updateDrawConsume(rLabel, num, goodsId)
    display.reloadRichLabel(rLabel, {c = {
        fontWithColor(7, {fontSize = 26, text = string.format(__('消耗 %s') , tostring(num))}) ,
        {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2},
    }})
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    local quitBtn = display.newButton(size.width - 16, size.height - 100, {n = RES_DICT.COMMON_BTN_WHITE_DEFAULT, ap = display.RIGHT_TOP , scale9 = true })
	display.commonLabelParams(quitBtn, fontWithColor('14', {text = __('重置') , paddingW = 20 }))
    view:addChild(quitBtn,1)

    --最下方
    local bottomViewSize = cc.size(size.width, 200)
    local bottomView = CLayout:create(bottomViewSize)
    local bgImageView = display.newImageView(RES_DICT.NEWLAND_BG_BELOW, size.width * 0.5, bottomViewSize.height * 0.5, {scale9 = true, size = bottomViewSize})
    bottomView:addChild(bgImageView)
    -- bottomView:setVisible(false)

    local countLabelBg = display.newImageView(RES_DICT.NEWLAND_BG_COUNT, size.width * 0.5, 0, {ap = display.CENTER_BOTTOM, size = cc.size(size.width, 34), scale9 = true})
    local countNumLabel = display.newLabel(size.width * 0.5, 17,{fontSize = 22, color = '#d9c198'})
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

    -------------------------------------------------
    -- much info
    local drawMuchPos = cc.p(size.width/2 + 200, drawOncePos.y)
    local drawMuchBtn = display.newButton(drawMuchPos.x, drawMuchPos.y, {n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    display.commonLabelParams(drawMuchBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\nX_num_'), {_num_ = 10})}))
    drawMuchBtn:setEnabled(false)
    bottomView:addChild(drawMuchBtn)

    local muchConsumeRLable = display.newRichLabel(drawMuchPos.x, onceConsumeRLable:getPositionY())
    bottomView:addChild(muchConsumeRLable)

    local greatShowButton = display.newButton(drawMuchBtn:getContentSize().width *0.5, 96, {
        n = RES_DICT.NEWLAND_LABEL_HIGHTLIGHT, enable = false, ap = display.CENTER
    })
    display.commonLabelParams(greatShowButton, {fontSize = 20, offset = cc.p(-15, 4), ap = display.RIGHT_CENTER , hAlign = display.TAR ,  color = 'fffffff', text = "" or  __("必出")})
    drawMuchBtn:addChild(greatShowButton)
    greatShowButton:setVisible(false)
    local greatShowButtonSize = greatShowButton:getContentSize()
    local cardQualityIcon = display.newNSprite(CardUtils.QUALITY_ICON_PATH_MAP['3'], greatShowButtonSize.width - 120, greatShowButtonSize.height / 2 + 8, { ap = display.CENTER })
    greatShowButton:addChild(cardQualityIcon)
    return {
        view              = view,
        quitBtn           = quitBtn,
        bottomView        = bottomView,
        countNumLabel     = countNumLabel,
        drawOnceBtn       = drawOnceBtn,
        drawMuchBtn       = drawMuchBtn,
        onceConsumeRLable = onceConsumeRLable,
        muchConsumeRLable = muchConsumeRLable,
    }
end


function CapsuleCardChooseDrawCardView:getViewData()
    return self.viewData_
end

return CapsuleCardChooseDrawCardView
