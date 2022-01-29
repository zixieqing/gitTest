--[[
地图上关卡node
@params table {
	stageId int 关卡id
	lock bool 是否解锁
	no int 关卡在章节上的序号
	star int 星级
	cb function 点击回调
	isCurrentStage bool 是否是当前最新的关卡
}
--]]
local MapStageNode = class('MapStageNode', function ()
	local node = CColorView:create()
	node.name = 'Game.views.map.MapStageNode'
	node:enableNodeEvents()
	return node
end)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
contructor
--]]
function MapStageNode:ctor( ... )
	local args = unpack({...})

	self.stageId = args.stageId
	self.no = args.no
	self.lock = args.lock
	self.star = args.star
	self.isCurrentStage = args.isCurrentStage

	self:InitUI()
end
--[[
init ui
--]]
function MapStageNode:InitUI()

	local stageConf = CommonUtils.GetConfig('quest', 'quest', checkint(self.stageId))

	local function CreateView()

		-- 节点背景图
		local iconMonsterId = string.split(stageConf.icon, ';')[1]
		local iconMonsterConf = CardUtils.GetCardConfig(iconMonsterId)
		local icon = tostring(iconMonsterConf.drawId or iconMonsterId)

		local bg = nil
		local bgPos = nil
		local size = nil
		local scale = 1
		if self.lock or self.isCurrentStage then

			scale = 0.4
			if self.isCurrentStage then
				scale = scale * 1.25
			end

			bg = AssetsUtils.GetCartoonNode(icon)
			bg:setScale(scale)
			size = cc.size(120,120)--因为动态加载的话，一开始是获得不到size的，所以写死一个通用size
			-- size = cc.size(bg:getContentSize().width * scale, bg:getContentSize().height * scale)
			bgPos = cc.p(size.width * 0.5, 0)
			-- self:addChild(display.newLayer(0,0,{size =size, color = cc.r4b(150)}))

			if self.isCurrentStage then
				-- 创建刀叉
				local forkSpine = sp.SkeletonAnimation:create('arts/effects/map_fighting_fork.json', 'arts/effects/map_fighting_fork.atlas', 1)
				forkSpine:update(0)
				forkSpine:addAnimation(0, 'idle', true)
				self:addChild(forkSpine, 21)
				forkSpine:setPosition(cc.p(bgPos.x, size.height + bgPos.y - 10))
			end
		else
			bg = display.newImageView(_res('ui/common/maps_btn_pass_bg.png'))

			local bgSize = bg:getContentSize()
			size = bgSize

			-- 创建关卡怪物头像
			local headIconBg = display.newNSprite(_res('ui/common/maps_btn_pass_head.png'), 0, 0)
            local headIconPath = AssetsUtils.GetCardHeadPath(icon)
			local headIcon = display.newImageView(headIconPath, 0, 0)

			local headClipNode = cc.ClippingNode:create()
			headClipNode:setContentSize(headIconBg:getContentSize())
			headClipNode:setAnchorPoint(cc.p(0.5, 0.5))
			headClipNode:setPosition(cc.p(
				bgSize.width * 0.5,
				bgSize.height * 0.5 + 10))
			bg:addChild(headClipNode)

			headIcon:setScale(0.575)
			headIcon:setPosition(utils.getLocalCenter(headClipNode))
			headClipNode:addChild(headIcon)

			headClipNode:setInverted(false)
			headClipNode:setAlphaThreshold(0.1)
			headIconBg:setPosition(utils.getLocalCenter(headClipNode))
			headClipNode:setStencil(headIconBg)

			-- 创建星级
			if QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) then
				for i = 1, self.star do
					local starIcon = display.newNSprite(_res('ui/map/maps_ico_stars.png'), 0, 0)
					display.commonUIParams(starIcon, {po = cc.p(
						bgSize.width * 0.5 + ((starIcon:getContentSize().width * 0.5 + 10) * (i - 0.5 - self.star * 0.5)),
						(i == (self.star + 1) * 0.5) and bgSize.height + 5 or bgSize.height
					)})
					bg:addChild(starIcon)
				end
			else
				-- 打过的不能复刷的关卡创建标识
				local clearMarkBg = display.newImageView(_res('ui/map/maps_bg_eliminate.png'), bgSize.width * 0.5, bgSize.height * 0.5 + 5)
				bg:addChild(clearMarkBg, 21)
				local clearMarkLabel = display.newLabel(utils.getLocalCenter(clearMarkBg).x, utils.getLocalCenter(clearMarkBg).y,
					{text = __('已消灭'), fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color})
				clearMarkBg:addChild(clearMarkLabel)
			end
		end

		self:setContentSize(size)

		display.commonUIParams(bg, {ap = cc.p(0.5, 0), po = bgPos or cc.p(size.width * 0.5, 0)})
		self:addChild(bg, 5)

		-- 节点阴影
		local shadow = display.newNSprite(_res('ui/common/maps_ico_monster_shadow.png'), size.width * 0.5, 0)
		shadow:setScale(0.5)
		self:addChild(shadow, 1)

		-- 关卡序号
		local stageNoBg = display.newNSprite(_res('ui/map/maps_bg_checkpoint_number.png'), 0, 0)
		display.commonUIParams(stageNoBg, {po = cc.p(
			size.width * 0.5,
			-15 - stageNoBg:getContentSize().height * 0.5
		)})
		self:addChild(stageNoBg, 20)

		local stageNoLabel = display.newLabel(utils.getLocalCenter(stageNoBg).x, utils.getLocalCenter(stageNoBg).y,
			fontWithColor(9,{text = string.format('%s-%s', stageConf.cityId, tostring(self.no)) }))
		stageNoBg:addChild(stageNoLabel)
		self.cityId = stageConf.cityId

        local view = CLayout:create(cc.size(160,140))
        view:setName('CELL_IMAGE')
        view:setAnchorPoint(cc.p(0.5, 0))
        view:setPosition(cc.p(size.width * 0.5, 0))
        self:addChild(view, 20)
		return {
			bg = bg
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)



	------------ 设置回调 ------------
	-- if self.cb then
	-- 	if (not self.lock) and (QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) or self.isCurrentStage) then
	-- 		self:setTouchEnabled(true)
	-- 		self:setOnClickScriptHandler(self.cb)
	-- 	end
	-- end

	self:setTouchEnabled(true)
	display.commonUIParams(self , {cb =function (sender)
		AppFacade.GetInstance():DispatchObservers('MAP_STAGE_CLICK_EVENT', {stageId = self.stageId})
	end })
	------------ 设置回调 ------------

	------------ 设置灰化 ------------
	if self.lock then
		self.viewData.bg:setFilterName(filter.TYPES.GRAY)	
	end
	------------ 设置灰化 ------------

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
为图标添加描边
@params targetNode cc.Node 目标node
--]]
function MapStageNode:EnableImageOutline(targetNode)
	-- local outLineShaderName = 'StrokeOutline'
	-- -- 获取目标shader
	-- local glProgram = cc.GLProgramCache:getInstance():getGLProgram(outLineShaderName)
	-- -- 如果不存在 加载一次
	-- if not glProgram then
	-- 	glProgram = cc.GLProgram:createWithByteArrays(self:GetOutlineShader())
	-- 	cc.GLProgramCache:getInstance():addGLProgram(glProgram, outLineShaderName);  
	-- end
	-- -- 创建shader状态机
	-- local glProgramState = cc.GLProgramState:create(glProgram)
	-- -- 设置传参
	-- local outlineColor = ccc3FromInt('#825e5e')
	-- local outlineSize = 4
	-- local textureSize = targetNode:getContentSize()
	-- local foregroundColor = cc.c3b(128, 128, 128)
	-- local needGrey = self.isCurrentStage and 0 or 1
	-- glProgramState:setUniformFloat("outlineSize", outlineSize)
	-- glProgramState:setUniformVec3("outlineColor", cc.vec3(outlineColor.r / 255.0, outlineColor.g / 255.0, outlineColor.b / 255.0))
	-- glProgramState:setUniformVec2("textureSize", cc.vertex2F(textureSize.width, textureSize.height))
	-- glProgramState:setUniformVec3("foregroundColor", cc.vec3(foregroundColor.r / 255.0, foregroundColor.g / 255.0, foregroundColor.b / 255.0))
	-- ---------------------------------------------------
	-- -- glProgramState:setUniformInt("needGrey", needGrey)
	-- --[[ TIPS : C++ error 这个报错可以无视 重载两个方法 lua binding 那里先判断另一个方法 这个报错是另外那个传参不是string和int产生的 但实际调用的是传参string和int那个方法
	-- error:
    --  cc.GLProgramState:setUniformInt argument #2 is 'string'; 'number' expected.
	-- --]]
	-- ---------------------------------------------------
	
	-- -- 绑定shader状态机
	-- targetNode:setGLProgramState(glProgramState)
