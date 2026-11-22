import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/patient_profile_service.dart';
import 'main_shell_page.dart';

class AuthPage extends StatefulWidget {
  final bool initialIsLogin;
  const AuthPage({super.key, this.initialIsLogin = true});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late bool _isLogin;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _handleSubmit(bool isUrdu) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isLogin) {
      final res = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShellPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              res.message ??
                  (isUrdu
                      ? 'لاگ ان کی معلومات درست نہیں ہیں'
                      : 'Login failed. Please check credentials.'),
            ),
          ),
        );
      }
    } else {
      final res = await AuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.success) {

        final current = PatientProfileService.profile;
        if (current.name.isEmpty || current.name == 'Clinical Patient') {
          PatientProfileService.saveProfile(
            current.copyWith(name: _nameController.text.trim()),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00796B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              isUrdu
                  ? 'اکاؤنٹ کامیابی کے ساتھ بن گیا ہے!'
                  : 'Account created successfully!',
            ),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShellPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              res.message ??
                  (isUrdu
                      ? 'رجسٹریشن ناکام ہو گئی'
                      : 'Registration could not be completed.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Directionality(
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: const Color(0xFF004D40),
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: const Color(0xFF80CBC4).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            width: 68,
                            height: 68,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.local_hospital_rounded,
                              size: 50,
                              color: Color(0xFF80CBC4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isUrdu ? 'میڈی اے آئی' : 'MediAI Clinical Suite',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrdu
                          ? 'مقامی کلینیکل انٹیلی جنس اور ٹرائیج سسٹم'
                          : 'On-Device AI Dermatology & Clinical Triage',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            if (!_isLogin) _toggleMode();
                                          },
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isLogin
                                                  ? const Color(0xFF004D40)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              isUrdu ? 'لاگ ان' : 'Sign In',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: _isLogin
                                                    ? Colors.white
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            if (_isLogin) _toggleMode();
                                          },
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: !_isLogin
                                                  ? const Color(0xFF004D40)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              isUrdu ? 'نیا اکاؤنٹ' : 'Register',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: !_isLogin
                                                    ? Colors.white
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),

                                if (!_isLogin) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText:
                                          isUrdu ? 'پورا نام' : 'Full Name',
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF00796B),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F9FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (val) {
                                      if (!_isLogin &&
                                          (val == null || val.trim().isEmpty)) {
                                        return isUrdu
                                            ? 'نام درج کریں'
                                            : 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: isUrdu
                                        ? 'ای میل ایڈریس'
                                        : 'Email Address',
                                    hintText: 'patient@mediai.org',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF00796B),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F9FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null ||
                                        val.trim().isEmpty ||
                                        !val.contains('@')) {
                                      return isUrdu
                                          ? 'درست ای میل درج کریں'
                                          : 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                if (!_isLogin) ...[
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: isUrdu
                                          ? 'فون نمبر (اختیاری)'
                                          : 'Phone Number (Optional)',
                                      hintText: '+92 300 1234567',
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        color: Color(0xFF00796B),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F9FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: isUrdu ? 'پاس ورڈ' : 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF00796B),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F9FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.length < 6) {
                                      return isUrdu
                                          ? 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے'
                                          : 'Password must be at least 6 chars';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _handleSubmit(isUrdu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004D40),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isLogin
                                              ? (isUrdu
                                                  ? 'لاگ ان کریں'
                                                  : 'Sign In')
                                              : (isUrdu
                                                  ? 'اکاؤنٹ بنائیں'
                                                  : 'Create Account'),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 14),

                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const MainShellPage(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.offline_bolt_outlined,
                                    size: 18,
                                    color: Color(0xFF00796B),
                                  ),
                                  label: Text(
                                    isUrdu
                                        ? 'بطور مہمان جاری رکھیں (آف لائن)'
                                        : 'Continue as Guest (Offline Mode)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUrdu ? 'زبان تبدیل کریں:' : 'Language:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                            ),
                            child: ChoiceChip(
                              label: const Text('English'),
                              selected: !isUrdu,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  LocaleService.setLocale('en'),
                              selectedColor: const Color(0xFF00796B),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              side: BorderSide(
                                color: !isUrdu
                                    ? const Color(0xFF80CBC4)
                                    : Colors.white.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                            ),
                            child: ChoiceChip(
                              label: const Text('اردو'),
                              selected: isUrdu,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  LocaleService.setLocale('ur'),
                              selectedColor: const Color(0xFF00796B),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              side: BorderSide(
                                color: isUrdu
                                    ? const Color(0xFF80CBC4)
                                    : Colors.white.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
