import 'dart:convert';
import 'dart:io';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/hydrofix_theme.dart';
<<<<<<< HEAD

// HydroFix displays three colors, but public.complaints.reported_severity
// uses the PostgreSQL enum labels low, medium, high, emergency.
// Reserve 'high' for future use; critical public leaks require emergency.
String severityToDatabase(String color) {
  switch (color.trim().toLowerCase()) {
    case 'green':
      return 'low';
    case 'yellow':
      return 'medium';
    case 'red':
      return 'emergency';
    default:
      throw ArgumentError.value(color, 'color', 'Unknown severity');
  }
}

=======
>>>>>>> 090230e (Fix Supabase configuration and update login)
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
    debugPrint('HYDROFIX LOGIN: Supabase authentication successful');
debugPrint('HYDROFIX LOGIN: User ID = ${response.user?.id}');

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
    debugPrint('HYDROFIX LOGIN: Profile fetched = $profile');


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
        debugPrint('HYDROFIX LOGIN: Checking professional verification');
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
    debugPrint('COMPLAINT USER ID: ${user?.id}');
    debugPrint('COMPLAINT USER EMAIL: ${user?.email}');
    debugPrint('SESSION ACTIVE: ${client.auth.currentSession != null}');
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
        'reported_severity': severityToDatabase(severity),
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

class ProfessionalDashboardPreview extends StatefulWidget {
  const ProfessionalDashboardPreview({super.key});

  @override
  State<ProfessionalDashboardPreview> createState() =>
      _ProfessionalDashboardPreviewState();
}

