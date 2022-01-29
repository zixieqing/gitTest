local BossDetailView = class('BossDetailView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.BossDetailView'
	node:enableNodeEvents()
	return node
end)

--local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
--local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
--local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

function BossDetailView:ctor()
    self:InitUI()
end
-- 初始化UI
function BossDetailView:InitUI()

    -- 吞噬层
    local swallowLayer = display.newLayer(0,0,{ size = display.size , color = cc.c4b(0,0,0,180), enable = true ,cb = function (  )
       AppFacade.GetInstance():UnRegsitMediator("BossDetailMediator")
    end})
    self:addChild(swallowLayer)
    -- 创建boss 的image
    local bossImage = require('common.CardSkinDrawNode').new({confId = 200013, coordinateType = COORDINATE_TYPE_HOME})
    bossImage:setPositionX(display.SAFE_L)
    bossImage:setVisible(false)
    self:addChild(bossImage)
    -- 创建image 的详情列表
    local detailImageBg  = display.newImageView(_res("ui/bossdetail/bosspokedex_bg.png"))
    local rightLayoutSize = detailImageBg:getContentSize()
    local rightLayout = CLayout:create(rightLayoutSize)
    rightLayout:setVisible(false)
    rightLayout:setPosition(cc.p(display.cx/2*3,display.cy))
    detailImageBg:setPosition(cc.p(rightLayoutSize.width/2, rightLayoutSize.height/2))
    rightLayout:addChild(detailImageBg)
    self:addChild(rightLayout)
    local listSize = cc.size(555,655)
    local bossIntroduceList = CListView:create(listSize)
    bossIntroduceList:setDirection(eScrollViewDirectionVertical)
    bossIntroduceList:setAnchorPoint(cc.p(0.5, 0.5))
    bossIntroduceList:setPosition(cc.p(rightLayoutSize.width/2, rightLayoutSize.height/2))
    rightLayout:addChild(bossIntroduceList)

    local bgSize = cc.size(display.width, 80)
    local moneyNode = CLayout:create(bgSize)
    display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    self:addChild(moneyNode,100)
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, bgSize.height - 18 - backBtn:getContentSize().height * 0.5)})
    moneyNode:addChild(backBtn, 5)

    self.viewData =  {
        bossImage = bossImage ,
        bossIntroduceList = bossIntroduceList ,
        rightLayout = rightLayout ,
        navBackButton  = backBtn
    }
