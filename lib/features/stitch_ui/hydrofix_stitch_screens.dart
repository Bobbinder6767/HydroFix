import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/hydrofix_theme.dart';

// These UI screens use sample content where backend integration is pending.
// The citizen sign-in form calls the existing Supabase Auth client.

class HydroShell extends StatefulWidget {
  const HydroShell({super.key});

  @override
  State<HydroShell> createState() => _HydroShellState();
}

class _HydroShellState extends State<HydroShell> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CitizenHome(onReport: () => setState(() => selected = 1),
        onTrack: () => setState(() => selected = 2)),
      ReportScreen(onSubmitted: () => setState(() => selected = 2)),
      const TrackScreen(),
      const ProfileScreen(),
    ];
    return PopScope(
      canPop: selected == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selected != 0) setState(() => selected = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: selected, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => setState(() => selected = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Report'),
            NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Track'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HydroWelcome extends StatelessWidget {
  const HydroWelcome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(),
        Image.asset(
          'assets/images/hydrofix_logo.png',  width: 230,  height: 230,
          fit: BoxFit.contain,
          
        ),
        const SizedBox(height: 28),
      
        const SizedBox(height: 12),
        const Text('Report. Resolve. Conserve.', style: TextStyle(fontSize: 17, color: HydroColors.muted)),
        const SizedBox(height: 24),
        const Text('A smarter way to protect our city’s water, together.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: HydroColors.muted)),
        const Spacer(),
        FilledButton(onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LoginTypeScreen())), child: const Text('Get Started')),
        const SizedBox(height: 24),
      ]),
    )),
  );
}

enum HydroRole { citizen, professional, bmc }

class LoginTypeScreen extends StatelessWidget {
  const LoginTypeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Select Your Login Type', style: TextStyle(fontSize: 29,
        fontWeight: FontWeight.bold, color: HydroColors.navy)),
      const SizedBox(height: 8),
      const Text('Choose how you use HydroFix.', style: TextStyle(color: HydroColors.muted)),
      const SizedBox(height: 30),
      _RoleTile(icon: Icons.person_outline, title: 'Citizen', subtitle: 'Report and track water issues', role: HydroRole.citizen),
      _RoleTile(icon: Icons.handyman_outlined, title: 'Professional', subtitle: 'Plumber and electrician work orders', role: HydroRole.professional),
      _RoleTile(icon: Icons.account_balance_outlined, title: 'BMC Officer', subtitle: 'Monitor ward-level critical alerts', role: HydroRole.bmc),
    ])),
  );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.icon, required this.title, required this.subtitle, required this.role});
  final IconData icon;
  final String title, subtitle;
  final HydroRole role;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HydroSignIn(role: role))),
      child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        CircleAvatar(radius: 27, backgroundColor: HydroColors.aqua,
          child: Icon(icon, color: HydroColors.teal, size: 27)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: HydroColors.muted)),
        ])),
        const Icon(Icons.chevron_right),
      ]))),
  );
}

class HydroSignIn extends StatefulWidget {
  const HydroSignIn({super.key, required this.role});
  final HydroRole role;
  @override
  State<HydroSignIn> createState() => _HydroSignInState();
}

