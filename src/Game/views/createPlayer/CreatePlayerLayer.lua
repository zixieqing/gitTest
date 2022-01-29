--[[
登录弹窗
--]]
local CreatePlayerLayer = class('CreatePlayerLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.createPlayer.CreatePlayerLayer'
	node:enableNodeEvents()
	return node
end)

local shareFacade   = AppFacade.GetInstance()
local AuthorCommand = require('Game.command.AuthorCommand')
local gameMgr       = app.gameMgr
local uiMgr         = app.uiMgr

local BTN_TAG = {
	-- 创建角色
	TAG_CREATE_ROLE         = 1000,
	-- 随机名字
	TAG_RANDOM_NAME         = 1001,
	-- 生日
	TAG_BIRTHDAY            = 1002,

	-- 邀请码 tag
	TAG_INVITE_CODE_BACK    = 2000,
	TAG_INVITE_CODE_CONFIRM = 2001,
}

local RES_DICT = {
	MAIN_BG_06                    = _res('arts/stage/bg/main_bg_06.jpg'),
	CREATE_ROLES_ARROW            = _res('ui/author/createPlayer/create_roles_arrow.png'),
	CREATE_ROLES_BG_NAME          = _res('ui/author/createPlayer/create_roles_bg_name.png'),
	CREATE_ROLES_BG_TITLE         = _res('ui/author/createPlayer/create_roles_bg_title.png'),
	CREATE_ROLES_BTN              = _res('ui/author/createPlayer/create_roles_btn.png'),
	CREATE_ROLES_BTN_DICE         = _res('ui/author/createPlayer/create_roles_btn_dice.png'),
	CREATE_ROLES_FRAME            = _res('ui/author/createPlayer/create_roles_frame.png'),
	COMMON_BG_FRAME_GOODS_ELECTED = _res('ui/common/common_bg_frame_goods_elected.png'),
}


