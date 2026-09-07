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
  const countLabel = document.querySelector('.active-accounts') || document.getElementById('active-count');

  if (countLabel) {
    countLabel.innerText = `Active Accounts: ${accounts.length}`;
  }

  if (!accounts || accounts.length === 0) {
    return;
  }

  let html = '';
  accounts.forEach((acc, index) => {
    const topPet = (acc.pets && acc.pets.length > 0) ? acc.pets[0] : null;

    html += `
      <div style="background:#131B2E; border:1px solid #1E293B; border-radius:12px; padding:16px; margin-top:16px; color:white;">
        <div style="display:flex; justify-between; align-items:center; border-bottom:1px solid #1E293B; padding-bottom:10px; margin-bottom:12px;">
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:36px; height:36px; background:#2563EB; border-radius:50%; display:flex; align-items:center; justify-content:center; font-weight:bold;">
              ${acc.username.charAt(0).toUpperCase()}
            </div>
            <div>
              <h3 style="margin:0; font-size:16px;">${acc.username}</h3>
              <p style="margin:0; font-size:11px; color:#94A3B8;">ID: ${acc.userId}</p>
            </div>
          </div>
          <span style="background:rgba(245,158,11,0.1); color:#F59E0B; border:1px solid rgba(245,158,11,0.2); padding:2px 8px; border-radius:4px; font-size:12px; font-weight:bold;">
            #${index + 1}
          </span>
        </div>

        <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:12px;">
          <div style="background:#0B0F19; padding:10px; border-radius:8px; border:1px solid #1E293B;">
            <p style="margin:0; font-size:10px; font-weight:bold; color:#94A3B8;">⚡ INCOME / S</p>
            <p style="margin:4px 0 0 0; font-size:18px; font-weight:bold; color:#10B981;">${acc.income}</p>
          </div>
          <div style="background:#0B0F19; padding:10px; border-radius:8px; border:1px solid #1E293B;">
            <p style="margin:0; font-size:10px; font-weight:bold; color:#94A3B8;">🏃 WALKSPEED</p>
            <p style="margin:4px 0 0 0; font-size:18px; font-weight:bold; color:#E2E8F0;">${acc.walkSpeed}</p>
          </div>
        </div>

        <div style="background:#0B0F19; padding:10px; border-radius:8px; border:1px solid #1E293B; display:flex; justify-content:space-between; align-items:center;">
          <div>
            <p style="margin:0; font-size:10px; font-weight:bold; color:#94A3B8;">👑 TOP PET</p>
            <p style="margin:2px 0 0 0; font-size:13px; font-weight:bold;">${topPet ? topPet.name : 'None'}</p>
          </div>
          <p style="margin:0; font-size:12px; font-weight:bold; color:#10B981;">${topPet ? topPet.income : '0/s'}</p>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

fetchAccounts();
setInterval(fetchAccounts, 2000);