class _HydroSignInState extends State<HydroSignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  final key = GlobalKey<FormState>();
  bool busy = false, hidden = true;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> submit() async {
  if (!key.currentState!.validate()) return;

  setState(() {
    busy = true;
  });

  final supabase = Supabase.instance.client;

  try {
    // STEP 1: Authenticate using Supabase.
    final response = await supabase.auth.signInWithPassword(
      email: email.text.trim(),
      password: password.text,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException('Authentication failed.');
    }

    // STEP 2: Retrieve the user's role.
    final profile = await supabase
        .from('profiles')
        .select('id, role, is_active')
        .eq('id', user.id)
        .single();

    final String userRole = profile['role'] as String;
    final bool isActive = profile['is_active'] == true;

    if (!isActive) {
      throw const AuthException(
        'Your account has been deactivated.',
      );
    }

    // STEP 3: Select the correct dashboard.
    Widget destination;

    switch (widget.role) {
      case HydroRole.citizen:
        if (userRole != 'citizen') {
          throw const AuthException(
            'This account is not registered as a citizen.',
          );
        }

        destination = const HydroShell();
        break;

      case HydroRole.professional:
        if (userRole != 'professional') {
          throw const AuthException(
            'This account is not registered as a professional.',
          );
        }

        // Check BMC verification status.
        final professional = await supabase
            .from('professional_profiles')
            .select('verification_status')
            .eq('user_id', user.id)
            .single();

        final String verificationStatus =
            professional['verification_status'] as String;

        if (verificationStatus != 'approved') {
          throw AuthException(
            verificationStatus == 'pending'
                ? 'Your professional account is awaiting BMC approval.'
                : 'Your professional account is not approved.',
          );
        }

        destination = const ProfessionalDashboardPreview();
        break;

      case HydroRole.bmc:
        if (userRole != 'bmc_admin') {
          throw const AuthException(
            'You do not have BMC administrator access.',
          );
        }

        // Verify administrator profile.
        final admin = await supabase
            .from('admin_profiles')
            .select('user_id, officer_id, ward_id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (admin == null) {
          throw const AuthException(
            'BMC administrator profile not found.',
          );
        }

        destination = const BmcDashboardPreview();
        break;
    }

    // STEP 4: Navigate to the authorized dashboard.
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => destination,
      ),
      (route) => false,
    );
  } on AuthException catch (error) {
    await supabase.auth.signOut();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red,
      ),
    );
  } catch (error) {
    await supabase.auth.signOut();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login failed: $error'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final label = switch (widget.role) {
      HydroRole.citizen => 'Citizen Login',
      HydroRole.professional => 'Professional Login',
      HydroRole.bmc => 'BMC Officer Login',
    };
    return Scaffold(appBar: AppBar(), body: SafeArea(child: Center(
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(
        key: key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.water_drop_rounded, color: HydroColors.teal, size: 74),
          const SizedBox(height: 16),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 27, color: HydroColors.navy)),
          const SizedBox(height: 10),
          const Text('Welcome back to HydroFix', textAlign: TextAlign.center,
            style: TextStyle(color: HydroColors.muted)),
          const SizedBox(height: 36),
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            validator: (s) => (s == null || !s.contains('@')) ? 'Enter a valid email' : null),
          const SizedBox(height: 16),
          TextFormField(controller: password, obscureText: hidden,
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (s) => (s == null || s.isEmpty) ? 'Enter your password' : null),
          const SizedBox(height: 24),
          FilledButton(onPressed: busy ? null : submit,
            child: busy ? const SizedBox(height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login')),
        ]),
      )),
    )));
  }
}

class HydroCard extends StatelessWidget {
  const HydroCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: padding, child: child),
  );
}

