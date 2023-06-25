import 'dart:io';
import 'dart:isolate';
import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../Widgets/QueueWidget.dart';
import 'QueueObject.dart';

// Class responsible for handling the video download process
class DownloadManager {
  // Isolate Function
  @pragma('vm:entry-point')
  static void donwloadVideoFromYoutube(Map<String, dynamic> args) async {
    // Port to send download status to UI (QueueWidget)
    final SendPort sd = args['port'];
    // A port to be sent to QueueWidget for it to be able to kill the Isolate when stopping the download
    ReceivePort rc = ReceivePort();
    sd.send([rc.sendPort]);
    rc.listen(((message) {
      Isolate.exit();
    }));

    final yt = YoutubeExplode();
    double progress = 0;
    // Filename
    String title = args['ytObj'].validTitle as String;
    // Condition to download the video if the download type is Video only or Video+Audio
    if (args['ytObj'].downloadType == DownloadType.VideoOnly ||
        args['ytObj'].downloadType == DownloadType.Muxed) {
      try {
        var stream = yt.videos.streamsClient.get(args['ytObj'].stream);
        final size =
            args['ytObj'].stream.size.totalBytes; // for calculating percentage
        var count = 0; // number of bytes downloaded for calculating percentage

        String? fileDir;
        // Condition to put the video in the downloads folder if download type is Video only
        // and in temp if it is Video+Audio as it is not the final product and still needs conversion
        Directory? directory =
            args['ytObj'].downloadType == DownloadType.VideoOnly
                ? args['downloads']
                : args['temp'];
        fileDir =
            '${directory!.path}/$title.${args['ytObj'].stream.container.name}';
        File vidFile = await File(fileDir).create(recursive: true);

        var fileStream = vidFile.openWrite(mode: FileMode.writeOnlyAppend);
        await for (var bytes in stream) {
          fileStream.add(bytes);
          count += bytes.length;
          var currentProgress = ((count / size) * 100);
          progress = currentProgress;
          if (args['ytObj'].downloadType == DownloadType.Muxed) {
            currentProgress = progress / 2;
          }
          print(currentProgress);
          sd.send([DownloadStatus.downloading, currentProgress]);
        }
      } catch (e) {
        sd.send([e.toString()]);
      }
    }

    // Condition to download the audio if the download type is Audio only or Video+Audio
    if (args['ytObj'].downloadType == DownloadType.AudioOnly ||
        args['ytObj'].downloadType == DownloadType.Muxed) {
      try {
        final audioStream =
            yt.videos.streamsClient.get(args['ytObj'].bestAudio);
        final size = args['ytObj']
            .bestAudio
            .size
            .totalBytes; // for calculating percentage
        var count = 0; // number of bytes downloaded for calculating percentage

        // Directory is always temp because conversion is still needed
        Directory? directory = args['temp'];
        String? fileDir =
            '${directory!.path}/$title.${args['ytObj'].bestAudio.container.name}';
        File audFile = await File(fileDir).create(recursive: true);

        var fileStream =
            await audFile.openWrite(mode: FileMode.writeOnlyAppend);
        await for (var bytes in audioStream) {
          fileStream.add(bytes);
          count += bytes.length;
          double currentProgress = ((count / size) * 100);
          progress = 100 + currentProgress;
          if (args['ytObj'].downloadType == DownloadType.Muxed) {
            currentProgress = progress / 2;
          }
          print(currentProgress);
          sd.send([DownloadStatus.downloading, currentProgress]);
        }
      } catch (e) {
        sd.send([e.toString()]);
      }
    }

    yt.close();
    // Condition to determine if further conversion is needed
    if (args['ytObj'].downloadType == DownloadType.VideoOnly) {
      sd.send([DownloadStatus.done, 100.0]);
    } else {
      sd.send([DownloadStatus.converting, 100.0]);
    }
    Isolate.exit();
  }

