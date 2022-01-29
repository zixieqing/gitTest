--[[
 * author : panmeng
 * descpt : 通用改名界面
]]
local CommonDialog    = require('common.CommonDialog')
local ChangeNamePopup = class('ChangeNamePopup', CommonDialog)

local RES_DICT = {
    BG_FRAME    = _res('ui/common/common_bg_8.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    BTN_CANCEL  = _res('ui/common/common_btn_white_default'),
    BG_EDIT     = _res('ui/home/accountMigration/account_bg_line_1.png'),
    ALPHA_IMG   = _res('ui/common/story_tranparent_bg.png'),
}


function ChangeNamePopup:InitialUI()
    -- init vars
    self.renameCallback_ = self.args.renameCB
    self.renameConsume_  = self.args.renameConsume
    self.preName_        = self.args.preName
    self.isFreeCharge_   = self.args.isFreeCharge

    self.args.title      = self.args.title or __("昵称")

    -- create view
    self.viewData = ChangeNamePopup.CreateView(self.args)
    self:setPosition(display.center)

    -- add listener
    self:getViewData().reNameEditBox:registerScriptEditBoxHandler(handler(self, self.onEditBoxStateChangeHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))
    ui.bindClick(self:getViewData().cancelBtn, handler(self, self.onClickCancelBtnHandler_))
end


function ChangeNamePopup:getViewData()
    return self.viewData
end


function ChangeNamePopup:isFreeCharge()
    return checkbool(self.isFreeCharge_)
end


function ChangeNamePopup:getRenameConsume()
    return checktable(self.renameConsume_)
end


function ChangeNamePopup:getPreName()
    return tostring(self.preName_)
end

-------------------------------------------------
-- handler

function ChangeNamePopup:onEditBoxStateChangeHandler_(eventType, sender)
    if eventType == "return" then
        local text = string.trim(sender:getText())
        text = nativeSensitiveWords(text)
        sender:setText(tostring(text))
    end
end


function ChangeNamePopup:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()

    local inputNameText    = self:getViewData().reNameEditBox:getText()
    if self:getPreName() == inputNameText then
        app.uiMgr:ShowInformationTips(__("名字并未改变"))
    elseif tostring(inputNameText) == "" then
        app.uiMgr:ShowInformationTips(__("修改名不能为空"))
    elseif not CommonUtils.CheckIsDisableInputDay() then
        -- renameConsumeStr
        local renameConsumeStr = nil
        if next(self:getRenameConsume()) == nil or self:isFreeCharge() then
            renameConsumeStr = ""
        elseif type(self:getRenameConsume()[next(self:getRenameConsume())]) == "table" then
            renameConsumeStr = GoodsUtils.GetMultipleConsumeStr(self:getRenameConsume())
        else
            renameConsumeStr = GoodsUtils.GetSingleConsumeStr(self:getRenameConsume())
        end

        -- confirm cb
        local confirmCB        = function()
            local isCanRename  = next(self:getRenameConsume()) == nil or self:isFreeCharge()
            if not isCanRename then
                if type(self:getRenameConsume()[next(self:getRenameConsume())]) == "table" then
                    isCanRename = GoodsUtils.CheckMultipCosts(self:getRenameConsume(), true)
                else
                    isCanRename = GoodsUtils.CheckSingleCosts(self:getRenameConsume(), true)
                end
            end
            if isCanRename then
                if self.renameCallback_ then
                    self.renameCallback_(inputNameText)
                end
                self:CloseHandler()
            end
        end


        if string.len(renameConsumeStr) > 0 then
            app.uiMgr:AddCommonTipDialog({
                text     = string.fmt(self.consumeTip_ or __('是否花费_goodInfo_修改_name_？'), {_goodInfo_ = renameConsumeStr, _name_ = self.args.title}),
                callback = confirmCB,
            })
        else
            confirmCB()
        end
    end
end


function ChangeNamePopup:onClickCancelBtnHandler_(sender)
    PlayAudioByClickNormal()
    self:CloseHandler()
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChangeNamePopup.CreateView(params)
    local size = cc.size(435, 308)
    local view = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    local cpos = cc.sizep(size, ui.cc)

    local title = ui.label({fnt = FONT.D20, fontSize = 30, text = string.fmt(__("修改_name_"), {_name_ = params.title})})
    view:addList(title):alignTo(nil, ui.ct, {offsetY = -50})

    local editBg  = ui.image({img = RES_DICT.BG_EDIT, scale9 = true, size = cc.size(320, 50)})
    view:addList(editBg):alignTo(nil, ui.cc, {offsetY = 10})

    local reNameEditBox = ccui.EditBox:create(cc.resize(editBg:getContentSize(), -20, -14), RES_DICT.ALPHA_IMG)
    display.commonUIParams(reNameEditBox, {po = cc.sizep(size, ui.cc)})
    reNameEditBox:setFontSize(18)
    reNameEditBox:setFontColor(ccc3FromInt("#5d5d5d"))
    reNameEditBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    reNameEditBox:setPlaceHolder(__("请输入关键字"))
    reNameEditBox:setPlaceholderFontSize(18)
    reNameEditBox:setPlaceholderFontColor(ccc3FromInt("#c5c5c5"))
    reNameEditBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    reNameEditBox:setMaxLength(params.inputMaxLen or 20)
    editBg:addList(reNameEditBox):alignTo(nil, ui.cc)

    local btnGroup = view:addList({
        ui.button({n = RES_DICT.BTN_CANCEL}):updateLabel({fnt = FONT.D14, text = __("取消")}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("修改")}),
    })
    local offsetY = params.renameConsume ~= nil and 90 or 70
    ui.flowLayout(cc.rep(cc.sizep(view, ui.cb), 0, offsetY), btnGroup, {type = ui.flowH, ap = ui.cc, gapW = 70})

    if params.renameConsume ~= nil then
        local costLabelList = {}
        if not params.isFreeCharge then
            if type(params.renameConsume[next(params.renameConsume)]) == "table" then
                for _, goodsData in ipairs(params.renameConsume) do
                    table.insert(costLabelList, {fontSize = 24, color = "#2b2017", text = goodsData.num})
                    table.insert(costLabelList, {img = GoodsUtils.GetIconPathById(goodsData.goodsId), scale = 0.2})
                end
            else
                local goodsData = params.renameConsume
                table.insert(costLabelList, {fontSize = 24, color = "#2b2017", text = goodsData.num})
                table.insert(costLabelList, {img = GoodsUtils.GetIconPathById(goodsData.goodsId), scale = 0.2})
            end
        end
        if #costLabelList > 0 then
            table.insert(costLabelList, 1, {text = __("消耗"), fontSize = 24, color = "#2b2017"})
            local costRichLabel = ui.rLabel({r = true, c = costLabelList})
            view:addList(costRichLabel):alignTo(nil, ui.rb, {offsetX = -60, offsetY = 20})
        else
            local costLabelList = ui.label({fontSize = 24, color = "#2b2017", text = __("首次改名免费")})
            view:addList(costLabelList):alignTo(nil, ui.rb, {offsetX = -60, offsetY = 20})
        end
    end

    return {
        view          = view,
        reNameEditBox = reNameEditBox,
        confirmBtn    = btnGroup[2],
        cancelBtn     = btnGroup[1],
    }
end


return ChangeNamePopup
