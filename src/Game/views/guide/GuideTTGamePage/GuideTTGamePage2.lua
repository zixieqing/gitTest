--[[
 * descpt : PVP指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTTGamePage2 = class('GuideTTGamePage2', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTTGamePage2'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    LINE_DOTTED_1 = _res('guide/guide_line_dotted_1.png'),
    IMAGE_1       = _res('guide/guide_cardgame_image_p2_1.png'),
    IMAGE_2       = _res('guide/guide_cardgame_image_p2_2.png'),
    IMAGE_3       = _res('guide/guide_cardgame_image_p2_3.png'),
    IMAGE_4       = _res('guide/guide_cardgame_image_p2_4.png'),
}

local CreateView = nil
local CreateRuleCell = nil

function GuideTTGamePage2:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTTGamePage2:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTTGamePage2:initView()
    
end

function GuideTTGamePage2:refreshUI(data)
    local viewData   = self:getViewData()
   
    local tipLabels = viewData.tipLabels
    local t = {'3', '4', '5'}
    for index, value in ipairs(t) do
        display.commonLabelParams(tipLabels[index], {text = tostring(data[value]), reqW = 230})
    end

end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local dottedlineLayerSize = cc.size(420, 180)
    
    ------------------------------
    -- left middle layer

    local leftMiddleLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(leftMiddleLayer)

    -- local image2 = display.newImageView(RES_DIR.IMAGE_2, dottedlineLayerSize.width / 2 + 10, dottedlineLayerSize.height / 2 - 10, {ap = display.CENTER})
    -- leftMiddleLayer:addChild(image2)

    local index = 2
    local endIndex = 4
    local startX = dottedlineLayerSize.width * 0.5 - 50
    local startY = dottedlineLayerSize.height * 0.5 + 67
    local tipLabels = {}
    for i = index, endIndex do
        local imgae = display.newNSprite(RES_DIR['IMAGE_' .. i], startX, startY - (i - index) * 80)    
        leftMiddleLayer:addChild(imgae)

        local tipLabel = display.newLabel(startX + 120, imgae:getPositionY(), {ap = display.LEFT_CENTER, fontSize = 24, color = '#97766f'})
        leftMiddleLayer:addChild(tipLabel)

        if i ~= endIndex then
            local line = display.newNSprite(RES_DIR.LINE_DOTTED_1, dottedlineLayerSize.width * 0.5, imgae:getPositionY() - 40)
            leftMiddleLayer:addChild(line)
        end

        table.insert(tipLabels, tipLabel)
    end

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image1 = display.newImageView(RES_DIR.IMAGE_1, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(image1)

    return {
        view       = view,
        tipLabels  = tipLabels,
        tipLabel4  = tipLabel4,
        descLabel2 = descLabel2,
    }
end

function GuideTTGamePage2:getViewData()
    return self.viewData_
end

return GuideTTGamePage2