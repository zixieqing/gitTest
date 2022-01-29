--[[
 * author : panmeng
 * descpt : 猫咪属性界面
]]
---@class CatModuleCatInfoView
local CatModuleCatInfoView = class('CatModuleCatInfoView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleCatInfoView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME        = _res('ui/catModule/catInfo/grow_cat_main_bg.jpg'),
    GIRL_FRAME        = _res('ui/catModule/catInfo/grow_cat_main_bg_bar_f.png'),
    BOY_FRAME         = _res('ui/catModule/catInfo/grow_cat_main_bg_bar_m.png'),
    WEEK_NAME_BG      = _res('ui/catModule/catList/grow_main_list_bg_state_1.png'),
    BREED_NAME_BG     = _res('ui/catModule/catList/grow_main_list_bg_state_2.png'),
    DEAD_NAME_BG      = _res('ui/catModule/catList/grow_main_list_bg_state_3.png'),
    COM_BACK_BTN      = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR     = _res('ui/common/common_title.png'),
    COM_TIPS_ICON     = _res('ui/common/common_btn_tips.png'),
    --                = center
    NAME_BG           = _res('ui/catModule/catInfo/grow_cat_main_bg_name.png'),
    A_PRO_BG          = _res('ui/catModule/catInfo/grow_cat_main_bg_number.png'),
    BOOK_IMG          = _res('ui/catModule/catInfo/grow_cat_main_btn_book.png'),
    ACHIEVE_IMG       = _res('ui/catModule/catInfo/grow_cat_main_btn_cup.png'),
    SEARCH_IMG        = _res('ui/catModule/catInfo/grow_cat_main_btn_day.png'),
    DEL_BTN           = _res('ui/catModule/catInfo/grow_cat_main_btn_delete.png'),
    GROW_BTN          = _res('ui/catModule/catInfo/grow_cat_main_btn_grow.png'),
    GROW_BTN_G        = _res('ui/catModule/catInfo/grow_cat_main_btn_grow_gray.png'),
    REBIRTH_BTN       = _res('ui/catModule/catInfo/grow_cat_main_btn_star.png'),
    REBORN_BTN        = _res('ui/catModule/catInfo/grow_cat_main_btn_live.png'),
    RENAME_BTN        = _res('ui/catModule/catInfo/grow_cat_main_btn_name.png'),
    LIFE_IMG          = _res('ui/catModule/catInfo/grow_cat_main_ico_life.png'),
    WORK_IMG          = _res('ui/catModule/catInfo/grow_cat_main_ico_work.png'),
    WORK_IMG_G        = _res('ui/catModule/catInfo/grow_cat_main_ico_work_gray.png'),
    MATCH_IMG         = _res('ui/catModule/catInfo/grow_cat_main_ico_love.png'),
    MATCH_IMG_G       = _res('ui/catModule/catInfo/grow_cat_main_ico_love_gray.png'),
    BOY_ICON          = _res('ui/catModule/catInfo/grow_cat_main_ico_name_m.png'),
    GIRL_ICON         = _res('ui/catModule/catInfo/grow_cat_main_ico_name_f.png'),
    RED_PRO           = _res('ui/catModule/catInfo/grow_cat_main_line_bar_red.png'),
    GREEN_PRO         = _res('ui/catModule/catInfo/grow_cat_main_line_bar_green.png'),
    BG_PRO            = _res('ui/catModule/catList/grow_main_list_line_bag.png'),
    LINE_IMG          = _res('ui/catModule/catInfo/grow_cat_main_line_bar.png'),
    DIE_IMG           = _res('ui/catModule/catInfo/grow_cat_main_pic_die.png'),
    DIE_OR_RELEASE_BG = _res('ui/anniversary20/explore/wonderland_explore_go_label_title.png'),
    LOCKED_IMG        = _res('ui/catModule/catInfo/grow_cat_main_ico_lock_drak.png'),
    ICON_BG           = _res('ui/catModule/catInfo/grow_cat_main_bg_ability_wood.png'),
    DISEASE_IMG       = _res('ui/catModule/catInfo/grow_cat_main_bg_grow_light.png'),
    CAT_SHADOW        = _res('ui/battle/battle_role_shadow.png'),
    BTN_CAT_GUIDE     = _res('ui/catModule/catInfo/grow_cat_main_btn_guide.png'),
    --                = rebirth
    NEXT_BG           = _res('ui/catModule/catInfo/grow_cat_main_bg_day_grey.png'),
    CUR_BG            = _res('ui/catModule/catInfo/grow_cat_main_bg_day_light.png'),
    REBIRTH_BG        = _res('ui/catModule/catInfo/grow_cat_main_bg_day.png'),
    ARROW_IMG         = _res('ui/catModule/catInfo/grow_cat_main_ico_day_switch.png'),
    --                = state popup
    FILTER_BG         = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    ARROW_BG          = _res('ui/anniversary20/hang/common_bg_tips_horn.png'),
    --                = spine
    DEATH_SPINE       = _spn('ui/catModule/catInfo/anim/death_ligth'),
    GREEN_SPINE       = _spn('ui/catModule/catInfo/anim/ball_green'),
    RED_SPINE         = _spn('ui/catModule/catInfo/anim/ball_red'),
    LIGHT_SPINE       = _spn('ui/catModule/catInfo/anim/cat_light'),
    STATE_SPINE       = _spn('ui/catModule/catInfo/anim/cat_state'),
}


CatModuleCatInfoView.LIGHT_ANIM_TAG = {
    REBIRTH_DONE = 1, -- 回归
    RECURE_DONE  = 2, -- 治愈
}

function CatModuleCatInfoView:ctor()
    self.stateRow_ = 2
    self.stateCol_ = 6

    -- create view
    self.viewData_ = CatModuleCatInfoView.CreateView()
    self:addChild(self.viewData_.view)

    self:resetStateNodeLayer()
end


function CatModuleCatInfoView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------
function CatModuleCatInfoView:resetStateNodeLayer()
    self.randomMap_   = {}
    self.stateNodeMap = {}
    self.isDisease_   = false
    self:getViewData().stateNodeLayer:removeAllChildren()
    for i = 1, self.stateRow_ * self.stateCol_ do
        self.randomMap_[i] = true
    end
    self:getViewData().diseaseImg:setVisible(false)
end

