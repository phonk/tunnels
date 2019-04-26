-- glut
--
-- granular sampler in progress
-- (currently requires a grid)
--
-- trigger voices
-- using grid rows 2-8
--
-- mute voices and record
-- patterns using grid row 1
--

engine.name = 'Glut'
local g = grid.connect()

local tn = include('lib/tunnel')


local VOICES = 7

local positions = {}
local gates = {}
local voice_levels = {}

for i=1, VOICES do
  positions[i] = -1
  gates[i] = 0
  voice_levels[i] = 0
end

local gridbuf = require 'lib/gridbuf'
local grid_ctl = gridbuf.new(16, 8)
local grid_voc = gridbuf.new(16, 8)

local metro_grid_refresh
local metro_blink

--[[
recorder
]]

local pattern_banks = {}
local pattern_timers = {}
local pattern_leds = {} -- for displaying button presses
local pattern_positions = {} -- playback positions
local record_bank = -1
local record_prevtime = -1
local record_length = -1
local alt = false
local blink = 0
local metro_blink

local tunnelmode = 0
local printmode = "tunnels off"
local tunnelgroup

local function tunnels_pan()
  if tunnelgroup == 1 then
    softcut.pan(1, math.random(70, 80) * 0.01)
    softcut.pan(4, math.random(30, 45) * 0.01)
  elseif tunnelgroup == 2 then
    softcut.pan(2, math.random(20, 30) * 0.01)
    softcut.pan(3, math.random(55, 70) * 0.01)
  end
end

