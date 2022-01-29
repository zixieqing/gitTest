--[[
好友头像node
@params {
	callback funtion 返回按钮回调
	showLevel bool 是否显示等级
	level int 玩家等级
	scale int 缩放
	isGray bool 是否去色	
}
--]]
local FriendHeadNode = class('FriendHeadNode', function ()
	local node = CButton:create()
	node.name = 'common.FriendHeadNode'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function FriendHeadNode:ctor( ... )
	self.args = unpack({...})
	self.viewData = nil
	self.callback = self.args.callback
	if self.args.showLevel ~= nil then
		self.showLevel = self.args.showLevel
	else
		self.showLevel = true
	end
	self.level = checkint(self.args.level or 1)
	self.scale = tonumber(self.args.scale or 1)
	self.isGray = self.args.isGray or false
	self.avatar = self.args.avatar or ''
	self.avatarFrame = self.args.avatarFrame or ''
	if self.args.enable ~= nil then
		self.enable = self.args.enable
	else
		self.enable = true
	end
	self:initUI()
	-- 绑定点击回调
	if self.callback then
		self:setTouchEnabled(true)
		self:setOnClickScriptHandler(function (sender)
	    	local isFlipX = sender:getScaleX() < 0
	        local fScale  = math.abs(sender:getScaleX())
	        if isFlipX then
	            fScale = 1.0
	        end
	        transition.execute(sender,cc.Sequence:create(
	            cc.EaseOut:create(cc.ScaleTo:create(0.03, (isFlipX and -1 or 1) * 0.97*fScale, 0.97*fScale), 0.03),
	            cc.EaseOut:create(cc.ScaleTo:create(0.03, (isFlipX and -1 or 1) * 1*fScale, 1*fScale), 0.03),
	            cc.CallFunc:create(function()
	                self.callback(sender)
	            end)
	        ))	
		end)
	end
	-- 去色
	if self.isGray ~= nil then
		self:SetGray(self.isGray)
	end
end
function FriendHeadNode:initUI()
	-- bg
	-- local bg = FilteredSpriteWithOne:create(_res('ui/common/create_roles_head_down_default.png'))
	local bgSize = cc.size(134, 134)
	self:setContentSize(bgSize)
	-- display.commonUIParams(bg, {po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5)})
	-- self:addChild(bg, 1)

 	local headIcon = require('root.CCHeaderNode').new({tsize = bgSize, pre = self.avatarFrame or 500077, url = self.avatar})
    display.commonUIParams(headIcon,{po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5)})
    self:addChild(headIcon,2)
	-- local headIcon = FilteredSpriteWithOne:create(_res("ui/common/common_role_female.png"))
	-- display.commonUIParams(headIcon, {po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5)})
	-- self:addChild(headIcon, 2)

	-- local frame = FilteredSpriteWithOne:create()
	-- display.commonUIParams(frame, {po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5)})
	-- self:addChild(frame , 5)

	local levelBg = FilteredSpriteWithOne:create(_res('ui/home/friend/friends_bg_level.png'))
	display.commonUIParams(levelBg, {po = cc.p(bgSize.width - 4, 4), ap = cc.p(1, 0)})
	self:addChild(levelBg, 3)

	local levelLabel = display.newLabel(levelBg:getContentSize().width/2, levelBg:getContentSize().height/2, fontWithColor(9, {text = self.level}))
	levelBg:addChild(levelLabel)

	levelBg:setVisible(self.showLevel)

	if self.scale ~= 1 then
		if self.scale <= 1 then
			self:setScale(self.scale)
			levelBg:setScale(1/self.scale)
		else
			self:setScale(self.scale)
		end
	end

	self:setEnabled(self.enable)
	self.viewData = {
		bg         = bg,
		headIcon   = headIcon, 
		frame      = frame,
		levelBg    = levelBg,
		levelLabel = levelLabel
	}
end
--[[
灰化
@params isGray bool 是否灰化
--]]
function FriendHeadNode:SetGray( isGray )
	if isGray then
		if nil == self.grayFilter then
			self.grayFilter = GrayFilter:create()
		end
		-- 逐个子节点设置灰化
		-- self.viewData.bg:setFilter(self.grayFilter)
		self.viewData.headIcon:SetGray(true)
		-- self.viewData.headIcon:setFilter(self.grayFilter)
		-- self.viewData.frame:setFilter(self.grayFilter)
		self.viewData.levelBg:setFilter(self.grayFilter)
	else
		-- 逐个子节点清除灰化
		-- self.viewData.bg:clearFilter()
		self.viewData.headIcon:SetGray(false)
		-- self.viewData.headIcon:clearFilter()
		-- self.viewData.frame:clearFilter()
		self.viewData.levelBg:clearFilter()
		self.grayFilter = nil 
	end
end
function FriendHeadNode:RefreshSelf( datas )
	if datas.showLevel ~= nil then
		self.viewData.levelBg:setVisible(datas.showLevel)
	end
	if checkint(datas.level) ~= 0 then
		self.viewData.levelLabel:setString(datas.level)
	end
	if datas.avatar then
		self.viewData.headIcon.headerSprite:setWebURL(datas.avatar)
	end
	-- if datas.avatarFrame then
		self.viewData.headIcon:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(datas.avatarFrame)))
	-- end
	if datas.isGray ~= nil then
		self:SetGray(datas.isGray)
	end
end

return FriendHeadNode