class CitizenHome extends StatelessWidget {
  const CitizenHome({super.key, required this.onReport, required this.onTrack});
  final VoidCallback onReport, onTrack;
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    padding: const EdgeInsets.all(24), children: [
      Row(children: [
        const CircleAvatar(backgroundColor: HydroColors.aqua,
          child: Icon(Icons.person, color: HydroColors.teal)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Hello, Welcome Back!', style: TextStyle(color: HydroColors.muted)),
          Text(Supabase.instance.client.auth.currentUser?.email ?? 'HydroFix Citizen',
            overflow: TextOverflow.ellipsis, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: HydroColors.navy)),
        ])),
        IconButton(onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HydroNotifications())),
          icon: const Icon(Icons.notifications_none)),
      ]),
      const SizedBox(height: 26),
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [HydroColors.aqua, Color(0xFFB8DADE)]),
        borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💧  24/7 RAPID RESPONSE', style: TextStyle(color: HydroColors.navy,
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          const Text('Facing a Water Leakage Problem?', style: TextStyle(
            fontSize: 25, fontWeight: FontWeight.bold, color: HydroColors.navy)),
          const SizedBox(height: 8),
          const Text('Report it now and get connected with a professional.'),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onReport,
            icon: const Icon(Icons.add_circle_outline), label: const Text('Report Leakage')),
        ])),
      const SizedBox(height: 26),
      const _SectionTitle('Quick Actions'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _ActionTile(Icons.water_drop_outlined, 'Report Leakage', onReport)),
        const SizedBox(width: 12),
        Expanded(child: _ActionTile(Icons.track_changes, 'Track Complaint', onTrack)),
      ]),
      const SizedBox(height: 24),
      const _SectionTitle('Complaint Overview'),
      const SizedBox(height: 14),
      const Row(children: [
        Expanded(child: _Metric('—', 'Reported', Icons.assignment_outlined)),
        SizedBox(width: 10),
        Expanded(child: _Metric('—', 'In Progress', Icons.timelapse)),
      ]),
      const SizedBox(height: 10),
      const HydroCard(child: Text('Your live complaints will appear here once the Supabase query is connected.',
        style: TextStyle(color: HydroColors.muted))),
    ],
  ));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: HydroColors.navy));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.icon, this.label, this.onTap);
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HydroCard(child: InkWell(onTap: onTap,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(backgroundColor: HydroColors.aqua, child: Icon(icon, color: HydroColors.teal)),
      const SizedBox(height: 20),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ])));
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon);
  final String value, label; final IconData icon;
  @override
  Widget build(BuildContext context) => HydroCard(child: Column(children: [
    Icon(icon, color: HydroColors.teal), const SizedBox(height: 8),
    Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: HydroColors.muted, fontSize: 12)),
  ]));
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.onSubmitted});
  final VoidCallback? onSubmitted;
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final form = GlobalKey<FormState>();
  String severity = 'green';
  String category = 'water_leakage';
  bool submitting = false;
  final address = TextEditingController();
  bool verifying = false;
  XFile? selectedPhoto;
  String? aiSuggested;
  String? aiReason;
  double? aiConfidence;

  Future<void> selectPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 65,
        requestFullMetadata: false,
      );
      if (!mounted || photo == null) return;
      setState(() {
        selectedPhoto = photo;
        aiSuggested = null;
        aiReason = null;
        aiConfidence = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not access the camera or gallery.'),
      ));
    }
  }

  Future<void> verifySeverity() async {
    if (verifying) return;
    final text = description.text.trim();
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Describe the issue in at least 10 characters.'),
      ));
      return;
    }
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please sign in before verifying severity.'),
      ));
      return;
    }

    setState(() => verifying = true);
    try {
      final body = <String, dynamic>{'description': text};
      if (selectedPhoto != null) {
        final bytes = await selectedPhoto!.readAsBytes();
        if (bytes.length > 4 * 1024 * 1024) {
          throw Exception('Photo is too large. Choose a smaller image.');
        }
        final extension = selectedPhoto!.path.toLowerCase();
        final mime = extension.endsWith('.png')
            ? 'image/png'
            : extension.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        body['imageBase64'] = base64Encode(bytes);
        body['imageMimeType'] = mime;
      }

      final response = await client.functions.invoke(
        'verify-severity',
        body: body,
      );
      debugPrint('========== AI RESPONSE ==========');
      debugPrint('Status: ${response.status}');
      debugPrint('Data: ${response.data}');
debugPrint('=================================');
      if (response.status != 200 || response.data is! Map) {
        throw Exception('AI verification unavailable (${response.status}).');
      }
      final result = response.data as Map;
      final recommendation = result['severity']?.toString().toLowerCase();
      if (!['green', 'yellow', 'red'].contains(recommendation)) {
        throw Exception(result['error'] ?? 'Invalid AI response.');
      }
      if (!mounted) return;
      setState(() {
        severity = recommendation!;
        aiSuggested = recommendation;
        aiReason = result['reason']?.toString() ?? 'No explanation provided.';
        aiConfidence = (result['confidence'] as num?)?.toDouble();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('AI verification failed: $error'),
      ));
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  Future<void> submitReport() async {
    if (submitting || !form.currentState!.validate()) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please sign in to submit a complaint.'),
      ));
      return;
    }

    setState(() => submitting = true);
    String? trackingId;
    try {
      // Database defaults generate the complaint id, tracking id, status,
      // reporter id, and timestamps.
      final complaint = await client.from('complaints').insert({
        'category': category,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'reported_severity': severity,
        'address_text': address.text.trim(),
      }).select('id, tracking_id').single();

      final complaintId = complaint['id'] as String;
      trackingId = complaint['tracking_id'] as String;

      // The Storage INSERT policy requires:
      // {auth.uid()}/{existing complaint id}/{filename}
      if (selectedPhoto != null) {
        try {
          final bytes = await selectedPhoto!.readAsBytes();
          if (bytes.length > 4 * 1024 * 1024) {
            throw Exception('Photo exceeds 4 MB.');
          }
          final name = selectedPhoto!.path.toLowerCase();
          final mime = name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg';
          final extension = mime == 'image/png'
              ? 'png'
              : mime == 'image/webp'
                  ? 'webp'
                  : 'jpg';
          final path = '${user.id}/$complaintId/before.$extension';

          await client.storage.from('complaint-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
          await client.from('complaint_images').insert({
            'complaint_id': complaintId,
            'storage_path': path,
            'image_type': 'before',
          });
        } catch (error) {
          if (!mounted) return;
          // Never retry the complaint insert here: it already succeeded.
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('Complaint $trackingId saved, but the photo failed: $error'),
          ));
          widget.onSubmitted?.call();
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Complaint submitted! Tracking ID: $trackingId'),
        duration: const Duration(seconds: 7),
      ));
      title.clear();
      description.clear();
      address.clear();
      setState(() {
        selectedPhoto = null;
        aiSuggested = null;
        aiReason = null;
        aiConfidence = null;
        severity = 'green';
        category = 'water_leakage';
      });
      widget.onSubmitted?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Complaint could not be submitted: $error'),
        duration: const Duration(seconds: 7),
      ));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() { title.dispose(); description.dispose(); address.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    padding: const EdgeInsets.all(24), children: [
      const _SectionTitle('Report a Problem'),
      const SizedBox(height: 8),
      const Text('Help us identify and resolve water leakage or wastage.',
        style: TextStyle(color: HydroColors.muted)),
      const SizedBox(height: 24),
      Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HydroCard(child: Column(children: [
          InkWell(onTap: verifying ? null : selectPhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(height: 160, width: double.infinity,
              decoration: BoxDecoration(color: HydroColors.aqua,
                borderRadius: BorderRadius.circular(16)),
              child: selectedPhoto == null
                ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, size: 35, color: HydroColors.teal),
                    SizedBox(height: 8), Text('Add a photo of the issue'),
                  ])
                : ClipRRect(borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(selectedPhoto!.path), fit: BoxFit.cover)),
            )),
          const SizedBox(height: 8),
          const Text('Tap to take or choose a photo. It will be included in AI verification.',
            style: TextStyle(fontSize: 12, color: HydroColors.muted)),
        ])),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Issue category'),
          items: const [
            DropdownMenuItem(value: 'water_leakage', child: Text('Water Leakage')),
            DropdownMenuItem(value: 'pipe_damage', child: Text('Pipe Damage')),
            DropdownMenuItem(value: 'tap_faucet', child: Text('Tap / Faucet')),
            DropdownMenuItem(value: 'tank_overflow', child: Text('Tank Overflow')),
            DropdownMenuItem(value: 'water_pump', child: Text('Water Pump')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: submitting ? null : (value) {
            if (value != null) setState(() => category = value);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Issue title'),
          validator: (s) => (s == null || s.trim().isEmpty) ? 'Enter a title' : null),
        const SizedBox(height: 16),
        TextFormField(controller: description, maxLines: 4,
          onChanged: (_) => setState(() { aiSuggested = null; aiReason = null; aiConfidence = null; }),
          decoration: const InputDecoration(labelText: 'Describe the problem'),
          validator: (s) => (s == null || s.trim().isEmpty) ? 'Describe the issue' : null),
        const SizedBox(height: 16),
        TextFormField(
          controller: address,
          decoration: const InputDecoration(
            labelText: 'Location / address',
            prefixIcon: Icon(Icons.location_on_outlined),
            hintText: 'Street, landmark, or building',
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Enter where the problem is located'
              : null,
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Select Severity'),
        const SizedBox(height: 12),
        _SeverityTile('green', 'GREEN — Minor pipeline leak',
          'Small, local water leakage', HydroColors.green, severity,
          (s) => setState(() => severity = s)),
        _SeverityTile('yellow', 'YELLOW — Pump room problem',
          'Needs a plumber or electrician', HydroColors.yellow, severity,
          (s) => setState(() => severity = s)),
        _SeverityTile('red', 'RED — Critical public leak',
          'Urgent attention from BMC', HydroColors.red, severity,
          (s) => setState(() => severity = s)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: verifying ? null : verifySeverity,
          icon: verifying
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: Text(verifying ? 'Checking severity...' : 'AI Verify Severity'),
        ),
        if (aiReason != null) ...[
          const SizedBox(height: 12),
          HydroCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI suggests ${aiSuggested!.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(aiReason!),
              if (aiConfidence != null) ...[
                const SizedBox(height: 6),
                Text('Model-reported confidence: ${(aiConfidence! * 100).round()}%',
                  style: const TextStyle(color: HydroColors.muted)),
              ],
              const SizedBox(height: 8),
              const Text('This is advisory. You can change the selected severity.'),
            ])),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: submitting ? null : submitReport,
          child: submitting
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Report'),
        ),
      ])),
    ],
  ));
}

