--[[
 * author : kaishiqi
 * descpt : 缩放滑动列表
]]
local socket = require('socket')
local ZoomSliderList = class('ZoomSliderList', function()
    return display.newLayer(0, 0, {name = 'ZoomSliderList', enableEvent = true})
end)

-- 排列方式
ZoomSliderList.D_HORIZONTAL = 0  -- 水平方向
ZoomSliderList.D_VERTICAL   = 1  -- 垂直方向

-- 对其方式
ZoomSliderList.ALIGN_CENTER = 0  -- 中心对其
ZoomSliderList.ALIGN_LEFT   = 1  -- 左边对其
ZoomSliderList.ALIGN_RIGHT  = 2  -- 右边对其
ZoomSliderList.ALIGN_TOP    = 1  -- 顶部对其
ZoomSliderList.ALIGN_BOTTOM = 2  -- 底部对其

local SCROLL_TIME       = 0.2
local INTERVAL_INTERVAL = 0.01   -- 惯性滑动触发时间间隔
local INTERVAL_FALL     = 0.86  -- 惯性滑动衰减速度
local SLIDE_RANGE       = 5     -- 滑动手势识别范围
local SHOW_REFOBJ       = false -- 是否显示参考对象（debug用）
local SHOW_TOUCH_RECT   = false -- 是否显示触摸参考（debug用）

local TweeningMap = {
    linear = function(t, b, c, d)
        return c * t / d + b
    end
}

function ZoomSliderList:ctor()
    self.centerIndex_ = 0
    self:setBasePoint(cc.p(0,0))
    self:setCellSize(cc.size(0,0))
    self:setScaleMin(1)
    self:setEnabled(true)
    self:setAlphaMin(255)
    self:setCellSpace(0)
    self:setSideCount(0)
    self:setCellCount(0)
    self:setCellChangeCB(nil)
    self:setCellUpdateCB(nil)
    self:setIndexPassChangeCB(nil)
    self:setIndexOverChangeCB(nil)
    self:setDirection(ZoomSliderList.D_HORIZONTAL)
    self:setAlignType(ZoomSliderList.ALIGN_CENTER)
    self:setTouchRectPadding(cc.p(0,0))
    self:setHostCellZOrder(true)

    self.usedCellMap_    = {}
    self.freeCellList_   = {}
    self.cellPreInfoMap_ = {
        pointList = {},
        scaleList = {},
        alphaList = {},
    }

    self.isInited_      = false
    self.isReload_      = false
    self.minLimit_      = 0
    self.maxLimit_      = 0
    self.touchMovedMin_ = 0
    self.touchMovedMax_ = 0
    self.offsetValue_   = 0
    self.isScrolling_   = false
    self.tweenValueMap_ = {}

    self.refObjLayer_ = display.newLayer(0, 0, {size = cc.size(1,1)})
    self.refObjLayer_:setPosition(self:getBasePoint())
    self:addChild(self.refObjLayer_)

    self.cellsLayer_ = display.newLayer(0, 0)
    self:addChild(self.cellsLayer_)

    self.touchLayer_ = display.newLayer(0, 0, {size = self:getContentSize(), color = cc.c4b(0,0,0,100)})
    self:addChild(self.touchLayer_)
    self.touchLayer_:setVisible(SHOW_TOUCH_RECT)
end


-------------------------------------------------
-- get / set

-- 坐标基点
function ZoomSliderList:setBasePoint(pos)
    self.basePoint_ = cc.p(checknumber(pos.x), checknumber(pos.y))
end
function ZoomSliderList:getBasePoint()
    return self.basePoint_
end


-- 单元尺寸
function ZoomSliderList:setCellSize(size)
    self.cellSize_ = cc.size(checknumber(size.width), checknumber(size.height))
end
function ZoomSliderList:getCellSize()
    return self.cellSize_
end


-- 单元格间距
function ZoomSliderList:setCellSpace(space)
    self.cellSpace_ = checkint(space)
end
function ZoomSliderList:getCellSpace()
    return self.cellSpace_
end


-- 单侧的单元格数量
function ZoomSliderList:setSideCount(count)
    self.sideCount_ = math.max(0, checkint(count))
end
function ZoomSliderList:getSideCount()
    return self.sideCount_
end


-- 单元格数量
function ZoomSliderList:setCellCount(count)
    self.cellCount_ = math.max(0, checkint(count))
