// Copyright (c) 2017, Ravi Teja Gudapati. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:srec_codec/srec_codec.dart';

main() async {
  final String filename = 'data/srecs/iodesc_iqs.srec';
  File file = new File(filename);
  final result = await SRec.parseRecordsByteStream(file.openRead());
  print(result);
}