---@param catModel HouseCatModel
function CatModuleCatInfoView:setCatInfo(catModel)
    self:getViewData().catLayer:removeAllChildren()
    self:getViewData().catLayer:addList(ui.image({img = RES_DICT.CAT_SHADOW, scale = 1})):alignTo(nil, ui.cb, {offsetY = display.center.y - 20})
    self.catSpineNode_ = CatHouseUtils.GetCatSpineNode({catUuid = catModel:getUuid(), scale = 1.3})
    self:getViewData().catLayer:addList(self.catSpineNode_):alignTo(nil, ui.cb, {offsetY = display.center.y})
    self.catSpineNode_:setClickCB(function()
        self.catSpineNode_:doTouchdAnime()
    end)
    
    self:updateStateView(catModel)
    self:updateAgeView(catModel)
    self:updateYouthView(catModel:getAge() <= CatHouseUtils.CAT_YOUTH_AGE_NUM)
    self:setCatIsDie(catModel)
    self:updateAlgebraView(catModel)
    self:updateNameView(catModel:getName())
    self:updateSexView(catModel:getSex())
    self:updateAllAbilityData(catModel)
    self:updateAllAttrData(catModel)
    self:getViewData().diseaseImg:setVisible(catModel:isSicked())
end

---@param catModel HouseCatModel
function CatModuleCatInfoView:updateRebirthBtnVisible(catModel)
    local isCanRebirth = catModel:getGeneration() >= CatHouseUtils.CAT_PARAM_FUNCS.REBIRTH_GENERATION() and not catModel:isRebirth()
    local isDie        = catModel:isDie()
    self:getViewData().rebirthBtn:setVisible(isDie or isCanRebirth)
end


function CatModuleCatInfoView:addStateNode(stateId, initCB)
    local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(stateId)
    if checkint(stateConf.display) ~= 1 then
        return
    end
    if self.stateNodeMap[checkint(stateId)] ~= nil then
        return
    end

    
    local halfRect = cc.size(display.SAFE_RECT.width / 2 - 400, display.height / 2 - 100)
    local deltaX    = math.floor(halfRect.width / (self.stateCol_ * 0.5))
    local deltaY    = math.floor(halfRect.height / self.stateRow_)

    -- get random index
    local randomList  = table.keys(self.randomMap_)
    if #randomList <= 0 then
        return
    end
    local randomIndex = randomList[math.random(1, #randomList)]
    self.randomMap_[randomIndex] = nil
    
    -- calculate pos
    local col   = math.ceil(randomIndex / self.stateRow_)
    local row   = randomIndex % self.stateRow_ + 1
    local size  = cc.size(100, 100)
    local delta = col > self.stateCol_ * 0.5 and 500 or 100
    local posX  = display.SAFE_L + deltaX * (col - 0.5) + delta
    local posY  = display.height * 0.5 + deltaY * (row - 0.5) - 50
    posX  = math.random(posX - math.max(deltaX - size.width, 5) * 0.5, posX + math.max(deltaX - size.width, 5) * 0.5)
    posY  = math.random(posY - math.max(deltaY - size.height, 5) * 0.5, posY + math.max(deltaY - size.height, 5) * 0.5)

    -- create node
    local nodePos = cc.p(posX, posY)
    local stateNode = ui.layer({size = size, color = cc.r4b(0), enable = true, p = nodePos, cb = initCB})
    stateNode.stateId = stateId
    stateNode:setTag(randomIndex)

    -- create node spine
    local stateSpinePath = checkint(stateConf.buffIconColor) > 0 and RES_DICT.RED_SPINE or RES_DICT.GREEN_SPINE
    local stateSpine = ui.spine({path = stateSpinePath, init = "idle", cache = SpineCacheName.CAT_HOUSE})
    stateNode:addList(stateSpine):alignTo(nil, ui.cc)
    stateNode.spine = stateSpine

    -- create node icon
    local icon = ui.image({img = _res(string.format("ui/catModule/catInfo/stateIcon/%s.png", stateId)), scale = 0.8})
    stateNode:addList(icon):alignTo(nil, ui.cc)
    self:getViewData().stateNodeLayer:add(stateNode)
    self.stateNodeMap[checkint(stateId)] = stateNode

    -- play anim
    stateNode:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.MoveTo:create(1.5, cc.rep(nodePos, math.random(-25, 0), math.random(10, 20))), 
        cc.MoveTo:create(1.5, cc.rep(nodePos, math.random(-50, 0), math.random(0, 10))), 
        cc.MoveTo:create(1.5, cc.rep(nodePos, math.random(0, 25), math.random(-20, -10))),
        cc.MoveTo:create(1.5, cc.rep(nodePos, math.random(0, 50), math.random(-10, 0)))
    )))

    return stateNode
end
function CatModuleCatInfoView:removeStateNode(stateId)
    local stateNode = self.stateNodeMap[checkint(stateId)]
    if stateNode then
        stateNode:stopAllActions()
        stateNode:setTouchEnabled(false)
        local randomIndex = stateNode:getTag()
        self.stateNodeMap[checkint(stateId)] = nil
        self.randomMap_[checkint(randomIndex)] = true
        stateNode.spine:setAnimation(0, "play1", false)
        stateNode.spine:registerSpineEventHandler(function()
            stateNode:runAction(cc.RemoveSelf:create())
        end, sp.EventType.ANIMATION_COMPLETE)
    end
end

---@param catModel HouseCatModel
function CatModuleCatInfoView:updateStateView(catModel)
    local isDoNothing = catModel:isDoNothing()
    local isSicked    = catModel:isSicked()
    local isDie       = not catModel:isAlive()

    local showCatState = isDie or isSicked or not isDoNothing
    self:getViewData().catStateImg:setVisible(showCatState)
    self:getViewData().catStateImg:setChecked(isSicked)
    self:getViewData().catStateImg:setEnabled(not isDie)
    self:getViewData().timeTitle:setVisible(not isDoNothing)

    if not isDoNothing then
        local stateStr = ""
        local leftTime = os.time()
        if catModel:isMating() then
            stateStr = __("孕育中")
            leftTime = catModel:getMatingLeftSeconds()
        elseif catModel:isStudying() then
            stateStr = __("学习中")
            leftTime = catModel:getStudyLeftSeconds()
        elseif catModel:isWorking() then
            stateStr = __("工作中")
            leftTime = catModel:getWorkLeftSeconds()
        elseif catModel:isOutGoing() then
            stateStr = __("外出中")
            leftTime = catModel:getOutLeftSeconds()
        elseif catModel:isSleeping() then
            stateStr = __("睡觉中")
            leftTime = catModel:getSleepLeftSeconds()
        elseif catModel:isHousing() then
            stateStr = __("等待中")
            leftTime = catModel:getHouseLeftSeconds()
        else
            stateStr = __("如厕中")
            leftTime = catModel:getToiletLeftSeconds()
        end
        self:getViewData().normalStr:updateLabel({text = stateStr, reqW = 190})
        local timeText = CommonUtils.getTimeFormatByType(math.max(checkint(leftTime), 0), 2)
        self:getViewData().timeTitle:setString(timeText)
    end
end


---@param catModel HouseCatModel
function CatModuleCatInfoView:updateAllAbilityData(catModel)
    for abilityId, _ in pairs(self:getViewData().abilityNodeMap) do
        self:updateAbilityDataAt(catModel, abilityId)
    end
