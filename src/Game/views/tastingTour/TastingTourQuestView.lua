--[[
 * descpt : 品鉴之旅 探索 界面
]]
local VIEW_SIZE = display.size
local TastingTourQuestView = class('TastingTourQuestView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tastingTour.TastingTourQuestView'
	node:enableNodeEvents()
	return node
end)

local CreateView           = nil
local CreateQuestDescView_ = nil
local CreateGroupTaskCell_ = nil
local CreateQuestTaskCell_      = nil

local tastingTourMgr = AppFacade.GetInstance():GetManager("TastingTourManager")

local VIEW_TAG = {
    GROUP_TASK      = 1,
    QUEST_DESC      = 2,
}

local GROUP_TASK_TAG = {
    COMPLETED = 1,
    CONDUCT   = 2,
    LOCK  = 3,
}

local QUEST_TASK_TAG = {
    NORMAL      = 1,
    SELECT      = 2,
    COUNT_DOWN  = 3,
}

local RES_DIR = {
    BG_WORLD_TITLE                 = _res("ui/tastingTour/quest/fishtravel_main_bg_world_title.png"),
    BTN_WORLD_TITLE                = _res("ui/tastingTour/quest/fishtravel_main_btn_world_title.png"),
    TASK_BG                        = _res("ui/tastingTour/quest/fishtravel_main_list_bg_l.png"),
    BTN_RULE                       = _res('ui/common/common_btn_tips.png'),

    GROUP_TASK_SELECTED            = _res("ui/tastingTour/quest/fishtravel_main_area_title_btn_selected_1.png"),

    ICON_RIGHT                     = _res("ui/tastingTour/quest/fishtravel_main_ico_right.png"),
    ICO_TRIANGLE                   = _res("ui/tastingTour/quest/fishtravel_main_area_title_ico_triangle.png"),
    ICO_LOCK                       = _res('ui/common/common_ico_lock.png'),
    SCENIC_SPOT_DEFAULT            = _res('ui/manual/mapoverview/pokedex_maps_btn_scenic_spot_default'),
    SCENIC_SPOT_LOCK               = _res('ui/manual/mapoverview/pokedex_maps_btn_scenic_spot_lock'),

    TITLE_LABEL_NUM_BG             = _res("ui/tastingTour/quest/fishtravel_main_area_title_label_num.png"),
    ICO_FISHSTAR                   = _res("ui/tastingTour/quest/fishtravel_main_list_ico_star_s.png"),
    AWARDS_BG_DOCK                 = _res("ui/tastingTour/quest/fishtravel_main_awards_bg_dock.png"),
    AWARDS_ICO_AVAILABLE           = _res("ui/tastingTour/quest/fishtravel_main_awards_ico_available.png"),
    AWARDS_ICO_GET                 = _res("ui/tastingTour/quest/fishtravel_main_awards_ico_get.png"),
    AWARDS_ICO_LOCKED              = _res("ui/tastingTour/quest/fishtravel_main_awards_ico_locked.png"),
    LIST_BG                        = _res("ui/tastingTour/quest/fishtravel_main_list_bg_s.png"),
    CELL_DEFAULT                   = _res("ui/tastingTour/quest/fishtravel_main_list_btn_default.png"),
    CELL_SELECTED                  = _res("ui/tastingTour/quest/fishtravel_main_list_btn_selected.png"),
    ICO_STARSLOT                   = _res("ui/tastingTour/quest/fishtravel_main_list_ico_starslot.png"),
    ICO_PASSED                     = _res("ui/tastingTour/quest/fishtravel_main_list_ico_passed.png"),
    COUNTDOWN_BG                   = _res('ui/home/nmain/main_maps_bg_countdown.png'),
}


function TastingTourQuestView:ctor( ... )
    
    self.args = unpack({...})
    self:initialUI()
end

function TastingTourQuestView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end


