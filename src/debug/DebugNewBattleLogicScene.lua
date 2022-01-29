local GameScene = require( 'Frame.GameScene' )
local DebugNewBattleLogicScene = class('DebugNewBattleLogicScene', GameScene)

------------ import ------------
------------ import ------------

------------ define ------------
local RES_DICT = {
	BTN_N = 'ui/common/common_btn_blue_default.png'
}

local MAX_TEAM_MEMBER = 5
------------ define ------------

--[[
constructor
--]]
function DebugNewBattleLogicScene:ctor( ... )
	
	-- 初始化场景
	self:InitScene()

end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化场景
--]]
function DebugNewBattleLogicScene:InitScene()
	self:setBackgroundColor(cc.c4b(0, 128, 128, 255))

	-- debug battle btn
	local debugBtn = self:GetABtn(
		'测试战斗',
		function (sender)
			self:EnterBattle()
		end
	)
	display.commonUIParams(debugBtn, {po = cc.p(display.cx, display.cy)})
	self:addChild(debugBtn)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
进入一场debug的战斗
--]]
function DebugNewBattleLogicScene:EnterBattle()
	local teamData = self:GetADebugTeam()

	local battleConstructor = require('battleEntry.BattleConstructor').new()
	battleConstructor:InitByDebugBattle(
		6,
		teamData,
		{active = {['1'] = 80004}, passive = {}}
	)

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = ''},
		{name = 'BattleMediator', params = battleConstructor}
	)
end
require('battleEntry.BattleGlobalDefines')
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- utils begin --
---------------------------------------------------
--[[
创建一个默认的按钮
@params text string 按钮文字
@params cb function 按钮回调
--]]
function DebugNewBattleLogicScene:GetABtn(text, cb)
	local btn = display.newButton(0, 0, {
		n = _res(RES_DICT.BTN_N),
		cb = cb
	})
	display.commonLabelParams(btn, {
		text = text,
		fontSize = 24,
		color = '#ffffff',
		font = 'font/FZCQJW.TTF',
		ttf = true,
		outline = '#311717'
	})
	return btn
end
---------------------------------------------------
-- utils end --
---------------------------------------------------

---------------------------------------------------
-- data begin --
---------------------------------------------------
--[[
获取一个测试的卡牌阵容
--]]
function DebugNewBattleLogicScene:GetADebugTeam()
	local teamData = {
		[1] = {
			cardId = 200012,
			level = 80,
			breakLevel = 5,
			favorLevel = 1,
			skills = {
				['10023'] = {level = 1},
				['10024'] = {level = 1},
				['90012'] = {level = 1}
			},
			skinId = '250123',
			pets = {}
		},
		[2] = {
			cardId = 200023,
			level = 80,
			breakLevel = 5,
			favorLevel = 1,
			skills = {
				['10045'] = {level = 1},
				['10046'] = {level = 1},
				['90023'] = {level = 1}
			},
			skinId = '250230',
			pets = {}
		},
		-- [1] = {
		-- 	cardId = 200036,
		-- 	level = 80,
		-- 	breakLevel = 5,
		-- 	favorLevel = 1,
		-- 	skills = {
		-- 		['10071'] = {level = 1},
		-- 		['10072'] = {level = 1},
		-- 		['90036'] = {level = 1}
		-- 	},
		-- 	skinId = '250364',
		-- 	pets = {}
		-- },
		-- [4] = {
		-- 	cardId = 200004,
		-- 	level = 80,
		-- 	breakLevel = 5,
		-- 	favorLevel = 1,
		-- 	skills = {
		-- 		['10007'] = {level = 1},
		-- 		['10008'] = {level = 1},
		-- 		['90004'] = {level = 1}
		-- 	},
		-- 	skinId = '250040',
		-- 	pets = {}
		-- }
	}

	return teamData
end
---------------------------------------------------
-- data end --
---------------------------------------------------

-- local looptime = 2000000

-- print('\n\n============= here test key is int =============\n')

-- local targettable = {
-- 	[1] = {cardId = 1},
-- 	[2] = {cardId = 2},
-- 	[3] = {cardId = 3},
-- 	[4] = {cardId = 4},
-- 	[5] = {cardId = nil}
-- }

-- local itor = 0

-- local timer = os.clock()
-- local timer_ = os.clock()

-- local deltaTimeInt = nil
-- local deltaTimeStr = nil

-- print('start ! -> ', timer)

-- for _ = 1, looptime do
-- 	for i = 1, MAX_TEAM_MEMBER do
-- 		local cardData = targettable[i]
-- 		if nil ~= cardData and nil ~= cardData.cardId then
-- 			itor = itor + 1
-- 		end
-- 	end
-- end

-- timer_ = os.clock()
-- deltaTimeInt = timer_ - timer
-- print('over ! -> ', timer_)
-- print('delta time is : ', deltaTimeInt, 'valid cards amount : ', itor)

-- print('\n\n============= here test key is int =============\n')




-- print('\n\n============= here test key is str =============\n')

-- targettable = {
-- 	['1'] = {cardId = 1},
-- 	['2'] = {cardId = 2},
-- 	['3'] = {cardId = 3},
-- 	['4'] = {cardId = 4},
-- 	['5'] = {cardId = nil}
-- }

-- itor = 0

-- timer = os.clock()
-- timer_ = os.clock()

-- print('start ! -> ', timer)

-- for _ = 1, looptime do
-- 	for i = 1, MAX_TEAM_MEMBER do
-- 		local cardData = targettable[tostring(i)]
-- 		if nil ~= cardData and nil ~= cardData.cardId then
-- 			itor = itor + 1
-- 		end
-- 	end
-- end

-- timer_ = os.clock()
-- deltaTimeStr = timer_ - timer
-- print('over ! -> ', timer_)
-- print('delta time is : ', deltaTimeStr, 'valid cards amount : ', itor)

-- print('\n\n============= here test key is str =============\n')
-- print('efficiency ratio : ', deltaTimeInt / deltaTimeStr, deltaTimeStr / deltaTimeInt)

-- local t = {1, 2, 3, nil, 5, nil, 7, nil, nil, 10}





return DebugNewBattleLogicScene
