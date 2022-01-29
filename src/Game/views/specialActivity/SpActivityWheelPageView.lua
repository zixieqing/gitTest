--[[
特殊活动 转盘活动页签view
--]]
local SpActivityWheelPageView = class('SpActivityWheelPageView', function ()
    local node = CLayout:create()
    node.name = 'home.SpActivityWheelPageView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BTN_BG     = _res('ui/home/specialActivity/unni_activity_bg_button.png'),
    COMMON_BTN = _res('ui/common/common_btn_orange_big.png')
}
function SpActivityWheelPageView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function SpActivityWheelPageView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)



        local drawBg = display.newImageView(RES_DICT.BTN_BG, size.width / 2 + 173, size.height / 2 - 200)
        view:addChild(drawBg, 2)
        local drawBtn = display.newButton(size.width / 2 + 173, size.height / 2 - 200, {n = RES_DICT.COMMON_BTN})
        view:addChild(drawBtn, 3)
        local drawTextLabel = display.newLabel(drawBtn:getContentSize().width / 2, drawBtn:getContentSize().height / 2, fontWithColor(14, {text = __('豪华奖励')}))
        drawBtn:addChild(drawTextLabel, 1)
        local btnBg = display.newImageView(RES_DICT.BTN_BG, size.width / 2 + 373, size.height / 2 - 200)
        view:addChild(btnBg, 2)
        local enterBtn = display.newButton(size.width / 2 + 373, size.height / 2 - 200, {n = RES_DICT.COMMON_BTN})
        view:addChild(enterBtn, 3)
        local textLabel = display.newLabel(enterBtn:getContentSize().width / 2, enterBtn:getContentSize().height / 2, fontWithColor(14, {text = __('前 往')}))
        enterBtn:addChild(textLabel, 1)
        drawBg:setVisible(false)
        drawBtn:setVisible(false)
        btnBg:setVisible(false)
        enterBtn:setVisible(false)
        return {      
            view                 = view,
            enterBtn             = enterBtn,
            drawBtn              = drawBtn,
            drawBg               = drawBg,
            btnBg                = btnBg,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

return SpActivityWheelPageView
