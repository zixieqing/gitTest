--[[
头像node
--]]
---@class ProfileNode
local ProfileNode = class('ProfileNode', function ()
	local node = CLayout:create()
	node.name = 'common.ProfileNode'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function ProfileNode:ctor( ... )
	self.args = unpack({...})
	self.viewData = nil
	self:initUI()
end
function ProfileNode:initUI()
	-- bg
	local size = cc.size(310, 110)
	self:setContentSize(size)
	local swallowLayer = ui.layer({x = size.width/2 , y = size.height/2 , ap = ui.cc, size = size,  enable = true, color = cc.c4b(0,0,0,0)})
	self:addChild(swallowLayer,20)
	local animate = self.args.animate or false
	display.commonUIParams(swallowLayer , {cb = self.args.cb , animationNode = animate and self })
	local bg = display.newImageView(_res('ui/home/nmain/main_ico_player_frame.png'), -60, size.height, {ap = display.LEFT_TOP})
	self:addChild(bg, 4)
	-- self:setBackgroundColor(cc.c4b(200, 0, 0, 100))
	-- box
	local headBox = display.newImageView(_res('ui/home/nmain/main_bg_player.png'), 54, size.height * 0.5)
	headBox:setScale(1.1)
	self:addChild(headBox,10)
	---@type CCHeaderNode
	local headIcon = nil
	if not  self.args.isTop then
		headIcon = require('root.CCHeaderNode').new({tsize = cc.size(110,110) })
		display.commonUIParams(headIcon,{po = cc.p(54, size.height * 0.5)})
		self:addChild(headIcon,2)
	else
		local data = {}
		local scale = 0.7
		local po = cc.p(54, size.height * 0.5)
		if self.args.pre and  self.args.pre ~= "" then
			data.pre = self.args.pre
			scale = 0.55

		else
			data.bg = _res('ui/home/infor/setup_head_bg_2.png')
			data.isPre = true
			scale = 0.67
			po.x =  56
		end
		-- dump(data)
		headIcon = require('root.CCHeaderNode').new(data)
		display.commonUIParams(headIcon,{po = po})
		self:addChild(headIcon,10)
		headIcon:setScale(scale)
		headIcon:SetTouchEnabled(false)
	end

	local nameLabel = display.newLabel(195, 84,
			{text = gameMgr:GetUserInfo().playerName, fontSize = 20, color = '47322'})
	self:addChild(nameLabel,5)

	local lvLabel = display.newLabel(126, 20, {text = string.format('%d', checkint(gameMgr:GetUserInfo().level)), fontSize = 18, color = 'ffffff'})
	self:addChild(lvLabel, 5)
	self.viewData = {
		headIcon = headIcon,
		nameLabel = nameLabel,
		lvLabel   = lvLabel,
	}
end

function ProfileNode:updateImageView(cardId)
	local cardData = {}
	if not cardId then
		local cardInfo = AppFacade.GetInstance():GetManager("GameManager"):GetCaptainCardInfoByTeamId(1)
		if cardInfo then
			cardData = cardInfo
		else
			cardData.cardId = 200013
		end
	else
		cardData.cardId = cardId
	end
	local skinId   = cardMgr.GetCardSkinIdByCardId(cardData.cardId)
    local drawPath = CardUtils.GetCardHeadPathBySkinId(skinId)
	self.viewData.headIcon:setTexture(drawPath)

end

return ProfileNode
