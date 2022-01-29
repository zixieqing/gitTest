-------------------------------------------------------------------------------
-- 个人信息 - 领取级奖励 视图
-- 
-- Author: kaishiqi <zhangkai@funtoygame.com>
-- 
-- Create: 2021-07-20 14:34:54
-------------------------------------------------------------------------------

---@class PersonInformationRewardsView : CLayout
local PersonInformationRewardsView = class('PersonInformationRewardsView', function()
    return ui.layer({name = 'Game.views.PersonInformationRewardsView', enableEvent = true})
end)


local RES_DICT = {
    TITLE_RIBBON_IMAGE         = _res('ui/home/personInformation/drawRewards/personal_reward_bg_head.png'),
    REWARDS_LIST_FRAME         = _res('ui/home/personInformation/drawRewards/personal_reward_bg_list.png'),
    CONTENT_REWARD_LIGHT       = _res('ui/home/personInformation/drawRewards/personal_reward_bg_box_light.png'),
    CONTENT_REWARD_FRAME       = _res('ui/home/personInformation/drawRewards/personal_reward_bg_details.png'),
    --                         = rewardList
    REWARD_CELL_FRAME_SELECT   = _res('ui/stores/base/shop_btn_tab_select.png'),
    REWARD_CELL_FRAME_DEFAULT  = _res('ui/stores/base/shop_btn_tab_default.png'),
    --                         = lvMax
    LVMAX_REWARD_SPINE         = _spn('ui/home/personInformation/drawRewards/lvMax/personal_reward_pic_box_light'),
    LVMAX_BOTTOM_FRAME         = _res('ui/home/personInformation/drawRewards/lvMax/personal_reward_box_bg_bottom.png'),
    LVMAX_TIPS_FRAME           = _res('ui/home/personInformation/drawRewards/lvMax/personal_reward_bg_tips.png'),
    LVMAX_LEVEL_FRAME          = _res('ui/home/personInformation/drawRewards/lvMax/personal_reward_box_bg_lv.png'),
    LVMAX_PREVIEW_BTN          = _res('ui/home/personInformation/drawRewards/lvMax/personal_reward_box_btn_details.png'),
    LVMAX_DRAW_BTN_D           = _res('ui/home/personInformation/drawRewards/lvMax/personal_reward_box_btn_get_grey.png'),
    LVMAX_DRAW_BTN_N           = _res('ui/home/personInformation/drawRewards/lvMax/personal_reward_box_btn_get.png'),
    --                         = address
    ADDRESS_INFO_LABEL_BG      = _res('ui/common/commcon_bg_text.png'),
    ADDRESS_INFO_SAVE_BTN_N    = _res('ui/common/common_btn_orange.png'),
    ADDRESS_INFO_SAVE_BTN_D    = _res('ui/common/common_btn_orange_disable.png'),
    ADDRESS_INFO_BG_IMG        = _res('ui/home/personInformation/drawRewards/address/personal_reward_address_bg.png'),
    ADDRESS_INFO_TIPS_BAR      = _res('ui/home/personInformation/drawRewards/address/personal_reward_address_bg_head.png'),
    ADDRESS_REWARD_PREVIEW_BTN = _res('ui/home/personInformation/drawRewards/address/personal_reward_address_btn_box.png'),
    ADDRESS_SENDING_BAR        = _res('ui/home/personInformation/drawRewards/address/personal_reward_address_bg_car.png'),
    ADDRESS_INFO_COPY_BTN      = _res('ui/home/personInformation/drawRewards/address/personal_reward_address_btn_copy.png'),
    ADDRESS_SENDING_SPINE      = _spn('ui/home/carexplore/waimai'),
}


