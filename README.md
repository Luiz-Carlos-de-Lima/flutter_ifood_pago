<h1 align="center">Flutter iFood Pago</h1>

<div align="center" id="top"> 
  <img src="https://miriangasparin.com.br/wp-content/uploads/2024/06/iFood-Pago.jpg" alt="iFood" height=120 />
</div>

## Plugin não oficial para Integração com iFood Pagamentos

## Sobre

O **Flutter iFood Pago** é um plugin Flutter desenvolvido para integrar funcionalidades de pagamento do iFood em aplicativos Flutter. O plugin permite processar transações via crédito, débito, voucher e PIX, além de oferecer suporte para estorno de transações e impressão de comprovantes em dispositivos POS.

## Funcionalidades Principais

- Processamento de pagamentos (crédito, débito, voucher, PIX)
- Estorno de transações
- Impressão de comprovantes
- Suporte a diferentes tipos de layout de impressão (texto, linha, imagem)
- Preview de impressão em base64

## Tecnologias Utilizadas

- Flutter
- Dart
- HTTP para requisições
- Platform Channels para comunicação nativa
- Shared Preferences para armazenamento local

## Instalação

Adicione ao seu `pubspec.yaml`:

```yaml
dependencies:
  flutter_ifood_pago: ^latest_version
```

## Como Utilizar

### Inicialização

```dart
import 'package:flutter_ifood_pago/flutter_ifood_pago.dart';

final flutterIfoodPagoPlugin = FlutterIfoodPago();
```

### Processamento de Pagamento

```dart
try {
  final payment = IfoodPagoPaymentPayload(
    paymentMethod: IfoodPagoTransactionType.CREDIT,
    value: 1000, // R$ 10,00 em centavos
    transactionId: "123456",
    tableId: "789",
    printReceipt: true
  );
  
  final response = await flutterIfoodPagoPlugin.pay(payload: payment);
  // Trata resposta
} on IfoodPagoPaymentException catch (e) {
  // Trata erro de pagamento
}
```

### Estorno de Transação

```dart
try {
  final refund = IfoodPagoRefundPayload(
    transactionIdAdyen: "ID_TRANSACAO",
    printReceipt: true
  );
  
  final response = await flutterIfoodPagoPlugin.refund(payload: refund);
  // Trata resposta
} on IfoodPagoRefundException catch (e) {
  // Trata erro de estorno
}
```

### Impressão de Comprovante

```dart
try {
  final printPayload = IfoodPagoPrintPayload(
    integrationApp: "NomeApp",
    printableContent: [
      IfoodPagoContentprint(
        type: IfoodPagoPrintType.text,
        content: "Texto exemplo",
        align: IfoodPagoPrintAlign.center,
        size: IfoodPagoPrintSize.medium
      )
    ]
  );
  
  final response = await flutterIfoodPagoPlugin.printData(payload: printPayload);
  // Trata resposta
} on IfoodPagoPrintException catch (e) {
  // Trata erro de impressão
}
```

## Classes Principais

### IfoodPagoPaymentPayload
Responsável por estruturar dados de pagamento:
- `paymentMethod`: Tipo de transação
- `value`: Valor em centavos
- `transactionId`: Identificador único
- `tableId`: Identificador da mesa
- `printReceipt`: Flag para impressão

### IfoodPagoRefundPayload
Estrutura dados de estorno:
- `transactionIdAdyen`: ID da transação original
- `printReceipt`: Flag para impressão

### IfoodPagoPrintPayload
Configura impressão:
- `integrationApp`: Nome da integradora. Deve ser informado sem espaços, utilizando por exemplo underline: Nome_Integradora.
- `printableContent`: Lista de conteúdos para impressão
- `groupAll`: Valor booleano que indica se toda a lista deve ser agrupada em uma única imagem.

## Tipos de Impressão

### IfoodPagoPrintType
- `text`: Impressão de texto
- `line`: Impressão de linha
- `image`: Impressão de imagem

### IfoodPagoPrintAlign
- `center`: Centralizado
- `right`: Direita
- `left`: Esquerda

### IfoodPagoPrintSize
- `big`: Grande
- `medium`: Médio
- `small`: Pequeno

## Tratamento de Erros

O plugin possui três tipos principais de exceções:

```dart
IfoodPagoPaymentException: Erros relacionados a pagamentos
IfoodPagoRefundException: Erros relacionados a estornos
IfoodPagoPrintException: Erros relacionados a impressão
```

## :memo: Autores

Este projeto foi desenvolvido por:
<a href="https://github.com/Luiz-Carlos-de-Lima" target="_blank">Luiz Carlos de Lima</a>
</br>
<div> 
<a href="https://github.com/Luiz-Carlos-de-Lima">
  <img src="https://avatars.githubusercontent.com/u/82920625?s=400&u=a114c12a6e61d2f9b907feb450587a37aae068bb&v=4" height=90 />
</a>
<br>
<a href="https://github.com/Luiz-Carlos-de-Lima" target="_blank">Luiz Carlos de Lima</a>
</div>

&#xa0;

## Licença

Este projeto está sob a licença MIT.

<a href="#top">Voltar para o topo</a>