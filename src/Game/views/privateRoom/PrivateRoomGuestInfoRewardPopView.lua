--[[
包厢功能 贵宾信息列表 view
--]]
local VIEW_SIZE = display.size
local PrivateRoomGuestInfoRewardPopView = class('PrivateRoomGuestInfoRewardPopView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.privateRoom.PrivateRoomGuestInfoRewardPopView'
	node:enableNodeEvents()
	return node
end)


local CreateView  = nil
local CreateCell_ = nil


local RES_DIR = {
    BTN_ORANGE        = _res('ui/common/common_btn_orange.png'),
    COMMON_LIGHT      = _res('ui/common/common_light.png'),
    TITLE_LIGHT       = _res('ui/share/shop_skin_have_title_light.png'),
    MAKE_BG_ATTRIBUT  = _res('ui/home/kitchen/cooking_make_bg_attribute_promotion.png'),
}

function PrivateRoomGuestInfoRewardPopView:ctor( ... ) 
    
    self.args = unpack({...}) or {}

    self:initialUI()
end

function PrivateRoomGuestInfoRewardPopView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self:initView()
	end, __G__TRACKBACK__)
end

function PrivateRoomGuestInfoRewardPopView:initView()
    local viewData = self:getViewData()
    local makeSureBtn = viewData.makeSureBtn
    display.commonUIParams(makeSureBtn, {cb = handler(self, self.onClickMakeSureBtnAction)})

    self:refreshUI(self.args.goodsId or 340001)
end

function PrivateRoomGuestInfoRewardPopView:refreshUI(goodsId)
    local viewData = self:getViewData()
    local rewardIcon    = viewData.rewardIcon
    rewardIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))

    local conf = app.privateRoomMgr:GetGuestGiftConfByGoodsId(goodsId) or {}
    local nameLabel     = viewData.nameLabel
    display.commonLabelParams(nameLabel, {text = tostring(conf.name)})
    local descrLabel    = viewData.descrLabel
    display.commonLabelParams(descrLabel, {text = string.format( "%s %s", tostring(conf.descr), tostring(conf.conditionDescr))})
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    view:addChild(display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,200)}))

    local titleBg = display.newButton(size.width / 2, size.height / 2 + 270, {n = RES_DIR.TITLE_LIGHT})
    display.commonLabelParams(titleBg, fontWithColor(20, {color = '#fff4c3', outline = '#5b3c25', text = __('恭喜解锁')}))
    view:addChild(titleBg, 1)

    -- shine 
    local rewardShineScale = 0.52
    local rewardShine = display.newImageView(RES_DIR.COMMON_LIGHT, size.width  / 2, size.height  / 2 + 90)
    view:addChild(rewardShine)
    rewardShine:setScale(rewardShineScale)

    local rewardIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(340013), size.width  / 2, rewardShine:getPositionY())
    view:addChild(rewardIcon)
    rewardShine:setScale(rewardShineScale)

    local makeBgAttribute = display.newImageView(RES_DIR.MAKE_BG_ATTRIBUT, size.width / 2, size.height / 2 - 130 ,{size = cc.size(1000, 280) , scale9 = true })
    makeBgAttribute:setScale(0.7)
    view:addChild(makeBgAttribute)

    local nameLabel = display.newLabel(size.width / 2, size.height / 2 - 60, fontWithColor(7, {ap = display.CENTER, fontSize = 28, color = '#ffcb4f', text = '测试'}))
    view:addChild(nameLabel)

    local descrLabel = display.newLabel(size.width / 2, size.height / 2 - 80, fontWithColor(18, {ap = display.CENTER_TOP, w = 650, hAlign = display.TAL}))
    view:addChild(descrLabel)

    local makeSureBtn = display.newButton(size.width / 2, size.height / 2 - 270, {n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(makeSureBtn ,fontWithColor('14', { text = __('确定')}))
    view:addChild(makeSureBtn)

    return {
        view          = view,
        rewardIcon    = rewardIcon,
        nameLabel     = nameLabel,
        descrLabel    = descrLabel,
        makeSureBtn   = makeSureBtn,
    }
end

function PrivateRoomGuestInfoRewardPopView:onClickMakeSureBtnAction()
    local currentScene = app.uiMgr:GetCurrentScene()
	if currentScene then
        currentScene:RemoveDialogByTag(self.args.tag)
        self:removeFromParent()
	end
end

function PrivateRoomGuestInfoRewardPopView:getViewData()
	return self.viewData_
end

return PrivateRoomGuestInfoRewardPopView