import 'package:fluent_ai/app/models/interview_video.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerView extends StatefulWidget {
  final InterviewVideo video;

  const VideoPlayerView({super.key, required this.video});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan ID video dari model kita
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F1A,
      ), // Tema gelap agar fokus ke video
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Nonton Panduan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pemutar Video
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF6C63FF),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFF6C63FF),
              handleColor: Colors.white,
            ),
          ),

          // Info Video di bawahnya
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business_center_rounded,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.video.company,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatViews(widget.video.viewCount),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000)
      return '${(views / 1000000).toStringAsFixed(1)}M Views';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}rb Views';
    return '$views Views';
  }
}
