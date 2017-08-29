library srec_codec.srec_print.parser;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:srec_codec/src/srec/srec.dart';

export 'package:srec_codec/src/srec/srec.dart' show DataRecord;

abstract class SRecView {
  /// Parses SREC view string to [DataRecord]
  static DataRecord parseRecord(String line) {
    List<String> parts = line.split(new RegExp(r'\s+'));
    if (parts.length != 18) {
      //TODO support incomplete lines
      throw new Exception('Invalid SREC view line!');
    }

    parts.removeLast();

    final int startAddr = int.parse(parts.first, radix: 16, onError: (_) {
      throw new Exception('Invalid SREC view line!');
    });

    final List<int> data = parts
        .sublist(1)
        .map((String str) => int.parse(str, radix: 16, onError: (_) {
              throw new Exception('Invalid SREC view line!');
            }))
        .toList();

    return new DataRecord(startAddr, new Uint8List.fromList(data));
  }

  static List<DataRecord> parseRecords(List<String> lines) =>
      lines.map(parseRecord).toList();

  static Stream<DataRecord> parseRecordsByteStream(Stream<List<int>> stream) =>
      stream
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .map(parseRecord);

  /// Converts the provided [DataRecord] [rec] to SREC view string
  static String toView(DataRecord rec) {
    if (rec.data.length > 16) {
      throw new Exception('Only accepts 16 bytes records!');
    }
    final sb = new StringBuffer();
    String addrDigits = rec.startAddr.toRadixString(16).toUpperCase();
    addrDigits = '0' * (8 - addrDigits.length) + addrDigits;
    sb.write(addrDigits);
    sb.write('\t');
    rec.data.forEach((int d) {
      String digits = d.toRadixString(16).toUpperCase();
      if (digits.length == 1) digits = '0' + digits;
      sb.write(digits + ' ');
    });
    sb.write('\t');
    rec.data.forEach((int d) {
      if (d >= 32 && d <= 165 && d != 127) {
        sb.write(new String.fromCharCode(d));
      } else {
        sb.write('.');
      }
    });
    return sb.toString();
  }

  static List<String> toViews(List<DataRecord> lines) =>
      lines.map(toView).toList();

  static Stream<String> toViewStream(Stream<DataRecord> stream) =>
      stream.map(toView);
}