end
--[[
获取描边shader
@return _ vert 顶点着色器 _ frag 片段着色器
--]]
function MapStageNode:GetOutlineShader()
	print('***** program here get shader *****')
	local vert = [[
		attribute vec4 a_position;
        attribute vec2 a_texCoord;
        attribute vec4 a_color;

        #ifdef GL_ES
        varying lowp vec4 v_fragmentColor;
        varying mediump vec2 v_texCoord;
        #else
        varying vec4 v_fragmentColor;
        varying vec2 v_texCoord;
        #endif

        void main()
        {
            gl_Position = CC_PMatrix * a_position;
            v_fragmentColor = a_color;
            v_texCoord = a_texCoord;
        }
	]]
	local frag = [[
        varying vec4 v_fragmentColor;  
        varying vec2 v_texCoord;  
        uniform float outlineSize;  
        uniform vec3 outlineColor;  
        uniform vec2 textureSize;  
        uniform vec3 foregroundColor;
        
        int getIsStrokeWithAngelIndex(float cosV, float sinV )  
        {  
            int stroke = 0;  
            float a = texture2D(CC_Texture0, vec2(v_texCoord.x + outlineSize * cosV / textureSize.x, v_texCoord.y + outlineSize * sinV / textureSize.y)).a;  
            if (a >= 0.1)  
            {  
                stroke = 1;  
            }  
        
            return stroke;  
        }  
        
        void main()  
        {  
            vec4 myC = texture2D(CC_Texture0, vec2(v_texCoord.x, v_texCoord.y));  
            //myC.rgb *= foregroundColor;  
            if (myC.a >= 0.5)  
            {  
				gl_FragColor = v_fragmentColor * myC;
                return;  
            }  
            int strokeCount = 0;  
            strokeCount += getIsStrokeWithAngelIndex(1.0, 0.0);  
            strokeCount += getIsStrokeWithAngelIndex(0.866, 0.5);  
            strokeCount += getIsStrokeWithAngelIndex(0.5, 0.866);
            strokeCount += getIsStrokeWithAngelIndex(0.0, 1.0);  
            strokeCount += getIsStrokeWithAngelIndex(-0.5, 0.866);  
            strokeCount += getIsStrokeWithAngelIndex(-0.866, 0.5);  
            strokeCount += getIsStrokeWithAngelIndex(-0.1, 0.0);  
            strokeCount += getIsStrokeWithAngelIndex(-0.866, 0.5);  
            strokeCount += getIsStrokeWithAngelIndex(-0.5, -0.866);  
            strokeCount += getIsStrokeWithAngelIndex(0.0, -1.0);  
            strokeCount += getIsStrokeWithAngelIndex(0.5, -0.866);
            strokeCount += getIsStrokeWithAngelIndex(0.866, -0.5);  
        
            bool stroke = false;  
            if (strokeCount > 0)  
            {  
                stroke = true;  
            }  
        
            if (stroke)  
            {  
                myC.rgb = outlineColor;  
                myC.a = 1.0;  
            }  
        
            gl_FragColor = v_fragmentColor * myC;
        }
	]]
	return vert, frag
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return MapStageNode