---@param size cc.size
function PersonInformationRewardsView.CreateView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    ------------------------------------------------- [left]
    local leftLayer = ui.layer()
    view:add(leftLayer)

    local leftGroup = leftLayer:addList({
        ui.image({img = RES_DICT.REWARDS_LIST_FRAME}),
        ui.tableView({size = cc.size(225, 530), csizeH = 120, dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.p(115, size.height/2), leftGroup, {type = ui.flowC, ap = ui.cc})

    ---@type ExDataSourceAdapter
    local rewardListView = leftGroup[2]
    rewardListView:setCellCreateHandler(PersonInformationRewardsView.CreateRewardListCell)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local contentLayer = ui.layer({size = cc.size(760, 560), p = cc.p(size.width - 0, size.height/2), ap = ui.rc})
    centerLayer:addChild(contentLayer)


    ------------------------------------------------- [top]
    local ribbonImg = ui.image({img = RES_DICT.TITLE_RIBBON_IMAGE, p = cc.pAdd(cc.sizep(size, ui.ct), cc.p(0, 15))})
    view:add(ribbonImg)

    ---@class PersonInformationRewardsView.ViewData
    local viewData = {
        view           = view,
        --             = left,
        rewardListView = rewardListView,
        --             = center
        contentLayer   = contentLayer,
    }
    return viewData
end


---@param cellParent cc.Node
function PersonInformationRewardsView.CreateRewardListCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)
    cellParent:addChild(view)

    -- image layer
    local imageLayer = ui.layer({p = cpos})
    view:addChild(imageLayer)

    -- normal frame
    local frameNormal = ui.image({img = RES_DICT.REWARD_CELL_FRAME_DEFAULT, p = cpos})
    view:addChild(frameNormal)

    -- name label
    local nameLabel = ui.label({fnt = FONT.D14, fontSize = 22, p = cc.rep(cpos, 0, -34)})
    view:addChild(nameLabel)

    -- select frame
    local frameSelect = ui.image({img = RES_DICT.REWARD_CELL_FRAME_SELECT, p = cpos})
    view:addChild(frameSelect)

    -- clickArea
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    ---@class PersonInformationRewardsView.RewardListCellData
    local viewData = {
        view        = view,
        clickArea   = clickArea,
        imageLayer  = imageLayer,
        nameLabel   = nameLabel,
        frameNormal = frameNormal,
        frameSelect = frameSelect,
    }
    return viewData
end


---@param size cc.size
function PersonInformationRewardsView.CreateLvMaxView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local contentRewardFrame = ui.image({img = RES_DICT.CONTENT_REWARD_FRAME, p = cpos})
    view:addChild(contentRewardFrame)

    local contentRewardLight = ui.image({img = RES_DICT.CONTENT_REWARD_LIGHT, p = cpos})
    view:addChild(contentRewardLight)

    local rewardImageLayer = ui.layer({p = cc.rep(cpos, 0, 30)})
    view:addChild(rewardImageLayer)

    local rewardLightSpine = ui.spine({path = RES_DICT.LVMAX_REWARD_SPINE, p = cc.rep(cpos, -80, 0), init = 'idle'})
    view:addChild(rewardLightSpine)
    
    
    local contentBottomFrame = ui.image({img = RES_DICT.LVMAX_BOTTOM_FRAME, p = cpos})
    view:addList(contentBottomFrame):alignTo(nil, ui.cb, {offsetY = 15})

    local rewardTipsFrame = ui.image({img = RES_DICT.LVMAX_TIPS_FRAME})
    view:addList(rewardTipsFrame):alignTo(contentBottomFrame, ui.cc, {offsetX = -30, offsetY = -65})
    
    local rewardPreviewBtn = ui.button({n = RES_DICT.LVMAX_PREVIEW_BTN})
    view:addList(rewardPreviewBtn):alignTo(rewardTipsFrame, ui.rc, {offsetX = -10})
    
    local drawRewardBtn = ui.button({n = RES_DICT.LVMAX_DRAW_BTN_N})
    drawRewardBtn:updateLabel({fnt = FONT.D14, text = __('领取礼包')})
    view:addList(drawRewardBtn):alignTo(contentBottomFrame, ui.cc, {offsetX = -23, offsetY = 27})

    local descrTextArea = ui.textArea({size = cc.size(500, 60), fnt = FONT.D12, hAlign = ui.TAC, vAlign = ui.TAC})
    view:addList(descrTextArea):alignTo(rewardTipsFrame, ui.cc, {offsetX = 50, offsetY = 5})

    
    local levelInfoFrame = ui.image({img = RES_DICT.LVMAX_LEVEL_FRAME})
    view:addList(levelInfoFrame):alignTo(nil, ui.rt, {inside = true, offsetX = -10, offsetY = -45})

    local levelLabelGroup = levelInfoFrame:addList({
        ui.label({fnt = FONT.D9, color = '#FDF2E6', mb = 40, text = __('所需等级')}),
        ui.label({fnt = FONT.D9, color = '#986926', mb = 14, text = '----'}),
        ui.label({fnt = FONT.D9, color = '#FDF2E6', mt = 14, text = __('当前等级')}),
        ui.label({fnt = FONT.D9, color = '#986926', mt = 40, text = '----'}),
    })
    ui.flowLayout(cc.rep(cc.sizep(levelInfoFrame, ui.cc), -20, 0), levelLabelGroup, {type = ui.flowC, ap = ui.cc})

    ---@class PersonInformationRewardsView.LvMaxViewData
    local viewData = {
        view              = view,
        rewardImageLayer  = rewardImageLayer,
        rewardPreviewBtn  = rewardPreviewBtn,
        drawRewardBtn     = drawRewardBtn,
        descrTextArea     = descrTextArea,
        targetLevelLabel  = levelLabelGroup[2],
        currentLevelLabel = levelLabelGroup[4],
    }
    return viewData
end


---@param size cc.size
function PersonInformationRewardsView.CreateAddressInputView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local contentRewardFrame = ui.image({img = RES_DICT.CONTENT_REWARD_FRAME, p = cpos})
    view:addChild(contentRewardFrame)

    local addressInfoBgImage = ui.image({img = RES_DICT.ADDRESS_INFO_BG_IMG, p = cpos})
    view:addChild(addressInfoBgImage)
    
    local cardImageLayer = ui.layer({p = cc.p(11, 12)})
    view:addChild(cardImageLayer)
    

    local rewardInfoTipsBar = ui.title({img = RES_DICT.ADDRESS_INFO_TIPS_BAR}):updateLabel({fnt = FONT.D18, text = __('周边礼包请填写地址，耐心等待寄出'), offset = cc.p(20, 0)})
    view:addList(rewardInfoTipsBar):alignTo(addressInfoBgImage, ui.rt, {inside = true, offsetX = -60, offsetY = -80})
    
    local rewardPreviewBtn = ui.button({n = RES_DICT.ADDRESS_REWARD_PREVIEW_BTN})
    view:addList(rewardPreviewBtn):alignTo(rewardInfoTipsBar, ui.rc, {inside = true, offsetX = 40})


    local addressInfoGroup = view:addList({
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 40), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), len = 10, pText = string.fmt(__('不超过_num_个字符'), {_num_ = 10})}),
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 40), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), len = 11, pText = __('请输入手机号码'), inputMode = ui.INPUT_MODE.PHONENUMBER}),
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 120), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), len = 50, pText = __('请输入详细地址')}),
    })
    ui.flowLayout(cc.p(size.width - 240, cpos.y - 10), addressInfoGroup, {type = ui.flowV, ap = ui.cc, gapH = 20})
    view:addList(ui.label({fnt = FONT.D4, text = __('收件人')})):alignTo(addressInfoGroup[1], ui.lc, {offsetX = -10})
    view:addList(ui.label({fnt = FONT.D4, text = __('手机')})):alignTo(addressInfoGroup[2], ui.lc, {offsetX = -10})
    view:addList(ui.label({fnt = FONT.D4, text = __('地址')})):alignTo(addressInfoGroup[3], ui.lt, {offsetX = -10, offsetY = -30})


    local modifyInfoLayer = ui.layer()
    view:addChild(modifyInfoLayer)

    local addressTimeLabel = ui.label({fnt = FONT.D16, text = '----'})
    modifyInfoLayer:addList(addressTimeLabel):alignTo(addressInfoGroup[3], ui.cb, {offsetY = -20})

    local updateAddressBtn = ui.button({n = RES_DICT.ADDRESS_INFO_SAVE_BTN_N, d = RES_DICT.ADDRESS_INFO_SAVE_BTN_D, scale9 = true}):updateLabel({fnt = FONT.D14, text = __('保存')})
    modifyInfoLayer:addList(updateAddressBtn):alignTo(addressTimeLabel, ui.cb, {offsetY = -5})


    local sendingInfoLayer = ui.layer()
    view:addChild(sendingInfoLayer)

    local sendingInfoBar = ui.title({img = RES_DICT.ADDRESS_SENDING_BAR}):updateLabel({fnt = FONT.D14, text = __('礼包出货中')})
    sendingInfoLayer:addList(sendingInfoBar):alignTo(addressInfoGroup[3], ui.cb, {offsetY = -40})
    
    local sendingInfoSpine = ui.spine({path = RES_DICT.ADDRESS_SENDING_SPINE, init = 'idle'})
    sendingInfoLayer:addList(sendingInfoSpine):alignTo(sendingInfoBar, ui.rb, {offsetX = -20, offsetY = -20})

    
    ---@class PersonInformationRewardsView.AddressInputViewData
    local viewData = {
        view             = view,
        cardImageLayer   = cardImageLayer,
        nameEditBox      = addressInfoGroup[1],
        phoneEditBox     = addressInfoGroup[2],
        addressEditBox   = addressInfoGroup[3],
        rewardPreviewBtn = rewardPreviewBtn,
        modifyInfoLayer  = modifyInfoLayer,
        addressTimeLabel = addressTimeLabel,
        updateAddressBtn = updateAddressBtn,
        sendingInfoLayer = sendingInfoLayer,
    }
    return viewData