end
---@param catModel HouseCatModel
function CatModuleCatInfoView:updateAbilityDataAt(catModel, abilityId)
    local viewData = self:getViewData().abilityNodeMap[checkint(abilityId)]
    if viewData then
        local abilityValue = catModel:getAbility(abilityId)
        local abilityConf  = CONF.CAT_HOUSE.CAT_ABILITY:GetValue(abilityId)
        display.reloadRichLabel(viewData.progress, {c = {
            {fnt = FONT.D6, color = "#efd8ca", fontSize = 22, text = abilityValue},
            {fnt = FONT.D4, color = "#9f8473", fontSize = 18, text = "/" .. abilityConf.max},
        }})
    end

end

---@param catModel HouseCatModel
function CatModuleCatInfoView:updateAllAttrData(catModel)
    for attrId, _ in pairs(self:getViewData().attrNodeMap) do
        self:updateAttrDataAt(catModel, attrId)
    end
end
---@param catModel HouseCatModel
function CatModuleCatInfoView:updateAttrDataAt(catModel, attrId)
    local viewData = self:getViewData().attrNodeMap[checkint(attrId)]
    if viewData then
        local value = catModel:getAttrNum(attrId)
        local max   = catModel:getAttrMax(attrId)
        viewData.progress:setString(string.fmt("_num1_/_num2_", {_num1_ = math.min(value, max), _num2_ = max}))
        
        local isWeak = value < CatHouseUtils.CAT_ATTR_ALERT_NUM
        viewData.redBar:setVisible(isWeak)
        viewData.greedBar:setVisible(not isWeak)

        viewData.redBar:setValue(value / max * 100)
        viewData.greedBar:setValue(value / max * 100)
    end
end

------------------------------------------------view update
-- 幼年期界面状态
function CatModuleCatInfoView:updateYouthView(isYouth)
    self:getViewData().abilityYouthPage:setVisible(isYouth)
    self:getViewData().abilityGrowPage:setVisible(not isYouth)
end

-- 是否死亡界面状态
---@param catModel HouseCatModel
function CatModuleCatInfoView:setCatIsDie(catModel)
    local isDie = catModel:isDie()
    self:getViewData().stateNodeLayer:setVisible(not isDie)
    self:getViewData().catGrowBtnLayer:setVisible(not isDie)
    self.catSpineNode_:checkCatModelAlive_()

    local releaseBtnStr = isDie and __("埋葬") or __("放生")
    local rebirthBtnStr = isDie and __("复活") or __("归回")
    self:getViewData().releaseBtn:updateLabel({text = releaseBtnStr})
    self:getViewData().rebirthBtn:updateLabel({text = rebirthBtnStr})
    local img = isDie and RES_DICT.REBORN_BTN or RES_DICT.REBIRTH_BTN
    self:getViewData().rebirthBtn:setNormalImage(img)
    self:getViewData().rebirthBtn:setSelectedImage(img)
    self:updateRebirthBtnVisible(catModel)
end

-- 更新代数状态
---@param catModel HouseCatModel
function CatModuleCatInfoView:updateAlgebraView(catModel)
    local algebraNum = catModel:getGeneration()
    local isRebirth  = catModel:isRebirth()
    self:getViewData().algebraLabel:setString(algebraNum)
    self:getViewData().rebirthNumLabel:setString(isRebirth and __("是") or __("否"))
    self:updateRebirthBtnVisible(catModel)
end

-- 更新名字
function CatModuleCatInfoView:updateNameView(nameStr)
    self:getViewData().nameBtn:updateLabel({text = nameStr, reqW = 230})
end

-- 更新性别
function CatModuleCatInfoView:updateSexView(sex)
    self:getViewData().sexIcon:setChecked(sex == CatHouseUtils.CAT_SEX_TYPE.BOY)
    self:getViewData().bottomBg:setChecked(sex == CatHouseUtils.CAT_SEX_TYPE.BOY)
end

--------------------------------------------------------- view show
-- 放生猫界面展示
function CatModuleCatInfoView:showReleaseCatView()
    self:getViewData().centerLayer:setVisible(false)
    self:getViewData().releaseResultLayer:setVisible(true)
    self:getViewData().releaseResultLayer:updateLabel({text = __("你的猫走了"), paddingW = 40})
end

-- 埋葬猫界面展示
function CatModuleCatInfoView:showBuriedCatview()
    -- TODO 动画
    self:getViewData().centerLayer:setVisible(false)
    self:getViewData().releaseResultLayer:setVisible(true)
    self:getViewData().releaseResultLayer:updateLabel({text = __("你的猫被埋葬了"), paddingW = 40})
end

-- 状态细节展示
function CatModuleCatInfoView:showStateDetailView(stateNode, deathTimestamp, leftSeconds)
    local stateDetailView, stateTimeUpdate = CatModuleCatInfoView.CreateStateDetailView(stateNode, deathTimestamp, leftSeconds)
    self:add(stateDetailView)
    self.stateTimeUpdate = stateTimeUpdate
end

-- 年龄界面展示
function CatModuleCatInfoView:showAgeGradeView(currentAge, nextAgeLeftSeconds)
    self.ageDetailView = CatModuleCatInfoView.CreateGradeLevelView(currentAge, nextAgeLeftSeconds, function() self.ageDetailView = nil end)
    self:add(self.ageDetailView.view)
end

-- 升星效果
function CatModuleCatInfoView:showRebirthResult()
    local spine = ui.spine({path = RES_DICT.LIGHT_SPINE , init = "play1", loop = false})
    self:getViewData().catLayer:addList(spine):alignTo(nil, ui.cc)
    spine:registerSpineEventHandler(function()
        spine:runAction(cc.RemoveSelf:create())
    end, sp.EventType.ANIMATION_COMPLETE)
end

-- 治愈效果
function CatModuleCatInfoView:showRecureResult()
    local spine = ui.spine({path = RES_DICT.LIGHT_SPINE , init = "play2", loop = false})
    self:getViewData().catLayer:addList(spine):alignTo(nil, ui.cc)
    spine:registerSpineEventHandler(function()
        spine:runAction(cc.RemoveSelf:create())
    end, sp.EventType.ANIMATION_COMPLETE)
end


---@param catModel HouseCatModel
function CatModuleCatInfoView:updateAgeView(catModel)
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(catModel:getAge())
    self:getViewData().growStageLabel:updateLabel({text = ageConf.name, reqW = 120})
    self.catSpineNode_:setCatAge(catModel:getAge())

    self:getViewData().matchBtn:setTouchEnabled(catModel:isUnlockMaking())
    self:getViewData().studyBtn:setTouchEnabled(catModel:isUnlockStudy() or catModel:isUnlockWork())
    self:getViewData().matchBtn.updateLockedStatue(not catModel:isUnlockMaking())
    self:getViewData().studyBtn.updateLockedStatue(not catModel:isUnlockStudy() and not catModel:isUnlockWork())