end
--==============================--
--desc:用于创建boss 的详情介绍
--time:2017-07-05 04:01:55
--@return
--==============================--
function BossDetailView:CreateBossDetailCell()
    local bossSize = cc.size(555,170)
    local bossLayout = CLayout:create(bossSize)
    bossLayout:setAnchorPoint(display.CENTER_TOP)
    local bossTitile = display.newButton(bossSize.width/2,bossSize.height -20,{ n = _res('ui/bossdetail/bosspokedex_name_bg.png') , d  = _res('ui/bossdetail/bosspokedex_name_bg.png'),enable = false})
    -- boss 的名字介绍
    bossLayout:addChild(bossTitile)
    display.commonLabelParams(bossTitile,fontWithColor('14' , { text = 30 , color = "#ffffff" ,text = ""} ) )
    local offsetW = 175
    local  threatStarLabel  = display.newLabel(offsetW,bossSize.height -70 ,fontWithColor('3',{reqW = 170 ,  ap = display.RIGHT_CENTER,text = __('威胁指数:') }) )
    -- 怪物危险技术介绍
    bossLayout:addChild(threatStarLabel)
    local distance = 40
    local starLayoutSize = cc.size(distance*5,distance)
    -- 星级展示
    local starLayout = CLayout:create(starLayoutSize)
    starLayout:setAnchorPoint(display.LEFT_CENTER)
    local starTable = {} -- 星级的table收集
    for i =1 , 5 do
        local star = display.newImageView(_res('ui/common/common_star_grey_l_ico.png'),distance*(i -0.5),distance/2)
        table.insert( starTable,#starTable+1,star )
        starLayout:addChild(star)
    end
    starLayout:setPosition(cc.p(offsetW , bossSize.height -70 ))
    bossLayout:addChild(starLayout)
    local bossInforLabel = display.newLabel(offsetW,bossSize.height - 110,fontWithColor("3" , {reqW = 170 ,  ap = display.RIGHT_CENTER, text = __('怪物情报:')}))
    bossLayout:addChild(bossInforLabel)
    local bossInfoeSpecialLabel = display.newLabel(offsetW,bossSize.height - 100,{ap = display.LEFT_TOP,fontSize = 22 , color = "ffc66c" , w = 365 })
    -- boss 的特点介绍
    bossLayout:addChild(bossInfoeSpecialLabel)
    local bossIntroduceSize =cc.size(555,140)
    local bossIntroduceLayout =  display.newLayer(550,140,{size = bossIntroduceSize ,  ap = display.CENTER_TOP })
    bossIntroduceLayout:setAnchorPoint(display.CENTER_TOP)
    local bossIntroduceImage = display.newImageView(_res('ui/bossdetail/bosspokedex_boss_bg_words.png'), bossIntroduceSize.width/2, bossIntroduceSize.height /2 , {  scale9 = true , ap = display.CENTER})
    bossIntroduceLayout:addChild(bossIntroduceImage)
    local bossIntroduceImageSize = bossIntroduceImage:getContentSize()

    local bossInforIntroduecLabel = display.newLabel(40,bossIntroduceImageSize.height - 10,{fontSize = 22 ,color = "#cebba4", ap = display.LEFT_TOP, text = "" ,w = bossIntroduceImageSize.width - 80})
    -- boss 的怪物详情介绍
    bossIntroduceImage:addChild(bossInforIntroduecLabel)
    local cellSize = cc.size(550, 310)
    local celllayout = CLayout:create(cellSize)
    celllayout:addChild(bossLayout)
    celllayout:addChild(bossIntroduceLayout)
    bossLayout:setPosition(cc.p(cellSize.width/2 , cellSize.height))
    bossIntroduceLayout:setPosition(cc.p(cellSize.width/2 , cellSize.height-170))
    celllayout.viewData  = {
        bossTitile = bossTitile ,
        starTable = starTable ,
        bossInfoeSpecialLabel = bossInfoeSpecialLabel ,
        bossInforIntroduecLabel = bossInforIntroduecLabel ,
        bossIntroduceImage = bossIntroduceImage ,
        bossLayout = bossLayout ,
        bossIntroduceLayout = bossIntroduceLayout ,
        celllayout = celllayout
    }
    return  {
        bossTitile = bossTitile ,
        starTable = starTable ,
        bossInfoeSpecialLabel = bossInfoeSpecialLabel ,
        bossInforIntroduecLabel = bossInforIntroduecLabel ,
        bossIntroduceImage = bossIntroduceImage ,
        bossLayout = bossLayout ,
        bossIntroduceLayout = bossIntroduceLayout ,
        celllayout = celllayout
    }
end
--==============================--
--desc:用于常见boss的技能介绍
--time:2017-07-05 04:02:31
--@return
--==============================--
function BossDetailView:CreateBossSkillCell()
    local skillSize = cc.size(555,210)
    local skillLayout = display.newLayer(skillSize.width/2,skillSize.height,{ ap = display.CENTER_TOP , size = skillSize})
    local skillImageBg = display.newImageView(_res("ui/bossdetail/bosspokedex_titile_skill.png"),skillSize.width/2,skillSize.height,{ap  = display.CENTER_TOP})
    skillLayout:addChild(skillImageBg,2)
    local skillImageBgSize = skillImageBg:getContentSize()
    -- 技能名称
    local skillName = display.newLabel(40,skillImageBgSize.height/2, fontWithColor('3',{ text = "" ,ap = display.LEFT_CENTER} ))
    skillImageBg:addChild(skillName)
    -- 技能作用介绍
    local skillIntroduceBg = display.newImageView(_res('ui/bossdetail/bosspokedex_skill_bg_words.png'),skillSize.width/2,skillSize.height -skillImageBgSize.height +3 ,{ scale9 = true ,  ap = display.CENTER_TOP})
    skillLayout:addChild(skillIntroduceBg)
    local skillIntroduceBgSize = skillIntroduceBg:getContentSize()
    local skillIntroduceLabel = display.newLabel(40,skillIntroduceBgSize.height -10,fontWithColor('16', { ap = display.LEFT_TOP , w = skillIntroduceBgSize.width -80 ,text = "" }))
    skillLayout:addChild(skillIntroduceLabel)
    local cellLayout =display.newLayer(0,0, { size = skillSize})
    cellLayout:addChild(skillLayout)
    cellLayout.viewData = {
        skillName = skillName ,
        skillIntroduceLabel = skillIntroduceLabel ,
        cellLayout = cellLayout ,
        skillLayout = skillLayout ,
        skillIntroduceBg = skillIntroduceBg,

    }
    return {
        skillName = skillName ,
        skillIntroduceLabel = skillIntroduceLabel ,
        cellLayout = cellLayout ,
        skillLayout = skillLayout ,
        skillIntroduceBg = skillIntroduceBg
    }
end

--==============================--
--desc:用于更新boss 的详情cell
--time:2017-07-05 04:03:31
--viewData cell里面需更新的项
--data  怪物的详细描述
--@return
--==============================--
function BossDetailView:UpdateBossDetailCell(viewData,data)
    local  bossName = data.name  -- boss  名称
    local  threatStar = checkint(data.star)    or  1 -- 星级数
    local  bossSpecial = data.feature or "" -- boss 特点
    local  bossIntroduce = data.descr or "" -- boss 的介绍
    for i = 1 , 5 do  -- 重置原始的星级显示
        viewData.starTable[i]:setTexture(_res('ui/common/common_star_grey_l_ico.png'))
    end
    for i =1 ,threatStar do
        viewData.starTable[i]:setTexture(_res('ui/common/common_star_l_ico.png'))
    end
    viewData.bossTitile:getLabel():setString(bossName)
    --viewData.bossInfoeSpecialLabel:setString(bossSpecial)
    display.commonLabelParams(viewData.bossInfoeSpecialLabel ,{text = bossSpecial} )
    viewData.bossInforIntroduecLabel:setString(bossIntroduce)
    local labelSize = display.getLabelContentSize(viewData.bossInforIntroduecLabel)
    local bossIntroduceImageSize  =  viewData.bossIntroduceImage:getContentSize()
    if labelSize.height+20 > bossIntroduceImageSize.height  then
        bossIntroduceImageSize = cc.size(544 , labelSize.height+20)
        viewData.bossIntroduceImage:setContentSize( bossIntroduceImageSize)
        viewData.bossInforIntroduecLabel:setPosition(40,bossIntroduceImageSize.height - 10)
        viewData.bossIntroduceLayout:setContentSize( cc.size(550 , bossIntroduceImageSize.height+20 ) )
        viewData.bossIntroduceImage:setPositionY(bossIntroduceImageSize.height/2+10)
        local cellSize = cc.size(550 , bossIntroduceImageSize.height+20+170 )
        viewData.celllayout:setContentSize(cellSize)
        viewData.bossLayout:setPositionY(cellSize.height)
        viewData.bossIntroduceLayout:setPositionY(cellSize.height-170)
    end

end
--==============================--
--desc: 用于更新boss 的详情介绍
--time:2017-07-05 04:04:45
--@args:
--viewData cell里面需更新的项
--data  技能数据
--@return
--==============================--
function BossDetailView:UpdateeBossSkillCell(viewData, data)
    local skillName = data.name or  "" --技能名称
    local skillDescr =  data.descr or  "" -- 技能描述

    viewData.skillName:setString(skillName)
    viewData.skillIntroduceLabel:setString(skillDescr)
    local skillIntroduceLabelSize = display.getLabelContentSize(viewData.skillIntroduceLabel)
    if skillIntroduceLabelSize.height > 130  then
        local skillIntroduceBgSize =   viewData.skillIntroduceBg:getContentSize()
        local distance = skillIntroduceBgSize.height - 20 - skillIntroduceLabelSize.height
        local height  = distance > 0 and skillIntroduceBgSize.height or (math.abs(distance ) + skillIntroduceBgSize.height)
        viewData.skillIntroduceBg:setContentSize(cc.size(skillIntroduceBgSize.width , height+10 )  )
        viewData.skillIntroduceBg:setCapInsets(cc.rect(2,2 , skillIntroduceBgSize.width/2 -1, height/2-1)  )
        local cellLayoutSize =  viewData.cellLayout:getContentSize()
        viewData.cellLayout:setContentSize(cc.size(cellLayoutSize.width ,math.abs(distance ) + cellLayoutSize.height  +10)  )
        cellLayoutSize = viewData.cellLayout:getContentSize()
        viewData.skillLayout:setPosition(cc.p(cellLayoutSize.width/2 , cellLayoutSize.height-10))
    end

end
--==============================--
--desc:创建boss头像的集合
--time:2017-07-06 11:15:20
--@Num:表示当前关卡具有怪物数量的多少
--@return
--==============================--
function BossDetailView:createBossHeadlayout(Num)
    local headSize = cc.size(155,155)
    local bossLayoutSize =cc.size(headSize.width,headSize.height * Num)
    local bossCollectLayout = CLayout:create(bossLayoutSize)
    local swallowLayer = display.newLayer(bossLayoutSize.width/2,bossLayoutSize.height/2,{ap =display.CENTER ,color = cc.c4b(0,0,0,0),enable = true , size = bossLayoutSize})
    bossCollectLayout:addChild(swallowLayer)
    local headTable  = {}
    for i =Num , 1 , -1 do
        local headData= self:createBossHead()
        table.insert( headTable, #headTable+1, headData )
        headData.bgLayout:setPosition(cc.p(headSize.width/2 , headSize.height*(i -0.5)))
        bossCollectLayout:addChild(headData.bgLayout)
    end
    return{
        headTable =  headTable ,
        bossCollectLayout = bossCollectLayout ,

    }

end
--==============================--
--desc:割取一个boss 的头像框
--time:2017-07-05 08:17:59
--@return
--==============================--
function BossDetailView:createBossHead()

    local outLineBorder  = display.newImageView(_res('ui/bossdetail/bosspokedex_boss_head_2.png'))
    local outSize = outLineBorder:getContentSize()
    local layoutCenterPos = cc.p(outSize.width/2, outSize.height/2)
    outLineBorder:setPosition(layoutCenterPos)
    -- 外边的边框
    local bgLayout = CLayout:create(outSize)
    bgLayout:addChild(outLineBorder,3)
    -- 点击选择的按钮

    local bottomImage  = display.newImageView(_res('ui/bossdetail/bosspokedex_boss_head_3'))
    local bottomSize = bottomImage:getContentSize()
    bottomImage:setPosition(layoutCenterPos)
    bgLayout:addChild(bottomImage,-1)
    local headButton = display.newCheckBox(outSize.width/2,outSize.height/2,{ n = _res('ui/bossdetail/bosspokedex_boss_head_1.png') , s =_res('ui/bossdetail/bosspokedex_boss_head_1.png') })
    bgLayout:addChild(headButton,1)
    local heaButtonTop  = display.newImageView( _res('ui/bossdetail/bosspokedex_boss_head_light.png') ,outSize.width/2+6,outSize.height/2)
    bgLayout:addChild(heaButtonTop,2)
    heaButtonTop:setName("heaButtonTop")
    heaButtonTop:setVisible(false)
    -- 获取底部图片的大小
    local headImage = display.newImageView(CardUtils.GetCardHeadPathByCardId(300024))
    local headSize = headImage:getContentSize()
    local scale = bottomSize.width / headSize.width
    headImage:setScale(scale)
    headImage:setPosition(cc.p(bottomSize.width/2,bottomSize.height/2))
    local clippingNode = cc.ClippingNode:create()
    clippingNode:setContentSize(bottomSize)
    clippingNode:setPosition(layoutCenterPos)
    clippingNode:setAnchorPoint(display.CENTER)
    clippingNode:addChild(headImage)
    local  stencilNode  = display.newImageView(_res('ui/bossdetail/bosspokedex_boss_head_3'))
    clippingNode:setStencil(stencilNode)
    clippingNode:setAlphaThreshold(0.05)
    clippingNode:setInverted(false)
    stencilNode:setPosition(cc.p(outSize.width/2,outSize.height/2))
    stencilNode:setAnchorPoint(display.CENTER)
    bgLayout:addChild(clippingNode,3)
    return {
        bgLayout = bgLayout ,
        headButton = headButton ,
        headImage = headImage ,
        heaButtonTop = heaButtonTop
    }
end

return  BossDetailView
