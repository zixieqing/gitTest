--[[

--]]
local RecipeStyleKindsDetailView = class('RecipeStyleKindsDetailView', function()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.RecipeStyleKindsDetailView'
    node:enableNodeEvents()

    return node
end)

local BackpackCell = require('home.BackpackCell')
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local RES_DICT = {
    SELECT_BTN = _res("ui/common/common_btn_tab_select.png"),
    NORMAL_BTN = _res("ui/common/common_btn_tab_default.png"),
    GOODSGRIDBG = _res("ui/common/common_bg_goods.png"),
    COOKING_BAR1 = _res('ui/home/kitchen/cooking_mastery_bar_1.png'),
    COOKING_BAR2 = _res('ui/home/kitchen/cooking_mastery_bar_2.png'),
    BG_FONT_NAME = _res("ui/common/common_cooking_bg_font_name.png"),
    COOKING_BAR = _res('ui/home/kitchen/cooking_mastery_bar_bg.png'),

}
local BTN_TAG = {
    COMMOM_TAG = 1001,
    UNCOMMOM_TAG = 1002,
}
local UNCOMMON_STYLE_TYPE = 0
local COMMONSTYLE_TYPE = 1
function RecipeStyleKindsDetailView:ctor(param)
    param = param or {}
    self.styleType = param.styleType or 1 --这个表示菜系的风格
    self.styleData = gameMgr:GetUserInfo().cookingStyles[tostring(self.styleType)] or {} -- 该菜谱的数据
    self.preIndex = nil  --表示上一次点击的
    self.type = 0   -- 0 、 为普通的菜谱 1、 为特殊而菜谱
    self.recipeData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    self.unLockData = CommonUtils.GetConfigAllMess('unlockType')
    self.commonRecipeData = self:getRecipeTypeByData(1)
    self.uncommonRecipeData = self:getRecipeTypeByData(0)
    self.commonStyleRecipeData, self.uncommonStyleRecipeData = self:getStyleCommonAndUncommonRecipe()
    self:initUI()
