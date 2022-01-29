--[[
连携技信息弹窗
--]]
local RewardResearchAndMakeView = class('RewardResearchAndMakeView',
	function ()
		local node = CLayout:create(display.size)
		node.name = 'Game.views.RewardResearchAndMakeView'
		node:enableNodeEvents()
		return node
	end
)
local MAGIC_FOOD_STYLE = 2
local UNMAGIC_FOOD_STYLE = 1   -- 不需要升级
local RECIPE_UPGRADE_COMPLETE = 3 -- 升级完成 ，这个对应的也是状态3
local TAKEAWAY_UPGRADE = 4
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local RES_DIC = {
    REWARD_LIGHT       = _res('ui/common/common_reward_light.png'),
    REWARD_DELICACY    = _res('ui/home/kitchen/kitchen_light_delicate.png'), -- 精致才的背景光束
    REWARD_IMG         = _res('ui/common/common_words_congratulations.png'),
    MAKE_BG_ATTRIBUT   = _res('ui/home/kitchen/cooking_make_bg_attribute_promotion.png'),
    DRAW_CARD_BG_NAME  = _res('ui/home/capsule/draw_card_bg_name.png'),
    DRAW_CARD_ICON_NEW = _res('ui/home/capsule/draw_card_ico_new.png'),
    BTN_ORANGE         = _res("ui/common/common_btn_orange.png"),
    ICON_DOWN          = _res('ui/home/kitchen/kitchen_ico_down.png'),
    ICON_TOP           = _res('ui/home/kitchen/kitchen_ico_top.png'),
    GRADE_A            = _res('ui/home/kitchen/cooking_grade_ico_4.png'),
    COOKING_LEVEL_UP   = _res("ui/home/kitchen/cooking_level_up_ico_arrow.png"),
    COOKING_BAR1       = _res('ui/home/kitchen/cooking_bar_1.png'),
    COOKING_BAR2       = _res('ui/home/kitchen/cooking_bar_2.png'),
    BLUE_COLOR         = _res('ui/home/kitchen/kitchen_bg_blue.png'),
    RED_COLOR          = _res('ui/home/kitchen/kitchen_bg_red.png'),
    GREEN_COLOR        = _res('ui/home/kitchen/kitchen_bg_green.png'),
    COMMON_TITLE       = _res('ui/home/kitchen/kitchen_foods_name_delicate.png'),
    DELICACY_TITLE     = _res('ui/home/kitchen/kitchen_foods_name_default.png'),
}