  static void convertToMp3(Directory? downloads, YoutubeQueueObject ytobj,
      Function callBack, Directory temp, BuildContext context) async {
    // Code to get the image of the vid thumbnail for the mp3 metadata photo
    String imgPath = '${temp.path}/${ytobj.validTitle}.jpg';
    File? imgfile = await getImageAsFile(ytobj.thumbnail, imgPath);
    String audioDir =
        "${temp.path}/${ytobj.validTitle}.${ytobj.bestAudio.container.name}";

    // More metadata
    String author = ytobj.author;
    String title = ytobj.title;

    // Output Mp3 path
    String out = '${downloads!.path}/${ytobj.validTitle}.mp3';
    List<String> args = [];

    // if for any reason the thumbnail could not be gotten include less metadata
    if (imgfile != null) {
      args = [
        "-y",
        '-i',
        '$audioDir',
        '-i',
        '$imgPath',
        '-map',
        '0',
        '-map',
        '1',
        '-metadata',
        'artist=$author',
        '-metadata',
        'title=$title',
        '$out'
      ];
    } else {
      args = ['-y', '-i', '$audioDir', '$out'];
    }

    print(args);
    FFmpegKit.executeWithArgumentsAsync(args, (session) async {
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode) &&
          !ReturnCode.isCancel(returnCode)) {
        GlobalMethods.snackBarError(session.getOutput().toString(), context);
        clean(ytobj, downloads, temp, true);
      }

      // Clean function is used to delete the unconverted audio webm file
      clean(ytobj, downloads, temp, false);

      // Refreshes the QueueWidget
      callBack();

      return;
    }, ((log) {
      print(log.getMessage());
    }));
  }

  static void mergeIntoMp4(Directory? temps, Directory? downloads,
      YoutubeQueueObject ytobj, Function callBack, BuildContext context) {
    String audioDir =
        "${temps!.path}/${ytobj.validTitle}.${ytobj.bestAudio.container.name}";
    String videoDir = "${temps.path}/${ytobj.validTitle}.mp4";
    String outDir = "${downloads!.path}/${ytobj.validTitle}.mp4";

    List<String> args = [
      '-y',
      '-i',
      '$videoDir',
      '-i',
      '$audioDir',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '$outDir'
    ];

    FFmpegKit.executeWithArgumentsAsync(args, (session) async {
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode) &&
          !ReturnCode.isCancel(returnCode)) {
        String? msg = await session.getOutput();
        GlobalMethods.snackBarError(msg!, context);
        clean(ytobj, downloads, temps, true);
      }

      print(session.getOutput());

      // Clean function is used to delete the separate Audio and Video files
      clean(ytobj, downloads, temps, false);

      // Refreshes the QueueWidget
      callBack();
    }, ((log) {
      print(log.getMessage());
    }));
  }

  // Function to download the thumbnail image
  static Future<File?> getImageAsFile(String uri, String path) async {
    final file = File(path);
    try {
      final response = await http.get(Uri.parse(uri));

      file.writeAsBytesSync(response.bodyBytes);

      return file;
    } catch (e) {
      return null;
    }
  }

  // Function to stop the download
  static void stop(DownloadStatus ds, YoutubeQueueObject queueObject,
      Directory downloads, Directory temps, SendPort? stopper) async {
    // if the file is still being downloaded send anything through the stopper port to kill the isolate
    // else ask FFmpeg to stop every ongoing operation (might be a problem)
    if (ds == DownloadStatus.downloading) {
      stopper!.send(null);
    } else {
      FFmpegKit.cancel();
    }
    // then delete the files downloaded
    clean(queueObject, downloads, temps, true);
  }

  static void clean(YoutubeQueueObject queueObject, Directory downloads,
      Directory temps, bool cleanOutFile) async {
    // if download type is audio only then delete the following:
    // - The webm audio file
    // - The Image file used for mp3 metadata
    // - The output mp3 file (if requested when stopping the download)
    if (queueObject.downloadType == DownloadType.AudioOnly) {
      String path =
          '${temps.path}/${queueObject.validTitle}.${queueObject.bestAudio.container.name}';
      File file = File(path);

      String imgPath = '${temps.path}/${queueObject.validTitle}.jpg';
      File imgFile = File(imgPath);

      String outPath = '${downloads.path}/${queueObject.validTitle}.mp3';
      File outFile = File(outPath);

      try {
        await file.delete();
        await imgFile.delete();
        if (cleanOutFile) {
          await outFile.delete();
        }
      } catch (e) {}
      // if download type is video only
      // and output file deletion is requested (Because video only downloads a single output file)
      // then delete it
    } else if (queueObject.downloadType == DownloadType.VideoOnly &&
        cleanOutFile) {
      String path = '${downloads.path}/${queueObject.validTitle}.mp4';
      File file = File(path);

      try {
        await file.delete();
      } catch (e) {}
      // Else (Video+Audio) delete the following:
      // - The audioless mp4 video file
      // - The webm audio file
      // - The output mp4 (Video+Audio) file (if requested when stopping the download)
    } else {
      String pathToVid = '${temps.path}/${queueObject.validTitle}.mp4';
      File vidfile = File(pathToVid);

      String pathToAud = '${temps.path}/${queueObject.validTitle}.webm';
      File audfile = File(pathToAud);

      String pathToOut = '${downloads.path}/${queueObject.validTitle}.mp4';
      File outfile = File(pathToOut);

      try {
        await vidfile.delete();
        await audfile.delete();
        if (cleanOutFile) {
          await outfile.delete();
        }
      } catch (e) {}
    }
  }
}
