local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local AppendDescrCommand = Command:New()

AppendDescrCommand.NAME = "AppendDescrCommand"

AppendDescrCommand.TYPE_DEFINE = {
    mood_red   = {viewFuncName = 'createRedMoodView'},
    mood_blue  = {viewFuncName = 'createBlueMoodView'},
    mood_paper = {viewFuncName = 'createPaperMoodView'},
}


function AppendDescrCommand:New(type, descr)
    local this = {}
    setmetatable( this, {__index = AppendDescrCommand} )
    this.type        = type
    this.descr       = tostring(descr)
    this.inAction    = true
    this.isDelayMode = tostring(type) ~= 'mood_paper'
    return this
end


function AppendDescrCommand:Execute()
    local director = Director.GetInstance('Director')
    local stage = director:GetStage()
    
    -- clean old append descr layer
    if stage:getChildByTag(Director.ZorderTAG.Z_APPEND_DESCR_LAYER) then
        stage:removeChildByTag(Director.ZorderTAG.Z_APPEND_DESCR_LAYER)
    end
    director.delayDescrData = nil

    local typeDefine = AppendDescrCommand.TYPE_DEFINE[tostring(self.type)]
    if typeDefine then
        if typeDefine.viewFuncName and self[typeDefine.viewFuncName] then
            local viewData = handler(self, self[typeDefine.viewFuncName])()
            stage:addChild(viewData.view, Director.ZorderTAG.Z_APPEND_DESCR_LAYER, Director.ZorderTAG.Z_APPEND_DESCR_LAYER)
            
            -- check is delay type
            if self.isDelayMode then
                self.inAction = false
                viewData.view:setVisible(false)
                director.delayDescrData = viewData
            else
                viewData.view:setOpacity(0)
                viewData.view:runAction(cc.Sequence:create(
                    cc.FadeIn:create(0.2),
                    cc.DelayTime:create(0.1),
                    cc.CallFunc:create(function()
                        self.inAction = false
                    end)
                ))
            end
        end
    end
end


function AppendDescrCommand:CanMoveNext()
    return self.inAction == false
end


function AppendDescrCommand:ExecuteAfter()
	local director = Director.GetInstance('Director')
	local stage = director:GetStage()
	if stage and not self.isDelayMode then
		local node = stage:getChildByTag(Director.ZorderTAG.Z_APPEND_DESCR_LAYER)
		if node then
			node:runAction(cc.Sequence:create(
                cc.FadeOut:create(0.2),
                cc.CallFunc:create(function()
                    director:MoveNext()
                end),
                cc.RemoveSelf:create()
            ))
		end
	end
end


-------------------------------------------------
-- mood view

function AppendDescrCommand:createRedMoodView()
    return self:createMoodView_(1)
end

function AppendDescrCommand:createBlueMoodView()
    return self:createMoodView_(2)
end

function AppendDescrCommand:createMoodView_(moodType)
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150)}))

    local isRedMoodType = moodType == 2
    local moodFramePath = isRedMoodType and _res('arts/stage/ui/club/clue_screen_blue.png') or _res('arts/stage/ui/club/clue_screen_red.png')
    local moodDecorPath = isRedMoodType and _res('arts/stage/ui/club/clue_screen_blue_left.png') or _res('arts/stage/ui/club/clue_screen_red_left.png')

    -- moodFrame
    local moodFrame = display.newImageView(moodFramePath, size.width/2, size.height/2 + 50)
    view:addChild(moodFrame)
    
    -- moodLabel
    -- local moodLabel = display.newLayer(moodFrame:getPositionX() + 80, moodFrame:getPositionY(), {color = cc.r4b(150), size = cc.size(280,260), ap = display.CENTER})
    local moodLabel = display.newLabel(moodFrame:getPositionX() + 80, moodFrame:getPositionY(), {fontSize = 32, color = '#dcFFFF', text = self.descr, w = 280, hAlign = display.TAC})
    view:addChild(moodLabel)
    
    -- scrollView
    local scrollSize = cc.size(140, 250)
    local scrollView = CScrollView:create(scrollSize)
    scrollView:setPosition(cc.p(moodFrame:getPositionX() - 180, moodFrame:getPositionY() - 25))
    scrollView:setDirection(eScrollViewDirectionVertical)
    scrollView:setAnchorPoint(display.CENTER)
    scrollView:setContainerSize(scrollSize)
    scrollView:setDragable(false)
    view:addChild(scrollView)


    local moodDescrLayer = display.newLayer()
    scrollView:getContainer():addChild(moodDescrLayer)

    local moodDescrImg1 = display.newImageView(moodDecorPath, 0, 0, {ap = display.LEFT_BOTTOM})
    local moodDescrSize = moodDescrImg1:getContentSize()
    local moodDescrImg2 = display.newImageView(moodDecorPath, 0, moodDescrSize.height, {ap = display.LEFT_BOTTOM})
    moodDescrLayer:addChild(moodDescrImg1)
    moodDescrLayer:addChild(moodDescrImg2)
    moodDescrLayer:setContentSize(cc.size(moodDescrSize.width, moodDescrSize.height*2))

    -- auto run descr
    view:scheduleUpdateWithPriorityLua(function(dt)
        local offsetPos = scrollView:getContentOffset()
        if offsetPos.y < -moodDescrSize.height then
            offsetPos.y = offsetPos.y + moodDescrSize.height
        end
        scrollView:setContentOffset(cc.p(0, offsetPos.y - 2))
    end, 0)

    return {
        view = view,
    }
end


function AppendDescrCommand:createPaperMoodView()
    local view = display.newLayer()
    local size = view:getContentSize()
    -- view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150)}))

    local moodFramePath = _res('arts/stage/ui/club/dialogue_bg_3.png')

    -- moodFrame
    local moodFrame = display.newImageView(moodFramePath, size.width/2, size.height/2)
    local frameSize = moodFrame:getContentSize()
    view:addChild(moodFrame)
    
    -- moodLabel
    local labelSize = cc.size(frameSize.width - 90, frameSize.height - 100)
    local labelPos  = cc.p(moodFrame:getPositionX() - labelSize.width/2, moodFrame:getPositionY() + labelSize.height/2)
    local moodLabel = display.newLabel(labelPos.x, labelPos.y, fontWithColor(6, {ap = display.LEFT_TOP, text = self.descr, w = labelSize.width, h = labelSize.height, hAlign = display.TAL}))
    view:addChild(moodLabel)
    
    return {
        view = view,
    }
end


-------------------------------------------------


return AppendDescrCommand