end


---@param size cc.size
function PersonInformationRewardsView.CreateAddressShowView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local contentRewardFrame = ui.image({img = RES_DICT.CONTENT_REWARD_FRAME, p = cpos})
    view:addChild(contentRewardFrame)

    local addressInfoBgImage = ui.image({img = RES_DICT.ADDRESS_INFO_BG_IMG, p = cpos})
    view:addChild(addressInfoBgImage)
    
    local cardImageLayer = ui.layer({p = cc.p(11, 12)})
    view:addChild(cardImageLayer)
    

    local rewardInfoTipsBar = ui.title({img = RES_DICT.ADDRESS_INFO_TIPS_BAR}):updateLabel({fnt = FONT.D18, text = __('请注意查收礼包'), offset = cc.p(20, 0)})
    view:addList(rewardInfoTipsBar):alignTo(addressInfoBgImage, ui.rt, {inside = true, offsetX = -60, offsetY = -80})
    
    local rewardPreviewBtn = ui.button({n = RES_DICT.ADDRESS_REWARD_PREVIEW_BTN})
    view:addList(rewardPreviewBtn):alignTo(rewardInfoTipsBar, ui.rc, {inside = true, offsetX = 40})


    local addressInfoGroup = view:addList({
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 40), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), isEnable = false}),
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 40), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), isEnable = false}),
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 80), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), isEnable = false}),
        ui.editBox({bg = RES_DICT.ADDRESS_INFO_LABEL_BG, size = cc.size(360, 80), cut = cc.dir(10,10,10,10), dir = cc.dir(10,2,10,2), isEnable = false}),
    })
    ui.flowLayout(cc.p(size.width - 240, cpos.y - 10), addressInfoGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})
    view:addList(ui.label({fnt = FONT.D4, text = __('快递单号')})):alignTo(addressInfoGroup[1], ui.lc, {offsetX = -10})
    view:addList(ui.label({fnt = FONT.D4, text = __('快递服务')})):alignTo(addressInfoGroup[2], ui.lc, {offsetX = -10})
    view:addList(ui.label({fnt = FONT.D4, text = __('收件信息')})):alignTo(addressInfoGroup[3], ui.lt, {offsetX = -10, offsetY = -30})
    view:addList(ui.label({fnt = FONT.D4, text = __('收件地址')})):alignTo(addressInfoGroup[4], ui.lt, {offsetX = -10, offsetY = -30})

    local copyExpressNoBtn = ui.button({n = RES_DICT.ADDRESS_INFO_COPY_BTN})
    view:addList(copyExpressNoBtn):alignTo(addressInfoGroup[1], ui.rc, {inside = true, offsetX = -10})


    local sendingInfoLayer = ui.layer()
    view:addChild(sendingInfoLayer)

    local sendingInfoBar = ui.title({img = RES_DICT.ADDRESS_SENDING_BAR}):updateLabel({fnt = FONT.D14, text = __('礼包已出货')})
    sendingInfoLayer:addList(sendingInfoBar):alignTo(addressInfoGroup[4], ui.cb, {offsetY = -30})
    
    local sendingInfoSpine = ui.spine({path = RES_DICT.ADDRESS_SENDING_SPINE, init = 'idle'})
    sendingInfoLayer:addList(sendingInfoSpine):alignTo(sendingInfoBar, ui.rb, {offsetX = -20, offsetY = -20})


    ---@class PersonInformationRewardsView.AddressShowViewData
    local viewData = {
        view             = view,
        cardImageLayer   = cardImageLayer,
        numberEditBox    = addressInfoGroup[1],
        expressEditBox   = addressInfoGroup[2],
        receiverEditBox  = addressInfoGroup[3],
        addressEditBox   = addressInfoGroup[4],
        rewardPreviewBtn = rewardPreviewBtn,
        copyExpressNoBtn = copyExpressNoBtn,
    }
    return viewData
