import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/main.dart';
import 'package:ddd/splash.dart';

class D {
  static final _instance = D._internal();
  factory D() => _instance;
  D._internal();
  String? deviceId;
  String get _adbPath => SplashScreen.adbPath!;
  Future<List<String>> listDevices() async {
    final result = await Process.run(_adbPath, ['devices'], runInShell: true);
    if (result.exitCode != 0) return [];
    final lines = result.stdout.toString().split('\n');
    final List<String> currentDevices = [];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') currentDevices.add(parts[0]);
    }
    if (currentDevices.isEmpty) {
      deviceId = null;
    } else if (deviceId == null || !currentDevices.contains(deviceId))
      deviceId = currentDevices.first;
    return currentDevices;
  }

  Future<String> execute(String command, L l) async {
    if (deviceId == null) return '';
    final result = await Process.run(_adbPath, ['-s', deviceId!, ...command.trim().split(RegExp(r'\s+'))], runInShell: true);
    return result.exitCode == 0 ? (result.stdout.toString().trim().isEmpty ? 'N/A' : result.stdout.toString().trim()) : '';
  }

  Future<Process> executeStream(String command) async {
    List<String> args = deviceId != null ? ['-s', deviceId!] : [];
    args.addAll(command.trim().split(RegExp(r'\s+')));
    return await Process.start(_adbPath, args, runInShell: true);
  }
}

class DeviceSelector extends StatefulWidget {
  final Function()? onDeviceSelected;
  const DeviceSelector({super.key, this.onDeviceSelected});
  @override
  State<DeviceSelector> createState() => _DeviceSelectorState();
}

class _DeviceSelectorState extends State<DeviceSelector> {
  final _adb = D();
  List<String> _devices = [];
  Process? _tracker;
  late L l;
  @override
  void initState() {
    super.initState();
    _fetch();
    _initTracker();
  }

  @override
  void dispose() {
    _tracker?.kill();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l = L.of(context)!;
  }

  void _initTracker() async {
    _tracker = await _adb.executeStream('track-devices');
    _tracker?.stdout.transform(utf8.decoder).listen((data) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() async {
    final devices = await _adb.listDevices();
    if (mounted) setState(() => _devices = devices);
  }

  @override
  Widget build(BuildContext context) {
    if (_devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l.no_device, style: kText(context).copyWith(color: Colors.red)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isSelected = _adb.deviceId == device;
        return ListTile(
          selected: isSelected,
          dense: true,
          title: Text(
            device,
            style: kText(context).copyWith(color: isSelected ? Theme.of(context).colorScheme.primary : null, fontWeight: isSelected ? FontWeight.bold : FontWeight.w300),
          ),
          onTap: () {
            setState(() => _adb.deviceId = device);
            widget.onDeviceSelected?.call();
          },
        );
      },
    );
  }
}
