--[[
账户系统UI
--]]
local GameScene = require( 'Frame.GameScene' )
local AuthorTransView = class('AuthorTransView', GameScene)

local RES_DICT = {
    BG_IMG = HOME_THEME_STYLE_DEFINE.LOGIN_BG or "update/update_bg.png",
	START  = IS_CHINA_GRAY_MODE and 'update/gray/login_btn_start.png' or 'update/login_btn_start.png',
	SERVER = IS_CHINA_GRAY_MODE and 'update/gray/login_btn_server.png' or 'update/login_btn_server.png',
}

function AuthorTransView:ctor( ... )
	local args = unpack({...})
	self.super.ctor(self,'views.AuthorTransView')
	self.viewData = nil

    local scale = display.height / 1002
	local function CreateLoginView()
        local actionButtons = {}

        if args.trans then
			local __bg = display.newImageView(_res(RES_DICT.BG_IMG))
			if IS_CHINA_GRAY_MODE then
				__bg = FilteredSpriteWithOne:create()
				__bg:setTexture(_res(RES_DICT.BG_IMG))
				__bg:setFilter(GrayFilter:create())
			end
            display.commonUIParams(__bg,{ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
            self:addChild(__bg)
            --添加logo的文件
            --添加logo的文件
			local logoAnimate = sp.SkeletonAnimation:create('update/logo.json', 'update/logo.atlas', 0.92)
			if IS_CHINA_GRAY_MODE then
				logoAnimate = sp.SkeletonAnimation:create('update/gray/logo.json', 'update/gray/logo.atlas', 0.92)
			end
            logoAnimate:setPosition(cc.p(__bg:getContentSize().width * 0.5, __bg:getContentSize().height - 470))
            logoAnimate:setToSetupPose()
            logoAnimate:update(0)
            logoAnimate:setAnimation(0, 'logo', false)
            __bg:addChild(logoAnimate)
            logoAnimate:registerSpineEventHandler(function (event)
                if event.animation == "logo" then
                    logoAnimate:setAnimation(0, 'xunhuan', true)
                end
            end,sp.EventType.ANIMATION_COMPLETE)

		local roleAnimate = sp.SkeletonAnimation:create('update/mifan.json', 'update/mifan.atlas', 0.92)
		if IS_CHINA_GRAY_MODE then
            roleAnimate = sp.SkeletonAnimation:create('update/gray/mifan.json', 'update/gray/mifan.atlas', 0.92)
        end
        -- roleAnimate:setPosition(cc.p(display.cx, __bg:getContentSize().height - 502))
        roleAnimate:setPosition(cc.p(__bg:getContentSize().width * 0.5, __bg:getContentSize().height - 502))
        roleAnimate:setToSetupPose()
        roleAnimate:update(0)
        roleAnimate:setAnimation(0, 'idle', true)
        __bg:addChild(roleAnimate)


    end
		-- local bg = display.newImageView(_res(RES_DICT.BG_IMG), display.cx, display.height)
  --       display.commonUIParams(bg, {ap = display.CENTER_TOP})
		-- self:addChild(bg)

  --       local logoImage = display.newImageView(_res(RES_DICT.LOGO), display.cx - 20, display.height - 138 * scale)
  --       display.commonUIParams(logoImage, {ap = display.CENTER_TOP})
		-- self:addChild(logoImage,2)

		local entryBtnPos = cc.p(display.cx, display.height - 780 * scale)
		local entryButton = display.newButton(0, 0, {n = _res(RES_DICT.START)})
		display.commonUIParams(entryButton, {ap = display.CENTER_TOP, po = entryBtnPos})
		display.commonLabelParams(entryButton, fontWithColor(2,{text = __('进入游戏'), fontSize = fontWithColor('M2PX').fontSize, color = '#000000', offset = cc.p(0, - 0)}))
		self:addChild(entryButton)
		entryButton:setVisible(false)
		entryButton:setTag(1001)
		actionButtons[tostring(1001)] = entryButton

		local newEntryButton = display.newButton(0, 0, {n = _res(RES_DICT.START)})
        display.commonUIParams(newEntryButton, {ap = display.CENTER_TOP, po = cc.p(entryBtnPos.x, entryBtnPos.y + 100)})
		display.commonLabelParams(newEntryButton, fontWithColor(2,{text = __('创建角色'), fontSize = fontWithColor('M2PX').fontSize, color = '#000000', offset = cc.p(0, - 40)}))
		self:addChild(newEntryButton)
        newEntryButton:setVisible(false)
		newEntryButton:setTag(1007)
		actionButtons[tostring(1007)] = newEntryButton

		local accountButton = display.newButton(display.SAFE_L + 0, 0, {n = _res('ui/author/login_btn_Accounts.png')})
		display.commonUIParams(accountButton, {po = cc.p(display.SAFE_L + 10 + accountButton:getContentSize().width * 0.5, display.height - 30 - accountButton:getContentSize().height * 0.5)})
		self:addChild(accountButton)
		accountButton:setTag(1002)
		actionButtons[tostring(1002)] = accountButton

		local serverButton = display.newButton(entryBtnPos.x, entryBtnPos.y + 35, {n = _res(RES_DICT.SERVER), scale9 = true})
		display.commonLabelParams(serverButton, fontWithColor(11, {color = IS_CHINA_GRAY_MODE and '#555555' or '#8f7640'}))
		self:addChild(serverButton)
		serverButton:setVisible(false)
		serverButton:setTag(1008)
		actionButtons[tostring(1008)] = serverButton

		local unameLabel = display.newLabel(utils.getLocalCenter(accountButton).x, utils.getLocalCenter(accountButton).y,
			fontWithColor(4,{text = __('账户管理'), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('TC1').color}))
		accountButton:addChild(unameLabel)

		return {
			unameLabel = unameLabel,
			actionButtons = actionButtons,
		}
	end

	xTry(function ( )
		self.viewData = CreateLoginView( )
	end, __G__TRACKBACK__)
end

function AuthorTransView:setServerName(serverName)
	local serverButton = self.viewData.actionButtons[tostring(1008)]
	if serverButton then
		display.commonLabelParams(serverButton, {text = tostring(serverName), paddingW = 40, safeW = 160, offset = cc.p(-20,0)})
	end
end

return AuthorTransView

