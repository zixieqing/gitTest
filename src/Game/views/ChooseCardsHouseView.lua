---
--- Created by xingweihao.
--- DateTime: 09/11/2017 5:22 PM
---
--[[
选择英雄UI
--]]
local GameScene = require( "Frame.GameScene" )
local ChooseCardsHouseView = class('ChooseCardsHouseView', GameScene)
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local RES_DICT = {
    BG 					= 'ui/common/common_bg_13.png',
    BG_UP 				= 'ui/common/common_bg_title_2.png',
    BG_CARD_DEFAULT 	= 'ui/home/teamformation/choosehero/card_order_ico_default.png',
    BG_CARD_SELECTED	= 'ui/home/teamformation/choosehero/card_order_ico_selected.png',
    BTN_BG				= 'ui/home/teamformation/choosehero/team_btn_screen_white.png',
    SORT_BG				= 'ui/home/teamformation/choosehero/team_sort_bg.png',
    IMG_LINE			= 'ui/home/teamformation/choosehero/team_sort_ico_line.png',
    IMG_CHOOSE_DEFAULT	= 'ui/home/teamformation/choosehero/team_sort_ico_point_unselected.png',
    IMG_CHOOSE_SELECTED = 'ui/home/teamformation/choosehero/team_sort_ico_point_selected.png',
}
local BTN_TAG = {
    MINUS = 1,
    ADD   = 2,
    MAX   = 3,
    SALE  = 4,
    OTHER = 999,
}

local sortType = {
    {descr = __('排序'), typeDescr = __('默认'), tag = 0},
    {descr = __('等级'), typeDescr = __('等级'), tag = 1},
    {descr = __('稀有度'), typeDescr = __('稀有度'), tag = 2},
    {descr = __('灵力'), typeDescr = __('灵力'), tag = 3},
    {descr = __('星级'), typeDescr = __('星级'), tag = 4},
    -- {descr = __('编队信息'), typeDescr = __('编队信息'), tag = 4},
}

