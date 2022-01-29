--[[
UI管理模块
场景管理相关
--]]
---@type ManagerBase
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class UIManager
local UIManager = class('UIManager',ManagerBase)

UIManager.instances = {}

GameSceneTag = {
	Current_GameSceneTag          = 900,
	Push_GameSceneTag             = 901,
	Home_GameSceneTag             = 902,
	Chat_GameSceneTag             = 1027,
	UI_GameSceneTag               = 1026,
	Dialog_GameSceneTag           = 1028,
	Top_Chat_GameSceneTag         = 1029,
	ScrollNotice_GameSceneTag     = 2018,
	Information_TIPS_GameSceneTag = 2020,
	Guide_GameSceneTag            = 2022,
	NetworkWeak_GameSceneTag      = 2023,
	Loading_GameSceneTag          = 2024,
	TouchWave_GameSceneTag        = 3048,
	Dowloader_GameSceneTag        = 54320,
	Notice_GameSceneTag           = 54321,
	ExitGameView_GameSceneTag     = 99998,
	BlockClick_GameSceneTag       = 99999,
	LogInfoPopup_GameSceneTag     = 100000,
	GlobalVoiceNodeTag            = 999999,
	BootLoader_GameSceneTag       = 1000000,
	ERROR_TIPS_GameSceneTag       = 1000001,
}

GameSceneType = {
	ST_None           = 1,
	ST_Initial        = 2,
	ST_ResourceLoader = 3,
	ST_Login          = 4,
	ST_MainScene      = 5,
	ST_LoadingScene   = 6,
}

local shareSceneManager = cc.CSceneManager:getInstance()



function UIManager:ctor( key )
	self.super.ctor(self)
	if UIManager.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的facade类型" )
		return
	end
	self.ui = {}
	self.scene = {}
	self.suspend = {}
	-------------------
	self.currentScene = nil
	self.gameScenes = {} --管理场景的dict 防止加多个
	self.sceneStack = {} --节点stack
	self.sceneType  = GameSceneType.ST_None
	---------------------
    self.isBusy = false

    --添加一个全局场景对白层
    local uilayer = CLayout:create(display.size)
	uilayer:setPosition(display.center)
	sceneWorld:addChild(uilayer, GameSceneTag.UI_GameSceneTag, GameSceneTag.UI_GameSceneTag)

    local dialogLayer = CLayout:create(display.size)
    dialogLayer:setPosition(display.center)
    sceneWorld:addChild(dialogLayer, GameSceneTag.Dialog_GameSceneTag, GameSceneTag.Dialog_GameSceneTag)

	UIManager.instances[key] = self
end

function UIManager.GetInstance(key)
	key = (key or "UIManager")
	if UIManager.instances[key] == nil then
		UIManager.instances[key] = UIManager.new(key)
	end
	return UIManager.instances[key]
end

function UIManager:SetSceneType( atype )
	if self.sceneType == atype then return end
	self.sceneType = atype --设置当前状态
end

--------------------------------------------
---############# 新的场景管理逻辑 ##########
---------------------------------------------

function UIManager:Scene( )
	return sceneWorld
