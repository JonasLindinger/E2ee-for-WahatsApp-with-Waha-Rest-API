import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart'; // <-- needed for PEM encode/decode
import 'package:shared_preferences/shared_preferences.dart';

class RSAUtils {
  static const keysPrefName = "KEYS";

  Future<String> GetPublicKeyAsString() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? keys = prefs.getStringList(keysPrefName);
    if (keys == null) {
      await CreatePersonalKeys();
      keys = prefs.getStringList(keysPrefName);
    }

    return keys![0]; // PEM public key
  }

  Future<RSAPrivateKey> GetPrivateKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? keys = prefs.getStringList(keysPrefName);
    if (keys == null) {
      await CreatePersonalKeys();
      keys = prefs.getStringList(keysPrefName);
    }

    return privateKeyFromString(keys![1]); // PEM private key
  }

  Future<void> CreatePersonalKeys() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final keyPair = generateRSAKeyPair();
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    // Convert to PEM
    final publicKeyPem = publicKeyToString(publicKey);
    final privateKeyPem = privateKeyToString(privateKey);

    await prefs.setStringList(keysPrefName, [publicKeyPem, privateKeyPem]);
  }

  /// Generate a new RSA key pair
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair(
      {int bitLength = 2048}) {
    final secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(_seed()));

    final rsaParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 12);
    final rngParams = ParametersWithRandom(rsaParams, secureRandom);

    final generator = RSAKeyGenerator()..init(rngParams);
    return generator.generateKeyPair();
  }

  static Uint8List _seed() {
    final seed = List<int>.generate(32, (_) => DateTime.now().microsecondsSinceEpoch % 256);
    return Uint8List.fromList(seed);
  }

  /// ---- PEM ONLY ----

  /// Convert Public Key to PEM string
  static String publicKeyToString(RSAPublicKey publicKey) {
    return CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
  }

  /// Convert PEM string to Public Key
  static RSAPublicKey publicKeyFromString(String pemString) {
    return CryptoUtils.rsaPublicKeyFromPemPkcs1(pemString);
  }

  /// Convert Private Key to PEM string
  static String privateKeyToString(RSAPrivateKey privateKey) {
    return CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);
  }

  /// Convert PEM string to Private Key
  static RSAPrivateKey privateKeyFromString(String pemString) {
    return CryptoUtils.rsaPrivateKeyFromPemPkcs1(pemString);
  }

  /// Encrypt with public key
  static String encrypt(String plaintext, RSAPublicKey publicKey) {
    final cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return base64Encode(encrypted); // <- use Dart's base64Encode
  }

  /// Decrypt with private key
  static String decrypt(String ciphertext, RSAPrivateKey privateKey) {
    final cipher = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(base64Decode(ciphertext)); // <- use Dart's base64Decode
    return utf8.decode(decrypted);
  }
}