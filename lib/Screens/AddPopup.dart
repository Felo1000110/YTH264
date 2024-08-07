import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:flutter/material.dart';
import 'package:YT_H264/Screens/DownloadOptions.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:YT_H264/Services/Youtube.dart';
import 'package:clipboard/clipboard.dart';

// ignore: must_be_immutable
class AddModalPopup extends StatefulWidget {
  String? uri;
  AddModalPopup({super.key, this.uri});

  @override
  State<AddModalPopup> createState() => _AddModalPopupState();
}

class _AddModalPopupState extends State<AddModalPopup> {
  final TextEditingController _uriController = TextEditingController();
  Widget? downloadButton;
  bool isSearching = false;
  YoutubeQueueObject? vidInfo;

  @override
  void initState() {
    _uriController.addListener(() {
      if (!isSearching) {
        if (_uriController.text.length == 0) {
          setState(() {
            downloadButton = Icon(
              Icons.paste,
              color: Theme.of(context).colorScheme.onPrimary,
            );
          });
        } else {
          setState(() {
            downloadButton = Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onPrimary,
            );
          });
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> search() async {
    if (_uriController.text != '') {
      try {
        setState(() {
          isSearching = true;
          downloadButton = Center(
            child: Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary)),
            ),
          );
        });
        YoutubeService serv = YoutubeService();
        vidInfo = await serv.getVidInfo(_uriController.text).then((value) {
          setState(() {
            isSearching = false;
            downloadButton = Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onPrimary,
            );
          });
          return value;
        });
        print(vidInfo!.title);
        setState(() {});
      } catch (e) {
        downloadButton = Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.onPrimary,
        );
        GlobalMethods.snackBarError(e.toString(), context, isException: true);
      }
    } else {
      FlutterClipboard.paste().then((value) {
        setState(() {
          _uriController.text = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    downloadButton = downloadButton ??
        Icon(Icons.paste, color: Theme.of(context).colorScheme.onPrimary);
    if (widget.uri != null) {
      _uriController.text = widget.uri!;
      widget.uri = null;
      print('Share Detected');
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) async => search(),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20)),
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: TextFormField(
                            style: Theme.of(context).textTheme.bodyLarge,
                            maxLines: 1,
                            controller: _uriController,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 13.0, horizontal: 16.0),
                                hintStyle:
                                    Theme.of(context).textTheme.bodyLarge,
                                hintText: 'Enter Youtube URL',
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                        width: 1.5,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20))),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: SizedBox(
                          height: 50,
                          width: 50,
                          child: IconButton.filled(
                            onPressed: () async {
                              await search();
                            },
                            icon: downloadButton!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  DownloadOptions(
                    ytObj: vidInfo,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
