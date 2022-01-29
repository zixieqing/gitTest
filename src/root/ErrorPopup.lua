--[[ 错误弹窗 ]]
local windowSize = cc.Director:getInstance():getWinSize()
local screenSize = {width = windowSize.width, height = windowSize.height}
local ErrorPopup = class('ErrorPopup', function()
	local layer = CLayout:create()
	layer:setName('ErrorPopup')
	layer:setPosition(cc.p(0,0))
	layer:setAnchorPoint(cc.p(0,0))
	layer:setContentSize(screenSize)
	return layer
end)


-------------------------------------------------
-- life cycle

function ErrorPopup:ctor()
	local errorMsg = "Today's log is empty..."

	-- background
	local background = CColorView:create(cc.c4b(0, 80, 20, 200))
	background:setTouchEnabled(true)
	background:setPosition(cc.p(0,0))
	background:setAnchorPoint(cc.p(0,0))
	background:setContentSize(screenSize)
	self:addChild(background)

	-- create view
	self.viewData_ = ErrorPopup.CreateView()
	self:addChild(self.viewData_.view)

	self.viewData_.closeBtn:setOnClickScriptHandler(function(sender)
		self:close()
	end)

	-- set error message
	local READ_MAX   = 1024 * 30
	local fileUtils  = cc.FileUtils:getInstance()
    local logDirpath = fileUtils:getWritablePath() .. 'log/'
    if fileUtils:isDirectoryExist(logDirpath) then
		local todayStr = os.date('%Y-%m-%d')
		local filename = string.format('%seater-%s.log', logDirpath, todayStr)
		if fileUtils:isFileExist(filename) then
            local fsize = io.filesize(filename)
            local file  = io.open(filename, 'r')
            if file then
                if fsize > READ_MAX then
                    local current = file:seek()
                    file:seek('cur', (fsize - READ_MAX))
                    errorMsg = file:read('*a')
                    file:seek('set', current)
                else
                    errorMsg = file:read('*a')
                end
                io.close(file)
            end
		end
    end
	self:setIntroText(errorMsg)
end


function ErrorPopup.CreateView()
	local view = CLayout:create()
	view:setPosition(cc.p(0,0))
	view:setAnchorPoint(cc.p(0,0))
	view:setContentSize(screenSize)

    -- scroll view
	local scrollView = cc.ScrollView:create()
	scrollView:setViewSize(cc.size(screenSize.width - 160, screenSize.height - 80))
    scrollView:setPosition(cc.p(80, 70))
	scrollView:setDirection(1)  -- Horizontal = 0, Vertical = 1
	view:addChild(scrollView)

	-- message label
	local msgLabel = cc.Label:create()
	msgLabel:setLineBreakWithoutSpace(true)
	msgLabel:setWidth(screenSize.width)
	msgLabel:setAnchorPoint(cc.p(0,0))
	msgLabel:setSystemFontName('Menlo')
	msgLabel:setSystemFontSize(20)
    scrollView:setContainer(msgLabel)

	-- close button
	local closeSize = cc.size(800, 50)
	local closeBtn  = CColorView:create(cc.c4b(80, 20, 0, 150))
	closeBtn:setTouchEnabled(true)
	closeBtn:setContentSize(closeSize)
    closeBtn:setPosition(cc.p(screenSize.width/2, 35))
	view:addChild(closeBtn)

    closeBtn:runAction(cc.RepeatForever:create(cc.Sequence:create(
		cc.FadeOut:create(1),
		cc.FadeIn:create(1)
    )))
	
	local tipsLabel = cc.Label:createWithSystemFont('>>> close <<<', 'Menlo', 28)
	tipsLabel:setPosition(cc.p(closeSize.width/2, closeSize.height/2))
	tipsLabel:setColor(cc.c3b(255,200,200))
	closeBtn:addChild(tipsLabel)

	return {
		view       = view,
		scrollView = scrollView,
		msgLabel   = msgLabel,
		closeBtn   = closeBtn,
	}
end


-------------------------------------------------
-- public method

function ErrorPopup:close()
	self:runAction(cc.RemoveSelf:create())
end


function ErrorPopup:setIntroText(text)
	if not self.viewData_ then return end

	local introText = self.viewData_.msgLabel
	introText:setString(text or '')

    -- scroll to top
	local scrollView = self.viewData_.scrollView
	local scrollTop  = scrollView:getViewSize().height - scrollView:getContainer():getContentSize().height
	scrollView:setContentOffset(cc.p(0, scrollTop))
end


-------------------------------------------------
-- handler


return ErrorPopup
