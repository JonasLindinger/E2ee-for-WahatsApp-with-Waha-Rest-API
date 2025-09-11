import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart' as crypto;
import 'package:pointycastle/key_generators/rsa_key_generator.dart' as crypto;
import 'package:pointycastle/random/fortuna_random.dart' as crypto;
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:basic_utils/basic_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cryptography.dart' as RsaEncrypt;

const keysPrefName = "KEYS";

void main() {
  // 1. Generate RSA key pair
  final keyPair = generateRSAKeyPair();
  final publicKey = keyPair.publicKey as RSAPublicKey;
  final privateKey = keyPair.privateKey as RSAPrivateKey;

  print("Public Key: ${CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey)}");
  print("Private Key: ${CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey)}");

  // 2. Encrypt a string using the public key
  String message = "Hello Flutter!";
  String encrypted = encrypt(message, publicKey);
  print("Encrypted: $encrypted");

  // 3. Decrypt using the private key
  String decrypted = decrypt(encrypted, privateKey);
  print("Decrypted: $decrypted");
}

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

String publicKeyToPem(RSAPublicKey publicKey) {
  // Option A: PKCS#1
  return CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
  // Option B (also common): SubjectPublicKeyInfo (SPKI)
  // return CryptoUtils.encodeRSAPublicKeyToPemSpki(publicKey);
}

String privateKeyToPem(RSAPrivateKey privateKey) {
  // Option A: PKCS#1
  return CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);
  // Option B: PKCS#8
  // return CryptoUtils.encodeRSAPrivateKeyToPemPkcs8(privateKey);
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

// Encrypt string with public key
String encrypt(String plaintext, RSAPublicKey publicKey) {
  var RsaEncrypt;
  final encrypted = RsaEncrypt.encryptString(plaintext, publicKey);
  return base64Encode(encrypted);
}

// Decrypt string with private key
String decrypt(String encryptedBase64, RSAPrivateKey privateKey) {
  final encryptedBytes = base64Decode(encryptedBase64);
  return RsaEncrypt.decrypt(encryptedBytes as String, privateKey);
}

