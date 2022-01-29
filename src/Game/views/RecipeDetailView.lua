---@class RecipeDetailView
local RecipeDetailView = class('RecipeDetailView',
   function ()
       local node = CLayout:create(display.size)
       node.name = 'Game.views.RecipeDetailView'
       node:enableNodeEvents()
       return node
   end
)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local RES_DICT = {

    BGImage      = _res('ui/home/kitchen/cooking_bg_make.png'),
    COOKING_BAR1 = _res('ui/home/kitchen/cooking_prop_bar_1.png'),
    COOKING_BAR2 = _res('ui/home/kitchen/cooking_prop_bar_2.png'),
    GRADE_BAR_1  = _res('ui/home/kitchen/cooking_bar_1.png'),
    GRADE_BAR_2  = _res('ui/home/kitchen/cooking_bar_2.png'),
    READY_LEVEL_UP  = _res("ui/home/kitchen/cooking_bg_level_up.png"),
    CIRCLE       = _res("ui/home/kitchen/kitchen_bg_food_quan.png"),
    BG_FONT_NAME = _res("ui/common/common_title_5.png"),
    MAKE_BTN     = _res("ui/home/kitchen/kitchen_make_btn_orange.png"),
    MAKE_TIMES_BTN = _res("ui/home/kitchen/kitchen_make_btn_red.png"),
    GRADE_A      = _res('ui/home/kitchen/cooking_grade_ico_a.png'),
    ADD_SEASING  = _res('ui/home/kitchen/kitchen_btn_add_seasoning.png'),
    ICON_DOWN    = _res('ui/home/kitchen/kitchen_ico_down.png'),
    ICON_TOP     = _res('ui/home/kitchen/kitchen_ico_top.png'),
    ICON_ADD     = _res('ui/home/kitchen/kitchen_ico_add.png'),
    LINE_NAME    = _res('ui/home/kitchen/cooking_line_name.png'),
    SEASONING_ICON    = _res('ui/home/kitchen/kitchen_ico_add_seasoning.png'),
    COOKING_ICON = _res('ui/home/kitchen/cooking_ico_cooking.png'),
    QUESTION_MARK = _res("ui/airship/common_btn_tips.png"),
}
local BTNCOLLECT_TAG = {
    ADDTIP_TEST = 1  ,
    ADDTIP_MUSEFEEL = 2 ,
    ADDTIP_FRAGRABCE = 3,
    ADDTIP_EXTERIOR = 4 ,
    ADDTIP_TOTAL   =  5 ,
    MAKE_BTN = 1001 ,
    MAKE_BTN_TIMES = 1004 ,
    ADDSEASONING_BTN = 1002,
    READY_LEVEL_UP = 1003,
    LOBBY_FESTIVAL_TIP = 2000,
}
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function RecipeDetailView:ctor(param)
    param = param or {}
    self.type = param.type or 1  --  type 为1 的时候独自弹出，2 为和烹饪弹出
    self.recipeData = CommonUtils.GetConfigAllMess('recipe','cooking')  --
    self.gradeData =CommonUtils.GetConfigAllMess('grade','cooking')
    self.magicFoodData = CommonUtils.GetConfigAllMess('magicFood','goods') -- 获取魔法菜品的数据

    self.currentData = nil
    self.foodMaterialEnough =true
    self:initUi()
end