local createView = function (type, countRewards)
    local bgLayout = CLayout:create(display.size)
    local swallowLayer = display.newLayer(display.cx, display.cy , {ap = display.CENTER ,size = display.size ,color = cc.c4b(0,0,0,200), enable = true })
    swallowLayer:setName('SWALLOW_LAYER')
    bgLayout:addChild(swallowLayer)
    local rewardImage = display.newImageView(RES_DIC.REWARD_IMG  ,display.cx, display.height+60)
    bgLayout:addChild(rewardImage,2)
    rewardImage:setVisible(false)
    local  recipeNameBg = display.newImageView(RES_DIC.DRAW_CARD_BG_NAME)
    local recipeNameBgSize = recipeNameBg:getContentSize()
    recipeNameBg:setPosition(cc.p(recipeNameBgSize.width/2,recipeNameBgSize.height/2))
    local recipeLayout = display.newLayer(0 ,0, {size = recipeNameBgSize ,ap = display.CENTER } )
    --CLayout:create(recipeNameBgSize)
    recipeLayout:addChild(recipeNameBg)
    local newIcon = display.newImageView(RES_DIC.DRAW_CARD_ICON_NEW,0 ,recipeNameBgSize.height/2)
    recipeLayout:addChild(newIcon)
    local newIcon_two = display.newImageView(RES_DIC.DRAW_CARD_ICON_NEW,0 ,recipeNameBgSize.height/2)
    recipeLayout:addChild(newIcon_two)
    newIcon_two:setVisible(false)
    local recipeName = display.newLabel(recipeNameBgSize.width/2 -100 , recipeNameBgSize.height/2 ,{ ap =  display.LEFT_CENTER, fontSize = 26 ,text =  __('蒜蓉龙虾'),color = "ffdf89" })
    recipeLayout:addChild(recipeName)
    recipeLayout:setVisible(false)
    bgLayout:addChild(recipeLayout,2)
    local light = display.newImageView(RES_DIC.REWARD_LIGHT)
    local lightSize = light:getContentSize()
    light:setPosition(cc.p(lightSize.width/2 ,lightSize.height/2))
    local lightLayout = display.newLayer(0,0 , { size = lightSize ,ap = display.CENTER })
    --CLayout:create(lightSize)
    lightLayout:addChild(light)
    local iconpath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
    local recipeImage  = display.newImageView(iconpath ,lightSize.width/2 , lightSize.height/2+20)
    recipeImage:setScale(0.85)
    if type == TAKEAWAY_UPGRADE  then
        local recipeImageSize = recipeImage:getContentSize()
        recipeImage = CLayout:create(recipeImageSize)
        recipeImage:setPosition(cc.p(lightSize.width/2 , lightSize.height/2-40))
        local spnPath = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
        local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
        qAvatar:setPosition(cc.p(recipeImageSize.width/2,recipeImageSize.height/2))
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)
        qAvatar:setTimeScale(0)
        qAvatar:setScale(1.5)
        recipeImage:addChild(qAvatar)
    end
    lightLayout:addChild(recipeImage)
    local lightTwo = nil
    local lightLayoutTwo = nil
    local recipeOneLabel = nil
    local recipeTwoLabel = nil
    local recipeImageTwo = nil
    if type == MAGIC_FOOD_STYLE then
        lightLayout:setPosition(cc.p(display.cx ,display.cy+ 50))
    elseif type == UNMAGIC_FOOD_STYLE then
        rewards = rewards or {}
        countRewards = countRewards or 2
        recipeOneLabel = display.newImageView( RES_DIC.COMMON_TITLE,lightSize.width/2 , 70  )
        lightLayout:addChild(recipeOneLabel)

        if countRewards > 1 then
            --lightLayout:setAnchorPoint(display.CENTER)
            lightLayout:setPosition(cc.p(display.cx - 220  ,display.cy+ 150 ))

            lightTwo = display.newImageView(RES_DIC.REWARD_LIGHT)
            lightTwo:setPosition(cc.p(lightSize.width/2 ,lightSize.height/2))
            lightLayoutTwo = display.newLayer(0,0 , { ap = display.CENTER , size = lightSize})
            lightLayoutTwo:addChild(lightTwo)

            recipeImageTwo  = display.newImageView(iconpath ,lightSize.width/2 , lightSize.height/2+20)
            recipeImageTwo:setScale(0.85)
            lightLayoutTwo:addChild(recipeImageTwo)
            lightLayoutTwo:setPosition(cc.p(display.cx +  220 ,display.cy + 150))
            bgLayout:addChild(lightLayoutTwo)
            recipeTwoLabel = display.newImageView( RES_DIC.COMMON_TITLE,lightSize.width/2 , 70  )
            lightLayoutTwo:addChild(recipeTwoLabel)
            lightLayoutTwo:setVisible(false)
        else
            lightLayout:setPosition(cc.p(display.cx    ,display.cy +100))
        end
    else
        lightLayout:setPosition(cc.p(display.cx ,display.cy + 100))
    end

    bgLayout:addChild(lightLayout)
    lightLayout:setVisible(false)

    local makeSureBtn = display.newButton(display.cx,display.cy - 345 , { n = RES_DIC.BTN_ORANGE ,s =  RES_DIC.BTN_ORANGE ,enable = true} )
    display.commonLabelParams(makeSureBtn ,fontWithColor('14', { text = __('确定')}))
    bgLayout:addChild(makeSureBtn,2)
    bgLayout:setName("bgLayout")
    --makeSureBtn:setName("makeSureBtn")
    makeSureBtn:setVisible(false)
    local _x, _y = display.cx,display.cy - 345 + 160
    if type == UNMAGIC_FOOD_STYLE or type == RECIPE_UPGRADE_COMPLETE  or type == TAKEAWAY_UPGRADE then
        _x, _y = display.cx,display.cy - 345 + 60
    end
    local layout  = display.newLayer(_x,_y , {ap = display.CENTER , size = makeSureBtn:getContentSize() , color = cc.c4b(0,0,0,0) , enable = true })
    bgLayout:addChild(layout,1)
    layout:setName("makeSureBtn")

    if type == UNMAGIC_FOOD_STYLE  or type == RECIPE_UPGRADE_COMPLETE  or type == TAKEAWAY_UPGRADE then
        local makeBgAttribute = display.newImageView(RES_DIC.MAKE_BG_ATTRIBUT)
        local makeBgAttributeSize = makeBgAttribute:getContentSize()
        makeBgAttribute:setPosition(cc.p(makeBgAttributeSize.width/2,makeBgAttributeSize.height/2))
        local attributelayout = display.newLayer(display.cx, display.cy - 50, { ap = display.CENTER_TOP , size = makeBgAttributeSize })
        attributelayout:addChild(makeBgAttribute)
        makeBgAttribute:setVisible(false)
        attributelayout:setVisible(false)
        bgLayout:addChild(attributelayout)
        local attributeTables = {
            labels = { }, -- 这个表里面存放的是Label
            poss  =  {} , -- 这个是用于存放layout的位置
            effectIcons = {} ,-- 这个里面用于收集效果的icon
            layouts = {}  ,-- 存放Layout
         }
        local attributeNameTables = { __('味道：'),__('口感：'),__('香味：'),__('外观：')}
        local attributeSize = cc.size(180 ,45)
        local offset = 0
        if type == UNMAGIC_FOOD_STYLE then
            offset = -10

        elseif  type == RECIPE_UPGRADE_COMPLETE  then
            offset = - 35
        end

        for i = 1, 4 do
            local layout = display.newLayer(makeBgAttributeSize.width/2 , makeBgAttributeSize.height - (offset+attributeSize.height*(i- 0.5)) , {size = attributeSize ,ap = display.CENTER  } )
            local richLabel  = display.newLabel(0,attributeSize.height/2 ,
            fontWithColor('3',{ap = display.LEFT_CENTER ,text = attributeNameTables[i]} ) )
            attributelayout:addChild(layout,2)
            layout:addChild(richLabel)
            attributeTables.layouts[#attributeTables.layouts+1] = layout
            attributeTables.labels[#attributeTables.labels+1] = richLabel
            attributeTables.poss[i] = cc.p(150 , makeBgAttributeSize.height - (offset + attributeSize.height*(i- 0.5)))
            layout:setPosition(attributeTables.poss[i])
            attributeTables.effectIcons[i] = {}
            for j = 1 , 3 do
                local iconDown = display.newImageView(RES_DIC.ICON_TOP , 105 + 18*(j - 0.5) ,attributeSize.height/2 )
                attributeTables.effectIcons[i][j] = iconDown
                layout:addChild(iconDown)
                iconDown:setVisible(false)
            end
        end
        local expBar  = nil
        local addGradeLabel = nil
        local addGradeLabel = nil
        local gradeImage = nil
        if  type == UNMAGIC_FOOD_STYLE then
            expBar = CProgressBar:create(RES_DIC.COOKING_BAR1)
            expBar:setBackgroundImage(RES_DIC.COOKING_BAR2)
            expBar:setDirection(eProgressBarDirectionLeftToRight)
            expBar:setMaxValue(100)
            expBar:setValue(50)
            expBar:setShowValueLabel(true)
            expBar:setAnchorPoint(display.CENTER)
            expBar:getLabel():setVisible(true)
            display.commonLabelParams(expBar:getLabel(),fontWithColor('9',{ text = ''}))
            expBar:setPosition(cc.p(makeBgAttributeSize.width/2 ,40+180))
            attributelayout:addChild(expBar)
            local expBarSize  = expBar:getContentSize()
            gradeImage  = display.newImageView(RES_DIC.GRADE_A , 0 ,expBarSize.height/2,{ap = display.RIGHT_CENTER })
            addGradeLabel = display.newLabel(expBarSize.width + 10, expBarSize.height/2 , { ap = display.LEFT_CENTER , text = "---" ,fontSize = 28 ,color = "ffcc00"})
            expBar:addChild(gradeImage)
            expBar:addChild(addGradeLabel)
        else
            expBar = CLayout:create(cc.size(0,0))
            attributelayout:addChild(expBar)

        end
        return {
            bgLayout = bgLayout ,
            rewardImage = rewardImage ,
            recipeNameBg = recipeNameBg ,
            newIcon = newIcon ,
            newIcon_two = newIcon_two ,
            recipeName = recipeName ,
            light = light ,
            lightLayout = lightLayout ,
            recipeLayout = recipeLayout,
            recipeImage = recipeImage ,
            makeSureBtn = makeSureBtn ,
            makeBgAttribute = makeBgAttribute ,
            attributelayout = attributelayout  ,
            attributeTables = attributeTables ,
            attributeNameTables = attributeNameTables  ,
            addGradeLabel = addGradeLabel ,
            recipeOneLabel = recipeOneLabel ,
            recipeTwoLabel = recipeTwoLabel ,
            recipeImageTwo = recipeImageTwo ,
            gradeImage = gradeImage ,
            expBar = expBar ,
            lightTwo = lightTwo,
            lightLayoutTwo = lightLayoutTwo
        }
    else

        return {
            bgLayout = bgLayout ,
            rewardImage = rewardImage ,
            recipeNameBg = recipeNameBg ,
            newIcon = newIcon ,
            newIcon_two = newIcon_two ,
            recipeName = recipeName ,
            light = light ,
            lightLayout = lightLayout ,
            recipeLayout = recipeLayout,
            recipeImage = recipeImage ,
            makeSureBtn = makeSureBtn ,
        }
    end
end
function RewardResearchAndMakeView:ctor(param)
    param = param or  {}
    self:setName("RewardResearchAndMakeView")
    self.type = param.type or MAGIC_FOOD_STYLE   -- type 类型可以为1，2 ， 3 ，2表示的开发制作获得 ，1、表示魔法菜谱获得
    if  self.type  == UNMAGIC_FOOD_STYLE or self.type == RECIPE_UPGRADE_COMPLETE  or  self.type == TAKEAWAY_UPGRADE then
        self.datas = {}
        self.datas.rewards = {}
        self.viewData = createView(self.type)
        self:addChild(self.viewData.bgLayout)
        self.viewData.bgLayout:setPosition(display.center)
    else
        self.datas = param or {}
        self.datas.rewards = self.datas.rewards or {}
        self.viewData = createView(self.type)
        self:addChild(self.viewData.bgLayout)
        self.viewData.bgLayout:setPosition(display.center)
        self:updataView()
        self:runActionType()
    end
end
function RewardResearchAndMakeView:updateData(param,delayFuncList_)
    self.datas = param
    dump(self.datas)
    self.datas.rewards = self.datas.rewards or {}
    self.type = param.type or self.type
    if delayFuncList_ then
        self.delayFuncList_ = delayFuncList_
    end
    self:updataView()
    self:runActionType()

end
function RewardResearchAndMakeView:setTopContent()
    local recipeData = CommonUtils.GetConfigAllMess('recipe' ,'cooking')
    local goodsId = recipeData[tostring( self.datas.recipeId)].foods[1].goodsId or 190001
    local recipName = CommonUtils.GetConfig('goods' ,'goods', goodsId ).name   or  __('蒜蓉龙虾')
    local iconPath = CommonUtils.GetGoodsIconPathById(goodsId,true )
    self.viewData.recipeImage:setTexture(iconPath)
    self.viewData.recipeName:setString(recipName)
    if self.type == UNMAGIC_FOOD_STYLE then
        local titleSize =  self.viewData.recipeOneLabel:getContentSize()
        local rewards = clone(self.datas.rewards)
        for i =#rewards , 1 ,-1 do
            local data  = rewards[i]
            if checkint(data.goodsId) ~= EXP_ID  and checkint(data.goodsId) > 150000 and   checkint(data.goodsId) <160000 then
            else
                table.remove(rewards , i) -- 删除无效的东西
            end
        end
        local count = table.nums(rewards)
        if count > 1 then
            for i =1 , count do
                local data  = rewards[i]
                if checkint(data.goodsId) ~= EXP_ID  and checkint(data.goodsId) > 150000 and   checkint(data.goodsId) <160000 then
                    if data.goodsId then
                        if checkint(data.goodsId) > 151000 then
                            self.viewData.lightTwo:setTexture(RES_DIC.REWARD_DELICACY)
                            local size =  self.viewData.recipeOneLabel:getContentSize()
                            local name = CommonUtils.GetConfig('goods','goods', data.goodsId).name or ""

                            local nums = data.num
                            --local name = foodData.name  or " "
                            local richLabel = display.newRichLabel(size.width/2 , size.height /2 , { r = true ,
                                c = { {text =  name , fontSize = 24, color = "#ffffff" },
                                    fontWithColor('14' , {text = " x" ..nums , color = '#ffcc00' } )
                                } })
                            self.viewData.recipeTwoLabel:setTexture(RES_DIC.DELICACY_TITLE)
                            self.viewData.recipeTwoLabel:addChild(richLabel)
                            self.viewData.recipeImageTwo:setTexture(iconPath)
                        else
                            self.viewData.recipeImage:setTexture(iconPath)
                            local size =  self.viewData.recipeOneLabel:getContentSize()
                            local foodData = CommonUtils.GetConfig('goods','goods', data.goodsId)
                            local nums = data.num
                            local name = foodData.name  or " "
                            local richLabel = display.newRichLabel(size.width/2 , size.height /2 , { r  = true ,
                                c = { {text =  name , fontSize = 24, color = "#ffffff" } ,
                                    fontWithColor('14' , {text = " x" ..nums , color = '#ffcc00' } )
                                } })
                            self.viewData.recipeOneLabel:addChild(richLabel)
                        end
                    end
                end

            end
        else
            local lightLayout =  self.viewData.lightLayout
            local y =  lightLayout:getPositionY()
            lightLayout:setPosition(cc.p(display.cx, y))
            local data = rewards[1]
            if data then
                if data.goodsId then
                    if checkint(data.goodsId) ~= EXP_ID  and checkint(data.goodsId) > 150000 and   checkint(data.goodsId) <160000 then
                        if checkint(data.goodsId) > 151000 then
                            local size =  self.viewData.recipeOneLabel:getContentSize()
                            self.viewData.recipeOneLabel:setTexture(RES_DIC.DELICACY_TITLE)
                            local foodData = CommonUtils.GetConfig('goods','goods', data.goodsId)
                            local name = foodData.name  or " "
                            local nums = data.num
                            local richLabel = display.newRichLabel(size.width/2 , size.height /2 , { r = true ,
                                c = { {text =  name , fontSize = 24, color = "#ffffff" },
                                    fontWithColor('14' , {text =" x" ..nums , color = '#ffcc00' } )
                                } })
                            self.viewData.recipeOneLabel:addChild(richLabel)
                        else
                            self.viewData.recipeOneLabel:setTexture(RES_DIC.COMMON_TITLE)
                            local size =  self.viewData.recipeOneLabel:getContentSize()
                            local foodData = CommonUtils.GetConfig('goods','goods', data.goodsId)
                            local nums = data.num
                            local name = foodData.name  or " "
                            local richLabel = display.newRichLabel(size.width/2 , size.height /2 , { r = true ,
                             c = { {text =  name , fontSize = 24, color = "#ffffff" },
                                    fontWithColor('14' , {text = " x" ..nums , color = '#ffcc00' } )
                                } })
                            self.viewData.recipeOneLabel:addChild(richLabel)
                        end
                    end
                end

            end
        end
    end
end
--返回最宽的宽度 横向比较的最大值
function RewardResearchAndMakeView:ReturnMaxLineWidth(nodeTable)
    local node = nil
    local maxWidth = 80
    local x = 0

    local size = nil
    local endWidth  = nil
    for i =1, #nodeTable  do
        node =  nodeTable[i][#nodeTable[i]]
        if node then
            if tolua.type(node ) == "ccw.CLabel" then
                size = display.getLabelContentSize(node)
                x  = node:getPositionX()
            else
                size = node:getContentSize()
                x  = node:getPositionX()
            end
            endWidth = x +size.width
            maxWidth = endWidth > maxWidth and endWidth or maxWidth
        end
    end
    return  maxWidth

end
--- 如果元素是列的时候返回最大值
function RewardResearchAndMakeView:ReturnMaxListWidth(nodeTable)
    local node = nil
    local maxWidth = 80
    local x = 0
    local size = nil
    local endWidth  = 80
    local count =  #nodeTable
    for i=1 , #nodeTable[count] do
        node =  nodeTable[count][i]
        if node then
            if tolua.type(node ) == "ccw.CLabel" then
                size = display.getLabelContentSize(node)
                x  = node:getPositionX()
            else
                size= node:getContentSize()
                x  = node:getPositionX()
            end
            endWidth =  x +size.width
            maxWidth = endWidth > maxWidth and endWidth or maxWidth
        end
    end
    return  maxWidth
end

--刷新界面的显示
function RewardResearchAndMakeView:updataView()

    if  self.type == UNMAGIC_FOOD_STYLE then
        self:setTopContent()
        local recipeData = CommonUtils.GetConfigAllMess('recipe' ,'cooking')
        local level = table.nums(CommonUtils.GetConfigAllMess('grade','cooking'))
        local grade = (self.datas.gradeId +1 > level and level ) or self.datas.gradeId +1
        local sum = CommonUtils.GetConfigAllMess('grade','cooking')[tostring( grade)].sum
        self.viewData.expBar:setMaxValue(checkint(sum))
        self.viewData.expBar:setValue(checkint(self.datas.growthTotal))
        self.viewData.gradeImage:setTexture(_res(string.format( "ui/home/kitchen/cooking_grade_ico_%d.png",self.datas.gradeId or 0 )))
        if checkint(self.datas.growthTotal) >= checkint(sum) and checkint(self.datas.growthTotal)  ==  checkint(self.datas.lastGrowthTotal) then
            self.viewData.addGradeLabel:setVisible(true)
            self.viewData.addGradeLabel:setString("MAX")
            for i  =1 ,#self.viewData.attributeTables.layouts do
                self.viewData.attributeTables.layouts[i]:removeAllChildren()
            end
            local text = ""
            if self.datas.gradeId == level  then
                text =  __('已经到达等级上限')
            else
                text =  __('已达上限，请升级食谱')
            end
            local label  = display.newLabel(213,0,fontWithColor('3' , { text = text}))
            self.viewData.attributeTables.layouts[2]:addChild(label)
            local attributelayoutSize = self.viewData.attributelayout:getContentSize()
            local expRichLabel = display.newRichLabel(attributelayoutSize.width-20,attributelayoutSize.height, {ap = display.RIGHT_BOTTOM ,  r =true ,c = {
                {img = CommonUtils.GetGoodsIconPathById(EXP_ID) ,scale = 0.3 },
                {fontSize = 28 ,ap = display.LEFT_CENTER,hAlign = display.TAL,color = "ffeac5" ,text =  "+" .. self.datas.Exp}
            }})
            self.viewData.attributelayout:addChild(expRichLabel)
        else
            local propertyAll = 0  -- 记录增加的z
            local keysTable = {"taste", "museFeel" , "fragrance","exterior" }
            local collectNextNodeTable  = { {} , {} , {} , {}}
            local addPropertyAll  = 0
            for i =1  ,  #self.viewData.attributeNameTables do
                local layout =  self.viewData.attributeTables.layouts[i]
                local posX=  layout:getPositionX()
                local posY=  layout:getPositionY()
                layout:setPosition(cc.p(posX,posY - 20 ))
            end
            for i =1 , #self.viewData.attributeNameTables do
                local propertyValue = self.datas[keysTable[i]]
                local baseValue = checkint( self.datas[keysTable[i] .."Map"].base)
                local seasoningValue =  checkint( self.datas[keysTable[i] .."Map"].seasoning)
                local assistantValue = checkint( self.datas[keysTable[i] .."Map"].assistant)
                local addproperty = 0
                addproperty  = baseValue + seasoningValue + assistantValue
                local label = display.newLabel(0,20 , fontWithColor('3' ,{ap = display.LEFT_CENTER,text = self.datas[keysTable[i]] , color = addproperty  > 0 and "ffcc00" or "ffffff"}  ))
                self.viewData.attributeTables.layouts[i]:addChild(label)
                collectNextNodeTable[i][#collectNextNodeTable[i]+1] = label
                local attributelayoutSize = self.viewData.attributelayout:getContentSize()
                local expRichLabel = display.newRichLabel(attributelayoutSize.width-20,attributelayoutSize.height, {ap = display.RIGHT_BOTTOM ,  r =true ,c = {
                        {img = CommonUtils.GetGoodsIconPathById(EXP_ID) ,scale = 0.3 },
                        {fontSize = 28 ,ap = display.LEFT_CENTER,hAlign = display.TAL,color = "ffeac5" ,text =  "+" .. self.datas.Exp}
                }})
                self.viewData.attributelayout:addChild(expRichLabel)
                propertyAll = propertyAll + addproperty
                local layout = self.viewData.attributeTables.layouts[i]
                if addproperty == 0  then
                    label = display.newLabel(0,20 , {fontSize = 28 ,ap = display.LEFT_CENTER,hAlign = display.TAL,color = "ffeac5" ,text = ""}  )
                    layout:addChild(label)
                    collectNextNodeTable[i][#collectNextNodeTable[i]+1] = label
                    label = display.newLabel(0,20 , {fontSize = 28 ,ap = display.LEFT_CENTER,hAlign = display.TAL,color = "ffeac5" ,text = ""}  )
                    layout:addChild(label)
                    collectNextNodeTable[i][#collectNextNodeTable[i]+1] = label
                else
                    local iconPath = ""
                    if  addproperty > 0 then
                        iconPath = RES_DIC.ICON_TOP
                    elseif addproperty < 0 then
                        iconPath = RES_DIC.ICON_DOWN
                    end
                    local image  = display.newImageView( iconPath,0 ,20 ,{ap = display.LEFT_CENTER})
                    layout:addChild(image)

                    collectNextNodeTable[i][#collectNextNodeTable[i]+1] = image

                    local callback = function (imagePath,labelText,effectImage,scaleValue,isClipNode ,ap ) -- 效果的背景路径 对应的文本text ，effectImage 的效果
                        local image = display.newImageView(imagePath ,0 ,20)
                        image:setAnchorPoint(display.LEFT_CENTER)
                        local imageSize = image:getContentSize()
                        layout:addChild(image)
                        local label = display.newLabel(10 , imageSize.height/2, {fontSize = 28 ,ap = display.LEFT_CENTER ,color = "ffcc00" ,text = labelText})
                        image:addChild(label)
                        if isClipNode then
                            local clippingNode = cc.ClippingNode:create()
                            local noticeImage = display.newImageView(effectImage)
                            local  stencilNode = display.newImageView(_res('ui/home/kitchen/cooking_cook_bg_head.png'))
                            local stencilNodeSzie = stencilNode:getContentSize()
                            local scale = stencilNodeSzie.width/ noticeImage:getContentSize().width
                            noticeImage:setPosition(cc.p(stencilNodeSzie.width/2,stencilNodeSzie.height/2))
                            clippingNode:setAnchorPoint(display.RIGHT_CENTER)
                            clippingNode:setContentSize( cc.size(stencilNodeSzie.width,stencilNodeSzie.height))
                            clippingNode:addChild(noticeImage)
                            clippingNode:setPosition(cc.p(imageSize.width, imageSize.height/2))
                            image:addChild(clippingNode)
                            clippingNode:setStencil(stencilNode)
                            clippingNode:setAlphaThreshold(0.05)
                            clippingNode:setInverted(false)
                        else
                            ap = ap or display.RIGHT_CENTER
                            local effectImage = display.newImageView(effectImage,imageSize.width - 5, imageSize.height/2,{ap = ap })
                            effectImage:setScale(scaleValue)
                            image:addChild(effectImage)
                        end
                        collectNextNodeTable[i][#collectNextNodeTable[i]+1] = image
                    end
                    if baseValue > 0 then
                        local labelText =  "+" .. baseValue
                        local imagePath = RES_DIC.RED_COLOR
                        local effectImage = _res('ui/home/kitchen/cooking_ico_cooking.png')
                        local ap = cc.p(1,0.4)
                        callback(imagePath,labelText,effectImage,1,nil,ap)
                    end
                    if seasoningValue > 0 then
                        local labelText =  "+" ..  seasoningValue
                        local imagePath = RES_DIC.BLUE_COLOR
                        local effectImage = CommonUtils.GetGoodsIconPathById(self.datas.makeSureSeasoningId)
                        callback(imagePath,labelText,effectImage,0.3 )
                    end
                    if assistantValue > 0 then
                        local labelText =  "+" ..  assistantValue
                        local imagePath = RES_DIC.GREEN_COLOR
                        local effectImage = nil
                        if gameMgr:GetUserInfo().chef["2"] then
                            local cardUid  = gameMgr:GetUserInfo().chef["2"]
                            local cardData = gameMgr:GetCardDataById(cardUid)
                            local cardId = checkint(cardData.cardId)
                            local skinId = cardMgr.GetCardSkinIdByCardId(cardId)
                            effectImage  = CardUtils.GetCardHeadPathBySkinId(skinId)
                        end
                        if effectImage then
                            callback(imagePath,labelText,effectImage , isClipNode)
                        end
                    end
                end
            end
            local maxNum = 0
            for i =1 , #collectNextNodeTable do
                if maxNum< #collectNextNodeTable[i] then
                    maxNum = #collectNextNodeTable[i]
                end
            end
            local offset =  0
            local positionXTable = {}
            local labels = self.viewData.attributeTables.labels

            for i =1 ,#labels-1 do -- 计算前面label 宽度的最大值
                local nowLabelWidth = display.getLabelContentSize(labels[i]).width
                local nextLabelWidth = display.getLabelContentSize(labels[i+1]).width
                positionXTable[1] = nowLabelWidth > nextLabelWidth  and nowLabelWidth or nextLabelWidth
                positionXTable[1] = offset + positionXTable[1]
            end
            for i =1 , #collectNextNodeTable do
                for j =1 , maxNum-1 do
                    local width  = 0
                    if j == 2 then  -- 因为第二项直接写死宽度30
                        width = 30
                    else
                        if collectNextNodeTable[i][j] then
                            if j ==1 then
                                width = display.getLabelContentSize(collectNextNodeTable[i][j]).width
                            else
                                width = collectNextNodeTable[i][j]:getContentSize().width
                            end
                        end
                    end
                    if positionXTable[j+1] then
                        positionXTable[j+1] = positionXTable[j+1] > width and  positionXTable[j+1]  or width
                    else
                        positionXTable[j+1] = width
                    end
                end
            end
            for  i =1 ,#positionXTable -1 do  -- 算出每一个对应node 应该偏移的的距离
                positionXTable[i+1] = positionXTable[i] +  positionXTable[i+1]
            end
            for i =1 , #collectNextNodeTable do
                for  j =1 ,  #collectNextNodeTable[i] do
                    collectNextNodeTable[i][j]:setPosition(cc.p(positionXTable[j],20))
                end
            end
            if propertyAll == 0 then
                self.viewData.addGradeLabel:setVisible(false)
            else
                self.viewData.addGradeLabel:setVisible(true)
                self.viewData.addGradeLabel:setString("+" .. propertyAll)
            end
            local maxWidth = self:ReturnMaxLineWidth(collectNextNodeTable)
            --collectNextNodeTable
            local layout =  nil
            local contnetSize =  nil
            local parentNode =  self.viewData.attributeTables.layouts[1]:getParent()
            local parentNodeSize = parentNode:getContentSize()
            local y = 0
            for  i =1 , #self.viewData.attributeTables.layouts do
                layout = self.viewData.attributeTables.layouts[i]
                contnetSize = layout:getContentSize()
                layout:setContentSize(cc.size(maxWidth, contnetSize.height))
                y = layout:getPositionY()
                layout:setAnchorPoint(display.CENTER)
                layout:setPosition(cc.p( parentNodeSize.width/2 , y ))
            end

        end
    elseif self.type == RECIPE_UPGRADE_COMPLETE then
        self:setTopContent()
        self.viewData.rewardImage:setTexture(_res('ui/home/lobby/information/restaurant_ico_level_up'))
        self.viewData.newIcon:setTexture(_res(string.format('ui/home/kitchen/balance_ico_%d.png', self.datas.gradeId)))
        self.viewData.newIcon_two:setTexture(_res(string.format('ui/home/kitchen/balance_ico_%d.png', self.datas.gradeId)))

        for i =1 ,#self.viewData.attributeTables.layouts do
            self.viewData.attributeTables.layouts[i]:removeAllChildren()
        end
        local posY =  self.viewData.newIcon:getPositionY()
        self.viewData.newIcon:setPosition(cc.p(15,posY))
        self.viewData.newIcon_two:setPosition(cc.p(15,posY))
        local offsetPosX = -30
        local positionTable = {0,0,0,0,0}
        local recipeOneData = CommonUtils.GetConfigAllMess('recipe' ,'cooking')[tostring(self.datas.recipeId)]
        local gradeData = recipeOneData['grade'][tostring( self.datas.gradeId-1)]
        local gradeUpData = recipeOneData['grade'][tostring( self.datas.gradeId)]
        local nameTable = {
            { name = __('外卖:') , specific = __('厨力点') , specificLastValue =  checkint(gradeData.cookingPoint), specificNowValue =  checkint(gradeUpData.cookingPoint)} ,
            { name = __('厨房:') , specific = __('制作时间') , specificLastValue = string.format(__("%d秒") ,checkint(gradeData.makingTime))  , specificNowValue = string.format(__("%d秒") ,checkint(gradeUpData.makingTime))  } ,
            { name = __('厨房:') , specific = __('制作数量') , specificLastValue = string.format(__("%d个"), checkint(gradeData.makingMax))  , specificNowValue =   string.format(__("%d个"), checkint(gradeUpData.makingMax)) } ,
            { name = __('价格:') , specific = __('餐厅价格') , specificLastValue =  checkint(gradeData.gold), specificNowValue =  checkint(gradeUpData.gold)}
        }
        local collectElementTable = {{},{},{},{},{}}
        for i =1 , 5 do
            for j =1, 4 do
                local width = 0
                if i ==1 then
                    local label = display.newLabel(0,20,fontWithColor('3' ,{ ap = display.LEFT_CENTER , color = "ffeac5" , text =  nameTable[j].name}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width
                    collectElementTable[j][#collectElementTable[j]+1] = label
                elseif  i ==2 then
                    local label = display.newLabel(0,offsetPosX,fontWithColor('3' ,{ ap = display.LEFT_CENTER , color = "ffeac5" ,text =  nameTable[j].specific}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width
                    local height = display.getLabelContentSize(label).height
                    if i ==2 and j ==1 then
                        local image = display.newImageView(CommonUtils.GetGoodsIconPathById(COOK_ID),positionTable[2] +width,offsetPosX,{ap = display.LEFT_CENTER})
                        self.viewData.attributeTables.layouts[j]:addChild(image)

                        image:setScale(0.2)
                        local imageSize = image:getContentSize()
                        width =  imageSize.width*0.2 + width
                    end
                    collectElementTable[j][#collectElementTable[j]+1] = label
                    width = width + 10
                elseif i ==3 then
                    local label = display.newLabel(0,offsetPosX,fontWithColor('3' ,{ ap = display.LEFT_CENTER , text =  nameTable[j].specificLastValue}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width +10
                    collectElementTable[j][#collectElementTable[j]+1] = label
                elseif i == 4 then
                    local levelUpIcon = display.newImageView(RES_DIC.COOKING_LEVEL_UP)
                    local iconSize = levelUpIcon:getContentSize()
                    local gradeLayout = CLayout:create(cc.size(iconSize.width*3,iconSize.height))
                    local gradeSize = gradeLayout:getContentSize()
                    gradeLayout:setAnchorPoint(display.LEFT_CENTER)
                    gradeLayout:setPosition(cc.p(0,offsetPosX))
                    self.viewData.attributeTables.layouts[j]:addChild(gradeLayout)
                    local interval = 0.5
                    for i = 1 ,3 do
                        local icon_Up = display.newImageView(RES_DIC.COOKING_LEVEL_UP,(i - 0.5)*(iconSize.width -5) ,gradeSize.height/2)
                        gradeLayout:addChild(icon_Up)
                        icon_Up:setOpacity(0)
                        icon_Up:runAction(cc.Sequence:create(
                            cc.DelayTime:create(interval*i ) , cc.CallFunc:create(
                                function ()
                                    icon_Up:stopAllActions()
                                    icon_Up:runAction(cc.RepeatForever:create(
                                        cc.Sequence:create(cc.FadeIn:create(1.5),cc.FadeOut:create(1.5))
                                        )
                                    )
                                end
                            )
                        ) )
                    end
                    width = gradeSize.width
                    collectElementTable[j][#collectElementTable[j]+1] = gradeLayout
                elseif i ==5  then
                    local label = display.newLabel(0,offsetPosX,fontWithColor('3' ,{ ap = display.LEFT_CENTER ,color = "ffcc00",  text =  nameTable[j].specificNowValue}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width
                    collectElementTable[j][#collectElementTable[j]+1] = label
                end
                if i < 5 then
                    positionTable[i+1]= positionTable[i+1] > width and positionTable[i+1] or width
                end
            end
            if positionTable[i-1] then
                positionTable[i] = positionTable[i] + positionTable[i-1]
            end
        end
        for i =1 ,#collectElementTable do
            for j =1 , #collectElementTable[i] do
                collectElementTable[i][j]:setPosition(cc.p(positionTable[j],offsetPosX))
            end
        end
        local maxWidth = self:ReturnMaxLineWidth(collectElementTable)
        --collectNextNodeTable
        local layout =  nil
        local contnetSize =  nil
        local parentNode =  self.viewData.attributeTables.layouts[1]:getParent()
        local parentNodeSize = parentNode:getContentSize()
        local y = 0
        for  i =1 , #self.viewData.attributeTables.layouts do
            layout = self.viewData.attributeTables.layouts[i]
            contnetSize = layout:getContentSize()
            layout:setContentSize(cc.size(maxWidth, contnetSize.height))
            y = layout:getPositionY()
            layout:setAnchorPoint(display.CENTER)
            layout:setPosition(cc.p( parentNodeSize.width/2 , y ))
        end

    elseif self.type == TAKEAWAY_UPGRADE then
        local viewData =  self.viewData
        viewData.recipeLayout:setVisible(false)
        viewData.rewardImage:setTexture(_res('ui/home/lobby/information/restaurant_ico_level_up'))
        local layouts =  viewData.attributeTables.layouts
        local offsetPosY  =-30
        for i =1 ,4 do
            layouts[i]:removeAllChildren()
        end
        local positionTable = {40,0,0,0}
        local gradeData  = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
        local nameTable = {
            { name = __('等级:') , specificLastValue = string.format(__('%d级') ,self.datas.level - 1 ) , specificNowValue =  string.format(__('%d级') ,self.datas.level)} ,
            { name = __('配送时间减少:') , specificLastValue = string.format(__('%s秒'),gradeData[tostring(self.datas.level - 1)].speed * 2)   , specificNowValue = string.format(__('%s秒') , gradeData[tostring(self.datas.level)].speed * 2)  } ,
            --{ name = __('经验:') , specificLastValue =  gradeData[tostring(self.datas.level - 1)].mainExp , specificNowValue =   gradeData[tostring(self.datas.level )].mainExp}
        }
        local attributelayoutSize = self.viewData.attributelayout:getContentSize()
        local expRichLabel = display.newRichLabel(attributelayoutSize.width-20,attributelayoutSize.height, {ap = display.RIGHT_BOTTOM ,  r =true ,c = {
            {img = CommonUtils.GetGoodsIconPathById(EXP_ID) ,scale = 0.3 },
            {fontSize = 28 ,ap = display.LEFT_CENTER,hAlign = display.TAL,color = "ffeac5" ,text =  "+" .. gradeData[tostring(self.datas.level )].mainExp}
        }})
        self.viewData.attributelayout:addChild(expRichLabel)
        local collectElementTable = {{},{},{},{}}
        for i =1 , 4 do
            for j =1, 2 do
                local width = 0
                if i ==1 then
                    local label = display.newLabel(0,20,fontWithColor('3' ,{ ap = display.LEFT_CENTER , text =  nameTable[j].name}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width
                    collectElementTable[j][#collectElementTable[j]+1] = label
                elseif i ==2 then
                    local label = display.newLabel(0,offsetPosY,fontWithColor('3' ,{ ap = display.LEFT_CENTER , text =  nameTable[j].specificLastValue}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width +10
                    collectElementTable[j][#collectElementTable[j]+1] = label
                elseif i == 3 then
                    local levelUpIcon = display.newImageView(RES_DIC.COOKING_LEVEL_UP)
                    local iconSize = levelUpIcon:getContentSize()
                    local gradeLayout = CLayout:create(cc.size(iconSize.width*3,iconSize.height))
                    local gradeSize = gradeLayout:getContentSize()
                    gradeLayout:setAnchorPoint(display.LEFT_CENTER)
                    gradeLayout:setPosition(cc.p(0,offsetPosY))
                    self.viewData.attributeTables.layouts[j]:addChild(gradeLayout)
                    local interval = 0.5
                    for i = 1 ,3 do
                        local icon_Up = display.newImageView(RES_DIC.COOKING_LEVEL_UP,(i - 0.5)*(iconSize.width -5) ,gradeSize.height/2)
                        gradeLayout:addChild(icon_Up)
                        icon_Up:setOpacity(0)
                        icon_Up:runAction(cc.Sequence:create(
                            cc.DelayTime:create(interval*i ) , cc.CallFunc:create(
                                function ()
                                    icon_Up:stopAllActions()
                                    icon_Up:runAction(cc.RepeatForever:create(
                                        cc.Sequence:create(cc.FadeIn:create(1.5),cc.FadeOut:create(1.5))
                                        )
                                    )
                                end
                            )
                        ) )
                    end
                    width = gradeSize.width
                    collectElementTable[j][#collectElementTable[j]+1] = gradeLayout
                elseif i == 4  then
                    local label = display.newLabel(0,offsetPosY,fontWithColor('3' ,{ ap = display.LEFT_CENTER ,color = "ffcc00",  text =  nameTable[j].specificNowValue}))
                    self.viewData.attributeTables.layouts[j]:addChild(label)
                    width = display.getLabelContentSize(label).width
                    collectElementTable[j][#collectElementTable[j]+1] = label
                end
                if i < 4 then
                    positionTable[i+1]= positionTable[i+1] > width and positionTable[i+1] or width
                end
            end
            if positionTable[i-1] then
                positionTable[i] = positionTable[i] + positionTable[i-1]
            end
        end
        for i =1 ,#collectElementTable do
            for j =1 , #collectElementTable[i] do
                collectElementTable[i][j]:setPosition(cc.p(positionTable[j],offsetPosY))
            end
        end
        local maxWidth = self:ReturnMaxLineWidth(collectElementTable)
        local layout =  nil
        local contnetSize =  nil
        local parentNode =  self.viewData.attributeTables.layouts[1]:getParent()
        local parentNodeSize = parentNode:getContentSize()
        local y = 0
        for  i =1 , #self.viewData.attributeTables.layouts do
            layout = self.viewData.attributeTables.layouts[i]
            contnetSize = layout:getContentSize()
            layout:setContentSize(cc.size(maxWidth, contnetSize.height))
            y = layout:getPositionY()
            layout:setAnchorPoint(display.CENTER)
            layout:setPosition(cc.p( parentNodeSize.width/2 , y ))
        end
    else
        self:setTopContent()
    end
end
function RewardResearchAndMakeView:GetUseEffectGoods()
    local count = 0
    for i = #self.datas.rewards , 1, -1 do
        local data = self.datas.rewards[i]
        dump( data)
        if checkint(data.goodsId) ~= EXP_ID  and checkint(data.goodsId) > 150000 and   checkint(data.goodsId) <160000 then
            count = count +1
        end
    end

    return count
end
-- 动作的进行 根据type 的不同显示不同的界面
function RewardResearchAndMakeView:runActionType()

    if self.type == UNMAGIC_FOOD_STYLE or self.type == RECIPE_UPGRADE_COMPLETE  or self.type == TAKEAWAY_UPGRADE then
        self.viewData.newIcon:setVisible(false)
        local recipeImageAction = cc.Sequence:create(
            cc.CallFunc:create(function ()
                self.viewData.lightLayout:setVisible(true)
                self.viewData.recipeImage:setScale(0.14)
                self.viewData.recipeImage:setVisible(true)
            end ) ,
            cc.ScaleTo:create(0.2 , 1.12) , cc.ScaleTo:create(0.1,0.7 * 0.85)
            )
        self.viewData.recipeImage:runAction(recipeImageAction) --菜谱UI动画展示

        local ligthAction = cc.Sequence:create(    -- 光的动画展示
        cc.DelayTime:create(0.1) ,
        cc.CallFunc:create( function ()
            self.viewData.light:setVisible(true)
            self.viewData.light:setScale(0.519)
            self.viewData.light:setRotation(-0.8)
        end) ,
        cc.Spawn:create(cc.ScaleTo:create(0.1, 0.96) ,cc.RotateTo:create(0.1, 10)) ,
        cc.Spawn:create(cc.ScaleTo:create(1.8, 1) ,cc.RotateTo:create(1.8, 78)) ,
        cc.RotateTo:create(4.9 *1000, 180*1000)
        )
        self.viewData.light:runAction(ligthAction)

        if self:GetUseEffectGoods()> 1 and self.type ==  UNMAGIC_FOOD_STYLE  then
            local recipeImageAction = cc.Sequence:create(
            cc.CallFunc:create(function ()
                self.viewData.lightLayoutTwo:setVisible(true)
                self.viewData.recipeImageTwo:setScale(0.14)
                self.viewData.recipeImageTwo:setVisible(true)
            end ) ,
            cc.ScaleTo:create(0.2 , 1.12) , cc.ScaleTo:create(0.1,0.7*0.85)
            )
            self.viewData.recipeImageTwo:runAction(recipeImageAction) --菜谱UI动画展示

            local ligthAction = cc.Sequence:create(    -- 光的动画展示
            cc.DelayTime:create(0.1) ,
            cc.CallFunc:create( function ()
                self.viewData.lightTwo:setVisible(true)
                self.viewData.lightTwo:setScale(0.519)
                self.viewData.lightTwo:setRotation(-0.8)
            end) ,
            cc.Spawn:create(cc.ScaleTo:create(0.1, 0.96) ,cc.RotateTo:create(0.1, 10)) ,
            cc.Spawn:create(cc.ScaleTo:create(1.8, 1) ,cc.RotateTo:create(1.8, 78)) ,
            cc.RotateTo:create(4.9 *1000, 180*1000)
            )
            self.viewData.lightTwo:runAction(ligthAction)
        end

        local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6)
        local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5)
        local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24)
        local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15)
        local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15)
        local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
            cc.DelayTime:create(0.2) ,cc.CallFunc:create(function ( )
                self.viewData.rewardImage:setVisible(true)
                self.viewData.rewardImage:setOpacity(0)
                self.viewData.rewardImage:setPosition(rewardPoint_Srtart)
            end),
             cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
             cc.MoveTo:create(0.1,rewardPoint_Two) ,
             cc.MoveTo:create(0.1,rewardPoint_Three) ,
             cc.MoveTo:create(0.1,rewardPoint_Four)
             )
        self.viewData.rewardImage:runAction(rewardSequnece)
        if self.type ~= TAKEAWAY_UPGRADE and self.type ~=UNMAGIC_FOOD_STYLE  then
            local recipeLayoutAction = cc.Sequence:create(
                cc.DelayTime:create(0.4),
                cc.CallFunc:create( function ()

                    self.viewData.recipeLayout:setVisible(true)
                    self.viewData.recipeLayout:setOpacity(0)
                    self.viewData.recipeLayout:setPosition(cc.p(display.cx - 240 - 201.05 , display.cy +211))
                    self.viewData.recipeName:setCascadeOpacityEnabled(true)
                end),
                cc.Spawn:create(
                    cc.MoveTo:create(5/30,cc.p(display.cx - 240 , display.cy +211)),
                    cc.FadeIn:create(5/30)
                ) ,
                cc.CallFunc:create(
                    function ()
                        if self.type == RECIPE_UPGRADE_COMPLETE then
                            self.viewData.newIcon:runAction(
                                cc.Sequence:create(
                                    cc.CallFunc:create(function ()
                                    self.viewData.newIcon:setScale(2)
                                    self.viewData.newIcon:setOpacity(0)
                                    self.viewData.newIcon:setVisible(true)
                                    end),
                                    cc.Spawn:create(
                                        cc.FadeIn:create(5/30),
                                        cc.ScaleTo:create(5/30,1.2)
                                    ),
                                    cc.CallFunc:create(
                                        function ()
                                            self.viewData.newIcon_two:setOpacity(255)
                                            self.viewData.newIcon_two:setVisible(true)
                                            self.viewData.newIcon_two:setScale(1.2)
                                        end
                                    ) ,
                                    cc.TargetedAction:create(self.viewData.newIcon_two ,
                                        cc.Spawn:create(
                                            cc.FadeOut:create(0.1),
                                            cc.ScaleTo:create(0.1 ,2.5)
                                        )
                                    )

                                )
                            )
                        end
                    end
                )

            )
            self.viewData.recipeLayout:runAction(recipeLayoutAction)
        end
        local attributeSpawnTable = {}
        local attributeDelayTimes = { }
        for i =1 , 5 do  --计算队列的时间
            attributeDelayTimes[i] = {}
            attributeDelayTimes[i].oneTimes =(0 +2 * (i-1)) /30  --起始等待时间
            attributeDelayTimes[i].twotimes = 8 - (i-1) *2/30   -- 结束等待时间
        end
        local attributeTables = self.viewData.attributeTables

        for i =1 , 5  do
            local node = nil
            if i ~= 1 then
                node = attributeTables.layouts[i-1]
            else
                node = self.viewData.expBar
            end
            local targetAction = cc.TargetedAction:create(node ,
                cc.Sequence:create(cc.CallFunc:create(function ()
                        node:setOpacity(0)
                        local pos = cc.p(node:getPositionX(),node:getPositionY())
                        node:setPosition(cc.p(pos.x, pos.y - 56.5))
                    end ) ,
                    cc.Sequence:create(
                        cc.DelayTime:create(attributeDelayTimes[i].oneTimes ) ,
                        cc.Spawn:create(
                           cc.EaseSineOut:create( cc.MoveBy:create(8/30, cc.p(0,56.5))),  cc.FadeIn:create( 8/30)  )
                        )
                        , cc.DelayTime:create(attributeDelayTimes[i].twotimes
                    )
                )
            )
            attributeSpawnTable[#attributeSpawnTable+1] = targetAction
        end
        local targetAction = cc.TargetedAction:create(self.viewData.makeBgAttribute ,
            cc.Sequence:create(
                cc.DelayTime:create(3/30) ,
                cc.CallFunc:create(function ()
                    self.viewData.makeBgAttribute:setVisible(true)
                    self.viewData.makeBgAttribute:setOpacity(0)

                end),

                cc.Sequence:create(
                    cc.FadeIn:create(10/30) ,cc.DelayTime:create((5+22)/30)
                )
            )
        )
        attributeSpawnTable[#attributeSpawnTable+1]  = targetAction
        local spawnAction = cc.Spawn:create(attributeSpawnTable)
        self.viewData.attributelayout:runAction(cc.Sequence:create(
                cc.DelayTime:create(25/30) ,
                cc.CallFunc:create(
                function ()
                    self.viewData.attributelayout:setVisible(true)
                end
                ) ,
                spawnAction
            )
        )
        local bgLayoutView = self.viewData.bgLayout
        local btnAction = cc.Sequence:create(
            cc.DelayTime:create(25/30),
            cc.CallFunc:create(function ()
                self.viewData.makeSureBtn:setVisible(true)
                self.viewData.makeSureBtn:setOpacity(0)
            end),
            cc.Spawn:create(cc.MoveBy:create(7/30, cc.p(0 ,60)) ,cc.FadeIn:create(7/30) ) ,
            cc.CallFunc:create(function (  )
                self:stopAllActions()
                if self.delayFuncList_  then
                    if table.nums(self.delayFuncList_ ) > 0 then
                        self.delayFuncList_[1]()
                        self.delayFuncList_ = nil
                    end
                end
            end)
            )
        self.viewData.makeSureBtn:setOnClickScriptHandler(function (sender)
            local swallView = bgLayoutView:getChildByName("SWALLOW_LAYER")
            if swallView then swallView:setTouchEnabled(false) end
            GuideUtils.DispatchStepEvent()
            self:runAction(cc.RemoveSelf:create())
        end)
        self.viewData.makeSureBtn:runAction(btnAction)
    else
        local recipeImageAction = cc.Sequence:create(
            cc.CallFunc:create(function ()
                self.viewData.lightLayout:setVisible(true)
                self.viewData.recipeImage:setScale(0.14)
                self.viewData.recipeImage:setVisible(true)
                -- self.viewData.lightLayout:setPosition(cc.p(display.cx, display.cy ))
            end ) ,
            cc.ScaleTo:create(0.2 , 1.4) , cc.ScaleTo:create(0.1,1)
            )
        self.viewData.recipeImage:runAction(recipeImageAction) --菜谱UI动画展示
        local ligthAction = cc.Sequence:create(    -- 光的动画展示
            cc.DelayTime:create(0.1) ,
            cc.CallFunc:create( function ()
                self.viewData.light:setVisible(true)
                self.viewData.light:setScale(0.519)
                self.viewData.light:setRotation(-0.8)
            end) ,
            cc.Spawn:create(cc.ScaleTo:create(0.1, 1.2) ,cc.RotateTo:create(0.1, 10)) ,
            cc.Spawn:create(cc.ScaleTo:create(1.8, 1.4) ,cc.RotateTo:create(1.8, 78)) ,
            cc.RotateTo:create(4.9 *1000, 180*1000)
            )
        self.viewData.light:runAction(ligthAction)
        local heightoff = 300
        local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6)
        local rewardPoint_one = cc.p(display.cx ,  display.cy+heightoff-35.5)
        local rewardPoint_Two = cc.p(display.cx ,  display.cy+heightoff+24)
        local rewardPoint_Three = cc.p(display.cx ,  display.cy+heightoff-15)
        local rewardPoint_Four = cc.p(display.cx ,  display.cy+heightoff-15)



        local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
            cc.DelayTime:create(0.2) ,cc.CallFunc:create(function ( )
                self.viewData.rewardImage:setVisible(true)
                self.viewData.rewardImage:setOpacity(0)
                self.viewData.rewardImage:setPosition(rewardPoint_Srtart)
            end),
             cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
             cc.MoveTo:create(0.1,rewardPoint_Two) ,
             cc.MoveTo:create(0.1,rewardPoint_Three) ,
             cc.MoveTo:create(0.1,rewardPoint_Four)
             )
        self.viewData.rewardImage:runAction(rewardSequnece)
        local recipeLayoutoff = 170
        local recipeLayoutAction = cc.Sequence:create(
            cc.DelayTime:create(0.4),
            cc.CallFunc:create( function ()
                self.viewData.recipeLayout:setVisible(true)
                self.viewData.recipeLayout:setOpacity(0)
                self.viewData.recipeLayout:setPosition(cc.p(display.cx - 240 - 201.05 , display.cy +recipeLayoutoff))
                self.viewData.recipeName:setCascadeOpacityEnabled(true)
            end),
            cc.Spawn:create(
                cc.MoveTo:create(5/30,cc.p(display.cx - 240 , display.cy +recipeLayoutoff)),
                cc.FadeIn:create(5/30)
            ) ,
            cc.CallFunc:create(function ( )
                self.viewData.newIcon:setScale(2)
                self.viewData.newIcon:setOpacity(0)
                self.viewData.newIcon:setVisible(true)
            end),
            cc.TargetedAction:create( self.viewData.newIcon,
                cc.Spawn:create(
                    cc.FadeIn:create(5/30),
                    cc.ScaleTo:create(5/30,1)
                )
            ) ,
            cc.CallFunc:create(
                function ()
                    self.viewData.newIcon_two:setOpacity(255)
                    self.viewData.newIcon_two:setVisible(true)
                end
            ) ,

            cc.TargetedAction:create(self.viewData.newIcon_two ,
                cc.Spawn:create(
                    cc.FadeOut:create(0.1),
                    cc.ScaleTo:create(0.1 ,2)
                )
            )
        )
        self.viewData.recipeLayout:runAction(recipeLayoutAction)
        local bgLayoutView = self.viewData.bgLayout
        local btnAction = cc.Sequence:create(
            cc.DelayTime:create(25/30),
            cc.CallFunc:create(function ()
                self.viewData.makeSureBtn:setVisible(true)
                self.viewData.makeSureBtn:setOpacity(0)
            end),
            cc.Spawn:create(cc.MoveBy:create(7/30, cc.p(0 ,160)) ,cc.FadeIn:create(7/30) ) ,
            cc.CallFunc:create(function (  )
                    self:stopAllActions()
            end)
            )
        self.viewData.makeSureBtn:setOnClickScriptHandler(function (sender)
            local swallView = bgLayoutView:getChildByName("SWALLOW_LAYER")
            if swallView then swallView:setTouchEnabled(false) end
            GuideUtils.DispatchStepEvent()
            self:runAction(cc.RemoveSelf:create())
        end)

        self.viewData.makeSureBtn:runAction(btnAction)
    end
end

return RewardResearchAndMakeView
