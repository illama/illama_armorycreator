local ESX = exports["es_extended"]:getSharedObject()
local weaponAmmoTypes = {
    -- Pistolets
    ['WEAPON_PISTOL'] = 'ammo-9',
    ['WEAPON_COMBATPISTOL'] = 'ammo-9',
    ['WEAPON_APPISTOL'] = 'ammo-9',
    ['WEAPON_PISTOL50'] = 'ammo-50',
    ['WEAPON_SNSPISTOL'] = 'ammo-9',
    ['WEAPON_HEAVYPISTOL'] = 'ammo-45',
    ['WEAPON_VINTAGEPISTOL'] = 'ammo-9',
    -- Mitraillettes
    ['WEAPON_MICROSMG'] = 'ammo-9',
    ['WEAPON_SMG'] = 'ammo-9',
    ['WEAPON_ASSAULTSMG'] = 'ammo-9',
    ['WEAPON_MINISMG'] = 'ammo-9',
    -- Fusils d'assault
    ['WEAPON_ASSAULTRIFLE'] = 'ammo-rifle',
    ['WEAPON_CARBINERIFLE'] = 'ammo-rifle',
    ['WEAPON_ADVANCEDRIFLE'] = 'ammo-rifle',
    ['WEAPON_SPECIALCARBINE'] = 'ammo-rifle',
    ['WEAPON_BULLPUPRIFLE'] = 'ammo-rifle',
    -- Fusils à pompe
    ['WEAPON_PUMPSHOTGUN'] = 'ammo-shotgun',
    ['WEAPON_SAWNOFFSHOTGUN'] = 'ammo-shotgun',
    ['WEAPON_BULLPUPSHOTGUN'] = 'ammo-shotgun',
    ['WEAPON_ASSAULTSHOTGUN'] = 'ammo-shotgun',
    ['WEAPON_MUSKET'] = 'ammo-shotgun',
    ['WEAPON_HEAVYSHOTGUN'] = 'ammo-shotgun',
    -- Armes de précision
    ['WEAPON_SNIPERRIFLE'] = 'ammo-sniper',
    ['WEAPON_HEAVYSNIPER'] = 'ammo-sniper',
    ['WEAPON_MARKSMANRIFLE'] = 'ammo-sniper'
}
-- Vérification des permissions admin
ESX.RegisterServerCallback('illama_armorycreator:checkAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.AdminGroups[xPlayer.getGroup()] then
        cb(true)
    else
        cb(false)
    end
end)

-- Récupération des jobs
ESX.RegisterServerCallback('illama_armorycreator:getJobs', function(source, cb)
    local jobs = {}
    
    MySQL.query('SELECT name, label FROM jobs', function(jobs1)
        MySQL.query('SELECT name, label FROM jobs2', function(jobs2)
            for _, job in ipairs(jobs1) do
                table.insert(jobs, {
                    name = job.name,
                    label = job.label
                })
            end
            
            for _, job in ipairs(jobs2) do
                table.insert(jobs, {
                    name = job.name,
                    label = job.label
                })
            end
            
            cb(jobs)
        end)
    end)
end)

-- Récupération des armureries
ESX.RegisterServerCallback('illama_armorycreator:getArmories', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.query('SELECT * FROM illama_armories', function(results)
        if results then
            local armories = {}
            for _, armory in ipairs(results) do
                if Config.AdminGroups[xPlayer.getGroup()] or xPlayer.job.name == armory.job or xPlayer.job2.name == armory.job then
                    table.insert(armories, {
                        id = armory.id,
                        job = armory.job,
                        coords = armory.coords,
                        weapons = json.decode(armory.weapons)
                    })
                end
            end
            cb(armories)
        else
            cb({})
        end
    end)
end)

