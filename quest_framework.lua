-- XSAF Quest Framework

-- global calls
--

XQF = {} -- global quest framework container

-- locals
  local ingame_feedback = true -- if true log messages will be replicated ingame too
  local ingame_display = 40 -- time on screen for ingame messages
  local ingame_clear = false -- clearview on message ingame
  local _time = function(n) return timer.getTime()+(n or 0) end
  local _log = function(fmt,...) local msg = "JSB.XQF: "..string.format(fmt or "",...) env.info(msg) if ingame_feedback then trigger.action.outText(msg, ingame_display, ingame_clear) end end
  local trigger_get_zone = trigger.misc.getZone
  local sZones = globalOptions.spawn.red.zRef
  local _,jmr,ai,boom,veh_templ,has_attribute
  timer.scheduleFunction(function()
    has_attribute = aiMed.cache()
    _ = aiMed.fun
    jmr = _.getJMR()
    ai = newAI.getAI()
    boom = jsb.boom
    veh_templ = Spm.get("xsafAbr", 2, 'vehicle', 'cmdo_veh')
  end,nil,_time(9.5))
  local troops = spManager.callSpawns().spc[4][1]
  local deepCopy = pMan.deepCopy
  local do_not_save = DONOTSAVE
--

-- data
  local xqc = {
    coalition = {},
    personal = {},
    config = {},
  } -- local data
--

-- Quest Class
  XQC = {} -- global class container

  local xqm = {} -- shared methods
  local xqmp = {} -- personal methods
  local xqmc = {} -- coalition methods

  -- methods

    --[[
      a way to;
        construct quest
          have a begin, goal/s, {...}, win condition, end, result, reward
        track progress of player
    ]]

    -- personal
      -- player related funs
    --

    -- coslition
      -- global msg out

      -- adds a hook to start the quest
      -- fun @funciton (optional): can be used to inject a custom function on start
      -- event_id @DCS_Enum: the event id that will trigger quest to start
      -- delays @number/@table (optional): if number then quest starts event + delay, if table { min = n (optoinal), max = n } then will be random time min/max if just max then random 0-max
      -- return: nil
      function xqmc:add_start_hook(event_id, fun, delays)
        self.start.hook_func = fun or nil
        self.start.hook_event = event_id
        if delays then
          self.start.delay_min = delays.min
          self.start.delay_max = delays.max
        end
      end
    --

    -- shared
      -- data saving and recovery

      -- set to started, adds a time stamp, increases flag number to 1, runs the quest start params

      function xqm:set_start_conditions(args)
        if args.fun then
          self.start.start_func = args.fun
        elseif args.msg then
          self.start.msg = args.msg
        end
      end

      -- return: nil
      function xqm:start()
        self.time_start = _time()
        self:inc()
      end

      -- return: nil
      function xqm:set_runtime(n)
        self.run_time = n
      end

      -- increases flag by n @number, or 1 if n is nil
      -- return: nil
      function xqm:inc(n)
        self.flag = n or (self.flag + 1)
      end
    --

    -- construct the metamethods from shared + methods passed
    -- return: table of merged methods
    function method_construct(method_to_merge)
      local to_merge = {method_to_merge, xqm}
      local merged = {}
      for i = 1, 2 do
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
    }
  --

  -- local function to take personal quest params and create object
  -- return: quest object with methods or nil if fail
  local function personal_quest(setup)
    if not setup.player_name then return end
    xqc.personal[setup.player_name] = {
      player_name = setup.player_name,
      time_start = 0,
      quest_type = setup.quest_type,
      flag = 0,
      -- optional args at setup, may need to be added later by implicit method call
        run_time = setup.run_time or nil,
        spin_func = setup.spin_fun or nil,
        start = {
          start_func = nil,
          msg = nil,
        },
      --
    }
    setmetatable(xqc.personal[setup.player_name], { __index = method_construct(xqmp) })
    return xqc.personal[setup.player_name]
  end

  -- local function to take coalition quest params and create object
  -- return: quest object with methods or nil if fail
  local function coalition_quest(setup)
    local index = #xqc.coalition+1
    xqc.coalition[index] = {
      time_start = 0,
      quest_type = setup.quest_type,
      flag = 0,
      -- optional args at setup, may need to be added later by implicit method call
        run_time = setup.run_time or nil,
        spin_time = setup.spin_time or nil,
        spin_func = setup.spin_fun or nil,
        start = {
          start_func = nil,
          msg = nil,
          hook_func = nil,
          hook_event = nil,
        },
      --
    }
    setmetatable(xqc.coalition[index], { __index = method_construct(xqmc) })
    return xqc.coalition[index]
  end

  -- To create a quest object
  -- setup{...};
  -- personal @bool, identifies if is a personal quest
  -- player_name @string, required if a personal quest
  -- return: quest object with methods or nil if fail
  function XQC.newQuest(setup)
    if setup.personal then
      return personal_quest(setup)
    end
    return coalition_quest(setup)
  end
--

-- quest story board
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

-- Simple Quest
  -- //Baniyas Refinery Mission
  -- // This mission instructs blue to destroy fuel storage tanks at a refinery 
  -- // the reward would be reduced red flights out of Bassel, hama, AQ and Rene for 3 hours

  local example = XQC.newQuest({})

  -- if(BASSEL is RED  ){
  -- 	// only spawn this mission if bassel is red

  example:add_start_hook(10, nil, {min = 300, max = 1200})

  -- 	// set timer - blue has 90 minutes to complete mission

  example:set_runtime(5400)
    
  -- 	// spawn protection force
  -- 	// spawn a series of sams and ground units protecting the refinery
    
    
  -- 	//create 4 point trigger zone with specifc coords around the tanks
    
  -- 	// use the MAP OBJECT IS DEAD trigger and assign trigger zone for mission completion
  -- 	// create a trigger to detect blue taking Bassel
    
    
  -- 	//mission start message
  -- 	Message to Blue: "Intelligence has uncovered that Red Force is highly dependant on the Baniyas Refinery located near N35 13 00 E35 58 00. 
  -- 	Your mission is to destroy all 40 fuel tanks on the north side of the refinery and you have 90 minutes to do so. 
  -- 	We believe success will lead to few red air activity for the next several hours."
    
    
    
  -- 	//after 30 elapsed minutes: 
  -- 	Message to Blue: "you have 60 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)"
    
  -- 	//after 60 mins
  -- 	Message to Blue: "you have 30 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)"
    
  -- 	// after 80 mins
  -- 	Message to Blue: "you have 10 minutes to destroy the Baniyas refinery (N35 13 00 E35 58 00)"
    
  -- 	map object dead trigger complete {
  -- 		Message to blue: "Great work! The Baniyas refinery has been neutralized and we're already noticing fewer departures from nearby red force bases." 
  -- 		// give reward:
      
  -- 		//im not sure how you would get skynet to do this on your side - maybe reduce the fuel to those 4 bases (if red) 
  -- 		// or maybe you have another way to close/reduce flights from them?
      
  -- 		// also Give 50 intel points
  -- 		// mission ends
  -- 	}
    
  -- 	bassel captured by blue trigger{
  -- 		// mission ends
  -- 		// no reward, no penalty
  -- 		// units created for the mission begin driving to bassel :)
  -- 		Message to Blue: "Great work taking Bassel Al Assad - we're canceling the strike mission at the Baniyas Refinery
      
  -- 	}
    
  -- 	time expires trigger{
    
  -- 		message to blue: "It's too late - Red Force knows what were up to at Baniyas and has resupplied by other means. The refinery strike mission is cancelled."
  -- 		// mission ends
  -- 	}
    
    
    
    
  -- }
--