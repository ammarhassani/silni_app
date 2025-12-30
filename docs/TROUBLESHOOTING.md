# Silni App - Troubleshooting and FAQ

## Overview

This comprehensive troubleshooting guide helps users and developers resolve common issues with Silni app. It includes step-by-step solutions, frequently asked questions, and best practices for optimal app performance.

## Table of Contents

1. [Installation & Setup Issues](#installation--setup-issues)
2. [Account & Authentication](#account--authentication)
3. [Family Management Issues](#family-management-issues)
4. [Interaction Tracking Problems](#interaction-tracking-problems)
5. [Reminder System Issues](#reminder-system-issues)
6. [Gamification & Points](#gamification--points)
7. [AI Features Problems](#ai-features-problems)
8. [Performance Issues](#performance-issues)
9. [Sync & Backup Issues](#sync--backup-issues)
10. [Notification Problems](#notification-problems)
11. [Platform-Specific Issues](#platform-specific-issues)
12. [Advanced Troubleshooting](#advanced-troubleshooting)

---

## Installation & Setup Issues

### App Won't Install

#### iOS Installation Problems

**Problem**: App won't install from App Store

**Solutions**:
1. **Check iOS Version**: Ensure iOS 12.0 or later
2. **Free Up Space**: Need at least 100MB available
3. **Restart Device**: Hold power button + volume up until Apple logo appears
4. **Update iOS**: Settings → General → Software Update
5. **Check Region**: App Store region must match your App Store account
6. **Reset App Store**: Settings → App Store → Apple ID → Sign Out, then sign back in

**Problem**: Installation gets stuck at "Waiting..."

**Solutions**:
1. **Check Internet**: Stable Wi-Fi or cellular connection
2. **Restart Download**: Pause and resume download
3. **Free Storage**: Check available device storage
4. **Update iOS**: Ensure latest iOS version
5. **Try Different Network**: Switch between Wi-Fi and cellular

#### Android Installation Problems

**Problem**: App won't install from Google Play

**Solutions**:
1. **Check Android Version**: Need Android 5.0 (API level 21) or later
2. **Free Up Space**: Need at least 100MB available
3. **Clear Play Store Cache**: Settings → Apps → Google Play Store → Clear cache
4. **Update Google Play**: Ensure latest Play Store version
5. **Check Storage**: Ensure device isn't in storage optimization mode
6. **Restart Device**: Power off and on again

**Problem**: "App not installed" error from APK

**Solutions**:
1. **Enable Unknown Sources**: Settings → Security → Unknown sources (allow this installation only)
2. **Check APK Integrity**: Ensure file isn't corrupted
3. **Verify Permissions**: Grant all requested permissions during installation
4. **Disable Play Protect**: Temporarily disable if blocking installation
5. **Free Up Space**: Clear cache and unnecessary apps

### First-Time Setup Issues

#### Environment Configuration Problems

**Problem**: App crashes on startup after environment setup

**Solutions**:
1. **Check .env File**: Ensure all required variables are set
2. **Validate API Keys**: Verify Supabase and Firebase credentials are correct
3. **Regenerate Code**: Run `flutter pub run build_runner build`
4. **Clear Cache**: Delete app data and try again
5. **Check Flutter Version**: Ensure compatible Flutter version

```bash
# Validate environment setup
flutter pub run build_runner build
flutter doctor -v

# Check for common issues
echo "Checking environment variables..."
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

echo "Environment setup validated successfully"
```

---

## Account & Authentication

### Login Issues

#### Can't Log In with Email/Password

**Problem**: "Invalid credentials" error despite correct login

**Solutions**:
1. **Check Email Format**: Ensure email is entered correctly
2. **Verify Password**: Check for typos, caps lock, extra spaces
3. **Clear App Cache**: Settings → Apps → Silni → Clear cache
4. **Reset Password**: Use "Forgot Password" feature
5. **Check Account Status**: Verify account isn't locked or suspended

**Problem**: Account locked due to multiple failed attempts

**Solutions**:
1. **Wait 30 Minutes**: Lockout automatically expires after 30 minutes
2. **Use Forgot Password**: Reset password instead of waiting
3. **Contact Support**: If lockout persists, contact support team
4. **Enable 2FA**: Add two-factor authentication to prevent future lockouts

#### Social Login Issues

**Problem**: Google/Apple login not working

**Google Login Solutions**:
1. **Check Google Account**: Ensure account is active and not suspended
2. **Update Google Play Services**: Ensure latest Google Play Services
3. **Clear Google Account Data**: Remove cached Google account data
4. **Revoke App Access**: Revoke app access in Google account settings
5. **Try Different Browser**: If using web login, try different browser

**Apple Login Solutions**:
1. **Check Apple ID**: Ensure Apple ID is active
2. **Update iOS**: Ensure latest iOS version
3. **Check Two-Factor**: Verify 2FA is working correctly
4. **Sign Out and Back In**: Try signing out of Apple ID and signing back in
5. **Check App Store Connect**: Ensure app is properly configured

### Account Verification Issues

#### Email Verification Not Received

**Problem**: Verification email not arriving

**Solutions**:
1. **Check Spam Folder**: Look in email spam/junk folders
2. **Verify Email Address**: Ensure correct email address was entered
3. **Wait 10 Minutes**: Email delivery can sometimes be delayed
4. **Request New Verification**: Use "Resend verification" option
5. **Check Email Filters**: Verify email provider isn't blocking verification emails

**Problem**: Verification link expired or invalid

**Solutions**:
1. **Request New Verification**: Generate fresh verification link
2. **Check Link Timestamp**: Verification links expire after 24 hours
3. **Copy Link Manually**: Copy and paste link instead of clicking
4. **Use Private Browser**: Try in incognito/private browsing mode
5. **Clear Browser Cache**: Clear browser cache and cookies

---

## Family Management Issues

### Can't Add Family Members

#### Form Validation Errors

**Problem**: "Required field missing" or "Invalid format" errors

**Solutions**:
1. **Check All Fields**: Ensure all required fields are filled
2. **Validate Email Format**: Use correct email format (user@domain.com)
3. **Check Phone Number**: Include country code and valid number
4. **Name Length**: Names must be 2-100 characters
5. **Relationship Selection**: Must select a valid relationship type

#### Database Save Errors

**Problem**: "Failed to save family member" error

**Solutions**:
1. **Check Internet Connection**: Ensure stable internet connection
2. **Verify Permissions**: Check app has necessary permissions
3. **Restart App**: Close and reopen the app
4. **Check Server Status**: Verify backend services are operational
5. **Try Again Later**: Server might be temporarily unavailable

#### Contact Import Issues

**Problem**: Contacts import not working

**Solutions**:
1. **Grant Contacts Permission**: Go to Settings → Apps → Silni → Permissions → Contacts
2. **Enable Contacts Access**: Toggle contacts permission on
3. **Check Contact Permissions**: Ensure system-level contacts permission is granted
4. **Restart App**: Force close and reopen app after granting permissions
5. **Try Manual Import**: Add contacts manually if import continues to fail

### Family Member Display Issues

#### Profile Pictures Not Loading

**Problem**: Family member photos not displaying

**Solutions**:
1. **Check Internet Connection**: Photos require internet to load
2. **Clear Image Cache**: Settings → Clear image cache
3. **Check Photo URL**: Verify photo URL is valid and accessible
4. **Update App**: Ensure latest app version is installed
5. **Use Default Avatar**: Set to default avatar if photo issues persist

#### Family Tree View Problems

**Problem**: Family tree not displaying correctly

**Solutions**:
1. **Check Relationships**: Verify relationship types are set correctly
2. **Refresh Data**: Pull down to refresh family data
3. **Check Network**: Ensure stable internet for real-time updates
4. **Update App**: Install latest version with bug fixes
5. **Report Issue**: Contact support if problem persists

---

## Interaction Tracking Problems

### Can't Log Interactions

#### Form Submission Errors

**Problem**: "Failed to log interaction" error

**Solutions**:
1. **Validate Required Fields**: Ensure date and interaction type are selected
2. **Check Date Format**: Ensure date is valid and not in future
3. **Verify Family Member**: Ensure family member is selected
4. **Check Internet**: Ensure stable connection for saving
5. **Try Again Later**: Temporary server issues might cause failures

#### Interaction History Issues

**Problem**: Interaction history not loading or displaying

**Solutions**:
1. **Refresh Data**: Pull down to refresh interaction data
2. **Check Filter Settings**: Verify filters aren't hiding interactions
3. **Check Date Range**: Ensure date range includes expected interactions
4. **Clear Cache**: Clear app cache and restart
5. **Check Network**: Ensure stable internet for data loading

#### Photo Upload Issues

**Problem**: Can't upload photos with interactions

**Solutions**:
1. **Check Photo Size**: Ensure photos are under 10MB limit
2. **Check Photo Format**: Use supported formats (JPEG, PNG)
3. **Check Internet**: Stable connection required for uploads
4. **Free Up Storage**: Ensure sufficient device storage
5. **Compress Photos**: Use smaller photos or compress before upload

---

## Reminder System Issues

### Reminders Not Triggering

#### Schedule Configuration Problems

**Problem**: Reminders not triggering at scheduled times

**Solutions**:
1. **Check Schedule Settings**: Verify time, frequency, and days are correct
2. **Check Notification Permissions**: Ensure app can send notifications
3. **Check Do Not Disturb**: Ensure DND isn't blocking notifications
4. **Check Battery Optimization**: Disable battery optimization for the app
5. **Test Notification**: Use "Test Notification" feature to verify setup

#### Notification Delivery Issues

**Problem**: Not receiving push notifications

**Solutions**:
1. **Check Internet**: Push notifications require internet
2. **Check Notification Settings**: Verify notifications are enabled in device settings
3. **Check App Permissions**: Ensure app has notification permissions
4. **Restart Device**: Sometimes device restart fixes notification issues
5. **Check OS Battery Settings**: Ensure app isn't being optimized aggressively

#### Local Notification Issues

**Problem**: In-app notifications not showing

**Solutions**:
1. **Check App Settings**: Verify in-app notifications are enabled
2. **Check Sound Settings**: Ensure notification sound is enabled
3. **Check Volume**: Ensure device volume is up and not muted
4. **Check Focus Mode**: Ensure app isn't in focus mode
5. **Restart App**: Force close and reopen app

---

## Gamification & Points

### Points Not Awarding

#### Interaction Points Not Adding Up

**Problem**: Points not being awarded after logging interactions

**Solutions**:
1. **Check Internet**: Points calculation requires server connection
2. **Verify Interaction Saved**: Ensure interaction was successfully saved
3. **Refresh Profile**: Pull down to refresh profile data
4. **Check Point Rules**: Review point calculation rules for interaction type
5. **Report Issue**: Contact support if points consistently don't update

#### Achievement Issues

**Problem**: Achievements not unlocking

**Solutions**:
1. **Check Requirements**: Verify you meet achievement requirements
2. **Check Progress**: Review achievement progress in gamification section
3. **Refresh Data**: Pull down to sync latest achievement data
4. **Check Achievement Logic**: Some achievements have specific unlock conditions
5. **Wait for Sync**: Some achievements may take time to register

#### Leaderboard Issues

**Problem**: Not appearing on leaderboard or incorrect ranking

**Solutions**:
1. **Check Opt-In**: Verify you've opted into leaderboard participation
2. **Check Privacy Settings**: Ensure leaderboard sharing is enabled
3. **Refresh Data**: Pull down to sync latest leaderboard data
4. **Check Time Zone**: Ensure device time zone is correct
5. **Check Internet**: Stable connection required for leaderboard updates

---

## AI Features Problems

### AI Assistant Not Working

#### AI Features Not Available

**Problem**: AI features showing as "not available" or disabled

**Solutions**:
1. **Check Subscription**: Verify you have premium subscription for AI features
2. **Check Internet**: AI features require internet connection
3. **Check AI Service Status**: Verify AI backend services are operational
4. **Update App**: Ensure latest version with AI features
5. **Check Feature Flags**: Verify AI features are enabled in settings

#### AI Analysis Issues

**Problem**: AI analysis not generating insights

**Solutions**:
1. **Check Data Availability**: Need sufficient interaction history for analysis
2. **Check Family Member Data**: Ensure family member has complete profile
3. **Check Internet**: Stable connection required for AI processing
4. **Try Different Analysis**: Try analyzing different family members or time periods
5. **Check AI Credits**: Verify you have sufficient AI credits if applicable

#### AI Content Issues

**Problem**: AI-generated content inappropriate or irrelevant

**Solutions**:
1. **Provide Feedback**: Rate AI-generated content to improve future results
2. **Adjust Context**: Provide more specific context for better results
3. **Check Input Quality**: Ensure prompts are clear and specific
4. **Use Templates**: Try using predefined AI templates
5. **Report Issues**: Report problematic AI content to support team

---

## Performance Issues

### App Running Slow

#### General Performance Issues

**Problem**: App is slow or laggy

**Solutions**:
1. **Close Other Apps**: Free up device memory and CPU
2. **Restart Device**: Clear temporary memory and cache
3. **Update App**: Install latest version with performance improvements
4. **Clear App Cache**: Settings → Clear cache and data
5. **Check Storage Space**: Ensure sufficient free storage on device

#### Memory Issues

**Problem**: App crashing due to memory issues

**Solutions**:
1. **Free Up Device Storage**: Remove unnecessary apps and files
2. **Restart Device**: Clear RAM and temporary files
3. **Update OS**: Install latest operating system updates
4. **Check Memory Usage**: Monitor which apps are using most memory
5. **Use Lite Version**: Consider using lite version if available

#### Battery Drain Issues

**Problem**: App draining battery quickly

**Solutions**:
1. **Disable Background Refresh**: Turn off automatic data refresh
2. **Reduce Notification Frequency**: Optimize notification settings
3. **Enable Battery Saver**: Use device battery optimization features
4. **Update App**: Install latest version with battery improvements
5. **Check Location Services**: Disable unnecessary location tracking

---

## Sync & Backup Issues

### Data Not Syncing

#### Sync Problems

**Problem**: Changes not syncing across devices

**Solutions**:
1. **Check Internet**: Stable connection required for sync
2. **Verify Account**: Ensure you're logged into correct account
3. **Manual Sync**: Pull down to force manual sync
4. **Check Sync Settings**: Verify sync is enabled in settings
5. **Restart App**: Force close and reopen app to restart sync

#### Conflict Resolution

**Problem**: Sync conflicts when data edited on multiple devices

**Solutions**:
1. **Choose Which Version to Keep**: Select which device's data to preserve
2. **Manual Merge**: Manually combine data from both devices
3. **Use Web Portal**: Use web interface to resolve conflicts
4. **Backup Before Sync**: Always backup before resolving conflicts
5. **Contact Support**: Get help from support team for complex conflicts

### Backup Issues

#### Backup Not Working

**Problem**: Backup creation failing

**Solutions**:
1. **Check Storage Space**: Ensure sufficient space for backup
2. **Check Internet**: Stable connection required for cloud backup
3. **Check Backup Settings**: Verify backup is configured correctly
4. **Manual Backup**: Use manual backup option if automatic fails
5. **Check Account**: Ensure you're logged into correct account

#### Restore Issues

**Problem**: Can't restore from backup

**Solutions**:
1. **Verify Backup File**: Ensure backup file is valid and not corrupted
2. **Check Internet**: Stable connection required for restore
3. **Check Account**: Ensure you're logged into correct account
4. **Sufficient Storage**: Ensure enough space for restored data
5. **Try Partial Restore**: Restore data in smaller chunks if full restore fails

---

## Notification Problems

### Push Notification Issues

#### Not Receiving Push Notifications

**Problem**: Not receiving any push notifications

**Solutions**:
1. **Check Notification Permissions**: Enable notifications in device settings
2. **Check App Permissions**: Ensure app has notification permissions
3. **Check Do Not Disturb**: Ensure DND isn't blocking notifications
4. **Check Battery Settings**: Ensure app isn't being optimized aggressively
5. **Reinstall App**: Sometimes reinstallation fixes notification issues

#### Notification Sound Issues

**Problem**: Notifications not playing sound

**Solutions**:
1. **Check Device Volume**: Ensure device volume is up and not muted
2. **Check App Settings**: Verify notification sound is enabled in app
3. **Check Sound Settings**: Ensure notification sound is enabled in device settings
4. **Test with Different Sound**: Try changing notification sound
5. **Check Vibration**: Ensure vibration is enabled if sound isn't working

#### Notification Display Issues

**Problem**: Notifications not displaying properly

**Solutions**:
1. **Check Notification Settings**: Verify notifications are enabled in app and device
2. **Check Lock Screen**: Ensure notifications show on lock screen
3. **Check Banner Settings**: Ensure banner notifications are enabled
4. **Restart Device**: Sometimes device restart fixes display issues
5. **Update App**: Install latest version with notification fixes

---

## Platform-Specific Issues

### iOS-Specific Issues

#### App Store Issues

**Problem**: App not available in App Store or update issues

**Solutions**:
1. **Check Region**: Ensure App Store region matches your location
2. **Update iOS**: Ensure latest iOS version is installed
3. **Sign Out and Back In**: Sign out of App Store and sign back in
4. **Check Device Compatibility**: Verify device is supported by app
5. **Contact Apple Support**: If issues persist, contact Apple App Store support

#### iOS Permission Issues

**Problem**: App permissions not working on iOS

**Solutions**:
1. **Check Settings → Privacy**: Verify app permissions are enabled
2. **Restart Device**: Sometimes permission changes require restart
3. **Update iOS**: Ensure latest iOS version is installed
4. **Reset Location Settings**: Reset location privacy settings if location permissions fail
5. **Reinstall App**: Sometimes reinstallation fixes permission issues

### Android-Specific Issues

#### Google Play Issues

**Problem**: App not available in Google Play or update issues

**Solutions**:
1. **Check Google Account**: Ensure you're logged into correct Google account
2. **Clear Play Store Cache**: Clear cache and data in Google Play Store
3. **Update Play Store**: Ensure latest Google Play Store version
4. **Check Device Compatibility**: Verify device meets minimum requirements
5. **Use Direct APK**: Install APK directly if Play Store issues persist

#### Android Permission Issues

**Problem**: App permissions not working on Android

**Solutions**:
1. **Check App Permissions**: Go to Settings → Apps → Silni → Permissions
2. **Enable Permissions**: Grant all requested permissions
3. **Check OS Permissions**: Go to Settings → Privacy → Permission manager
4. **Restart Device**: Sometimes permission changes require restart
5. **Reinstall App**: Sometimes reinstallation fixes permission issues

---

## Advanced Troubleshooting

### Debug Mode

#### Enabling Debug Mode

**Problem**: Need to enable debug mode for troubleshooting

**Solutions**:

**iOS Debug Mode**:
1. **Connect Device to Computer**: Use USB cable
2. **Open Xcode**: Open Xcode and select your device
3. **Enable Debug Mode**: Enable debug mode in Xcode device settings
4. **Run App from Xcode**: Build and run app directly from Xcode

**Android Debug Mode**:
1. **Enable Developer Options**: Go to Settings → About phone → Tap build number 7 times
2. **Enable USB Debugging**: Enable USB debugging option
3. **Connect to Computer**: Use USB cable
4. **Run Debug Command**: Use `adb logcat` to view debug logs
5. **Use Android Studio**: Run app directly from Android Studio with debug configuration

### Log Collection

#### Collecting Diagnostic Logs

**Problem**: Need to collect logs for support ticket

**Solutions**:
1. **Enable Debug Logging**: Enable debug mode in app settings
2. **Reproduce Issue**: Perform actions that trigger the problem
3. **Export Logs**: Use app's export logs feature
4. **Include Device Info**: Include device model, OS version, app version
5. **Share with Support**: Send logs to support team with detailed issue description

### Factory Reset

#### App Reset Issues

**Problem**: Need to reset app to default state

**Solutions**:
1. **Backup Data**: Backup all important data before reset
2. **Use Reset Option**: Use app's reset option in settings
3. **Clear All Data**: Clear cache, preferences, and local data
4. **Reinstall App**: Uninstall and reinstall app for complete reset
5. **Restore Data**: Restore backed up data after reset

---

## Frequently Asked Questions

### General Questions

**Q: Is Silni free to use?**
A: Silni offers a freemium model. Basic features are free, but premium features require a subscription.

**Q: How do I delete my account?**
A: Go to Settings → Account → Delete Account. This will permanently delete all your data.

**Q: Can I use Silni without internet?**
A: Yes, most features work offline, but some features require internet for synchronization.

**Q: Is my data secure?**
A: Yes, all data is encrypted and stored securely. We follow industry best practices for data protection.

**Q: How do I contact support?**
A: Email us at support@silni.app or use the in-app support chat feature.

### Technical Questions

**Q: What are the system requirements?**
A: iOS 12+, Android 5.0+, or modern web browser with internet connection.

**Q: Does Silni work on tablets?**
A: Yes, Silni is optimized for both phones and tablets on iOS and Android.

**Q: Can I use Silni on multiple devices?**
A: Yes, you can use Silni on multiple devices with the same account. Data syncs across all devices.

### Feature Questions

**Q: How do I add family members who don't use Silni?**
A: You can add family members manually and track interactions on their behalf.

**Q: Can I export my data?**
A: Yes, you can export your family data and interactions from the settings menu.

**Q: How do reminder notifications work?**
A: Reminders use both push notifications and in-app notifications based on your settings.

**Q: Are AI features included in free plan?**
A: Basic AI features are included, but advanced AI insights require a premium subscription.

### Subscription Questions

**Q: How do I cancel my subscription?**
A: Go to Settings → Subscription → Cancel Subscription. Your access continues until the end of the billing period.

**Q: Can I change my subscription plan?**
A: Yes, you can upgrade or downgrade your subscription at any time from the settings menu.

**Q: What happens to my data if I cancel my subscription?**
A: Your data remains safe and you can continue using free features. Premium features become unavailable.

---

## Getting Help

### Self-Service Resources

1. **In-App Help**: Tap the "?" icon in any screen for context-sensitive help
2. **Help Library**: Browse comprehensive help articles and tutorials
3. **FAQ Section**: Find answers to common questions
4. **Video Tutorials**: Watch step-by-step video guides
5. **Community Forum**: Get help from other users and community moderators

### Contacting Support

#### When to Contact Support

1. **Critical Issues**: App crashes, data loss, security concerns
2. **Payment Issues**: Subscription problems, payment failures
3. **Account Issues**: Login problems, account lockouts
4. **Bug Reports**: Persistent bugs not resolved through troubleshooting

#### Information to Include

1. **Device Information**: Device model, OS version, app version
2. **Issue Description**: Detailed description of the problem
3. **Steps to Reproduce**: Clear steps to reproduce the issue
4. **Expected vs Actual**: What you expected vs. what actually happened
5. **Troubleshooting Steps**: Steps you've already tried

#### Contact Methods

- **Email**: support@silni.app
- **In-App Support**: Use support chat feature in app
- **Community Forum**: https://community.silni.app
- **Twitter**: @SilniSupport
- **Response Time**: Within 24 hours for critical issues, 48 hours for general issues

---

## Conclusion

This troubleshooting guide covers the most common issues users may encounter with Silni app. By following these solutions systematically, most problems can be resolved quickly.

### Best Practices

1. **Keep App Updated**: Always use the latest version of Silni
2. **Stable Internet**: Ensure reliable internet connection for data-dependent features
3. **Regular Backups**: Backup your data regularly to prevent data loss
4. **Follow Security Best Practices**: Use strong passwords and enable available security features
5. **Provide Feedback**: Report issues and provide feedback to help improve the app

### Escalation Path

If you've tried all troubleshooting steps and still can't resolve your issue:

1. **Document Everything**: Keep detailed notes of what you've tried
2. **Collect Logs**: Gather diagnostic logs and device information
3. **Contact Support**: Reach out with comprehensive information
4. **Be Patient**: Complex issues may take time to resolve
5. **Follow Up**: Don't hesitate to follow up if you don't hear back within expected timeframes

Thank you for using Silni to strengthen your family bonds. We're committed to providing the best possible support and continuously improving the app experience.