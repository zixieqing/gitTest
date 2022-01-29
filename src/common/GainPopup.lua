--[[
获取途径界面
--]]
---@class GainPopup
local GainPopup    = class('GainPopup', function()
    local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name  = 'common.GainPopup'
    clb:enableNodeEvents()
    return clb
end)
---@type UIManager
local uiMgr        = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr      = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local shareFacade  = AppFacade.GetInstance()
local AssistCell   = require('home.AssistCell')
local scheduler    = require('cocos.framework.scheduler')

--[[
]]
local jumpViewData = {
    [JUMP_MODULE_DATA.NORMAL_MAP]           = {
        ['jumpView'] = 'MapMediator',
    },
    [JUMP_MODULE_DATA.DIFFICULTY_MAP]       = {
        ['jumpView'] = 'MapMediator',
    },
    [JUMP_MODULE_DATA.TEAM_MAP]             = {
        ['jumpView'] = 'MapMediator',
    },
    [JUMP_MODULE_DATA.RESEARCH]             = {
        ['jumpView']    = 'RecipeDetailMediator',
        ['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
            ['jumpView'] = 'RecipeResearchAndMakingMediator',
            ['needData'] = { presStyleTag = 1002 }
        }
    },
    [JUMP_MODULE_DATA.RESTAURANT]           = {
        ['jumpView'] = 'AvatarMediator',
    -- ['firstLayer']  = 1003,
    },
    [JUMP_MODULE_DATA.TAKEWAY]              = {
        ['jumpView'] = '1',
        ['jumpDes']  = __('返回主界面看看有什么可以发送的外卖吧')
    },
    [JUMP_MODULE_DATA.EXPLORATIN]           = {
        ['jumpView'] = 'ExplorationMediator',
    },
    [JUMP_MODULE_DATA.DAILYTASK]            = {
        ['jumpView'] = 'task.TaskHomeMediator',

    },
    [JUMP_MODULE_DATA.CAPSULE]              = {
        ['jumpView'] = GAME_MODULE_OPEN.NEW_CAPSULE and 'drawCards.CapsuleNewMediator' or 'drawCards.CapsuleMediator'
    },
    [JUMP_MODULE_DATA.ACTIVITY]             = {
        ['jumpView'] = '1',
    },
    [JUMP_MODULE_DATA.GUILD]                = {
        ['jumpView'] = 'UnionLobbyMediator',
        ['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
            ['jumpView'] = 'UnionCreateHomeMediator',
        }
    },
    [JUMP_MODULE_DATA.SHOP]                 = {
        ['jumpView'] = 'ShopMediator',
    },
    [JUMP_MODULE_DATA.ARENA]                = {
        ['jumpView'] = '1',
    },
    [JUMP_MODULE_DATA.PAY]                  = {
        ['jumpView'] = 'CumulativeRechargeMediator',
    },
    [JUMP_MODULE_DATA.MONEYTREE]            = {
        ['jumpView'] = '1',
    },
    [JUMP_MODULE_DATA.TALENT_BUSSINSS]      = {
        ['jumpView'] = 'TalentMediator',
    },
    [JUMP_MODULE_DATA.TALENT_DAMAGE]        = {
        ['jumpView'] = 'TalentMediator',
    },
    [JUMP_MODULE_DATA.TALENT_ASSIT]         = {
        ['jumpView'] = 'TalentMediator',
    },
    [JUMP_MODULE_DATA.TALENT_CONTROL]       = {
        ['jumpView'] = 'TalentMediator',
    },

    [JUMP_MODULE_DATA.HANDBOOK]             = {
        ['jumpView'] = '1',
    },

    [JUMP_MODULE_DATA.MARKET]               = {
        ['jumpView'] = 'MarketMediator',
    },

    [JUMP_MODULE_DATA.CARBARN]              = {
        ['jumpView'] = '1',
    },

    [JUMP_MODULE_DATA.TOWER]                = {
        ['jumpView'] = 'TowerQuestHomeMediator',
    },

    [JUMP_MODULE_DATA.PET]                  = {
        ['jumpView'] = 'PetDevelopMediator',
    },
    [JUMP_MODULE_DATA.RECIPE_MAKE]          = {
        ['jumpView']    = 'RecipeDetailMediator',
        ['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
            ['jumpView'] = 'RecipeResearchAndMakingMediator',
            ['needData'] = { presStyleTag = 1002 }
        }
    -- ['sencondLayer']  = 1,
    },
    [JUMP_MODULE_DATA.RECIPE_STUDY]         = {
        ['jumpView']    = 'RecipeDetailMediator',
        ['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
            ['jumpView'] = 'RecipeResearchAndMakingMediator',
            ['needData'] = { presStyleTag = 1002 }
        }
    -- ['firstLayer']  = 1001,
    -- ['sencondLayer']  = 2,
    },
    [JUMP_MODULE_DATA.RECIPE_MASTER]        = {
        ['jumpView']    = 'RecipeDetailMediator',
        ['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
            ['jumpView'] = 'RecipeResearchAndMakingMediator',
            ['needData'] = { presStyleTag = 1002 }
        }
    -- ['firstLayer']  = 1001,
    -- ['sencondLayer']  = 3,
    },
    [JUMP_MODULE_DATA.MATERIALCOMPOSE]      = {
        ['jumpView'] = 'MaterialComposeMediator',
        ['isPopup']  = 1
    },
    [JUMP_MODULE_DATA.CARDSFRAGMENTCOMPOSE] = {
        ['jumpView'] = 'CardsFragmentComposeMediator',
        ['isPopup']  = 1
    },
    [JUMP_MODULE_DATA.SHOP_TIPS]            = {
        ['jumpView'] = 'ShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.RESTAURANT} or { goShopIndex = 'restaurant' }
    },
    [JUMP_MODULE_DATA.AIR_TRANSPORTATION]   = {
        ['jumpView'] = 'HomeMediator',
    },
    [JUMP_MODULE_DATA.ACHIEVEMENT]          = {
        ['jumpView'] = 'task.TaskHomeMediator',
        ['jumpData'] = { clickTag = 1002, isJumpRequest = true }
    },
    [JUMP_MODULE_DATA.MATERIAL_SCRIPT]      = {
        ['jumpView'] = 'MaterialTranScriptMediator',
    },
    [JUMP_MODULE_DATA.PROMOTERS]            = {
        ['jumpView'] = 'PromotersMediator'
    },
    [JUMP_MODULE_DATA.SKINSHOP]             = {
        ['jumpView'] = 'ShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.CARD_SKIN} or { goShopIndex = 'cardSkin' },
    },
    [JUMP_MODULE_DATA.PVC_ROYAL_BATTLE]             = {
        ['jumpView'] = 'PVCMediator'
    },
    [JUMP_MODULE_DATA.TEAM_BATTLE_SCRIPT]          = {
        ['jumpView'] = 'RaidHallMediator'
    },
    [JUMP_MODULE_DATA.UNION_SHOP]          = {
        ['jumpView'] = 'UnionShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.UNION} or nil,
    },
    [JUMP_MODULE_DATA.UNION_PARTY]          = {
        ['jumpView'] = 'UnionShopMediator'
    },
    [JUMP_MODULE_DATA.DIAMOND_SHOP]          = {
        ['jumpView'] = 'ShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.DIAMOND} or { goShopIndex = 'diamond' },
    },
    [JUMP_MODULE_DATA.GIFT_SHOP]          = {
        ['jumpView'] = 'ShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GIFTS} or { goShopIndex = 'chest' },
    },
    [JUMP_MODULE_DATA.GOODS_SHOP]          = {
        ['jumpView'] = 'ShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.PROPS} or { goShopIndex = 'goods' },
    },
    [JUMP_MODULE_DATA.MEDAL_SHOP]          = {
        ['jumpView'] = 'ShopMediator',
        ['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.PVP_ARENA} or { goShopIndex = 'arena' },
    },
    [JUMP_MODULE_DATA.TASTING_TOUR]          = {
        ['jumpView'] = "tastingTour.TastingTourChooseRecipeStyleMediator",
    },
    [JUMP_MODULE_DATA.CARD_GATHER]          = {
        ['jumpView'] = "CardGatherRewardMediator",
    },
    [JUMP_MODULE_DATA.SMELTING_PET]  = {
        ['jumpView'] = "PetSmeltingMediator"

    },
    [JUMP_MODULE_DATA.TAG_JEWEL_EVOL]  = {
        ['jumpView'] = "artifact.JewelEvolutionMediator"
    },
    [JUMP_MODULE_DATA.ARTIFACT_TAG]  = {

    },
     [JUMP_MODULE_DATA.FISHING_GROUND] = {
         ['jumpView'] = 'fishing.FishingGroundMediator',
         ['jumpData'] = {queryPlayerId = app.gameMgr:GetUserInfo().playerId}
     } ,                                                                  
    [JUMP_MODULE_DATA.FISHING_SHOP]           = {
        ['jumpView'] = "fishing.FishingShopMeditor",
    },
    [JUMP_MODULE_DATA.FISHING_SHOP_ONE]           = {
        ['jumpView'] = "fishing.FishingShopMeditor",
        ['jumpData'] = { goShopIndex = 1 }
    },
    [JUMP_MODULE_DATA.FISHING_SHOP_TWO]           = {
        ['jumpView'] = "fishing.FishingShopMeditor",
        ['jumpData'] = { goShopIndex = 2 }
    },
    [JUMP_MODULE_DATA.FISHING_SHOP_THREE]           = {
        ['jumpView'] = "fishing.FishingShopMeditor",
        ['jumpData'] = { goShopIndex = 3 }
    },

    [JUMP_MODULE_DATA.EXPLORE_SYSTEM]           = {
        ['jumpView'] = "exploreSystem.ExploreSystemMediator"
    },
    [JUMP_MODULE_DATA.WATER_BAR_MARKET]           = {
        ['jumpView'] = "waterBar.WaterBarMarketMediator"
    },
}

function GainPopup:ctor(...)
    self.args = unpack({ ... })
    self:setName('common.GainPopup')
    PlayAudioClip(AUDIOS.UI.ui_window_open.id)
    self.goodsId      = self.args.goodId or self.args.goodsId
    self.datas        = CommonUtils.GetConfig('goods', 'goods', self.goodsId)
    -- dump(self.datas)
    -- ui
    self.selectTable  = {} -- 当前选中的好友
    self.bgLayer      = nil
    self.bgImg        = nil
    self.rewardBg     = nil
    self.friendList   = nil
    self.cd           = nil
    self.cell         = nil

    local contentView = CColorView:create(cc.c4b(0, 0, 0, 100))
    contentView:setContentSize(display.size)
    contentView:setOnClickScriptHandler(function(sender)
        -- self.bgLayer:runAction(
        -- 	cc.Sequence:create(
        -- 		cc.EaseExponentialOut:create(
        -- 			cc.ScaleTo:create(0.2, 1.1)
        -- 		),
        -- 		cc.ScaleTo:create(0.1, 1),
        -- 		cc.TargetedAction:create(self, cc.RemoveSelf:create())
        -- 	)
        -- )
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end)
    contentView:setTouchEnabled(true)
    display.commonUIParams(contentView, { po = display.center })
    self:addChild(contentView, -1)

    -- bg
    local bgImg   = display.newImageView(_res('ui/common/common_bg_3.png'))
    self.bgImg    = bgImg
    local bgSize  = bgImg:getContentSize()
    local bgLayer = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, { size = bgSize, ap = cc.p(0.5, 0.5) })
    bgLayer:addChild(bgImg, 5)
    display.commonUIParams(bgImg, { po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5) })
    self:addChild(bgLayer)
    local cover = CColorView:create(cc.c4b(0, 0, 0, 0))
    cover:setTouchEnabled(true)
    cover:setContentSize(bgSize)
    cover:setAnchorPoint(cc.p(0, 0))
    bgLayer:addChild(cover, -1)
    self.bgLayer = bgLayer
    -- 顶部背景
    local bgUp   = display.newButton(bgSize.width * 0.5, bgSize.height - 3,
                                     { n = _res('ui/common/common_bg_title_2.png'), ap = cc.p(0.5, 1), enable = false })
    bgLayer:addChild(bgUp, 10)
    display.commonLabelParams(bgUp, { text = __('获取途径'), fontSize = 22, color = '#ffffff' })

    -- 图标背景
    if not self.datas or not self.datas.id then return end
    local iconBg = display.newImageView(_res(string.format('ui/common/common_frame_goods_' .. (self.datas.quality or 1) .. '.png')), bgSize.width * 0.2, bgSize.height * 0.8)
    bgLayer:addChild(iconBg, 10)
    local scaleValue = 0.55
    local goodsType  = CommonUtils.GetGoodTypeById(self.datas.id)
    if goodsType == GoodsType.TYPE_ARCHIVE_REWARD then
        if checkint(self.datas.rewardType) == 3 then
            local bottomImage = display.newImageView(_res('ui/common/create_roles_head_down_default'), bgSize.width * 0.2, bgSize.height * 0.8)
            bottomImage:setScale(0.55)
            bgLayer:addChild(bottomImage, 10)
            iconBg:setVisible(false)
            local spineAction = CommonUtils.GetAchieveRewardsGoodsSpineActionById(self.goodsId)
            if spineAction then
                bgLayer:addChild(spineAction,12)
                spineAction:setPosition(bgSize.width * 0.2, bgSize.height * 0.8)
                spineAction:setScale(0.55)
            end
        elseif checkint(self.datas.rewardType) == 1 then
            scaleValue = 0.51
            local spineAction = CommonUtils.GetAchieveRewardsGoodsSpineActionById(self.goodsId)
            if spineAction then
                bgLayer:addChild(spineAction,12)
                spineAction:setPosition(bgSize.width * 0.2, bgSize.height * 0.8)
                spineAction:setScale(0.55)
            end
        end
    end
    -- 物品icon
    local iconPath = CommonUtils.GetGoodsIconPathById(self.datas.id)
    local iconImg  = display.newImageView(_res(iconPath), bgSize.width * 0.2, bgSize.height * 0.8)

    iconImg:setScale(scaleValue)
    bgLayer:addChild(iconImg, 11)

    -- 物品名称
    local goodName = display.newLabel(bgSize.width * 0.33, bgSize.height * 0.885,
                                      { text = tostring(self.datas.name), fontSize = 22, color = '#ba5c5c' ,ap =  cc.p(0, 1)})
    bgLayer:addChild(goodName, 10)
    -- 物品描述
    local goodDescr = display.newLabel(0, 0,
                                       { text = tostring(self.datas.descr or ' '), fontSize = 20, color = '#6c6c6c', w = 320 })
    local goodDescrSize = display.getLabelContentSize(goodDescr)
    local goodLayout = display.newLayer(0,0,{size = goodDescrSize  })
    goodLayout:addChild(goodDescr)
    goodDescr:setPosition(goodDescrSize.width/2  , goodDescrSize.height/2)
    local listSize  = cc.size(330 ,120 )
    local listView = CListView:create(listSize )
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setPosition(bgSize.width * 0.33, bgSize.height * 0.83)
    listView:setAnchorPoint(display.LEFT_TOP)
    bgLayer:addChild(listView ,10 )
    listView:insertNodeAtLast(goodLayout)
    listView:reloadData()

    -- 数量
    local numLabel = display.newRichLabel(bgSize.width * 0.29, bgSize.height * 0.71, { c                               = {
        { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
        { text = tostring(checkint(gameMgr:GetAmountByGoodId(self.datas.id))), fontSize = 20, color = '#ba5c5c' } }, ap = cc.p(1, 1), r = true })
    bgLayer:addChild(numLabel, 10)

    -- 途径
    local wayLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.62,
                                      { text = __('通过以下几种途径可以获取'), fontSize = 20, color = '#5b3c25' })
    bgLayer:addChild(wayLabel, 10)

    -- 列表背景
    local listBg = display.newImageView(_res('ui/home/gain/gain_bg_frame_gray_1.png'), bgSize.width * 0.5, bgSize.height * 0.31,
                                        {})
    bgLayer:addChild(listBg, 10)
    self.listBg = listBg

    -- 途径列表
    local listBgFrameSize        = listBg:getContentSize()
    local gainListSize     = cc.size(listBgFrameSize.width, listBgFrameSize.height)
    local gainListCellSize = cc.size(gainListSize.width, 93)
    local gainListView     = CListView:create(gainListSize)
    gainListView:setDirection(eScrollViewDirectionVertical)
    gainListView:setBounceable(true)
    bgLayer:addChild(gainListView, 10)
    gainListView:setAnchorPoint(cc.p(0.5, 0))
    gainListView:setPosition(cc.p(bgSize.width * 0.5, 17))
    self.gainListView = gainListView

    local showAll     = false
    local TempDatas   = {}
    -- 如果物品类型为菜品，则添加请求途径

    if goodsType == GoodsType.TYPE_FOOD and CommonUtils.GetJumpModuleAvailable(JUMP_MODULE_DATA.FRIEND) then
        local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
        mediator:SendSignal(COMMANDS.COMMAND_Friend_AssistanceList)
    end
    if goodsType == GoodsType.TYPE_MONEY then
        --货币类
        if self.goodsId == DIAMOND_ID then
            -- 幻晶石
            display.reloadRichLabel(numLabel, { c  = {
                { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
                { text = tostring(gameMgr:GetUserInfo().diamond), fontSize = 20, color = '#ba5c5c' } },
                                                ap = cc.p(0, 1), r = true })
        elseif self.goodsId == GOLD_ID then
            -- 金币
            display.reloadRichLabel(numLabel, { c = {
                { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
                { text = tostring(gameMgr:GetUserInfo().gold), fontSize = 20, color = '#ba5c5c' } } })
        elseif self.goodsId == HP_ID then
            -- 体力
            display.reloadRichLabel(numLabel, { c = {
                { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
                { text = tostring(gameMgr:GetUserInfo().hp), fontSize = 20, color = '#ba5c5c' } } })
        elseif self.goodsId == COOK_ID then
            --厨力点
            display.reloadRichLabel(numLabel, { c = {
                { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
                { text = tostring(gameMgr:GetUserInfo().cookingPoint), fontSize = 20, color = '#ba5c5c' } } })
        elseif self.goodsId == POPULARITY_ID then
            -- 知名度
            display.reloadRichLabel(numLabel, { c = {
                { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
                { text = tostring(gameMgr:GetUserInfo().popularity), fontSize = 20, color = '#ba5c5c' } } })
        end
    else

        display.reloadRichLabel(numLabel, { c = {
            { text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
            { text = tostring(checkint(gameMgr:GetAmountByGoodId(self.datas.id))), fontSize = 20, color = '#ba5c5c' } } })
        for k, v in pairs(self.datas.openType) do
            if v == JUMP_MODULE_DATA.SKINSHOP then -- 外观商城
                local tempTab = CommonUtils.GetConfigAllMess('module')[v]
                tempTab.tag   = checkint(v)
                table.insert(TempDatas, tempTab)
            elseif v == '998' then
                local tempTab = {}
                tempTab.name = __('飨灵达到5星时解锁')
                tempTab.hideBtn = true
                tempTab.tag   = checkint(v)
                table.insert(TempDatas, tempTab)
            elseif v == '999' then
                -- 全部关卡
                showAll = true
            elseif CommonUtils.GetJumpModuleAvailable(v) then
                if v == JUMP_MODULE_DATA.NORMAL_MAP or v == JUMP_MODULE_DATA.DIFFICULTY_MAP or v == JUMP_MODULE_DATA.TEAM_MAP then
                    --关卡系列能获得
                    local tempTab = nil
                    for i, vv in ipairs(self.datas.dropQuests) do
                        --可获得改物品的关卡id
                        tempTab        = {}
                        tempTab.tag    = checkint(v)
                        tempTab.taksId = checkint(vv)
                        -- tempTab.exploreAreaFixedPointId = 0
                        local canAdded = 1
                        local tempStr  = ''
                        if CommonUtils.GetConfig('quest', 'quest', vv) then
                            local difficulty = CommonUtils.GetConfig('quest', 'quest', vv).difficulty
                            local cityId     = CommonUtils.GetConfig('quest', 'quest', vv).cityId
                            local tageNum    = 1
                            if CommonUtils.GetConfig('quest', 'city', cityId) then
                                for j, vvv in ipairs(CommonUtils.GetConfig('quest', 'city', cityId).quests[tostring(difficulty)]) do
                                    if vvv == vv then
                                        tageNum = j
                                        break
                                    end
                                end
                            end

                            if checkint(difficulty) == 1 and checkint(cityId) == 1 and checkint(tageNum) == 1 then
                                canAdded = 0
                            else
                                if checkint(difficulty) == 1 then
                                    tempStr = __('普通关卡')
                                elseif checkint(difficulty) == 2 then
                                    tempStr = __('困难关卡')
                                end
                                tempTab.name = string.format('%s %s-%s', tempStr, cityId, tageNum)
                            end
                        end
                        if canAdded == 1 then
                            table.insert(TempDatas, tempTab)
                        end
                    end
                elseif v == JUMP_MODULE_DATA.EXPLORATIN then
                    -- 探索获得
                    -- if gameMgr:GetUserInfo().level >= checkint(CommonUtils.GetConfigAllMess('module')['7'].openLevel) then
                    local newestAreaId = gameMgr:GetUserInfo().newestAreaId
                    for i, exploreAreaFixedPointId in ipairs(self.datas.dropExplores or {}) do
                        local index     = nil
                        local areaDatas = CommonUtils.GetConfig('common', 'areaFixedPoint', tonumber(exploreAreaFixedPointId))
                        if areaDatas then
                            -- 判断区域点是否开放
                            -- if checkint(areaDatas.areaId) <= checkint(newestAreaId) then
                            index = exploreAreaFixedPointId
                            -- end
                        end
                        if index ~= nil then
                            local tempTab                   = {}
                            tempTab.tag                     = checkint(v)
                            tempTab.openLevel               = checkint(CommonUtils.GetConfigAllMess('module')['7'].openLevel)
                            -- tempTab.taksId = 0
                            tempTab.exploreAreaFixedPointId = checkint(index)
                            local areaDatas                 = CommonUtils.GetConfig('common', 'areaFixedPoint', index)
                            tempTab.name                    = string.fmt(__('探索 _name_'), { ['_name_'] = areaDatas.name })
                            table.insert(TempDatas, tempTab)
                        end
                    end
                else
                    cclog("jumpView  =  " ,v )
                    if self.args.isFrom ~= jumpViewData[tostring(v)].jumpView then
                        local tempTab = {}
                        tempTab       = CommonUtils.GetConfigAllMess('module')[v] or {}
                        tempTab.tag   = checkint(v)
                        -- tempTab.taksId = 0
                        -- tempTab.exploreAreaFixedPointId = 0
                        tempTab.name  = tempTab.descr
                        table.insert(TempDatas, tempTab)
                    end
                end
            end
        end
        gainListView:setVisible(false)
        for i, v in ipairs(TempDatas) do
            local cellSize = cc.size(gainListView:getContentSize().width, 102)
            local view     = CLayout:create(cellSize)
            display.commonUIParams(view, { po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5) })
            local bg = display.newImageView(_res('ui/common/common_bg_list_2.png'), cellSize.width * 0.5, cellSize.height * 0.5 - 4)
            view:addChild(bg)
            -- local iconBg = display.newImageView(_res('ui/common/common_frame_goods_1.png'), cellSize.width * 0.13, cellSize.height * 0.5 - 2)
            -- iconBg:setScale(0.7)
            -- view:addChild(iconBg)
            local nameLabel = display.newLabel(50, cellSize.height * 0.5 - 2,
                                               { text = __(v.name), fontSize = 20,  w = 270 ,color = '#5c5c5c', ap = cc.p(0, 0.5) })
            view:addChild(nameLabel)

            local turnButton = display.newButton(cellSize.width * 0.8, cellSize.height * 0.5 - 2,
                                                 { n = _res('ui/common/common_btn_orange.png') ,scale9 = true, scale9 = true , size = cc.size(140,65 )  })
            display.commonLabelParams(turnButton, fontWithColor(14, { text = __('前往')  }))
            local turnButtonLabelSize =  display.getLabelContentSize(turnButton:getLabel())
            if turnButtonLabelSize.width > 130  then
                display.commonLabelParams(turnButton, fontWithColor(14, { text = __('前往') , w = 130 , hAlign  = display.TAC }))
            end
            turnButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
            turnButton:setTag(v.tag)
            if v.taksId then
                turnButton:setUserTag(v.taksId)
            elseif v.exploreAreaFixedPointId then
                turnButton:setUserTag(v.exploreAreaFixedPointId)
            end
            view:addChild(turnButton)
            if checkint(v.taksId) >= 0 and checkint(v.taksId) < 2000 then
                if gameMgr:GetUserInfo().newestQuestId < checkint(v.taksId) then
                    turnButton:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                    turnButton:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
                end
            elseif checkint(v.taksId) >= 2000 and checkint(v.taksId) < 3000 then
                if gameMgr:GetUserInfo().newestHardQuestId < checkint(v.taksId) then
                    turnButton:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                    turnButton:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
                end
            else
                if gameMgr:GetUserInfo().newestInsaneQuestId < checkint(v.taksId) then
                    turnButton:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                    turnButton:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
                end
            end

            -- if true then
            if checkint(gameMgr:GetUserInfo().level) < checkint(v.openLevel) then
                turnButton:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                turnButton:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
            end
            local areaDatas = CommonUtils.GetConfig('common', 'areaFixedPoint', v.exploreAreaFixedPointId)
            if areaDatas then
                if checkint(gameMgr:GetUserInfo().newestAreaId) < checkint(areaDatas.areaId) then
                    turnButton:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                    turnButton:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
                end
            end
            if v.hideBtn then
                turnButton:setVisible(false)
            end
            gainListView:insertNodeAtLast(view)
        end
    end

    if next(TempDatas) ~= nil then
        gainListView:reloadData()
        gainListView:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function( )
            gainListView:setVisible(true)
        end)) )
    else
        -- local index = (math.random(1, 200) % 3 ) + 1
        -- 中间小人

        -- local loadingCardQ = AssetsUtils.GetCartoonNode(3, listBgFrameSize.width * 0.5, listBgFrameSize.height * 0.55)
        -- listBg:addChild(loadingCardQ, 6)
        -- loadingCardQ:setScale(0.65)
        local text = ''
        if showAll == true then
            text = __('所有关卡都可获得')

        else
            text = __('暂无获取途径')

        end
        local hintLabel = display.newLabel(listBgFrameSize.width * 0.5, listBgFrameSize.height * 0.5,
                                           { text = text, ttf = true, font = TTF_GAME_FONT, fontSize = 30, color = '#5c5c5c', w = 480 })
        listBg:addChild(hintLabel, 6)
        hintLabel:setName('hintLabel')
        if CommonUtils.GetGoodTypeById(self.datas.id) == GoodsType.TYPE_MONEY then
            --货币类
            hintLabel:setString(self.datas.obtainDescr or '')
            hintLabel:setPositionX(listBgFrameSize.width * 0.5)
            --hintLabel:setVisible(false)
        end
    end

    shareFacade:RegistObserver(FRIEND_ASSISTANCELIST, mvc.Observer.new(handler(self, self.AddAssistCell), self))
    shareFacade:RegistObserver(FRIEND_REQUEST_ASSISTANCE, mvc.Observer.new(handler(self, self.RequestAssistanceCallback), self))
end

function GainPopup:ButtonActions(sender)
    local tag     = sender:getTag()
    local userTag = sender:getUserTag()
    if tag == checkint(JUMP_MODULE_DATA.UNION_PARTY) then
        uiMgr:ShowInformationTips(__('功能正在加速建造中，敬请期待。'))
        return
    end
    if not  CommonUtils.UnLockModule(tag , true)  then
        return
    end

    if tag == 1 or tag == 2 or tag == 3 then
        if userTag >= 0 and userTag < 2000 then
            if gameMgr:GetUserInfo().newestQuestId < userTag then
                uiMgr:ShowInformationTips(__('该关卡未解锁'))
                return
            end
        elseif userTag >= 2000 and userTag < 3000 then
            if gameMgr:GetUserInfo().newestHardQuestId < userTag then
                uiMgr:ShowInformationTips(__('该关卡未解锁'))
                return
            end
        else
            if gameMgr:GetUserInfo().newestInsaneQuestId < userTag then
                uiMgr:ShowInformationTips(__('该关卡未解锁'))
                return
            end
        end
        local mediator = AppFacade.GetInstance():RetrieveMediator("StoryMissionsMessageNewMediator")
        if mediator then
            mediator.data =  mediator.data or {}
            if checkint(mediator.data.taskType) == 37 then -- 新增道具获取
                AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")
            end
        end
        if self.args.toParams then
            self.args.toParams.stageId = userTag
        else
            self.args.toParams         = {}
            self.args.toParams.stageId = userTag
        end

        ---------- 此处调出战斗准备界面 ----------
        local battleReadyData = BattleReadyConstructorStruct.New(
                2,
                gameMgr:GetUserInfo().localCurrentBattleTeamId,
                gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
                self.args.toParams.stageId,
                CommonUtils.GetQuestBattleByQuestId(self.args.toParams.stageId),
                nil,
                POST.QUEST_AT.cmdName,
                { questId = self.args.toParams.stageId },
                POST.QUEST_AT.sglName,
                POST.QUEST_GRADE.cmdName,
                { questId = self.args.toParams.stageId },
                POST.QUEST_GRADE.sglName,
                'HomeMediator', --self.args.isFrom or
                'HomeMediator'--self.args.isFrom or
        )
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)

        -- if self.args.isFrom then
        -- 	dump(self.args.isFrom)
        -- 	AppFacade.GetInstance():UnRegsitMediator(self.args.isFrom)
        -- end
        self:runAction(cc.RemoveSelf:create())
        return
        ---------- 此处调出战斗准备界面 ----------
    elseif tag == 7 then
        --local mediator =  AppFacade.GetInstance():RetrieveMediator("HomeMediator")
        --if  not  mediator then
        --    AppFacade.GetInstance():BackHomeMediator()
        --end
        -- 探索处理
        local areaDatas = CommonUtils.GetConfig('common', 'areaFixedPoint', tonumber(userTag))
        if checkint(gameMgr:GetUserInfo().newestAreaId) >= checkint(areaDatas.areaId) then
            shareFacade:RetrieveMediator("Router"):Dispatch({ name = self.args.isFrom },
                                                            { name = "ExplorationMediator", params = { id = checkint(userTag) } })
            self:runAction(cc.RemoveSelf:create())
            if AppFacade.GetInstance():RetrieveMediator('StoryMissionsMediator') then
                AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")
            end
            if AppFacade.GetInstance():RetrieveMediator('RecipeDetailMediator') then
                AppFacade.GetInstance():UnRegsitMediator("RecipeDetailMediator")
            end
            if AppFacade.GetInstance():RetrieveMediator('RecipeResearchAndMakingMediator') then
                AppFacade.GetInstance():UnRegsitMediator("RecipeResearchAndMakingMediator")
            end
            if AppFacade.GetInstance():RetrieveMediator('BackPackMediator') then
                AppFacade.GetInstance():UnRegsitMediator("BackPackMediator")
            end

            local node = uiMgr:GetCurrentScene():GetDialogByName("RecipeBackPackView")
            if node and (not tolua.isnull(node)) then
                node:runAction(cc.RemoveSelf:create())
            end
        else
            uiMgr:ShowInformationTips(__('未解锁该区域'))
        end
        return
    elseif tag == checkint(JUMP_MODULE_DATA.GUILD) then
        local isJoinUnion = gameMgr:hasUnion()
        if isJoinUnion then
            AppFacade.GetInstance():RetrieveMediator("Router" ):Dispatch({ name = self.args.isFrom, params = self.args.fromParams or {} }, { name = jumpViewData[tostring(tag)].jumpView})
        else
            AppFacade.GetInstance():RetrieveMediator("Router" ):Dispatch({ name = self.args.isFrom, params = self.args.fromParams or {} }, { name = jumpViewData[tostring(tag)].jumpViewTwo.jumpView})
        end
    elseif tag == checkint(JUMP_MODULE_DATA.UNION_SHOP) then
        if not   gameMgr:hasUnion() then
            uiMgr:ShowInformationTips(__('您没有工会'))
            return
        end
        self:JumpToShopMediator(jumpViewData[tostring(JUMP_MODULE_DATA.UNION_SHOP)])
        return
    elseif tag == checkint(JUMP_MODULE_DATA.SHOP) then
        if GAME_MODULE_OPEN.NEW_STORE then
            self:JumpToShopMediator({jumpData = {storeType = GAME_STORE_TYPE.SEARCH_PROP, searchGoodsId = checkint(self.goodsId)} })
        else
            if self.goodsId == UNION_HIGH_ROLL_ID or checkint(self.goodsId ) == CAPSULE_VOUCHER_ID then
                self:JumpToShopMediator(jumpViewData[tostring(JUMP_MODULE_DATA.GOODS_SHOP)])
            else
                self:JumpToShopMediator(jumpViewData[tostring(JUMP_MODULE_DATA.DIAMOND_SHOP)])
            end
        end
        return
    elseif tag == checkint(JUMP_MODULE_DATA.DIAMOND_SHOP) or
            tag == checkint(JUMP_MODULE_DATA.SKINSHOP) or
            tag == checkint(JUMP_MODULE_DATA.SHOP_TIPS) or
            tag == checkint(JUMP_MODULE_DATA.GIFT_SHOP) or
            tag == checkint(JUMP_MODULE_DATA.GOODS_SHOP) or
            tag == checkint(JUMP_MODULE_DATA.MEDAL_SHOP) then
        self:JumpToShopMediator(jumpViewData[tostring(tag)])
        return
    elseif tag == checkint(JUMP_MODULE_DATA.SMELTING_PET) then
        local chooesePetListView =  uiMgr:GetCurrentScene():GetDialogByName("ChooesePetListView")
        if  chooesePetListView then
            chooesePetListView:runAction(cc.RemoveSelf:create())
            chooesePetListView = nil
        end
        local petUpgradeMediator = AppFacade.GetInstance():RetrieveMediator("PetUpgradeMediator")
        if petUpgradeMediator then
            local viewComponent = petUpgradeMediator:GetViewComponent()
            if viewComponent and (not tolua.isnull(viewComponent)) then
                viewComponent:CloseHandler()
            end
        end
        if self and (not tolua.isnull(self)) then
            self:runAction(cc.RemoveSelf:create())
        end
        local petDevelopMediator = AppFacade.GetInstance():RetrieveMediator("PetDevelopMediator")
        if not  petDevelopMediator then
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PetDevelopMediator'})
            petDevelopMediator = AppFacade.GetInstance():RetrieveMediator("PetDevelopMediator")
        end
        if petDevelopMediator  then
            petDevelopMediator:RefreshMuduleByModuleType(1,false )
            AppFacade.GetInstance():DispatchObservers( SGL.GO_TO_SMELTING_EVENT ,{})
        end
        return
    elseif   tag == checkint(JUMP_MODULE_DATA.TOWER) then
        local chooesePetListView =  uiMgr:GetCurrentScene():GetDialogByName("ChooesePetListView")
        if  chooesePetListView then
            chooesePetListView:runAction(cc.RemoveSelf:create())
            chooesePetListView = nil
        end
        local petUpgradeMediator = AppFacade.GetInstance():RetrieveMediator("PetUpgradeMediator")
        if petUpgradeMediator then
            local viewComponent = petUpgradeMediator:GetViewComponent()
            if viewComponent and (not tolua.isnull(viewComponent)) then
                viewComponent:CloseHandler()
            end
        end
    elseif   tag == checkint(JUMP_MODULE_DATA.ARTIFACT_TAG) then
        ---@type ArtifactManager
        local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
        local questId =   artifactMgr:GetQuestIdByArtifactFragmentId(self.goodsId)
        if checkint(questId) > 0 then
            artifactMgr:GoToBattleReadyView(
                    questId ,    'HomeMediator','HomeMediator' , nil
            )
        end
        return
    elseif  tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP) or
            tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP_ONE)
            or   tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP_THREE)
            or tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP_TWO) then
        local mediator = app:RetrieveMediator("BackPackMediator")
        if mediator then
            app:UnRegsitMediator("BackPackMediator")
        end
        local goShopIndex = nil
        if jumpViewData[tostring(tag)].jumpData then
            goShopIndex = jumpViewData[tostring(tag)].jumpData.goShopIndex
        end
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = jumpViewData[tostring(tag)].jumpView , params = {goodsId = self.goodsId , goShopIndex = goShopIndex } })
        self:runAction(cc.RemoveSelf:create())
        return
    elseif  tag == checkint(JUMP_MODULE_DATA.WATER_BAR_MARKET) then
        local materialConf = CONF.BAR.MATERIAL:GetAll()
        local materialOneConf = materialConf[tostring(self.goodsId)]
        self:JumpToMediator(jumpViewData[tostring(tag)].jumpView , {initType = checkint(materialOneConf.materialType) ,goodsId = self.goodsId  })
        self:runAction(cc.RemoveSelf:create())
        return
    end
    if self.args.isFrom == jumpViewData[tostring(tag)].jumpView then
        AppFacade.GetInstance():DispatchObservers(JumpLayer_DoAction, jumpViewData[tostring(tag)])
    else
        if jumpViewData[tostring(tag)].jumpView then
            if jumpViewData[tostring(tag)].jumpView == 'RecipeDetailMediator' then
                -- 首先判断当前料理师傅为料理残渣
                if FOOD_RESIDUE_ID == checkint(self.datas.id ) then
                    self:JumpToMediator(jumpViewData[tostring(tag)].jumpViewTwo.jumpView, jumpViewData[tostring(tag)].jumpViewTwo.needData)
                    return
                end
                local goodsId    = self.datas.recipeId
                local recipeData = CommonUtils.GetConfigAllMess('recipe', 'cooking')[tostring(goodsId)]
                if not recipeData then
                    return
                end
                local cookingStyleId = recipeData.cookingStyleId
                local styleData      = CommonUtils.GetConfigAllMess('style', 'cooking')
                local ownRecipeData  = gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyleId)]
                local data           = {}
                if ownRecipeData then
                    local isHave = false
                    for k, v in pairs(ownRecipeData) do
                        if checkint(v.recipeId) == checkint(goodsId) then
                            isHave = true
                            data   = v
                            break
                        end
                    end
                    if checkint(cookingStyleId) == 5 and ( not isHave) then
                        -- 判断该菜系是否是
                        uiMgr:ShowInformationTips(__('需要先从任务中获得该菜谱哦~'))
                        return
                    end
                    if isHave then
                        data.type                            = 1        
                        jumpViewData[tostring(tag)].needData = data
                        self:JumpToMediator( jumpViewData[tostring(tag)].jumpView, jumpViewData[tostring(tag)].needData)
                        -- AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = self.args.isFrom,params = self.args.fromParams or {}},{name = jumpViewData[tostring(tag)].jumpView,params = data},{isBack = true})
                    else
                        if CommonUtils.UnLockModule(JUMP_MODULE_DATA.RECIPE_STUDY, false) then
                            self:JumpToMediator(jumpViewData[tostring(tag)].jumpViewTwo.jumpView, jumpViewData[tostring(tag)].jumpViewTwo.needData)
                        else
                            uiMgr:ShowInformationTips(__('开发功能未解锁'))
                        end
                    end
                else
                    uiMgr:ShowInformationTips(string.format(__('当前菜品属于%s菜系哦'), styleData[tostring(cookingStyleId)].name) )
                end

            else
                if jumpViewData[tostring(tag)].isPopup then
                    local mediator    = require('Game.mediator.' .. jumpViewData[tostring(tag)].jumpView)
                    local oneMediator = mediator.new()
                    AppFacade.GetInstance():RegistMediator(oneMediator)
                else
                    if jumpViewData[tostring(tag)].jumpView == '1' then
                        local descr = jumpViewData[tostring(tag)].jumpDes or __('返回主界面')
                        if tag == checkint(JUMP_MODULE_DATA.ACTIVITY) then
                            local moduleData = CommonUtils.GetConfigAllMess('module')[tostring(tag)]
                            if moduleData and moduleData.descr then
                                descr = moduleData.descr
                            end
                        end
                        uiMgr:ShowInformationTips(descr)
                    else
                        if checkint(tag) == checkint(JUMP_MODULE_DATA.AIR_TRANSPORTATION) then
                            local key = string.format('%s_ModulePanelIsOpen', tostring(gameMgr:GetUserInfo().playerId))
                            cc.UserDefault:getInstance():setBoolForKey(key, false)
                            cc.UserDefault:getInstance():flush()
                        end
                        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({ name = self.args.isFrom, params = self.args.fromParams or {} }, { name = jumpViewData[tostring(tag)].jumpView, params = jumpViewData[tostring(tag)].jumpData or {} }, { isBack = self.args.isBack or false })
                    end
                end
            end

        end
    end
    self:runAction(cc.RemoveSelf:create())

