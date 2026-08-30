# Integrasi Pembayaran Midtrans

Integrasi gateway pembayaran yang aman untuk aplikasi Flutter menggunakan Supabase Edge Function. Pola ini melindungi kredensial API sensitif dari eksposur di sisi klien.

## Arsitektur

```
Aplikasi Flutter
    Γåô
Supabase Edge Function (Deno)
    Γö£ΓöÇ Validasi request
    Γö£ΓöÇ Menyimpan MIDTRANS_SERVER_KEY
    ΓööΓöÇ Memanggil Midtrans Snap API
         Γåô
    Midtrans Sandbox
```

**Manfaat Utama:**
- Server Key tidak pernah terbuka di aplikasi mobile
- Mencegah serangan reverse engineering/decompilation
- Validasi transaksi terpusat
- Mudah untuk monitoring dan audit API calls

## Model Keamanan

| Komponen | Penyimpanan | Risiko |
|----------|------------|--------|
| **Server Key** | Supabase Secrets | Γ£à Terlindungi |
| **Aplikasi Klien** | Kode Flutter | Γ¥î Bisa di-decompile |
| **Kredensial** | `.gitignore` | Γ£à Terlindungi |

## Prasyarat

- Proyek Supabase (untuk Edge Function)
- Akun Midtrans Sandbox
- Dart/Flutter SDK
- Pemahaman environment variables

## Konfigurasi

### 1. Setup Supabase

```bash
# Install Supabase CLI
npm install -g supabase

# Buat proyek baru atau gunakan yang sudah ada
supabase projects create petani-maju-payment
```

### 2. Variabel Environment

Buat file `secrets.json` (tambahkan ke `.gitignore`):

```json
{
  "SUPABASE_EDGE_URL": "https://xxxxx.supabase.co",
  "SUPABASE_EDGE_KEY": "eyJhbGc...",
  "MIDTRANS_SERVER_KEY": "SB-Mid-server-xxxxx"
}
```

**ΓÜá∩╕Å Catatan Keamanan:** Jangan pernah commit file ini ke version control.

### 3. Setup Edge Function

File: `supabase/functions/midtrans-snap/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const SNAP_URL = "https://app.sandbox.midtrans.com/snap/v1/transactions"

serve(async (req) => {
  // Penanganan CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    })
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    })
  }

  try {
    const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY")
    
    if (!MIDTRANS_SERVER_KEY) {
      return new Response(
        JSON.stringify({ error: "Server key not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    const body = await req.json()
    const { orderId, amount, planName, customerName, customerEmail } = body

    if (!orderId || !amount) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Buat Basic Auth header
    const auth = btoa(`${MIDTRANS_SERVER_KEY}:`)

    const transactionData = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      item_details: [
        {
          id: "premium-plan",
          price: amount,
          quantity: 1,
          name: planName || "Premium Subscription",
        },
      ],
      customer_details: {
        first_name: customerName,
        email: customerEmail,
      },
      credit_card: { secure: true },
    }

    const response = await fetch(SNAP_URL, {
      method: "POST",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(transactionData),
    })

    const data = await response.json()

    if (!response.ok) {
      throw new Error(data.message || "Midtrans API error")
    }

    return new Response(
      JSON.stringify({
        token: data.token,
        redirect_url: data.redirect_url,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

### 4. Deploy Edge Function

```bash
# Set secrets
supabase secrets set MIDTRANS_SERVER_KEY=your-key-here

# Deploy
supabase functions deploy midtrans-snap
```

### 5. Konfigurasi Flutter

File: `lib/core/constants/env_config.dart`

```dart
class EnvConfig {
  static String get supabaseEdgeUrl =>
      const String.fromEnvironment('SUPABASE_EDGE_URL');
      
  static String get supabaseEdgeKey =>
      const String.fromEnvironment('SUPABASE_EDGE_KEY');
}
```

File: `lib/core/services/midtrans_service.dart`

```dart
Future<void> createTransaction({
  required String orderId,
  required int amount,
  required String planName,
  required String customerName,
  required String customerEmail,
}) async {
  final supabaseUrl = EnvConfig.supabaseEdgeUrl;
  final supabaseAnonKey = EnvConfig.supabaseEdgeKey;

  final response = await http.post(
    Uri.parse('$supabaseUrl/functions/v1/midtrans-snap'),
    headers: {
      'Authorization': 'Bearer $supabaseAnonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'orderId': orderId,
      'amount': amount,
      'planName': planName,
      'customerName': customerName,
      'customerEmail': customerEmail,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final redirectUrl = data['redirect_url'];
    
    if (redirectUrl != null) {
      await launchUrl(
        Uri.parse(redirectUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  } else {
    throw Exception('Payment initialization failed');
  }
}
```

### 6. Jalankan Development

```bash
flutter run --dart-define-from-file=secrets.json
```

## Penggunaan

### Inisialisasi Pembayaran

```dart
final midtransService = MidtransService();

await midtransService.createTransaction(
  planName: '1 Bulan',
  amount: 29000,
  customerName: 'John Doe',
  customerEmail: 'john@example.com',
);
```

### Format API Request

**Endpoint:** `POST /functions/v1/midtrans-snap`

**Headers:**
```
Authorization: Bearer YOUR_ANON_KEY
Content-Type: application/json
```

**Body:**
```json
{
  "orderId": "PM-1BUL-1788055439620",
  "amount": 29000,
  "planName": "1 Bulan",
  "customerName": "John Doe",
  "customerEmail": "john@example.com"
}
```

### Format API Response

**Sukses (200):**
```json
{
  "token": "48d3dff607dd7225dab0f21456c4c446200a9a9e60b3a920",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/48d3dff607dd7225dab0f21456c4c446200a9a9e60b3a920"
}
```

**Error (400/401/500):**
```json
{
  "error": "Missing required fields"
}
```

## Troubleshooting

| Masalah | Penyebab | Solusi |
|--------|---------|--------|
| **401 Unauthorized** | Server Key tidak valid/hilang | Verifikasi key di Supabase Secrets ΓåÆ Redeploy function |
| **500 Server Error** | Env variable tidak ter-load | Periksa `MIDTRANS_SERVER_KEY` ada ΓåÆ Redeploy |
| **CORS Error** | OPTIONS tidak ditangani | Verifikasi CORS headers di Edge Function |
| **QR tidak muncul** | Akun belum activated | Selesaikan Midtrans Business Registration |
| **Error "unparsable"** | Order ID digunakan sebagai QR | Gunakan QR yang dihasilkan Midtrans setelah pilih metode pembayaran |

## Best Practices

- Γ£à Simpan `MIDTRANS_SERVER_KEY` hanya di Supabase Secrets
- Γ£à Jangan hardcode kredensial di kode
- Γ£à Tambahkan `secrets.json` ke `.gitignore`
- Γ£à Regenerate keys jika ter-expose
- Γ£à Gunakan proyek Supabase terpisah untuk infrastruktur pembayaran
- Γ£à Log semua percobaan transaksi untuk audit trail
- Γ¥î Jangan pass Server Key melalui environment variables di git
- Γ¥î Jangan simpan keys di kode aplikasi atau dokumentasi

## Referensi Tambahan

- [Dokumentasi Midtrans](https://docs.midtrans.com)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Dokumentasi Deno](https://deno.land)