local screenType = {
    {tag = 0, descr = __('筛选'), typeDescr = __('所有')},
    {tag = CardUtils.CAREER_TYPE.DEFEND},
	{tag = CardUtils.CAREER_TYPE.ATTACK},
	{tag = CardUtils.CAREER_TYPE.ARROW},
	{tag = CardUtils.CAREER_TYPE.HEART},
}
--[[
    {
    -- 移除或者要更换的数据
    datas = {}
    -- 已经选中的数据
    cardHouseData = {}, --传输当前选中的卡牌信息
    type  =  1 or 2     --更换皮肤传二
    callback 传输传输  1. { 直接返回飨灵卡的全部数据 } 2. { 在返回卡牌总数据基础上返回一个skin 字段}
    }
    isAutonClose = true
    type  选择卡牌的形式 1. 只更换卡牌 2. 更换卡牌和皮肤

--]]
function ChooseCardsHouseView:ctor( ... )
    print("------------------------1111122222")
    local arg = unpack({...})
    self.datas = arg
    self.type = arg.type or 1
    self.cardHouseData = arg.cardHouseData
    self.isAutonClose = arg.isAutonClose or false
    if arg.callback then self.callback = arg.callback end
    self.clickTag = 1
    self.clickBtn = nil
    self.showNameOrFight = false --显示名字或者灵力
    self.eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    self.eaterLayer:setTouchEnabled(true)
    self.eaterLayer:setContentSize(display.size)
    self.eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    self.eaterLayer:setPosition(cc.p(display.cx, display.height))-- NAV_BAR_HEIGHT
    if  self.isAutonClose then
        self.eaterLayer:setOnClickScriptHandler(
                function (sender)
                    if self and ( not tolua.isnull(self)) then
                        self:runAction(cc.RemoveSelf:create())
                    end
                end
        )
    end

    self:addChild(self.eaterLayer, -1)
    self:setName('ChooseCardsHouseView')

    local function CreateView( ... )
        local view = CLayout:create()
        view:setName('view')
        local bg = display.newImageView(_res(RES_DICT.BG),
                                        {})	--scale9 = true, size = cc.size(display.size.width - NAV_BAR_HEIGHT - 42 , display.size.height - 2*NAV_BAR_HEIGHT )
        bg:setTouchEnabled(true)
        view:addChild(bg)

        local frameSize  = bg:getContentSize()
        bg:setAnchorPoint(display.LEFT_BOTTOM)
        view:setContentSize(cc.size(frameSize.width,frameSize.height))

        local pox = frameSize.width * 0.5
        --标题  物品名称
        local btn_up = display.newButton(0, 0, {n = _res(RES_DICT.BG_UP),enable = false , scale9 = true })
        if isJapanSdk() then
            display.commonUIParams(btn_up, {po = cc.p(pox, frameSize.height - 10),ap = cc.p(0.5,1)})
            display.commonLabelParams(btn_up, fontWithColor(1,{fontSize = 24, text = __('选择飨灵'), color = 'ffffff',  paddingW = 20, offset = cc.p(0, 0)}))
        else
            display.commonUIParams(btn_up, {po = cc.p(pox, frameSize.height - 12),ap = cc.p(0.5,1)})
            display.commonLabelParams(btn_up, fontWithColor(1,{fontSize = 24, text = __('选择飨灵'), color = 'ffffff',  paddingW = 20, offset = cc.p(0, -2)}))
        end
        view:addChild(btn_up)


        local taskListSize = cc.size(frameSize.width - 90, frameSize.height -150)
        local taskListCellSize = cc.size(taskListSize.width/ 5, 225)--taskListSize.height/5



        local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 0, 0, {scale9 = true, size = cc.size(taskListSize.width,taskListSize.height + 6)})
        display.commonUIParams(gridViewBg, {po = cc.p(frameSize.width /2,frameSize.height /2 - 50)})
        view:addChild(gridViewBg, bg:getLocalZOrder() + 1)


        local gridView = CGridView:create(taskListSize)
        gridView:setSizeOfCell(taskListCellSize)
        gridView:setColumns(5)
        gridView:setAutoRelocate(false)
        gridView:setBounceable(true)
        view:addChild(gridView, gridViewBg:getLocalZOrder() + 1)
        gridView:setAnchorPoint(cc.p(0.5, 0.5))
        gridView:setPosition(cc.p(frameSize.width /2,frameSize.height /2 - 50))
        -- gridView:setBackgroundColor(cc.c4b(200, 0, 0, 100))
        gridView:setName('gridView')

        --灵力和名称切换显示按钮
        local nameAndFigthBtn = display.newCheckBox(0, 0,
                                                    {scale9 = true ,  n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
        display.commonUIParams(nameAndFigthBtn, {po = cc.p(70,530),ap = cc.p(0,0)})
        view:addChild(nameAndFigthBtn, 10)
        nameAndFigthBtn:setContentSize(cc.size(160,50))
        nameAndFigthBtn:setOnClickScriptHandler(handler(self, self.NameAndFigthBtnCallback))

        local nameAndFigthLabel = nil
        if isJapanSdk() then
            nameAndFigthLabel = display.newLabel(utils.getLocalCenter(nameAndFigthBtn).x, utils.getLocalCenter(nameAndFigthBtn).y,
                                                   fontWithColor(5,{text = __('显示灵力'), color = 'ffffff' , hAlign = display.TAC }))
            nameAndFigthBtn:addChild(nameAndFigthLabel)
        else
            nameAndFigthLabel = display.newLabel(utils.getLocalCenter(nameAndFigthBtn).x, utils.getLocalCenter(nameAndFigthBtn).y,
                                                   fontWithColor(5,{text = __('显示灵力'), color = 'ffffff' ,reqW = 120 , w = 180 , hAlign = display.TAC }))
            nameAndFigthBtn:addChild(nameAndFigthLabel)
        end



        local captainDesLabel = display.newRichLabel(220,541,{ap = cc.p(0,0),c = {
            fontWithColor(10,{text =__('队长奖励：')}),
            fontWithColor(15,{text = __("进入战斗时获得50能量") })
        }})
        captainDesLabel:reloadData()
        view:addChild(captainDesLabel,15)
        captainDesLabel:setVisible(false)

        if self.datas.clickHeroTag then
            if checkint(self.datas.clickHeroTag) == 1 then
                --captainDesLabel:setVisible(true)
            end
        end

        -- sort btn
        local screenBtn = display.newCheckBox(0, 0,
                                              {n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
        display.commonUIParams(screenBtn, {po = cc.p(800,575),ap = cc.p(1,1)})
        view:addChild(screenBtn, 10)
        screenBtn:setOnClickScriptHandler(handler(self, self.ScreenBtnCallback))

        local screenLabel = display.newLabel(utils.getLocalCenter(screenBtn).x, utils.getLocalCenter(screenBtn).y,
                                             fontWithColor(5,{text = __('筛选'),color = 'ffffff'}))
        screenBtn:addChild(screenLabel)

        local screenBoardImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_frame_1.png'), screenBtn:getPositionX() + 20, screenBtn:getPositionY() - screenBtn:getContentSize().height * 0.5 - 30
        ,{scale9 = true,size = cc.size(160,56*table.nums(screenType))})
        local screenBoard = display.newLayer(screenBoardImg:getPositionX() , screenBoardImg:getPositionY()  ,
                                             {size = cc.size(screenBoardImg:getContentSize().width,screenBoardImg:getContentSize().height - 16), ap = cc.p(1, 1)})
        -- screenBoard:setBackgroundColor(cc.c4b(0, 128, 0, 100))
        view:addChild(screenBoard, 15)
        display.commonUIParams(screenBoardImg, {po = utils.getLocalCenter(screenBoard)})
        screenBoard:addChild(screenBoardImg)
        screenBoard:setVisible(false)

        -- 筛选类型
        local topPadding = 2
        local bottomPadding = 0
        local listSize = cc.size(screenBoard:getContentSize().width, screenBoard:getContentSize().height - topPadding - bottomPadding)
        local cellSize = cc.size(listSize.width, listSize.height / (table.nums(screenType)))
        local centerPos = nil
        local screenTab = {}
        for i,v in ipairs(screenType) do
            -- centerPos = cc.p(listSize.width * 0.5, listSize.height + bottomPadding - (i - 0.5) * cellSize.height)
            centerPos = cc.p(listSize.width * 0.5, listSize.height  - (i * cellSize.height) + cellSize.height *0.5 )
            local screenTypeBtn = display.newButton(0, 0, {size = cellSize, ap = cc.p(0.5, 0.5), cb = handler(self, self.ScreenTypeBtnCallback)})
            display.commonUIParams(screenTypeBtn, {po = cc.p(centerPos)})
            screenBoard:addChild(screenTypeBtn)
            screenTypeBtn:setTag(v.tag)
            table.insert(screenTab,screenTypeBtn)
            if v.tag ~= 0 then
                local descrLabel = nil
				if isJapanSdk() then
					descrLabel = display.newLabel(0, 0, fontWithColor(5,{text = CardUtils.GetCardCareerName(v.tag), ap = cc.p(0, 0.5),fontSize = 18}))
				else
					descrLabel = display.newLabel(0, 0, fontWithColor(5,{text = CardUtils.GetCardCareerName(v.tag), ap = cc.p(0, 0.5), reqW = 100}))
				end

                local careerBg = display.newImageView(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(v.tag)]), centerPos.x - 25, centerPos.y)

                local totalWidth = careerBg:getContentSize().width * careerBg:getScale() + display.getLabelContentSize(descrLabel).width
                display.commonUIParams(careerBg, {po = cc.p(
                        centerPos.x - totalWidth * 0.5 + careerBg:getContentSize().width * 0.5 * careerBg:getScale(),
                        centerPos.y)})
                if isJapanSdk() then
                    display.commonUIParams(careerBg, {po = cc.p(centerPos.x - 40, centerPos.y)})
                end
                screenBoard:addChild(careerBg)

                local careerIcon = display.newImageView(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(v.tag)]), utils.getLocalCenter(careerBg).x, utils.getLocalCenter(careerBg).y + 2)
                careerIcon:setScale(0.65)
                careerBg:addChild(careerIcon)

                display.commonUIParams(descrLabel, {po = cc.p(careerBg:getPositionX() + careerBg:getContentSize().width * 0.5, careerBg:getPositionY())})
                screenBoard:addChild(descrLabel)


            else
                local descrLabel = display.newLabel(0, 0,
                                                    fontWithColor(5,{text = v.typeDescr, ap = cc.p(0.5, 0.5)}))
                display.commonUIParams(descrLabel, {po = centerPos})
                screenBoard:addChild(descrLabel)
            end

            if i < table.nums(screenType) then
                local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), centerPos.x, centerPos.y - cellSize.height * 0.5)
                screenBoard:addChild(splitLine)
            end
        end

        --排序
        local sortBtn = display.newCheckBox(0, 0,
                                            {n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
        display.commonUIParams(sortBtn, {po = cc.p(970,575),ap = cc.p(1,1)})
        view:addChild(sortBtn, 10)
        sortBtn:setOnClickScriptHandler(handler(self, self.SortBtnCallback))

        local sortLabel = display.newLabel(utils.getLocalCenter(sortBtn).x, utils.getLocalCenter(sortBtn).y,
                                           fontWithColor(5,{text = __('排序'),color = 'ffffff' }))
        sortBtn:addChild(sortLabel)

        local arrowImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_ico_filter_direction.png'))
        arrowImg:setAnchorPoint(cc.p(0.5,0.5))
        arrowImg:setTag(9)
        arrowImg:setPosition(cc.p(sortBtn:getContentSize().width *0.5 - 40,sortBtn:getContentSize().height *0.5))
        sortBtn:addChild(arrowImg)
        arrowImg:setVisible(false)



        local sortBoardImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_frame_1.png'), sortBtn:getPositionX() + 20, sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5 - 30
        ,{scale9 = true,size = cc.size(160,56*table.nums(sortType))})
        local sortBoard = display.newLayer(sortBoardImg:getPositionX() , sortBoardImg:getPositionY()  ,
                                           {size = cc.size(sortBoardImg:getContentSize().width,sortBoardImg:getContentSize().height - 16), ap = cc.p(1, 1)})

        -- sortBoard:setBackgroundColor(cc.c4b(0, 128, 0, 100))
        view:addChild(sortBoard, 15)
        display.commonUIParams(sortBoardImg, {po = utils.getLocalCenter(sortBoard)})
        sortBoard:addChild(sortBoardImg)
        sortBoard:setVisible(false)

        self.sortBtnState = {}
        -- 排序类型
        local topPadding = 2
        local bottomPadding = 0
        local listSize = cc.size(sortBoard:getContentSize().width, sortBoard:getContentSize().height - topPadding - bottomPadding)
        local cellSize = cc.size(listSize.width, listSize.height / (table.nums(sortType)))
        local centerPos = nil
        local sortTab = {}
        for i,v in ipairs(sortType) do
            -- centerPos = cc.p(listSize.width * 0.5, listSize.height + bottomPadding - (i - 0.5) * cellSize.height)
            centerPos = cc.p(listSize.width * 0.5, listSize.height  - (i * cellSize.height) + cellSize.height *0.5 )
            local sortTypeBtn = display.newCheckBox(0, 0, {size = cellSize, ap = cc.p(0.5, 0.5)})--newButton
            display.commonUIParams(sortTypeBtn, {po = cc.p(centerPos)})
            sortBoard:addChild(sortTypeBtn)
            sortTypeBtn:setTag(v.tag)
            sortTypeBtn:setOnClickScriptHandler(handler(self, self.SortTypeBtnCallback))
            table.insert(sortTab,sortTypeBtn)
            table.insert(self.sortBtnState,false)

            if isJapanSdk() then
				local descrLabel = display.newLabel(0, 0,
						fontWithColor(5,{text = v.typeDescr, ap = cc.p(0.5, 0.5),fontSize = 18}))
				display.commonUIParams(descrLabel, {po = centerPos})
				sortBoard:addChild(descrLabel)
			else
				local descrLabel = display.newLabel(0, 0,
						fontWithColor(5,{text = v.typeDescr ,reqW =120, ap = cc.p(0.5, 0.5)}))
				display.commonUIParams(descrLabel, {po = centerPos})
				sortBoard:addChild(descrLabel)
			end

            local selectIcon = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'), utils.getLocalCenter(sortTypeBtn).x, utils.getLocalCenter(sortTypeBtn).y ,
                                                    {scale9 = true,size = cc.size(cellSize.width - 40,cellSize.height)})
            sortTypeBtn:addChild(selectIcon)
            selectIcon:setTag(99)
            selectIcon:setVisible(false)


            local arrowImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_ico_filter_direction.png'))
            arrowImg:setAnchorPoint(cc.p(0.5,0.5))
            arrowImg:setTag(9)
            arrowImg:setPosition(cc.p(sortTypeBtn:getContentSize().width *0.5 - 50,sortTypeBtn:getContentSize().height *0.5))
            sortTypeBtn:addChild(arrowImg)
            -- if v.tag == 4 then
            arrowImg:setVisible(false)
            -- end

            if i < table.nums(sortType) then
                local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), centerPos.x, centerPos.y - cellSize.height * 0.5)
                sortBoard:addChild(splitLine)
            end
        end


        return {
            view 			= view,
            gridView 		= gridView,
            screenBtn = screenBtn,
            screenLabel = screenLabel,
            screenBoard = screenBoard,
            nameAndFigthLabel = nameAndFigthLabel,
            captainDesLabel = captainDesLabel,

            screenTab = screenTab,
            sortTab = sortTab,
            sortBtn = sortBtn,
            sortLabel = sortLabel,
            sortBoard = sortBoard,
            arrowImg = arrowImg,

        }
    end



    self.viewData_ = CreateView()
    display.commonUIParams(self.viewData_.view, {po = display.center})
    self:addChild(self.viewData_.view,1)

    local gridView = self.viewData_.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

    self.TtempTab = {}
    self.Tcards = gameMgr:GetUserInfo().cards


    self:ScreenCards(0)
    end

