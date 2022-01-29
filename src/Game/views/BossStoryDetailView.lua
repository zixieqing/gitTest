---@class BossStoryDetailView : Node
local BossStoryDetailView = class('BossStoryDetailView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.BossStoryDetailView'
	node:enableNodeEvents()
	return node
end)

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local BUTTON_TAG = {
    BOSS_STORY = 1001  , -- boss 的故事
    BOSS_HABIT = 1002  , -- boss 的习性
    BOSS_SKILL = 1003  , -- boss 的技能
    BOSS_NEXT  = 1004 ,  -- 下一个boos
    BOSS_LAST  = 1005 ,  -- 上 一个boos
    BOSS_COMMENT  = 1006 ,  -- 上 一个boos
}
function BossStoryDetailView:ctor(param )
    self.data = param or  {}
    self.type = checkint(self.data.type)
    self:InitUI(self.type)
end
-- 初始化UI
function BossStoryDetailView:InitUI()
    local swallowLayer = display.newLayer(0,0,{ size = display.size , color = cc.c4b(0,0,0,100), enable = true})
    self:addChild(swallowLayer)

    local touchLayer = display.newLayer(display.width/4,display.height/2,{ ap = display.CENTER ,size = cc.size(display.width/4,display.height/4*3),color = cc.c4b(0,0,0,0),enable = true  })
    self:addChild(touchLayer,10)

    local bgSize = cc.size(display.width, 80)
    local moneyNode = CLayout:create(bgSize)
    display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    self:addChild(moneyNode,100)

    -- 返回按钮
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, bgSize.height - 18 - backBtn:getContentSize().height * 0.5)})
    moneyNode:addChild(backBtn, 5)
    -- 返回按钮注册销毁事件
    backBtn:setOnClickScriptHandler(function (  )
        self:runAction(cc.RemoveSelf:create())
    end)
    local monsterText  = ""
    if self.type  == 3  then
        monsterText = __('异化')
    else
        monsterText = __('特型')
    end
    -- 标题按钮
    local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height, {n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
    display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = monsterText, fontSize = 30, color = '473227',offset = cc.p(0,-8)})
    self:addChild(tabNameLabel,10)

    -- 背景图片
    local noticeImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_bg.jpg'), display.cx, display.cy, {isFull = true})
    self:addChild(noticeImage)

    -- boss的头像 创建boss
    local secData = {confId = 200013, coordinateType = COORDINATE_TYPE_HOME}
    local bossImage = require('common.CardSkinDrawNode').new(secData)
    bossImage:setVisible(true)
    bossImage:setPositionX(display.SAFE_L)
    self:addChild(bossImage)

    -- 创建下部的的内容
    local bottomSize = cc.size(display.width,200)
    local bottomLayout = CLayout:create(bottomSize)
    bottomLayout:setAnchorPoint(display.CENTER_BOTTOM)
    bottomLayout:setPosition(cc.p(display.cx, 0))
    self:addChild(bottomLayout,3)

    -- 怪物的名称
    local levelPosY = 65
    local bossNameImage = display.newImageView(_res('avatar/ui/draw_card_bg_name'),display.cx/2+50 , levelPosY, {
        ap = display.CENTER
    })
    bottomLayout:addChild(bossNameImage,2)

    local bossTitleSize = bossNameImage:getContentSize()
    local nameLabel = display.newLabel(90,bossTitleSize.height/2-5, fontWithColor(14, { ap = display.LEFT_CENTER ,text = "", fontSize = 26, color = 'ffdf89'}))
    bossNameImage:addChild(nameLabel)

    -- 右侧下部分的按钮组合
    local bgRightImage = display.newImageView(_res('ui/cards/propertyNew/card_bg_tabs.png'))
    local bgRightSize = bgRightImage:getContentSize()
    local bottomRightLayout  = CLayout:create(bgRightSize)
    bgRightImage:setPosition(cc.p(bgRightSize.width/2 , bgRightSize.height/2))
    bottomRightLayout:addChild(bgRightImage)
    bottomRightLayout:setAnchorPoint(display.RIGHT_BOTTOM)
    bottomRightLayout:setPosition(cc.p(display.SAFE_R + 59 , 0))
    bottomLayout:addChild(bottomRightLayout)
    -- 加载按钮Layout

    local buttonSize =  cc.size(360,bgRightSize.height )
    local buttonLayout = CLayout:create(buttonSize)
    buttonLayout:setAnchorPoint(display.LEFT_CENTER)
    buttonLayout:setPosition(cc.p(255 , buttonSize.height/2))
    bottomRightLayout:addChild(buttonLayout)
    local buttonElement = {
        { name = __('故事') , n = _res('ui/home/handbook/pokedex_monster_btn_story_default.png'), s= _res('ui/home/handbook/pokedex_monster_btn_story_selected.png')  , tag = BUTTON_TAG.BOSS_STORY },
        { name = __('习性') , n = _res('ui/home/handbook/pokedex_monster_btn_habit_default.png'), s= _res('ui/home/handbook/pokedex_monster_btn_habit_selected.png')  , tag = BUTTON_TAG.BOSS_HABIT },
        { name = __('技能') , n = _res('ui/home/handbook/pokedex_monster_btn_skill_default.png'), s= _res('ui/home/handbook/pokedex_monster_btn_skill_selected.png')  , tag = BUTTON_TAG.BOSS_SKILL }
    }
    if self.type == 3 then
        table.remove( buttonElement,2)
    end
    local buttons = {}
    local width = buttonSize.width/#buttonElement
    for i =1 , #buttonElement do
        -- 按钮的点击事件
        local button = display.newCheckBox((i -0.5 )*width,buttonSize.height/2,{ n = buttonElement[i].n  , s = buttonElement[i].s})
        button:setTag( buttonElement[i].tag)
        buttons[#buttons+1] = button
        buttonLayout:addChild(button)
        local titleImage =  display.newImageView(_res('ui/common/common_bg_float_text.png'),(i -0.5 )*width,22)
        local titleImageSize = titleImage:getContentSize()
        titleImage:setScaleX(0.3)
        local titleSize =  cc.size(titleImageSize.width*0.3,titleImageSize.height)
        local titleLayout = CLayout:create(titleSize)
        titleImage:setPosition(cc.p(titleSize.width/2,titleSize.height/2))
        titleLayout:addChild(titleImage)
        titleLayout:setPosition(cc.p((i -0.5 )*width,20))
        local titleLable =display.newLabel(titleSize.width/2,titleSize.height/2,fontWithColor('14' , {fontSize = 26 , text = buttonElement[i].name}))
        titleLable:enableOutline(cc.c4b(31,17,17,255), 2)
        titleLayout:addChild(titleLable)
        buttonLayout:addChild(titleLayout,4)
    end
    local  commontBtn= display.newButton(40 , bottomSize.height -110,
    {n = _res('ui/home/handbook/pokedex_card_btn_forum.png'), ap = display.LEFT_TOP, animate = true})
    display.commonLabelParams(commontBtn, {text = __('评论'), fontSize = 22, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, offset = cc.p(-6, 10)})
    commontBtn:setTag(BUTTON_TAG.BOSS_COMMENT)
    commontBtn:setVisible(false)
    bottomLayout:addChild(commontBtn)
    local  qAvatar = self:CreateSpineMonster()
    self.viewData =  {
        bossImage = bossImage ,
        navBackButton  = backBtn ,
        leftSwichBtn = leftSwichBtn ,
        rightSwichBtn = rightSwichBtn ,
        buttons = buttons ,
        commontBtn = commontBtn ,
        nameLabel = nameLabel ,
        touchLayer = touchLayer ,
        qAvatar = qAvatar
    }
end
--==============================--
--desc:更新左侧的ui显示
--time:2017-07-26 05:27:43
--@return
--==============================--
function  BossStoryDetailView:UpdateMonsterUI(data)
    local attack = data.attack
    local cardData = {confId = data.id, coordinateType = COORDINATE_TYPE_HOME}
    if checkint(data.status) ~= 3 then
        self.viewData.bossImage:setFilterName(filter.TYPES.GRAY)
    else
        self.viewData.bossImage:setFilterName()
    end
    self.viewData.bossImage:RefreshAvatar(cardData)
    self.viewData.nameLabel:setString(data.name)

end
--==============================--
--desc:创建怪物技能的View
--time:2017-07-18 03:51:00
--@return
--==============================--
function BossStoryDetailView:CreateSkillView()
    -- 创建技能的view
    local bgImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_skill_bg.png'))
    local bgSize = bgImage:getContentSize()
    local bgLayout = CLayout:create(bgSize)
    bgImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    bgLayout:addChild(bgImage)
    local skillListViewSize = cc.size(bgSize.width+10, bgSize.height -20)
    local skillListView = CListView:create(skillListViewSize)
    skillListView:setDirection(eScrollViewDirectionVertical)
    skillListView:setPosition(cc.p(bgSize.width/2-8,bgSize.height/2))
    skillListView:setAnchorPoint(display.CENTER)
    bgLayout:addChild(skillListView)
    bgLayout:setPosition(cc.p( display.SAFE_R - 10 , display.height/2 + 30) )
    bgLayout:setAnchorPoint(display.RIGHT_CENTER)
    skillListView:reloadData()
    local viewData = {
        skillListView = skillListView ,
        bgLayout = bgLayout ,
    }
    return viewData
end
--==============================--
--desc:用于常见boss的技能介绍
--time:2017-07-05 04:02:31
--@return
--==============================--
function BossStoryDetailView:CreateBossSkillCell()
    local skillSize = cc.size(555,220)
    local skillLayout = display.newLayer(skillSize.width/2,skillSize.height-10, { ap = display.CENTER_TOP , size = skillSize ,color =  cc.c4b(0,0,0,0) ,enable =true  , ap = display.CENTER_TOP })
    local skillImageBg = display.newImageView(_res("ui/home/handbook/pokedex_monster_titile_skill.png"),skillSize.width/2,skillSize.height,{ap  = display.CENTER_TOP })
    skillLayout:addChild(skillImageBg,2)
    local  clickLayer = display.newLayer(skillSize.width/2,skillSize.height/2,{size = skillSize , enable = true , color = cc.c4b(0,0,0,0)})
    skillLayout:addChild(clickLayer)
    local skillImageBgSize = skillImageBg:getContentSize()
    -- 技能名称
    local skillName = display.newLabel(40,skillImageBgSize.height/2, fontWithColor('3',{ text = "" ,ap = display.LEFT_CENTER} ))
    skillImageBg:addChild(skillName)
    -- 技能作用介绍
    local skillIntroduceBg = display.newImageView(_res("ui/home/handbook/pokedex_monster_skill_bg_words.png"),skillSize.width/2,skillSize.height -skillImageBgSize.height +3 ,{ scale9 = true ,  ap = display.CENTER_TOP})
    skillLayout:addChild(skillIntroduceBg)
    local skillIntroduceBgSize = skillIntroduceBg:getContentSize()
    local skillIntroduceLabel = display.newLabel(60,skillIntroduceBgSize.height -10,fontWithColor('16', { ap = display.LEFT_TOP , w = skillIntroduceBgSize.width -80 ,text = "" }))
    skillLayout:addChild(skillIntroduceLabel)
    local cellLayout = display.newLayer(0,0,{size = skillSize , color1 = cc.r4b()})
    cellLayout:addChild(skillLayout)

    cellLayout.viewData = {
        skillName = skillName ,
        skillIntroduceLabel = skillIntroduceLabel ,
        cellLayout = cellLayout ,
        skillLayout = skillLayout ,
        skillIntroduceBg = skillIntroduceBg
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
--desc: 用于更新boss 的详情介绍
--time:2017-07-05 04:04:45
--@args:
--viewData cell里面需更新的项
--data  技能数据
--@return
--==============================--
function BossStoryDetailView:UpdateeBossSkillCell(viewData, data)
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
        viewData.cellLayout:setContentSize(cc.size(cellLayoutSize.width ,math.abs(distance ) + cellLayoutSize.height  +10 )  )
        cellLayoutSize = viewData.cellLayout:getContentSize()
        viewData.skillLayout:setAnchorPoint(display.CENTER_TOP)
        viewData.skillLayout:setPosition(cc.p(cellLayoutSize.width/2 , cellLayoutSize.height-10))
    else
        print("222222222222222222")
    end


end
--==============================--
--desc:创建骨骼动画的动作
--time:2017-07-26 07:07:34
--@return
--==============================--
function BossStoryDetailView:CreateSpineMonster()
    local node = self:getChildByTag(888)
    if node then
        node:removeFromParent()
    end
    local skinId = CardUtils.GetCardSkinId(self.data.id)
    local qAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.7})
    qAvatar:update(0)
    qAvatar:setTag(1)
    qAvatar:setAnimation(0, 'idle', true)
    self:addChild(qAvatar)
    qAvatar:setPosition(cc.p(display.width/4, display.height/2 - 200))
    qAvatar:setVisible(false)
    return qAvatar
