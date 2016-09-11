-- Configure pins which are going to be used
pinEngineC1 = 0 -- GPIO16
pinEngineC2 = 5 -- GPIO14
pinEngine = 6 -- GPIO12
pinServo = 7 -- GPIO13

-- Initial states for pins
valEngineC1 = gpio.LOW
valEngineC2 = gpio.LOW
valEngine = 0;
valServo = 128;

-- Configure pin modes and set initial states
gpio.mode(pinEngineC1, gpio.OUTPUT)
gpio.mode(pinEngineC2, gpio.OUTPUT) 
gpio.write(pinEngineC1, valEngineC1)
gpio.write(pinEngineC2, valEngineC2)

pwm.setup(pinEngine, 100, valEngine) -- index, clock, duty
pwm.setup(pinServo, 100, valServo)
pwm.start(pinEngine)
pwm.start(pinServo)
 
-- Configure AP
cfg={}
cfg.ssid="RCBoat";
wifi.ap.config(cfg)
wifi.setmode(wifi.SOFTAP)

-- Create listener on UDP
sv = net.createServer(net.UDP)

sv:on("receive", 
	function(c, m)
        -- print ("Engine: " .. valEngine .. ", valEngineC1: " .. valEngineC1 .. ", valEngineC2: " .. valEngineC2 .. ", Servo: " .. valServo)
		if string.len(m) == 5 then
			-- Checksum check
			if ((string.byte(m, 1) + string.byte(m, 2) + string.byte(m, 3) + string.byte(m, 4)) % 255 ~= string.byte(m, 5)) then return end
			-- Get new values from the message
			valEngineC1 = (string.byte(m, 4) == 0 and gpio.LOW or gpio.HIGH)
			valEngineC2 = (string.byte(m, 3) == 0 and gpio.LOW or gpio.HIGH)
			valEngine = string.byte(m, 2)
			valServo = string.byte(m, 1)
			-- Appply new values
			gpio.write(pinEngineC1, valEngineC1)
			gpio.write(pinEngineC2, valEngineC2)
			pwm.setduty(pinEngine, valEngine)
			pwm.setduty(pinServo, valServo)
		end
	end)

-- Without any special reason, port 80 is used. It looks nice. That's it.
sv:listen(80)
