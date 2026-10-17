import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
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
  RtcEngine? _engine;
  bool _joined = false;
  bool _muted = false;
  bool _busy = false;
  String _status = 'Voice room taiyar ho raha hai';

  static const String _testToken =
      String.fromEnvironment('AGORA_TEST_TOKEN');

  @override
  void initState() {
    super.initState();
    _startRoom();
  }

  Future<void> _startRoom() async {
    if (AgoraConfig.appId.isEmpty || _testToken.isEmpty) {
      setState(() {
        _status =
            'Test setup baaki hai. App ID aur temporary token build ke waqt dena hoga.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Microphone permission check ho raha hai...';
    });

    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        setState(() => _status = 'Voice room ke liye microphone permission zaroori hai.');
        return;
      }

      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(
        RtcEngineContext(appId: AgoraConfig.appId),
      );
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
        token: _testToken,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      if (mounted) setState(() => _status = 'Connecting...');
    } catch (e) {
      if (mounted) setState(() => _status = 'Connect nahi hua: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleMute() async {
    final engine = _engine;
    if (engine == null || !_joined) return;
    final next = !_muted;
    try {
      await engine.muteLocalAudioStream(next);
      if (mounted) setState(() => _muted = next);
    } catch (e) {
      if (mounted) setState(() => _status = 'Microphone change nahi hua');
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
              Text(widget.channelName,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_joined)
                FilledButton.icon(
                  onPressed: _toggleMute,
                  icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                  label: Text(_muted ? 'Unmute microphone' : 'Mute microphone'),
                ),
              if (!_joined && !_busy && AgoraConfig.appId.isNotEmpty && _testToken.isNotEmpty)
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
