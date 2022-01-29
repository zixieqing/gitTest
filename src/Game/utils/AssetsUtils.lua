--[[
 * author : kaishiqi
 * descpt : 资源工具类
]]
AssetsUtils = {}


--================================================================================================
-- arts
--================================================================================================

-------------------------------------------------
-- Q版立绘
-- arts/cartoon/card_q_xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCartoonPath(cartoonId)
    return _res(string.format('arts/cartoon/card_q_%s.png', tostring(cartoonId)))
end
function AssetsUtils.GetCartoonNode(cartoonId, x, y, params)
    return app.loadImage.new(AssetsUtils.GetCartoonPath(cartoonId), x, y, params)
end


--================================================================================================
-- restaurant
--================================================================================================

-------------------------------------------------
-- 餐厅装扮大图
-- avatar/xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetRestaurantBigAvatarPath(avatarId)
    return _res(string.format('avatar/%s.png', tostring(avatarId)))
end
function AssetsUtils.GetRestaurantBigAvatarNode(avatarId, x, y, params)
    return app.loadImage.new(AssetsUtils.GetRestaurantBigAvatarPath(avatarId), x, y, params)
end


-------------------------------------------------
-- 餐厅装扮小图
-- avatar/small/xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetRestaurantSmallAvatarPath(avatarId)
    return _res(string.format('avatar/small/%s.png', tostring(avatarId)))
end
function AssetsUtils.GetRestaurantSmallAvatarNode(avatarId, x, y, params)
    return app.loadImage.new(AssetsUtils.GetRestaurantSmallAvatarPath(avatarId), x, y, params)
end


-------------------------------------------------
-- 餐厅装扮 spine
-- avatar/spine/
-------------------------------------------------

function AssetsUtils.GetRestaurantAvatarSpinePath(avatarId)
	return string.format('avatar/spine/%s', tostring(avatarId))
end


-------------------------------------------------
-- 餐厅装扮 particle
-- avatar/particle/
-------------------------------------------------

function AssetsUtils.GetRestaurantAvatarParticlePath(particleId)
	return string.format('avatar/particle/%s.plist', tostring(particleId))
end


--================================================================================================
-- catHouse
--================================================================================================

-------------------------------------------------
-- 猫屋 家具大图
-- arts/catHouse/avatar/big/xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCatHouseBigAvatarPath(avatarId)
    return _res(string.format('arts/catHouse/avatar/big/%s.png', tostring(avatarId)))
end
function AssetsUtils.GetCatHouseBigAvatarNode(avatarId, x, y, params)
    return app.loadImage.new(AssetsUtils.GetCatHouseBigAvatarPath(avatarId), x, y, params)
end


-------------------------------------------------
-- 猫屋 家具小图
-- arts/catHouse/avatar/small/xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCatHouseSmallAvatarPath(avatarId)
    return _res(string.format('arts/catHouse/avatar/small/%s.png', tostring(avatarId)))
end
function AssetsUtils.GetCatHouseSmallAvatarNode(avatarId, x, y, params)
    return app.loadImage.new(AssetsUtils.GetCatHouseSmallAvatarPath(avatarId), x, y, params)
end


--================================================================================================
-- cards
--================================================================================================

-------------------------------------------------
-- 卡牌立绘
-- cards/card/card_draw_xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCardDrawPath(cardDrawName)
    local path = string.format('cards/card/card_draw_%s.png', tostring(cardDrawName))
	if not app.gameResMgr:isExistent(path) then
		path = string.format('cards/card/card_draw_%s.png', CardUtils.DEFAULT_DRAW_ID)
	end
	return _res(path)
end
function AssetsUtils.GetCardDrawNode(skinId, x, y)
	if skinId then
		return app.loadImage.new(AssetsUtils.GetCardDrawPath(skinId), x, y, {forceSize = cc.size(1002, 1334)})
	else
		return app.loadImage.new(nil, x, y, {forceSize = cc.size(1002, 1334)})
	end

end


-------------------------------------------------
-- 卡牌spine立绘
-- cards/spine/draw/xxxxxx
-------------------------------------------------

function AssetsUtils.GetCardSpineDrawPath(cardDrawName)
    local spnData = _spn(string.format('cards/spine/draw/%s', tostring(cardDrawName)))
    return app.gameResMgr:isExistent(spnData.atlas) and spnData or nil
end


-------------------------------------------------
-- 卡牌背景
-- cards/card/card_draw_bg_xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCardDrawBgPath(cardDrawBgName)
    return _res(string.format('cards/card/card_draw_bg_%s.jpg', tostring(cardDrawBgName)))