local function update_tunnels()
  -- set panning
  tunnels_pan()
    
	-- reset filters before changing (as some modes don't use)
  for i=1,4 do 
    softcut.level(i, 1)
    softcut.filter_dry(i, 0.5)
	  softcut.filter_lp(i, 0)
	  softcut.filter_bp(i, 1.0)
	  softcut.filter_rq(i, 2.0)
  end
  params:set("filter_fc3", math.random(40, 80))
  params:set("filter_fc4", math.random(80, 150))
  params:set("filter_fc2", math.random(150, 300))
  params:set("filter_fc1", math.random(300, 1000))
	
	-- specific modes
	
	-- delay off
	if tunnelmode == 0 then
	  for i=1, 4 do
	    softcut.level(i, 0)
	  end

	-- fractal landscape
	elseif tunnelmode == 1 then
	  if tunnelgroup == 1 then
	    for i=1, 2 do
	      params:set("delay_rate"..i, math.random(0, 250) * 0.01)
	      params:set("fade_time"..i, math.random(0, 6) * 0.1)
  	    softcut.loop_end(i, math.random(50, 500) * 0.01)
    	  softcut.position(i, math.random(0, 10) * 0.1)
    	  params:set("delay_feedback"..i, math.random(10, 90) * 0.01)
    	  params:set("filter_fc"..i, math.random(40, 1500))
  	  end
	  elseif tunnelgroup == 2 then
	    for i=3, 4 do
	      params:set("delay_rate"..i, math.random(0, 250) * 0.01)
	      params:set("fade_time"..i, math.random(0, 6) * 0.1)
  	    softcut.loop_end(i, math.random(50, 500) * 0.01)
    	  softcut.position(i, math.random(0, 10) * 0.1)
    	  params:set("delay_feedback"..i, math.random(10, 90) * 0.01)
    	  params:set("filter_fc"..i, math.random(40, 1500))
  	  end
	  end
  	
  --disemboguement	
  elseif tunnelmode == 2 then
    if tunnelgroup == 1 then
      params:set("filter_fc1", math.random(40, 400))
      params:set("filter_fc2", math.random(400, 800))
      for i=1, 2 do 
        params:set("delay_rate"..i, math.random(1, 10) * 0.1)
        params:set("fade_time"..i, math.random(0, 20) * 0.1)
        softcut.position(i, math.random(0, 10) * 0.1)
        params:set("delay_feedback"..i, math.random(10, 80) * 0.01)
        softcut.loop_end(i, math.random(5, 30) * 0.01)
      end
    elseif tunnelgroup == 2 then
      params:set("filter_fc3", math.random(40, 400))
      params:set("filter_fc4", math.random(400, 800))
      for i=3, 4 do 
        params:set("delay_rate"..i, math.random(-10, -1) * 0.1)
        params:set("fade_time"..i, math.random(0, 20) * 0.1)
        softcut.position(i, math.random(0, 10) * 0.1)
        params:set("delay_feedback"..i, math.random(10, 80) * 0.01)
        softcut.loop_end(i, math.random(30, 50) * 0.01)
      end
    end
  
   --post-horizon
  elseif tunnelmode == 3 then
    if tunnelgroup == 1 then
      for i=1, 2 do 
        params:set("delay_rate"..i, math.random(1, 10) * 0.1)
        params:set("fade_time"..i, math.random(50, 100) * 0.01)
        softcut.position(i, math.random(0, 10) * 0.1)
        softcut.loop_end(i, math.random(100, 1000) * 0.01)
        params:set("delay_feedback"..i, math.random(10, 80) * 0.01)
        softcut.filter_bp(i, math.random(0, 100) * 0.01)
        params:set("filter_fc"..i, math.random(400, 2000))
      end
    elseif tunnelgroup == 2 then
      for i=3, 4 do 
        params:set("delay_rate"..i, math.random(-10, -1) * 0.1)
        params:set("fade_time"..i, math.random(50, 100) * 0.01)
        softcut.position(i, math.random(0, 10) * 0.1)
        softcut.loop_end(i, math.random(100, 1000) * 0.01)
        params:set("delay_feedback"..i, math.random(10, 80) * 0.01)
        softcut.filter_bp(i, math.random(0, 100) * 0.01)
        params:set("filter_fc"..i, math.random(400, 2000))
      end
    end
    
  --coded air
  elseif tunnelmode == 4 then
    if tunnelgroup == 1 then
      for i=1, 2 do 
        params:set("delay_feedback"..i, math.random(50, 75) * 0.01)
        params:set("delay_rate"..i, math.random(-100, 0) * 0.02)
        softcut.loop_end(i, math.random(10, 500) * .01)
      end
    elseif tunnelgroup == 2 then
      for i=3, 4 do 
        params:set("delay_feedback"..i, math.random(0, 50) * 0.01)
        params:set("delay_rate"..i, math.random(-100, 0) * 0.02)
        softcut.loop_end(i, math.random(10, 500) * .01)
      end
    end
    
  --failing lantern
  elseif tunnelmode == 5 then
    if tunnelgroup == 1 then
      for i=1, 2 do
        params:set("delay_rate"..i, math.random(10, 25) * 0.1)
        --softcut.loop_start(i, math.random(0, 50) * 0.01)
        softcut.loop_end(i, math.random(6, 10))
        params:set("delay_feedback"..i, math.random(10, 30) * 0.01)
        params:set("fade_time"..i, math.random(0, 40) * 0.1)
      end
    elseif tunnelgroup == 2 then
      for i=3, 4 do 
        params:set("delay_rate"..i, math.random(10, 25) * 0.1)
        softcut.loop_end(i, math.random(4,6))
        params:set("delay_feedback"..i, math.random(10, 30) * 0.01)
        params:set("fade_time"..i, math.random(0, 40) * 0.1)
      end
    end
    
  -- blue cat
	elseif tunnelmode == 6 then
	  if tunnelgroup == 1 then
	    for i=1, 2 do
	      params:set("delay_rate"..i, math.random(0, 80) * 0.1)
  	    params:set("fade_time"..i, math.random(0, 6) * 0.1)
  	    softcut.position(i, math.random(0, 10) * 0.1)
  	    params:set("delay_feedback"..i, math.random(0, 100) * 0.01)
  	  end
	  elseif tunnelgroup == 2 then
	    for i=3, 4 do
  	    params:set("delay_rate"..i, math.random(0, 80) * 0.1)
  	    params:set("fade_time"..i, math.random(0, 6) * 0.1)
  	    softcut.position(i, math.random(0, 10) * 0.1)
  	    params:set("delay_feedback"..i, math.random(0, 100) * 0.01)
  	  end
	  end
	  
  -- crawler
	elseif tunnelmode == 7 then
	  for i=1, 4 do
	    softcut.filter_dry(i, 0.25)
	    softcut.loop_start(i, 0)
	    softcut.position(i, 0)
	  end
	  softcut.loop_end(1, .1)
	  softcut.loop_end(2, .4)
	  softcut.loop_end(3, .2)
	  softcut.loop_end(4, .3)
	  if tunnelgroup == 1 then
	    for i=1, 2 do
  	    params:set("delay_rate"..i, math.random(5, 15) * 0.1)
  	    softcut.fade_time(i, math.random(0, 6) * 0.1)
  	    params:set("delay_feedback"..i, math.random(0, 100) * 0.01)
  	  end
	  elseif tunnelgroup == 2 then
	    for i=3, 4 do
  	    params:set("delay_rate"..i, math.random(5, 15) * 0.1)
  	    softcut.fade_time(i, math.random(0, 6) * 0.1)
  	    params:set("delay_feedback"..i, math.random(0, 100) * 0.01)
  	  end
	  end
  end
end

local function record_event(x, y, z)
  if record_bank > 0 then
    -- record first event tick
    local current_time = util.time()

    if record_prevtime < 0 then
      record_prevtime = current_time
    end

    local time_delta = current_time - record_prevtime
    table.insert(pattern_banks[record_bank], {time_delta, x, y, z})
    record_prevtime = current_time
  end
end

local function start_playback(n)
  pattern_timers[n]:start(0.001, 1) -- TODO: timer doesn't start immediately with zero
end

local function stop_playback(n)
  pattern_timers[n]:stop()
  pattern_positions[n] = 1
end

local function arm_recording(n)
  record_bank = n
end

local function stop_recording()
  local recorded_events = #pattern_banks[record_bank]

  if recorded_events > 0 then
    -- save last delta to first event
    local current_time = util.time()
    local final_delta = current_time - record_prevtime
    pattern_banks[record_bank][1][1] = final_delta

    start_playback(record_bank)
  end

  record_bank = -1
  record_prevtime = -1
end

local function pattern_next(n)
  local bank = pattern_banks[n]
  local pos = pattern_positions[n]

  local event = bank[pos]
  local delta, x, y, z = table.unpack(event)
  pattern_leds[n] = z
  grid_key(x, y, z, true)

  local next_pos = pos + 1
  if next_pos > #bank then
    next_pos = 1
  end

  local next_event = bank[next_pos]
  local next_delta = next_event[1]
  pattern_positions[n] = next_pos

  -- schedule next event
  pattern_timers[n]:start(next_delta, 1)
end

local function record_handler(n)
  if alt then
    -- clear pattern
    if n == record_bank then stop_recording() end
    if pattern_timers[n].is_running then stop_playback(n) end
    pattern_banks[n] = {}
    do return end
  end

  if n == record_bank then
    -- stop if pressed current recording
    stop_recording()
  else
    local pattern = pattern_banks[n]

    if #pattern > 0 then
      -- toggle playback if there's data
      if pattern_timers[n].is_running then stop_playback(n) else start_playback(n) end
    else
      -- stop recording if it's happening
      if record_bank > 0 then
        stop_recording()
      end
      -- arm new pattern for recording
      arm_recording(n)
    end
  end
end

--[[
internals
]]

local function display_voice(phase, width)
  local pos = phase * width

  local levels = {}
  for i = 1, width do levels[i] = 0 end

  local left = math.floor(pos)
  local index_left = left + 1
  local dist_left = math.abs(pos - left)

  local right = math.floor(pos + 1)
  local index_right = right + 1
  local dist_right = math.abs(pos - right)

  if index_left < 1 then index_left = width end
  if index_left > width then index_left = 1 end

  if index_right < 1 then index_right = width end
  if index_right > width then index_right = 1 end

  levels[index_left] = math.floor(math.abs(1 - dist_left) * 15)
  levels[index_right] = math.floor(math.abs(1 - dist_right) * 15)

  return levels
end

local function start_voice(voice, pos)
  engine.seek(voice, pos)
  engine.gate(voice, 1)
  gates[voice] = 1
end

local function stop_voice(voice)
  gates[voice] = 0
  engine.gate(voice, 0)
end

local function grid_refresh()
  if g == nil then
    return
  end

  grid_ctl:led_level_all(0)
  grid_voc:led_level_all(0)

  -- alt
  grid_ctl:led_level_set(16, 1, alt and 15 or 1)

  -- pattern banks
  for i=1, VOICES do
    local level = 2

    if #pattern_banks[i] > 0 then level = 5 end
    if pattern_timers[i].is_running then
      level = 10
      if pattern_leds[i] > 0 then
        level = 12
      end
    end

    grid_ctl:led_level_set(8 + i, 1, level)
  end

  -- blink armed pattern
  if record_bank > 0 then
      grid_ctl:led_level_set(8 + record_bank, 1, 15 * blink)
  end

  -- voices
  for i=1, VOICES do
    if voice_levels[i] > 0 then
      grid_ctl:led_level_set(i, 1, math.min(math.ceil(voice_levels[i] * 15), 15))
      grid_voc:led_level_row(1, i + 1, display_voice(positions[i], 16))
    end
  end

  local buf = grid_ctl | grid_voc
  buf:render(g)
  g:refresh()
end

function grid_key(x, y, z, skip_record)
  if y > 1 or (y == 1 and x < 9) then
    if not skip_record then
      record_event(x, y, z)
    end
  end

  if z > 0 then
    -- set voice pos
    if y > 1 then
      local voice = y - 1
      start_voice(voice, (x - 1) / 16)
    else
      if x == 16 then
        -- alt
        alt = true
      elseif x > 8 then
        record_handler(x - 8)
      elseif x == 8 then
        -- reserved
      elseif x < 8 then
        -- stop
        local voice = x
        stop_voice(voice)
      end
    end
  else
    -- alt
    if x == 16 and y == 1 then alt = false end
  end
end

function init()
  g.key = function(x, y, z)
    grid_key(x, y, z)
  end

  -- polls
  for v = 1, VOICES do
    local phase_poll = poll.set('phase_' .. v, function(pos) positions[v] = pos end)
    phase_poll.time = 0.05
    phase_poll:start()

    local level_poll = poll.set('level_' .. v, function(lvl) voice_levels[v] = lvl end)
    level_poll.time = 0.05
    level_poll:start()
  end

  -- recorders
  for v = 1, VOICES do
    table.insert(pattern_timers, metro.init(function(tick) pattern_next(v) end))
    table.insert(pattern_banks, {})
    table.insert(pattern_leds, 0)
    table.insert(pattern_positions, 1)
  end

  -- grid refresh timer, 40 fps
  metro_grid_refresh = metro.init(function(stage) grid_refresh() end, 1 / 40)
  metro_grid_refresh:start()

  metro_blink = metro.init(function(stage) blink = blink ~ 1 end, 1 / 4)
  metro_blink:start()

  local sep = ": "

  params:add_taper("reverb_mix", "*"..sep.."mix", 0, 100, 50, 0, "%")
  params:set_action("reverb_mix", function(value) engine.reverb_mix(value / 100) end)

  params:add_taper("reverb_room", "*"..sep.."room", 0, 100, 50, 0, "%")
  params:set_action("reverb_room", function(value) engine.reverb_room(value / 100) end)

  params:add_taper("reverb_damp", "*"..sep.."damp", 0, 100, 50, 0, "%")
  params:set_action("reverb_damp", function(value) engine.reverb_damp(value / 100) end)

  for v = 1, VOICES do
    params:add_separator()

    params:add_file(v.."sample", v..sep.."sample")
    params:set_action(v.."sample", function(file) engine.read(v, file) end)

    params:add_taper(v.."volume", v..sep.."volume", -60, 20, 0, 0, "dB")
    params:set_action(v.."volume", function(value) engine.volume(v, math.pow(10, value / 20)) end)

    params:add_taper(v.."speed", v..sep.."speed", -200, 200, 100, 0, "%")
    params:set_action(v.."speed", function(value) engine.speed(v, value / 100) end)

    params:add_taper(v.."jitter", v..sep.."jitter", 0, 500, 0, 5, "ms")
    params:set_action(v.."jitter", function(value) engine.jitter(v, value / 1000) end)

    params:add_taper(v.."size", v..sep.."size", 1, 500, 100, 5, "ms")
    params:set_action(v.."size", function(value) engine.size(v, value / 1000) end)

    params:add_taper(v.."density", v..sep.."density", 0, 512, 20, 6, "hz")
    params:set_action(v.."density", function(value) engine.density(v, value) end)

    params:add_taper(v.."pitch", v..sep.."pitch", -24, 24, 0, 0, "st")
    params:set_action(v.."pitch", function(value) engine.pitch(v, math.pow(0.5, -value / 12)) end)

    params:add_taper(v.."spread", v..sep.."spread", 0, 100, 0, 0, "%")
    params:set_action(v.."spread", function(value) engine.spread(v, value / 100) end)

    params:add_taper(v.."fade", v..sep.."att / dec", 1, 9000, 1000, 3, "ms")
    params:set_action(v.."fade", function(value) engine.envscale(v, value / 1000) end)
  end

  params:bang()
  tn.init()
end

--[[
exports
]]

function enc(n, d)
end

-- Key input
function key(n, z)
  if z == 1 then
    if n == 1 then
      if tunnelmode == 0 then
        tunnelmode = 1
      elseif tunnelmode == 1 then
        tunnelmode = 2
      elseif tunnelmode == 2 then
        tunnelmode = 3
      elseif tunnelmode == 3 then
        tunnelmode = 4
      elseif tunnelmode == 4 then
        tunnelmode = 5
      elseif tunnelmode == 5 then
        tunnelmode = 6
      elseif tunnelmode == 6 then
        tunnelmode = 7
      elseif tunnelmode == 7 then
        tunnelmode = 0
      end
      softcut.buffer_clear()
      tunnelgroup = 1
      update_tunnels()
      tunnelgroup = 2
      update_tunnels()
      redraw()
    elseif n == 2 then
      tunnelgroup = 1
      update_tunnels()
      redraw()
    elseif n == 3 then
      tunnelgroup = 2
      update_tunnels()
      redraw()
    end
  end
end

function redraw()
  -- do return end
  screen.clear()
  screen.level(15)
  
  if tunnelmode == 0 then
    printmode = "tunnels off"
  elseif tunnelmode == 1 then
    printmode = "fractal landscape"
  elseif tunnelmode == 2 then
    printmode = "disemboguement"
  elseif tunnelmode == 3 then
    printmode = "post-horizon"
  elseif tunnelmode == 4 then
    printmode = "coded air"
  elseif tunnelmode == 5 then
    printmode = "failing lantern"
  elseif tunnelmode == 6 then
    printmode = "blue cat"
  elseif tunnelmode == 7 then
    printmode = "crawler"
  end

  screen.move(0, 10)
  screen.text("^ load samples")
  screen.move(0, 20)
  screen.text("  via menu > parameters")
  
  screen.move(10,56)
	screen.font_size(8)
	screen.text(printmode)

  screen.update()
end