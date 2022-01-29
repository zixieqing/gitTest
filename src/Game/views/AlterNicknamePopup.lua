--[[
修改昵称界面 
--]]
local GameScene = require( "Frame.GameScene" )
local AlterNicknamePopup = class('AlterNicknamePopup', GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function AlterNicknamePopup:ctor( ... )
	self.args = unpack({...})
	self.playerName = ""
	self.viewData = nil
    self.callback   = self.args.callback or nil
	self.cancelBack = self.args.cancelBack or nil
	self.autoClose = self.args.autoClose == nil and true or self.args.autoClose
	
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	if self.autoClose then
		eaterLayer:setOnClickScriptHandler(function(sender)
			self:runAction(cc.RemoveSelf:create())
		end)
	end
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)
	self.eaterLayer = eaterLayer
	
	local function CreateView()
		local view = CLayout:create(display.size)
		display.commonUIParams(view, {po = display.center})
		self:addChild(view)
		
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_8.png'), 0, 0, {ap = cc.p(0,0)})
		bg:setTouchEnabled(true)
		view:addChild(bg)

		local size = bg:getContentSize()
		view:setContentSize(size)

		local changeNameLabel = display.newLabel(size.width/2 ,  size.height - 45 , fontWithColor('14' , { hAlign = display.TAC , w = 330 , ap = display.CENTER_TOP,  text = __('是否要修改昵称')})  )
		view:addChild(changeNameLabel)
	
    	-- 编辑的按钮
    	local editBoxBg = display.newImageView(_res('ui/home/market/market_main_bg_research.png'))
    	local editBoxBgSize = editBoxBg:getContentSize()

    	local editBoxLayout = display.newLayer(size.width/2  , size.height - 150  , { ap = display.CENTER_BOTTOM , size = editBoxBgSize})
    	editBoxBg:setPosition(cc.p(editBoxBgSize.width/2 , editBoxBgSize.height/2))
    	editBoxLayout:addChild(editBoxBg)
		-- 编辑文本框
		local editBox = ccui.EditBox:create(cc.size(295, 35), 'empty')
		display.commonUIParams(editBox, {po = cc.p(4 , editBoxBgSize.height/2),ap = cc.p(0,0.5)})
		editBox:setFontSize(22)
		editBox:setFontColor(ccc3FromInt('#5b3c25'))
		editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		editBox:setPlaceHolder(__('输入昵称'))
		editBox:setPlaceholderFontSize(22)
		editBox:setPlaceholderFontColor(ccc3FromInt('#8c8c8c'))
		editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		--editBox:setMaxLength()
		editBoxLayout:addChild(editBox)
		view:addChild(editBoxLayout)

		local offWidth = 105
    	-- 修改名字的btn 按钮
    	local changeNameBtn = display.newButton(size.width/2 + offWidth  ,53,{
    	    n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER_BOTTOM
    	})
    	display.commonLabelParams(changeNameBtn,fontWithColor(14,{text = __('修改')}))
    	view:addChild(changeNameBtn)
    	display.commonUIParams(changeNameBtn , { cb = handler(self, self.AlterCardNickname) ,animate = true})
    	-- 取消按钮
    	local cancelBtn = display.newButton(size.width/2 -  offWidth  ,53,{
    	    n = _res('ui/common/common_btn_white_default.png') ,ap = display.CENTER_BOTTOM
    	})
    	view:addChild(cancelBtn)
    	display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __('取消')}))
    	display.commonUIParams(cancelBtn , { cb = function(sender)
            PlayAudioByClickClose()
            if self.cancelBack then
                self.cancelBack()
            end
            self:removeFromParent()
        end,animate = true  })
		
		return {
			view        		= view,
			editBox				= editBox,
			changeNameBtn		= changeNameBtn,
			cancelBtn			= cancelBtn,
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )

	end, __G__TRACKBACK__)
end

function AlterNicknamePopup:AlterCardNickname(sender)
	PlayAudioByClickNormal()
    self.playerName = self.viewData.editBox:getText()
    if self.playerName == "" or self.playerName == nil  then
        uiMgr:ShowInformationTips(__('修改名不能为空'))
        return
	end

	local dialogueLabel = nil
	dialogueLabel = display.newLabel(0, 0, {fontSize = 38, color = '#ffffff', text = self.playerName,ap = cc.p(0, 0)})
	if 240 < display.getLabelContentSize(dialogueLabel).width then
		uiMgr:ShowInformationTips(__('昵称过长'))
        return
	end

	if self.callback then
		self.callback(self.playerName)
	end
end

return AlterNicknamePopup
