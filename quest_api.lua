-- XSAF Mission Quest API

-- XSAF Quest Framework V1.0
  --[[ -- purpose, use and documentation
    --
  ]]
  -- for debug
    local debug_fun = function() return end
  --
--

-- Core mission functions
  --[[ -- purpose, use and documentation

    A set of key functions to action various tasks like saving data, printing to log and to the mission

    -- invocation
      local jsb_core = jsb.getCore()

      ---- simple log function
      -- fmt @string: format of string, lua convention
      -- vararg ... @any (optional): any args for the format
      -- return: nil

        jsb.log(fmt, ...)

      --- global screen print
      -- msg @ string
      -- duration @number in seconds to display
      -- clear @bool: screen clear if true

        jsb.jsb_say( msg, duration, clear )

      --- data saving
      -- data @table
      -- file_name @string
      -- table_name @string will be the table name in the save, required...

        jsb.save(data, file_name, table_name)

      --- table copy function without any metamethod copy
      -- data @table
      -- return @table: the copy

        jsb.shallowCopy(data)

      --- table copy function and metamethod copy
      -- data @table
      -- return @table: the copy

        jsb.deepCopy(data)

      --- data loading
      -- file_name @string

        jsb.load(file_name)

      --- return a DCS flag value
      -- flag_name @string
      -- return @number (0/1 is true or false)

        jsb.chflg(flag_name)

      --- makes badamooms
      -- position @vector3
      -- power @float(number): I normally use 0.000001 for effect and no damage...

        jsb.boom(position, power)

      --- return the mission time (Overloaded)
      -- time @number: if you use this is a timer.scheduleFunction call then put the variable in the perenthesese that way a calendar search is done to return a time
      -- that will not clash with another callback time, so the return will not be time + time exact. If you want exact then do time() + time ...
      -- return @number: DCS time + time (adjusted for callback)

        jsb.time(time)

        --- a shortened string.format
        -- fmt, ...

        jsb.fstr(fmt, ...)

  -- for debug
    jsb.getCore = function() return {
      log = debug_fun,
      say = debug_fun,
      save = debug_fun,
      chflg = debug_fun,
      time = debug_fun,
      fstr = debug_fun,
      shallowCopy = debug_fun,
      deepCopy = debug_fun,
      boom = debug_fun,
      load = debug_fun,
    } end
  --
  ]]
--

-- JMR functions
  --[[ -- purpose, use and documentation

    The JMR module is used to query mission objects, generation of vectors

    -- invocation
      local jmr = aiMed.fun.getJMR()

    -- function documentation

        ---- Get the forward speed of an object
        -- unit_object @DCS_UNIT
        -- return: The velocity of the given unit in KPH

          jmr.getKMH(unit_object)

        ---- A way to specifically confirm if any blue object is in a given place
        -- vector @vector: 3D vector of search area
        -- radius @number: (optional) meters of search radius or if nil 7,500m
        -- category @number: (optional) DCS_Enum of object category
        -- return @vector3: position of the first unit found matching given variables or nil

          jmr.findBlueUnit(vector, radius, object_category)

        -- a point and a radius to use which will capture all of the mission AO
        -- you can use as the vector and radius for other functions if needed to search everywhere
        -- return @vector3 and @number

          jmr.mPoint, jmr.mRad
        
        ---- The DCS search area structure returned to use in your own custom search functions
        -- point @vector: (optional) search point, defaults to jmr.mPoint
        -- radius @number: (optional) radius of search area, defaults to jmr.mRad
        -- volume_type @DCS_Enum: (optional) type of search, defaults to world.VolumeType.SPHERE
        -- return @table: Search area structure

          jmr.search_area(point, radius, volume_type)

        ---- A DCS search area function wrapper with overloaded args, a better solution below if only want to search
        -- zone_area @string or @vector: if its a string it assumes its part of an internal database or zones, else pass in a vector/point table.
        -- item_type @DCS_Enum: 
        -- item_name @string (optional): if looking for a specific object supply a name
        -- delete @bool (optional): if you want to delete what you find, use true
        -- search_size @number: radius from the point to define search area
        -- return @bool/@string (typename of object found)

          jmr.areaSearch(zone_area, item_type, item_name, delete, search_size)

        ----

        ---- Find players at a given location
        -- vector @vector3 (optional): if none given then use mPoint by default
        -- area @number (optional): if none given then use mRad by default
        -- return @array: all DCS_Units found of player type in the params given

          jmr.getPlayers(vector, area)
        
        ----
        
        jmr.inZone

        ----
        
        jmr.findUnits

        ----
        
        jmr.countInZone

        ----
        
        jmr.getWeapons

        ----
        
        jmr.getBaseClose
        
        ----
        
        jmr.random
        
        ----
        
        jmr.randomPoint
        
        ----
        
        jmr.middle

        ---- query the owner of an airbase
        -- base_name @string: the name of the airbase
        -- return @DCS_Enum: the owner of the base

        jmr.getOwner(base_name)
      }
  ]]

  -- for debug
    aiMed = {
      fun = {
        getJMR = function() return {
          mPoint = {},
          mRad = 220,
          search_area = debug_fun,
          middle = debug_fun,
          randomPoint = debug_fun,
          random = debug_fun,
          getBaseClose = debug_fun,
          getWeapons = debug_fun,
          countInZone = debug_fun,
          findUnits = debug_fun,
          inZone = debug_fun,
          getPlayers = debug_fun,
          findBlueUnit = debug_fun,
          getKMH = debug_fun,
          getOwner = debug_fun,
        } end,
      },
    }
  --
