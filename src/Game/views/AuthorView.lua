--[[
账户系统UI
--]]
local GameScene = require( 'Frame.GameScene' )
local AuthorView = class('AuthorView', GameScene)

local RES_DICT = {
    BG_IMG = HOME_THEME_STYLE_DEFINE.LOGIN_BG or "update/update_bg.png",
	START  = IS_CHINA_GRAY_MODE and 'update/gray/login_btn_start.png' or 'update/login_btn_start.png',
	SERVER = IS_CHINA_GRAY_MODE and 'update/gray/login_btn_server.png' or 'update/login_btn_server.png',
}
local BUTTON_TAG = {
    FAQ_TAG = 10001 , -- FAQ 的tag 值
}
local CreateView = function()
    local cview = CLayout:create(display.size)
    cview:setName('CVIEW')
    cview:setPosition(cc.p(display.cx, display.cy))
    local touchL = CColorView:create(cc.c4b(0, 0, 0, 130))
    touchL:setTouchEnabled(true)
    touchL:setContentSize(display.size)
    touchL:setPosition(cc.p(display.cx, display.cy))
    touchL:setOnClickScriptHandler(function(sender)
        cview:setVisible(false)
    end)
    cview:addChild(touchL)


	local view = display.newLayer(display.cx, display.cy, {ap = display.CENTER, bg = _res("ui/common/common_bg_7")})
    view:setName("CONTENT")
    cview:addChild(view)
    local size = view:getContentSize()

    -- title label
    local title = display.newButton(size.width/2, size.height - 3, {n = _res("ui/common/common_bg_title_2.png"), enable = false})
    display.commonUIParams(title, {ap = display.CENTER_TOP})
    title:setName("TITLE")
    view:addChild(title)

    -- lang list
    local listSize = cc.size(size.width - 35, size.height - 100)
    local langList = CListView:create(listSize)
    langList:setName("LIST")
    langList:setDirection(eScrollViewDirectionVertical)
    langList:setAnchorPoint(display.LEFT_BOTTOM)
    langList:setPosition(cc.p(10, 25))
    view:addChild(langList)

    return {
        cview    = cview,
		view     = view,
        title    = title,
		langList = langList
	}
end


local CreateLangCell = function(size)
	local view = display.newLayer(0, 0, {size = size})

	local langBtn = display.newButton(size.width/2, size.height/2, {n = _res("update/enter_language_bg_switch_default"), s = _res("update/enter_language_bg_switch_selected"), d = _res("update/enter_language_bg_switch_selected")})
	view:addChild(langBtn)

	local nameLabel = CLabel:create()
	nameLabel:setSystemFontSize(30)
	nameLabel:setSystemFontName(Helvetica)
	nameLabel:setColor(ccc3FromInt('7c7c7c'))
	nameLabel:setPosition(size.width/2, size.height/2)
	view:addChild(nameLabel)

	return {
		view      = view,
		langBtn   = langBtn,
		nameLabel = nameLabel
	}
end