end


function GainPopup:JumpToShopMediator(data)
    local jumpData = checktable(data)
    if GAME_MODULE_OPEN.NEW_STORE then
        app.uiMgr:showGameStores(jumpData.jumpData)
    else
        app:RetrieveMediator("Router"):Dispatch({name = self.args.isFrom, params = self.args.fromParams or {}}, {name = tostring(jumpData.jumpView), params  = jumpData.jumpData or {}})
    end

    if app:RetrieveMediator('BackPackMediator') then
        app:UnRegsitMediator("BackPackMediator")
    end
    if self and (not tolua.isnull(self)) then
        self:runAction(cc.RemoveSelf:create())
    end
end
-- 跳转到对应的mediator 里面
function GainPopup:JumpToMediator(name, data)
    local mediator    = require('Game.mediator.' .. name)
    local oneMediator = mediator.new(data)
    AppFacade.GetInstance():RegistMediator(oneMediator)
end
-- 显示求助页面
function GainPopup:AddAssistCell( stage, signal )
    local data      = checktable(signal:GetBody()).data
    self.friendList = data.friendList
    if checkint(data.assistanceCd) ~= 0 then
        self.cd = data.assistanceCd + 5
    end
    local gainListView = self.gainListView
    local cellSize     = cc.size(gainListView:getContentSize().width, 102)
    self.cellSize      = cellSize
    local view         = CLayout:create(cellSize)
    display.commonUIParams(view, { po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5) })
    local bg = display.newImageView(_res('ui/common/common_bg_list_2.png'), cellSize.width * 0.5, cellSize.height * 0.5 - 4
    )
    bg:setTag(2003)
    view:addChild(bg)
    self.cell       = view
    local nameLabel = display.newLabel(50, cellSize.height * 0.5 - 2,
                                       { text = __('求助好友'), fontSize = 20, color = '#5c5c5c', w = 280,  ap = cc.p(0, 0.5) })
    view:addChild(nameLabel)
    if data.assistanceCd == 0 then
        local turnButton = display.newButton(cellSize.width * 0.8, cellSize.height * 0.5 - 2,
                                             { n = _res('ui/common/common_btn_orange.png'),scale9 = true , size = cc.size(140,65 ) })
        display.commonLabelParams(turnButton, fontWithColor(14, { text = __('求助') }))
        turnButton:setOnClickScriptHandler(handler(self, self.AssistAction))
        view:addChild(turnButton)
    else
        local label = display.newLabel(410, 60,
                                       { text = __('冷却'), fontSize = 20, color = '#604339' }
        )
        label:setTag(2002)
        view:addChild(label)
        local timeLabel = display.newLabel(410, 30, fontWithColor('10', { text = self:TimeChange(self.cd) }))
        timeLabel:setTag(2001)
        view:addChild(timeLabel)
        bg:setTexture(_res('ui/home/friend/common_bg_list_unlock.png'))
        self.scheduler = scheduler.scheduleGlobal(handler(self, self.onTimerScheduler), 1)
        self.enterTimeStamp = os.time()
    end
    local userInfo       = gameMgr:GetUserInfo()
    local newestQuestId  = checkint(userInfo.newestQuestId)
    local currentQuestId = checkint(userInfo.currentQuestId)

    if newestQuestId == 1 and currentQuestId == 0 then
        gainListView:insertNodeAtLast(view)
        gainListView:setDragable(false)
    else
        gainListView:insertNodeAtFront(view)
    end
    gainListView:reloadData()
    gainListView:setVisible(true)
    local hintLabel = self.listBg:getChildByName('hintLabel')
    if hintLabel then
        hintLabel:runAction(cc.RemoveSelf:create())
    end