class _ProfessionalDashboardPreviewState
    extends State<ProfessionalDashboardPreview> {
  bool loading = true;

  String? errorMessage;
  String? updatingJobId;

  List<Map<String, dynamic>> jobs = [];

  int get assignedCount => jobs.where((job) {
        final status = job['status']?.toString();

        return status != 'completed' &&
            status != 'confirmed' &&
            status != 'rejected';
      }).length;

  int get completedCount => jobs.where((job) {
        final status = job['status']?.toString();

        return status == 'completed' ||
            status == 'confirmed';
      }).length;

  @override
  void initState() {
    super.initState();
    loadJobs();
  }

  // ============================================================
  // LOAD PROFESSIONAL JOBS
  // ============================================================

  Future<void> loadJobs() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;

      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please log in as a professional.',
        );
      }

      // Verify professional account.
      final professional = await client
          .from('professional_profiles')
          .select(
            'user_id, specialization, verification_status',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (professional == null ||
          professional['verification_status'] !=
              'approved') {
        throw Exception(
          'Your professional account is not approved.',
        );
      }

      // Load jobs assigned to the logged-in professional.
      final jobData = await client
          .from('jobs')
          .select(
            'id, complaint_id, professional_id, '
            'status, estimated_payout_paise, '
            'estimated_duration_minutes, '
            'rejection_reason, completion_notes, '
            'offered_at, accepted_at, started_at, '
            'completed_at',
          )
          .eq('professional_id', user.id)
          .order('offered_at', ascending: false);

      // Attach complaint details to each job.
      final List<Map<String, dynamic>> loadedJobs = [];

      for (final job in jobData) {
        final jobMap = Map<String, dynamic>.from(job);

        final complaintId =
            jobMap['complaint_id']?.toString();

        Map<String, dynamic>? complaint;

        if (complaintId != null) {
          final complaintData = await client
              .from('complaints')
              .select(
                'id, tracking_id, title, description, '
                'reported_severity, status, address_text',
              )
              .eq('id', complaintId)
              .maybeSingle();

          if (complaintData != null) {
            complaint =
                Map<String, dynamic>.from(complaintData);
          }
        }

        jobMap['complaint'] = complaint;

        loadedJobs.add(jobMap);
      }

      if (!mounted) return;

      setState(() {
        jobs = loadedJobs;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        loading = false;
      });
    }
  }

  // ============================================================
  // UPDATE JOB STATUS
  // ============================================================

  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
  }) async {
    if (updatingJobId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirm ${statusLabel(newStatus)}',
          ),
          content: Text(
            'Are you sure you want to change '
            'this job to "${statusLabel(newStatus)}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      updatingJobId = jobId;
    });

    try {
      final client = Supabase.instance.client;

      if (client.auth.currentUser == null) {
        throw Exception('Please log in again.');
      }

      await client.rpc(
        'update_my_job',
        params: {
          'p_job': jobId,
          'p_new_status': newStatus,
          'p_note': newStatus == 'completed'
              ? 'Repair completed by professional'
              : newStatus == 'rejected'
                  ? 'Job rejected by professional'
                  : 'Status updated by professional',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Job status updated to '
            '${statusLabel(newStatus)}',
          ),
          backgroundColor: HydroColors.teal,
        ),
      );

      await loadJobs();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update job: $error',
          ),
          backgroundColor: HydroColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          updatingJobId = null;
        });
      }
    }
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String statusLabel(String status) {
    switch (status) {
      case 'offered':
        return 'Job Offered';

      case 'accepted':
        return 'Accepted';

      case 'rejected':
        return 'Rejected';

      case 'on_the_way':
        return 'On the Way';

      case 'in_progress':
        return 'In Progress';

      case 'completed':
        return 'Completed';

      case 'confirmed':
        return 'Confirmed';

      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String severityLabel(String severity) {
    switch (severity) {
      case 'low':
        return 'GREEN';

      case 'medium':
        return 'YELLOW';

      case 'high':
      case 'emergency':
        return 'RED';

      default:
        return severity.toUpperCase();
    }
  }

  Color severityColor(String severity) {
    switch (severity) {
      case 'low':
        return HydroColors.green;

      case 'medium':
        return HydroColors.yellow;

      case 'high':
      case 'emergency':
        return HydroColors.red;

      default:
        return HydroColors.muted;
    }
  }

  // ============================================================
  // JOB ACTION BUTTON
  // ============================================================

  Widget buildActionButton({
    required String jobId,
    required String status,
    required String label,
    required IconData icon,
    bool outlined = false,
  }) {
    final isProcessing = updatingJobId == jobId;

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: updatingJobId != null
            ? null
            : () => updateJobStatus(
                  jobId: jobId,
                  newStatus: status,
                ),
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return FilledButton.icon(
      onPressed: updatingJobId != null
          ? null
          : () => updateJobStatus(
                jobId: jobId,
                newStatus: status,
              ),
      icon: isProcessing
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }

  // ============================================================
  // JOB CARD
  // ============================================================

  Widget buildJobCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';

    final status =
        job['status']?.toString() ?? 'unknown';

    final complaint =
        job['complaint'] is Map
            ? Map<String, dynamic>.from(
                job['complaint'] as Map,
              )
            : <String, dynamic>{};

    final title =
        complaint['title']?.toString() ??
            'Water Issue';

    final trackingId =
        complaint['tracking_id']?.toString() ??
            'N/A';

    final description =
        complaint['description']?.toString() ?? '';

    final address =
        complaint['address_text']?.toString() ??
            'Not provided';

    final severity =
        complaint['reported_severity']?.toString() ??
            'unknown';

    final duration =
        job['estimated_duration_minutes'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HydroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint title.
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: severityColor(severity),
                  size: 28,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HydroColors.navy,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              'Tracking ID: $trackingId',
              style: const TextStyle(
                color: HydroColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Severity: ${severityLabel(severity)}',
            ),

            const SizedBox(height: 8),

            Text(
              'Job Status: ${statusLabel(status)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('Location: $address'),

            if (duration != null) ...[
              const SizedBox(height: 8),

              Text(
                'Estimated Duration: $duration minutes',
              ),
            ],

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                description,
                style: const TextStyle(
                  color: HydroColors.muted,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ==========================================
            // OFFERED: ACCEPT OR REJECT
            // ==========================================

            if (status == 'offered')
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: buildActionButton(
                      jobId: jobId,
                      status: 'accepted',
                      label: 'Accept Job',
                      icon: Icons.check_circle,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: buildActionButton(
                      jobId: jobId,
                      status: 'rejected',
                      label: 'Reject Job',
                      icon: Icons.cancel_outlined,
                      outlined: true,
                    ),
                  ),
                ],
              ),

            // ==========================================
            // ACCEPTED: ON THE WAY
            // ==========================================

            if (status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: buildActionButton(
                  jobId: jobId,
                  status: 'on_the_way',
                  label: 'On the Way',
                  icon: Icons.directions_walk,
                ),
              ),

            // ==========================================
            // ON THE WAY: START WORK
            // ==========================================

            if (status == 'on_the_way')
              SizedBox(
                width: double.infinity,
                child: buildActionButton(
                  jobId: jobId,
                  status: 'in_progress',
                  label: 'Start Work',
                  icon: Icons.build,
                ),
              ),

            // ==========================================
            // IN PROGRESS: COMPLETE
            // ==========================================

            if (status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: buildActionButton(
                  jobId: jobId,
                  status: 'completed',
                  label: 'Mark Completed',
                  icon: Icons.task_alt,
                ),
              ),

            // ==========================================
            // COMPLETED
            // ==========================================

            if (status == 'completed' ||
                status == 'confirmed')
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: HydroColors.green,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Repair completed successfully.',
                      style: TextStyle(
                        color: HydroColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

            // ==========================================
            // REJECTED
            // ==========================================

            if (status == 'rejected')
              const Text(
                'You rejected this job.',
                style: TextStyle(
                  color: HydroColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Professional Dashboard',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh jobs',
            onPressed: loading || updatingJobId != null
                ? null
                : loadJobs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadJobs,

          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.all(24),

            children: [
              const Text(
                'Good morning, Technician',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HydroColors.navy,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Manage your plumbing and electrical jobs.',
                style: TextStyle(
                  color: HydroColors.muted,
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // LOADING
              // ==========================================

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )

              // ==========================================
              // ERROR
              // ==========================================

              else if (errorMessage != null)
                HydroCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: HydroColors.red,
                        size: 40,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Unable to load professional jobs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      FilledButton(
                        onPressed: loadJobs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )

              // ==========================================
              // DASHBOARD CONTENT
              // ==========================================

              else ...[
                // ========================================
                // JOB COUNTERS
                // ========================================

                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        '$assignedCount',
                        'Assigned',
                        Icons.assignment,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _Metric(
                        '$completedCount',
                        'Completed',
                        Icons.task_alt,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const _SectionTitle('Assigned Jobs'),

                const SizedBox(height: 12),

                if (jobs.isEmpty)
                  const HydroCard(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No jobs assigned to you yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ...jobs.map(buildJobCard),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BmcDashboardPreview extends StatefulWidget {
  const BmcDashboardPreview({super.key});

  @override
  State<BmcDashboardPreview> createState() =>
      _BmcDashboardPreviewState();
}

class _BmcDashboardPreviewState extends State<BmcDashboardPreview> {
  bool loading = true;

  String? errorMessage;
  String? wardId;
  String wardName = 'Assigned Ward';

  List<Map<String, dynamic>> complaints = [];

  List<Map<String, dynamic>> pendingProfessionals = [];

  List<Map<String, dynamic>> approvedProfessionals = [];

  String? reviewingProfessionalId;
  String? assigningComplaintId;

  bool get isReviewingProfessional =>
      reviewingProfessionalId != null;

  int get greenCount => complaints
      .where((c) => c['reported_severity'] == 'low')
      .length;

  int get yellowCount => complaints
      .where((c) => c['reported_severity'] == 'medium')
      .length;

  int get redCount => complaints
      .where(
        (c) =>
            c['reported_severity'] == 'high' ||
            c['reported_severity'] == 'emergency',
      )
      .length;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> loadDashboard() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Please log in as a BMC officer.');
      }

      // Get the BMC officer's ward.
      final adminData = await client
          .from('admin_profiles')
          .select('ward_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (adminData == null) {
        throw Exception(
          'No authorized BMC officer profile found.',
        );
      }

      final assignedWardId =
          adminData['ward_id']?.toString();

      if (assignedWardId == null ||
          assignedWardId.isEmpty) {
        throw Exception(
          'No ward assigned to this BMC officer.',
        );
      }

      // Get ward name.
      final wardData = await client
          .from('wards')
          .select('name')
          .eq('id', assignedWardId)
          .maybeSingle();

      // Get complaints belonging to this ward.
      final complaintData = await client
          .from('complaints')
          .select(
            'id, tracking_id, title, description, '
            'reported_severity, status, address_text, '
            'ward_id, assigned_professional_id, created_at',
          )
          .eq('ward_id', assignedWardId)
          .order('created_at', ascending: false);

      // Get pending professional applications.
      final pendingData = await client
          .from('professional_profiles')
          .select(
            'user_id, partner_id, specialization, '
            'service_ward_id, service_area, '
            'verification_status, availability, '
            'bio, experience_years, created_at',
          )
          .eq('service_ward_id', assignedWardId)
          .eq('verification_status', 'pending')
          .order('created_at', ascending: false);

      // Get approved professionals eligible for assignment.
      final approvedData = await client
          .from('professional_profiles')
          .select(
            'user_id, partner_id, specialization, '
            'service_ward_id, service_area, '
            'verification_status, availability, '
            'bio, experience_years',
          )
          .eq('service_ward_id', assignedWardId)
          .eq('verification_status', 'approved')
          .order('partner_id');

      if (!mounted) return;

      setState(() {
        wardId = assignedWardId;

        wardName =
            wardData?['name']?.toString() ??
            'Assigned Ward';

        complaints =
            List<Map<String, dynamic>>.from(
          complaintData,
        );

        pendingProfessionals =
            List<Map<String, dynamic>>.from(
          pendingData,
        );

        approvedProfessionals =
            List<Map<String, dynamic>>.from(
          approvedData,
        );

        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        loading = false;
      });
    }
  }

  // ============================================================
  // REVIEW PROFESSIONAL
  // ============================================================

  Future<void> reviewProfessional({
    required String professionalId,
    required String status,
  }) async {
    if (isReviewingProfessional) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            status == 'approved'
                ? 'Approve Professional?'
                : 'Reject Professional?',
          ),
          content: Text(
            status == 'approved'
                ? 'Are you sure you want to approve '
                    'this professional?'
                : 'Are you sure you want to reject '
                    'this professional?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                status == 'approved'
                    ? 'Approve'
                    : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      reviewingProfessionalId = professionalId;
    });

    try {
      final client = Supabase.instance.client;

      if (client.auth.currentUser == null) {
        throw Exception('BMC officer is not logged in.');
      }

      await client.rpc(
        'review_professional',
        params: {
          'p_professional': professionalId,
          'p_status': status,
          'p_reason': status == 'approved'
              ? 'Approved by BMC officer'
              : 'Rejected by BMC officer',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Professional approved successfully!'
                : 'Professional application rejected.',
          ),
          backgroundColor: status == 'approved'
              ? HydroColors.teal
              : HydroColors.red,
        ),
      );

      await loadDashboard();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Professional review failed: $error',
          ),
          backgroundColor: HydroColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          reviewingProfessionalId = null;
        });
      }
    }
  }

  // ============================================================
  // ASSIGN JOB
  // ============================================================

  Future<void> assignProfessional({
    required String complaintId,
    required String professionalId,
  }) async {
    if (assigningComplaintId != null) return;

    setState(() {
      assigningComplaintId = complaintId;
    });

    try {
      final client = Supabase.instance.client;

      if (client.auth.currentUser == null) {
        throw Exception('Please log in as a BMC officer.');
      }

      final jobId = await client.rpc(
        'assign_job',
        params: {
          'p_complaint': complaintId,
          'p_professional': professionalId,
          'p_amount_paise': null,
          'p_minutes': null,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Job assigned successfully! Job ID: $jobId',
          ),
          backgroundColor: HydroColors.teal,
        ),
      );

      await loadDashboard();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Job assignment failed: $error',
          ),
          backgroundColor: HydroColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          assigningComplaintId = null;
        });
      }
    }
  }

  // ============================================================
  // SHOW APPROVED PROFESSIONALS
  // ============================================================

  Future<void> showAssignProfessionalDialog(
    Map<String, dynamic> complaint,
  ) async {
    if (assigningComplaintId != null) return;

    final complaintId =
        complaint['id']?.toString();

    if (complaintId == null || complaintId.isEmpty) {
      return;
    }

    if (approvedProfessionals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No approved professionals available '
            'in this ward.',
          ),
        ),
      );
      return;
    }

    final selectedProfessional =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Select Professional',
          ),

          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: approvedProfessionals.length,
              itemBuilder: (context, index) {
                final professional =
                    approvedProfessionals[index];

                final specialization =
                    professional['specialization']
                            ?.toString() ??
                        'Unknown';

                final partnerId =
                    professional['partner_id']
                            ?.toString() ??
                        'N/A';

                final serviceArea =
                    professional['service_area']
                            ?.toString() ??
                        'Not specified';

                final availability =
                    professional['availability']
                            ?.toString() ??
                        'unknown';

                return ListTile(
                  leading: Icon(
                    specialization == 'electrician'
                        ? Icons.electrical_services
                        : Icons.plumbing,
                    color: HydroColors.teal,
                  ),

                  title: Text(
                    '$partnerId - $specialization',
                  ),

                  subtitle: Text(
                    '$serviceArea\n'
                    'Availability: $availability',
                  ),

                  isThreeLine: true,

                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                      professional,
                    );
                  },
                );
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedProfessional == null) {
      return;
    }

    final professionalId =
        selectedProfessional['user_id']?.toString();

    if (professionalId == null ||
        professionalId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Job Assignment',
          ),

          content: Text(
            'Assign "${complaint['title']}" to '
            '${selectedProfessional['partner_id']} '
            '(${selectedProfessional['specialization']})?',
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Assign Job'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await assignProfessional(
      complaintId: complaintId,
      professionalId: professionalId,
    );
  }

  // ============================================================
  // SEVERITY LABEL
  // ============================================================

  String severityLabel(String value) {
    switch (value) {
      case 'low':
        return 'GREEN';

      case 'medium':
        return 'YELLOW';

      case 'high':
        return 'RED - High';

      case 'emergency':
        return 'RED - Emergency';

      default:
        return value.toUpperCase();
    }
  }

  Color severityColor(String value) {
    switch (value) {
      case 'low':
        return HydroColors.green;

      case 'medium':
        return HydroColors.yellow;

      case 'high':
      case 'emergency':
        return HydroColors.red;

      default:
        return HydroColors.muted;
    }
  }

  // ============================================================
  // COMPLAINT CARD
  // ============================================================

  Widget buildComplaintCard(
    Map<String, dynamic> complaint,
  ) {
    final severity =
        complaint['reported_severity']?.toString() ??
            'unknown';

    final status =
        complaint['status']?.toString() ?? 'unknown';

    final trackingId =
        complaint['tracking_id']?.toString() ?? 'N/A';

    final title =
        complaint['title']?.toString() ?? 'Water Issue';

    final address =
        complaint['address_text']?.toString() ??
            'Not provided';

    final description =
        complaint['description']?.toString() ?? '';

    final assignedProfessionalId =
        complaint['assigned_professional_id']
            ?.toString();

    final assignedProfessional =
        assignedProfessionalId == null
            ? null
            : approvedProfessionals.where(
                (professional) =>
                    professional['user_id']
                        ?.toString() ==
                    assignedProfessionalId,
              ).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HydroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: severityColor(severity),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: HydroColors.navy,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Tracking ID: $trackingId',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: HydroColors.teal,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Severity: ${severityLabel(severity)}',
            ),

            const SizedBox(height: 6),

            Text('Status: $status'),

            const SizedBox(height: 6),

            Text('Location: $address'),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),

              Text(
                description,
                style: const TextStyle(
                  color: HydroColors.muted,
                ),
              ),
            ],

            if (assignedProfessionalId != null) ...[
              const SizedBox(height: 12),

              Text(
                'Assigned to: '
                '${assignedProfessional?['partner_id'] ?? assignedProfessionalId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: HydroColors.teal,
                ),
              ),
            ],

            if (status == 'submitted' ||
                status == 'waiting_assignment') ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: assigningComplaintId != null
                      ? null
                      : () => showAssignProfessionalDialog(
                            complaint,
                          ),

                  icon: const Icon(
                    Icons.person_add_alt_1,
                  ),

                  label: const Text(
                    'Assign Professional',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFESSIONAL APPROVAL CARD
  // ============================================================

  Widget buildProfessionalCard(
    Map<String, dynamic> professional,
  ) {
    final professionalId =
        professional['user_id']?.toString() ?? '';

    final partnerId =
        professional['partner_id']?.toString() ??
            'N/A';

    final specialization =
        professional['specialization']?.toString() ??
            'Unknown';

    final serviceArea =
        professional['service_area']?.toString() ??
            'Not specified';

    final experience =
        professional['experience_years']?.toString() ??
            'Not specified';

    final bio =
        professional['bio']?.toString() ?? '';

    final isProcessing =
        reviewingProfessionalId == professionalId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HydroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  specialization == 'electrician'
                      ? Icons.electrical_services
                      : Icons.plumbing,
                  color: HydroColors.teal,
                  size: 28,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    specialization.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: HydroColors.navy,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              'Partner ID: $partnerId',
              style: const TextStyle(
                color: HydroColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text('Service Area: $serviceArea'),

            const SizedBox(height: 8),

            Text('Experience: $experience years'),

            const SizedBox(height: 8),

            const Text(
              'Verification: PENDING',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HydroColors.yellow,
              ),
            ),

            if (bio.isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                bio,
                style: const TextStyle(
                  color: HydroColors.muted,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          isReviewingProfessional ||
                                  professionalId.isEmpty
                              ? null
                              : () => reviewProfessional(
                                    professionalId:
                                        professionalId,
                                    status: 'approved',
                                  ),

                      icon: const Icon(
                        Icons.check_circle,
                      ),

                      label: const Text('Approve'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          isReviewingProfessional ||
                                  professionalId.isEmpty
                              ? null
                              : () => reviewProfessional(
                                    professionalId:
                                        professionalId,
                                    status: 'rejected',
                                  ),

                      icon: const Icon(
                        Icons.cancel_outlined,
                      ),

                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN DASHBOARD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BMC Officer Dashboard',
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: loading ||
                    isReviewingProfessional ||
                    assigningComplaintId != null
                ? null
                : loadDashboard,

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,

          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.all(24),

            children: [
              const Text(
                'Water Issue Overview',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: HydroColors.navy,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Ward: $wardName',
                style: const TextStyle(
                  fontSize: 15,
                  color: HydroColors.muted,
                ),
              ),

              const SizedBox(height: 24),

              // ============================================
              // LOADING INDICATOR
              // ============================================

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )

              // ============================================
              // ERROR MESSAGE
              // ============================================

              else if (errorMessage != null)
                HydroCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: HydroColors.red,
                        size: 40,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Unable to load BMC dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      FilledButton(
                        onPressed: loadDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )

              // ============================================
              // DASHBOARD CONTENT
              // ============================================

              else ...[
                // ==========================================
                // CRITICAL ALERTS
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: redCount > 0
                        ? const Color(0xFFFFE7E7)
                        : HydroColors.aqua,

                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        redCount > 0
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,

                        color: redCount > 0
                            ? HydroColors.red
                            : HydroColors.teal,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          redCount > 0
                              ? '$redCount critical issue(s) '
                                  'require attention.'
                              : 'No critical issues currently '
                                  'reported.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // SEVERITY COUNTERS
                // ==========================================

                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        '$greenCount',
                        'Green',
                        Icons.water_drop_outlined,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _Metric(
                        '$yellowCount',
                        'Yellow',
                        Icons.build_outlined,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _Metric(
                        '$redCount',
                        'Red',
                        Icons.warning_amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ==========================================
                // AREA ISSUES
                // ==========================================

                const _SectionTitle(
                  'Area Issues',
                ),

                const SizedBox(height: 12),

                Text(
                  '${complaints.length} complaint(s) '
                  'in $wardName',
                  style: const TextStyle(
                    color: HydroColors.muted,
                  ),
                ),

                const SizedBox(height: 16),

                if (complaints.isEmpty)
                  const HydroCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No complaints found '
                          'in your authorized ward.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ...complaints.map(
                    buildComplaintCard,
                  ),

                const SizedBox(height: 30),

                // ==========================================
                // PENDING PROFESSIONAL APPROVALS
                // ==========================================

                const _SectionTitle(
                  'Pending Professional Approvals',
                ),

                const SizedBox(height: 12),

                Text(
                  '${pendingProfessionals.length} '
                  'professional(s) awaiting approval',
                  style: const TextStyle(
                    color: HydroColors.muted,
                  ),
                ),

                const SizedBox(height: 16),

                if (pendingProfessionals.isEmpty)
                  const HydroCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No pending professional '
                          'applications in your '
                          'authorized ward.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ...pendingProfessionals.map(
                    buildProfessionalCard,
                  ),

                const SizedBox(height: 30),

                // ==========================================
                // APPROVED PROFESSIONALS
                // ==========================================

                const _SectionTitle(
                  'Approved Professionals',
                ),

                const SizedBox(height: 12),

                Text(
                  '${approvedProfessionals.length} '
                  'approved professional(s) in $wardName',
                  style: const TextStyle(
                    color: HydroColors.muted,
                  ),
                ),

                const SizedBox(height: 16),

                if (approvedProfessionals.isEmpty)
                  const HydroCard(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No approved professionals '
                        'found in this ward.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...approvedProfessionals.map(
                    (professional) {
                      final specialization =
                          professional['specialization']
                                  ?.toString() ??
                              'Unknown';

                      final partnerId =
                          professional['partner_id']
                                  ?.toString() ??
                              'N/A';

                      final serviceArea =
                          professional['service_area']
                                  ?.toString() ??
                              'Not specified';

                      final availability =
                          professional['availability']
                                  ?.toString() ??
                              'unknown';

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: HydroCard(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Row(
                                children: [
                                  Icon(
                                    specialization ==
                                            'electrician'
                                        ? Icons
                                            .electrical_services
                                        : Icons.plumbing,

                                    color: HydroColors.teal,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                    child: Text(
                                      specialization
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 17,
                                        color:
                                            HydroColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'Partner ID: $partnerId',
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Service Area: $serviceArea',
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Availability: $availability',
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                'Verification: APPROVED',
                                style: TextStyle(
                                  color:
                                      HydroColors.green,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}