function AuthorView:ctor( ... )
	local args = unpack({...})
	self.super.ctor(self,'views.AuthorView')
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
        print("fontWithColor = " , fontWithColor(2).font)
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
        
        if isKoreanSdk() then
            -- 用户中心
            local userCenterButton = display.newButton(display.SAFE_L + 0, 0, {n = _res('ui/author/login_btn_Accounts.png')})
            -- display.commonUIParams(userCenterButton, {po = cc.p(display.SAFE_L + 10 + userCenterButton:getContentSize().width * 0.5, accountButton:getPositionY() - accountButton:getContentSize().height * 0.5 - 10 - userCenterButton:getContentSize().height * 0.5)})
            display.commonUIParams(userCenterButton, {po = cc.p(accountButton:getPositionX(), accountButton:getPositionY())})
            self:addChild(userCenterButton)
            userCenterButton:setTag(1009)
            userCenterButton:setVisible(false)
            actionButtons[tostring(1009)] = userCenterButton
            
            userCenterButton:addChild(display.newLabel(utils.getLocalCenter(userCenterButton).x, utils.getLocalCenter(userCenterButton).y,
            fontWithColor(4,{text = '用户中心', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('TC1').color})))
            
        end

        local langBtn = nil
        if i18n.supportLangs then
            langBtn = display.newButton(display.width - 20, 54, {scale9 = true, size = cc.size(212,54),
                    n = _res('update/enter_bg_name.png'), s = _res('update/enter_bg_name.png'),
                    cb = handler(self, self.ButtonAction),
                animate = true, ap = display.RIGHT_CENTER})
            display.commonLabelParams(langBtn,{fontSize = 24,color = 'ffffff',text = __('设置语言'), offset = cc.p(0, 2)})
            langBtn:setTag(1100)
            langBtn:setVisible(i18n.supportLangs and #i18n.supportLangs > 0)
            self:addChild(langBtn)
            -- 是智明并且不是澳大利亚
            if (isElexSdk()) and (not isNewUSSdk()) then
                local faqBtn = display.newButton( 100 , display.height -100 , { n = _res('update/login_btn_faq.png')})
                faqBtn:setVisible(false)
                display.commonLabelParams(faqBtn ,  fontWithColor(14, { text =  __('FAQ') }))
                faqBtn:getLabel():setPosition(140/2 , 15 )
                self:addChild(faqBtn)
                faqBtn:setTag(BUTTON_TAG.FAQ_TAG)
            end
        end

		-- 数据隐私协议
		-- local policyLayoutSize = cc.size(540, 80)
		-- local policyLayout = CLayout:create(policyLayoutSize) 
		-- display.commonUIParams(policyLayout, {po = cc.p(display.cx, entryBtnPos.y - 60), ap = display.CENTER_TOP})
		-- policyLayout:setVisible(false)
		-- self:addChild(policyLayout)
		-- local policyCheckBox = display.newCheckBox(5, policyLayoutSize.height - 40, {
		-- 	n = _res('ui/common/common_btn_check_default.png'),
        --     s = _res('ui/common/common_btn_check_selected.png')
		-- })
		-- policyCheckBox:setScale(0.8)
		-- policyCheckBox:setAnchorPoint(cc.p(0, 0))
		-- policyLayout:addChild(policyCheckBox)
		-- local policyBtn = display.newButton(60, policyLayoutSize.height - 34, {n = _res('update/login_bg_clause.png'), ap = display.LEFT_BOTTOM})
		-- display.commonLabelParams(policyBtn, {text = __('我已阅读并同意隐私政策条款'), fontSize = 20, color = '#ffffff', ap = display.LEFT_CENTER, offset = cc.p(- 225, 0)})
		-- policyLayout:addChild(policyBtn)
		-- policyBtn:setTag(1100)
		-- actionButtons[tostring(1100)] = policyBtn

		-- local ageCheckBox = display.newCheckBox(5, policyLayoutSize.height - 80, {
		-- 	n = _res('ui/common/common_btn_check_default.png'),
        --     s = _res('ui/common/common_btn_check_selected.png')
		-- })	
		-- ageCheckBox:setScale(0.8)
		-- ageCheckBox:setAnchorPoint(cc.p(0, 0))
		-- policyLayout:addChild(ageCheckBox)
		-- local ageBtn = display.newButton(60, policyLayoutSize.height - 74, {n = _res('update/login_bg_clause.png'), ap = display.LEFT_BOTTOM, enable = false})
		-- display.commonLabelParams(ageBtn, {text = __('年满16岁'), fontSize = 20, color = '#ffffff', ap = display.LEFT_CENTER, offset = cc.p(- 225, 0)})
		-- policyLayout:addChild(ageBtn)

		if isQuickSdk() then
			local accountButtonPos = cc.p(accountButton:getPosition())
			local height = 70
			local privacyBtn = display.newButton(accountButtonPos.x , accountButtonPos.y - height , {n = _res('ui/author/login_btn_Accounts.png')} )
			local privacyBtnContentSize = privacyBtn:getContentSize()
			local privacyLabel = display.newLabel(privacyBtnContentSize.width/2,privacyBtnContentSize.height/2,
												fontWithColor(4,{text = __('隐私政策'), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('TC1').color}))
			privacyBtn:addChild(privacyLabel)
			self:addChild(privacyBtn)
			
			display.commonUIParams(privacyBtn , {cb = function()
				local privacyFullPolicyView = require("Game.views.PrivacyFullPolicyView").new({
				  pngCount = 30 ,
				  pngStr = "ui/author/privacy/privacy_" ,
				  textTitle = __('隐私协议')
			    })
				privacyFullPolicyView:setPosition(display.center)
				app.uiMgr:GetCurrentScene():AddDialog(privacyFullPolicyView)
			end})


			local userAgreementBtn      = display.newButton(accountButtonPos.x , accountButtonPos.y - height*2 , { n = _res('ui/author/login_btn_Accounts.png')} )
			local userAgreementBtnContentSize = userAgreementBtn:getContentSize()
			local userAgreementLabel          = display.newLabel(userAgreementBtnContentSize.width/2,userAgreementBtnContentSize.height/2,
												  fontWithColor(4,{text = __('用户协议'), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('TC1').color}))
			userAgreementBtn:addChild(userAgreementLabel)
			display.commonUIParams(userAgreementBtn , {cb = function()
				local privacyFullPolicyView = require("Game.views.PrivacyFullPolicyView").new({
					  pngCount = 30 ,
					  pngStr = "ui/author/user_agreement/user_agreement_" ,
					  cellSize = cc.size(1204,500*0.85),
					  offsetW = -90 ,
					  scale = 0.85,
					  textTitle = __('用户协议') })
				privacyFullPolicyView:setPosition(display.center)
				app.uiMgr:GetCurrentScene():AddDialog(privacyFullPolicyView)
			end})
			self:addChild(userAgreementBtn)
		end
		

		if GAME_MODULE_OPEN.CLEAN_CACHE and not IS_CHINA_GRAY_MODE then
			local fixVersionButton = display.newButton(display.width - display.SAFE_L - 20, display.height - 30, {n = _res("update/login_btn_clear.png"), ap = display.RIGHT_TOP})
			display.commonLabelParams(fixVersionButton, fontWithColor(11, {fontSize = 18, color = '#ffffff', text = __("清除缓存"), offset = cc.p(0,-54)}))
			self:addChild(fixVersionButton,11)
			-- fixVersionButton:setVisible(false)
			fixVersionButton:setTag(20002)
			actionButtons[tostring(20002)] = fixVersionButton
		end
		
		return {
			unameLabel     = unameLabel,
            actionButtons  = actionButtons,
            langBtn        = langBtn,
		}
	end

	xTry(function ( )
		self.viewData = CreateLoginView( )

        local updateLangChange = function(event)
            --TTF_GAME_FONT = _res('res/font/FZCQJW.TTF')
            --TTF_TEXT_FONT = _res('res/font/DroidSansFallback.ttf')

            local langBtn = self.viewData.langBtn
            if langBtn then
                langBtn:getLabel():setString(__('设置语言'))
            end
            local accountLabel = self.viewData.unameLabel
            if accountLabel then
                accountLabel:setString(__("账号管理"))
            end
            local entryButton = self.viewData.actionButtons[tostring(1001)]
            if entryButton then
                display.commonLabelParams(entryButton, fontWithColor(2,{text = __('进入游戏'), fontSize = fontWithColor('M2PX').fontSize, color = '#000000', offset = cc.p(0, - 0)}))
            end

			if (isElexSdk()) and (not isNewUSSdk()) then
                local faqBtn = self:getChildByTag(BUTTON_TAG.FAQ_TAG)
				if faqBtn then
					display.commonLabelParams(faqBtn ,  fontWithColor(14, { text =  __('FAQ') }))
				end
            end
			if GAME_MODULE_OPEN.CLEAN_CACHE and not IS_CHINA_GRAY_MODE then
				local fixVersionButton = self.viewData.actionButtons[tostring(20002)]
				display.commonLabelParams(fixVersionButton, fontWithColor(11, {fontSize = 18, color = '#ffffff', text = __("清除缓存")}))
			end

			local serverButton = self.viewData.actionButtons[tostring(1008)]
			if serverButton then
				local text = string.fmt(__('_name_'), {_name_ = tostring(serverButton:getText())})
				display.commonLabelParams(serverButton, {text = text, paddingW = 40, safeW = 160})
			end
        end
        local listener = cc.EventListenerCustom:create('CHANG_LANG', updateLangChange)
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    end, __G__TRACKBACK__)
end


function AuthorView:CreateAppointLayer()
	local viewData       = self.viewData
	local actionButtons  = viewData.actionButtons
	-- 预约按钮
	local appointLayerSize = cc.size(256, 100)
	local scale = display.height / 1002
	local entryBtnPos = cc.p(display.cx, display.height - 780 * scale)
	local appointLayer = display.newLayer(entryBtnPos.x - 370, entryBtnPos.y + 65, {ap = display.CENTER, color = cc.c4b(0,0,0,0), size = appointLayerSize, enable = true})
	self:addChild(appointLayer)
	-- appointLayer:setVisible(false)
	appointLayer:setTag(1011)
	actionButtons[tostring(1011)] = appointLayer 

	local spineJsonPath = 'ui/author/spine/new_area_ico_bulangni.json'
	local spineAtlasPath = 'ui/author/spine/new_area_ico_bulangni.atlas'
	if utils.isExistent(spineJsonPath) and utils.isExistent(spineAtlasPath) then
		local appointSpine = sp.SkeletonAnimation:create(spineJsonPath, spineAtlasPath, 1)
		appointSpine:update(0)
		display.commonUIParams(appointSpine, {po = cc.p(appointLayerSize.width / 2, appointLayerSize.height / 2)})
		appointLayer:addChild(appointSpine)
		appointSpine:setName('appointSpine')
	end
	
	local appointLabel = display.newLabel(175, 70, {
		ap = display.CENTER, fontSize = 28, color = '#fc7e03', w = 120, hAlign = display.TAC, font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
	appointLayer:addChild(appointLabel)
	appointLabel:setName('appointLabel')
	
	local clickAppointLabel = display.newLabel(175, 30, { 
		ap = display.CENTER, fontSize = 24, color = '#5b3c25', w = 120, hAlign = display.TAC})
	appointLayer:addChild(clickAppointLabel)
	clickAppointLabel:setName('clickAppointLabel')
	appointLayer:setVisible(false)

	local shareNodeLayer = display.newImageView(_res('share/share_appoint_img.jpg'), display.cx, display.cy, {ap = display.CENTER})
	shareNodeLayer:setVisible(false)
	self:addChild(shareNodeLayer)

	self.viewData.shareNodeLayer = shareNodeLayer
end

--[[
	更新预约按钮状态
	state 0 未预约 1 已预约 2 新服已开启
--]]
function AuthorView:UpdateAppointmentBtnState(state)
	local actionButtons     = self.viewData.actionButtons
	local appointLayer      = actionButtons[tostring(1011)]
	local appointLayerSize  = appointLayer:getContentSize()
	appointLayer:setTouchEnabled(state ~= 2)
	appointLayer:setVisible(true)
	
	local appointSpine      = appointLayer:getChildByName('appointSpine')
	appointSpine:setAnimation(0, 'idle', true)
	
	local appointLabel      = appointLayer:getChildByName('appointLabel')
	
	local clickAppointLabel = appointLayer:getChildByName('clickAppointLabel')
	clickAppointLabel:setVisible(state == 0) 

	if state == 0 then
		display.commonLabelParams(appointLabel, {text = __('新服预约')})
		display.commonUIParams(appointLabel, {ap = display.CENTER_BOTTOM, po = cc.p(175, appointLayerSize.height / 2)})
		display.commonLabelParams(clickAppointLabel, {text = __('点击预约')})
		display.commonUIParams(clickAppointLabel, {ap = display.CENTER_TOP, po = cc.p(175, appointLayerSize.height / 2)})
	elseif state == 1 then
		display.commonLabelParams(appointLabel, {text = __('新服预约成功')})
		display.commonUIParams(appointLabel, {ap = display.CENTER, po = cc.p(175, appointLayerSize.height / 2)})
	elseif state == 2 then
		display.commonLabelParams(appointLabel, {text = __('新服开启')})
		display.commonUIParams(appointLabel, {ap = display.CENTER, po = cc.p(175, appointLayerSize.height / 2)})
	end
end

function AuthorView:setServerName(serverName)
	local serverButton = self.viewData.actionButtons[tostring(1008)]
	if serverButton then
		display.commonLabelParams(serverButton, {text = tostring(serverName), paddingW = 40, safeW = 160, offset = cc.p(-20,0)})
	end
end

--[[
---显示语言选择的逻辑界面
--]]
function AuthorView:ButtonAction(sender)
    local view = self:getChildByName('CVIEW')
    local languageList = nil
    if not view then
        local langViewData = CreateView()
        display.commonUIParams(langViewData.cview, {ap = display.CENTER, po = display.center})
        self:addChild(langViewData.cview, 100)
        languageList = langViewData.langList
        view = langViewData.cview
    else
        view:setVisible(true)
        languageList = view:getChildByName("CONTENT"):getChildByName("LIST")
    end
    if languageList then
        local title = view:getChildByName("CONTENT"):getChildByName("TITLE")
        display.commonLabelParams(title, fontWithColor(1,{fontSize = 24, text = __("语言设置"), color = 'ffffff',offset = cc.p(0, 0),paddingW = 50, safeW = 80}))
        local supportLangs = i18n.supportLangs or {}
        languageList:removeAllNodes()

        local ROW_H = 60
        local ROW_W = languageList:getContentSize().width
        for i,v in ipairs(supportLangs) do
            local langCode     = tostring(v)
            local langDefine   = i18n.langMap[langCode] or {}
            local cellViewData = CreateLangCell(cc.size(ROW_W, ROW_H))
            languageList:insertNodeAtLast(cellViewData.view)

            -- update name
            cellViewData.nameLabel:setString(tostring(langDefine.lang))

            -- update langBtn status
			if i18n.getLang() == langCode then
				cellViewData.langBtn:setEnabled(false)
			else
				cellViewData.langBtn:setEnabled(true)
			end
            cellViewData.langBtn:setTag(i)

            display.commonUIParams(cellViewData.langBtn, {cb = handler(self, self.onClickLangButtonHandler_)})
        end
        languageList:reloadData()
    end
end

function AuthorView:onClickLangButtonHandler_(sender)
    local supportLangs = i18n.supportLangs or {}
    local listIndex    = checkint(sender:getTag())
    local langCode     = supportLangs[listIndex]
    local langDefine   = i18n.langMap[langCode] or {}
    local langBtn      = sender
    local isSameSelect = i18n.getLang() == langCode
    -- langBtn:setChecked(isSameSelect)
	langBtn:setEnabled(false)

    if isSameSelect then
        local view = self:getChildByName('CVIEW')
        view:setVisible(false)
    else
        local TEMP_DOMAIN = 'temp'
        i18n.addMO(string.format('res/lang/%s.mo', langCode), TEMP_DOMAIN)
        local tips  = __('是否要切换游戏的语言设置', TEMP_DOMAIN)
        local name1 = __('确定', TEMP_DOMAIN)
        local name2 = __('取消', TEMP_DOMAIN)
		local delayTime = langCode == 'es-es' and 0.5 or 0  --根据语言判断延时的时间
        local CommonTip  = require( 'common.NewCommonTip' ).new({
				text = tips,
				delayTime = delayTime ,
			    btnTextRTTF = false ,
                btnTextL = name2,btnTextR = name1,
                isOnlyOK = false, callback = function ()
                    i18n.setLang(langCode)
					display.initFontTTF()
					FONT_TTF_REFRESH()
                    local view = self:getChildByName('CVIEW')
                    view:setVisible(false)
                    app.dataMgr:Destroy()
                    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
                    local event = cc.EventCustom:new("CHANG_LANG")
                    eventDispatcher:dispatchEvent(event)
            end})
        CommonTip:setPosition(display.center)
        self:addChild(CommonTip, 200)
    end
end

function AuthorView:onCleanup()
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:removeCustomEventListeners('CHANG_LANG')
end

return AuthorView

