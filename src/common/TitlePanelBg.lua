--[[
    通用的表标题背景层功能
    title: 标题文字
    type: 面板大小类别
        [2:  3:  5:  99(好友)]
    closable: 是否存在关闭回调数据 用来判断是否添加关闭按钮
]]
---@class TitlePanelBg
local TitlePanelBg = class('TitlePanelBg', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.TitlePanelBg'
	node:enableNodeEvents()
	return node
end)

function TitlePanelBg:ctor( ... )
	local args = unpack({...})
	if not args.type then
        assert(true, "指定的common的id数字")
    end

    self.cb = args.cb
    self.isGuide = false
    local isCenter = args.isCenter
    if args.isGuide == true then
        self.isGuide = true
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function(sender)
        if self.cb then self.cb() end
    end)

    -- bg
    local view = CLayout:create()
    local bg = display.newImageView(_res(string.format( "ui/common/common_bg_%d.png", checkint(args.type))), 0, 0)
    local size = bg:getContentSize()
    if self.cb then
        size.width = size.width + 60
        size.height = size.height
    end
    view:setContentSize(size)
    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy )})
    self:addChild(view, 2)

    local tempLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    tempLayer:setTouchEnabled(true)
    tempLayer:setContentSize(size)
    display.commonUIParams(tempLayer, {ap = display.CENTER, po = cc.p(display.cx, display.cy )})
    self:addChild(tempLayer)
    if isCenter == true then
        display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
        display.commonUIParams(tempLayer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    end


    local bottomLayout = CLayout:create(size)
    -- bottomLayout:setBackgroundColor(ccc3FromInt("ff9999"))
    bottomLayout:setBackgroundColor(cc.c4b(100,100,100,20))
    display.commonUIParams(bottomLayout, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
    view:addChild(bottomLayout) --标题背景加关闭的逻辑
    display.commonUIParams(bg, { ap = display.LEFT_BOTTOM, po = cc.p(0, 0)})
    bottomLayout:addChild(bg,2)
    -- title
    local offsetY = 10
    local offsetX = 12
    if args.offsetX then
        offsetX = args.offsetX
    end
    if args.offsetY then
        offsetY = args.offsetY
    end
    local titleBg = display.newButton(bg:getContentSize().width * 0.5 + offsetX, size.height - offsetY, {scale9 = true, n = _res('ui/common/common_bg_title_2.png'), enable = false})
    display.commonUIParams(titleBg, {ap = display.CENTER_TOP})
    display.commonLabelParams(titleBg, fontWithColor(1,{fontSize = 24, text = args.title, color = 'ffffff',offset = cc.p(0, -2)}))

    -- 修正标题超框的问题
    local fixedPaddingW = 25
    if (titleBg:getContentSize().width - fixedPaddingW * 2) < display.getLabelContentSize(titleBg:getLabel()).width then
        display.commonLabelParams(titleBg, {paddingW = fixedPaddingW})
    end

    bg:addChild(titleBg,2)

    local offsetButton = 0
    if args.offsetY then
        offsetButton = 10
    end
    local closeBtn = display.newButton(size.width, size.height, {n = _res('ui/common/common_btn_quit.png')})
    display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(size.width - 10, size.height + offsetButton)})
    bottomLayout:addChild(closeBtn, 40)
    closeBtn:setOnClickScriptHandler(function(sender)
        if self.cb then self.cb() end
    end)
    if not self.cb then
        closeBtn:setVisible(false)
    end

    self.viewData = {
        view = view,
        tempLayer = tempLayer,
        bview = bottomLayout,
        titleLabel = titleBg,
        closeBtn = closeBtn,
        eaterLayer = eaterLayer,
    }
end

--[[
--添加conentView的功能
--]]
function TitlePanelBg:AddContentView( cview )
    -- body
    local size = self.viewData.view:getContentSize()
    local csize = cview:getContentSize()
    if csize.width > size.width then
        self.viewData.view:setContentSize(cc.size(csize.width, size.height))
    end
    display.commonUIParams(cview, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
    cview:setTag(788)
    self.viewData.view:addChild(cview, 10)
    local size = self.viewData.view:getContentSize()
    local xx = size.width * 0.5
    if self.cb then xx = xx - 30 end
    local yy = - 14
    local closeLabel = display.newButton(xx,yy,{
        n = _res('ui/common/common_bg_close.png'),-- common_click_back
    })
    closeLabel:setEnabled(false)
    display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
    self.viewData.view:addChild(closeLabel, 10)
	self:setTag(9999)
    if self.isGuide then
        PlayAudioClip(AUDIOS.UI.ui_window_open.id)
        self.isAction = false
    else
        self.viewData.view:setScale(0.96)
        display.animationIn(self.viewData.view,function()
            PlayAudioClip(AUDIOS.UI.ui_window_open.id)
            self.isAction = false
        end)
    end
end

--[[
--添加conentView的功能
--]]
function TitlePanelBg:AddContentViewNoCloseLabel( cview )
    -- body
    local size = self.viewData.view:getContentSize()
    local csize = cview:getContentSize()
    if csize.width > size.width then
        self.viewData.view:setContentSize(cc.size(csize.width, size.height))
    end
    display.commonUIParams(cview, {ap = display.LEFT_BOTTOM, po = cc.p(32,0)})
    cview:setTag(788)
    self.viewData.view:addChild(cview, 10)
    local size = self.viewData.view:getContentSize()
    local xx = size.width * 0.5
    if self.cb then xx = xx - 30 end
    self:setTag(9999)
    if self.isGuide then
        PlayAudioClip(AUDIOS.UI.ui_window_open.id)
        self.isAction = false
    else
        self.viewData.view:setScale(0.96)
        display.animationIn(self.viewData.view,function()
            PlayAudioClip(AUDIOS.UI.ui_window_open.id)
            self.isAction = false
        end)
    end
end

function TitlePanelBg:SetText( text )
    if self.viewData.titleLabel then
        self.viewData.titleLabel:setText(text)
    end
end

return TitlePanelBg
