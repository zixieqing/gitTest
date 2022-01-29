--[[
头像node
--]]
local HeaderNode = class('HeaderNode', function ()
	local node = CLayout:create()
	node.name = 'common.HeaderNode'
	node:enableNodeEvents()
	return node
end)
function HeaderNode:ctor( ... )
	self.args = unpack({...})
    self.hasBox = true
    if self.args.hasBox ~= nil then
        self.hasBox = self.args.hasBox
    end
	self:initUI()
end

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function HeaderNode:initUI()
	-- bg
	local bg = display.newImageView(_res('ui/common/common_bg_hend_frame_blue.png'), 0, 0)
	local bgSize = bg:getContentSize()
	self:setContentSize(bgSize)
	display.commonUIParams(bg, {po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5)})
	self.bg = bg
	self:addChild(bg)
	-- self:setBackgroundColor(cc.c4b(200, 0, 0, 100))
	-- box
    if self.hasBox then
        local headBox = display.newImageView(_res('ui/common/main_frame_head_orange.png'), bgSize.width * 0.5, bgSize.height * 0.5)
        self:addChild(headBox, 10)
    end

	--headIcon
    local cardData = {}
    if (not self.args) then
        local cardInfo = AppFacade.GetInstance():GetManager("GameManager"):GetCaptainCardInfoByTeamId(1)
		if cardInfo then
			cardData = cardInfo
		else
            cardData.cardId = 200013
        end
    else
        cardData.cardId = 200013
    end
	local skinId   = cardMgr.GetCardSkinIdByCardId(cardData.cardId)
    local drawPath = CardUtils.GetCardHeadPathBySkinId(skinId)
	self.headIcon = display.newImageView(drawPath, bgSize.width * 0.5, bgSize.height * 0.5)
	self.headIcon:setScale(0.5)
	self:addChild(self.headIcon, 11)

	local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
	local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
	if cardMgr.GetCouple(gameMgr:GetCardDataByCardId(cardData.cardId).id) then
		if self.particleSpine then
			self.particleSpine:setVisible(true)
		else
			local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly_tx')
			-- particleSpine:setTimeScale(2.0 / 3.0)
			particleSpine:setPosition(cc.p(bgSize.width * 0.5, bgSize.height * 0.5))
			self:addChild(particleSpine,11)
			particleSpine:setAnimation(0, 'idle3', true)
			particleSpine:update(0)
			particleSpine:setToSetupPose()
			particleSpine:setScale(0.6)

			self.particleSpine = particleSpine
		end
	else
		if self.particleSpine then
			self.particleSpine:setVisible(false)
		end
	end
end

function HeaderNode:updateImageView(cardId)
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
    self.headIcon:setTexture(drawPath)

	local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
	local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
	if cardMgr.GetCouple(gameMgr:GetCardDataByCardId(cardData.cardId).id) then
		if self.particleSpine then
			self.particleSpine:setVisible(true)
		else
			local bgSize = self.bg:getContentSize()
			local particleSpine =display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly_tx')
			-- particleSpine:setTimeScale(2.0 / 3.0)
			particleSpine:setPosition(cc.p(bgSize.width * 0.5, bgSize.height * 0.5))
			self:addChild(particleSpine,11)
			particleSpine:setAnimation(0, 'idle3', true)
			particleSpine:update(0)
			particleSpine:setToSetupPose()
			particleSpine:setScale(0.6)

			self.particleSpine = particleSpine
		end
	else
		if self.particleSpine then
			self.particleSpine:setVisible(false)
		end
	end
end

return HeaderNode
