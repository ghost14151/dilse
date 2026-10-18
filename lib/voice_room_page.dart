import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'config/agora_config.dart';

class VoiceRoomPage extends StatefulWidget {
  final String title;
  final String channelName;

  const VoiceRoomPage({
    super.key,
    required this.title,
    required this.channelName,
  });

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage> {
  static const String _tokenUrl =
      'https://dilse-token.ghost14151611.workers.dev';

  RtcEngine? _engine;
  bool _joined = false;
  bool _muted = false;
  bool _busy = false;
  String _status = 'Voice room taiyar ho raha hai';

  @override
  void initState() {
    super.initState();
    _startRoom();
  }

  Future<void> _startRoom() async {
    if (_busy || _joined) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = 'Pehle DilSe mein login karo.');
      return;
    }

    if (!user.emailVerified) {
      setState(() => _status = 'Pehle email verify karo.');
      return;
    }

    if (AgoraConfig.appId.isEmpty) {
      setState(() => _status = 'Agora App ID configure nahi hai.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Firebase aur voice room check ho raha hai...';
    });

    RtcEngine? engine;

    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        if (mounted) {
          setState(
            () => _status =
                'Voice room ke liye microphone permission zaroori hai.',
          );
        }
        return;
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Firebase login token nahi mila.');
      }

      // Worker UID must be numeric and must match joinChannel UID.
      // Use a positive 31-bit value derived from the Firebase UID.
      final uid = _numericUid(user.uid);

      if (mounted) {
        setState(() => _status = 'Secure voice token mil raha hai...');
      }

      final response = await http
          .post(
            Uri.parse(_tokenUrl),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'channelName': widget.channelName, 'uid': uid}),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Token server ka response samajh nahi aaya.');
      }

      if (response.statusCode != 200) {
        final message =
            data['error']?.toString() ?? 'HTTP ${response.statusCode}';
        final detail = data['firebaseError']?.toString();
        throw Exception(
          detail != null && detail.isNotEmpty
              ? '$message ($detail)'
              : message,
        );
      }

      final token = data['token']?.toString() ?? '';
      final returnedAppId = data['appId']?.toString() ?? '';
      final returnedChannel = data['channelName']?.toString() ?? '';
      final returnedUid = int.tryParse(data['uid'].toString());

      if (token.isEmpty ||
          returnedAppId != AgoraConfig.appId ||
          returnedChannel != widget.channelName ||
          returnedUid != uid) {
        throw Exception('Token response ki details match nahi hui.');
      }

      if (mounted) setState(() => _status = 'Agora se connect ho raha hai...');

      engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(RtcEngineContext(appId: AgoraConfig.appId));
      await engine.enableAudio();

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!mounted) return;
            setState(() {
              _joined = true;
              _status = 'Voice room connected';
            });
          },
          onLeaveChannel: (connection, stats) {
            if (!mounted) return;
            setState(() {
              _joined = false;
              _status = 'Room se disconnect ho gaye';
            });
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted) return;
            setState(() => _status = 'Ek participant room mein aaya');
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted) return;
            setState(() => _status = 'Participant room se gaya');
          },
        ),
      );

      await engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      if (mounted) setState(() => _status = 'Connecting...');
    } catch (e) {
      final current = _engine;
      _engine = null;
      if (current != null) {
        try {
          await current.leaveChannel();
          await current.release();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _status = 'Connect nahi hua: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _numericUid(String firebaseUid) {
    // Deterministic positive 31-bit hash. Never use UID 0 for this Worker.
    var hash = 0;
    for (final unit in firebaseUid.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<void> _toggleMute() async {
    final engine = _engine;
    if (engine == null || !_joined) return;

    final next = !_muted;
    try {
      await engine.muteLocalAudioStream(next);
      if (mounted) setState(() => _muted = next);
    } catch (_) {
      if (mounted) setState(() => _status = 'Microphone change nahi hua.');
    }
  }

  Future<void> _leaveRoom() async {
    final engine = _engine;
    _engine = null;

    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (_) {}
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      engine.leaveChannel();
      engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.graphic_eq, size: 76),
              const SizedBox(height: 20),
              Text(
                widget.channelName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_joined)
                FilledButton.icon(
                  onPressed: _toggleMute,
                  icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                  label: Text(_muted ? 'Unmute microphone' : 'Mute microphone'),
                ),
              if (!_joined && !_busy)
                FilledButton(
                  onPressed: _startRoom,
                  child: const Text('Try connecting again'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _leaveRoom,
                child: const Text('Leave room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
