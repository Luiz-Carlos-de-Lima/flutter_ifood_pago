import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_ifood_pago/constants/ifood_pago_print_content_types.dart';
import 'package:flutter_ifood_pago/constants/ifood_pago_transaction_type.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_payment_exception.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_print_exception.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_refund_exception.dart';
import 'package:flutter_ifood_pago/flutter_ifood_pago.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_content_print.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_payment_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_print_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_refund_payload.dart';

import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

final flutterIfoodPagoPlugin = FlutterIfoodPago();

void main() {
  runApp(const MaterialApp(home: PaymentApp()));
}

class PaymentApp extends StatelessWidget {
  const PaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            spacing: 15.0,
            children: [
              SizedBox(
                width: 300,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PaymentPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: Text('Pagamento'),
                ),
              ),
              SizedBox(
                width: 300,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _EstonoPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: Text('Estorno'),
                ),
              ),
              SizedBox(
                width: 300,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PrintPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: Text('Imprimir'),
                ),
              ),
              // SizedBox(
              //   width: 300,
              //   height: 45,
              //   child: ElevatedButton(
              //     onPressed: () async {
              //       try {
              //         final info = await FlutterIfoodPago().deviceInfo();
              //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Device info: ${info.toJson()}")));
              //       } on IfoodPagoInfoException catch (e) {
              //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              //       } catch (e) {
              //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro desconhecido')));
              //       }
              //     },
              //     style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
              //     child: Text('Device Info'),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentPage extends StatefulWidget {
  const _PaymentPage();

  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  final _amountEC = TextEditingController();
  final _qtdEC = TextEditingController();

  final List<DropdownMenuItem<IfoodPagoTransactionType?>> _listTypes = IfoodPagoTransactionType.values
      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
      .toList();

  IfoodPagoTransactionType? _transactionType;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('pagamento'), centerTitle: true, leading: Container()),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text('Tipo do Pagamento')),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                    height: 55,
                    child: DropdownButton(
                      value: _transactionType,
                      items: _listTypes,
                      isExpanded: true,
                      underline: Container(),
                      onChanged: (value) {
                        _qtdEC.text = '';
                        _transactionType = value;
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Align(alignment: Alignment.centerLeft, child: Text('Valor')),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _amountEC,
                    decoration: InputDecoration(hintText: 'Valor', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: Text('Voltar'),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        double? amount = double.tryParse(_amountEC.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Valor inválido')));
                          return;
                        }

                        if (_transactionType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selecione um tipo de pagamento')));
                          return;
                        }

                        final payment = IfoodPagoPaymentPayload(
                          paymentMethod: _transactionType!,
                          value: (amount * 100).toInt(),
                          transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
                          tableId: Random().nextInt(1000).toString(),
                        );
                        final response = await flutterIfoodPagoPlugin.pay(payload: payment);

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Simulacao pagamento realizada com sucesso!")));
                      } on IfoodPagoPaymentException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro desconhecido')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: Text('Pagar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstonoPage extends StatefulWidget {
  const _EstonoPage();

  @override
  State<_EstonoPage> createState() => _EstonoPageState();
}

class _EstonoPageState extends State<_EstonoPage> {
  final _transactionIdEC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Estorno'), centerTitle: true, leading: Container()),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  SizedBox(height: 10.0),
                  Align(alignment: Alignment.centerLeft, child: Text('ID da Transação')),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _transactionIdEC,
                    decoration: InputDecoration(hintText: 'ID da Transação', border: OutlineInputBorder()),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: Text('Voltar'),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        String transactionId = _transactionIdEC.text.trim();
                        if (transactionId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID da transação é obrigatório')));
                          return;
                        }

                        final refund = IfoodPagoRefundPayload(transactionIdAdyen: transactionId);

                        final response = await flutterIfoodPagoPlugin.refund(payload: refund);

                        if (response.status.name == 'SUCCESS') {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Simulacao estorno realizada com sucesso!")));
                        } else {
                          throw IfoodPagoRefundException(message: "Erro ao realizar estorno");
                        }
                      } on IfoodPagoRefundException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro desconhecido')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: Text('Estornar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrintPage extends StatefulWidget {
  const _PrintPage();

  @override
  State<_PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<_PrintPage> {
  final _printTextEC = TextEditingController();
  final _imagePathEC = TextEditingController();
  final List<DropdownMenuItem<IfoodPagoPrintType>> _listPrintType = IfoodPagoPrintType.values
      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
      .toList();
  final List<DropdownMenuItem<IfoodPagoPrintAlign>> _listPrintAlign = IfoodPagoPrintAlign.values
      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
      .toList();
  final List<DropdownMenuItem<IfoodPagoPrintSize>> _listPrintSize = IfoodPagoPrintSize.values
      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
      .toList();

  IfoodPagoPrintType _printType = IfoodPagoPrintType.line;
  IfoodPagoPrintAlign? _printAlign = null;
  IfoodPagoPrintSize? _printSize = null;
  bool _ignoreLineBreak = false;
  String? _defaultImage64;
  List<Map> _previewBase64 = [];

  final List<IfoodPagoContentprint> _receiptContent = [];

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
  }

  @override
  void dispose() {
    _printTextEC.dispose();
    _imagePathEC.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultImage() async {
    final image64 = await imageToBase64('https://css-tricks.com/wp-content/uploads/2022/08/flutter-clouds.jpg');
    setState(() {
      _defaultImage64 = image64;
      if (_imagePathEC.text.isEmpty && image64 != null) {
        _imagePathEC.text = image64;
      }
    });
  }

  void _addToReceipt() {
    String? image64;
    if (_printType == IfoodPagoPrintType.image) {
      image64 = _imagePathEC.text.isNotEmpty ? _imagePathEC.text : _defaultImage64;
      if (image64 == null || image64.isEmpty) return;
    }
    if (_printType != IfoodPagoPrintType.image && _printTextEC.text.isEmpty) return;

    final item = IfoodPagoContentprint(
      type: _printType,
      align: _printAlign,
      content: _printTextEC.text,
      size: _printSize,
      imagePath: image64,
      ignoreLineBreak: _ignoreLineBreak,
    );
    setState(() {
      _receiptContent.add(item);
      _printTextEC.clear();
    });
  }

  void _removeLine(int index) {
    setState(() {
      _receiptContent.removeAt(index);
    });
  }

  void _clearReceipt() {
    setState(() {
      _receiptContent.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Impressão'), centerTitle: true, leading: Container()),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Align(alignment: Alignment.centerLeft, child: Text('Tipo de Impressão')),
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                    height: 55,
                    child: DropdownButton(
                      value: _printType,
                      items: _listPrintType,
                      isExpanded: true,
                      underline: Container(),
                      onChanged: (value) {
                        setState(() {
                          _printType = value!;
                          if (_printType == IfoodPagoPrintType.text) {
                            _printAlign = IfoodPagoPrintAlign.center;
                            _printSize = IfoodPagoPrintSize.medium;
                          } else {
                            _printAlign = null;
                            _printSize = null;
                          }
                        });
                      },
                    ),
                  ),
                  if (_printType == IfoodPagoPrintType.text) ...[
                    SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: Text('Alinhamento da Impressão')),
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                      height: 55,
                      child: DropdownButton(
                        value: _printAlign,
                        items: _listPrintAlign,
                        isExpanded: true,
                        underline: Container(),
                        onChanged: (value) {
                          setState(() {
                            _printAlign = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: Text('Tamanho da Impressão')),
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                      height: 55,
                      child: DropdownButton(
                        value: _printSize,
                        items: _listPrintSize,
                        isExpanded: true,
                        underline: Container(),
                        onChanged: (value) {
                          setState(() {
                            _printSize = value!;
                          });
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: Text('Ignorar Quebra de Linha'),
                      value: _ignoreLineBreak,
                      onChanged: (val) {
                        setState(() {
                          _ignoreLineBreak = val;
                        });
                      },
                    ),
                  ],
                  if (_printType != IfoodPagoPrintType.image)
                    Column(
                      children: [
                        SizedBox(height: 10),
                        Align(alignment: Alignment.centerLeft, child: Text('Texto para Impressão')),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _printTextEC,
                          decoration: InputDecoration(hintText: 'Texto', border: OutlineInputBorder()),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        SizedBox(height: 10),
                        Align(alignment: Alignment.centerLeft, child: Text('Base64 da Imagem')),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _imagePathEC,
                          decoration: InputDecoration(hintText: 'Cole o Base64 da imagem', border: OutlineInputBorder()),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        if (_defaultImage64 != null)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Image.memory(base64Decode(_defaultImage64!))),
                      ],
                    ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(onPressed: _addToReceipt, child: Text('Adicionar ao Recibo')),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(onPressed: _receiptContent.isEmpty ? null : _clearReceipt, child: Text('Remover tudo')),
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  if (_receiptContent.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conteúdo do Recibo:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._receiptContent.asMap().entries.map(
                          (entry) => Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(entry.value.type.name),
                              subtitle: Text(entry.value.type == IfoodPagoPrintType.image ? 'Imagem' : (entry.value.content ?? '')),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Remover linha',
                                onPressed: () => _removeLine(entry.key),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  if (_previewBase64.isNotEmpty) ...[
                    Text("Pré-visualização:", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ...List.generate(_previewBase64.length, (index) {
                      if (_previewBase64[index]['imageBase64'] is String && _previewBase64[index]['imageBase64'].isNotEmpty) {
                        return Column(
                          children: [
                            if (_previewBase64[index]['messageError'] != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(_previewBase64[index]['messageError'], style: TextStyle(color: Colors.red)),
                              ),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Image.memory(base64Decode(_previewBase64[index]['imageBase64']))),
                          ],
                        );
                      }

                      return SizedBox.shrink();
                    }),
                    SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: Text('Voltar'),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _receiptContent.isEmpty
                        ? null
                        : () async {
                            try {
                              final print = IfoodPagoPrintPayload(integrationApp: 'Jclan', printableContent: List<IfoodPagoContentprint>.from(_receiptContent));
                              _previewBase64 = await flutterIfoodPagoPlugin.printData(payload: print);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Impressão realizada com sucesso!")));
                              setState(() {});
                            } on IfoodPagoPrintException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro desconhecido')));
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: Text('Imprimir'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> imageToBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final originalBytes = response.bodyBytes;

        final codec = await ui.instantiateImageCodec(originalBytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        const maxWidth = 380;
        final originalWidth = image.width;
        final originalHeight = image.height;

        if (originalWidth <= maxWidth) {
          return base64Encode(originalBytes);
        }

        final ratio = maxWidth / originalWidth;
        final targetHeight = (originalHeight * ratio).round();

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
          Rect.fromLTWH(0, 0, maxWidth.toDouble(), targetHeight.toDouble()),
          Paint()..filterQuality = ui.FilterQuality.high,
        );

        final picture = recorder.endRecording();
        final resizedImage = await picture.toImage(maxWidth, targetHeight);
        final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          return base64Encode(byteData.buffer.asUint8List());
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao converter imagem para Base64: $e");
      }
      return null;
    }
  }
}