end
function ZoomSliderList:getCellCount()
    return self.cellCount_
end


-- 最小缩放值（默认为1）
function ZoomSliderList:setScaleMin(scale)
    self.scaleMin_ = checknumber(scale)
end
function ZoomSliderList:getScaleMin()
    return self.scaleMin_
end


-- 最小透明度度（默认为255）
function ZoomSliderList:setAlphaMin(alpha)
    self.alphaMin_ = checkint(alpha)
end
function ZoomSliderList:getAlphaMin()
    return self.alphaMin_
end


-- 排列方向
-- @see ZoomSliderList.D_VERTICAL
-- @see ZoomSliderList.D_HORIZONTAL
function ZoomSliderList:setDirection(direction)
    local isVertical = ZoomSliderList.D_VERTICAL == direction
    self.direction_ = isVertical and ZoomSliderList.D_VERTICAL or ZoomSliderList.D_HORIZONTAL
end
function ZoomSliderList:getDirection()
    return self.direction_
end


-- 排列方向
-- @see ZoomSliderList.ALIGN_CENTER
-- @see ZoomSliderList.ALIGN_LEFT
-- @see ZoomSliderList.ALIGN_RIGHT
-- @see ZoomSliderList.ALIGN_TOP
-- @see ZoomSliderList.ALIGN_BOTTOM
function ZoomSliderList:setAlignType(type)
    local isValidity = false
    if not self:isHorizontal_() then
        isValidity = ZoomSliderList.ALIGN_LEFT == type or 
                     ZoomSliderList.ALIGN_CENTER == type or 
                     ZoomSliderList.ALIGN_RIGHT == type
    else
        isValidity = ZoomSliderList.ALIGN_TOP == type or 
                     ZoomSliderList.ALIGN_CENTER == type or 
                     ZoomSliderList.ALIGN_BOTTOM == type
    end
    self.alignType_ = isValidity and type or ZoomSliderList.ALIGN_CENTER
end
function ZoomSliderList:getAlignType()
    return self.alignType_
end


-- 中心索引（从1开始）
function ZoomSliderList:setCenterIndex(index, noAnimation)
    self.tempCenterIndex_ = index
    self:scrollToIndex_(index, noAnimation)
end
function ZoomSliderList:getCenterIndex()
    return self.centerIndex_
end


-- 根据index获取cell
function ZoomSliderList:cellAtIndex(index)
    return self.usedCellMap_[index]
end


-- 单元格变动回调
--[[
function cellChangeCB(p_cell, idx)
    -- do something
    return cell
end
]]
function ZoomSliderList:setCellChangeCB(cellChangeCB)
    self.onCellChangeCB_ = cellChangeCB
end
function ZoomSliderList:getCellChangeCB()
    return self.onCellChangeCB_
end


-- 单元格更新回调
--[[
function cellUpdateCB(p_cell, idx)
    -- do something
end
]]
function ZoomSliderList:setCellUpdateCB(cellUpdateCB)
    self.onCellUpdateCB_ = cellUpdateCB
end
function ZoomSliderList:getCellUpdateCB()
    return self.onCellUpdateCB_
end


-- 当前中心索引变化经过回调
--[[
function indexPassChangeCB(sender, idx)
    -- do something
end
]]
function ZoomSliderList:setIndexPassChangeCB(dataChangeCB)
    self.onIndexPassChangeCB_ = dataChangeCB
end
function ZoomSliderList:getIndexPassChangeCB()
    return self.onIndexPassChangeCB_
end


-- 当前中心索引变化结束回调
--[[
function indexOverChangeCB(sender, idx)
    -- do something
end
]]
function ZoomSliderList:setIndexOverChangeCB(dataChangeCB)
    self.onIndexOverChangeCB_ = dataChangeCB
end
function ZoomSliderList:getIndexOverChangeCB()
    return self.onIndexOverChangeCB_
end



-- 单元变化的缓动方法
function ZoomSliderList:getTweenFunc()
    return TweeningMap.linear
end


function ZoomSliderList:isScrolling()
    return self.isScrolling_
end


-- 触摸判定区域的padding 在原本的基础上以中心对称加上传参的 x * 2  y * 2
function ZoomSliderList:getTouchRectPadding()
    return self.touchRectPadding_
end
function ZoomSliderList:setTouchRectPadding(pos)
    self.touchRectPadding_ = pos
end