--[[
显示切换卡牌灵力和名字
--]]
function ChooseCardsHouseView:NameAndFigthBtnCallback(sender)
    PlayAudioByClickNormal()
    local checked = sender:isChecked()
    if not checked then
        self.viewData_.nameAndFigthLabel:setString(__('显示灵力'))
    else
        self.viewData_.nameAndFigthLabel:setString(__('显示名称'))
    end
    self.showNameOrFight = checked
    local gridView = self.viewData_.gridView
    local contentOffset = gridView:getContentOffset()
    gridView:reloadData()
    gridView:setContentOffset(contentOffset)
end
--[[
    判断是否在飨灵屋的里面
]]
function ChooseCardsHouseView:JuageIdIsInCardHouseData(id)
    self.cardHouseData= self.cardHouseData or {}
    return self.cardHouseData[tostring(id)]
end
--[[
    添加图片的Image
--]]
function ChooseCardsHouseView:AddSelctImage(parentNode )
    local node = parentNode:getChildByName("selectImage")
    if node and ( not  tolua.isnull(node) )then
        return node
    else
        node = display.newImageView(_res('ui/common/common_btn_check_selected.png'),164,160 )
        node:setName("selectImage")
        parentNode:addChild(node,10000)
    end
    return node
end
--[[
筛选按钮回调
--]]
function ChooseCardsHouseView:ScreenBtnCallback(sender)
    PlayAudioByClickNormal()
    local checked = sender:isChecked()
    self:ShowScreenBoard(checked)
