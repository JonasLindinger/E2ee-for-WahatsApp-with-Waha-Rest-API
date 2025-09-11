/*
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart' as crypto;
import 'package:pointycastle/key_generators/rsa_key_generator.dart' as crypto;
import 'package:pointycastle/random/fortuna_random.dart' as crypto;
import 'package:pointycastle/api.dart' as crypto;
import 'package:basic_utils/basic_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';

const keysPrefName = "KEYS";

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
  return pemToPrivateKey(keys[1]); // 1 -> private key
}

Future<void> CreatePersonalKeys() async {
  // Obtain shared preferences.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Create keys
  final keyPair = generateRSAKeyPair();
  final publicKey = keyPair.publicKey as RSAPublicKey;
  final privateKey = keyPair.privateKey as RSAPrivateKey;

  final publicPem = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
  final privatePem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);

  await prefs.setStringList(keysPrefName, [publicPem, privatePem]);
}

RSAPublicKey pemToPublicKey(String pem) {
  // Auto-detects PKCS#1/SPKI in most cases
  return CryptoUtils.rsaPublicKeyFromPem(pem);
  // If you know it’s PKCS#1 only, some versions also provide:
  // return CryptoUtils.rsaPublicKeyFromPemPkcs1(pem);
}

RSAPrivateKey pemToPrivateKey(String pem) {
  // Auto-detects PKCS#1/PKCS#8 in most cases
  return CryptoUtils.rsaPrivateKeyFromPem(pem);
  // If you know the exact format, you can use the specific variant too.
}

// Generates an RSA key pair
crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey> generateRSAKeyPair({int bitLength = 2048}) {
  // Seed the PRNG
  final secureRandom = crypto.FortunaRandom();
  final seed = Uint8List(32);
  final rnd = Random.secure();
  for (var i = 0; i < seed.length; i++) {
    seed[i] = rnd.nextInt(256);
  }
  secureRandom.seed(crypto.KeyParameter(seed));

  final keyGen = crypto.RSAKeyGenerator()
    ..init(crypto.ParametersWithRandom(
      crypto.RSAKeyGeneratorParameters(
        BigInt.parse('65537'), // public exponent
        bitLength,             // key size
        64,                    // certainty
      ),
      secureRandom,
    ));
  return keyGen.generateKeyPair();
}

// Generate a random AES key (256-bit)
Uint8List generateAesKey() {
  final rnd = Random.secure();
  return Uint8List.fromList(List.generate(32, (_) => rnd.nextInt(256)));
}

// AES encryption
Uint8List aesEncrypt(Uint8List key, String plaintext) {
  final iv = Uint8List(16); // you should use a random IV per message in production!
  final params = ParametersWithIV(KeyParameter(key), iv);
  final cipher = CBCBlockCipher(AESEngine())..init(true, params);

  // PKCS7 padding
  final padder = PKCS7Padding();
  var input = Uint8List.fromList(utf8.encode(plaintext));
  int padLen = 16 - (input.length % 16);
  input = Uint8List.fromList(input + List.filled(padLen, padLen));

  final output = Uint8List(input.length);
  for (var offset = 0; offset < input.length; offset += 16) {
    cipher.processBlock(input, offset, output, offset);
  }
  return output;
}

// AES decryption
String aesDecrypt(Uint8List key, Uint8List ciphertext) {
  final iv = Uint8List(16);
  final params = ParametersWithIV(KeyParameter(key), iv);
  final cipher = CBCBlockCipher(AESEngine())..init(false, params);

  final output = Uint8List(ciphertext.length);
  for (var offset = 0; offset < ciphertext.length; offset += 16) {
    cipher.processBlock(ciphertext, offset, output, offset);
  }

  // Remove PKCS7 padding
  final padLen = output.last;
  final unpadded = output.sublist(0, output.length - padLen);
  return utf8.decode(unpadded);
}

// Hybrid encrypt: returns a map with both encrypted AES key and ciphertext
Map<String, String> hybridEncrypt(String plaintext, RSAPublicKey publicKey) {
  final aesKey = generateAesKey();
  final encryptedMessage = aesEncrypt(aesKey, plaintext);
  final encryptedKey = rsa.encrypt(base64Encode(aesKey), publicKey);

  return {
    "encryptedKey": encryptedKey,
    "encryptedMessage": base64Encode(encryptedMessage),
  };
}

// Hybrid decrypt: takes encrypted key + encrypted message
String hybridDecrypt(String encryptedKey, String encryptedMessage, RSAPrivateKey privateKey) {
  final aesKeyBase64 = rsa.decrypt(encryptedKey, privateKey);
  final aesKey = base64Decode(aesKeyBase64);
  final messageBytes = base64Decode(encryptedMessage);

  return aesDecrypt(aesKey, messageBytes);
}
*/