function TastingTourQuestView:refreshUi(tag)
    local viewData = self:getViewData()
    if tag == VIEW_TAG.GROUP_TASK then
        
    elseif tag == VIEW_TAG.QUEST_DESC then
        self:updateQuestDescView()
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = false})
    view:addChild(shallowLayer)

    local worldTitleLayer = display.newLayer(display.SAFE_R + 60, display.height, {ap = display.RIGHT_TOP, bg = RES_DIR.BG_WORLD_TITLE})
    local worldTitleLayerSize = worldTitleLayer:getContentSize()
    view:addChild(worldTitleLayer, 1)
    
    local worldTitleBtn = display.newButton(35, 100, {ap = display.LEFT_CENTER, n = RES_DIR.BTN_WORLD_TITLE})
    local worldTitleBtnSize = worldTitleBtn:getContentSize()
    display.commonLabelParams(worldTitleBtn, {fontSize = 28, color = '#50130e', offset = cc.p(0, -3)})
    worldTitleLayer:addChild(worldTitleBtn)

    local ruleBtn = display.newButton(worldTitleBtn:getPositionX() + 400, 100, {n = RES_DIR.BTN_RULE, ap = display.LEFT_CENTER})
    worldTitleLayer:addChild(ruleBtn)

    local taskBg = display.newImageView(RES_DIR.TASK_BG, display.SAFE_R + 60, display.cy, {ap = display.RIGHT_CENTER})
    local taskBgSize = taskBg:getContentSize()
    view:addChild(taskBg)

    -- all task group
    local questGroupLayerSize = cc.size(taskBgSize.width - 50, display.height - 105)
    local questGroupLayer = display.newLayer(display.SAFE_R - 160, display.height - 100, {ap = display.CENTER_TOP, size = questGroupLayerSize})
    view:addChild(questGroupLayer)
    -- questGroupLayer:setVisible(false)

    local groupGridViewSize = cc.size(questGroupLayerSize.width - 80, questGroupLayerSize.height)
    local groupGridViewCellSize = cc.size(groupGridViewSize.width, 90)
    -- dump(groupGridViewCellSize)
    local groupGridView = CGridView:create(groupGridViewSize)
    groupGridView:setPosition(cc.p(0, questGroupLayerSize.height / 2))
    -- groupGridView:setBackgroundColor(cc.c3b(100,100,200))
    groupGridView:setAnchorPoint(display.LEFT_CENTER)
    groupGridView:setSizeOfCell(groupGridViewCellSize)
    groupGridView:setColumns(1)
    questGroupLayer:addChild(groupGridView)

    -- view:addChild(CreateQuestDescView_())

    return {
        view              = view,
        shallowLayer      = shallowLayer,
        worldTitleBtn     = worldTitleBtn,
        ruleBtn           = ruleBtn,
        questGroupLayer   = questGroupLayer,
        groupGridView     = groupGridView,
    }
end

