--[[
 * author : kaishiqi
 * descpt : 工会战 - 地图建筑节点
]]
local UnionConfigParser     = require('Game.Datas.Parser.UnionConfigParser')
local UnionWarsModelFactory = require('Game.models.UnionWarsModelFactory')
local UnionWarsModel        = UnionWarsModelFactory.UnionWarsModel
local UnionWarsMapSiteNode  = class('UnionWarsMapSiteNode', function()
    return display.newLayer(0, 0, {name = 'Game.views.unionWars.UnionWarsMapSiteNode'})
end)

local RES_DICT = {
    HP_ICON_N        = _res('ui/union/wars/map/gvg_hp_heart_1.png'),
    HP_ICON_D        = _res('ui/union/wars/map/gvg_hp_heart_2.png'),
    SITE_IMG_DESTORY = _res('ui/union/wars/map/gvg_maps_fort_hollow_damage.png'),
    SITE_IMG_ENEMY   = _res('ui/union/wars/map/gvg_maps_fort_hollow_1.png'),
    SITE_IMG_UNION   = _res('ui/union/wars/map/gvg_maps_fort_hollow_2.png'),
    FRAME_POWER      = _res('ui/union/wars/map/gvg_zhanli_bg.png'),
    FRAME_BOSS_NAME  = _res('ui/union/wars/map/gvg_maps_name_boss_bg.png'),
    FRAME_EMPTY_NAME = _res('ui/union/wars/map/gvg_maps_name_hollow_bg.png'),
    BOSS_SHADOW      = _res('ui/battle/battle_role_shadow.png'),
    DEBUFF_SPINE     = _spn('ui/union/wars/map/gvg_debuff'),  -- idle1, idle2, idle3
    SITE_FILL_SPINE  = _spn('ui/union/wars/map/gvg_matching_jzd'),  -- idle
    DEFENDING_SPINE  = _spn('arts/effects/map_fighting_fork'),  -- idle
}

local CreateSiteNode = nil
local CreateBossNode = nil

local DEBUFF_SPINE_PLAY_DEFINE = {
    'idle1',
    'idle2',
    'idle3',
}

UnionWarsMapSiteNode.SIZE = cc.size(150, 180)

UnionWarsMapSiteNode.TYPES = {
    SITE = 'site',
    BOSS = 'boss',
}


function UnionWarsMapSiteNode:ctor(args)
    local initArgs = checktable(args)
    self.type_ = initArgs.type or UnionWarsMapSiteNode.TYPES.SITE
    
    -- create view
    if self:getType() == UnionWarsMapSiteNode.TYPES.SITE then
        self.viewData_ = CreateSiteNode(UnionWarsMapSiteNode.SIZE)
    else
        self.viewData_ = CreateBossNode(UnionWarsMapSiteNode.SIZE)
    end
    self:addChild(self:getViewData().view)

    -- init view
    -- self:setAnchorPoint(display.CENTER)
    self:setAnchorPoint(display.CENTER_BOTTOM)
    self:setContentSize(self:getViewData().view:getContentSize())

    -- init listen
    display.commonUIParams(self:getViewData().hotspot, {cb = function(sender)
        if self:getOnClickCB() then 
            self:getOnClickCB()(self)
        end
    end})
end


