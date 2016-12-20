print("Boot...")

config = require("config")
update = require("update")
app = require("app")

env = {
	conf = config,
	broker = mqtt.Client(wifi.ap.getmac(), 120, config.MQTT.USER, config.MQTT.PWD)
}

if app ~= false then
	pcall( function() app.init(env) end )
end

function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")

		mqtt_init()
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
    wifi.setmode(wifi.STATION);
	  wifi.sta.getap(findAP)
end

function mqtt_init()
	env.broker:on("message",
		function(conn, topic, data)
			if data ~= nil then
				if update.onEvent(topic, data) then return end
				if app ~= false then
					pcall( function() app.onEvent(topic, data) end )
				end
			end
		end)

	env.broker:connect(config.MQTT.HOST, config.MQTT.PORT, 0, 1,
		function(con)
		    update.subscribe(env.broker)
				if app ~= false then
					pcall( function() app.subscribe(env.broker) end )
				end
		end)
end

wifi_start()
