local construction_robot = require("construction-robot")

local kr_air_purifier = {}

function kr_air_purifier.init()
  global.filter_deliveries = {}

  global["kr-air-purifiers"] = {}

    for _, surface in pairs(game.surfaces) do
      for _, entity in pairs(surface.find_entities_filtered{name = "kr-air-purifier"}) do
        table.insert(global["kr-air-purifiers"], entity)
      end
    end
end

function kr_air_purifier.on_created_entity(event)
  local entity = event.created_entity or event.entity or event.destination
  if not (entity and entity.valid) then return end

  if entity.name == "kr-air-purifier" then
    table.insert(global["kr-air-purifiers"], entity)
    construction_robot.deliver(entity, {["pollution-filter"] = 2})
  end
end

function kr_air_purifier.on_entity_destroyed(event)
  if global.filter_deliveries[event.unit_number] then
  -- "item-request-proxy" on a "kr-air-purifier"

    local position = global.filter_deliveries[event.unit_number]
    local surface = game.get_surface(position.surface_index)
    if surface then
    -- surface exists

      local purifier = surface.find_entity("kr-air-purifier", {position.x, position.y})
      if purifier and purifier.valid then
      -- purifier exists

        local used_filters = purifier.get_inventory(defines.inventory.furnace_result)
        if not used_filters.is_empty() then
        -- has empty filters to extract

          local entity = surface.find_entity("construction-robot", {position.x, position.y})
          if entity then
          -- construction bot still nearby

            local bot = entity.get_inventory(defines.inventory.robot_cargo)
            if bot.is_empty() then
            -- bot on the return trip?

              for name, count in pairs(used_filters.get_contents()) do
                bot.insert({name = name, count = count})
              end

              used_filters.clear()
            end
          end
        end
      end
    end
    table.remove(global.filter_deliveries, event.unit_number)
  end
end

function kr_air_purifier.on_nth_tick()
  for i = #global["kr-air-purifiers"], 1, -1 do
    local entity = global["kr-air-purifiers"][i]

    if not entity.valid then
      table.remove(global["kr-air-purifiers"], i)
    else
      if entity.get_inventory(defines.inventory.furnace_source).is_empty() then
      -- filter input slot is empty

        if not construction_robot.pending_delivery(entity) then
          local proxy = construction_robot.deliver(entity, {["pollution-filter"] = 1})
          table.insert(global.filter_deliveries, proxy.unit_number, {surface_index = proxy.surface.index, x = proxy.position.x, y = proxy.position.y})
          script.register_on_entity_destroyed(proxy)
        end

      end
    end
  end
end

return kr_air_purifier
