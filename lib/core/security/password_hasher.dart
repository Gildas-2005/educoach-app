import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Hachage de mot de passe 100 % Dart, sans dépendance externe.
///
/// Algorithme : SHA-256 (implémentation publique FIPS 180-4 ci-dessous)
/// enchaîné sur N rounds, avec un sel aléatoire par compte généré via
/// [Random.secure]. Le format stocké est `v1$iter$hexSel$hexHash`, auto-descriptif,
/// ce qui permet une vérification sans jamais conserver le mot de passe
/// en clair.
class PasswordHasher {
  const PasswordHasher._();

  static const int _iterations = 2000;
  static const String _prefix = 'v1';

  static final Random _rng = Random.secure();

  /// Génère un sel hexadécimal de 16 octets.
  static String generateSalt() {
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _rng.nextInt(256)),
    );
    return _hex(bytes);
  }

  /// Produit un hash vérifiable : `v1$iterations$salt$digest`.
  static String hash(String password, String salt) {
    final input = Uint8List.fromList(utf8.encode('$salt:$password'));
    final digest = _iterate(input, _iterations);
    return '$_prefix\$$_iterations\$$salt\$${_hex(digest)}';
  }

  /// Vérifie un mot de passe contre un hash stocké, en temps constant.
  static bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    final salt = parts[2];
    final expected = parts[3];
    final input = Uint8List.fromList(utf8.encode('$salt:$password'));
    final actual = _hex(_iterate(input, iterations));
    return _constantTimeEquals(actual, expected);
  }

  /// Mots de passe faibles couramment refusés — rejet explicite côté
  /// inscription pour éviter les mots de passe trivials.
  static const _commonPasswords = <String>{
    '123456',
    '12345678',
    'password',
    'azerty',
    'qwerty',
    '111111',
    'admin123',
    'educoach',
    '000000',
    '123456789',
  };

  /// Retourne un message d'erreur, ou null si le mot de passe est acceptable.
  static String? validateStrength(String password) {
    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (!password.contains(RegExp(r'[A-Za-zÀ-ÿ]'))) {
      return 'Le mot de passe doit contenir au moins une lettre.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre.';
    }
    if (_commonPasswords.contains(password.toLowerCase())) {
      return 'Ce mot de passe est trop courant, choisissez-en un autre.';
    }
    return null;
  }

  static Uint8List _iterate(Uint8List input, int iterations) {
    var current = _sha256(input);
    for (var i = 1; i < iterations; i++) {
      current = _sha256(current);
    }
    return current;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String _hex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  // ---------------------------------------------------------------------------
  // SHA-256 — FIPS 180-4.
  // ---------------------------------------------------------------------------
  static final _k = Uint32List.fromList(<int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ]);

  static Uint8List _sha256(Uint8List message) {
    final h = Uint32List.fromList(<int>[
      0x6a09e667,
      0xbb67ae85,
      0x3c6ef372,
      0xa54ff53a,
      0x510e527f,
      0x9b05688c,
      0x1f83d9ab,
      0x5be0cd19,
    ]);

    // Padding : 0x80, zéros, longueur en bits sur 64 bits big-endian.
    final bitLen = message.length * 8;
    final paddedLen = ((message.length + 9) / 64).ceil() * 64;
    final padded = Uint8List(paddedLen);
    padded.setRange(0, message.length, message);
    padded[message.length] = 0x80;
    final view = ByteData.sublistView(padded);
    view.setUint32(paddedLen - 8, bitLen >>> 32);
    view.setUint32(paddedLen - 4, bitLen & 0xFFFFFFFF);

    final w = Uint32List(64);
    for (var chunk = 0; chunk < paddedLen; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = view.getUint32(chunk + i * 4);
      }
      for (var i = 16; i < 64; i++) {
        final s0 =
            _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        final s1 =
            _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }

      var a = h[0], b = h[1], c = h[2], d = h[3];
      var e = h[4], f = h[5], g = h[6], hh = h[7];

      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ (~e & 0xFFFFFFFF & g);
        final temp1 = (hh + s1 + ch + _k[i] + w[i]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xFFFFFFFF;
        hh = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h[0] = (h[0] + a) & 0xFFFFFFFF;
      h[1] = (h[1] + b) & 0xFFFFFFFF;
      h[2] = (h[2] + c) & 0xFFFFFFFF;
      h[3] = (h[3] + d) & 0xFFFFFFFF;
      h[4] = (h[4] + e) & 0xFFFFFFFF;
      h[5] = (h[5] + f) & 0xFFFFFFFF;
      h[6] = (h[6] + g) & 0xFFFFFFFF;
      h[7] = (h[7] + hh) & 0xFFFFFFFF;
    }

    final out = Uint8List(32);
    final outView = ByteData.sublistView(out);
    for (var i = 0; i < 8; i++) {
      outView.setUint32(i * 4, h[i]);
    }
    return out;
  }

  /// SHA-256 d'un texte UTF-8, en hexadécimal (exposé pour les tests ;
  /// permet de valider l'implémentation contre les vecteurs FIPS 180-4).
  static String sha256Hex(String text) =>
      _hex(_sha256(Uint8List.fromList(utf8.encode(text))));

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
}