end


-------------------------------------------------------------------------------
-- PersonInformationRewardsView
-------------------------------------------------------------------------------

function PersonInformationRewardsView:ctor(mdt)
    ---@type PersonInformationRewardsMediator
    self.parentMediator_ = mdt
    self:setAnchorPoint(display.CENTER)
    self:setContentSize(cc.size(988, 562))

    -- create view
    self.viewData_ = PersonInformationRewardsView.CreateView(self:getContentSize())
    self:addChild(self.viewData_.view)
end


---@return PersonInformationRewardsView.LvMaxViewData
function PersonInformationRewardsView:getViewData()
    return self.viewData_
end


function PersonInformationRewardsView:getContentViewData()
    return self.contentViewData_
end


function PersonInformationRewardsView:updateRewardListSelectIndex()
    local rewardListView  = self:getViewData().rewardListView
    ---@param cellViewData PersonInformationRewardsView.RewardListCellData
    for _, cellViewData in pairs(rewardListView:getCellViewDataDict()) do
        self:updateRewardListCell(cellViewData.view:getTag(), cellViewData, nil, 'select')
    end
end


---@param cellIndex    integer
---@param cellViewData PersonInformationRewardsView.RewardListCellData
---@param cellData?    table
---@param updateType?  string
function PersonInformationRewardsView:updateRewardListCell(cellIndex, cellViewData, cellData, updateType)
    local rewardCellId    = checkint(cellData)
    local rewardCellIndex = checkint(cellIndex)
    local cellSummaryConf = CONF.DERIVATIVE.SUMMARY:GetValue(rewardCellId)

    -- update selected status
    if not updateType or updateType == 'select' then
        local isSelected = rewardCellIndex == self.parentMediator_:getSelectCellIndex()
        cellViewData.frameSelect:setVisible(isSelected)
    end

    -- update name
    if not updateType then
        cellViewData.nameLabel:updateLabel({text = tostring(cellSummaryConf.name)})
    end

    -- update image
    if not updateType then
        local typeImagePath = string.fmt('ui/home/personInformation/drawRewards/personal_reward_img_list_%1.jpg', tostring(cellSummaryConf.photoIcon))
        cellViewData.imageLayer:addAndClear(ui.image({img = _res(typeImagePath)}))
    end
