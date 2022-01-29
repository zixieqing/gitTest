local clb = class('CloseBgNode',function ()
    local clb = CLayout:create(cc.size(display.width,display.height))
    clb.name = 'common.CloseBgNode'
    clb:enableNodeEvents()
    return clb
end)

function clb:ctor(...)
    local arg = unpack({...})
    local __callback = arg.callback
    self.cb = arg.callback
    self.executeAction = arg.executeAction
    self.isShowCloseLabel = (arg.showLabel == nil and true or arg.showLabel)
    self.isAction = true
    self.isCloseable_ = true

    local p = utils.getLocalCenter(self)
    local closeAction = function (sender)
        -- sender:setTouchEnabled(false) --禁用掉关闭层的逻辑
        if self.isAction == false and self.isCloseable_ == true then
            self.isAction = true
            if self.executeAction then
                utils.locateNodByLocator(self,'788',function(node)
                    self.cb()
                end)   
            else

                if self.cb then
                    self.cb()
                end
            end
        end
    end
    local colorBg = display.newLayer(0,0,{
        color = cc.c4b(0,0,0,178),enable = true,
        cb = closeAction
    })
    self:addChild(colorBg)
    -- local __transparentBg = display.newImageView(_res('ui/common/common_bg_mask.png'),checkint(p.x),checkint(p.y),{
    --     enable = true
    -- })
    -- __transparentBg:setOnClickScriptHandler(closeAction)
    -- self:addChild(__transparentBg)
end

function clb:isCloseable()
    return checkint(self.isCloseable_) == true
end
function clb:setCloseable(isCloseable)
    self.isCloseable_ = isCloseable == true
end

function clb:addContentView(cview,hasClose, isGuide)
    if not hasClose then hasClose = false end
    local lsize = cview:getContentSize()
    if hasClose then
        lsize.width = lsize.width + 60
        lsize.height = lsize.height + 10
    end
    local contentView = CLayout:create(lsize)
    -- contentView:setBackgroundColor(ccc3FromInt("ff9999"))
    local p = utils.getLocalCenter(self)
    local w = lsize.width
    -- if hasClose then w = lsize.width - 60 end
    local __clickAction = display.newImageView(_res('ui/common/story_tranparent_bg.png'), lsize.width * 0.5, lsize.height * 0.5,{
        scale9 = true, enable = true, size = cc.size(w, lsize.height)
    })
    contentView:addChild(__clickAction,1)
    display.commonUIParams(contentView,{po = cc.p(checkint(p.x),checkint(p.y))})
	-- contentView:setScale(0.96)
    --修复引导bug
    if isGuide then
        contentView:setScale(1.0)
    end
    -- cview:setVisible(false)
    -- cview:setHidden(true)
    display.commonUIParams(cview, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
    cview:setTag(788)
    contentView:addChild(cview, 4)
    contentView:setName('contentView') 
    contentView:setTag(788)
    self:addChild(contentView,3)
	self:setTag(9999)
	
	if self.isShowCloseLabel == true then
	   local xx = lsize.width * 0.5 
       if hasClose then xx = xx - 30 end
	   local yy = - 14
	   local closeLabel = display.newButton(xx,yy,{
            n = _res('ui/common/common_bg_close.png'),-- common_click_back
	   })
	   closeLabel:setEnabled(false)
	   display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
	   contentView:addChild(closeLabel,10)
       closeLabel:setTag(22)
       closeLabel:getLabel():setTag(22)
	end
    if hasClose then
       local pp = FTUtils:getOrigin(contentView)
       local closeBtn = display.newButton(0, 0, {ap = display.LEFT_TOP,n = _res('ui/common/common_btn_quit.png'), cb = handler(self, self.onClose)})
       display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(lsize.width,lsize.height)})
       contentView:addChild(closeBtn,40)
       closeBtn:setTag(250)
    end
    contentView:setScale(0.96)
    display.animationIn(contentView,function()
        self.isAction = false
        PlayAudioClip(AUDIOS.UI.ui_window_open.id)
    end)
end
function clb:setEnableAction(isTrue)
    self.executeAction = isTrue
end
function clb:onClose()
    if self.isAction == false and self.isCloseable_ == true then
        self.isAction = true 
        if self.executeAction then
            utils.locateNodByLocator(self,'788',function(node)
                self.cb()
            end)   
        else
            if self.cb then
                self.cb()
            end
        end
        
    end
end

function clb:onExit()

end

return clb
