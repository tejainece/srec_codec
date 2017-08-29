library srec_codec.srec;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';
import 'package:srec_codec/src/utils/hex.dart';

part 'memory_map.dart';
part 'record.dart';

abstract class SRec {
  /// Parses a single record [line] and returns the parsed [Record]
  static Record parseRecord(final String line) {
    final List<int> data = line.codeUnits;

    if (data.length < 4) throw new Exception('Invalid record!');
    if (data.first != 83) throw new Exception('Invalid record start char!');
    final int count = Hex.toUint8(data[2], data[3]);
    if (data.length < (4 + (count * 2))) return null;

    {
      int calcCsum = 0;
      for (int idx = 0; idx < count; idx++) {
        final int byte = Hex.toUint8(data[idx * 2 + 2], data[idx * 2 + 2 + 1]);
        calcCsum += byte;
      }
      calcCsum = ~calcCsum & 0xFF;

      final int end = (count * 2) + 4 - 2;
      final int readCsum = Hex.toUint8(data[end], data[end + 1]);
      if (calcCsum != readCsum) {
        throw new Exception('Invalid checksum!');
      }
    }

    if (data[1] >= 49 && data[1] <= 51) {
      final int addrLen = DataRecord.getStartLen(data[1]);
      return new DataRecord.parseSafe(data, count - addrLen - 1);
    } else if (data[1] == 48) {
      return new HeaderRecord.parseSafe(data);
    } else if (data[1] >= 55 && data[1] <= 57) {
      return new TerminationRecord.parseSafe(data);
    } else {
      throw new Exception('Unknown record type!');
    }
  }

  /// Parses all the records [lines] provided and returns
  static List<Record> parseRecords(List<String> lines) =>
      lines.map(parseRecord).toList();

  static Stream<Record> parseRecordsByteStream(Stream<List<int>> stream) =>
      stream
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .map(parseRecord)
          .where((r) => r is DataRecord);

  static String toSRec(Record rec) => rec.toSRec();

  static List<String> toSRecs(List<Record> recs) =>
      recs.map((Record rec) => rec.toSRec()).toList();

  static Stream<List<int>> toSRecStream(Stream<Record> recs) =>
      recs.map((Record rec) => rec.toSRec()).transform(UTF8.encoder);
}
