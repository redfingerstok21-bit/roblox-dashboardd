async function fetchAndRender() {
  try {
    const res = await fetch('/api/update');
    const data = await res.json();
    
    const grid = document.getElementById('cardsGrid');
    const now = Math.floor(Date.now() / 1000);
    
    // Ubah data object ke array
    let accounts = Object.values(data);

    // SORTING: Urutkan dari Income Raw tertinggi ke terendah
    accounts.sort((a, b) => (b.incomeRaw || 0) - (a.incomeRaw || 0));

    document.getElementById('activeCount').innerText = accounts.length;
    document.getElementById('globalClock').innerText = new Date().toLocaleTimeString();

    grid.innerHTML = '';

    accounts.forEach((acc, index) => {
      const isOnline = acc.lastSeen && (now - acc.lastSeen < 12);
      
      // Hitung Top Pet
      let topPetName = 'None';
      let topPetIncome = '0/s';
      if (acc.pets && acc.pets.length > 0) {
        const topPet = acc.pets.reduce((max, pet) => (pet.incomeRaw > max.incomeRaw) ? pet : max, acc.pets[0]);
        topPetName = topPet.name;
        topPetIncome = `${topPet.income}/s`;
      }

      const card = document.createElement('div');
      card.className = 'card';
      card.innerHTML = `
        <div class="rank-badge">#${index + 1}</div>
        <div class="card-header">
          <div class="avatar-wrapper">
            <div class="avatar">👤</div>
            <div class="status-dot ${isOnline ? 'online' : ''}"></div>
          </div>
          <div>
            <div class="username">${acc.username || 'Unknown'}</div>
            <div class="userid">ID: ${acc.userId || '-'}</div>
          </div>
        </div>

        <div class="stats-grid">
          <div class="stat-box">
            <div class="stat-label">💰 Money</div>
            <div class="stat-val">${acc.money || '0'}</div>
          </div>
          <div class="stat-box">
            <div class="stat-label">⚡ Income / s</div>
            <div class="stat-val" style="color: var(--accent-green);">${acc.income || '0'}/s</div>
          </div>
          <div class="stat-box">
            <div class="stat-label">🏃 Walkspeed</div>
            <div class="stat-val">${acc.walkSpeed || '16'}</div>
          </div>
          <div class="stat-box">
            <div class="stat-label">🐾 Pets Equipped</div>
            <div class="stat-val">${acc.pets ? acc.pets.length : 0}</div>
          </div>
        </div>

        <div class="top-pet-section">
          <div class="pet-info">
            <span class="pet-title">👑 TOP PET</span>
            <span class="pet-name">${topPetName}</span>
          </div>
          <span class="pet-income">${topPetIncome}</span>
        </div>
      `;
      grid.appendChild(card);
    });
  } catch (err) {
    console.error("Fetch error:", err);
  }
}

setInterval(fetchAndRender, 3000);
fetchAndRender();
