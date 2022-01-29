--[[
游乐园（夏活）滚动数字控件
--]]
local JumpingNumberTextComponent = class('JumpingNumberTextComponent', function ()
    local node = CLayout:create()
    node.name = 'home.JumpingNumberTextComponent'
    node:enableNodeEvents()
    return node
end)
function JumpingNumberTextComponent:ctor( ... )
    self.args = unpack({...})
    self.numbers_         = {}        -- 按最高位起始顺序设置每位数字Text（显示组）
    self.unactiveNumbers_ = {}        -- 按最高位起始顺序设置每位数字Text（替换组）
    self.duration_        = 1         -- 动画时长
    self.rollingDuration_ = 0         -- 滚动时长
    self.speed_           = 1         -- 数字每次变动数值
    self.delay_           = 0.05      -- 滚动延迟
    self.curNumber_       = 0         -- 当前数字
    self.startNumber_     = 0         -- 起始数字
    self.toNumber_        = 0         -- 最终数字
    self.isJumping_       = false     -- 是否处于滚动中 
    self.digitNum_        = 3         -- 数字数目
    self.fontSize_        = 80        -- 文字大小
    self.fontColor_       = '#ffffff' -- 文字颜色
    self.textW_            = 0        -- 文字宽度
    self:InitUI()
