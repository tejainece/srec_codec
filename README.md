# srec_codec

Dart library to parse and write motorola SREC

## Usage

A simple usage example:

```dart
import 'dart:io';
import 'package:srec_codec/srec_codec.dart';

main() async {
  final String filename = 'data/unnamed/iodesc_iqs.hps';
  File file = new File(filename);
  final result = await parse(file.openRead());
  print(result);
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/tejainece/srec_codec/issues
