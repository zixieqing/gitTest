--[[
工会弹劾成功弹窗
@params {
    feedPetLog list 数据
}
--]]
local UnionImpeachmentSuccessView = class('UnionImpeachmentSuccessView', function ()
	local clb = CLayout:create(display.size)
    clb.name = 'union.UnionImpeachmentSuccessView'
    clb:enableNodeEvents()
    return clb
end)

------------ import ------------

------------ import ------------

------------ define ------------
local CreateView = nil
local RES_DICT = {
    REWARDS_LIGHT       = _res('ui/common/common_reward_light.png'),
    REWARDS_TITLE       = _res('ui/union/roll/party_roll_reward_words.png'),
    COMMON_BTN_ORANGE   =  _res('ui/common/common_btn_orange.png')
}
------------ define ------------

function UnionImpeachmentSuccessView:ctor(...)
    self.args = unpack({...}) or {}
    self:InitialUI()
end
function UnionImpeachmentSuccessView:InitialUI()

    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
    end, __G__TRACKBACK__)

    self:InitView()
    self:RefreshUI(self.args)
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------

function UnionImpeachmentSuccessView:InitView()
    local viewData = self:GetViewData()
    display.commonUIParams(viewData.backBtn, {cb = handler(self, self.OnClickBackBtnAction), animate = false})
end

--[[
刷新界面
@params data list 数据
--]]
function UnionImpeachmentSuccessView:RefreshUI(data)
    local impeachmentData = data.impeachmentData or {}
    local unionPresidentPlayerId = checkint(impeachmentData.unionPresidentPlayerId)
    local member = data.member or {}
    local playerInfo
    for index, value in ipairs(member) do
        if checkint(value.playerId) == unionPresidentPlayerId then
            playerInfo = value
            break
        end 
    end

    local viewData = self:GetViewData()
    local playerHeadNode  = viewData.playerHeadNode
    local playerNameLabel = viewData.playerNameLabel
    if playerInfo then
        playerHeadNode:RefreshUI({
            avatar = playerInfo.playerAvatar,
            avatarFrame = playerInfo.playerAvatarFrame,
            playerLevel = playerInfo.playerLevel,
        })
        display.commonLabelParams(playerNameLabel, {text = tostring(playerInfo.playerName)})
    end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------


CreateView = function ()
    local view = display.newLayer()

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,130)})
    view:addChild(blockBg)

    -- light img
    local lightImg = display.newImageView(RES_DICT.REWARDS_LIGHT, display.cx, display.cy + 130)
    view:addChild(lightImg)

    -- title label
    local titleLabel = display.newLabel(display.cx, lightImg:getPositionY() + 60, fontWithColor(20, {ap = display.CENTER, color = '#ffeaa1', outline = '#622100', text = __('会长变更')}))
    view:addChild(titleLabel)

    -- add spine cache
    local rewardsSpinePath = 'effects/rewardgoods/skeleton'
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(rewardsSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(rewardsSpinePath, rewardsSpinePath, 1)
    end

    -- -- create rewards spine
    local rewardsSpine = SpineCache(SpineCacheName.UNION):createWithName(rewardsSpinePath)
    rewardsSpine:setPosition(display.center)
    view:addChild(rewardsSpine)

    -- union president Info
    local tipLabel = display.newLabel(titleLabel:getPositionX(), display.cy + 90, fontWithColor(7, {fontSize = 22, text = __('新会长')}))
    view:addChild(tipLabel)

    local playerHeadNodeScale = 0.85
    local playerHeadNode = require('common.PlayerHeadNode').new({
        avatar = 1,
        avatarFrame = 500143,
        playerLevel = 33,
        showLevel = false,
        defaultCallback = true
    })
    display.commonUIParams(playerHeadNode, {po = cc.p(
        titleLabel:getPositionX(),
        display.cy
    )})
    playerHeadNode:setScale(playerHeadNodeScale)
    -- playerHeadNode:
    view:addChild(playerHeadNode)

    local playerNameLabel = display.newLabel(0, 0, fontWithColor(18))
    display.commonUIParams(playerNameLabel, {ap = cc.p(0.5, 1), po = cc.p(
        playerHeadNode:getPositionX(),
        playerHeadNode:getPositionY() - playerHeadNode:getContentSize().height * 0.5 * playerHeadNodeScale - 8
    )})
    view:addChild(playerNameLabel)

    local backBtn = display.newButton(display.cx, display.cy - 200,
	{
		ap = display.CENTER,
		n = RES_DICT.COMMON_BTN_ORANGE,
		scale9 = true, size = cc.size(123, 62),
		enable = true,
	})
	display.commonLabelParams(backBtn, fontWithColor(14, {text = __('确认')}))
	view:addChild(backBtn)

    return {
        view            = view,
        blockBg         = blockBg,
        backBtn         = backBtn,
        lightImg        = lightImg,
        rewardsSpine    = rewardsSpine,
        playerHeadNode  = playerHeadNode,
        playerNameLabel = playerNameLabel,
    }
end

---------------------------------------------------
-- get set begin --
---------------------------------------------------
function UnionImpeachmentSuccessView:GetViewData()
    return self.viewData_
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

function UnionImpeachmentSuccessView:OnClickBackBtnAction(sender)
    self:setVisible(false)
    self:runAction(cc.RemoveSelf:create())
end

return UnionImpeachmentSuccessView
