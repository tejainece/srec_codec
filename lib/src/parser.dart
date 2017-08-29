library srec_codec.parser;

import 'dart:async';
import 'dart:typed_data';

int hexToNibble(final int data) {
  if (data >= 48 && data <= 57) {
    return data - 48;
  } else if (data >= 65 && data <= 70) {
    return 10 + data - 65;
  } else if (data >= 97 && data <= 102) {
    return 10 + data - 97;
  } else {
    throw new Exception('Not valid hex $data!');
  }
}

int hexToUint8(int data1, int data0) {
  int data = hexToNibble(data1);
  data <<= 4;
  data |= hexToNibble(data0);
  return data;
}

int hexToUint16(int data3, int data2, int data1, int data0) {
  int data = hexToUint8(data3, data2);
  data <<= 8;
  data |= hexToUint8(data1, data0);
  return data;
}

int hexToUint24(
    int data5, int data4, int data3, int data2, int data1, int data0) {
  int data = hexToUint8(data5, data4);
  data <<= 8;
  data |= hexToUint8(data3, data2);
  data <<= 8;
  data |= hexToUint8(data1, data0);
  return data;
}

int hexToUint32(int data7, int data6, int data5, int data4, int data3,
    int data2, int data1, int data0) {
  int data = hexToUint8(data7, data6);
  data <<= 8;
  data = hexToUint8(data5, data4);
  data <<= 8;
  data |= hexToUint8(data3, data2);
  data <<= 8;
  data |= hexToUint8(data1, data0);
  return data;
}

void trimNewLines(final List<int> data) {
  int count = 0;
  while (true) {
    if (data.length <= count) break;
    if (data[count] == 13 || data[count] == 10) {
      count++;
    } else {
      break;
    }
  }

  if (count == 0) return;
  data.removeRange(0, count);
}

abstract class Record {}

class HeaderRecord implements Record {}

class DataRecord implements Record {
  int startAddr;

  Uint8List data;

  DataRecord(this.startAddr, this.data);

  int get endAddr => startAddr + data.length - 1;

  String toString() {
    final sb = new StringBuffer();
    String addrDigits = startAddr.toRadixString(16).toUpperCase();
    addrDigits = '0' * (8 - addrDigits.length) + addrDigits;
    sb.write(addrDigits);
    sb.write('\t');
    data.forEach((int d) {
      String digits = d.toRadixString(16).toUpperCase();
      if(digits.length == 1) digits = '0' + digits;
      sb.write(digits + ' ');
    });
    return sb.toString();
  }
}

class TerminationRecord implements Record {
  int startAddr;

  TerminationRecord(this.startAddr);
}