CreateSiteNode = function(size)
    local view = display.newLayer(0, 0, {size = size})
    
    -- site image
    local siteImgPoint   = cc.p(size.width/2, size.height/2)
    local siteImgUnion   = display.newImageView(RES_DICT.SITE_IMG_UNION, siteImgPoint.x, siteImgPoint.y)
    local siteImgEnemy   = display.newImageView(RES_DICT.SITE_IMG_ENEMY, siteImgPoint.x, siteImgPoint.y)
    local siteImgDestory = display.newImageView(RES_DICT.SITE_IMG_DESTORY, siteImgPoint.x, siteImgPoint.y)
    view:addChild(siteImgUnion)
    view:addChild(siteImgEnemy)
    view:addChild(siteImgDestory)

    -- add spine cache
    local siteFillSpinePath = RES_DICT.SITE_FILL_SPINE.path
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(siteFillSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(siteFillSpinePath, siteFillSpinePath, 1)
    end

    -- create effect spine
    local siteFillSpine = SpineCache(SpineCacheName.UNION):createWithName(siteFillSpinePath)
    siteFillSpine:setPosition(siteImgPoint)
    view:addChild(siteFillSpine)
    siteFillSpine:setAnimation(0, 'idle', true)

    -- empty bar
    local emptyBar = display.newButton(siteImgPoint.x, siteImgPoint.y - 45, {n = RES_DICT.FRAME_EMPTY_NAME, enable = false})
    display.commonLabelParams(emptyBar, fontWithColor(16, {text = __('空')}))
    view:addChild(emptyBar)

    -- power bar
    local powerBar = display.newButton(siteImgPoint.x + 20, siteImgPoint.y - 45, {n = RES_DICT.FRAME_POWER, enable = false})
    display.commonLabelParams(powerBar, fontWithColor(2, {color = '#FDD445'}))
    view:addChild(powerBar)

    -- failed label
    local failedLabel = display.newLabel(siteImgPoint.x, siteImgPoint.y + 10, fontWithColor(14, {color = '#FF2222', outline = '#000000', text = __('战败')}))
    view:addChild(failedLabel)
    
    -------------------------------------------------
    -- payerInfo layer
    local playerInfoLayer = display.newLayer(siteImgPoint.x, siteImgPoint.y - 40)
    view:addChild(playerInfoLayer)

    -- player headNode
    local playerHeadNode = require('common.PlayerHeadNode').new()
    playerHeadNode:setAnchorPoint(display.CENTER)
    playerHeadNode:setScale(0.38)
    playerInfoLayer:addChild(playerHeadNode)

    -- player heart
    local playerHeartHList   = {}
    local playerHeartDList   = {}
    local PLAYER_HEART_WIDTH = 26
    local PLAYER_HEART_OFF_X = (UnionWarsModel.SITE_HP_MAX/2 - 0.5) * PLAYER_HEART_WIDTH
    for i = 1, UnionWarsModel.SITE_HP_MAX do
        local heartImgP = cc.p(-PLAYER_HEART_OFF_X + (i-1) * PLAYER_HEART_WIDTH, -30)
        local heartImgD = display.newImageView(RES_DICT.HP_ICON_D, heartImgP.x, heartImgP.y)
        local heartImgN = display.newImageView(RES_DICT.HP_ICON_N, heartImgP.x, heartImgP.y)
        playerInfoLayer:addChild(heartImgD)
        playerInfoLayer:addChild(heartImgN)
        table.insert(playerHeartHList, heartImgN)
        table.insert(playerHeartDList, heartImgD)
    end
    
    -- add spine cache
    local debuffSpinePath = RES_DICT.DEBUFF_SPINE.path
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(debuffSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(debuffSpinePath, debuffSpinePath, 1)
    end

    -- create effect spine
    local playerDebuffSpine = SpineCache(SpineCacheName.UNION):createWithName(debuffSpinePath)
    playerDebuffSpine:setPosition(cc.p(0, 30))
    playerInfoLayer:addChild(playerDebuffSpine)

    -------------------------------------------------
    -- add spine cache
    local defendingSpinePath = RES_DICT.DEFENDING_SPINE.path
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(defendingSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(defendingSpinePath, defendingSpinePath, 1)
    end

    -- create effect spine
    local defendingSpine = SpineCache(SpineCacheName.UNION):createWithName(defendingSpinePath)
    defendingSpine:setPosition(cc.p(siteImgPoint.x, siteImgPoint.y + 60))
    defendingSpine:setAnimation(0, 'idle', true)
    view:addChild(defendingSpine)

    -- click hotsport
    local hotspot = display.newLayer(0, 0, {color = cc.r4b(0), size = size, enable = true})
    view:addChild(hotspot)

    return {
        view               = view,
        hotspot            = hotspot,
        siteImgUnion       = siteImgUnion,
        siteImgEnemy       = siteImgEnemy,
        siteFillSpine      = siteFillSpine,
        siteImgDestory     = siteImgDestory,
        emptyBar           = emptyBar,
        powerBar           = powerBar,
        failedLabel        = failedLabel,
        playerInfoLayer    = playerInfoLayer,
        playerInfoUnionPos = cc.p(playerInfoLayer:getPosition()),
        playerInfoEnemyPos = cc.p(playerInfoLayer:getPositionX() - 60, playerInfoLayer:getPositionY()),
        playerHeadNode     = playerHeadNode,
        playerHeartHList   = playerHeartHList,
        playerHeartDList   = playerHeartDList,
        playerDebuffSpine  = playerDebuffSpine,
        defendingSpine     = defendingSpine,
    }
end


CreateBossNode = function(size)
    local view = display.newLayer(0, 0, {size = size})

    local shadowImg = display.newImageView(RES_DICT.BOSS_SHADOW, size.width/2, 35, {scale = 0.6})
    view:addChild(shadowImg)
    
    local spineLayer = display.newLayer(shadowImg:getPositionX(), shadowImg:getPositionY())
    view:addChild(spineLayer)

    local nameBar = display.newButton(size.width/2, 0, {n = RES_DICT.FRAME_BOSS_NAME, enable = false, ap = display.CENTER_BOTTOM, scale9 = true})
    display.commonLabelParams(nameBar, fontWithColor(18))
    view:addChild(nameBar)

    local hotspot = display.newLayer(0, 0, {color = cc.r4b(0), size = size, enable = true})
    view:addChild(hotspot)

    return {
        view       = view,
        hotspot    = hotspot,
        nameBar    = nameBar,
        shadowImg  = shadowImg,
        spineLayer = spineLayer,
    }
end


-------------------------------------------------
-- get / set

function UnionWarsMapSiteNode:getType()
    return self.type_
end


function UnionWarsMapSiteNode:getViewData()
    return self.viewData_
end


---@param callback function(self) end
function UnionWarsMapSiteNode:setOnClickCB(callback)
    self.clickCallback_ = callback
end
function UnionWarsMapSiteNode:getOnClickCB()
    return self.clickCallback_
end


-------------------------------------------------
-- public

function UnionWarsMapSiteNode:updateSiteStatus(siteId, siteModel, isWatchEnemy)
    if self:getType() ~= UnionWarsMapSiteNode.TYPES.SITE then return end
    
    local siteImgDestory     = self:getViewData().siteImgDestory
    local siteImgUnion       = self:getViewData().siteImgUnion
    local siteImgEnemy       = self:getViewData().siteImgEnemy
    local siteFillSpine      = self:getViewData().siteFillSpine
    local emptyBar           = self:getViewData().emptyBar
    local powerBar           = self:getViewData().powerBar
    local failedLabel        = self:getViewData().failedLabel
    local playerInfoUnionPos = self:getViewData().playerInfoUnionPos
    local playerInfoEnemyPos = self:getViewData().playerInfoEnemyPos
    local playerInfoLayer    = self:getViewData().playerInfoLayer
    local playerHeadNode     = self:getViewData().playerHeadNode
    local playerHeartHList   = self:getViewData().playerHeartHList
    local playerHeartDList   = self:getViewData().playerHeartDList
    local playerDebuffSpine  = self:getViewData().playerDebuffSpine
    local defendingSpine     = self:getViewData().defendingSpine

    if siteModel then
        emptyBar:setVisible(false)
        playerInfoLayer:setVisible(true)

        -- update plaeyr head
        playerHeadNode:RefreshUI({
            avatar      = checkint(siteModel:getPlayerAvatar()),
            avatarFrame = checkint(siteModel:getPlayerAvatarFrame()),
        })

        -- update player hp
        local playerHP = checkint(siteModel:getPlayerHP())
        for index, heartImgD in ipairs(playerHeartHList) do
            heartImgD:setVisible(index <= playerHP)
        end

        -- check is dead
        local isDead = siteModel:isDead() == true
        siteFillSpine:setVisible(not isDead)
        siteImgDestory:setVisible(isDead)
        failedLabel:setVisible(isDead)

        if isDead then
            siteImgUnion:setVisible(false)
            siteImgEnemy:setVisible(false)
        else
            siteImgUnion:setVisible(isWatchEnemy ~= true)
            siteImgEnemy:setVisible(isWatchEnemy == true)
        end

        -- update defending spine
        defendingSpine:setVisible(siteModel:isDefending())

        -- update debuff spine
        local defendDebuffCount   = checkint(siteModel:getDefendDebuff())
        local debuffSpinePlayName = DEBUFF_SPINE_PLAY_DEFINE[defendDebuffCount]
        playerDebuffSpine:setVisible(defendDebuffCount > 0)
        if debuffSpinePlayName then
            playerDebuffSpine:setAnimation(0, tostring(debuffSpinePlayName), true)
        end

        -- check isWatchEnemy
        if isWatchEnemy then
            local battlePoint = 0
            for index, cardData in ipairs(siteModel:getPlayerCards() or {}) do
                battlePoint = battlePoint + app.cardMgr.GetCardStaticBattlePointByCardData(cardData)
            end
            display.commonLabelParams(powerBar, {text = tostring(battlePoint)})
        end
        powerBar:setVisible(isWatchEnemy)
        playerInfoLayer:setPosition(isWatchEnemy and playerInfoEnemyPos or playerInfoUnionPos)

    else
        -- empty site
        siteImgUnion:setVisible(isWatchEnemy ~= true)
        siteImgEnemy:setVisible(isWatchEnemy == true)
        siteImgDestory:setVisible(false)
        siteFillSpine:setVisible(false)
        emptyBar:setVisible(true)
        powerBar:setVisible(false)
        failedLabel:setVisible(false)
        playerInfoLayer:setVisible(false)
        defendingSpine:setVisible(false)
    end 
end


function UnionWarsMapSiteNode:updateBossStatus(pageId, questId)
    if self:getType() ~= UnionWarsMapSiteNode.TYPES.BOSS then return end

    local bossNameBar    = self:getViewData().nameBar
    local spineLayer     = self:getViewData().spineLayer
    local bossShadowImg  = self:getViewData().shadowImg
    local bossSiteDefine = UnionWarsModel.BOSS_SITE_DEFINES[checkint(pageId)]
    spineLayer:removeAllChildren()

    if bossSiteDefine and checkint(questId) > 0 then

        -- update spine
        local bossQuestConf  = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.WARS_BOSS_QUEST, questId) or {}
        local unionPetConf   = app.cardMgr.GetBeastBabyFormConfig(bossSiteDefine.petId, checkint(bossQuestConf.level), 1) or {}
        local bossSpineNode  = AssetsUtils.GetCardSpineNode({skinId = checkint(unionPetConf.skinId), scale = 0.25 * checknumber(unionPetConf.scale)})
        bossSpineNode:setAnimation(0, 'idle', true)
        bossSpineNode:setScaleX(-1)
        spineLayer:addChild(bossSpineNode)

        -- update name
        display.commonLabelParams(bossNameBar, {text = tostring(bossSiteDefine.name), paddingW = 30})
        bossNameBar:setVisible(true)
        bossShadowImg:setVisible(true)

    else
        -- clean all
        bossNameBar:setVisible(false)
        bossShadowImg:setVisible(false)
    end
end


return UnionWarsMapSiteNode
