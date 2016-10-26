-- Database



sqlite3 = require("lsqlite3")

databaseName = "mt_gandi.sqlite3"

function initDatabase()
    local db = sqlite3.open(databaseName)
    db:exec[[
      CREATE TABLE server (id INTEGER PRIMARY KEY AUTOINCREMENT,  
                         hostname CHAR(32),
                         ipv4 CHAR(32),
                         ipv6 CHAR(32),
			 posx CHAR(32),
			 posy CHAR(32),
			 posz CHAR(32)
                        );

    ]]
    db:close()
end


-- Lua CRUD method
function insertServer(hostname, ipv4, ipv6, posx, posy, posz)
    local db = sqlite3.open(databaseName)
    local stmt = db:prepare[[ INSERT INTO server VALUES (null, :hostname, :ipv4, :ipv6, :posx, :posy, :posz) ]]
    stmt:bind_names{ hostname = hostname, ipv4 = ipv4, ipv6 = ipv6, posx = posx, posy = posy, posz = posz  }
    stmt:step()
    stmt:finalize()
    db:close()
end

function selectServer()
    local db = sqlite3.open(databaseName)
    for row in db:nrows("SELECT * FROM server") do
      print(row.id, row.hostname, row.ipv4, row.ipv6, row.posx, row.posy, row.posz)
    end 
    db:close()
end


function updateServer(id, field, value)
    local db = sqlite3.open(databaseName)
    if field == "ipv6" then
        local stmt = db:prepare[[ UPDATE server SET  ipv6 = :value WHERE id = :id ]]
        stmt:bind_names{  id = id,  value = value  }
        stmt:step()
        stmt:finalize()
    end
    db:close()
end


function deleteServer(id)
    local db = sqlite3.open(databaseName)
    local stmt = db:prepare[[ DELETE FROM server WHERE id = :id ]]
    stmt:bind_names{  id = id }
    stmt:step()
    stmt:finalize()
    db:close()
end


function seperator()
    print("-----------------------")
end

-- Init database
initDatabase()





-- whereis <player name>
-- Display player location

minetest.register_chatcommand("whereis", {
	params = "<player name>",
	description = "Tell the location of <player>",
	func = function(user, args)
		if args == "" then
			return false, "Player name required."
		end
		local player = minetest.get_player_by_name(args)
		if not player then
			return false, "There is no player named '"..args.."'"
		end
		local fmt = "Player %s is at (%.2f,%.2f,%.2f)"
		
		local pos = player:getpos()
		return true, fmt:format(args, pos.x, pos.y, pos.z)
	end
})


-- myinfo
-- Display all player informations 

minetest.register_chatcommand("myinfo", {
	params = "",
	description = "Display my informations",
	func = function(user, param)
		local player = minetest.get_player_by_name(user)
		if not player then
			return false, "Player not found"
		end

		return true, "My information: " .. user
	end
})


-- build <player> <structure>
-- Build a structure

