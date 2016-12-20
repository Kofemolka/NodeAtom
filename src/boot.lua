print("Boot...")

local devTopic = "/dev/"
local resetTopic = devTopic .. "reset"
local heapTopic = devTopic .. "heap"
local lwtTopic = devTopic .. "lwt"

config = require("config")
update = require("update")
pcall( function() app = require("app") end )

env = {
	conf = config,
	broker = mqtt.Client(config.MQTT.ROOT, 120, config.MQTT.USER, config.MQTT.PWD)
}

pcall( function() app.init(env) end )

function wifiWatchDog()
	tmr.alarm(1, 30000, tmr.ALARM_AUTO,
		function()
			if wifi.sta.getip()== nil then
				wifiConnect()
			end
		end)
end

function wifiWaitIP()
  if wifi.sta.getip()== nil then
    print("Waiting for IP ...")
  else
    tmr.stop(1)
    print("MAC: " .. wifi.ap.getmac())
    print("IP: ".. wifi.sta.getip())

		mqttInit()
		wifiWatchDog()
  end
end

function findAP(t)
	for ssid,v in pairs(t) do
		if config.SSID[ssid] ~= nil then
			wifi.sta.config(ssid,config.SSID[ssid])
			print("Connecting to " .. ssid .. " ...")
	    wifi.sta.connect()
			tmr.alarm(1, 2500, tmr.ALARM_AUTO, wifiWaitIP)
			return
		end
	end

	tmr.alarm(1, 5000, tmr.ALARM_AUTO, wifiConnect)
end

function wifiConnect()
	print("WiFi Connect ...")
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(findAP)
end

local once = false
function mqttInit()
	env.broker:lwt(env.conf.MQTT.ROOT .. lwtTopic, "offline", 1, 1)
	env.broker:on("message",
		function(conn, topic, data)
			if data ~= nil then
				local subTopic = string.sub(topic, string.len(config.MQTT.ROOT)+1)
				if subTopic == resetTopic then node.restart() end
				if update.onEvent(subTopic, data) then return end

				pcall( function() app.onEvent(subTopic, data) end )
			end
		end)

env.broker:on("connect",
	function(con)
		print("MQTT connect...")
		env.broker:subscribe(env.conf.MQTT.ROOT .. resetTopic,0, nil)
		update.subscribe(env)
		pcall( function() app.subscribe(env) end )

		tmr.alarm(2, 60000, tmr.ALARM_AUTO,
			function()
				pcall( function() env.broker:publish(env.conf.MQTT.ROOT .. heapTopic,node.heap(),0,0, nil) end )
			end)
	end)

	if not once then
		env.broker:connect(config.MQTT.HOST, config.MQTT.PORT, 0, 1, nil)

		once = true
	end
end

wifiConnect()
