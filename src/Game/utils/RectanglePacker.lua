local RectanglePacker = {}
local function IntegerRectangle(x, y, width, height) 
    local rectangle = {}
    rectangle.x = x
    rectangle.y = y
    rectangle.width = width
    rectangle.height = height
    rectangle.right = x + width
    rectangle.bottom = y + height

    return rectangle
end
local function SortableSize(width, height, id) 
    local size = {}
    size.width = width
    size.height = height
    size.id = id

    return size
end

local w = 1024
local h = 1024
local p = 2
local mInsertedRectangles = {}
local mRectangleStack = {}
local mFreeAreas = {}
local mSortableSizeStack = {}
local mNewFreeAreas = {}
local mInsertList = {}
local function freeRectangle(rectangle) 
    table.insert(mRectangleStack, rectangle)
end
local function freeSize(size) 
    table.insert( mSortableSizeStack, size )
end

local function allocateRectangle(x, y, width, height) 
    if (table.nums(mRectangleStack) > 0) then
        local rectangle = table.remove(mRectangleStack)
        rectangle.x = x
        rectangle.y = y
        rectangle.width = width
        rectangle.height = height
        rectangle.right = x + width
        rectangle.bottom = y + height

        return rectangle
    end

    return IntegerRectangle(x, y, width, height)
end

local mOutsideRectangle = IntegerRectangle(w + p, h + p, 0, 0)
while (table.nums(mInsertedRectangles) > 0) do
    freeRectangle(table.remove(mInsertedRectangles))
end
while (table.nums(mFreeAreas) > 0) do
    freeRectangle(table.remove(mFreeAreas))
end
local mWidth = w
local mHeight = h
local mPackedWidth = 0
local mPackedHeight = 0
table.insert(mFreeAreas, allocateRectangle(0, 0, mWidth, mHeight))
while (table.nums(mInsertList) > 0) do
    freeSize(table.remove(mInsertList))
end
local mPadding = p

local function allocateSize(width, height, id) 
    if (table.nums(mSortableSizeStack) > 0) then
        local size = table.remove(mSortableSizeStack)
        size.width = width
        size.height = height
        size.id = id

        return size
    end

    return SortableSize(width, height, id)
end

local function getFreeAreaIndex(width, height) 
    local best = mOutsideRectangle
    local index = -1

    local paddedWidth = width + mPadding
    local paddedHeight = height + mPadding

    for i=table.nums(mFreeAreas),1,-1 do
        local free = mFreeAreas[i]
        if (free.x < mPackedWidth or free.y < mPackedHeight) then
            if (free.x < best.x and paddedWidth <= free.width and paddedHeight <= free.height) then
                index = i
                if ((paddedWidth == free.width and free.width <= free.height and free.right < mWidth) or 
                    (paddedHeight == free.height and free.height <= free.width)) then
                    break
                end
                
                best = free
            end
         else 
            if (free.x < best.x and width <= free.width and height <= free.height) then
                index = i
                if ((width == free.width and free.width <= free.height and free.right < mWidth) or 
                    (height == free.height and free.height <= free.width)) then
                    break
                end
                best = free
            end
        end
    end

    return index
end

local function generateDividedAreas(divider, area, results) 
    local count = 0

    local rightDelta = area.right - divider.right
    if (rightDelta > 0) then
        table.insert(results, allocateRectangle(divider.right, area.y, rightDelta, area.height))
        count = count + 1
    end

    local leftDelta = divider.x - area.x
    if (leftDelta > 0) then
        table.insert(results, allocateRectangle(area.x, area.y, leftDelta, area.height))
        count = count + 1
    end

    local bottomDelta = area.bottom - divider.bottom
    if (bottomDelta > 0) then
        table.insert(results, allocateRectangle(area.x, divider.bottom, area.width, bottomDelta))
        count = count + 1
    end

    local topDelta = divider.y - area.y
    if (topDelta > 0) then
        table.insert(results, allocateRectangle(area.x, area.y, area.width, topDelta))
        count = count + 1
    end

    if (count == 0 and (divider.width < area.width or divider.height < area.height)) then
        table.insert(results, area)
    else
        freeRectangle(area)
    end
end

local function filterSelfSubAreas(areas) 
    for i=table.nums(areas),1,-1 do
        local filtered = areas[i]
        for j=table.nums(areas),1,-1 do
            if (i ~= j) then
                local area = areas[j]
                if (filtered.x >= area.x and filtered.y >= area.y and filtered.right <= area.right 
                    and filtered.bottom <= area.bottom) then
                    freeRectangle(filtered)
                    local topOfStack = table.remove(areas)
                    if (i <= table.nums(areas)) then
                        areas[i] = topOfStack
                    end
                    break
                end
            end
        end
    end
end

local function generateNewFreeAreas(target, areas, results) 
    local x = target.x
    local y = target.y
    local right = target.right + 1 + mPadding
    local bottom = target.bottom + 1 + mPadding

    local targetWithPadding = nil
    if (mPadding == 0) then
        targetWithPadding = target
    end
    for i=table.nums(areas),1,-1 do
        local area = areas[i]
        if (not (x >= area.right or right <= area.x or y >= area.bottom or bottom <= area.y)) then
            if (not targetWithPadding) then
                targetWithPadding = allocateRectangle(target.x, target.y, target.width + mPadding, target.height + mPadding)
            end

            generateDividedAreas(targetWithPadding, area, results)
            local topOfStack = table.remove(areas)
            if (i <= table.nums(areas)) then
                areas[i] = topOfStack
            end
        end
    end

    if (targetWithPadding ~= nil and targetWithPadding ~= target) then
        freeRectangle(targetWithPadding)
    end

    filterSelfSubAreas(results)
end

function RectanglePacker.packRectangles( sort )
    if (sort) then
        -- mInsertList.Sort((emp1, emp2)=>emp1.width.CompareTo(emp2.width))
    end

    while (table.nums(mInsertList) > 0) do
        local sortableSize = table.remove(mInsertList)
        local width = sortableSize.width
        local height = sortableSize.height

        local index = getFreeAreaIndex(width, height)
        if (index >= 0) then
            local freeArea = mFreeAreas[index]
            local target = allocateRectangle(freeArea.x, freeArea.y, width, height)
            target.id = sortableSize.id

            generateNewFreeAreas(target, mFreeAreas, mNewFreeAreas)

            while (table.nums(mNewFreeAreas) > 0) do
                table.insert( mFreeAreas, table.remove(mNewFreeAreas) )
            end

            table.insert(mInsertedRectangles, target)

            if (target.right > mPackedWidth) then
                mPackedWidth = target.right
            end
            
            if (target.bottom > mPackedHeight) then
                mPackedHeight = target.bottom
            end
        end

        freeSize(sortableSize)
    end

    return table.nums(mInsertedRectangles)
end

function RectanglePacker.getRectangle(index)
    local rectangle = {}
    local inserted = mInsertedRectangles[index]

    rectangle.x = inserted.x
    rectangle.y = inserted.y
    rectangle.width = inserted.width
    rectangle.height = inserted.height
    rectangle.id = inserted.id

    return rectangle
end

function RectanglePacker.insertRectangle( width, height )
    table.insert( mInsertList, allocateSize(width, height, table.nums(mInsertList) + 1) )
end

function RectanglePacker.dump(  )
    -- dump(mInsertList)
    dump(mInsertedRectangles)
end

return RectanglePacker