-- 是否由list自身逻辑托管zorder
function ZoomSliderList:getHostCellZOrder()
    return self.hostCellZOrder_
end
function ZoomSliderList:setHostCellZOrder(host)
    self.hostCellZOrder_ = host
end


function ZoomSliderList:getSwallowTouches()
    return self.touchEventListener_:isSwallowTouches()
end
function ZoomSliderList:setSwallowTouches(isSwallow)
    self.isSwallowTouches_ = isSwallow
    if self.touchEventListener_ then
        self.touchEventListener_:setSwallowTouches(isSwallow)
    end
end


function ZoomSliderList:isEnabled()
    return self.isEnabled_
end
function ZoomSliderList:setEnabled(isEnabled)
    self.isEnabled_ = isEnabled
end


-------------------------------------------------
-- public method

-- 刷新数据
function ZoomSliderList:reloadData()
    assert(self:getCellChangeCB(), 'cellChangeCB is null')

    -- reset status
    self.cellPreInfoMap_.pointList = {}
    self.cellPreInfoMap_.scaleList = {}
    self.cellPreInfoMap_.alphaList = {}
    for index, cell in pairs(self.usedCellMap_) do
        self.usedCellMap_[index] = nil
        self:addFreeCell_(cell)
    end

    -- udpate preInfo
    self.cellPreInfoMap_.scaleList[0] = 1
    self.cellPreInfoMap_.alphaList[0] = 255
    self.cellPreInfoMap_.pointList[0] = clone(self:getBasePoint())
    local basicPointValue  = self:isHorizontal_() and self:getBasePoint().x or self:getBasePoint().y
    local offsetPointValue = 0
    for i = 1, self:getSideCount() do
        -- update scale value
        local scaleValue = self:getTweenValue_(i, 1, self:getScaleMin(), self:getSideCount())
        self.cellPreInfoMap_.scaleList[i]  = scaleValue
        self.cellPreInfoMap_.scaleList[-i] = scaleValue

        -- update alpha value
        local alphaValue = self:getTweenValue_(i, 255, self:getAlphaMin(), self:getSideCount())
        self.cellPreInfoMap_.alphaList[i]  = alphaValue
        self.cellPreInfoMap_.alphaList[-i] = alphaValue

        -- update point value
        local pointValue = self:getCellSpace() * scaleValue
        offsetPointValue = offsetPointValue + pointValue
        if self:isHorizontal_() then
            self.cellPreInfoMap_.pointList[i]  = cc.p(basicPointValue + offsetPointValue, self:getBasePoint().y)
            self.cellPreInfoMap_.pointList[-i] = cc.p(basicPointValue - offsetPointValue, self:getBasePoint().y)
        else
            self.cellPreInfoMap_.pointList[i]  = cc.p(self:getBasePoint().x, basicPointValue - offsetPointValue)
            self.cellPreInfoMap_.pointList[-i] = cc.p(self:getBasePoint().x, basicPointValue + offsetPointValue)
        end
    end

    -- update limit info
    self.minLimit_ = 0
    self.maxLimit_ = self:getCellSpace() * (self:getCellCount()-1)
    if self:isHorizontal_() then
        self.touchMovedMin_ = -(self:getCellCount() + self:getSideCount()-1) * self:getCellSpace()
        self.touchMovedMax_ = self:getSideCount() * self:getCellSpace()
    else
        self.touchMovedMin_ = -self:getSideCount() * self:getCellSpace()
        self.touchMovedMax_ = (self:getCellCount() + self:getSideCount()-1) * self:getCellSpace()
    end
    
    -- update refObjLayer
    self.refObjLayer_:removeAllChildren()
    if SHOW_REFOBJ then
        for i = -5, self:getCellCount() do
            local objSize = cc.size(self:getCellSpace(), self:getCellSpace())
            local objGap = (i-1) * self:getCellSpace()
            local objPos = clone(self:getBasePoint())
            objPos.x = objPos.x + (self:isHorizontal_() and objGap or 0)
            objPos.y = objPos.y - (self:isHorizontal_() and 0 or objGap)
            local refObj = display.newLayer(objPos.x, objPos.y, {color = cc.r4b(150), size = objSize})
            refObj:addChild(display.newLabel(objSize.width/2, objSize.height/2, {fontSize = 30, color = '#FFFFFF', text = i}))
            self.refObjLayer_:addChild(refObj)
        end
    end

    self.isInited_ = true
    self.isReload_ = false
    self:scrollToIndex_(self.tempCenterIndex_ or 0, true)
    self.isReload_ = true

    self.touchLayer_:removeAllChildren()
    self:updateTouchRect_()
