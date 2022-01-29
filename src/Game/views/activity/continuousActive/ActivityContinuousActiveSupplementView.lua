--[[
 * author : liuzhipeng
 * descpt : 活动 连续活跃活动 补签view
--]]
local ActivityContinuousActiveSupplementView = class('ActivityContinuousActiveSupplementView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.view.activity.continuous.ActivityContinuousActiveSupplementView'
    node:enableNodeEvents()
    return node
end)
local CALENDAR_STATE = {
    UNSIGNED = 0,
    SIGNED = 1,
    LOCK = 2,
}
local RES_DICT = {
    ACTIVITY_BG           = _res('ui/home/activity/continuousActive/activity_bg.jpg'),
    BG_INFO               = _res('ui/home/activity/continuousActive/calendar_bg_info.png'),
    BG_INFO_S             = _res('ui/home/activity/continuousActive/calendar_bg_info_s.png'),
    BG_INFO_NUM           = _res('ui/home/activity/continuousActive/calendar_bg_info_num.png'),
    ROLE_IMG              = _res('ui/home/activity/continuousActive/calendar_role_1.png'),
    CALENDAR_BG           = _res('ui/home/activity/continuousActive/calendar_bg.png'),
    COMMON_BTN_GREEN      = _res('ui/common/common_btn_green.png'),
    -- cell
    CELL_BG               = _res('ui/home/activity/continuousActive/calendar_bg_day_default.png'),
    CELL_SIGNED           = _res('ui/home/activity/continuousActive/calendar_bg_catch_day_signed.png'),
    CELL_UNSIGNED         = _res('ui/home/activity/continuousActive/calendar_bg_catch_day_unsign.png'),
    CELL_TODAY            = _res('ui/home/activity/continuousActive/calendar_bg_catch_day_today.png'),
    CELL_SELECTED         = _res('ui/home/activity/continuousActive/calendar_bg_catch_day_selected.png'),
    COMMON_BTN_SWITCH     = _res('ui/common/common_btn_switch.png'),


}
function ActivityContinuousActiveSupplementView:ctor( ... )
    self.args = unpack({...})
    self.calendarData = self:ConvertCalendarData(self.args.yearProgressDetail)
    self.selectedIndex = #self.calendarData
    self.firstSelectedId = nil
    self:InitUI()