end
--==============================--
--desc:创建boss的故事表
--time:2017-07-18 04:34:04
--@viewData:
--@data:
--@return
--==============================--

function BossStoryDetailView:CreateStoryView()
    -- 创建技能的view
    local bgImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_story_bg.png'))
    local bgSize = cc.size(529,592)
    local bgLayout = CLayout:create(bgSize)
    bgImage:setAnchorPoint(display.LEFT_CENTER)
    bgImage:setPosition(cc.p(12,bgSize.height/2))
    bgLayout:addChild(bgImage)
    -- statusOneLayout 未解锁的状态
    local statusOneLayout = CLayout:create(bgSize)
    statusOneLayout:setVisible(true)
    statusOneLayout:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    bgLayout:addChild(statusOneLayout)
    local storyListViewSize = cc.size(bgSize.width - 40 ,bgSize.height-100)
    local storyListView = CListView:create(storyListViewSize)
    storyListView:setDirection(eScrollViewDirectionVertical)
    storyListView:setAnchorPoint(display.CENTER)
    storyListView:setPosition(bgSize.width/2, bgSize.height/2 -20)
    storyListView:setBounceable(true)
    statusOneLayout:addChild(storyListView)
    -- 创建内容的文本 关于怪物的故事
    local cellSize =  cc.size(storyListViewSize.width ,storyListViewSize.height )
    local cellLayout =  CLayout:create(cellSize)
    local contentLabel = display.newLabel(storyListViewSize.width/2,storyListViewSize.height, { fontSize = 24 ,noScale = true,ttf = true, font = TTF_TEXT_FONT, color = "#5b3c25", ap = display.CENTER_TOP, w = storyListViewSize.width -100, hAlign = display.TAL})
    cellLayout:addChild(contentLabel)
    storyListView:insertNodeAtLast(cellLayout)
    --  创建蒙版设置为影藏
    local maskingImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_story_bg_up.png'),12,-11 , {ap  = display.LEFT_BOTTOM})
    statusOneLayout:addChild(maskingImage,2)

    local statusTwoLayout =  CLayout:create(bgSize)
    statusTwoLayout:setVisible(false)
    statusTwoLayout:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
    bgLayout:addChild(statusTwoLayout)
    local lineImage  =  display.newImageView(_res('ui/home/lobby/cooking/kitchen_tool_split_line.png'), bgSize.width/2, bgSize.height/2+20,{scale9 = true, size = cc.size(410, 20)})
    statusTwoLayout:addChild(lineImage)
    local bossStringDescr = display.newLabel(bgSize.width/2,bgSize.height/2 + 30,{ fontSize = 22 ,color = "a3776b", hAlign = display.TAC , ap = display.CENTER_BOTTOM,text = __('完成剧情任务后解锁完整背景故事') })
    statusTwoLayout:addChild(bossStringDescr)
    local label = display.newLabel(bgSize.width/2,bgSize.height/2 -10,{ fontSize = 22 ,color = "a3776b", ap = display.CENTER , maxW = 450 ,text = __('完成剧情任务后解锁完整背景故事') })
    statusTwoLayout:addChild(label)
    bgLayout:setAnchorPoint(display.RIGHT_CENTER)
    bgLayout:setPosition(cc.p( display.SAFE_R +10 , display.height/2 + 30) )
    return {
        bgLayout = bgLayout ,
        statusOneLayout = statusOneLayout ,
        statusTwoLayout = statusTwoLayout ,
        label = label ,
        storyListView = storyListView ,
        cellLayout = cellLayout ,
        contentLabel = contentLabel ,
        bossStringDescr = bossStringDescr ,
    }