Record parseRecord(final List<int> data) {
  trimNewLines(data);
  if (data.length < 4) return null;
  if (data.first != 83) throw new Exception('Invalid record start char!');

  if (data[1] == 49) {
    if (data.length < 8) return null;
    int calcCsum = 0;
    final int count = hexToUint8(data[2], data[3]);
    final int addr = hexToUint16(data[4], data[5], data[6], data[7]);

    if (data.length < (4 + (count * 2))) return null;

    final Uint8List hex = new Uint8List(count);

    for (int idx = 0; idx < 3; idx++) {
      calcCsum += hexToUint8(data[idx * 2 + 2], data[idx * 2 + 3]);
    }

    for (int idx = 0; idx < (count - 3); idx++) {
      final int byte = hexToUint8(data[idx * 2 + 8], data[idx * 2 + 9]);
      calcCsum += byte;
      hex[idx] = byte;
    }

    calcCsum = ~calcCsum & 0xFF;

    final int end = (count * 2) + 4 - 2;
    if (calcCsum != hexToUint8(data[end], data[end + 1])) {
      throw new Exception('Invalid checksum!');
    }

    if (data.length == (end + 2)) {
      data.clear();
    } else {
      data.removeRange(0, end + 2);
    }

    return new DataRecord(addr, hex);
  } else if (data[1] == 48) {
    if (data.length < 6) return null;

    int calcCsum = 0;
    final int count = hexToUint8(data[2], data[3]);

    if (data.length < (4 + (count * 2))) return null;

    calcCsum += hexToUint8(data[2], data[3]);

    for (int idx = 0; idx < (count - 1); idx++) {
      final int byte = hexToUint8(data[idx * 2 + 4], data[idx * 2 + 5]);
      calcCsum += byte;
    }

    calcCsum = ~calcCsum & 0xFF;

    final int end = (count * 2) + 4 - 2;
    if (calcCsum != hexToUint8(data[end], data[end + 1])) {
      throw new Exception('Invalid checksum!');
    }

    if (data.length == (end + 2)) {
      data.clear();
    } else {
      data.removeRange(0, end + 2);
    }

    return new HeaderRecord();
  } else if (data[1] == 55) {
    if (data.length < 12) return null;
    int calcCsum = 0;
    final int count = hexToUint8(data[2], data[3]);
    final int addr = hexToUint32(data[4], data[5], data[6], data[7], data[8],
        data[9], data[10], data[11]);

    if (data.length < (4 + (count * 2))) return null;

    for (int idx = 0; idx < 3; idx++) {
      calcCsum += hexToUint8(data[idx * 2 + 2], data[idx * 2 + 3]);
    }

    for (int idx = 0; idx < (count - 3); idx++) {
      final int byte = hexToUint8(data[idx * 2 + 8], data[idx * 2 + 9]);
      calcCsum += byte;
    }

    calcCsum = ~calcCsum & 0xFF;

    final int end = (count * 2) + 4 - 2;
    if (calcCsum != hexToUint8(data[end], data[end + 1])) {
      throw new Exception('Invalid checksum!');
    }

    if (data.length == (end + 2)) {
      data.clear();
    } else {
      data.removeRange(0, end + 2);
    }

    return new TerminationRecord(addr);
  } else if (data[1] == 56) {
    if (data.length < 10) return null;
    int calcCsum = 0;
    final int count = hexToUint8(data[2], data[3]);
    final int addr =
        hexToUint24(data[4], data[5], data[6], data[7], data[8], data[9]);

    if (data.length < (4 + (count * 2))) return null;

    for (int idx = 0; idx < 3; idx++) {
      calcCsum += hexToUint8(data[idx * 2 + 2], data[idx * 2 + 3]);
    }

    for (int idx = 0; idx < (count - 3); idx++) {
      final int byte = hexToUint8(data[idx * 2 + 8], data[idx * 2 + 9]);
      calcCsum += byte;
    }

    calcCsum = ~calcCsum & 0xFF;

    final int end = (count * 2) + 4 - 2;
    if (calcCsum != hexToUint8(data[end], data[end + 1])) {
      throw new Exception('Invalid checksum!');
    }

    if (data.length == (end + 2)) {
      data.clear();
    } else {
      data.removeRange(0, end + 2);
    }

    return new TerminationRecord(addr);
  } else if (data[1] == 57) {
    if (data.length < 8) return null;
    int calcCsum = 0;
    final int count = hexToUint8(data[2], data[3]);
    final int addr = hexToUint16(data[4], data[5], data[6], data[7]);

    if (data.length < (4 + (count * 2))) return null;

    for (int idx = 0; idx < 3; idx++) {
      calcCsum += hexToUint8(data[idx * 2 + 2], data[idx * 2 + 3]);
    }

    for (int idx = 0; idx < (count - 3); idx++) {
      final int byte = hexToUint8(data[idx * 2 + 8], data[idx * 2 + 9]);
      calcCsum += byte;
    }

    calcCsum = ~calcCsum & 0xFF;

    final int end = (count * 2) + 4 - 2;
    if (calcCsum != hexToUint8(data[end], data[end + 1])) {
      throw new Exception('Invalid checksum!');
    }

    if (data.length == (end + 2)) {
      data.clear();
    } else {
      data.removeRange(0, end + 2);
    }

    return new TerminationRecord(addr);
  } else {
    throw new Exception('Unknown record type!');
  }
}

Future<Uint8List> parse(Stream<List<int>> stream) async {
  final List<Record> records = new List<Record>();
  final List<int> remain = new List<int>();

  int maxAddr = 0;

  await for (List<int> data in stream) {
    remain.addAll(data);
    while (true) {
      final Record rec = parseRecord(remain);
      if (rec != null) {
        if (rec is DataRecord) {
          records.add(rec);
          if (rec.endAddr > maxAddr) maxAddr = rec.endAddr;
        }
      } else {
        break;
      }
    }
  }

  trimNewLines(remain);

  if (remain.length != 0) throw new Exception("Stray data found!");

  final Uint8List ret = new Uint8List(maxAddr + 1);
  for (DataRecord rec in records) {
    for (int addr = 0; addr < rec.data.length; addr++) {
      ret[rec.startAddr + addr] = rec.data[addr];
    }
  }

  return ret;
}
