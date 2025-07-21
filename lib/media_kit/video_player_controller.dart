import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CustomVideoPlayerController {
  final Player player;
  final VideoController videoController;

  CustomVideoPlayerController._(this.player, this.videoController);

  static Future<CustomVideoPlayerController> create(String url) async {
    final player = Player();
    final videoController = VideoController(player);
    await player.open(Media(url));
    return CustomVideoPlayerController._(player, videoController);
  }

  void playOrPause() {
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void dispose() {
    player.dispose();
  }
}
