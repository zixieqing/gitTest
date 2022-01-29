local CommonDialog   = require('common.CommonDialog')
local PetAwakePopup = class('PetAwakePopup', CommonDialog)

local RES_DICT = {
    BG_FRAME    = _res('ui/common/common_bg_8.png'),
    COM_TITLE   = _res('ui/common/common_bg_title_2.png'),
    NUM_BG      = _res('ui/pet/pet_clean_number_bg.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    BTN_NUM     = _res('ui/home/market/market_buy_bg_info.png'),
    BTN_DEL     = _res('ui/home/market/market_sold_btn_sub.png'),
    BTN_ADD     = _res('ui/home/market/market_sold_btn_plus.png'),
    BTN_MAX     = _res('ui/common/pet_clean_btn_number_small.png'),
    BTN_MIN     = _res('ui/common/pet_clean_btn_number_big.png'),
}


function PetAwakePopup:InitialUI()
    -- create view
    self.viewData = PetAwakePopup.CreateView()
    self:setPosition(display.center)

    -- bind event
    ui.bindClick(self:getViewData().btnMin, handler(self, self.onClickMinButtonHandler_))
    ui.bindClick(self:getViewData().btnMax, handler(self, self.onClickMaxButtonHandler_))
    ui.bindClick(self:getViewData().btnDel, handler(self, self.onClickDelButtonHandler_))
    ui.bindClick(self:getViewData().btnAdd, handler(self, self.onClickAddButtonHandler_))
    ui.bindClick(self:getViewData().btnNum, handler(self, self.onClickNumButtonHandler_), false)
    ui.bindClick(self:getViewData().btnConfirm, handler(self, self.onClickConfirmButtonHandler))

    -- update view
    self:initView()
end


function PetAwakePopup:getViewData()
    return self.viewData
end


-------------------------------------------------------------------------------
-- get/set
-------------------------------------------------------------------------------
function PetAwakePopup:setSelectedNum(num)
    self.num_ = checkint(num)
    self:getViewData().btnNum:setText(self:getSelectedNum())
end
function PetAwakePopup:getSelectedNum()
    return checkint(self.num_)
end


function PetAwakePopup:getMaxNum()
    return self.args.maxNum or 1
end
-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------
function PetAwakePopup:onClickDelButtonHandler_(sender)
    PlayAudioByClickNormal()

    if self:getSelectedNum() <= 1 then
        app.uiMgr:ShowInformationTips(__('已达最小次数'))
    else
        self:setSelectedNum(self:getSelectedNum() - 1)
    end
end


function PetAwakePopup:onClickAddButtonHandler_(sender)
    PlayAudioByClickNormal()

    if self:getSelectedNum() >= self:getMaxNum() then
        app.uiMgr:ShowInformationTips(__('已达最大次数'))
    else
        self:setSelectedNum(self:getSelectedNum() + 1)
    end
end


function PetAwakePopup:onClickNumButtonHandler_(sender)
    PlayAudioByClickNormal()

    if self:getMaxNum() > 0 then
        local tempData = {
            callback = handler(self, self.onClickKeyBoardReturn),
            titleText = string.fmt(__('请输入觉醒数量'), {_num_ = self:getMaxNum()}),
            nums = math.floor(math.log10(self:getMaxNum())) + 1,
            model = NumboardModel.freeModel,
        }

        local mediator = require( 'Game.mediator.NumKeyboardMediator' ).new(tempData)
        app:RegistMediator(mediator)
    else
        app.uiMgr:ShowInformationTips(__('当前状态不可更改觉醒数量'))
    end
end


function PetAwakePopup:onClickConfirmButtonHandler(sender)
    PlayAudioByClickNormal()

    if self:getSelectedNum() <= 0 then
        app.uiMgr:ShowInformationTips(__('请输入有效的觉醒数量'))
    else
        if self.args.callback then
            self.args.callback(self:getSelectedNum())
        end
        self:CloseHandler()
    end
end


function PetAwakePopup:onClickKeyBoardReturn(data) 
    PlayAudioByClickNormal()

    if not data then return end
    local useNum = checkint(data)
    if useNum <= 0 then
        useNum = 1
    elseif useNum > self:getMaxNum() then
        useNum = self:getMaxNum()
    end
    self:setSelectedNum(useNum)
end


function PetAwakePopup:onClickMinButtonHandler_(sender)
    PlayAudioByClickNormal()

    self:setSelectedNum(math.min(1, self:getMaxNum()))
end


function PetAwakePopup:onClickMaxButtonHandler_(sender)
    PlayAudioByClickNormal()

    self:setSelectedNum(self:getMaxNum())
end
-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------
function PetAwakePopup:initView()
    local viewData = self:getViewData()

    viewData.title:setVisible(self.args.title ~= nil)
    if self.args.title then
        viewData.title:updateLabel({text = self.args.title, reqW = 550})
    end

    viewData.descr:setVisible(self.args.descr ~= nil)
    if self.args.descr then
        viewData.descr:updateLabel({text = self.args.descr, reqW = 550})
    end

    viewData.numTitle:setVisible(self.args.numTitle ~= nil)
    if self.args.numTitle then
        viewData.numTitle:setText(self.args.numTitle)
    end

    if self.args.confirmStr then
        viewData.btnConfirm:updateLabel({text = self.args.confirmStr, reqW = 110})
    end

    viewData.limitLabel:setVisible(self.args.limitNum ~= nil)
    if self.args.limitNum then
        viewData.limitLabel:setString(string.fmt(__("单次上限:_num_"), {_num_ = self.args.limitNum}))
    end

    self:setSelectedNum(math.min(1, self:getMaxNum()))
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function PetAwakePopup.CreateView()
    local size = cc.size(display.width * 0.4, 370)
    local view = ui.layer({bg = RES_DICT.BG_FRAME, scale9 = true, size = size, cut = cc.dir(50, 50, 1, 1)})
    local cpos = cc.sizep(size, ui.cc)

    local viewGroup = view:addList({
        ui.label({fnt = FONT.D4, text = "--", fontSize = 28}),
        ui.label({fnt = FONT.D6, text = "--", fontSize = 26}),
        ui.title({img = RES_DICT.NUM_BG, mt = 14, ap = ui.lc}):updateLabel({fnt = FONT.D4, color = "#6c4a31", text = "--", ap = ui.lc, offset = cc.p(-80, 0)}),
        ui.layer({size = cc.size(390, 70)}),
        ui.label({fnt = FONT.D9, color = "#c7ad9e", text = "--"}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = "--"}),
    })
    ui.flowLayout(cc.rep(cpos, -10, -14), viewGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})

    local numLayer = viewGroup[4]
    local numGroup = numLayer:addList({
        ui.button({n = RES_DICT.BTN_MIN}):updateLabel({fnt = FONT.D9, color = "#c7ad9e", text = __("最小"), offset = cc.p(0, -35)}),
        ui.button({n = RES_DICT.BTN_DEL, zorder = 2}),
        ui.button({n = RES_DICT.BTN_NUM, zorder = 1, ml = -4, scale9 = true, size = cc.size(200, 45)}):updateLabel({fnt = FONT.D4, color = "#AA0000", text = "--"}),
        ui.button({n = RES_DICT.BTN_ADD, zorder = 2, ml = -4}),
        ui.button({n = RES_DICT.BTN_MAX}):updateLabel({fnt = FONT.D9, color = "#c7ad9e", text = __("最大"), offset = cc.p(0, -35)}),
    })
    ui.flowLayout(cc.sizep(numLayer, ui.cc), numGroup, {type = ui.flowH, ap = ui.cc})

    local numTitle = viewGroup[3]
    numTitle:setPositionX(numLayer:getPositionX() + numGroup[1]:getContentSize().width)

    return {
        view       = view,
        title      = viewGroup[1],
        descr      = viewGroup[2],
        limitLabel = viewGroup[5],
        btnConfirm = viewGroup[6],
        numTitle   = numTitle,
        btnMin     = numGroup[1],
        btnDel     = numGroup[2],
        btnNum     = numGroup[3],
        btnAdd     = numGroup[4],
        btnMax     = numGroup[5],
    }
end


return PetAwakePopup
