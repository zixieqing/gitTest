local GameScene = require('Frame.GameScene')
-- local BossStoryView = class('home.BossStoryView',function ()
--     local node = CLayout:create(display.size)
--     node.name = 'Game.views.BossStoryView'
--     node:enableNodeEvents()
--     return node
-- end)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BossStoryView = class('BossStoryView', GameScene)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local RES_DICT = {
    KINDS_BTN_NORMAL = _res( 'ui/home/handbook/pokedex_monster_tab_default.png'),
    KINDS_BTN_SELECT = _res( 'ui/home/handbook/pokedex_monster_tab_select.png'),
    BOSS_BG_IMAGE = _res('ui/home/handbook/pokedex_monster_bg.jpg'),
    BOSS_LIST_IMAGE =  _res('ui/home/handbook/pokedex_monster_list_bg.png'),

}
local SELECT_BTNCHECK = {
    BOSS_TYPECASE = 4,  -- 特型
    BOSS_DISSMAILATION = 3 , -- 异化
    BOSS_COMMON = 2 ,  -- 普通
    BOSS_ASSICAST = 1   -- 伴生
}
function BossStoryView:ctor()
    self.super.ctor(self,'views.BossStoryView')

    -- bg image
    local bgImage = display.newImageView(RES_DICT.BOSS_BG_IMAGE, display.cx, display.cy, {isFull = true})
    self:addChild(bgImage)

    -- title bar
    local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1)})
    display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('堕神物语'),   fontSize = 30, color = '473227',offset = cc.p(0,-8)})
    if  display.getLabelContentSize(tabNameLabel:getLabel()).width > 250 then
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('堕神物语'),  reqH = 45,hAlign = display.TAC , fontSize = 20,  w = 250, color = '473227',offset = cc.p(0,0)})
    end
    self:addChild(tabNameLabel,10)

    -------------------------------------------------
    -- 下面的范围
    local bottomSize = cc.size(display.width , display.height/2  - 353)
    local bottomLayout = display.newLayer(display.cx, 0, {ap = display.CENTER_BOTTOM, size = bottomSize})
    self:addChild(bottomLayout,2)

    -------------------------------------------------
    --中部的范围
    local middleSize = cc.size(display.SAFE_RECT.width, 625)
    local middleLayout = CLayout:create(middleSize)
    middleLayout:setAnchorPoint(display.CENTER_BOTTOM)
    middleLayout:setPosition(cc.p(display.cx, bottomSize.height))
    self:addChild(middleLayout,2)

    -- list bg image
    local bgImageList = display.newImageView(RES_DICT.BOSS_LIST_IMAGE, middleSize.width/2, middleSize.height/2, {scale9 = true, size = cc.size(display.width, 632)})
    middleLayout:addChild(bgImageList)

    -------------------------------------------------
    -- 顶部的范围
    local topSize = cc.size(display.width, display.height/2 - 272)
    local topLayout = display.newLayer(0, 0, {size = topSize, ap = display.CENTER_BOTTOM})
    topLayout:setPosition(cc.p(display.cx, bottomSize.height + middleSize.height))
    self:addChild(topLayout,100)

    -- 创建bottonLayout 的部分
    local bottonSize = cc.size(175,85)
    local bottonLayoutSize = cc.size(bottonSize.width* 4 ,bottonSize.height)
    local bottonLayout = display.newLayer(0, 0, {size  = bottonLayoutSize})
    bottonLayout:setAnchorPoint(display.LEFT_BOTTOM)
    bottonLayout:setPosition(cc.p(topSize.width - bottonLayoutSize.width - display.SAFE_L , -3) )
    topLayout:addChild(bottonLayout)

    -- tab btn list
    local kindsBoss =  {
        { __('伴生') ,"0/10" ,SELECT_BTNCHECK.BOSS_ASSICAST },
        { __('普通') ,"0/10",SELECT_BTNCHECK.BOSS_COMMON},
        { __('异化') ,"0/10", SELECT_BTNCHECK.BOSS_DISSMAILATION},
        { __('特型') ,"0/10",SELECT_BTNCHECK.BOSS_TYPECASE}
    }
    local checkButtons = {}
    for i =1 ,  #kindsBoss do
        local checkBtned = display.newButton((i -0.5) *bottonSize.width, bottonLayoutSize.height/2,{n = RES_DICT.KINDS_BTN_NORMAL , s = RES_DICT.KINDS_BTN_SELECT,enable = true})
        -- 这个是选中的btn按钮
        local bossKindsName = display.newLabel(bottonSize.width/2-10,bottonSize.height /2 + 15,fontWithColor('6',{ fontSize = 20,reqW = 110, color = '#ffc52a' ,text = kindsBoss[i][1] , outline ="#4f2212"}) )
        local prograssName = display.newLabel(0,0 , {text = "" , fontSize = 22 , color = "#ffffff" , ap = display.LEFT_CENTER})
        local collectLabel = display.newLabel(0,0 , {text =  __('收集') .. "  " , fontSize = 22 , color = "#f4d8a7" , ap = display.LEFT_CENTER})
        local prograssNameLayout = display.newLayer(bottonSize.width/2 -10, bottonSize.height/2 - 27 ,{size = cc.size( 20, 100) ,ap = display.CENTER_BOTTOM})
        prograssNameLayout:addChild(collectLabel)
        prograssNameLayout:addChild(prograssName)
        -- 收集boss 的进度
        checkBtned:addChild(bossKindsName)
        checkBtned:addChild(prograssNameLayout)
        checkBtned.bossKindsName = bossKindsName
        checkBtned.prograssName = prograssName
        checkBtned.collectLabel = collectLabel
        checkBtned.prograssNameLayout = prograssNameLayout
        checkBtned:setTag(kindsBoss[i][3])
        bottonLayout:addChild(checkBtned)
        checkButtons[tostring(kindsBoss[i][3])] = checkBtned
    end

    -------------------------------------------------
    local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
    tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
    tabNameLabel:runAction( action )

    self.viewData = {
        middleLayout = middleLayout ,
        topLayout = topLayout ,
        bottomLayout = bottomLayout ,
        bottonLayout = bottonLayout ,
        navBack = backBtn ,
        checkButtons = checkButtons
    }
