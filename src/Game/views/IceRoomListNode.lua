local IceRoomListNode = class('IceRoomListNode', function()
	local node = CLayout:create()
	node.name = 'Game.views.IceRoomListNode'
	node:enableNodeEvents()
    return node
end)

local socket = require("socket")
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr   = shareFacade:GetManager("UIManager")
local timerMgr = shareFacade:GetManager("TimerManager")

local DICT = {
    LIST_BG  = "ui/iceroom/common_bg_list.png",
    LIST_STATE_ICON = "ui/iceroom/refresh_expangd_ico_blank_2.png",
    LIST_HEAD_BG   = "ui/iceroom/common_bg_role_s.png",
    LIST_LOCK_TOP_BG = "ui/iceroom/refresh_expand_bg_lock.png",
    LIST_LOCK_ICON  = "ui/common/common_ico_lock.png",
    LIST_LOCK_GOODS_BG = "ui/common/common_frame_goods_3.png",
    BTN_COMMON  = "ui/common/common_btn_orange.png",
}
local dataMgr = shareFacade:GetManager("DataManager")
local UpgradeDatas = dataMgr:GetConfigDataByFileName("icePlaceUpgrade", "iceBink")


function IceRoomListNode:ctor( ... )
    local args = unpack({...})
    self.state = args.state
    self.datas = args.data
    self.isOver = false
    self.startTime = socket:gettime()
    --要有一个记时器
    self:setContentSize(cc.size(500,120))
    local size = cc.size(500, 114)
    self.viewData = nil
    local view = CLayout:create(size)
    display.commonUIParams(view, {ap = display.LEFT_CENTER, po = cc.p(size.width, 60)})
    self:addChild(view)
    local bgImage = display.newNSprite(_res(DICT.LIST_BG), size.width * 0.5, size.height * 0.5)
    view:addChild(bgImage)
    local lockSprite = display.newNSprite(_res(DICT.LIST_LOCK_ICON), size.width * 0.5, size.height * 0.5)
    view:addChild(lockSprite, 10)
    lockSprite:setVisible(false)
    if self.state == "locked" then
        lockSprite:setVisible(true)
    end

    --最上面的无状态情况的逻辑,显示为暂无飨灵入驻的逻辑状态
    local unlessStateView = CLayout:create(size)
    display.commonUIParams(unlessStateView, {po = cc.p(size.width * 0.5, size.height * 0.5)})
    view:addChild(unlessStateView, 20)
    local stateIcon = display.newNSprite(_res(DICT.LIST_STATE_ICON), size.width * 0.5, size.height * 0.5)
    unlessStateView:addChild(stateIcon,2)
    local stateLabel = display.newLabel(size.width * 0.7,size.height * 0.31, {ap = display.CENTER, text = __('暂无飨灵入住'), hAlign = display.TAC , w = 250  , fontSize = 20, color = '6c6c6c'})
    unlessStateView:addChild(stateLabel,10)
    if self.state == "wait" then
        unlessStateView:setVisible(true)
    else
        unlessStateView:setVisible(false)
    end
    --解锁状态的显示
    local unlockView = CLayout:create(size)
    display.commonUIParams(unlockView, {po = utils.getLocalCenter(view)})
    view:addChild(unlockView,12)
    local topImage = display.newNSprite(_res(DICT.LIST_LOCK_TOP_BG), size.width * 0.5,size.height)
    display.commonUIParams(topImage, {ap = display.CENTER_TOP})
    unlockView:addChild(topImage)
    local lockSprite = display.newNSprite(_res(DICT.LIST_LOCK_ICON),66,47)
    lockSprite:setAnchorPoint(display.CENTER_TOP)
    topImage:addChild(lockSprite,1)
    local tipLabel = display.newLabel(68,size.height * 0.4, { ap = display.CENTER, text = __('扩容材料'),   fontSize = 20, color = '6c6c6c'})
    unlockView:addChild(tipLabel,2)
    local tipLabelSize  = display.getLabelContentSize(tipLabel)
    if tipLabelSize.width > 120 then
        display.commonLabelParams( tipLabel , {w= 160 ,hAlign = display.TAC, reqW = 120})
    end
    --添加物品数据节点
    local unLockButton = display.newButton(410,size.height * 0.5, {
        n = _res(DICT.BTN_COMMON), cb = function ( sender )
            --解锁的点
            local datas = UpgradeDatas[tostring(self.datas.roomId)][tostring(self.datas.id)]
            local isCanUnlock = true
            if datas.consume then
                for i,v in pairs(datas.consume) do
                    local no = gameMgr:GetAmountByGoodId(v.targetId)
                    if no < checkint(v.targetNum) then
                        isCanUnlock = false
                        uiMgr:ShowInformationTips(__('当前的材料不足，不能进行解锁操作'))
                        break
                    end
                end
            end
            if isCanUnlock then
                --发送请求
                shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = checkint(self.datas.roomId), placeId = checkint(self.datas.id)},'unlockPosition')
            end
        end
    })
    display.commonLabelParams(unLockButton, fontWithColor(14,{text = __('扩容')}))
    unlockView:addChild(unLockButton,1)
    if self.state == "open" then
        local datas = UpgradeDatas[tostring(self.datas.roomId)][tostring(self.datas.id)]
        if datas and datas.consume and table.nums(datas.consume) > 0 then
            unLockButton:setTag(checkint(self.roomId))
            --添加物品节点
            for i,v in pairs(datas.consume) do
                local x = (i - 1) * 0.196 + 0.374
                local no = gameMgr:GetAmountByGoodId(v.targetId)
                local numberLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', string.format( "%d/%d",no, checkint(v.targetNum) ))
                display.commonUIParams(numberLabel, {ap = display.CENTER , po = cc.p(50, -10)})
                --local numberLabel = display.newLabel(76,14, {ap = display.RIGHT_CENTER, fontSize = 20, text = string.format( "%d/%d",no, checkint(v.targetNum) ), color = "5c5c5c"})
                --goodsIconBg:addChild(numberLabel, 5)
                local goodsNode = require('common.GoodNode').new({id = checkint(v.targetId), amount = string.format( "%d/%d",no, checkint(v.targetNum) ), showAmount = false ,callBack = function(sender)
                    uiMgr:AddDialog("common.GainPopup", {goodId = sender:getTag()})
                end})
                goodsNode:setTag(checkint(v.targetId))
                goodsNode:addChild(numberLabel, 20)
                display.commonUIParams(goodsNode, {po = cc.p(x * (size.width +60) -40  ,size.height * 0.5)})
                goodsNode:setScale(0.8)
                unlockView:addChild(goodsNode, 5)
            end
        else
            self:setVisible(false)
        end
    else
        unlockView:setVisible(false)
    end
    --正常恢复状态的逻辑页面
    local normalView = CLayout:create(size)
    display.commonUIParams(normalView, {po = utils.getLocalCenter(view)})
    view:addChild(normalView,8)
    local headerNode = require("common.HeaderNode").new({id = args.id})
    display.commonUIParams(headerNode, {ap = display.LEFT_CENTER, po = cc.p(14, size.height * 0.5)})
    normalView:addChild(headerNode,2)
    local nameLabel = display.newLabel(130,90, {ap = display.LEFT_CENTER, text = "", fontSize = 24, color = '6c6c6c'})
    normalView:addChild(nameLabel)
    normalView:setVisible(false)
    --添加解锁按钮
    local unLock2Button = display.newButton(410,size.height * 0.5, {
        n = _res(DICT.BTN_COMMON), cb = function ( sender )
            --解锁的点
            sender:setEnabled(false)
            shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = checkint(self.datas.roomId), playerCardId = checkint(self.datas.cardData.id)},'unload')
        end
    })
    display.commonLabelParams(unLock2Button, fontWithColor(14,{text = __("撤下")}))
    normalView:addChild(unLock2Button,10)
    --添加进度
    local vigourView = CLayout:create(cc.size(168, 32))
    display.commonUIParams(vigourView, {ap = display.LEFT_BOTTOM, po = cc.p(120, 36)})
    normalView:addChild(vigourView, 12)
    local progressBG = display.newImageView(_res('ui/home/teamformation/newCell/refresh_bg_tired_2.png'), {
            scale9 = true, size = cc.size(168,28)
        })
    display.commonUIParams(progressBG, {po = cc.p(84, 16)})
    vigourView:addChild(progressBG,2)

    local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_red.png'))
    operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
    operaProgressBar:setMaxValue(100)
    operaProgressBar:setValue(0)
    operaProgressBar:setPosition(cc.p(6, 16))
    vigourView:addChild(operaProgressBar,5)
    local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
    vigourProgressBarTop:setAnchorPoint(cc.p(0,0.5))
    vigourProgressBarTop:setPosition(cc.p(2,16))
    vigourView:addChild(vigourProgressBarTop,6)

    local vigourLabel = display.newLabel(operaProgressBar:getContentSize().width + 14, operaProgressBar:getPositionY() + 2,{
        ap = display.LEFT_CENTER, fontSize = 20, color = 'ffffff', text = ""
    })
    vigourView:addChild(vigourLabel, 6)
    local normalLabel = display.newLabel(130,10, {ap = display.LEFT_BOTTOM, text = __("恢复满还剩余"), fontSize = 20, color = '5c5c5c'})
    normalView:addChild(normalLabel,2)
    if self.state == 'opened' then
        normalView:setVisible(true) --显示然后更新数据
    end

    self.viewData = {
        view = view,
        unlessStateView = unlessStateView,
        unlockView  = unlockView,
        normalView  = normalView,
        unLockButton = unLockButton,
        headerNode = headerNode,
        nameLabel = nameLabel,
        normalLabel = normalLabel,
        vigourProgressBar = operaProgressBar,
        vigourLabel = vigourLabel,
    }
    if self.datas.cardData then
        local targetTimer = timerMgr:RetriveTimer(string.format('ICEROOM_%s', tostring(self.datas.cardData.id)))
        local remainTime = checkint(self.datas.cardData.recoverTime)
        if targetTimer then
            remainTime = checkint(targetTimer.countdown)
        end
        local cardInfo = gameMgr:GetCardDataById(checkint(self.datas.cardData.id))
        if cardInfo then
            local configInfo = CommonUtils.GetConfig("cards", "card", cardInfo.cardId)
            -- self.viewData.nameLabel:setString(configInfo.name)
            self.viewData.nameLabel:setString(CommonUtils.GetCardNameById(checkint(self.datas.cardData.id)))
            self.viewData.headerNode:updateImageView(cardInfo.cardId)
            local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
            if remainTime > 0 and checkint(cardInfo.vigour) < maxVigour then
                --需要自我计时更新
                display.commonLabelParams(self.viewData.normalLabel, {fontSize = 20,color = "6c6c6c", text = string.formattedTime(remainTime, __("恢复时间 %02i:%02i:%02i"))})
                self:schedule(function()
                    if self.isOver then return end
                    local curTime = socket:gettime()
                    local span = curTime - self.startTime
                    remainTime = remainTime - span
                    display.commonLabelParams(self.viewData.normalLabel, {fontSize = 20,color = "6c6c6c", text = string.formattedTime(remainTime,__("恢复时间 %02i:%02i:%02i"))})
                    local curCarInfo = gameMgr:GetCardDataById(checkint(cardInfo.id))
                    local vigour = checkint(cardInfo.vigour)
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                    -- if targetVigour > maxVigour then
                        -- targetVigour = maxVigour
                    -- end
                    self.viewData.vigourLabel:setString(tostring(vigour))
                    local ratio = (vigour / maxVigour) * 100
                    self.viewData.vigourProgressBar:setValue(rangeId(ratio, 100))
                    if (ratio > 40 and (ratio <= 60)) then
                        self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
                    elseif ratio > 60 then
                        self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
                    end
                    if remainTime <= 0.2 then
                        --结束的结果
                        self.isOver = true
                        self.viewData.normalLabel:setString(__('已恢复完成'))
                        local vigour = checkint(cardInfo.vigour)
                        self.viewData.vigourLabel:setString(tostring(vigour))
                        local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                        local ratio = (vigour / maxVigour) * 100
                        self.viewData.vigourProgressBar:setValue(rangeId(ratio, 100))
                        if (ratio > 40 and (ratio <= 60)) then
                            self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
                        elseif ratio > 60 then
                            self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
                        end
                        AppFacade.GetInstance():DispatchObservers("EVENT_TIME_UPDATE", {id = self.datas.cardData.id, time = 0})
                    else
                        --更改时间
                        AppFacade.GetInstance():DispatchObservers("EVENT_TIME_UPDATE", {id = self.datas.cardData.id, time = remainTime})
                        display.commonLabelParams(self.viewData.normalLabel, {fontSize = 20,color = "6c6c6c", text = string.formattedTime(remainTime,__("恢复时间 %02i:%02i:%02i"))})
                    end
                    -- end
                    self.startTime = curTime
                end,1) --检测是否已经满值
            else
                self.viewData.normalLabel:setString(__("已恢复完成"))
            end
            local vigour = checkint(cardInfo.vigour)
            self.viewData.vigourLabel:setString(tostring(vigour))
            local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
            local ratio = (vigour / maxVigour) * 100
            self.viewData.vigourProgressBar:setValue(rangeId(ratio, 100))
            if (ratio > 40 and (ratio <= 60)) then
                self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
            elseif ratio > 60 then
                self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
            end
        end
    end
end


function IceRoomListNode:StartInAction( index )
    self:setTag(index)
    self.viewData.view:runAction(
        cc.Sequence:create(cc.DelayTime:create(index * 0.1),
        cc.EaseOut:create(cc.MoveTo:create(0.2, cc.p(0, 56)), 0.2))
    )
end

return IceRoomListNode