end
---@return GameScene
function UIManager:GetCurrentScene( )
	return self.sceneStack[#self.sceneStack]
end

--[[
--添加一个场景并返回这个场景
--@param scenepath 场景名称
--@return 添加后的场景 GameScene对象
--]]
function UIManager:AddScene( scenepath, ... )
	local gameScene = nil
	if not self.gameScenes[scenepath] then
		local params = {name = scenepath}
		local arg = unpack({...})
		if arg and next(arg) ~= nil  then
			-- TODO 变长参数产生的bug
			params = arg
			params.name = scenepath
		end
		gameScene = require( scenepath ).new(params)
		gameScene.contextName = scenepath
		self.gameScenes[scenepath] = gameScene
		logs('+  scene) ' .. tostring(scenepath))
	else
		gameScene = self.gameScenes[scenepath]
	end
	return gameScene
end
--[[
--添加对话框层
--@path 文件路径
--@params 参数
--]]
function UIManager:AddDialog( path, params, zorder)
	local curDialog = self:GetCurrentScene():getChildByName(path)
	if not curDialog then
		xTry(function()
            local dialogNode = require(path)
            curDialog = dialogNode.new(params)
            display.commonUIParams(curDialog, {po = display.center})
            curDialog:setName(path)
            if zorder then
                curDialog:setLocalZOrder(zorder)
            end
            self:GetCurrentScene():AddDialog(curDialog)
		end,__G__TRACKBACK__)
	end
	return curDialog
end

--[[
显示通用提示框
--]]
function UIManager:ShowInformationTips( text, pos )
	xTry(function()
		if not pos then pos = display.center end
		local curDialog = self:GetCurrentScene():GetDialogByTag(92345)
		if not curDialog then
			local dialogNode = require("common.InforTips")
			curDialog = dialogNode.new({text = text, pos = pos})
			display.commonUIParams(curDialog, {po = display.center})
			app.uiMgr:Scene():addChild(curDialog ,GameSceneTag.BootLoader_GameSceneTag)
			--curDialog:setTag(92345)
			--curDialog:setLocalZOrder(1000)
			--self:GetCurrentScene():AddDialog(curDialog)
		else
			curDialog:addTips(text, pos)
		end
	end,__G__TRACKBACK__)
end
--[[
显示奖励要求提示框
--]]
function UIManager:ShowRewardInformationTips( params )
	xTry(function()
		local tag = 77777
		local curNode = self:GetCurrentScene():GetDialogByTag(tag)
		if not curNode then
			local node = require("common.CommonTipBoard").new({tag = tag, params = params})
			node:setTag(tag)
			display.commonUIParams(node, {po = cc.p(0, 0)})
			node:setLocalZOrder(6200)
			self:GetCurrentScene():AddDialog(node)
		else
			curNode:RefreshUI(params)
		end
	end,__G__TRACKBACK__)
end
--[[
奖励要求提示框是否存在
--]]
function UIManager:IsRewardInformationTipsExist()
	local tag = 77777
	local curNode = self:GetCurrentScene():GetDialogByTag(tag)
	if curNode then
		return true
	end
	return false
end
--[[
通用提示框是否存在
--]]
function UIManager:IsCommonInformationTipsExist()
	local tag = 23456
	local curNode = self:GetCurrentScene():GetDialogByTag(tag)
	if curNode then
		return true
	end
	return false
end
--[[
	删除通用提示框
--]]
function UIManager:RemoveInformationTips()
	xTry(function()
		local curDialog = self:GetCurrentScene():GetDialogByTag(23456)
		if curDialog  then
			curDialog:RemoveSelf_()
		end
	end,__G__TRACKBACK__)
end
--[[
显示通用提示板
@params params table 参数
--]]
function UIManager:ShowInformationTipsBoard(params)
	xTry(function()
		local tag = 23456
		local curNode = self:GetCurrentScene():GetDialogByTag(tag)
		if not curNode then
			local node = require("common.CommonTipBoard").new({tag = tag, params = params})
			node:setTag(tag)
			display.commonUIParams(node, {po = cc.p(0, 0)})
			node:setLocalZOrder(6200)
			self:GetCurrentScene():AddDialog(node)
		else
			curNode:RefreshUI(params)
		end
	end,__G__TRACKBACK__)
end
--[[
显示通用通用数字键盘
@params params table 参数
--]]
function UIManager:ShowNumberKeyBoard(params)
	xTry(function ()
		local mediator = require('Game.mediator.NumKeyboardMediator').new({
			nums 			= checkint(params.nums), 				-- 最大输入位数
			model 			= checkint(params.model), 				-- 输入模式 1为n位密码模式 2为自由模式
			callback 		= params.callback, 						-- 回调函数 确定之后接收输入字符的处理回调
			titleText 		= params.titleText, 					-- 标题
			defaultContent 	= params.defaultContent 				-- 输入框中默认显示的文字
		})
		AppFacade.GetInstance():RegistMediator(mediator)
	end,__G__TRACKBACK__)
end
--[[
显示通用对话气泡
@params params table 参数 -> CommonDialogueBubbleNode
@return dialogueBubbleNode CommonDialogueBubbleNode 对话气泡节点
--]]
function UIManager:ShowDialogueBubble(params)
	xTry(function ()
		local dialogueBubbleNode = require('common.CommonDialogueBubbleNode').new({
			targetNode 				= params.targetNode, 				-- 对齐的目标节点 与对齐的目标位置二选一
			targetPosition 			= params.targetPosition,			-- 对齐的目标位置 与对齐的目标节点二选一
			descr 					= tostring(params.descr or ''), 	-- 对话内容
			parentNode 				= params.parentNode, 				-- 父节点 不能为空
			zorder 					= params.zorder, 					-- zorder
			alwaysOnCenter 			= params.alwaysOnCenter, 			-- 是否始终在中间 默认false
			alwaysOnTop 			= params.alwaysOnTop, 				-- 是否始终在顶部 默认false
			ignoreOutside 			= params.ignoreOutside, 			-- 是否无视超边界 默认false
			paddingX 				= params.paddingX, 					-- 修正的x距离 始终为正 默认0
			paddingY 				= params.paddingY, 					-- 修正的y距离 始终为正 默认0
			touchRemove 			= params.touchRemove, 				-- 是否开启点击移除 默认false
			autoRemove 				= params.autoRemove 				-- 是否开启自动移除 默认true
		})
		return dialogueBubbleNode
	end,__G__TRACKBACK__)
end
--[[
	为当前场景 添加通用提示框
	@params CommonTip 的 args
]]
function UIManager:AddCommonTipDialog(commonTipArgs)
	local commonTip = require('common.CommonTip').new(commonTipArgs)
	self:GetCurrentScene():AddDialog(commonTip)
	return commonTip
end
function UIManager:AddNewCommonTipDialog(commonTipArgs)
	local commonTip = require('common.NewCommonTip').new(commonTipArgs)
	commonTip:setPosition(display.center)
	self:GetCurrentScene():AddDialog(commonTip)
	return commonTip
end
function UIManager:AddCommonTipNewDialog(args)
	local commonTip = require('common.CommonTipNew').new(args)
	commonTip:setPosition(display.center)
	self:GetCurrentScene():AddDialog(commonTip)
	return commonTip
end

--[[
	为当前场景 添加通用改名框
	@params ChangeNamePopup 的 args
]]
function UIManager:AddChangeNamePopup(args)
	local changeNamePopup = require('common.ChangeNamePopup').new(args)
	self:GetCurrentScene():AddDialog(changeNamePopup)
	return changeNamePopup
end

--[[
显示通用介绍板
@params params table 参数
@see common.IntroPopup
--]]
function UIManager:ShowIntroPopup(params)
	xTry(function()
		local nodeName  = 'common.IntroPopup'
		local introNode = self:GetCurrentScene():GetDialogByName(nodeName)
		if not introNode then
			local node = require('common.IntroPopup').new(params)
			node:setCloseCB(handler(self, self.RemoveIntroPopup))
			node:setName(nodeName)
			node:setLocalZOrder(6100)
			node:setTag(6100)
			self:GetCurrentScene():AddDialog(node)
		end
	end,__G__TRACKBACK__)
end
function UIManager:RemoveIntroPopup()
	xTry(function()
		local nodeName  = 'common.IntroPopup'
		local introNode = self:GetCurrentScene():GetDialogByName(nodeName)
		if introNode then
			self:GetCurrentScene():RemoveDialog(introNode)
		end
	end,__G__TRACKBACK__)
end


--[[
显示 文件验证弹窗
@params params 				table 	弹窗参数表
@params params.infoText		string	提示文字
@params params.isVerifying	bool	是否验证中状态（默认为 true）
@see common.VerifyInfoPopup
--]]
function UIManager:showVerifyInfoPopup(params)
	xTry(function()
		local nodeName       = 'verifyInfoPopup'
		local verifyInfoNode = self:GetCurrentScene():GetDialogByName(nodeName)
		if not verifyInfoNode then
			local node = require('common.VerifyInfoPopup').new()
			node:setName(nodeName)
			node:setLocalZOrder(6010)
			node:setTag(6010)
			self:GetCurrentScene():AddDialog(node)
			verifyInfoNode = node
		end
		
		if params then
			verifyInfoNode:setIsVerifying(params.isVerifying == nil or params.isVerifying == true)

			if params.infoText then
				verifyInfoNode:setInfoText(params.infoText)
			end
		end
	end, __G__TRACKBACK__)
end
function UIManager:removeVerifyInfoPopup()
	xTry(function()
		local nodeName       = 'verifyInfoPopup'
		local verifyInfoNode = self:GetCurrentScene():GetDialogByName(nodeName)
		if verifyInfoNode then
			self:GetCurrentScene():RemoveDialog(verifyInfoNode)
		end
	end, __G__TRACKBACK__)
end


--[[
显示 文件验证弹窗
@params params 				table 	弹窗参数表
@params params.isFuzzy		bool	是否模糊详情（默认为 false）
@params params.resDatas		table	下载资源数据列表
@params params.finishCB		funtion	下载完成回调
@see common.DownloadResPopup
--]]
function UIManager:showDownloadResPopup(params)
	xTry(function()
		local nodeName        = 'downloadResPopup'
		local downloadResNode = self:GetCurrentScene():GetDialogByName(nodeName)
		if not downloadResNode then
			local node = require('common.DownloadResPopup').new()
			node:setName(nodeName)
			node:setLocalZOrder(6020)
			node:setTag(6020)
			self:GetCurrentScene():AddDialog(node)
			downloadResNode = node
		end
		
		if params then
			downloadResNode:setFuzzyMode(params.isFuzzy)
			if params.finishCB then
				downloadResNode:setFinishCallback(params.finishCB)
			end
			if params.resDatas then
				downloadResNode:setDownloadResDatas(params.resDatas)
			end
		end
	end, __G__TRACKBACK__)
end


--[[
--切换一个场景
--@param scenepath 新的场景路径
--]]
function UIManager:SwitchToScene( gameScene )
	xTry( function ( )
		if self.currentScene then
			self.gameScenes[tostring( self.currentScene.contextName )] = nil --清除缓存
			logs('-  scene) ' .. tostring(self.currentScene.contextName))
            -- local currentScene = self.currentScene
            -- currentScene:setLocalZOrder(-9999)
            -- currentScene:setVisible(false)
            -- currentScene:removeFromParent()
            -- currentScene:runAction(cc.RemoveSelf:create())
			-- self.currentScene:removeAllChildren(true)
			-- self.currentScene:runAction(cc.RemoveSelf:create())
			if sceneWorld:getChildByTag(GameSceneTag.Current_GameSceneTag) then
                local sceneNode = sceneWorld:getChildByTag(GameSceneTag.Current_GameSceneTag)
                if sceneNode then
					sceneNode:setTag(-100000)
                    sceneNode:setVisible(false)
                    sceneNode:setLocalZOrder(-100000)
					-- sceneNode:removeFromParent()
                    sceneNode:runAction(cc.RemoveSelf:create())
                end
				-- sceneWorld:getChildByTag(GameSceneTag.Current_GameSceneTag):runAction(cc.RemoveSelf:create())
				-- sceneWorld:removeChildByTag(GameSceneTag.Current_GameSceneTag, true)
			end
			if sceneWorld:getChildByTag(GameSceneTag.Push_GameSceneTag) then
				local sceneNode = sceneWorld:getChildByTag(GameSceneTag.Push_GameSceneTag)
                if sceneNode then
					sceneNode:setTag(-100001)
                    sceneNode:setVisible(false)
					sceneNode:setLocalZOrder(-100001)
                    -- sceneNode:removeFromParent()
                    sceneNode:runAction(cc.RemoveSelf:create())
                end
                -- sceneWorld:removeChildByTag(GameSceneTag.Push_GameSceneTag, true)
			end
			-- sceneWorld:removeChildByTag(GameSceneTag.Push_GameSceneTag, true);
		end

		------------ 移除所有dialog ------------
		-- local dialogScene = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
		-- if dialogScene then
			-- dialogScene:removeAllChildren()
		-- end
        ------------ 移除所有dialog ------------

		self.currentScene = gameScene
		gameScene:setPosition(display.center)
		sceneWorld:addChild(gameScene, GameSceneTag.Current_GameSceneTag,GameSceneTag.Current_GameSceneTag)
		self.sceneStack = {gameScene}
		funLog(Logger.INFO, "##### gameScenes #########" .. tostring(table.nums(self.sceneStack) ))
		funLog(Logger.INFO, self.gameScenes)
	end, __G__TRACKBACK__)
end

function UIManager:SwitchToTargetScene( scenepath, ... )
	funLog(Logger.INFO, "########## SwitchToTargetScene ########" .. scenepath )
    --判断是否需要影藏充值条的逻辑
    display.removeUnusedSpriteFrames()
	local gameScene = self:AddScene(scenepath, ...)
	self:SwitchToScene(gameScene)
	return gameScene
end

--[[
--添加一个场景进入
--@param scenepath 场景的路径
--]]
function UIManager:PushGameScene( scenepath)
	local gameScene = self:AddScene( scenepath )
	local scene = sceneWorld:getChildByTag(GameSceneTag.Push_GameSceneTag)
	if not scene then
		for k, v in pairs( self.gameScenes ) do
			v:onExit() --退出功能,是否需要
		end
		funLog(Logger.INFO, "PushGameScene ==" .. gameScene.contextName )
		-- local colorView = CLayout:create(display.size)
		-- colorView:setBackgroundColor(cc.c4b(0, 0, 0, 0))
		-- colorView:setPosition(display.center)
		gameScene:setPosition(display.center)
		-- colorView:addChild(gameScene)
		sceneWorld:addChild(gameScene, GameSceneTag.Push_GameSceneTag,GameSceneTag.Push_GameSceneTag)
		table.insert( self.sceneStack, gameScene)
	end
	return gameScene
end

function UIManager:PopGameScene( )
	local topScene = table.remove( self.sceneStack, #self.sceneStack)
	if topScene:getParent() then
		funLog(Logger.INFO,"4============" ..  topScene.contextName )
		self.gameScenes[tostring( topScene.contextName )] = nil --清除缓存
		logs('-  scene) ' .. tostring(topScene.contextName))
        topScene:setVisible(false)
        topScene:setLocalZOrder(-99999)
        topScene:runAction(cc.RemoveSelf:create())
		-- sceneWorld:removeChild(topScene, true)
		funLog(Logger.INFO,"PopGameScene =========" .. tostring(#self.sceneStack), tostring(#self.gameScenes ))
		if #self.sceneStack > 0 then
			topScene = self.sceneStack[#self.sceneStack]
			topScene:onEnter()-- 是否需要?
		end
	end
	display.removeUnusedSpriteFrames()
end

function UIManager:PopAllScene( )
    -- for name,val in pairs(GameSceneTag) do
        -- sceneWorld:removeChildByTag(val)
    -- end
    local children = sceneWorld:getChildren()
    for _,child in pairs(children) do
        child:runAction(cc.RemoveSelf:create())
    end
    display.removeUnusedSpriteFrames()
end

function UIManager.Destroy( key )
	key = (key or "UIManager")
	if UIManager.instances[key] == nil then
		return
	end
    local instance = UIManager.instances[key]
    --清除配表数据
	UIManager.instances[key] = nil
end

---------------------------------
----################游戏操作类#########
------------------------------------
--[[
资源加载功能逻辑
@params table {
	isInit boolean 是否是最开始的boolean初始化数据资源逻辑
	loadTasks function 开始加载逻辑回调
	done function 完成加载逻辑回调
}
--]]
function UIManager:SwitchToWelcomScene( ... )
	self:SetSceneType(GameSceneType.ST_ResourceLoader)
	self:SwitchToTargetScene('Game.views.LoadingView', ...)
end

function UIManager:ShowLoadingScene( )
	-- local gameScene = self:AddScene( "common.ProgressHUD" )
	local gameScene = sceneWorld:getChildByTag(GameSceneTag.Loading_GameSceneTag)
	if not gameScene then
        gameScene = self:AddScene( "common.ProgressHUD" )
        -- funLog(Logger.INFO,"PushGameScene ==" .. gameScene.contextName )
		-- local colorView = CLayout:create(display.size)
		-- colorView:setBackgroundColor(cc.c4b(0, 0, 0, 0))
		-- colorView:setPosition(display.center)
		gameScene:setPosition(display.center)
		-- colorView:addChild(gameScene)
		sceneWorld:addChild(gameScene, GameSceneTag.Loading_GameSceneTag,GameSceneTag.Loading_GameSceneTag)
		-- table.insert( self.sceneStack, gameScene)
	end
	return gameScene
end

function UIManager:RemoveLoadingScene( )
	-- local topScene = table.remove( self.sceneStack, #self.sceneStack)
	-- if topScene:getParent() then
		-- funLog(Logger.INFO, "4============".. topScene.contextName )
		-- self.gameScenes[tostring( topScene.contextName )] = nil --清除缓存
        -- funLog(Logger.INFO,"PopGameScene =========" .. tostring(#self.sceneStack), tostring(#self.gameScenes ))
	-- end
    self.gameScenes['common.ProgressHUD'] = nil
	logs('-  scene) ' .. 'common.ProgressHUD')
    local scene = sceneWorld:getChildByTag(GameSceneTag.Loading_GameSceneTag)
    if scene then
        sceneWorld:removeChild(scene, true)
    end

end

function UIManager:ShowNetworkWeakScene( )
	local scene = sceneWorld:getChildByTag(GameSceneTag.NetworkWeak_GameSceneTag)
	if not scene then
		scene = self:AddScene('common.NetworkWeakTip')
		scene:setPosition(display.center)
		sceneWorld:addChild(scene, GameSceneTag.NetworkWeak_GameSceneTag, GameSceneTag.NetworkWeak_GameSceneTag)
		funLog(Logger.INFO, "PushGameScene ==" .. scene.contextName )
	end
	return scene
end

function UIManager:RemoveNetworkWeakScene( )
    local scene = sceneWorld:getChildByTag(GameSceneTag.NetworkWeak_GameSceneTag)
    if scene then
		funLog(Logger.INFO,"PopGameScene =========" .. scene.contextName)
		self.gameScenes[tostring(scene.contextName)] = nil --清除缓存
		logs('-  scene) ' .. tostring(scene.contextName))
        sceneWorld:removeChild(scene, true)
    end
end


--[[
--设置购买条的显示状态的功能
--@visible
--]]
function UIManager:UpdatePurchageNodeState(visible)
    local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
    if uiLayer then
        local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if viewComponent then
            viewComponent:setVisible(visible)
        end
    end
end

function UIManager:UpdateBackButton( visible )
	local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
    if uiLayer then
        local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if viewComponent then
            viewComponent.viewData.navBackButton:setVisible(visible)
        end
    end
end


function UIManager:showGameNotice(noticeData)
	local noticeLayer = sceneWorld:getChildByTag(GameSceneTag.Notice_GameSceneTag)
	if noticeLayer then
		noticeLayer:addGameNotice(noticeData)
	else
		noticeLayer = require('home.GameNoticeLayer').new(noticeData)
		noticeLayer:setTag(GameSceneTag.Notice_GameSceneTag)
		sceneWorld:addChild(noticeLayer, GameSceneTag.Notice_GameSceneTag)
    end
end


function UIManager:showDownloaderSubRes()
	local sceneNode = sceneWorld:getChildByTag(GameSceneTag.Dowloader_GameSceneTag)
	if not sceneNode then
		local sceneNode = require('root.Downloader').new(function()
			self:ShowInformationTips(__('扩展包已经下载完成'))
			self:removeDownloaderSubRes()
		end, true, true)
		sceneNode:setErrorCallback(function()
			self:removeDownloaderSubRes()
		end)
		sceneNode:setPosition(display.center)
		sceneWorld:addChild(sceneNode, GameSceneTag.Dowloader_GameSceneTag, GameSceneTag.Dowloader_GameSceneTag)
	end
	return sceneNode
end
function UIManager:removeDownloaderSubRes()
	local sceneNode = sceneWorld:getChildByTag(GameSceneTag.Dowloader_GameSceneTag)
    if sceneNode then
        sceneWorld:removeChild(sceneNode, true)
	end
end


function UIManager:showGameStores(args)
	local gameStoresMdt = app:RetrieveMediator('GameStoresMediator')
	if gameStoresMdt then
		if args and args.storeType then
			gameStoresMdt:setSelectedType(args.storeType)
		end
	else
		gameStoresMdt = require('Game.mediator.stores.GameStoresMediator').new(args)
		app:RegistMediator(gameStoresMdt)
	end

end
function UIManager:showDiamonTips(diamonPrice, isOnlyDiamonStore, closeTipsCb)
	local useDiamond = checkint(diamonPrice)
	local hasDiamond = CommonUtils.GetCacheProductNum(DIAMOND_ID)
	if diamonPrice == nil or hasDiamond < useDiamond then
		local tipString = __('当前幻晶石不足，是否去商城购买？')
		local commonTip = require('common.NewCommonTip').new({text = tipString, callback = function()
			if closeTipsCb then closeTipsCb() end
			self:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND, isOnlyDiamon = isOnlyDiamonStore})
		end, isOnlyOK = true, btnTextR = __('去商城')})
		commonTip:setPosition(display.center)
		self:GetCurrentScene():AddDialog(commonTip)
		return true
	else
		return false
	end
end
function UIManager:showRealNameAuthView(text , otherAuthor  )
	local idNo = app.gameMgr:GetUserInfo().idNo
	if (not otherAuthor) and  string.len(idNo) > 0 then
		local downChineseVoiceFile = require("Game.mediator.DownChineseVoiceFile").GetInstance()
		downChineseVoiceFile:SetStopDownload()
		if  GuideUtils.GetDirector():IsInGuiding() then
			local stage =  GuideUtils.GetDirector():GetStage()
			if stage and (not tolua.isnull(stage)) then
				stage:RemoveTouchEvent()
				app.gameMgr:ShowExitGameView(text , true , function()
					stage:RecoverTouchEvent()
				end)
			else
				app.gameMgr:ShowExitGameView(text , true)
			end
		else
			app.gameMgr:ShowExitGameView(text , true)
		end
	elseif otherAuthor and string.len(idNo) > 0 then
		local CommonTip  = require( 'common.NewCommonTip' ).new({text = text , isOnlyOK = true ,cb = function()

		end})
		CommonTip:setPosition(display.center)
		app.uiMgr:Scene():addChild(CommonTip, GameSceneTag.BootLoader_GameSceneTag , GameSceneTag.ExitGameView_GameSceneTag)
	else
		local canClose = otherAuthor and 1 or nil
		-- 没有认证的话 引导认证
		local mediator = require("Game.mediator.RealNameAuthenicationMediator").new({canClose = canClose })
		app:RegistMediator(mediator)
	end
end

function UIManager:showModuleGuide(guideName)
	local guideNode = require('common.GuideNode').new({tmodule = guideName})
    sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
end


function UIManager:showErrorTips()
	if DEBUG == 0 then return end
	
	if sceneWorld:getChildByTag(GameSceneTag.ERROR_TIPS_GameSceneTag) == nil then
		local tipsLayer = CLayout:create(display.size)
		tipsLayer:setPosition(display.center)
		sceneWorld:addChild(tipsLayer, GameSceneTag.ERROR_TIPS_GameSceneTag, GameSceneTag.ERROR_TIPS_GameSceneTag)

		local GAP = 25
		local posList = {
			cc.p(GAP, GAP),
			cc.p(GAP, display.height - GAP),
			cc.p(display.width - GAP, display.height - GAP),
			cc.p(display.width - GAP, GAP),
		}
		for index, value in ipairs(posList) do
			local tipsImg = CImageView:create('ui/common/common_btn_warning.png')
			tipsImg:setPosition(value)
			tipsLayer:addChild(tipsImg)
		end
	end

	local tipsLayer = sceneWorld:getChildByTag(GameSceneTag.ERROR_TIPS_GameSceneTag)
	tipsLayer:stopAllActions()
	tipsLayer:runAction(cc.Repeat:create(cc.Sequence:create(
		cc.FadeIn:create(0.5),
		cc.FadeOut:create(0.5)
	), 10))
end


--@see common.RewardPopup
function UIManager:showRewardPopup(args)
	self:AddDialog('common.RewardPopup', args)
end


return UIManager