CreateQuestDescView_ = function ()
    local size = cc.size(412, display.height)
    local view = display.newLayer(display.SAFE_R, display.height, {ap = display.RIGHT_TOP, size = size})
    
    local titleBg = display.newButton(0, size.height - 95, {ap = display.LEFT_TOP, n = RES_DIR.GROUP_TASK_SELECTED})
    local titleBgSize = titleBg:getContentSize()
    view:addChild(titleBg)

    local triangleImg = display.newImageView(RES_DIR.ICO_TRIANGLE, 16, titleBgSize.height / 2, {ap = display.LEFT_CENTER})
    titleBg:addChild(triangleImg)
    
    local nameLabel = display.newLabel(45, titleBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 24, color = '#794a2f'})
    titleBg:addChild(nameLabel)
    
    local titleNumBg = display.newImageView(RES_DIR.TITLE_LABEL_NUM_BG, titleBgSize.width - 24, titleBgSize.height / 2, {ap = display.RIGHT_CENTER})
    local titleNumBgSize = titleNumBg:getContentSize()
    titleBg:addChild(titleNumBg)

    local starScale = 0.93
    local fishstarIcon = display.newImageView(RES_DIR.ICO_FISHSTAR, titleNumBgSize.width - 3, titleNumBgSize.height / 2 + 2, {ap = display.RIGHT_CENTER})
    fishstarIcon:setScale(starScale)
    titleNumBg:addChild(fishstarIcon)

    local fishstarNumLabel = display.newLabel(fishstarIcon:getPositionX() - fishstarIcon:getContentSize().width * starScale - 2, fishstarIcon:getPositionY(), {ap = display.RIGHT_CENTER, fontSize = 22, color = '#ffffff', text = 1})
    titleNumBg:addChild(fishstarNumLabel)

    -- reward 
    local awardBgDockLayer = display.newLayer(39, size.height - 95 - titleBgSize.height - 5, {ap = display.LEFT_TOP, bg = RES_DIR.AWARDS_BG_DOCK})
    local awardBgDockLayerSize = awardBgDockLayer:getContentSize()
    view:addChild(awardBgDockLayer)

    local rewardBtns = {}
    local offsetX = awardBgDockLayerSize.width / 3
    for i = 1, 3 do
        local rewardBtn = display.newButton(0 + (i - 1) * offsetX, awardBgDockLayerSize.height / 2 + 18, {ap = display.LEFT_CENTER, n = RES_DIR.AWARDS_ICO_LOCKED})
        display.commonLabelParams(rewardBtn, {text = '0/0', fontSize = 20, color = '#fff2e6', offset = cc.p(0, -17)})
        awardBgDockLayer:addChild(rewardBtn)
        table.insert(rewardBtns, rewardBtn)
    end
    
    -- list
    local listSize = cc.size(awardBgDockLayerSize.width, size.height * 0.61)
    local listBgLayer = display.newLayer(39, size.height - 295, {ap = display.LEFT_TOP, bg = RES_DIR.LIST_BG, scale9 = true, size = listSize})
    view:addChild(listBgLayer)
    
    local gridViewCellSize = cc.size(listSize.width, 90)
    local gridView = CGridView:create(cc.size(listSize.width, listSize.height - 10))
    gridView:setPosition(cc.p(listSize.width / 2, listSize.height/ 2))
    gridView:setAnchorPoint(display.CENTER)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    listBgLayer:addChild(gridView)

    view.viewData = {
        titleBg          = titleBg,
        nameLabel        = nameLabel,
        fishstarNumLabel = fishstarNumLabel,
        rewardBtns       = rewardBtns,
        gridView         = gridView,       
    }

    return view
end

CreateGroupTaskCell_ = function ()
    local size = cc.size(505, 90)
    local cell = CGridViewCell:new()
    cell:setContentSize(size)

    local bg = display.newImageView(RES_DIR.GROUP_TASK_SELECTED, 0, size.height / 2, {ap = display.LEFT_CENTER})
    cell:addChild(bg)
    
    local layerSize = bg:getContentSize()
    local touchLayer = display.newLayer(0, size.height / 2,  {ap = display.LEFT_CENTER, enable = true, size = layerSize, color = cc.c4b(0, 0, 0, 0)})
    cell:addChild(touchLayer)

    local triangleImg = display.newImageView(RES_DIR.ICO_TRIANGLE, 28, size.height / 2 - 12, {ap = display.LEFT_CENTER})
    triangleImg:setRotation(-90)
    cell:addChild(triangleImg)
    
    local nameLabel = display.newLabel(40, size.height / 2, {ap = display.LEFT_CENTER, fontSize = 24, color = '#794a2f'})
    cell:addChild(nameLabel)
    
    local size2 = cc.size(140, 90)
    local layer = display.newLayer(260, size.height / 2, {ap = display.LEFT_CENTER, size = size2})
    cell:addChild(layer)
    
    local completedLabel = display.newLabel(38, size2.height / 2, {ap = display.CENTER, fontSize = 20, color = '#794a2f', text = ""})
    local completedLabelSize = display.getLabelContentSize(completedLabel)
    layer:addChild(completedLabel)
    completedLabel:setVisible(false)
    
    local spot = display.newImageView(RES_DIR.SCENIC_SPOT_DEFAULT, size2.width - 45, size2.height / 2, {ap = display.CENTER})
    spot:setScale(0.6)
    layer:addChild(spot)
    spot:setVisible(false)

    local rightIcon = display.newImageView(RES_DIR.ICON_RIGHT, size2.width - 40, size2.height / 2 + 14, {ap = display.CENTER})
    layer:addChild(rightIcon)
    rightIcon:setVisible(false)

    local lock = display.newImageView(RES_DIR.ICO_LOCK, 38, size2.height / 2, {ap = display.CENTER})
    layer:addChild(lock)
    lock:setVisible(false)

    local animeBase = sp.SkeletonAnimation:create('effects/mapOver/anime_base.json', 'effects/mapOver/anime_base.atlas', 1)
    animeBase:update(0)
    animeBase:setTag(1)
    animeBase:setAnimation(0, 'idle', true)
    animeBase:setPosition(cc.p(size2.width - 45, size2.height / 2))
    animeBase:setScale(0.75)
    layer:addChild(animeBase)
    animeBase:setVisible(false)

    cell.viewData = {
        bg             = bg,
        nameLabel      = nameLabel,
        touchLayer     = touchLayer,
        completedLabel = completedLabel,
        rightIcon      = rightIcon,
        spot           = spot,
        lock           = lock,
        animeBase      = animeBase,
    }
    
    return cell
