import 'dart:convert';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart' as crypto;
import 'package:pointycastle/key_generators/rsa_key_generator.dart' as crypto;
import 'package:pointycastle/random/fortuna_random.dart' as crypto;
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:basic_utils/basic_utils.dart';

import 'cryptography.dart' as RsaEncrypt;

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

// Generates an RSA key pair
crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey> generateRSAKeyPair({int bitLength = 2048}) {
  final keyGen = crypto.RSAKeyGenerator()
    ..init(crypto.ParametersWithRandom(
      crypto.RSAKeyGeneratorParameters(
        BigInt.parse('65537'), // public exponent
        bitLength, // key size
        64, // certainty
      ),
      crypto.FortunaRandom(),
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

