import 'package:flutter/widgets.dart';

import '../models/book_item.dart';
import '../widgets/synced_reader_gate.dart';
import 'cbz_reader_screen.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

Widget buildSyncedReaderScreen(BookItem book) => SyncedReaderGate(
      book: book,
      readerBuilder: (syncedBook) {
        if (syncedBook.format == BookFormat.pdf) {
          return PdfReaderScreen(book: syncedBook);
        }
        if (syncedBook.format == BookFormat.epub) {
          return EpubReaderScreen(book: syncedBook);
        }
        return CbzReaderScreen(book: syncedBook);
      },
    );
