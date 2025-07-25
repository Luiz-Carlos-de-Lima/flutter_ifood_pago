import 'package:flutter_ifood_pago/constants/ifood_pago_print_content_types.dart';

class IfoodPagoContentprint {
  final IfoodPagoPrintType type;
  final String? content;
  final IfoodPagoPrintAlign? align;
  final IfoodPagoPrintSize? size;
  final String? imagePath;
  final bool ignoreLineBreak;

  IfoodPagoContentprint({required this.type, this.content, this.align, this.size = IfoodPagoPrintSize.medium, this.imagePath, this.ignoreLineBreak = false})
    : assert(
        type != IfoodPagoPrintType.text || (content is String && align is IfoodPagoPrintAlign && size is IfoodPagoPrintSize),
        "content, align, and size must be defined when type is text",
      ),
      assert(type != IfoodPagoPrintType.image || imagePath is String, "imagePath cannot be null when type is image"),
      assert(type != IfoodPagoPrintType.line || content is String, "content cannot be null when type is line");

  /// Método para formatar o conteúdo evitando cortes no meio das palavras e tratando palavras maiores que o limite da linha.
  String formatContent() {
    if (ignoreLineBreak == true) {
      return content ?? '';
    }
    if (type == IfoodPagoPrintType.image || content == null || size == null) return content ?? '';

    int maxLength = _getMaxLength(size!);
    List<String> lines = [];
    List<String> words = content!.split(' ');
    String currentLine = '';

    for (var word in words) {
      if (word.length > maxLength) {
        // Se a palavra for maior que o limite da linha, quebra a palavra
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = '';
        }

        // Divide a palavra em partes do tamanho máximo permitido
        for (int i = 0; i < word.length; i += maxLength) {
          lines.add(word.substring(i, (i + maxLength) > word.length ? word.length : (i + maxLength)));
        }
      } else if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + word.length + 1) <= maxLength) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.join("\n");
  }

  /// Retorna o tamanho máximo de caracteres permitido para cada tamanho de impressão
  int _getMaxLength(IfoodPagoPrintSize size) {
    switch (size) {
      case IfoodPagoPrintSize.small:
        return 48;
      case IfoodPagoPrintSize.medium:
      case IfoodPagoPrintSize.big:
        return 32;
    }
  }

  Map<String, dynamic> toJson() {
    bool disableAlignAndSize = type != IfoodPagoPrintType.text;

    return {
      'type': type.name.toString(),
      'content': type != IfoodPagoPrintType.image ? formatContent() : null,
      'align': disableAlignAndSize ? null : align?.name.toString(),
      'size': disableAlignAndSize ? null : size?.name.toString(),
      'imagePath': type == IfoodPagoPrintType.image ? imagePath : null,
    };
  }

  static IfoodPagoContentprint fromJson(Map<String, dynamic> json) {
    return IfoodPagoContentprint(
      type: IfoodPagoPrintType.values.firstWhere((e) => e.name == json['type']),
      content: json['content'],
      align: json['align'] != null ? IfoodPagoPrintAlign.values.firstWhere((e) => e.name == json['align']) : null,
      size: IfoodPagoPrintSize.values.firstWhere((e) => e.name == json['size']),
      imagePath: json['imagePath'],
    );
  }
}