function CreatePlayerLayer:ctor( ... )
	self.args = unpack({...})
	self.names = {}
	self.curSelectHeadId = 0
	self.isControllable_ = false
	self.birthdayData = nil

	local function CreateView()
		local actionButtons = {}

		local view       = display.newLayer()
		local size       = view:getContentSize()
		local middlePosX = size.width * 0.5
		local middlePosY = size.height * 0.5
		local mainBg     = display.newImageView(RES_DICT.MAIN_BG_06, middlePosX, middlePosY, {isFull = true})
		view:addChild(mainBg)
		mainBg:setVisible(false)

		-----------------frameLayer start-----------------
		local frameLayerSize = cc.size(908, 598)
		local middleFrameLayerPosX = frameLayerSize.width * 0.5
		local frameLayer = display.newLayer(middlePosX, middlePosY,
		{
			ap = display.CENTER,
			size = frameLayerSize,
		})
		view:addChild(frameLayer)
		frameLayer:setOpacity(0)
		frameLayer:setVisible(false)

		frameLayer:addChild(display.newLayer(0,0,{size = frameLayerSize, color = cc.c4b(0,0,0,0), enable = true}))

		local frameImg = display.newNSprite(RES_DICT.CREATE_ROLES_FRAME, middleFrameLayerPosX, frameLayerSize.height * 0.5,
		{
			ap = display.CENTER,
		})
		frameLayer:addChild(frameImg)
		frameImg:setVisible(false)

		local titleLabel = display.newButton(middleFrameLayerPosX, 527,
		{
			ap = display.CENTER,
			n = RES_DICT.CREATE_ROLES_BG_TITLE,
			scale9 = true, size = cc.size(158, 28),
			enable = true,
		})
		display.commonLabelParams(titleLabel, fontWithColor(14, {text = __('契约书')}))
		frameLayer:addChild(titleLabel)

		local selectHeadLabel = display.newLabel(217, 422,
		{
			text = __('选择形象'),
			ap = display.CENTER,
			fontSize = 24,
			color = '#5b3c25',
		})
		frameLayer:addChild(selectHeadLabel)

		local avatarConf = {
			500058,
			500059
		}
		local headScale = 0.8
		local headNodes = {}
		for index, avatar in ipairs(avatarConf) do
			local headNode = require('common.FriendHeadNode').new({
				enable = true, scale = headScale, showLevel = false, avatar = avatar, callback = handler(self, self.OnClickHeadNodeAction)
			})
			display.commonUIParams(headNode, {po = cc.p(
				151 + (index - 1) * 134 , 330
			), ap = display.CENTER})
			frameLayer:addChild(headNode)
			headNode:setTag(avatar)
			-- headNode:setVisible(false)
			-- headNode:setCascadeOpacityEnabled(true)

			headNodes[tostring(avatar)] = headNode
		end

		local selectImg = display.newNSprite(RES_DICT.COMMON_BG_FRAME_GOODS_ELECTED, 151, 330,
		{
			ap = display.CENTER,
		})
		frameLayer:addChild(selectImg)
		selectImg:setVisible(false)
		
		local nameLabel = display.newLabel(464, 378,
		{
			text = __('昵称：'),
			ap = display.RIGHT_CENTER,
			fontSize = 24,
			color = '#5b3c25',
		})
		frameLayer:addChild(nameLabel)
		-- 名称
		local nameBoxSize = cc.size(296, 50)
		local nameBox = ccui.EditBox:create(nameBoxSize, RES_DICT.CREATE_ROLES_BG_NAME)
		nameBox:setFontSize(22)
		nameBox:setFontColor(ccc3FromInt('#5b3c25'))
		nameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		nameBox:setPlaceHolder(__('请输入昵称'))
		nameBox:setPlaceholderFontSize(22)
		nameBox:setPlaceholderFontColor(ccc3FromInt('#a86f54'))
		nameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		nameBox:setCascadeOpacityEnabled(true)
		display.commonUIParams(nameBox, {po = cc.p(622, 380), ap = display.CENTER})
		frameLayer:addChild(nameBox)

		local nameErrorTipsLabel = display.newLabel(622, 335,
		{
			text = __('用户名已存在！'),
			ap = display.CENTER,
			fontSize = 22,
			color = '#ff2929',
		})
		frameLayer:addChild(nameErrorTipsLabel)
		nameErrorTipsLabel:setVisible(false)

		local dictBtn
		if not isKoreanSdk() and not isJapanSdk() then
			dictBtn = display.newButton(818, 381,
			{
				ap = display.CENTER,
				n = RES_DICT.CREATE_ROLES_BTN_DICE,
				scale9 = true, size = cc.size(56, 57),
				enable = true,
			})
			display.commonUIParams(dictBtn, {cb = handler(self, self.OnClickDictBtnAction)})
			frameLayer:addChild(dictBtn)
			actionButtons[tostring(BTN_TAG.TAG_RANDOM_NAME)] = dictBtn
		end

		local birthdayLabel = display.newLabel(464, 273,
		{
			text = __('生日：'),
			ap = display.RIGHT_CENTER,
			fontSize = 24,
			color = '#5b3c25',
		})
		frameLayer:addChild(birthdayLabel)

		----------------birthdayBtn start-----------------
		local birthdayBtn = display.newButton(622, 274,
		{
			ap = display.CENTER,
			n = RES_DICT.CREATE_ROLES_BG_NAME,
			scale9 = true, size = cc.size(296, 50),
		})
		frameLayer:addChild(birthdayBtn)
		actionButtons[tostring(BTN_TAG.TAG_BIRTHDAY)] = birthdayBtn

		local birthdayTipLabel = display.newLabel(6, 25, {ap = display.LEFT_CENTER, fontSize = 22, color = '#a86f54', text = __('选择出生年月')})
		birthdayBtn:addChild(birthdayTipLabel)

		local arrowImg = display.newNSprite(RES_DICT.CREATE_ROLES_ARROW, 274, 24,
		{
			ap = display.CENTER,
		})
		birthdayBtn:addChild(arrowImg)

		-----------------birthdayBtn end------------------
		local birthdayErrorTipsLabel = display.newLabel(634, 228,
		{
			text = __('请选择正确日期！'),
			ap = display.CENTER,
			fontSize = 22,
			color = '#ff2929',
		})
		frameLayer:addChild(birthdayErrorTipsLabel)
		birthdayErrorTipsLabel:setVisible(false)

		local createBtn = display.newButton(743, 86,
		{
			ap = display.CENTER,
			n = RES_DICT.CREATE_ROLES_BTN,
			scale9 = true, size = cc.size(200, 68),
			enable = true,
		})
		display.commonLabelParams(createBtn, fontWithColor(14, {text = __('签署'), outline = '#5b3c25', outlineSize = 1}))
		frameLayer:addChild(createBtn)
		actionButtons[tostring(BTN_TAG.TAG_CREATE_ROLE)] = createBtn

		------------------frameLayer end------------------
		return {
			view                    = view,
			frameLayer              = frameLayer,
			frameImg                = frameImg,
			titleLabel              = titleLabel,
			selectHeadLabel         = selectHeadLabel,
			headNodes               = headNodes,
			selectImg               = selectImg,
			nameLabel               = nameLabel,
			nameBox                 = nameBox,
			nameErrorTipsLabel      = nameErrorTipsLabel,
			birthdayTipLabel        = birthdayTipLabel,
			birthdayLabel           = birthdayLabel,
			arrowImg                = arrowImg,
			birthdayErrorTipsLabel  = birthdayErrorTipsLabel,

			actionButtons           = actionButtons,
		}
	end

	xTry(function ( )
        self.viewData = CreateView()
        self:addChild(self.viewData.view)

        shareFacade:RegistObserver(SGL.CreateRole_Callback,     mvc.Observer.new(handler(self, self.CreateRoleCallback), self))
		shareFacade:RegistObserver(SGL.RandomRoleName_Callback, mvc.Observer.new(handler(self, self.RandomRoleNameCallback), self))
		shareFacade:RegistObserver(SGL.BIRTHDAY_SET_COMMPLETE,  mvc.Observer.new(handler(self, self.SetBirthdayCallback), self))

        self:InitVal()
        self:InitView()

	end, __G__TRACKBACK__)
