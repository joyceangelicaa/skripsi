// File ini otomatis milih implementasi sesuai platform:
// - Web (dart.library.html tersedia) → pakai _web.dart (AnchorElement)
// - Mobile/Desktop (dart.library.html tdk tersedia) → pakai _mobile.dart (path_provider + share_plus)
export 'pdf_download_helper_mobile.dart'
    if (dart.library.html) 'pdf_download_helper_web.dart';