minetest.register_chatcommand("build", {
	params = "<structure name> <structure param>",
	description = "Build a structure with parameters",
	func = function(user, args)

		if args == "" then
			return false, "Parameters required."
		end

		local structureName, structureParam = args:match("^(%S+)%s(%S+)$")

		if not structureParam then
			return false, "Structure parameters required"
		end

		local player = minetest.get_player_by_name(user)
		if not player then
			return false, "Player not found"
		end

		local fmt = "Player %s is at (%.2f,%.2f,%.2f)"

		local pos = player:getpos()
		
		-- /build pillar 5
		if structureName == "pillar" then
			local heightPillar = tonumber(structureParam)
			for i = 0, heightPillar do
				minetest.set_node({x=pos.x + 2, y=pos.y + i, z=pos.z }, {name="default:ice"})
			end
			

		-- /build server hostname
		elseif structureName == "server" then
			for i = 0, 4 do
				for j = 0, 4 do
					for k = 0, 2 do
						minetest.set_node({x = pos.x + 2 + i, y = pos.y + k, z = pos.z + j}, {name="default:ice"})
					end
				end
			end
			for i = 0, 4 do
				for j = 0, 2 do
					minetest.set_node({x = pos.x + 2 + i , y = pos.y + j, z = pos.z }, {name="mesecons_switch:mesecon_switch_off"})
				end
			end

			hostname = structureParam
			insertServer(hostname, "ipv4", "Ipv6", tostring(pos.x + 2), tostring(pos.y), tostring(pos.z))
			selectServer()


		-- /build sign_yard
		elseif structureName == "sign_yard" then
			minetest.set_node({x=pos.x    , y=pos.y, z=pos.z }, {name="default:ice"})
			minetest.set_node({x=pos.x + 1, y=pos.y, z=pos.z }, {name="default:ice"})

			minetest.set_node({x=pos.x + 2, y=pos.y, z=pos.z }, {name="signs:sign_yard"})
			local meta = minetest.get_meta({x=pos.x + 2, y=pos.y, z=pos.z })
			meta:set_string("infotext", "My custom text here")
			meta:set_string("text", "My custom text here")
			signs_lib.update_sign({x=pos.x + 2, y=pos.y, z=pos.z })

			minetest.set_node({x=pos.x + 3, y=pos.y, z=pos.z }, {name="default:ice"})
			minetest.set_node({x=pos.x + 4, y=pos.y, z=pos.z }, {name="default:ice"})


		-- /build switch
		elseif structureName == "switch" then
			minetest.set_node({x=pos.x + 2, y=pos.y, z=pos.z }, {name="mesecons_switch:mesecon_switch_off"})
			minetest.chat_send_all("mesecons_switch:mesecon_switch_off; x=" .. pos.x + 2 .. " y=" .. pos.y .. " z=" .. pos.z)

		else
			return false, "No structure builded"
		end

		return true, fmt:format(args, pos.x, pos.y, pos.z)
	end
})


-- Action on punch node

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	if node.name == "default:brick" then
		local puncher_name = puncher:get_player_name()
		local mypos = minetest.pos_to_string(pos) -- Sets variable to (X,Y,Z.. where Y is up) 
		minetest.chat_send_all(puncher_name .." is hitting me. I'm located at ".. mypos)		
	end 
	if node.name == "default:desert_stonebrick" then
		local puncher_name = puncher:get_player_name()
		minetest.chat_send_player(puncher_name, "That's got to hurt!!")
	end
	if node.name == "mesecons_switch:mesecon_switch_off" then
		local puncher_name = puncher:get_player_name()
		local mypos = minetest.pos_to_string(pos)
		minetest.chat_send_all(puncher_name .." switch: ".. mypos)
	end
end)

-- Use switch to on/off and use pick wood weapon to change the value
minetest.register_tool("nekromod:pick_wood", {
    	description = "Wooden Pickaxe Weapon",
    	inventory_image = "default_tool_woodpick.png",
    	tool_capabilities = {
    	},

	-- Left button mouse
	on_use = function(itemstack, user, pointed_thing)
		local pos = pointed_thing.under
		if not pos then
			return itemstack
		end

		-- Player
                --local player = minetest.get_player_by_name(user)
                local playerPos = user:getpos()
		minetest.chat_send_all("player; x=" .. playerPos.x .. " y=" .. playerPos.y .. " z=" .. playerPos.z)

		-- Node
		local meta = minetest.get_meta(pos)
		local nodeName = minetest.get_node(pos).name
		minetest.chat_send_all("on_use; x=" .. pos.x .. " y=" .. pos.y .. " z=" .. pos.z .. " name=" .. nodeName)

		-- Check distance between player and node
		if (playerPos.x > pos.x - 3  and playerPos.x < pos.x + 3) and
		   (playerPos.y > pos.y - 3  and playerPos.y < pos.y + 3) and
		   (playerPos.z > pos.z - 3  and playerPos.z < pos.z + 3) then
			if nodeName  == "mesecons_switch:mesecon_switch_on" then
				minetest.set_node({x=pos.x, y=pos.y, z=pos.z }, {name="mesecons_switch:mesecon_switch_off"})
			else
				minetest.set_node({x=pos.x, y=pos.y, z=pos.z }, {name="mesecons_switch:mesecon_switch_on"})
			end
		end

		return itemstack
	end,
	
	-- Right button mouse
    	on_place = function(itemstack, user, pointed_thing)
		local pos = pointed_thing
		if not pos then
			return itemstack
		end

		 minetest.chat_send_all("on_place;" )

        	return itemstack
    	end,
})

