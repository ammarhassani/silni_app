const { execSync } = require('child_process');
const fs = require('fs');

// Read the rules file
const rulesContent = fs.readFileSync('firestore.rules', 'utf8');

// Escape for JSON
const escapedRules = JSON.stringify(rulesContent);

// Create the request body
const requestBody = JSON.stringify({
  source: {
    files: [{
      name: 'firestore.rules',
      content: rulesContent
    }]
  }
});

// Write to temp file for curl
fs.writeFileSync('rules_payload.json', requestBody);

console.log('📝 Rules file read successfully');
console.log('🔍 Deploying to Firebase...');
console.log('⚠️  You will be prompted to authenticate in your browser');

try {
  // Use firebase CLI to get authenticated request
  const result = execSync(
    'firebase --config firestore:release --project silni-31811',
    { encoding: 'utf8', stdio: 'inherit' }
  );
  console.log('✅ Rules deployed successfully!');
} catch (error) {
  console.error('❌ Deployment failed:', error.message);
  console.log('\n📋 Alternative: Manual deployment via Firebase Console');
  console.log('   Go to: https://console.firebase.google.com/project/silni-31811/firestore/rules');
  console.log('   Copy the rules from firestore.rules and paste them');
}

// Clean up
fs.unlinkSync('rules_payload.json');
