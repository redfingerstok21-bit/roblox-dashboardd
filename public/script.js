async function fetchAccounts() {
  try {
    const response = await fetch('/api/update');
    if (!response.ok) return;
    const accounts = await response.json();
    renderDashboard(accounts);
  } catch (error) {
    console.error("Fetch Error:", error);
  }
}

function renderDashboard(accounts) {
  const container = document.getElementById('accounts-container') || document.body;
  if (!accounts || accounts.length === 0) return;

  let html = '';
  accounts.forEach((acc, index) => {
    const topPet = (acc.pets && acc.pets.length > 0) ? acc.pets[0] : null;

    html += `
      <div class="card" style="background: #131b2e; border: 1px solid #1e293b; border-radius: 12px; padding: 16px; margin-bottom: 16px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <div style="width: 36px; height: 36px; background: #2563eb; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; color: white;">
              ${acc.username ? acc.username.charAt(0).toUpperCase() : 'U'}
            </div>
            <div>
              <h3 style="margin: 0; font-size: 15px; color: white;">${acc.username}</h3>
              <p style="margin: 0; font-size: 11px; color: #64748b;">ID: ${acc.userId}</p>
            </div>
          </div>
          <span style="background: rgba(245, 158, 11, 0.1); color: #f59e0b; padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: bold;">#${index + 1}</span>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 10px;">
          <div style="background: #0f172a; padding: 10px; border-radius: 8px;">
            <p style="margin: 0; font-size: 10px; color: #94a3b8; font-weight: bold;">⚡ INCOME / S</p>
            <p style="margin: 4px 0 0 0; font-size: 16px; font-weight: bold; color: #10b981;">${acc.income || '0/s'}</p>
          </div>
          <div style="background: #0f172a; padding: 10px; border-radius: 8px;">
            <p style="margin: 0; font-size: 10px; color: #94a3b8; font-weight: bold;">🏃 WALKSPEED</p>
            <p style="margin: 4px 0 0 0; font-size: 16px; font-weight: bold; color: white;">${acc.walkSpeed || 16}</p>
          </div>
        </div>

        <div style="background: #0f172a; padding: 10px; border-radius: 8px; display: flex; justify-content: space-between; align-items: center;">
          <div>
            <p style="margin: 0; font-size: 10px; color: #94a3b8; font-weight: bold;">👑 TOP PET</p>
            <p style="margin: 2px 0 0 0; font-size: 13px; font-weight: bold; color: white;">${topPet ? topPet.name : 'None'}</p>
          </div>
          <p style="margin: 0; font-size: 12px; font-weight: bold; color: #10b981;">${topPet ? topPet.income : '0/s'}</p>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

fetchAccounts();
setInterval(fetchAccounts, 2000);