end
-- 求助回调
function GainPopup:RequestAssistanceCallback( stage, signal )
    self:runAction(cc.RemoveSelf:create())
end

function GainPopup:AssistAction( sender )
    if self:getChildByTag(1000) then
        return
    end

    local viewSize   = cc.size(462, 598)
    local assistView = CLayout:create(viewSize)
    assistView:setPosition(cc.p(display.cx, display.cy - 20))
    assistView:setTag(1000)
    self:addChild(assistView)
    local cover = CColorView:create(cc.c4b(0, 0, 0, 0))
    cover:setTouchEnabled(true)
    cover:setContentSize(viewSize)
    cover:setAnchorPoint(cc.p(0, 0))
    assistView:addChild(cover, -1)
    local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0, { scale9 = true, size = viewSize, ap = cc.p(0, 0) })
    assistView:addChild(bg)
    local title = display.newLabel(viewSize.width / 2, 566,
                                   fontWithColor(8, { text = __('选择你的好友') }    ))
    assistView:addChild(title)
    local chooseNum = display.newLabel(viewSize.width / 2, 540, fontWithColor(6, { text = string.fmt(__('最多选择(_num1_/_num2_)'), { _num1_ = 0, _num2_ = 20 }) }))
    self.chooseNum  = chooseNum
    assistView:addChild(chooseNum)
    -- 好友列表
    local listSize     = cc.size(448, 434)
    local listCellSize = cc.size(147, 122)
    local listBg       = display.newImageView(_res('ui/common/common_bg_goods.png'), viewSize.width / 2, viewSize.height / 2,
                                              { scale9 = true, size = listSize }
    )
    assistView:addChild(listBg)
    local gridView = CGridView:create(cc.size(listSize.width - 2, listSize.height - 1))
    gridView:setSizeOfCell(listCellSize)
    gridView:setColumns(3)
    gridView:setAutoRelocate(true)
    assistView:addChild(gridView)
    gridView:setPosition(cc.p(viewSize.width / 2 + 2, viewSize.height / 2))
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))

    gridView:setCountOfCell(table.nums(self.friendList))
    gridView:reloadData()

    local sendBtn = display.newButton(viewSize.width / 2, 45,
                                      { n = _res('ui/common/common_btn_orange.png'), scale9 = true, size = cc.size(128, 56) }
    )
    assistView:addChild(sendBtn, 10)
    display.commonLabelParams(sendBtn, fontWithColor('14', { text = __('发送') }))
    sendBtn:setOnClickScriptHandler(handler(self, self.SendBtnCallBack))
    -- 动作
    self.bgLayer:runAction(
            cc.MoveTo:create(0.2, cc.p(display.cx - 300, display.cy))
    )
    assistView:setScale(0.2)
    assistView:runAction(
            cc.Spawn:create(
                    cc.MoveTo:create(0.2, cc.p(display.cx + 200, display.cy - 20)),
                    cc.ScaleTo:create(0.2, 1)
            )
    )


