--[[
 * author : panmeng
 * descpt : 猫咪改名界面
]]
local CommonDialog             = require('common.CommonDialog')
local CatModuleChangeNamePopup = class('CatModuleChangeNamePopup', CommonDialog)

local RES_DICT = {
    BG_FRAME    = _res('ui/common/common_bg_8.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    BTN_CANCEL  = _res('ui/common/common_btn_white_default'),
    BG_EDIT     = _res('ui/home/accountMigration/account_bg_line_1.png'),
    ALPHA_IMG   = _res('ui/common/story_tranparent_bg.png'),
}


function CatModuleChangeNamePopup:InitialUI()
    -- init vars
    self.renameCallback_ = self.args.renameCB
    self.isRenamed_      = self.args.isRenamed

    -- create view
    self.viewData = CatModuleChangeNamePopup.CreateView(self:isRenamed())
    self:setPosition(display.center)

    -- add listener
    self:getViewData().reNameEditBox:registerScriptEditBoxHandler(handler(self, self.onEditBoxStateChangeHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))
    ui.bindClick(self:getViewData().cancelBtn, handler(self, self.onClickCancelBtnHandler_))
end


function CatModuleChangeNamePopup:getViewData()
    return self.viewData
end


function CatModuleChangeNamePopup:isRenamed()
    return checkbool(self.isRenamed_)
end


-------------------------------------------------
-- handler

function CatModuleChangeNamePopup:onEditBoxStateChangeHandler_(eventType, sender)
    if eventType == "return" then
        local text = string.trim(sender:getText())
        text = nativeSensitiveWords(text)
        sender:setText(tostring(text))
    end
end


function CatModuleChangeNamePopup:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()

    local renameConsumeStr = not self:isRenamed() and '' or GoodsUtils.GetMultipleConsumeStr(CatHouseUtils.CAT_PARAM_FUNCS.RENAME_CONSUME())
    local inputNameText = self:getViewData().reNameEditBox:getText()
    local confirmCB     = function()
        if self.renameCallback_ then
            self.renameCallback_(inputNameText)
        end
        self:CloseHandler()
    end
    if string.len(inputNameText) > 0 then
        if string.len(renameConsumeStr) > 0 then
            app.uiMgr:AddCommonTipDialog({
                text     = string.fmt(__('是否花费_goodInfo_修改昵称？'), {_goodInfo_ = renameConsumeStr}),
                callback = confirmCB,
            })
        else
            confirmCB()
        end
    else
        app.uiMgr:ShowInformationTips(__('名字不能为空'))
    end
end


function CatModuleChangeNamePopup:onClickCancelBtnHandler_(sender)
    PlayAudioByClickNormal()
    self:CloseHandler()
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleChangeNamePopup.CreateView(isRenamed)
    local size = cc.size(435, 308)
    local view = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    local cpos = cc.sizep(size, ui.cc)

    local title = ui.label({fnt = FONT.D20, fontSize = 32, text = __("修改昵称")})
    view:addList(title):alignTo(nil, ui.ct, {offsetY = -40})

    local editBg  = ui.image({img = RES_DICT.BG_EDIT, scale9 = true, size = cc.size(320, 50)})
    view:addList(editBg):alignTo(nil, ui.cc, {offsetY = 20})

    local reNameEditBox = ccui.EditBox:create(cc.resize(editBg:getContentSize(), -20, -14), RES_DICT.ALPHA_IMG)
    display.commonUIParams(reNameEditBox, {po = cc.sizep(size, ui.cc)})
    reNameEditBox:setFontSize(18)
    reNameEditBox:setFontColor(ccc3FromInt("#5d5d5d"))
    reNameEditBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    reNameEditBox:setPlaceHolder(__("请输入关键字"))
    reNameEditBox:setPlaceholderFontSize(18)
    reNameEditBox:setPlaceholderFontColor(ccc3FromInt("#c5c5c5"))
    reNameEditBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    reNameEditBox:setMaxLength(20)
    editBg:addList(reNameEditBox):alignTo(nil, ui.cc)

    local btnGroup = view:addList({
        ui.button({n = RES_DICT.BTN_CANCEL}):updateLabel({fnt = FONT.D14, text = __("取消")}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("修改")}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.cb), 0, 90), btnGroup, {type = ui.flowH, ap = ui.cc, gapW = 100})

    local costLabelList = {}
    if isRenamed then
        for _, goodsData in ipairs(CatHouseUtils.CAT_PARAM_FUNCS.RENAME_CONSUME()) do
            table.insert(costLabelList, {fontSize = 24, color = "#2b2017", text = goodsData.num})
            table.insert(costLabelList, {img = GoodsUtils.GetIconPathById(goodsData.goodsId), scale = 0.2})
        end
    end
    if #costLabelList > 0 then
        table.insert(costLabelList, 1, {text = __("消耗"), fontSize = 24, color = "#2b2017"})
        local costRichLabel = ui.rLabel({r = true, c = costLabelList})
        view:addList(costRichLabel):alignTo(nil, ui.rb, {offsetX = -40, offsetY = 20})
    else
        local costLabelList = ui.label({fontSize = 24, color = "#2b2017", text = __("首次改名免费")})
        view:addList(costLabelList):alignTo(nil, ui.rb, {offsetX = -50, offsetY = 20})
    end

    return {
        view          = view,
        reNameEditBox = reNameEditBox,
        confirmBtn    = btnGroup[2],
        cancelBtn     = btnGroup[1],
    }
end


return CatModuleChangeNamePopup