end
--[[
显示筛选板
@params visible bool 是否显示筛选板
--]]
function ChooseCardsHouseView:ShowScreenBoard(visible)
    self.viewData_.screenBtn:setChecked(visible)
    self.viewData_.screenBoard:setVisible(visible)
    local labelColor = '#ffffff'--
    if visible then
        labelColor = '#ffffff'
    end
    self.viewData_.screenLabel:setColor(ccc3FromInt(labelColor))
end

--[[
筛选按钮点击回调
--]]
function ChooseCardsHouseView:ScreenTypeBtnCallback(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    self:ScreenCards(tag)
    self.viewData_.screenLabel:setString(screenType[tag + 1].descr or CardUtils.GetCardCareerName(tag))
    self:ShowScreenBoard(false)
end

--[[
排序整个界面
@params pattern int 排序模式
0 默认所有卡牌按照 id 排序
1 所有防御型
2 所有近战 dps
3 所有远程 dps
4 所有辅助型
--]]
function ChooseCardsHouseView:ScreenCards(pattern)
    local tag = pattern
    self.Tdata = {}
    for i,v in pairs(self.Tcards) do
        v.specialType = 0
        local CardData = CommonUtils.GetConfig('cards', 'card', v.cardId)
        if CardData then
            v.name = CardData.name
            v.qualityId = CardData.qualityId
            if tag == CARD_FILTER_TYPE_DEF and checkint(CardData.career) == tag then
                table.insert(self.Tdata,v)
            elseif tag == CARD_FILTER_TYPE_NEAR_ATK and checkint(CardData.career) == tag then
                table.insert(self.Tdata,v)
            elseif tag == CARD_FILTER_TYPE_REMOTE_ATK and checkint(CardData.career) == tag then
                table.insert(self.Tdata,v)
            elseif tag == CARD_FILTER_TYPE_DOCTOR and checkint(CardData.career) == tag then
                table.insert(self.Tdata,v)
            elseif tag == 0 then
                --在引导过程中选人可能在餐厅工作的问题
                table.insert(self.Tdata,v)
            end
        end
    end
    for i, v in pairs(self.Tdata) do
        v.battlePoint = checkint(cardMgr.GetCardStaticBattlePointById(checkint(v.id)))
        v.level             = tonumber(v.level)
        v.breakLevel        = tonumber(v.breakLevel)
        v.qualityId         = tonumber(v.qualityId)
        v.specialType       = tonumber(v.specialType)
    end

    -- sortByMember(self.Tdata, "id", false)
    if self.datas.id then
        self.Tdata =  self.Tdata ~= nil and self.Tdata or {}
        local tempTab = {specialType = 1,level =1,breakLevel =1,qualityId = 1,battlePoint =  0}
        table.insert(self.Tdata,1,tempTab)
    end


    local sortRule =  { sort = { "specialType", "qualityId", "breakLevel", "level", "battlePoint" }, ignoreLowUp = true }
    self:SortTableByRule(self.Tdata , sortRule)


    self.viewData_.gridView:setCountOfCell(table.nums(self.Tdata))
    self.viewData_.gridView:reloadData()
end
--[[
排序按钮回调
--]]
function ChooseCardsHouseView:SortBtnCallback(sender)
    PlayAudioByClickNormal()
    local checked = sender:isChecked()
    self:ShowSortBoard(checked)
    local str = ''
    if not checked then
        str = '#ffffff'
    else
        str = '#ffcf96'
    end
    self.viewData_.sortLabel:setColor(ccc3FromInt(str))
end
--[[
显示排序板
@params visible bool 是否显示排序板
--]]
function ChooseCardsHouseView:ShowSortBoard(visible)
    self.viewData_.sortBtn:setChecked(visible)

    if visible == true then
        self.viewData_.sortBoard:setScaleY(0)
        for i=1,10 do
            self.viewData_.sortBoard:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.01),cc.CallFunc:create(function ()
                self.viewData_.sortBoard:setScaleY(i*0.1)
            end)))
        end
        self.viewData_.sortBoard:setVisible(visible)
    else
        self.viewData_.sortBoard:setScaleY(1)
        self.viewData_.sortBoard:setVisible(visible)
    end


    local str = self.viewData_.sortLabel:getString()
    local index = 0
    for i,v in ipairs(sortType) do
        if str == v.descr then
            index = i
            break
        end
    end

    for i,v in ipairs(self.viewData_.sortTab) do
        local sortIcon = v:getChildByTag(9)
        local selectIcon = v:getChildByTag(99)
        if sortIcon then
            selectIcon:setVisible(false)
            sortIcon:setVisible(false)
            if i == index then
                selectIcon:setVisible(true)
                if i ~= 1 then
                    sortIcon:setVisible(true)
                end
            end
        end
    end
