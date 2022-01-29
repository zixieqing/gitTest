local AreaCellView = class('home.AreaCellView',function ()
    local pageviewcell = CLayout:new()
    pageviewcell.name = 'home.AreaCellView'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function AreaCellView:ctor(cellSize, index, totalCount)
    local CellWidth = cellSize.width
    local CellHeight = cellSize.height
    -- 左右两个cell背光会超出cellSize
    -- 不让光被裁剪需要Resize
    if 1 == index then
        cellSize.width = cellSize.width + 34
    end
    if totalCount == index then
        cellSize.width = cellSize.width + 34
    end
    self:setContentSize(cellSize)
    local cellContentSzie = cc.size(CellWidth,CellHeight)
    local cellLayout = CLayout:create(cellContentSzie)
    if 1 == index and totalCount == index then
        cellLayout:setPosition(cc.p(cellSize.width/2 , cellSize.height/2))
    elseif 1 == index then
        cellLayout:setAnchorPoint(cc.p(1,0.5))
        cellLayout:setPosition(cc.p(cellSize.width , cellSize.height/2))
    elseif totalCount == index then
        cellLayout:setAnchorPoint(cc.p(0,0.5))
        cellLayout:setPosition(cc.p(0 , cellSize.height/2))
    else
        cellLayout:setPosition(cc.p(cellSize.width/2 , cellSize.height/2))
    end
    self:addChild(cellLayout)
    cellLayout:setName("cellLayout")
    -- 点击的layer
    local clickLayer = display.newLayer(cellContentSzie.width/2 , 0,{ap = display.CENTER_BOTTOM ,size =cc.size(190,140) , color = cc.c4b(0,0,0,0) , enable = true })
    cellLayout:addChild(clickLayer)

    -- 选中后的背光
    local backLight = display.newImageView(_res('ui/prize/collect_prize_area_ico_light.png'),cellContentSzie.width/2, cellContentSzie.height/2 - 60)
    cellLayout:addChild(backLight)
    backLight:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.6, 25)))
    backLight:setScale(0.9)
    backLight:setVisible(false)

    -- 新的图标
    local newIcon = display.newImageView(_res('ui/prize/collect_prize_area_ico_1.png'),cellContentSzie.width/2, 15,{ap = display.CENTER_BOTTOM})
    cellLayout:addChild(newIcon,2)
    newIcon:setVisible(false)
    
    -- 地区的名称
    local bottonName = display.newImageView(_res('ui/prize/collect_prize_area_bg_name.png'),cellContentSzie.width/2, -6,{ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(270, 54)})
    cellLayout:addChild(bottonName,4)
    local buttonSize = bottonName:getContentSize()
    bottonName:setVisible(false)
    local areaName = display.newLabel(buttonSize.width/2,buttonSize.height/2 - 3,fontWithColor(5) )
    bottonName:addChild(areaName)

    -- 小红点
    local redPoint = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), bottonName:getContentSize().width - 34, bottonName:getContentSize().height / 2 + 4)
	redPoint:setName('BTN_RED_POINT')
	redPoint:setVisible(false)
    bottonName:addChild(redPoint)
        
    self.bgLayout  = cellLayout
    self.viewData = {
        newIcon         = newIcon,
        bottonName      = bottonName ,
        areaName        = areaName ,
        clickLayer      = clickLayer,
        cellLayout      = cellLayout,
        backLight       = backLight,
        redPoint        = redPoint,
    }
end
--==============================--
--desc:更新cell 的状态
--@return 
--==============================--
function AreaCellView:UpdateView(data)
    if not  data then
        return
    end
    local viewData_ = self.viewData
    local areaName = data.areaName or ""

    viewData_.newIcon:setTexture(_res(string.format('ui/prize/collect_prize_area_ico_%d.png', tonumber(data.areaId))))
    viewData_.newIcon:setVisible(true)
    viewData_.areaName:setString(areaName)
    viewData_.bottonName:setVisible(true)
end

return AreaCellView