import 'package:flutter/material.dart';
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
      const ReportScreen(),
      const TrackScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
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
        Container(padding: const EdgeInsets.all(34),
          decoration: const BoxDecoration(color: HydroColors.aqua, shape: BoxShape.circle),
          child: const Icon(Icons.water_drop_rounded, color: HydroColors.teal, size: 96)),
        const SizedBox(height: 28),
        const Text('HydroFix', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: HydroColors.navy)),
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
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(), password: password.text);
      if (!mounted) return;
      // Roles must be resolved from profiles / memberships, never a UI choice.
      // Until that authorization is wired, only citizen navigation is enabled.
      if (widget.role != HydroRole.citizen) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
          Text('Professional/BMC role verification is not connected yet.')));
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
        builder: (_) => const HydroShell()), (_) => false);
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to sign in. Try again.')));
    } finally { if (mounted) setState(() => busy = false); }
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
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final form = GlobalKey<FormState>();
  String severity = 'green';
  @override
  void dispose() { title.dispose(); description.dispose(); super.dispose(); }

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
          Container(height: 120, width: double.infinity,
            decoration: BoxDecoration(color: HydroColors.aqua,
              borderRadius: BorderRadius.circular(16)),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_a_photo_outlined, size: 35, color: HydroColors.teal),
              SizedBox(height: 8), Text('Add a photo of the issue'),
            ])),
          const SizedBox(height: 8),
          const Text('Photo picker integration is the next step.',
            style: TextStyle(fontSize: 12, color: HydroColors.muted)),
        ])),
        const SizedBox(height: 16),
        TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Issue title'),
          validator: (s) => (s == null || s.trim().isEmpty) ? 'Enter a title' : null),
        const SizedBox(height: 16),
        TextFormField(controller: description, maxLines: 4,
          decoration: const InputDecoration(labelText: 'Describe the problem'),
          validator: (s) => (s == null || s.trim().isEmpty) ? 'Describe the issue' : null),
        const SizedBox(height: 16),
        const HydroCard(child: Row(children: [
          Icon(Icons.location_on_outlined, color: HydroColors.teal),
          SizedBox(width: 12), Expanded(child: Text('Location will be obtained with permission')),
        ])),
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
        OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI verification will connect to the existing Edge Function.'))),
          icon: const Icon(Icons.auto_awesome), label: const Text('AI Verify Severity')),
        const SizedBox(height: 18),
        FilledButton(onPressed: () {
          if (!form.currentState!.validate()) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
            Text('Preview only — report was not submitted to Supabase.')));
        }, child: const Text('Submit Report')),
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

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    padding: EdgeInsets.all(24), children: [
      _SectionTitle('Track Complaint'),
      SizedBox(height: 8),
      Text('View updates on your reported issues.', style: TextStyle(color: HydroColors.muted)),
      SizedBox(height: 24),
      HydroCard(child: Column(children: [
        Icon(Icons.fact_check_outlined, size: 54, color: HydroColors.teal),
        SizedBox(height: 12),
        Text('No complaints loaded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Complaint tracking will read from your Supabase complaints table.',
          textAlign: TextAlign.center, style: TextStyle(color: HydroColors.muted)),
      ])),
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