end
--[[
init ui
--]]
function ActivityContinuousActiveSupplementView:InitUI()
    local CreateView = function ()
        local size = cc.size(1030, 690) 
        local view = CLayout:create(size)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        local bg = display.newImageView(RES_DICT.ACTIVITY_BG, 0, size.height / 2, {scale9 = true, size = cc.size(670, 670), capInsets = cc.rect(50, 50, 928, 530), ap = display.LEFT_CENTER})
        view:addChild(bg, 1)
        
        local calendarTitleLabel = display.newLabel(10, size.height - 40, {ap = display.LEFT_CENTER, text = '', fontSize = 50, color = '#b4350e', ttf = true, font = TTF_GAME_FONT})
        view:addChild(calendarTitleLabel, 5)
        local calendarTipsLabel = display.newLabel(10, size.height - 80, fontWithColor(5, {ap = display.LEFT_CENTER, text = __('选中漏签的日期可进行补签哦')}))
        view:addChild(calendarTipsLabel, 5)
        local pageupBtn = display.newButton(248, 40, {n = RES_DICT.COMMON_BTN_SWITCH})
        pageupBtn:setScaleX(-1)
        view:addChild(pageupBtn, 5)
        local pagedownBtn = display.newButton(420, 40, {n = RES_DICT.COMMON_BTN_SWITCH})
        view:addChild(pagedownBtn, 5)
        local currentMonthLabel = display.newLabel(334, 40, fontWithColor(14, {text = '', fontSize = 34}))
        view:addChild(currentMonthLabel, 5)
        -- 日历Layout -- 
        local calendarLayoutSize = cc.size(615, 520)
        local calendarLayout = CLayout:create(calendarLayoutSize)
        display.commonUIParams(calendarLayout, {ap = display.LEFT_BOTTOM, po = cc.p(17, 70)})
        view:addChild(calendarLayout, 1)
        local calendarBg = display.newImageView(RES_DICT.CALENDAR_BG, calendarLayoutSize.width / 2, calendarLayoutSize.height / 2)
        calendarLayout:addChild(calendarBg, 1)
        local dayName = {__('日'), __('一'), __('二'), __('三'), __('四'), __('五'), __('六')}
        if isElexSdk() then
            dayName = {__('周日'), __('周一'), __('周二'), __('周三'), __('周四'), __('周五'), __('周六')}
        end
        for i, v in ipairs(dayName) do
            local label = display.newLabel(- 40 + i * 87, calendarLayoutSize.height - 20, {text = dayName[i], color = '#ffffff', fontSize = 20})
            calendarLayout:addChild(label, 1)
        end
        -- 日历列表
        local calendarGridViewSize = cc.size(calendarLayoutSize.width, 480)
        local calendarGridViewCellSize = cc.size(calendarGridViewSize.width / 7, calendarGridViewSize.height / 5)
        local calendarGridView = CGridView:create(calendarGridViewSize)
        calendarGridView:setSizeOfCell(calendarGridViewCellSize)
        calendarGridView:setColumns(7)
        calendarGridView:setBounceable(false)
        calendarLayout:addChild(calendarGridView, 3)
        display.commonUIParams(calendarGridView, {ap = display.CENTER_BOTTOM, po = cc.p(calendarLayoutSize.width / 2, 2)})


        -- 信息面板Layout -- 
        local infoLayoutSize = cc.size(400, 700)
        local infoLayout = CLayout:create(infoLayoutSize)
        infoLayout:setPosition(cc.p(size.width / 2 + 335, size.height / 2))
        view:addChild(infoLayout, 1)
        local infoLayoutBg = display.newImageView(RES_DICT.BG_INFO, -5, infoLayoutSize.height / 2, {ap = display.LEFT_CENTER})
        infoLayout:addChild(infoLayoutBg, 1)
        -- local roleImg = display.newImageView(RES_DICT.ROLE_IMG, 0, infoLayoutSize.height / 2, {ap = display.LEFT_CENTER})
        -- infoLayout:addChild(roleImg, 2)

        local unsignedBg = display.newImageView(RES_DICT.BG_INFO_S, 5, 365, {ap = display.LEFT_BOTTOM})
        infoLayout:addChild(unsignedBg, 3)
        local unsignedTextLabel = display.newLabel(18, 438, {text = __('未签到天数'), fontSize = 24, color = '#859bbf', ap = display.LEFT_CENTER})
        infoLayout:addChild(unsignedTextLabel, 5)
        local unsignedNumBg = display.newImageView(RES_DICT.BG_INFO_NUM, 18, 398, {ap = display.LEFT_CENTER})
        infoLayout:addChild(unsignedNumBg, 4)
        local unsignedNumLabel = display.newLabel(18, 398, {text = '', color = '#ffffff', fontSize = 36, ap = display.LEFT_CENTER})
        infoLayout:addChild(unsignedNumLabel, 5)

        local supplementBg = display.newImageView(RES_DICT.BG_INFO_S, 5, 128, {ap = display.LEFT_BOTTOM, scale9 = true, size = cc.size(263, 180), capInsets = cc.rect(10, 10, 243, 86)})
        infoLayout:addChild(supplementBg, 3)
        local selectedTextLabel = display.newLabel(18, 285, {text = __('已选中天数'), fontSize = 24, color = '#859bbf', ap = display.LEFT_CENTER})
        infoLayout:addChild(selectedTextLabel, 5)
        local selectedNumBg = display.newImageView(RES_DICT.BG_INFO_NUM, 18, 245, {ap = display.LEFT_CENTER})
        infoLayout:addChild(selectedNumBg, 4)
        local selectedNumLabel = display.newLabel(18, 245, {text = '', color = '#ffffff', fontSize = 36, ap = display.LEFT_CENTER})
        infoLayout:addChild(selectedNumLabel, 5)
        local costTextLabel = display.newLabel(18, 200, {text = __('需要消耗'), fontSize = 24, color = '#859bbf', ap = display.LEFT_CENTER})
        infoLayout:addChild(costTextLabel, 5)
        local costNumBg = display.newImageView(RES_DICT.BG_INFO_NUM, 18, 160, {ap = display.LEFT_CENTER})
        infoLayout:addChild(costNumBg, 4)
        local costNumRichLabel = display.newRichLabel(18, 160, {ap = display.LEFT_CENTER})
        infoLayout:addChild(costNumRichLabel, 4)
        
        local supplementBtn = display.newButton(150, 72, {n = RES_DICT.COMMON_BTN_GREEN})
        infoLayout:addChild(supplementBtn, 3)
        display.commonLabelParams(supplementBtn, fontWithColor(14, {text = __('补签')}))

        -- local cardPreviewBtn = require("common.CardPreviewEntranceNode").new({confId = 200110})
        -- display.commonUIParams(cardPreviewBtn, {ap = display.LEFT_CENTER, po = cc.p(infoLayoutSize.width - 130, 55)})
        -- infoLayout:addChild(cardPreviewBtn, 5)

        return {
            view                     = view,
            calendarGridViewSize     = calendarGridViewSize,
            calendarGridViewCellSize = calendarGridViewCellSize,
            calendarGridView         = calendarGridView,
            pageupBtn                = pageupBtn,
            pagedownBtn              = pagedownBtn,
            supplementBtn            = supplementBtn,
            unsignedNumLabel         = unsignedNumLabel,
            currentMonthLabel        = currentMonthLabel,
            calendarTitleLabel       = calendarTitleLabel,
            selectedNumLabel         = selectedNumLabel,
            costNumRichLabel         = costNumRichLabel,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function () 
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.pageupBtn:setOnClickScriptHandler(handler(self, self.PageupButtonCallback))
        self.viewData.pagedownBtn:setOnClickScriptHandler(handler(self, self.PagedownButtonCallback))
        self.viewData.supplementBtn:setOnClickScriptHandler(handler(self, self.SupplementButtonCallback))
        self.viewData.calendarGridView:setDataSourceAdapterScriptHandler(handler(self, self.CalendarDataSourceAdapter))
        self:RefreshView()
    end, __G__TRACKBACK__)
