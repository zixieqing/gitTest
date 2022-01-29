--[[
邮箱界面
--]]
---@class PetSmeltingView
local PetSmeltingView = class('PetSmeltingView', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(display.CENTER)
    node.name = 'home.PetSmeltingView'
    node:enableNodeEvents()
    return node
end)
local BUTTON_TAG = {
    CLEAN_PET_EGGS         = 1101,
    QUICK_CONSUME_PET_EGGS = 1102,
    SMELTING_EGGS          = 1103,
    BACK_PURGE             = 1104,
    BATCH_CONSUME_PET_EGGS = 1105
}
local funsionConfig = CommonUtils.GetConfigAllMess('fusion','pet')

function PetSmeltingView:ctor(param )
    local callbackSpine = param.callbackSpine
    local bgLayer = display.newLayer(display.cx, display.cy , {  ap = display.CENTER, color1 = cc.r4b()  ,enable = true })
    self:addChild(bgLayer)

    -- 左侧的熔炼炉背景图片
    --local leftBgImage = display.newImageView(_res('ui/pet/smelting/aaamelting_bg_guo'))
    local leftBgImage = sp.SkeletonAnimation:create(
            'effects/pet/ronglian.json',
            'effects/pet/ronglian.atlas',
            1)
    leftBgImage:setAnimation(0, 'yidong1', true)
    local leftSize = cc.size(856,878 )

    local fixeid =  display.width/display.height
    local height = fixeid > 1.7 and -126 or 0
    local leftLayout = display.newLayer(display.SAFE_RECT.x , height, { ap = display.LEFT_BOTTOM , color1 = cc.r4b(), size = leftSize})
    self:addChild(leftLayout)
    --leftLayout:setVisible(false)
    local heightoff = -54

    leftBgImage:setPosition(cc.p(0,0))
    -- 返回熔炼的按钮
    local backPurgeBtn = display.newButton(110 , 278 , { n = _res('ui/pet/smelting/melting_btn_fuhua')} )
    display.commonLabelParams(backPurgeBtn, fontWithColor('14', {text = __('去孵化')}))
    leftLayout:addChild(backPurgeBtn,10)
    backPurgeBtn:setTag(BUTTON_TAG.BACK_PURGE)


    leftLayout:addChild(leftBgImage)
    leftBgImage:registerSpineEventHandler(callbackSpine, sp.EventType.ANIMATION_COMPLETE)
    local leftPos = cc.p( leftLayout:getPosition())

    -- 熔炼的进度条
    local progressOne = CProgressBar:create(_res('ui/pet/smelting/melting_bar_2'))
    progressOne:setBackgroundImage(_res('ui/pet/smelting/melting_bar_3'))
    progressOne:setDirection(eProgressBarDirectionLeftToRight)
    progressOne:setAnchorPoint(display.CENTER_BOTTOM)
    progressOne:setPosition(cc.p(leftSize.width/2  +70, 710 +heightoff))


    local count = 0
    for i, v in pairs(funsionConfig) do
        count = checkint(v.fusionUnit)
        break
    end
    progressOne:setMaxValue(checkint(count) )
    progressOne:setValue(0)

    leftLayout:addChild(progressOne)

    local progressOneSize = progressOne:getContentSize()
    local progressOneLabel = display.newLabel(progressOneSize.width/2 , progressOneSize.height/2,
                                              fontWithColor('10',{reqW = 420 ,  color = "#ffffff",fontSize = 24 ,  ap = display.CENTER , text =  string.format(__('熔炉容量:0/%d 灵司') ,count  )  }))
    progressOne:addChild(progressOneLabel,100)
    local formeImage = display.newImageView(_res('ui/pet/smelting/melting_bar_1'),progressOneSize.width/2 , progressOneSize.height/2)
    progressOne:addChild(formeImage,100)


    local  cleanSmleterBtn
    if isElexSdk() then
        cleanSmleterBtn  = display.newButton( 200 ,700 + heightoff, { ap = display.CENTER_BOTTOM ,  n = _res( "ui/cards/petNew/team_btn_selection_unused.png") , scale9 = true , size = cc.size(150 ,60 ) } )
        leftLayout:addChild(cleanSmleterBtn)
        display.commonLabelParams(cleanSmleterBtn ,  fontWithColor('10',{color = "ffffff", text = __('清空熔炉') , hAlign = display.TAC ,  w = 150 }))
    else
        cleanSmleterBtn  = display.newButton( 200 ,700 + heightoff, { ap = display.CENTER_BOTTOM ,  n = _res( "ui/cards/petNew/team_btn_selection_unused.png") } )
        leftLayout:addChild(cleanSmleterBtn)
        display.commonLabelParams(cleanSmleterBtn ,  fontWithColor('10',{color = "ffffff", text = __('清空熔炉')  }))
    end
    cleanSmleterBtn:setTag(BUTTON_TAG.CLEAN_PET_EGGS)
    local detailImage  = display.newImageView(_res('ui/pet/smelting/melting_bg_details') )
    local detailSize = detailImage:getContentSize()
    -- 熔炼详情的layout
    local detailLayout = display.newLayer(428,680 +heightoff,{ap = display.CENTER_TOP , size = cc.size(503, 285)})
    detailLayout:addChild(detailImage)
    detailImage:setPosition(detailSize.width/2, detailSize.height/2)
    leftLayout:addChild(detailLayout)

    -- 添加精华介绍
    --local detailLabel = display.newLabel(detailSize.width/2 , detailSize.height - 80 , fontWithColor('8', {text = __('请添加堕神精华')}) )
    local detailLabel = display.newRichLabel(detailSize.width/2, detailSize.height/2 +80, {
        r = true ,
        ap = display.CENTER_TOP,
        c = {
            {img = _res('ui/pet/smelting/melting_qban_bg'),ap = cc.p(0, 0.2) },
            fontWithColor('8', {text = "    " ..  __('请添加灵体进入熔炉') , ap = cc.p(0, -1)})
        }
    })
    detailLayout:addChild(detailLabel)

    -- 添加的详细怪物
    local detailContent = display.newLayer(detailSize.width/2 , detailSize.height/2 , { ap = display.CENTER , size = detailSize })
    detailLayout:addChild(detailContent)

    -- 消耗的堕神
    local gridViewSize =  cc.size(detailSize.width - 25 , detailSize.height - 22 )
    local gridPetLine = 4 
    local petConsumeCellSize = cc.size(gridViewSize.width / gridPetLine, gridViewSize.width / gridPetLine - 10 )
    local petConsumeGridView = CGridView:create(gridViewSize)
    petConsumeGridView:setAnchorPoint(display.CENTER)
    petConsumeGridView:setPosition(detailSize.width/2 -1, detailSize.height/2)
    petConsumeGridView:setCountOfCell(0)
    petConsumeGridView:setColumns(gridPetLine)
    petConsumeGridView:setSizeOfCell(petConsumeCellSize)
    petConsumeGridView:setAutoRelocate(false)
    detailContent:addChild(petConsumeGridView)
    detailContent:setVisible(false)


    local leftBottomImage = display.newImageView(_res('ui/pet/pet_clean_bg_console'))
    local leftBottomSize = leftBottomImage:getContentSize()

    -- 底部的图片
    local leftBottomLayout = display.newLayer(leftSize.width/2, math.abs(height) ,{ap = display.CENTER_BOTTOM, size = leftBottomSize })
    leftLayout:addChild(leftBottomLayout)
    leftBottomImage:setAnchorPoint(display.CENTER)

    leftBottomImage:setPosition(cc.p( leftBottomSize.width/2 , leftBottomSize.height/2))
    leftBottomLayout:addChild(leftBottomImage)
    leftBottomLayout:setVisible(false)

    local leftBottomLayoutPos = cc.p(leftBottomLayout:getPosition())

    ---- 熔炼按钮
    local smeltingBtn = display.newButton(leftBottomSize.width/2,leftBottomSize.height/2 + 10,{ n =_res('ui/common/common_btn_orange_disable') , scale9 = true })
    leftBottomLayout:addChild(smeltingBtn)
    smeltingBtn:setTag(BUTTON_TAG.SMELTING_EGGS)
    --local smeltinBtnSize = smeltingBtn:getContentSize()
    --local originImage = display.newImageView(_res('ui/common/common_btn_orange'),smeltinBtnSize.width/2 , smeltinBtnSize.height/2 )
    --smeltingBtn:addChild(originImage)
    display.commonLabelParams(smeltingBtn,  fontWithColor( '14' , {text = __('熔炼') , paddingW = 20 }))

    -- 提示的语句
    local tipBtn = display.newButton(leftBottomSize.width/2 , 5 , {ap = display.CENTER_BOTTOM , n = _res('ui/pet/smelting/melting_bg_tips'  ), enable = false , scale9  = true })
    leftBottomLayout:addChild(tipBtn)
    display.commonLabelParams(tipBtn, fontWithColor(10 , {color = "#ffffff", text = __('每次熔炼可随机获取1~5个异化石') , paddingW = 20 }))


    -- 右侧的内容
    local rightSize = cc.size(display.width-leftSize.width - display.SAFE_RECT.x -13 ,display.height - 40 )
    local rightLayout = display.newLayer(leftSize.width + display.SAFE_RECT.x +4, display.height - 58 , {ap = display.LEFT_TOP, size= rightSize, color1 = cc.r4b() } )
    local rightBgImage = display.newImageView(_res('ui/common/common_bg_4') , rightSize.width/2,rightSize.height/2,{ap = display.CENTER , scale9 = true , size = rightSize})
    rightLayout:addChild(rightBgImage)
    self:addChild(rightLayout)

    -- 堕神的仓库label
    local petWareHouseLabel
    -- 快速填充的按钮
    local  quickBtn
    if isElexSdk() then
        petWareHouseLabel  = display.newButton(rightSize.width/2 + 80   , rightSize.height - 28  , { ap = display.RIGHT_CENTER ,  n =  _res('ui/common/common_title_5.png')  , scale9 = true })
        display.commonLabelParams(petWareHouseLabel, fontWithColor('6' , { fontSize = 18 , text = __('灵体仓库') ,   hAlign = display.TAC , paddingW = 20  } ))
        rightLayout:addChild(petWareHouseLabel)
        quickBtn = display.newButton(90 ,rightSize.height - 35, { ap = display.CENTER , scale9 = true , size = cc.size(150, 55  ), n = _res( "ui/cards/petNew/team_btn_selection_unused.png")} )
        rightLayout:addChild(quickBtn)
        quickBtn:setTag(BUTTON_TAG.QUICK_CONSUME_PET_EGGS)
        display.commonLabelParams(quickBtn ,  fontWithColor('10',{w = 150 , hAlign = display.TAC ,  color = "ffffff", text = __('快速填充')}))
    else
        petWareHouseLabel = display.newButton(rightSize.width/2 - 20  , rightSize.height - 28  , { n =  _res('ui/common/common_title_5.png') })
        display.commonLabelParams(petWareHouseLabel, fontWithColor('6' , {text = __('灵体仓库')}))
        rightLayout:addChild(petWareHouseLabel)
        quickBtn = display.newButton(80 ,rightSize.height - 35, { ap = display.CENTER ,  n = _res( "ui/cards/petNew/team_btn_selection_unused.png")} )
        rightLayout:addChild(quickBtn)
        quickBtn:setTag(BUTTON_TAG.QUICK_CONSUME_PET_EGGS)
        display.commonLabelParams(quickBtn ,  fontWithColor('10',{color = "ffffff", text = __('快速填充')}))
    end


    local  batchBtn = display.newButton( rightSize.width - 80 ,rightSize.height - 35, { ap = display.CENTER ,  n = _res( "ui/cards/petNew/team_btn_selection_unused.png")} )
    rightLayout:addChild(batchBtn)
    batchBtn:setTag(BUTTON_TAG.BATCH_CONSUME_PET_EGGS)
    display.commonLabelParams(batchBtn ,  fontWithColor('10',{color = "ffffff", text = __('批量填充')}))


    local petContentSize = cc.size(rightSize.width - 20, rightSize.height - 75 )
    local petContentLayer = display.newLayer(rightSize.width/2 , rightSize.height - 65 ,{ap = display.CENTER_TOP ,size = petContentSize , color1 = cc.r4b()})
    rightLayout:addChild(petContentLayer)
    -- 底贝
    local bgContentImage = display.newImageView(_res('ui/common/common_bg_goods.png'),petContentSize.width/2 , petContentSize.height/2,
        {ap = display.CENTER , scale9 = true , size = petContentSize })
    petContentLayer:addChild(bgContentImage)

    -- 堕神的界面
    local gridViewSize =  cc.size(petContentSize.width- 7  , petContentSize.height   )
    local gridPetLine = display.isFullScreen and 5 or 4
    local petCellSize = cc.size(gridViewSize.width / gridPetLine, gridViewSize.width / gridPetLine)
    local petEggdGridView = CGridView:create(gridViewSize)
    petEggdGridView:setAnchorPoint(display.CENTER)
    petEggdGridView:setPosition(petContentSize.width/2, petContentSize.height/2)
    petEggdGridView:setCountOfCell(0)
    petEggdGridView:setColumns(gridPetLine)
    petEggdGridView:setSizeOfCell(petCellSize)
    petEggdGridView:setAutoRelocate(false)
    petContentLayer:addChild(petEggdGridView)
    petEggdGridView:setCascadeOpacityEnabled(true)
    petContentLayer:setCascadeOpacityEnabled(true)
    progressOne:setCascadeOpacityEnabled(true)
    cleanSmleterBtn:setVisible(false)
    detailLayout:setVisible(false)
    cleanSmleterBtn:setVisible(false)
    progressOne:setVisible(false)
    rightLayout:setVisible(false)
    self.viewData = {
        ----------------------左侧内容的元素--------------------------------
        progressOne        = progressOne,
        progressOneLabel   = progressOneLabel,
        cleanSmleterBtn    = cleanSmleterBtn,
        detailLayout       = detailLayout,
        detailLabel        = detailLabel,
        detailContent      = detailContent,
        petConsumeGridView = petConsumeGridView,
        petConsumeCellSize = petConsumeCellSize,
        leftBottomLayout   = leftBottomLayout,
        smeltingBtn        = smeltingBtn,
        leftBottomLayoutPos= leftBottomLayoutPos,
        tipBtn             = tipBtn,
        leftBgImage        = leftBgImage ,
        leftLayout         = leftLayout ,
        leftPos            = leftPos,
        backPurgeBtn       = backPurgeBtn ,

        ------------------------右侧内容的元素-------------------------------
        rightLayout        = rightLayout,
        quickBtn           = quickBtn,
        batchBtn           = batchBtn,
        petCellSize        = petCellSize,
        petEggdGridView        = petEggdGridView
    }

end


return PetSmeltingView
