local SimpleCommand = mvc.SimpleCommand

local ActivityCommand = class("ActivityCommand", SimpleCommand)
function ActivityCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function ActivityCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Activity_Home then
		httpManager:Post("Activity/home", SIGNALNAMES.Activity_Home_Callback)
	elseif name == COMMANDS.COMMAND_Activity_Newbie15Day then
		httpManager:Post("Activity/newbie15DayReward", SIGNALNAMES.Activity_Newbie15Day_Callback)
	elseif name == COMMANDS.COMMAND_Activity_Draw_Newbie15Day then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawNewbie15DayReward", SIGNALNAMES.Activity_Draw_Newbie15Day_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_monthlyLogin then
		httpManager:Post("Activity/monthlyLoginReward", SIGNALNAMES.Activity_MonthlyLogin_Callback)
	elseif name == COMMANDS.COMMAND_Activity_Draw_monthlyLogin then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawMonthlyLoginReward", SIGNALNAMES.Activity_Draw_MonthlyLogin_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_monthlyLoginWheel then
		local data = signal:GetBody()
		httpManager:Post("Activity/monthlyLoginWheelReward", SIGNALNAMES.Activity_MonthlyLoginWheel_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_monthlyLoginWheel then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawMonthlyLoginWheelReward", SIGNALNAMES.Activity_Draw_MonthlyLoginWheel_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_exchangeList then
		local data = signal:GetBody()
		httpManager:Post("Activity/exchangeList", SIGNALNAMES.Activity_Draw_ExchangeList_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_exchange then
		local data = signal:GetBody()
		httpManager:Post("Activity/exchange", SIGNALNAMES.Activity_Draw_Exchange_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_loveBento then
		httpManager:Post("Activity/receiveLoveBento", SIGNALNAMES.Activity_Draw_LoveBento_Callback)
	elseif name == COMMANDS.COMMAND_Activity_Draw_serverTask then
		local data = signal:GetBody()
		httpManager:Post("Activity/serverTask", SIGNALNAMES.Activity_Draw_serverTask_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_drawServerTask then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawServerTask", SIGNALNAMES.Activity_Draw_drawServerTask_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_ChargeWheel then
		local data = signal:GetBody()
		httpManager:Post("Activity/bigWheel", SIGNALNAMES.Activity_ChargeWheel_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_ChargeWheel then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawBigWheel", SIGNALNAMES.Activity_Draw_ChargeWheel_Callback, data)	
	elseif name == COMMANDS.COMMAND_Activity_Draw_Wheel_TimesRewards then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawBigWheelTimesRewards", SIGNALNAMES.Activity_Draw_Wheel_Timesrewards_Callback, data)	
	elseif name == COMMANDS.COMMAND_Activity_CyclicTasks then
		local data = signal:GetBody()
		httpManager:Post("Activity/circleTask", SIGNALNAMES.Activity_CyclicTasks_Callback, data)		
	elseif name == COMMANDS.COMMAND_Activity_Buy_CyclicTasks then
		local data = signal:GetBody()
		httpManager:Post("Activity/buyCircleTaskDoneTimes", SIGNALNAMES.Activity_Buy_CyclicTasks_Callback, data)	
	elseif name == COMMANDS.COMMAND_Activity_Draw_CyclicTasks then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawCircleTask", SIGNALNAMES.Activity_Draw_CyclicTasks_Callback, data)	
	elseif name == COMMANDS.COMMAND_Activity_TakeawayPoint then
		local data = signal:GetBody()
		httpManager:Post("Activity/takeawayPoint", SIGNALNAMES.Activity_TakeawayPoint_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_TaskBinggoList then
		local data = signal:GetBody()
		httpManager:Post("Activity/taskBinggoList", SIGNALNAMES.Activity_TaskBinggoList_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_BinggoTask then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawBinggoTask", SIGNALNAMES.Activity_DrawBinggoTask_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_BinggoOpen then
		local data = signal:GetBody()
		httpManager:Post("Activity/binggoOpen", SIGNALNAMES.Activity_BinggoOpen_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_ChestExchangeList then
		local data = signal:GetBody()
		httpManager:Post("Activity/festivalExchangeList", SIGNALNAMES.Activity_Chest_ExchangeList_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_ChestExchange then
		local data = signal:GetBody()
		httpManager:Post("Activity/festivalExchange", SIGNALNAMES.Activity_Chest_Exchange_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_LoginReward then	
		local data = signal:GetBody()
		httpManager:Post("Activity/loginReward", SIGNALNAMES.Activity_Login_Reward_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_LoginReward then	
		local data = signal:GetBody()
		httpManager:Post("Activity/drawLoginReward", SIGNALNAMES.Activity_Draw_Login_Reward_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_AccumulativePay then
		local data = signal:GetBody()
		httpManager:Post("Activity/accumulativePay", SIGNALNAMES.Activity_AccumulativePay_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_AccumulativePay_Home then
		local data = signal:GetBody()
		httpManager:Post("Activity/accumulativePay", SIGNALNAMES.Activity_AccumulativePay_Home_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Draw_AccumulativePay then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawAccumulativePay", SIGNALNAMES.Activity_Draw_AccumulativePay_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Quest_Home then
		local data = signal:GetBody()
		httpManager:Post("ActivityQuest/home", SIGNALNAMES.Activity_Quest_Home_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Quest_Exchange then
		local data = signal:GetBody()
		httpManager:Post("ActivityQuest/exchange", SIGNALNAMES.Activity_Quest_Exchange_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_AccumulativeConsume then
		local data = signal:GetBody()
		httpManager:Post("Activity/accumulativeConsume", SIGNALNAMES.Activity_AccumulativeConsume_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_AccumulativeConsume_Draw then
		local data = signal:GetBody()
		httpManager:Post("Activity/drawAccumulativeConsume", SIGNALNAMES.Activity_Draw_AccumulativeConsume_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Questionnaire then
		local data = signal:GetBody()
		httpManager:Post("Activity/questionnaire", SIGNALNAMES.Activity_Questionnaire_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Balloon_Home then
		local data = signal:GetBody()
		httpManager:Post("Activity/ranBubbleList", SIGNALNAMES.Activity_Balloon_Home_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_SinglePay_Home then
		local data = signal:GetBody()
		httpManager:Post("Activity/singlePay", SIGNALNAMES.Activity_SinglePay_Home_Callback, data)
	elseif name == COMMANDS.COMMAND_Activity_Permanent_Single_Pay then 
		httpManager:Post("Activity/permanentSinglePay", SIGNALNAMES.Activity_Permanent_Single_Pay_Callback)
	elseif name == COMMANDS.COMMAND_Activity_Web_Home then
		local data = signal:GetBody()
		httpManager:Post("Activity/marketH5", SIGNALNAMES.Activity_Web_Home_Callback, data)
	end
end

return ActivityCommand