end
--[[
上一页按钮点击回调
--]]
function ActivityContinuousActiveSupplementView:PageupButtonCallback( sender )
    PlayAudioByClickNormal()
    if self.selectedIndex > 1 then
        self.selectedIndex= self.selectedIndex - 1
        self:RefreshView()
    end
end
--[[
下一页按钮点击回调
--]]
function ActivityContinuousActiveSupplementView:PagedownButtonCallback( sender )
    PlayAudioByClickNormal()
    if self.selectedIndex < #self.calendarData then
        self.selectedIndex= self.selectedIndex + 1
        self:RefreshView()
    end
end
--[[
补签按钮点击回调
--]]
function ActivityContinuousActiveSupplementView:SupplementButtonCallback( sender )
    PlayAudioByClickNormal()
    local str = ''
    local num = 0
    for _, monthData in ipairs(self.calendarData) do
        for _, v in ipairs(monthData.detail) do
            if v.selected then
                if str ~= '' then 
                    str = str .. ','
                end
                str = str .. tostring(v.id)
                num = num + 1
            end
        end
    end
    local currency = checkint(self.args.yearSupplementCurrency)
    local price = num *checkint(self.args.yearSupplementPrice)
    local config = CommonUtils.GetConfig('goods', 'goods', currency) or {}
    if str == '' then
        app.uiMgr:ShowInformationTips(__('选择需要补签的天数'))
    elseif app.gameMgr:GetAmountByIdForce(currency) < price then
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = config.name}))
    else
        app.uiMgr:AddCommonTipDialog({
            callback = function () 
                AppFacade.GetInstance():DispatchObservers(ACTIVITY_CONTINUOUS_ACTIVE_SUPPLEMENT, {str = str, num = num})
                self:runAction(cc.RemoveSelf:create())
            end,
            text = string.fmt(__('是否花费_num__name_补签？'), {['_num_'] = price, ['_name_'] = config.name}),
        })
    end
end
--[[
日历列表点击回调
--]]
function ActivityContinuousActiveSupplementView:CellButtonCallback( sender )
    local tag = sender:getTag()
    local data = self.calendarData[self.selectedIndex].detail[tag]
    if not data or data.state ~= CALENDAR_STATE.UNSIGNED or data.today then return end
    PlayAudioByClickNormal()
    if data.selected then
        data.selected = false
        self.firstSelectedId = nil
        
    else
        data.selected = true
        if self.firstSelectedId then
            local startId = math.min(data.id, self.firstSelectedId)
            local endId = math.max(data.id, self.firstSelectedId)
            self:ContinuousSelected(startId, endId)
            self.firstSelectedId = nil 
        else
            self.firstSelectedId = data.id
        end
    end
    self:RefreshCalendarGridView()
    self:RefreshSelectedNumLabel()
