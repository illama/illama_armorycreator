local ESX = exports["es_extended"]:getSharedObject()
local creatingArmory = false
local currentArmory = nil

-- Commande admin pour créer une armurerie
RegisterCommand('createarmory', function()
    ESX.TriggerServerCallback('illama_armorycreator:checkAdmin', function(isAdmin)
        if isAdmin then
            OpenCreationMenu()
        else
            ESX.ShowNotification('Vous n\'avez pas les permissions nécessaires.')
        end
    end)
end)

-- Fonction pour ouvrir le menu de création
function OpenCreationMenu()
    ESX.TriggerServerCallback('illama_armorycreator:getJobs', function(jobs)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'openCreator',
            jobs = jobs,
            weapons = Config.Weapons
        })
        creatingArmory = true
    end)
end

-- Fonction pour ouvrir le menu de l'armurerie
function OpenArmoryMenu(armory)
    ESX.TriggerServerCallback('illama_armorycreator:getArmoryWeapons', function(weapons)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'openArmory',
            weapons = weapons,
            armoryId = armory.id
        })
        currentArmory = armory
    end, armory.id)
end

-- Callback pour recevoir les données du menu
RegisterNUICallback('createArmory', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('illama_armorycreator:saveArmory', {
        job = data.job,
        weapons = data.weapons,
        coords = coords
    })
    SetNuiFocus(false, false)
    creatingArmory = false
    cb('ok')
end)

-- Callback pour fermer le menu
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    creatingArmory = false
    currentArmory = nil
    cb('ok')
end)

-- Callback pour prendre une arme
RegisterNUICallback('takeWeapon', function(data, cb)
    if currentArmory then
        TriggerServerEvent('illama_armorycreator:takeWeapon', currentArmory.id, data.weapon, data.ammo)
        SetNuiFocus(false, false)
        currentArmory = nil
    end
    cb('ok')
end)

-- Callback pour déposer une arme
RegisterNUICallback('storeWeapon', function(data, cb)
    if currentArmory then
        TriggerServerEvent('illama_armorycreator:storeWeapon', currentArmory.id, data.weapon)
        SetNuiFocus(false, false)
        currentArmory = nil
    end
    cb('ok')
end)

-- Configuration des ox_target pour les armureries
CreateThread(function()
    Wait(1000) -- Attendre que ESX soit complètement chargé
    ESX.TriggerServerCallback('illama_armorycreator:getArmories', function(armories)
        for _, armory in pairs(armories) do
            local coords = json.decode(armory.coords)
            exports.ox_target:addSphereZone({
                coords = vector3(coords.x, coords.y, coords.z),
                radius = 1.5,
                options = {
                    {
                        name = 'open_armory_' .. armory.id,
                        icon = 'fas fa-gun',
                        label = 'Accéder à l\'armurerie',
                        canInteract = function()
                            local playerData = ESX.GetPlayerData()
                            return (playerData.job and playerData.job.name == armory.job) or 
                                   (playerData.job2 and playerData.job2.name == armory.job)
                        end,
                        onSelect = function()
                            -- Double vérification côté client
                            local playerData = ESX.GetPlayerData()
                            if (playerData.job and playerData.job.name == armory.job) or 
                               (playerData.job2 and playerData.job2.name == armory.job) then
                                OpenArmoryMenu(armory)
                            else
                                ESX.ShowNotification('Vous n\'avez pas accès à cette armurerie')
                            end
                        end
                    }
                }
            })
        end
    end)
end)
-- Fonction pour fermer le menu après une action
function CloseArmoryMenu()
    SetNuiFocus(false, false)
    currentArmory = nil
end