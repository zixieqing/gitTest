---
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---

---@class UnionInforDetailView
local UnionInforDetailView = class('home.UnionInforDetailView',function ()
    local node = CLayout:create(cc.size(1139,639)) --cc.size(984,562)
    node.name = 'Game.views.UnionInforDetailView'
    node:enableNodeEvents()
    return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    CHANGE_DECR_TEXT    = 1102, -- 修改工会的签名
    CHANGE_UNION_NAME   = 1103, -- 修改工会名字
    CHANGE_UNION_HEADER = 1104, -- 修改工会的头像
    CHANGE_DECR         = 1105,
    CHANGE_HEAD         = 1109, -- 修改头像
    UNION_TIPS          = 1110, -- 工会的提示按钮
    UNION_QUIT          = 1111, -- 退出工会
    SWITCH_BTN          = 1112,
    UNION_RANKING       = 1113, -- 工会排行
}
function UnionInforDetailView:ctor()
    self:initUI()
end

function UnionInforDetailView:initUI()
    local bgSize =  cc.size(1139,639)
    local bgLayout = display.newLayer(bgSize.width/2 -5  , bgSize.height/2 -5, { ap = display.CENTER , size  = bgSize , color1 = cc.r4b() ,enable = true ,
                                                                           cb = function ()
                                                                               self:removeFromParent()
                                                                           end
    })
    self:addChild(bgLayout)
    local layoutSize = cc.size(1075,578)
    local layout = display.newLayer(bgSize.width/2, 15,
    { ap =  display.CENTER_BOTTOM , size = layoutSize  , color1 = cc.r4b(), enable = true , cb = function ()
        self:removeFromParent()
    end})

    bgLayout:addChild(layout)
    local leftBgImage = display.newImageView(_res('ui/union/guild_establish_information_bg_2'))
    local leftSize = leftBgImage:getContentSize()
    local LeftLayout =  display.newLayer(0 , layoutSize.height/2  ,{ ap =  display.LEFT_CENTER , size = leftSize })

    leftBgImage:setPosition(cc.p(leftSize.width/2 ,leftSize.height/2))
    layout:addChild(leftBgImage)
    layout:addChild(LeftLayout)
    -- 工会ID Label
    local unionIdLabel = display.newLabel(10, leftSize.height -20,  {ap = display.LEFT_CENTER , fontSize  = 20 ,color = '997b7b', text= "好好类型"   })
    LeftLayout:addChild(unionIdLabel )
    -- 头像框的内容
    local headBgImage = display.newImageView(_res('ui/union/guild_head_frame_default'))
    local headBgImageSize = headBgImage:getContentSize()
    local headLayout = display.newLayer(leftSize.width/2 ,leftSize.height - 10,
            {ap  = display.CENTER_TOP , color = cc.c4b(0,0,0,0) , enable = true  ,size =  headBgImageSize})
    local headImage  = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID),
                headBgImageSize.width/2 ,headBgImageSize.height/2)
    --headImage:setScale(0.85)
    headLayout:addChild(headBgImage,2)
    headBgImage:setScale(0.85)
    headImage:setScale(0.85)
    headLayout:addChild(headImage)
    headLayout:setTag(BUTTON_CLICK.CHANGE_HEAD)
    headBgImage:setPosition(cc.p(headBgImageSize.width/2 , headBgImageSize.height/2))
    local changeHeadLabel = display.newLabel(headBgImageSize.width/2 ,  15 , fontWithColor('14' , { text = __('更换') , color   = "#fefade" , outline = "#5b3c25", outlineSize = 1 }) )
    headLayout:addChild(changeHeadLabel,3)
    LeftLayout:addChild(headLayout , 10)
    --- 工会信息的显示

    local unionInfoSize = cc.size(leftSize.width ,160)
    local unionInfoLayout = display.newLayer(unionInfoSize.width/2 ,leftSize.height -  151 , {size = unionInfoSize  ,color1 = cc.r4b(),  ap = display.CENTER_TOP  } )
    LeftLayout:addChild(unionInfoLayout)
    local changeNameSize = cc.size(365, 35)
    
    local changeNameLayout  = display.newLayer(unionInfoSize.width/2 ,unionInfoSize.height - 2 ,
        {ap = display.CENTER_TOP , size = changeNameSize , color  = cc.c4b(0,0,0,0) , enable = true } )
    unionInfoLayout:addChild(changeNameLayout)
    changeNameLayout:setTag(BUTTON_CLICK.CHANGE_UNION_NAME)

    local playerLabelBg =  display.newImageView(_res('ui/home/infor/personal_information_bg_name_bg.png'),
                changeNameSize.width/2 ,changeNameSize.height/2 ,
                { ap = display.CENTER  ,  scale9 = true  ,size = changeNameSize })
    changeNameLayout:addChild(playerLabelBg)

    local changeNameBtn = display.newCheckBox(changeNameSize.width - 17 ,changeNameSize.height/2,
          {
              enable = true ,
              n = _res('ui/home/infor/setup_btn_name_revise.png') ,
              s = _res('ui/home/infor/setup_btn_name_revise.png')
          })
    changeNameLayout:addChild(changeNameBtn)

    local unionNameLabel = display.newRichLabel(changeNameSize.width/2 ,changeNameSize.height /2 , {r = true , c = {
        fontWithColor('10' ,{ ap = display.CENTER ,color = "#a74700" ,fontSize = 26, text = "deeds"})
        } })
    changeNameLayout:addChild(unionNameLabel)


    local widthOffset = 25
    local heightOffset = 5
     --工会数量
    local unionNum = display.newRichLabel( widthOffset , 20 +18 +heightOffset,  { r = true ,   ap = display.LEFT_CENTER , c = {
        fontWithColor('14' ,{   text = __('人气:') ,fontSize = 22 ,  color = "#8f5e39"}) ,
        fontWithColor('6' ,{ text = "1314" })
    }}  )
    unionInfoLayout:addChild(unionNum)


    -- 工会贡献

    local unionContriBution = display.newRichLabel( widthOffset ,52.5 + 15 +heightOffset, {r = true ,   ap = display.LEFT_CENTER , c = {
        fontWithColor('14' ,{   text = __('人气:')  ,fontSize = 22 , color = "#8f5e39"}) ,
        fontWithColor('6' ,{ text = "1314" })
    }}  )
    unionInfoLayout:addChild(unionContriBution)
    -- 工会等级
    local unionLevel = display.newRichLabel( widthOffset ,85 + 12 +heightOffset , { r = true ,   ap = display.LEFT_CENTER , c = {
        fontWithColor('14' ,{   text = __('人气:') ,fontSize = 22 , color = "#8f5e39"}) ,
        fontWithColor('6' ,{ text = "1314" })
    }}  )
    unionInfoLayout:addChild(unionLevel)

    -- 提示显示
    local tipBtn  = display.newButton(leftSize.width -30 , leftSize.height +3  ,  {  ap = display.CENTER_TOP,n = _res('ui/common/common_btn_tips.png')})
    LeftLayout:addChild(tipBtn ,10)
    tipBtn:setTag(BUTTON_CLICK.UNION_TIPS)
    -- 工会介绍
    local unionIntroduce = display.newButton(leftSize.width/2, 270 , { n = _res('ui/common/common_title_5') , enable = false ,scale9 = true  })
    display.commonLabelParams(unionIntroduce ,fontWithColor('16' ,{ fontSize  = 20 , text=  __("工会宣言")    , paddingW = 30 } ))
    LeftLayout:addChild(unionIntroduce)


    local changeSize = cc.size(370,164)
    local changeLayout = display.newLayer( leftSize.width/2,88, { ap = display.CENTER_BOTTOM,size = changeSize})
    LeftLayout:addChild(changeLayout)
    local autographIamge =  display.newImageView(_res('ui/union/guild_declaration_bg.png'),changeSize.width/2 ,  changeSize.height / 2, { ap = display.CENTER  })
    changeLayout:addChild(autographIamge)
    -- 修改按钮
    local changeLabel = display.newLabel(changeSize.width/2,20, {ap  = display.CENTER, fontSize = 20, color = '#7c7c7c',text = __('点击修改')} )
    local changeLabelContent = display.newLayer(changeSize.width/2,changeSize.height/2 , {ap  = display.CENTER,size = changeSize ,
                                                                                          color = cc.c4b(0,0,0,0)
    , enable = true })
    changeLabelContent:setTag(BUTTON_CLICK.CHANGE_DECR)
    changeLayout:addChild(changeLabelContent,10)
    changeLabelContent:addChild(changeLabel)

    -- 叙述按钮
    local decLabel = display.newRichLabel(changeSize.width/2,changeSize.height - 14 ,{ap = display.CENTER_TOP ,  w = 26   ,c = {fontWithColor('6', { text = "" })}})
    changeLabelContent:addChild(decLabel)

    local descrName = ccui.EditBox:create(cc.size(changeSize.width, 160), _res('ui/author/login_bg_Accounts_info.png'))
    display.commonUIParams(descrName, {po = cc.p(changeSize.width/2, changeSize.height * 0.5)})
    changeLayout:addChild(descrName)
    descrName:setFontSize(fontWithColor('M2PX').fontSize)
    descrName:setFontColor(ccc3FromInt('#9f9f9f'))
    descrName:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    descrName:setPlaceHolder(__('请输入'))
    descrName:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
    descrName:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
    descrName:setVisible(false)
    descrName:setMaxLength(100)
    descrName:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    descrName:setTag(BUTTON_CLICK.CHANGE_DECR_TEXT)

    -- 退出工会的按钮
    local unionExit = display.newButton(leftSize.width/2 + 100    ,37.5 + 5 ,{
        n = _res('ui/common/common_btn_white_default.png'),ap = display.CENTER ,fontSize = 22 , scale9 = true
    })
    display.commonLabelParams(unionExit , fontWithColor('14' ,{text =__('退出工会') , paddingW = 20   }))
    LeftLayout:addChild(unionExit)
    unionExit:setTag(BUTTON_CLICK.UNION_QUIT)
    local unionRanking = display.newButton(leftSize.width/2 -100   ,37.5 + 5,{
        n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER,fontSize = 22
    })
    display.commonLabelParams(unionRanking , fontWithColor('14' ,{text =__('工会排行'),reqW = 110 , w = 140  , hAlign = display.TAC}))
    LeftLayout:addChild(unionRanking)
    unionRanking:setTag(BUTTON_CLICK.UNION_RANKING)


    -- 右侧的内容
    local rightSize = cc.size(677,leftSize.height)
    local rightLayout = display.newLayer(layoutSize.width, layoutSize.height/2,
                                    { ap =  display.RIGHT_CENTER , size = rightSize  , color1 = cc.r4b(), enable = true })
    layout:addChild(rightLayout)
    -- 右侧顶部的Layout
    local topRightImage  = display.newImageView(_res('ui/union/guild_establish_information_title'))
    local topRightImageSize = topRightImage:getContentSize()
    local topRightLayout = display.newLayer(rightSize.width/2 , rightSize.height , { ap = display.CENTER_TOP,color1 = cc.r4b() , size =topRightImageSize  })
    topRightLayout:addChild(topRightImage)
    topRightImage:setPosition(cc.p(topRightImageSize.width/2 , topRightImageSize.height/2))
    rightLayout:addChild(topRightLayout,2)

    local unionPlayerLabel = display.newLabel(50 ,  topRightImageSize.height/2 ,
             fontWithColor('16' , {ap = display.LEFT_CENTER , text = __('御侍成员') , w = 160, hAlign = display.TAC }) )
    topRightLayout:addChild(unionPlayerLabel)

    local switchLabel =  display.newLabel(topRightImageSize.width -265 ,  topRightImageSize.height/2 ,
                                          fontWithColor('16' , {ap = display.RIGHT_CENTER, text = __('贡献值') , w = 160 , hAlign = display.TAC   }) )
    topRightLayout:addChild(switchLabel)

    local switchBtn = display.newButton(topRightImageSize.width -265, topRightImageSize.height/2 ,
                    { ap = display.LEFT_CENTER ,  n = _res('ui/union/guild_btn_switch')})
    topRightLayout:addChild(switchBtn)
    switchBtn:setTag(BUTTON_CLICK.SWITCH_BTN)
    -- 登录状态
    local loginStatus = display.newLabel(topRightImageSize.width - 75 ,  topRightImageSize.height/2 + 12 ,
        fontWithColor('16' , {ap = display.CENTER , text = __('登录状态')   , reqW = 140}) )
    topRightLayout:addChild(loginStatus)

    local onLineNum =  display.newLabel(topRightImageSize.width - 75 ,  topRightImageSize.height/2 - 12 ,
                                        fontWithColor('16' , {ap = display.CENTER , text = ""  }) )
    topRightLayout:addChild(onLineNum)

    --右侧下面的内容
    local rightBottomSize = cc.size(rightSize.width ,rightSize.height -topRightImageSize.height )
    local rightBottomLayout = display.newLayer(rightSize.width/2 ,rightSize.height -topRightImageSize.height ,
                                               {ap = display.CENTER_TOP , size = rightBottomSize , color1 = cc.r4b()})
    rightLayout:addChild(rightBottomLayout)

    local bgImage  = display.newImageView(_res('ui/union/guild_establish_information_search_list_bg') ,
          rightBottomSize.width/2 ,rightBottomSize.height/2 + 3 , { ap  = display.CENTER , scale9 = true , size = rightBottomSize} )
    rightBottomLayout:addChild(bgImage)


    local grideSize = rightBottomSize
    local gridView = CGridView:create(cc.size(grideSize.width , grideSize.height -5) )
    gridView:setSizeOfCell(cc.size(670,105))
    gridView:setColumns(1)
    rightBottomLayout:addChild(gridView)
    gridView:setAnchorPoint(cc.p(0.5, 0.5))
    gridView:setPosition(cc.p(grideSize.width/2 + 4, grideSize.height/2 +5 ))
    self.viewData = {
        LeftLayout         = LeftLayout,
        unionNameLabel     = unionNameLabel,
        changeNameBtn      = changeNameBtn,
        unionLevel         = unionLevel,
        unionContriBution  = unionContriBution,
        changeLabel        = changeLabel,
        changeLabelContent = changeLabelContent,
        descrName          = descrName,
        decLabel           = decLabel,
        unionExit          = unionExit,
        unionRanking       = unionRanking,
        unionNum           = unionNum,
        changeLayout       = changeLayout,
        unionPlayerLabel   = unionPlayerLabel,
        gridView           = gridView,
        tipBtn             = tipBtn,
        headLayout         = headLayout,
        changeNameLayout   = changeNameLayout,
        switchBtn          = switchBtn,
        unionIdLabel       = unionIdLabel,
        onLineNum          = onLineNum,
        changeHeadLabel    = changeHeadLabel,
        headImage          = headImage ,
        switchLabel        = switchLabel
    }
