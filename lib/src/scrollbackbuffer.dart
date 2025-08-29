import 'dart:io';

/// The ScrollbackBuffer class is a utility for handling multi-line user
/// input in readline(). It now supports a persistent history by saving
/// and loading the command history to a file.
class ScrollbackBuffer {
  final List<String> lineList = <String>[];
  int? lineIndex;
  String? currentLineBuffer;
  bool recordBlanks;
  final String _historyFilePath;

  // called by Console.scrolling()
  ScrollbackBuffer({required this.recordBlanks, String historyFilePath = '.console_history'})
      : _historyFilePath = historyFilePath {
    _loadHistory();
  }

  void _loadHistory() {
    final historyFile = File(_historyFilePath);
    if (historyFile.existsSync()) {
      lineList.addAll(historyFile.readAsLinesSync());
      lineIndex = lineList.length;
    }
  }

  void _appendToHistory(String buffer) {
    final historyFile = File(_historyFilePath);
    historyFile.writeAsStringSync('$buffer\n', mode: FileMode.append);
  }

  /// Add a new line to the scrollback buffer. This would normally happen
  /// when the user finishes typing/editing the line and taps the 'enter'
  /// key. This also appends the line to the persistent history file.
  void add(String buffer) {
    // don't add blank line to scrollback history if !recordBlanks
    if (buffer.trim().isEmpty && !recordBlanks) {
      return;
    }
    lineList.add(buffer);
    _appendToHistory(buffer);
    lineIndex = lineList.length;
    currentLineBuffer = null;
  }

  /// Scroll 'up' -- Replace the user-input buffer with the contents of the
  /// previous line. ScrollbackBuffer tracks which lines are the 'current'
  /// and 'previous' lines. The up() method stores the current line buffer
  /// so that the contents will not be lost in the event the user starts
  /// typing/editing the line and then wants to review a previous line.
  String up(String buffer) {
    // Handle the case of the user tapping 'up' before there is a
    // scrollback buffer to scroll through.
    if (lineList.isEmpty) {
      return buffer;
    }

    lineIndex ??= lineList.length;

    // Only store the current line buffer once while scrolling up
    currentLineBuffer ??= buffer;
    lineIndex = lineIndex! - 1;
    if (lineIndex! < 0) {
      lineIndex = 0;
    }
    return lineList[lineIndex!];
  }

  /// Scroll 'down' -- Replace the user-input buffer with the contents of
  /// the next line. The final 'next line' is the original contents of the
  /// line buffer.
  String? down() {
    // Handle the case of the user tapping 'down' before there is a
    // scrollback buffer to scroll through.
    if (lineIndex == null || lineList.isEmpty) {
      return null;
    } else {
      lineIndex = lineIndex! + 1;
      if (lineIndex! >= lineList.length) {
        lineIndex = lineList.length;
        // Once the user scrolls to the bottom, reset the current line
        // buffer so that up() can store it again: The user might have
        // edited it between down() and up().
        final temp = currentLineBuffer;
        currentLineBuffer = null;
        return temp;
      } else {
        return lineList[lineIndex!];
      }
    }
  }
}