-- Récupération des armes d'une armurerie
ESX.RegisterServerCallback('illama_armorycreator:getArmoryWeapons', function(source, cb, armoryId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.query('SELECT weapons FROM illama_armories WHERE id = ?', {armoryId}, function(result)
        if result[1] and result[1].weapons then
            local weapons = json.decode(result[1].weapons)
            local formattedWeapons = {}
            -- Convertir le tableau d'armes stocké en tableau d'objets avec toutes les informations
            for _, weaponData in ipairs(weapons) do
                local weaponConfig = nil
                -- Chercher les informations de l'arme dans la config
                for _, configWeapon in ipairs(Config.Weapons) do
                    if configWeapon.name == weaponData.name then
                        weaponConfig = configWeapon
                        break
                    end
                end
                
                if weaponConfig then
                    table.insert(formattedWeapons, {
                        name = weaponData.name,
                        label = weaponConfig.label,
                        category = weaponConfig.category,
                        ammo = weaponData.ammo
                    })
                end
            end
            cb(formattedWeapons)
        else
            cb({})
        end
    end)
end)

-- Sauvegarde d'une nouvelle armurerie
RegisterServerEvent('illama_armorycreator:saveArmory', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if Config.AdminGroups[xPlayer.getGroup()] then
        -- S'assurer que data.weapons est un tableau avec les bonnes informations
        local formattedWeapons = {}
        for _, weaponData in ipairs(data.weapons) do
            table.insert(formattedWeapons, {
                name = weaponData.name,
                ammo = weaponData.ammo
            })
        end
        
        MySQL.insert('INSERT INTO illama_armories (job, coords, weapons) VALUES (?, ?, ?)',
            {data.job, json.encode(data.coords), json.encode(formattedWeapons)},
            function(id)
                if id then
                    TriggerClientEvent('esx:showNotification', source, 'Armurerie créée avec succès')
                else
                    TriggerClientEvent('esx:showNotification', source, 'Erreur lors de la création de l\'armurerie')
                end
            end)
    end
end)

-- Génération d'un numéro de série unique
function GenerateSerial()
    return string.upper(ESX.GetRandomString(3) .. '-' .. ESX.GetRandomString(5))
end

-- Gestion des prises d'armes
RegisterServerEvent('illama_armorycreator:takeWeapon', function(armoryId, weaponName, ammo)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Vérifier d'abord si le joueur a accès à cette armurerie
    MySQL.query('SELECT * FROM illama_armories WHERE id = ?', {armoryId}, function(result)
        if not result[1] or (not Config.AdminGroups[xPlayer.getGroup()] and xPlayer.job.name ~= result[1].job and xPlayer.job2.name ~= result[1].job) then
            TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas accès à cette armurerie')
            return
        end

        -- Vérifier si le joueur a déjà cette arme avec ox_inventory
        local hasWeapon = exports.ox_inventory:Search(source, 'count', weaponName)
        if hasWeapon > 0 then
            TriggerClientEvent('esx:showNotification', source, 'Vous avez déjà cette arme sur vous')
            return
        end

        -- Vérifier si l'arme existe dans l'armurerie
        local weapons = json.decode(result[1].weapons)
        local weaponFound = false
        local weaponAmmo = 0
        local weaponLabel = ""
        
        -- Trouver le label de l'arme dans la config
        for _, configWeapon in pairs(Config.Weapons) do
            if configWeapon.name == weaponName then
                weaponLabel = configWeapon.label
                break
            end
        end
        
        for _, weapon in ipairs(weapons) do
            if weapon.name == weaponName then
                weaponFound = true
                weaponAmmo = weapon.ammo
                break
            end
        end
        
        if not weaponFound then
            TriggerClientEvent('esx:showNotification', source, 'Cette arme n\'est pas disponible dans l\'armurerie')
            return
        end

        -- Générer un numéro de série unique
        local serial = GenerateSerial()
        
        -- Insérer dans la base de données
        MySQL.insert('INSERT INTO illama_armoryguns (serial, weapon, job, owner, status, last_action_date, last_action_by) VALUES (?, ?, ?, ?, ?, NOW(), ?)',
            {serial, weaponName, xPlayer.job.name, xPlayer.identifier, 'taken', xPlayer.getName()},
            function(insertId)
                if insertId then
                    -- Donner l'arme au joueur avec un nom personnalisé
                    local customLabel = weaponLabel .. " | " .. serial
                    local success = exports.ox_inventory:AddItem(source, weaponName, 1, {
                        serial = serial,
                        registered = true,
                        jobName = xPlayer.job.name,
                        owner = xPlayer.identifier,
                        label = customLabel,
                        description = "Arme de service - " .. xPlayer.job.label
                    })
                    
                    if success then
                        -- Gérer les munitions
                        local ammoType = weaponAmmoTypes[weaponName]
                        if ammoType then
                            exports.ox_inventory:AddItem(source, ammoType, weaponAmmo)
                            TriggerClientEvent('esx:showNotification', source, 'Vous recevez ' .. weaponAmmo .. ' munitions')
                        end
                        
                        -- Notifier le joueur
                        TriggerClientEvent('esx:showNotification', source, 'Arme récupérée: ' .. customLabel)
                    else
                        TriggerClientEvent('esx:showNotification', source, 'Erreur lors de la récupération de l\'arme')
                        -- Annuler l'entrée dans la base de données si l'arme n'a pas pu être donnée
                        MySQL.query('DELETE FROM illama_armoryguns WHERE id = ?', {insertId})
                    end
                end
            end
        )
    end)
end)
-- Modifier dans server/main.lua la fonction de dépôt


-- Dans le server/main.lua, modifier la requête pour inclure les weapons:

RegisterServerEvent('illama_armorycreator:storeWeapon', function(armoryId, weaponName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Vérifier d'abord si le joueur a accès à cette armurerie
    MySQL.query('SELECT * FROM illama_armories WHERE id = ?', {armoryId}, function(result)
        if not result[1] or (not Config.AdminGroups[xPlayer.getGroup()] and xPlayer.job.name ~= result[1].job and xPlayer.job2.name ~= result[1].job) then
            TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas accès à cette armurerie')
            return
        end

        -- Vérifier si le joueur a l'arme avec ox_inventory
        local items = exports.ox_inventory:Search(source, 'slots', weaponName)
        local weaponItem = nil
        
        -- Chercher l'arme avec un numéro de série
        for _, item in pairs(items) do
            if item.metadata and item.metadata.serial then
                weaponItem = item
                break
            end
        end
        
        if not weaponItem then
            TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas cette arme de service sur vous')
            return
        end

        -- Vérifier si l'arme provient de cette armurerie et appartient au bon job
        MySQL.query('SELECT armoryguns.id, armoryguns.serial, armories.weapons FROM illama_armoryguns armoryguns INNER JOIN illama_armories armories ON armories.id = ? WHERE armoryguns.serial = ? AND armoryguns.owner = ? AND armoryguns.status = ? AND armoryguns.job = ?',
            {armoryId, weaponItem.metadata.serial, xPlayer.identifier, 'taken', xPlayer.job.name},
            function(result)
                if result[1] then
                    -- S'assurer que weapons est un json valide
                    local weapons = json.decode(result[1].weapons)
                    if not weapons then
                        TriggerClientEvent('esx:showNotification', source, 'Erreur lors de la récupération des données de l\'armurerie')
                        return
                    end

                    local configuredAmmo = 0
                    
                    -- Trouver les munitions configurées pour cette arme
                    for _, weapon in ipairs(weapons) do
                        if weapon.name == weaponName then
                            configuredAmmo = weapon.ammo
                            break
                        end
                    end

                    -- Trouver le type de munitions pour cette arme
                    local ammoType = weaponAmmoTypes[weaponName]
                    if ammoType then
                        -- Récupérer les munitions actuelles du joueur
                        local currentAmmo = exports.ox_inventory:Search(source, 'count', ammoType)
                        
                        -- Calculer combien de munitions on doit rendre
                        local ammoToRemove = math.min(currentAmmo, configuredAmmo)
                        
                        -- Retirer l'arme avec ox_inventory
                        if exports.ox_inventory:RemoveItem(source, weaponName, 1, nil, weaponItem.slot) then
                            -- Retirer seulement le nombre de munitions configuré initialement
                            if ammoToRemove > 0 then
                                exports.ox_inventory:RemoveItem(source, ammoType, ammoToRemove)
                            end

                            -- Mettre à jour le statut de l'arme
                            MySQL.update('UPDATE illama_armoryguns SET status = ?, last_action_date = NOW(), last_action_by = ? WHERE id = ?',
                                {'stored', xPlayer.getName(), result[1].id},
                                function(affectedRows)
                                    if affectedRows > 0 then
                                        TriggerClientEvent('esx:showNotification', source, 'Arme déposée avec succès')
                                        if ammoToRemove > 0 then
                                            TriggerClientEvent('esx:showNotification', source, 'Vous avez rendu ' .. ammoToRemove .. ' munitions')
                                        end
                                        
                                        -- Si le joueur garde des munitions, le notifier
                                        local remainingAmmo = currentAmmo - ammoToRemove
                                        if remainingAmmo > 0 then
                                            TriggerClientEvent('esx:showNotification', source, 'Il vous reste ' .. remainingAmmo .. ' munitions')
                                        end
                                    end
                                end
                            )
                        else
                            TriggerClientEvent('esx:showNotification', source, 'Erreur lors du dépôt de l\'arme')
                        end
                    end
                else
                    TriggerClientEvent('esx:showNotification', source, 'Cette arme ne provient pas de cette armurerie')
                end
            end
        )
    end)
end)

-- Configuration
local githubUser = 'illama'
local githubRepo = 'illama_armorycreator'

-- Fonction pour récupérer la version locale depuis le fxmanifest
local function GetCurrentVersion()
    local resourceName = GetCurrentResourceName()
    local manifest = LoadResourceFile(resourceName, 'fxmanifest.lua')
    if not manifest then
        return nil
    end
    
    -- Chercher la ligne avec version
    for line in manifest:gmatch("[^\r\n]+") do
        local version = line:match("^version%s+['\"](.+)['\"]")
        if version then
            return version:gsub("%s+", "") -- Enlever les espaces
        end
    end
    
    return nil
end

-- Fonction pour vérifier la version
local function CheckVersion()
    local currentVersion = GetCurrentVersion()
    if not currentVersion then
        print('^1[illama_armorycreator] Impossible de lire la version dans le fxmanifest.lua^7')
        return
    end

    -- Utiliser l'API GitHub pour récupérer la dernière release
    PerformHttpRequest(
        ('https://api.github.com/repos/%s/%s/releases/latest'):format(githubUser, githubRepo),
        function(err, text, headers)
            if err ~= 200 then
                print('^1[illama_armorycreator] Impossible de vérifier la version sur GitHub^7')
                return
            end
            
            -- Parser la réponse JSON
            local data = json.decode(text)
            if not data or not data.tag_name then
                print('^1[illama_armorycreator] Erreur lors de la lecture de la version GitHub^7')
                return
            end
            
            local latestVersion = data.tag_name:gsub("^v", "") -- Enlever le 'v' si présent
            
            if latestVersion ~= currentVersion then
                print('^3[illama_armorycreator] Une nouvelle version est disponible!^7')
                print('^3[illama_armorycreator] Version actuelle: ^7' .. currentVersion)
                print('^3[illama_armorycreator] Dernière version: ^7' .. latestVersion)
                print('^3[illama_armorycreator] Notes de mise à jour: ^7' .. (data.html_url or 'N/A'))
                if data.body then
                    print('^3[illama_armorycreator] Changements: \n^7' .. data.body)
                end
            else
                print('^2[illama_armorycreator] Le script est à jour (v' .. currentVersion .. ')^7')
            end
        end,
        'GET',
        '',
        {['User-Agent'] = 'FXServer-'..githubUser}
    )
end

-- Vérifier la version au démarrage
CreateThread(function()
    Wait(5000) -- Attendre 5 secondes après le démarrage du serveur
    CheckVersion()
end)