end
--[[
日历列表处理
--]]
function ActivityContinuousActiveSupplementView:CalendarDataSourceAdapter( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewData = self:GetViewData()
    if pCell == nil then
        local size = viewData.calendarGridViewCellSize
        pCell = CGridViewCell:new()
        pCell:setAnchorPoint(display.CENTER)
        pCell:setContentSize(size)
        local view = CLayout:create(size)
        view:setPosition(cc.p(size.width / 2, size.height / 2))
        pCell:addChild(view, 1)
        local bg = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.CELL_BG})
        view:addChild(bg, 1)
        bg:setOnClickScriptHandler(handler(self, self.CellButtonCallback))
        local dayLabel = display.newLabel(size.width - 7, 10, {text = 1, fontSize = 28, color = '#e0d2c1', ap = display.RIGHT_BOTTOM})
        view:addChild(dayLabel, 3)
        local stateIcon = display.newImageView(RES_DICT.CELL_SIGNED, size.width / 2, size.height / 2)
        view:addChild(stateIcon, 2)
        local selectedFrame = display.newImageView(RES_DICT.CELL_SELECTED, size.width / 2, size.height / 2)
        view:addChild(selectedFrame, 5)
        pCell.view = view
        pCell.bg = bg
        pCell.dayLabel = dayLabel
        pCell.stateIcon = stateIcon
        pCell.selectedFrame = selectedFrame
    end
    xTry(function()
        if self:IsSpecialCalendarFormat() then
            pCell.view:setScale(0.9)
        else
            pCell.view:setScale(1)
        end
        local data = self.calendarData[self.selectedIndex].detail[index]
        pCell.bg:setTag(index)
        pCell.dayLabel:setString(data.day or '')
        pCell.bg:setVisible(data.day and true or false)
        pCell.stateIcon:setVisible(data.state ~= CALENDAR_STATE.LOCK)
        pCell.selectedFrame:setVisible(data.selected)
        if data.state == CALENDAR_STATE.UNSIGNED then 
            if data.today then
                pCell.stateIcon:setTexture(RES_DICT.CELL_TODAY)
            else
                pCell.stateIcon:setTexture(RES_DICT.CELL_UNSIGNED)
            end
        elseif data.state == CALENDAR_STATE.SIGNED then 
            pCell.stateIcon:setTexture(RES_DICT.CELL_SIGNED)
        elseif data.state == CALENDAR_STATE.LOCK then 
        end
    end,__G__TRACKBACK__)
    return pCell
end
--[[
初始化日历数据
@params yearProgressDetail string 签到信息
--]]
function ActivityContinuousActiveSupplementView:ConvertCalendarData( yearProgressDetail )
    local calendarData = {}
    local date = os.date('!*t', getServerTime() + getServerTimezone())
    local year = date.year
    local month = date.month
    local day = date.day
    local function insertMonthData( progressDetail )
        local monthData = {
            year = year,
            month = month,
            detail = {},
        }
        local len = string.len(progressDetail)
        local num = checkint(os.date("!%d", os.time({year = year, month = month + 1, day = 0}))) -- 本月天数
        local wday = os.date("!%w", os.time({year = year, month = month, day = 1})) + 1 -- 1号是星期几
        local finDay = day or num -- 结束日期
        local monthDetail = len >= finDay and string.sub(progressDetail, -finDay) or progressDetail -- 签到详情
        local startDay = finDay - string.len(monthDetail) + 1 -- 开始日期
        local index = 1
        for i = 1, 42 do
            if i >= wday and index <= num then
                local temp = {
                    day = index,
                    state = CALENDAR_STATE.LOCK,
                    selected = false,
                    today = day and (index == finDay and true) or false,
                    id = len - finDay + index
                }
                if index >= startDay and index <= finDay then
                    temp.state = checkint(string.sub(monthDetail, 1, 1))
                    monthDetail = string.sub(monthDetail, 2, -1)
                end
                table.insert(monthData.detail, temp)
                index = index + 1
            else
                table.insert(monthData.detail, {
                    state = CALENDAR_STATE.LOCK,
                    selected = false
                })
            end
        end
        table.insert(calendarData, 1, monthData)
        if len > finDay then
            day = nil 
            if month > 1 then
                month = month - 1
            else
                month = 12
                year = year - 1
            end
            insertMonthData(string.sub(progressDetail, 1, len - finDay))
        end
    end
    insertMonthData(yearProgressDetail)
    return calendarData
