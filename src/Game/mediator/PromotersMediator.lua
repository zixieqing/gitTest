--[[
推广员 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "PromotersMediator"
local PromotersMediator = class("PromotersMediator", Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local PROMOTERS_VIEW_TAG = {
    AGENT = 100,
    REDEEMCODE = 101,
}

local BTN_TAG = {
    PROMOTERS_INFO           = 1000,         -- 推广员信息
    SKIN_COUPON_REPLACEMENT  = 1001,         -- 幻晶石补领
    SAVE_IMAGE               = 1002,         -- 保存图片
    COPY_LINK                = 1003,         -- 复制图片
    PRE_ARROW                = 1004,         -- 上张头像按钮
    NEXT_ARROW               = 1005,         -- 下张头像图片
    REDEEM_CODE              = 1006,         -- 兑换码
    REPLACEMENT_COUPON       = 1007,         -- 补领兑换券
}

local SKIN_COUPON_ID         = 890006        -- 皮肤劵 道具id

local MAX_HEAD_INDEX = nil
local MIN_HEAD_INDEX = 1
function PromotersMediator:ctor(params, viewComponent)
    self.super:ctor(NAME,viewComponent)
    self.args = checktable(params)

    self.curViewTag = self.args.viewTag or PROMOTERS_VIEW_TAG.AGENT
    self.contentViewDatas = {}

    local achieveRewardCof = CommonUtils.GetConfigAllMess('achieveReward', 'goods')
	self.initialHeads = {}
	for id, achieveRewardData in pairs(achieveRewardCof) do
		if checkint(achieveRewardData.initial) == 1 and checkint(achieveRewardData.rewardType) == CHANGE_TYPE.CHANGE_HEAD then
			table.insert(self.initialHeads, achieveRewardData)
		end
	end

	table.sort(self.initialHeads, function (a, b)
		return a.id < b.id
	end)
    
    MAX_HEAD_INDEX = #self.initialHeads
    self.curHeadIndex = 1
    self.curHeadId = self.initialHeads[self.curHeadIndex].id
    
    -- 屏蔽好友界面输入框
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false})
end

function PromotersMediator:InterestSignals()
	local signals = { 
        POST.RECOMMEN_HOME.sglName,
        POST.RECOMMEN_GETPRESENT.sglName,
        POST.PRESENT_CODE.sglName,
	}

	return signals
end

function PromotersMediator:ProcessSignal( signal )
    local name = signal:GetName() 
	-- print(name)
    local body = checktable(signal:GetBody())
    dump(body, name)
    if name == POST.RECOMMEN_HOME.sglName then
        self.recommenData = body
        self:updatePromoterView()
    elseif name == POST.RECOMMEN_GETPRESENT.sglName then
        local rewards = body.rewards or {}
        if #rewards > 0 then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})

            local isUpdateSkinCoupon = false
            for i,v in ipairs(rewards) do
                local goodsId = v.goodsId
                local num = checkint(v.num)
                if goodsId == SKIN_COUPON_ID then
                    self.recommenData.recommendNum = self.recommenData.recommendNum
                    self.recommenData.recommendTotalNum = self.recommenData.recommendTotalNum + num
                    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
                    self:updateSkinCoupon()
                end
            end
        else
            uiMgr:ShowInformationTips(__('被推广人等级未达到要求'))
        end

        local UUIDEditBox = self.infoViewData.UUIDEditBox
        local phoneEditBox = self.infoViewData.phoneEditBox
        UUIDEditBox:setText('')
        phoneEditBox:setText('')

    elseif name == POST.PRESENT_CODE.sglName then
        local msg = body.msg or ''
        uiMgr:ShowInformationTips(msg)
    end
end

function PromotersMediator:Initial( key )
    self.super.Initial(self,key)

    local tag = 5001
	local viewComponent = require('Game.views.PromotersView').new({tag = tag, mediatorName = NAME})
	viewComponent:setTag(tag)
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)

	local scene = uiMgr:GetCurrentScene() 
    scene:AddDialog(viewComponent)
    
    self:initUi(viewComponent)
end

