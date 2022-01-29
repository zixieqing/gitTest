--[[
	输入召回码UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecallInvitedCodeInputLayer = class('RecallInvitedCodeInputLayer', GameScene)

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallInvitedCodeInputLayer:ctor( ... )
    --创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
	self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        self:removeFromParent()
	end)
    local function CreateView( ... )
		local size = display.size
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0, 0)})
        self:addChild(view)

        -- 背景图片
        local bg = display.newLayer(utils.getLocalCenter(view).x, utils.getLocalCenter(view).y, {enable = true, bg = _res('ui/common/common_bg_5.png'), ap = cc.p(0.5, 0.5)})
	    view:addChild(bg)
        local bgSize = bg:getContentSize()

	    -- title
	    local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
	    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 -3)})
	    display.commonLabelParams(titleBg,
	    	{text = __('御侍召回'),
	    	fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
	    	offset = cc.p(0, -2)})
        bg:addChild(titleBg)
    
        local tempLayer = display.newLayer(display.cx, display.cy, {size = bg:getContentSize(), ap = display.CENTER, color = cc.r4b(0), enable = true})
		view:addChild(tempLayer)

		local xx = display.cx
    	local yy = display.cy - bg:getContentSize().height * 0.5 - 14
    	local closeLabel = display.newButton(xx,yy,{
    	    n = _res('ui/common/common_bg_close.png'),-- common_click_back
    	})
    	closeLabel:setEnabled(false)
    	display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
        view:addChild(closeLabel, 10)
        
        local bgImageOne = display.newImageView(_res("ui/home/infor/agent_bg_code.png") )
    
        -- 内容的content
        local contentSize = bgImageOne:getContentSize()
        bgImageOne:setPosition(contentSize.width/2 ,contentSize.height/2 )
        local contentLayout = display.newLayer(size.width/2 , size.height/2 , { ap  = display.CENTER, size =  contentSize})
        contentLayout:addChild(bgImageOne)
        view:addChild(contentLayout)
    
        -- 绑定按钮
        local  makeSureBtn  =display.newButton(contentSize.width/2,60 ,{n = _res('ui/common/common_btn_orange.png'), ap = display.CENTER } )
        contentLayout:addChild(makeSureBtn)
        display.commonLabelParams(makeSureBtn , fontWithColor('14',{text = __('绑定') }) )
        -- makeSureBtn:setTag(BUTTON_CLICK.MAKE_SURE)
    
        local editBox = ccui.EditBox:create(cc.size(340, 44), _res('ui/common/common_bg_input_default.png'))
        -- display.commonUIParams(editBox, {po = cc.p(4 , editBoxBgSize.height/2),ap = cc.p(0,0.5)})
        editBox:setFontSize(22)
        -- editBox:setTag(BUTTON_CLICK.INPUT_EXCHANGE)
        editBox:setFontColor(ccc3FromInt('#4c4c4c'))
        editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        -- editBox:setPlaceHolder(__('输入关键字'))
        editBox:setPlaceholderFontSize(22)
        editBox:setPlaceholderFontColor(ccc3FromInt('#4c4c4c'))
        editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        editBox:setMaxLength(10)
        editBox:setPosition(cc.p(contentSize.width/2 , 158))
        contentLayout:addChild(editBox)
    
		local inviteCodeLabel = display.newLabel(contentSize.width/2 , 160, {text = '', fontSize = 28, color = '#d23d3d'})
		contentLayout:addChild(inviteCodeLabel)

        local label = display.newLabel(contentSize.width/2 , 186 , { color = "#5b3c25", fontSize = 22, ap = display.CENTER_BOTTOM, text = __('请输入邀请你回归的御侍大人召回码')}  )
        contentLayout:addChild(label)

        local nameTitleLabel = display.newLabel(60 , 116 , fontWithColor(6, {text = __('角色名：'), fontSize = 20, ap = cc.p(0, 0.5)})  )
        contentLayout:addChild(nameTitleLabel)

        local nameLabel = display.newLabel(nameTitleLabel:getPositionX() + display.getLabelContentSize(nameTitleLabel).width , 
        116 , fontWithColor(6, {text = '', fontSize = 20, ap = cc.p(0, 0.5), maxW = 142})  )
        contentLayout:addChild(nameLabel)
        
        local areaTitleLabel = display.newLabel(280 , 116 , fontWithColor(6, {text = __('区服：'), fontSize = 20, ap = cc.p(0, 0.5)})  )
        contentLayout:addChild(areaTitleLabel)

        local areaLabel = display.newLabel(areaTitleLabel:getPositionX() + display.getLabelContentSize(areaTitleLabel).width , 
            116 , fontWithColor(6, {text = '', fontSize = 20, ap = cc.p(0, 0.5)})  )
        contentLayout:addChild(areaLabel)
        
		return {
            view        	= view,
            nameTitleLabel  = nameTitleLabel,
            nameLabel       = nameLabel,
            areaTitleLabel  = areaTitleLabel,
            areaLabel       = areaLabel,
            editBox         = editBox,
            makeSureBtn     = makeSureBtn,
            inviteCodeLabel = inviteCodeLabel,
		}
	end
	xTry(function()
        self.viewData_ = CreateView()

	end, __G__TRACKBACK__)
end

return RecallInvitedCodeInputLayer