end
--==============================--
--desc:更改button 的显示
--time:2017-07-19 03:41:47
--@return
--==============================--
function BossStoryView:UpdateButtonDisplay(data , allData)
    local contentSize = nil
    local prograssNameSize = nil
    local collectLabelSize = nil
    for k , v in pairs(self.viewData.checkButtons) do
        local tag = v:getTag()
        --检测已经拥有的数量
        local count = 0
        allData[tostring(tag)] = allData[tostring(tag)] or {}
        for kkk , vvv in pairs(allData[tostring(tag)]) do
            if checkint( vvv.status) == 3   or (tag  == SELECT_BTNCHECK.BOSS_ASSICAST and checkint(vvv.status) >1) then
                count = count +1
            end
        end
        v.prograssName:setString(string.format( "%s/%s",count , table.nums(allData[tostring(tag)])))
        prograssNameSize = display.getLabelContentSize(v.prograssName)
        collectLabelSize = display.getLabelContentSize(v.collectLabel)
        contentSize = cc.size(prograssNameSize.width + collectLabelSize.width , collectLabelSize.height)
        v.prograssNameLayout:setContentSize(contentSize)
        if contentSize.width > 130 then
            v.prograssNameLayout:setScale(130/contentSize.width)
        end
        v.collectLabel:setPosition(0,contentSize.height/2)
        v.prograssName:setPosition(cc.p(collectLabelSize.width , contentSize.height/2 ))
    end
end
--==============================--
--desc:创建精英和异化的界面
--time:2017-07-17 02:26:33
--@return
--==============================--
function BossStoryView:CreateBossTypecaseAndMailAtion(type)
    local middleSize = self.viewData.middleLayout:getContentSize()
    local gridView = CTableView:create(middleSize)
    gridView:setSizeOfCell(middleSize)
    gridView:setAutoRelocate(true)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setCountOfCell(0)
    gridView:setSizeOfCell(cc.size(195,625))
    gridView:setAnchorPoint(cc.p(0.5, 0.5))
    gridView:setPosition(cc.p(middleSize.width/2, middleSize.height/2))
    gridView:setTag(type)
    return gridView
end
-- 普通怪的介绍
function BossStoryView:CommonBossIntroduce()

