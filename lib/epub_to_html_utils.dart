
import 'package:epub_parser/epub_parser.dart';
import 'package:flutter_ebook_view_parser/file_management_utils.dart';

import 'html_combinator.dart';

class EpubToHtmlHelper {

  Map<String, EpubByteContentFile>? images;
  Map<String, EpubTextContentFile>? html;

  Future<String> test(String fileName) async {
    final uInt = await FileManagementUtils.toUint8List(fileName);

    List<int> list = uInt.cast<int>();

    final epubBook = await EpubReader.readBook(list);
    this.images = epubBook.Content?.Images;
    html = epubBook.Content?.Html;

    // test
    // final html2 = epubBook.Content?.Html!["titlepage.xhtml"]!.Content;
    // final html2 = epubBook.Content?.Html!["index.html"]!.Content;

    // alice
    // final html2 = epubBook.Content?.Html!["chapter01.xhtml"]!.Content;

    // sample1
    // final html2 = epubBook.Content?.Html!["OEBPS/cover.xml"]!.Content;
    final html2 = epubBook.Chapters![0].HtmlContent;
    // final html2 = epubBook.Chapters![1].HtmlContent;
    // epubBook.Schema?.Package?.Spine?.Items; => order
    // epubBook.Schema?.Package?.Manifest?.Items; => which json
    // json Href -> filename
    if (html2 != null) {
      final combinator = HtmlCombinator(html2);
      combinator.init(epubBook.Content!.Images!, epubBook.Content!.Css!);
      return combinator.result;
    }
    return '';
  }
}