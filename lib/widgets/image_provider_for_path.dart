import 'dart:io';

import 'package:flutter/widgets.dart';

import '../services/content_api.dart';

ImageProvider<Object> imageProviderForPath(String path) {
  final uri = Uri.tryParse(path);
  if (uri?.hasAuthority == true) return NetworkImage(path);
  if (path.startsWith('/public/media/')) {
    return NetworkImage(ContentApi().absoluteUrl(path));
  }
  return FileImage(File(path));
}
