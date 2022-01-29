local SliceBackground = class('SliceBackground', function ()
	local node = CLayout:create(cc.size(1624, 1002))
	node.name = 'common.SliceBackground'
	node:enableNodeEvents()
	return node
end)

local textureCache = cc.Director:getInstance():getTextureCache()
--[[
--切片背景的拉装的逻辑
--params = {
-- size = "背景的contentSize"
-- pic_path_name = "路径名"
-- count = 总数量 --总数是几个
-- cols = 行数量(rows) 一排的数量是几个
--}
--]]
function SliceBackground:ctor(...)
    local args = unpack({...})
    self.isAction = false
    self.isMoving = false
    self.images = {}
    self.async = true
    if args.async ~= nil then self.async = checkbool(args.async) end
    local count = checkint(args.count) --总籹
    local cols = checkint(args.cols) --列
    local size = args.size
    local offsetX = size.width / cols
    local offsetY = size.height / cols
    if count > 1 then
        for i=1,count do
            local spanNo = math.floor( (i + cols -1 ) / cols) --
            local spanX = math.floor( (i + cols - 1) % cols ) --行间距
            local x = spanX * offsetX
            local y = size.height - (spanNo - 1) * offsetY
            --[[
            if self.async then
                local imagePath = _res(string.format( "%s_%02d.png",args.pic_path_name, i))
                table.insert(self.images, imagePath)
                textureCache:addImageAsync(imagePath, function(texture)
                    local image = display.newImageView(imagePath,0,0)
                    display.commonUIParams(image, {ap = display.LEFT_TOP, po = cc.p(x,y)})
                    self:addChild(image)
                end)
            else
            --]]
            local image = display.newImageView(_res(string.format( "%s_%02d.png",args.pic_path_name, i)),0,0)
            display.commonUIParams(image, {ap = display.LEFT_TOP, po = cc.p(x,y)})
            self:addChild(image)
        end
    else
        local image = display.newImageView(_res(string.format( "%s",args.pic_path_name)),0,0)
        display.commonUIParams(image, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
        self:addChild(image)
    end
    if args.slidout then
        --主界面拖动出来的逻辑
        local touchView = CColorView:create(cc.c4b(100,100,100,0))
        touchView:setContentSize(size)
        display.commonUIParams(touchView, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        -- touchView:setTouchEnabled(true)
        self:addChild(touchView)
    end
end


function SliceBackground:onCleanup()
    --清除资源
    if self.async then
        -- if #self.images > 0 then
            -- for name,val in pairs(self.images) do
                -- textureCache:unbindImageAsync(val)
            -- end
        -- end
    end
    -- textureCache:unbindAllImageAsync()
end

return SliceBackground
