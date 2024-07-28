--control.lua

function init()
  global.watched_machines = {}
  find_machines()
  load()
end

function find_machines()
  for _, each_surface in pairs(game.surfaces) do
    for chunk in each_surface.get_chunks() do
      local entities = each_surface.find_entities_filtered{type={"assembling-machine","furnace"}, area={{chunk.x*32, chunk.y*32}, {(chunk.x+1)*32, (chunk.y+1)*32}}}
      for _, entity in pairs(entities) do
          if entity.products_finished == 0 then
            table.insert(global.watched_machines, {machine = entity, box = add_box(entity)})
          end
      end
    end
  end
end

function load()
  -- start the timer for polling
  set_timer()
end

function add_box(machine)
  -- add box to machine
  local box = machine.surface.create_entity{
    name = "highlight-box",
    position = {0, 0},  -- Ignored by game
    bounding_box = selection_box,
    box_type = "not-allowed",
    target = machine,
    blink_interval = 30
  }
  
  return box
end

function machine_added(event)
  -- add to list of watched machines
  table.insert(global.watched_machines, {machine = event.created_entity, box = add_box(event.created_entity)})
end

function machine_removed(event)
  -- check if in list of watched machines and remove if so
  for id, entry in pairs(global.watched_machines) do
    if entry["machine"] == event.entity then
      remove_machine(id)
    end
  end
end

function remove_machine(id)
  -- remove box from machine
  global.watched_machines[id]["box"].destroy()

  -- remove from list of watched machines
  table.remove(global.watched_machines, id)
end

function poller()
  -- check each watched machine and see if it has produced, if so remove it from our monitoring
  for id, entry in pairs(global.watched_machines) do
    if entry["machine"].products_finished ~= 0 then
      remove_machine(id)
    end
  end
end

function set_timer()
  -- stop the poller and start a new one
  script.on_nth_tick(nil)
  script.on_nth_tick(settings.global["broken-machines-refresh-interval"].value * 60, poller)
end

-- init, load, and mod change events
script.on_init(init)
script.on_configuration_changed(init)
script.on_load(load)

-- config change
script.on_event(defines.events.on_runtime_mod_setting_changed, set_timer)

-- events for new machines being built
script.on_event(defines.events.on_built_entity, machine_added, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})
script.on_event(defines.events.on_robot_built_entity, machine_added, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})
script.on_event(defines.events.script_raised_revive, machine_added, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})
script.on_event(defines.events.script_raised_built, machine_added, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})

-- events for existing machines being removed
script.on_event(defines.events.on_player_mined_entity, machine_removed, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})
script.on_event(defines.events.on_robot_pre_mined, machine_removed, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})
script.on_event(defines.events.on_entity_died, machine_removed, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})
script.on_event(defines.events.script_raised_destroy, machine_removed, {{filter = "type", type = "assembling-machine"}, {filter = "type", type = "furnace"}})