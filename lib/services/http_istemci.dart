// Paylaşılan HTTP istemcisinin platforma göre kurulumu (web'de dart:io yok).
export 'http_istemci_varsayilan.dart'
    if (dart.library.io) 'http_istemci_io.dart';
