#!/usr/bin/env node
/**
 * Generate Apple Sign In Client Secret for Supabase
 *
 * Usage:
 *   npm install jsonwebtoken
 *   node generate_apple_secret.js /path/to/AuthKey_H49QU2J6LU.p8
 */

const fs = require('fs');
const jwt = require('jsonwebtoken');

// Your Apple Developer Configuration
const TEAM_ID = "3SPV37F368";        // Your Apple Team ID
const CLIENT_ID = "com.silni.app";   // Your App Bundle ID
const KEY_ID = "H49QU2J6LU";         // Your Key ID

// Check if key file path is provided
if (process.argv.length < 3) {
  console.log("Usage: node generate_apple_secret.js /path/to/AuthKey_H49QU2J6LU.p8");
  console.log("");
  console.log("Download your .p8 key file from:");
  console.log("https://developer.apple.com/account/resources/authkeys/list");
  process.exit(1);
}

const keyFile = process.argv[2];

// Check if file exists
if (!fs.existsSync(keyFile)) {
  console.log(`Error: Key file not found: ${keyFile}`);
  process.exit(1);
}

// Read the private key
const privateKey = fs.readFileSync(keyFile, 'utf8');

// Current time
const now = Math.floor(Date.now() / 1000);

// JWT claims - valid for 6 months (maximum allowed by Apple)
const claims = {
  iss: TEAM_ID,
  iat: now,
  exp: now + (86400 * 180),  // 6 months
  aud: "https://appleid.apple.com",
  sub: CLIENT_ID
};

// Generate the JWT
const token = jwt.sign(claims, privateKey, {
  algorithm: 'ES256',
  header: {
    kid: KEY_ID,
    alg: 'ES256'
  }
});

console.log("");
console.log("=".repeat(60));
console.log("Apple Sign In Client Secret Generated Successfully!");
console.log("=".repeat(60));
console.log("");
console.log("Copy this entire token and paste it in Supabase:");
console.log("Dashboard > Authentication > Providers > Apple > Secret Key");
console.log("");
console.log("-".repeat(60));
console.log(token);
console.log("-".repeat(60));
console.log("");
console.log("This secret is valid for 6 months.");
console.log(`Regenerate before: ${new Date((now + 86400 * 180) * 1000).toISOString()}`);
console.log("");
