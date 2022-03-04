-- version: 0.50

--[[
  Collapse this document to make it easier to digest.
  Use: This is intended to provide insight into the framework class which can be
  used to create a 'quest' for XSAF servers along side the more comprehensive API provided.

  You can either solely use the API functions to write fully custom code, or you can
  use this framework class, or you can mix and match. The way I write code generally gives
  great flexibility and scalability.

  The API and indeed this framework class (to which the whole source is below) is open for
  further development, so if theres a function or method you need, or idea youre not sure how
  to do / can't with current scope then let me know and I may already have something written
  in the code I have running the server and I will export it, or I may write it in, or tell
  you how to do it.

  XQF is provided in full so that you understand the object/data structures and what it's doing
  and how. It's not intended for you to have this in your code as it will already be server side,
  however, it is written mostly without dependencies so you could use it to debug. You might look
  at the calls I make to some of the API functions and wonder why they are different, and thats
  because I might be calling the modules behind the API. Its not intended for you to change
  anything within it, although by all means improve on it or fix bugs if you can and use github
  to manage the pulls/requests and submissions and issues.

  I have provided an example of how to use it below, and you should be able to see how i use the
  functions exposed in the API to get a reference on how to use them yourself too.

  ALPHA Development: Whilst this is in early stages you may find my notes, comments, unfinished
  things, unoptimised functions, methods, ideas... You will know it's ready when the version >= 1
]]

