--[[
通用提示弹窗
@params {
    text/textRich      string/table   标题
    descr/descrRich    string/table   附加提示(带TIP:开头)
    extra              string         描述(正常描述)
    defaultRichPattern bool           是否使用默认的字体样式
    callback           function       确认按钮回调
    cancelBack         function       取消按钮回调
    isOnlyOK           bool           是否至展示确认按钮
    hideAllButton      bool           是否隐藏所有按钮
    textLLabel         string         左侧按钮文本，默认为取消
    textRLabel         string         右侧按钮文本，默认为确定
    costInfo           table          消耗信息 {goodsId = 0, num = 0}

    isShowOwnTips      bool           是否展示信息提示
    ownTips            string         拥有信息的提示
    isShowOwn          bool           是否展示拥有的信息
    ownGoodsId         init           拥有的道具id(不传默认为costInfo的goosId)

    isShowGoodsTips    bool           是否展示道具信息提示
    goodsNodeTips      string         上方的道具图标提示
    isShowGoodsNode    bool           是否通过展示道具node的形式展示消耗信息
    goodsNodeInfo      table          展示道具node(不传默认为costInfo)
}
--]]
local GameScene = require( "Frame.GameScene" )
local CommonTipNew = class('CommonTipNew', GameScene)
local uiMgr     = AppFacade.GetInstance():GetManager('UIManager')

local RES_DICT = {
    BG_FRAME    = _res('ui/common/common_bg_8.png'),
    CANCEL_BTN  = _res('ui/common/common_btn_white_default.png'),
    ENTRY_BTN   = _res('ui/common/common_btn_orange.png'),
    CONFIRM_BTN = _res('ui/common/common_btn_green.png'),
    NUM_BG      = _res('ui/common/maze_clear_quantity_bg.png'),
}

function CommonTipNew:ctor( ... )
    local arg = unpack({...})
    self.args = arg
    self:init()
end


function CommonTipNew:init()
    self.text               = self.args.text
    self.extra              = self.args.extra
    self.callback           = self.args.callback
    self.cancelBack         = self.args.cancelBack
    self.isOnlyOK           = self.args.isOnlyOK == true
    self.hideAllButton      = self.args.hideAllButton == true
    self.descr              = self.args.descr
    self.textLLabel         = self.args.textLLabel or __("取消")
    self.textRLabel         = self.args.textRLabel or __("确定")
    self.ownGoodsId         = self.args.ownGoodsId
    self.goodsNodeInfo      = self.args.goodsNodeInfo
    self.isShowOwn          = self.args.isShowOwn == true
    self.isShowGoodsNode    = self.args.isShowGoodsNode == true
    self.textRich           = self.args.textRich
    self.descrRich          = self.args.descrRich
    self.defaultRichPattern = self.args.defaultRichPattern
    self.costInfo           = self.args.costInfo
    self.ownTips            = self.args.ownTips
    self.goodsNodeTips      = self.args.goodsNodeTips
    self.isShowOwnTips      = self.args.isShowOwn ~= false
    self.isShowGoodsTips = self.args.isShowGoodsTips ~= false

    if not self.ownGoodsId and self.isShowOwn and self.args.costInfo then
        self.ownGoodsId = self.args.costInfo.goodsId
    end

    if not self.goodsNodeInfo and self.isShowGoodsNode and self.args.costInfo then
        self.goodsNodeInfo = self.args.costInfo
    end

    self:setPosition(self.args.po or display.center)
    self:initView()
end


