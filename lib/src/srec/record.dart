part of srec_codec.srec;

abstract class Record {
  String toSRec();
}

class HeaderRecord implements Record {
  final Uint8List data;

  HeaderRecord(this.data);

  int get checksum {
    int ret = data.length;
    ret = data.fold(ret, (int incom, int v) => incom + v);
    return ~ret & 0xFF;
  }

  String toSRec() {
    final sb = new StringBuffer();
    sb.write("S0");
    sb.write(Hex.toHex8Str(data.length + 1));
    sb.write("0000");
    data.map(Hex.toHex8Str).forEach(sb.write);
    sb.write(Hex.toHex8Str(checksum));
    return sb.toString();
  }

  factory HeaderRecord.parseSafe(List<int> data) {
    if (data.length < 9) {
      throw new Exception('Invalid header record!');
    }
    final d = new Uint8List.fromList(data.sublist(8, data.length - 2));
    return new HeaderRecord(d);
  }
}

class DataRecord implements Record {
  int startAddr;

  Uint8List data;

  DataRecord(this.startAddr, this.data);

  factory DataRecord.parseSafe(List<int> data, int dataCount) {
    final int addr = DataRecord.parseAddr(data, data[1]);
    if (addr == null) {
      throw new Exception('Invalid record!');
    }
    final int addrLen = DataRecord.getStartLen(data[1]);
    final int dataStartIndex = 4 + addrLen * 2;

    final Uint8List hex = new Uint8List(dataCount);

    for (int idx = 0; idx < dataCount; idx++) {
      final int byte = Hex.toUint8(
          data[idx * 2 + dataStartIndex], data[idx * 2 + dataStartIndex + 1]);
      hex[idx] = byte;
    }

    return new DataRecord(addr, hex);
  }

  int get endAddr => startAddr + data.length - 1;

  int get recordType {
    if (endAddr & ~0xFFFF == 0) {
      return 1;
    } else if (startAddr & ~0xFFFFFF == 0) {
      return 2;
    } else if (startAddr & ~0xFFFFFFFF == 0) {
      return 3;
    } else {
      throw new Exception('Addresses longer than 32-bits are not supported!');
    }
  }

  int get addressLen {
    switch (recordType) {
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      default:
        throw new Exception('Invalid record type!');
    }
  }

  int get checksum {
    int ret = addressLen + data.length + 1;
    ret = UInt.bytes4(startAddr).fold(ret, (int incom, int v) => incom + v);
    ret = data.fold(ret, (int incom, int v) => incom + v);
    return ~ret & 0xFF;
  }

  String toSRec() {
    final sb = new StringBuffer();
    sb.write("S");
    sb.write(recordType);
    sb.write(Hex.toHex8Str(addressLen + data.length + 1));
    if (recordType == 1) {
      sb.write(Hex.toHex16Str(startAddr));
    } else if (recordType == 2) {
      sb.write(Hex.toHex24Str(startAddr));
    } else if (recordType == 3) {
      sb.write(Hex.toHex32Str(startAddr));
    }
    data.map(Hex.toHex8Str).forEach(sb.write);
    sb.write(Hex.toHex8Str(checksum));
    return sb.toString();
  }

  String toString() {
    final sb = new StringBuffer();
    String addrDigits = startAddr.toRadixString(16).toUpperCase();
    addrDigits = '0' * (8 - addrDigits.length) + addrDigits;
    sb.write(addrDigits);
    sb.write('\t');
    data.forEach((int d) {
      String digits = d.toRadixString(16).toUpperCase();
      if (digits.length == 1) digits = '0' + digits;
      sb.write(digits + ' ');
    });
    return sb.toString();
  }

  static int parseAddr(List<int> data, int recordType) {
    if (recordType == 49) {
      if (data.length < 8) return null;
      return Hex.toUint16(data[4], data[5], data[6], data[7]);
    } else if (recordType == 50) {
      if (data.length < 10) return null;
      return Hex.toUint24(data[4], data[5], data[6], data[7], data[8], data[9]);
    } else if (recordType == 51) {
      if (data.length < 12) return null;
      return Hex.toUint32(data[4], data[5], data[6], data[7], data[8], data[9],
          data[10], data[11]);
    } else {
      throw new Exception('Not a termination record type!');
    }
  }

  static int getStartLen(int recordType) {
    return recordType - 49 + 2;
  }
}

class TerminationRecord implements Record {
  final int startAddr;

  TerminationRecord(this.startAddr);

  factory TerminationRecord.parseSafe(List<int> data) {
    final int addr = TerminationRecord.parseAddr(data, data[1]);
    if (addr == null) {
      throw new Exception('Invalid record!');
    }
    return new TerminationRecord(addr);
  }

  int get recordType {
    if (startAddr & 0xFFFF == 0) {
      return 9;
    } else if (startAddr & 0xFFFFFF == 0) {
      return 8;
    } else if (startAddr & 0xFFFFFFFF == 0) {
      return 7;
    } else {
      throw new Exception('Addresses longer than 32-bits are not supported!');
    }
  }

  int get addressLen {
    switch (recordType) {
      case 9:
        return 2;
      case 8:
        return 3;
      case 7:
        return 4;
      default:
        throw new Exception('Invalid record type!');
    }
  }

  int get checksum {
    int ret = addressLen + 1;
    ret = UInt.bytes4(startAddr).fold(ret, (int incom, int v) => incom + v);
    return ~ret & 0xFF;
  }

  String toSRec() {
    final sb = new StringBuffer();
    sb.write("S");
    sb.write(recordType);
    sb.write(Hex.toHex8Str(addressLen + 1));
    if (recordType == 9) {
      sb.write(Hex.toHex16Str(startAddr));
    } else if (recordType == 8) {
      sb.write(Hex.toHex24Str(startAddr));
    } else if (recordType == 7) {
      sb.write(Hex.toHex32Str(startAddr));
    }
    sb.write(Hex.toHex8Str(checksum));
    return sb.toString();
  }

  static int parseAddr(List<int> data, int recordType) {
    if (recordType == 57) {
      if (data.length < 8) return null;
      return Hex.toUint16(data[4], data[5], data[6], data[7]);
    } else if (recordType == 56) {
      if (data.length < 10) return null;
      return Hex.toUint24(data[4], data[5], data[6], data[7], data[8], data[9]);
    } else if (recordType == 55) {
      if (data.length < 12) return null;
      return Hex.toUint32(data[4], data[5], data[6], data[7], data[8], data[9],
          data[10], data[11]);
    } else {
      throw new Exception('Not a data record type!');
    }
  }
}
