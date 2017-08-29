import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:srec_codec/src/srec_print/parser.dart';

Future main(List<String> args) async {
  final argParser = new ArgParser();
  argParser.addOption('input',
      abbr: 'i', help: 'Specifies input SREC view file');
  argParser.addOption('output', abbr: 'o', help: 'Specifies output SREC file');

  final ArgResults argRes = argParser.parse(args);

  if (argRes['input'] == null) {
    stdout.write('Input file must be specified using -i option!');
    exit(1);
  }

  /* TODO
  if(argRes['output'] == null) {
    stdout.write('Output file must be specified using -o option!');
    exit(1);
  }
  */

  final File input = new File(argRes['input']);
  if (!await input.exists()) {
    stdout.write('Input file not found!');
    exit(1);
  }

  final Stream<String> lines =
      input.openRead().transform(UTF8.decoder).transform(new LineSplitter());

  await lines.map(parseSrecView).map(toSrecView).forEach(print);

  //TODO
}