end


-------------------------------------------------
-- private method

function ZoomSliderList:isHorizontal_()
    return self:getDirection() == ZoomSliderList.D_HORIZONTAL
end
function ZoomSliderList:isValidIndex_(index)
    return index > 0 and index <= self:getCellCount()
end


function ZoomSliderList:getTweenValue_(progress, begin, ending, duration)
    -- 由于不需要那么高精度的计算，所以小数位只保留2位。
    -- 利用缓存计算结果，来减少反复计算的性能消耗。尤其在 touchMove 时来回反复移动。
    local tweenResultValue = 0
    local optimizeDuration = checkint(duration)
    local optimizeProgress = checkint(progress)
    local optimizeBegin    = checkint(checknumber(begin) * 100)
    local optimizeEnding   = checkint(checknumber(ending) * 100)
    if self.tweenValueMap_[self:getTweenFunc()] == nil then
        self.tweenValueMap_[self:getTweenFunc()] = {}
    end
    if self.tweenValueMap_[self:getTweenFunc()][optimizeDuration] == nil then
        self.tweenValueMap_[self:getTweenFunc()][optimizeDuration] = {}
    end
    if self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress] == nil then
        self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress] = {}
    end
    if self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress][optimizeBegin] == nil then
        self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress][optimizeBegin] = {}
    end
    if self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress][optimizeBegin][optimizeEnding] == nil then
        tweenResultValue = self:getTweenFunc()(optimizeProgress, optimizeBegin/100, (optimizeEnding - optimizeBegin)/100, optimizeDuration)
        self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress][optimizeBegin][optimizeEnding] = tweenResultValue
    else
        tweenResultValue = self.tweenValueMap_[self:getTweenFunc()][optimizeDuration][optimizeProgress][optimizeBegin][optimizeEnding]
    end
    return tweenResultValue
    -- return self:getTweenFunc()(progress, begin, ending - begin, duration)
end


function ZoomSliderList:getCellPrePoint_(pos)
    local pos = math.max(-self:getSideCount(), math.min(pos, self:getSideCount()))
    return clone(self.cellPreInfoMap_.pointList[pos] or self:getBasePoint())
end
function ZoomSliderList:getCellPreScale_(pos)
    local pos = math.max(-self:getSideCount(), math.min(pos, self:getSideCount()))
    return self.cellPreInfoMap_.scaleList[pos] or 1
end
function ZoomSliderList:getCellPreAlpha_(pos)
    local pos = math.max(-self:getSideCount(), math.min(pos, self:getSideCount()))
    return self.cellPreInfoMap_.alphaList[pos] or 255
end


function ZoomSliderList:scrollToIndex_(index, isFast)
    if not self.isInited_ then return end
    local newOffsetValue = (index - 1) * self:getCellSpace()

    local targetPos = cc.p(0, 0)
    if self:isHorizontal_() then
        targetPos.x = -newOffsetValue
    else
        targetPos.y = newOffsetValue
    end

    if isFast then
        self:updateCenterIndex_(index)
    end
    self:scrollToPos_(targetPos, isFast)
end
function ZoomSliderList:scrollToPos_(targetPos, isFast)
    self:stopScrollUpdate_()
    self:stopInertiaUpdate_()
    self.refObjLayer_:stopAllActions()
    local finishCB = function()
        if self:isHorizontal_() then
            self.offsetValue_ = targetPos.x
        else
            self.offsetValue_ = targetPos.y
        end
        self:updateAllCell_()
        self:stopScrollUpdate_()

        if self:getIndexOverChangeCB() then
            self:getIndexOverChangeCB()(self, self.centerIndex_)
        end
    end

    if isFast then
        finishCB()
        if self:isHorizontal_() then
            self.refObjLayer_:setPositionX(self.offsetValue_)
        else
            self.refObjLayer_:setPositionY(self.offsetValue_)
        end
    else
        self:startScrollUpdate_()
        self.refObjLayer_:runAction(cc.Sequence:create({
            cc.MoveTo:create(SCROLL_TIME, targetPos),
            cc.CallFunc:create(finishCB)
        }))
    end
end


