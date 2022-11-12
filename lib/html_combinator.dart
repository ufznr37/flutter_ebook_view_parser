import 'dart:typed_data';

import 'package:epub_parser/epub_parser.dart';

class HtmlCombinator {
  HtmlCombinator(this.base);

  final String base;
  String _result = '';

  final String meta = """<meta name="viewport" content="width=device-width, initial-scale=1.0">""";

  String get result => _result;

  void init(Map<String, EpubByteContentFile>? images, Map<String, EpubTextContentFile>? css) {
    _result = addMeta(base);
    _result = addXImage(_result, images);
    _result = addImage(_result, images);
    _result = addCss(_result, css);
    _result = addScript(_result);
  }

  String addMeta(String base) {
    return base.replaceFirst('</head>', "$meta\n</head>");
  }

  String addCss(String base, Map<String, EpubTextContentFile>? mapCss) {
    if (mapCss != null) {
      String tempCss = '';
      mapCss.forEach((key, value) {
        final css = value.Content;
        if (css != null) {
          tempCss += """\n$css\n""";
        }
      });
      if (base.contains("</style>")) {
        return base.replaceFirst("</style>", """$tempCss\n</style>""");
      } else {
        return base.replaceFirst("</head>", """<style>$tempCss\n</style>\n</head>""");
      }
    } else {
      return base;
    }
  }

  String addScript(String base) {
    final js = """var element = document.getElementsByTagName("body")[0];
element.addEventListener('touchmove', function(e) { Print.postMessage("MOVE"); }, { passive: false });
element.addEventListener('touchend', function() { Print.postMessage("END");
if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
        Print.postMessage("BOTTOM");
    } });""";
    if (base.contains("</script>")) {
      return base.replaceFirst("</script>", "$js\n</script>");
    } else {
      return base.replaceFirst("</body>", "\n<script>\n$js\n</script>\n</body>");
    }
  }

  String addXImage(String base, Map<String, EpubByteContentFile>? images) {
    if (images != null) {
      String temp = base;
      String imageScript = "";
      var regexp = RegExp(r"""(?<=xlink:href=").+?(?=")""");
      if (regexp.hasMatch(base)) {
        final matches = regexp.allMatches(base).map((e) => e.group(0)).toList();
        int count = 0;
        matches.forEach((imgName) {
          if (imgName != null) {
            final key = getKey(imgName, images);
            if (key != null) {
              final img = images[key];
              final id = "xImage$count";
              final addId = temp.replaceAll(
                  "$imgName\"", "$imgName\" id=\"$id\"");
              final content = img?.Content;
              if (content != null) {
                final uint = Uint8List.fromList(content);
                imageScript += xImgScript(count, uint, id);
                temp = addId; // base html with image id
              }
            }
          }
          count++;
        });
        if (imageScript.isNotEmpty) {
          if (temp.contains("</script>")) {
            temp = temp.replaceFirst("</script>", """$imageScript\n</script>""");
          } else {
            temp = temp.replaceFirst(
                "</body>", """\n<script>$imageScript</script></body>""");
          }
        }
      }
      return temp;
    } else {
      return base;
    }
  }

  String addImage(String base, Map<String, EpubByteContentFile>? images) {
    if (images != null) {
      String temp = base;
      String imageScript = "";
      var regexp = RegExp(r"""(?<=src=").+?(?=")""");
      if (regexp.hasMatch(base)) {
        final matches = regexp.allMatches(base).map((e) => e.group(0)).toList();
        int count = 0;
        matches.forEach((imgName) {
          if (imgName != null) {
            final key = getKey(imgName, images);
            if (key != null) {
              final img = images[key];
              final id = "image$count";
              final addId = temp.replaceFirst(
                  "$imgName\"", "$id\" id=\"$id\"");
              final content = img?.Content;
              if (content != null) {
                final uint = Uint8List.fromList(img!.Content!);
                imageScript += imgScript(count, uint, id);
                temp = addId; // base html with image id
              }
            }
          }
          count++;
        });
        if (imageScript.isNotEmpty) {
          if (temp.contains("</script>")) {
            temp = temp.replaceFirst("</script>", """$imageScript\n</script>""");
          } else {
            temp = temp.replaceFirst(
                "</body>", """\n<script>$imageScript</script></body>""");
          }
        }
      }
      return temp;
    } else {
      return base;
    }
  }

  String? getKey(String name, Map<String, EpubByteContentFile>? images) {
    final result = images?.keys.firstWhere((e) => e.contains(name), orElse: () => '');
    if (result == null || result.isEmpty) {
      return null;
    } else {
      return result;
    }
  }

  String xImgScript(int count, Uint8List uint, String id) {
    return """\tconst xImg$count = new Uint8Array($uint);
    document.getElementById("$id")?.setAttributeNS('http://www.w3.org/1999/xlink', 'xlink:href', URL.createObjectURL(
    new Blob([xImg$count.buffer], { type: 'image/png' })
  ));
""";
  }

  String imgScript(int count, Uint8List uint, String id) {
    return """\tconst img$count = new Uint8Array($uint);
    document.getElementById("$id").src = URL.createObjectURL(
    new Blob([img$count.buffer], { type: 'image/png' }));
""";
  }
}