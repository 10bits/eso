import 'dart:convert';

import 'package:eso/api/api.dart';
import 'package:eso/ui/ui_chapter_select.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/search_item.dart';
import '../global.dart';
import '../model/content_page_controller.dart';
import '../ui/ui_dash.dart';
import 'langding_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentPage extends StatefulWidget {
  final SearchItem searchItem;

  const ContentPage({
    this.searchItem,
    Key key,
  }) : super(key: key);

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  Widget page;
  ContentPageController __pageController;
  @override
  Widget build(BuildContext context) {
    if (page == null) {
      page = buildPage();
    }
    return page;
  }

  @override
  void dispose() {
    __pageController?.dispose();
    super.dispose();
  }

  Widget buildPage() {
    return ChangeNotifierProvider<ContentPageController>.value(
      value: ContentPageController(searchItem: widget.searchItem),
      child: Scaffold(
        body: Consumer<ContentPageController>(
          builder:
              (BuildContext context, ContentPageController pageController, _) {
            if (pageController.content == null) {
              return LandingPage();
            }
            return GestureDetector(
              child: Stack(
                children: <Widget>[
                  NotificationListener(
                    child: (() {
                      switch (widget.searchItem.ruleContentType) {
                        case API.MANGA:
                          return _MangaContentPage(
                              pageController: pageController);
                        case API.NOVEL:
                          return _NovelContentPage(
                              pageController: pageController);
                        case API.RSS:
                          return _RSSContentPage(
                              pageController: pageController);
                        default:
                          throw ('${widget.searchItem.ruleContentType} not support');
                      }
                    })(),
                    onNotification: (t) {
                      if (t is ScrollEndNotification) {
                        pageController.refreshProgress();
                      }
                      return false;
                    },
                  ),
                  pageController.showChapter
                      ? UIChapterSelect(
                          searchItem: widget.searchItem,
                          loadChapter: pageController.loadChapter,
                        )
                      : Container(),
                ],
              ),
              onLongPressUp: () {},
              onTapUp: (TapUpDetails details) {
                final size = MediaQuery.of(context).size;
                if (details.globalPosition.dx > size.width * 3 / 8 &&
                    details.globalPosition.dx < size.width * 5 / 8 &&
                    details.globalPosition.dy > size.height * 3 / 8 &&
                    details.globalPosition.dy < size.height * 5 / 8) {
                  pageController.showChapter = true;
                } else {
                  pageController.showChapter = false;
                }
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _buildChapterSeparate(
    Color color, double screenHeight, bool isLoading, SearchItem searchItem) {
  return Container(
    alignment: Alignment.topLeft,
    padding: EdgeInsets.only(
      top: 80,
      left: 32,
      right: 10,
      bottom: screenHeight - 200,
    ),
    child: Text(
      searchItem.durChapterIndex == searchItem.chapters.length - 1
          ? "当前章节\n${searchItem.durChapter}\n\n已经是最后一章"
          : isLoading
              ? "当前章节\n${searchItem.durChapter}\n\n正在加载..."
              : "当前章节\n${searchItem.durChapter}\n\n继续滑动加载下一章",
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 2,
        color: color,
      ),
    ),
  );
}

class _RSSContentPage extends StatefulWidget {
  final ContentPageController pageController;

  _RSSContentPage({
    this.pageController,
    Key key,
  }) : super(key: key);

  @override
  __RSSContentPageState createState() => __RSSContentPageState();
}

class __RSSContentPageState extends State<_RSSContentPage> {
  WebViewController _controller;
  Widget _webView;
  int _durChapterIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageController.searchItem.durChapter),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => widget.pageController.showChapter =
                !widget.pageController.showChapter,
          ),
        ],
      ),
      body: _buildWebView(),
    );
  }

  WebView _buildWebView() {
    String contentBase64 = base64.encode(utf8.encode(
        '<meta charset="UTF-8"><style>img{max-width:100%}</style>${widget.pageController.content.join('\n')}'));
    if (_controller != null &&
        _durChapterIndex != widget.pageController.searchItem.durChapterIndex) {
      _durChapterIndex = widget.pageController.searchItem.durChapterIndex;
      _controller.loadUrl('data:text/html;base64,$contentBase64');
    }
    if (_webView == null) {
      _webView = WebView(
        onWebViewCreated: (WebViewController controller) =>
            _controller = controller,
        initialUrl: 'data:text/html;base64,$contentBase64',
      );
      _durChapterIndex = widget.pageController.searchItem.durChapterIndex;
    }
    return _webView;
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }
}

class _MangaContentPage extends StatelessWidget {
  final ContentPageController pageController;

  const _MangaContentPage({
    this.pageController,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView.builder(
          cacheExtent: double.infinity,
          padding: EdgeInsets.all(0),
          controller: pageController.controller,
          itemCount: pageController.content.length + 1,
          itemBuilder: (context, index) {
            if (index == pageController.content.length) {
              return _buildChapterSeparate(
                  null,
                  MediaQuery.of(context).size.height,
                  pageController.isLoading,
                  pageController.searchItem);
            }
            return FadeInImage(
              placeholder: AssetImage(Global.waitingPath),
              image: NetworkImage(
                "${pageController.content[index]}",
                headers: pageController.headers,
              ),
              fit: BoxFit.fitWidth,
            );
          },
        ),
        Positioned(
          right: 10,
          bottom: 0,
          child: Container(
            color: Colors.black.withAlpha(0x80),
            child: Text(
              '${pageController.searchItem.durChapter} ${pageController.content.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _NovelContentPage extends StatelessWidget {
  final ContentPageController pageController;

  const _NovelContentPage({
    this.pageController,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5DEB3),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 80),
              controller: pageController.controller,
              itemCount: pageController.content.length + 2,
              itemBuilder: (context, index) {
                if (index == pageController.content.length + 1) {
                  return _buildChapterSeparate(
                      Colors.black87,
                      MediaQuery.of(context).size.height,
                      pageController.isLoading,
                      pageController.searchItem);
                }
                if (index == 0) {
                  return Text(
                    '${pageController.searchItem.durChapter}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  );
                }
                return Text(
                  pageController.content[index - 1],
                  style: TextStyle(
                    fontSize: 20,
                    height: 2,
                    color: Colors.black,
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 4,
          ),
          UIDash(
            height: 2,
            dashWidth: 6,
            color: Colors.black38,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${pageController.searchItem.durChapter}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${pageController.progress}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