function RecipeDetailView:initUi()
    local bgImage = display.newImageView(RES_DICT.BGImage)
    local bgSize = bgImage:getContentSize()
    bgImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    local bgLayout = CLayout:create(bgSize)
    bgLayout:addChild(bgImage)
    local maskingImage = display.newImageView(_res('ui/home/kitchen/cooking_bg_make_food.png') ,bgSize.width /2 , bgSize.height , { ap = display.CENTER_TOP} )
    bgLayout:addChild(maskingImage)
    -- 隔壁点击事件的吞噬层
    local swallowView = display.newLayer(bgSize.width/2,bgSize.height/2 ,{ap = display.CENTER ,enable= true ,color =  cc.c4b(0,0,0,0) , size = bgSize})
    bgLayout:addChild(swallowView)
    --- 加上直线
    local lineImage = display.newImageView(RES_DICT.LINE_NAME,bgSize.width/2 ,bgSize.height - 66)
    bgLayout:addChild(lineImage)

    local middleX = 140
    -- 菜品名称按钮
    local recipeName = display.newLabel(middleX,bgSize.height - 66,{color = "#7c4b35" ,font = TTF_GAME_FONT ,ttf = true ,fontSize = 26  ,text = " hjgds " ,ap = display.CENTER_BOTTOM ,  reqW =200  } )
    bgLayout:addChild(recipeName)


    local circleImage = display.newImageView(RES_DICT.CIRCLE ,middleX,420,{ap = display.CENTER_BOTTOM})
    circleImage:setName("levelBtn")
    local iconPath = CommonUtils.GetGoodsIconPathById("190001")
    local circleSize= circleImage:getContentSize()
    bgLayout:addChild(circleImage)
    local iconImage = display.newImageView(iconPath,circleSize.width/2 ,circleSize.height/2 -10)
    circleImage:addChild(iconImage)
    -- 升级按钮
    local levelBtn   = display.newButton(middleX,470 + 20,{n = RES_DICT.READY_LEVEL_UP,enable = true})
    -- display.commonLabelParams(levelBtn,fontWithColor('14',{text = __('点击升级')}))
    bgLayout:addChild(levelBtn)
    levelBtn:setVisible(false)
    levelBtn:setTag(BTNCOLLECT_TAG.READY_LEVEL_UP)
    local prograssHigh = 353
    -- 菜谱升级进度按钮

    local expBar = CProgressBar:create(RES_DICT.GRADE_BAR_1)
    local expBarSize = expBar:getContentSize()
    expBar:setBackgroundImage(RES_DICT.GRADE_BAR_2)
    expBar:setDirection(eProgressBarDirectionLeftToRight)
    expBar:setMaxValue(100)
    expBar:setValue(50)
    expBar:setShowValueLabel(true)
    expBar:setPosition(cc.p(211/2+13,59/2))
    expBar:setAnchorPoint(display.CENTER)

    local layer = display.newLayer(middleX,prograssHigh,{ap = display.CENTER , size  = cc.size(220,59) , enable = true , color = cc.c4b(0,0,0,0) })
    -- expBar:getLabel():setVisible(true)
    layer:setTag(BTNCOLLECT_TAG.ADDTIP_TOTAL)
    layer:addChild(expBar,3)
    bgLayout:addChild(layer)
    display.commonLabelParams(expBar:getLabel(),fontWithColor('9',{ text = ''}))
    --- 成绩图标
    local gradeImage  = display.newImageView(RES_DICT.GRADE_A,0,expBarSize.height/2,{ap = display.RIGHT_CENTER})
    expBar:addChild(gradeImage)
    expBar:setTag(BTNCOLLECT_TAG.ADDTIP_EXTERIOR)
    -- 菜谱图片
    local goldIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID),410,bgSize.height - 305 ,{ap = display.LEFT_CENTER} )
    bgLayout:addChild(goldIcon)
    goldIcon:setScale(0.18)
    -- 菜品的价值
    local valueLabel  = display.newRichLabel( 290,bgSize.height - 305   , { ap = display.LEFT_CENTER,c = {
        fontWithColor('16',{text = ""}) ,
        fontWithColor('10',{text = ""})
    }})
    bgLayout:addChild(valueLabel)
    valueLabel:setName("valueLabel")
    -- 菜品拥有的数量
    local ownerLabel  = display.newRichLabel(145,bgSize.height - 285  , { ap = display.CENTER_BOTTOM,c = {
        fontWithColor('16',{text = ""}) ,
        fontWithColor('16',{text = ""})
    }})
    bgLayout:addChild(ownerLabel)

    local labelTables ={
        { name =  __('味道') , tag = BTNCOLLECT_TAG.ADDTIP_TEST  },
        { name =  __('口感') , tag = BTNCOLLECT_TAG.ADDTIP_MUSEFEEL  },
        { name =  __('香味') , tag = BTNCOLLECT_TAG.ADDTIP_FRAGRABCE  },
        { name =  __('外观') , tag = BTNCOLLECT_TAG.ADDTIP_EXTERIOR  },
    }
    local cellSize = cc.size(280,50)
    local recipePropertySize = cc.size(cellSize.width,cellSize.height * 4)
    -- 属性的Layout
    local recipePropertyLayout = display.newLayer(269,390 ,{ size = recipePropertySize})
    recipePropertyLayout:setAnchorPoint(display.LEFT_BOTTOM)
    recipePropertyLayout:setPosition(cc.p(269,376))
    bgLayout:addChild(recipePropertyLayout)
    local expBarBtns = {}
    local tag =1000

    local downImage  = display.newImageView(RES_DICT.ICON_DOWN)
    local downSize = downImage:getContentSize()
    local offsetRight =  65
    local seasoningIconTable = {}
    for  i =1 ,4 do
        local cellLayout = display.newLayer(40,0,{ap = display.CENTER ,size = cellSize ,enable =true ,color = cc.c4b(0,0,0,0) })
        -- CLayout:create(cellSize)
        local label = display.newLabel(15,cellSize.height/2 ,fontWithColor('16',{ fontSize =22 , color = "#7c4b35"  , text = labelTables[i].name,ap = display.LEFT_CENTER}))
        cellLayout:addChild(label,2)

        local expBar = CProgressBar:create(RES_DICT.COOKING_BAR1)
        expBar:setBackgroundImage(RES_DICT.COOKING_BAR2)
        expBar:setDirection(eProgressBarDirectionLeftToRight)
        expBar:setMaxValue(100)
        expBar:setValue(0)
        expBar:setShowValueLabel(true)
        expBar:setPosition(cc.p(0,cellSize.height/2))
        expBar:setAnchorPoint(display.LEFT_CENTER)
        cellLayout:addChild(expBar)
        cellLayout:setTag(labelTables[i].tag)
        local expBarSize = expBar:getContentSize()
        table.insert( expBarBtns,#expBarBtns+1, expBar)
        display.commonLabelParams(expBar:getLabel(),fontWithColor('9', {color = "#7c4b35" , text = ""}))
        display.commonUIParams(expBar:getLabel(), {   ap = display.RIGHT_CENTER , po = cc.p(expBarSize.width -10,expBarSize.height/2 )})
        local maxLabel = display.newLabel(expBarSize.width -10,expBarSize.height/2 , {ap = display.RIGHT_CENTER , text= "" })
        expBar:addChild(maxLabel,10)
        maxLabel:setName("maxLabel")
        maxLabel:setVisible(false)
        seasoningIconTable[#seasoningIconTable+1] = {}
        for j =1 ,6 do
            local downImage =  display.newImageView(RES_DICT.ICON_DOWN,offsetRight+downSize.width*(j - 0.5),cellSize.height/2)
            cellLayout:addChild(downImage,10)
            downImage:setTag(j)
            downImage:setVisible(false)
            seasoningIconTable[i][j] = downImage
        end
        recipePropertyLayout:addChild(cellLayout)
        cellLayout:setPosition(cc.p(cellSize.width/2 + 25,(4.5 - i) *cellSize.height))
    end
    local titleBtn = display.newButton(bgSize.width/2,294,{n = RES_DICT.BG_FONT_NAME ,enable = false, scale9 = true, size = cc.size(186,32)})
    display.commonLabelParams(titleBtn,fontWithColor('16',{ text = __('食材与佐料') ,paddingW = 30  }))
    local lwidth = display.getLabelContentSize(titleBtn:getLabel()).width
    bgLayout:addChild(titleBtn)
    -- 调料按钮
    local seasoningImage  = display.newImageView(RES_DICT.ADD_SEASING ,0, 0 ,{enable = true,ap = display.CENTER_BOTTOM })
    local seasoningImageSize = seasoningImage:getContentSize()
    local addImage = display.newImageView(RES_DICT.ICON_ADD)
    local addSize = addImage:getContentSize()
    local seasoningSize = cc.size(seasoningImageSize.width + addSize.width,seasoningImageSize.height)
    seasoningImage:setTag(BTNCOLLECT_TAG.ADDSEASONING_BTN)
    local seasoningLayout = CLayout:create(seasoningSize)
    addImage:setPosition(cc.p(addSize.width/2 , seasoningSize.height/2))
    seasoningImage:setPosition(cc.p(addSize.width + seasoningSize.width/2,0))
    local tipLabel = display.newLabel(seasoningImageSize.width+5,-10,fontWithColor('16',{text = __('添加佐料'),fontSize = 20 ,ap = display.CENTER_TOP}) )
    -- seasoningImage:addChild(tipLabel)
    seasoningLayout:addChild(addImage)
    seasoningLayout:addChild(seasoningImage)
    seasoningLayout:addChild(tipLabel)
    local magicContentSize = cc.size(250,150)
    local magicContentLayout =  CLayout:create(magicContentSize)
    local magicContentImage = display.newImageView(_res('ui/home/kitchen/kitchen_bg_food_mastery_words.png'),magicContentSize.width/2 ,magicContentSize.height/2,{ap = display.CENTER })
    local magicContentImageSize = magicContentImage:getContentSize()

    magicContentImage:setScale(magicContentSize.width/magicContentImageSize.width ,magicContentSize.height/magicContentImageSize.height )

    local listSize = cc.size(250,140)
    local magicListView = CListView:create(listSize)
    magicListView:setDirection(eScrollViewDirectionVertical)
    magicListView:setAnchorPoint(cc.p(0.5, 0.5))
    magicListView:setPosition(cc.p(magicContentSize.width/2, magicContentSize.height/2))
    magicContentLayout:addChild(magicListView,6)


    local useLabel = display.newLabel(22,15 , { color = "#5b3c25", fontSize =24 , text = __('用途：'),ap = display.LEFT_CENTER })
    --magicContentLayout:addChild(useLabel,6)
    local useLabelSize = cc.size(listSize.width , display.getLabelContentSize(useLabel).height)
    local useLabelContent = display.newLayer(0,0,{ size = useLabelSize })
    useLabelContent:addChild(useLabel)
    magicListView:insertNodeAtLast(useLabelContent)






    magicContentLayout:addChild(magicContentImage,5)
    local useContent = display.newLabel(0, 0 , fontWithColor('6',{ ap = display.LEFT_TOP,hAlign = display.TAL , w = 200,text = "" }))
    --magicContentLayout:addChild(useContent,6)
    local useContentSize =cc.size(listSize.width , display.getLabelContentSize(useContent).height)
    local useContentLayout = display.newLayer(0,0,{ size  = useContentSize})
    useContentLayout:addChild(useContent)
    magicListView:insertNodeAtLast(useContentLayout)
    magicListView:reloadData()

    magicContentLayout:setVisible(true)
    magicContentLayout:setAnchorPoint(display.LEFT_TOP)
    magicContentLayout:setPosition(cc.p(bgSize.width -280 , bgSize.height -120))
    bgLayout:addChild(magicContentLayout)
    magicContentLayout:setVisible(false)
    -- 魔法菜谱显示的所需的物品Layout
    local mgaicLayout = CLayout:create(cc.size(108,108))
    mgaicLayout:setPosition(cc.p(bgSize.width/2 ,190 ))
    bgLayout:addChild(mgaicLayout)

    local goodsLayout = CLayout:create(cc.size(seasoningSize))
    local goodsSize  = goodsLayout:getContentSize()
    local middleSize = cc.size(seasoningSize.width + goodsSize.width,seasoningSize.height)
    local middleLayout = CLayout:create(middleSize)
    goodsLayout:setPosition(cc.p(goodsSize.width/2,middleSize.height/2))
    middleLayout:addChild(goodsLayout)
    middleLayout:setPosition(cc.p(bgSize.width/2 ,220 ))
    bgLayout:addChild(middleLayout)
    seasoningLayout:setPosition(cc.p(goodsSize.width + seasoningSize.width/2 ,seasoningSize.height/2-20))
    middleLayout:addChild(seasoningLayout)
    local makeBtn = display.newButton(bgSize.width/2 - 125, 70 ,{ n = RES_DICT.MAKE_BTN ,enable = true , scale9 = true  } )
    bgLayout:addChild(makeBtn)
    makeBtn:setContentSize(cc.size(205, 70))
    bgLayout:setName("bgLayout")
    local makeSize = makeBtn:getContentSize()
    local iconCooking = display.newImageView(RES_DICT.COOKING_ICON,makeSize.width/4 - 10, makeSize.height/2 +8 )
    makeBtn:addChild(iconCooking)
    display.commonUIParams(makeBtn:getLabel(), {ap = display.LEFT_CENTER})
    display.commonLabelParams(makeBtn,fontWithColor('14',{text = __('做1份'),w  =120,hAlign = display.TAC,offset = cc.p(-30,0)}))
    makeBtn:setTag(BTNCOLLECT_TAG.MAKE_BTN)
    makeBtn:setName("makeBtn")


    local makeBtnTimes = display.newButton(bgSize.width/2 +  125, 70  ,{ n = RES_DICT.MAKE_TIMES_BTN ,enable = true, scale9 = true  } )
    bgLayout:addChild(makeBtnTimes)
    makeBtnTimes:setContentSize(cc.size(205, 70))
    bgLayout:setName("bgLayout")
    local iconCooking = display.newImageView(RES_DICT.COOKING_ICON,makeSize.width/4 - 10, makeSize.height/2 +8 )
    makeBtnTimes:addChild(iconCooking)
    display.commonUIParams(makeBtnTimes:getLabel(), {ap = display.LEFT_CENTER})
    display.commonLabelParams(makeBtnTimes,fontWithColor('14',{text = string.format( __('做%d份') , 10 ),w =120,hAlign = display.TAC ,offset = cc.p(-32,0)}))
    makeBtnTimes:setTag(BTNCOLLECT_TAG.MAKE_BTN_TIMES)
    makeBtnTimes:setName("makeBtnTimes")
    local closeView = nil
    local pos = display.center
    if self.type == 1 then  -- 根据type 类型的不同传输不同的值
        closeView = display.newLayer(display.cx,display.cy , { ap = display.CENTER ,color =cc.c4b(0,0,0,100),enable = true,cb =  function ( )
            AppFacade.GetInstance():UnRegsitMediator("RecipeDetailMediator")
        end})

        self:addChild(closeView)
        self:addChild(bgLayout)
        bgLayout:setPosition(pos)
    elseif self.type == 2  then
        self:setContentSize(bgSize)
        bgLayout:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        self:addChild(bgLayout)
        self:setAnchorPoint(display.RIGHT_CENTER)
        pos = cc.p(display.cx -92, display.cy)
    end
    self:setPosition(pos)
    SpineCache(SpineCacheName.GLOBAL):addCacheData(_res('effects/upgraderecipe/skeleton.json'), _res('effects/upgraderecipe/skeleton.atlas'), 'upGradeRecipe', 1)
    local upGradeAnimation = SpineCache(SpineCacheName.GLOBAL):createWithName('upGradeRecipe')
    levelBtn:addChild(upGradeAnimation)
    local levelBtnSize = levelBtn:getContentSize()
    upGradeAnimation:setPosition(cc.p(levelBtnSize.width/2 ,levelBtnSize.height/2))
    local prograssAnimation = SpineCache(SpineCacheName.GLOBAL):createWithName('upGradeRecipe')
    prograssAnimation:setPosition(expBar:getPosition())
    layer:addChild(prograssAnimation ,-1)
    local  seasoningIcon = display.newImageView(RES_DICT.SEASONING_ICON)
    seasoningIcon:setPosition(cc.p(seasoningImageSize.width/2,seasoningImageSize.height/2))
    seasoningImage:addChild(seasoningIcon)
    self.viewData  = {
        recipeName = recipeName ,
        iconImage = iconImage ,
        levelBtn  = levelBtn ,
        expBar = expBar ,
        upGradeAnimation = upGradeAnimation ,
        expBarBtns = expBarBtns ,
        seasoningLayout = seasoningLayout  ,
        goodsLayout = goodsLayout ,
        middleLayout = middleLayout ,
        makeBtn = makeBtn ,
        bgLayout = bgLayout,
        valueLabel =valueLabel,
        ownerLabel = ownerLabel ,
        seasoningImage = seasoningImage ,
        magicContentLayout = magicContentLayout ,
        mgaicLayout  = mgaicLayout ,
        useLabel = useLabel ,
        useContent = useContent ,
        goldIcon = goldIcon ,
        tipLabel = tipLabel ,
        prograssAnimation = prograssAnimation ,
        gradeImage = gradeImage ,
        recipePropertyLayout =recipePropertyLayout ,
        seasoningIcon = seasoningIcon ,
        seasoningIconTable = seasoningIconTable ,
        makeBtnTimes = makeBtnTimes,
        magicListView = magicListView ,
        bgSize   = bgSize,
    }
end

function RecipeDetailView:updateDetailView(data ,makeSureSeasoningId)
    local isMagic = false
    if checkint(data.recipeId)>= 229001 and checkint(data.recipeId) <= 229999 then
        isMagic = true
    end
    self.viewData.middleLayout:setVisible(false)
    self.viewData.recipePropertyLayout:setVisible(false)
    self.viewData.magicContentLayout:setVisible(false)
    self.viewData.mgaicLayout:setVisible(false)
    self.viewData.expBar:setVisible(false)
    self.viewData.valueLabel:setVisible(false)
    self.viewData.goldIcon:setVisible(false)
    self.viewData.levelBtn:setVisible(false)
    self.viewData.upGradeAnimation:setVisible(false)
    self.viewData.prograssAnimation:setVisible(false)
    local recipeOneData = self.recipeData[tostring( data.recipeId)]
    self.currentData = recipeOneData
    local recipeName = CommonUtils.GetConfig('goods','goods',recipeOneData.foods[1].goodsId ).name
    local iconPath = CommonUtils.GetGoodsIconPathById(recipeOneData.foods[1].goodsId)
    display.commonLabelParams(self.viewData.recipeName , {text = recipeName, reqW  = 250  })
    self.viewData.iconImage:setTexture(iconPath)
    display.reloadRichLabel(self.viewData.ownerLabel , {
        c = {
            fontWithColor('16',{text = __('拥有:')}),
            fontWithColor('16',{text =  gameMgr:GetAmountByGoodId(recipeOneData.foods[1].goodsId)})
        }
    })
    -- self.viewData.ownerLabel:setString(__('拥有：') .. gameMgr:GetAmountByGoodId(recipeOneData.foods[1].goodsId))
    if not isMagic then
        if not  makeSureSeasoningId then
            self:reloadIconShow()
        end



        self.viewData.gradeImage:setVisible(true)
        self.viewData.expBar:setVisible(true)
        self.viewData.valueLabel:setVisible(true)
        self.viewData.middleLayout:setVisible(true)
        self.viewData.recipePropertyLayout:setVisible(true)
        self.viewData.valueLabel:setVisible(true)
        self.viewData.goldIcon:setVisible(true)

        local RecipeDetailMediator = AppFacade.GetInstance():RetrieveMediator('RecipeDetailMediator')
        if RecipeDetailMediator and RecipeDetailMediator.lobbyFestivalTipView then
            RecipeDetailMediator.lobbyFestivalTipView:setVisible(false)
            -- if RecipeDetailMediator.lobbyFestivalTipView:isVisible() then
            --     RecipeDetailMediator.lobbyFestivalTipView:updateUi(lobbyFestivalMenuData, data)
            -- end
        end
        local gold  =  recipeOneData.grade[tostring(data.gradeId)].gold
        -- self.viewData.valueLabel:setString( __('价值：') .. gold)
        display.reloadRichLabel(self.viewData.valueLabel , {
            c = {
                fontWithColor('16',{text = __('餐厅价格:')}),
                fontWithColor('10',{text =  gold})
            }
        })

        local level = table.nums(CommonUtils.GetConfigAllMess('grade','cooking'))
        local grade = (checkint(data.gradeId)  +1 >= level and level ) or checkint(data.gradeId) +1
        local taste = data.taste  --口味
        local museFeel = data.museFeel  --口感
        local fragrance = data.fragrance
        local exterior = data.exterior
        local recipePropertyData = { [1] = taste, [2] = museFeel,[3]= fragrance ,[4] = exterior}
        local growthTotal = data.growthTotal
        self.viewData.expBar:setMaxValue(checkint(self.gradeData[tostring(grade) ].sum))
        self.viewData.expBar:setValue(data.growthTotal)
        self.viewData.gradeImage:setTexture(_res( string.format('ui/home/kitchen/cooking_grade_ico_%d.png' ,data.gradeId)))

        local groupKeys = {"taste" ,"museFeel" , "fragrance" ,"exterior"}
        local node = nil
        for i=1 , #self.viewData.expBarBtns do
            --dump(data)
            --dump(self.recipeData)
            local countMax = checkint(self.recipeData[tostring(data.recipeId)][groupKeys[i]])
            -- 当前菜谱拥有的属性的最大值
            local countNum = checkint(recipePropertyData[i])
            -- 当前菜谱属性
            if countMax > countNum  then
                node = self.viewData.expBarBtns[i]:getChildByName("maxLabel")
                if node then
                    node:setVisible(false)
                end
                self.viewData.expBarBtns[i]:setMaxValue(countMax )
                self.viewData.expBarBtns[i]:setValue(countNum)
                display.commonLabelParams(self.viewData.expBarBtns[i]:getLabel(),{ text =  string.format(" %s/%s",countNum,countMax)})
                self.viewData.expBarBtns[i]:getLabel():setVisible(true)
            else
                self.viewData.expBarBtns[i]:setMaxValue(countMax )
                self.viewData.expBarBtns[i]:setValue(countMax)
                self.viewData.expBarBtns[i]:getLabel():setVisible(false)
                node = self.viewData.expBarBtns[i]:getChildByName("maxLabel")
                if node then
                    node:setVisible(true)
                    display.commonLabelParams(node, fontWithColor('14' , { fontSize = 30, text = "Max"  }))
                end
            end
        end
        if checkint(data.growthTotal)  >= checkint(self.gradeData[tostring(grade)].sum)  and grade <= level and checkint(data.gradeId)  ~= level then
            self.viewData.levelBtn:setVisible(true)
            self.viewData.levelBtn:setOpacity(0)
            self.viewData.levelBtn:setCascadeOpacityEnabled(false)
            self.viewData.prograssAnimation:setCascadeOpacityEnabled(false)
            self.viewData.upGradeAnimation:setVisible(true)
            self.viewData.prograssAnimation:setVisible(true)
            self.viewData.upGradeAnimation:setAnimation(0, 'idle_wenzi', true)
            self.viewData.prograssAnimation:setAnimation(0,'idle_jindutiao',true)
        else
            self.viewData.upGradeAnimation:setToSetupPose()
            self.viewData.prograssAnimation:setToSetupPose()
        end

        if not  makeSureSeasoningId  then
            self.viewData.tipLabel:setString(__('添加佐料'))
            self.viewData.seasoningIcon:setVisible(true)
            local node =  self.viewData.seasoningImage:getChildByTag(115)
            if  node then
                self.viewData.seasoningImage:removeChildByTag(115)
            end
        else
            self.viewData.seasoningIcon:setVisible(false)
        end
        -- 调整下面的界面
        local consumeData = recipeOneData.make
        local needLayout = self:needLayout(consumeData)
        local needSize = needLayout:getContentSize()
        self.viewData.goodsLayout:setContentSize(needSize)
        self.viewData.goodsLayout:removeAllChildren()
        self.viewData.goodsLayout:addChild(needLayout)

        local seasoningSize = self.viewData.seasoningLayout:getContentSize()
        local milddleSize = cc.size(seasoningSize.width+needSize.width , seasoningSize.height)
        self.viewData.middleLayout:setContentSize(milddleSize)
        needLayout:setPosition(cc.p(needSize.width/2 ,milddleSize.height/2))
        self.viewData.goodsLayout:setPosition(cc.p(needSize.width/2 ,milddleSize.height/2))
        self.viewData.seasoningLayout:setAnchorPoint(display.RIGHT_CENTER)
        self.viewData.seasoningLayout:setPosition(cc.p(milddleSize.width,milddleSize.height/2 -6))

        local isOpenLobbyActivity = app.activityMgr:isOpenLobbyFestivalActivity()
        -- 活动开启
        if isOpenLobbyActivity then
            -- self:createLobbyFestivalTip()
            -- 该菜谱 是 餐厅活动菜谱
            local lobbyFestivalMenuData = app.activityMgr:getLobbyFestivalMenuData(data.recipeId)
            local lobbyFestivalTipVisible = lobbyFestivalMenuData ~= nil

            local nodeExist = function (node)
                return node and not tolua.isnull(node)
            end

            if not nodeExist(self.viewData.lobbyFestivalTipLayer) then
                self:createLobbyFestivalTip()
            end

            self.viewData.lobbyFestivalTipLayer:setVisible(lobbyFestivalTipVisible)
            if lobbyFestivalTipVisible then
                self:showLobbyFestivalTip()
            end

        end
    else
        local node =  self.viewData.mgaicLayout:getChildByTag(115)
        if node then
            self.viewData.mgaicLayout:removeChildByTag(115)
        end
        self.viewData.magicContentLayout:setVisible(true)
        self.viewData.mgaicLayout:setVisible(true)
        self.viewData.useContent:setString(CommonUtils.GetConfig('goods','goods',recipeOneData.foods[1].goodsId ).descr)

        local useContentParent = self.viewData.useContent:getParent()
        local useContentSize = display.getLabelContentSize(self.viewData.useContent)
        local useContentParentSize  = useContentParent:getContentSize()
        useContentParent:setContentSize(cc.size(useContentParentSize.width,useContentSize.height) )
        self.viewData.useContent:setPosition( 22, useContentSize.height)

        self.viewData.magicListView:reloadData()
        local layout = self:needLayout(recipeOneData.make)
        layout:setTag(115)
        local layoutSize = layout:getContentSize()
        layout:setPosition(cc.p(layoutSize.width/2,layoutSize.height/2))
        self.viewData.mgaicLayout:setContentSize(layoutSize)
        self.viewData.mgaicLayout:addChild(layout)
    end
end

function RecipeDetailView:reloadIconShow(isChange) -- 重置显示的效果

    local  seasoningIconTable = self.viewData.seasoningIconTable
    for i =1 ,   #seasoningIconTable do  -- 首先要重置界面的状态
        for j  =1 , #seasoningIconTable[i] do
            seasoningIconTable[i][j]:setVisible(false)
        end
    end
    if isChange ~= false then
        self.viewData.tipLabel:setString(__('添加佐料'))
    end
end
-- 显示添加调料的效果
function RecipeDetailView:addSeasoningUpdateView(datas , seasongId)
    self:reloadIconShow(false)
    local seasoningEffect = CommonUtils.GetConfigAllMess('recipeSeasoningEffect','cooking')[tostring(datas.recipeId)][tostring(seasongId)]
    --local seasoningData = CommonUtils.GetConfig('goods','goods',seasongId)
    local groupkeys =  {"taste" ,"museFeel" , "fragrance" ,"exterior"}
    local groupkeysDecr = {__('味道'),  __('口感'), __('香味') , __('外观')}
    --self.viewData.tipLabel:setString(seasoningData.name)
    if not  seasoningEffect then
        return
    end

    local attrTable  = table.split(tostring(seasoningEffect.attr),";")
    local effectLevel = seasoningEffect.effectLevel
    local haveUseSeasoningTable
    if datas.seasoning then
        haveUseSeasoningTable  = table.split(datas.seasoning ,",")
    else
        haveUseSeasoningTable = {}
    end
    local haveUse = false
    for  i =1 ,#haveUseSeasoningTable do
        if checkint(seasongId) == checkint(haveUseSeasoningTable[i]) + 230000  then
            haveUse = true
            break
        end
    end
    if haveUse then
        local fullAttr = {}
        for  i = 1 , #attrTable do
            local iconPath = ""
            if checkint(effectLevel[i]) > 0 then
                iconPath = RES_DICT.ICON_TOP
            elseif  checkint(effectLevel[i])  < 0  then
                iconPath = RES_DICT.ICON_DOWN
            end
            if iconPath == "" then
                return
            end
            --TODO  此处做添加操作
            local attr = groupkeys[checkint(attrTable[i]) ]
            if  checkint(datas[attr]) >= checkint(self.recipeData[tostring(datas.recipeId) ][attr] )   then
                table.insert(fullAttr, #fullAttr+1, groupkeysDecr[checkint(attrTable[i]) ])
            end
            for j =1 ,math.abs( checkint(effectLevel[i])   or 0 )   do
                if  checkint(datas[attr]) >= checkint(self.recipeData[tostring(datas.recipeId) ][attr] )   then --- 对应的是菜品详情的 当前属性满足的时候不添加书香显示
                else
                    self.viewData.seasoningIconTable[checkint(attrTable[i])][j]:setVisible(true)
                    self.viewData.seasoningIconTable[checkint(attrTable[i])][j]:setTexture(iconPath)
                end
            end
            local str  = ""
            if #effectLevel> 0 and  #fullAttr == #effectLevel then

                for k ,v in pairs( fullAttr) do
                    str = str .. v
                end
                return str
            end
        end
    end
end
--创建需要食材的界面
function RecipeDetailView:needLayout(consumeData)
    local consume_Data = {}
    for  k , v  in pairs (consumeData) do
        consume_Data[#consume_Data+1] = {}
        consume_Data[#consume_Data].goodsId = k
        consume_Data[#consume_Data].num = v
    end
    local goodSize  = cc.size(108,108)
    local needSize = cc.size(goodSize.width * (table.nums(consume_Data)) ,goodSize.height)
    local needLayout = CLayout:create(needSize)
    local foodMaterial  = true

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
            fontWithColor(oneColor ,{text =tostring(gameMgr:GetAmountByGoodId(data.goodsId)) .."/" } )  ,
            fontWithColor('6',{text = tostring(data.num) })
        }})
        needLayout:addChild(richLabel)
    end
    self.foodMaterialEnough =foodMaterial
    return needLayout
end

function RecipeDetailView:createLobbyFestivalTip()
    local bgLayout = self.viewData.bgLayout
    local bgSize   = self.viewData.bgSize

    local lobbyFestivalTipLayer = display.newLayer(20, bgSize.height - 66, {ap = display.LEFT_BOTTOM, enable = true, size = cc.size(bgSize.width - 120, 50), color = cc.c4b(0, 0, 0, 0)})
    lobbyFestivalTipLayer:setTag(BTNCOLLECT_TAG.LOBBY_FESTIVAL_TIP)
    bgLayout:addChild(lobbyFestivalTipLayer)

    local lobbyFestivalLabel = display.newLabel(0, 0, {color = '#d34300', fontSize = 24, ap = display.LEFT_BOTTOM, text = __('(节日菜谱)')})
    local lobbyFestivalLabelSize = display.getLabelContentSize(lobbyFestivalLabel)
    display.commonUIParams(lobbyFestivalLabel, {po = cc.p(250, 16)})
    lobbyFestivalTipLayer:addChild(lobbyFestivalLabel)

    local questionMarkImg = display.newImageView(RES_DICT.QUESTION_MARK, 0, 0)
    display.commonUIParams(questionMarkImg, {po = cc.p(250 + lobbyFestivalLabelSize.width / 2 + 5, 0), ap = display.LEFT_BOTTOM})
    lobbyFestivalTipLayer:addChild(questionMarkImg)

    self.viewData.lobbyFestivalTipLayer = lobbyFestivalTipLayer
    self.viewData.lobbyFestivalLabel = lobbyFestivalLabel
    self.viewData.questionMarkImg = questionMarkImg

end

function RecipeDetailView:showLobbyFestivalTip()

    local recipeNameSize = self.viewData.recipeName:getContentSize() --display.getLabelContentSize(self.viewData.recipeName)
    local lobbyFestivalLabel = self.viewData.lobbyFestivalLabel
    display.commonUIParams(lobbyFestivalLabel, {po = cc.p(120 + recipeNameSize.width/2 + 10, 0)})

    local questionMarkImg = self.viewData.questionMarkImg
    local lobbyFestivalLabelSize = display.getLabelContentSize(lobbyFestivalLabel)
    display.commonUIParams(questionMarkImg, {po = cc.p(lobbyFestivalLabel:getPositionX() + lobbyFestivalLabelSize.width + 10, 0)})
end

return RecipeDetailView
