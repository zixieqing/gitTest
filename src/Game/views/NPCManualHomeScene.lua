--[[
NPC图鉴主页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
local NPCManualHomeScene = class('NPCManualHomeScene',GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function NPCManualHomeScene:ctor(...)
	self.super.ctor(self,'views.NPCManualHomeScene')
    local args = unpack({...})
    self.viewData = nil
    local function CreateView()
        local bg = display.newImageView(_res('ui/home/handbook/pokedex_npc_bg.jpg'), 0, 0, {ap = cc.p(0, 0), isFull = true})
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)
        view:addChild(bg, 1)
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT,  text = __('角色介绍'),reqW = 250, fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)
        local tabNameLabelSize = display.getLabelContentSize(tabNameLabel:getLabel())
        if tabNameLabelSize.width > 350  then
            display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT,  text = __('角色介绍'), fontSize = 22, hAlign = display.TAC, w = 250 , color = '473227'})
        else
            display.commonLabelParams(tabNameLabel, {})
        end
        -- 收集进度
        local collectionBg = display.newButton(display.width - 10 - display.SAFE_L, display.height - 70, {ap = cc.p(1, 0.5), n = _res('ui/home/handbook/pokedex_npc_bg_collection_degree.png')})
        display.commonLabelParams(collectionBg, {text = ' ', fontSize = 24, color = '#ffffff'})
        view:addChild(collectionBg, 5)
        -- 列表背景
        local listBg = display.newImageView(_res('ui/home/handbook/pokedex_monster_list_bg.png'), display.width/2, display.height/2 - 45, {scale9 = true, size = cc.size(display.width - 2*display.SAFE_L, 625)})
        view:addChild(listBg, 5)
        -- 列表
        local listSize = cc.size(listBg:getContentSize().width+4, listBg:getContentSize().height)
        local listCellSize = cc.size(195, listSize.height)
        local gridView = CTableView:create(listSize)
        gridView:setSizeOfCell(listCellSize)
        gridView:setAutoRelocate(true)
        gridView:setDirection(eScrollViewDirectionHorizontal)
        gridView:setPosition(cc.p(display.width/2, display.height/2 - 45))
        view:addChild(gridView, 10)

		return {
            view         = view,
            bg           = bg,
            tabNameLabel = tabNameLabel,
            gridView     = gridView,
            listSize     = listSize,
            listCellSize = listCellSize,
            collectionBg = collectionBg
        }
    end

    self.viewData = CreateView()

    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, cc.p(display.SAFE_L + 130, display.height - 80)))
    self.viewData.tabNameLabel:runAction( action )
end


function NPCManualHomeScene:onCleanup()
end

return NPCManualHomeScene
