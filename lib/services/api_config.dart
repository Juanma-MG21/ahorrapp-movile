// ApiConfig.token debería leer el token guardado
// (por ejemplo con flutter_secure_storage o shared_preferences).

class ApiConfig {
  // TODO: cambia esto por la IP/dominio real de tu backend.
  // - Si pruebas en un emulador Android, "localhost" del backend
  //   normalmente se accede como 10.0.2.2
  // - Si pruebas en un celular físico en la misma red, usa la IP local
  //   de tu PC, ej: http://192.168.1.10:3000
  static const String baseUrl = 'http://172.25.240.1/api';

  // TODO: token de prueba, SOLO para poder probar la pantalla de QR
  // mientras no existe login. Bórralo cuando conectes autenticación real.
  static const String tempToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwicm9sZXMiOltdLCJpYXQiOjE3ODIzMTc4NDAsImV4cCI6MTc4MjM0NjY0MH0.WdAnVuSI2l-ygzrSjI4AYKqIRHeeK5q9j-jANFSqVL4';

  /// Headers estándar para llamadas autenticadas.
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $tempToken',
  };
}