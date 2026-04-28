import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class ClassSectionBackupPage extends StatefulWidget {
  const ClassSectionBackupPage({super.key});

  @override
  State<ClassSectionBackupPage> createState() => _ClassSectionBackupPageState();
}

class _ClassSectionBackupPageState extends State<ClassSectionBackupPage> {
  List<dynamic> _paidStudents = [];
  bool _isLoading = true;

  static const _bg     = Color(0xFF060818);
  static const _accent = Color(0xFF00CCFF);
  static const _green  = Color(0xFF10B981);
  static const _tp     = Color(0xFFEEEEFF);

  // class-wise accent colors
  final List<Color> _sectionColors = [
    const Color(0xFF6C00FF), const Color(0xFF0EA5E9), const Color(0xFF10B981),
    const Color(0xFFF59E0B), const Color(0xFFEC4899), const Color(0xFF8B5CF6),
    const Color(0xFF00CCFF), const Color(0xFFEF4444), const Color(0xFF06B6D4),
  ];

  int _currentClassIndex = 0;
  static const _visibleCount = 3;

  @override
  void initState() {
    super.initState();
    _loadPaidStudents();
  }

  Future<void> _loadPaidStudents() async {
    try {
      final students = await ApiService.getStudents();
      setState(() {
        _paidStudents = students.where((s) => s['status'] == 'succeed').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // "5TH/A" → class="5TH", section="A"
  String _classOnly(String raw) {
    final norm = raw.trim().toUpperCase().replaceAll('-', '/');
    final parts = norm.split('/');
    return parts[0];
  }

  String _sectionOnly(String raw) {
    final norm = raw.trim().toUpperCase().replaceAll('-', '/');
    final parts = norm.split('/');
    return parts.length > 1 ? parts[1] : '';
  }

  // group by class only → { "5TH": { "A": [...], "B": [...] } }
  Map<String, Map<String, List<dynamic>>> _groupByClassAndSection() {
    final Map<String, Map<String, List<dynamic>>> grouped = {};
    for (final s in _paidStudents) {
      final raw = (s['studentClass']?.toString() ?? '').trim();
      final cls = raw.isEmpty ? 'No Class' : _classOnly(raw);
      final sec = raw.isEmpty ? '' : _sectionOnly(raw);
      grouped.putIfAbsent(cls, () => {}).putIfAbsent(sec, () => []).add(s);
    }
    final sorted = grouped.keys.toList()
      ..sort((a, b) => _classOrder(a).compareTo(_classOrder(b)));
    return {for (final k in sorted) k: grouped[k]!};
  }

  int _classOrder(String cls) {
    if (cls == 'No Class') return 9999;
    final lower = cls.toLowerCase();
    if (lower.startsWith('lkg')) return 0;
    if (lower.startsWith('ukg')) return 1;
    final match = RegExp(r'^(\d+)').firstMatch(cls);
    if (match != null) return int.parse(match.group(1)!) * 10;
    return 500;
  }

  Future<void> _downloadSectionPdf(String className, String sec, List<dynamic> students) async {
    final title = '$className${sec.isEmpty ? '' : ' - Section $sec'} | Paid Students';
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(color: PdfColors.indigo700, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Text(title,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 6),
        pw.Text('Total: ${students.length} students  •  Generated: ${DateTime.now().toString().split('.')[0]}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              children: ['Name', 'Phone', 'Roll No', 'Location', 'Amt Paid'].map((h) =>
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                )).toList(),
            ),
            ...students.asMap().entries.map((e) {
              final i = e.key; final s = e.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.grey100 : PdfColors.white),
                children: [
                  s['name']?.toString() ?? '',
                  s['phone']?.toString() ?? '',
                  s['rollNo']?.toString() ?? '',
                  s['location']?.toString() ?? '',
                  s['amountPaid']?.toString() ?? '0',
                ].map((v) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(v, style: const pw.TextStyle(fontSize: 8)),
                )).toList(),
              );
            }),
          ],
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00CCFF), Color(0xFF0066FF)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Class-wise Paid Students',
                          style: TextStyle(color: _tp, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                      ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
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
                : _paidStudents.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Icon(Icons.school_outlined, color: Colors.white.withOpacity(0.25), size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text('No paid students yet',
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
                        ]),
                      )
                    : _buildClassList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final grouped = _groupByClassAndSection();
    final classes = grouped.keys.toList();
    if (classes.isEmpty) return const SizedBox();

    if (_currentClassIndex >= classes.length) _currentClassIndex = 0;

    final className = classes[_currentClassIndex];
    final sections = grouped[className]!;
    final sortedSections = sections.keys.toList()..sort();
    final color = _sectionColors[_currentClassIndex % _sectionColors.length];
    final totalStudents = sections.values.fold(0, (s, l) => s + l.length);

    // window of 3: shift so selected is always visible and centered
    int startIdx = _currentClassIndex - 1;
    if (startIdx < 0) startIdx = 0;
    if (startIdx + _visibleCount > classes.length) startIdx = classes.length - _visibleCount;
    if (startIdx < 0) startIdx = 0;
    final visibleClasses = classes.sublist(startIdx, (startIdx + _visibleCount).clamp(0, classes.length));

    return Column(
      children: [
        // ── < 3-class scroll > ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              // < prev
              GestureDetector(
                onTap: _currentClassIndex > 0
                    ? () => setState(() => _currentClassIndex--)
                    : null,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _currentClassIndex > 0 ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _currentClassIndex > 0 ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                    color: _currentClassIndex > 0 ? color : Colors.white24, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              // 3 class chips
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: visibleClasses.map((cls) {
                    final idx = classes.indexOf(cls);
                    final isActive = idx == _currentClassIndex;
                    final c = _sectionColors[idx % _sectionColors.length];
                    return GestureDetector(
                      onTap: () => setState(() => _currentClassIndex = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? c.withOpacity(0.22) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? c.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Text(cls,
                          style: TextStyle(
                            color: isActive ? c : Colors.white38,
                            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                            fontSize: isActive ? 14 : 12,
                          )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              // > next
              GestureDetector(
                onTap: _currentClassIndex < classes.length - 1
                    ? () => setState(() => _currentClassIndex++)
                    : null,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _currentClassIndex < classes.length - 1 ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _currentClassIndex < classes.length - 1 ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                    color: _currentClassIndex < classes.length - 1 ? color : Colors.white24, size: 22),
                ),
              ),
            ],
          ),
        ),

        // ── selected class info ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: _green, size: 12),
                const SizedBox(width: 5),
                Text('$totalStudents paid  •  ${sortedSections.length} sections',
                  style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),

        // ── Sections list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: sortedSections.length,
            itemBuilder: (context, i) {
              final sec = sortedSections[i];
              final students = sections[sec]!;
              final label = sec.isEmpty ? 'No Section' : sec;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.45)),
                    ),
                    child: Center(
                      child: Text(label,
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$className${sec.isEmpty ? '' : ' / $sec'}',
                          style: const TextStyle(color: _tp, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text('${students.length} student${students.length == 1 ? '' : 's'} paid',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _downloadSectionPdf(className, sec, students),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _green.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.download_rounded, color: _green, size: 14),
                        const SizedBox(width: 4),
                        Text('${students.length}',
                          style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }
}
