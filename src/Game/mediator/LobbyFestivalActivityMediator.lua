--[[
餐厅节日活动Mediator
--]]
local Mediator = mvc.Mediator
local LobbyFestivalActivityMediator = class("LobbyFestivalActivityMediator", Mediator)

local NAME = "LobbyFestivalActivityMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local FESTIVAL_ACTIVITY_STATE = {
    PREVIEW = 1,    -- 活动预览装填 
    OPEN    = 2,    -- 活动开始状态
}

local ATTR_KEY_CONFIG     = {'taste', 'museFeel', 'fragrance', 'exterior'}
local ATTR_NAME_CONFIG    = {__('味道'), __('口感'), __('香味'), __('外观')}

local VDATA = function ( )
    local chooseData = gameMgr:GetUserInfo().cookingStyles

    local datas = {}
    for i,v in ipairs(chooseData['0']) do

        local data = {
            recipe = v.recipeId,
            recipeGrade = v.gradeId,
            attr = {
                taste = v.taste + math.random( 1, 20),
                museFeel = v.museFeel + math.random( 1, 30),
                fragrance = v.fragrance - math.random( 1, 40),
                exterior = v.exterior - math.random( 1, 25),
            }
        }
        table.insert(datas, data)
    end
    -- "recipeId"       = "220005"
    return datas
end

function LobbyFestivalActivityMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)

    self.isReceiveResponse = false

    self.args = checktable(params)
    
    self.tag = checkint(self.args.tag) or RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW

    self.datas = {}
    self.recipes = {}

    self:initData()
    
    -- dump(self.chooseData[ALL_RECIPE_STYLE], 'dawefcawea')

    -- dump(self.datas, '22LobbyFestivalActivityMediator22')
end

function LobbyFestivalActivityMediator:InterestSignals()
    local signals = {
        POST.Activity_Draw_restaurant.sglName,
        UPDATE_LOBBY_FESTIVAL_ACTIVITY_PREVIEW_UI,
        LOBBY_FESTIVAL_ACTIVITY_END,
        LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END,
        COUNT_DOWN_ACTION,
	}

	return signals
end

function LobbyFestivalActivityMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.Activity_Draw_restaurant.sglName then
        -- 更新餐厅活动 （例：从预览 到 开启）
        if self.isReceiveResponse then return end
        self.isReceiveResponse = true
        self.tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY
        
        -- 重新走 初始化
        self:initData()
        self:initUi()
    elseif name == UPDATE_LOBBY_FESTIVAL_ACTIVITY_PREVIEW_UI then
        
    elseif name == COUNT_DOWN_ACTION then
        local tag = checkint(body.tag)
        if self.tag ~= tag then return end
        if tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
            local countDownBg          = self.viewData.countDownBg
            local countDownLabel       = self.viewData.countDownLabel
            local seconds              = checkint(body.countdown)
            
            countDownBg:setVisible(true)
            
            local timeConf = self:analysisSeconds(seconds)
            display.reloadRichLabel(countDownLabel, {c = timeConf})
        elseif tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW  then
            local countDownBg          = self.viewData.countDownBg
            local countDownLabel       = self.viewData.countDownLabel
            local seconds              = checkint(body.countdown)
            
            countDownBg:setVisible(true)
            local timeConf = self:analysisSeconds(seconds)
            display.reloadRichLabel(countDownLabel, {c = timeConf})
        end
        
    elseif name == LOBBY_FESTIVAL_ACTIVITY_END then

    elseif name == LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END then
        if not app.activityMgr:isOpenLobbyFestivalActivity() then
            self:SendSignal(POST.Activity_Draw_restaurant.cmdName)
        end
    end

end

function LobbyFestivalActivityMediator:Initial( key )
    self.super.Initial(self,key)
    
    local scene = uiMgr:GetCurrentScene()
    local viewComponent = require('Game.views.LobbyFestivalActivityView').new({mediatorName = NAME})
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    self.viewData = viewComponent.viewData
    self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))

    self:initUi()
end

