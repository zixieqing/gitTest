--[[
餐厅节日活动提示板

--]]
local LobbyFestivalTipView = class('Game.views.LobbyFestivalTipView', function ()
	return display.newLayer()
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local RES_DIR = {
    BG           = _res('ui/common/common_bg_list.png'),
    TITLE        = _res('ui/common/common_title_5.png'),
    LV_BG        = _res('avatar/ui/kitchen_make_bg_level.png'),
    ATTR_BG      = _res('ui/home/market/market_buy_bg_info.png'),
    ARROW        = _res('ui/common/common_bg_tips_horn.png'),
}

local CreateView          = nil
local CreateAttr          = nil
local getCookingGradeImg  = nil

local LAYER_SIZE          = cc.size(298, 251)

local ATTR_KEY_CONFIG     = {'taste', 'museFeel', 'fragrance', 'exterior'}
local ATTR_NAME_CONFIG    = {__('味道'), __('口感'), __('香味'), __('外观')}

function LobbyFestivalTipView:ctor( ... )
    self.args = unpack({...}) or {}

    xTry(function ()
        self:setContentSize(LAYER_SIZE)
        -- self.recipeId = nil
        self.gradeId  = nil

        local arrowDirection = self.args.arrowDirection or 1

        self.viewData = CreateView(arrowDirection)
        self:addChild(self.viewData.layer)
    end,__G__TRACKBACK__)
end

--==============================--
--desc: 更新UI
--time:2017-12-19 02:44:22
--@data: 餐厅活动菜谱数据
--@return 
--==============================---
function LobbyFestivalTipView:updateUi(recepeFestivalData, recepeData)
    -- if self.recipeId == recepeData.recipeId then return end
    -- self.recipeId = recepeData.recipeId

    local gradeId            = checkint(recepeFestivalData.recipeGrade)
    local localMenuDataGrade = checkint(recepeData.gradeId)
    local isGradeSatisfy     = localMenuDataGrade >= gradeId

    -- self:updateQuality(isGradeSatisfy, gradeId)
    self:updateAttrs(recepeFestivalData, recepeData)
end

function LobbyFestivalTipView:updateQuality(isGradeSatisfy, gradeId)

    -- local color = isGradeSatisfy and '#30ab05' or  '#c52d02'
    -- local text = isGradeSatisfy and __('(已达成)') or __('(未达成)')
    -- local qualityImg       = self.viewData.qualityImg
    -- local qualitytTipLabel = self.viewData.qualitytTipLabel
    -- local lvBgSize         = self.viewData.lvBgSize
    -- qualityImg:setTexture(app.cookingMgr:getCookingGradeImg(gradeId))
    -- display.commonLabelParams(qualitytTipLabel, {text = text, color = color})

end

function LobbyFestivalTipView:updateAttrs(recepeFestivalData, recepeData)
    local attrBgLayer   = self.viewData.attrBgLayer
    if attrBgLayer:getChildrenCount() > 0 then
        attrBgLayer:removeAllChildren()
    end

    local attrs = self:getShowAtrr(recepeFestivalData, recepeData)

    for i,attr in ipairs(attrs) do
        CreateAttr(attrBgLayer, i, attr)
    end
end

function LobbyFestivalTipView:getShowAtrr(recepeFestivalData, recepeData)
    local serAttr            = recepeFestivalData.attr
    local localMenuDataGrade = checkint(recepeData.gradeId)
    local gradeId            = checkint(recepeFestivalData.recipeGrade)
    local isGradeSatisfy     = localMenuDataGrade >= gradeId
    
    local gradeText  = isGradeSatisfy and __('(已达成)') or __('(未达成)')
    local gradeColor = isGradeSatisfy and '#30ab05' or  '#c52d02'

    local showAttr = {
        {attrName = __('评级'), text = gradeText, color = gradeColor, img = app.cookingMgr:getCookingGradeImg(gradeId)}
    }
    for i,attrName in ipairs(ATTR_NAME_CONFIG) do
        if serAttr[tostring(i)] then
            local attrNum = checkint(serAttr[tostring(i)])
            local localNum = checkint(recepeData[ATTR_KEY_CONFIG[i]])
            print(localNum, attrNum)
            local isNumSatisfy = localNum >= attrNum

            local color = isNumSatisfy and '#30ab05' or  '#c52d02'
            table.insert(showAttr, {attrName = attrName, num = attrNum, color = color})
        else
            table.insert(showAttr, {attrName = attrName, num = '--', color = '#30ab05'})
        end
    end

    return showAttr
end

CreateView = function (arrowDirection)
    local layer = display.newLayer(0, 0, {size = LAYER_SIZE, color = cc.c3b(100,100,100)})
    local bg = display.newImageView(RES_DIR.BG, 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true, size = LAYER_SIZE})
    layer:addChild(bg)
    
    local title = display.newButton(LAYER_SIZE.width / 2, LAYER_SIZE.height * 0.975, {n = RES_DIR.TITLE, ap = display.CENTER_TOP , scale9 = true })
    display.commonLabelParams(title, fontWithColor(4, {fontSize = 22, paddingW = 20,  text = __('节日特色')}))
    layer:addChild(title)
    
    -- local lvBg = display.newImageView(RES_DIR.LV_BG, title:getPositionX(), 168, {ap = display.CENTER_BOTTOM})
    -- local lvBgSize = lvBg:getContentSize()
    -- layer:addChild(lvBg)
    
    -- local qualityLabel     = display.newLabel(0, 0, {fontSize = 22, color = '#a19b85', text = __('所需评级:'), ap = display.RIGHT_CENTER})
    -- local qualityImg       = display.newImageView(_res('ui/home/kitchen/cooking_grade_ico_5.png'), 0, 0, {ap = display.CENTER})
    -- local qualitytTipLabel = display.newLabel(0, 0, {fontSize = 22, ap = display.LEFT_CENTER})
    -- local qualityImgSize   = qualityImg:getContentSize()
    -- display.commonUIParams(qualityImg, {po = cc.p(lvBgSize.width / 2, lvBgSize.height / 2)})
    -- display.commonUIParams(qualityLabel, {po = cc.p(lvBgSize.width / 2 - qualityImgSize.width / 2 + 3, lvBgSize.height / 2)})
    -- display.commonUIParams(qualitytTipLabel, {po = cc.p(lvBgSize.width / 2 + qualityImgSize.width / 2 - 3, lvBgSize.height / 2)})
    -- lvBg:addChild(qualityImg)
    -- lvBg:addChild(qualityLabel)
    -- lvBg:addChild(qualitytTipLabel)

    local attrBgSize = cc.size(LAYER_SIZE.width, 210)
    local attrBgLayer = display.newLayer(0, 0, {size = attrBgSize, ap = display.LEFT_BOTTOM})
    layer:addChild(attrBgLayer)
    
    local boardArrow = display.newImageView(RES_DIR.ARROW, 0, 0)
    layer:addChild(boardArrow)
    if arrowDirection == 1 then
        display.commonUIParams(boardArrow, {ap = display.LEFT_CENTER, po = cc.p(LAYER_SIZE.width, LAYER_SIZE.height / 2 + 10)})
        boardArrow:setRotation(90)
    else
        display.commonUIParams(boardArrow, {ap = display.CENTER_BOTTOM, po = cc.p(LAYER_SIZE.width / 2, LAYER_SIZE.height - 11)})
    end

    return {
        layer         = layer,
        bg            = bg,
        -- qualityImg    = qualityImg,
        -- qualityLabel  = qualityLabel,
        -- qualitytTipLabel = qualitytTipLabel,
        attrBgLayer   = attrBgLayer,

        lvBgSize      = lvBgSize,
    }
