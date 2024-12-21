let weaponsList = [];
let jobsList = [];
let currentArmoryId = null;

window.addEventListener('message', function(event) {
    if (event.data.type === 'openCreator') {
        document.getElementById('creator-container').style.display = 'block';
        document.getElementById('armory-container').style.display = 'none';
        jobsList = event.data.jobs;
        weaponsList = event.data.weapons;
        initializeCreator();
    } else if (event.data.type === 'openArmory') {
        document.getElementById('creator-container').style.display = 'none';
        document.getElementById('armory-container').style.display = 'block';
        currentArmoryId = event.data.armoryId;
        initializeArmory(event.data.weapons);
    }
});

function initializeCreator() {
    const jobSelect = document.getElementById('job-select');
    const weaponsContainer = document.getElementById('weapons-list');
    
    // Vider les listes existantes
    jobSelect.innerHTML = '<option value="">Sélectionnez un métier</option>';
    weaponsContainer.innerHTML = '';
    
    // Remplir la liste des jobs
    jobsList.forEach(job => {
        const option = document.createElement('option');
        option.value = job.name;
        option.textContent = job.label;
        jobSelect.appendChild(option);
    });
    
    // Grouper les armes par catégorie
    const weaponsByCategory = {};
    weaponsList.forEach(weapon => {
        if (!weaponsByCategory[weapon.category]) {
            weaponsByCategory[weapon.category] = [];
        }
        weaponsByCategory[weapon.category].push(weapon);
    });
    
    // Créer les sections pour chaque catégorie
    for (const category in weaponsByCategory) {
        const categoryDiv = document.createElement('div');
        categoryDiv.className = 'weapon-category';
        categoryDiv.textContent = category;
        weaponsContainer.appendChild(categoryDiv);
        
        weaponsByCategory[category].forEach(weapon => {
            const div = document.createElement('div');
            div.className = 'weapon-item';
            div.innerHTML = `
                <label>
                    <input type="checkbox" id="weapon-${weapon.name}" value="${weapon.name}">
                    ${weapon.label}
                </label>
                <input type="number" id="ammo-${weapon.name}" class="ammo-input" 
                       placeholder="Munitions" min="0" max="250" value="100">
            `;
            weaponsContainer.appendChild(div);
        });
    }
}

function initializeArmory(weapons) {
    const weaponsContainer = document.getElementById('armory-weapons');
    weaponsContainer.innerHTML = '';
    
    // Grouper les armes par catégorie
    const weaponsByCategory = {};
    weapons.forEach(weapon => {
        if (!weaponsByCategory[weapon.category]) {
            weaponsByCategory[weapon.category] = [];
        }
        weaponsByCategory[weapon.category].push(weapon);
    });
    
    // Créer les sections pour chaque catégorie
    for (const category in weaponsByCategory) {
        const categoryDiv = document.createElement('div');
        categoryDiv.className = 'weapon-category';
        categoryDiv.textContent = category;
        weaponsContainer.appendChild(categoryDiv);
        
        weaponsByCategory[category].forEach(weapon => {
            const div = document.createElement('div');
            div.className = 'weapon-item';
            div.innerHTML = `
                <span>${weapon.label} (${weapon.ammo} munitions)</span>
                <div>
                    <button class="weapon-button" onclick="takeWeapon('${weapon.name}', ${weapon.ammo})">Prendre</button>
                    <button class="weapon-button" onclick="storeWeapon('${weapon.name}')">Déposer</button>
                </div>
            `;
            weaponsContainer.appendChild(div);
        });
    }
}

document.getElementById('save-button').addEventListener('click', function() {
    const jobSelect = document.getElementById('job-select');
    const errorMessage = document.getElementById('error-message');
    
    if (!jobSelect.value) {
        errorMessage.style.display = 'block';
        return;
    }
    
    errorMessage.style.display = 'none';
    const selectedWeapons = Array.from(document.querySelectorAll('input[type="checkbox"]:checked')).map(cb => ({
        name: cb.value,
        ammo: parseInt(document.getElementById('ammo-' + cb.value).value) || 100
    }));
    
    if (selectedWeapons.length === 0) {
        errorMessage.textContent = 'Veuillez sélectionner au moins une arme';
        errorMessage.style.display = 'block';
        return;
    }

    fetch(`https://${GetParentResourceName()}/createArmory`, {
        method: 'POST',
        body: JSON.stringify({
            job: jobSelect.value,
            weapons: selectedWeapons
        })
    });
    
    document.getElementById('creator-container').style.display = 'none';
});

document.getElementById('close-button').addEventListener('click', function() {
    closeMenu();
});

function closeMenu() {
    document.getElementById('creator-container').style.display = 'none';
    document.getElementById('armory-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function takeWeapon(weaponName, ammo) {
    fetch(`https://${GetParentResourceName()}/takeWeapon`, {
        method: 'POST',
        body: JSON.stringify({
            weapon: weaponName,
            ammo: ammo,
            armoryId: currentArmoryId
        })
    }).then(() => {
        document.getElementById('armory-container').style.display = 'none';
    });
}

function storeWeapon(weaponName) {
    fetch(`https://${GetParentResourceName()}/storeWeapon`, {
        method: 'POST',
        body: JSON.stringify({
            weapon: weaponName,
            armoryId: currentArmoryId
        })
    }).then(() => {
        document.getElementById('armory-container').style.display = 'none';
    });
}

// Gestion de la touche ECHAP
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});