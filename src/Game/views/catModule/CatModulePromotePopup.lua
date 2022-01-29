--[[
 * author : panmeng
 * descpt : 职位升阶界面
]]

local CommonDialog   = require('common.CommonDialog')
local CatModulePromotePopup = class('CatModulePromotePopup', CommonDialog)

local RES_DICT = {
    CONFIRM_BTN = _res('ui/common/common_btn_orange.png'),
    CANCEL_BTN  = _res("ui/common/common_btn_white_default.png"),
    BG_FRAME    = _res('ui/catHouse/breed/grow_birth_sure_bg.png'),
    BG_CELL     = _res("ui/catModule/catInfo/work/grow_cat_work_sure_bg_ability.png"),
    BG_TITLE    = _res("ui/catModule/catInfo/work/grow_cat_work_sure_bg_lv.png"),
    BG_ARROW    = _res('ui/collection/cardAlbum/rank_up_ico_arrow.png'),
    VALUE_BG    = _res('ui/catModule/catInfo/work/grow_birth_sure_bg_number.png'),
}

function CatModulePromotePopup:ctor(args)
    self.ctorArgs_ = checktable(args)
    self.super.ctor(self, args)
end

function CatModulePromotePopup:InitialUI()
    -- create view
    self.viewData = CatModulePromotePopup.CreateView()
    self:setPosition(display.center)

    -- bind event
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))
    ui.bindClick(self:getViewData().cancelBtn, handler(self, self.onClickCancelBtnHandler_))

    -- refresh view
    self:setCatUuid(self.ctorArgs_.catUuid)
    self:setCareerId(self.ctorArgs_.careerId)
end


function CatModulePromotePopup:getViewData()
    return self.viewData
end


-------------------------------------------------------------------------------
-- set/get
-------------------------------------------------------------------------------
function CatModulePromotePopup:setCareerId(careerId, careerLvl)
    self.careerId_  = checkint(careerId)
    self:refreshPage()
end
function CatModulePromotePopup:getCareerId()
    return checkint(self.careerId_)
end
function CatModulePromotePopup:getCareerLevel()
    return self:getCatModel():getCareerLevel(self:getCareerId())
end


function CatModulePromotePopup:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
end
function CatModulePromotePopup:getCatUuid()
    return self.catUuid_
end


---@return HouseCatModel
function CatModulePromotePopup:getCatModel()
    return self.catModel_
end

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

function CatModulePromotePopup:updateDamandNode(cellViewData, data)
    cellViewData.value:updateLabel({text = data.value})

    local iconPath = ""
    if data.isAttr then
        iconPath = CatHouseUtils.GetCatAttrTypeIconPath(data.damandId)
    else
        iconPath = _res(string.format("ui/catModule/catInfo/abilityIcon/ability_%s.png", data.damandId))
    end
    cellViewData.icon:setTexture(iconPath)
end


