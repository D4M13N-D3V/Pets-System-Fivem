local petPed = nil
local petType = "None"

local petMaxHunger = 100
local petMaxThirst=100

local petHunger = 100
local petThirst = 100

local petDamage = 1
local petMaxHealth = 25
local petHealth = 25

local uiToggle = true

--PUT YOUR CORRESPONDING ITEM IDS TO ANIMALS HERE!
--local petInventoryInformation={
--    ["Rottwieler"]=89,  
--    ["Husky"]=90,  
--    ["German Shepard"]=91,  
--    ["Golden Retriever"]=92,   
--    ["Cat"]=93,
--}

local petModels = {
	["Rottweiler"]="a_c_rottweiler",
	["Husky"]="a_c_husky",
	["German Shepard"]="a_c_shepherd",
	["Golden Retriever"]="a_c_retriever"
}

RegisterNetEvent("togglePetUI")
AddEventHandler("togglePetUI", function()
    uiToggle = not uiToggle
end)

RegisterNetEvent("togglePet")
AddEventHandler("togglePet", function(type)
    petType=type
    if(petPed)then
        putPetUp()
    else
        getPetOut()
    end
end)

RegisterNetEvent("feedPet")
AddEventHandler("feedPet", function(food,amount)
    if(food)then
        petHunger=petHunger+amount
        if(petHunger>petMaxHunger)then
            petHunger=petMaxHunger
        end
    else
        petThirst=petThirst+amount
        if(petThirst>petMaxThirst)then
            petThirst=petMaxThirst
        end
    end
end)

RegisterNetEvent("healPet")
AddEventHandler("healPet", function(amount)
    petHealth=petHealth+amount
    if(petHealth>petMaxHealth)then
        petHealth=petMaxHealth
    end
end)

function getPetOut()
    local ped = nil
    ped = GetHashKey(petModels[petType])
    RequestModel(ped)
    while not HasModelLoaded(ped) do
        Citizen.Wait(1)
        RequestModel(ped)
    end
    local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 2.0, 0.0)
    local dog = CreatePed(28, ped, plyCoords.x, plyCoords.y, plyCoords.z, GetEntityHeading(GetPlayerPed(-1)), 0, 1)
    petPed = dog
    SetBlockingOfNonTemporaryEvents(petPed, true)
    SetPedFleeAttributes(petPed, 0, 0)
    SetEntityInvincible(petPed, true)
    SetPedRelationshipGroupHash(petPed, GetHashKey("k9"))
    local blip = AddBlipForEntity(petPed)
    SetBlipAsFriendly(blip, true)
    SetBlipSprite(blip, 442)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(tostring("Dog"))
    EndTextCommandSetBlipName(blip)
    NetworkRegisterEntityAsNetworked(petPed)
    while not NetworkGetEntityIsNetworked(petPed) do
        NetworkRegisterEntityAsNetworked(petPed)
        Citizen.Wait(1)
    end
    TaskFollowToOffsetOfEntity(petPed, GetPlayerPed(-1), 0.5, 0.0, 0.0, 5.0, -1, 0.0, 1)
    SetPedKeepTask(petPed, true)
    Citizen.CreateThread(function()
        while petPed~=nil do
            Citizen.Wait(300000)
            if(petThirst>0 and petHunger>0)then
                petHunger=petHunger-1
                petThirst=petThirst-1
            else
                if(petHealth>0)then
                    petHealth=petHealth-petDamage
                else
                    SetEntityHealth(petPed, 0)
                    petHunger=petMaxHunger
                    petThirst=petMaxThirst
                    petHealth=petMaxHealth
                    --PUT CODE TO REMOVE YOUR INVENTORY ITEMS HERE    TriggerServerEvent("inventory:remove",petInventoryInformation[petType],1)
                    Citizen.Wait(5000)
                    DeleteEntity(petPed)
                end
            end
        end
    end)

    Citizen.CreateThread(function()
        local ply = GetPlayerPed(-1)
        while petPed~=nil do 
            Citizen.Wait(0)
            if(IsPedInAnyVehicle(ply)==true and IsPedInAnyVehicle(petPed)==false)then
                local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1),false)
                local door = GetClosestVehicleDoor(vehicle)
                TaskEnterVehicle(petPed, vehicle, -1, door, 2.0, 1, 0)
            elseif(IsPedInAnyVehicle(ply)==false and IsPedInAnyVehicle(petPed)==true)then
                TaskLeaveVehicle(petPed, GetVehiclePedIsIn(petPed, false), 256)
            end
        end
    end)

    Citizen.CreateThread(function()
        while petPed~=nil do
            Citizen.Wait(0)
            if(uiToggle)then
                x, y, z = table.unpack( GetEntityCoords( petPed, false ) )
                DrawText3D(x, y, z+0.6,0,175,0,"Hunger : "..petHunger.."/"..petMaxHunger)
                DrawText3D(x, y, z+0.45,0,0,175,"Thirst : "..petThirst.."/"..petMaxThirst)
            end
        end
    end)    
end

function putPetUp()
    if(petPed~=nil)then
        SetEntityAsMissionEntity(petPed, true, true)
        DeleteEntity(petPed)
        petPed = nil
    end
end

function DrawText3D(x,y,z,red,green,blue,text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        SetTextScale(0.0*scale, 0.55*scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(red, green, blue, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        World3dToScreen2d(x,y,z, 0) --Added Here
        DrawText(_x,_y)
    end
end