--[[
 * author : liuzhipeng
 * descpt : 图鉴 飨灵收集册Scene
--]]
local GameScene = require('Frame.GameScene')
local CardAlbumScene = class('CardAlbumScene', GameScene)
local RemindIcon = require('common.RemindIcon')

local RES_DICT = {
    COMMON_TITLE                    = _res('ui/common/common_title.png'),
    COMMON_TIPS                     = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    SCENE_BG                        = _res('ui/collection/cardAlbum/collect_main_bg.png'),
    LIST_BG                         = _res('ui/collection/cardAlbum/pokedex_monster_tab_bg.png'),
    LIST_FG_TOP                     = _res('ui/collection/cardAlbum/pokedex_monster_img_up.png'),
    LIST_FG_BOTTOM                  = _res('ui/collection/cardAlbum/pokedex_monster_img_down.png'),
    ALBUM_BG                        = _res('ui/collection/cardAlbum/collect_main_list_bg.png'),
    CONTENT_TOP_BG                  = _res('ui/collection/cardAlbum/collect_main_list_bg_1.png'),
    BUFF_LEVEL_BG                   = _res('ui/collection/cardAlbum/common_bg_title_4.png'),
    TASK_BTN                        = _res('ui/collection/cardAlbum/tesk_btn_selection_used.png'),
    TASK_ICON                       = _res('ui/collection/cardAlbum/tesk_ico_book_4.png'),
    CONTENT_SPLIT_LINE              = _res('ui/collection/cardAlbum/collect_main_line.png'),
    ATTRIBUTE_BG                    = _res('ui/collection/cardAlbum/rank_selection_bg_frame.png'),
    TAB_BTN_N                       = _res('ui/collection/cardAlbum/collect_left_ico_unselect_.png'),
    TAB_BTN_S                       = _res('ui/collection/cardAlbum/collect_left_ico_select_.png'),
    ATTRIBUTE_SPLIT_LINE            = _res('ui/collection/cardAlbum/rank_selection_line.png'),
    ATTRIBUTE_ARROW                 = _res('ui/collection/cardAlbum/rank_up_ico_arrow.png'),
    REMIND_ICON                     = _res('ui/common/common_hint_circle_red_ico.png'),
    -- spine --
}
local CreateTabCell = nil 
local CreateCardCell = nil
local PROPERTY_DATA = {
    [tostring(ObjP.ATTACK)]     = {name = __('攻击力'), path = 'ui/common/role_main_att_ico.png'},
    [tostring(ObjP.DEFENCE)]    = {name = __('防御力'), path = 'ui/common/role_main_def_ico.png'},
    [tostring(ObjP.HP)]         = {name = __('生命值'), path = 'ui/common/role_main_hp_ico.png'},
    [tostring(ObjP.CRITRATE)]   = {name = __('暴击值'), path = 'ui/common/role_main_baoji_ico.png'},
    [tostring(ObjP.CRITDAMAGE)] = {name = __('暴伤值'), path = 'ui/common/role_main_baoshangi_ico.png'},
    [tostring(ObjP.ATTACKRATE)] = {name = __('攻速值'), path = 'ui/common/role_main_speed_ico.png'},
}
function CardAlbumScene:ctor( ... )
    self.super.ctor(self, 'CardAlbumScene')
    local args = unpack({...})
    self:InitUI()