function CatModulePromotePopup:refreshPage()
    local careerConf  = CONF.CAT_HOUSE.CAT_CAREER_INFO:GetValue(self:getCareerId())
    local careerLvl   = self:getCareerLevel()

    local curLvlConf  = checktable(careerConf[tostring(careerLvl)])
    local nextLvlConf = checktable(careerConf[tostring(careerLvl + 1)])
    if next(nextLvlConf) == nil or next(curLvlConf) == nil then
        return
    end
    self:getViewData().curLvlTitle:updateLabel({text = string.fmt(__("等级_level_"), {_level_ = careerLvl}), paddingW = 30, offset = cc.p(-15, 0)})
    self:getViewData().nextLvlTitle:updateLabel({text = string.fmt(__("等级_level_"), {_level_ = careerLvl + 1}), paddingW = 30, offset = cc.p(-15, 0)})
    
    -- update cur damand need
    local curRequireAbilityList = {}
    for abilityId, abilityValue in pairs(curLvlConf.requireAbility) do
        table.insert(curRequireAbilityList, {id = abilityId, value = abilityValue})
    end
    self:getViewData().curDamandTabView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local abilityData = checktable(curRequireAbilityList[cellIndex])
        self:updateDamandNode(cellViewData, {isAttr = false, damandId = abilityData.id, value = abilityData.value})
    end)
    self:getViewData().curDamandTabView:resetCellCount(#curRequireAbilityList)
    self:getViewData().curDamandEmpty:setVisible(#curRequireAbilityList <= 0)
    -- self:getViewData().curDamandLayer:removeAllChildren()
    -- local curDemandNode = {}
    -- for abilityId, abilityValue in pairs(curLvlConf.requireAbility) do
    --     local demandNode = CatModulePromotePopup.CreateDamandNode(abilityId, abilityValue)
    --     self:getViewData().curDamandLayer:addChild(demandNode)
    --     table.insert(curDemandNode, demandNode)
    -- end
    -- ui.flowLayout(cc.sizep(self:getViewData().curDamandLayer, ui.cc), curDemandNode, {type = ui.flowH, ap = ui.cc})

    -- update next damand need
    local nextRequireAbilityList = {}
    for abilityId, abilityValue in pairs(nextLvlConf.requireAbility) do
        table.insert(nextRequireAbilityList, {id = abilityId, value = abilityValue})
    end
    self:getViewData().nextDamandTabView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local abilityData = checktable(nextRequireAbilityList[cellIndex])
        self:updateDamandNode(cellViewData, {isAttr = false, damandId = abilityData.id, value = abilityData.value})
    end)
    self:getViewData().nextDamandEmpty:setVisible(#nextRequireAbilityList <= 0)
    self:getViewData().nextDamandTabView:resetCellCount(#nextRequireAbilityList)
    -- self:getViewData().nextDamandLayer:removeAllChildren()
    -- local nextDemandNode = {}
    -- for abilityId, abilityValue in pairs(nextLvlConf.requireAbility) do
    --     local demandNode = CatModulePromotePopup.CreateDamandNode(abilityId, abilityValue)
    --     self:getViewData().nextDamandLayer:addChild(demandNode)
    --     table.insert(nextDemandNode, demandNode)
    -- end
    -- ui.flowLayout(cc.sizep(self:getViewData().nextDamandLayer, ui.cc), nextDemandNode, {type = ui.flowH, ap = ui.cc})
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function CatModulePromotePopup:onClickCancelBtnHandler_(sender)
    PlayAudioByClickClose()
    self:CloseHandler()
end


function CatModulePromotePopup:checkIsCanPromote()
    local careerConf  = CONF.CAT_HOUSE.CAT_CAREER_INFO:GetValue(self:getCareerId())
    local nextLvlConf = checktable(careerConf[tostring(self:getCareerLevel() + 1)])
    if next(nextLvlConf) == nil then
        app.uiMgr:ShowInformationTips(__("已达到最大等级"))
        return false
    end

    for abilityId, abilityValue in pairs(nextLvlConf.requireAbility) do
        if self:getCatModel():getAbility(abilityId) < checkint(abilityValue) then
            app.uiMgr:ShowInformationTips(__("猫咪工作能力不足"))
            return false
        end
    end

    return true
end


function CatModulePromotePopup:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()

    if self:checkIsCanPromote() then
        if self.ctorArgs_.confirmCB then
            self.ctorArgs_.confirmCB()
        end
        self:CloseHandler()
    end
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModulePromotePopup.CreateDamandNode(parent)
    local view = ui.layer({size = cc.size(130, 80)})
    parent:addList(view):alignTo(nil, ui.cc)

    local bg   = ui.image({img = RES_DICT.VALUE_BG})
    view:addList(bg):alignTo(nil, ui.rb)

    local attrPath    = CatHouseUtils.GetCatAttrTypeIconPath(101)
    local icon        = ui.image({img = attrPath})
    view:addList(icon):alignTo(nil, ui.lb)

    local value  = ui.label({fnt = FONT.D14, text = "--"})
    view:addList(value):alignTo(bg, ui.cc)

    return {
        view  = view,
        value = value,
        icon  = icon,
    }
end


function CatModulePromotePopup.CreateTaskCell(taskData)
    local size = cc.size(310, 200)
    local view = ui.layer({size = size})

    local frameGroup = view:addList({
        ui.title({n = RES_DICT.BG_TITLE, scale9 = true, ap = ui.lc}):updateLabel({fnt = FONT.D14, outline = "#50262b", text = "--", paddingW = 30, offset = cc.p(-15, 0)}),
        ui.layer({bg = RES_DICT.BG_CELL}),
    })
    ui.flowLayout(cc.sizep(size, ui.lc), frameGroup, {type = ui.flowV, ap = ui.lc})

    local infoLayer = frameGroup[2]
    local infoGroup = infoLayer:addList({
        ui.label({fnt = FONT.D4, color = "#50262b", text = __("岗位要求")}),
        ui.layer({size = cc.size(320, 120)}),
    })
    ui.flowLayout(cc.sizep(infoLayer, ui.cc), infoGroup, {type = ui.flowV, ap = ui.cc})

    local damandLayer = infoGroup[2]
    local damandTabView = ui.tableView({size = cc.resize(damandLayer:getContentSize(), -10, 0), csizeW = 130, dir = display.SDIR_H})
    damandLayer:addList(damandTabView):alignTo(nil, ui.cc)
    damandTabView:setCellCreateHandler(CatModulePromotePopup.CreateDamandNode)

    local emptyTip = ui.label({fnt = FONT.D14, text = __("暂无岗位要求")})
    damandLayer:addList(emptyTip):alignTo(nil, ui.cc)

    return {
        view          = view,
        levelTitle    = frameGroup[1],
        damandLayer   = damandLayer,
        damandTabView = damandTabView,
        emptyTip      = emptyTip,
    }
end

function CatModulePromotePopup.CreateView()
    local size = cc.size(760, 450)
    local view = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    local cpos = cc.sizep(size, ui.cc)

    local frameGroup = view:addList({
        ui.label({fnt = FONT.D1, fontSize = 24, color = "#683320", text = __("是否升级当前职位"), mt = 10}),
        ui.layer({size = cc.size(680, 200)}),
        ui.layer({size = cc.size(500, 100)})
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowV, ap = ui.cc})

    local bgGroup = frameGroup[2]:addList({
        ui.layer({size = cc.size(680, 200), color = cc.r4b(0), mt = 40}),
        ui.layer({size = cc.size(680, 200)})
    })
    ui.flowLayout(cc.sizep(frameGroup[2], ui.cc), bgGroup, {type = ui.flowC, ap = ui.cc})

    local infoLayer      = bgGroup[2]
    local preCareerView  = CatModulePromotePopup.CreateTaskCell()
    local nextCareerView = CatModulePromotePopup.CreateTaskCell()
    local infoGroup      = infoLayer:addList({
        preCareerView.view,
        ui.image({img = RES_DICT.BG_ARROW}),
        nextCareerView.view,
    })
    ui.flowLayout(cc.sizep(infoLayer, ui.cc), infoGroup, {type = ui.flowH, ap = ui.cc})

    local btnLayer = frameGroup[3]
    local btnGroup = btnLayer:addList({
        ui.button({n = RES_DICT.CANCEL_BTN}):updateLabel({fnt = FONT.D14, text = __("取消"), reqW = 110}),
        ui.button({n = RES_DICT.CONFIRM_BTN}):updateLabel({fnt = FONT.D14, text = __("确认"), reqW = 110}),
    })
    ui.flowLayout(cc.sizep(btnLayer, ui.cc), btnGroup, {type = ui.flowH, ap = ui.cc, gapW = 150})

    return {
        view              = view,
        cancelBtn         = btnGroup[1],
        confirmBtn        = btnGroup[2],
        curLvlTitle       = preCareerView.levelTitle,
        nextLvlTitle      = nextCareerView.levelTitle,
        curDamandLayer    = preCareerView.damandLayer,
        nextDamandLayer   = nextCareerView.damandLayer,
        curDamandTabView  = preCareerView.damandTabView,
        curDamandEmpty    = preCareerView.emptyTip,
        nextDamandTabView = nextCareerView.damandTabView,
        nextDamandEmpty   = nextCareerView.emptyTip,
    }
end


return CatModulePromotePopup
