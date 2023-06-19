import 'package:flutter/material.dart';

import '../model/cartabook.dart';
import '../shared/settings.dart';

enum ScreenLayout { library, split, book }

// book view
enum BookPanelView { bookInfo, bookText }

class ScreenConfig extends ChangeNotifier {
  late ScreenLayout _layout;
  BookPanelView _panelView = BookPanelView.bookInfo;
  CartaBook? _selectedBook;

  ScreenConfig() {
    _layout = isScreenWide ? ScreenLayout.split : ScreenLayout.library;
  }

  void setLayout(ScreenLayout newLayout) {
    _layout = newLayout;
    notifyListeners();
  }

  void setPanelView(BookPanelView newView) {
    _panelView = newView;
    notifyListeners();
  }

  void setBook(CartaBook? newBook) {
    _selectedBook = newBook;
    // always return to the book info view
    _panelView = BookPanelView.bookInfo;
    notifyListeners();
  }

  ScreenLayout get layout {
    return _layout;
  }

  BookPanelView get panelView {
    return _panelView;
  }

  CartaBook? get book {
    return _selectedBook;
  }
}