end

--[[
排序按钮点击回调
--]]
function ChooseCardsHouseView:SortTypeBtnCallback(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    self.sortBtnState[tag+1] = sender:isChecked()
    self.viewData_.sortLabel:setString(sortType[tag + 1].descr)
    self.viewData_.sortLabel:setColor(ccc3FromInt('#ffffff'))
    self:ShowSortBoard(false)
    self:SortAction(tag+1,sender:getChildByTag(9),self.viewData_.arrowImg)
end
function ChooseCardsHouseView:SortAction(tag,btn,arrowImg)
    if tag ~= 1 then
        arrowImg:setVisible(true)
    else
        arrowImg:setVisible(false)
    end
    local sortRuleTable = {
        { sort = { "specialType", "qualityId", "breakLevel", "level", "battlePoint" }, ignoreLowUp = true },
        { sort = { "specialType", "level", "qualityId", "breakLevel", "battlePoint" }, ignoreLowUp = false },
        { sort = { "specialType", "qualityId", "breakLevel", "level", "battlePoint" }, ignoreLowUp = false },
        { sort = { "specialType", "battlePoint", "qualityId", "breakLevel", "level" }, ignoreLowUp = false },
        { sort = { "specialType", "breakLevel", "qualityId", "level", "battlePoint" }, ignoreLowUp = false },
    }
    local sortRule = sortRuleTable[tag]
    if not sortRule.ignoreLowUp then
        if self.sortBtnState[tag] then
            btn:setRotation(0)
            arrowImg:setRotation(180)
        else
            btn:setRotation(180)
            arrowImg:setRotation(0)
        end
    end
    for i, v in pairs(self.Tdata) do
        v.battlePoint = checkint(cardMgr.GetCardStaticBattlePointById(checkint(v.id)))
        v.level             = tonumber(v.level)
        v.breakLevel        = tonumber(v.breakLevel)
        v.qualityId         = tonumber(v.qualityId)
        v.specialType       = tonumber(v.specialType)
    end
    self:SortTableByRule(self.Tdata , sortRule , self.sortBtnState[tag])
    self.viewData_.gridView:setCountOfCell(table.nums(self.Tdata))
    self.viewData_.gridView:reloadData()
end

function ChooseCardsHouseView:SortTableByRule(cardsData  , sortRule , isUpAndDown)
    local r = nil
    local sort = sortRule.sort
    local ignoreLowUp = sortRule.ignoreLowUp
    table.sort(cardsData, function(a, b )
        r  = nil
        if  a[sort[1]] ==  b[sort[1]] then
            if  a[sort[2]] ==  b[sort[2]] then
                if  a[sort[3]] ==  b[sort[3]] then
                    if  a[sort[4]] ==  b[sort[4]] then
                        r = a[sort[5]] > b[sort[5]]
                    else
                        r = a[sort[4]] > b[sort[4]]
                    end
                else
                    r = a[sort[3]] > b[sort[3]]
                end
            else
                if ignoreLowUp then
                    r = a[sort[2]] > b[sort[2]]
                else
                    if isUpAndDown then
                        r = a[sort[2]] > b[sort[2]]
                    else
                        r = a[sort[2]] < b[sort[2]]
                    end
                end
            end
        else
            r = a[sort[1]] >  b[sort[1]]
        end
        return r
    end)
end

function ChooseCardsHouseView:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local cardHeadNode = nil
    local tempBtn = nil
    local bg = self.viewData_.gridView
    local sizee = cc.size(200,225)--225
    xTry(function()
        if nil ==  pCell  then
            pCell = CGridViewCell:new()
            cardHeadNode = require('common.CardHeadNode').new({showName = true,showNameOrFight = self.showNameOrFight,specialType = self.Tdata[index].specialType ,id = checkint(self.Tdata[index].id),
                                                               showActionState = false})

            sizee = cardHeadNode:getContentSize()

            cardHeadNode:setTag(2345)
            pCell:setContentSize(sizee)
            cardHeadNode:setPosition(cc.p(sizee.width * 0.5 ,sizee.height * 0.5 + 18 + 14))
            pCell:addChild(cardHeadNode)
            if index < 15 then
                cardHeadNode:setScale(0.5)
                cardHeadNode:runAction(cc.Sequence:create(
                        cc.Spawn:create(cc.FadeIn:create(0.4), cc.ScaleTo:create(0.4,1)),
                        cc.CallFunc:create(function ()
                            cardHeadNode:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
                        end))
            )
            end
        end

        cardHeadNode = pCell:getChildByTag(2345)
        cardHeadNode:setScale(1)
        cardHeadNode:setOpacity(255)
        cardHeadNode:RefreshUI({specialType = self.Tdata[index].specialType ,
                                id = checkint(self.Tdata[index].id),
                                showActionState = false,showName = true,showNameOrFight = self.showNameOrFight})
        cardHeadNode:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
        if self.Tdata[index].specialType == 1 then
            cardHeadNode.viewData.specialLabel:setString(__('移除'))
        end
        local node = self:AddSelctImage(cardHeadNode)
        if self:JuageIdIsInCardHouseData(self.Tdata[index].id) then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
        pCell:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
cell事件处理逻辑
@param sender button对象
--]]
function ChooseCardsHouseView:cellCallBackActions( sender  )
    PlayAudioByClickNormal()
    local tag = sender:getParent():getTag()
    if self.type == 1 then
        --不在任何状态
        if tag == 1 then
            if self.datas.id then
                if self.callback then
                    self.datas.id = nil
                    self.callback(self.datas)
                end
            else
                local data =  clone(self.Tdata[tag])
                self.datas.id  = data.id
                self.callback(self.datas)
            end
        else
            if self.callback then
                local data =  clone(self.Tdata[tag])
                self.datas.id  = data.id
                self.callback(self.datas)
            end
        end

        self:runAction(cc.RemoveSelf:create())
    else
        local func  = function (skinId)
            local data =  clone(self.Tdata[tag])
            data.skinId =skinId
            self.callback(data)
            self:runAction(cc.RemoveSelf:create())
        end
        local id = self.Tdata[tag].id 
        local cardDatas = self:GetCardSkinDataById(id)
        if #cardDatas > 1 then
            local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
            uiMgr:AddDialog('Game.views.ChangeCardSkinView', {id = self.Tdata[tag].id  , callback = func ,cardDatas = cardDatas })
        elseif #cardDatas == 1 then
            func(cardDatas[1].skinId)
        else
            if self and (not tolua.isnull(self) )  then
                self:runAction(cc.RemoveSelf:create())
            end
        end
    end
