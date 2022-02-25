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
        -- return @vector: position of the first unit found matching given variables or nil

        jmr.findBlueUnit(vector, radius, object_category)

        -- a point and a radius to use which will capture all of the mission AO
        -- you can use as the vector and radius for other functions if needed to search everywhere

        jmr.mPoint, jmr.mRad
        
        ---- The DCS search area structure returned to use in your own custom search functions
        -- point @vector: (optional) search point, defaults to jmr.mPoint
        -- radius @number: (optional) radius of search area, defaults to jmr.mRad
        -- volume_type @DCS_Enum: (optional) type of search, defaults to world.VolumeType.SPHERE

        jmr.search_area(point, radius, volume_type)

        ----

        jmr.getPlayers
        
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
        } end,
      },
    }
  --
--

-- Utility misc
  --[[ -- purpose, use and documentation
    --
  ]]
--

-- Tasking functions
  --[[ -- purpose, use and documentation

    A comprehensive yet simple tasking module to control mission assets

    -- invocation
      local ai = newAI.getAI()
  ]]
--

-- C++ Functions
  --[[ -- purpose, use and documentation

    A collection of C++ mission functions to facilitate extra mission functionality

    -- invocation
      local api = jsb.getAPI()
  ]]
--