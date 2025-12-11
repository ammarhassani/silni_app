#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the Runner target
target = project.targets.first

# Get the Runner group
runner_group = project.main_group['Runner']

# Check if GoogleService-Info.plist already exists in project
existing_file = runner_group.files.find { |f| f.display_name == 'GoogleService-Info.plist' }

if existing_file
  puts "✅ GoogleService-Info.plist already in project"
else
  # Add GoogleService-Info.plist to the project
  file_ref = runner_group.new_reference('Runner/GoogleService-Info.plist')

  # Add to Copy Bundle Resources build phase
  resources_build_phase = target.resources_build_phase
  resources_build_phase.add_file_reference(file_ref)

  puts "✅ Added GoogleService-Info.plist to Xcode project"
end

# Save the project
project.save

puts "✅ Project saved successfully"
puts "Now commit the updated ios/Runner.xcodeproj/project.pbxproj file"
