-------------------------------------------------------------------------------
-- CommonEditBox Brief
-- 
-- Author: kaishiqi <zhangkai@funtoygame.com>
-- 
-- Create: 2021-07-23 17:01:51
-------------------------------------------------------------------------------

---@class CommonEditBox : CLayout
local CommonEditBox = class('CommonEditBox', function()
    return ui.layer({name = 'common.CommonEditBox', enableEvent = true})
end)


local DefaultDefine = {
    ACT_RELOAD_TEXT  = 1,
    ACT_RELOAD_PLACE = 2,
    IMG_ALPHA        = _res('ui/common/story_tranparent_bg.png'),
    TEXT_FONT        = {fontSize = 24, color = '#B47643'},
    PLACE_FONT       = {fontSize = 24, color = '#D4C6BA'},
    INPUT_MODE       = ui.INPUT_MODE.SINGLELINE,
    RETURN_TYPE      = cc.KEYBOARD_RETURNTYPE_DONE,
    EDIT_BORDER_POS  = cc.p(4,4),
}


function CommonEditBox.CreateView(initArgs)
    local view = ui.layer({ap = ui.lb})

    local bgPath  = initArgs.bgPath
    local bgImage = ui.image({img = bgPath, ap = ui.lb, scale9 = true, capInsets = initArgs.bgCapInsets})
    local bgSize  = bgImage:getOriginalSize()
    view:setContentSize(bgSize)
    view:addChild(bgImage)

    local scrollView = ui.scrollView({size = bgSize, dir = display.SDIR_V, ap = ui.lb})
    view:addChild(scrollView)

    local touchLayer = ui.layer({ap = ui.lb, size = bgSize, color = cc.r4b(0), enable = true})
    scrollView:getContainer():addChild(touchLayer)

    local descrLabel = ui.label({ap = ui.lt, w = bgSize.width})
    touchLayer:addChild(descrLabel)

    local placeLabel = ui.label({ap = ui.lt, w = bgSize.width})
    touchLayer:addChild(placeLabel)

    local editBox = ccui.EditBox:new()  -- 这里不能create，要用onEnter初始
    editBox:setAnchorPoint(ui.cc)
    view:addChild(editBox)

    ---@class CommonEditBox.ViewData
    local viewData = {
        view       = view,
        bgImage    = bgImage,
        scrollView = scrollView,
        touchLayer = touchLayer,
        placeLabel = placeLabel,
        descrLabel = descrLabel,
        editBox    = editBox,
    }
    return viewData
end


--[[
    size           cc.size 控件尺寸；默认为bg图大小
    bg             string  底框图 路径；默认为 common_bt_text
    capInsets      cc.rect 底框图 切分区域；默认为3等分尺寸
    place          string  占位符 文字
    placeFontSize  number  占位符 字体大小
    placeFontColor string  占位符 字体颜色
    text           string  文本框 文字
    textFontSize   number  文本框 字体大小
    textFontColor  string  文本框 字体颜色
    textLen        number  文本框 字符长度；默认-1，不限制
    inputMode      number  文本框 输入模式；默认单行
    returnType     number  文本框 回车按钮的样式；默认“完成”
    isEnable       bool    是否 允许编辑；默认true
    isFilter       bool    是否 过滤文字；默认true
    borderDir      cc.dir  文本框 范围内边界
]]
---@return CommonEditBox
function CommonEditBox:ctor(args)
    local initArgs = checktable(args)
    self.isInited_ = false

    -- create view
    local viewArgs = {
        bgPath      = initArgs.bg or DefaultDefine.IMG_ALPHA,
        bgCapInsets = initArgs.capInsets,
    }
    self.viewData_ = CommonEditBox.CreateView(viewArgs)
    self:addChild(self:getViewData().view)

    -- add listener
    self:getViewData().touchLayer:setOnClickScriptHandler(handler(self, self.onClickTouchLayerHandler_))
    self:getViewData().editBox:registerScriptEditBoxHandler(handler(self, self.onEventToEditBoxHandler_))

    -- init views
    self:setTextLen(initArgs.textLen or -1)
    self:setEditEnable(initArgs.isEnable ~= false)
    self:setFilterText(initArgs.isFilter ~= false)
    self:setBorderDir(initArgs.borderDir or cc.dir(0,0,0,0))
    self:setInputMode(initArgs.inputMode or DefaultDefine.INPUT_MODE)
    self:setReturnType(initArgs.returnType or DefaultDefine.RETURN_TYPE)
    self:setViewSize(initArgs.size or self:getViewData().view:getContentSize())
    self:setTextFontColor(initArgs.textFontColor or DefaultDefine.TEXT_FONT.color)
    self:setTextFontSize(initArgs.textFontSize or DefaultDefine.TEXT_FONT.fontSize)
    self:setPlaceFontColor(initArgs.placeFontColor or DefaultDefine.PLACE_FONT.color)
    self:setPlaceFontSize(initArgs.placeFontSize or DefaultDefine.PLACE_FONT.fontSize)
    self:setPlace(initArgs.place or '')
    self:setText(initArgs.text or '')
