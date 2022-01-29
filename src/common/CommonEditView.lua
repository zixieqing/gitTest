--[[
 * descpt : 通用编辑 界面
 ]]

 local CommonEditView = class('CommonEditView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.CommonEditView'
	node:enableNodeEvents()
	return node
end)


--==============================--
--desc:
--time:2017-12-30 04:32:59
--@args:
--      @bg: 底图
--      @isScale9: 是不是 .9
--      @bgSize: 只有为 isScale9 为true  传入 此参数 才有效 否则  默认 为 背景图大小
--@return 
--==============================--
function CommonEditView:ctor( ... )
    self.args = unpack({...})

    self.bg       = self.args.bg or 'ui/union/guild_declaration_bg.png'
    self.isScale9 = checkbool(self.args.isScale9)
    self.bgSize   = self.args.bgSize

    self.descW    = self.args.descW or 23
    self.text     = self.args.text or ''
    self.labelFont     = self.args.labelFont or fontWithColor(6)
    self.isEnableEditBox = self.args.isEnableEditBox == nil and true or self.args.isEnableEditBox
    self.isFilterText = self.args.isFilterText == nil and true or self.args.isFilterText

    -- init editbox data
    self.boxFontSize = self.args.boxFontSize or fontWithColor('M2PX').fontSize
    self.boxFontColor   = self.args.boxFontColor or '#5b3c25'
    self.boxInputMode = self.args.boxInputMode or cc.EDITBOX_INPUT_MODE_SINGLELINE
    self.placeHolder = self.args.placeHolder or ''
    self.placeholderFontSize = self.args.placeholderFontSize or 22
    self.placeholderFontColor = self.args.placeholderFontColor or '#9c9c9c'
    self.returnType = self.args.returnType or cc.KEYBOARD_RETURNTYPE_DONE
    self.maxLength = self.args.maxLength

    self:initialUI()
end

function CommonEditView:initialUI()
    
    local CreateView = function ()
        local bg = display.newImageView(_res(self.bg), 0, 0, {ap = display.LEFT_BOTTOM, scale9 = self.isScale9})
        local bgSize = bg:getContentSize()
        if self.isScale9 and self.bgSize then
             bg:setContentSize(self.bgSize)
        else
            self.bgSize = bgSize
        end

        local view = display.newLayer(0, 0, {size = self.bgSize, ap = display.LEFT_BOTTOM})
        view:addChild(bg)
        self:addChild(view)

        local descTouchLayer = display.newLayer(0,0,{ap = display.LEFT_BOTTOM, size = self.bgSize, color = cc.c4b(0,0,0,0), enable = self.isEnableEditBox, cb = handler(self, self.OnDescTouchAction)})
        local descLabel = display.newRichLabel(self.bgSize.width / 2, self.bgSize.height - 5,{ap = display.CENTER_TOP, w = self.descW})
        descTouchLayer:addChild(descLabel)
        
        local scrollView = CScrollView:create(self.bgSize)
        scrollView:setDirection(eScrollViewDirectionVertical)
        scrollView:setAnchorPoint(display.CENTER)
        scrollView:setPosition(cc.p(self.bgSize.width / 2, self.bgSize.height / 2))
        view:addChild(scrollView)
        -- scrollView:setBackgroundColor(cc.c3b(100,100,200))
        scrollView:setContainerSize(self.bgSize)
        scrollView:getContainer():addChild(descTouchLayer)

        -- display.commonUIParams(descTouchLayer, {po = cc.p(self.bgSize.width / 2, self.bgSize.height)})

        local descBox = ccui.EditBox:create(self.bgSize, _res(self.bg))
        descBox:setFontSize(self.boxFontSize)
        descBox:setFontColor(ccc3FromInt(self.boxFontColor))
        descBox:setInputMode(self.boxInputMode)
        descBox:setPlaceHolder(self.placeHolder)
        descBox:setPlaceholderFontSize(self.placeholderFontSize)
        descBox:setPlaceholderFontColor(ccc3FromInt( self.placeholderFontColor))
        descBox:setReturnType(self.returnType)
        if self.maxLength then
            descBox:setMaxLength(self.maxLength)
        end
        display.commonUIParams(descBox, {po = cc.p(self.bgSize.width / 2, self.bgSize.height / 2), ap = display.CENTER})
        descBox:registerScriptEditBoxHandler(handler(self, self.OnEditDescAction))
        view:addChild(descBox)
        descBox:setVisible(false)

        return {
            view      = view,
            scrollView = scrollView,
            descLabel = descLabel,
            descTouchLayer = descTouchLayer,
            descBox   = descBox,
        }
    end

    xTry(function ( )
		self.viewData_ = CreateView()
        self:setContentSize(self.bgSize)
	end, __G__TRACKBACK__)