end
--[[
init ui
--]]
function JumpingNumberTextComponent:InitUI()
    local function CreateView()
        local bg = display.newImageView(_res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_num.png'), 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        -- 裁剪节点
        local clipNode = cc.ClippingNode:create()

	    clipNode:setPosition(cc.p(size.width/2, size.height/2))
	    view:addChild(clipNode, 1)
	    local stencilNode = display.newNSprite(_res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_num.png'), 0, 0)
	    clipNode:setAlphaThreshold(0.1)
        clipNode:setStencil(stencilNode)
        local numberLayout = CLayout:create(size)
        numberLayout:setPosition(0, 0)
        clipNode:addChild(numberLayout)
        return {
            view             = view,
            size             = size,
            numberLayout     = numberLayout,
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
        self:setContentSize(self.viewData.size)
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
end
--[[
设置显示数字
@params digitNum int 显示数字位数
startNumber int 起始数字
}
--]]
function JumpingNumberTextComponent:SetStartNumber( startNumber, digitNum )
    self.startNumber_ = checkint(startNumber)
    self.digitNum_ = checkint(digitNum or 3)
    self.viewData.numberLayout:removeAllChildren()
    self.numbers_ = {}
    self.unactiveNumbers_ = {}
    local temp = display.newLabel(0, 0, {text = '0', fontSize = self.fontSize_, ttf = true, color = self.fontColor_, font = TTF_GAME_FONT})
    local textW = display.getLabelContentSize(temp).width -- 字符宽度
    self.textW_ = textW 
    for i=1, self.digitNum_ do
        local text = display.newLabel(self:GetNumberPosX(i), self.viewData.size.height/2, {text = '0', fontSize = self.fontSize_, ttf = true, color = self.fontColor_, font = TTF_GAME_FONT})
        self.viewData.numberLayout:addChild(text)
        table.insert(self.numbers_, text)
        local unactiveText = display.newLabel(self:GetNumberPosX(i), -self.fontSize_/2, {text = '0', fontSize = self.fontSize_, ttf = true, color = self.fontColor_, font = TTF_GAME_FONT})
        self.viewData.numberLayout:addChild(unactiveText)
        table.insert(self.unactiveNumbers_, unactiveText)
    end
    self:RefreshView(self.startNumber_)
end
--[[
刷新页面
@params number int 显示数字
--]]
function JumpingNumberTextComponent:RefreshView( number )
    local list = self:GetNumberList(number)
    for i, v in ipairs(self.numbers_) do
        if list[i] then
            v:setString(list[i])
        end
    end
    self.curNumber_ = checkint(number)
end
--[[
获取数字字符List
@params number int 需转换的数字
--]]
function JumpingNumberTextComponent:GetNumberList( number )
    local numStr = string.format(string.format('%%.%dd', self.digitNum_), checkint(number))
    local list = {}
    local length = string.len(numStr)
    local startNum = 1
    if length > self.digitNum_ then
        startNum = startNum + length - self.digitNum_
    end
    for i = startNum, length do
        table.insert(list, string.sub(numStr, i, i))
    end
    return list
end
--[[
改变数字 
@params toNumber int 目标数字
--]]
function JumpingNumberTextComponent:ChangeNumber( toNumber )
    if self.isJumping_ then return end
    self.toNumber_ = checkint(toNumber)
    local different = self.toNumber_ - self.curNumber_
    if different > 0 then
        self.speed_ = 1
    elseif different < 0 then
        self.speed_ = -1
    elseif different == 0 then
        return 
    end
    self.rollingDuration_ = math.abs(self.duration_/different)
    if math.abs(different) == 1 then
        self.rollingDuration_ = self.rollingDuration_ / 2
    end
    self.isJumping_ = true
    self:JumpAction()
end
--[[
滚动动画
--]]
function JumpingNumberTextComponent:JumpAction()
    if self.speed_ > 0 then
        self.curNumber_ = math.min(self.curNumber_ + self.speed_, self.toNumber_)
    elseif self.speed_ < 0 then
        self.curNumber_ = math.max(self.curNumber_ + self.speed_, self.toNumber_)
    end
    
    local list = self:GetNumberList(self.curNumber_)
    for i, v in ipairs(list) do
        if self.numbers_[i] then
            local curStr = self.numbers_[i]:getString()
            if v ~= curStr then
                local tempNum = self.unactiveNumbers_[i]
                tempNum:setString(v)
                tempNum:stopAllActions()
                if self.speed_ > 0 then
                    tempNum:setPosition(cc.p(self:GetNumberPosX(i), -self.fontSize_/2))
                    local action1 = cc.MoveTo:create(self.rollingDuration_, cc.p(self:GetNumberPosX(i), self.viewData.size.height/2))
                    local action2 = cc.MoveTo:create(self.rollingDuration_, cc.p(self:GetNumberPosX(i), self.viewData.size.height + self.fontSize_))
                    local delay = 0
                    if #list > i then
                        delay = self.delay_ * math.pow(2, #list - i)
                    end
                    tempNum:runAction(cc.Sequence:create(cc.DelayTime:create(delay), action1))
                    self.numbers_[i]:runAction(cc.Sequence:create(cc.DelayTime:create(delay), action2))
                    self.unactiveNumbers_[i] = self.numbers_[i]
                    self.numbers_[i] = tempNum
                elseif self.speed_ < 0 then
                    tempNum:setPosition(cc.p(self:GetNumberPosX(i), self.viewData.size.height + self.fontSize_/2))
                    local action1 = cc.MoveTo:create(self.rollingDuration_, cc.p(self:GetNumberPosX(i), self.viewData.size.height/2))
                    local action2 = cc.MoveTo:create(self.rollingDuration_, cc.p(self:GetNumberPosX(i), -self.fontSize_))
                    local delay = 0
                    if #list > i then
                        delay = self.delay_ * math.pow(2, #list - i)
                    end
                    tempNum:runAction(cc.Sequence:create(cc.DelayTime:create(delay), action1))
                    self.numbers_[i]:runAction(cc.Sequence:create(cc.DelayTime:create(delay), action2))
                    self.unactiveNumbers_[i] = self.numbers_[i]
                    self.numbers_[i] = tempNum
                end
            end
        end
    end
    
    transition.execute(self, nil, {delay = self.rollingDuration_, complete = function()
        if self.curNumber_ ~= self.toNumber_ then
            self:JumpAction()
        else
            self.isJumping_ = false
        end
    end})
end
function JumpingNumberTextComponent:GetNumberPosX( index )
    return 40 + (checkint(index) - 1) * self.textW_
end
return JumpingNumberTextComponent