end
function GainPopup:OnDataSourceAction( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(147, 122)
    if self.friendList and index <= table.nums(self.friendList) then
        if pCell == nil then
            pCell = AssistCell.new(cSize)
            pCell.toggleView:setOnClickScriptHandler(handler(self, self.CellButtonAction))
        end
        xTry(function()
            local isSelect = false
            for k, v in ipairs(self.selectTable) do
                if v == self.friendList[index].friendId then
                    isSelect = true
                    break
                end
            end
            if isSelect then
                pCell.toggleView:setChecked(true)
                pCell.nameLabel:setColor(cc.c3b(255, 255, 255))

            else
                pCell.toggleView:setChecked(false)
                pCell.nameLabel:setColor(cc.c3b(92, 92, 92))
            end

            pCell.toggleView:setTag(index)
            pCell.nameLabel:setString(self.friendList[index].name)
            pCell.avatarIcon:RefreshSelf({ level = self.friendList[index].level, avatar = self.friendList[index].avatar, avatarFrame = self.friendList[index].avatarFrame })
        end, __G__TRACKBACK__)
        return pCell
    end

end
function GainPopup:CellButtonAction( sender )
    local tag         = sender:getTag()
    local addFriendId = true
    local nameLabel   = sender:getParent():getChildByTag(1500)
    for k, v in ipairs(self.selectTable) do
        if v == self.friendList[tag].friendId then
            table.remove(self.selectTable, k)
            nameLabel:setColor(cc.c3b(92, 92, 92))
            addFriendId = false
            break
        end
    end
    if addFriendId then
        if table.nums(self.selectTable) == 20 then
            -- 判断是否超过上限
            sender:setChecked(false)
            return
        end
        table.insert(self.selectTable, self.friendList[tag].friendId)
        nameLabel:setColor(cc.c3b(255, 255, 255))
    end
    self.chooseNum:setString(string.fmt(__('最多选择(_num1_/_num2_)'), { ['_num1_'] = table.nums(self.selectTable), ['_num2_'] = 20 }))
end
function GainPopup:SendBtnCallBack( sender )
    if table.nums(self.selectTable) == 0 then
        uiMgr:ShowInformationTips(__('请选择好友'))
    else
        local str = nil
        for i, v in ipairs(self.selectTable) do
            if i == 1 then
                str = v
            else
                str = string.format('%s,%s', str, v)
            end
        end
        local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
        mediator:SendSignal(COMMANDS.COMMAND_Friend_RequestAssistance, { goodsId = self.datas.id, friends = str })
    end

end
function GainPopup:onTimerScheduler( )
	local curTime = os.time()
	local deltaTime = math.abs(curTime - self.enterTimeStamp)
    self.enterTimeStamp = curTime
    if self.cd then
        self.cd = self.cd - deltaTime
        if self.cd <= 0 then
            self.cell:getChildByTag(2001):removeFromParent()
            self.cell:getChildByTag(2002):removeFromParent()
            self.cell:getChildByTag(2003):setTexture(_res('ui/common/common_bg_list_2.png'))
            local turnButton = display.newButton(self.cellSize.width * 0.8, self.cellSize.height * 0.5 - 2,
                                                 { n = _res('ui/common/common_btn_orange.png') })
            display.commonLabelParams(turnButton, fontWithColor(14, { text = __('求助') }))
            turnButton:setOnClickScriptHandler(handler(self, self.AssistAction))
            self.cell:addChild(turnButton)
            scheduler.unscheduleGlobal(self.scheduler)
        else
            if self.cell:getChildByTag(2001) then
                self.cell:getChildByTag(2001):setString(self:TimeChange(self.cd))
            end
        end
    end
end
function GainPopup:TimeChange(completeTime)
    local hour   = math.floor(completeTime / 3600)
    local minute = math.floor((completeTime - hour * 3600) / 60)
    local sec    = (completeTime - hour * 3600 - minute * 60)
    return string.format("%.2d:%.2d:%.2d", hour, minute, sec)
end
function GainPopup:onCleanup()
    --清理逻辑

    if self.scheduler then
        scheduler.unscheduleGlobal(self.scheduler)
    end
    shareFacade:UnRegistObserver(FRIEND_ASSISTANCELIST, self)
    shareFacade:UnRegistObserver(FRIEND_REQUEST_ASSISTANCE, self)

end
return GainPopup