end


function CommonEditBox:onCleanup()
    self:getViewData().editBox:unregisterScriptEditBoxHandler()
end


------------------------------------------
-- get / set

---@return CommonEditBox.ViewData
function CommonEditBox:getViewData()
    return self.viewData_
end


---@return cc.size 视图大小
function CommonEditBox:getViewSize()
    return self.viewSize_ or SizeZero
end
function CommonEditBox:setViewSize(size)
    self.viewSize_ = clone(size)
    self:updateViewSize_()
end


---@return cc.dir 内边距离
function CommonEditBox:getBorderDir()
    return self.borderDir_
end
function CommonEditBox:setBorderDir(dir)
    self.borderDir_ = clone(dir)
    self:updateTextContent_()
end


---@return boolean @ 是否 允许编辑
function CommonEditBox:isEditEnable()
    return self.isEditEnable_
end
function CommonEditBox:setEditEnable(isEnable)
    self.isEditEnable_ = checkbool(isEnable)
    self:getViewData().touchLayer:setTouchEnabled(self:isEditEnable())
end


---@return boolean @ 是否 过滤关键字
function CommonEditBox:isFilterText()
    return self.isFilterText_
end
function CommonEditBox:setFilterText(isFilter)
    self.isFilterText_ = checkbool(isFilter)
end


---@return boolean @ 获取 输入模式
function CommonEditBox:getInputMode()
    return self.inputMode_
end
function CommonEditBox:setInputMode(inputMode)
    self.inputMode_ = checkint(inputMode)
    if self.isInited_ then
        self:getViewData().editBox:setInputMode(self:getInputMode())
    end
end


---@return boolean @ 获取 过滤关键字
function CommonEditBox:getReturnType()
    return self.returnType_
end
function CommonEditBox:setReturnType(returnType)
    self.returnType_ = checkint(returnType)
    if self.isInited_ then
        self:getViewData().editBox:setReturnType(self:getReturnType())
    end
end


---@return integer @ 获取 文字长度
function CommonEditBox:getTextLen()
    return self.textLen_
end
function CommonEditBox:setTextLen(length)
    self.textLen_ = checkint(length)
    if self.isInited_ then
        self:getViewData().editBox:setMaxLength(self:getTextLen())
    end
end


---@return string @ 获取 内容文字
function CommonEditBox:getText()
    return checkstr(self.text_)
end
function CommonEditBox:setText(text)
    local newText = checkstr(text)
    if self:isFilterText() then
        newText = nativeSensitiveWords(newText)
    end
    if self:getTextLen() > 0 then
        local textLen = string.utf8len(newText)
        if textLen > self:getTextLen() then
            newText = utf8sub(newText, 1, self:getTextLen())
        end
    end
    if self.text_ ~= newText then
        self.text_ = newText
        self:updateTextContent_()
    end
end


---@return number @ 获取 内容字体大小
function CommonEditBox:getTextFontSize()
    return checknumber(self.textFontSize_)
end
function CommonEditBox:setTextFontSize(fontSize)
    self.textFontSize_ = checknumber(fontSize)
    self:updateTextContent_()
end


---@return number @ 获取 内容字体颜色
function CommonEditBox:getTextFontColor()
    return checkstr(self.textFontColor_)
end
function CommonEditBox:setTextFontColor(fontColor)
    self.textFontColor_ = checkstr(fontColor)
    self:updateTextContent_()
end


---@return string @ 获取 占位文字
function CommonEditBox:getPlace()
    return checkstr(self.place_)
end
function CommonEditBox:setPlace(text)
    self.place_ = checkstr(text)
    self:updatePlaceContent_()
end


---@return number @ 获取 占位字体大小
function CommonEditBox:getPlaceFontSize()
    return checknumber(self.placeFontSize_)
end
function CommonEditBox:setPlaceFontSize(fontSize)
    self.placeFontSize_ = checknumber(fontSize)
    self:updatePlaceContent_()
end


---@return number @ 获取 占位字体颜色
function CommonEditBox:getPlaceFontColor()
    return checkstr(self.placeFontColor_)
end
function CommonEditBox:setPlaceFontColor(fontColor)
    self.placeFontColor_ = checkstr(fontColor)
    self:updatePlaceContent_()
end


-------------------------------------------------
-- private

function CommonEditBox:toEditMode_()
    self:getViewData().editBox:setVisible(true)
    self:getViewData().scrollView:setVisible(false)
end


function CommonEditBox:toShowMode_()
    self:getViewData().editBox:setVisible(false)
    self:getViewData().scrollView:setVisible(true)
end


