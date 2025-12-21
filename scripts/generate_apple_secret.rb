#!/usr/bin/env ruby
# Generate Apple Sign In Client Secret for Supabase
# Usage: ruby generate_apple_secret.rb /path/to/AuthKey_H49QU2J6LU.p8

require 'jwt'
require 'openssl'

# Your Apple Developer Configuration
TEAM_ID = "3SPV37F368"        # Your Apple Team ID
CLIENT_ID = "com.silni.app"   # Your App Bundle ID
KEY_ID = "H49QU2J6LU"         # Your Key ID

# Check if key file path is provided
if ARGV.empty?
  puts "Usage: ruby generate_apple_secret.rb /path/to/AuthKey_H49QU2J6LU.p8"
  puts ""
  puts "Download your .p8 key file from:"
  puts "https://developer.apple.com/account/resources/authkeys/list"
  exit 1
end

key_file = ARGV[0]

unless File.exist?(key_file)
  puts "Error: Key file not found: #{key_file}"
  exit 1
end

# Read the private key
key_content = File.read(key_file)
ecdsa_key = OpenSSL::PKey::EC.new(key_content)

# JWT headers
headers = {
  "kid" => KEY_ID,
  "alg" => "ES256"
}

# JWT claims - valid for 6 months (maximum allowed)
now = Time.now.to_i
claims = {
  "iss" => TEAM_ID,
  "iat" => now,
  "exp" => now + (86400 * 180),  # 6 months
  "aud" => "https://appleid.apple.com",
  "sub" => CLIENT_ID
}

# Generate the JWT
token = JWT.encode(claims, ecdsa_key, "ES256", headers)

puts ""
puts "=" * 60
puts "Apple Sign In Client Secret Generated Successfully!"
puts "=" * 60
puts ""
puts "Copy this entire token and paste it in Supabase:"
puts "Dashboard > Authentication > Providers > Apple > Secret Key"
puts ""
puts "-" * 60
puts token
puts "-" * 60
puts ""
puts "This secret is valid for 6 months."
puts "Regenerate before: #{Time.at(now + 86400 * 180)}"
puts ""
