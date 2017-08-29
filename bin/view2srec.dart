import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:srec_codec/srec_codec.dart';

Future bail(String message, int code) async {
  stdout.write(message);
  await stdout.flush();
  exit(1);
}

Future main(List<String> args) async {
  final argParser = new ArgParser();
  argParser.addOption('input',
      abbr: 'i', help: 'Specifies input SREC view file');
  argParser.addOption('output', abbr: 'o', help: 'Specifies output SREC file');
  argParser.addFlag('overwrite',
      abbr: 'w',
      help: 'Should existing output be overwritten?',
      defaultsTo: false);

  final ArgResults argRes = argParser.parse(args);

  final String argInput = argRes['input'];
  final String argOutput = argRes['output'];
  final bool argOverwrite = argRes['overwrite'];

  if (argInput == null) {
    await bail('Input file must be specified using -i option!', 1);
  }

  final File input = new File(argInput);
  if (!await input.exists()) {
    await bail('Input file not found!', 2);
  }

  final Stream<DataRecord> recs =
      SRecView.parseRecordsByteStream(input.openRead());

  if (argOutput == null) {
    recs.map((DataRecord rec) => rec.toSRec()).forEach(print);
  } else {
    final File output = new File(argOutput);
    if (await output.exists() && !argOverwrite) {
      await bail(
          'Output file exists! Add -w overwrite flag to overwrite the existing file',
          3);
    }
    final IOSink sink = output.openWrite();
    await sink.addStream(SRec.toSRecStream(recs));
    await sink.flush();
    await sink.close();
  }
}