end
function UnionInforDetailView:ActivityTabDataSource(pcell , index)
    if not  pcell then
        pcell = self:CreateGridCell()
    end
    return pcell
end
function UnionInforDetailView:CreateGridCell()
    local gridCell = CGridViewCell:new()
    local bgImage = display.newImageView(_res('ui/union/guild_member_bg'))
    local bgSize = bgImage:getContentSize()
    gridCell:setContentSize(bgSize)

    local bgLayout =  display.newLayer(bgSize.width/2 , bgSize.height/2, {size= bgSize , ap = display.CENTER , enable = true , color = cc.c4b( 0,0,0,0) })
    gridCell:addChild(bgLayout)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    bgLayout:addChild(bgImage)

    local headerNode = require('root.CCHeaderNode').new(
            {bg = _res('ui/home/infor/setup_head_bg_2.png') , pre =  gameMgr:GetUserInfo().avatarFrame , isPre = true })
    display.commonUIParams(headerNode,{po = cc.p(10 ,bgSize.height/2), ap = display.LEFT_CENTER})
    bgLayout:addChild(headerNode)
    headerNode:setScale(0.6)
    -- 玩家名称
    local playerName = display.newLabel( 110 ,  bgSize.height/2 + 30 ,
            fontWithColor('16' , {ap = display.LEFT_CENTER ,text = __('登录状态')  }) )
    bgLayout:addChild(playerName)
    -- 玩家等级
    local playerLevel = display.newLabel(110 ,  bgSize.height/2 ,
         fontWithColor('16' , {ap = display.LEFT_CENTER , text = __('登录状态')  }) )
    bgLayout:addChild(playerLevel)
    -- 玩家职业
    local playerJob = display.newLabel(110 ,  bgSize.height/2  - 30 ,
         fontWithColor('16' , {ap = display.LEFT_CENTER , fontSize = 22,  color = "#a94007", text = __('登录状态')  }) )
    bgLayout:addChild(playerJob)
    -- 贡献值
    local contributionTitle = display.newLabel(365 + 40 ,  bgSize.height/2  ,
                                       fontWithColor('16' , {ap = display.CENTER , text = 1500000  }) )
    bgLayout:addChild(contributionTitle)
    -- 贡献值
    local isOnlineLable = display.newLabel(bgSize.width -  70 ,  bgSize.height/2 ,
                                               fontWithColor('16' , {ap = display.CENTER , text = 1500000  }) )
    bgLayout:addChild(isOnlineLable)
    gridCell.playerName        = playerName
    gridCell.playerLevel       = playerLevel
    gridCell.playerJob         = playerJob
    gridCell.contributionTitle = contributionTitle
    gridCell.isOnlineLable     = isOnlineLable
    gridCell.headerNode        = headerNode
    gridCell.bgLayout          = bgLayout
    gridCell.bgImage           = bgImage
    return gridCell
end

return UnionInforDetailView
