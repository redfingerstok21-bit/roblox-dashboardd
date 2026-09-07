// Fungsi untuk mengambil data akun dari API Vercel
async function fetchAccounts() {
  try {
    const response = await fetch('/api/update');
    const data = await response.json();
    renderCards(data);
  } catch (error) {
    console.error('Gagal mengambil data:', error);
  }
}

// Fungsi merender kartu ke halaman HTML
function renderCards(accounts) {
  const container = document.getElementById('accounts-container') || document.body;
  
  if (!accounts || accounts.length === 0) {
    container.innerHTML = '<p class="no-data">Belum ada akun yang terhubung.</p>';
    return;
  }

  let html = '';

  accounts.forEach((acc, index) => {
    const topPet = (acc.pets && acc.pets.length > 0) ? acc.pets[0] : null;

    html += `
      <div class="card">
        <div class="card-header">
          <div class="user-info">
            <span class="user-avatar">${acc.username ? acc.username.substring(0, 2).toUpperCase() : 'RO'}</span>
            <div>
              <h3 class="username">${acc.username || 'Unknown'}</h3>
              <p class="user-id">ID: ${acc.userId || '-'}</p>
            </div>
          </div>
          <span class="rank">#${index + 1}</span>
        </div>

        <!-- STATS GRID (TANPA MONEY) -->
        <div class="stats-grid">
          <div class="stat-item">
            <span class="stat-label">⚡ INCOME / S</span>
            <span class="stat-value text-green">${acc.income || '0/s'}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">🏃 WALKSPEED</span>
            <span class="stat-value">${acc.walkSpeed || 16}</span>
          </div>
        </div>

        <!-- TOP PET SECTION -->
        <div class="pet-card">
          <div class="pet-info">
            <span class="stat-label">👑 TOP PET</span>
            <span class="pet-name">${topPet ? topPet.name : 'None'}</span>
          </div>
          <span class="pet-income">${topPet ? topPet.income : '0/s'}</span>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

// Jalankan pengambilan data secara otomatis setiap 2 detik
fetchAccounts();
setInterval(fetchAccounts, 2000);
