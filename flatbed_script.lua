---@ diagnostic disable: undefined-global, lowercase-global

flatbed_script = gui.get_tab("Flatbed Script")
attached_vehicle = {}
local debug = false
-- local validModel = false
local modelOverride = false
flatbed_script:add_imgui(function()
    local vehicleHandles = entities.get_all_vehicles_as_handles()
    local flatbedModel = 1353720154
    local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
    local vehicle_model = ENTITY.GET_ENTITY_MODEL(current_vehicle)
    local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
-- local closestVehicle = VEHICLE.GET_CLOSEST_VEHICLE(playerPosition.x, playerPosition.y, playerPosition.z, 10.0, 0, 70) --doesn't return cop cars or occupied pvs.
    for _, veh in ipairs(vehicleHandles) do
        script.run_in_fiber(function(script)
            local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
            local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
            local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
            if vDist <= 5 then
                closestVehicle = veh
            else
                script:sleep(50)
                closestVehicle = nil
                return
            end
        end)
    end
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
    elseif tostring(closestVehicleName) == "Flatbed" then
        displayText = "You can not tow another flatbed truck."
    else
        displayText = ("Closest Vehicle: "..tostring(closestVehicleName))
    end
    if attached_vehicle[1] ~= nil then
        displayText = "Towing..."
    end
    if modelOverride then
        validModel = true
    else
        validModel = false
    end
    if is_car then
        validModel = true
    end
    if is_bike then
        validModel = true
    end
    if closestVehicleModel == 745926877 then --Buzzard
        validModel = true
    end
    if is_in_flatbed then
        ImGui.Text(displayText)
        towPos, used = ImGui.Checkbox("Show Towing Position", towPos, true)
        towEverything, used = ImGui.Checkbox("Tow Everything", towEverything, true)
        if towEverything then
            modelOverride = true
        else
            modelOverride = false
        end
        if ImGui.Button("   Tow    ") then
            if attached_vehicle[1] == nil then
                if validModel and closestVehicleModel ~= flatbedModel then
                    local controlled = entities.take_control_of(closestVehicle, 350)
                    if controlled then
                        flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
                        flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis_dummy")
                        ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, 0.0, -2.0, 1.069, 0.0, 0.0, 0.0, false, true, true, false, 1, true, 1)
                        table.insert(attached_vehicle, closestVehicle)
                    else
                        gui.show_error("Flatbed Script", "Failed to take control of the vehicle!")
                    end
                end
                if closestVehicle ~= nil and closestVehicleModel ~= flatbedModel and not validModel then
                    gui.show_message("Flatbed Script", "You can only tow cars, trucks and bikes.")
                end
                if closestVehicle ~= nil and closestVehicleModel == flatbedModel then
                    gui.show_message("Flatbed Script", "Sorry but you can not tow another flatbed truck.")
                end
            else
                gui.show_error("Flatbed Script", "You are already towing a vehicle.")
            end
        end
        ImGui.SameLine()
        if ImGui.Button(" Detach ") then
            for _, v in ipairs(vehicleHandles) do
                script.run_in_fiber(function()
                    local modelHash = ENTITY.GET_ENTITY_MODEL(v)
                    local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(PED.GET_VEHICLE_PED_IS_USING(self.get_ped()), modelHash)
                    if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                        ENTITY.DETACH_ENTITY(attachedVehicle)
                        ENTITY.SET_ENTITY_COORDS(attachedVehicle, playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                    end
                end)
            end
            for key, value in ipairs(attached_vehicle) do
                script.run_in_fiber(function()
                    local modelHash = ENTITY.GET_ENTITY_MODEL(value)
                    local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(PED.GET_VEHICLE_PED_IS_USING(self.get_ped()), modelHash)
                    if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                        ENTITY.DETACH_ENTITY(attachedVehicle)
                        ENTITY.SET_ENTITY_COORDS(attachedVehicle, playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                    end
                end)
                table.remove(attached_vehicle, key)
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
                fltbd = VEHICLE.CREATE_VEHICLE(flatbedModel, playerPosition.x, playerPosition.y, playerPosition.z, ENTITY.GET_ENTITY_HEADING(self.get_ped()), true, false, false)
                -- script:sleep(200)
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
            for _, veh in ipairs(vehicleHandles) do
                script.run_in_fiber(function(script)
                    local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
                    local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
                    local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
                    local vHash =  ENTITY.GET_ENTITY_MODEL(veh)
                end)
            end
            -- log.debug(tostring(closestVehicle))
            log.debug(tostring(vDist))
        end
    end
end)
script.register_looped("flatbed script", function(script)
    -- script:yield()
    local vehicleHandles = entities.get_all_vehicles_as_handles()
    local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
    local vehicle_model = ENTITY.GET_ENTITY_MODEL(current_vehicle)
    local flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
    local flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
    local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    for _, veh in ipairs(vehicleHandles) do
        local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
        local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
        local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
        if vDist <= 5 then
            closestVehicle = veh
        end
    end
    local closestVehicleModel = ENTITY.GET_ENTITY_MODEL(closestVehicle)
    local is_car = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
    local is_bike = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
    local validModel = false
    if modelOverride then
        validModel = true
    else
        validModel = false
    end
    if is_car then
        validModel = true
    end
    if is_bike then
        validModel = true
    end
    if closestVehicleModel == 745926877 then --Buzzard
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
        if PAD.IS_CONTROL_PRESSED(0, 73) and validModel and closestVehicleModel ~= flatbedModel then
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
        end
        if PAD.IS_CONTROL_PRESSED(0, 73) and closestVehicle ~= nil and not validModel then
            gui.show_message("Flatbed Script", "You can only tow cars, trucks and bikes.")
            script:sleep(400)
        end
        if PAD.IS_CONTROL_PRESSED(0, 73) and closestVehicleModel == flatbedModel then
            script:sleep(400)
            gui.show_message("Flatbed Script", "Sorry but you can not tow another flatbed truck.")
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
                    ENTITY.SET_ENTITY_COORDS(attachedVehicle, playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z, 0, 0, 0, 0)
                    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                end
            end
            for key, value in ipairs(attached_vehicle) do
                local modelHash = ENTITY.GET_ENTITY_MODEL(value)
                local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(PED.GET_VEHICLE_PED_IS_USING(self.get_ped()), modelHash)
                    if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                        ENTITY.DETACH_ENTITY(attachedVehicle)
                        ENTITY.SET_ENTITY_COORDS(attachedVehicle, playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z, 0, 0, 0, 0)
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                    end
                table.remove(attached_vehicle, key)
            end
            script:sleep(200)
        end
    end
end)
script.register_looped("TowPos Marker", function()
    if towPos then
        if is_in_flatbed and attached_vehicle[1] == nil then
            local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
            local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
            local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
            local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
            GRAPHICS.DRAW_MARKER_SPHERE(detectPos.x, detectPos.y, detectPos.z, 2.5, 180, 128, 0, 0.115)
        end
    end
end)