--[[
包厢主题
--]]
local PriviateRoomThemeNode = class('PriviateRoomThemeNode', function ()
    local node = CLayout:create(cc.size(1334, 1002))
    node.name = 'home.PriviateRoomThemeNode'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
	DEFAULT_THEME        = _res('avatar/privateRoom/wallpaper_330001.jpg'),
	WALL_BG  	 	 	 = _res('avatar/privateRoom/frame_330001.png'),
	MENU_LABEL_TITLE_BG  = _res('ui/privateRoom/vip_main_label_menu.png'),
}
function PriviateRoomThemeNode:ctor( ... )
    self.args = unpack({...})
    self.themeId = nil
    self:InitUI()
end
--[[
init ui
--]]
function PriviateRoomThemeNode:InitUI()
    local function CreateView()
        local size = cc.size(1334, 1002)
        local view = CLayout:create(size)
		-- bgLayout
		local bgLayoutSize = cc.size(1334, 1002)
		local bgLayout = CLayout:create(bgLayoutSize)
		bgLayout:setPosition(cc.p(size.width / 2, size.height / 2))
		view:addChild(bgLayout, 5)
		-- 主题背景
		local themeBg = display.newImageView(RES_DICT.DEFAULT_THEME, bgLayoutSize.width / 2, bgLayoutSize.height / 2)
		bgLayout:addChild(themeBg, 1)
		-- 陈列墙
		local wallLayoutSize = size
		local wallLayout = CLayout:create(wallLayoutSize)
		wallLayout:setPosition(cc.p(size.width / 2, size.height / 2))
		view:addChild(wallLayout, 5)
		local wallView = require('Game.views.privateRoom.PrivateRoomWallView').new()
		wallLayout:addChild(wallView, 1)
		wallView:setAnchorPoint(cc.p(0, 0))
		wallView:setScale(0.5)
		wallView:setPosition(cc.p(530, 495))
		local wallBg = display.newButton(497, 485, {n = RES_DICT.WALL_BG, ap = cc.p(0, 0)})
		wallLayout:addChild(wallBg, 5)
		-- avatarLayout 
		local avatarLayoutSize = cc.size(1334, 1002)
		local avatarLayout = CLayout:create(avatarLayoutSize)
		avatarLayout:setPosition(cc.p(size.width / 2, size.height / 2))
		view:addChild(avatarLayout, 5)
        return {
            view             = view,
            bgLayout         = bgLayout,
            wallLayout       = wallLayout,
            avatarLayout     = avatarLayout,
            wallView         = wallView,
			wallBg           = wallBg,
			themeBg   	 	 = themeBg,
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
		self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
end
--[[
设置主题
@params themeId int 主题id
--]]
function PriviateRoomThemeNode:SetTheme( themeId )
	if not themeId or CommonUtils.GetGoodTypeById(themeId) ~= GoodsType.TYPE_PRIVATEROOM_THEME then return end
    self.themeId = themeId
	local themeConf = CommonUtils.GetConfig('privateRoom', 'avatarTheme', themeId)
	self.viewData.avatarLayout:removeAllChildren()
    local avatars = nil
    for i, v in ipairs(checktable(themeConf.avatars)) do
		local nodes = self:SetThemeAvatar(v, bgLayout, avatarLayout)
		if nodes then
			avatars = nodes
        end
	end
	-- 纪念品
	local putThings = self:AddPutThings(avatars[1])
    -- 菜单
	local menuBtn = self:AddMenuBtn(avatars[1])
	return {
		avatars = avatars, 
		menuBtn = menuBtn,
		putThings = putThings,
	}
end
--[[
设置主题相关avatar
@params avatarId int avatarId
--]]
function PriviateRoomThemeNode:SetThemeAvatar( avatarId )
	local avatarPosConf = CommonUtils.GetConfig('privateRoom', 'avatarLocation', avatarId)
	if not avatarPosConf then return end
	if checkint(avatarPosConf.type) ==  1 then -- avatar
		local avatars = self:AddTableAvatar(avatarId, avatarLayout)
		return avatars
	elseif checkint(avatarPosConf.type) ==  2 then -- 陈列墙背景
		local pos = app.privateRoomMgr:GetAvatarLocation(avatarPosConf.location[1])
		self.viewData.wallBg:setPosition(pos)
		self.viewData.wallBg:setNormalImage(string.format('avatar/privateRoom/frame_%s.png', avatarPosConf.themeId))
		self.viewData.wallBg:setSelectedImage(string.format('avatar/privateRoom/frame_%s.png', avatarPosConf.themeId))
	elseif checkint(avatarPosConf.type) ==  3 then -- 背景
		self.viewData.themeBg:setTexture(string.format('avatar/privateRoom/wallpaper_%s.jpg', avatarPosConf.themeId))
	end
end
--[[
添加餐桌avatar
@params avatarId int avatarId
@return avatars list 添加的avatar
--]]
function PriviateRoomThemeNode:AddTableAvatar( avatarId)
    local avatarLayout = self.viewData.avatarLayout
	local avatarPosConf = CommonUtils.GetConfig('privateRoom', 'avatarLocation', avatarId)
	if not avatarPosConf then return end
    local avatars = {}
	local location = app.privateRoomMgr:GetAvatarLocation(avatarPosConf.location[1])
	local avatar = display.newImageView(_res(string.format('avatar/privateRoom/table_%d.png', avatarPosConf.themeId)), location.x, location.y, {ap = cc.p(0, 0)})
	avatarLayout:addChild(avatar, 5)
	table.insert(avatars, avatar)
	for i, v in ipairs(checktable(avatarPosConf.additions)) do
		local addition = display.newImageView(_res(string.format('avatar/privateRoom/table_%s.png', v.additionId)), location.x, location.y, {ap = cc.p(0, 0)})
		table.insert(avatars, addition)
		avatarLayout:addChild(addition, 3)
	end
	return avatars
end
--[[
添加纪念品
--]]
function PriviateRoomThemeNode:AddPutThings( tableAvatar )
	local putThingConf = app.privateRoomMgr:GetDishPutPos(self.themeId)
	local putThings = {}
	for i, v in ipairs(putThingConf) do
		local img = display.newImageView(_res(string.format('avatar/privateRoom/%s', v.thingId)), v.x, v.y)
		tableAvatar:addChild(img, 1024 - v.y)
		table.insert(putThings, img)
	end
	return putThings
end
--[[
添加菜单
--]]
function PriviateRoomThemeNode:AddMenuBtn( tableAvatar )
	local tablePos = app.privateRoomMgr:GetDishPutPos(self.themeId)[1]
	local worldPos = tableAvatar:convertToWorldSpace(cc.p(tablePos.x, tablePos.y))
	local nodePos = self.viewData.avatarLayout:convertToNodeSpace(worldPos)
    local btnSize = cc.size(150, 200)
    local menuBtn = display.newButton(nodePos.x, nodePos.y, {n = 'empty', size = btnSize, ap = cc.p(0.5, 0)})
	self.viewData.avatarLayout:addChild(menuBtn, 20)
    local menuSpine = sp.SkeletonAnimation:create(
        'ui/privateRoom/effect/vip_caidan.json',
        'ui/privateRoom/effect/vip_caidan.atlas',
        1)
    menuSpine:update(0)
    menuSpine:setToSetupPose()
    menuSpine:setAnimation(0, 'idle', true)
	menuSpine:setPosition(cc.p(btnSize.width / 2, btnSize.height / 2))
	menuSpine:setName('spine')
    menuBtn:addChild(menuSpine, 1)
    menuBtn:setVisible(false)
	local clickBg = display.newImageView(RES_DICT.MENU_LABEL_TITLE_BG, btnSize.width / 2, 20)
	menuBtn:addChild(clickBg, 10)
	local clickLabel = display.newLabel(clickBg:getContentSize().width / 2, clickBg:getContentSize().height / 2, {text = __('点击菜单'), fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#744427', outlineSize = 2})
	menuBtn:addChild(clickLabel, 10)
	return menuBtn
end
--[[
刷新陈列墙
@params wallData map 纪念品数据
--]]
function PriviateRoomThemeNode:RefreshWall( wallData )
	self.viewData.wallView:RefreshWall(wallData)
end
--[[
设置陈列墙是否可以点击
--]]
function PriviateRoomThemeNode:SetWallEnabled( isEnabled )
	self.viewData.wallBg:setEnabled(false)
	self.viewData.wallView:SetSouvenirsEnabled(false)
end
return PriviateRoomThemeNode