end

CreateQuestTaskCell_ = function()
    local size = cc.size(355, 90)
    local cell = CGridViewCell:new()
    cell:setContentSize(size)

    local bg = display.newImageView(RES_DIR.CELL_DEFAULT, size.width / 2, size.height / 2, {ap = display.CENTER})
    local bgSize = bg:getContentSize()
    cell:addChild(bg)

    local touchLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, enable = true, size = bgSize, color = cc.c4b(0, 0, 0, 0)})
    cell:addChild(touchLayer)

    local nameLabel = display.newLabel(40, size.height / 2, {ap = display.LEFT_CENTER, w = 22 * 7 + 5, fontSize = 22, color = '#76553b'})
    cell:addChild(nameLabel)
 
    local starBgs = {}
    local stars = {}
    for i = 1, 3 do
        local starBg = display.newImageView(RES_DIR.ICO_STARSLOT, 0, 0)
        local starBgSize = starBg:getContentSize()
        display.commonUIParams(starBg, {po = cc.p(228 + (i - 1) * starBgSize.width, size.height / 2), ap = display.CENTER})
        cell:addChild(starBg)
        table.insert(starBgs, starBg)

        local star = display.newImageView(RES_DIR.ICO_FISHSTAR, starBgSize.width / 2, starBgSize.height / 2, {ap = display.CENTER})
        -- star:setScale(0.22)
        starBg:addChild(star)
        table.insert(stars, star)

    end

    local countDown = display.newButton(271, 26, {n = RES_DIR.COUNTDOWN_BG, enable = false, scale9 = true, size = cc.size(98, 24)})
    display.commonLabelParams(countDown, {fontSize = 20, color = '#5b3c25', ttf = true, font = TTF_GAME_FONT, text = '--:--:--'})
    cell:addChild(countDown)
    
    local passIcon = display.newImageView(RES_DIR.ICO_PASSED, size.width - 18, size.height, {ap = display.RIGHT_TOP})
    cell:addChild(passIcon)
    passIcon:setVisible(false)

    cell.viewData = {
        bg         = bg,
        nameLabel  = nameLabel,
        stars      = stars,
        starBgs    = starBgs,
        countDown  = countDown,
        touchLayer = touchLayer,
        passIcon   = passIcon,
    }

    return cell
end

function TastingTourQuestView:CreateQuestDescView()
    return CreateQuestDescView_()
end

function TastingTourQuestView:CreateQuestTaskCell()
    return CreateQuestTaskCell_()
end

function TastingTourQuestView:CreateGroupTaskCell()
    return CreateGroupTaskCell_()
end


