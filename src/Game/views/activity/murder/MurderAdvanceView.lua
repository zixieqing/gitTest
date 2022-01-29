--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）推进view
--]]
local MurderAdvanceView = class('MurderAdvanceView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.murder.MurderAdvanceView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    CLOCK_BG                    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_bg.png'),
    CLOCK_ARROW                 = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_ico_arrow.png'),
    UNLOCK_BG                   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_bg_list.png'),
    COMMON_BTN_N                = app.murderMgr:GetResPath('ui/common/common_btn_orange.png'),
    COMMON_BTN_D                = app.murderMgr:GetResPath('ui/common/common_btn_orange_disable.png'),
    REAUIREMENT_PROGRESS_BAR_BG = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_bar_grey.png'),
    REAUIREMENT_PROGRESS_BAR    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_bar_active.png'),
    REAUIREMENT_GREEN_ICON      = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_ico_greenlight.png'),
    REAUIREMENT_RED_ICON        = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_clock_ico_redlight.png'),

}
function MurderAdvanceView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MurderAdvanceView:InitUI()
    local function CreateView()
        local heightOffset = app.murderMgr:GetTotalHeightOffset()
        local bg = display.newImageView(RES_DICT.CLOCK_BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- 解锁内容背景
        local unlockBg = display.newImageView(RES_DICT.UNLOCK_BG, size.width / 2, 650-heightOffset)
        view:addChild(unlockBg, 2)
        -- 解锁标题
        local unlockTitle = display.newLabel(size.width / 2, 800-heightOffset, {text = app.murderMgr:GetPoText(__('解锁')), fontSize = 22, color = '#483126'})
        view:addChild(unlockTitle, 3)
        -- 解锁列表
        local unlockListViewSize = cc.size(522, 300)
        local unlockListView = CListView:create(unlockListViewSize)
		unlockListView:setDirection(eScrollViewDirectionVertical)
        unlockListView:setAnchorPoint(cc.p(0.5, 0))
		unlockListView:setPosition(size.width / 2, 490 - heightOffset)
        view:addChild(unlockListView, 5)
        -- 需求标题
        local requirementTitle = display.newLabel(size.width / 2, 420 - heightOffset, {text = app.murderMgr:GetPoText(__('需要')), fontSize = 22, color = '#483126'})
        view:addChild(requirementTitle, 3)
        app.murderMgr:AdditionalOffsetTables(requirementTitle, "requirementTitle")

        local requirementList = {}
        for i = 1, 3 do
			local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), size.width / 2 - 170, 428 - 48 * i -heightOffset)
			goodsIcon:setScale(0.2)
            view:addChild(goodsIcon, 3)
            local progressBarBg = display.newImageView(RES_DICT.REAUIREMENT_PROGRESS_BAR_BG, size.width / 2, 428 - 48 * i - heightOffset)
            view:addChild(progressBarBg, 1)
            local pointProgressBar = CProgressBar:create(RES_DICT.REAUIREMENT_PROGRESS_BAR)
            pointProgressBar:setPosition(size.width / 2, 428 - 48 * i- heightOffset)
            pointProgressBar:setMaxValue(100)
            pointProgressBar:setValue(50)
            pointProgressBar:setDirection(eProgressBarDirectionLeftToRight)
            view:addChild(pointProgressBar, 3)
            local progressBarRichLabel = display.newRichLabel(size.width / 2, 428 - 48 * i - heightOffset, {})
            view:addChild(progressBarRichLabel, 3)
            local stateIcon = display.newImageView(RES_DICT.REAUIREMENT_RED_ICON, size.width / 2 + 170, 428 - 48 * i - heightOffset)
            view:addChild(stateIcon, 3)
            local temp = {
                goodsIcon            = goodsIcon,
                pointProgressBar     = pointProgressBar,
                progressBarRichLabel = progressBarRichLabel,
                progressBarBg        = progressBarBg,
                stateIcon            = stateIcon,
            }
            table.insert(requirementList, temp)
        end
        -- 放入按钮
        local putBtn = display.newButton(size.width / 2, 205 - heightOffset, {n = RES_DICT.COMMON_BTN_N})
        view:add(putBtn, 5)
        app.murderMgr:AdditionalOffsetTables(putBtn , "putBtn")
        display.commonLabelParams(putBtn, fontWithColor(14, {text = app.murderMgr:GetPoText(__('放入'))}))
        return {
            view               = view,
            requirementList    = requirementList,
            putBtn             = putBtn,
            unlockListViewSize = unlockListViewSize,
            unlockListView     = unlockListView,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
获取viewData
--]]
function MurderAdvanceView:GetViewData()
    return self.viewData
