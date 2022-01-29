--[[
 * descpt : PVP指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTTGamePage3 = class('GuideTTGamePage3', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTTGamePage3'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),

    IMAGE1             = _res('ui/ttgame/common/cardgame_common_bg_1.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuideTTGamePage3:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTTGamePage3:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTTGamePage3:initView()
    
end

function GuideTTGamePage3:refreshUI(data)
    local viewData   = self:getViewData()

    local tipLabel3  = viewData.tipLabel3
    display.commonLabelParams(tipLabel3, {text = tostring(data['3']), reqW =230 })
     --local tipLabel2  = viewData.tipLabel2
     --display.commonLabelParams(tipLabel2, {text = tostring(data['4']) })

    local tipLabels = viewData.tipLabels
    local t = {'4', '5', '6'}
    for index, value in ipairs(t) do
        display.commonLabelParams(tipLabels[index], {text = tostring(data[value])})
    end
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local dottedlineLayerSize = cc.size(420, 180)
    local middleX, middleY = dottedlineLayerSize.width * 0.5, dottedlineLayerSize.height * 0.5
    ------------------------------
    -- left middle layer

    local leftMiddleLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(leftMiddleLayer)

    local imageSize = cc.size(346, 94)
    local imageLayer = display.newLayer(middleX, middleY, {ap = display.CENTER, size = imageSize})
    leftMiddleLayer:addChild(imageLayer)

    local imgae1 = display.newImageView(RES_DIR.IMAGE1, imageSize.width * 0.5, imageSize.height * 0.5, {scale9 = true, size = imageSize})
    imageLayer:addChild(imgae1)

    -- 规则图片icon id
    local conf = {5, 8, 2, 10}
    local startX = 40
    for index, ruleId in ipairs(conf) do
        local node = TTGameUtils.GetRuleIconNode(ruleId)
        display.commonUIParams(node, {ap = display.LEFT_CENTER, po = cc.p(startX + (index - 1) * 70, 47)})
        imageLayer:addChild(node)
    end

    local headIcon2 = display.newImageView(RES_DIR.ICO_HAND, dottedlineLayerSize.width - 22, 56, {ap = display.LEFT_TOP})
    headIcon2:setScaleX(-1)
    leftMiddleLayer:addChild(headIcon2) 

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local tipLabel3 = display.newLabel(30, rightImgLayerSize.height - 56, {ap = display.LEFT_CENTER, fontSize = 20, color = '#97766f'})
    rightImgLayer:addChild(tipLabel3)

    local conf1 = {6, 9, 7}
    local startY = tipLabel3:getPositionY() - 20
    local tipLabels = {}
    local heights = {
        0 ,
        240,
        380
    }
    for index, ruleId in ipairs(conf1) do
        local line = display.newNSprite(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width * 0.5, startY -heights[index] )
        rightImgLayer:addChild(line)

        local node = TTGameUtils.GetRuleIconNode(ruleId)
        display.commonUIParams(node, {ap = display.LEFT_TOP, po = cc.p(30, line:getPositionY() - 10)})
        rightImgLayer:addChild(node)
        node:setScale(0.5)

        local labelStartX = node:getPositionX() + node:getContentSize().width + 8 -30
        local tipLabel = display.newLabel(labelStartX, node:getPositionY()+5, {w = 400, ap = display.LEFT_TOP, fontSize = 20, color = '#97766f'})
        rightImgLayer:addChild(tipLabel)
        table.insert(tipLabels, tipLabel)
    end

    return {
        view       = view,
        tipLabel3  = tipLabel3,
        tipLabels  = tipLabels,
    }
end

function GuideTTGamePage3:getViewData()
    return self.viewData_
end

return GuideTTGamePage3