class _SeverityTile extends StatelessWidget {
  const _SeverityTile(this.value, this.title, this.subtitle, this.color, this.selected, this.onSelect);
  final String value, title, subtitle, selected;
  final Color color; final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: selected == value ? color : HydroColors.outline, width: selected == value ? 2 : 1)),
    child: InkWell(onTap: () => onSelect(value), borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Icon(Icons.water_drop, color: color, size: 30),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 3), Text(subtitle,
            style: const TextStyle(color: HydroColors.muted, fontSize: 12)),
        ])),
        Radio<String>(value: value, groupValue: selected, onChanged: (s) { if (s != null) onSelect(s); }),
      ]))),
  );
}

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});
  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  Future<List<Map<String, dynamic>>> loadComplaints() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return [];
    final results = await client.from('complaints')
        .select('id, tracking_id, title, description, reported_severity, status, address_text, created_at')
        .eq('reported_by', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(results);
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    padding: const EdgeInsets.all(24), children: [
      Row(children: [
        const Expanded(child: _SectionTitle('Track Complaint')),
        IconButton(
          tooltip: 'Refresh complaints',
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.refresh),
        ),
      ]),
      const SizedBox(height: 8),
      const Text('View updates on your reported issues.',
        style: TextStyle(color: HydroColors.muted)),
      const SizedBox(height: 24),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: loadComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HydroCard(child: Text('Could not load complaints: ${snapshot.error}'));
          }
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return const HydroCard(child: Text('No complaints yet. Submit your first report.'));
          }
          return Column(children: [
            for (final complaint in complaints)
              HydroCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(complaint['tracking_id']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: HydroColors.teal)),
                  const SizedBox(height: 8),
                  Text(complaint['title']?.toString().isNotEmpty == true
                      ? complaint['title'].toString()
                      : complaint['description']?.toString() ?? 'Complaint'),
                  const SizedBox(height: 8),
                  Text('Status: ${complaint['status']?.toString().replaceAll('_', ' ') ?? 'Unknown'}'),
                  Text('Severity: ${complaint['reported_severity'] ?? 'Unknown'}'),
                  Text('Location: ${complaint['address_text'] ?? ''}'),
                ],
              )),
          ]);
        },
      ),
    ],
  ));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
    const _SectionTitle('My Profile'), const SizedBox(height: 24),
    const Center(child: CircleAvatar(radius: 42, backgroundColor: HydroColors.aqua,
      child: Icon(Icons.person, size: 46, color: HydroColors.teal))),
    const SizedBox(height: 15),
    Center(child: Text(Supabase.instance.client.auth.currentUser?.email ?? 'Citizen',
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
    const SizedBox(height: 28),
    const HydroCard(child: ListTile(leading: Icon(Icons.account_circle_outlined),
      title: Text('Account details'), subtitle: Text('Profile editing coming next'))),
    const SizedBox(height: 16),
    FilledButton.tonalIcon(onPressed: () async {
      await Supabase.instance.client.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
        builder: (_) => const HydroWelcome()), (_) => false);
    }, icon: const Icon(Icons.logout), label: const Text('Sign Out')),
  ]));
}

