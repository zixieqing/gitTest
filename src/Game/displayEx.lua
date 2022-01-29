--[[
 * author : kaishiqi
 * descpt : 开新坑了
]]

-- 字体定义
FONT = {
    --         = defalut
    D1         = fontWithColor(1),   -- { fontSize = 28, color = '#493328', font = TTF_GAME_FONT, ttf = true                                      }, -- 大标题01
    D2         = fontWithColor(2),   -- { fontSize = 26, color = '#2b2017', font = TTF_GAME_FONT, ttf = true                                      }, -- 侧页签按钮文字01
    D3         = fontWithColor(3),   -- { fontSize = 24, color = '#ffffff'                                                                        }, -- 大标题02
    D4         = fontWithColor(4),   -- { fontSize = 24, color = '#76553b'                                                                        }, -- 副标题01
    D5         = fontWithColor(5),   -- { fontSize = 22, color = '#7e6454'                                                                        }, -- 副标题02
    D6         = fontWithColor(6),   -- { fontSize = 22, color = '#5c5c5c'                                                                        }, -- 正文01
    D7         = fontWithColor(7),   -- { fontSize = 28, color = '#ffffff', font = TTF_GAME_FONT, ttf = true                                      }, -- 侧页签按钮文字02
    D8         = fontWithColor(8),   -- { fontSize = 20, color = '#78564b'                                                                        }, -- 通用数字01
    D9         = fontWithColor(9),   -- { fontSize = 20, color = '#ffffff'                                                                        }, -- 通用数字02
    D10        = fontWithColor(10),  -- { fontSize = 20, color = '#d23d3d'                                                                        }, -- 强调的数字
    D11        = fontWithColor(11),  -- { fontSize = 22, color = '#b1613a'                                                                        }, -- 道具标题
    D12        = fontWithColor(12),  -- { fontSize = 20, color = '#ffffff'                                                                        }, -- 上页签按钮选中
    D13        = fontWithColor(13),  -- { fontSize = 20, color = '#826d5e'                                                                        }, -- 上页签按钮未选中
    D14        = fontWithColor(14),  -- { fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#734441'                 }, -- 按钮01
    D15        = fontWithColor(15),  -- { fontSize = 20, color = '#7c7c7c'                                                                        }, -- tips
    D16        = fontWithColor(16),  -- { fontSize = 22, color = '#5b3c25'                                                                        }, -- 类型
    D17        = fontWithColor(17),  -- { fontSize = 22, color = '#e0491a'                                                                        }, -- 侧页签按钮3
    D18        = fontWithColor(18),  -- { fontSize = 22, color = '#ffffff'                                                                        }, -- 通用描述类文字
    D19        = fontWithColor(19),  -- { fontSize = 28, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#311717'                 }, -- 大标题03
    D20        = fontWithColor(20),  -- { fontSize = 50, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#4e2e1e', outlineSize = 2}, -- 大按钮
    --         = ttf
    TTF20      = {fontSize = 20, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF21      = {fontSize = 21, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF22      = {fontSize = 22, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF23      = {fontSize = 23, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF24      = {fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF25      = {fontSize = 25, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF26      = {fontSize = 26, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF27      = {fontSize = 27, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF28      = {fontSize = 28, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF29      = {fontSize = 29, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF30      = {fontSize = 30, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF31      = {fontSize = 31, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF32      = {fontSize = 32, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF33      = {fontSize = 33, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF34      = {fontSize = 34, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF35      = {fontSize = 35, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF36      = {fontSize = 36, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF37      = {fontSize = 37, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF38      = {fontSize = 38, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF39      = {fontSize = 39, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF40      = {fontSize = 40, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF41      = {fontSize = 41, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF42      = {fontSize = 42, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF43      = {fontSize = 43, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF44      = {fontSize = 44, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF45      = {fontSize = 45, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF46      = {fontSize = 46, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF47      = {fontSize = 47, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF48      = {fontSize = 48, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF49      = {fontSize = 49, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    TTF50      = {fontSize = 50, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT},
    --         = text
    TEXT20     = {fontSize = 20, color = '#FFFFFF'},
    TEXT21     = {fontSize = 21, color = '#FFFFFF'},
    TEXT22     = {fontSize = 22, color = '#FFFFFF'},
    TEXT23     = {fontSize = 23, color = '#FFFFFF'},
    TEXT24     = {fontSize = 24, color = '#FFFFFF'},
    TEXT25     = {fontSize = 25, color = '#FFFFFF'},
    TEXT26     = {fontSize = 26, color = '#FFFFFF'},
    TEXT27     = {fontSize = 27, color = '#FFFFFF'},
    TEXT28     = {fontSize = 28, color = '#FFFFFF'},
    TEXT29     = {fontSize = 29, color = '#FFFFFF'},
    TEXT30     = {fontSize = 30, color = '#FFFFFF'},
    TEXT31     = {fontSize = 31, color = '#FFFFFF'},
    TEXT32     = {fontSize = 32, color = '#FFFFFF'},
    TEXT33     = {fontSize = 33, color = '#FFFFFF'},
    TEXT34     = {fontSize = 34, color = '#FFFFFF'},
    TEXT35     = {fontSize = 35, color = '#FFFFFF'},
    TEXT36     = {fontSize = 36, color = '#FFFFFF'},
    TEXT37     = {fontSize = 37, color = '#FFFFFF'},
    TEXT38     = {fontSize = 38, color = '#FFFFFF'},
    TEXT39     = {fontSize = 39, color = '#FFFFFF'},
    TEXT40     = {fontSize = 40, color = '#FFFFFF'},
    TEXT41     = {fontSize = 41, color = '#FFFFFF'},
    TEXT42     = {fontSize = 42, color = '#FFFFFF'},
    TEXT43     = {fontSize = 43, color = '#FFFFFF'},
    TEXT44     = {fontSize = 44, color = '#FFFFFF'},
    TEXT45     = {fontSize = 45, color = '#FFFFFF'},
    TEXT46     = {fontSize = 46, color = '#FFFFFF'},
    TEXT47     = {fontSize = 47, color = '#FFFFFF'},
    TEXT48     = {fontSize = 48, color = '#FFFFFF'},
    TEXT49     = {fontSize = 49, color = '#FFFFFF'},
    TEXT50     = {fontSize = 50, color = '#FFFFFF'},
    --         = outline
    OUTLINE1   = {fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#000000', outlineSize = 1},
    OUTLINE2   = {fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#000000', outlineSize = 2},
    OUTLINE3   = {fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#000000', outlineSize = 3},
    OUTLINE4   = {fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#000000', outlineSize = 4},
    OUTLINE5   = {fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#000000', outlineSize = 5},
    --         = bmFont
    BMF_TEXT_U = 'font/small/common_num_unused.fnt',
    BMF_TEXT_W = 'font/small/common_text_num.fnt',  -- 白色
    BMF_TEXT_G = 'font/small/common_text_num2.fnt', -- 绿色
    BMF_TEXT_B = 'font/small/common_text_num3.fnt', -- 蓝色
    BMF_TEXT_P = 'font/small/common_text_num4.fnt', -- 紫色
    BMF_TEXT_O = 'font/small/common_text_num5.fnt', -- 橘色
    BMF_FIGHT  = 'font/team_ico_fight_figure.fnt',  -- 战力
}

-- 刷新font中ttf字体的定义
FONT_TTF_REFRESH = function()
    for _, fontDefine in pairs(FONT) do
        if fontDefine.font ~= nil then
            fontDefine.font = TTF_GAME_FONT
        end
    end
end


-------------------------------------------------------------------------------
-- cc
-------------------------------------------------------------------------------
-- cc = cc or {}

---@class cc.dir
---@field public left integer
---@field public top integer
---@field public right integer
---@field public bottom integer
function cc.dir(l, t, r, b)
    return {left = checkint(l), top = checkint(t), right = checkint(r), bottom = checkint(b)}
end


---@param p cc.Node | cc.p
---@param x number
---@param y number
function cc.rep(p, x, y)
    if type(p) == 'userdata' then
        p = cc.p(p:getPosition())
    end
    return cc.p(p.x + checkint(x), p.y + checkint(y))
end


---@param size cc.Node | cc.size
---@param ap cc.p
function cc.sizep(size, ap)
    if type(size) == 'userdata' then
        size = cc.size(size:getBoundingBox().width, size:getBoundingBox().height)
    end
    return cc.p(checkint(size.width * ap.x), checkint(size.height * ap.y))
end


---@param size cc.Node | cc.size
---@param w number
---@param h number
function cc.resize(size, w, h)
    local hh = (h == nil) and checkint(w) or checkint(h)
    if type(size) == 'userdata' then
        size = cc.size(size:getBoundingBox().width, size:getBoundingBox().height)
    end
    return cc.size(size.width + checkint(w), size.height + hh)
end


-------------------------------------------------------------------------------
-- ui
-------------------------------------------------------------------------------
---@class ui
ui = ui or {}

ui.lt = display.LEFT_TOP
ui.lb = display.LEFT_BOTTOM
ui.lc = display.LEFT_CENTER
ui.rt = display.RIGHT_TOP
ui.rb = display.RIGHT_BOTTOM
ui.rc = display.RIGHT_CENTER
ui.ct = display.CENTER_TOP
ui.cb = display.CENTER_BOTTOM
ui.cc = display.CENTER

ui.flowH = 1  -- 水平流布局
ui.flowV = 2  -- 垂直流布局
ui.flowC = 3  -- 中心堆叠

-- 滚动面板的 方向常量定义
ui.SDIR_H = eScrollViewDirectionHorizontal
ui.SDIR_V = eScrollViewDirectionVertical
ui.SDIR_B = eScrollViewDirectionBoth

-- 滚动条的 方向常量定义
ui.PDIR_LR = eProgressBarDirectionLeftToRight
ui.PDIR_RL = eProgressBarDirectionRightToLeft
ui.PDIR_BT = eProgressBarDirectionBottomToTop
ui.PDIR_TB = eProgressBarDirectionTopToBottom

-- 标签的对齐 方向常量定义
ui.TAL = cc.TEXT_ALIGNMENT_LEFT
ui.TAC = cc.TEXT_ALIGNMENT_CENTER
ui.TAR = cc.TEXT_ALIGNMENT_RIGHT
ui.TAT = cc.VERTICAL_TEXT_ALIGNMENT_TOP
ui.TAB = cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM

-- 输入框的 输入模式常量定义
ui.INPUT_MODE = {
    ANY         = cc.EDITBOX_INPUT_MODE_ANY,
    EMAILADDR   = cc.EDITBOX_INPUT_MODE_EMAILADDR,
    NUMERIC     = cc.EDITBOX_INPUT_MODE_NUMERIC,
    PHONENUMBER = cc.EDITBOX_INPUT_MODE_PHONENUMBER,
    URL         = cc.EDITBOX_INPUT_MODE_URL,
    DECIMAL     = cc.EDITBOX_INPUT_MODE_DECIMAL,
    SINGLELINE  = cc.EDITBOX_INPUT_MODE_SINGLELINE,
}


local checkImgPath = function(source)
    local imgPath = checkstr(source)
    local isValid = string.len(imgPath) > 0 and string.sub(imgPath, -1) ~= '/'
    local isExist = isValid and FTUtils:isPathExistent(imgPath) or false
    return isExist and imgPath or _res('ui/common/story_tranparent_bg.png')
end


local checkMargin = function(node, params)
    node:setMarginT(checkint(params.mt))
    node:setMarginB(checkint(params.mb))
    node:setMarginL(checkint(params.ml))
    node:setMarginR(checkint(params.mr))
end


-- cut = {left, top, right, bottom}
local checkCapInsets = function(imgPath, params)
    if params.capInsets ~= nil or params.cut ~= nil then
        params.scale9 = true
    end
    if imgPath and params.scale9 == true and params.capInsets == nil and params.cut ~= nil then
        local imgNode    = display.newImageView(checkImgPath(imgPath))
        local imgSize    = imgNode:getContentSize()
        local imgWidth   = imgSize.width
        local imgHeight  = imgSize.height
        local capInsets  = cc.rect(imgWidth/3, imgHeight/3, imgWidth/3, imgHeight/3)
        local cutInfo    = checktable(params.cut)
        local cutLeft    = checkint(cutInfo.left)
        local cutTop     = checkint(cutInfo.top)
        local cutRight   = checkint(cutInfo.right)
        local cutBottom  = checkint(cutInfo.bottom)
        capInsets.x      = cutLeft   > 0 and cutLeft or capInsets.x
        capInsets.y      = cutTop    > 0 and cutTop or capInsets.y
        capInsets.width  = cutRight  > 0 and (imgWidth - capInsets.x - cutRight) or capInsets.width
        capInsets.height = cutBottom > 0 and (imgHeight - capInsets.y - cutBottom) or capInsets.height
        params.capInsets = capInsets
        params.cut = nil  -- 避免被递归调用，清除掉
    end
end


local checkFont = function(params)
    local fontConfig = checktable(params.fnt)
    for k, v in pairs(fontConfig) do
        params[k] = params[k] or v
    end
    return params
end


local checkPos = function(params)
    if params.p ~= nil then
        local pos = checktable(params.p)
        params.x = params.x or checkint(params.p.x)
        params.y = params.y or checkint(params.p.y)
    end
end


---@return CLabel
function ui.label(_params)
    local params = checktable(_params)
    checkPos(params)
    checkFont(params)
    local label = display.newLabel(checkint(params.x), checkint(params.y), params)
    if params.zorder then label:setLocalZOrder(params.zorder) end
    checkMargin(label, params)
    label.updateLabel = function(obj, params)
        return ui.updateLabel(obj, params)
    end
    label.getSize = function(obj)
        local boundingBox = obj:getBoundingBox()
        return cc.size(boundingBox.width, boundingBox.height)
    end
    return label
end


--- 指定尺寸的滚动label，超过高度会自动滚动
---@class CTextArea : CScrollView
---@field public label CLabel
---@return CTextArea
function ui.textArea(_params)
    local params = checktable(_params)
    checkPos(params)
    checkFont(params)
    params.dir      = display.SDIR_V
    params.vAlign   = params.vAlign or ui.TAT
    local textLayer = ui.scrollView(params)

    -- create label
    local labelArgs = {ap = ui.lb}
    local textLabel = ui.label(labelArgs)
    textLayer:getContainer():addChild(textLabel)
    textLayer.label = textLabel

    ---@param obj CScrollView
    textLayer.updateLabel = function(obj, params)
        params.ap = nil
        -- update label
        params.w = checkint(obj:getContentSize().width)
        ui.updateLabel(obj.label, params)
        -- update layer
        obj.labelAlignV     = params.vAlign or obj.labelAlignV
        local containerSize = obj.label:getSize()
        local contentSize   = obj:getContentSize()
        obj:setContainerSize(containerSize)
        -- check layer size
        if contentSize.height > containerSize.height then
            if obj.labelAlignV == ui.TAT then
                obj.label:setPositionY(contentSize.height - containerSize.height)
            elseif obj.labelAlignV == ui.TAC then
                obj.label:setPositionY((contentSize.height - containerSize.height)/2)
            else
                obj.label:setPositionY(0)
            end
            obj:setDragable(false)
        else
            obj.label:setPositionY(0)
            obj:setDragable(true)
        end
        -- scroll to top
        obj:setContentOffsetToTop()
        return obj
    end
    -- init label
    textLayer:updateLabel(params)

    return textLayer
end


---@return CommonEditBox
function ui.editBox(_params)
    local params = checktable(_params)
    checkCapInsets(params.bg, params)
    params.borderDir      = params.dir
    params.place          = params.pText
    params.placeFontSize  = params.pSize
    params.placeFontColor = params.pColor
    params.textFontSize   = params.tSize
    params.textFontColor  = params.tColor
    params.textLen        = params.len
    local editBox = require('common.CommonEditBox').new(params)
    checkPos(params)
    editBox:setPositionX(checkint(params.x))
    editBox:setPositionY(checkint(params.y))
    if params.ap then editBox:setAnchorPoint(params.ap) end
    if params.tag then editBox:setTag(params.tag) end
    if params.scale then editBox:setScale(params.scale) end
    if params.scaleX then editBox:setScaleX(params.scaleX) end
    if params.scaleY then editBox:setScaleY(params.scaleY) end
    if params.zorder then editBox:setLocalZOrder(params.zorder) end
    checkMargin(editBox, params)
    return editBox
end


---@return CImageView | CImageViewScale9
function ui.image(_params)
    local params = checktable(_params)
    checkPos(params)
    checkCapInsets(params.img, params)
    local path  = checkImgPath(params.img)
    local image = display.newImageView(path, checkint(params.x), checkint(params.y), params)
    if params.zorder then image:setLocalZOrder(params.zorder) end
    checkMargin(image, params)
    return image
end


---@return CLayout | CColorView
function ui.layer(_params)
    local params = checktable(_params)
    checkPos(params)
    checkCapInsets(params.bg, params)
    if params.color and type(params.color) == 'string' then
        params.color = ccc4FromInt(params.color)
    end
    local layer = display.newLayer(checkint(params.x), checkint(params.y), params)
    if params.zorder then layer:setLocalZOrder(params.zorder) end
    if params.tag then layer:setTag(params.tag) end
    if params.scale then layer:setScale(params.scale) end
    if params.scaleX then layer:setScaleX(params.scaleX) end
    if params.scaleY then layer:setScaleY(params.scaleY) end
    checkMargin(layer, params)
    return layer
end


---@return CLayout | CColorView
function ui.colorBtn(_params)
    local params  = checktable(_params)
    params.enable = true
    if params.color == nil then
        params.color = cc.r4b(150)
    end
    if params.size == nil then
        params.size = cc.size(100, 100)
    end
    if params.ap == nil then
        params.ap = ui.cc
    end

    local colorBtn  = ui.layer(params)
    colorBtn.label_ = ui.label()
    colorBtn:addList(colorBtn.label_):alignTo(nil, ui.cc)

    colorBtn.getLabel = function(obj)
        return obj.label_
    end
    colorBtn.getText = function(obj)
        return obj.label_:getString()
    end
    colorBtn.updateLabel = function(obj, params)
        ui.updateLabel(obj:getLabel(), params)
        return obj
    end
    return colorBtn
end


---@return CButton
function ui.button(_params)
    local params = checktable(_params)
    checkPos(params)
    checkCapInsets(params.n, params)
    local button = display.newButton(checkint(params.x), checkint(params.y), params)
    button.updateLabel = function(obj, params)
        return ui.updateLabel(obj, params)
    end
    if params.zorder then button:setLocalZOrder(params.zorder) end
    if params.ccEnable ~= nil then button:setCascadeColorEnabled(params.ccEnable == true) end
    if params.coEnable ~= nil then button:setCascadeOpacityEnabled(params.coEnable == true) end
    checkMargin(button, params)
    return button
end


---@return CButton
function ui.title(_params)
    local params = checktable(_params)
    if params.scale9 == nil then
        params.scale9 = true
    end
    if params.enable == nil then
        params.enable = false
    end
    if params.img then
        params.n = params.img
    end
    return ui.button(params)
end


---@return CToggleView
function ui.tButton(_params)
    local params = checktable(_params)
    checkPos(params)
    checkCapInsets(params.n, params)
    local tbutton = display.newToggleView(checkint(params.x), checkint(params.y), params)
    if params.enable == false then tbutton:setTouchEnabled(false) end
    if params.scale then tbutton:setScale(params.scale) end
    if params.scaleX then tbutton:setScaleX(params.scaleX) end
    if params.scaleY then tbutton:setScaleX(params.scaleY) end
    if params.zorder then tbutton:setLocalZOrder(params.zorder) end
    checkMargin(tbutton, params)

    if params.nLabel or params.sLabel or params.dLabel then
        if params.sLabel or params.dLabel then
            if params.nLabel then
                tbutton.nLabel = ui.label(params.nLabel)
                tbutton:getNormalImage():addList(tbutton.nLabel):alignTo(nil, ui.cc)
            end
            if params.sLabel then
                tbutton.sLabel = ui.label(params.sLabel)
                tbutton:getSelectedImage():addList(tbutton.sLabel):alignTo(nil, ui.cc)
            end
            if params.dLabel then
                tbutton.dLabel = ui.label(params.dLabel)
                tbutton:getDisabledImage():addList(tbutton.dLabel):alignTo(nil, ui.cc)
            end
        else
            tbutton.label = ui.label(params.nLabel)
            tbutton:addList(tbutton.label):alignTo(nil, ui.cc)
        end
    end

    return tbutton
end


---@return CProgressBar
function ui.pBar(_params)
    local params = checktable(_params)
    checkPos(params)
    local pbar   = display.newProgressBar(checkint(params.x), checkint(params.y), params)
    if params.zorder then pbar:setLocalZOrder(params.zorder) end
    checkMargin(pbar, params)
    return pbar
end


---@return CSlider
function ui.slider(_params)
    local params = checktable(_params)
    checkPos(params)
    local slider = display.newSlider(checkint(params.x), checkint(params.y), params)
    if params.zorder then slider:setLocalZOrder(params.zorder) end
    checkMargin(slider, params)
    return slider
end


---@return cc.Sprite
function ui.goodsImg(_params)
    local params   = checktable(_params)
    checkPos(params)
    ---@type cc.Sprite
    local goodsImg = CommonUtils.GetGoodsIconNodeById(params.goodsId, checkint(params.x), checkint(params.y), params)
    if params.zorder then goodsImg:setLocalZOrder(params.zorder) end
    checkMargin(goodsImg, params)
    return goodsImg
end


---@return GoodNode
function ui.goodsNode(_params)
    local params = checktable(_params)
    if params.defaultCB == true then
        params.callBack = function(sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(sender.goodId), type = 1})
        end
    end
    if params.gainCB == true then
        params.callBack = function(sender)
            app.uiMgr:AddDialog('common.GainPopup', {goodId = checkint(sender.goodId), isFrom = sender.from})
        end
    end
    ---@type GoodNode
    local goodsNode = require('common.GoodNode').new(params)
    if params.zorder then goodsNode:setLocalZOrder(params.zorder) end
    checkPos(params)
    goodsNode:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(goodsNode, params)
    return goodsNode
end


---@return PlayerHeadNode
function ui.playerHeadNode(_params)
    local params         = checktable(_params)
    ---@type PlayerHeadNode
    local playerHeadNode = require('common.PlayerHeadNode').new(params)
    if params.zorder then playerHeadNode:setLocalZOrder(params.zorder) end
    checkPos(params)
    playerHeadNode:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(playerHeadNode, params)
    return playerHeadNode
end


---@return CardHeadNode
function ui.cardHeadNode(_params)
    local params       = checktable(_params)
    ---@type CardHeadNode
    local cardHeadNode = require('common.CardHeadNode').new(params)
    if params.zorder then cardHeadNode:setLocalZOrder(params.zorder) end
    checkPos(params)
    cardHeadNode:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(cardHeadNode, params)
    return cardHeadNode
end


---@return CardSkinDrawNode
function ui.cardDrawNode(_params)
    local params       = checktable(_params)
    ---@type CardSkinDrawNode
    local cardDrawNode = require('common.CardSkinDrawNode').new(params)
    if params.zorder then cardDrawNode:setLocalZOrder(params.zorder) end
    checkPos(params)
    cardDrawNode:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(cardDrawNode, params)
    return cardDrawNode
end


---@return CardSpine
function ui.cardSpineNode(_params)
    local params       = checktable(_params)
    if params.uuid and params.skinId == nil then
        local cardData = app.gameMgr:GetCardDataById(params.uuid) or {}
        params.skinId  = cardData.defaultSkinId
    end
    if params.cardId and params.skinId == nil then
        local cardData = app.gameMgr:GetCardDataByCardId(params.uuid) or {}
        params.skinId  = cardData.defaultSkinId
    end
    if params.confId and params.skinId == nil then
        params.skinId = CardUtils.GetCardSkinId(params.confId)
    end
    ---@type CardSpine
    local cardSpineNode = AssetsUtils.GetCardSpineNode(params)
    cardSpineNode:setContentSize(cc.size(0,0))  -- spine的尺寸往往不固定，所以设置成0方便给坐标对齐。
    if params.zorder then cardSpineNode:setLocalZOrder(params.zorder) end
    if params.init then cardSpineNode:setAnimation(0, params.init, true) end
    if params.size then cardSpineNode:setContentSize(params.size) end
    if params.flipX ~= nil then cardSpineNode:setScaleX(cardSpineNode:getScaleX() * (params.flipX == true and -1 or 1)) end
    if params.flipY ~= nil then cardSpineNode:setScaleY(cardSpineNode:getScaleX() * (params.flipY == true and -1 or 1)) end
    checkPos(params)
    cardSpineNode:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(cardSpineNode, params)
    return cardSpineNode
end


---@return CommonBattleButton
function ui.battleButton(_params)
    local params    = checktable(_params)
    ---@type CommonBattleButton
    local battleBtn = require('common.CommonBattleButton').new(params)
    if params.zorder then battleBtn:setLocalZOrder(params.zorder) end
    checkPos(params)
    battleBtn:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(battleBtn, params)
    return battleBtn
end


---@return SpineExt
function ui.spine(_params)
    local params    = checktable(_params)
    ---@type SpineExt
    local spineNode = nil
    if params.cache then
        spineNode = display.newCacheSpine(params.cache, params.path, params.scale)
    else
        spineNode = display.newPathSpine(params.path, params.scale)
    end
    local isEnableEvent = checkbool(params.enableEvent)
    if params.startCB and spineNode.setStartCB then
        isEnableEvent = true
        spineNode:setStartCB(params.startCB)
    end
    if params.endedCB and spineNode.setEndedCB then
        isEnableEvent = true
        spineNode:setEndedCB(params.endedCB)
    end
    if params.eventCB and spineNode.setEventCB then
        isEnableEvent = true
        spineNode:setEventCB(params.eventCB)
    end
    if params.completeCB and spineNode.setCompleteCB then
        isEnableEvent = true
        spineNode:setCompleteCB(params.completeCB)
    end
    if isEnableEvent then
        spineNode:setEnableSpineEvents(true)
    end
    spineNode:setContentSize(cc.size(0,0))  -- spine的尺寸往往不固定，所以设置成0方便给坐标对齐。
    if params.zorder then spineNode:setLocalZOrder(params.zorder) end
    if params.init then spineNode:setAnimation(0, params.init, (params.loop == nil or params.loop == true)) end
    if params.size then spineNode:setContentSize(params.size) end
    if params.flipX ~= nil then spineNode:setScaleX(params.flipX == true and -1 or 1) end
    if params.flipY ~= nil then spineNode:setScaleY(params.flipY == true and -1 or 1) end
    checkPos(params)
    spineNode:setPosition(cc.p(checkint(params.x), checkint(params.y)))
    checkMargin(spineNode, params)
    return spineNode
end


---@return CTextRich
function ui.rLabel(_params)
    local params = checktable(_params)
    checkPos(params)
    local rlabel = display.newRichLabel(checkint(params.x), checkint(params.y), params)
    checkMargin(rlabel, params)
    rlabel.reload = function(obj, reloadData)
        for _, reloadParam in ipairs(reloadData or {}) do
            checkFont(reloadParam)
        end
        display.reloadRichLabel(obj, {c = reloadData})
        return obj
    end
    rlabel.setOnClickScriptHandler = function(obj, callback)
        obj:setOnTextRichClickScriptHandler(callback)
    end
    rlabel:setContentSize(cc.size(0,0))
    if params.zorder then rlabel:setLocalZOrder(params.zorder) end
    if params.h then rlabel:setContentSize(cc.size(0, params.h)) end
    if params.c then rlabel:reload(params.c) end
    return rlabel
end


---@return cc.Label
function ui.bmfLabel(_params)
    local params   = checktable(_params)
    checkPos(params)
    local bmfLabel = display.newBMFLabel(checkint(params.x), checkint(params.y), params)
    if params.zorder then bmfLabel:setLocalZOrder(params.zorder) end
    if params.scale then bmfLabel:setScale(params.scale) end
    checkMargin(bmfLabel, params)
    bmfLabel.updateLabel = function(obj, params)
        return bmfLabel.setString(obj, checkstr(checktable(params).text))
    end
    bmfLabel.getSize = function(obj)
        local boundingBox = obj:getBoundingBox()
        return cc.size(boundingBox.width, boundingBox.height)
    end
    return bmfLabel
end


---@return CGridView | ExDataSourceAdapter
function ui.gridView(_params)
    local params   = checktable(_params)
    checkPos(params)
    local gridView = display.newGridView(checkint(params.x), checkint(params.y), params)
    checkMargin(gridView, params)
    return gridView
end


---@return CTableView | ExDataSourceAdapter
function ui.tableView(_params)
    local params    = checktable(_params)
    checkPos(params)
    local tableView = display.newTableView(checkint(params.x), checkint(params.y), params)
    checkMargin(tableView, params)
    return tableView
end


---@return CPageView | ExDataSourceAdapter
function ui.pageView(_params)
    local params = checktable(_params)
    checkPos(params)
    local pageView = display.newPageView(checkint(params.x), checkint(params.y), params)
    checkMargin(pageView, params)
    return pageView
end


---@return CScrollView
function ui.scrollView(_params)
    local params    = checktable(_params)
    checkPos(params)
    local tableView = display.newScrollView(checkint(params.x), checkint(params.y), params)
    checkMargin(tableView, params)
    return tableView
end


---@return CListView
function ui.listView(_params)
    local params    = checktable(_params)
    checkPos(params)
    local listView = CListView:create(params.size or SizeZero)
    listView:setPosition(checkint(params.x), checkint(params.y))
    display.commonScrollParams(listView, params)
    checkMargin(listView, params)
    return listView
end


---@return cc.ClippingNode
function ui.clipNode(_params)
    local params    = checktable(_params)
    checkPos(params)
    local clipNode  = cc.ClippingNode:create()
    clipNode:setPosition(checkint(params.x), checkint(params.y))
    clipNode:setContentSize(params.size)
    clipNode:setAnchorPoint(params.ap or display.CENTER)
    clipNode:setAlphaThreshold(params.at or 0.1)
    if params.stencil then
        local stencilNode = ui.image(params.stencil)
        clipNode:setStencil(stencilNode)
    end
    checkMargin(clipNode, params)
    return clipNode
end


function ui.updateLabel(source, _params)
    local params = checktable(_params)
    checkFont(params)

    local label = source
    if tolua.type(source) == 'ccw.CProgressBar' or tolua.type(source) == 'ccw.CSlider' then
        label = source:getLabel()
    end

    display.commonLabelParams(label, params)
    return source
end


function ui.bindClick(sender, handler, hasAnimate)
    display.commonUIParams(sender, {cb = handler, animate = hasAnimate})
    if sender then
        sender.onClickScriptHandler_ = handler
        sender.getOnClickScriptHandler = function(obj)
            return obj.onClickScriptHandler_
        end
        sender.toOnClickScriptHandler = function(obj)
            if obj:getOnClickScriptHandler() then
                obj:getOnClickScriptHandler()(obj)
            end
        end
    end
end


ui.spStart    = sp.EventType.ANIMATION_START
ui.spEvent    = sp.EventType.ANIMATION_EVENT
ui.spComplete = sp.EventType.ANIMATION_COMPLETE

function ui.bindSpine(spine, handler, eventType)
    if spine then
        spine:registerSpineEventHandler(handler, eventType or ui.spComplete)
    end
end
function ui.unbindSpine(spine, eventType)
    if spine then
        spine:unregisterSpineEventHandler(eventType or ui.spComplete)
    end
end


function ui.flowLayout(basePos, nodeList, params)
    return display.flowLayout(basePos, nodeList, params)
end


-------------------------------------------------------------------------------
-- display
-------------------------------------------------------------------------------
---@type display
display = display or {}

--[[
    根据路径创建spine，可以传 string 或者 _spn 结构。
    -- @param spinePath string 不包含后缀的路径
    -- @param spinePath table _spn数据类型
]]
---@return SpineExt
function display.newPathSpine(spinePath, scale)
    if type(spinePath) == 'table' then
        local spineData = spinePath
        return sp.SkeletonAnimation:create(spineData.json, spineData.atlas, scale or 1)
    else
        return sp.SkeletonAnimation:create(spinePath .. '.json', spinePath .. '.atlas', scale or 1)
    end
end


--[[
    根据路径创建缓存spine，可以传 string 或者 _spn 结构。
    -- @param spinePath string 不包含后缀的路径
    -- @param spinePath table _spn数据类型
]]
---@return SpineExt
function display.newCacheSpine(cacheName, spinePath, scale)
    if type(spinePath) == 'table' then
        local spineData = spinePath
        spinePath = spineData.path
    end
    if not SpineCache(cacheName):hasSpineCacheData(spinePath) then
        SpineCache(cacheName):addCacheData(spinePath, spinePath, scale or 1)
    end
    return SpineCache(cacheName):createWithName(spinePath)
end


-- 扩展目标对象
function ExtendTargetObject(targetObject, extendTable)
    if targetObject ~= nil and extendTable ~= nil then
        for memberName, memberValue in pairs(extendTable) do
            targetObject[memberName] = memberValue
        end
    end
end


-------------------------------------------------------------------------------
-- ExAdapter
-------------------------------------------------------------------------------

display.SAFE_SIZE = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

-- 滚动面板的 方向常量定义
display.SDIR_H = ui.SDIR_H
display.SDIR_V = ui.SDIR_V
display.SDIR_B = ui.SDIR_B

-- 滚动条的 方向常量定义
display.PDIR_LR = ui.PDIR_LR
display.PDIR_RL = ui.PDIR_RL
display.PDIR_BT = ui.PDIR_BT
display.PDIR_TB = ui.PDIR_TB


--[[
    适配器组件扩展
]]
---@class ExDataSourceAdapter
local ExDataSourceAdapter = {}
do
    function ExDataSourceAdapter:initOptions(initValueTable)
        self.widgetCellClass   = nil
        self.cellViewDataDict_ = self.cellViewDataDict_ or {}

        for name, value in pairs(initValueTable or {}) do
            self[name] = initValueTable[name]  
        end
    end


    ---@return table<cc.Node, table>
    function ExDataSourceAdapter:getCellViewDataDict()
        return self.cellViewDataDict_
    end


    ---@param cellCount integer
    ---@param isAutoDragale? boolean
    ---@param isRetainOffset? boolean
    function ExDataSourceAdapter:resetCellCount(cellCount, isAutoDragale, isRetainOffset)
        self:setCountOfCell(checkint(cellCount))

        local oldMaxOffset = self:getMaxOffset()
        local oldMinOffset = self:getMinOffset()
        local oldNowOffset = self:getContentOffset()
        local offsetWidth  = checkint(oldMinOffset.x - oldNowOffset.x)
        local offsetLength = checkint(oldMinOffset.y - oldNowOffset.y)
        if self.refreshAll then self:refreshAll() else self:reloadData() end

        if isAutoDragale then
            if self:getDirection() == display.SDIR_H then
                self:setDragable(self:getContainerSize().width > self:getContentSize().width)
            elseif self:getDirection() == display.SDIR_V then
                self:setDragable(self:getContainerSize().height > self:getContentSize().height)
            elseif self:getDirection() == display.SDIR_B then
                local isDragableH = self:getContainerSize().width > self:getContentSize().width
                local isDragableV = self:getContainerSize().height > self:getContentSize().height
                self:setDragable(isDragableH or isDragableV)
            end
        end

        if isRetainOffset then
            local newMaxOffset = self:getMaxOffset()
            local newMinOffset = self:getMinOffset()
            local newNowOffset = cc.p(newMinOffset.x - offsetWidth, newMinOffset.y - offsetLength)
            if offsetWidth ~= 0 or offsetLength ~= 0 then
                self:setContentOffset(newNowOffset)
            end
        end
        
        return self
    end

    
    ---@param isTouchable boolean
    function ExDataSourceAdapter:setTouchable(isTouchable)
        if isTouchable then
            self:setOnTouchBeganScriptHandler(nil)
            self:setOnTouchMovedScriptHandler(nil)
            self:setOnTouchEndedScriptHandler(nil)
        else
            self:setOnTouchBeganScriptHandler(function(sender, touch) return true end)
            self:setOnTouchMovedScriptHandler(function(sender, touch) return true end)
            self:setOnTouchEndedScriptHandler(function(sender, touch) return true end)
        end
    end


    ---@param callback fun(cellParent:cc.Node):table
    ---@param cellCreateArgs? table
    function ExDataSourceAdapter:setCellCreateHandler(callback, cellCreateArgs)
        self.cellCreateHandler_ = callback
        self.cellCreateArgs_    = cellCreateArgs
        return self
    end


    ---@return fun(cellParent:cc.Node):table
    function ExDataSourceAdapter:getCellCreateHandler()
        return self.cellCreateHandler_
    end
    

    ---@param class table
    ---@param cellCreateArgs? table
    function ExDataSourceAdapter:setCellCreateClass(class, cellCreateArgs)
        self.cellCreateClass_ = class
        self.cellCreateArgs_  = cellCreateArgs
        return self
    end


    ---@return table
    function ExDataSourceAdapter:getCellCreateClass()
        return self.cellCreateClass_
    end


    ---@param callback fun(cellViewData:table):void
    function ExDataSourceAdapter:setCellInitHandler(callback)
        self.cellInitHandler_ = callback
        if self:getCellInitHandler() then
            for _, viewData in pairs(self:getCellViewDataDict()) do
                self:getCellInitHandler()(viewData)
            end
        end
        return self
    end


    ---@return fun(cellViewData:table):void
    function ExDataSourceAdapter:getCellInitHandler()
        return self.cellInitHandler_
    end


    ---@param callback fun(cellIndex:integer, cellViewData:table, ...):void
    function ExDataSourceAdapter:setCellUpdateHandler(callback)
        self.cellUpdateHandler_ = callback
        if self.refreshAll then self:refreshAll() else self:reloadData() end
    end


    ---@return fun(cellIndex:integer, cellViewData:table, ...):void
    function ExDataSourceAdapter:getCellUpdateHandler()
        return self.cellUpdateHandler_
    end


    ---@param cellIndex integer @ value range [1 - cellCount]
    function ExDataSourceAdapter:updateCellViewData(cellIndex, viewData, ...)
        if checkint(cellIndex) > 0 and self:getCellUpdateHandler() then
            local cellViewData = viewData or self:getCellViewDataDict()[self:cellAtIndex(cellIndex - 1)]
            local updateArgs   = {...}
            xTry(function()
                self:getCellUpdateHandler()(cellIndex, cellViewData, unpack(updateArgs))
            end, __G__TRACKBACK__)
        end
    end
    

    ---@return cc.Node
    function ExDataSourceAdapter:createAdapterCell()
        local cellSize = self:getSizeOfCell()
        local cellNode = self.widgetCellClass:new()
        local viewData = nil--{ view = cellNode }
        cellNode:enableNodeEvents()
        cellNode:setContentSize(cellSize)
        cellNode:setCascadeColorEnabled(true)
        cellNode:setCascadeOpacityEnabled(true)
        
        xTry(function()
            if self:getCellCreateHandler() then
                viewData = self:getCellCreateHandler()(cellNode, self.cellCreateArgs_)
            elseif self:getCellCreateClass() then
                viewData = self:getCellCreateClass().new(self.cellCreateArgs_)
                cellNode:addChild(viewData)
            end
        end, __G__TRACKBACK__)

        if viewData then
            self:getCellViewDataDict()[cellNode] = viewData

            xTry(function()
                if self:getCellInitHandler() then
                    self:getCellInitHandler()(viewData)
                end
            end, __G__TRACKBACK__)
        else
            cellNode:setBackgroundColor(cc.r4b(150))
        end
        return cellNode
    end


    ---@param cell cc.Node
    ---@param idx  integer @ value range [0 - cellcount-1]
    ---@return cc.Node
    function ExDataSourceAdapter:onDataSourceAdapterHandler_(cell, idx)
        local pCell = cell or self:createAdapterCell()
        local index = idx + 1
        
        local viewData = self:getCellViewDataDict()[pCell]
        if viewData then
            self:updateCellViewData(index, viewData)
        end
        return pCell
    end


    ---@param idx integer @ value range [1 - cellcount]
    function ExDataSourceAdapter:setContentOffsetAt(idx)
        self:setContentOffset(self:getContentOffsetAt(idx))
    end

    ---@param idx integer @ value range [1 - cellIndex]
    function ExDataSourceAdapter:getContentOffsetAt(idx)
        local cellIndex  = math.max(checkint(idx) - 1, 0)
        local scrollPos  = cc.p(0,0)-- bottom
        local containerW = self:getContainerSize().width
        local tableViewW = self:getContentSize().width
        local tableViewH = self:getContentSize().height
        local tableCellW = self:getSizeOfCell().width
        local tableCellH = self:getSizeOfCell().height
        local cellCount  = self:getCountOfCell()
        if self:getDirection() == display.SDIR_V then
            local col = self.getColumns and self:getColumns() or 1
            scrollPos.y = math.min(tableViewH - (math.ceil(cellCount / col) - math.ceil((cellIndex + 0.1) / col) + 1) * tableCellH, 0)
        elseif self:getDirection() == display.SDIR_H then
            local row = self.getRows and self:getRows() or 1
            scrollPos.x = math.max(math.ceil(cellIndex / row) * tableCellW * -1, tableViewW - containerW)
        end
        return scrollPos
    end
end


---@class ExListSourceAdapter
local ExListSourceAdapter = {}
do
    function ExListSourceAdapter:getSizeOfCell()
        return self.cellSize_ or ZeroSize
    end
    function ExListSourceAdapter:setSizeOfCell(size)
        self.cellSize_ = size
    end


    function ExListSourceAdapter:getCountOfCell()
        return checkint(self.cellCount_)
    end
    function ExListSourceAdapter:setCountOfCell(count)
        self.cellCount_ = count
        return self
    end


    -- index : int    [0 - cellCount-1]
    function ExListSourceAdapter:cellAtIndex(index)
        return self:getExpandableNodeAtIndex(index)
    end


    function ExListSourceAdapter:refreshAll()
        self.exCellViewDataDict_ = {}
        self:removeAllExpandableNodes()

        for index = 1, self:getCountOfCell() do
            local exCellNode = self:createAdapterCell()
            self:insertExpandableNodeAtLast(exCellNode)
            
            local viewData = self:getCellViewDataDict()[exCellNode]
            if viewData then
                self:updateCellViewData(index, viewData)
            end
        end
        self:reloadData()
    end
end


-------------------------------------------------------------------------------
-- ui widght
-------------------------------------------------------------------------------

---@param scrollView CScrollView
local checkScrollListeren = function(scrollView)
    local platform = cc.Application:getInstance():getTargetPlatform()
    if platform == cc.PLATFORM_OS_MAC or platform == cc.PLATFORM_OS_WINDOWS then
        CommonUtils.AdditionToMouseScrollEvent(scrollView, 45)
    end
end


--[[
    -- @param scrollView     : node       视图组件对象
    -- @param params.tag     : int        组件tag
    -- @param params.ap      : cc.p       组件锚点
    -- @param params.size    : cc.size    组件尺寸
    -- @param params.dir     : int        滚动方向
    -- @param params.drag    : bool       是否 允许拖动
    -- @param params.bounce  : bool       是否 允许拖动到尽头回弹回来
    -- @param params.deacce  : bool       是否 允许拖拽抬起后加速滚动（默认 true）
    -- @param params.ssize   : cc.size    滚动容器尺寸
    -- @param params.bgColor : #FFFFFFFF  背景颜色
]]
---@param scrollView CScrollView
function display.commonScrollParams(scrollView, params)
    if scrollView and params then
        if params.tag then scrollView:setTag(params.tag) end
        if params.ap then scrollView:setAnchorPoint(params.ap) end
        if params.size then scrollView:setContentSize(params.size) end
        if params.zorder then scrollView:setLocalZOrder(params.zorder) end
    
        -- @see display.SDIR_H, display.SDIR_V, display.SDIR_B
        if params.dir then scrollView:setDirection(params.dir) end -- int
        if params.drag ~= nil then scrollView:setDragable(params.drag == true) end -- bool
        if params.bounce ~= nil then scrollView:setBounceable(params.bounce == true) end -- bool
        if params.deacce ~= nil then scrollView:setDeaccelerateable(params.deacce == true) end -- bool
        if params.ssize then scrollView:setContainerSize(params.ssize) end -- cc.size
        if params.bgColor then
            local bgColor = type(params.bgColor) == 'string' and ccc4FromInt(params.bgColor) or params.bgColor
            scrollView:setBackgroundColor(bgColor)
        end

        checkScrollListeren(scrollView)
    end
end


--[[
    -- @param tableView       : node       视图组件对象
    -- @param params.auto     : bool       是否 开启整格滑动（默认 false。开启后，当拖动超过半格时松手，会自动校正滚动至整格。）
    -- @param params.csize    : cc.size    单元格尺寸（nil 的话使用 csizeW 和 csizeH ）
    -- @param params.csizeW   : int        单元格宽度（csize 为 nil 时才生效）
    -- @param params.csizeH   : int        单元格宽度（csize 为 nil 时才生效）
    -- @param params.csizeAdd : cc.size    单元格尺寸额外再追加的增量
    -- @param params.bgColor  : #FFFFFFFF  背景颜色
]]
---@param tableView CTableView
function display.commonTableParams(tableView, params)
    display.commonScrollParams(tableView, params)
    if tableView and params then
        if params.auto ~= nil then tableView:setAutoRelocate(params.auto == true) end -- bool
        if params.csize then
            tableView:setSizeOfCell(params.csize)
        else
            local celllSize = cc.size(checkint(params.csizeW), checkint(params.csizeH))
            if params.size and params.csizeW == nil then
                celllSize.width = params.size.width
            end
            if params.size and params.csizeH == nil then
                celllSize.height = params.size.height
            end
            if params.csizeAdd then
                celllSize.width  = celllSize.width + params.csizeAdd.width
                celllSize.height = celllSize.height + params.csizeAdd.height
            end
            tableView:setSizeOfCell(celllSize)
        end
        
    end
end


--[[
    创建 ScrollView 组件
    -- @param x : int    所处X坐标
    -- @param y : int    所处Y坐标
    -- @see display.commonScrollParams
]]
---@return CScrollView
function display.newScrollView(x, y, params)
    local scrollView = CScrollView:create(SizeZero)
    scrollView:setPosition(cc.p(checkint(x), checkint(y)))
    display.commonScrollParams(scrollView, params)
    return scrollView
end


--[[
    创建 GridView 组件
    -- @param x : int              所处X坐标
    -- @param y : int              所处Y坐标
    -- @param params.cols : int    网格分割的列数
    -- @see display.commonScrollParams
    -- @see display.commonTableParams
]]
---@return CGridView | ExDataSourceAdapter
function display.newGridView(x, y, params)
    ---@type ExDataSourceAdapter
    local gridView = CGridView:create(SizeZero)
    ExtendTargetObject(gridView, ExDataSourceAdapter)
    gridView:initOptions({widgetCellClass = CGridViewCell})
    gridView:setDataSourceAdapterScriptHandler(handler(gridView, gridView.onDataSourceAdapterHandler_))
    gridView:setPosition(cc.p(checkint(x), checkint(y)))
    
    if params then
        if params.cols then
            gridView:setColumns(params.cols)

            if params.size and params.csize == nil and params.csizeW == nil then
                params.csizeW = checkint(params.size.width / params.cols)

                if params.csizeH == nil then
                    params.csizeH = params.csizeW
                end
            end
        end
    end
    display.commonTableParams(gridView, params)
    return gridView
end


--[[
    创建 TableView 组件
    -- @param x : int    所处X坐标
    -- @param y : int    所处Y坐标
    -- @see display.commonScrollParams
    -- @see display.commonTableParams
]]
---@return CTableView | ExDataSourceAdapter
function display.newTableView(x, y, params)
    ---@type ExDataSourceAdapter
    local tableView = CTableView:create(SizeZero)
    ExtendTargetObject(tableView, ExDataSourceAdapter)
    tableView:initOptions({widgetCellClass = CTableViewCell})
    tableView:setDataSourceAdapterScriptHandler(handler(tableView, tableView.onDataSourceAdapterHandler_))
    tableView:setPosition(cc.p(checkint(x), checkint(y)))
    display.commonTableParams(tableView, params)
    return tableView
end


--[[
    创建 PageView 组件
    -- @param x : int    所处X坐标
    -- @param y : int    所处Y坐标
    -- @see display.commonScrollParams
    -- @see display.commonTableParams
]]
---@return CPageView | ExDataSourceAdapter
function display.newPageView(x, y, params)
    ---@type ExDataSourceAdapter
    local pageView = CPageView:create(SizeZero)
    ExtendTargetObject(pageView, ExDataSourceAdapter)
    pageView:initOptions({widgetCellClass = CPageViewCell})
    pageView:setDataSourceAdapterScriptHandler(handler(pageView, pageView.onDataSourceAdapterHandler_))
    pageView:setPosition(cc.p(checkint(x), checkint(y)))
    display.commonTableParams(pageView, params)
    return pageView
end


--[[
    创建 GridPageView 组件
    -- @param x : int              所处X坐标
    -- @param y : int              所处Y坐标
    -- @param params.rows : int    网格分割的行数
    -- @param params.cols : int    网格分割的列数
    -- @see display.commonScrollParams
    -- @see display.commonTableParams
]]
---@return CGridPageView | ExDataSourceAdapter
function display.newGridPageView(x, y, params)
    ---@type ExDataSourceAdapter
    local gridPageView = CGridPageView:create(SizeZero)
    ExtendTargetObject(gridPageView, ExDataSourceAdapter)
    gridPageView:initOptions({widgetCellClass = CGridPageViewCell})
    gridPageView:setDataSourceAdapterScriptHandler(handler(gridPageView, gridPageView.onDataSourceAdapterHandler_))
    gridPageView:setPosition(cc.p(checkint(x), checkint(y)))
    
    if params then
        if params.rows then gridPageView:setRows(params.rows) end -- int
        if params.cols then gridPageView:setColumns(params.cols) end -- int

        if params.size and params.csize == nil then
            if params.cols and params.csizeW == nil then
                params.csizeW = checkint(params.size.width / params.cols)
            end
            if params.rows and params.csizeH == nil then
                params.csizeH = checkint(params.size.height / params.rows)
            end
        end
    end
    display.commonTableParams(gridPageView, params)
    return gridPageView
end


--[[
    创建 CExpandableListView 组件
    -- @param x : int                   所处X坐标
    -- @param y : int                   所处Y坐标
    -- @param params.csize : cc.size    单元格尺寸
    -- @see display.commonScrollParams
]]
---@return CExpandableListView | ExDataSourceAdapter | ExListSourceAdapter
function display.newExListView(x, y, params)
    ---@type ExDataSourceAdapter
    local exListView = CExpandableListView:create(SizeZero)
    ExtendTargetObject(exListView, ExDataSourceAdapter)
    ExtendTargetObject(exListView, ExListSourceAdapter)
    exListView:initOptions({widgetCellClass = CExpandableNode})
    exListView:setPosition(cc.p(checkint(x), checkint(y)))
    display.commonScrollParams(exListView, params)
    exListView:setContentOffsetToTop() -- 不知道为啥，如果初始为空时，再设置大小后，第一次总会从下向上滚动出现，所以手动置顶一下。

    if params then
        if params.csize then exListView:setSizeOfCell(params.csize) end -- cc.size
    end
    return exListView
end


--[[
    创建 CProgressBar 组件
    -- @param x : int                  所处X坐标
    -- @param y : int                  所处Y坐标
    -- @param params.img    : str      进度图片路径
    -- @param params.bg     : str      背景图片路径
    -- @param params.dir    : int      滚动条方向
    -- @param params.w      : int      缩放到的宽度
    -- @param params.h      : int      缩放到的高度
    -- @param params.label  : bool     是否显示标签
    -- @param params.ap     : cc.p     锚点
    -- @param params.value  : cc.p     当前进度
    -- @param params.max    : cc.p     最大进度
    -- @param params.min    : cc.p     最小进度
    -- @param params.tag    : int      标签
    -- @param params.scale  : float    整体缩放
    -- @param params.scaleX : float    x轴缩放
    -- @param params.scaleY : float    y轴缩放
]]
---@return CProgressBar
function display.newProgressBar(x, y, params)
    local progressBar = CProgressBar:create(params.img)
    progressBar:setBackgroundImage(params.bg)
    progressBar:setPosition(cc.p(checkint(x), checkint(y)))

    function progressBar:setWidth(width)
        self:setScaleX(checkint(width) / self:getContentSize().width)
        self:getLabel():setPositionX(self:getBoundingBox().width/2)
    end
    function progressBar:setHeight(height)
        self:setScaleY(checkint(height) / self:getContentSize().height)
        self:getLabel():setPositionY(self:getBoundingBox().height/2)
    end
    function progressBar:updateLabel(params)
        return ui.updateLabel(self, params)
    end
    function progressBar:setNowValue(value)
        self:setValue(math.min(self:getMaxValue(), checkint(value)))
    end

    if params then
        -- @see display.PDIR_TB, display.PDIR_BT, display.PDIR_LR, display.PDIR_RL
        if params.dir then progressBar:setDirection(params.dir) end
        if params.ap then progressBar:setAnchorPoint(params.ap) end
        if params.tag then progressBar:setTag(params.tag) end
        if params.scale then progressBar:setScale(params.scale) end
        if params.scaleX then progressBar:setScaleX(params.scaleX) end
        if params.scaleY then progressBar:setScaleX(params.scaleY) end
        if params.value then progressBar:setValue(params.value) end
        if params.min then progressBar:setMinValue(params.min) end
        if params.max then progressBar:setMaxValue(params.max) end
        if params.w then progressBar:setWidth(params.w) end
        if params.h then progressBar:setHeight(params.h) end
        if params.label ~= nil then progressBar:setShowValueLabel(params.label == true) end
    end
    return progressBar
end


--[[
    创建 CSlider 组件
    -- @param x : int                  所处X坐标
    -- @param y : int                  所处Y坐标
    -- @param params.img    : str      进度图片路径
    -- @param params.bg     : str      背景图片路径
    -- @param params.dir    : int      滚动条方向
    -- @param params.w      : int      缩放到的宽度
    -- @param params.h      : int      缩放到的高度
    -- @param params.label  : bool     是否显示标签
    -- @param params.ap     : cc.p     锚点
    -- @param params.value  : cc.p     当前进度
    -- @param params.max    : cc.p     最大进度
    -- @param params.min    : cc.p     最小进度
    -- @param params.tag    : int      标签
    -- @param params.scale  : float    整体缩放
    -- @param params.scaleX : float    x轴缩放
    -- @param params.scaleY : float    y轴缩放
]]
---@return CSlider
function display.newSlider(x, y, params)
    local slider = CSlider:create(params.sImg, params.pImg)
    slider:setBackgroundImage(params.bg)
    slider:setPosition(cc.p(checkint(x), checkint(y)))

    function slider:setWidth(width)
        self:setScaleX(checkint(width) / self:getContentSize().width)
        self:getLabel():setPositionX(self:getBoundingBox().width/2)
    end
    function slider:setHeight(height)
        self:setScaleY(checkint(height) / self:getContentSize().height)
        self:getLabel():setPositionY(self:getBoundingBox().height/2)
    end
    function slider:updateLabel(params)
        return ui.updateLabel(self, params)
    end
    -- 由于 slider 继承自 progress，所以min不支持负数，复写取值范围实现可以设置负值的min。
    function slider:setNowValue(value)
        self.realMowValue_ = math.min(self:getMaxValue(), checkint(value))
        local sliderMetatable = getmetatable(self)
        if checkint(self.realMinValue_) < 0 then
            sliderMetatable.setValue(self, self.realMowValue_ - self.realMinValue_)
        else
            sliderMetatable.setValue(self, self.realMowValue_)
        end
    end
    function slider:getNowValue()
        local sliderMetatable = getmetatable(self)
        local sliderNowValue  = sliderMetatable.getValue(self)
        if checkint(self.realMinValue_) < 0 then
            return self.realMinValue_ + sliderNowValue
        end
        return sliderNowValue
    end
    function slider:setMinValue(value)
        self.realMinValue_    = checkint(value)
        local sliderMetatable = getmetatable(self)
        sliderMetatable.setMinValue(self, math.max(self.realMinValue_, 0))
        self:checkValueRange_()
    end
    function slider:getMinValue()
        return self.realMinValue_ or 0
    end
    function slider:setMaxValue(value)
        self.realMaxValue_ = checkint(value)
        self:checkValueRange_()
    end
    function slider:getMaxValue()
        return self.realMaxValue_ or 100
    end
    function slider:checkValueRange_()
        local sliderMetatable = getmetatable(self)
        if self:getMinValue() < 0 then
            sliderMetatable.setMaxValue(self, self:getMaxValue() - self:getMinValue())
        else
            sliderMetatable.setMaxValue(self, self:getMaxValue())
        end
    end

    if params then
        -- @see display.PDIR_TB, display.PDIR_BT, display.PDIR_LR, display.PDIR_RL
        if params.dir then slider:setDirection(params.dir) end
        if params.ap then slider:setAnchorPoint(params.ap) end
        if params.tag then slider:setTag(params.tag) end
        if params.scale then slider:setScale(params.scale) end
        if params.scaleX then slider:setScaleX(params.scaleX) end
        if params.scaleY then slider:setScaleX(params.scaleY) end
        if params.value then slider:setValue(params.value) end
        if params.min then slider:setMinValue(params.min) end
        if params.max then slider:setMaxValue(params.max) end
        if params.w then slider:setWidth(params.w) end
        if params.h then slider:setHeight(params.h) end
        if params.label ~= nil then slider:setShowValueLabel(params.label == true) end
    end

    slider:setOnValueChangedScriptHandler(function(sender, value)
        sender:updateLabel({text = tostring(value)})
    end)
    return slider
end


--[[
    创建 bmfont 标签
    -- @param x : int               所处X坐标
    -- @param y : int               所处Y坐标
    -- @param params.ap   : cc.p    锚点
    -- @param params.tag  : int     标签
    -- @param params.text : str     初始文字
    -- @param params.path : str     fnt路径
]]
---@return cc.Label
function display.newBMFLabel(x, y, params)
    local fntFilePath = params.path or 'font/small/common_text_num.fnt'
    local bmFontlabel = cc.Label:createWithBMFont(fntFilePath, '')
    bmFontlabel:setPosition(cc.p(checkint(x), checkint(y)))

    if params then
        if params.ap then bmFontlabel:setAnchorPoint(params.ap) end
        if params.tag then bmFontlabel:setTag(params.tag) end
        if params.text then bmFontlabel:setString(params.text) end
    end
    return bmFontlabel
end


-------------------------------------------------------------------------------
-- layout
-------------------------------------------------------------------------------
-- Ps：布局会忽略全部对象的锚点设置

display.FLOW_C = ui.flowC -- 中心堆叠
display.FLOW_H = ui.flowH -- 水平流布局
display.FLOW_V = ui.flowV -- 垂直流布局

--[[
    流布局（单行的布局）Ps：先开个新坑，慢慢填常用布局
    -- @param basePos        : cc.p    基点坐标
    -- @param nodeList       : list    节点列表
    -- @param params.ap      : cc.p    对齐锚点（例如：0表示左对齐，0.5表示居中，1表示右对齐）
    -- @param params.type    : int     水平/垂直（默认水平）
    -- @param params.gapW    : int     水平间距
    -- @param params.gapH    : int     垂直间距
    -- @see display.FLOW_H
    -- @see display.FLOW_V
    -- @see display.FLOW_C
]]
function display.flowLayout(basePos, nodeList, params)
    local nodeGapW  = params and params.gapW or 0
    local nodeGapH  = params and params.gapH or 0
    local flowType  = params and params.type or display.FLOW_H
    local anchorPos = params and params.ap or display.LEFT_CENTER
    local basePoint = basePos or PointZero
    local nodeCount = #checktable(nodeList)

    local prevSpace = 0 -- 上一个距离空间
    local prevPoint = cc.p(basePoint.x, basePoint.y) -- 上一个位置
    local groupSize = cc.size(0, 0)  -- 总尺寸
    for index, node in ipairs(nodeList or {}) do
        local nodeRect = node:getBoundingBox()

        -------------------------------------------------
        -- horizontal align
        if flowType == display.FLOW_H then

            local offsetY = 0
            if 0.5-anchorPos.y > 0 then
                offsetY = node:getMarginB()
            elseif 0.5-anchorPos.y < 0 then
                offsetY = -node:getMarginT()
            end

            -- calculate nodePoint
            prevPoint.x = prevPoint.x + (node:getAnchorPoint().x) * nodeRect.width + prevSpace + node:getMarginL()
            prevPoint.y = basePoint.y + (node:getAnchorPoint().y) * nodeRect.height - (nodeRect.height * anchorPos.y) + offsetY
            prevSpace = (1-node:getAnchorPoint().x) * nodeRect.width + node:getMarginR()
            node:setPosition(prevPoint)
            
            -- calculate groupSize
            groupSize.width  = groupSize.width + nodeRect.width + node:getMarginL() + node:getMarginR()
            groupSize.height = math.max(groupSize.height, nodeRect.height + math.abs(offsetY))

            -- calculate gapW
            if index < nodeCount then
                groupSize.width = groupSize.width + nodeGapW
                prevPoint.x = prevPoint.x + nodeGapW
            end

        -------------------------------------------------
        -- vertical align
        elseif flowType == display.FLOW_V then
            local offsetX = 0
            if 0.5-anchorPos.x > 0 then
                offsetX = node:getMarginL()
            elseif 0.5-anchorPos.x < 0 then
                offsetX = -node:getMarginR()
            end

            -- calculate nodePoint
            prevPoint.x = basePoint.x + (node:getAnchorPoint().x) * nodeRect.width - (nodeRect.width * anchorPos.x) + offsetX
            prevPoint.y = prevPoint.y - (1-node:getAnchorPoint().y) * nodeRect.height - prevSpace - node:getMarginT()
            prevSpace = (node:getAnchorPoint().y) * nodeRect.height + node:getMarginB()
            node:setPosition(prevPoint)
            
            -- calculate groupSize
            groupSize.width  = math.max(groupSize.width, nodeRect.width + math.abs(offsetX))
            groupSize.height = groupSize.height + nodeRect.height + node:getMarginT() + node:getMarginB()

            -- calculate gapW
            if index < nodeCount then
                groupSize.height = groupSize.height + nodeGapH
                prevPoint.y = prevPoint.y - nodeGapH
            end

        -------------------------------------------------
        -- center Stack
        else
            local offsetX = 0
            if 0.5-anchorPos.x > 0 then
                offsetX = node:getMarginL()
            elseif 0.5-anchorPos.x < 0 then
                offsetX = -node:getMarginR()
            else
                offsetX = node:getMarginL() > 0 and node:getMarginL() or -node:getMarginR()
            end

            local offsetY = 0
            if 0.5-anchorPos.y > 0 then
                offsetY = node:getMarginB()
            elseif 0.5-anchorPos.y < 0 then
                offsetY = -node:getMarginT()
            else
                offsetY = node:getMarginB() > 0 and node:getMarginB() or -node:getMarginT()
            end

            prevPoint.x = basePoint.x + (node:getAnchorPoint().x) * nodeRect.width - (nodeRect.width * anchorPos.x) + offsetX
            prevPoint.y = basePoint.y + (node:getAnchorPoint().y) * nodeRect.height - (nodeRect.height * anchorPos.y) + offsetY
            node:setPosition(prevPoint)
        end
    end

    -- offset fix
    if flowType == display.FLOW_H then
        local offsetX = (groupSize.width * anchorPos.x)
        if offsetX ~= 0 then
            for _, node in ipairs(nodeList or {}) do
                node:setPositionX(node:getPositionX() - offsetX)
            end
        end
    elseif flowType == display.FLOW_V then
        local offsetY = (groupSize.height * anchorPos.y)
        if offsetY ~= 0 then
            for _, node in ipairs(nodeList or {}) do
                node:setPositionY(node:getPositionY() + offsetY)
            end
        end
    end

    return groupSize
end


-------------------------------------------------------------------------------
-- node extends
-------------------------------------------------------------------------------

local Node = cc.Node

--[[
    对齐到指定对象的某个位置（会忽略自身锚点）
    -- @param target         : node/display    对齐的目标对象，display为屏幕对齐（为nil时会找父级）
    -- @param alignAp        : cc.p            对齐的参照锚点（默认中心点）
    -- @param params.blank   : bool            忽略自身尺寸的对齐
    -- @param params.inside  : bool            对齐模式，内部或外部（默认外部对齐，如果目标是父级默认为内部对齐）
    -- @param params.parent  : bool            是否为父级对象（因为有些时候还没add就对齐，这时是不需要叠加父级坐标偏移的）
    -- @param params.offsetX : int             手动追加偏移x量
    -- @param params.offsetY : int             手动追加偏移y量
]]
function Node:alignTo(target, alignAp, _params)
    local params     = checktable(_params)
    local isBlank    = params.blank == true
    local isParent   = params.parent == true
    local isInside   = params.inside == true
    local offsetX    = checkint(params.offsetX)
    local offsetY    = checkint(params.offsetY)
    local alignAp    = alignAp or display.CENTER
    local alignPos   = cc.p(0, 0)

    local targetAp   = cc.p(0, 0)
    local targetPos  = cc.p(0, 0)
    local targetSize = cc.size(0, 0)

    local selfAp     = self:getAnchorPoint()
    local selfWidth  = isBlank and 0 or self:getBoundingBox().width
    local selfHeight = isBlank and 0 or self:getBoundingBox().height

    if target == nil and self:getParent() ~= nil then
        target   = self:getParent()
        isParent = params.parent == nil and true or isParent
        isInside = params.inside == nil and true or isInside
    end

    if target ~= nil then
        if target == display then
            targetSize.width  = display.width
            targetSize.height = display.height
        else
            targetAp          = target:getAnchorPoint()
            targetSize.width  = target:getBoundingBox().width
            targetSize.height = target:getBoundingBox().height
            targetPos.x       = isParent and (targetAp.x*targetSize.width) or target:getPositionX()
            targetPos.y       = isParent and (targetAp.y*targetSize.height) or target:getPositionY()
        end

        alignPos.x = targetPos.x + (alignAp.x - targetAp.x) * targetSize.width
        alignPos.y = targetPos.y + (alignAp.y - targetAp.y) * targetSize.height

        if isInside then
            alignPos.x = alignPos.x + ((1-alignAp.x) - (1-selfAp.x)) * selfWidth
            alignPos.y = alignPos.y + ((selfAp.y) - (alignAp.y)) * selfHeight
        else
            alignPos.x = alignPos.x + (alignAp.x - (1-selfAp.x)) * selfWidth
            alignPos.y = alignPos.y + (selfAp.y - (1-alignAp.y)) * selfHeight
        end
    end
    self:setPosition(cc.pAdd(cc.p(offsetX, offsetY), alignPos))

    return self
end


function Node:addList(nodeList, zorder)
    if type(nodeList) == 'userdata' then
        self:add(nodeList, zorder)
    else
        for _, node in ipairs(nodeList or {}) do
            if zorder then
                self:addChild(node, zorder)
            else
                self:addChild(node)
            end
        end
    end
    return nodeList
end


function Node:addAndClear(child, zorder, tag)
    self:removeAllChildren()
    self:add(child, zorder, tag)
    return child
end


-- margin 相关方法，生效于 layout
function Node:setMargin(t, r, b, l)
    self:setMarginT(t)
    self:setMarginB(b)
    self:setMarginL(l)
    self:setMarginR(r)
    return self
end
function Node:setMarginT(num)
    self.marginT_ = checkint(num)
    return self
end
function Node:getMarginT(num)
    return checkint(self.marginT_)
end
function Node:setMarginB(num)
    self.marginB_ = checkint(num)
    return self
end
function Node:getMarginB(num)
    return checkint(self.marginB_)
end
function Node:setMarginL(num)
    self.marginL_ = checkint(num)
    return self
end
function Node:getMarginL(num)
    return checkint(self.marginL_)
end
function Node:setMarginR(num)
    self.marginR_ = checkint(num)
    return self
end
function Node:getMarginR(num)
    return checkint(self.marginR_)
end
