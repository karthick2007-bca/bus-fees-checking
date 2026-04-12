$f = 'c:/feb1/dec_02/lib/views/admin_dashboard.dart'
$c = [System.IO.File]::ReadAllText($f)

# Cut everything from BackupPage onwards, keep only up to FeedbackPage
$feedbackIdx = $c.IndexOf('class FeedbackPage')
$base = $c.Substring(0, $feedbackIdx)

$backupClass = @'
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> with SingleTickerProviderStateMixin {
  List<dynamic> _students = [];
  bool _isLoading = true;
  bool _isDownloading = false;
  late TabController _tabController;

  static const _bg     = Color(0xFF060818);
  static const _card   = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF00CCFF);
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _border = Color(0xFF2E2E4A);
  static const _tp     = Color(0xFFEEEEFF);
  static const _ts     = Color(0xFF8888AA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final data = await ApiService.getStudents();
      setState(() { _students = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _paid   => _students.where((s) => s['status'] == 'succeed').toList();
  List<dynamic> get _unpaid => _students.where((s) => s['status'] != 'succeed').toList();

  Future<void> _downloadPdf(List<dynamic> students, String title, bool isPaid) async {
    setState(() => _isDownloading = true);
    try {
      final pdf = pw.Document();
      final color = isPaid ? PdfColors.green800 : PdfColors.orange800;
      final headers = ['Name', 'Phone', 'Roll No', 'Class', 'Location', isPaid ? 'Amt Paid' : 'Due'];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text(title,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Total: ${students.length} students  •  Generated: ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: color),
                  children: headers.map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  )).toList(),
                ),
                ...students.asMap().entries.map((e) {
                  final i = e.key; final s = e.value;
                  final bg = i.isEven ? PdfColors.grey100 : PdfColors.white;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      s['name']?.toString() ?? '',
                      s['phone']?.toString() ?? '',
                      s['rollNo']?.toString() ?? '',
                      s['studentClass']?.toString() ?? '',
                      s['location']?.toString() ?? '',
                      isPaid ? (s['amountPaid']?.toString() ?? '0') : (s['totalDue']?.toString() ?? '0'),
                    ].map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(v, style: const pw.TextStyle(fontSize: 8)),
                    )).toList(),
                  );
                }),
              ],
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Download PDF', style: TextStyle(color: _tp, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            _downloadTile(Icons.check_circle_rounded, 'Paid Students', 'Download paid students report', _green,
              () { Navigator.pop(context); _downloadPdf(_paid, 'Paid Students Report', true); }),
            const SizedBox(height: 10),
            _downloadTile(Icons.pending_rounded, 'Unpaid Students', 'Download unpaid students report', _amber,
              () { Navigator.pop(context); _downloadPdf(_unpaid, 'Unpaid Students Report', false); }),
          ],
        ),
      ),
    );
  }

  Widget _downloadTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _tp, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: _ts, fontSize: 11)),
          ])),
          Icon(Icons.picture_as_pdf_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paid   = _paid;
    final unpaid = _unpaid;
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00CCFF), Color(0xFF0066FF)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.backup_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Back Up',
                      style: TextStyle(color: _tp, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3))),
                    GestureDetector(
                      onTap: _isDownloading ? null : _showDownloadOptions,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accent.withOpacity(0.35)),
                        ),
                        child: _isDownloading
                            ? const Padding(padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                            : const Icon(Icons.download_rounded, color: _accent, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.14)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_bg, Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_accent.withOpacity(0.14), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_green.withOpacity(0.12), Colors.transparent])))),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(children: [
                        _statBadge('${_students.length}', 'Total', _accent),
                        const SizedBox(width: 10),
                        _statBadge('${paid.length}', 'Paid', _green),
                        const SizedBox(width: 10),
                        _statBadge('${unpaid.length}', 'Unpaid', _amber),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: _green,
                              unselectedLabelColor: _ts,
                              indicatorColor: _green,
                              indicatorWeight: 2,
                              indicatorSize: TabBarIndicatorSize.label,
                              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              tabs: [
                                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.check_circle_rounded, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Paid (${paid.length})'),
                                ])),
                                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.pending_rounded, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Unpaid (${unpaid.length})'),
                                ])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _studentList(paid, _green),
                          _studentList(unpaid, _amber),
                        ],
                      ),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _ts, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _studentList(List<dynamic> students, Color accent) {
    if (students.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 64, height: 64,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Icon(Icons.person_off_rounded, color: Colors.white.withOpacity(0.25), size: 28)),
        const SizedBox(height: 12),
        Text('No students', style: TextStyle(color: _ts, fontSize: 14, fontWeight: FontWeight.w500)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final name  = s['name']?.toString() ?? '';
        final phone = s['phone']?.toString() ?? '';
        final loc   = s['location']?.toString() ?? '';
        final amt   = s['amountPaid'] ?? s['totalDue'] ?? 0;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : (phone.isNotEmpty ? phone[0] : 'S');
        final colors = [_accent, const Color(0xFF6C63FF), _green, _amber, const Color(0xFFEC4899), const Color(0xFF8B5CF6)];
        final c = colors[index % colors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: c.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withOpacity(0.22)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.withOpacity(0.3))),
                    child: Center(child: Text(initial, style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name.isNotEmpty ? name : phone,
                      style: const TextStyle(color: _tp, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (phone.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
                          child: Text(phone, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 6),
                      ],
                      if (loc.isNotEmpty)
                        Expanded(child: Text(loc, style: const TextStyle(color: _ts, fontSize: 10), overflow: TextOverflow.ellipsis)),
                    ]),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.currency_rupee_rounded, color: accent, size: 11),
                      Text('$amt', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

'@

# Get the FeedbackPage onwards
$feedbackOnwards = $c.Substring($feedbackIdx)

# Write: base (up to FeedbackPage) + BackupPage + FeedbackPage onwards
$final = $base + $backupClass + $feedbackOnwards
[System.IO.File]::WriteAllText($f, $final)
Write-Host "Done. File length=$($final.Length)"