end
function AssetsUtils.GetCardDrawBgNode(skinId, x, y, params)
    return app.loadImage.new(CardUtils.GetCardDrawBgPathBySkinId(skinId), x, y, params)
end


-------------------------------------------------
-- 卡牌前景
-- cards/card/card_draw_fg_xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCardDrawFgPath(cardDrawFgName)
    return _res(string.format('cards/card/card_draw_fg_%s.jpg', tostring(cardDrawFgName)))
end
function AssetsUtils.GetCardDrawFgNode(skinId, x, y, params)
    return app.loadImage.new(CardUtils.GetCardDrawFgPathBySkinId(skinId), x, y, params)
end


-------------------------------------------------
-- 卡牌头像
-- cards/head/card_icon_xxxxxx.png
-------------------------------------------------

function AssetsUtils.GetCardHeadPath(cardHeadName)
    local path = string.format('cards/head/card_icon_%s.png', tostring(cardHeadName))
	if not app.gameResMgr:isExistent(path) then
		path = string.format('cards/head/card_icon_%s.png', CardUtils.DEFAULT_HEAD_ID)
	end
	return _res(path)
end
-- FIXME 因为 CommonUtils.GetGoodsIconPathById 使用了头像，所以目前没办法全面替换。


-------------------------------------------------
-- 卡牌编队背景
-- cards/teambg/card_draw_bg_xxxxxx.jpg
-------------------------------------------------

function AssetsUtils.GetCardTeamBgPath(cardTeamBgName)
    local path = string.format('cards/teambg/card_draw_bg_%s.jpg', tostring(cardTeamBgName))
    return app.gameResMgr:isExistent(path) and _res(path) or nil
end
function AssetsUtils.GetCardTeamBgNode(skinId, x, y)
    return app.loadImage.new(CardUtils.GetCardTeamBgPathBySkinId(skinId), x, y, {forceSize = cc.size(200, 540)})
end


-------------------------------------------------
-- 卡牌Q版 spine
-- cards/spine/avatar/
-------------------------------------------------

function AssetsUtils.GetCardSpinePath(spineId)
    local pathPrefix = _res(string.format('cards/spine/avatar/%s.atlas', tostring(spineId)))
	if not app.gameResMgr:isExistent(pathPrefix) then
		pathPrefix = string.format('cards/spine/avatar/%s.atlas', CardUtils.DEFAULT_SPINE_ID)
	end
    return utils.deletePathExtension(pathPrefix)
end

--[[
    @params params is CardSpine ctor args.
    @see Frame.gui.CardSpine
]]
function AssetsUtils.GetCardSpineNode(params)
    return app.cardSpine.new(params)
end


-------------------------------------------------
-- 卡牌技能 spine
-- cards/spine/effect/
-------------------------------------------------

function AssetsUtils.GetCardSkillSpinePath(effectId)
    return string.format('cards/spine/effect/%s', tostring(effectId))
end


-------------------------------------------------
-- 卡牌buff spine
-- cards/spine/hurt/
-------------------------------------------------

function AssetsUtils.GetCardBuffSpinePath(buffType)
    return string.format('cards/spine/hurt/%s', tostring(buffType))
end


-------------------------------------------------
-- 副本boss预览立绘
-- cards/raidboss/card_draw_xxxxxx_s.png
-------------------------------------------------

function AssetsUtils.GetRaidBossPreviewDrawPath(bossDrawName)
    return _res(string.format('cards/raidboss/card_draw_%s_s.png', tostring(bossDrawName)))
end
function AssetsUtils.GetRaidBossPreviewDrawNode(skinId, x, y, params)
    return app.loadImage.new(CardUtils.GetRaidBossPreviewDrawPathBySkinId(skinId), x, y, params)
end

-------------------------------------------------
-- 卡牌商标
-- cards/trademark/card_draw_words_xxx.png
-------------------------------------------------

function AssetsUtils.GetCardTrademarkPath(cardTrademarkName)
    local path = string.format('cards/trademark/%s.png', tostring(cardTrademarkName))
    if app.gameResMgr:isExistent(path) then
        return _res(path)
	end
end
function AssetsUtils.GetCardTrademarkNode(trademarkName, x, y)
    if trademarkName then
		return app.loadImage.new(AssetsUtils.GetCardTrademarkPath(trademarkName), x, y)
	else
		return app.loadImage.new(nil, x, y)
	end

end