function PromotersMediator:initUi(viewComponent)
    local viewData = viewComponent:GetViewData()
    local tabs = viewData.tabs
    for tag, tab in pairs(tabs) do
        local tag = checkint(tag)
        display.commonUIParams(tab, {cb = handler(self, self.OnTabAction)})
        
        tab:setTag(tag)
        if tag == self.curViewTag then
            tab:setNormalImage(_res('ui/common/common_btn_sidebar_selected.png'))
            tab:setSelectedImage(_res('ui/common/common_btn_sidebar_selected.png'))
        end
    end

    self.viewData = viewData

    self:showTabCententView()

end

function PromotersMediator:showTabCententView()
    local centenViewData = self.contentViewDatas[tostring(self.curViewTag)]
    if centenViewData then
        centenViewData.view:setVisible(true)
        return 
    end

    local bgSize = self.viewData.bgSize
    local view   = nil
    if self.curViewTag == PROMOTERS_VIEW_TAG.AGENT then
        print('CreatePromotersView')
        local promoterViewData = self:GetViewComponent():CreatePromotersView(bgSize)
        self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.AGENT)] = promoterViewData
        view = promoterViewData.view

        local actionButtons = promoterViewData.actionButtons
        for tag, btn in pairs(actionButtons) do
            btn:setTag(tag)
            
            display.commonUIParams(btn, {animate = checkint(tag) ~= BTN_TAG.PROMOTERS_INFO, cb = handler(self, self.OnButtonAction)})
        end
        self:updateQRCodeHead()
        
    elseif self.curViewTag == PROMOTERS_VIEW_TAG.REDEEMCODE then
        print('CreateRedeemCodeView')
        
        local redeemCodeViewData = self:GetViewComponent():CreateRedeemCodeView(bgSize)
        self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.REDEEMCODE)] = redeemCodeViewData

        view = redeemCodeViewData.view

        local redeemCodeBtn = redeemCodeViewData.btn
        display.commonUIParams(redeemCodeBtn, {cb = handler(self, self.OnButtonAction)})

        self:updateRedeemCodeView()
    end

    if view then
        self.viewData.view:addChild(view)
    end
end

function PromotersMediator:updateTabSelectState(viewTag)
    local tabs = self.viewData.tabs
    dump(tabs)
    print(self.curViewTag)
    local oldTab = tabs[tostring(self.curViewTag)]
    oldTab:setNormalImage(_res('ui/common/common_btn_sidebar_common.png'))
    oldTab:setSelectedImage(_res('ui/common/common_btn_sidebar_common.png'))

    local tab = tabs[tostring(viewTag)]
    tab:setNormalImage(_res('ui/common/common_btn_sidebar_selected.png'))
    tab:setSelectedImage(_res('ui/common/common_btn_sidebar_selected.png'))
    
end

function PromotersMediator:updatePromoterView()
    local promoterViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.AGENT)]
    -- local todayObtainLabel = promoterViewData.todayObtainLabel
    -- local totalObtainLabel = promoterViewData.totalObtainLabel
    local qrCode           = promoterViewData.qrCode
    local linkLabel        = promoterViewData.linkLabel
    local friendHeaderNode = promoterViewData.friendHeaderNode
    local qrCodeLayer     = promoterViewData.qrCodeLayer
    -- qrCodeImgLink
    -- qrCodeImgMd5
    local link = self.recommenData.link or 'http://food.funtoygame.com/'
    local qrCodeImgLink = gameMgr:GetUserInfo().qrCodeImgLink or ''
    local qrCodeImgMd5 = gameMgr:GetUserInfo().qrCodeImgMd5 or ''

    qrCode:setSpriteMD5(qrCodeImgMd5)
    qrCode:setWebURL(qrCodeImgLink)
    qrCode:setVisible(true)

    self:updateSkinCoupon()

    friendHeaderNode:setPosition(utils.getLocalCenter(qrCodeLayer))
    
    display.commonLabelParams(linkLabel,        {text = link, maxW = 280})
end

function PromotersMediator:updateSkinCoupon()
    local promoterViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.AGENT)]
    local todayObtainLabel = promoterViewData.todayObtainLabel
    local totalObtainLabel = promoterViewData.totalObtainLabel
    local recommendNum = self.recommenData.recommendNum or 0
    local recommendTotalNum = self.recommenData.recommendTotalNum or 0
    display.reloadRichLabel(todayObtainLabel, {c = {
        fontWithColor(6, {text = recommendNum}),
        {img = _res('arts/goods/goods_icon_890006.png'), scale = 0.2},
    }})

    display.reloadRichLabel(totalObtainLabel, {c = {
            fontWithColor(6, {text = recommendTotalNum}),
            {img = _res('arts/goods/goods_icon_890006.png'), scale = 0.2},
        }})
