/**
 * SIGN UP SCREEN - MODERN REDESIGN
 *
 * User registration with:
 * - Beautiful gradient background
 * - Glassmorphism UI
 * - Form validation
 * - Smooth animations
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuthStore } from '@/store/authStore';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';
import { GradientBackground, GlassCard, GradientButton } from '@/components/ui';
import { FadeInView } from '@/components/animated';

export default function SignUpScreen() {
  const navigation = useNavigation<any>();
  const { signUp, isLoading, error, clearError } = useAuthStore();

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const handleSignUp = async () => {
    // Clear previous errors
    clearError();

    // Validation
    if (!fullName.trim() || !email.trim() || !password.trim() || !confirmPassword.trim()) {
      Alert.alert('خطأ', 'يرجى إكمال جميع الحقول');
      return;
    }

    if (fullName.trim().length < 2) {
      Alert.alert('خطأ', 'الاسم يجب أن يكون حرفين على الأقل');
      return;
    }

    if (password.length < 6) {
      Alert.alert('خطأ', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (password !== confirmPassword) {
      Alert.alert('خطأ', 'كلمة المرور وتأكيد كلمة المرور غير متطابقين');
      return;
    }

    const success = await signUp(email.trim(), password, fullName.trim());

    if (success) {
      // Navigate immediately after successful signup
      navigation.replace('MainTabs');

      // Show success message after navigation (non-blocking)
      setTimeout(() => {
        Alert.alert(
          'تم إنشاء الحساب بنجاح!',
          'تم إرسال رسالة تفعيل إلى بريدك الإلكتروني'
        );
      }, 500);
    }
  };

  return (
    <GradientBackground colors={Colors.gradients.royal}>
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <FadeInView delay={100} style={styles.header}>
            <View style={styles.logoContainer}>
              <GlassCard style={styles.logoGlass} intensity={95}>
                <Text style={styles.logoEmoji}>✨</Text>
              </GlassCard>
            </View>
            <Text style={styles.title}>إنشاء حساب جديد</Text>
            <Text style={styles.subtitle}>انضم إلينا وابدأ رحلتك</Text>
          </FadeInView>

          {/* Form Card */}
          <FadeInView delay={300}>
            <GlassCard style={styles.formCard} intensity={95}>
              {/* Full Name Input */}
              <View style={styles.inputContainer}>
                <Text style={styles.label}>الاسم الكامل</Text>
                <TextInput
                  style={styles.input}
                  placeholder="محمد أحمد"
                  placeholderTextColor={Colors.glass.white}
                  value={fullName}
                  onChangeText={setFullName}
                  autoCapitalize="words"
                  textAlign="right"
                />
              </View>

              {/* Email Input */}
              <View style={styles.inputContainer}>
                <Text style={styles.label}>البريد الإلكتروني</Text>
                <TextInput
                  style={styles.input}
                  placeholder="example@email.com"
                  placeholderTextColor={Colors.glass.white}
                  value={email}
                  onChangeText={setEmail}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoComplete="email"
                  textAlign="right"
                />
              </View>

              {/* Password Input */}
              <View style={styles.inputContainer}>
                <Text style={styles.label}>كلمة المرور</Text>
                <View style={styles.passwordContainer}>
                  <TouchableOpacity
                    onPress={() => setShowPassword(!showPassword)}
                    style={styles.eyeButton}
                  >
                    <Text style={styles.eyeIcon}>{showPassword ? '👁️' : '👁️‍🗨️'}</Text>
                  </TouchableOpacity>
                  <TextInput
                    style={[styles.input, styles.passwordInput]}
                    placeholder="6 أحرف على الأقل"
                    placeholderTextColor={Colors.glass.white}
                    value={password}
                    onChangeText={setPassword}
                    secureTextEntry={!showPassword}
                    autoCapitalize="none"
                    textAlign="right"
                  />
                </View>
              </View>

              {/* Confirm Password Input */}
              <View style={styles.inputContainer}>
                <Text style={styles.label}>تأكيد كلمة المرور</Text>
                <View style={styles.passwordContainer}>
                  <TouchableOpacity
                    onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                    style={styles.eyeButton}
                  >
                    <Text style={styles.eyeIcon}>
                      {showConfirmPassword ? '👁️' : '👁️‍🗨️'}
                    </Text>
                  </TouchableOpacity>
                  <TextInput
                    style={[styles.input, styles.passwordInput]}
                    placeholder="أعد إدخال كلمة المرور"
                    placeholderTextColor={Colors.glass.white}
                    value={confirmPassword}
                    onChangeText={setConfirmPassword}
                    secureTextEntry={!showConfirmPassword}
                    autoCapitalize="none"
                    textAlign="right"
                  />
                </View>
              </View>

              {/* Error Message */}
              {error && (
                <View style={styles.errorContainer}>
                  <Text style={styles.errorText}>{error}</Text>
                </View>
              )}

              {/* Sign Up Button */}
              <GradientButton
                title="إنشاء حساب"
                onPress={handleSignUp}
                variant="accent"
                size="large"
                loading={isLoading}
                disabled={isLoading}
                style={styles.signUpButton}
              />

              {/* Terms & Privacy */}
              <Text style={styles.termsText}>
                بإنشاء حساب، أنت توافق على{' '}
                <Text style={styles.termsLink}>الشروط والأحكام</Text> و
                <Text style={styles.termsLink}>سياسة الخصوصية</Text>
              </Text>

              {/* Login Link */}
              <View style={styles.loginContainer}>
                <TouchableOpacity onPress={() => navigation.navigate('Login')}>
                  <Text style={styles.loginLink}>تسجيل الدخول</Text>
                </TouchableOpacity>
                <Text style={styles.loginText}>لديك حساب بالفعل؟ </Text>
              </View>
            </GlassCard>
          </FadeInView>
        </ScrollView>
      </KeyboardAvoidingView>
    </GradientBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.xl,
    paddingBottom: Spacing.xl,
  },
  header: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  logoContainer: {
    marginBottom: Spacing.md,
  },
  logoGlass: {
    width: 90,
    height: 90,
    borderRadius: 45,
    alignItems: 'center',
    justifyContent: 'center',
    ...Colors.shadow.xl,
  },
  logoEmoji: {
    fontSize: 45,
  },
  title: {
    ...Typography.h1,
    fontSize: 32,
    fontWeight: '700',
    color: Colors.white,
    marginBottom: Spacing.xs,
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  subtitle: {
    ...Typography.body,
    fontSize: 16,
    color: Colors.white,
    opacity: 0.9,
  },
  formCard: {
    padding: Spacing.xl,
    marginBottom: Spacing.xl,
    ...Colors.shadow.xl,
  },
  inputContainer: {
    marginBottom: Spacing.md,
  },
  label: {
    ...Typography.caption,
    fontWeight: '600',
    color: Colors.white,
    marginBottom: Spacing.xs,
    textAlign: 'right',
    fontSize: 14,
  },
  input: {
    backgroundColor: Colors.glass.whiteLight,
    borderWidth: 1,
    borderColor: Colors.glass.border,
    borderRadius: 14,
    paddingVertical: Spacing.md + 2,
    paddingHorizontal: Spacing.md + 2,
    ...Typography.body,
    fontSize: 16,
    color: Colors.white,
  },
  passwordContainer: {
    position: 'relative',
  },
  passwordInput: {
    paddingRight: Spacing.xxl,
  },
  eyeButton: {
    position: 'absolute',
    right: Spacing.md,
    top: 0,
    bottom: 0,
    justifyContent: 'center',
    zIndex: 1,
  },
  eyeIcon: {
    fontSize: 22,
  },
  errorContainer: {
    backgroundColor: Colors.error.light,
    borderRadius: 12,
    padding: Spacing.md,
    marginBottom: Spacing.md,
  },
  errorText: {
    ...Typography.caption,
    color: Colors.error.dark,
    textAlign: 'center',
    fontWeight: '600',
  },
  signUpButton: {
    marginTop: Spacing.md,
    marginBottom: Spacing.md,
  },
  termsText: {
    ...Typography.caption,
    fontSize: 13,
    color: Colors.white,
    opacity: 0.8,
    textAlign: 'center',
    marginBottom: Spacing.md,
    lineHeight: 18,
  },
  termsLink: {
    color: Colors.white,
    fontWeight: '700',
  },
  loginContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loginText: {
    ...Typography.body,
    color: Colors.white,
    opacity: 0.8,
  },
  loginLink: {
    ...Typography.body,
    color: Colors.white,
    fontWeight: '700',
  },
});