function ZoomSliderList:stopScrollUpdate_()
    self.isScrolling_ = false
    if self.scrollUpdateHandler_ then
        scheduler.unscheduleGlobal(self.scrollUpdateHandler_)
        self.scrollUpdateHandler_ = nil
    end
end
function ZoomSliderList:startScrollUpdate_()
    self.isScrolling_ = true
    if self.scrollUpdateHandler_ then return end
    self.scrollUpdateHandler_ = scheduler.scheduleUpdateGlobal(function()
        if self:isHorizontal_() then
            self.offsetValue_ = self.refObjLayer_:getPositionX()
        else
            self.offsetValue_ = self.refObjLayer_:getPositionY()
        end
        
        self:updateAllCell_()
    end)
end


function ZoomSliderList:stopInertiaUpdate_()
    self.isScrolling_ = false
    if self.inertiaUpdateHandler_ then
        scheduler.unscheduleGlobal(self.inertiaUpdateHandler_)
        self.inertiaUpdateHandler_ = nil
    end
end
function ZoomSliderList:startInertiaUpdate_()
    self.isScrolling_ = true
    if self.inertiaUpdateHandler_ then return end
    self.inertiaUpdateHandler_ = scheduler.scheduleUpdateGlobal(function()
        self.offsetValue_ = self.offsetValue_ + self.inertiaSpeed_
        self:updateRefObjLayer_()
        self:updateAllCell_()

        if self:checkLimit_() then
            self:stopInertiaUpdate_()

        else
            self.inertiaSpeed_ = self.inertiaSpeed_ * INTERVAL_FALL
            if math.abs(self.inertiaSpeed_) < 4 then
                self:stopInertiaUpdate_()
                self:fixOffsetValue_()
            end
        end
    end)
end


function ZoomSliderList:checkLimit_()
    local isLimit = false
    if self:isHorizontal_() then
        -- check right limit
        if self.offsetValue_ < -self.maxLimit_ then
            self:scrollToPos_(cc.p(-self.maxLimit_, 0))
            isLimit = true

        -- check left limit
        elseif self.offsetValue_ > self.minLimit_ then
            self:scrollToPos_(cc.p(-self.minLimit_, 0))
            isLimit = true
        end

    else
        -- check top limit
        if self.offsetValue_ > self.maxLimit_ then 
            self:scrollToPos_(cc.p(0, self.maxLimit_))
            isLimit = true

        -- check bottom limit
        elseif self.offsetValue_ < self.minLimit_ then
            self:scrollToPos_(cc.p(0, self.minLimit_))
            isLimit = true
        end
    end
    return isLimit
end
function ZoomSliderList:fixOffsetValue_()
    local centerIndex = math.floor(self.offsetValue_ / self:getCellSpace())
    if self.offsetValue_ % self:getCellSpace() > self:getCellSpace() / 2 then
        -- fix to next
        if self:isHorizontal_() then
            self:scrollToPos_(cc.p(self:getCellSpace() * (centerIndex+1), 0))
        else
            self:scrollToPos_(cc.p(0, self:getCellSpace() * (centerIndex+1)))
        end

    else
        -- fix to prev
        if self:isHorizontal_() then
            self:scrollToPos_(cc.p(self:getCellSpace() * centerIndex, 0))
        else
            self:scrollToPos_(cc.p(0, self:getCellSpace() * centerIndex))
        end
    end
end