end
-- 伴生怪的介绍
function BossStoryView:AssociatedIntroduce()
    local introduceImage  =  display.newImageView(_res("ui/home/handbook/pokedex_monster_bg_summary.png"))
    local introduceImageSize = introduceImage:getContentSize()
    local introduceSize = cc.size(introduceImageSize.width ,625)
    local introduceLayout = display.newLayer(0, 0, {size = introduceSize})
    local contentLayout = display.newLayer(introduceSize.width/2 - 408, introduceSize.height/2, {size = introduceImageSize ,ap = display.CENTER })
    introduceImage:setPosition(cc.p(introduceImageSize.width/2   , introduceImageSize.height/2))
    contentLayout:addChild(introduceImage)
    introduceLayout:addChild(contentLayout)
    introduceLayout:setName("introduceLayout")
    introduceImage:setCascadeOpacityEnabled(true)
    introduceLayout:setCascadeOpacityEnabled(true)
    contentLayout:setCascadeOpacityEnabled(true)
    -- 头标题
    local titleLabel = display.newLabel(introduceImageSize.width/2, introduceImageSize.height - 36, fontWithColor(14, { text = __('简介') , color = "5b3c25" , outline  = false}) )
    contentLayout:addChild(titleLabel)
    titleLabel:setCascadeOpacityEnabled(true)
    local titleImage = display.newImageView(_res("ui/home/handbook/monthcard_tool_split_line.png"), introduceImageSize.width/2, introduceImageSize.height - 68 , { ap = display.CENTER})
    contentLayout:addChild(titleImage)
    titleImage:setCascadeOpacityEnabled(true)
    -- 怪物介绍Label introduceLabel
    local introduceLabel = display.newLabel(introduceImageSize.width/2, introduceImageSize.height - 90,fontWithColor('6', { ap = display.CENTER_TOP , w = 310 , hAligh = display.TAL ,text  = ""}) )
    contentLayout:addChild(introduceLabel)
    introduceLabel:setCascadeOpacityEnabled(true)
    introduceLayout.viewData =  {
        contentLayout = contentLayout ,
        introduceLayout = introduceLayout ,
        introduceLabel = introduceLabel ,
        introduceImage = introduceImage,
        titleLabel = titleLabel,
        titleImage = titleImage
    }
    introduceLayout:setLocalZOrder(-1)
    return introduceLayout
end

function BossStoryView:CreateAssociateView()
    local bgSize =cc.size(display.SAFE_RECT.width,625)
    local bgLayout  = display.newLayer(display.SAFE_L, 0, {size = bgSize, ap = display.CENTER })
    local associateList = CListView:create(bgSize)
    associateList:setDirection(eScrollViewDirectionHorizontal)
    associateList:setBounceable(true)
    associateList:setAnchorPoint(display.LEFT_CENTER)
    associateList:setPosition(cc.p(0 , bgSize.height/2))
    associateList:setCascadeOpacityEnabled(true)
    bgLayout:addChild(associateList)
    bgLayout.viewData =  {
        bgLayout = bgLayout ,
        associateList = associateList ,

    }
    return bgLayout
end

