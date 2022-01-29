--[[
好友备注页面
--]]
local FriendRemarkPopup = class('FriendRemarkPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'common.FriendRemarkPopup'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG         = _res('ui/common/common_bg_8.png'),
    COMMON_BTN = _res('ui/common/common_btn_orange.png'),
    EDITBOX_BG = _res('ui/home/friend/create_roles_bg_name.png')
    
}
function FriendRemarkPopup:ctor( ... )
    local args = unpack({...})
    self.friendId = checkint(args.friendId)
    self:InitUI()
end
function FriendRemarkPopup:InitUI()
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- editBox
        local editBox = ccui.EditBox:create(cc.size(296, 50), RES_DICT.EDITBOX_BG)
        display.commonUIParams(editBox, {po = cc.p(size.width / 2, size.height / 2 + 40)})
        view:addChild(editBox, 5)
        editBox:setFontSize(24)
        editBox:setFontColor(ccc3FromInt('#5B3C25'))
        editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        editBox:setPlaceHolder(__('输入备注名'))
        editBox:setPlaceholderFontSize(24)
        editBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
        editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        editBox:setMaxLength(12)
        -- confirmBtn
        local confirmBtn = display.newButton(size.width / 2, 65, {n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确定')}))
        view:addChild(confirmBtn, 5)
        return {
            view       = view,
            editBox    = editBox,
            confirmBtn = confirmBtn,

		}
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function ()
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    self.viewData = CreateView( )
    self:addChild(self.viewData.view)
    self.viewData.view:setPosition(display.center)
    self.viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.confirmButtonCallback))
    -- action
    self.viewData.view:setScale(0.5)
    self.viewData.view:runAction(
        cc.EaseBackOut:create(cc.ScaleTo:create(0.25, 1))
    )
end
--[[
确认按钮点击回调
--]]
function FriendRemarkPopup:confirmButtonCallback( sender )
    PlayAudioByClickNormal()
    local viewData = self:GetViewData()
    local str = viewData.editBox:getText()
    if str == '' then
        app.uiMgr:ShowInformationTips(__('备注不能为空'))
    else
        if not CommonUtils.CheckIsDisableInputDay() then
            local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
            if mediator then
                mediator:SendSignal(POST.FRIEND_REMARK.cmdName, {friendId = self.friendId, noteName = str})
                self:runAction(cc.RemoveSelf:create())
            end
        end
    end
end
--[[
获取viewData
--]]
function FriendRemarkPopup:GetViewData()
    return self.viewData
end
return FriendRemarkPopup
