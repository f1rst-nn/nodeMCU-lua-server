led1 = 3
pin = 4
gpio.mode(led1, gpio.OUTPUT)


ow.setup(pin)

counter=0
lasttemp=-999

function bxor(a,b)
   local r = 0
   for i = 0, 31 do
	  if ( a % 2 + b % 2 == 1 ) then
		 r = r + 2^i
	  end
	  a = a / 2
	  b = b / 2
   end
   return r
end

--- Get temperature from DS18B20 
function getTemp()
	  addr = ow.reset_search(pin)
	  repeat
		tmr.wdclr()
	  
	  if (addr ~= nil) then
		crc = ow.crc8(string.sub(addr,1,7))
		if (crc == addr:byte(8)) then
		  if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
				ow.reset(pin)
				ow.select(pin, addr)
				ow.write(pin, 0x44, 1)
				tmr.delay(1000000)
				present = ow.reset(pin)
				ow.select(pin, addr)
				ow.write(pin,0xBE, 1)
				data = nil
				data = string.char(ow.read(pin))
				for i = 1, 8 do
				  data = data .. string.char(ow.read(pin))
				end
				crc = ow.crc8(string.sub(data,1,8))
				if (crc == data:byte(9)) then
				   t = (data:byte(1) + data:byte(2) * 256)
		 if (t > 32768) then
					t = (bxor(t, 0xffff)) + 1
					t = (-1) * t
				   end
		 t = t * 625
				   lasttemp = t
		 print("Last temp: " .. lasttemp)
				end                   
				tmr.wdclr()
		  end
		end
	  end
	  addr = ow.search(pin)
	  until(addr == nil)
end

--- Get temp and send data to thingspeak.com
getTemp()
t1 = lasttemp / 10000
t2 = (lasttemp >= 0 and lasttemp % 10000) or (10000 - lasttemp % 10000)
print("Temp:"..t1 .. "."..string.format("%04d", t2).." C\n")

	  srv=net.createServer(net.TCP)
	  srv:listen(80,function(conn)
		conn:on("receive", function(client,request)
			local buf = "";
			local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
			if(method == nil)then
				_, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
			end
			local _GET = {}
			if (vars ~= nil)then
				for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
					_GET[k] = v
				end
			end
			
			buf = buf.."<h1> ESP8266 Web Server</h1>";
			buf = buf.."<p>GPIO0 <a href=\"?pin=ON1\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF1\"><button>OFF</button></a></p>";
			getTemp()
			t1 = lasttemp / 10000
			t2 = (lasttemp >= 0 and lasttemp % 10000) or (10000 - lasttemp % 10000)
			buf = buf.."<p class=\"temp\">"..t1 .. "."..string.format("%04d", t2).."</p>"      
			local _on,_off = "",""
			if(_GET.pin == "ON1")then
				  gpio.write(led1, gpio.HIGH);
			elseif(_GET.pin == "OFF1")then
				  gpio.write(led1, gpio.LOW);
			end
			client:send(buf);
			client:close();
			collectgarbage();
		end)
	end)
