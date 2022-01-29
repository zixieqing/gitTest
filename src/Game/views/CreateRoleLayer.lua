--[[
登录弹窗
--]]
local CreateRoleLayer = class('CreateRoleLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.CreateRoleLayer'
	node:enableNodeEvents()
	return node
end)

local shareFacade = AppFacade.GetInstance()
local AuthorCommand = require('Game.command.AuthorCommand')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local BTN_TAG = {
	TAG_RANDOM_NAME = 1008,
	TAG_CREATE_ROLE = 1006,

	-- 邀请码 tag
	TAG_INVITE_CODE_BACK = 2000,
	TAG_INVITE_CODE_CONFIRM = 2001,
}

local RES_DIR = {
	bg = _res('ui/home/cardslistNew/card_preview_bg.png'),
	titleBg = _res('ui/author/create_roles_bg_title.png'),
	nameBg = _res('ui/author/create_roles_bg_name.png'),
	nameBoxBg = _res('ui/author/create_roles_bg_name_2'),
	dice = _res('ui/author/create_roles_btn_dice.png'),
	list_bg = _res('ui/author/create_roles_bg_head.png'),
	btn_n = _res('ui/author/create_roles_btn_orange.png'),
	----------------------------------------------------------
	dialog_bg = _res('arts/stage/ui/dialogue_bg_2.png'),
	dialog_horn = _res('arts/stage/ui/dialogue_horn.png'),

	cell_bg_b = _res('ui/author/create_roles_head_black.png'),
	cell_bg_df = _res('ui/author/create_roles_head_down_default.png'),
	head = _res('ui/home/nmain/common_role_female.png'),
	frame_default = _res('ui/author/create_roles_head_up_default.png'),
	frame_select = _res('ui/author/create_roles_head_select.png'),
}

local CreateListCell = nil
local CreateDialogue = nil
local CreateInviteCodeLayer = nil

