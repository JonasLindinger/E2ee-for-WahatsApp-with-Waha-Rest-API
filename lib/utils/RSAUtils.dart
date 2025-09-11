import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RSAUtils {
  static const keysPrefName = "KEYS";

  Future<String> GetPublicKeyAsString() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    dynamic keys = prefs.getStringList(keysPrefName);

    if (keys == null) {
      await CreatePersonalKeys();
    }

    keys = prefs.getStringList(keysPrefName);

    // Share keys
    return keys[0]; // 0 -> public key
  }

  Future<RSAPrivateKey> GetPrivateKey() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    dynamic keys = prefs.getStringList(keysPrefName);

    if (keys == null) {
      await CreatePersonalKeys();
    }

    keys = prefs.getStringList(keysPrefName);

    // Share keys
    return privateKeyFromString(keys[1]); // 1 -> private key
  }

  Future<void> CreatePersonalKeys() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Create keys
    final keyPair = generateRSAKeyPair();
    final publicKey = keyPair.publicKey;
    final privateKey = keyPair.privateKey;

    final publicKeyStr = publicKeyToString(publicKey);
    final privateKeyStr = privateKeyToString(privateKey);

    await prefs.setStringList(keysPrefName, [publicKeyStr, privateKeyStr]);
  }

  /// Generate a new RSA key pair
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair(
      {int bitLength = 2048}) {
    final secureRandom = FortunaRandom();
    final random = SecureRandom("Fortuna")
      ..seed(KeyParameter(_seed()));

    secureRandom.seed(KeyParameter(_seed()));

    final rsaParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 12);
    final rngParams = ParametersWithRandom(rsaParams, secureRandom);

    final generator = RSAKeyGenerator()..init(rngParams);
    return generator.generateKeyPair();
  }

  /// Helper to create random seed
  static Uint8List _seed() {
    final random = SecureRandom("Fortuna");
    final seed = List<int>.generate(32, (_) => DateTime.now().microsecondsSinceEpoch % 256);
    return Uint8List.fromList(seed);
  }

  /// Convert Public Key to Base64 String
  static String publicKeyToString(RSAPublicKey publicKey) {
    final modulus = base64Encode(_encodeBigInt(publicKey.modulus!));
    final exponent = base64Encode(_encodeBigInt(publicKey.exponent!));
    return jsonEncode({'modulus': modulus, 'exponent': exponent});
  }

  /// Convert String to Public Key
  static RSAPublicKey publicKeyFromString(String keyString) {
    final data = jsonDecode(keyString);
    final modulus = _decodeBigInt(base64Decode(data['modulus']));
    final exponent = _decodeBigInt(base64Decode(data['exponent']));
    return RSAPublicKey(modulus, exponent);
  }

  /// Convert Private Key to Base64 String
  static String privateKeyToString(RSAPrivateKey privateKey) {
    final modulus = base64Encode(_encodeBigInt(privateKey.modulus!));
    final exponent = base64Encode(_encodeBigInt(privateKey.exponent!));
    final p = base64Encode(_encodeBigInt(privateKey.p!));
    final q = base64Encode(_encodeBigInt(privateKey.q!));
    return jsonEncode({'modulus': modulus, 'exponent': exponent, 'p': p, 'q': q});
  }

  /// Convert String to Private Key
  static RSAPrivateKey privateKeyFromString(String keyString) {
    final data = jsonDecode(keyString);
    final modulus = _decodeBigInt(base64Decode(data['modulus']));
    final exponent = _decodeBigInt(base64Decode(data['exponent']));
    final p = _decodeBigInt(base64Decode(data['p']));
    final q = _decodeBigInt(base64Decode(data['q']));
    return RSAPrivateKey(modulus, exponent, p, q);
  }

  /// Encrypt with public key
  static String encrypt(String plaintext, RSAPublicKey publicKey) {
    final cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return base64Encode(encrypted);
  }

  /// Decrypt with private key
  static String decrypt(String ciphertext, RSAPrivateKey privateKey) {
    final cipher = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(base64Decode(ciphertext));
    return utf8.decode(decrypted);
  }

  /// BigInt Encoding / Decoding helpers
  static Uint8List _encodeBigInt(BigInt number) {
    final byteMask = BigInt.from(0xff);
    var temp = number;
    final result = <int>[];
    while (temp > BigInt.zero) {
      result.insert(0, (temp & byteMask).toInt());
      temp = temp >> 8;
    }
    return Uint8List.fromList(result);
  }

  static BigInt _decodeBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}