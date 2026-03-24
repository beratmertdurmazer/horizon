import 'dart:js_interop';
import 'package:web/web.dart' as web;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  web.AudioContext? _ctx;
  web.OscillatorNode? _ambientOsc;
  web.GainNode? _ambientGain;

  web.AudioContext _getContext() {
    _ctx ??= web.AudioContext();
    return _ctx!;
  }

  void playTypingBeep() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.value = 850;
      gain.gain.value = 0.03;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.02);
    } catch (e) {}
  }

  void playGlitchSound() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.value = 120;
      gain.gain.value = 0.06;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.2);
    } catch (e) {}
  }

  /// Kalp atışı (Heartbeat) sesi - Programatik Thump
  void playHeartbeat() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      
      // Alçak frekanslı vuruş
      osc.type = 'sine';
      osc.frequency.setValueAtTime(60, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(30, ctx.currentTime + 0.1);
      
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.15);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.15);
    } catch (e) {}
  }

  void playAmbientLoop() {
    try {
      if (_ambientOsc != null) return;
      final ctx = _getContext();
      _ambientOsc = ctx.createOscillator();
      _ambientGain = ctx.createGain();
      _ambientOsc!.type = 'sine';
      _ambientOsc!.frequency.value = 50;
      _ambientGain!.gain.value = 0.05;
      _ambientOsc!.connect(_ambientGain!);
      _ambientGain!.connect(ctx.destination);
      _ambientOsc!.start();
    } catch (e) {}
  }

  void stopAll() {
    try { _ambientOsc?.stop(); _ambientOsc = null; } catch (e) {}
  }
}
