local AssociatedBossView = class('AssociatedBossView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.AssociatedBossView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")


function AssociatedBossView:ctor(param )
    param = param or {}
    self:InitUI()
    self:UpdateBossView(param)
end
-- 初始化UI
function AssociatedBossView:InitUI()
    local swallowLayer = display.newLayer(0,0,{ size = display.size , color = cc.c4b(0,0,0,100), enable = true , cb  = function ()
        self:runAction(cc.RemoveSelf:create())
    end})
    self:addChild(swallowLayer)
    local bgSize = cc.size(display.width, 80)
    local moneyNode = CLayout:create(bgSize)
    display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    self:addChild(moneyNode,100)

    -- 返回按钮
    local buttons = {}
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30, bgSize.height - 18 - backBtn:getContentSize().height * 0.5)})
    moneyNode:addChild(backBtn, 5)
    backBtn:setOnClickScriptHandler(function (  )
        self:runAction(cc.RemoveSelf:create())
    end)
    --人物的图片
    local associateBossImage = display.newImageView( _res('ui/home/handbook/pokedex_monster_list_bg.png'),display.cx, display.cy + 75)
    self:addChild(associateBossImage)
    associateBossImage:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.MoveBy:create(2,cc.p(0,100)  ),cc.MoveBy:create(2,cc.p(0,-100)  )
    )))
    local tipSize = cc.size(496 ,176)
    local tipImage = display.newImageView(_res('ui/common/common_bg_tips.png'),display.cx,display.cy - 105,{ ap = display.CENTER , scale9 = true , size = tipSize})

    local tipSize = tipImage:getContentSize()
    tipImage:setPosition(cc.p(tipSize.width/2, tipSize.height/2))
    local tipLayout = CLayout:create(tipSize)

    tipLayout:setPosition(cc.p( display.cx,display.cy - 105))
    tipLayout:setAnchorPoint(display.CENTER_TOP)
    self:addChild(tipLayout)

    tipLayout:addChild(tipImage)
    local cha_one = display.newImageView(_res('ui/home/handbook/pokedex_monster_ico_cha.png'),12,tipSize.height /2)
    local cha_Two = display.newImageView(_res('ui/home/handbook/pokedex_monster_ico_dao.png'),tipSize.width -12,tipSize.height/2)
    tipImage:addChild(cha_one)
    tipImage:addChild(cha_Two)
    local titleName  = display.newLabel(tipSize.width/2,tipSize.height - 24 ,fontWithColor('14', { fontSize = 26 , color = "#5b3c25", text = ""}))
    tipImage:addChild(titleName)
    titleName:setName("titleName")
    -- 创建内容的滚动框
    local listSize = cc.size(370 ,120)
    local listView = CListView:create(listSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint(display.CENTER_TOP)
    listView:setPosition(cc.p(tipSize.width/2,tipSize.height - 50 ))
    listView:setBounceable(true)
    tipLayout:addChild(listView,2)
    --local layoutColor = display.newLayer(tipSize.width/2,tipSize.height - 50, { size = listSize,  color = cc.r4b(), ap = display.CENTER_TOP})
    --tipLayout:addChild(layoutColor ,10)
    local contentLayout = display.newLayer(0, 0, { color = cc.c4b(0,0,0,0) , size = listSize })
    listView:insertNodeAtLast(contentLayout)
    listView:reloadData()
    local contentLabel = display.newLabel(listSize.width/2,listSize.height/2 ,fontWithColor('6', {w = 370 , hAlign = display.TAL , ap = display.CENTER ,text = "sdafffffffffffffffffff"}))
    contentLayout:addChild(contentLabel,2)
    contentLabel:setName( "contentLabel")

    self.viewData = {
        titleName = titleName ,
        contentLabel = contentLabel ,
        associateBossImage = associateBossImage ,
        tipImage = tipImage ,
        listView = listView ,
        contentLayout = contentLayout ,
    }
end

--==============================--
--desc:更新view 的内容显示
--time:2017-07-18 10:47:35
--@data:这个是表示的传输的刷新数据
--@return 
--==============================--
function AssociatedBossView:UpdateBossView(data)
    local bossId = data.id or 320001
    -- bossId = bossId - 320000
    local monsterInfo = CommonUtils.GetConfigAllMess('monster','collection')[tostring(data.id)] or {}
    local bossName =  monsterInfo.name or  "-------------------" -- boss 的name
    local bossContent = monsterInfo.descr  or  ""

    display.commonUIParams(self.viewData.titleName,fontWithColor('14', { fontSize = 26 , color = "#5b3c25", text = bossName}))
    display.commonUIParams(self.viewData.contentLabel,fontWithColor('6', {color = "#5b3c25", text = bossContent}))
    local iamge =  _res( string.format('cards/bikouguai/pokedex_bikong_%d.png', bossId))
    self.viewData.titleName:setString(bossName)
    self.viewData.contentLabel:setString(bossContent)
    self.viewData.associateBossImage:setTexture(iamge)
    local contentLabelSize = display.getLabelContentSize(self.viewData.contentLabel)
    self.viewData.contentLabel:setPosition(cc.p(contentLabelSize.width/2 ,contentLabelSize.height/2))
    self.viewData.contentLayout:setContentSize(contentLabelSize)
    self.viewData.listView:reloadData()
end

return  AssociatedBossView