end
function RecipeStyleKindsDetailView:initUI()
    local name = CommonUtils.GetConfigAllMess('style', 'cooking')[tostring(self.styleType)].name
    local view = require("common.TitlePanelBg").new({ title = string.fmt(__('_name_一览'), {['_name_'] = name}), type = 2 })
    view.viewData.view:setPosition(display.center)
    view.viewData.view:setAnchorPoint(display.CENTER)
    local titleLabel = view.viewData.titleLabel
    local pos = cc.p(titleLabel:getPositionX() - 11, titleLabel:getPositionY() + 5)
    titleLabel:setPosition(pos)
    display.commonUIParams(view, { ap = display.CENTER, po = cc.p(display.cx, display.cy) })
    self:addChild(view)
    local unClose = true
    view.viewData.eaterLayer:setOnClickScriptHandler(function()
        -- body
        if unClose then
            unClose = true
            self:runAction(cc.RemoveSelf:create())
        end
    end)
    local bgSize = view.viewData.view:getContentSize()
    local bgLayout = CLayout:create(bgSize)
    local swallowLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true })
    bgLayout:addChild(swallowLayer)
    local listSize = cc.size(685, bgSize.height - 55)
    local listView = CListView:create(listSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setBounceable(true)
    listView:setAnchorPoint(display.CENTER_TOP)
    listView:setPosition(cc.p(bgSize.width * 0.5, bgSize.height - 42))
    bgLayout:addChild(listView)
    if checkint(#self.commonStyleRecipeData) > 0 then
        local cellLayout = self:createProgressLayout(COMMONSTYLE_TYPE)
        listView:insertNodeAtLast(cellLayout)
        cellLayout = self:createRecipeCellLayout(COMMONSTYLE_TYPE)
        listView:insertNodeAtLast(cellLayout)
    end
    if checkint(#self.uncommonStyleRecipeData) > 0 then
        local cellLayout = self:createProgressLayout(UNCOMMON_STYLE_TYPE)
        listView:insertNodeAtLast(cellLayout)
        cellLayout = self:createRecipeCellLayout(UNCOMMON_STYLE_TYPE)
        listView:insertNodeAtLast(cellLayout)
    end

    listView:reloadData()
    view:AddContentView(bgLayout)

    self.bgLayout = view
    self.viewData = {
        gridView = gridView,
        btns = btns,
        uncommonRecipeBtn = uncommonRecipeBtn,
        commonRecipeBtn = commonRecipeBtn,
        eaterLayer = view.viewData.eaterLayer,
    }

end
function RecipeStyleKindsDetailView:createProgressLayout(type)
    local cellSize = cc.size(685, 56)
    local cellLayout = CLayout:create(cellSize)
    local styleKindData = CommonUtils.GetConfigAllMess('style', 'cooking')[tostring(self.styleType)]
    local Value_SpecialMax = 0
    local value_Special = 0
    local text = __('精致菜谱')
    if checkint(type) ~= UNCOMMON_STYLE_TYPE then
        -- 根据类型创建cell
        Value_SpecialMax = checkint(#self.commonStyleRecipeData)
        value_Special = #self.commonRecipeData
        text = __('普通菜谱')
    else
        Value_SpecialMax = checkint(#self.uncommonStyleRecipeData)
        value_Special = #self.uncommonRecipeData
    end
    local titleBtn = display.newButton(0, 10, { n = RES_DICT.BG_FONT_NAME, ap = display.LEFT_BOTTOM, enable = false })
    display.commonLabelParams(titleBtn, fontWithColor('8', { text = text }))
    cellLayout:addChild(titleBtn)-- body
    local expBarSpecial = CProgressBar:create(RES_DICT.COOKING_BAR1) -- 判断进度条的长度
    expBarSpecial:setBackgroundImage(RES_DICT.COOKING_BAR)
    expBarSpecial:setDirection(eProgressBarDirectionLeftToRight)
    expBarSpecial:setMaxValue(Value_SpecialMax)
    expBarSpecial:setValue(value_Special)
    expBarSpecial:setShowValueLabel(true)
    expBarSpecial:setPosition(cc.p(cellSize.width - 5, 10))
    expBarSpecial:setAnchorPoint(display.RIGHT_BOTTOM)
    display.commonLabelParams(expBarSpecial:getLabel(), fontWithColor('9') )
    cellLayout:addChild(expBarSpecial)
    local expBarSpecialSize = expBarSpecial:getContentSize()
    local progressLabel = display.newLabel(-10, expBarSpecialSize.height / 2, fontWithColor('16', { text = __('收集进度'), ap = display.RIGHT_CENTER }))
    expBarSpecial:addChild(progressLabel)
    return cellLayout
end

function RecipeStyleKindsDetailView:createRecipeCellLayout(type)
    local count = 0
    local styleKindData = CommonUtils.GetConfigAllMess('style', 'cooking')[tostring(self.styleType)]
    local currentData = nil
    if type == UNCOMMON_STYLE_TYPE then
        currentData = self.uncommonStyleRecipeData
    else
        currentData = self.commonStyleRecipeData
    end
    count = math.ceil(#currentData / 6)
    local distance = 8
    local cellSize = cc.size(685, (count * (distance + 108 ) + distance) )
    local bgSize = cc.size(685, (count * (distance + 108 ) + distance) )
    local cellLayout = CLayout:create(cellSize)
    local bgLayout = CLayout:create(bgSize)
    bgLayout:setPosition(cc.p(cellSize.width / 2, cellSize.height / 2))
    cellLayout:addChild(bgLayout)
    local bgImage = display.newImageView(RES_DICT.GOODSGRIDBG, bgSize.width / 2, bgSize.height / 2, { scale9 = true, size = bgSize, ap = display.CENTER })
    bgLayout:addChild(bgImage)
    local seq = {}
    for i = 1, #currentData do
        local line = math.ceil(i / 6)
        local PosX = (((i - 0.5) - math.floor((i - 0.5) / 6) * 6) * 108) + ( math.ceil( ((i - 0.5 ) % 6 )) * 2 - 1) * 2.5 - 52   -- 计算x的左边 ，计算组边边
        local posY = bgSize.height - (line - 0.5) * 108 - line * distance - 48
        local pCell = BackpackCell.new(cc.size(108, 108) )
        pCell:setPosition(cc.p(PosX, posY))
        bgLayout:addChild(pCell)
        local quality = 1
        if data then
            if data.quality then
                quality = data.quality
            end
        end
        local data = CommonUtils.GetConfig('goods', 'goods', currentData[i].goodsId)
        local drawBgPath = _res('ui/common/common_frame_goods_' .. tostring(quality) .. '.png')
        local fragmentPath = _res('ui/common/common_ico_fragment_' .. tostring(quality) .. '.png')
        if not utils.isExistent(drawBgPath) then
            drawBgPath = _res('ui/common/common_frame_goods_' .. tostring(1) .. '.png')
            fragmentPath = _res('ui/common/common_ico_fragment_' .. tostring(quality) .. '.png')
        end
        pCell.fragmentImg:setTexture(fragmentPath)
        pCell.toggleView:setNormalImage(drawBgPath)
        pCell.toggleView:setSelectedImage(drawBgPath)
        pCell.toggleView:setScale(0.92)
        pCell.toggleView:setEnabled(false)
        pCell.toggleView:setTag(checkint(currentData[i].id))
        local parentNode = pCell.toggleView:getParent()
        local parentSize = parentNode:getContentSize()
        local clickLayer = display.newLayer(parentSize.width / 2, parentSize.height / 2, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), size = cc.size(parentSize.width * 0.95, parentSize.height * 0.95 ), enable = true })
        --pCell.toggleView:setOnClickScriptHandler(handler(self,self.cellButtonAction))
        clickLayer:setTag(checkint(currentData[i].id))
        parentNode:addChild(clickLayer, 10)
        clickLayer:setOnClickScriptHandler(handler(self, self.cellButtonAction))
        local node = pCell.toggleView:getChildByTag(111)
        if node then
            node:removeFromParent()
        end
        dump(currentData[i].foods)
        local goodsId = currentData[i].foods[1].goodsId
        local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
        print("iconPath ---------->",iconPath)
        local sprite = display.newImageView(_res(iconPath), 0, 0, { as = false })
        sprite:setScale(0.55)
        local isIn = self:isInResearchRecipeData(currentData[i].id)
        if not isIn then
            sprite:setColor(cc.c3b(80, 80, 80))
        end
        clickLayer.isIn = isIn
        local lsize = pCell.toggleView:getContentSize()
        sprite:setPosition(cc.p(lsize.width * 0.5, lsize.height * 0.5))
        sprite:setTag(111)
        pCell.toggleView:addChild(sprite)
    end

    return cellLayout
end
-- 获取到当前菜谱中拥有的菜品
function RecipeStyleKindsDetailView:getRecipeTypeByData(recipeType)
    local data = {}
    for k, v in pairs(self.styleData) do

        local recipeData = self.recipeData[tostring(v.recipeId)]
        if checkint(recipeData.canStudyUnlock) == checkint(recipeType) then
            data[#data + 1] = clone(recipeData)
        end
    end

    return data
end
-- 获取该菜系的常见菜品和稀有菜品
function RecipeStyleKindsDetailView:getStyleCommonAndUncommonRecipe()
    local commonData = {}
    local uncommonData = {}
    for k, v in pairs(self.recipeData) do
        if self.styleType == checkint(v.cookingStyleId) then
            if checkint(v.canStudyUnlock) == UNCOMMON_STYLE_TYPE then
                uncommonData[#uncommonData + 1] = v
            elseif checkint(v.canStudyUnlock) == COMMONSTYLE_TYPE then
                commonData[#commonData + 1] = v
            end
        end
    end
    table.sort(commonData , function (a, b)
        if checkint(a.id) > checkint(b.id) then
            return false
        else
            return true
        end
    end)
    table.sort(uncommonData , function (a, b)
        if checkint(a.id) > checkint(b.id) then
            return false
        else
            return true
        end
    end)
    return commonData, uncommonData
end
--==============================--
--desc:刚方法是在验证是否存在于已开发的类型中
--time:2017-05-26 10:05:38
--return
--==============================--
-- 目前不知道数据的类型格式  先协程通用的 后面在修改
function RecipeStyleKindsDetailView:isInResearchRecipeData(recipeId)
    local isIn = false
    local recipeOneData = self.recipeData[tostring(recipeId)]
    local type = checkint(recipeOneData.canStudyUnlock)
    local data = (type == COMMONSTYLE_TYPE and self.commonRecipeData ) or self.uncommonRecipeData
    for k, v in pairs(data) do
        if checkint(v.id) == checkint(recipeId) then
            isIn = true
            break
        end
    end
    return isIn
end


--==============================--
--desc:用于切换稀有菜系和普通菜系
--time:2017-05-23 03:09:37
--return
--==============================--
-- function RecipeStyleKindsDetailView:changeGrideView(data)
--     self.viewData.gridView:setCountOfCell(#data)
--     self.viewData.gridView:reloadData()
-- end

function RecipeStyleKindsDetailView:GridViewDataAdapter( p_convertview, idx)
    -- body
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(111, 114)
    if self.userCurrentData and index <= table.nums(self.userCurrentData) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.userCurrentData[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self, self.cellButtonAction))
            if index <= 30 then
                pCell.eventnode:setPositionY(sizee.height - 800)
                pCell.eventnode:runAction(
                cc.Sequence:create(cc.DelayTime:create(index * 0.01),
                cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width * 0.5, sizee.height * 0.5)), 0.2))
                )
            else
                pCell.eventnode:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
            end
        else
            pCell.selectImg:setVisible(false)
            pCell.eventnode:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
        end
        xTry(function()
            local quality = 1
            if data then
                if data.quality then
                    quality = data.quality
                end
            end
            local drawBgPath = _res('ui/common/common_frame_goods_' .. tostring(quality) .. '.png')
            local fragmentPath = _res('ui/common/common_ico_fragment_' .. tostring(quality) .. '.png')
            if not utils.isExistent(drawBgPath) then
                drawBgPath = _res('ui/common/common_frame_goods_' .. tostring(1) .. '.png')
                fragmentPath = _res('ui/common/common_ico_fragment_' .. tostring(quality) .. '.png')
            end
            pCell.fragmentImg:setTexture(fragmentPath)
            pCell.toggleView:setNormalImage(drawBgPath)
            pCell.toggleView:setSelectedImage(drawBgPath)
            pCell.toggleView:setTag(checkint(self.userCurrentData[index].id))
            pCell.toggleView:setScale(0.92)
            pCell.toggleView:setTag(index)
            local node = pCell.toggleView:getChildByTag(111)
            if node then
                node:removeFromParent()
            end
            local goodsId = self.userCurrentData[index].foods[1].goodsId
            local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
            local sprite = display.newImageView(_res(iconPath), 0, 0, { as = false })
            -- sprite:setColor(cc.c3b(100,100,100))
            sprite:setScale(0.55)
            local isIn = self:isInResearchRecipeData(tostring(self.userCurrentData[index].id))
            if not isIn then
                sprite:setColor(cc.c3b(80, 80, 80))
            end
            pCell.toggleView.isIn = isIn
            local lsize = pCell.toggleView:getContentSize()
            sprite:setPosition(cc.p(lsize.width * 0.5, lsize.height * 0.5))
            sprite:setTag(111)
            pCell.toggleView:addChild(sprite)
        end, __G__TRACKBACK__)
        return pCell
    end
end
--[[
    字符串的分割方式 是以<b></b>
--]]
function RecipeStyleKindsDetailView:DisposeSpecialString (str )
    local count = string.len( str )
    local redTable = {}
    local i = 1
    while (i <= count ) do
        local x, y = string.find( str, "<b>.-</b>", i, false)
        print("x =%d , y =%d ", x, y )
        if x and y then
            i = y + 1
        else
            break
        end
        redTable[#redTable + 1] = { x, y }
    end
    local tabalestr = {}
    if redTable[1] then
        if redTable[1][1] > 1 then
            tabalestr[#tabalestr + 1] = { common = true, str = string.sub( str, 1, redTable[1][1] - 1 ) }
            --else
            --    local specialstr =  string.gsub(str,redTable[1][1],redTable[1][2])
            --    local x, y = string.find(specialstr,">.-<", 1,false)
            --    print("x , y " , x , y )
            --    if (x +1)  <= (y -1)  then
            --        local specialstr = string.sub(specialstr,x+1, y-1)
            --        tabalestr [#tabalestr+1] = {common = false , str  = specialstr}
            --    end
        end
    end
    local mediatorStr = ""

    for i = 1, #redTable do
        local str1 = string.sub( str, redTable[i][1], redTable[i][2])
        local x, y = string.find(str1, ">.-<", 1, false)
        if (x + 1) <= (y - 1) then
            local str2 = string.sub(str1, x + 1, y - 1)
            tabalestr[#tabalestr + 1] = { common = false, str = str2 }
        end
        if i == #redTable then
            if redTable[i][2] < count then
                tabalestr[#tabalestr + 1] = { common = true, str = string.sub( str, redTable[i][2] + 1, count) }
            end
        else
            tabalestr[#tabalestr + 1] = { common = true, str = string.sub( str, redTable[i][2] + 1, redTable[i + 1][1] - 1 ) }
        end
    end
    dump(tabalestr)
    local elementTable = {}
    for i = 1, #tabalestr do
        if tabalestr[i].common then
            elementTable[#elementTable + 1] = fontWithColor(8, { text = tabalestr[i].str })
        else
            elementTable[#elementTable + 1] = fontWithColor(8, { text = tabalestr[i].str, color = "d23d3d", fontSize = 20 })
        end
    end
    if #elementTable == 0 then
        elementTable[#elementTable + 1] = fontWithColor(8, { text = str })
    end
    dump(elementTable)
    return elementTable
end
function RecipeStyleKindsDetailView:cellButtonAction(sender)
    local tag = sender:getTag()
    PlayAudioByClickNormal()
    if sender.isIn then
        -- uiMgr:ShowInformationTips(__("该菜谱已经开发出来"))
        local goodsId = self.recipeData[tostring(tag)].foods[1].goodsId
        uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = goodsId, type = 1 })
    else
        local goodsId = self.recipeData[tostring(tag)].foods[1].goodsId
        local str = self.recipeData[tostring(tag)].foodMaterialTips
        local  curLang = i18n.getLang()


        if  curLang == 'zh-cn' or curLang == 'zh-tw'  then
            local elementTable = self:DisposeSpecialString(str)
            uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = goodsId, type = 5, descr = elementTable, isRich = true })
        else
            local str = self.recipeData[tostring(tag)].foodMaterialTips
            local elementTable = self:DisposeSpecialString(str)
            if isElexSdk() then
                local str = ""
                for i, v in pairs(elementTable) do
                    str = str .. v.text
                end
                elementTable = str
                uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = goodsId, type = 5, descr = elementTable, isRich = false })
            else
                uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = goodsId, type = 5, descr = elementTable, isRich = true  })
            end

        end
    end
end
return RecipeStyleKindsDetailView