end
--[[
刷新页面
--]]
function ActivityContinuousActiveSupplementView:RefreshView()
    self:RefreshCalendarGridView()
    self:RefreshPageTurningButton()
    self:RefreshCurrentMonth()
    self:RefreshUnsignedNumLabel()
    self:RefreshSelectedNumLabel()
end
--[[
刷新当前月份
--]]
function ActivityContinuousActiveSupplementView:RefreshCurrentMonth()
    local viewData = self:GetViewData()
    local data = self.calendarData[self.selectedIndex]
    local year = string.fmt(__('_num_年'), {['_num_'] = data.year})
    local month = string.fmt(__('_num_月'), {['_num_'] = data.month})
    viewData.currentMonthLabel:setString(month)
    viewData.calendarTitleLabel:setString(year .. month)
end
--[[
刷新日历列表
--]]
function ActivityContinuousActiveSupplementView:RefreshCalendarGridView()
    local viewData = self:GetViewData()
    local calendarGridView = viewData.calendarGridView
    local data = self.calendarData[self.selectedIndex].detail
    if self:IsSpecialCalendarFormat() then
        calendarGridView:setSizeOfCell(cc.size(viewData.calendarGridViewSize.width / 7, viewData.calendarGridViewSize.height / 6))
        calendarGridView:setCountOfCell(42)
        calendarGridView:reloadData()
    else
        calendarGridView:setSizeOfCell(cc.size(viewData.calendarGridViewSize.width / 7, viewData.calendarGridViewSize.height / 5))
        calendarGridView:setCountOfCell(35)
        calendarGridView:reloadData()
    end
end
--[[
刷新翻页按钮状态
--]]
function ActivityContinuousActiveSupplementView:RefreshPageTurningButton()
    local viewData = self:GetViewData()
    viewData.pageupBtn:setVisible(self.selectedIndex > 1)
    viewData.pagedownBtn:setVisible(self.selectedIndex < #self.calendarData)
end 
--[[
刷新未签到天数
--]]
function ActivityContinuousActiveSupplementView:RefreshUnsignedNumLabel()
    local viewData = self:GetViewData()
    local yearProgressDetail = self.args.yearProgressDetail
    local _, num = string.gsub(yearProgressDetail, '0', '0')
    viewData.unsignedNumLabel:setString(checkint(num))
end
--[[
刷新已选中天数
--]]
function ActivityContinuousActiveSupplementView:RefreshSelectedNumLabel()
    local viewData = self:GetViewData()
    local num = 0 
    for _, monthData in ipairs(self.calendarData) do
        for _, v in ipairs(monthData.detail) do
            if v.selected then
                num = num + 1
            end
        end
    end
    viewData.selectedNumLabel:setString(num)
    display.reloadRichLabel(viewData.costNumRichLabel, { c = {
        {text = tostring(num * checkint(self.args.yearSupplementPrice)), fontSize = 30, color = '#ffffff'},
        {text = ' ', fontSize = 20, color = '#ffffff'},
        {img = CommonUtils.GetGoodsIconPathById(self.args.yearSupplementCurrency), scale = 0.2}
    }})
end
--[[
判断日历是否为特殊格式（6行）
--]]
function ActivityContinuousActiveSupplementView:IsSpecialCalendarFormat()
    local data = self.calendarData[self.selectedIndex].detail
    return data[36].day and true or false
end
--[[
连续选择
--]]
function ActivityContinuousActiveSupplementView:ContinuousSelected( startId, endId )
    for _, monthData in ipairs(self.calendarData) do
        for _, v in ipairs(monthData.detail) do
            if v.id and v.id > endId then return end
            if v.id and v.id >= startId and v.id <= endId and v.state == CALENDAR_STATE.UNSIGNED then
                v.selected = true
            end
        end
    end
end
--[[
获取viewData
--]]
function ActivityContinuousActiveSupplementView:GetViewData()
    return self.viewData
end
return ActivityContinuousActiveSupplementView