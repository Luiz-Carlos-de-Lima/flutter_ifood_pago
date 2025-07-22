import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ifood_pago/constants/ifood_pago_transaction_type.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_payment_exception.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_refund_exception.dart';
import 'package:flutter_ifood_pago/flutter_ifood_pago.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_payment_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_refund_payload.dart';

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
              // SizedBox(
              //   width: 300,
              //   height: 45,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PrintPage()));
              //     },
              //     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              //     child: Text('Imprimir'),
              //   ),
              // ),
              // SizedBox(
              //   width: 300,
              //   height: 45,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ReprintPage()));
              //     },
              //     style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              //     child: Text('Reimprimir'),
              //   ),
              // ),
              // SizedBox(
              //   width: 300,
              //   height: 45,
              //   child: ElevatedButton(
              //     onPressed: () async {
              //       try {
              //         final info = await FlutterIfoodPago().deviceInfo();
              //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Device info: ${info.toJson()}")));
              //       } on StoneInfoException catch (e) {
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

  bool _editableAmount = false;

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
                  InkWell(
                    onTap: () {
                      setState(() {
                        _editableAmount = !_editableAmount;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _editableAmount,
                          onChanged: (_) {
                            setState(() {
                              _editableAmount = !_editableAmount;
                            });
                          },
                        ),
                        Text("Valor Editável", style: TextStyle(fontSize: 18)),
                      ],
                    ),
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
