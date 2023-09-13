local msg = require 'mp.msg'
function on_media_change(name, value)
   if mp.get_property("width") ~= nil then

      for i = 0,100,1
      do
	 scr="aud"..i
	 if mp.get_opt(scr)  ~= nil
	 then
	    if added ~= 1
	    then
	       msg.log("info", "scr")
	       msg.log("info", mp.get_opt(scr))
	       mysplit(mp.get_opt(scr), "|")
	       myaud = mysplit(mp.get_opt(scr), "|")[1]
	       mytitle = mysplit(mp.get_opt(scr), "|")[2]
	       mylang = mysplit(mp.get_opt(scr), "|")[3]
	       --	       if mytitle == "Оригинал" and
	       -- mylang == "eng"
	       --	       then
	       if string.match(mytitle, ".*Кураж.*") or
		  --		  string.match(mytitle, ".*Санаев.*") or
		  --  		  string.match(mytitle, ".*Пучков.*") or
		  string.match(mytitle, "Оригинал") and string.match(mylang, "eng")
	       then
		  if string.match(mytitle, ".*Санаев.*") or
		     string.match(mytitle, ".*Кураж.*") 
		  --		     string.match(mytitle, ".*Пучков.*") 
		  then
		     mp.commandv("set", "sub", 0);
		  end
		  --		  command = "audio-add "..myaud.." select \""..mytitle.."\" "..mylang
		  command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
		  added = 1
		  msg.log("info", command)
		  mp.command(command)
	       end

	       --        if string.find(mp.get_property("media-title", "A"), "MythBusters", 1, true) ~= nil
	       -- #	       then
	       -- #		  command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
	       -- #		  added = 1
	       -- #		  msg.log("info", command)
	       -- #		  mp.command(command)
	       -- #	       end
	    end
	 end
      end
      
      if added ~= 1 then
	 for i = -1,50,1
	 do
	    scr="aud"..i
	    if mp.get_opt(scr)  ~= nil
	    then
	       if added ~= 1
	       then
		  msg.log("info", mp.get_opt(scr))
		  mysplit(mp.get_opt(scr), "|")
		  myaud = mysplit(mp.get_opt(scr), "|")[1]
		  mytitle = mysplit(mp.get_opt(scr), "|")[2]
		  mylang = mysplit(mp.get_opt(scr), "|")[3]
		  if string.match(mylang, "eng") 
		  then
		     --		     command = "audio-add "..myaud.." select \""..mytitle.."\" "..mylang
		     command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
		     added = 1
		     msg.log("info", "added null audiotrack")
		     mp.command(command)
		     --mp.commandv("set", "sub", 0);
		  end
	       end
	    end

	    --	    mp.command(command)
	 end
      end

      
      if added ~= 1 then
	 for i = -1,50,1
	 do
	    scr="aud"..i
	    if mp.get_opt(scr)  ~= nil
	    then
	       if added ~= 1
	       then
		  msg.log("info", "finding ru")
		  msg.log("info", mp.get_opt(scr))
		  mysplit(mp.get_opt(scr), "|")
		  myaud = mysplit(mp.get_opt(scr), "|")[1]
		  mytitle = mysplit(mp.get_opt(scr), "|")[2]
		  mylang = mysplit(mp.get_opt(scr), "|")[3]
		  if string.match(mylang, "rus") 
		  then
		     --		     command = "audio-add "..myaud.." select \""..mytitle.."\" "..mylang
		     command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
		     added = 1
		     msg.log("info", "no eng")
		     mp.command(command)
		     mp.commandv("set", "sub", 0);
		  end
	       end
	    end
	    --	    mp.command(command)
	 end
      end
      if added ~= 1 then
	 --	 command = "audio-add "..myaud.." select \""..mytitle.."\" "..mylang
	 command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
	 mp.command(command)
      end
      --	 mp.commandv("seek", start+7, "exact")
      start = mp.get_opt("start")
      if start ~= "0"
      then
	 mp.commandv("show-text", "Seeking to "..start, "3500")
	 mp.commandv("seek", start)
      else
	 mp.commandv("seek", 0)
      end

   
end
end

function mysplit (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end
mp.observe_property("p.height", "none", on_media_change);	