end

function PromotersMediator:updateRedeemCodeView()
    local redeemCodeViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.REDEEMCODE)]
    local editBox = redeemCodeViewData.editBox
end

function PromotersMediator:updateInfoView()
    local promoterViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.AGENT)]
    local todayObtainLabel = promoterViewData.todayObtainLabel
    local totalObtainLabel = promoterViewData.totalObtainLabel

end

function PromotersMediator:updateQRCodeHead()
    self:checkHeadRange()
    local promoterViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.AGENT)]
    local friendHeaderNode = promoterViewData.friendHeaderNode
    friendHeaderNode.headerSprite:setWebURL(self.curHeadId)
end

function PromotersMediator:OnTabAction(sender)
    local viewTag = sender:getTag()
    if viewTag == self.curViewTag then return end
    self:updateTabSelectState(viewTag)

    local viewData = self.contentViewDatas[tostring(self.curViewTag)]
    viewData.view:setVisible(false)

    self.curViewTag = viewTag
    self:showTabCententView()
end

function PromotersMediator:OnButtonAction(sender)
    local tag = sender:getTag()
    if tag == BTN_TAG.PROMOTERS_INFO then
        -- uiMgr:ShowInformationTipsBoard({targetNode = sender, bgSize = cc.size(507, 220), descr = __('分享你的专属二维码，邀请链接，可以获得外观券，具体规则：\n1.其他人每次点击，你获得1个外观券，每日最多5个，每周20个封顶。\n2.邀请新玩家通过你的链接下载并将角色提升至5级，你获得10个外观券，无上限。'), type = 5})
        -- print('OnButtonAction', tag)
        local explainViewData = self:GetViewComponent():GetExplainViewData()
        local layer = explainViewData.layer
        layer:setVisible(not layer:isVisible())
    elseif tag == BTN_TAG.SKIN_COUPON_REPLACEMENT then
        
        if self.infoViewData then
            self.infoViewData.view:setVisible(true)
            return
        end
        self.infoViewData = self:GetViewComponent():CreateInfoView()
        self:GetViewComponent():addChild(self.infoViewData.view)

        local touchView = self.infoViewData.touchView
        display.commonUIParams(touchView, {cb = function ()
            self.infoViewData.view:setVisible(false)
            self.infoViewData.UUIDEditBox:setText('')
            self.infoViewData.phoneEditBox:setText('')
        end})
        -- btn
        local replacementBtn = self.infoViewData.btn
        display.commonUIParams(replacementBtn, {cb = handler(self, self.OnButtonAction)})
        
    elseif tag == BTN_TAG.SAVE_IMAGE then
        
        -- if gameMgr:GetUserInfo().isSaveQrCode then uiMgr:ShowInformationTips(__('保存成功')) return end

        local promoterViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.AGENT)]
        
        local bgSize      = promoterViewData.bgSize
        local view        = promoterViewData.view
        local qrCodeLayer = promoterViewData.qrCodeLayer
        local qrCode      = promoterViewData.qrCode

        local function CreateCutNode(parent, node, size)
            local texture = cc.RenderTexture:create(size.width, size.height)
            if parent then
                parent:addChild(texture)
            end
            
            texture:beginWithClear(0, 0, 0, 0)
            -- texture:setVirtualViewport(cc.p(display.cx - 200, display.cy - 200), cc.rect(0, 0, display.width, display.height), cc.rect(display.cx - 200, display.cy - 200, 200, 200))
            node:visit()
            texture:endToLua()

            return texture
        end

        local function nodePosToWorldPos(node, anc)
            local x,y = node:getPosition()
            local pp = cc.p(x, y)
            pp = node:convertToWorldSpaceAR(cc.p(0,0))
            local anchor = anc or node:getAnchorPoint()
            local size = node:getContentSize()
            local tx = checkint(pp.x - size.width * (anchor.x - 0.5))
            local ty = checkint(pp.y - size.height * (anchor.y - 0.5))
        
            return cc.p(tx, ty)
        end

        local texture = CreateCutNode(view, qrCodeLayer, display.size)
        texture:setVisible(false)

        local pos = nodePosToWorldPos(qrCodeLayer, cc.p(1,0.5))
        --以render1的texture创建精灵，rect即为所需要的截图部分
        local tempSp = cc.Sprite:createWithTexture(texture:getSprite():getTexture(), cc.rect(pos.x, pos.y, 200, 200))
        tempSp:setAnchorPoint(0, 0)
        tempSp:setPosition(0, 0)
        tempSp:setFlippedY(true)

        local render2 = CreateCutNode(nil, tempSp, cc.size(200,200))

        local toFileName = string.format("%s.jpg", gameMgr:GetUserInfo().playerId)
        local save = render2:saveToFile(toFileName, cc.IMAGE_FORMAT_JPEG, false)
        if save then
            -- gameMgr:GetUserInfo().isSaveQrCode = true
            local qrCodeImgPath = cc.FileUtils:getInstance():getWritablePath() .. toFileName
            FTUtils:storePhotoAlum(qrCodeImgPath)
            uiMgr:ShowInformationTips(__('保存成功'))
        else    
            uiMgr:ShowInformationTips(__('保存失败'))
        end
    elseif tag == BTN_TAG.COPY_LINK then
        -- linkLabel
        local link = self.recommenData.link
        if link then
            FTUtils:storePasteboard(link)
            uiMgr:ShowInformationTips(__('复制链接成功'))
        else
            uiMgr:ShowInformationTips(__('复制链接失败'))
        end
        
    elseif tag == BTN_TAG.PRE_ARROW then
        self.curHeadIndex = self.curHeadIndex - 1
        self:updateQRCodeHead()
    elseif tag == BTN_TAG.NEXT_ARROW then
        self.curHeadIndex = self.curHeadIndex + 1
        self:updateQRCodeHead()
    elseif tag == BTN_TAG.REDEEM_CODE then
        local redeemCodeViewData = self.contentViewDatas[tostring(PROMOTERS_VIEW_TAG.REDEEMCODE)]
        local editBox = redeemCodeViewData.editBox
        local code = editBox:getText()
        local isNil = self:checkStrIsNil(code)
        if not isNil then
            local data = {code = code}
            dump(data)
            self:SendSignal(POST.PRESENT_CODE.cmdName, data)
        else
            uiMgr:ShowInformationTips(__('兑换码不能为空'))
        end
    elseif tag == BTN_TAG.REPLACEMENT_COUPON then
        local UUIDEditBox = self.infoViewData.UUIDEditBox
        local phoneEditBox = self.infoViewData.phoneEditBox

        local uuid = checkint(UUIDEditBox:getText())
        local phoneNum = phoneEditBox:getText()

        if uuid == 0 then 
            uiMgr:ShowInformationTips(__('请重新输入UID'))
            return 
        end
        
        local phoneNumIsNil = self:checkStrIsNil(phoneNum)
        if phoneNumIsNil then 
            uiMgr:ShowInformationTips(__('手机号不能为空'))
            return 
        end
        
        local data = {uuid = uuid, phoneNum = phoneNum}
        self:SendSignal(POST.RECOMMEN_GETPRESENT.cmdName, data)
    end
end


function PromotersMediator:checkHeadRange()
    if self.curHeadIndex < MIN_HEAD_INDEX then
        self.curHeadIndex = MAX_HEAD_INDEX
    elseif self.curHeadIndex > MAX_HEAD_INDEX then
        self.curHeadIndex = MIN_HEAD_INDEX
    end
    self.curHeadId = self.initialHeads[self.curHeadIndex].id
end

function PromotersMediator:checkStrIsNil(str)
    local isNil = (nil == str) or (string.len(string.gsub(str, " ", "")) <= 0)
    
    return isNil
end

function PromotersMediator:enterLayer()
    self:SendSignal(POST.RECOMMEN_HOME.cmdName)
    -- AppFacade.GetInstance():DispatchObservers(POST.RECOMMEN_HOME.sglName)
end

function PromotersMediator:OnRegist()
    regPost(POST.RECOMMEN_HOME)
    regPost(POST.RECOMMEN_GETPRESENT)
    regPost(POST.PRESENT_CODE)
    self:enterLayer()
end

function PromotersMediator:OnUnRegist()
    unregPost(POST.RECOMMEN_HOME)
    unregPost(POST.RECOMMEN_GETPRESENT)
    unregPost(POST.PRESENT_CODE)

    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end

return PromotersMediator