function ZoomSliderList:updateTouchRect_()
    local touchSize  = clone(self:getCellSize())
    local edgePoint  = self:getCellPrePoint_(self:getSideCount())
    local edgeScale  = self:getCellPreScale_(self:getSideCount())
    local touchPoint = clone(self:getBasePoint())
    local touchRectPadding = self:getTouchRectPadding()

    if self:isHorizontal_() then
        touchSize.width = math.max(0, (edgePoint.x - self:getBasePoint().x) * 2 + self:getCellSize().width * edgeScale + touchRectPadding.x * 2)
        touchSize.height = math.max(0, (touchSize.height + touchRectPadding.y * 2))
        touchPoint.x = touchPoint.x - touchSize.width/2
        if self:getAlignType() == ZoomSliderList.ALIGN_TOP then
            touchPoint.y = touchPoint.y - self:getCellSize().height - touchRectPadding.y
        elseif self:getAlignType() == ZoomSliderList.ALIGN_CENTER then
            touchPoint.y = touchPoint.y - self:getCellSize().height/2 - touchRectPadding.y
        end
    else
        touchSize.width = math.max(0, (touchSize.width + touchRectPadding.x * 2))
        touchSize.height = math.max(0, (self:getBasePoint().y - edgePoint.y) * 2 + self:getCellSize().height * edgeScale + touchRectPadding.y * 2)
        touchPoint.y = touchPoint.y - touchSize.height/2
        if self:getAlignType() == ZoomSliderList.ALIGN_RIGHT then
            touchPoint.x = touchPoint.x - self:getCellSize().width - touchRectPadding.x
        elseif self:getAlignType() == ZoomSliderList.ALIGN_CENTER then
            touchPoint.x = touchPoint.x - self:getCellSize().width/2 - touchRectPadding.x
        end
    end

    self.touchLayer_:setPosition(touchPoint)
    self.touchLayer_:setContentSize(touchSize)

    -- add cells rect
    local addCellTouchRect = function(index, zorder, tag)
        local rectPosX   = touchSize.width/2 + (self:isHorizontal_() and self:getCellPrePoint_(index).x - self:getBasePoint().x or 0)
        local rectPosY   = touchSize.height/2 + (self:isHorizontal_() and 0 or self:getCellPrePoint_(index).y - self:getBasePoint().y)
        local rectWidth  = self:getCellSize().width * (self:isHorizontal_() and self:getCellPreScale_(index) or 1)
        local rectHeight = self:getCellSize().height * (self:isHorizontal_() and 1 or self:getCellPreScale_(index))
        local rectLayer  = display.newLayer(rectPosX, rectPosY, {size = cc.size(rectWidth, rectHeight), color = cc.r4b(0), ap = display.CENTER})
        self.touchLayer_:addChild(rectLayer, zorder, tag)
        rectLayer:setName(tostring(index))
    end

    local cellTag = 0
    addCellTouchRect(0, self:getSideCount(), cellTag)
    for i = 1, self:getSideCount() do
        cellTag = cellTag + 1
        addCellTouchRect(i, self:getSideCount() - i, cellTag)
        cellTag = cellTag + 1
        addCellTouchRect(-i, self:getSideCount() - i, cellTag)
    end
end


function ZoomSliderList:updateCenterIndex_(newCenterIndex)
    if self:isValidIndex_(newCenterIndex) then
        self.centerIndex_ = newCenterIndex
        
        self.tempCenterIndex_ = newCenterIndex

        if self:getIndexPassChangeCB() then
            self:getIndexPassChangeCB()(self, self.centerIndex_)
        end
    end
end


function ZoomSliderList:updateRefObjLayer_()
    if self:isHorizontal_() then
        self.refObjLayer_:setPositionX(self.offsetValue_)
    else
        self.refObjLayer_:setPositionY(self.offsetValue_)
    end
end
function ZoomSliderList:updateAllCell_()
    -- calculate newCenterIndex
    local offsetValue    = self:isHorizontal_() and -self.offsetValue_ or self.offsetValue_
    local newCenterIndex = math.ceil((offsetValue + self:getCellSpace()/2) / self:getCellSpace())
    if self:getCenterIndex() ~= newCenterIndex then
        self:updateCenterIndex_(newCenterIndex)
    end

    -- check index range
    local maxSideCount = self:getSideCount() + 1  -- 1 is preload
    local beginIndex   = newCenterIndex - maxSideCount
    local endedIndex   = newCenterIndex + maxSideCount

    -- check unused cell (outside index)
    for index, cell in pairs(self.usedCellMap_) do
        if checkint(index) < beginIndex or checkint(index) > endedIndex then
            self.usedCellMap_[index] = nil
            self:addFreeCell_(cell)
        end
    end

    -- update each index cell
    local cellOffset = offsetValue - (newCenterIndex-1) * self:getCellSpace()
    self:updateCellAtIndex_(newCenterIndex, maxSideCount, 0, cellOffset)
    for i = 1, maxSideCount do
        local forwardIndex  = newCenterIndex + i
        local backwardIndex = newCenterIndex - i
        self:updateCellAtIndex_(forwardIndex, maxSideCount - i, i, cellOffset)
        self:updateCellAtIndex_(backwardIndex, maxSideCount - i, -i, cellOffset)
    end
