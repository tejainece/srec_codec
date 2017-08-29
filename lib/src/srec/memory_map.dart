part of srec_codec.srec;

class MemoryMap {
  final int defaultValue;

  final SplayTreeMap<int, int> data = new SplayTreeMap<int, int>();

  MemoryMap({this.defaultValue}) {
    if (defaultValue != null && (defaultValue < 0 || defaultValue > 255)) {
      throw new Exception('Invalid default value!');
    }
  }

  factory MemoryMap.fromRecords(List<Record> recs, {int defaultValue}) {
    final MemoryMap memoryMap = new MemoryMap(defaultValue: defaultValue);
    for (final Record rec in recs) {
      if (rec is! DataRecord) continue;
      memoryMap.addRecord(rec);
    }
    return memoryMap;
  }

  int get minAddress => data.firstKey();

  int get maxAddress => data.lastKey();

  int operator [](int addr) {
    if (!data.containsKey(addr)) {
      if (defaultValue == null) {
        throw new Exception('Address not found!');
      }
      return defaultValue;
    }
    return data[addr];
  }

  operator []=(int addr, int data) {
    set(addr, data);
  }

  void set(int addr, int data) {
    if (data < 0 || data > 255) {
      throw new Exception('Invalid data: $data!');
    }
    this.data[addr] = data;
  }

  void addRecord(DataRecord rec) {
    for (int i = 0; i < data.length; i++) {
      set(rec.startAddr + i, rec.data[i]);
    }
  }

  void removeRecord(DataRecord rec) {
    for (int i = 0; i < data.length; i++) {
      data.remove(rec.startAddr + i);
    }
  }

  void removeRange(int start, [int end]) {
    if (end == null) end = data.lastKey();
    for (int i = start; i <= end; i++) {
      data.remove(i);
    }
  }

  int nextAddr(int address) {
    int newAddr;
    do {
      int newAddr = data.firstKeyAfter(address);
      if (newAddr == null) continue;
      if (defaultValue == null) {
        return newAddr;
      }
      if (defaultValue != data[newAddr]) {
        return newAddr;
      }
    } while (newAddr != null);
    return null;
  }

  DataRecord makeRecord(int startAddr, int size) {
    final data = new Uint8List(size);
    for (int i = 0; i < size; i++) {
      data[i] = this.data[startAddr + i];
    }
    return new DataRecord(startAddr, data);
  }

  DataRecord searchNextRecord(int startSearchAddr, int size) {
    final int startAddr = nextAddr(startSearchAddr);
    if (startAddr == null) return null;
    return makeRecord(startAddr, size);
  }

  DataRecord searchNextRecordAligned(int startSearchAddr, int size) {
    final int startAddr = nextAddr(startSearchAddr);
    if (startAddr == null) return null;
    final int mask = ~(math.pow(2, Math.log2(size).ceil()).toInt() - 1);
    return makeRecord(startAddr & mask, size);
  }
}
