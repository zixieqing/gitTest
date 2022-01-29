--[[
 * author : panmeng
 * descpt : 学习成功后的属性弹窗
]]

local CommonDialog   = require('common.CommonDialog')
local CatModuleStudySuccessPopup = class('CatModuleStudySuccessPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME  = _res('ui/catModule/catInfo/work/grow_cat_study_bg_star.png'),
    BG_CELL   = _res('ui/common/card_bg_attribute_number.png'),
    IMG_LINE  = _res('ui/cards/propertyNew/card_ico_attribute_line.png'),
    IMG_ARROW = _res('ui/cards/propertyNew/card_ico_green_arrow.png'),
}

function CatModuleStudySuccessPopup:ctor(args)
    self.ctorArgs_ = checktable(args)
    self.super.ctor(self)
end


function CatModuleStudySuccessPopup:InitialUI()
    -- create view
    self.viewData = CatModuleStudySuccessPopup.CreateView()
    self:setPosition(display.center)

    -- set data
    self:setCatUuid(self.ctorArgs_.catUuid)
    self:setCatAge(self.ctorArgs_.catAge)
    self:setStudyId(self.ctorArgs_.studyId)
end

-------------------------------------------------------------------------------
-- get/set
-------------------------------------------------------------------------------

function CatModuleStudySuccessPopup:getViewData()
    return self.viewData
end

-- cat studyId
function CatModuleStudySuccessPopup:getStudyId()
    return checkint(self.catStudyId_)
end
function CatModuleStudySuccessPopup:setStudyId(studyId)
    self.catStudyId_  = checkint(studyId)
    self:updateView()
end

-- cat studyId
function CatModuleStudySuccessPopup:getCatAge()
    return checkint(self.catAgeId_)
end
function CatModuleStudySuccessPopup:setCatAge(catAge)
    self.catAgeId_  = checkint(catAge)
    self:createAbilityNodeMap()
end


-- cat uuid
function CatModuleStudySuccessPopup:getCatUuid()
    return self.catUuid_
end
function CatModuleStudySuccessPopup:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
end


---@return HouseCatModel
function CatModuleStudySuccessPopup:getCatModel()
    return self.catModel_
end

-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------
function CatModuleStudySuccessPopup:updateView()
    local deltaAbilityMap = self.ctorArgs_.deltaAbilityMap or {}
    local studyConf       = CONF.CAT_HOUSE.CAT_STUDY:GetValue(self:getStudyId())
    local attributeChange = checktable(studyConf.rewardAbility)
    for abilityId, viewData in pairs(self:getViewData().abilityNodeMap) do
        local abilityValue  = self:getCatModel():getAbility(abilityId)
        local hasChange = attributeChange[tostring(abilityId)] ~= nil
        viewData.nextValueLabel:setVisible(hasChange)
        viewData.arrImg:setVisible(hasChange)

        if hasChange then
            local deltaAttrValue = checkint(deltaAbilityMap[checkint(abilityId)])
            viewData.nextValueLabel:setString(abilityValue)
            viewData.curValueLabel:setString(abilityValue - deltaAttrValue)
        else
            viewData.curValueLabel:setString(tostring(abilityValue))
        end
    end

end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleStudySuccessPopup:createAbilityNodeMap()
    local CELL_SIZE       = cc.size(357, 37)
    local abilityNodeList = {}
    local abilityNodeMap  = {}
    local abilityIndex    = 1
    for _, abilityConf in pairs(CONF.CAT_HOUSE.CAT_ABILITY:GetAll()) do
        local isAgree = true
        if self:getCatAge() == CatHouseUtils.CAT_YOUTH_AGE_NUM then
            isAgree = #abilityConf.convertAbilities > 0
        else
            isAgree = #abilityConf.convertAbilities <= 0
        end
        if isAgree then
            local isDouble = abilityIndex % 2 == 0
            local view = isDouble and ui.layer({bg = RES_DICT.BG_CELL}) or ui.layer({size = CELL_SIZE})
            table.insert(abilityNodeList, view)

            local icon = ui.image({img = _res(string.format('ui/catModule/catInfo/abilityIcon/ability_circle_%d.png', abilityConf.id))})
            view:addList(icon):alignTo(nil, ui.lc)

            local abilityNameLabel = ui.label({fnt = FONT.D9, color = "#e2c0b5", text = abilityConf.name, ap = ui.lc})
            view:addList(abilityNameLabel):alignTo(nil, ui.lc, {offsetX = 50})

            local nextValueLabel = ui.label({fnt = FONT.D9, color = "#66b526", text = abilityConf.max, ap = ui.rc})
            view:addList(nextValueLabel):alignTo(nil, ui.rc, {offsetX = -80})

            local arrImg = ui.image({img = RES_DICT.IMG_ARROW})
            view:addList(arrImg):alignTo(nil, ui.rc, {offsetX = -50})

            local curValueLabel = ui.label({fnt = FONT.D9, color = "#e2c9bf", text = abilityConf.rebirthMax, ap = ui.lc})
            view:addList(curValueLabel):alignTo(nil, ui.lc, {offsetX = 310})

            
            abilityNodeMap[checkint(abilityConf.id)] = {
                curValueLabel  = curValueLabel,
                nextValueLabel = nextValueLabel,
                arrImg         = arrImg,
            }
            abilityIndex = abilityIndex + 1
        end
    end

    self:getViewData().bgLayer:addList(abilityNodeList)
    self:getViewData().abilityNodeMap = abilityNodeMap
    ui.flowLayout(cc.rep(cc.sizep(self:getViewData().size, ui.ct), 0, -55), abilityNodeList, {type = ui.flowV, ap = ui.cb})
end

function CatModuleStudySuccessPopup.CreateView()
    local size = cc.size(450, 300)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local bgLayer = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true, cut = cc.dir(10, 200, 10, 10)})
    view:addList(bgLayer):alignTo(nil, ui.cc)

    return {
        view    = view,
        bgLayer = bgLayer,
        size    = size,
    }
end


return CatModuleStudySuccessPopup
