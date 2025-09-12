import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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

    final publicKeyPem = publicKeyToString(publicKey);
    final privateKeyPem = privateKeyToString(privateKey);

    await prefs.setStringList(keysPrefName, [publicKeyPem, privateKeyPem]);
  }

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
  static String publicKeyToString(RSAPublicKey publicKey) =>
      CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
  static RSAPublicKey publicKeyFromString(String pem) =>
      CryptoUtils.rsaPublicKeyFromPemPkcs1(pem);
  static String privateKeyToString(RSAPrivateKey privateKey) =>
      CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);
  static RSAPrivateKey privateKeyFromString(String pem) =>
      CryptoUtils.rsaPrivateKeyFromPemPkcs1(pem);

  static String encryptHybridToString(String plaintext, RSAPublicKey publicKey) {
    var map = encryptHybrid(plaintext, publicKey);
    String jsonString = jsonEncode(map);
    return jsonString;
  }

  static String decryptHybridFromString(String payload, RSAPrivateKey privateKey) {
    Map<String, String> myMap = Map<String, String>.from(jsonDecode(payload));
    var decryptedMessage = decryptHybrid(myMap, privateKey);
    return decryptedMessage;
  }

  static Map<String, String> encryptHybrid(String plaintext, RSAPublicKey publicKey) {
    // 1. Generate random 128-bit AES key
    final aesKey = Uint8List(16);
    final rng = Random.secure();
    for (int i = 0; i < aesKey.length; i++) aesKey[i] = rng.nextInt(256);

    // 2. Encrypt plaintext with AES
    final iv = Uint8List(16);
    for (int i = 0; i < iv.length; i++) iv[i] = rng.nextInt(256);

    final cipher = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESFastEngine()));
    cipher.init(true, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(aesKey), iv), null));
    final encryptedMessage = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));

    // 3. Encrypt AES key with RSA using OAEP padding
    final oaepEncrypt = OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final encryptedKey = oaepEncrypt.process(aesKey);

    return {
      "key": base64Encode(encryptedKey),
      "iv": base64Encode(iv),
      "message": base64Encode(encryptedMessage),
    };
  }

  static String decryptHybrid(Map<String, String> payload, RSAPrivateKey privateKey) {
    final encryptedKey = base64Decode(payload["key"]!);
    final iv = base64Decode(payload["iv"]!);
    final encryptedMessage = base64Decode(payload["message"]!);

    // 1. Decrypt AES key with RSA using OAEP padding
    final oaepDecrypt = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final aesKey = oaepDecrypt.process(encryptedKey);

    // 2. Decrypt message with AES
    final cipher = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESFastEngine()));
    cipher.init(false, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(aesKey), iv), null));
    final decrypted = cipher.process(encryptedMessage);

    return utf8.decode(decrypted);
  }
}