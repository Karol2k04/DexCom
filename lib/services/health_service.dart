// Conditional export: use a native implementation on mobile/desktop and a web stub for web builds.
export 'health_service_io.dart'
    if (dart.library.html) 'health_service_web.dart';