end
--[[
初始化ui
--]]
function CardAlbumScene:InitUI()
    local CreateView = function ()
        local size = display.size
        local view = CLayout:create(size)
        view:setPosition(size.width / 2, size.height / 2)
        -- 返回按钮
        local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
                {
                    ap = display.LEFT_CENTER,
                    n = RES_DICT.COMMON_BTN_BACK,
                    scale9 = true, size = cc.size(90, 70),
                    enable = true,
                })
        view:addChild(backBtn, 10)
        -- 标题板
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('游记'), fontSize = 30, color = '#473227',offset = cc.p(0,-10)})
        self:addChild(tabNameLabel, 20)
        -- 提示按钮
        local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 29)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 背景
        local bg = display.newImageView(RES_DICT.SCENE_BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        local albumBg = display.newImageView(RES_DICT.ALBUM_BG, size.width / 2, size.height / 2 - 35)
        view:addChild(albumBg, 1)

        -- listLayout --
        local listLayoutSize = cc.size(220, 660)
        local listLayout = CLayout:create(listLayoutSize)
        listLayout:setPosition(cc.p(size.width / 2 - 558, size.height / 2 - 35))
        view:addChild(listLayout, 3)
        local listBg = display.newImageView(RES_DICT.LIST_BG, listLayoutSize.width / 2, listLayoutSize.height / 2)
        listLayout:addChild(listBg, 1)
        local listFgTop = display.newImageView(RES_DICT.LIST_FG_TOP, listLayoutSize.width / 2 - 1, listLayoutSize.height - 5, {ap = display.CENTER_TOP})
        listLayout:addChild(listFgTop, 5)
        local listFgBottom = display.newImageView(RES_DICT.LIST_FG_BOTTOM, listLayoutSize.width / 2 - 1, 5, {ap = display.CENTER_BOTTOM})
        listLayout:addChild(listFgBottom, 5) 

        local tabTableViewSize = cc.size(listLayoutSize.width, listLayoutSize.height - 10)
        local tabTableViewCellSize = cc.size(tabTableViewSize.width, 98)
        local tabTableView = display.newTableView(listLayoutSize.width / 2, listLayoutSize.height / 2, {size = tabTableViewSize, csize = tabTableViewCellSize, dir = display.SDIR_V, ap = display.CENTER})
		tabTableView:setCellCreateHandler(CreateTabCell)
        listLayout:addChild(tabTableView, 3)
        -- listLayout --

        -- contentLayout -- 
        local contentLayoutSize = cc.size(1125, 650)
        local contentLayout = CLayout:create(contentLayoutSize)
        contentLayout:setPosition(cc.p(size.width / 2 + 110, size.height / 2 - 35))
        view:addChild(contentLayout, 3)
        -- 顶部等级栏
        local topBg = display.newImageView(RES_DICT.CONTENT_TOP_BG, contentLayoutSize.width / 2, contentLayoutSize.height - 45)
        contentLayout:addChild(topBg, 1)
        local levelBg = display.newImageView(RES_DICT.BUFF_LEVEL_BG, 130, topBg:getContentSize().height / 2)
        topBg:addChild(levelBg, 1)
        local levelTitle = display.newLabel(levelBg:getContentSize().width / 2 - 20, levelBg:getContentSize().height / 2, {text = __('当前增益等级'), fontSize = 20, color = '#ffffff', reqW = 140})
        levelBg:addChild(levelTitle, 1)
        local levelLabel = display.newLabel(levelBg:getContentSize().width / 2 + 70, levelBg:getContentSize().height / 2, {text = '', fontSize = 26, color = '#ffe32e', ttf = true, font = TTF_GAME_FONT})
        levelBg:addChild(levelLabel, 1)
        local taskBtn = display.newButton(contentLayoutSize.width - 100, contentLayoutSize.height - 45, {n = RES_DICT.TASK_BTN})
        contentLayout:addChild(taskBtn, 5)
        display.commonLabelParams(taskBtn, {text = __('等级任务'), fontSize = 28, color = '#ffffff', reqW = 105, ttf = true, font = TTF_GAME_FONT})
        local taskIcon = display.newImageView(RES_DICT.TASK_ICON, -10, taskBtn:getContentSize().height / 2)
        taskBtn:addChild(taskIcon, 1)
        local taskBtnRemindIcon = RemindIcon.addRemindIcon({parent = taskBtn, po = cc.rep(cc.sizep(taskBtn, ui.rt), -10, 0)})
        -- cardTableView
        local cardTableViewSize = cc.size(1080, 284)
        local cardTableViewCellSize = cc.size(cardTableViewSize.width / 4, cardTableViewSize.height)
        local cardTableView = display.newTableView(contentLayoutSize.width / 2, contentLayoutSize.height - 220, {size = cardTableViewSize, csize = cardTableViewCellSize, dir = display.SDIR_H, ap = display.CENTER})
        cardTableView:setBounceable(false)
		cardTableView:setCellCreateHandler(CreateCardCell)
        contentLayout:addChild(cardTableView, 5)
        -- 分割线
        local contentSplitLine = display.newImageView(RES_DICT.CONTENT_SPLIT_LINE, contentLayoutSize.width / 2, contentLayoutSize.height / 2 - 45)
        contentLayout:addChild(contentSplitLine, 5)
        -- 属性面板
        local attributeBg = display.newImageView(RES_DICT.ATTRIBUTE_BG, contentLayoutSize.width / 2, 145)
        contentLayout:addChild(attributeBg, 1)
        local attributeBgSize = attributeBg:getContentSize()
        local curLevelTitle = display.newLabel(attributeBgSize.width / 2 - 270, attributeBgSize.height, {text = __('当前等级'), fontSize = 20, color = '#92614a'})
        attributeBg:addChild(curLevelTitle, 1)
        local nextLevelTitle = display.newLabel(attributeBgSize.width / 2 + 265, attributeBgSize.height, {text = __('下一等级'), fontSize = 20, color = '#92614a'})
        attributeBg:addChild(nextLevelTitle, 1)
        local curLevelLabel = display.newLabel(attributeBgSize.width / 2 - 270, attributeBgSize.height - 30, {text = '', fontSize = 26, color = '#ffe22e', ttf = true, font = TTF_GAME_FONT})
        attributeBg:addChild(curLevelLabel, 1)
        local nextLevelLabel = display.newLabel(attributeBgSize.width / 2 + 265, attributeBgSize.height - 30, {text = '', fontSize = 26, color = '#ffe22e', ttf = true, font = TTF_GAME_FONT})
        attributeBg:addChild(nextLevelLabel, 1)
        local lvUpArrow = display.newImageView(RES_DICT.ATTRIBUTE_ARROW, attributeBgSize.width / 2, attributeBgSize.height / 2 - 15)
        attributeBg:addChild(lvUpArrow, 5)

        local buffConf = CONF.CARD.CARD_COLL_BUFF:GetValue(1)
        local buffDefine = table.keys(buffConf.buff)
        table.sort(buffDefine)
        local curLevelMap = {}
        local nextLevelMap = {}
        for i, v in ipairs(buffDefine) do
            -- 当前等级
            local icon = display.newImageView(PROPERTY_DATA[v].path, 105, attributeBg:getContentSize().height - 40 - i * 40)
            attributeBg:addChild(icon, 1)
            local name = display.newLabel(130, attributeBg:getContentSize().height - 38 - i * 40, {text = PROPERTY_DATA[v].name, fontSize = 22, color = '#6c4a31', ap = display.LEFT_CENTER})
            attributeBg:addChild(name, 1)
            local valueLabel = display.newLabel(410, attributeBg:getContentSize().height - 38 - i * 40, {text = '', fontSize = 23, color = '#66b526', ap = display.RIGHT_CENTER})
            attributeBg:addChild(valueLabel, 1)
            local line = display.newImageView(RES_DICT.ATTRIBUTE_SPLIT_LINE, attributeBg:getContentSize().width / 2 - 270, attributeBg:getContentSize().height - 58 - i * 40)
            attributeBg:addChild(line, 1)
            curLevelMap[v] = valueLabel
            -- 下一等级
            local icon = display.newImageView(PROPERTY_DATA[v].path, attributeBg:getContentSize().width - 410, attributeBg:getContentSize().height - 40 - i * 40)
            attributeBg:addChild(icon, 1)
            local name = display.newLabel(attributeBg:getContentSize().width - 385, attributeBg:getContentSize().height - 38 - i * 40, {text = PROPERTY_DATA[v].name, fontSize = 22, color = '#6c4a31', ap = display.LEFT_CENTER})
            attributeBg:addChild(name, 1)
            local valueLabel = display.newLabel(attributeBg:getContentSize().width - 100, attributeBg:getContentSize().height - 38 - i * 40, {text = '', fontSize = 23, color = '#66b526', ap = display.RIGHT_CENTER})
            attributeBg:addChild(valueLabel, 1)
            local line = display.newImageView(RES_DICT.ATTRIBUTE_SPLIT_LINE, attributeBg:getContentSize().width / 2 + 265, attributeBg:getContentSize().height - 58 - i * 40)
            attributeBg:addChild(line, 1)
            nextLevelMap[v] = valueLabel
        end
        -- contentLayout -- 
        return {
            view                = view,
            backBtn             = backBtn,
            tabNameLabel        = tabNameLabel,
            bg                  = bg,
            taskBtn             = taskBtn,
            tabTableView        = tabTableView,
            cardTableView       = cardTableView,
            levelLabel          = levelLabel,
            curLevelMap         = curLevelMap,
            nextLevelMap        = nextLevelMap,
            curLevelLabel       = curLevelLabel,
            nextLevelLabel      = nextLevelLabel,
            taskBtnRemindIcon   = taskBtnRemindIcon,
        }
    end
    xTry(function ()
        self.viewData = CreateView()
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
创建页签列表cell
--]]
CreateTabCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local btn = display.newButton(size.width / 2, 40, {n = RES_DICT.TAB_BTN_N})
    btn:setName('nameBtn')
    view:addChild(btn , 1)
    local titleLabel = display.newLabel(size.width / 2, 40, {text = '', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#361d0e', outlineSize = 1})
    view:addChild(titleLabel, 1)
    local remindIcon = RemindIcon.addRemindIcon({parent = view, po = cc.rep(cc.sizep(view, ui.rt), -30, -20)})
    return {
        view       = view,
        btn        = btn,
        titleLabel = titleLabel,
        remindIcon = remindIcon,
    }
end
--[[
创建卡牌列表cell
--]]
CreateCardCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local cardNode = require('Game.views.collection.cardAlbum.CardAlbumCardNode').new()
    cardNode:setPosition(size.width / 2, size.height / 2)
    view:addChild(cardNode, 1)
    return {
        view       = view,
        cardNode   = cardNode,
    }
end
--[[
刷新页签选中状态
@params cell       node cell节点
@params isSelected bool 是否选中 
--]]
function CardAlbumScene:RefreshTabSelectedState( cell, isSelected )
    if not cell then return end
    local btn = cell:getChildByName('nameBtn')
    if isSelected then
        btn:setNormalImage(RES_DICT.TAB_BTN_S)
        btn:setSelectedImage(RES_DICT.TAB_BTN_S)
    else
        btn:setNormalImage(RES_DICT.TAB_BTN_N)
        btn:setSelectedImage(RES_DICT.TAB_BTN_N)
    end
end
--[[
刷新当前等级
--]]
function CardAlbumScene:RefershCurrentLevel( level )
    local viewData = self:GetViewData()
    viewData.levelLabel:setString(level)
    viewData.curLevelLabel:setString(level)
    viewData.nextLevelLabel:setString(level + 1)
    local curLevelBuffConf = CONF.CARD.CARD_COLL_BUFF:GetValue(level)
    local nextLevelBuffConf = CONF.CARD.CARD_COLL_BUFF:GetValue(level + 1)
    if next(curLevelBuffConf) ~= nil then
        for k, v in pairs(curLevelBuffConf.buff) do
            if viewData.curLevelMap[k] then
                viewData.curLevelMap[k]:setString(string.format('+%d%%', tonumber(v) * 100))
            end
        end
    else
        for k, v in pairs(viewData.curLevelMap) do
            viewData.curLevelMap[k]:setString('+0%')
        end
    end
    if next(nextLevelBuffConf) ~= nil  then
        for k, v in pairs(nextLevelBuffConf.buff) do
            if viewData.nextLevelMap[k] then
                viewData.nextLevelMap[k]:setString(string.format('+%d%%', tonumber(v) * 100))
            end
        end
    else        
        for k, v in pairs(viewData.nextLevelMap) do
            viewData.nextLevelMap[k]:setString('+0%')
        end
    end
end
--[[
刷新任务红点
--]]
function CardAlbumScene:RefershTaskBtnRemindIcon( bookId )
    local viewData = self:GetViewData()
    viewData.remindIcon:setVisible(app.cardMgr.IsCardAlbumBookCanDraw(bookId))
end
--[[
获取viewData
--]]
function CardAlbumScene:GetViewData()
    return self.viewData
end
return CardAlbumScene