end

-- @params attr {attrName = attrName, num = attrNum, color = color}
CreateAttr = function (attrLayer, i, attr)
    local attrLayerSize = attrLayer:getContentSize()
    local attrBgSize = cc.size(240, 31)

    local attrBgLayer = display.newLayer(attrLayerSize.width / 2, attrLayerSize.height - 5 - (attrBgSize.height + 9) * (i - 1), {size = attrBgSize, ap = display.CENTER_TOP})
    attrLayer:addChild(attrBgLayer)

    local attrBg = display.newImageView(RES_DIR.ATTR_BG, attrBgSize.width / 2, attrBgSize.height / 2, {scale9 = true, size = attrBgSize, ap = display.CENTER})
    attrBgLayer:addChild(attrBg)
    


    if attr.img then
        local  attrRichLabel = display.newRichLabel(8, attrBg:getPositionY() , {r= true ,
            ap = display.LEFT_CENTER , c = {
                fontWithColor(6, {text = tostring(attr.attrName)}),
                { img = attr.img , scale = 0.7 },
                fontWithColor(6, {text = tostring(attr.text),  color = attr.color})
            }
        })
        attrBgLayer:addChild(attrRichLabel)
        CommonUtils.SetNodeScale(attrRichLabel , {width = 230 })
    else
        local attrLabel = display.newLabel(8, attrBg:getPositionY(), fontWithColor(6, {text = tostring(attr.attrName), ap = display.LEFT_CENTER}))
        attrBgLayer:addChild(attrLabel)
        local attrNumberLabel = display.newLabel(attrBgSize.width - 10, attrBg:getPositionY(), fontWithColor(6, {text = tostring(attr.num), ap = display.RIGHT_CENTER, color = attr.color}))
        attrBgLayer:addChild(attrNumberLabel)
    end
end

getCookingGradeImg = function (gradeId)
    local path = _res('ui/home/kitchen/cooking_grade_ico_'..gradeId..'.png')
    if not utils.isExistent(path) then
        path = _res('ui/home/kitchen/cooking_grade_ico_1.png')
    end
    return path
end

return LobbyFestivalTipView