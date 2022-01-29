--[[
日期选择
--]]
local VIEW_SIZE = display.size
local DateSelectView = class('DateSelectView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'common.DateSelectView'
    node:enableNodeEvents()
    return node
end)

local CreateView = nil
local CreateCell = nil

local RES_DICT = {
    COMMON_BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_WHITE_DEFAULT     = _res('ui/common/common_btn_white_default.png'),
    CREATE_ROLES_BIRTHDAY_BG     = _res('ui/author/createPlayer/create_roles_birthday_bg.png'),
    CREATE_ROLES_BIRTHDAY_SELECT = _res('ui/author/createPlayer/create_roles_birthday_select.png'),
    
}

local DATE_TAG = {
    YEAR  = 1,
    MONTH = 2,
    DAY   = 3,
}

local DAY_COUNT = {
    [1]  = 31, [3]  = 31,
    [4]  = 30, [5]  = 31,
    [6]  = 30, [7]  = 31,
    [8]  = 31, [9]  = 30,
    [10] = 31, [11] = 30,
    [12] = 31,
}

local DATE_NAME = {
    [DATE_TAG.YEAR]  = __('%d年'),
    [DATE_TAG.MONTH] = __('%d月'),
    [DATE_TAG.DAY]   = __('%d号'),
}


function DateSelectView:ctor( ... )
    self.args  = unpack({...}) or {}
    self.datas = {}
    self.clickCellTag = 0

    self:InitUI()
end
--[[
init ui
--]]
function DateSelectView:InitUI()
    xTry(function ( )
        local selectIndexData = self:InitData(self.args)

        logInfo.add(5, tableToString(selectIndexData))

        self.viewData_ = CreateView(VIEW_SIZE, selectIndexData)
        self:addChild(self.viewData_.view)

        self:InitView()
	end, __G__TRACKBACK__)
end

function DateSelectView:InitData(data)
    local curDateData = os.date("*t")
    local curYear     = curDateData.year
    local curMonth    = curDateData.month
    local curDay      = curDateData.day

    local selectYear
    local selectMonth
    local selectDay
    local maxYear  = curYear
    local maxMonth = curMonth
    local maxDay   = curDay
    if next(data) then
        selectYear, selectMonth, selectDay = checkint(data.year), checkint(data.month), checkint(data.day)

        if selectYear ~= curYear then
            maxMonth = selectMonth ~= curMonth and 12 or curMonth
            maxDay = self:CalcDayCount(selectYear, selectMonth)
        end
    end

    local minYear = curYear - 99
    local datas   = {
        [DATE_TAG.YEAR]  = {}, 
        [DATE_TAG.MONTH] = {}, 
        [DATE_TAG.DAY]   = {}, 
    }

    -- init year month day
    for i = 1, maxMonth do
        table.insert(datas[DATE_TAG.MONTH], i)
    end

    for i = 1, maxDay do
        table.insert(datas[DATE_TAG.DAY], i)
    end

    for i = minYear, maxYear do
        table.insert(datas[DATE_TAG.YEAR], i)
    end

    self.selectYearIndex  = selectYear and (100 - (curYear - selectYear)) or 100
    self.selectMonthIndex = selectMonth or curMonth
    self.selectDayIndex   = selectDay or curDay
    self.datas            = datas
    self.curDateData = {
        [DATE_TAG.YEAR]  = curYear, 
        [DATE_TAG.MONTH] = curMonth, 
        [DATE_TAG.DAY]   = curDay, 
    }
    
    return {
        [DATE_TAG.YEAR]  = self.selectYearIndex,
        [DATE_TAG.MONTH] = self.selectMonthIndex,
        [DATE_TAG.DAY]   = self.selectDayIndex,
    }

end

function DateSelectView:InitView()
    local viewData   = self:GetViewData()
    local dateViews = viewData.dateViews
    local dateAdapters = {
        [DATE_TAG.YEAR]  = handler(self, self.OnYearDataSourceAdapter),
        [DATE_TAG.MONTH] = handler(self, self.OnMonthDataSourceAdapter),
        [DATE_TAG.DAY]   = handler(self, self.OnDayDataSourceAdapter),
    }
    self.init = true
    for dateTag, dateView in ipairs(dateViews) do
        
        dateView:setCellChangeCB(dateAdapters[dateTag])
        dateView:setIndexOverChangeCB(function(sender, index_)
            -- update day
            if self.init then return end

            if dateTag == DATE_TAG.YEAR then
                self.selectYearIndex = index_
            elseif dateTag == DATE_TAG.MONTH then
                self.selectMonthIndex = index_
            elseif dateTag == DATE_TAG.DAY then
                self.selectDayIndex = index_
            end
            if dateTag ~= DATE_TAG.DAY then
                self:ReloadUI(dateTag)
            end

        end)

        local count = #self.datas[dateTag]
        if count > 0 then
            dateView:setCellCount(count)
            dateView:reloadData()
        end
    end
    self.init = false

    display.commonUIParams(viewData.cancelBtn, {cb = handler(self, self.OnClickCancelBtnAction)})
    display.commonUIParams(viewData.determineBtn, {cb = handler(self, self.OnClickDetermineBtnAction)})
