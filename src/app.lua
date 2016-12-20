local module = {}

local subTopic = "/led"
local pubTopic = "/heap"

function module.init(env)
	print("App start")

	tmr.alarm(2, 5000, tmr.ALARM_AUTO,
		function()
			pcall( function() env.broker:publish(env.conf.MQTT.ROOT .. pubTopic,node.heap(),0,0, nil) end )
		end)

	gpio.mode(4,gpio.OUTPUT)
end

function module.subscribe(env)
	env.broker:subscribe(env.conf.MQTT.ROOT .. subTopic,0, nil)
end

function module.onEvent(topic, data)
	if topic == subTopic then
		if data == "1" then
			gpio.write(4,gpio.HIGH)
		else
			gpio.write(4,gpio.LOW)
		end
	end
end

return module