--==============================--
--desc: 更新任务组 cell 
--time:2018-03-02 10:24:57
--@viewData:
--@state:
--@return 
--==============================-- 
function TastingTourQuestView:updateGroupTaskCell(viewData, state, frameId)
    if viewData == nil then return end
    local bg             = viewData.bg
    local nameLabel      = viewData.nameLabel
    local touchLayer     = viewData.touchLayer
    local completedLabel = viewData.completedLabel
    local rightIcon      = viewData.rightIcon
    local spot           = viewData.spot
    local lock           = viewData.lock
    local animeBase      = viewData.animeBase

    rightIcon:setVisible(false)
    completedLabel:setVisible(false)
    spot:setVisible(false)
    lock:setVisible(false)
    animeBase:setVisible(false)

    display.commonLabelParams(nameLabel, {color = '#794a2f'})

    if state == GROUP_TASK_TAG.LOCK then
        bg:setTexture(string.format("ui/tastingTour/quest/fishtravel_main_area_title_btn_locked_%s.png", frameId))
        display.commonLabelParams(nameLabel, {color = '#524d49'})
        lock:setVisible(true)
        spot:setVisible(true)
        spot:setTexture(RES_DIR.SCENIC_SPOT_LOCK)
    else
        if state == GROUP_TASK_TAG.COMPLETED then
            bg:setTexture(string.format("ui/tastingTour/quest/fishtravel_main_area_title_btn_selected_%s.png", frameId))
            completedLabel:setVisible(true)
            rightIcon:setVisible(true)
            spot:setVisible(true)
            spot:setTexture(RES_DIR.SCENIC_SPOT_DEFAULT)
        elseif state == GROUP_TASK_TAG.CONDUCT then
            bg:setTexture(string.format("ui/tastingTour/quest/fishtravel_main_area_title_btn_selected_%s.png", frameId))
            animeBase:setVisible(true)
        end
    end

end

function TastingTourQuestView:updateQuestDescView(data, curQuestIndex)
    local viewData = self:getViewData()
    local questDescView = viewData.questDescView
    if questDescView == nil then return end
    local questDescViewData = questDescView.viewData

    local titleBg = questDescViewData.titleBg
    local frameId = data.groupConfData.frameId
    local frameImg = string.format("ui/tastingTour/quest/fishtravel_main_area_title_btn_selected_%s.png", frameId)
    titleBg:setNormalImage(_res(frameImg))
    titleBg:setSelectedImage(_res(frameImg))

    local questIds = data.questIds
    local fishstarNumLabel = questDescViewData.fishstarNumLabel
    local fishStarNum = tastingTourMgr:GetGroupStarNumByQuestIds(questIds)
    display.commonLabelParams(fishstarNumLabel, {text = fishStarNum})    

    local listLen = #questIds
    local gridView = questDescViewData.gridView
    gridView:setCountOfCell(listLen)
    gridView:reloadData()

    local offsetH = CommonUtils.calcListContentOffset(gridView:getContentSize().height, listLen, gridView:getSizeOfCell().height, curQuestIndex)
    gridView:setContentOffset(cc.p(0, offsetH))

    local rewardBtns = questDescViewData.rewardBtns
    local groupConfRewards = data.groupConfData.groupRewards or {}
    self:updateGroupRewardBtns(rewardBtns, groupConfRewards, fishStarNum)
        
end

function TastingTourQuestView:updateGroupRewardBtns(rewardBtns, groupConfRewards, fishStarNum)
    for i, btn in ipairs(rewardBtns) do
        local groupRewardId = groupConfRewards[tostring(i)]
        -- 1. 检查是否已经领取
        local oneGroupRewardConf = tastingTourMgr:GetOneGroupRewardConfig(groupRewardId)
        local startNum = checkint(oneGroupRewardConf.starNum)

        local rewardStaus = tastingTourMgr:GetGroupRewardStatus(groupRewardId, fishStarNum)

        if rewardStaus == 0 then
            btn:setNormalImage(RES_DIR.AWARDS_ICO_LOCKED)
            btn:setSelectedImage(RES_DIR.AWARDS_ICO_LOCKED)
            display.commonLabelParams(btn, {text = string.format("%s/%s", fishStarNum, startNum)})
        elseif rewardStaus == 1 then
            btn:setNormalImage(RES_DIR.AWARDS_ICO_AVAILABLE)
            btn:setSelectedImage(RES_DIR.AWARDS_ICO_AVAILABLE)
            display.commonLabelParams(btn, {text = string.format("%s/%s", fishStarNum, startNum)})
        elseif rewardStaus == 2 then
            btn:setNormalImage(RES_DIR.AWARDS_ICO_GET)
            btn:setSelectedImage(RES_DIR.AWARDS_ICO_GET)
            display.commonLabelParams(btn, {text = __('已领取')})
        end
    end