function CommonEditBox:updateViewSize_()
    local viewSize  = self:getViewSize()
    local borderDir = self:getBorderDir()
    local editSize  = cc.size(
        viewSize.width - borderDir.left - borderDir.right,
        viewSize.height - borderDir.top - borderDir.bottom
    )
    
    local editBorderL = DefaultDefine.EDIT_BORDER_POS.x
    local editBorderB = DefaultDefine.EDIT_BORDER_POS.y
    local editBorderW = DefaultDefine.EDIT_BORDER_POS.x*2
    local editBorderH = DefaultDefine.EDIT_BORDER_POS.y*2
    local scrollSize  = cc.resize(editSize, -editBorderW, -editBorderH)
    self:setContentSize(viewSize)
    self:getViewData().view:setContentSize(viewSize)
    self:getViewData().bgImage:setContentSize(viewSize)
    self:getViewData().editBox:setContentSize(editSize)
    self:getViewData().editBox:setPositionX(viewSize.width/2)
    self:getViewData().editBox:setPositionY(viewSize.height/2)
    self:getViewData().scrollView:setPositionX(borderDir.left + editBorderL)
    self:getViewData().scrollView:setPositionY(borderDir.bottom + editBorderB)
    self:getViewData().scrollView:setContentSize(scrollSize)
    
    display.commonLabelParams(self:getViewData().placeLabel, {w = scrollSize.width})
    display.commonLabelParams(self:getViewData().descrLabel, {w = scrollSize.width})
    
    local descrHeight = self:getViewData().descrLabel:getSize().height + editBorderH
    local placeHeight = self:getViewData().placeLabel:getSize().height + editBorderH
    local textSize    = cc.size(scrollSize.width, math.max(descrHeight, scrollSize.height))
    local isEmptyText = string.len(self:getText()) == 0
    self:getViewData().touchLayer:setContentSize(textSize)
    self:getViewData().scrollView:setContainerSize(textSize)
    self:getViewData().scrollView:setContentOffsetToTop()
    self:getViewData().placeLabel:setVisible(isEmptyText)
    self:getViewData().descrLabel:setVisible(not isEmptyText)
    self:getViewData().placeLabel:setPositionY(textSize.height)
    self:getViewData().descrLabel:setPositionY(textSize.height)
end


function CommonEditBox:updateTextContent_()
    if not self:getActionByTag(DefaultDefine.ACT_RELOAD_TEXT) then
        self:runAction(cc.CallFunc:create(function()
            local descrLabel = self:getViewData().descrLabel
            local editBox    = self:getViewData().editBox
            editBox:setText(self:getText())
            editBox:setFontSize(self:getTextFontSize())
            editBox:setFontColor(ccc3FromInt(self:getTextFontColor()))
            ui.updateLabel(descrLabel, {fontSize = self:getTextFontSize(), color = self:getTextFontColor(), text = self:getText()})
            self:updateViewSize_()
        end)):setTag(DefaultDefine.ACT_RELOAD_TEXT)
    end
end


function CommonEditBox:updatePlaceContent_()
    if not self:getActionByTag(DefaultDefine.ACT_RELOAD_PLACE) then
        self:runAction(cc.CallFunc:create(function()
            local placeLabel = self:getViewData().placeLabel
            local editBox    = self:getViewData().editBox
            editBox:setPlaceHolder(self:getPlace())
            editBox:setPlaceholderFontSize(self:getPlaceFontSize())
            editBox:setPlaceholderFontColor(ccc3FromInt(self:getPlaceFontColor()))
            ui.updateLabel(placeLabel, {fontSize = self:getPlaceFontSize(), color = self:getPlaceFontColor(), text = self:getPlace()})
            self:updateViewSize_()
        end)):setTag(DefaultDefine.ACT_RELOAD_PLACE)
    end
end


-------------------------------------------------
-- handler

function CommonEditBox:onEnter()
    -- 一定要用先让 ccui.EditBox 在onEnter后初始化，不然真机上会出现输入框尺寸不对的bug。
    if not self.isInited_ then
        local editBox    = self:getViewData().editBox
        editBox:initWithSizeAndBackgroundSprite(editBox:getContentSize(), DefaultDefine.IMG_ALPHA)
        
        self.isInited_ = true
        self:setInputMode(self:getInputMode())
        self:setReturnType(self:getReturnType())
        self:setTextLen(self:getTextLen())
        self:updateTextContent_()
        self:updatePlaceContent_()
        self:toShowMode_()
    end
end


function CommonEditBox:onClickTouchLayerHandler_(sender)
    self:toEditMode_()

    -- 吊起 editBox 键盘
    local editBox = self:getViewData().editBox
    editBox:touchDownAction(editBox, ccui.TouchEventType.ended)
end


function CommonEditBox:onEventToEditBoxHandler_(eventType, sender)
    if eventType == 'began' then  -- 输入开始
    elseif eventType == 'ended' then  -- 输入结束
        self:toShowMode_()

        -- update text
        self:setText(sender:getText())

    elseif eventType == 'changed' then  -- 内容变化
    elseif eventType == 'return' then  -- 从输入返回
    end
end


return CommonEditBox
