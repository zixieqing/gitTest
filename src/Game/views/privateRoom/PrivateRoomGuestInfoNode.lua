local VIEW_SIZE = cc.size(260, 316)
local PrivateRoomGuestInfoNode = class('PrivateRoomGuestInfoNode', function ()
    local node = CLayout:create(VIEW_SIZE)
    -- node:setBackgroundColor(cc.c4b(23, 67, 128, 128))
	node.name = 'Game.views.privateRoom.PrivateRoomGuestInfoNode'
	node:enableNodeEvents()
	return node
end)


local RES_DIR = {
    NPC_NAME         =  _res("ui/privateRoom/guestInfo/vip_handbook_btn_npc_name.png"),
    NPC_BG_UNLOCK    =  _res("ui/privateRoom/guestInfo/vip_handbook_btn_npc_unlock.png"),
    NPC_BG           =  _res("ui/privateRoom/guestInfo/vip_handbook_btn_npc.png"),
    PROGRESS_1       =  _res("ui/privateRoom/guestInfo/vip_handbook_line_1.png"),
    PROGRESS_2       =  _res("ui/privateRoom/guestInfo/vip_handbook_line_2.png"),
    ICO_UNKOWN       =  _res('ui/home/handbook/compose_ico_unkown.png'),
    RED_IMG          = _res('ui/common/common_ico_red_point.png'),
}

local CreateView = nil

function PrivateRoomGuestInfoNode:ctor( ... )
    self.args = unpack({...}) or {}
    -- self.grayFilter = GrayFilter:create()
    self:initialUI()
end

function PrivateRoomGuestInfoNode:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)

        self:initView()
	end, __G__TRACKBACK__)
end

function PrivateRoomGuestInfoNode:initView()
    
end

function PrivateRoomGuestInfoNode:refreshUI(data, count)
    if data == nil then
        return 
    end
    local viewData = self:getViewData()
    local bg              = viewData.bg
    local progressBar     = viewData.progressBar
    local questionMarkImg = viewData.questionMarkImg
    local nameLabel       = viewData.nameLabel
    local icon            = viewData.icon
    local spineLayer      = viewData.spineLayer
    
    local guestConf       = data.guestConf or {}
    local storyCount      = checkint(data.storyCount)
    local guestsData      = data.guestsData or {}
    local isUnlock        = data.isUnlock
    
    local nameBg          = viewData.nameBg
    local openRestaurantLevel = checkint(guestConf.openRestaurantLevel)
    local restaurantLevel     = app.gameMgr:GetUserInfo().restaurantLevel
    
    local isDrawn = checkint(guestsData.hasDrawn) > 0
    local dialogues = guestsData.dialogues or {}
    local value = math.min(table.nums(dialogues), storyCount)
    local isSatisfyProgress = value >= storyCount
    if isUnlock then

        if isSatisfyProgress then
            icon:clearFilter()
        else
            icon:setFilter(GrayFilter:create())
        end

        if not isDrawn then
            progressBar:setMaxValue(storyCount)
            progressBar:setValue(value)
        end
        icon:setTexture(CommonUtils.GetGoodsIconPathById(guestConf.giftId or 340001))
        bg:setTexture(RES_DIR.NPC_BG)
        progressBar:setVisible(not isDrawn)
        display.commonLabelParams(nameLabel, {text = tostring(guestConf.name)})
    else
        bg:setTexture(RES_DIR.NPC_BG_UNLOCK)
        progressBar:setVisible(false)
        
        display.commonLabelParams(nameLabel, {text = '? ? ?'})
    end

    self:updateSpine(spineLayer, guestConf.id)

    -- self:updateRedPointState(not isDrawn and isSatisfyProgress)
    
    icon:setVisible(isUnlock)
    questionMarkImg:setVisible(not isUnlock)
    nameBg:setVisible(isUnlock)
end