end


---@param createFunc fun(viewSize:cc.size):table
---@param createArgs? table
function PersonInformationRewardsView:updateContentView(createFunc, createArgs)
    local contentSize = self:getViewData().contentLayer:getContentSize()
    self.contentViewData_ = createFunc and createFunc(contentSize, createArgs) or nil

    if self.contentViewData_ and self.contentViewData_.view then
        self:getViewData().contentLayer:addChild(self.contentViewData_.view)
    end
end


function PersonInformationRewardsView:updateLvMaxRewardView(rewardCellId)
    local summaryConf  = CONF.DERIVATIVE.SUMMARY:GetValue(rewardCellId)
    local rewardImgId  = checkint(summaryConf.photoGift)
    local rewardDescr  = tostring(summaryConf.rewardWords)
    local targetLevel  = checkint(summaryConf.level)
    local currentLevel = checkint(app.gameMgr:GetUserInfo().level)

    ---@type PersonInformationRewardsView.LvMaxViewData
    local lvMaxViewData = self:getContentViewData()
    if lvMaxViewData then

        -- update rewardImage
        local typeImagePath = string.fmt('ui/home/personInformation/drawRewards/personal_reward_pic_box_%1.jpg', rewardImgId)
        lvMaxViewData.rewardImageLayer:addAndClear(ui.image({img = _res(typeImagePath)}))

        -- update level info
        local isEnableReward = currentLevel >= targetLevel
        lvMaxViewData.targetLevelLabel:updateLabel({text = tostring(targetLevel)})
        lvMaxViewData.currentLevelLabel:updateLabel({text = tostring(currentLevel)})

        -- update drawRewardBtn
        local drawBtnImgPath = isEnableReward and RES_DICT.LVMAX_DRAW_BTN_N or RES_DICT.LVMAX_DRAW_BTN_D
        lvMaxViewData.drawRewardBtn:setNormalImage(drawBtnImgPath)
        lvMaxViewData.drawRewardBtn:setSelectedImage(drawBtnImgPath)

        -- update reward descr
        lvMaxViewData.descrTextArea:updateLabel({text = rewardDescr})
    end
