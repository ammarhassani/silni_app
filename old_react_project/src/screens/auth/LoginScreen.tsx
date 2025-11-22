/**
 * LOGIN SCREEN - MODERN REDESIGN
 *
 * User login with:
 * - Beautiful gradient background
 * - Glassmorphism input fields
 * - Smooth animations
 * - Form validation
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

export default function LoginScreen() {
  const navigation = useNavigation<any>();
  const { signIn, isLoading, error, clearError } = useAuthStore();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async () => {
    // Clear previous errors
    clearError();

    // Validation
    if (!email.trim() || !password.trim()) {
      Alert.alert('خطأ', 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    const success = await signIn(email.trim(), password);

    if (success) {
      // Navigation handled by auth state listener
      navigation.replace('MainTabs');
    }
  };

  const handleForgotPassword = () => {
    Alert.alert(
      'استعادة كلمة المرور',
      'سيتم إضافة هذه الميزة قريباً',
      [{ text: 'حسناً' }]
    );
  };

  return (
    <GradientBackground colors={Colors.gradients.forest}>
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
                <Text style={styles.logoEmoji}>🤝</Text>
              </GlassCard>
            </View>
            <Text style={styles.title}>مرحباً بعودتك</Text>
            <Text style={styles.subtitle}>سجّل الدخول لمتابعة رحلتك</Text>
          </FadeInView>

          {/* Form Card */}
          <FadeInView delay={300}>
            <GlassCard style={styles.formCard} intensity={95}>
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
                    placeholder="••••••••"
                    placeholderTextColor={Colors.glass.white}
                    value={password}
                    onChangeText={setPassword}
                    secureTextEntry={!showPassword}
                    autoCapitalize="none"
                    textAlign="right"
                  />
                </View>
              </View>

              {/* Forgot Password */}
              <TouchableOpacity
                onPress={handleForgotPassword}
                style={styles.forgotButton}
              >
                <Text style={styles.forgotText}>نسيت كلمة المرور؟</Text>
              </TouchableOpacity>

              {/* Error Message */}
              {error && (
                <View style={styles.errorContainer}>
                  <Text style={styles.errorText}>{error}</Text>
                </View>
              )}

              {/* Login Button */}
              <GradientButton
                title="تسجيل الدخول"
                onPress={handleLogin}
                variant="primary"
                size="large"
                loading={isLoading}
                disabled={isLoading}
                style={styles.loginButton}
              />

              {/* Sign Up Link */}
              <View style={styles.signupContainer}>
                <TouchableOpacity onPress={() => navigation.navigate('SignUp')}>
                  <Text style={styles.signupLink}>إنشاء حساب جديد</Text>
                </TouchableOpacity>
                <Text style={styles.signupText}>ليس لديك حساب؟ </Text>
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
    paddingTop: Spacing.xxl * 1.5,
  },
  header: {
    alignItems: 'center',
    marginBottom: Spacing.xl,
  },
  logoContainer: {
    marginBottom: Spacing.lg,
  },
  logoGlass: {
    width: 100,
    height: 100,
    borderRadius: 50,
    alignItems: 'center',
    justifyContent: 'center',
    ...Colors.shadow.xl,
  },
  logoEmoji: {
    fontSize: 50,
  },
  title: {
    ...Typography.h1,
    fontSize: 36,
    fontWeight: '700',
    color: Colors.white,
    marginBottom: Spacing.xs,
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  subtitle: {
    ...Typography.body,
    fontSize: 17,
    color: Colors.white,
    opacity: 0.9,
  },
  formCard: {
    padding: Spacing.xl,
    marginBottom: Spacing.xl,
    ...Colors.shadow.xl,
  },
  inputContainer: {
    marginBottom: Spacing.lg,
  },
  label: {
    ...Typography.caption,
    fontWeight: '600',
    color: Colors.white,
    marginBottom: Spacing.xs,
    textAlign: 'right',
    fontSize: 15,
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
  forgotButton: {
    alignSelf: 'flex-end',
    marginBottom: Spacing.lg,
  },
  forgotText: {
    ...Typography.caption,
    color: Colors.white,
    fontWeight: '600',
    fontSize: 14,
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
  loginButton: {
    marginBottom: Spacing.md,
  },
  signupContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.sm,
  },
  signupText: {
    ...Typography.body,
    color: Colors.white,
    opacity: 0.8,
  },
  signupLink: {
    ...Typography.body,
    color: Colors.white,
    fontWeight: '700',
  },
});