end


function CatModuleCatInfoView:playStateAnimation(animTag, endCB)
    local spine = ui.spine({path = RES_DICT.STATE_SPINE, init = "play" .. animTag, loop = false})
    self:addList(spine):alignTo(nil, ui.cc)

    local text = ui.label({fnt = FONT.D14, text = STATE_INFO_DEFINE[animTag].text, fontSize = 50})
    spine:addList(text):alignTo(nil, ui.cc, {offsetX = 200})

    spine:registerSpineEventHandler(function()
        if endCB then
            endCB()
        end
        spine:runAction(cc.RemoveSelf:create())
    end, sp.EventType.ANIMATION_COMPLETE)
end



function CatModuleCatInfoView:playLigthAnimation(animTag, endCB)
    local spine = ui.spine({path = RES_DICT.LIGHT_SPINE , init = "play" .. animTag, loop = false})
    self:getViewData().catLayer:addList(spine):alignTo(nil, ui.cc)
    spine:registerSpineEventHandler(function()
        if endCB then
            endCB()
        end

        spine:runAction(cc.RemoveSelf:create())
    end, sp.EventType.ANIMATION_COMPLETE)
end


function CatModuleCatInfoView:playLifeAnimation(data, endCB)
    local goodsId      = checkint(data.goodsId)
    local goodsConf    = CONF.CAT_HOUSE.CAT_GOODS_INFO:GetValue(goodsId)
    local goodsType    = checkint(goodsConf.type)

    if self.catSpineNode_ then
        self.catSpineNode_:setClickEnabled(false)
    end
    local lifeEndAnim = function()
        if self.catSpineNode_ then
            self.catSpineNode_:setClickEnabled(true)
        end
        if endCB then
            endCB()
        end
    end

    local FadeAnim = function()
        local tipIndex     = 1
        if checkint(data.recureState) > 0 then
            local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(data.recureState)
            local descr     = string.fmt(__("治好了_name_"), {_name_ = tostring(stateConf.name)})
            local fadeTip   = CatModuleCatInfoView.CreateFadeLabel(descr, 0.2 * (tipIndex - 1))
            self:addList(fadeTip):alignTo(nil, ui.cc, {offsetY = 100})
            tipIndex = tipIndex + 1
        end

        for attrId, attrValue in pairs(goodsConf.attrAddition or {}) do
            local attrConf = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
            local descr = string.fmt("_name_ +_value_", {_name_ = tostring(attrConf.name), _value_ = tostring(attrValue)})
            local attrLabel = CatModuleCatInfoView.CreateFadeLabel(descr, 0.2 * (tipIndex - 1))
            self:addList(attrLabel):alignTo(nil, ui.cc, {offsetY = 100})
            tipIndex = tipIndex + 1
        end

        for attrId, attrValue in pairs(goodsConf.attrSubtraction or {}) do
            local attrConf = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
            local descr = string.fmt("_name_ +_value_", {_name_ = tostring(attrConf.name), _value_ = tostring(attrValue)})
            local attrLabel = CatModuleCatInfoView.CreateFadeLabel(descr, 0.2 * (tipIndex - 1))
            self:addList(attrLabel):alignTo(nil, ui.cc, {offsetY = 100})
            tipIndex = tipIndex + 1
        end
    end

    local goodNodeInitP  = cc.p(display.width, math.random(display.center.y, display.height))
    local goodNodeEndP   = cc.rep(display.center, 0, 80)
    local goodsIconNode  = GoodsUtils.GetIconNodeById(goodsId, goodNodeInitP.x, goodNodeInitP.y, {isBig = true})
    self:add(goodsIconNode)
    local bezierConfig   = {
        cc.rep(goodNodeEndP, -100, 100),
        self:GetFixedBezierPos(goodNodeInitP, goodNodeEndP, 100),
        goodNodeEndP,
    }
    local goodMoveAction = cc.BezierTo:create(1, bezierConfig)
    goodsIconNode:runAction(cc.Sequence:create(goodMoveAction, cc.FadeOut:create(0.4), cc.CallFunc:create(function()
        if goodsType == CatHouseUtils.CAT_GOODS_TYPE.CLEAN_ITEM then
            self.catSpineNode_:doShowerAnime(lifeEndAnim)
        elseif goodsType == CatHouseUtils.CAT_GOODS_TYPE.TOY then
            self.catSpineNode_:doPlayAnime(lifeEndAnim)
        elseif goodsType == CatHouseUtils.CAT_GOODS_TYPE.FOOD or goodsType == CatHouseUtils.CAT_GOODS_TYPE.DRUG then
            self.catSpineNode_:doFeedAnime(lifeEndAnim)
        end
        if checkint(data.recureState) > 0 then
            self:playLigthAnimation(CatModuleCatInfoView.LIGHT_ANIM_TAG.RECURE_DONE)
        end
        FadeAnim()
    end), cc.RemoveSelf:create()))
end