end

function CreatePlayerLayer:InitVal()

	shareFacade:RegistSignal(COMMANDS.COMMAND_CreateRole,     AuthorCommand)
	shareFacade:RegistSignal(COMMANDS.COMMAND_RandomRoleName, AuthorCommand)

end

function CreatePlayerLayer:InitView()
	local viewData = self:GetViewData()
	local actionButtons = viewData.actionButtons
	for tag, node in pairs(actionButtons) do
		node:setTag(checkint(tag))
		display.commonUIParams(node, {cb = handler(self, self.OnButtonAction), animated = false})
	end

	local nameBox = viewData.nameBox
	local nameErrorTipsLabel = viewData.nameErrorTipsLabel
	nameBox:registerScriptEditBoxHandler(function (eventType, sender)
		-- 开始输入 并且  提示处于显示状态 则 隐藏 提示
		if eventType == 'began' then
			nameErrorTipsLabel:runAction(cc.Sequence:create({
				cc.FadeOut:create(0.2),
				cc.CallFunc:create(function()
					nameErrorTipsLabel:setOpacity(255)
					nameErrorTipsLabel:setVisible(false)
				end),
			}))
		end
	end)
end

function CreatePlayerLayer:onCleanup()
	shareFacade:UnRegistObserver(SGL.CreateRole_Callback,     self)
	shareFacade:UnRegistObserver(SGL.RandomRoleName_Callback, self)
	shareFacade:UnRegistObserver(SGL.BIRTHDAY_SET_COMMPLETE,  self)
end

function CreatePlayerLayer:OnButtonAction(sender)
	if not self.isControllable_ then return end

	local tag = checkint(sender:getTag())
	
	if tag == BTN_TAG.TAG_CREATE_ROLE then
		self:HandleCreateRole()
	elseif tag == BTN_TAG.TAG_RANDOM_NAME then
		self:HandleRandomName()
	elseif tag == BTN_TAG.TAG_BIRTHDAY then
		self:HanderBirthday()
	elseif tag == BTN_TAG.TAG_INVITE_CODE_CONFIRM then
		self:CheckCreateRole()
	end