function CreateRoleLayer:ctor( ... )
	self.args = unpack({...})

	local function CreateViewNew()
		local actionButtons = {}

		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
		eaterLayer:setTouchEnabled(true)
		eaterLayer:setContentSize(self:getContentSize())
		eaterLayer:setPosition(utils.getLocalCenter(self))
		self:addChild(eaterLayer)

		local mainBg = display.newImageView(_res('arts/stage/bg/main_bg_06.jpg'), display.cx, display.cy, {isFull = true})
		local bg = display.newImageView(RES_DIR.bg, display.width, display.cy, {ap = cc.p(1, 0.5), isFull = true})
		local bgSize = display.size
		local view = display.newLayer(0, 0, { size = bgSize, ap = display.LEFT_BOTTOM})
		view:addChild(mainBg)
		view:addChild(bg)

		---------------------------  left  -------------------------------)
		local roleLayer = display.newLayer()
		local roleNode = CommonUtils.GetRoleNodeById('role_42', 1)
		local dialogue = CreateDialogue()
		roleNode:setAnchorPoint(display.LEFT_TOP)
		roleNode:setPosition(cc.p(display.SAFE_L, display.height))
		dialogue:setPosition(display.SAFE_L + bgSize.width * 0.03, bgSize.height * 0.05)
		view:addChild(roleLayer)
		roleLayer:setPosition(0, 0)
		roleLayer:addChild(roleNode)
		view:addChild(dialogue)

		---------------------------  right  -------------------------------
		local rightLayer = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})
		view:addChild(rightLayer)
		-- title
		local titleBg = display.newImageView(RES_DIR.titleBg, display.SAFE_R - 500, display.cy + 350, {ap = display.LEFT_TOP})
		local titleLabel = display.newLabel(0, 0, {text = __('选择你的形象'), fontSize = 22, color = '#c8b18d'})
		display.commonUIParams(titleLabel, {po = cc.p(utils.getLocalCenter(titleBg))})
		titleBg:addChild(titleLabel)
		rightLayer:addChild(titleBg)

		-- list
		local listBg = display.newImageView(RES_DIR.list_bg, 0, 0, {ap = display.LEFT_BOTTOM})
		local listBgSize = listBg:getContentSize()
		local listBgLayer = display.newLayer(display.SAFE_R - 50, display.cy - 140, {size = listBgSize, ap = display.RIGHT_BOTTOM})
		listBgLayer:addChild(listBg)
		rightLayer:addChild(listBgLayer)

		local gridViewSize = cc.size(listBgSize.width, listBgSize.height - 8)
		local gridViewCellSize = cc.size(147, 147)
		local gridView = CGridView:create(gridViewSize)
		-- gridView:setVisible(false)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(3)
		-- gridView:setAutoRelocate(true)
		-- gridView:setBounceable(false)
		-- gridView:setBackgroundColor(cc.c3b(100,100,200))
		gridView:setAnchorPoint(display.CENTER)
		gridView:setPosition(cc.p(listBgSize.width / 2 + 5, listBgSize.height / 2 - 5))
		listBgLayer:addChild(gridView)

		-- 重名提示
		local nameTip = display.newLabel(listBgLayer:getPositionX() - listBgSize.width / 2, display.cy - 276, {text = __('用户名已存在!'), fontSize = 24, color = '#ff2929', ap = display.CENTER_BOTTOM})
		nameTip:setVisible(false)
		rightLayer:addChild(nameTip)

		local nameBoxBg = display.newImageView(RES_DIR.nameBg, nameTip:getPositionX(), display.cy - 244, {ap = display.CENTER_BOTTOM})
		rightLayer:addChild(nameBoxBg)
		-- 名称
		local nameBoxSize = cc.size(280, 42)
		local nameBox = ccui.EditBox:create(nameBoxSize, RES_DIR.nameBoxBg)
		-- display.commonUIParams(nameBox, {po = cc.p(bgSize.width * 0.683, bgSize.height * 0.27), ap = display.CENTER})
		nameBox:setFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setFontColor(ccc3FromInt('#5b3c25'))
		nameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		nameBox:setPlaceHolder(__('请输入角色名'))
		nameBox:setPlaceholderFontSize(fontWithColor('M1PX').fontSize)
		nameBox:setPlaceholderFontColor(ccc3FromInt('#8c8c8c'))
		nameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		-- nameBox:setMaxLength(6)
		nameBox:registerScriptEditBoxHandler(function (eventType, sender)
			-- 开始输入 并且  提示处于显示状态 则 隐藏 提示
			if eventType == 'began' and nameTip:isVisible() then
				nameTip:runAction(cc.Sequence:create({
					cc.FadeOut:create(0.2),
					cc.CallFunc:create(function()
						nameTip:setOpacity(255)
						nameTip:setVisible(false)
					end),
				}))
			end
		end)
		-- nameBox:setMaxLength(6)
		display.commonUIParams(nameBox, {po = cc.p(nameTip:getPositionX(), display.cy - 234), ap = display.CENTER_BOTTOM})
		rightLayer:addChild(nameBox)

		if  not isKoreanSdk() and not isJapanSdk() then
			-- 随机昵称
			local diceBtn = display.newButton(0, 0, {n = RES_DIR.dice})
			display.commonUIParams(diceBtn, {po = cc.p(nameBoxBg:getPositionX() + nameBoxSize.width / 2 + 60, display.cy - 254), ap = display.CENTER_BOTTOM})
			actionButtons[tostring(BTN_TAG.TAG_RANDOM_NAME)] = diceBtn
			diceBtn:setTag(BTN_TAG.TAG_RANDOM_NAME)
			rightLayer:addChild(diceBtn)
		end

		-- 确定按钮
		local createRoleButton = display.newButton(nameBoxBg:getPositionX(), nameBoxBg:getPositionY() - 100, {n = RES_DIR.btn_n, ap = display.CENTER_BOTTOM})
		display.commonLabelParams(createRoleButton, fontWithColor(14, {text = __('确定'), fontSize = 30, outline = '#5b3c25'}))
		rightLayer:addChild(createRoleButton)
		createRoleButton:setTag(BTN_TAG.TAG_CREATE_ROLE)
		actionButtons[tostring(BTN_TAG.TAG_CREATE_ROLE)] = createRoleButton

		-- 2007
		return {
			view = view,
			roleLayer = roleLayer,
			dialogue = dialogue,

			rightLayer = rightLayer,
			nameTip = nameTip,
			playerNameBox = nameBox,
			gridView = gridView,
			actionButtons = actionButtons,
		}
	end

	local function CreateView()
		local actionButtons = {}

		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
		eaterLayer:setTouchEnabled(true)
		eaterLayer:setContentSize(self:getContentSize())
		eaterLayer:setPosition(utils.getLocalCenter(self))
		self:addChild(eaterLayer)

		-- local bg = display.newImageView(_res('ui/author/login_bg_account.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y)
		local bg = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {bg = _res('ui/author/login_bg_account.png'), ap = cc.p(0.5, 0.5)})
		self:addChild(bg)
		local bgSize = bg:getContentSize()

		local titleBg = display.newImageView(_res('ui/author/login_bg_title.png'), utils.getLocalCenter(bg).x, bgSize.height, {ap = cc.p(0.5, 1)})
		bg:addChild(titleBg)

		local titleLabel = display.newLabel(utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y,
			{text = __('创建角色'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('TC1').color})
		titleBg:addChild(titleLabel)

		local backBtn = display.newButton(0, 0, {n = _res('ui/author/login_btn_back.png')})
		display.commonUIParams(backBtn, {po = cc.p(15 + backBtn:getContentSize().width * 0.5, bgSize.height - 15 - backBtn:getContentSize().height * 0.5)})
		bg:addChild(backBtn)
		backBtn:setTag(10100)
		actionButtons[tostring(10100)] = backBtn

		-- local backBtn = display.newButton(0, 0, {n = _res('ui/author/login_btn_back.png')})
		-- display.commonUIParams(backBtn, {po = cc.p(15 + backBtn:getContentSize().width * 0.5, bgSize.height - 15 - backBtn:getContentSize().height * 0.5)})
		-- bg:addChild(backBtn)
		-- backBtn:setTag(10040)
		-- actionButtons[tostring(10040)] = backBtn

		local nameBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
		display.commonUIParams(nameBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.75)})
		bg:addChild(nameBox)
		nameBox:setFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setFontColor(ccc3FromInt('#9f9f9f'))
		nameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		nameBox:setPlaceHolder(__('请输入角色名'))
		nameBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		nameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		-- nameBox:setMaxLength(12)

        local inviteCode = nil
        if checkint(Platform.id) ~= InviteCodeChannel and SS_SHOW_INVITECODE then
            inviteCode = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
            display.commonUIParams(inviteCode, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.55)})
            bg:addChild(inviteCode)
            inviteCode:setFontSize(fontWithColor('M2PX').fontSize)
            inviteCode:setFontColor(ccc3FromInt('#9f9f9f'))
            inviteCode:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
            inviteCode:setPlaceHolder(__('请输入邀请码'))
            inviteCode:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
            inviteCode:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
            inviteCode:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        end

		local createRoleButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.175, {n = _res('ui/author/login_btn_create_new.png')})
		display.commonLabelParams(createRoleButton, {text = __('创  建'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color})
		bg:addChild(createRoleButton)
		createRoleButton:setTag(1006)
		actionButtons[tostring(1006)] = createRoleButton

		return {
			playerNameBox = nameBox,
            inviteCode = inviteCode,
			actionButtons = actionButtons,
		}
	end

	xTry(function ( )
		-- self.viewData = CreateView( )
        self.viewData = CreateViewNew()
        self:addChild(self.viewData.view)

        shareFacade:RegistObserver(SIGNALNAMES.CreateRole_Callback, mvc.Observer.new(handler(self, self.CreateRoleCallback), self))
        shareFacade:RegistObserver(SIGNALNAMES.RandomRoleName_Callback, mvc.Observer.new(handler(self, self.RandomRoleNameCallback), self))
        self:initVal()
        self:initView()
        if isElexSdk() then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AppFlyerEventTrack("CreateRolePage",{af_event_start = "CreateRolePage"})
        end
    end, __G__TRACKBACK__)
end

--==============================--
--desc: 初始化 参数
--time:2017-10-10 10:02:38
--@return
--==============================--
function CreateRoleLayer:initVal()
	self.names = {}
	self.selectIndex = 1

	local achieveRewardCof = CommonUtils.GetConfigAllMess('achieveReward', 'goods')
	self.initialHeads = {}
	for id, achieveRewardData in pairs(achieveRewardCof) do
		if checkint(achieveRewardData.initial) == 1 and checkint(achieveRewardData.rewardType) == CHANGE_TYPE.CHANGE_HEAD then
			table.insert(self.initialHeads, achieveRewardData)
		end
	end

	table.sort(self.initialHeads, function (a, b)
		return checkint(a.id) < checkint(b.id)
	end)

	shareFacade:RegistSignal(COMMANDS.COMMAND_CreateRole, AuthorCommand)
	shareFacade:RegistSignal(COMMANDS.COMMAND_RandomRoleName, AuthorCommand)
end

--==============================--
--desc: 初始化视图
--time:2017-10-10 09:56:51
--@return
--==============================--
function CreateRoleLayer:initView()
	local layer = self
	for k,btn in pairs(layer.viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
	end

    layer:runViewAction()
    local listCount = #self.initialHeads --FLAG_MAX_HEAD_ID - FLAG_MIN_HEAD_ID + 1
    local gridView = layer.viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    gridView:setBounceable(listCount > 9)
    gridView:setCountOfCell(listCount)
    gridView:reloadData()
end

--==============================--
--desc: 头像列表 数据源
--time:2017-10-10 10:01:57
--@p_convertview:
--@idx:
--@return
--==============================--
function CreateRoleLayer:OnDataSource(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1
	-- print('OnDataSource111')
	if pCell == nil then
		pCell = CreateListCell()

		local viewData = pCell.viewData
		local bg = viewData.bg
		display.commonUIParams(bg, {animate = false, cb = handler(self, self.OnCellAction)})

	end

	xTry(function()
		local isSelectState = index == self.selectIndex
		local imgs = self:updateCellState(pCell, isSelectState)
		local head = imgs.head
		local headData = self.initialHeads[index]
        head:setTexture(_res(string.format("ui/head/avator_icon_%d", headData.id)))
		pCell:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
end

--==============================--
--desc: 头像列表 cell  事件处理
--time:2017-10-10 09:59:46
--@sender:
--@return
--==============================--
function CreateRoleLayer:OnCellAction(sender)
    PlayAudioByClickNormal()
	local view = sender:getParent()
	local newCell = view:getParent()
	local index = newCell:getTag()

	if index == self.selectIndex then return end

    local layer = self
    if layer then
        local gridView = layer.viewData.gridView
        -- 先重置 原先 的 cell 实例
        local oldCell = gridView:cellAtIndex(self.selectIndex - 1)
        self:updateCellState(oldCell, false)

        -- 更新 最新cell 的状态
        self:updateCellState(newCell, true)
        self.selectIndex = index
    end
end

--==============================--
--desc: 按钮响应事件
--time:2017-10-10 09:56:51
--@sender:
--@return
--==============================--
function CreateRoleLayer:ButtonActions(sender)
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BTN_TAG.TAG_CREATE_ROLE then
		-- 先检查 创角 角色名
		local playerName = self.viewData.playerNameBox:getText()
		-- 查错
		if nil == playerName or string.len(string.gsub(playerName, " ", "")) <= 0 then
			uiMgr:ShowInformationTips(__('角色名非法'))
			return
		-- elseif string.len(playerName) > 21 then
			-- uiMgr:ShowInformationTips(__('角色名过长'))
			-- return
		end

		if checkint(Platform.id) == PreIos or checkint(Platform.id) == PreAndroid then
			if self.inviteCodeViewData then
				self.inviteCodeViewData.layer:setVisible(true)

			else
				self.inviteCodeViewData = CreateInviteCodeLayer()
				self:addChild(self.inviteCodeViewData.layer)

				local backBtn = self.inviteCodeViewData.backBtn
				local confirmButton = self.inviteCodeViewData.confirmButton
				local eaterLayer = self.inviteCodeViewData.eaterLayer

				display.commonUIParams(backBtn, {cb = handler(self, self.ButtonActions)})
				display.commonUIParams(confirmButton, {cb = handler(self, self.ButtonActions)})
				display.commonUIParams(eaterLayer, {cb = handler(self, self.closeInviteCode)})
			end
			return
		end

		self:checkCreateRole()

	elseif BTN_TAG.TAG_RANDOM_NAME == tag then
        -- 随机名字
        local layer = self
        local viewData = layer.viewData
        local nameTip = viewData.nameTip
        local playerNameBox = viewData.playerNameBox
        if layer then
            -- 1. 隐藏 昵称相关的提示
            if nameTip:isVisible() then
				nameTip:runAction(cc.Sequence:create({
					cc.FadeOut:create(0.2),
					cc.CallFunc:create(function()
						nameTip:setOpacity(255)
						nameTip:setVisible(false)
					end),
				}))
            end

			if #self.names <= 0 then
				-- 2. 发送 请求 随机昵称的 协议
				shareFacade:DispatchSignal(COMMANDS.COMMAND_RandomRoleName)
			else
				self:updateName()
			end
		end

	elseif BTN_TAG.TAG_INVITE_CODE_BACK == tag then
		self:closeInviteCode()
	elseif BTN_TAG.TAG_INVITE_CODE_CONFIRM == tag then
		self:checkCreateRole()
	end
end

--==============================--
--desc: 创建角色 响应 回调
--time:2017-10-10 09:56:51
--@stage:
--@signal:
--@return
--==============================--
function CreateRoleLayer:CreateRoleCallback(stage, signal)
    if tolua.isnull(self) then return end
	local name = signal:GetName()
	local body = signal:GetBody()
	local errcode = body.errcode and body.errcode or 0
	if errcode == 0 then
		-- 创角成功 走checkin
		EVENTLOG.Log(EVENTLOG.EVENTS.createSuccessful)
		gameMgr:UpdateAuthorInfo({playerId = body.playerId, avatar = tostring(body.requestData.avatar), playerName = body.playerName})
        -- 移除 视图前 先移除 editbox 监听
        local playerNameBox = self.viewData.playerNameBox
        if playerNameBox then
            playerNameBox:unregisterScriptEditBoxHandler()
        end
        if isElexSdk() then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AppFlyerEventTrack("CreateRoleSuccess",{af_event_start = "CreateRoleSuccess", playerId = body.playerId})
        end
        -- shareFacade:DispatchSignal(COMMANDS.COMMAND_Checkin, {isCreateRole = 1}) --是否是创角的请求
		self:enterNextView()
	else
		-- 在名字 输入框上面显示 错误提示
		if layer then
			local errmsg = body.errmsg
			local nameTip = layer.viewData.nameTip
			if nameTip then
				nameTip:setVisible(true)
				local fadeIn = cc.FadeIn:create(0.2)
				nameTip:runAction(fadeIn)
				display.commonLabelParams(nameTip, {text = errmsg})
			end
		end
	end
end

--==============================--
--desc: 随机名字 响应 回调
--time:2017-10-10 09:56:51
--@stage:
--@signal:
--@return
--==============================--
function CreateRoleLayer:RandomRoleNameCallback(stage, signal)
	local name = signal:GetName()
	local body = signal:GetBody()

	self.names = checktable(body.playerName)
	self:updateName()
end

function CreateRoleLayer:getSelectIndex()
	return self.selectIndex
end

--==============================--
--desc: 更新玩家输入的名称
--time:2017-10-10 09:55:48
--@return
--==============================--
function CreateRoleLayer:updateName()
	local playerNameBox = self.viewData.playerNameBox
	playerNameBox:setText(tostring(self.names[#self.names]))
	table.remove(self.names, #self.names)
end

--==============================--
--desc: 更新 头像cell  的选择状态
--time:2017-10-10 09:55:48
--@return
--==============================--
function CreateRoleLayer:updateCellState(cell, isSelectState)
	local viewData = cell.viewData
	local imgs = viewData.imgs
	local frame_select = imgs.frame_select
	local cell_bg_b = imgs.cell_bg_b
	frame_select:setVisible(isSelectState)
	cell_bg_b:setVisible(not isSelectState)
    return imgs
end

--==============================--
--desc: 进入下一个界面
--time:2017-10-10 09:55:07
--@return
--==============================--
function CreateRoleLayer:enterNextView()
    --创角成功后这个页面关闭
    self:setVisible(false)
    shareFacade:DispatchObservers("DirectorStory","next")
end

function CreateRoleLayer:checkCreateRole()
	EVENTLOG.Log(EVENTLOG.EVENTS.create)

	local inviteCode = nil
	if self.inviteCodeViewData then
		inviteCode = self.inviteCodeViewData.inviteCode:getText()
		if nil == inviteCode or string.len(string.gsub(inviteCode, " ", "")) <= 0 then
			uiMgr:ShowInformationTips(__('邀请码不能为空'))
			return
		end
	end

	local playerName = self.viewData.playerNameBox:getText()
	if nil == playerName or string.len(string.gsub(playerName, " ", "")) <= 0 then
		uiMgr:ShowInformationTips(__('角色名非法'))
		return
	elseif string.len(playerName) > 21 then
		uiMgr:ShowInformationTips(__('角色名过长'))
		return
	end
	-- 头像 id
    local headData = self.initialHeads[self.selectIndex]
    local headId = headData.id -- FLAG_MIN_HEAD_ID + self.selectIndex - 1
    local width  = display.sizeInPixels.width
    local height = display.sizeInPixels.height
    local userAgent = CCNative.getUserAgent and CCNative:getUserAgent() or ''
    local data   = {playerName = playerName, avatar = tostring(headId), width = width, height = height, userAgent = userAgent}
    if inviteCode ~= nil then
        data.inviteCode = inviteCode
	end

    shareFacade:DispatchSignal(COMMANDS.COMMAND_CreateRole, data)
end

function CreateRoleLayer:closeInviteCode( ... )
	self.inviteCodeViewData.layer:setVisible(false)
end

function CreateRoleLayer:onCleanup()
	shareFacade:UnRegistObserver(SIGNALNAMES.CreateRole_Callback, self)
	shareFacade:UnRegistObserver(SIGNALNAMES.RandomRoleName_Callback, self)
end

CreateListCell = function ()
	local cell = CGridViewCell:new()

	local bg = display.newButton(0, 0, {animate = false, n = RES_DIR.cell_bg_df, ap = display.CENTER})
	local bgSize = bg:getContentSize()

	local view = display.newLayer(0, 0, {size = bgSize, ap = display.LEFT_BOTTOM})
	display.commonUIParams(bg, {po = utils.getLocalCenter(view)})
	view:addChild(bg)
	cell:addChild(view)

	local headConf = {
		{'head', RES_DIR.head, true},
		{'frame_default', RES_DIR.frame_default, true},
		{'frame_select', RES_DIR.frame_select, false},
		{'cell_bg_b', RES_DIR.cell_bg_b, true},
	}
	local imgs = {}
	for i,v in ipairs(headConf) do
		local key, imgPath, defVisible = unpack(v)
		local img = display.newImageView(imgPath, bgSize.width / 2, bgSize.height /2)
		img:setVisible(defVisible)
		bg:addChild(img)
		if key == 'head' then
			img:setScale(0.8)
		end
		imgs[key] = img
	end

	cell.viewData = {
		bg = bg,
		imgs = imgs
	}
	return cell
end

CreateDialogue = function ()
	local dialogue = display.newImageView(RES_DIR.dialog_bg, 0,  0, {ap = display.LEFT_BOTTOM ,scale9 = true })
	local size = dialogue:getContentSize()
	local dialogLayer = display.newLayer(0, 0, {size = size})
	dialogLayer:addChild(dialogue)

	local horn = display.newImageView(_res(RES_DIR.dialog_horn), size.width / 2, size.height + 5, {rotation = 182})
	dialogue:addChild(horn)

	local dialogueText = display.newLabel(size.width/2, size.height/2,
		{text =  __('哟~等你很久了，我记得你的梦想是经营餐厅来赚大钱，而这间餐厅正好需要一个新主人，在这份契约书上填写你的资料后，它就属于你了，要好好经营它哦。 '), fontSize = 22,  w = 650 ,color = '#5b3c25'})
	dialogue:addChild(dialogueText)
	return dialogLayer
end

CreateInviteCodeLayer = function ()
	local layer = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})

	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(layer:getContentSize())
	eaterLayer:setPosition(utils.getLocalCenter(layer))
	layer:addChild(eaterLayer)

	local bg = display.newLayer(utils.getLocalCenter(layer).x, utils.getLocalCenter(layer).y, {bg = _res('ui/author/login_bg_account.png'), ap = cc.p(0.5, 0.5)})
	layer:addChild(bg)
	local bgSize = bg:getContentSize()
	bg:addChild(display.newLayer(0,0,{ap = display.LEFT_BOTTOM, color = cc.c4b(0, 0, 0, 0), enable = true, size = bgSize}))

	local titleBg = display.newImageView(_res('ui/author/login_bg_title.png'), utils.getLocalCenter(bg).x, bgSize.height, {ap = cc.p(0.5, 1)})
	bg:addChild(titleBg)

	local titleLabel = display.newLabel(utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y,
		{text = __('请输入邀请码'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('TC1').color})
	titleBg:addChild(titleLabel)

	local backBtn = display.newButton(0, 0, {n = _res('ui/author/login_btn_back.png')})
	display.commonUIParams(backBtn, {po = cc.p(15 + backBtn:getContentSize().width * 0.5, bgSize.height - 15 - backBtn:getContentSize().height * 0.5)})
	backBtn:setTag(BTN_TAG.TAG_INVITE_CODE_BACK)
	bg:addChild(backBtn)

	local inviteCode = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
	display.commonUIParams(inviteCode, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.55)})
	bg:addChild(inviteCode)
	inviteCode:setFontSize(fontWithColor('M2PX').fontSize)
	inviteCode:setFontColor(ccc3FromInt('#9f9f9f'))
	inviteCode:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	inviteCode:setPlaceHolder(__('请输入邀请码'))
	inviteCode:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
	inviteCode:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	inviteCode:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

	local confirmButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.2, {n = _res('ui/author/login_btn_enter_Accounts.png'), scale9 = true, size = cc.size(220, 67)})
	display.commonLabelParams(confirmButton, {text = __('确  定'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color})
	confirmButton:setTag(BTN_TAG.TAG_INVITE_CODE_CONFIRM)
	bg:addChild(confirmButton)

	return {
		layer      = layer,
		eaterLayer = eaterLayer,
		backBtn    = backBtn,
		inviteCode = inviteCode,
		confirmButton = confirmButton,
		bg = bg,
	}
end

function CreateRoleLayer:runViewAction()
	local roleLayer = self.viewData.roleLayer
	local dialogue = self.viewData.dialogue
	local rightLayer = self.viewData.rightLayer

	-- roleLayer:setSkewX(-20)
	roleLayer:setPositionX(-display.width * 0.37)

	dialogue:setScale(0)
    dialogue:setOpacity(0)
    dialogue:setRotation(90)

	local rightLayerX, rightLayerY = rightLayer:getPosition()

	rightLayer:setPosition(cc.p(rightLayerX + rightLayer:getContentSize().width, rightLayerY))
	-- rightLayer:setVisible(false)
	-- rightLayer:setScale(0)
	-- rightLayer:setOpacity(0)

	self:runAction(cc.Sequence:create({
		cc.TargetedAction:create(roleLayer, cc.MoveTo:create(0.4, cc.p(0, 0))),
		-- cc.TargetedAction:create(roleLayer, cc.SkewTo:create(0.2, 10, 0)),
        -- cc.TargetedAction:create(roleLayer, cc.SkewTo:create(0.1, 0, 0)),
		cc.Spawn:create({
            cc.TargetedAction:create(dialogue, cc.FadeTo:create(0.2, 255)),
            cc.TargetedAction:create(dialogue, cc.ScaleTo:create(0.25, 1)),
            cc.TargetedAction:create(dialogue, cc.RotateTo:create(0.3, 0))
        }),
		cc.TargetedAction:create(rightLayer, cc.MoveTo:create(0.5, cc.p(rightLayerX, rightLayerY))),
			-- cc.TargetedAction:create(rightLayer, cc.FadeTo:create(0.5, 255)),
            -- cc.TargetedAction:create(rightLayer, cc.ScaleTo:create(0.5, 1)),

	}))
end

return CreateRoleLayer