function LobbyFestivalActivityMediator:initUi()
    self:updateViewState()
    local gridView = self.viewData.gridView
    gridView:setCountOfCell(table.nums(self.recipes))
    gridView:reloadData()


end

function LobbyFestivalActivityMediator:updateViewState()
    local descLabel            = self.viewData.descLabel
    local title                = self.viewData.title
    local countDownBg          = self.viewData.countDownBg
    local countDownLabel       = self.viewData.countDownLabel

    local c = {}
    if self.tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW then
        countDownBg:setTexture(_res('avatar/ui/festival_bg_countdown.png'))
        c = {
            {text = __('离开始还有: '), fontSize = 22, color = '#5b3c25'},
        }
    elseif self.tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
        countDownBg:setTexture(_res('avatar/ui/festival_bg_countdown_over.png'))
        c = {
            {text = __('离结束还有: '), fontSize = 22, color = '#5b3c25'},
        }
    end
   
    local timeConf = self:analysisSeconds(self.datas.leftSeconds)
    for i,v in ipairs(timeConf) do
        table.insert(c, v)
    end
    display.reloadRichLabel(countDownLabel, {c = c})
    dump(self.datas)
    display.commonLabelParams(descLabel, {text = tostring(self.datas.detail[i18n.getLang()] or "")})
    display.commonLabelParams(title, {text = tostring(self.datas.title[i18n.getLang()] or "")})
    self:GetViewComponent():updateViewState(self.tag, self.datas)
end

function LobbyFestivalActivityMediator:OnDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell()
    end

    xTry(function()
        local viewData            = pCell.viewData
        local bg                  = viewData.bg
        local unlockBg            = viewData.unlockBg
        local attrLayer           = viewData.attrLayer
        local nameLabel           = viewData.nameLabel
        local qualityLayer        = viewData.qualityLayer
        local qualityImg          = viewData.qualityImg
        local qualityLabel        = viewData.qualityLabel
        local goodNode            = viewData.goodNode
        -- local attrNumberLabels    = viewData.attrNumberLabels
        local cuisineTipLabel     = viewData.cuisineTipLabel

        local serData         = self.recipes[index].serData
        local localData       = self.recipes[index].localData
        local localMenuData   = self.recipes[index].localMenuData
        local menuName        = localMenuData.name
        local gradeId         = serData.recipeGrade
        local localMenuDataGrade = checkint(localMenuData.quality)

        local isOwnMenu = localData ~= nil
        bg:setVisible(isOwnMenu)
        attrLayer:setVisible(isOwnMenu)
        qualityLayer:setVisible(isOwnMenu)

        unlockBg:setVisible(not isOwnMenu)
        cuisineTipLabel:setVisible(not isOwnMenu)

        display.commonLabelParams(nameLabel, {text = menuName, color = isOwnMenu and '#ba5c5c' or '#a19b85'})

        goodNode:RefreshSelf({goodsId = serData.recipe})
        
        if isOwnMenu then
            -- 1. 渲染菜谱
            self:renderMenu(attrLayer, serData, localData, localMenuDataGrade)
            -- 2. 更新菜谱评级
            qualityImg:setTexture(app.cookingMgr:getCookingGradeImg(gradeId))
        else

        end

	end,__G__TRACKBACK__)

    return pCell
end

function LobbyFestivalActivityMediator:renderMenu(attrLayer, serData, localData, localMenuDataGrade)
    if attrLayer:getChildrenCount() > 0 then
        attrLayer:removeAllChildren()
    end

    local serAttr    = serData.attr
    local gradeId    = checkint(serData.recipeGrade)
    local isGradeSatisfy = localMenuDataGrade >= gradeId

    print('gradeiddddd', localMenuDataGrade, gradeId)
    local showAttr   = self:getShowAtrr(serAttr, localData, isGradeSatisfy)

    for i,attr in ipairs(showAttr) do
        self:GetViewComponent():CreateAttr(attrLayer, i, attr)
    end
end