function BossStoryView:CreateBossCommonView()
    --物品种类的背景图片
    local bgSize =cc.size(display.SAFE_RECT.width,625)
    local bgLayout = display.newLayer(0, 0, {size = bgSize, ap = display.CENTER })
    local kindBgListImage = display.newImageView(_res("ui/home/handbook/pokedex_monster_tab_bg.png"))
    local kindbgListSize = kindBgListImage:getContentSize()
    local kindBgLayout = display.newLayer(0, bgSize.height/2, {size = kindbgListSize, ap = display.LEFT_CENTER})

    kindBgListImage:setPosition(cc.p(kindbgListSize.width/2 , kindbgListSize.height/2))
    kindBgLayout:addChild(kindBgListImage)

    bgLayout:addChild(kindBgLayout)
    local upImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_img_up.png'), kindbgListSize.width/2 ,kindbgListSize.height , { ap = display.CENTER_TOP})
    kindBgLayout:addChild(upImage)

    local downImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_img_down.png'), kindbgListSize.width/2 ,0 , { ap = display.CENTER_BOTTOM})
    kindBgLayout:addChild(downImage)



    -- 背景的size
    -- 左边的种类选择
    local  listSize = cc.size(kindbgListSize.width , kindbgListSize.height -30)
    local  kindsList = CListView:create(listSize)
    kindsList:setDirection(eScrollViewDirectionVertical)
    kindsList:setBounceable(true)
    kindsList:setPosition(cc.p(kindbgListSize.width/2 , kindbgListSize.height/2))
    kindBgLayout:addChild(kindsList)

    local familyData =  CommonUtils.GetConfigAllMess('monsterFamily', 'collection')
    for k , v in pairs(familyData) do
        -- 创建Button
        local kindsButton = display.newCheckBox(0, 0, { s = _res('ui/home/handbook/pokedex_monster_tab_btn_default.png') , n = _res('ui/home/handbook/pokedex_monster_tab_btn_select.png') })
        local kindsButtonSize =  kindsButton:getContentSize()
        local buttonName = display.newLabel(kindsButtonSize.width/2, kindsButtonSize.height * 0.5, fontWithColor(14, {ap = display.CENTER, color = "ffffff",text = v.name,w = 180}) )
        kindsButton:addChild(buttonName)
        local buttonNameSize =  buttonName:getContentSize()
        if  buttonNameSize.height > 80  then
            display.commonLabelParams(buttonName , {ap = display.CENTER, color = "ffffff",text = v.name,w = 180 , reqH = 80 })
        end
        buttonName:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        kindsButtonSize  = cc.size(kindbgListSize.width, kindsButtonSize.height + 20)
        kindsButton:setPosition(cc.p(kindsButtonSize.width/2 ,kindsButtonSize.height/2 ))
        local kindsButtonLayout = display.newLayer(0, 0,{ size =  kindsButtonSize })
        --- 设置tag 值
        kindsButton:setTag(checkint(v.id))
        kindsButton:setName("kindsButton")
        kindsButtonLayout:setPosition(cc.p(kindsButtonSize.width /2 , kindsButtonSize.height/2 ))
        kindsButtonLayout:addChild(kindsButton)
        -- 设置类型的名称

        kindsList:insertNodeAtLast(kindsButtonLayout)
    end
    kindsList:reloadData()

    local introduceSize = cc.size(360, bgSize.height)
    local introduceLayout = display.newLayer(kindbgListSize.width, bgSize.height/2, { ap =  display.LEFT_CENTER , size =introduceSize })



    local titleImage = display.newImageView(_res("ui/home/handbook/monthcard_tool_split_line.png"), introduceSize.width/2, introduceSize.height -98, { ap = display.CENTER})
    introduceLayout:addChild(titleImage)
    local titleLabel = display.newLabel(introduceSize.width/2, introduceSize.height - 60, fontWithColor("14", { text = __('族群简介')  , color = "5b3c25", outline  = false}) )
    introduceLayout:addChild(titleLabel,2)
    -- 怪物介绍Label introduceLabel
    local introduceLabel = display.newLabel(introduceSize.width/2, introduceSize.height -110,fontWithColor('6', { ap = display.CENTER_TOP , w = 310 , hAligh = display.TAL}) )
    introduceLayout:addChild(introduceLabel)
    -- 右侧的线
    local rightLine = display.newImageView(_res("ui/home/handbook/pokedex_monster_line.png"), introduceSize.width - 5 , introduceSize.height /2, { ap = display.CENTER})
    introduceLayout:addChild(rightLine)
    bgLayout:addChild(introduceLayout)

    -- 常用的list 的列表
    local commonListSize = cc.size(display.SAFE_RECT.width - kindbgListSize.width - introduceSize.width , bgSize.height)
    local commonList = CListView:create(commonListSize)
    commonList:setDirection(eScrollViewDirectionHorizontal)
    commonList:setBounceable(true)
    commonList:setAnchorPoint(display.LEFT_CENTER)
    commonList:setPosition(cc.p(kindbgListSize.width + introduceSize.width , bgSize.height/2))
    bgLayout:addChild(commonList)
    bgLayout.viewData  =  {
        bgLayout = bgLayout ,
        kindsList = kindsList ,
        introduceLabel = introduceLabel ,
        commonList = commonList,
        introduceLayout = introduceLayout ,
    }
   return bgLayout
end

--==============================--
--desc:创建伴生怪的boss界面
--time:2017-07-17 02:42:11
--@return
--==============================--
function BossStoryView:CreateBossAssicast()
    local listSize =  cc.size(display.SAFE_RECT.width,625)
    local listView = CListView:create(listSize)--TODO
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setBounceable(true)
    listView:setAnchorPoint(display.CENTER)
    listView:setPosition(cc.p(listSize.width/2, listSize.height/2))
    listView:setTag(4)
    return listView