end
function ZoomSliderList:updateCellAtIndex_(index, zOrder, pos, offset)
    if not self:isValidIndex_(index) then return end

    local cell = self.usedCellMap_[index] or self:popFreeCell_()
    if cell == nil then
        cell = self:getCellChangeCB()(nil, index)
        assert(cell, 'cell can not be nil')
        self.usedCellMap_[index] = cell
        cell:setTag(index)
    else
        if cell:getTag() ~= index then
            cell = self:getCellChangeCB()(cell, index)
            self.usedCellMap_[index] = cell
            cell:setTag(index)
        end
    end

    -- update cell status
    local scale = self:getCellPreScale_(pos)
    local point = self:getCellPrePoint_(pos)
    local alpha = self:getCellPreAlpha_(pos)

    -- forward offset
    if offset > 0 then

        -- update scale value
        local refScale = self:getCellPreScale_(pos-1)
        scale = self:getTweenValue_(offset, scale, refScale, self:getCellSpace())

        -- update alpha value
        if math.abs(pos) - self:getSideCount() > 0 then
            alpha = pos < 0 and 0 or self:getTweenValue_(offset, 0, alpha*2, self:getCellSpace())
        else
            local refAlpha = self:getCellPreAlpha_(pos-1)
            alpha = self:getTweenValue_(offset, alpha, refAlpha, self:getCellSpace())
        end

        -- update point value
        local refPoint = self:getCellPrePoint_(pos-1)
        if self:isHorizontal_() then
            point.x = self:getTweenValue_(offset, point.x, refPoint.x, self:getCellSpace())
        else
            point.y = self:getTweenValue_(offset, point.y, refPoint.y, self:getCellSpace())
        end

    -- backward offset
    elseif offset < 0 then

        -- update scale value
        local refScale = self:getCellPreScale_(pos+1)
        scale = self:getTweenValue_(-offset, scale, refScale, self:getCellSpace())

        -- update alpha value
        if math.abs(pos) - self:getSideCount() > 0 then
            alpha = pos > 0 and 0 or self:getTweenValue_(-offset, 0, alpha*2, self:getCellSpace())
        else
            local refAlpha = self:getCellPreAlpha_(pos+1)
            alpha = self:getTweenValue_(-offset, alpha, refAlpha, self:getCellSpace())
        end

        -- update point value
        local refPoint = self:getCellPrePoint_(pos+1)
        if self:isHorizontal_() then
            point.x = self:getTweenValue_(-offset, point.x, refPoint.x, self:getCellSpace())
        else
            point.y = self:getTweenValue_(-offset, point.y, refPoint.y, self:getCellSpace())
        end

    else
        if math.abs(pos) - self:getSideCount() > 0 then
            alpha = 0
        end
    end
    cell:setScale(scale)
    cell:setPosition(point)
    cell:setOpacity(math.max(0, math.min(alpha, 255)))

    -- update cell align type
    if cell:getParent() == nil or not self.isReload_ then
        if self:isHorizontal_() then
            if self:getAlignType() == ZoomSliderList.ALIGN_TOP then
                cell:setAnchorPoint(display.CENTER_TOP)
            elseif self:getAlignType() == ZoomSliderList.ALIGN_BOTTOM then
                cell:setAnchorPoint(display.CENTER_BOTTOM)
            else
                cell:setAnchorPoint(display.CENTER)
            end
        else
            if self:getAlignType() == ZoomSliderList.ALIGN_LEFT then
                cell:setAnchorPoint(display.LEFT_CENTER)
            elseif self:getAlignType() == ZoomSliderList.ALIGN_RIGHT then
                cell:setAnchorPoint(display.RIGHT_CENTER)
            else
                cell:setAnchorPoint(display.CENTER)
            end
        end
    end

    -- addChild
    if cell:getParent() == nil then
        self.cellsLayer_:addChild(cell)
    end

    -- update cell zOrder
    if self:getHostCellZOrder() then
        cell:setLocalZOrder(zOrder)
    end

    -- updateCB
    if self:getCellUpdateCB() then
        self:getCellUpdateCB()(cell, index)
    end
end


function ZoomSliderList:addFreeCell_(cell)
    if not cell then return end
    cell:setVisible(false)
    table.insert(self.freeCellList_, 1, cell)