end

function ChooseCardsHouseView:GetCardSkinDataById(id)
    local cardData = gameMgr:GetCardDataById(id)
    local ownerSkinData = self:GetOwnerSkinByCardId(cardData.cardId)
    local cardDatas = {}
    for i = 1 , #ownerSkinData do
        local data = {}
        data.cardId = cardData.cardId
        data.skinId = ownerSkinData[i]
        data.breakLevel = cardData.breakLevel
        data.level = cardData.level
        cardDatas[#cardDatas+1] = data
    end
    return cardDatas
end
--[[
    根据卡牌的cardId 获取到已经拥有的id
--]]
function ChooseCardsHouseView:GetOwnerSkinByCardId(cardId)
    local skinData = gameMgr:GetUserInfo().cardSkins
    local cardSkinConfig = CommonUtils.GetConfigAllMess('cardSkin','goods' )

    local  cardData = CommonUtils.GetConfig('cards', 'card', cardId)
    local data =  {}
    for i =1 , #skinData do
        for k , v in pairs(cardData.skin) do
            for kk , vv in pairs(v) do
                local cardSkinOneData =cardSkinConfig[tostring(kk)]
                if checkint(cardSkinOneData.unlockType) ~= 2  then
                    if checkint(vv) == checkint(skinData[i]) then
                        data[#data+1] = vv
                    end
                end
            end
        end
    end
    return data
end
--[[
	刷新界面信息
--]]
function ChooseCardsHouseView:RefreshUI()

end

function ChooseCardsHouseView:onEnter()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false , tag = DISABLE_EDITBOX_MEDIATOR.PERSON_DETAIL_TAG})
    -- add touch listener
end

function ChooseCardsHouseView:onExit()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true , tag = DISABLE_EDITBOX_MEDIATOR.PERSON_DETAIL_TAG})
end


return ChooseCardsHouseView
