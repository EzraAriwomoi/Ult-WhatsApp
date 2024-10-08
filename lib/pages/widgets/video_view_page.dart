import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ult_whatsapp/common/utils/coloors.dart';

class VideoViewPage extends StatefulWidget {
  const VideoViewPage({
    super.key,
    required this.path,
    required this.turnFlashOn,
  });
  final String path;
  final bool turnFlashOn;

  @override
  _VideoViewPageState createState() => _VideoViewPageState();
}

class _VideoViewPageState extends State<VideoViewPage> {
  late final VideoPlayerController _controller;
  double _currentPosition = 0;
  late double _totalDuration = 0;
  bool _isHDEnabled = false;
  List<String> _thumbnails = [];
  int videoFileSizeInBytes = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {});
        _getVideoFileSize();
        if (widget.turnFlashOn) {
          _turnFlashOn();
        }
        _generateThumbnails();
      });

    _controller.addListener(() {
      setState(() {
        _currentPosition = _controller.value.position.inSeconds.toDouble();
        _totalDuration = _controller.value.duration.inSeconds.toDouble();
      });
    });
  }

  Future<void> _generateThumbnails() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final duration = _controller.value.duration.inSeconds;
    List<String> tempThumbnails = [];

    for (int i = 0; i < duration; i += 2) {
      try {
        final String? thumbnail = await VideoThumbnail.thumbnailFile(
          video: widget.path,
          thumbnailPath: '${(await getTemporaryDirectory()).path}/thumb_$i.jpg',
          imageFormat: ImageFormat.JPEG,
          maxWidth: 80,
          quality: 50,
          timeMs: i * 1000,
        );

        if (thumbnail != null) {
          tempThumbnails.add(thumbnail);
        }
      } catch (e) {
        // print('Error generating thumbnail at time: ${i}s - $e');
      }
    }

    setState(() {
      _thumbnails = tempThumbnails;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    if (widget.turnFlashOn) {
      _turnFlashOff();
    }
    super.dispose();
  }

  void _turnFlashOn() {
    // Flashlight logic (turn on)
  }

  void _turnFlashOff() {
    // Flashlight logic (turn off)
  }

  void _toggleHD() {
    setState(() {
      _isHDEnabled = !_isHDEnabled;
    });
  }

  // Function to get the video file size
  Future<void> _getVideoFileSize() async {
    final file = File(widget.path);
    videoFileSizeInBytes = await file.length();
    setState(() {});
  }

  // Function to convert bytes to human-readable size (KB/MB)
  String getFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Stack(
            children: [
              // Video player container
              Positioned(
                top: 37,
                left: 0,
                right: 0,
                bottom: 108,
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              // Video Timeline (Scrubber)
              Positioned(
                top: 98,
                left: 14,
                right: 14,
                child: Column(
                  children: [
                    // Thumbnails for the video timeline
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      height: 41,
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: _thumbnails.map((thumbnailPath) {
                              // Calculate the width based on the total number of thumbnails
                              double thumbnailWidth =
                                  (MediaQuery.of(context).size.width - 32) /
                                      _thumbnails.length;
                              return Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: SizedBox(
                                  width: thumbnailWidth,
                                  child: Image.file(
                                    File(thumbnailPath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Vertical progress indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 50),
                            left: (_currentPosition / _totalDuration) *
                                (MediaQuery.of(context).size.width - 32),
                            top: 0,
                            child: Container(
                              width: 1.2,
                              height: 41,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Start circle dot
              Positioned(
                left: 10,
                top: 113,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // End circle dot
              Positioned(
                right: 10,
                top: 113,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Volume display
              Positioned(
                top: 146,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volume_up_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),

              // Duration and size display
              Positioned(
                top: 146,
                left: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_controller.value.duration.inMinutes}:${(_controller.value.duration.inSeconds % 60).toString().padLeft(2, '0')}  •  ${getFileSize(videoFileSizeInBytes)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Arial',
                      fontSize: 14,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 55,
                left: 12,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color.fromARGB(135, 24, 30, 39),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // HD button
              Positioned(
                top: 54,
                right: 157,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color.fromARGB(135, 24, 30, 39),
                  child: IconButton(
                    icon: Icon(
                      _isHDEnabled ? Icons.hd : Icons.hd_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleHD,
                  ),
                ),
              ),
              // Sticker button
              Positioned(
                top: 54,
                right: 109,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color.fromARGB(135, 24, 30, 39),
                  child: IconButton(
                    icon: const Icon(
                      Icons.sticky_note_2_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Sticker logic here
                    },
                  ),
                ),
              ),
              // Text button
              Positioned(
                top: 54,
                right: 61,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color.fromARGB(135, 24, 30, 39),
                  child: IconButton(
                    icon: const Icon(
                      Icons.title_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Text logic here
                    },
                  ),
                ),
              ),
              // Edit button
              Positioned(
                top: 54,
                right: 12,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color.fromARGB(135, 24, 30, 39),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Editing logic here
                    },
                  ),
                ),
              ),
              // Caption input field
              Positioned(
                bottom: 0,
                left: 3,
                right: 4,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          maxLines: 4,
                          minLines: 1,
                          onChanged: (value) {},
                          cursorColor: Coloors.greenDark,
                          cursorHeight: 18,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Arial',
                            fontSize: 17,
                            letterSpacing: 0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a caption...',
                            hintStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Arial',
                              fontSize: 17,
                              letterSpacing: 0,
                            ),
                            filled: true,
                            fillColor: Coloors.backgroundDark,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                style: BorderStyle.none,
                                width: 0,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            prefixIcon: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Add photo logic
                                },
                              ),
                            ),
                            suffixIcon: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.motion_photos_on_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Add motion photo logic
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Coloors.greenDark,
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Play/Pause button
              Align(
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.black38,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
