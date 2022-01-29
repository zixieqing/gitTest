local CatModuleAchievementView = class('CatModuleAchievementView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleAchievementView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME   = _res('ui/common/common_bg_12.png'),
    BTN_CONFIRM  = _res('ui/common/common_btn_orange.png'),
    BTN_DISABLE  = _res('ui/common/common_btn_orange_disable.png'),
    CELL_S       = _res('ui/common/common_bg_list_active.png'),
    CELL_N       = _res('ui/common/common_bg_list_unlock.png'),
    BTN_REFRESH  = _res('ui/home/commonShop/shop_btn_refresh.png'),
    TITLE_S      = _res('ui/catModule/catInfo/achievement/grow_cat_cup_bg_head_light.png'),
    TITLE_N      = _res('ui/catModule/catInfo/achievement/grow_cat_cup_bg_head_grey.png'),
    BTN_N        = _res('ui/catModule/catInfo/achievement/grow_cat_cup_ico_circle.png'),
    BTN_S        = _res('ui/catModule/catInfo/achievement/grow_cat_cup_ico_ok.png'),
    IMG_OK       = _res('ui/catModule/catInfo/achievement/grow_cat_cup_ico_grt.png'),
    IMG_DRAWN    = _res('ui/common/activity_mifan_by_ico.png'),
    PROGRESS_BG  = _res('ui/catModule/catInfo/achievement/grow_cat_cup_line_bg.png'),
    PROGRESS_IMG = _res('ui/catModule/catInfo/achievement/grow_cat_cup_line_light.png'),
    PASS_SPINE   = _spn('ui/catModule/catInfo/achievement/anim/cup_light'),
}

CatModuleAchievementView.ACHIEVEMENT_TYPE = {
    CAREER_NEED    = 154, -- 职业需求
    ABILITY_NEED   = 155, -- 能力需求
}

function CatModuleAchievementView:ctor(args)
    -- create view
    self.viewData_ = CatModuleAchievementView.CreateView()
    self:addChild(self.viewData_.view)
end

-------------------------------------------------------------------------------
-- get/set
-------------------------------------------------------------------------------
function CatModuleAchievementView:getViewData()
    return self.viewData_
end
-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

---@param catModel HouseCatModel
function CatModuleAchievementView:updateCellView(cellIndex, cellViewData, taskConfs, catModel)
    local targetIdDescr = ""
    local curProgress   = 0
    local taskType      = checkint(taskConfs.taskType)
    local arrDescrs     = string.split(taskConfs.descr, ";")
    local taskConf      = checktable(taskConfs.targets[cellIndex])
    local targetValue   = checkint(taskConf.targetNum)
    if taskType == self.ACHIEVEMENT_TYPE.CAREER_NEED then
        local careerConf = CONF.CAT_HOUSE.CAT_CAREER_INFO:GetValue(taskConf.targetId)
        targetIdDescr = tostring(careerConf[next(careerConf)].groupName)

        curProgress = checkint(catModel:getCareerLevel(taskConf.targetId))
    elseif taskType == self.ACHIEVEMENT_TYPE.ABILITY_NEED then
        local abilityConf = CONF.CAT_HOUSE.CAT_ABILITY:GetValue(taskConf.targetId)
        targetIdDescr = tostring(abilityConf.name)
        curProgress = checkint(catModel:getAbility(taskConf.targetId))
    end
    cellViewData.title:updateLabel({text = tostring(arrDescrs[cellIndex]), reqW = 520})

    cellViewData.progress:setValue(curProgress / targetValue * 100)
    cellViewData.progressStr:setString(string.fmt("_num1_/_num2_", {_num1_ = curProgress, _num2_ = targetValue}))
    cellViewData.achieveImg:setChecked(curProgress >= targetValue)
    cellViewData.bg:setChecked(curProgress > targetValue)
end

-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------

---@param catModel HouseCatModel
function CatModuleAchievementView:updatePageView(achieveConf, hasDrawn, catModel)
    display.commonLabelParams(self:getViewData().title, {text = achieveConf.name, reqW = 400})
    self:updateRewardState(hasDrawn)
    
    if not hasDrawn then
        local isPassed = true
        local taskType = checkint(achieveConf.taskType)
        local progress = 0

        for _, taskConf in pairs(achieveConf.targets) do
            if taskType == self.ACHIEVEMENT_TYPE.CAREER_NEED then
                progress = checkint(catModel:getCareerLevel(taskConf.targetId))
            elseif taskType == self.ACHIEVEMENT_TYPE.ABILITY_NEED then
                progress = checkint(catModel:getAbility(taskConf.targetId))
            end
            if progress < checkint(taskConf.targetNum) then
                isPassed = false
                break
            end
        end
        self:getViewData().receiveBtn:setEnabled(isPassed)
        
        if isPassed and not self.passedSpine_ then
            self.passedSpine_ = ui.spine({path = RES_DICT.PASS_SPINE, init = "play1"})
            self:getViewData().view:addList(self.passedSpine_):alignTo(nil, ui.cb, {offsetY = 140})
        elseif not isPassed and not tolua.isnull(self.passedSpine_) then
            self.passedSpine_:runAction(cc.RemoveSelf:create())
            self.passedSpine_ = nil
        end
    end
    
end


