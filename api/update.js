// Storage sementara di serverless
global.accountsData = global.accountsData || {};

export default async function handler(req, res) {
  // Izinkan CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method === 'POST') {
    try {
      const data = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      const userId = data.userId || data.username || "unknown";

      global.accountsData[userId] = {
        username: data.username || "Unknown Player",
        userId: userId,
        income: data.income || "0/s",
        walkSpeed: data.walkSpeed || 16,
        pets: Array.isArray(data.pets) ? data.pets : [],
        lastUpdated: Date.now()
      };

      return res.status(200).json({ success: true, count: Object.keys(global.accountsData).length });
    } catch (err) {
      return res.status(400).json({ error: "Invalid JSON Data" });
    }
  }

  if (req.method === 'GET') {
    const list = Object.values(global.accountsData || {});
    return res.status(200).json(list);
  }

  return res.status(405).json({ error: "Method Not Allowed" });
}
