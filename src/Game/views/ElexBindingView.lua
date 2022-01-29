--[[
市场系统UI
--]]
local GameScene = require( "Frame.GameScene" )

local ElexBindingView = class('ElexBindingView', GameScene)

local RES_DICT = {
	Btn_Normal 			= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 		= "ui/common/common_btn_sidebar_selected.png",


}

function ElexBindingView:ctor( ... )
	self.viewData_ = nil

	local view = require("common.TitlePanelBg").new({ title = __('账号'), type = 8, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("ElexBindingMediator")
    end, isCenter = true})
    view.viewData.titleLabel:setVisible(false)
    view.viewData.closeBtn:setVisible(false)
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)

	local function CreateView()
		local layout = CLayout:create(cc.size(550, 288))
        -- layout:setBackgroundColor(cc.c4b(200,100,100,100))
		local frameSize = layout:getContentSize()

		-- 添加多个按钮功能
		local tabsData = {
			{name = __('绑定'), tag = 1001, },
			{name = __('切換'), tag = 1002, },
		}
		local buttons = {}
		local tabNameLabels = {}
		for i,v in ipairs(tabsData) do
			local tabButton = display.newCheckBox(0, 0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed)})

			local buttonSize = tabButton:getContentSize()

			display.commonUIParams(
				tabButton,
				{
					ap = cc.p(1, 0.5),
					po = cc.p(frameSize.width,
						frameSize.height - 60 - (i - 1) * (buttonSize.height - 20))
				})
			layout:addChild(tabButton, layout:getLocalZOrder() - 1)
			tabButton:setTag(v.tag)
			buttons[tostring( v.tag )] = tabButton

			local tabNameLabel = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y,
				{ttf = true, font = fontWithColor('2').font, text = v.name, fontSize = fontWithColor('2').fontSize , color = fontWithColor('2').color, ap = cc.p(0.5, 0)})
			tabButton:addChild(tabNameLabel)
			tabNameLabels[tostring( v.tag )] = tabNameLabel
		end
		-- 展示页面
		-- local modelLayout = CLayout:create(cc.size(1082, 641))
		-- modelLayout:setAnchorPoint(cc.p(0, 0))
		-- modelLayout:setPosition(cc.p(0, 0))
		-- layout:addChild(modelLayout)
        local googleName = _resEx('update/button_google' ,nil, device.platform)
        if device.platform == 'ios' then
            googleName = _res('update/button_gamecenter')
        end
        local googleButton = display.newButton(220, 230, {
                n = googleName,
                s = googleName,

            })
		googleButton:setScale(0.8)
        googleButton:setColor(cc.c3b(200,0,0))
        googleButton:setOnClickScriptHandler(handler(self, self.ElexSDKLoginButtonAction))
        googleButton:setName("GOOGLE")
        layout:addChild(googleButton)
        local facebookButton = display.newButton(220, 230 - 80 , {
                n = _resEx('update/button_facebook' ,nil, device.platform),
                s = _resEx('update/button_facebook',nil,device.platform),
		})
		facebookButton:setScale(0.8)
        facebookButton:setOnClickScriptHandler(handler(self, self.ElexSDKLoginButtonAction))
        facebookButton:setName("FACEBOOK")
        layout:addChild(facebookButton)
		local appleButton = nil
		if device.platform == "ios" then
			googleButton:setScale(0.25)
			facebookButton:setScale(0.25)
			appleButton = display.newButton(220, 230 - 160 , {
				n = _res('update/btton_apple'),
				s = _res('update/btton_apple')
			})
			appleButton:setScale(0.25)
			appleButton:setOnClickScriptHandler(handler(self, self.ElexSDKLoginButtonAction))
			appleButton:setName("APPLE")
			layout:addChild(appleButton)
			local appleSystemVersion = utils.getSystemVersionInt()
			if isElexSdk() and FTUtils:getTargetAPIVersion() >= 15 and appleSystemVersion >= 13 then
				appleButton:setVisible(true)
			else
				appleButton:setVisible(false)
			end
		end
		view:AddContentView(layout)
		local iconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
		local rewardDiamond
		if isElexSdk() and (not isNewUSSdk()) then
			if checkint(app.gameMgr:GetUserInfo().isBindAccountDrawn ) == 0  then
				rewardDiamond = display.newRichLabel(230   , 30 , { r = true , c =  {
					fontWithColor(16, { fontSize = 20 , text = string.format(__('首次绑定奖励%d') , 100)}) ,
					{img =  iconPath  , scale =  0.2  }
				}})
				layout:addChild(rewardDiamond)
			end
		end
		return {
			view 			= layout,
			buttons     	= buttons,
			tabNameLabels   = tabNameLabels,
            googleButton    = googleButton,
			rewardDiamond   = rewardDiamond,
            facebookButton  = facebookButton,
			appleButton     = appleButton,
			-- modelLayout     = modelLayout
		}
	end
	self.viewData_ = CreateView()
end

return ElexBindingView
