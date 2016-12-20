print("Boot...")

config = require("config")
update = require("update")
pcall( function() app = require("app") end )

env = {
	conf = config,
	broker = mqtt.Client(config.MQTT.ROOT, 120, config.MQTT.USER, config.MQTT.PWD)
}

local resetTopic = "/reset"

pcall( function() app.init(env) end )

function wifiWatchDog()
	tmr.alarm(1, 30000, tmr.ALARM_AUTO,
		function()
			if wifi.sta.getip()== nil then
				wifi_start()
			end
		end)
end

function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("MAC: " .. wifi.ap.getmac())
    print("IP: "..wifi.sta.getip())
    
		mqtt_init()
		wifiWatchDog()
  end
end

function findAP(t)
	for ssid,v in pairs(t) do
		if config.SSID[ssid] ~= nil then
			wifi.sta.config(ssid,config.SSID[ssid])
			print("Connecting to " .. ssid .. " ...")
	    wifi.sta.connect()
			tmr.alarm(1, 2500, 1, wifi_wait_ip)
			return
		end
	end

	tmr.alarm(1, 5000, 1, wifi_start)
end

function wifi_start()
	print("WiFi Setup...")
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(findAP)
end

local mqttInited = false
function mqtt_init()
	if mqttInited then return end

	env.broker:on("message",
		function(conn, topic, data)
			if data ~= nil then
				local subTopic = string.sub(topic, string.len(config.MQTT.ROOT)+1)
				if subTopic == resetTopic then node.restart() end
				if update.onEvent(subTopic, data) then return end

				pcall( function() app.onEvent(subTopic, data) end )
			end
		end)

	env.broker:connect(config.MQTT.HOST, config.MQTT.PORT, 0, 1,
		function(con)
			  print("MQTT connect...")
				env.broker:subscribe(env.conf.MQTT.ROOT .. resetTopic,0, nil)
		    update.subscribe(env)
				pcall( function() app.subscribe(env) end )
		end)

	mqttInited = true
end

wifi_start()