end
--[[
刷新材料需求
@params nextClockLevel int 下一时钟等级
--]]
function MurderAdvanceView:RefreshRequirementList( nextClockLevel )
    local config = CommonUtils.GetConfig('newSummerActivity', 'building', nextClockLevel)
    local viewData = self:GetViewData()
    local requirementList = viewData.requirementList
    local consume = config.consume
    for i = 1, 3 do
        if consume[i] then
            -- 刷新
            local requirementNum = consume[i].num
            local hasNum = app.gameMgr:GetAmountByIdForce(consume[i].goodsId)
            requirementList[i].goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(consume[i].goodsId))
            requirementList[i].pointProgressBar:setMaxValue(requirementNum)
            requirementList[i].pointProgressBar:setValue(hasNum)
            -- 数字颜色
            local color = '#ffffff'
            if hasNum >= requirementNum then
                requirementList[i].stateIcon:setTexture(RES_DICT.REAUIREMENT_GREEN_ICON)
            else
                requirementList[i].stateIcon:setTexture(RES_DICT.REAUIREMENT_RED_ICON)
                color = '#f05959'
            end
            display.reloadRichLabel(requirementList[i].progressBarRichLabel,{ c = {
                {text = tostring(hasNum), fontSize = 24, color = color},
                {text = string.format('/%d', requirementNum), fontSize = 24, color = '#ffffff'},
            }})
        else
            -- 隐藏
            for _, v in pairs(requirementList[i]) do
                v:setVisible(false)
            end
        end
    end
end
--[[
刷新解锁列表
@params nextClockLevel int 下一时钟等级
--]]
function MurderAdvanceView:RefreshUnlockListView( nextClockLevel )
    local viewData = self:GetViewData()
    local unlockListView = viewData.unlockListView
    local unlockConfig = CommonUtils.GetConfigAllMess('moduleUnlock', 'newSummerActivity')
    local module = {} -- 解锁模块
    for k, v in orderedPairs(unlockConfig) do
        if checkint(v.grade) == nextClockLevel then
            table.insert(module, v)
        end
    end
    unlockListView:removeAllNodes()
    for i,v in ipairs(module) do
        local layoutSize = cc.size(viewData.unlockListViewSize.width, 124)
        local layout = CLayout:create(layoutSize)
        local icon = display.newImageView(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/buffIcon/murder_main_clock_ico_buff_%s.png', tostring(v.icon))), 60,layoutSize.height / 2, {ap = display.LEFT_CENTER})
        layout:addChild(icon, 1)
        local title = display.newLabel(175, 95, {text = v.title, color = '#ecaa4d', fontSize = 24, ap = display.LEFT_CENTER})
        layout:addChild(title, 1)
        local descr = display.newLabel(175, 80, {text = v.descr, color = '#ffffff', fontSize = 20, ap = display.LEFT_TOP, w = 300})
        layout:addChild(descr, 1)
        local buffLabel = nil

        if v.type == MURDER_MOUDLE_TYPE.BUFF then
            local config = CommonUtils.GetConfig('newSummerActivity', 'building', nextClockLevel)
            local addditon = (1 + tonumber(config.addition[tostring(app.murderMgr:GetMurderGoodsIdByKey("murder_book_id"))])) * 100
            buffLabel = display.newRichLabel(175, 20, {r = true, ap = display.LEFT_CENTER, c = {
                {text = '100%', fontSize = 20, color = '#ffffff'},
                {text = '  ', fontSize = 20, color = '#ffffff'},
                {img = RES_DICT.CLOCK_ARROW},
                {text = '  ', fontSize = 20, color = '#ecaa4d'},
                {text = string.format('%d%%', addditon), fontSize = 20, color = '#ecaa4d'}
            }})
            layout:addChild(buffLabel, 1)
        end
        local titleHight = display.getLabelContentSize(title).height
        local descrHight = display.getLabelContentSize(descr).height
        local buffHight = 0
        if buffLabel then
            buffHight = 30
        end
        local totalHight = 20 + titleHight + descrHight + buffHight
        if totalHight > layoutSize.height then
            layout:setContentSize(cc.size(layoutSize.width, totalHight))
            icon:setPositionY(totalHight / 2)
            title:setPositionY(totalHight - 20)
            descr:setPositionY(totalHight - 35)
        end
        unlockListView:insertNodeAtLast(layout)
    end
    unlockListView:reloadData()
end
return MurderAdvanceView