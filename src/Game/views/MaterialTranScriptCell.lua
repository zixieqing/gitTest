---
--- Created by xingweihao.
--- DateTime: 20/11/2017 1:32 PM
---
---@class MaterialTranScriptCell
local MaterialTranScriptCell = class('home.MaterialTranScriptCell',function ()
    local pageviewcell = CTableViewCell:new()
    pageviewcell.name = 'home.MaterialTranScriptCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)
local DESC_DICT = {
    CARD_BG = _res('ui/home/materialScript/material_card_bg_back'),
    CARD_BG_CHOSEN = _res('ui/home/materialScript/material_card_bg_chosen'),
    CARD_BG_DISABLE = _res('ui/home/materialScript/material_card_bg_disable'),
    CARD_BG_MAIN = _res('ui/home/materialScript/material_card_bg_main'),
    CARD_BG_SUB = _res('ui/home/materialScript/material_card_bg_sub'),
    CARD_BG_TITLE = _res('ui/home/materialScript/material_card_bg_title'),
    CARD_BTN_SELECT_DEFAULT = _res('ui/home/materialScript/material_card_btn_selectlist_default'),
    CARD_BTN_SELECT_DOWN = _res('ui/home/materialScript/material_card_btn_selectlist_down'),
    CARD_LABEL_RELEASE_TIME = _res('ui/home/materialScript/material_card_label_releasetime'),
    CARD_LABEL_TIMELEFT = _res('ui/home/materialScript/material_card_label_timesleft'),
    CARD_LABEL_RCMLEVEL = _res('ui/home/materialScript/material_card_laber_rcmlevel'),
    CARD_LINE_ONE      =   _res('ui/home/materialScript/material_card_line_1'),
    CARD_LINE_TWO       =   _res('ui/home/materialScript/material_card_line_2'),
    CARD_MODEICO       = _res('ui/home/materialScript/material_card_modeico_1'),
    CARD_WARNING_TWO       = _res('ui/home/materialScript/material_label_warning_2'),
    CARD_SELECT_LIST       = _res('ui/home/materialScript/material_selectlist_bg'),
    CARD_SELECT_LIST_LABEL_CHOSE        = _res('ui/home/materialScript/material_selectlist_label_chosen'),
    CARD_SELECT_LIST_LABEL_LINE        = _res('ui/home/materialScript/material_selectlist_line'),
    MATERIAL_CARD_ICON     = _res('ui/home/materialScript/material_card_ico_1'),
}
local CELL_STATUS = {
    LOCK_STATUS = 1 , -- 未解锁
    UNLOCK_UNUSE = 2 , -- 已解锁 不可用
    UNLOCK_UNSELECT = 3 , -- 解锁未选中
    UNLOCK_SELECT = 4 , -- 选中状态

}


function MaterialTranScriptCell:ctor(param)
    local cellSize =  cc.size(404,680)
    self:setContentSize(cellSize)

    local cellContentSzie = cc.size(400,600)
    local cellLayout = display.newLayer(cellSize.width/2, 50, { ap = display.CENTER_BOTTOM  , size = cellContentSzie})
    self:addChild(cellLayout)
    cellLayout:setName("cellLayout")
    -- 点击的layer
    local clickLayer = display.newLayer(cellContentSzie.width/2 , cellContentSzie.height/2,
            {ap = display.CENTER ,size =cellContentSzie , color = cc.c4b(0,0,0,0) , enable = true })
    cellLayout:addChild(clickLayer)
    -- 选中的光圈
    local bgImageChosen = display.newImageView(DESC_DICT.CARD_BG_CHOSEN , cellContentSzie.width/2 , cellContentSzie.height/2)
    cellLayout:addChild(bgImageChosen)
    bgImageChosen:setVisible(false)
    -- 顶部的材料图片
    local card_Bg_Back = FilteredSpriteWithOne:create(DESC_DICT.CARD_BG)
    card_Bg_Back:setPosition(cc.p( cellContentSzie.width/2 , cellContentSzie.height -18))
    card_Bg_Back:setAnchorPoint(display.CENTER_TOP)
    cellLayout:addChild(card_Bg_Back)
    -- 材料的东西
    local materialCard =FilteredSpriteWithOne:create(DESC_DICT.MATERIAL_CARD_ICON)
    materialCard:setPosition(cc.p(  cellContentSzie.width/2 , cellContentSzie.height + 10))
    materialCard:setAnchorPoint(display.CENTER_TOP)
    cellLayout:addChild(materialCard)
    -- 前面的背景
    local card_bg_main = FilteredSpriteWithOne:create(DESC_DICT.CARD_BG_MAIN )
    card_bg_main:setPosition(cc.p(  cellContentSzie.width/2 , cellContentSzie.height /2))
    cellLayout:addChild(card_bg_main)

    -- 图片蒙版
    local card_bg_disable = display.newImageView(DESC_DICT.CARD_BG_DISABLE)
    card_bg_disable:setPosition(cc.p(  cellContentSzie.width/2 , cellContentSzie.height /2))
    cellLayout:addChild(card_bg_disable,4)
    card_bg_disable:setVisible(false)
    -- 最左侧的线
    local titleImage =  FilteredSpriteWithOne:create(DESC_DICT.CARD_BG_TITLE)
    local titleSize = titleImage:getContentSize()

    local titleLayout  =   display.newLayer(cellContentSzie.width/2 , cellContentSzie.height - 195,
                 {ap = display.CENTER ,size =titleSize , color = cc.c4b(0,0,0,0)})
    titleLayout:addChild(titleImage)
    titleImage:setPosition(cc.p(titleSize.width/2 ,titleSize.height/2 +10))
    cellLayout:addChild(titleLayout,2)
    -- 副本的名字
    local materialScriptLabel = display.newLabel(titleSize.width/2 , titleSize.height/2  +10, fontWithColor('14' , {fontSize = 24 , color = "#ffffff" ,text = " asdadada"   }))
    titleLayout:addChild(materialScriptLabel)
    -- 第一条线
    local line_one = display.newImageView(DESC_DICT.CARD_LINE_ONE,titleSize.width/2 , titleSize.height , { ap  = display.CENTER_TOP } )
    titleLayout:addChild(line_one)
    -- 简介的label



    local labelWarning = display.newImageView(DESC_DICT.CARD_LABEL_TIMELEFT)
    local labelWarningSize = labelWarning:getContentSize()
    labelWarning:setPosition(cc.p(labelWarningSize.width/2 , labelWarningSize.height/2))
    local introduceLabel = display.newLabel(titleSize.width/2 , titleSize.height , fontWithColor('8' , {fontSize = 18 ,color = "#926341" ,text = "" , ap = display.CENTER_TOP }))
    titleLayout:addChild(introduceLabel,10 )

    local labelWarnLayout =  display.newLayer(titleSize.width/2 , 40,
                    {ap = display.CENTER_TOP,size =labelWarningSize , color1 = cc.r4b() , enable = true })
    titleLayout:addChild(labelWarnLayout)
    labelWarnLayout:addChild(labelWarning)

    --local openTimeLabel = display.newRichLabel(labelWarningSize.width/2 , labelWarningSize.height/2 , { r = true ,
    --    c ={fontWithColor('8' , { color = "#ffffff",text = "好好学习"}) }
    --})
    local openTimeLabel = display.newLabel(labelWarningSize.width/2 , labelWarningSize.height/2 , fontWithColor('10',{fontSize = 22, text = ""}))
    labelWarnLayout:addChild(openTimeLabel,2)


    -- 中间区域的背景
    local card_bg_sub = FilteredSpriteWithOne:create(DESC_DICT.CARD_BG_SUB)
    local card_bg_sub_Size = card_bg_sub:getContentSize()
    card_bg_sub:setPosition(cc.p(card_bg_sub_Size.width/2 , card_bg_sub_Size.height/2))
    -- 中部区域的主要内容
    local subcontentLayout =  display.newLayer(cellContentSzie.width/2 , cellContentSzie.height - 265,
                    {ap = display.CENTER_TOP ,size =card_bg_sub_Size , color1 = cc.r4b() , enable = true })

    cellLayout:addChild(subcontentLayout)
    subcontentLayout:addChild(card_bg_sub)

    -- 选择难度
    local chosenDifficultyLabel = display.newLabel(15, card_bg_sub_Size.height-20 ,
                fontWithColor('8' , {fontSize = 20 ,color = "#926341",text =  __("选择难度:") ,ap = display.LEFT_CENTER}))
    subcontentLayout:addChild(chosenDifficultyLabel)
    -- 选择难度的按钮
    local chooseDifficultyBtn  =  display.newCheckBox(card_bg_sub_Size.width/2 , card_bg_sub_Size.height -35,
                { n = DESC_DICT.CARD_BTN_SELECT_DEFAULT , s=   DESC_DICT.CARD_BTN_SELECT_DOWN})
    chooseDifficultyBtn:setName("chooseDifficultyBtn")
    local chooseDifficultyBtnSize = chooseDifficultyBtn:getContentSize()
    chooseDifficultyBtn:setPosition(cc.p(chooseDifficultyBtnSize.width/2 , chooseDifficultyBtnSize.height/2))
    local chooseDifficultyLayout = display.newLayer(card_bg_sub_Size.width/2 , card_bg_sub_Size.height -35, {ap = display.CENTER_TOP , size = chooseDifficultyBtnSize ,color = cc.c4b(0,0,0,0),enable = true  })
    subcontentLayout:addChild( chooseDifficultyLayout)

    chooseDifficultyLayout:addChild(chooseDifficultyBtn)
    -- 选择的难度
    local difficultyLabel = display.newRichLabel(chooseDifficultyBtnSize.width/2 - 30 , chooseDifficultyBtnSize.height/2 , { r = true ,
        c ={fontWithColor('8' , {text = "好好学习"}) }
    })
    difficultyLabel:setName("difficultyLabel")
    chooseDifficultyLayout:addChild(difficultyLabel)

    -- 第二条线
    local lineTwo  = display.newImageView(DESC_DICT.CARD_LINE_TWO ,card_bg_sub_Size.width/2 , card_bg_sub_Size.height - 104 , { ap = display.CENTER_TOP} )
    subcontentLayout:addChild(lineTwo)

    local titleBtn =  display.newButton(card_bg_sub_Size.width/2 , card_bg_sub_Size.height -105, {ap = display.CENTER_TOP , n = _res('ui/common/common_title_5') ,scale9 = true , enable = false })
    display.commonLabelParams(titleBtn, fontWithColor('8' , {text = __('可能掉落') ,paddingW  = 20}))
    subcontentLayout:addChild(titleBtn)

    --local recommendImage = display.newImageView(DESC_DICT.CARD_LABEL_RCMLEVEL , card_bg_sub_Size.width/2, 15 )
    --subcontentLayout:addChild(recommendImage)
    --local recommendLevel =  display.newLabel(card_bg_sub_Size.width/2, 15 , fontWithColor('8' , {fontSize = 20 ,text = "推荐等级:" , color = "#926341" ,ap = display.CENTER}))
    --subcontentLayout:addChild(recommendLevel)
    --recommendLevel:setName("recommendLevel")


    local card_releasetTime =  FilteredSpriteWithOne:create(DESC_DICT.CARD_LABEL_RELEASE_TIME)
    local card_releasetTimeSize = card_releasetTime:getContentSize()
    local challengeLayout = display.newLayer(cellContentSzie.width/2 , 0 , {size  = card_releasetTimeSize ,ap = display.CENTER , color1 = cc.r4b()
    })
    card_releasetTime:setPosition(cc.p(card_releasetTimeSize.width/2 ,card_releasetTimeSize.height/2))
    challengeLayout:addChild(card_releasetTime)
    -- 剩余的次数
    local leftTime  = display.newRichLabel(card_releasetTimeSize.width/2, card_releasetTimeSize.height/2 , { c = {fontWithColor('8' , {fontSize = 20   ,text = "推荐等级:"})}} )
    challengeLayout:addChild(leftTime)
    cellLayout:addChild(challengeLayout)


    self.viewData = {
        clickLayer = clickLayer,
        card_Bg_Back = card_Bg_Back ,
        materialCard = materialCard ,
        card_bg_main = card_bg_main ,
        card_bg_disable = card_bg_disable ,
        titleImage = titleImage ,
        materialScriptLabel = materialScriptLabel ,
        chooseDifficultyBtn = chooseDifficultyBtn ,
        difficultyLabel = difficultyLabel ,
        card_releasetTime = card_releasetTime ,
        card_releasetTimeSize = card_releasetTimeSize ,
        challengeLayout = challengeLayout ,
        --recommendLevel = recommendLevel,
        subcontentLayout = subcontentLayout ,
        introduceLabel = introduceLabel ,
        leftTime = leftTime ,
        openTimeLabel = openTimeLabel,
        card_bg_sub = card_bg_sub ,
        cellLayout = cellLayout,
        chooseDifficultyLayout = chooseDifficultyLayout,
        bgImageChosen = bgImageChosen
    }
end

--[[
    更细图片的状态，这个里面  】
     status  = CELL_STATUS.LOCK_STATUS , 未解锁
     status  = CELL_STATUS.UNLOCK_UNSELECT , 未选定
     status  = CELL_STATUS.UNLOCK_SELECT  ,选中状态
]]
function MaterialTranScriptCell:UpdateCellStatus(status)
    local isVisible = false
    isVisible = (status == CELL_STATUS.LOCK_STATUS)  or  (status == CELL_STATUS.UNLOCK_UNUSE) -- 为1和为2 的时候 蒙版显示
    if status == CELL_STATUS.UNLOCK_UNUSE  then
        self.viewData.materialCard:setColor( cc.c3b(100,100,100))
    else
        self.viewData.materialCard:setColor( cc.c3b(255   ,255,255) )
    end
    if status == CELL_STATUS.LOCK_STATUS  then
        self:SetGray(false , self.viewData.card_Bg_Back)
        self:SetGray(false , self.viewData.materialCard)
        self:SetGray(false , self.viewData.card_bg_main)
        self:SetGray(false , self.viewData.titleImage)
        self:SetGray(false , self.viewData.card_releasetTime)
        self:SetGray(false , self.viewData.card_bg_sub)
        self.viewData.card_bg_disable:setVisible(isVisible)
    elseif status ==CELL_STATUS.UNLOCK_SELECT or status ==CELL_STATUS.UNLOCK_UNSELECT or status == CELL_STATUS.UNLOCK_UNUSE   then
        self:SetGray(true , self.viewData.card_Bg_Back)
        self:SetGray(true , self.viewData.materialCard)
        self:SetGray(true , self.viewData.card_bg_main)

        self:SetGray(true , self.viewData.titleImage)
        self:SetGray(true , self.viewData.card_releasetTime)
        self:SetGray(true , self.viewData.card_bg_sub)

        self.viewData.card_bg_disable:setVisible(isVisible)


    end
end

function MaterialTranScriptCell:SetGray( isGray ,node )
    if not  isGray then
        node:setFilter(GrayFilter:create())
    else
        node:clearFilter()
    end
end
return MaterialTranScriptCell