end

function CommonEditView:OnDescTouchAction(sender)
    sender:setVisible(false)
    local descBox = self:getViewData().descBox
    descBox:setVisible(true)
    -- 吊起 editbox 键盘
    descBox:touchDownAction(descBox, ccui.TouchEventType.ended)
end

function CommonEditView:OnEditDescAction(eventType, sender)
    if eventType == 'began' then  -- 输入开始

    elseif eventType == 'ended' then  -- 输入结束
        sender:setVisible(false)
        self:getViewData().descTouchLayer:setVisible(true)
        local text = sender:getText()

        if self.isFilterText then
             text = nativeSensitiveWords(text)
             sender:setText(text)
        end

        self:setText(text)
    elseif eventType == 'changed' then  -- 内容变化

    elseif eventType == 'return' then  -- 从输入返回

    end
end

------------------------------------------
-- get / set

function CommonEditView:getText()
    return self.text
end

function CommonEditView:setText(text)

    if text == nil or self.text == text then return end

    self.text = text

    local descLabel = self:getViewData().descLabel
    self.labelFont.text = text
    display.reloadRichLabel(descLabel, {c = {self.labelFont}})

    self:updateScrollContainerSize()
end

function CommonEditView:updateScrollContainerSize()
    local descLabel = self:getViewData().descLabel
    local scrollView = self:getViewData().scrollView
    local descTouchLayer = self:getViewData().descTouchLayer

    local descLabelSize = display.getLabelContentSize(descLabel)
    local scrollView = self:getViewData().scrollView
    local descTouchLayer = self:getViewData().descTouchLayer

    local scrollViewContainerSize = scrollView:getContainerSize()
    local scrollViewSize = scrollView:getContentSize()

    local updateSize = function (newSize)
        descTouchLayer:setContentSize(newSize)

        -- 更新 scrollView ContainerSize
        scrollView:getContainer():setContentSize(newSize)
        scrollView:setContentSize(self.bgSize)
        scrollView:setContentOffsetToTop()

        display.commonUIParams(descLabel, {po = cc.p(newSize.width / 2, newSize.height - 5)})
    end
    
    if descLabelSize.height > scrollViewContainerSize.height then
        local newSize = cc.size(scrollViewContainerSize.width, descLabelSize.height)
        updateSize(newSize)
    elseif descLabelSize.height < self.bgSize.height then
        local newSize = cc.size(scrollViewContainerSize.width, self.bgSize.height)
        updateSize(newSize)
    end
end

function CommonEditView:setEditBoxFontSize(fontSize)
    if fontSize == nil then return end
    self.boxFontSize = fontSize
    local descBox = self:getViewData().descBox
    descBox:setFontSize(fontSize)
end

function CommonEditView:setEditBoxFontColor(color)
    if color == nil then return end
    self.boxFontColor = color
    local descBox = self:getViewData().descBox
    descBox:setFontColor(ccc3FromInt(color))
end

function CommonEditView:setEditBoxInputMode(inputMode)
    if inputMode == nil then return end
    self.boxInputMode = inputMode
    local descBox = self:getViewData().descBox
    descBox:setInputMode(inputMode)
end

function CommonEditView:setEditBoxPlaceHolder(placeHolder)
    if placeHolder == nil then return end
    self.placeHolder = placeHolder
    local descBox = self:getViewData().descBox
    descBox:setPlaceHolder(placeHolder)
end

function CommonEditView:setEditBoxPlaceholderFontSize(placeholderFontSize)
    if placeholderFontSize == nil then return end
    self.placeholderFontSize = placeholderFontSize
    local descBox = self:getViewData().descBox
    descBox:setPlaceholderFontSize(placeholderFontSize)
end

function CommonEditView:setEditBoxPlaceholderFontColor(placeholderFontColor)
    if placeholderFontColor == nil then return end
    self.placeholderFontColor = placeholderFontColor
    local descBox = self:getViewData().descBox
    descBox:setPlaceholderFontColor(ccc3FromInt(placeholderFontColor))
end

function CommonEditView:setEditBoxReturnType(returnType)
    if returnType == nil then return end
    self.returnType = returnType
    local descBox = self:getViewData().descBox
    descBox:setReturnType(returnType)
end

function CommonEditView:registerScriptEditBoxHandler(editBoxHandler)
    if editBoxHandler == nil then return end
   local descBox = self:getViewData().descBox
   descBox:registerScriptEditBoxHandler(editBoxHandler)
end

function CommonEditView:getViewData()
	return self.viewData_
end

-- get / set
------------------------------------------
function CommonEditView:onExit( ... )
    self:getViewData().descBox:unregisterScriptEditBoxHandler()
end

return CommonEditView