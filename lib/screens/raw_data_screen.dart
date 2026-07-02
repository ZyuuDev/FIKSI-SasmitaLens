import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bluetooth_service.dart';
import '../utils/app_theme.dart';

/// Raw Data Screen — Monitor Serial & Mode Tes Bebas ESP32
/// Menampilkan log JSON mentah dari ESP32 dan tombol kirim perintah akustik.
/// Tidak ada UV, tidak ada fluoresensi — AKUSTIK ONLY.
class RawDataScreen extends ConsumerStatefulWidget {
  const RawDataScreen({super.key});
  @override
  ConsumerState<RawDataScreen> createState() => _RawDataScreenState();
}

class _RawDataScreenState extends ConsumerState<RawDataScreen> {
  final List<_LogEntry> _logs = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _customCtrl = TextEditingController();
  StreamSubscription<String>? _sub;

  // ── State panel debug akustik ──────────────────────────────
  int    _freq   = 0;
  int    _amp    = 0;
  int    _conf   = 0;
  String _status = '—';
  bool   _ampValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenRaw());
  }

  void _listenRaw() {
    final btManager = ref.read(bluetoothManagerProvider);
    _sub = btManager.rawDataStream.listen((raw) {
      if (!mounted) return;
      _addLog(raw);
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;

        if (json['debug'] == 'AMP') {
          // Respon dari DEBUG_AMP
          setState(() {
            _freq    = (json['freq'] as num?)?.toInt() ?? _freq;
            _amp     = (json['amp']  as num?)?.toInt() ?? _amp;
            _ampValid = _amp > 25;
          });
        } else if (json.containsKey('acoustic')) {
          // Hasil scan normal
          setState(() {
            _freq    = (json['acoustic'] as num?)?.toInt() ?? _freq;
            _amp     = (json['amp']      as num?)?.toInt() ?? _amp;
            _conf    = (json['conf']     as num?)?.toInt() ?? _conf;
            _status  = json['status']    as String?        ?? _status;
            _ampValid = _amp > 25;
          });
        } else if (json.containsKey('status')) {
          setState(() => _status = json['status'] as String? ?? _status);
        }
      } catch (_) {}
    });
  }

  void _addLog(String raw) {
    final now = DateTime.now();
    final ts  = '${now.hour.toString().padLeft(2, '0')}:'
                '${now.minute.toString().padLeft(2, '0')}:'
                '${now.second.toString().padLeft(2, '0')}';
    _LogType type = _LogType.data;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json.containsKey('debug'))                    type = _LogType.debug;
      else if (json['status'] == 'ERROR')               type = _LogType.error;
      else if (json.containsKey('acoustic'))            type = _LogType.scan;
      else                                              type = _LogType.notif;
    } catch (_) { type = _LogType.error; }

    setState(() {
      _logs.add(_LogEntry(ts: ts, raw: raw, type: type));
      if (_logs.length > 300) _logs.removeAt(0);
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String cmd) {
    final bt = ref.read(bluetoothManagerProvider);
    if (!bt.terhubung) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Belum terhubung ke ESP32')),
      );
      return;
    }
    bt.kirimPerintah(cmd);
    final now = DateTime.now();
    final ts  = '${now.hour.toString().padLeft(2, '0')}:'
                '${now.minute.toString().padLeft(2, '0')}:'
                '${now.second.toString().padLeft(2, '0')}';
    setState(() => _logs.add(_LogEntry(
      ts: ts,
      raw: '→ $cmd',
      type: _LogType.cmd,
    )));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terhubung = ref.watch(btTerhubungProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundCard,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MODE TES BEBAS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
            Text(
              terhubung ? '🟢 ESP32 Terhubung' : '🔴 Belum Terhubung',
              style: TextStyle(
                fontSize: 11,
                color: terhubung ? AppTheme.primaryGreen : AppTheme.statusError,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => setState(_logs.clear),
            tooltip: 'Bersihkan Log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel debug akustik
          _AcousticDebugPanel(
            freq: _freq,
            amp: _amp,
            conf: _conf,
            status: _status,
            ampValid: _ampValid,
          ),

          // Panel tombol perintah
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundCard,
              border: Border(
                top:    BorderSide(color: AppTheme.borderDark),
                bottom: BorderSide(color: AppTheme.borderDark),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PERINTAH ESP32',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _Btn('SCAN',       Icons.document_scanner_rounded, AppTheme.primaryGreen,  _send),
                  _Btn('DEBUG_AMP',  Icons.graphic_eq_rounded,       AppTheme.accentBlue,    _send),
                  _Btn('STREAM_ON',  Icons.waves_rounded,            AppTheme.primaryGreen,  _send),
                  _Btn('STREAM_OFF', Icons.stop_circle_outlined,     AppTheme.textMuted,     _send),
                  _Btn('KALIBRASI',  Icons.sync_rounded,             AppTheme.accentBlue,    _send),
                  _Btn('TIDUR',      Icons.power_settings_new,       AppTheme.statusError,   _send),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _customCtrl,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Perintah kustom...',
                        hintStyle:
                            const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.borderDark)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.borderDark)),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          _send(v.trim().toUpperCase());
                          _customCtrl.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final v = _customCtrl.text.trim();
                      if (v.isNotEmpty) {
                        _send(v.toUpperCase());
                        _customCtrl.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: const Text('KIRIM',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ),

          // Log terminal
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Terminal kosong.\nHubungkan ESP32 lalu tekan tombol perintah.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(10),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '[${log.ts}] ',
                              style: const TextStyle(
                                  color: Color(0xFF555555),
                                  fontSize: 10,
                                  fontFamily: 'monospace'),
                            ),
                            TextSpan(
                              text: log.raw,
                              style: TextStyle(
                                color: log.type.color,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: log.type == _LogType.scan
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Debug Panel Akustik (ONLY, tanpa fluoresensi) ─────────────
class _AcousticDebugPanel extends StatelessWidget {
  const _AcousticDebugPanel({
    required this.freq,
    required this.amp,
    required this.conf,
    required this.status,
    required this.ampValid,
  });
  final int    freq, amp, conf;
  final String status;
  final bool   ampValid;

  @override
  Widget build(BuildContext context) {
    final confColor = conf >= 70
        ? AppTheme.primaryGreen
        : conf >= 40
            ? AppTheme.accentOrange
            : AppTheme.statusError;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.graphic_eq_rounded,
                color: AppTheme.primaryGreen, size: 14),
            const SizedBox(width: 6),
            const Text('AKUSTIK — MAX9814 + BUZZER LLT',
                style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (ampValid
                        ? AppTheme.primaryGreen
                        : AppTheme.statusError)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ampValid ? '✓ SINYAL VALID' : '✗ SINYAL LEMAH',
                style: TextStyle(
                    color: ampValid
                        ? AppTheme.primaryGreen
                        : AppTheme.statusError,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _MiniVal(
                label: 'FREQ',
                value: freq > 0 ? '$freq Hz' : '—',
                color: AppTheme.primaryGreen),
            const SizedBox(width: 16),
            _MiniVal(
                label: 'AMP',
                value: amp > 0 ? '$amp' : '—',
                color: AppTheme.accentBlue),
            const SizedBox(width: 16),
            _MiniVal(
                label: 'STATUS',
                value: status,
                color: AppTheme.textPrimary),
            const Spacer(),
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CONF $conf%',
                      style: TextStyle(
                          color: confColor, fontSize: 9)),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (conf / 100.0).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: const Color(0xFF222222),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(confColor),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 6),
          // Bar amplitude
          Row(children: [
            const Text('AMP',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                    letterSpacing: 1)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (amp / 500.0).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: const Color(0xFF222222),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    amp > 25 ? AppTheme.accentBlue : AppTheme.statusError,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(amp > 25 ? '> 25 ✓' : '≤ 25 ✗',
                style: TextStyle(
                    color: amp > 25
                        ? AppTheme.primaryGreen
                        : AppTheme.statusError,
                    fontSize: 8,
                    fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

class _MiniVal extends StatelessWidget {
  const _MiniVal(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8,
              letterSpacing: 1)),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace')),
    ]);
  }
}

enum _LogType { cmd, debug, scan, notif, error, data }

extension _LogColor on _LogType {
  Color get color => switch (this) {
        _LogType.cmd   => const Color(0xFFFFD600),
        _LogType.debug => const Color(0xFF40C4FF),
        _LogType.scan  => const Color(0xFF69FF47),
        _LogType.notif => const Color(0xFFB0BEC5),
        _LogType.error => const Color(0xFFFF5252),
        _LogType.data  => const Color(0xFF78909C),
      };
}

class _LogEntry {
  const _LogEntry({required this.ts, required this.raw, required this.type});
  final String   ts, raw;
  final _LogType type;
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.icon, this.color, this.onTap);
  final String            label;
  final IconData          icon;
  final Color             color;
  final void Function(String) onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace')),
        ]),
      ),
    );
  }
}
