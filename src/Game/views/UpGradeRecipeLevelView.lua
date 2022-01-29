local UpGradeRecipeLevelView = class('home.UpGradeRecipeLevelView',function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.UpGradeRecipeLevelView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local  RES_DICT = {
    COMMON_BG = _res("ui/common/common_bg_7.png"),
    FOOD_CIRCLE =  _res("ui/home/kitchen/kitchen_bg_food_quan.png"),
    GRADE_A  =  _res("ui/home/kitchen/cooking_grade_ico_1.png"),
    BTN_NORNAL =  _res("ui/common/common_btn_white_default.png"),
    BTN_SECLECT =  _res("ui/common/common_btn_orange.png"),
    COMMON_TITLE  = _res("ui/common/common_title_5.png"),  
    COOKING_LEVEL_UP = _res("ui/home/kitchen/cooking_level_up_ico_arrow.png"),  
    ICON_DOWN  = _res("ui/home/kitchen/kitchen_ico_down.png"),  
    ICON_UP  = _res("ui/home/kitchen/kitchen_ico_top.png"),  
    BG_TITLE = _res("ui/common/common_bg_title_2.png"), 
    TOP_IMAGE = _res("ui/home/kitchen/kitchen_bg_food_mastery_words.png"), 
    COMMON_FONT_NAME = _res("ui/common/common_bg_font_name.png"),
    
}
local COLLECT_BTNS = {
    UPGRADE_CANACEL = 1101,
    UPGRADE_LEVEL = 1102 

}
function UpGradeRecipeLevelView:ctor(param)
    param = param or {}
    self:initUI()
end

function UpGradeRecipeLevelView:initUI()
    local closeView = display.newLayer(display.cx, display.cy, {ap = display.CENTER , size = display.size ,enable = true, color = cc.c4b(0,0,0,100),cb = function ()
        if GuideUtils.IsGuiding() then
        else
            self:removeFromParent()
        end

    end })
    self:addChild(closeView)
    local bgImage = display.newImageView(RES_DICT.COMMON_BG)
    local bgSize = bgImage:getContentSize()
    bgImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    -- local bgLayout = display.newLayer(display.cx,display.cy ,{ap = display.CENTER , size = bgSize , color = cc.c4b(10,20,20,40)})
    local bgLayout = CLayout:create(bgSize)
    bgLayout:setPosition(display.center)
    bgLayout:addChild(bgImage)
    local  swallowView  = display.newLayer(bgSize.width * 0.5, bgSize.height*0.5,{ ap  = display.CENTER, size = bgSize ,enable = true ,color = cc.c4b(0,0,0,0)})
    bgLayout:addChild(swallowView)
    
    local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 -5 )})
    display.commonLabelParams(titleBg,
        {text = __('菜谱升级'),
        fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
        offset = cc.p(0, -2)})
	bgLayout:addChild(titleBg)
    self:addChild(bgLayout,2)

    local contentSize = cc.size(525,495)
    local contentLayer = display.newLayer(bgSize.width/2,bgSize.height - 47 ,{enable = false  ,size =contentSize , ap = display.CENTER_TOP})
    bgLayout:addChild(contentLayer)
    bgLayout:setName("bgLayout")
    local offsetWidth = 125
    local topSize = cc.size(508,240)
    local topImage = display.newImageView(RES_DICT.TOP_IMAGE,contentSize.width/2,contentSize.height,{ap = display.CENTER_TOP,size = topSize ,scale9 = true})
    contentLayer:addChild(topImage)

    local recipeCircle = display.newImageView(RES_DICT.FOOD_CIRCLE,offsetWidth,150,{ap = display.CENTER})
    local iconPath = CommonUtils.GetGoodsIconPathById('190001')
    local recipeCircleSize = recipeCircle:getContentSize()
    local recipeImage  = display.newImageView(iconPath,recipeCircleSize.width/2,recipeCircleSize.height/2)
    recipeCircle:addChild(recipeImage)
    topImage:addChild(recipeCircle)
    local gradeImageOne = display.newImageView(RES_DICT.GRADE_A)
    local gradeSize  =  gradeImageOne:getContentSize()
    gradeImageOne:setPosition(cc.p(gradeSize.width /2 ,gradeSize.height/2 ))
    local levelUpIcon = display.newImageView(RES_DICT.COOKING_LEVEL_UP)
    local iconSize = levelUpIcon:getContentSize()
    local gradeLayout = CLayout:create(cc.size(gradeSize.width*2+iconSize.width*3,gradeSize.height))
    gradeLayout:setPosition(cc.p(125,38))
    gradeLayout:addChild(gradeImageOne)
    topImage:addChild(gradeLayout)
    local gradeImageTwo = display.newImageView(RES_DICT.GRADE_A,gradeSize.width * 1.5 + 3*iconSize.width,gradeSize.height/2)
    gradeLayout:addChild(gradeImageTwo)

    for i = 1 ,3 do 
        local icon_Up = display.newImageView(RES_DICT.COOKING_LEVEL_UP,gradeSize.width + (i - 0.5)*iconSize.width ,gradeSize.height/2)
        gradeLayout:addChild(icon_Up)
    end

    local offsetWidthTwo = 270  
    local titleDesBtn = display.newButton( 354,189 , { n =  RES_DICT.COMMON_FONT_NAME , s=  RES_DICT.COMMON_FONT_NAME ,d = RES_DICT.COMMON_FONT_NAME ,enable = false})
    topImage:addChild(titleDesBtn)
    display.commonLabelParams(titleDesBtn,fontWithColor('16',{text = __('升级提升')}))
    local propertyTables = {
        __('厨力点（外卖）') ,
        __('制作时间（厨房）'),
        __('制作数量（厨房）'),
        __('餐厅售价（餐厅）'),
    }
    local up_or_down_icons = {}
    local labelTable = {}
    local labelSize = cc.size(0,0)
    for i =1 , 4 do 
        local label = display.newLabel(270,154 -(i-1) *32,fontWithColor('16' , {text = propertyTables[i] , ap = display.LEFT_CENTER}))
        local icon_up_or_down = display.newImageView(RES_DICT.ICON_DOWN,462,154 -(i-1) *32 )
        topImage:addChild(icon_up_or_down)
        topImage:addChild(label)
        labelTable[#labelTable+1] = label
        local oneSize = display.getLabelContentSize(label)
        labelSize = oneSize.width > labelSize.width and oneSize or labelSize
        table.insert( up_or_down_icons, #up_or_down_icons+1, icon_up_or_down ) 
    end
    if labelSize.width > 180 then

        local posX =  0
        local scale = 1
        if labelSize.width > 240 then
            posX =   270 - (240 -180)
            scale = 240 /  labelSize.width
        else
            posX =   270 - (labelSize.width -180)
        end

        for i, v in pairs(labelTable) do
            local pos = cc.p(v:getPosition())
            pos.x = posX
            v:setPosition(pos)
            local currentScale = v:getScale()
            v:setScale(currentScale * scale)
        end
    end



    local goodsTitleImage = display.newButton( contentSize.width/2 ,contentSize.height - 265,{ n = RES_DICT.COMMON_TITLE  , s = RES_DICT.COMMON_TITLE , enable = false })
    contentLayer:addChild(goodsTitleImage)
    display.commonLabelParams(goodsTitleImage, fontWithColor('16', { text = __('升级材料') , paddingW  =0}))
    local btnCanacel = display.newButton(contentSize.width/2 - 80,55, { n = RES_DICT.BTN_NORNAL , s = RES_DICT.BTN_NORNAL})
    contentLayer:addChild(btnCanacel)
    contentLayer:setName("contentLayer")
    display.commonLabelParams(btnCanacel, fontWithColor('14', {text = __('取消')}))
    btnCanacel:setName("btnCanacel")
    btnCanacel:setTag(COLLECT_BTNS.UPGRADE_CANACEL)
    local upGradeBtn = display.newButton(contentSize.width/2 + 80,55, { n = RES_DICT.BTN_SECLECT , s = RES_DICT.BTN_SECLECT})
    contentLayer:addChild(upGradeBtn)
    display.commonLabelParams(upGradeBtn, fontWithColor('14', {text = __('升级')}))
    upGradeBtn:setTag(COLLECT_BTNS.UPGRADE_LEVEL)
    upGradeBtn:setName("upGradeBtn")
    self.viewData = {
        gradeImageOne = gradeImageOne ,
        gradeImageTwo = gradeImageTwo ,
        up_or_down_icons = up_or_down_icons ,
        recipeImage = recipeImage,
        btnCanacel = btnCanacel ,
        upGradeBtn = upGradeBtn ,
        closeView = closeView ,
        bgLayout = bgLayout ,
    }
end

function UpGradeRecipeLevelView:onEnter()

end
function UpGradeRecipeLevelView:createNeedGoods(data)
    local consume_Data = data
    local goodSize =cc.size(108,108)
    local needSize = cc.size(108*(#consume_Data) , 108)
    local needLayout = CLayout:create(needSize)
    local foodMaterial = true
    for i =1 , #consume_Data do
        local data = consume_Data[i]
        local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = false})
            display.commonUIParams(goodNode, {animate = false, cb = function (sender)
                uiMgr:AddDialog("common.GainPopup", {goodId = data.goodsId})
        end})
        goodNode:setAnchorPoint(cc.p(0.5,0.5))
        goodNode:setPosition(cc.p((i-0.5)*goodSize.width ,needSize.height/2))
        goodNode:setScale(0.8)
        needLayout:addChild(goodNode)
        local oneColor ='6' 
        if checkint(gameMgr:GetAmountByGoodId(data.goodsId)) < checkint(data.num) then -- 检测食材是否充足
            oneColor = '10' 
            if foodMaterial then 
                foodMaterial = false 
            end
        end
        local richLabel = display.newRichLabel((i-0.5)*goodSize.width ,-10,{ ap = display.CENTER , r = true , c = {
            fontWithColor(oneColor ,{fontSize =20 ,text =tostring(gameMgr:GetAmountByGoodId(data.goodsId)) .."/" } )  ,
            fontWithColor('6',{text = tostring(data.num),fontSize =20 }) 
        }})
        needLayout:addChild(richLabel)
    end
    self.foodMaterial = foodMaterial
    return needLayout
end
function UpGradeRecipeLevelView:updateView(data)
    local recipeData = CommonUtils.GetConfigAllMess('recipe',"cooking")
    local recipeOneData = recipeData[tostring(data.recipeId)] 
    local recipePath = CommonUtils.GetGoodsIconPathById(recipeOneData.foods[1].goodsId )
    local gradeData = recipeOneData['grade'][tostring( data.gradeId)]
    local gradeUpData = recipeOneData['grade'][tostring( data.gradeId+1)]
    -- 判段数据是否异常 有时候这个页面还没有删除 而数据已经更新就会造成崩溃
    if (not  gradeData)  or (not  gradeUpData)then
        return
    end
    self.viewData.recipeImage:setTexture(recipePath)

    if checkint(gradeUpData.cookingPoint) > checkint(gradeData.cookingPoint) then
        self.viewData.up_or_down_icons[1]:setTexture(RES_DICT.ICON_UP)
    else 
        self.viewData.up_or_down_icons[1]:setTexture(RES_DICT.ICON_DOWN)
    end
    
    if checkint(gradeUpData.makingTime) > checkint(gradeData.makingTime) then
        self.viewData.up_or_down_icons[2]:setTexture(RES_DICT.ICON_UP)
    else 
        self.viewData.up_or_down_icons[2]:setTexture(RES_DICT.ICON_DOWN)
    end
    if checkint(gradeUpData.makingMax) > checkint(gradeData.makingMax) then
        self.viewData.up_or_down_icons[3]:setTexture(RES_DICT.ICON_UP)
    else 
        self.viewData.up_or_down_icons[3]:setTexture(RES_DICT.ICON_DOWN)
    end
    if checkint(gradeUpData.gold) > checkint(gradeData.gold) then
        self.viewData.up_or_down_icons[4]:setTexture(RES_DICT.ICON_UP)
    else 
        self.viewData.up_or_down_icons[4]:setTexture(RES_DICT.ICON_DOWN)
    end
    self.viewData.gradeImageOne:setTexture(_res(string.format( "ui/home/kitchen/cooking_grade_ico_%d.png",data.gradeId)))
    self.viewData.gradeImageTwo:setTexture(_res(string.format( "ui/home/kitchen/cooking_grade_ico_%d.png",data.gradeId+1)))
    local consume = recipeOneData['grade'][tostring( data.gradeId+1)].consume
    local node = self.viewData.bgLayout:getChildByTag(115)
    if node then -- 修改重影问题
        node:removeFromParent()
        node = nil 
    end
    local needLayout =  self:createNeedGoods(consume)
    self.viewData.bgLayout:addChild(needLayout)
    needLayout:setTag(115)
    local bgSize =self.viewData.bgLayout:getContentSize()
    needLayout:setPosition(cc.p(bgSize.width/2,160))

end
function UpGradeRecipeLevelView:onCleanup()
    cc.UserDefault:getInstance():flush()
end


return UpGradeRecipeLevelView
