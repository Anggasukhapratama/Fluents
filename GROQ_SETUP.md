# 🚀 SETUP GROQ API - SUPER CEPAT & GRATIS!

## ✨ Keunggulan Groq vs Gemini

| Feature | Groq | Gemini |
|---------|------|--------|
| **Kecepatan** | ~100 tokens/detik ⚡ | ~10 tokens/detik 🐌 |
| **Gratis** | 14,400 requests/hari 🆓 | 20 requests/hari 💸 |
| **Model** | Llama 3.1 8B (Pintar) 🧠 | Gemini 2.5 Flash |
| **Reliability** | Sangat Stabil ✅ | Sering Rate Limit ❌ |

---

## 🔧 CARA SETUP (5 MENIT)

### 1. **Daftar Akun Groq** (GRATIS)
1. Buka: https://console.groq.com
2. Klik **"Sign Up"** 
3. Daftar dengan email/Google account
4. Verifikasi email jika diminta

### 2. **Buat API Key**
1. Setelah login, klik **"API Keys"** di sidebar
2. Klik **"Create API Key"**
3. Beri nama: `FluentAI-Key-1`
4. **COPY** API Key yang muncul (format: `gsk_xxxxx...`)
5. ⚠️ **SIMPAN BAIK-BAIK** - key ini tidak akan muncul lagi!

### 3. **Masukkan API Key ke Aplikasi**
1. Buka file: `lib/app/services/groq_service.dart`
2. Cari bagian `_apiKeys` (sekitar baris 15)
3. Ganti placeholder dengan API Key Anda:

```dart
static const List<String> _apiKeys = [
  'gsk_PASTE_API_KEY_ANDA_DISINI', // ← Ganti ini!
  // 'gsk_API_KEY_KEDUA_OPSIONAL',   // ← Backup (opsional)
];
```

### 4. **Test Koneksi**
Jalankan aplikasi dan coba fitur AI. Jika berhasil, Anda akan melihat response yang jauh lebih cepat!

---

## 💡 TIPS OPTIMASI

### **Buat Multiple API Keys (Recommended)**
Untuk performa maksimal, buat 2-3 API key dengan akun berbeda:

```dart
static const List<String> _apiKeys = [
  'gsk_KEY_DARI_AKUN_1',  // Email utama
  'gsk_KEY_DARI_AKUN_2',  // Email kedua  
  'gsk_KEY_DARI_AKUN_3',  // Email ketiga
];
```

### **Monitor Usage**
- Cek usage di: https://console.groq.com/usage
- Limit: 14,400 requests/hari per akun
- Reset setiap hari pada 00:00 UTC

### **Troubleshooting**
- **Error 401**: API Key salah/expired
- **Error 429**: Rate limit (otomatis switch ke key lain)
- **Error 500**: Server Groq down (jarang terjadi)

---

## 📊 MONITORING

Untuk melihat status AI service:

```dart
// Di controller atau service Anda:
final groqService = GroqService();
groqService.printStatus(); // Print ke console
```

Output contoh:
```
📊 GroqService Status:
   Service: Groq API (llama-3.1-8b-instant)
   Active Key: #1 of 3
   Success Rate: 98.5% (197/200)
   Errors: 3
   Key #1: (ready) ← AKTIF
   Key #2: (ready)
   Key #3: (cooldown: 45s)
```

---

## 🎯 HASIL YANG DIHARAPKAN

Setelah setup berhasil:
- ⚡ **Response 5-10x lebih cepat**
- 🆓 **14,400 requests/hari (vs 20 di Gemini)**
- ✅ **Lebih stabil, jarang error**
- 🧠 **Kualitas jawaban tetap bagus**

---

## 🆘 BUTUH BANTUAN?

1. **API Key tidak work**: Pastikan copy paste benar, tidak ada spasi extra
2. **Masih lambat**: Cek internet, atau coba restart aplikasi
3. **Error terus**: Cek apakah API key sudah benar di `groq_service.dart`

**Happy Coding! 🚀**