-- XQF (XSAF Quest Framework) internal code
  -- global calls
    -- call in useful API functions (required to use)
    local jsb_core = jsb.getCore() -- API call
    local say = jsb_core.say -- ingame global print
    local fstr = jsb_core.fstr -- string.format
    local deepCopy = jsb_core.deepCopy -- copy func
    local shallowCopy = jsb_core.shallowCopy -- copy func
    local __log = jsb_core.log -- custom dcs.log output
    local jmr = aiMed.fun.getJMR()

    -- future use funcs
    local validity_search

    local do_not_save = DONOTSAVE -- is a global variable in my development build to stop data saving out

    local trigger_get_zone = trigger.misc.getZone -- DCS SSE func for getting a zone at runtime
    local sZones = globalOptions.spawn.red.zRef -- a DB of zones which surround all bases in XSAF, key'd by base name, comment out to load in this code
  --

  XQF = {} -- global quest framework container

  -- locals
    local ingame_feedback = true -- if true log messages will be replicated ingame too
    local ingame_display = 40 -- time on screen for ingame messages
    local ingame_clear = false -- clearview on message ingame
    local _time = jsb_core.time
    local _log = function(quest_name, fmt, ...)
      local msg = fstr("JSB.XQF: %s: %s", quest_name or "UKN", fstr(fmt, ...))
      __log(msg)
      if ingame_feedback then
        say(msg, ingame_display, ingame_clear)
      end
    end
  --

  -- data
    local xqc = {
      coalition = {}, -- persistent coalition quest log
      personal = {}, -- persistent player quest log
      config = {
        default_coalition_msg = 17,
        default_plyr_msg = 25,
        first_maintain = 20,
        maintain_time = 3.2,
        spin_time = 1.25,
      },
      idx = 0,
    } -- local data
  --

  -- data saving and recovery
    --
  --

  -- Quest Class
    XQC = {
      trigger = {},
    } -- global class container

    local xqm_interface = {} -- shared methods
    local xqmp = {} -- personal methods
    local xqmc = {} -- coalition methods
    local xqm = {} -- backend methods

    function XQC.getDB()
      return xqc
    end

    local function player_init_setup(plyr)
      if not xqmp[plyr] then
        xqmp[plyr] = {
          config = {

          },
        }
      end
    end

    local function is_quest_active(quest_name)
      if not quest_name then return end
      local quests = { xqmp, xqmc }
      for i = 1, 2 do
        for j = 1, #quests[i] do
          if (quest_name == quests[i][j].name) then
            return quests[i][j].flag == 2
          end
        end
      end
    end

    -- methods

      -- personal
        -- player related funs
        function xqmp:get_class()
          return Plyr.get(self.player_name)
        end

        function xqmp:msg(fmt, ...)
          local plyr = self:get_class()
          if plyr then plyr:msg(fstr(fmt, ...), xqc.config.default_plyr_msg) end
        end
      --

      -- coalition
        -- global msg out
        -- fmt @string: Lua standard string format
        -- ... @vararg of any args for the string
        -- return: nil
        function xqmc:msg(fmt, ...)
          say(fstr(fmt, ...), xqc.config.default_coalition_msg)
        end

        -- adds a hook to start the quest
        -- fun @funciton (optional): can be used to inject a custom function on start
        -- event_id @DCS_Enum: the event id that will trigger quest to start
        -- delays @number/@table (optional): if number then quest starts event + delay, if table { min = n (optoinal), max = n } then will be random time min/max if just max then random 0-max
        -- TODO: args...
        -- return: nil
        function xqmc:add_start_hook(event_id, fun, delays, msg, args)
          if not self.start then self.start = {} end
          if not args then args = {} end
          self.start.start_func = fun or nil
          self.start.hook_event = event_id or nil
          if event_id == 10 then
            self.start.base_name_trigger = args.base
            self.start.base_owner = args.owned_by
          end
          if delays and type(delays) == 'table' then
            self.start.delay_min = delays.min
            self.start.delay_max = delays.max
          elseif delays then
            self.start.delay_min = delays
          end
          if msg and not self.start.msg then self.start.msg = msg end
          if args then
            self.start.non_trigger = {
              from_reboot = args.reboot_start,
              delay_after_reboot = args.reboot_delay,
              random_start = args.boot_random,
              condition_func = args.cond_fun,
            }
          end
        end

        -- adds a delay config to the start conditions
        -- delays @number/@table: if number then quest start time is delayed, if table { min = n (optoinal), max = n } then will be random time min/max if just max then random 0-max
        -- return: nil
        function xqmc:add_start_delay(delays)
          if not self.start then self.start = {} end
          if delays and type(delays) == 'table' then
            self.start.delay_min = delays.min
            self.start.delay_max = delays.max
          elseif delays then
            self.start.delay_min = delays
          end
        end
      --

      -- interface main methods (shared)
        -- author in mission debug messages log divert
        -- player_name @string: name of the player debug should divert to
        -- TODO msg, menu, ...
        -- return: nil
        function xqm_interface:player_debug(player_name, debug_messages, debug_menu_generation)
          self.plyr_debug_msg = debug_messages
          self.author = player_name
          self.debug_menu = debug_menu_generation
        end

        -- shared log function
        -- fmt @string: Lua standard string format
        -- ... @vararg of any args for the string
        -- return: nil
        function xqm_interface:log(fmt, ...)
          _log(self.name, fmt, ...)
          if self.player_name and self.plyr_debug_msg and (self.author == self.player_name) then
            local PLYR = Plyr.get(self.author)
            if PLYR then
              PLYR:msg(fstr(fmt, ...), xqc.config.default_plyr_msg)
            end
          end
        end

        -- sets the starting conditions, spawns objects, gives init info
        -- args {
          -- start_fun @function (optional): use a custom function on start
          -- msg @string (overload): The message displayed on start, story context, instrutions, first task etc...
          -- ... various others instead of using individula methods
        -- }
        -- return: nil
        function xqm_interface:set_start_conditions(args)
          if (not args or type(args) ~= 'table') or not args.msg then
            return self:log("Error with args in start config")
          end
          self.start = {
            msg = args.msg,
            start_func = args.start_fun,
            hook_event = args.event_id,
            hook_func = args.hook_fun,
            delay_min = args.dealy or args.min,
            delay_max = args.max,
          }
          self.run_time = args.run_time
          self.spin_time = args.spin_time or xqc.config.spin_time
          self.maintain_time = args.maintain_time or xqc.config.maintain_time
        end

        -- pre-start exception check to pass onto spin or wait for other trigger
        -- return: will return @any or nil if fail
        function xqm_interface:start_quest()
          if self:verify_structure() then
            -- dont callback if flag 8 or manual start
            if self.start.hook_event and self:valid_hook() then
              return self:inc(8)
            end
            -- start the quest spinning
            self:spin()
            return true
          end
          self:log("Error in start_quest")
        end

        -- sets the maximum time the quest runs
        -- n @number: time in seconds
        -- return: nil
        function xqm_interface:set_runtime(n)
          self.run_time = n
        end

        -- sets the start trigger
        -- trigger_enum @number: from enum table
        -- return: nil
        function xqm_interface:set_trigger_type(trigger_enum)
          self.on_trigger_start = trigger_enum
        end

        --[[
          flags:
            0 = not started
            1 = started & spinning
            2 = started
            3 = fail
            4 = win
            5 = null
            6 = to remove
            7 = stop for error
            8 = waiting event trigger
            9 = waiting for manual start
            10 = started with delay
        ]]

        -- increases flag by n @number, or 1 if n is nil
        -- return @number: flag number
        function xqm_interface:inc(n)
          self.flag = n or (self.flag + 1)
          return self.flag
        end

        -- replace the maintain function
        -- return
        function xqm_interface:replace_maintain(func)
          --
        end

        -- add a custom trigger function inside the 'maintain' spin
        -- return
        function xqm_interface:maintain_trigger(func)
          --
        end

        -- used to pre schedule messages based on time
        -- time_to_display @number: screen display time
        -- msg @string: Lua standard format string type
        -- ... varargs @any (optional)
        -- return: nil
        function xqm_interface:schedule_msg(time_to_display, msg, ...)
          self.msg_store[#self.msg_store+1] = { time_to_display, msg, ... }
        end

        -- function to set the behaviour on completion, default is false (in session)
        -- time_based @number: Quest resets after a time period, if not reboot_reset then time period can be over a reboot
        -- reboot_reset @bool: (optional): reset on reboot, default = true
        function xqm_interface:repeatable(time_based, reboot_reset)
          self.repeatable_config = {
            repeatable = true,
            min_time = time_based,
            reboot_reset = reboot_reset,
          }
        end

        -- pass in the details of any statics to be spawned on start
        function xqm_interface:create_static_on_start(args)
          -- if not self.start then
          --   return self:log("Must set start conditions before defining statics")
          -- end
          self.assets.static = shallowCopy(args)
          -- self.start.statics = true
        end

        function xqm_interface:set_win_config(config)
          self.completion = shallowCopy(config)
        end

        function xqm_interface:set_null_config(config)
          self.null_config.msg = config.msg or fstr("Quest, %s, failed.", self.name)
          self.null_config.func = config.fun
          self.null_config.del_units = config.delete_units
          self.null_config.del_stat = config.delete_statics
          self.null_config.unit_behaviour = config.unit_behaviour
        end

        function xqm_interface:set_fail_config(config)
          self.failure.msg = config.msg or fstr("Quest, %s, failed.", self.name)
          self.failure.func = config.fun
          self.failure.del_units = config.delete_units
          self.failure.del_stat = config.delete_statics
          self.failure.unit_behaviour = config.unit_behaviour
        end

        -- pass in a custom function to watch for the start trigger or in addition to
        -- no need to use any callbacks in your code, pass in self as the 1st arg
        -- only_custom @bool (optional): pass true to bypass all framework code from maintain
        -- return: nil
        function xqm_interface:set_custom_spin(fun, only_custom)
          self.spin_func = fun
          self.spin_exlusive = only_custom -- flag to only use your code in this state
        end

        -- pass in a custom function to use before any triggers are looked for
        -- no need to use any callbacks in your code, pass in self as the 1st arg
        -- only_custom @bool (optional): pass true to bypass all framework code from maintain
        -- return: nil
        function xqm_interface:set_custom_start(fun, only_custom)
          self.start.start_func = fun
          self.start.start_exlusive = only_custom -- flag to only use your code in this state
        end

        -- pass in a custom function to use before any triggers are looked for
        -- no need to use any callbacks in your code, pass in self as the 1st arg
        -- periodicity @number (optional): ratio of your runtaime vs framwork, e.g. 1:2 pass 2 and yours runs every other time including framework
        -- only_custom @bool (optional): pass true to bypass all framework code from maintain
        -- return: nil
        function xqm_interface:set_custom_maintain(fun, periodicity, only_custom)
          self.maintian_func = fun
          self.maintain_custom_run = periodicity
          self.maintain_exlusive = only_custom -- flag to only use your code in this state
        end
      --

      -- backend methods (shared)
        -- TODO
        function xqm:verify_structure()
        --   if not self.repeatable_config then -- redundant
        --     return self:log("Cannot start quest because no repeatable config is set.")
          if not self.start then
            return self:log("Cannot start quest because no start config is set.")
          elseif not self.run_time then
            return self:log("Must have a run time")
          end
          return true
        end

        -- validate the hook type against any args
        function xqm:valid_hook(event)
          if self.start.hook_event == 10 and (self.start.hook_func or self.start.base_name_trigger) then
            return true
          elseif (event and self.start.hook_event == 10 and self.start.base_name_trigger) and (event.initiator and event.initiator:getName() == self.start.base_name_trigger and event.initiator:getCoalition() == self.start.base_onwer) then
            return true
          end
        end

            -- TODO, what if there are more than one site, for now assume all assets are in one place, need to refactor to allow for site indexing
              -- fuel_tanks = {
              --   template = {
              --     category = "Fortifications",
              --     shape_name = "kazarma2", -- TODO
              --     type = "Barracks 2", -- TODO
              --     dead = false,
              --   },
              --   config = {
              --     number_spawn = 5,
              --     position = {}, -- TODO
              --     max_radius = 1000,
              --     min_radius = 0,
              --     owner = 0,
              --     site_index = 1,
              --   },
              --   conditions = {
              --     kill_all = true,
              --     kill_some = 0,
              --   },
            -- }

        -- spawners
          local function find_spawn_point(search_area, max_distance, min_distance, safe_area, no_obsticles)
            if not validity_search then validity_search = jmr.areaSearch end
            local spot_found, random_point, idx = nil, nil, 0
            local item_type = { 3, 5 }
            -- WARNING
              repeat
                idx = idx + 1
                random_point = jmr.randomPoint(search_area, max_distance, min_distance)
                if random_point then
                  local surface_check = land.getSurfaceType({ x = random_point.x, y = random_point.z })
                  if surface_check and (surface_check ~= land.SurfaceType.WATER and surface_check ~= land.SurfaceType.SHALLOW_WATER) then
                    if not no_obsticles then
                      for i = 1, 2 do
                        if validity_search(random_point, item_type[i], nil, nil, safe_area) then
                          break
                        end
                        if i > 1 then spot_found = true end
                      end
                    else
                      spot_found = true
                    end
                  end
                end
              until (spot_found or (idx >= 5000))
            --
            if not spot_found then
              _log("No spawn spot found")
              return
            end
            return random_point
          end

          local function build_static(object_type, shape_name, position, object_name, mass, can_cargo)
            return {
              ["type"] = object_type,
              ["name"] = object_name,
              ["shape_name"] = shape_name,
              ["x"] = position.x,
              ["y"] = position.z,
              ["dead"] = false,
              ["mass"] = mass or nil,
              ["canCargo"] = can_cargo or nil,
              ["heading"] = math.random(359),
            }
          end

          -- statics
          function xqm:spawn_statics()
            self.spawned.static = {}
            self.spawned.totals.static = 0
            for static, data in pairs (self.assets.static or {}) do
              local max, min, safe = 175, 55, 50
              -- first site 'placement'
              if not self.reference_position then
                data.config.position = find_spawn_point(data.config.position, data.config.max_radius, data.config.min_radius, nil, true)
                self.reference_position = data.config.position
              end
              if not self.last_spawn_spot then max, min = nil, nil end
              local spawn_spot = find_spawn_point(self.last_spawn_spot or self.reference_position, max or 500, min or 0, safe)
              if not spawn_spot then self:log("Error finding spawn site !") return end
              self.last_spawn_spot = spawn_spot
              for i = 1, data.config.number_spawn do -- TODO, position data
                local static_object = coalition.addStaticObject(data.config.owner or 0, build_static(data.template.type, data.template.shape_name, self.last_spawn_spot, static .. self.name .. i))
                if static_object then
                  if not self.spawned.static[static] then self.spawned.static[static] = {} end
                  self.spawned.static[static][#self.spawned.static[static]+1] = {
                    static_object,
                    static_object:getName(),
                  }
                  self.spawned.totals.static = self.spawned.totals.static + 1
                  self:log("Spawned static %s", static_object:getName() or "")
                end
              end
            end
            return true
          end
        --

        -- init
        function xqm:init()
          if self.flag == 1 or self.flag == 8 or self.flag == 9 then
            -- delayed start
            if self.start.delay_max then -- has a scheduled start
              timer.scheduleFunction(function() self.flag = 8 self:maintain() end, nil, _time(math.random( self.start.delay_min, self.start.delay_max )))
              self.start.delay_max = nil
              self.flag = 10
              return true
            end
            -- start config action / execute
            self.max_time = self.run_time + _time()
            -- spawn statics
            if self.assets.static and self:spawn_statics() then
              -- msg schedules
              if #self.msg_store > 0 then
                for i = 1, #self.msg_store do
                  timer.scheduleFunction(function()
                    if is_quest_active(self.name) then self:msg(fstr(self.msg_store[i][2], self.msg_store[i][3])) end
                  end, nil, _time(self.msg_store[i][1]))
                end
              end
              -- TODO spawn other objects
              -- start msg
              self:msg(self.start.msg)
              self.flag = 2
            elseif self.assets.static then
              -- error in creating the site...
              return
            end

            -- transition to start
            timer.scheduleFunction(function()
              self.flag = 2 -- started the quest
              self:maintain()
              self:log("Init complete, maintain scheduled for first maintain callback.")
            end, nil, _time(xqc.config.first_maintain))
            return true
          elseif self.flag == 10 then -- already scheduled, with delayed start
            return true
          end
        end

        local function static_deaths(statics)
          local count = 0
          for shape, array in pairs (statics) do
            for i = 1, #array do
              local stat_object = StaticObject.getByName(array[i][2])
              if not stat_object or (stat_object and not (stat_object:isExist() or (stat_object:getLife() < 3))) then
                count = count + 1
                -- shall we remove from the array??
              end
            end
          end
          return count
        end

        -- in play spin
        function xqm:maintain()
          -- state transitions
            if self.flag == 10 then -- delayed to start
              return
            elseif self.flag == 3 then -- fail
              -- fail condition
              -- TODO
              self:run_fail()
              return
            elseif self.flag == 4 then -- win
              -- win condition
              -- TODO
              self:run_win()
              return
            elseif self.flag == 5 then -- null
              -- null condition
              -- TODO
              self:run_null()
              return
            elseif not self.max_time and self.flag ~= 2 then -- max_time is set on start
              if not self:init() then
                -- error in init
                self.flag = 7
              else
                return
              end
            end
          --
          -- normal schedule callback
          timer.scheduleFunction(function() self:maintain() end, nil, _time(self.maintain_time))
          if self.flag == 7 then -- error stop
            -- stopped on error
            -- TODO remove, dump data?
            -- self:remove()
            self:log("Error, state set to stop on error")
            return
          end
          -- check run time
          if self.to_remove or (self.max_time and (self.max_time < _time())) then
            -- quest should now be removed
            self.flag = 3
            return
          end
          -- custom maintain funcs
          self.tick = self.tick + 1
          if self.maintain_func then
            if self.maintain_exlucsive then
              return pcall(self.maintain_func, self)
            elseif self.maintain_periodicy and ((self.tick % self.maintain_periodicy) == 0) then
              if not pcall(self.maintain_func, self) then self.maintain_func = nil self:log("Error running custom maintain func, remove func") end
            end
          end
          -- customer trigger
          -- fail check
          -- null check
          if self.null_config.func and self.null_config.func(self) then
            -- null triggered
            self.flag = 5
            self:log("State set to null")
            self:msg(self.null_config.msg)
            return
          end
          -- trigger checks
          if self.quest_type == 2 then -- static kill
            local deaths = static_deaths(self.spawned.static)
            if deaths == self.spawned.totals.static then
              -- win condition
              self.flag = 4
              return
            end
          end
        end

        function xqm:get_flag()
          return self.flag
        end

        -- start trigger listen
        -- TODO
        function xqm:spin()
          if self.flag ~= 1 then return end
          timer.scheduleFunction(function() self:spin() end, nil, _time(self.spin_time))
          -- custom spin
          if self.spin_func then
            if pcall(self.spin_func()) then
              return
            else
              return self:log("Error in custom spin")
            end
          end
          -- start on timer
          -- trigger condition
          -- time dealys / pass to maintain
        end

        -- end execution methods
          function xqm:give_reward()
            -- TODO
          end
          
          function xqm:make_impact()
            -- TODO
          end

          function xqm:run_fail()
            -- TODO
          end

          function xqm:run_win()
            -- TODO
            self:msg(self.completion.msg)
            self:give_reward()
            self:make_impact()
            self:remove()
          end

          function xqm:run_null()
            -- TODO
                -- self.null_config.del_units = config.delete_units
                -- self.null_config.del_stat = config.delete_statics
                -- self.null_config.unit_behaviour = config.unit_behaviour
            self:remove()
          end
        --

        function xqm:clean_up()
            -- TODO
          -- clean up any alive units/statics
          -- remove any menus, coalition, player
        end

        function xqm:remove()
            -- TODO
          self:clean_up()
        end
      --

      -- construct the metamethods from shared + methods passed
      -- return: table of merged methods
      local function method_construct(method_to_merge)
        local to_merge = { xqm, xqm_interface, method_to_merge }
        local merged = {}
        for i = 1, 3 do
          for method_name, method_function in pairs (to_merge[i]) do
            merged[method_name] = method_function
          end
        end
        return merged
      end
    --

    -- enums
      XQC.quest_type = {
        unit_kill = 1,
        static_kill = 2,
      }

      XQC.reward_type = {
        intel = 1,
        personal_credits = 2,
        warehouse = {
          a2a = {
            aim_120 = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
          },
          a2g = {

          },
          fuel = 3,
        },
      }

      XQC.red_impacts = {
        lower_gce = 1,
      }

      XQC.units_on_end = {
        attack_blue_base = 1,
      }

      XQC.trigger.aircraft_type = {
        f18 = 1,
        huey = 2,
      }
    --

    -- local function to take personal quest params and create object
    -- return: quest object with methods or nil if fail
    local function personal_quest(setup)
      if not setup.player_name then return end
      if not xqc.personal[setup.player_name] then
        player_init_setup(setup.player_name)
      end
      xqc.personal[setup.player_name][setup.quest_name] = {
        name = setup.quest_name,
        player_name = setup.player_name,
        time_start = 0,
        quest_type = setup.quest_type,
        flag = 0,
        -- optional args at setup, may need to be added later by implicit method call
          run_time = setup.run_time or nil,
          spin_func = setup.spin_fun or nil,
          start = nil,
          -- {
          --   start_func = nil,
          --   msg = nil,
          -- },
        --
        msg_store = {},
        assets = {},
        spawned = {},
        repeatable_config = {
          repeatable = false,
          reboot_reset = true,
        },
      }
      setmetatable(xqc.personal[setup.player_name][setup.quest_name], { __index = method_construct(xqmp) })
      return xqc.personal[setup.player_name][setup.quest_name]
    end

    -- local function to take coalition quest params and create object
    -- return: quest object with methods or nil if fail
    local function coalition_quest(setup)
      xqc.coalition[setup.quest_name] = {
        name = setup.quest_name,
        time_start = 0,
        quest_type = setup.quest_type,
        flag = 0,
        tick = 0,
          -- run_time = setup.run_time or nil,
          -- spin_time = setup.spin_time or nil,
          -- maintain_time = setup.maintain_time or xqc.config.maintain_time,
        spin_func = setup.spin_fun or nil,
        start = nil,
          -- {
          --   start_func = nil, -- custom start func
          --   msg = nil,
          --   hook_func = nil, -- custom event pre-start verifications
          --   hook_event = nil,
          --   delay_min/max
          -- },
        msg_store = {},
        null_config = {},
        completion = {},
        failure = {},
        assets = {},
        spawned = {
          totals = {},
        },
        repeatable_config = {
          repeatable = false,
          reboot_reset = true,
        },
      }
      setmetatable(xqc.coalition[setup.quest_name], { __index = method_construct(xqmc) })
      xqc.idx = xqc.idx + 1
      return xqc.coalition[setup.quest_name]
    end

    -- To create a quest object
    -- setup{...};
    -- personal @bool, identifies if is a personal quest
    -- player_name @string, required if a personal quest
    -- quest_name @string, required name of the quest
    -- return: quest object with methods or nil if fail
    function XQF.newQuest(setup)
      if setup.personal then
        return personal_quest(setup)
      end
      return coalition_quest(setup)
    end

    function XQF.eventHandle(event)
      if not event or (xqc.idx < 1) then return end
      for quest_name, quest in pairs (xqc.coalition) do
        if quest:get_flag() == 8 and (event.id and quest.start.hook_event == event.id) then
          if (not quest.start.hook_func and quest:valid_hook(event)) or (quest.start.hook_func and quest.start.hook_func(quest)) then
            quest:maintain()
            quest:log("Hook event fired and maintain started")
          end
        end
      end
    end
    
    local quest_logs = { xqmc, xqmp }

    -- for recall of quest, by manual start or start from elsewehere
    function XQF.getQuest(name, args)
      for i = 1, 2 do
        for quest_name, quest in pairs (quest_logs[i]) do
          if quest_name == name then
            return quest
          end
        end
      end
    end

    -- for recall of quest, by manual start or start from elsewehere
    function XQF.getAuthor(player_name)
      local quests = {}
      for i = 1, 2 do
        for quest_name, quest in pairs (quest_logs[i]) do
          if quest.author and quest.author == player_name then
            quests[#quests+1] = quest_name
          end
        end
      end
      return quests
    end
  --
--

-- quest story board example
  -- is personal
    -- need player name for tracking
    -- need player unit
  -- else is coalition
  -- Start:
    -- Need to use a hel0, from Hatay, top deliver medical supplies to Aleppo Hospital
      -- Text for msg out
      -- need unit to track
        -- verify is a helo
        -- verify at Hatay
        -- track when in the air with a spin
  -- Middle: Explosion en-route in village, told to re-route to there and deliver to awaiting units
    -- create explosion in player view
    -- spawn ground units
      -- find a spot that works
      -- take position
    -- Text msg for player, about the re-route
      -- give them new coords
  -- End: Verify landed
    -- is near the ground units, check helo position
    -- End quest, give reward
  -- Spin:
    -- if player leaves unit, end quest
--

-- Simple Quest example with code and documentation
  -- create a XQF object
  -- minimal arguments need to be passed but the below are required. Its possible to set further params
  -- here at the construction, please see the data structures in the respective constructors above.

  local example = XQF.newQuest({quest_name = "ExampleQuest", quest_type = XQC.quest_type.static_kill})

  -- start config & options
  -- You can also construct step by step with the below methods.

  -- displayed to player or coalition on quest start
  local start_msg = "Intelligence has uncovered that Red Force is highly dependant on the Baniyas Refinery located near N35 13 00 E35 58 00.\n\nYour mission is to destroy all 40 fuel tanks on the north side of the refinery and you have 90 minutes to do so.\n\nWe believe success will lead to few red air activity for the next several hours."

  -- max time allowed to run after triggered/manual/preset start
  example:set_runtime(5400)
  -- for live environment debug for the author of the quest
  example:player_debug("Spunk 2 | Brodie", true, true)
  -- again msny args can be passed here instead of with individual methods
  -- see the above source code for more info
  example:set_start_conditions({msg = start_msg, run_time = 5400})
  -- configure how the quest repeats or not
  example:repeatable(0, false)

  -- add a hook to trigger the quest start

  example:add_start_hook(10, nil, {min = 2, max = 10}, { reboot_start = true, reboot_delay = {min = 3600, max = 12000}, boot_random = 35, base = "Bassel Al-Assad", owned_by = 1 })

  -- setup the static objects used for the kill goal

  example:create_static_on_start({
    fuel_tanks = {
      template = {
        category = "Fortifications",
        shape_name = "kazarma2", -- TODO
        type = "Barracks 2", -- TODO
        dead = false,
      },
      config = {
        number_spawn = 1,
        position = Airbase.getByName('Bassel Al-Assad'):getPoint(), -- TODO
        max_radius = 10000,
        min_radius = 3000,
        owner = 0,
        site_index = 1,
      },
      conditions = {
        kill_all = true,
        kill_some = 0,
      },
    },
  })

  -- schedule messages over time

  local messages = {
    [1] = {
      "you have 60 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)",
      30 * 60
    },
    [2] = {
      "you have 30 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)",
      60 * 60
    },
    [3] = {
      "you have 10 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)",
      80 * 60
    },
  }

  for i = 1, #messages do
    example:schedule_msg(messages[i][2], messages[i][1])
  end

  -- win config, and rewards

  example:set_win_config({
    msg = "Great work! The Baniyas refinery has been neutralized and we're already noticing fewer departures from nearby red force bases.",
    reward = XQC.reward_type.intel,
    intel_points = 50,
    red_impact = {
      impact = XQC.red_impacts.lower_gce,
      gce_pct = 50,
    },
  })

  -- quest nullification trigger and config

  example:set_null_config({
    msg = "Great work taking Bassel Al Assad - we're canceling the strike mission at the Baniyas Refinery",
    fun = function(self) -- always pass self into your own functions, this represents the class and will work when i insert
      return (Airbase.getByName('Bassel Al-Assad') and (Airbase.getByName('Bassel Al-Assad'):getCoalition() == 2))
    end,
    delete_units = false,
    delete_statics = true,
    unit_behaviour = XQC.units_on_end.attack_blue_base,
  })

  -- mission fail config

  example:set_fail_config({
    msg = "It's too late - Red Force knows what were up to at Baniyas and has resupplied by other means. The refinery strike mission is cancelled.",
    delete_units = true,
    delete_statics = true,
  })

  example:start_quest()

--   example:log(jsb.tbl2(example))

  example:maintain()

  return example

  -- example return structure of object after code executed
    -- {
    --   ["assets"] = table: 0000001C489894F0     {
    --       ["static"] = table: 0000001C4972A290         {
    --           ["fuel_tanks"] = table: 0000001C49729750             {
    --               ["config"] = table: 0000001C4972A0B0                 {
    --                   ["number_spawn"] = 5,
    --                   ["position"] = table: 0000001C4972A6A0                     {
    --                       },
    --                   ["max_radius"] = 1000,
    --                   ["owner"] = 0,
    --                   ["min_radius"] = 0,
    --                   ["site_index"] = 1,
    --                   },
    --               ["template"] = table: 0000001C4972A4C0                 {
    --                   ["shape_name"] = "kazarma2",
    --                   ["type"] = "Barracks 2",
    --                   ["category"] = "Fortifications",
    --                   ["dead"] = false,
    --                   },
    --               ["conditions"] = table: 0000001C4972A100                 {
    --                   ["kill_all"] = true,
    --                   ["kill_some"] = 0,
    --                   },
    --               },
    --           },
    --       },
    --   ["time_start"] = 0,
    --   ["plyr_debug"] = "Brodie",
    --   ["flag"] = 0,
    --   ["completion"] = table: 0000001C49729E30     {
    --       ["red_impact"] = table: 0000001C4972A740         {
    --           ["gce_pct"] = 50,
    --           ["impact"] = 1,
    --           },
    --       ["msg"] = "Great work! The Baniyas refinery has been neutralized and we're already noticing fewer departures from nearby red force bases.",
    --       ["intel_points"] = 50,
    --       ["reward"] = 1,
    --       },
    --   ["msg_store"] = table: 0000001C489893B0     {
    --       [1] = table: 0000001C4972A6F0         {
    --           [1] = 1800,
    --           [2] = "you have 60 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)",
    --           },
    --       [2] = table: 0000001C49729AC0         {
    --           [1] = 3600,
    --           [2] = "you have 30 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)",
    --           },
    --       [3] = table: 0000001C4972A2E0         {
    --           [1] = 4800,
    --           [2] = "you have 10 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)",
    --           },
    --       },
    --   ["quest_type"] = 2,
    --   ["null_config"] = table: 0000001C48989F90     {
    --       ["unit_behaviour"] = 1,
    --       ["del_units"] = false,
    --       ["del_stat"] = true,
    --       ["msg"] = "Great work taking Bassel Al Assad - we're canceling the strike mission at the Baniyas Refinery",
    --       ["func"] = "function: 0000001C48B362E0, defined in (856-858)",
    --       },
    --   ["run_time"] = 5400,
    --   ["name"] = "ExampleQuest",
    --   ["tick"] = 0,
    --   ["start"] = table: 0000001C49729890     {
    --       ["delay_min"] = 300,
    --       ["delay_max"] = 1200,
    --       ["hook_event"] = 10,
    --       },
    --   ["repeatable_config"] = table: 0000001C4972A380     {
    --       ["reboot_reset"] = false,
    --       ["min_time"] = 0,
    --       ["repeatable"] = true,
    --       },
    --   ["spawned"] = table: 0000001C48989720     {
    --       ["totals"] = table: 0000001C48989860         {
    --           },
    --       },
    --   ["failure"] = table: 0000001C489894A0     {
    --       ["del_stat"] = true,
    --       ["msg"] = "It's too late - Red Force knows what were up to at Baniyas and has resupplied by other means. The refinery strike mission is cancelled.",
    --       ["del_units"] = true,
    --       },
    --   }
  --
--

-- Quest example 2
  --Repeating Quest

  --// Intercept cargo ship(s)
  --// Skynet needs resuplies by land, air and sea. Heavy equipment from foreign weapon suppliers are always transported by sea
  --// WSC (World Safety Council) decided to declare an embargo for 1 or more Banned Harbours (not using countries to stay out of politics)
  --// Players are able to influence the logistic effectivness of Skynet. As in: supplies run out, skynet can't deploy it any more 
  --// Delivered goods initiate cargo quests from the harbour to red Airbases by helo of cargo plane (if airstrip is nearby)
  --// Cargo ships are persistent

  --// Player rewards: sense of influnece, showing added value, increasing skill, credits 
  -- qeust_input = {NumBluePlayers = 0, CurrentRedAirbases = {}, SupplierHarbours = {}, BannedHarbours = {}, RouteThroughSectors = {}, CargoShip = {}, ...}

  --//set up units in demand with input from Logistic Commander

  --//Set up logic to create supply routes
    --// Which airbases are red and add them to CurrentRedAirbases --> Which Harbour is the nearest and add to SupplierHarbours --> Choose random supplier harbour and add to SupplierHarbours
    --// Check number of available BlueFor players and edit NumBluePlayers 
    
  --//Spawn units, set routes
    --//For each 5 Blue Players create a quest 
    --//Routes follow direct path from SupplierHarbour to Main Sea lane and nearby the destination the direct path to the BannedHarbour
    --//check which sector the routes are crossing and add them to RouteThroughSectors
    
    -- local start_msg = "The WSC (Word Safety Council) has responded to latest actions of Skynet.\n\n They decided to declare a weapon embargo by sea for the following harbours:\n\n"..BannedHarbours.."\n\n Intercept any cargo ships in sectors:\n\n"..RouteThroughSectors) --repeat this global messeage each hour
    
    --//Quest success
    --//For each destroyed cargo ship create a new quest (if still enough Blue Players online)
    --// Update CargoShip
    --//Player in moving zone around CargoShip and event(hit) and unit destroyed = 500 (?) credit score  

    -- local player_msg = "You've have succesfully destroyed a cargo ship, weakend skynet and executed the WSC weapon embargo!"
--