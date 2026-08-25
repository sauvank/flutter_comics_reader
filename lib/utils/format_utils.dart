// Utility functions for string sorting, byte formatting, and time helpers

class NaturalSort {
  /// Sorts a list of strings naturally (e.g., 'page2.jpg' before 'page10.jpg')
  static int compare(String a, String b) {
    final regex = RegExp(r'(\d+|\D+)');
    final matchesA = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = regex.allMatches(b).map((m) => m.group(0)!).toList();

    final minLength = matchesA.length < matchesB.length ? matchesA.length : matchesB.length;

    for (int i = 0; i < minLength; i++) {
      final chunkA = matchesA[i];
      final chunkB = matchesB[i];

      final numA = int.tryParse(chunkA);
      final numB = int.tryParse(chunkB);

      if (numA != null && numB != null) {
        if (numA != numB) {
          return numA.compareTo(numB);
        }
      } else {
        final comp = chunkA.toLowerCase().compareTo(chunkB.toLowerCase());
        if (comp != 0) {
          return comp;
        }
      }
    }

    return matchesA.length.compareTo(matchesB.length);
  }
}

class FormatUtils {
  /// Formats byte sizes into human readable strings (e.g. 15.4 MB, 1.2 GB)
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Formats download speed (e.g. 4.5 MB/s)
  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    return '${formatBytes(bytesPerSec.toInt())}/s';
  }

  /// Formats duration (e.g. "Il y a 2 jours", "Hier", "Aujourd'hui")
  static String formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 30) {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return 'Il y a $weeks sem.';
    } else if (diff.inDays >= 2) {
      return 'Il y a ${diff.inDays} jours';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inHours >= 1) {
      return 'Il y a ${diff.inHours} h';
    } else if (diff.inMinutes >= 1) {
      return 'Il y a ${diff.inMinutes} min';
    } else {
      return 'À l\'instant';
    }
  }
}