--

-- Utility misc
  --[[ -- purpose, use and documentation

    ---- additionals in std library: table

    ---- return a line by line concat list of all the keys as a single string
    -- table @table: table to print from
    -- return @string: list of all the keys

    table.keys(table)

    ---- return a random key from a key, value table
    -- table @table: table to reference
    -- return @string: random key

    table.randomKey(table)

  ]]

-- XQF - XSAF Quest Framework
  --[[ -- purpose, use and documentation

    ---- end to end solution to easily script a quest, will be populated on framework completion.
    ---- Please reference the quest_framework.lua

    ----
    --
    --

    example_function

  ]] 

  ---- simple code to add to mission to enable a faux console to be able to live load code into the mission for testing
  ---- instead of having to restart. Place log outputs for returns or ingame print for quick feedback
  -- use: create a file in DCS_Install/Root called jsb_console.lua, inside write any code you like
  -- WARNING: This is crude and simple, there is no exception handling here thats your responsibility

  local load_script = function() dofile('jsb_console.lua') end

  -- create a menu for blue
  debugMenu = missionCommands.addSubMenuForCoalition(2, "Debug menu")
  missionCommands.addCommandForCoalition(2, "Load code", debugMenu, load_script)
--

-- Tasking functions
  --[[ -- purpose, use and documentation

    A comprehensive yet simple tasking module to control mission assets

    -- invocation
      local ai = newAI.getAI()

      this is a hard one for me to document, but this module takes a single line call and does the rest, with args to suit your request.
      taskings it can handle for you ...

      strike_function -- (Air) objects strike
      denial_function -- (Air) runway denial
      multi_function -- (Air) single or multi targets
      land_function -- (Air) will direct a plane to land, and if asked for re-arm and re-fuel and continue task
      multiGnd_function -- (Ground) single or multi target
      aiescort_function -- (Air) complex sub module to create anm escort for another
      aifollow_function -- (Air/Ground) simple follow
      patrol_function -- (Air/Ground) a set of points that will be looped, or a cool random 25nm radius random spiragraph pattern using 1 central point
      aero_function -- (Air) perform aerobatic move
      intercept_function -- (Air) intercept and engage specific target
      helo_log_function -- tell a helo to move a crate from A>B
      para_function -- paratrooper drop
      move_function -- WIP??

      the simplicity of this is can be called like this...

      ai.register( newAI.role.<ROLE>, { no_option = true, point = base_pos, types = "Ground Units", dist = 15000, alt = 5250 } )

      Talk to me abou this one, as it will take me an age to document it, its complicated and really powerful. It's not just a fire and forget,
      it makes sure a thing does a thing or else tries to ensure it does that thing again.
  ]]
--

-- C++ Functions
  --[[ -- purpose, use and documentation

    A collection of C++ mission functions to facilitate extra mission functionality

    -- invocation
      local api = jsb.getAPI()

      --- adds specific weapons to an airbase warehouse
      -- base @string: receiving airbase
      -- clsid @string: the clsid of said item to add

      api.addWeapon(base, clsid)
  ]]
--