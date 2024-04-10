---@ diagnostic disable: undefined-global, lowercase-global

flatbed = gui.get_tab("Flatbed Script")
vehicleHandles = entities.get_all_vehicles_as_handles()
attached_vehicle = {}
local debug = false
flatbed:add_imgui(function()
    local flatbedModel = 1353720154
    local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
    local vehicle_model = ENTITY.GET_ENTITY_MODEL(current_vehicle)
    local validModel = false
    local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    -- for _, veh in ipairs(vehicleHandles) do
    --     script.run_in_fiber(function()
    --         vehicleHash = ENTITY.GET_ENTITY_MODEL(veh)
    --         vehicleCoords = ENTITY.GET_ENTITY_COORDS(veh, false)
    --         myPos = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    --         local function vectorEquals(a, b)
    --             return a.x <= (b.x + 2) and a.y <= (b.y + 2) and a.z <= (b.z + 2)
    --           end
    --         if vectorEquals(vehicleCoords, myPos) then
    --             if ENTITY.IS_ENTITY_AT_COORD(veh, vehicleCoords.x,vehicleCoords.y, vehicleCoords.z, 5.0, 5.0, 5.0, false, true, 0) then
    --                 closestVehicle = veh
    --             end
    --         end
    --     end)
    -- end
    local closestVehicle = VEHICLE.GET_CLOSEST_VEHICLE(playerPosition.x, playerPosition.y, playerPosition.z, 10.0, 0, 70) --doesn't return cop cars or occupied pvs.
    local closestVehicleModel = ENTITY.GET_ENTITY_MODEL(closestVehicle)
    local is_car = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
    local is_bike = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
    local closestVehicleName = vehicles.get_vehicle_display_name(closestVehicleModel)
    if vehicle_model == flatbedModel then
        is_in_flatbed = true
    else
        is_in_flatbed = false
    end
    if closestVehicleName == "" then
        displayText = "No nearby vehicles found!"
    else
        displayText = tostring(closestVehicleName)
    end
    if is_car then
        validModel = true
    end
    if is_bike then
        validModel = true
    end
    if closestVehicleModel == 745926877 then
        validModel = true
    end
    if closestVehicleModel == flatbedModel then
        validModel = false
    end
    if is_in_flatbed then
        ImGui.Text("Vehicle: "..displayText)
        towPos, used = ImGui.Checkbox("Mark Selected Vehicle", towPos, true)
        if ImGui.Button("Tow Nearby Vehicle") then
            if attached_vehicle[1] == nil then
                if validModel then
                    local controlled = entities.take_control_of(closestVehicle, 350)
                    if controlled then
                        flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
                        flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
                        ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, 0.0, -2.0, 1.069, 0.0, 0.0, 0.0, false, true, true, false, 1, true, 1)
                        table.insert(attached_vehicle, closestVehicle)
                    else
                        gui.show_error("Flatbed Script", "Failed to take control of the vehicle!")
                    end
                end
                if closestVehicleModel ~= flatbedModel and not is_car and not is_bike then
                    gui.show_message("Flatbed Script", "You can only tow cars, trucks and bikes.")
                end
                if closestVehicleModel == flatbedModel then
                    gui.show_message("Flatbed Script", "Sorry but you can not tow another flatbed truck.")
                end
            else
                gui.show_error("Flatbed Script", "You are already towing a vehicle.")
            end
        end
        ImGui.SameLine()
        -- if ImGui.Button("Tow Player Vehicle") then
        --     script.run_in_fiber(function()
        --         local selected_player = PLAYER.GET_PLAYER_PED(network.get_selected_player())
        --         local towVeh = PED.GET_VEHICLE_PED_IS_USING(selected_player)
        --         local towVehModel = ENTITY.GET_ENTITY_MODEL(towVeh)
        --         local vehControlled = entities.take_control_of(towVeh, 350)
        --         local playerControlled = entities.take_control_of(selected_player, 350)
        --         if vehControlled and playerControlled then
        --             local flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
        --             local flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
        --             ENTITY.SET_ENTITY_HEADING(towVehModel, flatbedHeading)
        --             ENTITY.ATTACH_ENTITY_TO_ENTITY(towVeh, current_vehicle, flatbedBone, 0.0, -2.0, 1.069, 0.0, 0.0, 0.0, false, true, true, false, 1, true, 1)
        --             table.insert(attached_vehicle, towVeh)
        --         end
        --     end)
        -- end
        if ImGui.Button("Detach Vehicle") then
            for _, v in ipairs(vehicleHandles) do
                script.run_in_fiber(function()
                    modelHash = ENTITY.GET_ENTITY_MODEL(v)
                    attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(current_vehicle, modelHash)
                    if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                        ENTITY.DETACH_ENTITY(attachedVehicle)
                        ENTITY.SET_ENTITY_COORDS(attachedVehicle, playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                    end
                end)
            end
            for k, _ in ipairs(attached_vehicle) do
                table.remove(attached_vehicle, k)
            end
        end
    else
        ImGui.Text("Get inside a flatbed truck to use the script.")
        if ImGui.Button("Spawn Flatbed Truck") then
            script.run_in_fiber(function(script)
                local try = 0
                while not STREAMING.HAS_MODEL_LOADED(flatbedModel) do
                    STREAMING.REQUEST_MODEL(flatbedModel)
                    script:yield()
                    if try > 100 then
                        return
                    else
                        try = try + 1
                    end
                end
                fltbd = VEHICLE.CREATE_VEHICLE(flatbedModel, playerPosition.x + (playerForwardX * 2), playerPosition.y + (playerForwardX * 2), playerPosition.z, ENTITY.GET_ENTITY_HEADING(self.get_ped()), true, false, false)
                script:sleep(200)
                PED.SET_PED_INTO_VEHICLE(self.get_ped(), fltbd, -1)
                ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(fltbd)
            end)
        end
    end
    ImGui.TextDisabled("_")
    if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
        debug = not debug
    end
    if debug then
        ImGui.Separator()
        if ImGui.Button("debug") then
            lastVeh = ENTITY.GET_ENTITY_MODEL(PLAYER.GET_PLAYERS_LAST_VEHICLE())
            local closestVehicle2 = VEHICLE.GET_CLOSEST_VEHICLE(playerPosition.x, playerPosition.y, playerPosition.z, 10.0, 0, 70)
            -- log.debug("Last Vehicle: "..tostring(lastVeh).." | Attached Vehicle: "..tostring(attached_vehicle[1]))
            -- log.debug("My Coords: "..tostring(playerPosition).." | Vehicle Coords: "..tostring(vehicleCoords))
            log.debug(tostring(closestVehicle))
            log.debug(tostring(closestVehicle2))
        end
    end
end)
script.register_looped("show selected", function(script)
    local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
    local vehicle_model = ENTITY.GET_ENTITY_MODEL(current_vehicle)
    local flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
    local flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
    local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    local closestVehicle = VEHICLE.GET_CLOSEST_VEHICLE(playerPosition.x, playerPosition.y, playerPosition.z, 10.0, 0, 70)
    local closestVehicleModel = ENTITY.GET_ENTITY_MODEL(closestVehicle)
    local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    local is_car = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
    local is_bike = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
    local validModel = false
    if is_car then
        validModel = true
    end
    if is_bike then
        validModel = true
    end
    if closestVehicleModel == 745926877 then
        validModel = true
    end
    if closestVehicleModel == 1353720154 then
        validModel = false
    end
    if vehicle_model == 1353720154 then
        is_in_flatbed = true
    else
        is_in_flatbed = false
    end
    if is_in_flatbed and attached_vehicle[1] == nil then
        if PAD.IS_CONTROL_PRESSED(0, 73) then
            if validModel then
                script:sleep(200)
                local controlled = entities.take_control_of(closestVehicle, 350)
                if controlled then
                    ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, 0.0, -2.0, 1.069, 0.0, 0.0, 0.0, false, true, true, false, 1, true, 1)
                    table.insert(attached_vehicle, closestVehicle)
                    script:sleep(200)
                else
                    gui.show_error("Flatbed Script", "Failed to take control of the vehicle!")
                end
            else
                script:sleep(400)
                gui.show_message("Flatbed Script", "You can only tow cars, trucks and bikes.")
            end
        end
    elseif is_in_flatbed and attached_vehicle[1] ~= nil then
        if PAD.IS_CONTROL_PRESSED(0, 73) then
            script:sleep(200)
            local vehicleHandles = entities.get_all_vehicles_as_handles()
            for _, v in ipairs(vehicleHandles) do
                local modelHash = ENTITY.GET_ENTITY_MODEL(v)
                local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(current_vehicle, modelHash)
                if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                    ENTITY.DETACH_ENTITY(attachedVehicle)
                    ENTITY.SET_ENTITY_COORDS(attachedVehicle, playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
                    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                end
            end
            for k, _ in ipairs(attached_vehicle) do
                table.remove(attached_vehicle, k)
            end
            script:sleep(200)
        end
    end
    if towPos then
        if is_in_flatbed and attached_vehicle[1] == nil then
            local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
            local closestVehicle = VEHICLE.GET_CLOSEST_VEHICLE(playerPosition.x, playerPosition.y, playerPosition.z, 10.0, 0, 70)
            local closestVehicleCoords = ENTITY.GET_ENTITY_COORDS(closestVehicle, false)
            -- GRAPHICS.DRAW_BOX(closestVehicleCoords.x, closestVehicleCoords.x, closestVehicleCoords.x, closestVehicleCoords.x + 1, closestVehicleCoords.y + 1, closestVehicleCoords.z + 2, 255, 128, 0, 50)
            -- GRAPHICS.DRAW_MARKER(6,closestVehicleCoords.x, closestVehicleCoords.y, closestVehicleCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 1, 255, 128, 0, 50, true, true, 2, false, "mpmissmarkers128", "corona_marker", false)
            GRAPHICS.DRAW_MARKER_SPHERE(closestVehicleCoords.x, closestVehicleCoords.y, closestVehicleCoords.z, 2.5, 180, 128, 0, 0.115)
        end
    end
end)