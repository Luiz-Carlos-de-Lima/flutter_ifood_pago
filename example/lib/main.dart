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
                              List teste = [
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''                 JCLAN SISTEMAS                 
------------------------------------------------
          BAR           
================================================
Comanda: 87             
------------------------------------------------
Nome: Luiz C                                    
------------------------------------------------
Entregar na Mesa: 12                            
------------------------------------------------
IMP: 01/3 (BR)                                  
At: 0 - Suporte                                 
Term: 1                       Dt: 25/08/25 12:11
================================================
Qtde - Produto                                  
------------------------------------------------
1 - HEINEKKEN                                   
------------------------------------------------
                  Data Impressao: 25/08/25 12:11
''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''                                                ''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''                 JCLAN SISTEMAS                 
------------------------------------------------
          BAR           
================================================
Comanda: 87             
------------------------------------------------
Nome: Luiz C                                    
------------------------------------------------
Entregar na Mesa: 12                            
------------------------------------------------
IMP: 11/3 (BR)                                  
At: 0 - Suporte                                 
Term: 1                       Dt: 25/08/25 12:11
================================================
Qtde - Produto                                  
------------------------------------------------
1 - MANIACS CRAFT                               
------------------------------------------------
                  Data Impressao: 25/08/25 12:11
''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''                                                ''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''                 JCLAN SISTEMAS                 
------------------------------------------------
          BAR           
================================================
Comanda: 87             
------------------------------------------------
Nome: Luiz C                                    
------------------------------------------------
Entregar na Mesa: 12                            
------------------------------------------------
IMP: 21/3 (BR)                                  
At: 0 - Suporte                                 
Term: 1                       Dt: 25/08/25 12:11
================================================
Qtde - Produto                                  
------------------------------------------------
1 - MANIACS WIT                                 
------------------------------------------------
                  Data Impressao: 25/08/25 12:11
''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''                                                ''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''     JCLAN DESENVOLVIMENTO DE SOFTWARE LTDA     
              CNPJ: 05333353000127              
      AVENIDA BRASILIA, 4547, CURITIBA, PR      
DOCUMENTO AUXILIAR DA NOTA FISCAL DE CONSUMIDOR 
                   ELETRONICA                   
------------------------------------------------
CODIGO DESCRICAO      QTDE UN  VL UNIT  VL TOTAL
538    - NOTA FISCAL EMITIDA EM AMBIENTE DE HOMO
LOGACAO - SEM VALOR FISCAL
                         1 UN     5,00      5,00
538    - COCA COLA E     1 UN     5,00      5,00
560    - HEINEKKEN       1 UN    10,00     10,00
561    - MANIACS CRAFT
                         1 UN    10,00     10,00
563    - MANIACS WIT     1 UN    10,00     10,00
999    - Gorjeta         1 UN     4,00      4,00
------------------------------------------------
Qtde. total de itens                           6
Valor a Pagar R\$                           44,00                                                FORMA DE PAGAMENTO                 VALOR PAGO R\$
Cartao de Debito                           44,00
------------------------------------------------
          CONSUMIDOR - CPF 08686654959          
        Consulte pela Chave de Acesso em        
   http://www.fazenda.pr.gov.br/nfce/consulta   
  41250805333353000127652010000009741177075780  
         NFC-e n. 000000974   Serie 201         
       Data Emissao: 25/08/2025 12:11:50        
                 EMISSAO NORMAL                                                                     Protocolo de autorizacao:141250000285772    
    Data de Autorizacao: 25/08/2025 12:11:52    
''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  ignoreLineBreak: true,
                                  size: IfoodPagoPrintSize.small,
                                  content: '''                                                ''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.image,
                                  imagePath:
                                      '''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''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  ignoreLineBreak: true,
                                  size: IfoodPagoPrintSize.small,
                                  content: '''                                                ''',
                                ),
                                IfoodPagoContentprint(
                                  type: IfoodPagoPrintType.text,
                                  align: IfoodPagoPrintAlign.left,
                                  size: IfoodPagoPrintSize.small,
                                  ignoreLineBreak: true,
                                  content: '''
Val. Aprox Tributos: Estadual 8,70 (19.77%), Nac
ional 4,85 (11.02%), Fonte: IBPT                
''',
                                ),
                              ];

                              final print = IfoodPagoPrintPayload(
                                integrationApp: 'Exemplo_integradora',
                                printableContent: List<IfoodPagoContentprint>.from(teste),
                                groupAll: true,
                              );
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