end
--==============================--
--desc:创建鼻孔怪的信息
--time:2017-07-20 08:09:17
--@data:鼻孔怪的信息
--@return
--==============================--
function BossStoryView:CretaeAssicastList(data)
    local gradeCellSize = cc.size(150,150)
    local multiple =  math.floor(display.width/ gradeCellSize.width)
    local line = math.ceil(  #data / multiple )
    line = line >0 and line or  1
    local cellSize = cc.size(display.width ,gradeCellSize.height)
    local cellLayout = CLayout:create(cellSize)
    for k  , v in pairs(data) do
        local viewData = self:CreateSmallBoss()
        local line = math.ceil((k -0.5) / multiple)
        local list = (k -0.5) % multiple
        viewData.cellFrameLayout:setPosition(cc.p(list * gradeCellSize.width , (line - 0.5) * gradeCellSize.height ))
        cellLayout:addChild(viewData.cellFrameLayout)
        self:UpdateSmallView(viewData,v )
    end
    return cellLayout
end
--==============================--
--desc:创建小怪和伴生怪的cell
--time:2017-07-17 08:05:55
--@return
--==============================--
function BossStoryView:CreateSmallBoss()
    local bgImage = display.newImageView(_res('ui/cards/head/kapai_frame_bg.png'))
    local bgframe = display.newImageView(_res(CardUtils.CAREER_HEAD_FRAME_PATH_MAP[tostring(CardUtils.QUALITY_TYPE.N)]))
    -- boss 的图片id
    local bgSize  = bgframe:getContentSize()
    local bgLayoutSize = cc.size(bgSize.width+5,bgSize.height+5)
    local cellLayout  = CLayout:create(bgLayoutSize)
    local clickLayout = display.newLayer(bgSize.width/2,bgSize.height/2,{ap =display.CENTER, size = bgSize ,color = cc.c4b(0,0,0,0) ,enable = true})
    bgImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    bgframe:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    cellLayout:addChild(bgImage)
    cellLayout:addChild(bgframe)
    cellLayout:setScale(0.78)
    local cellFrameLayout = CLayout:create(bgLayoutSize)
    cellLayout:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    cellFrameLayout:addChild(cellLayout)
    cellFrameLayout:addChild(clickLayout)
    local viewData = {
        cellFrameLayout = cellFrameLayout  ,
        clickLayout = clickLayout ,
        cellLayout = cellLayout ,
        bgSize = bgSize
    }
     return viewData
end
--==============================--
--desc:更新显示小怪的信息
--time:2017-07-20 04:41:53
--@return
--==============================--
function BossStoryView:UpdateSmallView(viewData,data)
    local bossId = data.id  or '300005'
    local  bgSize = viewData.bgSize
    local status = data.status or 1
    local textureStr = ""
    local scale  = 1
    if checkint(data.type)  == 1 then
        viewData.clickLayout:setTag(checkint(data.id))
        status = (checkint(data.status)  ~=2 and   checkint( data.status) ~=3)  and  checkint(data.status ) or 3
        viewData.clickLayout:setOnClickScriptHandler(handler(self,self.SmallBossInfo)) --伴生怪没有

        -- 鼻孔怪做相减的操作
        scale = 0.45
        textureStr = _res(string.format('cards/bikouguai/pokedex_bikong_%d.png',data.id ) )
    else
        textureStr = AssetsUtils.GetCardHeadPath(bossId)
    end
    if  status == 1 then
        local  noObtainBoss = display.newImageView(_res('ui/home/handbook/pokedex_monster_ico_mark.png'))
        noObtainBoss:setVisible(true)
        noObtainBoss:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
        viewData.cellLayout:addChild(noObtainBoss)
    elseif  status == 2 then
        local bossIdImage = FilteredSpriteWithOne:create(textureStr)
        bossIdImage:setFilter(filter.newFilter('GRAY'))
        bossIdImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
        bossIdImage:setScale(0.6)
        viewData.cellLayout:addChild(bossIdImage)
    elseif  status == 3  then
        print(textureStr)
        local bossIdImage = FilteredSpriteWithOne:create(textureStr)
        bossIdImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
        viewData.cellLayout:addChild(bossIdImage)
        bossIdImage:setScale(0.6)
    end
end
function BossStoryView:SmallBossInfo(sender)
    print(sender:getTag())
    dump( gameMgr:GetUserInfo().monster)
    if checkint(gameMgr:GetUserInfo().monster[tostring(sender:getTag())])  == 2 or gameMgr:GetUserInfo().monster[tostring(sender:getTag())] ==3  then
        uiMgr:AddDialog('Game.views.AssociatedBossView',{ id = sender:getTag()})

    else
        uiMgr:ShowInformationTips(__('该怪物尚未遇到'))
    end
end
return BossStoryView
