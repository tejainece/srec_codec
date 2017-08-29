library srec_codec.srec_print.parser;

import '../parser.dart';
import 'dart:typed_data';

export '../parser.dart' show DataRecord;

/// Parses SREC view string to [DataRecord]
DataRecord parseSrecView(String line) {
  List<String> parts = line.split(new RegExp(r'\s+'));
  if (parts.length != 18) {
    //TODO support incomplete lines
    throw new Exception('Invalid SREC view line!');
  }

  parts.removeLast();

  final int startAddr = int.parse(parts.first, radix: 16, onError: (_) {
    throw new Exception('Invalid SREC view line!');
  });

  final List<int> data = parts.sublist(1).map((String str) => int.parse(str, radix: 16, onError: (_) {
    throw new Exception('Invalid SREC view line!');
  })).toList();

  return new DataRecord(startAddr, new Uint8List.fromList(data));
}

/// Converts the provided [DataRecord] [rec] to SREC view string
String toSrecView(DataRecord rec) {
  final sb = new StringBuffer();
  String addrDigits = rec.startAddr.toRadixString(16).toUpperCase();
  addrDigits = '0' * (8 - addrDigits.length) + addrDigits;
  sb.write(addrDigits);
  sb.write('\t');
  rec.data.forEach((int d) {
    String digits = d.toRadixString(16).toUpperCase();
    if(digits.length == 1) digits = '0' + digits;
    sb.write(digits + ' ');
  });
  sb.write('\t');
  rec.data.forEach((int d) {
    if(d >= 32 && d <= 165 && d != 127) {
      sb.write(new String.fromCharCode(d));
    } else {
      sb.write('.');
    }
  });
  return sb.toString();
}