end

function TastingTourQuestView:updateQuestTaskCell(viewData, questConfData, serQuestData, isSelect)
    if viewData == nil then return end
    
    self:updateQuestCellBg(viewData, isSelect)

    -- update quest name
    local nameLabel  = viewData.nameLabel
    local name = tostring(questConfData.name)
    display.commonLabelParams(nameLabel, {text = name})

    -- update star
    local stars        = viewData.stars
    local starNum     = checkint(serQuestData.starNum)
    self:updateQuestStarsUi(stars, starNum)
    
    -- update contdown
    local countDown  = viewData.countDown
    local leftSeconds = checkint(serQuestData.leftSeconds)
    self:updateQuestCountDownUi(countDown, leftSeconds)

    -- update passIcon show hint
    local passIcon   = viewData.passIcon
    passIcon:setVisible(starNum >= 3)
   
end

function TastingTourQuestView:updateQuestCellSelectState(gridView, idx, isSelect)
    local cell = gridView:cellAtIndex(idx)
    if cell then
        self:updateQuestCellBg(cell.viewData, isSelect)
    end
end

function TastingTourQuestView:updateQuestCellBg(viewData, isSelect)
    local bg         = viewData.bg
    bg:setTexture(isSelect and RES_DIR.CELL_SELECTED or RES_DIR.CELL_DEFAULT)
end

function TastingTourQuestView:updateQuestStarsUi(stars, starNum)
    for i, star in ipairs(stars) do
        local isFinsh = starNum >= i
        star:setVisible(isFinsh)
        -- star:setTexture(isFinsh and RES_DIR.ICO_FISHSTAR or RES_DIR.ICO_STARSLOT)
        -- star:setScale(isFinsh and 0.25 or 1)
    end
end

function TastingTourQuestView:updateQuestCountDownUi(countDown, leftSeconds)
    if countDown == nil then return end
    local isShowCountDown = leftSeconds > 0
    countDown:setVisible(isShowCountDown)
    
    if isShowCountDown then
        display.commonLabelParams(countDown, {text = CommonUtils.getTimeFormatByType(leftSeconds)})
        local labelSize = display.getLabelContentSize(countDown:getLabel())
        countDown:setContentSize(cc.size(labelSize.width + 12, 26))
    end
end

function TastingTourQuestView:showUiAction(tag)
    local viewData = self:getViewData()

    local view1 = nil
    local view2 = nil
    if VIEW_TAG.GROUP_TASK == tag then
        view1 = viewData.questDescView
        view2 = viewData.questGroupLayer
    elseif VIEW_TAG.QUEST_DESC == tag then
        view1 = viewData.questGroupLayer
        view2 = viewData.questDescView
    end

    view2:setVisible(true)
    self:runAction(cc.Spawn:create(
        cc.TargetedAction:create(view1, cc.Sequence:create(
            cc.EaseSineOut:create(cc.MoveBy:create(0.3, cc.p(550,0))),
            cc.CallFunc:create(function ()
                view1:setVisible(false)
            end),
            cc.MoveBy:create(0, cc.p(-550, 0))
        )),
        cc.TargetedAction:create(view2, cc.Sequence:create(
            cc.MoveBy:create(0, cc.p(550, 0)),
            cc.EaseSineOut:create(cc.MoveBy:create(0.3, cc.p(-550,0)))
        ))
    ))
end

function TastingTourQuestView:getViewData()
	return self.viewData_
end

return TastingTourQuestView