class HydroNotifications extends StatelessWidget {
  const HydroNotifications({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')),
    body: const Padding(padding: EdgeInsets.all(24), child: HydroCard(
      child: Text('Your Supabase notifications will appear here.'))));
}

class ProfessionalDashboardPreview extends StatelessWidget {
  const ProfessionalDashboardPreview({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Professional Dashboard')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Good morning, Technician', style: TextStyle(fontSize: 24,
        fontWeight: FontWeight.bold, color: HydroColors.navy)),
      const SizedBox(height: 8),
      const Text('Manage your plumbing and electrical jobs.',
        style: TextStyle(color: HydroColors.muted)),
      const SizedBox(height: 24),
      const Row(children: [
        Expanded(child: _Metric('—', 'Assigned', Icons.assignment)),
        SizedBox(width: 12),
        Expanded(child: _Metric('—', 'Completed', Icons.task_alt)),
      ]),
      const SizedBox(height: 24),
      const _SectionTitle('Assigned Jobs'),
      const SizedBox(height: 12),
      const HydroCard(child: Text('Jobs will load from complaint_assignments after technician authorization is connected.')),
    ])),
  );
}

class BmcDashboardPreview extends StatelessWidget {
  const BmcDashboardPreview({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BMC Officer Dashboard')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Water Issue Overview', style: TextStyle(fontSize: 25,
        fontWeight: FontWeight.bold, color: HydroColors.navy)),
      const SizedBox(height: 10),
      const Text('Ward-level monitoring and urgent alerts',
        style: TextStyle(color: HydroColors.muted)),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
        color: const Color(0xFFFFE7E7), borderRadius: BorderRadius.circular(16)),
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: HydroColors.red), SizedBox(width: 12),
          Expanded(child: Text('Critical alerts will appear here when connected to BMC area memberships.')),
        ])),
      const SizedBox(height: 24),
      const Row(children: [
        Expanded(child: _Metric('—', 'Green', Icons.water_drop_outlined)),
        SizedBox(width: 10),
        Expanded(child: _Metric('—', 'Yellow', Icons.build_outlined)),
        SizedBox(width: 10),
        Expanded(child: _Metric('—', 'Red', Icons.warning_amber)),
      ]),
      const SizedBox(height: 24), const _SectionTitle('Area Issues'),
      const SizedBox(height: 12),
      const HydroCard(child: Text('This view needs authorized area membership and live complaint queries.')),
    ])),
  );
}