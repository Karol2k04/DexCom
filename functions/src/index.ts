import {onRequest, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Inicjalizacja Firebase Admin
admin.initializeApp();

/**
 * Cloud Function do obsługi OAuth callback dla Dexcom API
 */
export const dexcomCallback = onRequest(
  {
    cors: true,
    invoker: "public",
  },
  async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const code = req.query.code as string;
    const state = req.query.state as string;
    const error = req.query.error as string;

    if (error) {
      console.error("OAuth error:", error);
      res.status(400).send(generateErrorPage(error));
      return;
    }

    if (!code) {
      res.status(400).send(generateErrorPage("Missing authorization code"));
      return;
    }

    console.log("Otrzymano authorization code:", code);
    console.log("State:", state);

    const deepLink = `myapp://dexcom/callback?code=${encodeURIComponent(code)}&state=${encodeURIComponent(state || "")}`;

    if (state) {
      await admin.firestore().collection("oauth_sessions").doc(state).set({
        code: code,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        used: false,
      });
    }

    res.status(200).send(generateSuccessPage(code, state, deepLink));
  } catch (error) {
    console.error("Error in dexcomCallback:", error);
    res.status(500).send(generateErrorPage("Internal server error"));
  }
});

/**
 * Pomocnicza funkcja do wymiany authorization code na access token
 */
export const exchangeToken = onCall(async (request) => {
  const {code, clientId, clientSecret, redirectUri} = request.data;

  if (!code || !clientId || !clientSecret || !redirectUri) {
    throw new Error("Missing required parameters");
  }

  try {
    const response = await fetch("https://api.dexcom.com/v2/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirectUri,
        client_id: clientId,
        client_secret: clientSecret,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Token exchange failed: ${errorText}`);
    }

    const tokenData = await response.json();

    if (request.auth?.uid) {
      await admin.firestore().collection("user_tokens").doc(request.auth.uid).set({
        accessToken: tokenData.access_token,
        refreshToken: tokenData.refresh_token,
        expiresIn: tokenData.expires_in,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      accessToken: tokenData.access_token,
      refreshToken: tokenData.refresh_token,
      expiresIn: tokenData.expires_in,
    };
  } catch (error) {
    console.error("Token exchange error:", error);
    throw new Error("Failed to exchange token");
  }
});

/**
 * Funkcja do odświeżania access token
 */
export const refreshToken = onCall(async (request) => {
  const {refreshToken, clientId, clientSecret} = request.data;

  if (!refreshToken || !clientId || !clientSecret) {
    throw new Error("Missing required parameters");
  }

  try {
    const response = await fetch("https://api.dexcom.com/v2/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: refreshToken,
        client_id: clientId,
        client_secret: clientSecret,
      }),
    });

    if (!response.ok) {
      throw new Error("Token refresh failed");
    }

    const tokenData = await response.json();

    if (request.auth?.uid) {
      await admin.firestore().collection("user_tokens").doc(request.auth.uid).update({
        accessToken: tokenData.access_token,
        expiresIn: tokenData.expires_in,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      accessToken: tokenData.access_token,
      expiresIn: tokenData.expires_in,
    };
  } catch (error) {
    console.error("Token refresh error:", error);
    throw new Error("Failed to refresh token");
  }
});

function generateSuccessPage(code: string, state: string | null, deepLink: string): string {
  return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Autoryzacja udana</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            padding: 20px;
            text-align: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px;
            width: 100%;
        }
        h1 {
            color: #4CAF50;
            margin-bottom: 20px;
        }
        .success-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        code {
            background: #f5f5f5;
            padding: 10px;
            display: block;
            margin: 15px 0;
            border-radius: 5px;
            word-break: break-all;
            font-size: 12px;
            text-align: left;
        }
        .btn {
            background: #4CAF50;
            color: white;
            padding: 15px 32px;
            text-decoration: none;
            display: inline-block;
            margin: 20px 0;
            border-radius: 8px;
            font-size: 16px;
            font-weight: bold;
            transition: background 0.3s;
        }
        .btn:hover {
            background: #45a049;
        }
        .info {
            color: #666;
            font-size: 14px;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✅</div>
        <h1>Autoryzacja udana!</h1>
        <p><strong>Authorization code otrzymany</strong></p>
        <code>${code.substring(0, 20)}...</code>
        ${state ? `<p>State: <code>${state}</code></p>` : ""}
        
        <a href="${deepLink}" class="btn">Otwórz w aplikacji</a>
        
        <p class="info">
            Kliknij przycisk powyżej aby przekierować do aplikacji mobilnej.<br>
            Jeśli jesteś na komputerze, ta strona może się automatycznie zamknąć.
        </p>
    </div>
    
    <script>
        if (/Android|iPhone|iPad|iPod/i.test(navigator.userAgent)) {
            setTimeout(() => {
                window.location.href = "${deepLink}";
            }, 1000);
        }
    </script>
</body>
</html>
  `;
}

function generateErrorPage(error: string): string {
  return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Błąd autoryzacji</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            padding: 20px;
            text-align: center;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px;
            width: 100%;
        }
        h1 {
            color: #f44336;
            margin-bottom: 20px;
        }
        .error-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        .error-message {
            background: #ffebee;
            color: #c62828;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon">❌</div>
        <h1>Błąd autoryzacji</h1>
        <div class="error-message">
            ${error}
        </div>
        <p>Spróbuj ponownie zalogować się w aplikacji.</p>
    </div>
</body>
</html>
  `;
}
