--[[
-- {
--  iconId = GOLD_ID,
--  discountedValue = "800"
--  discount = '3'
--  text = "抽十次"
-- }
--]]
local CapsuleButton = class('CapsuleButton', function ()
    local node = CLayout:create()
    node.name = 'Game.views.drawCards.CapsuleButton'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
	NEWLAND_BTN_DRAW_LOCK = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_btn_draw_locked.png"),
	NEWLAND_BTN_DRAW = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_btn_draw.png"),
	NEWLAND_LABEL_NUM = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_num.png"),
	NEWLAND_LABEL_SALE = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_sale.png"),
	NEWLAND_LINE_ONE = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_line_1.png"),
	NEWLAND_LINE_SALE = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_line_delete.png"),
	NEWLAND_LABEL_HIGHTLIGHT = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_highlight.png"),
}

function CapsuleButton:ctor(...)
    -- local size = cc.size(156, 376)
    local size = cc.size(344, 122)
    self:setContentSize(size)
    -- self:setBackgroundColor(cc.c4b(100,100,100,100))
    self.viewData = nil

    local args = unpack({...})
    self.id = args.id

    local function CreateView()
        local shotButton = display.newButton(size.width * 0.5, size.height * 0.5, {
                n = RES_DICT.NEWLAND_BTN_DRAW,
                d = RES_DICT.NEWLAND_BTN_DRAW_LOCK
            })
        self:addChild(shotButton, 10)
        display.commonLabelParams(shotButton, fontWithColor(14, {fontSize = 24, color = 'fffffff', text = tostring(args.text), offset = cc.p(0, 10), outline = '80341d', outlineSize = 2}))
        local shotDiscountButton = display.newButton(size.width * 0.5 + 50, 50, {
                n = RES_DICT.NEWLAND_LABEL_SALE, ap = display.LEFT_BOTTOM,
                enable = false
            })
        display.commonLabelParams(shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = string.fmt(__('_num_折'), {_num_ = checkint(args.discount)}), offset = cc.p(44, 0)}))
        if isJapanSdk() then
            display.commonLabelParams(shotDiscountButton, {ap = cc.p(1, 0.5), offset = cc.p(25, 1)})
            if 50 == checkint(args.discount) then
                display.commonLabelParams(shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = __('半价')}))
            end
            shotDiscountButton:setPositionX(176 + display.getLabelContentSize(shotDiscountButton:getLabel()).width)
        end
        self:addChild(shotDiscountButton)
        shotDiscountButton:setVisible(false)
        local discountInfoBg = display.newButton(shotButton:getContentSize().width * 0.5, 52, {
                n = RES_DICT.NEWLAND_LABEL_NUM, enable = false,
            })
        display.commonLabelParams(discountInfoBg, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = tostring(args.discountedValue),outline = 'ba662f', outlineSize = 2}))
        shotButton:addChild(discountInfoBg)
        local discountLine = display.newImageView(RES_DICT.NEWLAND_LINE_SALE, 134,12)
        discountInfoBg:addChild(discountLine, 10)
        local x = discountInfoBg:getLabel():getPositionX() + display.getLabelContentSize(discountInfoBg:getLabel()).width * 0.5 + 2
        if isJapanSdk() then
            display.commonLabelParams(discountInfoBg, {offset = cc.p(10, 0)})
            x = discountInfoBg:getLabel():getPositionX() - display.getLabelContentSize(discountInfoBg:getLabel()).width * 0.5 - 30
        end
        local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(checkint(args.iconId)),x , 12, {ap = display.LEFT_CENTER, scale = 0.14})
        discountInfoBg:addChild(goodsIcon)

        local consumeInfoLabel = display.newRichLabel( size.width * 0.5 , -4, {ap = display.CENTER, r = true,
                c = {
                    fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                    fontWithColor('14',{text = tostring(args.discountedValue), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                    {img = CommonUtils.GetGoodsIconPathById(args.iconId), scale = 0.15},
                    fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
            }})
        display.commonUIParams(consumeInfoLabel, {ap = display.CENTER, po = cc.p(shotButton:getContentSize().width * 0.5, 6)})
        shotButton:addChild(consumeInfoLabel)
        if isJapanSdk() then
            display.reloadRichLabel(consumeInfoLabel, {c = {
                {img = CommonUtils.GetGoodsIconPathById(args.iconId), scale = 0.15},
                fontWithColor('14',{text = tostring(args.discountedValue), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
            }})
        end

        local descr = args.descr or ''
        local greatShowButton = display.newButton(shotButton:getContentSize().width *0.5, 144, {
                n = RES_DICT.NEWLAND_LABEL_HIGHTLIGHT, enable = false,ap = display.CENTER
            })
        -- display.commonLabelParams(greatShowButton, {fontSize = 20, color = 'fffffff', text = descr, offset = cc.p( -4, 2), ap = display.RIGHT_CENTER})
        display.commonLabelParams(greatShowButton, fontWithColor(2,{fontSize = 20, color = 'fffffff', text = descr, offset = cc.p(-20, 4), }))
        shotButton:addChild(greatShowButton, 20)

        -- local path = _res(CardUtils.QUALITY_ICON_PATH_MAP[tostring(CardUtils.QUALITY_TYPE.UR)])
        -- if args.descr and args.type then
            -- path = _res(CardUtils.QUALITY_ICON_PATH_MAP[tostring(args.type)])
        -- end
        -- local qualityIcon = display.newImageView(path, 196, 64)
        -- greatShowButton:addChild(qualityIcon,22)
        if not args.type then
            greatShowButton:setVisible(false)
        end

        self.viewData = {
            shotButton         = shotButton,
            shotDiscountButton = shotDiscountButton,
            discountInfoBg     = discountInfoBg,
            goodsIcon          = goodsIcon,
            consumeInfoLabel   = consumeInfoLabel,
            greatShowButton    = greatShowButton,
            -- qualityIcon        = qualityIcon,
        }

    end

    CreateView()
end


function CapsuleButton:UpdateUI( datas )
    local gamblingTimes = checkint(datas.gamblingTimes)
    local maxGamblingTimes = checkint(datas.maxGamblingTimes)
    local oneGamblingTimes = checkint(datas.oneGamblingTimes)
    local oneDiscountTimes = checkint(datas.oneDiscountTimes)
    local tenGamblingTimes = checkint(datas.tenGamblingTimes)
    local tenDiscountTimes = checkint(datas.tenDiscountTimes)
    local remainGamblingTimes = maxGamblingTimes - gamblingTimes
    local viewData = self.viewData
    --判断是否为首次
    if self.id == 1 then --单抽
        if remainGamblingTimes >= 1 and remainGamblingTimes <= maxGamblingTimes then
            if oneGamblingTimes >= oneDiscountTimes then
                --无打折次数
                viewData.shotDiscountButton:setVisible(false)
                viewData.discountInfoBg:setVisible(false)
                viewData.shotButton:getLabel():setPosition(utils.getLocalCenter(viewData.shotButton))
                -- display.commonLabelParams(viewData.shotButton, fontWithColor(14, {fontSize = 24, color = 'fffffff', offset = cc.p(0, 0), outline = '80341d', outlineSize = 2}))
                local oneConsume = datas.oneConsume[1]
                local showRichTable = {
                    fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                    fontWithColor('14',{text = tostring(oneConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                    {img = CommonUtils.GetGoodsIconPathById(oneConsume.goodsId), scale = 0.15},
                }
                if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
                    if isJapanSdk() then
                        showRichTable = {
                            {img = CommonUtils.GetGoodsIconPathById(oneConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{text = tostring(oneConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    else
                        showRichTable = {
                            fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            fontWithColor('14',{text = tostring(oneConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            {img = CommonUtils.GetGoodsIconPathById(oneConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    end
                end
                display.reloadRichLabel(viewData.consumeInfoLabel, {c = showRichTable})
                --[[ display.reloadRichLabel(viewData.consumeInfoLabel, {c = { ]]
                            -- fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            -- fontWithColor('14',{text = tostring( oneConsume.num),fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            -- {img = CommonUtils.GetGoodsIconPathById(oneConsume.goodsId), scale = 0.15},
                    --[[ fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) }}) ]]
                viewData.shotButton:setTag(checkint(oneConsume.num))
                viewData.shotButton:setUserTag(checkint(oneConsume.goodsId))
            else
                viewData.shotDiscountButton:setVisible(true)
                local oneConsume = datas.oneConsume[1]
                local firstOneConsume = datas.firstOneConsume[1]
                local discountV = checkint(firstOneConsume.num) / checkint(oneConsume.num) * 10
                display.commonLabelParams(viewData.shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = string.fmt(__('_num_折'), {_num_ = discountV})}))
                if isJapanSdk() then
                    discountV = checkint(firstOneConsume.num) / checkint(oneConsume.num) * 100
                    display.commonLabelParams(viewData.shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = string.fmt(__('_num_折'), {_num_ = discountV})}))
                    if 50 == tonumber(discountV) then
                        display.commonLabelParams(viewData.shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = __('半价')}))
                    end
                    viewData.shotDiscountButton:setPositionX(176 + display.getLabelContentSize(viewData.shotDiscountButton:getLabel()).width)
                end
                display.commonLabelParams(viewData.discountInfoBg, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = tostring(oneConsume.num),outline = 'ba662f', outlineSize = 2}))
                viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(checkint(oneConsume.goodsId)))
                viewData.goodsIcon:setScale(0.15)
                local x = viewData.discountInfoBg:getLabel():getPositionX() + display.getLabelContentSize(viewData.discountInfoBg:getLabel()).width * 0.5 + 2
                if isJapanSdk() then
                    x = viewData.discountInfoBg:getLabel():getPositionX() - display.getLabelContentSize(viewData.discountInfoBg:getLabel()).width * 0.5 - 30
                end
                viewData.goodsIcon:setPositionX(x)
                local showRichTable = {
                    fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                    fontWithColor('14',{text = tostring(firstOneConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                    {img = CommonUtils.GetGoodsIconPathById(firstOneConsume.goodsId), scale = 0.15},
                }
                if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
                    if isJapanSdk() then
                        showRichTable = {
                            {img = CommonUtils.GetGoodsIconPathById(firstOneConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{text = tostring(firstOneConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    else
                        showRichTable = {
                            fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            fontWithColor('14',{text = tostring(firstOneConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            {img = CommonUtils.GetGoodsIconPathById(firstOneConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    end
                end
                display.reloadRichLabel(viewData.consumeInfoLabel, {c = showRichTable})
                --[[ display.reloadRichLabel(viewData.consumeInfoLabel, {c = { ]]
                            -- fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            -- fontWithColor('14',{text = tostring( firstOneConsume.num),fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            -- {img = CommonUtils.GetGoodsIconPathById(firstOneConsume.goodsId), scale = 0.15},
                    --[[ fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) }}) ]]
                viewData.shotButton:setTag(checkint(firstOneConsume.num))
                viewData.shotButton:setUserTag(checkint(firstOneConsume.goodsId))
            end
        else
            --已经不可抽了
            viewData.shotButton:setNormalImage(RES_DICT.NEWLAND_BTN_DRAW_LOCK)
            viewData.shotButton:setSelectedImage(RES_DICT.NEWLAND_BTN_DRAW_LOCK)
            viewData.shotButton:getLabel():setPosition(utils.getLocalCenter(viewData.shotButton))
            viewData.shotDiscountButton:setVisible(false)
            viewData.discountInfoBg:setVisible(false)
            viewData.consumeInfoLabel:setVisible(false)
            viewData.greatShowButton:setVisible(false)
            -- viewData.qualityIcon:setVisible(false)
        end
    elseif self.id == 10 then --十抽
        if remainGamblingTimes >= 10 and remainGamblingTimes <= maxGamblingTimes then
            if tenGamblingTimes >= tenDiscountTimes then
                --无打折次数
                viewData.shotDiscountButton:setVisible(false)
                viewData.discountInfoBg:setVisible(false)
                viewData.shotButton:getLabel():setPosition(utils.getLocalCenter(viewData.shotButton))
                local tenConsume = datas.tenConsume[1]
                local showRichTable = {
                    fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                    fontWithColor('14',{text = tostring(tenConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                    {img = CommonUtils.GetGoodsIconPathById(tenConsume.goodsId), scale = 0.15},
                }
                if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
                    if isJapanSdk() then
                        showRichTable = {
                            {img = CommonUtils.GetGoodsIconPathById(tenConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{text = tostring(tenConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    else
                        showRichTable = {
                            fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            fontWithColor('14',{text = tostring(tenConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            {img = CommonUtils.GetGoodsIconPathById(tenConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    end
                end
                display.reloadRichLabel(viewData.consumeInfoLabel, {c = showRichTable})
                --[[ display.reloadRichLabel(viewData.consumeInfoLabel, {c = { ]]
                            -- fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            -- fontWithColor('14',{text = tostring( tenConsume.num),fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            -- {img = CommonUtils.GetGoodsIconPathById(tenConsume.goodsId), scale = 0.15},
                    --[[ fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) }}) ]]
                viewData.shotButton:setTag(checkint(tenConsume.num))
                viewData.shotButton:setUserTag(checkint(tenConsume.goodsId))
            else
                viewData.shotDiscountButton:setVisible(true)
                local tenConsume = datas.tenConsume[1]
                local firstTenConsume = datas.firstTenConsume[1]
                local discountV = checkint(firstTenConsume.num) / checkint(tenConsume.num) * 10
                display.commonLabelParams(viewData.shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = string.fmt(__('_num_折'), {_num_ = discountV})}))
                if isJapanSdk() then
                    discountV = checkint(firstTenConsume.num) / checkint(tenConsume.num) * 100
                    display.commonLabelParams(viewData.shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = string.fmt(__('_num_折'), {_num_ = discountV})}))
                    if 50 == tonumber(discountV) then
                        display.commonLabelParams(viewData.shotDiscountButton, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = __('半价')}))
                    end
                    viewData.shotDiscountButton:setPositionX(176 + display.getLabelContentSize(viewData.shotDiscountButton:getLabel()).width)
                end
                display.commonLabelParams(viewData.discountInfoBg, fontWithColor(14, {fontSize = 22, color = 'fffffff', text = tostring(tenConsume.num),outline = 'ba662f', outlineSize = 2}))
                viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(checkint(tenConsume.goodsId)))
                viewData.goodsIcon:setScale(0.15)
                local x = viewData.discountInfoBg:getLabel():getPositionX() + display.getLabelContentSize(viewData.discountInfoBg:getLabel()).width * 0.5 + 2
                if isJapanSdk() then
                    x = viewData.discountInfoBg:getLabel():getPositionX() - display.getLabelContentSize(viewData.discountInfoBg:getLabel()).width * 0.5 - 30
                end
                viewData.goodsIcon:setPositionX(x)
                local showRichTable = {
                    fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                    fontWithColor('14',{text = tostring(firstTenConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                    {img = CommonUtils.GetGoodsIconPathById(firstTenConsume.goodsId), scale = 0.15},
                }
                if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
                    if isJapanSdk() then
                        showRichTable = {
                            {img = CommonUtils.GetGoodsIconPathById(firstTenConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{text = tostring(firstTenConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    else
                        showRichTable = {
                            fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            fontWithColor('14',{text = tostring(firstTenConsume.num), fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            {img = CommonUtils.GetGoodsIconPathById(firstTenConsume.goodsId), scale = 0.15},
                            fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) ,
                        }
                    end
                end
                display.reloadRichLabel(viewData.consumeInfoLabel, {c = showRichTable})
                --[[ display.reloadRichLabel(viewData.consumeInfoLabel, {c = { ]]
                            -- fontWithColor('14',{fontSize = 22, text = __("消耗"), outline = "5c372c", outlineSize = 2}) ,
                            -- fontWithColor('14',{text = tostring( firstTenConsume.num),fontSize = 22, color = 'd9bc00', outline = "5c372c", outlineSize = 2}),
                            -- {img = CommonUtils.GetGoodsIconPathById(firstTenConsume.goodsId), scale = 0.15},
                    --[[ fontWithColor('14',{fontSize = 22, text = __("(有偿)"), outline = "5c372c", outlineSize = 2}) }}) ]]
                viewData.shotButton:setTag(checkint(firstTenConsume.num))
                viewData.shotButton:setUserTag(checkint(firstTenConsume.goodsId))
            end
            if tenGamblingTimes == 0 then
                --first time
                display.commonLabelParams(viewData.greatShowButton, {fontSize = 20, color = 'fffffff', text = string.fmt(__("首次必出_name_"), {_name_ = 'UR'}), })
                -- local path = _res(CardUtils.QUALITY_ICON_PATH_MAP[tostring(CardUtils.QUALITY_TYPE.UR)])
                -- viewData.qualityIcon:setTexture(path)
            else
                display.commonLabelParams(viewData.greatShowButton, {fontSize = 20, color = 'fffffff', text = string.fmt(__("必出_name_"),{_name = "SR"}), })
                -- local path = _res(CardUtils.QUALITY_ICON_PATH_MAP[tostring(CardUtils.QUALITY_TYPE.SR)])
                -- viewData.qualityIcon:setTexture(path)
                -- display.commonLabelParams(viewData.greatShowButton, {fontSize = 20, color = 'fffffff', text = descr, offset = cc.p( -4, 4), ap = display.RIGHT_CENTER})
            end
        else
            --已经不可抽了
            viewData.shotButton:setNormalImage(RES_DICT.NEWLAND_BTN_DRAW_LOCK)
            viewData.shotButton:setSelectedImage(RES_DICT.NEWLAND_BTN_DRAW_LOCK)
            viewData.shotButton:setEnabled(false)
            viewData.shotButton:getLabel():setPosition(utils.getLocalCenter(viewData.shotButton))
            viewData.shotDiscountButton:setVisible(false)
            viewData.discountInfoBg:setVisible(false)
            viewData.consumeInfoLabel:setVisible(false)
            viewData.greatShowButton:setVisible(false)
            -- viewData.qualityIcon:setVisible(false)
        end
    end
end

function CapsuleButton:SetClick( cb )
    self.viewData.shotButton:setOnClickScriptHandler(cb)
end

return CapsuleButton


