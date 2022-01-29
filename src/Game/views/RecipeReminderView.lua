---@class RecipeReminderView
local RecipeReminderView = class('RecipeReminderView', function ()
   local node = CLayout:create(display.size)
   node.name = 'Game.views.RecipeReminderView'
   node:enableNodeEvents()
   return node
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newLayer = display.newLayer
local RES_DICT = {
    KITCHEN_BG_FOOD_QUAN          = _res('ui/home/kitchen/kitchen_bg_food_quan.png'),
    KITCHEN_BG_DESCRIBE           = _res('ui/home/kitchen/kitchen_bg_describe.png'),
    COMMON_BG_GOODS               = _res('ui/common/common_bg_goods.png'),
    COMMON_BG_4                   = _res('ui/common/common_bg_4.png'),
    COMMON_FRAME_GOODS_1          = _res('ui/common/common_frame_goods_1.png'),
    COMMON_BG_FRAME_GOODS_ELECTED = _res('ui/common/common_bg_frame_goods_elected.png'),
    COOKING_MASTERY_BAR_1         = _res('ui/home/kitchen/cooking_mastery_bar_1.png'),
    COOKING_MASTERY_BAR_BG        = _res('ui/home/kitchen/cooking_mastery_bar_bg.png'),
    COMMON_ARROW                  = _res("ui/common/common_arrow.png"),
}
local RecipeConfig = CommonUtils.GetConfigAllMess('recipe', 'cooking')
local StyleConfig  = CommonUtils.GetConfigAllMess('style', 'cooking')
function RecipeReminderView:ctor(param)
    self:initUi()
end

function RecipeReminderView:initUi()
    local closeLayer = newLayer(display.cx, display.cy,{ap = display.CENTER,  size = display.size})
    local recipeLayout = newLayer(display.cx , display.cy ,
                                  { ap = display.RIGHT_CENTER, size = cc.size(559, 644) })
    self:addChild(recipeLayout)
    self:addChild(closeLayer)
    local swallowLayer = newLayer(0, 0,
                                  { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(555, 640), enable = true })
    recipeLayout:addChild(swallowLayer)

    local bgImage = newImageView(RES_DICT.COMMON_BG_4, 0, 0,
                                 { ap = display.LEFT_BOTTOM, tag = 572, enable = false, scale9 = true, size = cc.size(559, 644) })
    recipeLayout:addChild(bgImage)

    local styleName = newLabel(259, 606,
                               fontWithColor(14, { outline = false,  ap = display.CENTER, color = '#9c5215', text = "", fontSize = 28, tag = 577 }))
    recipeLayout:addChild(styleName)

    local recipeContent = newLayer(113, 493,
                                   { ap = display.CENTER, color = cc.r4b(0), size = cc.size(145, 200), enable = true })
    recipeLayout:addChild(recipeContent)

    local circleImage = newNSprite(RES_DICT.KITCHEN_BG_FOOD_QUAN, 72, 129,
                                   { ap = display.CENTER, tag = 574 })
    circleImage:setScale(0.8 )
    recipeContent:addChild(circleImage)

    local recipeImage = newNSprite(RES_DICT.KITCHEN_BG_FOOD_QUAN, 70, 124,
                                   { ap = display.CENTER, tag = 575 })
    recipeImage:setScale(0.8, 0.8)
    recipeContent:addChild(recipeImage)

    local recipeName = newLabel(71, 43,
                                fontWithColor(14, { outline = false,  ap = display.CENTER, w = 140 , hAlign = display.TAC , color = '#c64f00', text = "", fontSize = 26, tag = 576 }))
    recipeContent:addChild(recipeName)

    local recipeDecrImage = newNSprite(RES_DICT.KITCHEN_BG_DESCRIBE, 355, 481,
                                       { ap = display.CENTER, tag = 578 })
    recipeDecrImage:setScale(1, 1)
    recipeLayout:addChild(recipeDecrImage)

    local listSize = cc.size(300, 160 )
    local listView = CListView:create(listSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint(display.CENTER)
    listView:setPosition(cc.p(10, 25))
    recipeLayout:addChild(listView)
    listView:setPosition(355, 481)

    local recipeDescrLayout = display.newLayer(0,0,{size = listSize})
    listView:insertNodeAtLast(recipeDescrLayout)

    local recipeDescr = newLabel(10, 0,
                                 fontWithColor(6,{ ap = display.LEFT_BOTTOM , text = "", w = 290 ,   fontSize = 22, tag = 193 }))
    recipeDescrLayout:addChild(recipeDescr)

    local prograssBgImage = newNSprite(RES_DICT.COOKING_MASTERY_BAR_BG, 422, 27,
                                       { ap = display.CENTER, tag = 580 })
    prograssBgImage:setScale(1, 1)
    recipeLayout:addChild(prograssBgImage)

    local prograssBar = CProgressBar:create(RES_DICT.COOKING_MASTERY_BAR_1)
    prograssBar:setAnchorPoint(cc.p(0.5, 0.5))
    prograssBar:setMaxValue(100)
    prograssBar:setValue(52)
    prograssBar:setScale(1, 1)
    prograssBar:setPosition(422, 27)
    prograssBar:setDirection(eProgressBarDirectionLeftToRight)
    recipeLayout:addChild(prograssBar)

    local prograssLabel = newLabel(422, 27,
                                   { ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 188 })
    recipeLayout:addChild(prograssLabel)

    local getPrograss = newLabel(258, 28,
                                 fontWithColor(6, { ap = display.CENTER, text = __('收集进度'), fontSize = 20, tag = 189 }))
    recipeLayout:addChild(getPrograss)

    local gradeViewBgImage = newImageView(RES_DICT.COMMON_BG_GOODS, 271, 212,
                                          { ap = display.CENTER, tag = 191, enable = false, scale9 = true, size = cc.size(515, 320) })
    recipeLayout:addChild(gradeViewBgImage)
    local gradSize = cc.size(500, 300)
    local gridViewCellSize = cc.size(125,125)
    local gridView = CGridView:create(gradSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setAnchorPoint(display.CENTER_BOTTOM)
    gridView:setColumns(4)
    gridView:setAutoRelocate(true)
    recipeLayout:addChild(gridView, 2)
    gridView:setPosition( 270, 60 )
    self.viewData  =  {
        recipeLayout            = recipeLayout,
        swallowLayer            = swallowLayer,
        bgImage                 = bgImage,
        styleName               = styleName,
        recipeContent           = recipeContent,
        circleImage             = circleImage,
        recipeImage             = recipeImage,
        recipeName              = recipeName,
        recipeDecrImage         = recipeDecrImage,
        recipeDescr             = recipeDescr,
        recipeDescrLayout       = recipeDescrLayout,
        listView                = listView,
        prograssBgImage         = prograssBgImage,
        prograssBar             = prograssBar,
        prograssLabel           = prograssLabel,
        getPrograss             = getPrograss,
        gradeViewBgImage        = gradeViewBgImage,
        gridView                = gridView,
    }
end
function RecipeReminderView:CreatRecipeNode()
    local goodLayout = newLayer(0,0,
                                { ap = display.CENTER, color = cc.c4b(0,0,0,0), size = cc.size(108, 108), enable = true })

    local frameImage = newNSprite(RES_DICT.COMMON_FRAME_GOODS_1, 54, 54,
                                  { ap = display.CENTER, tag = 33 })
    frameImage:setScale(1, 1)
    goodLayout:addChild(frameImage)

    local goodImage = newNSprite(RES_DICT.GOODS_ICON_899001, 54, 54,
                                 { ap = display.CENTER, tag = 34 })
    goodImage:setScale(0.55, 0.55)
    goodLayout:addChild(goodImage)
    local selectImage = display.newImageView(RES_DICT.COMMON_BG_FRAME_GOODS_ELECTED ,54, 54 )
    goodLayout:addChild(selectImage)
    selectImage:setVisible(false)
    local arrowImage = display.newImageView(RES_DICT.COMMON_ARROW , 108, 108 , {ap = display.RIGHT_TOP })
    goodLayout:addChild(arrowImage)
    arrowImage:setVisible(false)
    goodLayout.viewData  =   {
        goodLayout              = goodLayout,
        frameImage              = frameImage,
        goodImage               = goodImage,
        selectImage             = selectImage,
        arrowImage              = arrowImage,
    }
    return goodLayout
end
--==============================--
---@Description: 更新节点的显示
---@param data table {index = index , recipeId = recipeId,callback = callback }
---@author : xingweihao
---@date : 2019/1/23 10:14 PM
--==============================--
function RecipeReminderView:UpdateRecipeNode( data )
    local cell = data.cell
    local index = data.index
    local recipeId = data.recipeId
    local goodLayout = cell:getChildByName("goodLayout")
    local isOwner = data.isOwner
    local viewData = goodLayout.viewData
    viewData.arrowImage:setVisible(isOwner)
    if index == self.currentIndex then
        viewData.selectImage:setVisible(true)
    else
        viewData.selectImage:setVisible(false)
    end
    if isOwner then
        viewData.goodImage:setColor(cc.c3b(255,255,255) )
    else
        viewData.goodImage:setColor(cc.c3b(80,80,80) )
    end
    goodLayout:setTag(data.index)
    display.commonUIParams(goodLayout , { cb = data.callback})
    local path = self:GetRecipeIconByPath(recipeId)
    viewData.goodImage:setTexture(path)
end

function RecipeReminderView:UpdateUI(data)
    local index = data.index
    local recipeId =data.recipeId
    local isOwner = data.isOwner 
    local viewData = self.viewData
    local gridView = viewData.gridView
    local preIndex = data.preIndex
    local preCell = gridView:cellAtIndex(preIndex -1)
    if preCell and (not tolua.isnull(preCell)) then
        local goodLayout = preCell:getChildByName("goodLayout")
        local viewData = goodLayout.viewData
        viewData.selectImage:setVisible(false)
    end
    local cell =  gridView:cellAtIndex(index -1)
    if cell and  (not tolua.isnull(cell))  then
        local goodLayout = cell:getChildByName("goodLayout")
        local viewData = goodLayout.viewData
        viewData.selectImage:setVisible(true)
    end
    local recipePath = self:GetRecipeIconByPath(recipeId)
    viewData.recipeImage:setTexture(recipePath)
    local recipeOneData = RecipeConfig[tostring(recipeId)]
    local goodsConfig = CommonUtils.GetConfig('goods','goods',recipeId ) or {}
    local recipeName  =  tostring(goodsConfig.name) 
    display.commonLabelParams(viewData.recipeName , {text = recipeName })
    if not  isOwner then
        local foodMaterialTips = recipeOneData.foodMaterialTips
        foodMaterialTips = string.gsub(foodMaterialTips , "<b>" ,"")
        foodMaterialTips = string.gsub(foodMaterialTips , "</b>" ,"")
        display.commonLabelParams(viewData.recipeDescr , {text = foodMaterialTips})
        viewData.recipeDecrImage:setVisible(true)
    else
        viewData.recipeDecrImage:setVisible(true)
        display.commonLabelParams(viewData.recipeDescr , {text = __('该菜谱已经研究')})
    end
    local recipeDescrSize = display.getLabelContentSize(viewData.recipeDescr)
    local height = recipeDescrSize.height
    viewData.recipeDescrLayout:setContentSize(cc.size(300, height))
    viewData.listView:reloadData()
end
---==============================--
---@Description: 获取菜谱的icon 路径
---@param recipeId number 菜谱id
---@author : xingweihao
---@date : 2019/1/24 11:33 AM
--==============================--
function RecipeReminderView:GetRecipeIconByPath(recipeId)
    local recipeOneData = RecipeConfig[tostring(recipeId)] or {}
    local goodsId       = checktable(checktable(recipeOneData.foods)[1]).goodsId
    local  path = _res('arts/goods/goods_icon_error.png')
    if goodsId then
        path = CommonUtils.GetGoodsIconPathById(goodsId)
    end
    return path
end
--==============================--
---@Description: 显示当前所在的菜系和当前菜系的总数量
---@param styleInfoData table { styleId = styleId , ownerNum =  ownerNum  }
---@author : xingweihao
---@date : 2019/1/24 2:24 PM
--==============================--
function RecipeReminderView:UpdateStyleRecipeInfo(styleInfoData)
    local styleId = styleInfoData.styleId
    local styleOneConfig = StyleConfig[tostring(styleId)]
    local styleName = styleOneConfig.name
    local viewData = self.viewData
    local ownerNum = styleInfoData.ownerNum
    local countNum = styleOneConfig.studyRecipe
    display.commonLabelParams(viewData.styleName, {text = string.fmt(__('_name_一览') , {_name_ = styleName} )  })
    display.commonLabelParams(viewData.prograssLabel ,{text = string.format('%d/%d' ,ownerNum , countNum ) })
    viewData.prograssBar:setMaxValue(countNum)
    viewData.prograssBar:setValue(ownerNum)
end
return RecipeReminderView