end
function BossStoryDetailView:CreateHabitView()
    local bgImage = display.newImageView(_res('ui/home/handbook/pokedex_monster_story_bg.png'))
    local bgSize = cc.size(529,592)
    local bgLayout = CLayout:create(bgSize)
    bgImage:setAnchorPoint(display.LEFT_CENTER)
    bgImage:setPosition(cc.p(12,bgSize.height/2))
    bgLayout:addChild(bgImage)
    local storyListViewSize = cc.size(bgSize.width -60 ,bgSize.height-40)
    local habitListView = CListView:create(storyListViewSize)
    habitListView:setDirection(eScrollViewDirectionVertical)
    habitListView:setAnchorPoint(display.CENTER)
    habitListView:setPosition(bgSize.width/2 + 20, bgSize.height/2+10)
    habitListView:setBounceable(true)
    bgLayout:addChild(habitListView)
    --local layout =display.newLayer(bgSize.width/2, bgSize.height/2,  { ap = display.CENTER,color = cc.r4b() , size = storyListViewSize})
    --bgLayout:addChild(layout)
    local swordImage  = display.newImageView(_res("ui/home/handbook/pokedex_monster_ico_pen.png"), 50, 50)
    bgLayout:addChild(swordImage)
    bgLayout:setAnchorPoint(display.RIGHT_CENTER)
    bgLayout:setPosition(cc.p( display.SAFE_R+10  , display.height/2 + 30) )
    return {
        layout = layout,
        bgLayout = bgLayout ,
        habitListView = habitListView
    }
