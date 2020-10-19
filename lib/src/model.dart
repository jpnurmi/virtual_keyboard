part of virtual_keyboard;

extension _CodePoint on int {
  // Returns true if |code_point| is a leading surrogate of a surrogate pair.
  bool get isLeadingSurrogate => (this & 0xFFFFFC00) == 0xD800;

  // Returns true if |code_point| is a trailing surrogate of a surrogate pair.
  bool get isTrailingSurrogate => (this & 0xFFFFFC00) == 0xDC00;
}

extension _TextSelectionPosition on TextSelection {
  int get position {
    assert(start == end);
    return start;
  }
}

class VirtualKeyboardModel {
  String _text = '';
  TextSelection _selection = TextSelection.collapsed(offset: 0);

  String get text => _text;
  set text(String text) {
    _text = text;
    _selection = TextSelection.collapsed(offset: 0);
  }

  TextSelection get selection => _selection;
  set selection(TextSelection selection) {
    if (_selection.start < 0 || _selection.end >= _text.length) {
      return;
    }
    _selection = selection;
  }

  int get cursorOffset {
    // Measure the length of the current text up to the selection extent.
    // There is probably a much more efficient way of doing this.
    final leadingText = _text.substring(0, _selection.extent.offset);
    return leadingText.length;
  }

  void addCodePoint(int codePoint) {
    if (codePoint <= 0xFFFF) {
      addText(String.fromCharCode(codePoint));
    } else {
      final toDecompose = codePoint - 0x10000;
      addText(String.fromCharCodes([
        // High surrogate.
        (toDecompose >> 10) + 0xd800,
        // Low surrogate.
        (toDecompose % 0x400) + 0xdc00,
      ]));
    }
  }

  bool addText(String text) {
    deleteSelected();
    final position = _selection.position;
    _text = _text.replaceRange(position, position, text);
    _selection = TextSelection.collapsed(offset: position + text.length);
    return true;
  }

  bool deleteSelected() {
    if (_selection.isCollapsed) {
      return false;
    }
    _text = _text.replaceRange(_selection.start, _selection.end, '');
    _selection = TextSelection.collapsed(offset: _selection.start);
    return true;
  }

  bool delete() {
    if (deleteSelected()) {
      return true;
    }
    // If there's no selection, delete the preceding codepoint.
    final position = _selection.position;
    if (position != _text.length) {
      final count = _text.codeUnitAt(position).isLeadingSurrogate ? 2 : 1;
      _text = _text.replaceRange(position, position + count, '');
      return true;
    }
    return false;
  }

  bool backspace() {
    if (deleteSelected()) {
      return true;
    }
    // If there's no selection, delete the preceding codepoint.
    final position = _selection.position;
    if (position != 0) {
      final count = _text.codeUnitAt(position - 1).isTrailingSurrogate ? 2 : 1;
      _text = _text.replaceRange(position - count, position, '');
      _selection = TextSelection.collapsed(offset: position - count);
      return true;
    }
    return false;
  }

  bool deleteSurrounding(int offsetFromCursor, int count) {
    var start = _selection.extentOffset;
    if (offsetFromCursor < 0) {
      for (int i = 0; i < -offsetFromCursor; i++) {
        // If requested start is before the available text then reduce the
        // number of characters to delete.
        if (start == 0) {
          count = i;
          break;
        }
        start -= _text.codeUnitAt(start - 1).isTrailingSurrogate ? 2 : 1;
      }
    } else {
      for (int i = 0; i < offsetFromCursor && start != _text.length; i++) {
        start += _text.codeUnitAt(start).isLeadingSurrogate ? 2 : 1;
      }
    }

    var end = start;
    for (int i = 0; i < count && end != _text.length; i++) {
      end += _text.codeUnitAt(start).isLeadingSurrogate ? 2 : 1;
    }

    if (start == end) {
      return false;
    }

    _text = _text.replaceRange(start, end, '');

    // Cursor moves only if deleted area is before it.
    _selection = TextSelection.collapsed(
        offset: offsetFromCursor <= 0 ? start : _selection.start);

    return true;
  }

  bool moveCursorToBeginning() {
    if (_selection.isCollapsed && _selection.position == 0) {
      return false;
    }
    selection = TextSelection.collapsed(offset: 0);
    return true;
  }

  bool moveCursorToEnd() {
    final maxPos = _text.length;
    if (_selection.isCollapsed && _selection.position == maxPos) {
      return false;
    }
    _selection = TextSelection.collapsed(offset: maxPos);
    return true;
  }

  bool moveCursorForward() {
    // If there's a selection, move to the end of the selection.
    if (!_selection.isCollapsed) {
      _selection = TextSelection.collapsed(offset: _selection.end);
      return true;
    }
    // Otherwise, move the cursor forward.
    final position = _selection.position;
    if (position != _text.length) {
      final count = _text.codeUnitAt(position).isLeadingSurrogate ? 2 : 1;
      _selection = TextSelection.collapsed(offset: position + count);
      return true;
    }
    return false;
  }

  bool moveCursorBack() {
    // If there's a selection, move to the beginning of the selection.
    if (!_selection.isCollapsed) {
      _selection = TextSelection.collapsed(offset: _selection.start);
      return true;
    }
    // Otherwise, move the cursor backward.
    final position = _selection.position;
    if (position != 0) {
      final count = _text.codeUnitAt(position - 1).isTrailingSurrogate ? 2 : 1;
      _selection = TextSelection.collapsed(offset: position - count);
      return true;
    }
    return false;
  }
}