end


function PersonInformationRewardsView:updateAddressInputView(rewardCellId, addressData)
    local summaryConf  = CONF.DERIVATIVE.SUMMARY:GetValue(rewardCellId)
    local cardPhotoId  = checkint(summaryConf.photoBg)
    
    ---@type PersonInformationRewardsView.AddressInputViewData
    local inputViewData = self:getContentViewData()
    if inputViewData then

        -- update cardPhotoImage
        local cardImagePath = string.fmt('ui/home/personInformation/drawRewards/personal_reward_address_%1.jpg', cardPhotoId)
        inputViewData.cardImageLayer:addAndClear(ui.image({img = _res(cardImagePath), ap = ui.lb}))

        local nameText    = checkstr(addressData.name)
        local phoneText   = checkstr(addressData.telephone)
        local addressText = checkstr(addressData.address)
        local isMissing   = nameText == '' or phoneText == '' or addressText == ''
        local currentTime = os.time()
        local targetTime  = checkint(addressData.cdTimestamp)
        local leftSeconds = targetTime - currentTime
        local isSending   = not isMissing and leftSeconds <= 0
        inputViewData.nameEditBox:setText(nameText)
        inputViewData.phoneEditBox:setText(phoneText)
        inputViewData.addressEditBox:setText(addressText)
        inputViewData.nameEditBox:setEditEnable(not isSending)
        inputViewData.phoneEditBox:setEditEnable(not isSending)
        inputViewData.addressEditBox:setEditEnable(not isSending)
        
        inputViewData.sendingInfoLayer:setVisible(isSending)
        inputViewData.modifyInfoLayer:setVisible(not isSending)
        inputViewData.addressTimeLabel:setVisible(not isMissing)
        
        ui.updateLabel(inputViewData.updateAddressBtn, {text = isMissing and __('保存') or __('修改地址'), paddingW = 30})
    end
end


function PersonInformationRewardsView:updateAddressModifyTime(addressData)
    ---@type PersonInformationRewardsView.AddressInputViewData
    local inputViewData = self:getContentViewData()
    if inputViewData then
        local currentTime  = os.time()
        local targetTime   = checkint(addressData.cdTimestamp)
        local leftSeconds  = targetTime - currentTime
        local timeText     = CommonUtils.getTimeFormatByType(leftSeconds, 3)
        ui.updateLabel(inputViewData.addressTimeLabel, {text = timeText})
    end
end


function PersonInformationRewardsView:updateAddressShowView(rewardCellId, addressData)
    local summaryConf  = CONF.DERIVATIVE.SUMMARY:GetValue(rewardCellId)
    local cardPhotoId  = checkint(summaryConf.photoBg)

    ---@type PersonInformationRewardsView.AddressShowViewData
    local showViewData = self:getContentViewData()
    if showViewData then

        -- update cardPhotoImage
        local cardImagePath = string.fmt('ui/home/personInformation/drawRewards/personal_reward_address_%1.jpg', cardPhotoId)
        showViewData.cardImageLayer:addAndClear(ui.image({img = _res(cardImagePath), ap = ui.lb}))

        local nameText    = checkstr(addressData.name)
        local phoneText   = checkstr(addressData.telephone)
        local addressText = checkstr(addressData.address)
        local serviceId   = checkstr(addressData.expressServiceId)
        local expressConf = CONF.DERIVATIVE.EXPRESS:GetValue(serviceId)
        local expressText = tostring(expressConf.name)
        local numberText  = checkstr(addressData.expressNo)
        showViewData.numberEditBox:setText(numberText)
        showViewData.expressEditBox:setText(expressText)
        showViewData.receiverEditBox:setText(nameText .. '\n' .. phoneText)
        showViewData.addressEditBox:setText(addressText)
    end
end


return PersonInformationRewardsView