end
--==============================--
--desc:更新故事的信息
--time:2017-07-18 05:13:37
--@return
--==============================--
function BossStoryDetailView:UpdateStoryView( viewData,data)

    local  status = data.storyStatus
    local  bossStrDescr =  data.bossDescr
    local  contentStr =  data.storyDescr
    -- 首先应该重置显示
    viewData.statusOneLayout:setVisible(false)
    viewData.statusTwoLayout:setVisible(false)
    if status  then
        viewData.statusOneLayout:setVisible(true)
        viewData.contentLabel:setString(contentStr)
        local height = viewData.contentLabel:getContentSize().height
        -- local labelSize =  display.getLabelContentSize(viewData.contentLabel)
        -- local height =  labelSize.height > 580 and   labelSize.height or   580-- 获取到故事的长度
        local listSize =  viewData.statusOneLayout:getContentSize()
        viewData.cellLayout:setContentSize(cc.size(listSize.width,height + 20))
        viewData.contentLabel:setPosition(cc.p(listSize.width/2,height + 20))
        viewData.storyListView:reloadData()
    else
        --viewData.bossStringDescr:setString(bossStrDescr or  "")
        display.commonLabelParams(viewData.bossStringDescr, { text = bossStrDescr , w = 450})
        viewData.statusTwoLayout:setVisible(true)
    end

end

return  BossStoryDetailView
