--[[
	回归玩家输入召回码UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecallInvitedCodeView = class('RecallInvitedCodeView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallInvitedCodeView:ctor( ... )
    --创建页面
    local function CreateView( ... )
		local size = cc.size(1131,639)
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0, 0)})
        self:addChild(view)

        -- 背景图片
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

        local label = display.newLabel(contentSize.width/2 , 186 , { color = "#5b3c25", fontSize = 22, ap = display.CENTER_BOTTOM , w=400 , hAlign = display.TAL,   text = __('请输入邀请你回归的御侍大人召回码')}  )
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

return RecallInvitedCodeView