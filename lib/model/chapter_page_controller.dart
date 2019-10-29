import 'package:flutter/material.dart';

import '../api/api_manager.dart';
import '../database/search_item.dart';
import '../database/search_item_manager.dart';

class ChapterPageController with ChangeNotifier {
  final Size size;
  final SearchItem searchItem;
  ScrollController _controller;
  ScrollController get controller => _controller;

  bool get isLoading => _isLoading;
  bool _isLoading;

  static const BigList = ChapterListStyle.BigList;
  static const SmallList = ChapterListStyle.SmallList;
  static const Grid = ChapterListStyle.Grid;

  String getListStyleName([ChapterListStyle listStyle]) {
    if (listStyle == null) {
      listStyle = searchItem.chapterListStyle;
    }
    switch (listStyle) {
      case BigList:
        return "大列表";
      case SmallList:
        return "小列表";
      case Grid:
        return "宫格";
      default:
        return "宫格";
    }
  }

  ChapterPageController({@required this.searchItem, @required this.size}) {
    _controller = ScrollController(initialScrollOffset: _calcHeight);
    _isLoading = false;
    if (searchItem.chapters == null) {
      _isLoading = true;
      initChapters();
    } else if (searchItem.chapters?.length == 0 &&
        SearchItemManager.isFavorite(searchItem.url)) {
      searchItem.chapters = SearchItemManager.getChapter(searchItem.id);
    }
  }

  double get _calcHeight {
    if(searchItem.chapters == null) return 0.0;
    double itemHeight;
    int lineNum;
    switch (searchItem.chapterListStyle) {
      case BigList:
        lineNum = 1;
        itemHeight = 66;
        break;
      case SmallList:
        lineNum = 2;
        itemHeight = 52;
        break;
      case Grid:
        lineNum = 5;
        itemHeight = 47;
        break;
    }
    final durHeight = searchItem.durChapterIndex ~/ lineNum * itemHeight;
    double height = searchItem.chapters.length ~/ lineNum * itemHeight;
    if (searchItem.chapters.length % lineNum > 0) {
      height += itemHeight;
    }
    final screenHeight = size.height - 246;
    if (height < screenHeight) {
      return 1.0;
    }
    if ((height - durHeight) < screenHeight) {
      return height - screenHeight;
    }
    return durHeight;
  }

  void adjustScroll() {
    _controller.jumpTo(_calcHeight);
  }

  void initChapters() async {
    searchItem.chapters =
        await APIManager.getChapter(searchItem.originTag, searchItem.url);
    searchItem.durChapterIndex = 0;
    searchItem.durContentIndex = 1;
    searchItem.durChapter = searchItem.chapters.first?.name;
    searchItem.chaptersCount = searchItem.chapters.length;
    searchItem.chapter = searchItem.chapters.last?.name;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateChapter() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    searchItem.chapters =
        await APIManager.getChapter(searchItem.originTag, searchItem.url);
    searchItem.chaptersCount = searchItem.chapters.length;
    searchItem.chapter = searchItem.chapters.last?.name;
    if (SearchItemManager.isFavorite(searchItem.url)) {
      await SearchItemManager.saveChapter(searchItem.id, searchItem.chapters);
    }
    _isLoading = false;
    notifyListeners();
    return;
  }

  void changeChapter(int index) async {
    if (searchItem.durChapterIndex != index) {
      searchItem.durChapterIndex = index;
      searchItem.durChapter = searchItem.chapters[index].name;
      searchItem.durContentIndex = 1;
      await SearchItemManager.saveSearchItem();
      notifyListeners();
    }
  }

  void toggleFavorite() async {
    if (_isLoading) return;
    await SearchItemManager.toggleFavorite(searchItem);
    notifyListeners();
  }

  void scrollerToTop() {
    _controller.jumpTo(1);
  }

  void scrollerToBottom() {
    _controller.jumpTo(_controller.position.maxScrollExtent - 1);
  }

  void toggleReverse() {
    searchItem.reverseChapter = !searchItem.reverseChapter;
    notifyListeners();
  }

  void changeListStyle(ChapterListStyle listStyle) async {
    if (searchItem.chapterListStyle != listStyle) {
      searchItem.chapterListStyle = listStyle;
      await SearchItemManager.saveSearchItem();
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 20));
    }
    adjustScroll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

enum ChapterListStyle {
  BigList,
  SmallList,
  Grid,
}
