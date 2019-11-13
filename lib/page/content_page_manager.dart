import 'package:eso/api/api.dart';
import 'package:eso/database/search_item.dart';
import 'package:eso/page/audio_page.dart';
import 'package:eso/page/content_page.dart';
import 'package:eso/page/novel_page.dart';
import 'package:eso/page/video_page.dart';
import 'package:flutter/material.dart';

class ContentPageRoute {
  MaterialPageRoute route(SearchItem searchItem) {
    return MaterialPageRoute(
      builder: (context) {
        switch (searchItem.ruleContentType) {
          case API.NOVEL:
            return NovelPage(searchItem: searchItem);
          case API.MANGA:
          case API.RSS:
            return ContentPage(searchItem: searchItem);
            break;
          case API.VIDEO:
            return VideoPage(searchItem: searchItem);
            break;
          case API.AUDIO:
            return AudioPage(searchItem: searchItem);
            break;
          default:
            throw ('${searchItem.ruleContentType} not support !');
        }
      },
    );
  }
}
