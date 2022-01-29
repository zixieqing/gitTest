--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动Scene
--]]
local GameScene = require('Frame.GameScene')
local AssemblyActivityScene = class('AssemblyActivityScene', GameScene)

local RES_DICT = {
    COMMON_TITLE                    = _res('ui/common/common_title.png'),
    COMMON_TIPS                     = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    BG                              = _res('ui/home/activity/assemblyActivity/home/castle_map_bg.jpg'),
    TITLE_BG                        = _res('ui/home/activity/assemblyActivity/home/anni_main_label_title.png')

    


    -- spine --
}
local ENTRY_CONFIG = {
    {pos = cc.p(display.width / 2 - 480, display.height / 2 - 180)},
    {pos = cc.p(display.width / 2 - 300, display.height / 2 + 130)},
    {pos = cc.p(display.width / 2, display.height / 2)},
    {pos = cc.p(display.width / 2 + 300, display.height / 2 + 140)},
    {pos = cc.p(display.width / 2 + 480, display.height / 2 - 180)},
}
local CreateStageCell = nil
function AssemblyActivityScene:ctor( ... )
    self.super.ctor(self, 'AssemblyActivityScene')
    local args = unpack({...})
    self:InitUI()
end
--[[
初始化ui
--]]
function AssemblyActivityScene:InitUI()
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
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('返场狂欢会'), fontSize = 30, color = '#473227',offset = cc.p(0,-10)})
        self:addChild(tabNameLabel, 20)
        -- 提示按钮 
        local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 29)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)

        -- 按钮layout
        local btnLayout = CLayout:create(size)
        btnLayout:setPosition(display.center)
        view:addChild(btnLayout, 5)

        
        return {
            view                = view,
            backBtn             = backBtn,
            tabNameLabel        = tabNameLabel,
            bg                  = bg,  
            btnLayout           = btnLayout,
        }
    end
    xTry(function ()
        self.viewData = CreateView()
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
创建子活动入口
@params mainModuleList list 主入口模块列表
@params topModuleList  list 顶部入口模块列表
--]]
function AssemblyActivityScene:CreateEntry( mainModuleList, topModuleList, callback )
    local viewData = self:GetViewData()
    viewData.btnLayout:removeAllChildren()
    for i, v in ipairs(checktable(mainModuleList)) do
        local pos = ENTRY_CONFIG[checkint(v.areaId)].pos
        local entryBtn = display.newButton(pos.x, pos.y, {n = _res(string.format('ui/home/activity/assemblyActivity/home/%s.png', v.photoId)), cb = callback})
        entryBtn:setTag(checkint(v.moduleId))
        viewData.btnLayout:addChild(entryBtn, 1)
        local titleBg = display.newImageView(RES_DICT.TITLE_BG, pos.x, pos.y - 90)
        viewData.btnLayout:addChild(titleBg, 1)
        local titleLabel = display.newLabel(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2, fontWithColor(14, {text = v.areaName}))
        titleBg:addChild(titleLabel, 1)
    end
    for i, v in ipairs(checktable(topModuleList)) do
        local entryBg = display.newImageView(_res(string.format('ui/home/activity/assemblyActivity/home/anni_main_label_%d.png', i)), display.width - 150 - (i - 1) * 140 - display.SAFE_L, display.height - 60)
        viewData.btnLayout:addChild(entryBg, 1)
        local entryBtn = display.newButton(display.width - 150 - (i - 1) * 140 - display.SAFE_L, display.height - 60, {n = _res(string.format('ui/home/activity/assemblyActivity/home/%s.png', 'main_btn_rank')), cb = callback})
        entryBtn:setTag(checkint(v.moduleId))
        viewData.btnLayout:addChild(entryBtn, 1)
        local titleLabel = display.newLabel(display.width - 150 - (i - 1) * 140 - display.SAFE_L, display.height - 90, fontWithColor(14, {text = v.areaName, fontSize = 20, outlineSize = 2}))
        viewData.btnLayout:addChild(titleLabel, 1)
    end
end
--[[
获取viewData
--]]
function AssemblyActivityScene:GetViewData()
    return self.viewData
end
return AssemblyActivityScene