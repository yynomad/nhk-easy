import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/news.dart';

class AudioControls extends StatefulWidget {
  const AudioControls(this.news, {super.key});
  final NewsItem news;
  @override
  State<AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends State<AudioControls>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerException>? _errors;
  bool _loading = true;
  bool _loop = false;
  double _speed = 1;
  double? _drag;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _errors = _player.errorStream.listen((_) {
      if (mounted) setState(() => _error = '音频播放失败，请重试。');
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.news.isDemo && widget.news.assetAudio != null) {
        await _player.setAsset(widget.news.assetAudio!);
      } else if (widget.news.audioUrl != null) {
        await _player.setUrl(widget.news.audioUrl!);
      } else {
        throw StateError('No audio');
      }
    } catch (_) {
      if (mounted) setState(() => _error = '无法加载音频，请重试。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<void> Function() task) async {
    try {
      await task();
    } catch (_) {
      if (mounted) setState(() => _error = '音频操作失败，请重试。');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_action(_player.pause));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_errors?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  String _clock(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => Material(
    elevation: 6,
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.news.isDemo ? '演示合成语音 · 非 NHK 原音' : 'NHK 原始音频',
              style: const TextStyle(fontSize: 12),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing =
                    (state?.playing ?? false) &&
                    state?.processingState != ProcessingState.completed;
                final buffering =
                    _loading ||
                    state?.processingState == ProcessingState.buffering;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (buffering) const LinearProgressIndicator(),
                    StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, positionSnapshot) {
                            final position =
                                positionSnapshot.data ?? Duration.zero;
                            final max = duration.inMilliseconds.toDouble();
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Slider(
                                  value:
                                      (_drag ??
                                              position.inMilliseconds
                                                  .toDouble())
                                          .clamp(0.0, max > 0 ? max : 1.0)
                                          .toDouble(),
                                  max: max > 0 ? max : 1.0,
                                  label: _clock(
                                    Duration(
                                      milliseconds:
                                          (_drag ?? position.inMilliseconds)
                                              .round(),
                                    ),
                                  ),
                                  onChanged: max <= 0
                                      ? null
                                      : (value) =>
                                            setState(() => _drag = value),
                                  onChangeEnd: max <= 0
                                      ? null
                                      : (value) {
                                          setState(() => _drag = null);
                                          unawaited(
                                            _action(
                                              () => _player.seek(
                                                Duration(
                                                  milliseconds: value.round(),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _clock(position),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      _clock(duration),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _loading
                              ? null
                              : () {
                                  if (_error != null) {
                                    unawaited(_load());
                                    return;
                                  }
                                  unawaited(
                                    _action(() async {
                                      if (playing) {
                                        await _player.pause();
                                      } else {
                                        if (_player.processingState ==
                                            ProcessingState.completed) {
                                          await _player.seek(Duration.zero);
                                        }
                                        await _player.play();
                                      }
                                    }),
                                  );
                                },
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          label: Text(
                            _error != null
                                ? '重试'
                                : playing
                                ? '暂停'
                                : '播放',
                          ),
                        ),
                        IconButton(
                          tooltip: '后退10秒',
                          icon: const Icon(Icons.replay_10),
                          onPressed: () => unawaited(
                            _action(
                              () => _player.seek(
                                Duration(
                                  milliseconds:
                                      (_player.position.inMilliseconds - 10000)
                                          .clamp(0, 1 << 53)
                                          .toInt(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DropdownButton<double>(
                          value: _speed,
                          underline: const SizedBox.shrink(),
                          items: [.75, 1.0, 1.25, 1.5]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v×'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              unawaited(
                                _action(() async {
                                  await _player.setSpeed(value);
                                  if (mounted) setState(() => _speed = value);
                                }),
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: _loop ? '关闭循环' : '单篇循环',
                          isSelected: _loop,
                          icon: const Icon(Icons.repeat_one),
                          onPressed: () => unawaited(
                            _action(() async {
                              final next = !_loop;
                              await _player.setLoopMode(
                                next ? LoopMode.one : LoopMode.off,
                              );
                              if (mounted) setState(() => _loop = next);
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
