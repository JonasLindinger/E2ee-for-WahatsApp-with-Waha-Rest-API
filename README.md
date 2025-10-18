# AI Generated README ✅

# E2EE for WhatsApp

**E2EE** is a secure messaging solution for WhatsApp users who want true privacy. With end-to-end encryption implemented on top of WhatsApp, your messages are fully encrypted so that even WhatsApp itself cannot read what you share with your friends.  

> ⚠️ **Disclaimer:** This project uses the Waha library, which is **not officially supported by WhatsApp** and may not be 100% legal in some jurisdictions. This project is intended **for educational purposes only**. Use at your own risk.

This project allows you to send RSA-encrypted messages in private (1-to-1) chats while retaining access to all your WhatsApp functionality.

---

## 🚀 Features

- **RSA Encrypted Key Exchange**  
  Securely exchange chat keys between users to enable encrypted communication.

- **Encrypted Messaging**  
  Send messages that are fully encrypted, readable only by you and the intended recipient.

- **Full WhatsApp Integration**  
  Access your chats, voice messages, videos, and photos. Works alongside the normal WhatsApp client.

---

## 🛠️ Installation

1. Install the [Flutter SDK](https://flutter.dev/docs/get-started/install).  
2. Set up a **Waha Server**.  
3. Clone this repository:  
   ```bash
   git clone <repository-url>
   ```
4. Create a .env file in the project root containing:
 ```bash
   SERVER_IP_ADDRESS="http://[IPv4]:[PORT]"
```
5. Start the Flutter app in your browser on your PC.
6. Scan the displayed QR code with your WhatsApp account on your phone. This will link your WhatsApp account to the Waha Server.
7. Run the Flutter app on your phone (connect it to your PC).
8. You should be logged in automatically and see all your chats.
9. You can now send messages to any chat, including previous messages, voice notes, videos, and photos.
10. When another friend uses this app (with their own server), request chat keys. The app will automatically generate RSA chat keys for encrypted messaging.
11. Toggle the encryption button next to your text input field to send encrypted messages. Encrypted messages are unreadable in the standard WhatsApp client.

⚠️ Known Limitations / TODOs
File sending support
Voice message sending support
Waha server IP configuration (instead of .env file)
Waha API key support
HTTPS support for Waha server
Smoother loading and UI improvements
Encrypted file and voice message support
Contacts, Status, and additional WhatsApp features
Settings: colors, blur effects, and more

💡 Notes
This project is meant for users who prioritize privacy and want additional encryption on top of WhatsApp.
Each user must have their own Waha server to enable encrypted chats.
Encryption is optional and can be toggled per chat.
Keep your conversations private. Even WhatsApp won't be able to read them!

If you want, I can also make a **super-compact, visually appealing version with badges, sections for screenshots, and feature icons** that would look professional on GitHub. It would make your project look more “polished” for users.  
Do you want me to do that?
