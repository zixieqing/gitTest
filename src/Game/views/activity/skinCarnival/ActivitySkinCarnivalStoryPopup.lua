--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 皮肤故事popup
--]]
local ActivitySkinCarnivalStoryPopup = class('ActivitySkinCarnivalStoryPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.skinCarnival.ActivitySkinCarnivalStoryPopup'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                     = _res('ui/home/activity/skinCarnival/storyBg/story_bg.png'),
}
--[[
@params map {
    title string 故事标题
    story string 故事正文
}
--]]
function ActivitySkinCarnivalStoryPopup:ctor( params )
    self.storyData = checktable(params)
    self:InitUI()
end
--[[
init ui
--]]
function ActivitySkinCarnivalStoryPopup:InitUI()
    local storyData = self.storyData
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)

        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- 故事标题
        local titleLabel = display.newLabel(size.width / 2 + 10, size.height - 50, {text = '', color = '#A58669', fontSize = 26})
        view:addChild(titleLabel, 1)
        -- 故事内容
        local storyListSize = cc.size(570, 500)
        local storyListView = CListView:create(storyListSize)
        storyListView:setPosition(cc.p(size.width / 2  + 5, size.height / 2 - 7))
        storyListView:setDirection(eScrollViewDirectionVertical)
        view:addChild(storyListView, 5)

        return {
            bg               = bg,  
            view             = view,
            titleLabel       = titleLabel,
            storyListSize    = storyListSize,
            storyListView    = storyListView,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function (sender)
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        
        -- 检查有没有定制背景
        local resPath = nil 
        if utils.isExistent(__(string.format('ui/home/activity/skinCarnival/storyBg/story_bg_%d.png', checkint(storyData.skinId)))) then
            self.viewData.bg:setTexture(__(string.format('ui/home/activity/skinCarnival/storyBg/story_bg_%d.png', checkint(storyData.skinId))))
        end
        self.viewData.titleLabel:setString(storyData.title)
        local storyLabel = display.newLabel(0, 0, {text = storyData.story, fontSize = 22, color = '#A58669', w = 480, noScale = true, ttf = true, font = TTF_TEXT_FONT})
        local layout = CLayout:create(cc.size(self.viewData.storyListSize.width, display.getLabelContentSize(storyLabel).height))
        storyLabel:setPosition(utils.getLocalCenter(layout))
        layout:addChild(storyLabel)
        self.viewData.storyListView:insertNodeAtLast(layout)
        self.viewData.storyListView:reloadData()
    end, __G__TRACKBACK__)
end
--[[
获取viewData
--]]
function ActivitySkinCarnivalStoryPopup:GetViewData()
    return self.viewData
end
return ActivitySkinCarnivalStoryPopup