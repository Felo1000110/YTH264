import 'package:flutter/material.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadOptions extends StatefulWidget {
  final YoutubeQueueObject? ytObj;

  DownloadOptions({super.key, required this.ytObj});

  @override
  State<DownloadOptions> createState() => _DownloadOptionsState();
}

class _DownloadOptionsState extends State<DownloadOptions>
    with TickerProviderStateMixin {
  List<String> _types = ["Muxed", "VideoOnly", "AudioOnly"];
  List<String> _typenames = ["Both", "Video only", "Audio only"];
  late List<String> _qualities;
  late List<VideoOnlyStreamInfo> _res;

  Set<String> _downloadType = {"Muxed"};
  Set<String>? _videoQuality = null;
  @override
  void initState() {
    super.initState();
  }

  Widget getVideoQualties() {
    _qualities = [
      widget.ytObj!.videoOnlyStreams.keys.first,
      widget.ytObj!.videoOnlyStreams.length < 6
          ? widget.ytObj!.videoOnlyStreams.keys.elementAt(1)
          : widget.ytObj!.videoOnlyStreams.keys.elementAt(2),
      widget.ytObj!.videoOnlyStreams.length < 6
          ? widget.ytObj!.videoOnlyStreams.keys.elementAt(2)
          : widget.ytObj!.videoOnlyStreams.keys.elementAt(4)
    ];

    _res = [
      widget.ytObj!.videoOnlyStreams.values.first,
      widget.ytObj!.videoOnlyStreams.length < 6
          ? widget.ytObj!.videoOnlyStreams.values.elementAt(1)
          : widget.ytObj!.videoOnlyStreams.values.elementAt(2),
      widget.ytObj!.videoOnlyStreams.length < 6
          ? widget.ytObj!.videoOnlyStreams.values.elementAt(2)
          : widget.ytObj!.videoOnlyStreams.values.elementAt(4)
    ];
    if (_videoQuality == null) {
      _videoQuality = {_qualities[0]};
    }
    if ((_downloadType.first == "Muxed" ||
            _downloadType.first == "VideoOnly") &&
        widget.ytObj!.videoOnlyStreams.length >= 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text('Video Quality',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: 27)),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 90, 8),
            child: Container(
                child: SegmentedButton(
              showSelectedIcon: false,
              onSelectionChanged: (p0) {
                setState(() {
                  widget.ytObj!.selectedStream =
                      widget.ytObj!.videoOnlyStreams[p0.first]!;
                  _videoQuality = p0;
                });
              },
              selected: _videoQuality!,
              segments: List.generate(
                  3,
                  (index) => ButtonSegment<String>(
                      value: _qualities[index],
                      label: Text(_qualities[index]))),
            )
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: List<Widget>.generate(
                //       3,
                //       (index) => ChoiceChip(
                //             backgroundColor:
                //                 Theme.of(context).colorScheme.onPrimary,
                //             side: BorderSide.none,
                //             materialTapTargetSize:
                //                 MaterialTapTargetSize.shrinkWrap,
                //             padding: EdgeInsets.symmetric(
                //                 horizontal: 12, vertical: 0),
                //             labelPadding: EdgeInsets.all(4.0),
                //             shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(20)),
                //             elevation: 0.0,
                //             showCheckmark: false,
                //             label: Text(
                //               _qualities[index],
                //               style: TextStyle(
                //                   fontWeight: FontWeight.w500,
                //                   fontSize: 16,
                //                   color: index == _videoQuality
                //                       ? Colors.white
                //                       : Colors.black),
                //             ),
                //             selected: index == _videoQuality,
                //             onSelected: (value) {
                //               setState(() {
                //                 _videoQuality = index;
                //                 widget.ytObj!.selectedStream = _res[index];
                //               });
                //               print(index);
                //             },
                //           )),
                // )
                ),
          )
        ],
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ytObj != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 150,
                      height: 84,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          widget.ytObj!.thumbnail,
                          fit: BoxFit.fill,
                        ),
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.ytObj!.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(widget.ytObj!.author)
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Download Type',
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 27)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton(
                            showSelectedIcon: false,
                            selected: _downloadType,
                            segments: List<ButtonSegment<String>>.generate(
                                3,
                                (index) => ButtonSegment<String>(
                                      value: _types[index],
                                      label: Text(_typenames[index]),
                                    )),
                            onSelectionChanged: (p0) {
                              setState(() {
                                _downloadType = p0;
                                widget.ytObj!.type = DownloadType.values
                                    .byName(_downloadType.first);
                              });
                            },
                          ),
                          // child: Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children:
                          // List<Widget>.generate(
                          //     3,
                          //     (index) => ChoiceChip(
                          //           backgroundColor: Theme.of(context)
                          //               .colorScheme
                          //               .onPrimary,
                          //           side: BorderSide.none,
                          //           materialTapTargetSize:
                          //               MaterialTapTargetSize.shrinkWrap,
                          //           padding: EdgeInsets.symmetric(
                          //               horizontal: 12, vertical: 0),
                          //           labelPadding: EdgeInsets.all(4.0),
                          //           shape: RoundedRectangleBorder(
                          //               borderRadius:
                          //                   BorderRadius.circular(20)),
                          //           elevation: 0.0,
                          //           showCheckmark: false,
                          //           label: Text(
                          //             _types[index],
                          //             style: TextStyle(
                          //                 fontWeight: FontWeight.bold,
                          //                 fontSize: 14,
                          //                 color: index == _downloadType
                          //                     ? Colors.white
                          //                     : Colors.black),
                          //           ),
                          //           selected: index == _downloadType,
                          //           onSelected: (value) {
                          //             setState(() {
                          //               _downloadType = index;
                          // widget.ytObj!.type = DownloadType
                          //     .values[_downloadType];
                          //             });
                          //             print(_downloadType);
                          //           },
                          //         )),
                          // )
                        ),
                      ),
                      getVideoQualties(),
                      const SizedBox(height: 80),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop<QueueObject>(widget.ytObj);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          child: Container(
                            width: double.infinity,
                            height: 43,
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Center(
                              child: Text('Add to Queue',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                            ),
                          ),
                        ),
                      )
                    ]),
              ),
            ]),
      );
    } else {
      return Container();
    }
  }
}
