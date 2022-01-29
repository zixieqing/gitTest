--[[
 * author : liuzhipeng
 * descpt : 图鉴 飨灵收集册 升级popup
--]]
local CardAlbumUpgradePopup = class('CardAlbumUpgradePopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'collection.cardAlbum.CardAlbumUpgradePopup'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                   = _res('ui/collection/cardAlbum/rank_up_bg.png'),
    UPGRAGE_TITLE        = _res('ui/collection/cardAlbum/rank_ico_level_up.png'),
    LEVEL_ARROW          = _res('ui/collection/cardAlbum/rank_arrow_small.png'),
    ATTRIBUTE_ARROW      = _res('ui/collection/cardAlbum/rank_up_ico_arrow.png'),
    ATTRIBUTE_SPLIT_LINE = _res('ui/collection/cardAlbum/rank_up_line.png'),
}
local PROPERTY_DATA = {
    [tostring(ObjP.ATTACK)]     = {name = __('攻击力'), path = 'ui/common/role_main_att_ico.png'},
    [tostring(ObjP.DEFENCE)]    = {name = __('防御力'), path = 'ui/common/role_main_def_ico.png'},
    [tostring(ObjP.HP)]         = {name = __('生命值'), path = 'ui/common/role_main_hp_ico.png'},
    [tostring(ObjP.CRITRATE)]   = {name = __('暴击值'), path = 'ui/common/role_main_baoji_ico.png'},
    [tostring(ObjP.CRITDAMAGE)] = {name = __('暴伤值'), path = 'ui/common/role_main_baoshangi_ico.png'},
    [tostring(ObjP.ATTACKRATE)] = {name = __('攻速值'), path = 'ui/common/role_main_speed_ico.png'},
}
local CreateListCell = nil 

function CardAlbumUpgradePopup:ctor( ... )
    local args = unpack({...})
    self.level = args.level or 1 
    self.newLevel = args.newLevel or 1
    self:InitUI()
end
--[[
init ui
--]]
function CardAlbumUpgradePopup:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 升级成功
        local upgradeTitle = display.newImageView(RES_DICT.UPGRAGE_TITLE, size.width / 2, size.height - 105)
        view:addChild(upgradeTitle, 1)
        -- 等级
        local arrow = display.newImageView(RES_DICT.LEVEL_ARROW, size.width / 2 + 5, size.height / 2 + 50)
        view:addChild(arrow, 5)
        local levelLabel = display.newLabel(size.width / 2 - 55, size.height / 2 + 50, {text = '1', fontSize = 26, color = '#ffe22e', ttf = true, font = TTF_GAME_FONT})
        view:addChild(levelLabel, 5)
        local newLevelLabel = display.newLabel(size.width / 2 + 65, size.height / 2 + 50, {text = '1', fontSize = 26, color = '#ffe22e', ttf = true, font = TTF_GAME_FONT})
        view:addChild(newLevelLabel, 5)
        -- 属性面板
        local propertyArrow = display.newImageView(RES_DICT.ATTRIBUTE_ARROW, size.width / 2 + 5, size.height / 2 - 82)
        view:addChild(propertyArrow, 5)

        local buffConf = CONF.CARD.CARD_COLL_BUFF:GetValue(1)
        local buffDefine = table.keys(buffConf.buff)
        table.sort(buffDefine)
        local levelMap = {}
        local newLevelMap = {}
        for i, v in ipairs(buffDefine) do
            -- 当前等级
            local icon = display.newImageView(PROPERTY_DATA[v].path, 80, size.height - 185 - i * 50)
            view:addChild(icon, 1)
            local name = display.newLabel(105, size.height - 183 - i * 50, {text = PROPERTY_DATA[v].name, fontSize = 22, color = '#6c4a31', ap = display.LEFT_CENTER})
            view:addChild(name, 1)
            local valueLabel = display.newLabel(320, size.height - 183 - i * 50, {text = '', fontSize = 23, color = '#66b526', ap = display.RIGHT_CENTER})
            view:addChild(valueLabel, 1)
            local line = display.newImageView(RES_DICT.ATTRIBUTE_SPLIT_LINE, size.width / 2 - 170, size.height - 203 - i * 50)
            view:addChild(line, 1)
            levelMap[v] = valueLabel
            -- 下一等级
            local icon = display.newImageView(PROPERTY_DATA[v].path, size.width - 290, size.height - 185 - i * 50)
            view:addChild(icon, 1)
            local name = display.newLabel(size.width - 265, size.height - 183 - i * 50, {text = PROPERTY_DATA[v].name, fontSize = 22, color = '#6c4a31', ap = display.LEFT_CENTER})
            view:addChild(name, 1)
            local valueLabel = display.newLabel(size.width - 55, size.height - 183 - i * 50, {text = '', fontSize = 23, color = '#66b526', ap = display.RIGHT_CENTER})
            view:addChild(valueLabel, 1)
            local line = display.newImageView(RES_DICT.ATTRIBUTE_SPLIT_LINE, size.width / 2 + 180, size.height - 203 - i * 50)
            view:addChild(line, 1)
            newLevelMap[v] = valueLabel
        end
        return {
            view                = view,
            levelLabel          = levelLabel,
            newLevelLabel       = newLevelLabel,
            levelMap            = levelMap,
            newLevelMap         = newLevelMap,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true, cb = handler(self, self.CloseAction)})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:RefreshView()
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CardAlbumUpgradePopup:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function CardAlbumUpgradePopup:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
    )
end
--[[
刷新页面
--]]
function CardAlbumUpgradePopup:RefreshView()
    local viewData = self:GetViewData()
    viewData.levelLabel:setString(self.level)
    viewData.newLevelLabel:setString(self.newLevel)
    local levelBuffConf = CONF.CARD.CARD_COLL_BUFF:GetValue(self.level)
    local newLevelBuffConf = CONF.CARD.CARD_COLL_BUFF:GetValue(self.newLevel)
    if next(levelBuffConf) ~= nil then
        for k, v in pairs(levelBuffConf.buff) do
            if viewData.levelMap[k] then
                viewData.levelMap[k]:setString(string.format('+%d%%', tonumber(v) * 100))
            end
        end
    else
        for k, v in pairs(viewData.levelMap) do
            viewData.levelMap[k]:setString('+0%')
        end
    end
    if next(newLevelBuffConf) ~= nil  then
        for k, v in pairs(newLevelBuffConf.buff) do
            if viewData.newLevelMap[k] then
                viewData.newLevelMap[k]:setString(string.format('+%d%%', tonumber(v) * 100))
            end
        end
    else        
        for k, v in pairs(viewData.newLevelMap) do
            viewData.newLevelMap[k]:setString('+0%')
        end
    end
end
--[[
获取viewData
--]]
function CardAlbumUpgradePopup:GetViewData()
    return self.viewData
end
return CardAlbumUpgradePopup