end

function CreatePlayerLayer:HandleCreateRole()
	local viewData = self:GetViewData()
	-- 先检查 创角 角色名
	local playerName = viewData.nameBox:getText()
	-- 查错
	if nil == playerName or string.len(string.gsub(playerName, " ", "")) <= 0 then
		uiMgr:ShowInformationTips(__('角色名非法'))
		return
	end

	--如果是先行服 则检查邀请码
	if checkint(Platform.id) == PreIos or checkint(Platform.id) == PreAndroid or isEliteSDK() then
		if self.inviteCodeView then
			self.inviteCodeView:setVisible(true)
		else
			local view = require('Game.views.createPlayer.CreatePlayerInviteCodeView').new()
			display.commonUIParams(view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
			self:addChild(view)	
			self.inviteCodeView = view

			local inviteCodeViewData = view:GetViewData()
			local confirmButton = inviteCodeViewData.confirmButton
			confirmButton:setTag(BTN_TAG.TAG_INVITE_CODE_CONFIRM)

			display.commonUIParams(confirmButton, {cb = handler(self, self.OnButtonAction)})
			display.commonUIParams(inviteCodeViewData.backBtn,    {cb = handler(self, self.CloseInviteCode)})
			display.commonUIParams(inviteCodeViewData.eaterLayer, {cb = handler(self, self.CloseInviteCode)})
		end
		return
	end

	self:CheckCreateRole()
end

function CreatePlayerLayer:CheckCreateRole()
	--EVENTLOG.Log(EVENTLOG.EVENTS.create)

	if self.curSelectHeadId == 0 then
		uiMgr:ShowInformationTips(__('请选择一个头像'))
		return
	end

	if self.birthdayData == nil then
		uiMgr:ShowInformationTips(__('请选择出生生日'))
		return
	end

	local inviteCode = nil
	if self.inviteCodeView then
		local inviteCodeViewData = self.inviteCodeView:GetViewData()
		inviteCode = inviteCodeViewData.inviteCode:getText()
		if nil == inviteCode or string.len(string.gsub(inviteCode, " ", "")) <= 0 then
			uiMgr:ShowInformationTips(__('邀请码不能为空'))
			return
		end
	end

	local playerName = self.viewData.nameBox:getText()
	-- 头像 id
    local headId = self.curSelectHeadId
    local width  = display.sizeInPixels.width
    local height = display.sizeInPixels.height
    local userAgent = CCNative.getUserAgent and CCNative:getUserAgent() or ''
    local data   = {playerName = playerName, avatar = tostring(headId), width = width, height = height, userAgent = userAgent}
    if inviteCode ~= nil then
        data.inviteCode = inviteCode
	end
	-- 添加生日参数
	data.birthday = self.birthdayData.date

    shareFacade:DispatchSignal(COMMANDS.COMMAND_CreateRole, data)
end

function CreatePlayerLayer:HandleRandomName()
	-- 随机名字
	local viewData = self:GetViewData()
	local nameErrorTipsLabel = viewData.nameErrorTipsLabel
	local nameBox = viewData.nameBox
	-- 1. 隐藏 昵称相关的提示
	if nameErrorTipsLabel:isVisible() then
		nameErrorTipsLabel:runAction(cc.Sequence:create({
			cc.FadeOut:create(0.2),
			cc.CallFunc:create(function()
				nameErrorTipsLabel:setOpacity(255)
				nameErrorTipsLabel:setVisible(false)
			end),
		}))
	end

	if #self.names <= 0 then
		-- 2. 发送 请求 随机昵称的 协议
		shareFacade:DispatchSignal(COMMANDS.COMMAND_RandomRoleName)
	else
		self:UpdateName()
	end
	
end

function CreatePlayerLayer:UpdateName()
	local nameBox = self.viewData.nameBox
	nameBox:setText(tostring(self.names[#self.names]))
	table.remove(self.names, #self.names)
end

function CreatePlayerLayer:HanderBirthday(sender)
	-- show DateSelectView
	local DateSelectView = require('common.DateSelectView').new(self.birthdayData)
	DateSelectView:setPosition(utils.getLocalCenter(self))
	self:addChild(DateSelectView, 10)
end

function CreatePlayerLayer:OnClickHeadNodeAction(sender)
	local avatar    = checkint(sender:getTag())
	local viewData  = self:GetViewData()
	local selectImg = viewData.selectImg
	local headNodes = viewData.headNodes
	for avatarVal, headNode in pairs(headNodes) do
		if checkint(avatarVal) == avatar then
			selectImg:setPosition(headNode:getPosition())
		end
	end
	selectImg:setVisible(true)
	self.curSelectHeadId = avatar
end

function CreatePlayerLayer:CreateRoleCallback(stage, signal)
	if tolua.isnull(self) then return end
	local name = signal:GetName()
	local body = signal:GetBody()
	local errcode = body.errcode ~= nil and body.errcode or 0
	if errcode == 0 then
		-- 创角成功 走checkin
		--EVENTLOG.Log(EVENTLOG.EVENTS.createSuccessful)
		DotGameEvent.SendEvent(DotGameEvent.EVENTS.CREATE_ROLE)
		gameMgr:UpdateAuthorInfo({playerId = body.playerId, avatar = tostring(body.requestData.avatar), playerName = body.playerName, birthday = tostring(body.requestData.birthday)})
		-- 移除 视图前 先移除 editbox 监听
		local nameBox = self.viewData.nameBox
		if nameBox then
			nameBox:unregisterScriptEditBoxHandler()
		end
		
		self:EnterNextView()
	else
		-- 在名字 输入框上面显示 错误提示
		local errmsg = body.errmsg
		local nameErrorTipsLabel = self:GetViewData().nameErrorTipsLabel
		if nameErrorTipsLabel then
			nameErrorTipsLabel:setVisible(true)
			local fadeIn = cc.FadeIn:create(0.2)
			nameErrorTipsLabel:runAction(fadeIn)
			display.commonLabelParams(nameErrorTipsLabel, {text = errmsg})
		end
	end
end

function CreatePlayerLayer:RandomRoleNameCallback(stage, signal)
	local name = signal:GetName()
	local body = signal:GetBody()

	self.names = checktable(body.playerName)
	self:UpdateName()
end

function CreatePlayerLayer:SetBirthdayCallback(stage, signal)
	local name = signal:GetName()
	local body = signal:GetBody()

	self.birthdayData = body
	local birthdayTipLabel = self:GetViewData().birthdayTipLabel
	local text = string.fmt(__('_year_年_month_月_day_日'), {['_year_'] = body.year, ['_month_'] = body.month, ['_day_'] = body.day} )
	display.commonLabelParams(birthdayTipLabel, {text = text, color = '#5b3c25'})
end

function CreatePlayerLayer:EnterNextView()
	app.gameMgr:SetNewPlotWatchStatus(true)
    --创角成功后这个页面关闭
	-- self:setVisible(false)
	shareFacade:DispatchObservers("CREATE_PLAYER_SUCCESS")
    shareFacade:DispatchObservers("DirectorStory","next")
end


function CreatePlayerLayer:CloseInviteCode()
	self.inviteCodeView:setVisible(false)
end

function CreatePlayerLayer:ShowAcion()
	local viewData = self:GetViewData()
	local actions = {
		cc.TargetedAction:create(viewData.frameLayer, cc.Spawn:create({
			cc.Show:create(),
			cc.FadeIn:create(0.6)
		})),
		cc.CallFunc:create(function ()
			self.isControllable_ = true
		end)
	}
	self:runAction(cc.Sequence:create(actions))

end

function CreatePlayerLayer:GetViewData()
	return self.viewData
end

return CreatePlayerLayer
