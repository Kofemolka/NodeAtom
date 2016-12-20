local module = {}

function module.init(env)
	print("App start")

	tmr.alarm(2, 5000, tmr.ALARM_AUTO,
		function()
			pcall( function() env.broker:publish("heap",node.heap(),0,0, nil) end )		
		end)

	gpio.mode(4,gpio.OUTPUT)
end

function module.subscribe(broker)
	broker:subscribe("led",0, function(conn)
			print("Successfully subscribed to LED topic")
			end)
end

function module.onEvent(topic, data)
	if topic == "led" then
		if data == "1" then
			gpio.write(4,gpio.HIGH)
		else
			gpio.write(4,gpio.LOW)
		end
	end
end

function flashLed()
	local ledOn = false
	gpio.mode(4,gpio.OUTPUT)

	tmr.alarm(0, 500, 1, function()
		ledOn = not ledOn
		if ledOn then
			gpio.write(4,gpio.HIGH)
		else
			gpio.write(4,gpio.LOW)
		end
	end)
end

return module