function PrivateRoomGuestInfoNode:updateSpine(parent, spineId)
    if parent:getChildrenCount() then
        parent:removeAllChildren()
    end
    local spineLayrSize = parent:getContentSize()
    local pathPrefix = string.format("avatar/visitors/%s", spineId)
    local spine = sp.SkeletonAnimation:create(string.format("%s.json", pathPrefix),string.format('%s.atlas', pathPrefix), 0.55)
    spine:setToSetupPose()
    spine:setPosition(cc.p(spineLayrSize.width / 2 + 5, spineLayrSize.height / 2 - 130  + 5))
    -- spine:setAnimation(0, 'idle', false)
    parent:addChild(spine)
end

function PrivateRoomGuestInfoNode:updateRedPointState(isShow)
    local viewData    = self:getViewData()
    local redPointImg = viewData.redPointImg
    redPointImg:setVisible(isShow)
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size, ap = display.LEFT_BOTTOM})

    local bgSize = cc.size(251, 298)
    local bgLayer = display.newLayer(size.width / 2, size.height / 2, {size = bgSize, ap = display.CENTER})
    view:addChild(bgLayer)

    local touchView = display.newLayer(bgSize.width / 2, bgSize.height / 2, {color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER, size = bgSize})
    bgLayer:addChild(touchView)

    local bg = display.newImageView(RES_DIR.NPC_BG_UNLOCK, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER})
    bgLayer:addChild(bg)
    
    local progressBar = CProgressBar:create(RES_DIR.PROGRESS_2)
    display.commonUIParams(progressBar, {po = cc.p(bgSize.width / 2, bgSize.height - 24), ap = display.CENTER})
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setBackgroundImage(RES_DIR.PROGRESS_1)
	progressBar:setShowValueLabel(true)
	-- progressBar:setVisible(false)
	display.commonLabelParams(progressBar:getLabel(),fontWithColor('9'))
    bgLayer:addChild(progressBar, 1)
    
    local icon = FilteredSpriteWithOne:create()
    display.commonUIParams(icon, {po = cc.p(bgSize.width - 30, bgSize.height - 28), ap = display.CENTER})
    icon:setScale(0.3)
    bgLayer:addChild(icon, 1)

    local iconTouchVieww = display.newLayer(bgSize.width - 30, bgSize.height - 28, 
        {ap = display.CENTER, enable = true, size = cc.size(40,40), color = cc.c4b(0,0,0,0)})
    bgLayer:addChild(iconTouchVieww, 1)

    -- local redPointImg = display.newImageView(RES_DIR.RED_IMG, bgSize.width - 15, bgSize.height - 18, 
    --     {ap = display.CENTER})
    -- bgLayer:addChild(redPointImg, 1)
    -- redPointImg:setScale(0.8)
    -- redPointImg:setVisible(false)

    local spineLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2,
         {ap = display.CENTER, size = bgSize})
    bgLayer:addChild(spineLayer)

    -- question mark
    local questionMarkImg = display.newImageView(RES_DIR.ICO_UNKOWN, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER})
    bgLayer:addChild(questionMarkImg)

    local nameBg = display.newImageView(RES_DIR.NPC_NAME, bgSize.width / 2 -  1, 11, {ap = display.CENTER_BOTTOM})
    bgLayer:addChild(nameBg, 1)

    local nameLabel = display.newLabel(bgSize.width / 2, 27, fontWithColor(18, {text = '? ? ?',ap = display.CENTER}))
    bgLayer:addChild(nameLabel, 1)

    return {
        view            = view,
        bg              = bg,
        touchView       = touchView,
        progressBar     = progressBar,
        questionMarkImg = questionMarkImg,
        icon            = icon,
        iconTouchVieww  = iconTouchVieww,
        spineLayer      = spineLayer,
        -- redPointImg     = redPointImg,
        nameBg          = nameBg,
        nameLabel       = nameLabel,
    }
end

function PrivateRoomGuestInfoNode:getViewData()
    return self.viewData_
end

return PrivateRoomGuestInfoNode