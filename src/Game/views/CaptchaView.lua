--[[
验证码的ui
--]]
local CaptchaView = class('CaptchaView', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.TitlePanelBg'
	node:enableNodeEvents()
	return node
end)


function CaptchaView:ctor( ... )
	--创建页面
    self.cb = nil
    local arg = unpack({...})
    if arg.cb then
        self.cb = arg.cb
    end
	local view = require("common.TitlePanelBg").new({ title = __('答题'), type = 11})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)

    local function CreateTaskView( ... )
		local size = cc.size(866,578)
		local cview = CLayout:create(size)

        --添加一个标题描述
        local description = display.newLabel(size.width * 0.5,550,fontWithColor(2,{ap = display.CENTER_TOP, text = __('长时间玩游戏，请答题'),fontSize = 20, color = 'a9764a'}))
        cview:addChild(description,1)

        local questionBg = display.newImageView(_res('root/quenstion_titleframe'), size.width * 0.5, 482,{ap = display.CENTER_TOP})
        cview:addChild(questionBg)

        local questionLabel = display.newLabel(questionBg:getContentSize().width * 0.5,questionBg:getContentSize().height * 0.5,fontWithColor(2,{ap = display.CENTER, text = '题目：1 + 2 = ？',fontSize = 28, color = '5c5c5c'}))
        questionBg:addChild(questionLabel)

        -- 12格子 8个坚排
        local touchAreaView = CLayout:create(cc.size(720,320))
        display.commonUIParams(touchAreaView, {ap = display.CENTER_TOP, po = cc.p(size.width * 0.5, 370)})
        -- touchAreaView:setBackgroundColor(cc.c4b(100,100,100,100))
        cview:addChild(touchAreaView)

        --[[
        local touchAreaImage = display.newImageView(_res('root/quenstion_answerbog_bg'),442,68,{ap = display.LEFT_BOTTOM})
        cview:addChild(touchAreaImage)
        local adescription = display.newLabel(194, 140,fontWithColor(2,{ap = display.CENTER_TOP, text = __('请将正确答案拖到此框内'),fontSize = 20, color = 'ffffff'}))
        touchAreaImage:addChild(adescription)
        --4个答案

        local buttons = {}
        for i=1,4 do
            local x,y = 222, 344 - (i - 1) * 72
            local button = display.newButton(x, y, {ap = display.CENTER_TOP,
                n = _res('root/quenstion_answer unselected'),
                s = _res('root/quenstion_answer unselected'),
                -- s = _res('root/quenstion_answer selected')
            })
            cview:addChild(button)
            button:setOnClickScriptHandler(handler(self, self.ButtonAction))
            table.insert(buttons, button)
        end
        --]]
		view:AddContentViewNoCloseLabel(cview)
		return {
			cview 		= cview,
            questionLabel = questionLabel,
            touchAreaView = touchAreaView,
		}
	end
	xTry(function()
		self.viewData_ = CreateTaskView()
        --[[
        local sharedFileUtils = cc.FileUtils:getInstance()
        local writablePath = sharedFileUtils:getWritablePath()

        -- 90 * 8 80 * 4
        --总数量是96个
        local positions = {}
        for i=1, 32 do
            table.insert(positions, i)
        end
        for i=1,4 do
            math.newrandomseed()
            local pos = math.random(#positions)
            local loc = table.remove(positions,pos)
            local spanX = (loc % 8)
            if spanX == 0 then spanX = 8 end
            local x = (spanX - 1) * 90 + 45
            local spanY = math.floor((loc + 7)/ 8)
            local y = (spanY - 1) * 80 + 40
            -- cclog('---------->>>', loc, spanX, spanY)
            local filePath = writablePath .. string.format('answer_%d.png',i)
            local texture = display.loadImage(filePath)
            if texture then
                local anwserImageView = display.newImageView(_res('ui/common/story_tranparent_bg'),x, y, {
                        scale9 = true, size = cc.size(90, 60)
                    })
                anwserImageView:setTexture(texture)
                self.viewData_.touchAreaView:addChild(anwserImageView,2)
            end
        end

        --]]
	end, __G__TRACKBACK__)
end

function CaptchaView:ButtonAction(sender)
    PlayAudioByClickNormal()
    --执行请求的逻辑
    local answerId = sender:getUserTag()
    AppFacade.GetInstance():DispatchSignal(POST.CAPTCHA_ANSWER.cmdName, {answerId = answerId})
end

function CaptchaView:ReloadData(data)
    self.viewData_.touchAreaView:removeAllChildren()
    local question = data.question
    self.viewData_.questionLabel:setString(question)
    local options = data.options
    local sharedFileUtils = cc.FileUtils:getInstance()
    local writablePath = sharedFileUtils:getWritablePath()
    local positions = {}
    for i=1, 32 do
        table.insert(positions, i)
    end
    for i,val in ipairs(options) do
        local filePath = writablePath .. string.format('answer_%d.png',i)
        local data = crypto.decodeBase64(val.data)
        if data then
            local isOk = io.writefile(filePath, data)
            if isOk then
                --写入成功后添加到按钮上去
                display.removeImage(filePath)
                local texture = display.loadImage(filePath)
                if texture then
                    math.newrandomseed()
                    local pos = math.random(#positions)
                    local loc = table.remove(positions,pos)
                    local spanX = (loc % 8)
                    if spanX == 0 then spanX = 8 end
                    local x = (spanX - 1) * 90 + 45
                    local spanY = math.floor((loc + 7)/ 8)
                    local y = (spanY - 1) * 80 + 40

                    local anwserImageView = display.newImageView(_res('ui/common/story_tranparent_bg'),x, y, {
                            scale9 = true, size = cc.size(90, 60)
                        })
                    anwserImageView:setTexture(texture)
                    anwserImageView:setTouchEnabled(true)
                    anwserImageView:setUserTag(checkint(val.answerId))
                    anwserImageView:setOnClickScriptHandler(handler(self, self.ButtonAction))
                    self.viewData_.touchAreaView:addChild(anwserImageView,2)
                end
            end
        end
    end
end


function CaptchaView:onEnter()

end

function CaptchaView:onExit()

end

return CaptchaView
