--[[
特殊活动 周年庆pv回顾页签view
--]]
local SpActivityAnniPVView = class('SpActivityAnniPVView', function ()
    local node = CLayout:create()
    node.name = 'home.SpActivityAnniPVView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    COMMON_BTN_WHITE = _res('ui/common/common_btn_white_default.png'),
    H5_BUTTON        = _res('ui/anniversary/poster/btn_anni_h5.png'),

}
function SpActivityAnniPVView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function SpActivityAnniPVView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local pvBtn = display.newButton(size.width / 2 + 447, size.height / 2 + 230, {n = RES_DICT.COMMON_BTN_WHITE})
        view:addChild(pvBtn, 10)
        local pvLabel = display.newLabel(pvBtn:getContentSize().width / 2, pvBtn:getContentSize().height / 2, fontWithColor(14, {text = __('回看')}))
        pvBtn:addChild(pvLabel, 1)
        local anniBtn = display.newButton(size.width / 2 + 110, size.height / 2 - 250, {n = RES_DICT.H5_BUTTON})
        view:addChild(anniBtn, 10)
        local anniLabel = display.newLabel(anniBtn:getContentSize().width / 2, anniBtn:getContentSize().height / 2, {text = __('周年回顾'), fontSize = 38, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#984814', outlineSize = 2})
        anniBtn:addChild(anniLabel, 1)
        return {      
            view                 = view,
            pvBtn                = pvBtn,
            anniBtn              = anniBtn,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

return SpActivityAnniPVView