function CatModuleAchievementView:updateRewardState(hasDrawn)
    self:getViewData().refreshBtn:setVisible(not hasDrawn)
    self:getViewData().okIcon:setVisible(hasDrawn)
    self:getViewData().receiveBtn:setVisible(not hasDrawn)
    self:getViewData().drawnIcon:setVisible(hasDrawn)
    self:getViewData().titleBg:setChecked(hasDrawn)

    if hasDrawn and self.passedSpine_ then
        self.passedSpine_:runAction(cc.RemoveSelf:create())
        self.passedSpine_ = nil
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleAchievementView.CreateTaskCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0)})
    cellParent:add(view)

    local bg = ui.tButton({n = RES_DICT.CELL_N, s = RES_DICT.CELL_S, scale9 = true, size = cc.resize(size, -10, -10)})
    view:addList(bg):alignTo(nil, ui.cc)

    local infoGroup = view:addList({
        ui.label({fnt = FONT.D4, color = "#5a3236", text = "--", ap = ui.lc}),
        ui.pBar({bg = RES_DICT.PROGRESS_BG, img = RES_DICT.PROGRESS_IMG}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.lc), 20, 0), infoGroup, {type = ui.flowV, ap = ui.lc, gapH = 15})

    local achieveImg = ui.tButton({n = RES_DICT.BTN_N, s = RES_DICT.BTN_S})
    view:addList(achieveImg):alignTo(nil, ui.rc, {offsetY = -5})

    local progress    = infoGroup[2]
    local progressStr = ui.label({fnt = FONT.D4, fontSize = 18, text = "--", color = "#FFFFFF"})
    progress:addList(progressStr, 3):alignTo(nil, ui.cc)

    return {
        bg          = bg,
        title       = infoGroup[1],
        progress    = progress,
        achieveImg  = achieveImg,
        progressStr = progressStr,
    }
end

function CatModuleAchievementView.CreateView()
    local view = ui.layer()
    local size = cc.size(570, 600)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({color = cc.r4b(0), size = size, enable = true}),
        ui.layer({bg = RES_DICT.VIEW_FRAME, size = size, scale9 = true}),
    })
    ui.flowLayout(cc.sizep(view, ui.cc), backGroundGroup, {type = ui.flowC, ap = ui.cc})

    ------------------------------------------------- [center]
    local centerLayer = backGroundGroup[3]
    local viewFrameGroup = centerLayer:addList({
        ui.tButton({n = RES_DICT.TITLE_N, s = RES_DICT.TITLE_S, mt = 5}),
        ui.tableView({size = cc.size(547, 330), csizeH = 92, dir = display.SDIR_V, mt = 20}),
        ui.layer({size = cc.size(547, 130), mt = 10}),
    })
    ui.flowLayout(cc.sizep(centerLayer, ui.ct), viewFrameGroup, {type = ui.flowV, ap = ui.cb, gapH = 5})

    -- title
    local titleBg = viewFrameGroup[1]
    titleBg:addList(ui.label({fnt = FONT.D4, color = "#5a3236", text = __("解锁成就")})):alignTo(nil, ui.ct, {offsetY = -5})
    local title   = ui.label({fnt = FONT.D14, outline = "#50262b", text = "--"})
    titleBg:addList(title):alignTo(nil, ui.cc, {offsetY = -15})

    local refreshBtn = ui.button({n = RES_DICT.BTN_REFRESH})
    centerLayer:addList(refreshBtn):alignTo(titleBg, ui.rc, {offsetY = -15, offsetX = -90})
    local okIcon = ui.image({img = RES_DICT.IMG_OK})
    centerLayer:addList(okIcon):alignTo(titleBg, ui.rc, {offsetY = -15, offsetX = -115})

    local tipLabel = ui.label({fnt = FONT.D10, text = __("TIP:每只猫咪的成就终身只能完成一次"), reqW = 520})
    centerLayer:addList(tipLabel):alignTo(titleBg, ui.cb, {offsetY = -3})


    -- task tableView
    local taskTableView = viewFrameGroup[2]
    taskTableView:setCellCreateHandler(CatModuleAchievementView.CreateTaskCell)

    -- rewards
    local rewardLayer = viewFrameGroup[3]
    local rewardGroup = rewardLayer:addList({
        ui.label({fnt = FONT.D9, color = "#bd9574", text = __("成就达成后可领取奖励"), reqW = 540}),
        ui.tableView({size = cc.size(370, 100), dir = display.SDIR_H, csizeW = 100}),
    })
    ui.flowLayout(cc.sizep(rewardLayer, ui.lc), rewardGroup, {type = ui.flowV, ap = ui.lc, gapH = 5})

    local goodTabView = rewardGroup[2]
    goodTabView:setCellCreateClass(require("common.GoodNode"), {showAmount = true, scale = 0.75, callBack = function(sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(sender.goodId), type = 1})
    end})

    -- draw btn 
    local receiveBtn = ui.button({n = RES_DICT.BTN_CONFIRM, d = RES_DICT.BTN_DISABLE}):updateLabel({fnt = FONT.D14, text = __("领取"), reqW = 110})
    rewardLayer:addList(receiveBtn):alignTo(nil, ui.rc, {offsetY = -15, offsetX = -20})

    local drawnIcon  = ui.title({img = RES_DICT.IMG_DRAWN}):updateLabel({fnt = FONT.D4, color = "#f5e8d9", text = __("已领取"), paddingW = 20})
    rewardLayer:addList(drawnIcon):alignTo(nil, ui.rc, {offsetY = -15, offsetX = -15})



    return {
        view          = view,
        blockLayer    = backGroundGroup[1],
        drawnIcon     = drawnIcon,
        receiveBtn    = receiveBtn,
        goodTabView   = rewardGroup[2],
        taskTableView = taskTableView,
        title         = title,
        titleBg       = titleBg,
        refreshBtn    = refreshBtn,
        okIcon        = okIcon,
    }
end


return CatModuleAchievementView
