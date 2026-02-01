// server.js
require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
app.use(cors());          // allow your Flutter app to call this backend
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const {
  PORT = 3000,
  DEXCOM_CLIENT_ID,
  DEXCOM_CLIENT_SECRET,
  DEXCOM_REDIRECT_URI,
  DEXCOM_AUTH_URL,
  DEXCOM_TOKEN_URL,
  DEXCOM_EGVS_URL,
} = process.env;

// In-memory token store: { [userId]: { accessToken, refreshToken, expiresAt } }
const tokenStore = {};

//
// 1) Start Dexcom login
//    Flutter opens this in browser:  GET /dexcom/login?userId=<firebaseUid>
//    We redirect to Dexcom OAuth page.
//
app.get('/dexcom/login', (req, res) => {
  const userId = req.query.userId;
  if (!userId) return res.status(400).send('Missing userId');

  const params = new URLSearchParams({
    client_id: DEXCOM_CLIENT_ID,
    redirect_uri: DEXCOM_REDIRECT_URI,
    response_type: 'code',
    scope: 'offline_access',
    state: userId, // we get it back in callback
  });

  const url = `${DEXCOM_AUTH_URL}?${params.toString()}`;
  res.redirect(url);
});

//
// 2) Dexcom redirects here (MUST match DEXCOM_REDIRECT_URI)
//
app.get('/dexcom/callback', async (req, res) => {
  const { code, state: userId } = req.query;
  if (!code || !userId) {
    return res.status(400).send('Missing code or state (userId)');
  }

  try{
    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: DEXCOM_REDIRECT_URI,
      client_id: DEXCOM_CLIENT_ID,
      client_secret: DEXCOM_CLIENT_SECRET,
    });

    const tokenResp = await axios.post(DEXCOM_TOKEN_URL, body.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    });

    const data = tokenResp.data;
    const accessToken = data.access_token;
    const refreshToken = data.refresh_token;
    const expiresIn = data.expires_in; // seconds

    const expiresAt = Date.now() + expiresIn * 1000;

    tokenStore[userId] = { accessToken, refreshToken, expiresAt };

    // Simple page for user in browser
    res.send(`
      <html>
        <body style="font-family: sans-serif;">
          <h2>Dexcom connected!</h2>
          <p>You can now return to the app.</p>
        </body>
      </html>
    `);
  } catch (e) {
    console.error('Dexcom token error:', e.response?.data || e.message);
    res.status(500).send('Dexcom token exchange failed');
  }
});

//
// Helper: get valid access token (refresh if needed)
//
async function getValidAccessToken(userId) {
  const entry = tokenStore[userId];
  if (!entry) return null;

  const now = Date.now();
  if (now < entry.expiresAt - 60 * 1000) {
    // still valid
    return entry.accessToken;
  }

  if (!entry.refreshToken) return null;

  try {
    const body = new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: entry.refreshToken,
      client_id: DEXCOM_CLIENT_ID,
      client_secret: DEXCOM_CLIENT_SECRET,
    });

    const resp = await axios.post(DEXCOM_TOKEN_URL, body.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    });

    const data = resp.data;
    entry.accessToken = data.access_token;
    entry.refreshToken = data.refresh_token || entry.refreshToken;
    entry.expiresAt = Date.now() + data.expires_in * 1000;

    return entry.accessToken;
  } catch (e) {
    console.error('Refresh error:', e.response?.data || e.message);
    return null;
  }
}

//
// 3) Status endpoint: check if user is connected
//
app.get('/dexcom/status', (req, res) => {
  const userId = req.query.userId;
  if (!userId) return res.status(400).json({ connected: false });
  res.json({ connected: !!tokenStore[userId] });
});

//
// 4) Glucose endpoint: Flutter calls this to get EGVs
//    GET /dexcom/egvs?userId=<uid>&hours=3
//
app.get('/dexcom/egvs', async (req, res) => {
  const userId = req.query.userId;
  const hours = parseInt(req.query.hours || '3', 10);

  if (!userId) return res.status(400).send('Missing userId');

  const accessToken = await getValidAccessToken(userId);
  if (!accessToken) return res.status(401).send('Not connected to Dexcom');

  const now = new Date();
  const start = new Date(now.getTime() - hours * 60 * 60 * 1000);

  const fmt = (d) => d.toISOString().split('.')[0]; // trim ms

  const params = new URLSearchParams({
    startDate: fmt(start),
    endDate: fmt(now),
  });

  try {
    const resp = await axios.get(`${DEXCOM_EGVS_URL}?${params.toString()}`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    res.json(resp.data);
  } catch (e) {
    console.error('EGVS error:', e.response?.data || e.message);
    res.status(500).send('Error fetching Dexcom EGVs');
  }
});

app.listen(PORT, () => {
  console.log(`Dexcom backend listening on port ${PORT}`);
});