end
function ZoomSliderList:popFreeCell_()
    local cell = table.remove(self.freeCellList_, #self.freeCellList_)
    if cell then 
        cell:setVisible(true)
        cell:setTag(-1)
    end
    return cell
end


-------------------------------------------------
-- handler

function ZoomSliderList:onEnter()
    self.touchEventListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener_:setSwallowTouches(self.isSwallowTouches_ == nil and true or self.isSwallowTouches_)  -- 为了阻挡底部可拖动控件的响应，避免同时拖动，默认吞噬触摸。如果想要开启，请调用 self:setSwallowTouches() 方法
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.touchEventListener_, -99)
end
function ZoomSliderList:onExit()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.touchEventListener_)
end
function ZoomSliderList:onCleanup()
    self:stopScrollUpdate_()
    self:stopInertiaUpdate_()
end


function ZoomSliderList:onTouchBegan_(touch, event)
    if not self:isEnabled() then return false end

    -- check touch rank
    local touchPoint = self:convertToNodeSpace(touch:getLocation())
    local rect = self.touchLayer_:getBoundingBox()
    if not cc.rectContainsPoint(rect, touchPoint) then
        return false
    end

    self.movedPoint_     = nil
    self.beganPoint_     = touchPoint
    self.isTouchMoving_  = false
    self.oldOffsetValue_ = self.offsetValue_
    return true
end
function ZoomSliderList:onTouchMoved_(touch, event)
    if not self.beganPoint_ then return end

    self.movedTime_  = socket.gettime()
    self.movedPoint_ = self:convertToNodeSpace(touch:getLocation())

    -- check slide range
    if self.isTouchMoving_ == false then
        if self:isHorizontal_() then
            self.isTouchMoving_ = math.abs(self.movedPoint_.x - self.beganPoint_.x) >= SLIDE_RANGE
        else
            self.isTouchMoving_ = math.abs(self.movedPoint_.y - self.beganPoint_.y) >= SLIDE_RANGE
        end
    end

    -- update offsetValue
    if self.isTouchMoving_ then
        -- stop scroll
        if self:isScrolling() then
            self:stopScrollUpdate_()
            self:stopInertiaUpdate_()
            self.refObjLayer_:stopAllActions()
        end
        
        -- update offset
        local offsetValue = 0
        if self:isHorizontal_() then
            offsetValue = self.movedPoint_.x - self.beganPoint_.x
        else
            offsetValue = self.movedPoint_.y - self.beganPoint_.y
        end
        self.offsetValue_ = math.max(self.touchMovedMin_, math.min(self.oldOffsetValue_ + offsetValue, self.touchMovedMax_))
        self:updateRefObjLayer_()
        self:updateAllCell_()
    end
end
function ZoomSliderList:onTouchEnded_(touch, event)
    if self.isTouchMoving_ then
        -- moving operate
        self.endedTime_  = socket.gettime()
        self.endedPoint_ = self:convertToNodeSpace(touch:getLocation())

        if not self:checkLimit_() then
            -- check inertia move
            if self.endedTime_ - self.movedTime_ < INTERVAL_INTERVAL and self.isTouchMoving_ then
                if self:isHorizontal_() then
                    self.inertiaSpeed_ = (self.endedPoint_.x - self.beganPoint_.x)/2
                else
                    self.inertiaSpeed_ = (self.endedPoint_.y - self.beganPoint_.y)/2
                end
                self:startInertiaUpdate_()

            -- fix cell offsetValue
            else
                self:fixOffsetValue_()
            end
        end

    else
        -- click operate
        if not self:isScrolling() and not self:checkInTouckCellRect_(0, touch:getLocation()) then
            -- check each cell rect
            for i = 1, self.touchLayer_:getChildrenCount() do
                local rectCell  = self.touchLayer_:getChildByTag(i)
                local cellIndex = rectCell and checkint(rectCell:getName()) or 0
                if self:checkInTouckCellRect_(cellIndex, touch:getLocation()) then
                    local targetIndex = self:getCenterIndex() + cellIndex
                    self:setCenterIndex(math.max(1, math.min(targetIndex, self:getCellCount())))
                    break
                end
            end
        end
    end

    self.movedTime_     = 0
    self.beganPoint_    = nil
    self.isTouchMoving_ = false
end
function ZoomSliderList:checkInTouckCellRect_(index, touchPos)
    local touchCellView   = self.touchLayer_:getChildByName(tostring(index))
    local touchCellPoint  = self.touchLayer_:convertToNodeSpace(touchPos)
    local cellBoundingBox = touchCellView and touchCellView:getBoundingBox() or cc.rect(-1,-1,1,1)
    return cc.rectContainsPoint(cellBoundingBox, touchCellPoint)
end


return ZoomSliderList
