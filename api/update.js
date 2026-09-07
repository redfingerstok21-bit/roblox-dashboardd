// Storage global menyimpan multi-akun berdasarkan UserId
let globalAccounts = {};

export default function handler(req, res) {
  if (req.method === 'POST') {
    const body = req.body;
    
    if (!body.userId) {
      return res.status(400).json({ error: "Missing userId" });
    }

    // Simpan/Update data per akun berdasarkan Key (userId)
    globalAccounts[body.userId] = {
      username: body.username,
      userId: body.userId,
      money: body.money,
      income: body.income,
      incomeRaw: body.incomeRaw || 0, // Digunakan untuk urutan sorting
      walkSpeed: body.walkSpeed,
      pets: body.pets || [],
      lastSeen: Math.floor(Date.now() / 1000)
    };

    return res.status(200).json({ status: "ok" });
  } 

  if (req.method === 'GET') {
    return res.status(200).json(globalAccounts);
  }

  res.status(405).end();
}