function CatModuleCatInfoView:GetFixedBezierPos(p1, p2, len)
	-- p1起点 p2终点
	local p = cc.p(0, 0)
	local dp1p2 = cc.pGetDistance(p1, p2)
	local p_ = cc.pSub(p2, p1)

	local pCenter = cc.p(
		(p1.x + p2.x) * 0.5,
		(p1.y + p2.y) * 0.5
	)

	p.x = pCenter.x + len * p_.x / dp1p2
	p.y = pCenter.y + len * p_.y / dp1p2

	return p
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
-- 状态detail界面
function CatModuleCatInfoView.CreateStateDetailView(stateNode, deathTimestamp, leftSeconds)
    local stateId   = stateNode.stateId or CONF.CAT_HOUSE.CAT_STATUS:GetIdList()[1]
    local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(stateId)

    if not stateId then
        return
    end

    local viewW      = 200
    local title      = ui.label({fnt = FONT.D4, color = "#532922", text = stateConf.name})
    local descr      = ui.label({fnt = FONT.D13, color = "#70645b", w = viewW, text = stateConf.descr})
    local timeLabel  = nil
    local stateTimeLabel = ui.label({fnt = FONT.D13, color = "#70645b", text = string.fmt(__("剩余时间:_time_"), {_time_ = CommonUtils.getTimeFormatByType(leftSeconds)}), reqW = 200, mt = 10})
    if checkint(stateConf.deathSeconds) > 0 and DEBUG >= 2 then
        timeLabel  = ui.label({fnt = FONT.D13, color = "#70645b", text = CommonUtils.getTimeFormatByType(deathTimestamp - os.time())})
    end

    local timeH = timeLabel and display.getLabelContentSize(timeLabel).height or 0
    local size  = cc.size(viewW, display.getLabelContentSize(title).height + display.getLabelContentSize(descr).height + timeH + display.getLabelContentSize(stateTimeLabel).height + 10)
    local view  = ui.layer({color = cc.r4b(0), enable = true})
    local frame = ui.image({img = RES_DICT.FILTER_BG, size = cc.resize(size, 20, 20), scale9 = true, cut = cc.dir(5, 5, 5, 5)})
    frame:addList(ui.image({img = RES_DICT.ARROW_BG})):alignTo(nil, ui.ct, {offsetY = 11})
    view:addList(frame):alignTo(stateNode, ui.cb)

    local frameGroup = frame:addList({title, descr, stateTimeLabel, timeLabel})
    ui.flowLayout(cc.sizep(frame, ui.cc), frameGroup, {type = ui.flowV, ap = ui.cc})

    local leftTimeStamp = leftSeconds + os.time()
    local timeUpdate    = nil
    timeUpdate = app.timerMgr.CreateClocker(function()
        if timeLabel then
            timeLabel:setString(CommonUtils.getTimeFormatByType(deathTimestamp - os.time()))
        end
        stateTimeLabel:updateLabel({text = string.fmt(__("剩余时间:_time_"), {_time_ = CommonUtils.getTimeFormatByType(leftTimeStamp - os.time())}), reqW = 200})
        if (timeLabel and deathTimestamp - os.time() < 0) or leftTimeStamp - os.time() < 0 then
            view:runAction(cc.RemoveSelf:create())
            timeUpdate:stop()
        end 
    end)
    timeUpdate:start()

    ui.bindClick(view, function() 
        view:runAction(cc.RemoveSelf:create())
        if timeUpdate then
            timeUpdate:stop()
        end
    end)
    return view, timeUpdate
end