function LobbyFestivalActivityMediator:analysisSeconds(seconds)
    local timeConf = {
        {text = (self.tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY) and __('离结束还有: ') or __('离开始还有: '), fontSize = 22, color = '#5b3c25'},
    }
    if seconds >= 86400 then
        local day = math.floor(seconds / 86400)
        table.insert( timeConf, {text = day, fontSize = 22, color = '#ffffff'})
        table.insert( timeConf, {text = __('天'), fontSize = 22, color = '#5b3c25'})
        
    elseif seconds >= 3600 then
        local hour   = math.floor(seconds / 3600)
        local minute = math.floor((seconds - hour*3600) / 60)

        table.insert( timeConf, {text = hour, fontSize = 22, color = '#ffffff'})
        table.insert( timeConf, {text = __('小时'), fontSize = 22, color = '#5b3c25'})
        table.insert( timeConf, {text = minute, fontSize = 22, color = '#ffffff'})
        table.insert( timeConf, {text = __('分钟'), fontSize = 22, color = '#5b3c25'})
    else
	    local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
        local sec    = (seconds - hour*3600 - minute*60)

        table.insert(timeConf, {text = minute, fontSize = 22, color = '#ffffff'})
        table.insert(timeConf, {text = __('分钟'), fontSize = 22, color = '#5b3c25'})
        table.insert(timeConf, {text = sec, fontSize = 22, color = '#ffffff'})
        table.insert(timeConf, {text = __('秒'), fontSize = 22, color = '#5b3c25'})
    end

    return timeConf
end

function LobbyFestivalActivityMediator:initData()
    self.chooseData = gameMgr:GetUserInfo().cookingStyles
    -- dump(self.chooseData, 'ddddddddddddddd')
    local recipe = {}
    if self.tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW then
        self.datas = gameMgr:GetUserInfo().restaurantActivityPreview
        recipe = self.datas.content
    elseif self.tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
        self.datas = gameMgr:GetUserInfo().restaurantActivity
        recipe = self.datas.content.recipes
    end

    for i,v in pairs(recipe) do
        local recipeId = v.recipe
        self.recipes[checkint(i)] = {serData = v, localData = self:getLocalMenuData(recipeId), localMenuData = CommonUtils.GetConfig('goods', 'recipe', recipeId)}
    end
    -- dump(self.recipes, 'sxxweas')
end

function LobbyFestivalActivityMediator:getShowAtrr(serAttr, localData, isGradeSatisfy)
    local showAttr = {}
    for i,attrName in ipairs(ATTR_NAME_CONFIG) do
        if serAttr[tostring(i)] then
            local attrNum = checkint(serAttr[tostring(i)])
            local localNum = checkint(localData[ATTR_KEY_CONFIG[i]])
            print(localNum, attrNum)
            local isNumSatisfy = localNum >= attrNum

            local color = isNumSatisfy and '#30ab05' or  '#c52d02'
            table.insert(showAttr, {attrName = attrName, num = attrNum, color = color})
        else
            table.insert(showAttr, {attrName = attrName, num = '--', color = '#30ab05'})
        end
    end
    return showAttr
end

--==============================--
--desc:判断是否拥有该 菜谱是否开启
--time:2017-12-15 06:16:07
--@args:
--@return 
--==============================-- 
function LobbyFestivalActivityMediator:getLocalMenuData(recipeId)
    -- 在所有菜谱中查找
    for i,v in ipairs(self.chooseData[ALL_RECIPE_STYLE]) do
        if checkint(v.recipeId) == checkint(recipeId) then
            return v
        end
    end
    return nil
end

function LobbyFestivalActivityMediator:enterLayer()
    
    -- if self.tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
    --     if not app.activityMgr:isOpenLobbyFestivalActivity() then
    --         self:SendSignal(POST.Activity_Draw_restaurant.cmdName)
    --     end
    -- end
end

function LobbyFestivalActivityMediator:OnRegist(  )
    regPost(POST.Activity_Draw_restaurant)
    -- self:enterLayer()
end

function LobbyFestivalActivityMediator:OnUnRegist(  )
    unregPost(POST.Activity_Draw_restaurant)

    local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
end

return LobbyFestivalActivityMediator