--[[
特殊活动 活动副本页签view
--]]
local SpActivityQuestPageView = class('SpActivityQuestPageView', function ()
    local node = CLayout:create()
    node.name = 'home.SpActivityQuestPageView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BTN_BG     = _res('ui/home/specialActivity/unni_activity_bg_button.png'),
    COMMON_BTN = _res('ui/common/common_btn_orange_big.png')
}
function SpActivityQuestPageView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function SpActivityQuestPageView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local exbtnBg = display.newImageView(RES_DICT.BTN_BG, size.width / 2 + 173, size.height / 2 - 200)
        view:addChild(exbtnBg, 2)
        local exchangeBtn = display.newButton(size.width / 2 + 173, size.height / 2 - 200, {n = RES_DICT.COMMON_BTN})
        view:addChild(exchangeBtn, 3)
        local extextLabel = display.newLabel(exchangeBtn:getContentSize().width / 2, exchangeBtn:getContentSize().height / 2, fontWithColor(14, {text = __('前往兑换')}))
        exchangeBtn:addChild(extextLabel, 1)
        local btnBg = display.newImageView(RES_DICT.BTN_BG, size.width / 2 + 373, size.height / 2 - 200)
        view:addChild(btnBg, 2)
        local enterBtn = display.newButton(size.width / 2 + 373, size.height / 2 - 200, {n = RES_DICT.COMMON_BTN})
        view:addChild(enterBtn, 3)
        local textLabel = display.newLabel(enterBtn:getContentSize().width / 2, enterBtn:getContentSize().height / 2, fontWithColor(14, {text = __('进入副本')}))
        enterBtn:addChild(textLabel, 1)
        return {      
            view                 = view,
            exchangeBtn          = exchangeBtn,
            enterBtn             = enterBtn,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

return SpActivityQuestPageView