end

function DateSelectView:ReloadUI(dateTag)
    local yearDatas   = self.datas[DATE_TAG.YEAR] or {}
    local monthDatas  = self.datas[DATE_TAG.MONTH] or {}
    local dayDatas    = self.datas[DATE_TAG.DAY] or {}
    local year        = yearDatas[self.selectYearIndex]
    local month       = monthDatas[self.selectMonthIndex]
    local day         = dayDatas[self.selectDayIndex]
    
    local viewData    = self:GetViewData()
    local dateViews   = viewData.dateViews

    -- logInfo.add(5, 'MONTH content index = ' .. dateViews[DATE_TAG.MONTH]:getCenterIndex())

    if dateTag == DATE_TAG.YEAR then
        local oldMonthCount = monthDatas[#monthDatas]
        local monthCount, isChange = self:CheckMonthCountIsChange(year, month, oldMonthCount)

        if isChange then
            -- reload month data
            self:ReloadMonthDatas(monthCount)

            -- update month ui
            local monthView     = dateViews[DATE_TAG.MONTH]
            monthView:setCellCount(monthCount)
            monthView:reloadData()

            -- dateViews[DATE_TAG.MONTH]:setCenterIndex(math.min(monthCount, month))
            if month > monthCount then
                dateViews[DATE_TAG.MONTH]:setCenterIndex(monthCount)
            -- else
            --     -- dateViews[DATE_TAG.MONTH]:setCenterIndex(month)
            --     logInfo.add(5, 'content index = ' .. dateViews[DATE_TAG.MONTH]:getCenterIndex())
            end
            
        end
    end
    
    local oldDayCount = dayDatas[#dayDatas]
    local totalDayCount, isChange = self:CheckDayCountIsChange(year, month, oldDayCount)
    
    -- total day count change -> update ui
    if isChange then
        self:ReloadDayDatas(totalDayCount)
        local dayView = dateViews[DATE_TAG.DAY]
        dayView:setCellCount(totalDayCount)
        dayView:reloadData()

        -- cur day count > total day count -> set content offset
        if day > totalDayCount then
            -- dateViews[DATE_TAG.DAY]:setCenterIndex(math.min(day, totalDayCount))
            dateViews[DATE_TAG.DAY]:setCenterIndex(totalDayCount)
        end
    end
end

function DateSelectView:CheckMonthCountIsChange(year, month, oldMonthCount)
    local isCurDate = year == self.curDateData[DATE_TAG.YEAR]
    local monthCount = isCurDate and self.curDateData[DATE_TAG.MONTH] or 12
    local isChange = oldMonthCount ~= monthCount
    return monthCount, isChange
end

function DateSelectView:ReloadMonthDatas(monthCount)
    local monthDatas = {}
    for i = 1, monthCount do
        table.insert(monthDatas, i)
    end
    self.datas[DATE_TAG.MONTH] = monthDatas

    return monthCount
end

function DateSelectView:ReloadDayDatas(dayCount)
    local dayDatas = {}
    for i = 1, dayCount do
        table.insert(dayDatas, i)
    end
    self.datas[DATE_TAG.DAY] = dayDatas

    return dayCount
end

function DateSelectView:CheckDayCountIsChange(year, month, oldDayCount)
    local dayCount
    if year == self.curDateData[DATE_TAG.YEAR] and month == self.curDateData[DATE_TAG.MONTH] then
        dayCount = self.curDateData[DATE_TAG.DAY]
    else
        dayCount = self:CalcDayCount(year, month)
    end

    return dayCount, dayCount ~= oldDayCount
end

function DateSelectView:CalcDayCount(year, month)
    -- 只有二月特殊处理 其他月份为死的天数 所以没必要掉 os.date
    -- return os.date("%d", os.time({year = year, month = month + 1, day = 0}))
    -- is leap year
    local isLeapYear = function (y)
        return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0 and y % 3200 ~= 0)
    end

    local dayCount = DAY_COUNT[month]
    -- nil 即为二月
    if dayCount == nil then
        dayCount = isLeapYear(year) and 29 or 28
    end

    return dayCount
end

function DateSelectView:IsCurDate(year, month)
    return year == self.curDateData[DATE_TAG.YEAR] and month == self.curDateData[DATE_TAG.MONTH]
end

function DateSelectView:OnYearDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx

    if pCell == nil then
        pCell = CreateCell()
    end
    self:UpdateDate(pCell, DATE_TAG.YEAR, index)

    return pCell
end

function DateSelectView:OnMonthDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx

    if pCell == nil then
        pCell = CreateCell()
    end

    self:UpdateDate(pCell, DATE_TAG.MONTH, index)

    return pCell
end

function DateSelectView:OnDayDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx

    if pCell == nil then
        pCell = CreateCell()
    end

    self:UpdateDate(pCell, DATE_TAG.DAY, index)

    return pCell
end

function DateSelectView:UpdateDate(cell, tag, index)
    local data = self.datas[tag] or {}
    local num = data[index] or 0
    display.commonLabelParams(cell.label, {text = string.format(self:GetDateName(tag), num)})
end

function DateSelectView:GetDateName(tag)
    return DATE_NAME[tag]
end

function DateSelectView:DestoryView()
    self:setVisible(false)
    self:runAction(cc.RemoveSelf:create())
end

function DateSelectView:OnClickCancelBtnAction()
    self:DestoryView()
end

function DateSelectView:OnClickDetermineBtnAction()
    local yearDatas   = self.datas[DATE_TAG.YEAR] or {}
    local monthDatas  = self.datas[DATE_TAG.MONTH] or {}
    local dayDatas    = self.datas[DATE_TAG.DAY] or {}
    local year        = yearDatas[self.selectYearIndex]
    local month       = monthDatas[self.selectMonthIndex]
    local day         = dayDatas[self.selectDayIndex ]
    if month < 10 then
        month = string.format('0%s',month)
    end
    if day < 10 then
        day = string.format('0%s',day)
    end
    local t = {year, month, day}
	local date = table.concat(t, '-')
    app:DispatchObservers('BIRTHDAY_SET_COMMPLETE', {year = year, month = month, day = day, date = date})
    
    self:DestoryView()
end

CreateView = function (size, selectIndexData)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
    local shadowLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, enable = true, color = cc.c4b(0, 0, 0, 130), ap = display.CENTER})
    view:addChild(shadowLayer)
    
    local bgSize = cc.size(596, 417)
    local layer = display.newLayer(size.width * 0.5, size.height * 0.5, {ap = display.CENTER, size = bgSize})
    view:addChild(layer)

    local middleBgPosX, middleBgPosY = bgSize.width * 0.5, bgSize.height * 0.5

    local bg = display.newNSprite(RES_DICT.CREATE_ROLES_BIRTHDAY_BG, middleBgPosX, middleBgPosY)
    layer:addChild(bg)

    local selectBg = display.newNSprite(RES_DICT.CREATE_ROLES_BIRTHDAY_SELECT, middleBgPosX, middleBgPosY + 50, {ap = display.CENTER})
    layer:addChild(selectBg)

    local dateViews = {}
    local tableViewSize = cc.size(146, 180)
    local tableViewCellSize = cc.size(tableViewSize.width, 60)
    for i = 1, 3 do
        -- local pos = cc.p(130 + (166) * (i - 1), middleBgPosY + 50)
        local pos = cc.p(60 + (166) * (i - 1), middleBgPosY + 50)
        if i == 3 then
            pos.x = pos.x + 9
        end

        local zoomSliderList = require("common.ZoomSliderList").new()
        layer:addChild(zoomSliderList)
        zoomSliderList:setCellSize(tableViewCellSize)
        zoomSliderList:setAlphaMin(50)
        zoomSliderList:setCellSpace(70)
        zoomSliderList:setCenterIndex(selectIndexData[i])
        zoomSliderList:setDirection(1)
        zoomSliderList:setAlignType(1)
        zoomSliderList:setSideCount(1)
        zoomSliderList:setPosition(pos)
        zoomSliderList:setSwallowTouches(false)

        table.insert(dateViews, zoomSliderList)
    end

    -- cancel btn
    local cancelBtn = display.newButton(middleBgPosX - 105, 70, {n = RES_DICT.COMMON_BTN_WHITE_DEFAULT, ap = display.CENTER})
    display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('取消')}))
    layer:addChild(cancelBtn)

    -- determine btn
    local determineBtn = display.newButton(middleBgPosX + 110, cancelBtn:getPositionY(), {n = RES_DICT.COMMON_BTN_ORANGE, ap = display.CENTER})
    display.commonLabelParams(determineBtn, fontWithColor(14, {text = __('确定')}))
    layer:addChild(determineBtn)

    return {
        view         = view,
        cancelBtn    = cancelBtn,
        determineBtn = determineBtn,
        dateViews    = dateViews,
    }
end

CreateCell = function ()
    -- local cell = CTableViewCell:new()
    local size = cc.size(146, 60)
    local cell = display.newLayer(0, 0, {size = size})
    cell:setContentSize(size)

    local label = display.newLabel(size.width * 0.5, size.height * 0.5, {fontSize = 24, color = '#5b3c25'})
    cell:addChild(label)

    cell.label = label

    return cell
end

function DateSelectView:GetViewData()
    return self.viewData_
end

return DateSelectView