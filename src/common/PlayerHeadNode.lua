--[[
玩家方形头像
@params table {
	playerId int 玩家id
	bg string 头像背景
	avatar string 头像图片url
	avatarFrame string 头像框
	showLevel bool 是否显示玩家等级
	playerLevel int 玩家等级
	callback function 点击回调
	defaultCallback bool 是否启用默认点击回调 默认点击回调弹出玩家信息框
}
--]]
---@class PlayerHeadNode : CLayout
local PlayerHeadNode = class('PlayerHeadNode', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.PlayerHeadNode'
	node:enableNodeEvents()
	-- print('PlayerHeadNode', ID(node))
	return node
end)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local WebSprite = lrequire('root.WebSprite')
local CCHeaderNode = require('root.CCHeaderNode')
------------ import ------------

--[[
constructor
--]]
function PlayerHeadNode:ctor( ... )
	local args = unpack({...})
	self:InitValue(args or {})
	self:InitUI()
	if args and args.scale then
		self:setScale(args.scale or 1)
	end
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化参数
@params args table 参数列表
--]]
function PlayerHeadNode:InitValue(args)
	self.playerId = args.playerId
	self.avatar = args.avatar or args.url or ''
	self.avatarFrame = args.avatarFrame or ''
	self.bg = args.bg or 'ui/home/infor/setup_head_bg_2.png'
	if nil == self.showLevel and nil ~= args.showLevel then
		self.showLevel = args.showLevel
	elseif nil == self.showLevel then
		self.showLevel = false
	end
	self.playerLevel = checkint(args.playerLevel)

	self.callback = args.callback
	self.defaultCallback = nil ~= args.defaultCallback and args.defaultCallback or false
end
--[[
初始化头像ui
--]]
function PlayerHeadNode:InitUI()
	-- 头像node
	local headNode = CCHeaderNode.new({
		bg = _res(self.bg),
		url = self.avatar,
		pre = self.avatarFrame
	})
	local headNodeSize = headNode:getContentSize()
	self:setContentSize(headNodeSize)
	-- self:setBackgroundColor(cc.c4b(128, 218, 28, 100))

	display.commonUIParams(headNode, {po = cc.p(
		headNodeSize.width * 0.5,
		headNodeSize.height * 0.5
	)})
	self:addChild(headNode)
	self.headNode = headNode

	-- 等级
	local levelLabel = display.newLabel(0, 0, fontWithColor('14', {text = tostring(self.playerLevel), fontSize = 36}))
	display.commonUIParams(levelLabel, {ap = cc.p(1, 0), po = cc.p(
		headNodeSize.width - 10,
		10
	)})
	self:addChild(levelLabel, 21)
	levelLabel:setVisible(self.showLevel)

	self.levelLabel = levelLabel

	-- 点击回调
	local headBtn = display.newButton(0, 0, {size = headNodeSize, cb = handler(self, self.ClickHandler)})
	display.commonUIParams(headBtn, {po = utils.getLocalCenter(self)})
	self:addChild(headBtn)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- refresh begin --
---------------------------------------------------
--[[
刷新玩家头像
@params args table 参数信息
--]]
function PlayerHeadNode:RefreshUI(args)
	self:InitValue(args)
	if nil ~= args.showLevel then
		self.showLevel = args.showLevel == true
	end

	-- 刷新头像
	if self.headNode.headerSprite then
		self.headNode.headerSprite:setWebURL(self.avatar)
	end

	-- 刷新头像框
	self.headNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(self.avatarFrame or '')))

	-- 刷新玩家等级
	if self.showLevel and args.playerLevel then
		self.levelLabel:setString(tostring(args.playerLevel))
		self.levelLabel:setVisible(true)
	else
		self.levelLabel:setString('')
		self.levelLabel:setVisible(false)
	end
end
---------------------------------------------------
-- refresh end --
---------------------------------------------------

---------------------------------------------------
-- btn click handler begin --
---------------------------------------------------
--[[
头像点击回调
--]]
function PlayerHeadNode:ClickHandler(sender)
	if self.defaultCallback and self.playerId then
		PlayAudioByClickNormal()
		-- 弹出玩家信息框
		uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(self.playerId)})
	elseif self.callback then
		PlayAudioByClickNormal()
		self.callback()
	end
end
---------------------------------------------------
-- btn click handler end --
---------------------------------------------------

return PlayerHeadNode
