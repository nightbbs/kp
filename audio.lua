local msg = require 'mp.msg'
audiotracks = {}
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
	       audiotracks[i] = mylang.." "..mytitle
	       if string.match(mytitle, ".*Кураж.*") or
		  string.match(mytitle, ".*Сыендук.*") or
		  string.match(mytitle, ".*Санаев.*") or
  		  string.match(mytitle, ".*Пучков.*") or
		  string.match(mytitle, "Оригинал") and string.match(mylang, "eng")
	       then
		  if string.match(mytitle, ".*Санаев.*") or
		     string.match(mytitle, ".*Сыендук.*") or
		     string.match(mytitle, ".*Кураж.*") or
		     string.match(mytitle, ".*Пучков.*") 
		  then
		     mp.commandv("set", "sub", 0);
		  end
		  --		  command = "audio-add "..myaud.." select \""..mytitle.."\" "..mylang
		  command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
		  added = 1
		  selected = i
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
		     command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
		     added = 1
		     selected = i
		     msg.log("info", "added null audiotrack")
		     mp.command(command)
		  end
	       end
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
		  msg.log("info", "finding ru")
		  msg.log("info", mp.get_opt(scr))
		  mysplit(mp.get_opt(scr), "|")
		  myaud = mysplit(mp.get_opt(scr), "|")[1]
		  mytitle = mysplit(mp.get_opt(scr), "|")[2]
		  mylang = mysplit(mp.get_opt(scr), "|")[3]
		  if string.match(mylang, "rus") 
		  then
		     command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
		     added = 1
		     selected = i
		     msg.log("info", "no eng")
		     mp.command(command)
		     mp.commandv("set", "sub", 0);
		  end
	       end
	    end
	 end
      end

      if added ~= 1 then
	 for i = 0,1,1
	 do
	    selected = i
	    msg.log("info", i)
	 end
	 msg.log("info", "2222 - "..selected)
	 command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
	 mp.command(command)
	 --	 mp.commandv("set", "sub", 0);
      end


      --	 mp.commandv("seek", start+7, "exact")
      start = mp.get_opt("start")
      unpause = mp.get_opt("unpause")
      if start ~= "0"
      then
	 mp.commandv("seek", start, "exact")
	 mp.commandv("show-text", "Seeking to "..start, "3500")
	 if unpause ~= "0"
	 then
	    mp.command("set pause no")
	 end
      else
	 --	 mp.commandv("seek", 0)
      end
      --      unpause = mp.get_opt("unpause")
      if unpause ~= "0" and
	 start ~= "1"
      then
	 --	 mp.command("set pause no")
      end
   end
end
function messageshow ()
   message = "====================================================================\n"
   for i = 0,50,1
   do
      if audiotracks[i] ~= nil
      then
	 message1 = message
	 msg.log("info", "added to message")
	 if i == selected
	 then
	    message = "--"..message1..audiotracks[i].."\n"
	 else
	    message = message1..audiotracks[i].."\n"
	 end
      end
   end
   mp.commandv("show-text", message)
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
function audioprev ()
   i = selected - 1
   selected = i
   msg.log("info", selected)	    
   scr="aud"..i
   if mp.get_opt(scr)  ~= nil
   then
      msg.log("info", mp.get_opt(scr))	    
      myaud = mysplit(mp.get_opt(scr), "|")[1]
      mytitle = mysplit(mp.get_opt(scr), "|")[2]
      mylang = mysplit(mp.get_opt(scr), "|")[3]
      command = "audio-add "..myaud.." select \""..mytitle.."\"  \""..mylang.."\""
      mp.commandv("audio-remove")	 
      mp.commandv("audio-reload")
      mp.command(command)
      --    mp.command("set "..audio.." 0")
      --    mp.command("set "..audio.." 1")
      message = mylang.." "..mytitle
      mp.commandv("show-text", message)
      --      mp.commandv("audio-reload")
      
   end
end
function audionext ()
   i = selected + 1
   selected = i
   msg.log("info", selected)	    
   scr="aud"..i
   if mp.get_opt(scr)  ~= nil
   then
      msg.log("info", mp.get_opt(scr))	    
      myaud = mysplit(mp.get_opt(scr), "|")[1]
      mytitle = mysplit(mp.get_opt(scr), "|")[2]
      mylang = mysplit(mp.get_opt(scr), "|")[3]
      command = "audio-add "..myaud.." cached \""..mytitle.."\"  \""..mylang.."\""
      mp.commandv("audio-remove")	 
      mp.command(command)
      --     mp.commandv("audio-choose 1")
      message = mylang.." "..mytitle
      mp.commandv("show-text", message)
      --      mp.commandv("audio-reload")
      
   end
end

mp.observe_property("p.height", "none", on_media_change)
mp.add_key_binding("CTRL+e", messageshow);
mp.add_key_binding("CTRL+u", messageshow);
mp.add_key_binding("CTRL+i", audioprev);
mp.add_key_binding("CTRL+k", audionext);
