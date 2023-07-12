local msg = require 'mp.msg'
function on_media_change(name, value)
   if mp.get_property("width") ~= nil then
      for i = 0,50,1
      do
	 scr="aud"..i
	 if mp.get_opt(scr)  ~= nil
	 then
	    if added ~= 1
	    then
	       msg.log("info", "scr")
	       msg.log("info", mp.get_opt(scr))
	       mysplit(mp.get_opt(scr), "|")
	       mytitle = mysplit(mp.get_opt(scr), "|")[1]
	       mylang = mysplit(mp.get_opt(scr), "|")[2]
	       if string.match(mytitle, "Оригинал") and
		  string.match(mylang, "eng")
	       then
		  mp.set_property("aid", i)
		  added = 1
	       end
	    end
	    if added ~= 1
	    then
	       if string.match(mylang, "eng")
	       then
		  mp.set_property("aid", i)
		  added = 1
	       end
	    end
	    if added ~= 1
	    then
	       if string.match(mylang, "rus")
	       then
		  mp.set_property("aid", i)
	       end
	       
	    end
	 end
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