-- 归回界面
function CatModuleCatInfoView.CreateGradeLevelView(curLvl, nextAgeLeftSeconds, closeCB)
    curLvl = curLvl or 1

    local CELL_W  = 159
    local BG_SIZE = cc.size(336, 110)
    local view    = ui.layer({color = cc.r4b(0), enable = true})
    local bg      = ui.image({img = RES_DICT.REBIRTH_BG, size = cc.resize(BG_SIZE, 5, 5), scale9 = true})
    view:addList(bg):alignTo(nil, ui.cc)

    
    
    local frameGroup = bg:addList({
        ui.layer({size = cc.size(CELL_W, BG_SIZE.height)}),
        ui.image({img = RES_DICT.ARROW_IMG}),
        ui.layer({size = cc.size(CELL_W, BG_SIZE.height)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(bg, ui.lc), 2, 0), frameGroup, {type = ui.flowH, ap = ui.lc})

    local curLayer     = frameGroup[1]
    local curInfoGroup = curLayer:addList({
        ui.title({n = RES_DICT.CUR_BG, scale9 = true, size = cc.size(CELL_W, 38), mt = -4}):updateLabel({fnt = FONT.D10, color = "#6f3e12", text = __("当前阶段"), reqW = 150}),
        ui.label({fnt = FONT.D10, color = "#c9a25b", text = "--"}),
        ui.label({fnt = FONT.D10, color = "#c7a086", text = __("剩余天数"), reqW = 150}),
        ui.label({fnt = FONT.D10, color = "#c7a08b", text = "--"}),
    })
    ui.flowLayout(cc.sizep(curLayer, ui.cc), curInfoGroup, {type = ui.flowV, ap = ui.cc})

    
    local nextLayer     = frameGroup[3]
    local nextInfoGroup = nextLayer:addList({
        ui.title({n = RES_DICT.NEXT_BG, scale9 = true, size = cc.size(CELL_W, 38), mt = -4}):updateLabel({fnt = FONT.D10, color = "#6f3e12", text = __("下一阶段"), reqW = 150}),
        ui.label({fnt = FONT.D10, color = "#c9a25b", text = "--"}),
        ui.label({fnt = FONT.D10, color = "#c7a086", text = __("剩余天数"), reqW = 150}),
        ui.label({fnt = FONT.D10, color = "#c7a08b", text = "--"}),
    })
    ui.flowLayout(cc.sizep(nextLayer, ui.cc), nextInfoGroup, {type = ui.flowV, ap = ui.cc})


    ui.bindClick(view, function()  
        view:runAction(cc.RemoveSelf:create())
        if closeCB then
            closeCB()
        end
    end)

    local refreshAgeTime = function(curLvl, nextAgeLeftSeconds)
        local isMaxAge = curLvl >= CONF.CAT_HOUSE.CAT_AGE:GetLength()
        local timeStr      = "MAX"
        if not isMaxAge then
            timeStr = CommonUtils.getTimeFormatByType(math.max(0, nextAgeLeftSeconds), 1)
        end

        logs(timeStr, nextAgeLeftSeconds)
        curInfoGroup[4]:setString(timeStr)
    end
    local refreshAgeView = function(curLvl, nextAgeLeftSeconds)
        local isMaxAge = curLvl >= CONF.CAT_HOUSE.CAT_AGE:GetLength()
        frameGroup[2]:setVisible(not isMaxAge)
        nextLayer:setVisible(not isMaxAge)

        local curLayerSize = isMaxAge and BG_SIZE or cc.size(CELL_W, BG_SIZE.height)
        curLayer:setContentSize(curLayerSize)
        curInfoGroup[1]:setContentSize(cc.size(curLayerSize.width, 38))
        curInfoGroup[1]:updateLabel({text = __("当前阶段"), reqW = isMaxAge and 330 or 150})
        ui.flowLayout(cc.sizep(curLayer, ui.cc), curInfoGroup, {type = ui.flowV, ap = ui.cc})
        

        local curLvlConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(curLvl)
        curInfoGroup[2]:updateLabel({text = curLvlConf.name, reqW = 150})

        if not isMaxAge then
            local nextLvlConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(curLvl + 1)
            nextInfoGroup[2]:updateLabel({text = nextLvlConf.name, reqW = 150})
            local timeStr = "MAX"
            if checkint(nextLvlConf.id) < CONF.CAT_HOUSE.CAT_AGE:GetLength() then
                timeStr = CommonUtils.getTimeFormatByType(checkint(nextLvlConf.growthTime), 1)
            end
            nextInfoGroup[4]:setString(timeStr)
        end

        refreshAgeTime(curLvl, nextAgeLeftSeconds)
    end
    refreshAgeView(curLvl, nextAgeLeftSeconds)
    return {
        view           = view,
        refreshAgeView = refreshAgeView,
        refreshAgeTime = refreshAgeTime,
    }
end


-- 能力界面
function CatModuleCatInfoView.CreateAbilityView()
    local viewSize = cc.size(400, 180)
    local parent   = ui.layer({size = viewSize})
    local nodeSize = cc.size(200, 60)

    -- [youth ability layer] | [grow ability layer]
    local frameGroup = parent:addList({
        ui.layer({size = viewSize}),
        ui.layer({size = viewSize}),
    })

    -- [youth index] | grow index
    local indexGroup = {1, 1}

    local abilityNodeMap = {}

    for _, abilityConf in pairs(CONF.CAT_HOUSE.CAT_ABILITY:GetAll()) do
        local isYouth  = #abilityConf.convertAbilities > 0
        local ageIndex = isYouth and 1 or 2

        local parent = frameGroup[ageIndex]
        local index  = indexGroup[ageIndex]

        local posX   = nodeSize.width * ((index + 1) % 2)
        local posY   = parent:getContentSize().height - nodeSize.height * math.floor((index - 0.5) / 2)

        local view   = ui.layer({size = nodeSize, p = cc.p(posX, posY), ap = ui.lt})
        parent:add(view)

        -- bg group
        local frameGroup = view:addList({
            ui.layer({bg = RES_DICT.ICON_BG, mb = -10, zorder = 2}),
            ui.image({img = RES_DICT.A_PRO_BG, zorder = 1}),
        })
        ui.flowLayout(cc.sizep(view, ui.cb), frameGroup, {type = ui.flowH, ap = ui.cb, gapW = -7})

        -- icon 
        local iconLayer = frameGroup[1]
        local iconPath  = _res(string.format("ui/catModule/catInfo/abilityIcon/ability_%s.png", abilityConf.id))
        local iconImg   = ui.image({img = iconPath, scale = 0.5})
        iconLayer:addList(iconImg):alignTo(nil, ui.cc)

        -- progress
        local progressBg = frameGroup[2]
        local attrName   = ui.label({fnt = FONT.D4, color = "#653e25", text = tostring(abilityConf.name), reqW = 110})
        view:addList(attrName):alignTo(progressBg, ui.ct)

        local progress = ui.rLabel()
        view:addList(progress, 3):alignTo(progressBg, ui.cc)

        indexGroup[ageIndex] = checkint(indexGroup[ageIndex]) + 1
        abilityNodeMap[checkint(abilityConf.id)] = {
            view     = view,
            progress = progress,
            iconImg  = iconImg,
            attrName = attrName,
        }
    end

    return {
        view           = parent,
        abilityNodeMap = abilityNodeMap,
        youthPage      = frameGroup[1],
        growPage       = frameGroup[2],
    }
end


-- 属性界面
function CatModuleCatInfoView.CreateAttrView()
    local parent       = ui.layer({size = cc.size(400, 180)})
    local size         = cc.size(200, 60)
    local attrNodeMap  = {}
    for index, attrId in ipairs(CONF.CAT_HOUSE.CAT_ATTR:GetIdList()) do
        local attrConf = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
        local pos  = cc.p(size.width * (index % 2), parent:getContentSize().height - size.height * math.floor((index - 0.5) / 2))
        local view = ui.layer({size = size, p = pos, ap = ui.lt})
        parent:add(view)

        local frameGroup = view:addList({
            ui.layer({bg = RES_DICT.ICON_BG, zorder = 2, mb = -10}),
            ui.layer({size = cc.size(120, 30), zorder = 1}),
        })
        ui.flowLayout(cc.sizep(view, ui.cb), frameGroup, {type = ui.flowH, ap = ui.cb})

        local iconLayer = frameGroup[1]
        local icon = ui.image({img = CatHouseUtils.GetCatAttrTypeIconPath(attrId), scale = 0.5})
        iconLayer:addList(icon):alignTo(nil, ui.cc)

        local proLayer = frameGroup[2]
        local redBar = ui.pBar({bg = RES_DICT.BG_PRO, img = RES_DICT.RED_PRO, scale = 0.7})
        proLayer:addList(redBar):alignTo(nil, ui.cc)

        local greedBar = ui.pBar({bg = RES_DICT.BG_PRO, img = RES_DICT.GREEN_PRO, scale = 0.7})
        proLayer:addList(greedBar):alignTo(nil, ui.cc)

        local progress = ui.label({fnt = FONT.D5, color = "#efd8ca", fontSize = 16, text = "--"})
        proLayer:addList(progress):alignTo(nil, ui.cc)

        local attrName = ui.label({fnt = FONT.D4, color = "#653e25", text = attrConf.name, reqW = 120})
        view:addList(attrName):alignTo(proLayer, ui.ct)

        attrNodeMap[checkint(attrId)] = {
            view      = view,
            iconLayer = iconLayer,
            attrName  = attrName,
            redBar    = redBar,
            greedBar  = greedBar,
            progress  = progress,
        }
    end

    return {
        view        = parent,
        attrNodeMap = attrNodeMap,
    }
end


function CatModuleCatInfoView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({bg = RES_DICT.VIEW_FRAME}),
    })

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('猫咪之屋'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})

    local releaseResultLayer = ui.title({n = RES_DICT.DIE_OR_RELEASE_BG}):updateLabel({fnt = FONT.D4, color = "#f1ecda", text = "--"})
    releaseResultLayer:setVisible(false)
    view:addList(releaseResultLayer):alignTo(nil, ui.cc, {offsetY = 70})
    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- [catLayer] | [catStateNodeLayer] | [uiLayer] | [catReleaseLayer]
    local frameGroup = centerLayer:addList({
        ui.layer({}),
        ui.layer({}),
        ui.layer({}),
        ui.layer({}),
        ui.layer({}),
    })
    -------------------------------------------------- [catAttr layer]
    local stateNodeLayer  = frameGroup[3]
    -- local stateNodePos    = {cc.p(-500, 70), cc.p(-450, 250), cc.p(-300, 50), cc.p(-260, 170), cc.p(500, 100), cc.p(350, 100), cc.p(200, 50), cc.p(200, 250)}
    -- local stateNodes      = {}
    -- for index, pos in ipairs(stateNodePos) do
    --     local layer = ui.layer({size = cc.size(100, 100), color = cc.r4b(180), enable = true})
    --     stateNodeLayer:addList(layer):alignTo(nil, ui.cc, {offsetX = pos.x, offsetY = pos.y})

    --     table.insert(stateNodes, layer)
    -- end

    -------------------------------------------------- [state layer]
    local stateLayer = frameGroup[2]
    -- local dieImg = ui.image({img = RES_DICT.DIE_IMG})
    -- stateLayer:addList(dieImg):alignTo(nil, ui.cc, {offsetY = 120})

    -- state
    local catStateImg = ui.tButton({n = RES_DICT.BREED_NAME_BG, s = RES_DICT.WEEK_NAME_BG, d = RES_DICT.DEAD_NAME_BG, scale = 1.3})
    catStateImg:setTouchEnabled(false)
    stateLayer:addList(catStateImg):alignTo(nil, ui.cc, {offsetY= 60})

    catStateImg:getSelectedImage():addList(ui.label({fnt = FONT.D19, fontSize = 22, outline = "#821e0f", text = __("生病中"), reqW = 190})):alignTo(nil, ui.cc)
    local normalStr = ui.label({fnt = FONT.D19, fontSize = 22, outline = "#304767", text = __("孕育中"), reqW = 190})
    catStateImg:getNormalImage():addList(normalStr):alignTo(nil, ui.cc)
    catStateImg:getDisabledImage():addList(ui.label({fnt = FONT.D19, fontSize = 22, outline = "#2e2e2e", text = __("回喵星"), reqW = 190})):alignTo(nil, ui.cc)

    local timeTitle = ui.label({fnt = FONT.D14, text = "--", offset = cc.p(0, 5)})
    catStateImg:addList(timeTitle):alignTo(nil, ui.cc, {offsetY = -60, offsetX = - 30})
    -------------------------------------------------- [ui Layer]

    local uiLayer = frameGroup[4]
    local bottomBg    = ui.tButton({n = RES_DICT.GIRL_FRAME, s = RES_DICT.BOY_FRAME})
    bottomBg:setTouchEnabled(false)
    uiLayer:addList(bottomBg):alignTo(nil, ui.cb, {offsetY = -100})

    -- 放生，归回选项
    local centerGrowBtnGroup = uiLayer:addList({
        ui.button({n = RES_DICT.DEL_BTN}):updateLabel({fnt = FONT.D14, outline = "#432410", text = __("放生"), offset = cc.p(0, -40)}),
        ui.button({n = RES_DICT.REBIRTH_BTN}):updateLabel({fnt = FONT.D14, outline = "#432410", text = __("归回"), offset = cc.p(0, -40)}),
    })
    ui.flowLayout(cc.rep(cc.p(0, 200), bottomBg:getPosition()), centerGrowBtnGroup, {type = ui.flowH, ap = ui.cc, gapW = 440})

    -- 猫咪基本信息----
    local catInfoGroup = uiLayer:addList({
        ui.button({n = RES_DICT.NAME_BG}):updateLabel({fnt = FONT.D14, text = "--", outline = "#432410"}),
        ui.layer({size = cc.size(300, 90), color = cc.r4b(0), enable = true}),
    })
    ui.flowLayout(cc.rep(cc.p(0, 120), bottomBg:getPosition()), catInfoGroup, {type = ui.flowV, ap = ui.cc})

    -- 名字 性别
    local nameBtn = catInfoGroup[1]
    local sexIcon = ui.tButton({n = RES_DICT.GIRL_ICON, s = RES_DICT.BOY_ICON})
    sexIcon:setTouchEnabled(false)
    nameBtn:addList(sexIcon):alignTo(nil, ui.lc)
    nameBtn:addList(ui.image({img = RES_DICT.RENAME_BTN})):alignTo(nil, ui.rc, {offsetX = 10})

    -- 成长期 代数 归回次数
    local catInfoLayer = catInfoGroup[2]
    local titleStrGroup = {__("年龄阶段:"), __("代数:"), __("是否归回:")}
    local attrNodeGroup = {}
    for _, str in ipairs(titleStrGroup) do
        local view = ui.layer({size = cc.size(250, 30)})
        view:addList(ui.image({img = RES_DICT.LINE_IMG})):alignTo(nil, ui.cb)
        view:addList(ui.label({fnt = FONT.D11, color = "#653e25", text = str, ap = lc})):alignTo(nil, ui.lc, {offsetX = 15})
        local value = ui.label({fnt = FONT.D11, color = "#8c6553", text = "--", ap = ui.rc})
        view:addList(value):alignTo(nil, ui.rc, {offsetX = -15})
        view.value = value
        table.insert(attrNodeGroup, view)
    end
    catInfoLayer:addList(attrNodeGroup)
    ui.flowLayout(cc.sizep(catInfoLayer, ui.cc), attrNodeGroup, {type = ui.flowV, ap = ui.cc})

    attrNodeGroup[1]:addList(ui.image({img = RES_DICT.SEARCH_IMG})):alignTo(nil, ui.rc, {offsetX = 25})

    -- 猫咪属性信息----
    local bottomLayer = ui.layer({size = cc.size(1300, 270)})
    uiLayer:addList(bottomLayer):alignTo(nil, ui.cb)
    -- 能力
    bottomLayer:addList(ui.label({fnt = FONT.D4, color = "#FFFFFF", text = __("能力"), reqW = 130})):alignTo(nil, ui.cc, {offsetX = -580, offsetY = 130})
    local abilityView = CatModuleCatInfoView.CreateAbilityView()
    bottomLayer:addList(abilityView.view):alignTo(nil, ui.lb, {offsetY = 30})

    -- 状态
    bottomLayer:addList(ui.label({fnt = FONT.D4, color = "#FFFFFF", text = __("状态")})):alignTo(nil, ui.cc, {offsetX = 580, offsetY = 130})
    local attrViewData = CatModuleCatInfoView.CreateAttrView()
    bottomLayer:addList(attrViewData.view):alignTo(nil, ui.rb, {offsetY = 30})


    local fileBtn = ui.button({n = RES_DICT.BOOK_IMG}):updateLabel({fnt = FONT.D14, outline = "#432410", text = __("猫猫档案"), offset = cc.p(0, -50)})
    uiLayer:addList(fileBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = 70})

    local achieveBtn = ui.button({n = RES_DICT.ACHIEVE_IMG}):updateLabel({fnt = FONT.D14, outline = "#432410", text = __("猫猫成就"), offset = cc.p(0, -50)})
    uiLayer:addList(achieveBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L - 130, offsetY = 40})

    local guideBtn = ui.button({n = RES_DICT.BTN_CAT_GUIDE}):updateLabel({fnt = FONT.D14, outline = "#432410", text = __("指南"), offset = cc.p(-8, -35)})
    uiLayer:addList(guideBtn):alignTo(nil, ui.rc, {offsetX = -display.SAFE_L, offsetY = 40})

    -------------------------------------------------- [grow btn layer]
    local catGrowBtnLayer = frameGroup[5]
    local catGrowInfo = {
        {n = RES_DICT.LIFE_IMG, s = RES_DICT.LIFE_IMG, text = __("生活")},
        {n = RES_DICT.WORK_IMG, s = RES_DICT.WORK_IMG_G,text = __("深造")},
        {n = RES_DICT.MATCH_IMG, s = RES_DICT.MATCH_IMG_G, text = __("配对")},
    }
    local leftGrowBtnGroup = {}
    for _, btnInfo in ipairs(catGrowInfo) do
        local view = ui.layer({size = cc.size(140, 120), color = cc.r4b(0), enable = true, scale = 0.95})
        local btnGroup = view:addList({
            ui.tButton({n = btnInfo.n, s = btnInfo.s, mt = -20}),
            ui.tButton({n = RES_DICT.GROW_BTN, s = RES_DICT.GROW_BTN_G, mt = -40}),
        })
        ui.flowLayout(cc.rep(cc.sizep(view, ui.cc), 0, 10), btnGroup, {type = ui.flowV, ap = ui.cc})

        local title = btnGroup[2]
        title:getNormalImage():addList(ui.label({fnt = FONT.D14, outline = "#432410", text = btnInfo.text, reqW = 120})):alignTo(nil, ui.cc)
        title:getSelectedImage():addList(ui.label({fnt = FONT.D14, outline = "#353535", text = btnInfo.text, reqW = 120})):alignTo(nil, ui.cc)
        
        local lockimg = ui.image({img = RES_DICT.LOCKED_IMG})
        view:addList(lockimg):alignTo(nil, ui.cb, {offsetY = 60})

        view.title = title
        view.updateLockedStatue = function(visible)
            lockimg:setVisible(visible)
            btnGroup[1]:setChecked(visible)
            btnGroup[2]:setChecked(visible)
        end

        table.insert(leftGrowBtnGroup, view)
    end
    catGrowBtnLayer:addList(leftGrowBtnGroup)
    ui.flowLayout(cc.rep(cc.sizep(catGrowBtnLayer, ui.lc), display.SAFE_L, 100), leftGrowBtnGroup, {type = ui.flowV, ap = ui.lc})

    local lifeBtn = leftGrowBtnGroup[1]
    local diseaseImg = ui.image({img = RES_DICT.DISEASE_IMG})
    lifeBtn.title:addList(diseaseImg):alignTo(nil, ui.cc)
    lifeBtn.updateLockedStatue(false)
    diseaseImg:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5), cc.FadeOut:create(0.5))))


    -- to debug use
    local openDebugAttrFunc = nil
    if checkint(DEBUG) > 0 then
        local debugAttrLayer = ui.layer({size = cc.size(500, 180), x = display.cx, ap = ui.cb, color = cc.c4b(0,0,0,150)})
        view:add(debugAttrLayer)
        
        local attrLabelMap  = {}
        local attrLabelList = {}
        for _, attrId in ipairs(CONF.CAT_HOUSE.CAT_ATTR:GetIdListUp()) do
            local attrConf  = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
            local attrLabel = ui.label({fnt = FONT.D12, text = tostring(attrConf.name), ap = ui.lc})
            attrLabel:setSystemFontName('Menlo')
            table.insert(attrLabelList, attrLabel)
            attrLabelMap[tostring(attrId)] = attrLabel
            attrLabel.attrName = tostring(attrConf.name)
        end
        ui.flowLayout(cc.rep(cc.sizep(debugAttrLayer, ui.lc), 10, 0), attrLabelList, {type = ui.flowV, ap = ui.lc, gapH = 6})
        debugAttrLayer:addList(attrLabelList)
        
        openDebugAttrFunc = function(catUuid)
            local debugCatModel = app.catHouseMgr:getCatModel(catUuid)
            titleBtn:setText(catUuid)
            debugAttrLayer.lastUpdateTime = 0
            debugAttrLayer:scheduleUpdateWithPriorityLua(function(dt)
                local currentTimestamp = os.time()
                if currentTimestamp - debugAttrLayer.lastUpdateTime > 0.5 then
                    for attrId, attrModel in pairs(debugCatModel:getAllAttrModel()) do
                        local updateTimestamp = attrModel:getUpdateTimestamp()
                        local reduceSeconds   = attrModel:getReduceTime()
                        local offsetSeconds   = currentTimestamp - updateTimestamp
                        local catAttrLabel    = attrLabelMap[tostring(attrId)]
                        if catAttrLabel then
                            catAttrLabel:setString(string.format('%s : %7d * %0.2f = %7d / %d%s', 
                                catAttrLabel.attrName, 
                                attrModel:getReduceBase(),
                                1 + attrModel:getReduceRate()/100,
                                reduceSeconds,
                                offsetSeconds,
                                attrModel:isDisableReduce() and '[x]' or ''
                                -- tostring(reduceSeconds > 0 and offsetSeconds >= reduceSeconds and attrModel:getAttrNum() > 0 and attrModel:isDisableReduce() == false),
                            ))
                        end
                        debugAttrLayer.lastUpdateTime = currentTimestamp
                    end
                end
            end, 0)
        end
    end

    return {
        view               = view,
        --                 = top
        backBtn            = backBtn,
        catStateImg        = catStateImg,
        lifeBtn            = leftGrowBtnGroup[1],
        studyBtn           = leftGrowBtnGroup[2],
        matchBtn           = leftGrowBtnGroup[3],
        fileBtn            = fileBtn,
        achieveBtn         = achieveBtn,
        guideBtn           = guideBtn,
        abilityNodeMap     = abilityView.abilityNodeMap,
        abilityYouthPage   = abilityView.youthPage,
        abilityGrowPage    = abilityView.growPage,
        attrNodeMap        = attrViewData.attrNodeMap,
        releaseBtn         = centerGrowBtnGroup[1],
        rebirthBtn         = centerGrowBtnGroup[2],
        sexIcon            = sexIcon,
        nameBtn            = nameBtn,
        infoBtn            = catInfoLayer,
        growStageLabel     = attrNodeGroup[1].value,
        algebraLabel       = attrNodeGroup[2].value,
        rebirthNumLabel    = attrNodeGroup[3].value,
        sexBg              = bottomLayer,
        catLayer           = frameGroup[1],
        stateNodeLayer     = stateNodeLayer,
        -- dieImg             = dieImg,
        centerLayer        = centerLayer,
        releaseResultLayer = releaseResultLayer,
        catGrowBtnLayer    = catGrowBtnLayer,
        bottomBg           = bottomBg,
        normalStr          = normalStr,
        diseaseImg         = diseaseImg,
        titleBtn           = titleBtn,
        openDebugAttrFunc  = openDebugAttrFunc,
        timeTitle          = timeTitle
    }
end


function CatModuleCatInfoView.CreateFadeLabel(descr, delta)
    local fadeLabel = ui.label({fnt = FONT.D14, text = descr})
    fadeLabel:setVisible(false)
    fadeLabel:runAction(cc.Sequence:create(
        cc.DelayTime:create(delta),
        cc.CallFunc:create(function()
            fadeLabel:setVisible(true)
        end),
        cc.Spawn:create(
            cc.FadeOut:create(0.5), 
            cc.MoveBy:create(0.5, cc.p(0, 100))
        ),
        cc.CallFunc:create(function()
            fadeLabel:runAction(cc.RemoveSelf:create())
        end)
    ))
    return fadeLabel
end


return CatModuleCatInfoView
