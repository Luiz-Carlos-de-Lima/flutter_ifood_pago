import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_ifood_pago/constants/ifood_pago_print_content_types.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_content_print.dart';
import 'package:image/image.dart' as img;

class IfoodPagoPrinterService {
  static const double maxWidth = 384.0;
  static const double defaultSpacing = 8.0;

  /// Método principal para gerar conteúdo imprimível em base64
  Future<String> renderPrintableContentToBase64(List<IfoodPagoContentprint> contentList) async {
    try {
      // 1. Construir o layout
      final lines = _buildLayout(contentList);

      // 2. Renderizar o conteúdo
      final imageBytes = await _renderContent(lines);

      // 3. Processar a imagem (opcional)
      final processedImage = _processImage(imageBytes);

      return base64Encode(processedImage);
    } catch (e) {
      debugPrint('Erro ao gerar conteúdo: $e');
      rethrow;
    }
  }

  /// Construir o layout a partir do conteúdo
  List<_PrintableLine> _buildLayout(List<IfoodPagoContentprint> contentList) {
    final lines = <_PrintableLine>[];

    for (final item in contentList) {
      if (item.type == IfoodPagoPrintType.image && item.imagePath != null) {
        lines.add(_PrintableLine.image(item.imagePath!));
      } else {
        final formatted = item.ignoreLineBreak ? (item.content ?? '') : item.formatContent();
        final splitLines = formatted.split('\n');

        for (final lineText in splitLines) {
          lines.add(
            _PrintableLine(
              text: lineText,
              fontSize: _getFontSize(item.size ?? IfoodPagoPrintSize.medium),
              align: item.align ?? IfoodPagoPrintAlign.left,
              fontWeight: FontWeight.bold,
            ),
          );
        }
      }
    }

    return lines;
  }

  /// Renderizar o conteúdo em uma imagem
  Future<Uint8List> _renderContent(List<_PrintableLine> lines) async {
    // Calcular altura total
    double totalHeight = 0;
    for (final line in lines) {
      if (line.isImage) {
        totalHeight += 100 + defaultSpacing; // Altura estimada para imagens
      } else {
        final paragraph = _buildTextParagraph(line, maxWidth);
        totalHeight += paragraph.height + defaultSpacing;
      }
    }

    // Configurar canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, maxWidth, totalHeight));

    // Fundo branco
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, maxWidth, totalHeight), ui.Paint()..color = const ui.Color(0xFFFFFFFF));

    // Renderizar cada linha
    double y = 0;
    for (final line in lines) {
      if (line.isImage && line.imagePath != null) {
        try {
          final bytes = base64Decode(line.imagePath!);
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final img = frame.image;

          // Centralizar imagem
          final xOffset = (maxWidth - img.width) / 2;
          canvas.drawImage(img, ui.Offset(xOffset.clamp(0, maxWidth), y), ui.Paint());
          y += img.height + defaultSpacing;
        } catch (e) {
          debugPrint('Erro ao carregar imagem: $e');
          y += 100 + defaultSpacing;
        }
      } else {
        final paragraph = _buildTextParagraph(line, maxWidth);
        final xOffset = _calculateXOffset(line.align, maxWidth, paragraph);
        canvas.drawParagraph(paragraph, ui.Offset(xOffset, y));
        y += paragraph.height + defaultSpacing;
      }
    }

    // Converter para imagem
    final picture = recorder.endRecording();
    final image = await picture.toImage(maxWidth.ceil(), y.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) throw Exception('Falha ao converter imagem para bytes');
    return byteData.buffer.asUint8List();
  }

  /// Processamento adicional da imagem (conversão para preto e branco)
  Uint8List _processImage(Uint8List bytes) {
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception("Imagem inválida");

    // Redimensionar e converter para escala de cinza
    final resized = img.copyResize(original, width: maxWidth.toInt());
    final grayscale = img.grayscale(resized);

    // Aplicar threshold para preto e branco
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luma = img.getLuminance(pixel);
        grayscale.setPixelRgba(x, y, luma < 128 ? 0 : 255, luma < 128 ? 0 : 255, luma < 128 ? 0 : 255, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  // ========== MÉTODOS AUXILIARES ==========

  ui.Paragraph _buildTextParagraph(_PrintableLine line, double maxWidth) {
    final textStyle = ui.TextStyle(color: const ui.Color(0xFF000000), fontSize: line.fontSize, fontWeight: line.fontWeight);

    final paragraphStyle = ui.ParagraphStyle(textAlign: _convertAlign(line.align), fontSize: line.fontSize, fontWeight: line.fontWeight);

    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(line.text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));

    return paragraph;
  }

  double _calculateXOffset(IfoodPagoPrintAlign align, double maxWidth, ui.Paragraph paragraph) {
    switch (align) {
      case IfoodPagoPrintAlign.center:
        return (maxWidth - paragraph.maxIntrinsicWidth) / 2;
      case IfoodPagoPrintAlign.right:
        return maxWidth - paragraph.maxIntrinsicWidth;
      case IfoodPagoPrintAlign.left:
      default:
        return 0;
    }
  }

  ui.TextAlign _convertAlign(IfoodPagoPrintAlign align) {
    switch (align) {
      case IfoodPagoPrintAlign.center:
        return ui.TextAlign.center;
      case IfoodPagoPrintAlign.right:
        return ui.TextAlign.right;
      case IfoodPagoPrintAlign.left:
      default:
        return ui.TextAlign.left;
    }
  }

  double _getFontSize(IfoodPagoPrintSize size) {
    switch (size) {
      case IfoodPagoPrintSize.big:
        return 20;
      case IfoodPagoPrintSize.medium:
        return 18;
      case IfoodPagoPrintSize.small:
        return 14;
    }
  }
}

/// Representação de uma linha imprimível
class _PrintableLine {
  final String text;
  final double fontSize;
  final IfoodPagoPrintAlign align;
  final FontWeight fontWeight;
  final String? imagePath;
  final bool isImage;

  _PrintableLine({required this.text, required this.fontSize, required this.align, required this.fontWeight}) : imagePath = null, isImage = false;

  _PrintableLine.image(this.imagePath) : text = '', fontSize = 0, align = IfoodPagoPrintAlign.left, fontWeight = FontWeight.normal, isImage = true;
}