function CommonTipNew:initView()
    -- commonBg
    local commonBG = require('common.CloseBagNode').new({callback = function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end})
    commonBG:setPosition(utils.getLocalCenter(self))
    self:addChild(commonBG)

    -- outline
    local viewSize = cc.size(display.size.width/3,display.size.height/3)
    local outline  = ui.image({img = RES_DICT.BG_FRAME, scale9 = true, size = viewSize, ap = ui.lb})

    -- view
    local view = ui.layer({ap = ui.cc, p = display.center, size = viewSize})
    view:addChild(outline)

    local viewGroup     = {}
    local viewTotalSizeH = 0
    if self.text then
        local fontSize = self.descr and 24 or 26
        local tip      = ui.label({fontSize = fontSize, color = "#4c4c4c", w = viewSize.width - 75, hAlign = cc.TEXT_ALIGNMENT_CENTER, ap = ui.ct, text = self.text})
        table.insert(viewGroup, tip)

        viewTotalSizeH = display.getLabelContentSize(tip).height + viewTotalSizeH
    elseif self.textRich then
        if self.defaultRichPattern then
            for i,v in ipairs(self.textRich) do
                v.fontSize = v.fontSize or 26
                v.color = v.color or '#4c4c4c'
            end
        end
        local tip       = ui.rLabel({r = true, c = self.textRich, w = viewSize.width - 75, ap = ui.ct})
        local tipSizeW  = tip:getContentSize().width
        if tipSizeW > 370 then
            tip:setScale(370 / tipSizeW)
        end

        table.insert(viewGroup, tip)

        viewTotalSizeH = tip:getContentSize().height + viewTotalSizeH
    end

    local paddingH = 5
    if self.descr then
        local descrTip = ui.label({mt = paddingH, ap = ui.ct, fnt = FONT.D15, w = viewSize.width -100, hAlign = cc.TEXT_ALIGNMENT_CENTER, text = string.fmt('Tips: _text_', {_text_ = self.descr })})
        table.insert(viewGroup, descrTip)

        viewTotalSizeH = display.getLabelContentSize(descrTip).height + viewTotalSizeH + paddingH

    elseif self.descrRich then
        table.insert(self.descrRich, 1, fontWithColor('15', {text = __('Tips: ')}))
        if self.defaultRichPattern then
            for i,v in ipairs(self.descrRich) do
                v.fontSize = v.fontSize or fontWithColor('15').fontSize
                v.color = v.color or fontWithColor('15').color
            end
        end
        -- 有图片的情况下不支持换行
        local descrTipW = 40 
        for i, v in ipairs(checktable(self.descrRich)) do
            if v.img then
                descrTipW = 300
                break
            end
        end
        local descrTip = ui.rLabel({r = true, c = self.descrRich, w = descrTipW, ap = ui.ct, paddingH = paddingH})

        table.insert(viewGroup, descrTip)

        viewTotalSizeH = descrTip:getContentSize().height + viewTotalSizeH
    end

    if self.extra then
        paddingH = 10
        local extraTip = ui.label({fontSize = 18, color = '#FF7c7c', w = viewSize.width - 75, hAlign = cc.TEXT_ALIGNMENT_CENTER, text = self.extra, mt = paddingH})
        table.insert(viewGroup, extraTip)

        viewTotalSizeH = display.getLabelContentSize(extraTip).height + viewTotalSizeH + paddingH
    end

    if self.ownGoodsId then
        local layerGroup = {}
        local layerH     = 0
        if self.isShowOwnTips then
            local title = ui.label({fnt = FONT.D9, color = "#765439", ap = ui.ct, text = self.ownTips or string.fmt(__("当前拥有_name_:"), {_name_ = GoodsUtils.GetGoodsNameById(self.ownGoodsId)})})
            table.insert(layerGroup, title)
            layerH = layerH + display.getLabelContentSize(title).height
        end

        local icon      = ui.image({img = GoodsUtils.GetIconPathById(self.ownGoodsId), scale = 0.3})
        local iconLayer = ui.layer({size = cc.size(viewSize.width - 50, icon:getContentSize().height * 0.3)})
        local num       = ui.title({n = RES_DICT.NUM_BG}):updateLabel({fnt = FONT.D4, fontSize = 26, color = "#ffffff", text = app.goodsMgr:GetGoodsAmountByGoodsId(self.ownGoodsId)})
        iconLayer:addList({icon, num})
        ui.flowLayout(cc.sizep(iconLayer, ui.cc), {icon, num}, {type = ui.flowH, ap = ui.cc})
        table.insert(layerGroup, iconLayer)
        layerH = layerH + iconLayer:getContentSize().height

        paddingH = 30
        local gapH  = 5
        local layer = ui.layer({size = cc.size(viewSize.width - 50, layerH + gapH * #layerGroup - gapH), mt = paddingH})
        layer:addList(layerGroup)
        ui.flowLayout(cc.sizep(layer, ui.cc), layerGroup, {type = ui.flowV, ap = ui.cc, gapH = 5})


        table.insert(viewGroup, layer)
        viewTotalSizeH = layer:getContentSize().height + viewTotalSizeH + paddingH
    end

    if self.goodsNodeInfo then
        local layerGroup = {}
        local layerH     = 0
        if self.isShowGoodsTips then
            local costLabel  = ui.label({fnt = FONT.D15, text = self.goodsNodeTips or string.fmt(__("消耗_name_："), {_name_ = GoodsUtils.GetGoodsNameById(self.goodsNodeInfo.goodsId)}), ap = ui.ct})
            table.insert(layerGroup, costLabel)
            layerH = layerH + display.getLabelContentSize(costLabel).height
        end
        local goodsNode  = ui.goodsNode({id = self.goodsNodeInfo.goodsId, amount = self.goodsNodeInfo.num, showAmount = true, scale = 0.9})
        table.insert(layerGroup, goodsNode)
        layerH = layerH + goodsNode:getContentSize().height

        paddingH    = 20
        local gapH  = 5
        local layer = ui.layer({size = cc.size(viewSize.width - 50, layerH + gapH * #layerGroup - gapH), mt = paddingH})
		layer:addList(layerGroup)
        ui.flowLayout(cc.sizep(layer, ui.cc), layerGroup, {type = ui.flowV, ap = ui.cc, gapH = gapH})

        table.insert(viewGroup, layer)
        viewTotalSizeH = layer:getContentSize().height + viewTotalSizeH + paddingH
    end

    if not self.hideAllButton then
        paddingH  = 20
        local btnLayer  = ui.layer({size = cc.size(viewSize.width - 60, 80), mt = paddingH})
        local btnList   = {}
        if not self.isOnlyOK then
            local cancelBtn = ui.button({n = RES_DICT.CANCEL_BTN, cb = handler(self, self.onClickCancelBtnHandler_)})
            cancelBtn:updateLabel({fnt = FONT.D14, text = self.textLLabel})
            table.insert(btnList, cancelBtn)
        end
    
        local entryBtn = ui.button({n = RES_DICT.ENTRY_BTN, cb = handler(self, self.onClickConfirmBtnHandler_)})
        if self.costInfo then
            local costRLabel = ui.rLabel({r = true, c = {
                {img = CommonUtils.GetGoodsIconPathById(self.costInfo.goodsId), scale = 0.25},
                fontWithColor('14', {text = "x" .. self.costInfo.num, color = "#765439"}),
            }})
            entryBtn:addList(costRLabel):alignTo(nil, ui.cc)
        else
            entryBtn:updateLabel({fnt = FONT.D14, text = self.textRLabel})
        end
        table.insert(btnList, entryBtn)

        if #btnList > 0 then
            btnLayer:addList(btnList)
            ui.flowLayout(cc.sizep(btnLayer, ui.cc), btnList, {type = ui.flowH, ap = ui.cc, gapW = 80})
        end

        table.insert(viewGroup, btnLayer)

        viewTotalSizeH = btnLayer:getContentSize().height + viewTotalSizeH + paddingH
    end

    view:addList(viewGroup)

    local gapH    = 0
    local padding = 50
    local delta   = #viewGroup * gapH + padding

    if viewTotalSizeH + delta > viewSize.height then
        view:setContentSize(cc.size(viewSize.width, viewTotalSizeH + delta))
        outline:setContentSize(cc.size(viewSize.width, viewTotalSizeH + delta))
        commonBG:addContentView(view)
    else
        commonBG:addContentView(view)
        gapH = (viewSize.height - viewTotalSizeH - padding) / #viewGroup
    end
    ui.flowLayout(cc.rep(cc.sizep(view, ui.cc), 0, -15), viewGroup, {type = ui.flowV, ap = ui.cc, gapH = gapH})
end

function CommonTipNew:onClickCancelBtnHandler_()
    PlayAudioByClickClose()
    if self.cancelBack then
        self.cancelBack()
    end
    self:runAction(cc.RemoveSelf:create())
end

function CommonTipNew:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()

    if self.callback then
        self.callback()
    end
    self:runAction(cc.RemoveSelf:create())
end


return CommonTipNew
