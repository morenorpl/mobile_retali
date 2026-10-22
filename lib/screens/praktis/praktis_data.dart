import 'praktis_models.dart';

const praktisSections = <PraktisSection>[
  // ===== Dokumen & Keuangan =====
  PraktisSection(
    id: 'doc_money',
    title: 'Dokumen & Uang',
    entries: [
      PraktisEntry(
        title: 'Dokumen Wajib',
        bullets: [
          'Paspor (masa berlaku ≥ 6 bulan), e-Visa/visa, tiket, polis asuransi.',
          'Fotokopi paspor + KTP simpan terpisah; versi digital di ponsel/cloud.',
          'Kartu hotel & nomor darurat Tour Leader (TL).',
        ],
      ),
      PraktisEntry(
        title: 'Uang & Kurs',
        bullets: [
          'Mata uang: Saudi Riyal (SAR). Bawa cash secukupnya + kartu debit/credit internasional.',
          'Tukar di Indonesia atau money changer resmi di Saudi.',
          'Gunakan dompet kecil untuk transaksi harian; simpan sebagian di brankas hotel.',
        ],
        notes: [
          'Tipping petugas hotel/bus sifatnya sunnah—ikuti arahan TL.',
        ],
      ),
    ],
  ),

  // ===== Komunikasi & Internet =====
  PraktisSection(
    id: 'sim_inet',
    title: 'Komunikasi & Internet',
    entries: [
      PraktisEntry(
        title: 'Kartu SIM / eSIM',
        bullets: [
          'Provider populer: STC, Mobily, Zain. Pilih paket data 7–15 hari.',
          'eSIM tersedia di konter bandara atau aplikasi resmi provider.',
          'Butuh paspor saat registrasi; simpan bukti pembelian.',
        ],
      ),
      PraktisEntry(
        title: 'Tips Internet',
        bullets: [
          'Wi-Fi hotel sering padat. Paket data membantu navigasi & koordinasi.',
          'Aktifkan roaming hanya jika perlu (biaya bisa mahal).',
          'Unduh offline maps Makkah–Madinah sebelum berangkat.',
        ],
      ),
    ],
  ),

  // ===== Kesehatan & Obat =====
  PraktisSection(
    id: 'health',
    title: 'Kesehatan & Obat',
    entries: [
      PraktisEntry(
        title: 'Perlengkapan Wajib',
        bullets: [
          'Obat rutin + obat umum (maag, flu, diare, pereda nyeri, minyak kayu putih).',
          'Masker cadangan, hand sanitizer, plester, salep antiseptik.',
          'Botol minum kecil (isi Zamzam/air mineral) agar tidak dehidrasi.',
        ],
      ),
      PraktisEntry(
        title: 'Kondisi Lapangan',
        bullets: [
          'Cuaca kering—minum cukup & gunakan pelembap bibir/ kulit.',
          'Istirahat yang cukup; gunakan kursi roda bila lelah.',
          'Lapor TL jika ada komorbid/keluhan mendadak.',
        ],
      ),
    ],
  ),

  // ===== Cuaca & Pakaian =====
  PraktisSection(
    id: 'weather_wear',
    title: 'Cuaca & Pakaian',
    entries: [
      PraktisEntry(
        title: 'Cuaca',
        bullets: [
          'Musim panas: siang bisa >40°C; malam tetap hangat.',
          'Musim dingin: siang sejuk, malam dingin (bawa jaket tipis).',
        ],
      ),
      PraktisEntry(
        title: 'Pakaian Disarankan',
        bullets: [
          'Bahan adem & menyerap keringat; sepatu/sandal yang nyaman.',
          'Payung/topi untuk terik; kacamata hitam & sunblock.',
          'Ihram laki-laki: 2 kain; perempuan: pakaian syar’i menutup aurat.',
        ],
      ),
    ],
  ),

  // ===== Transportasi Lokal =====
  PraktisSection(
    id: 'transport',
    title: 'Transportasi',
    entries: [
      PraktisEntry(
        title: 'Bus Rombongan',
        bullets: [
          'Ikuti seat plan & jadwal TL; jangan turun tanpa izin saat transit.',
          'Tulis nomor bus & kontak TL di ponsel.',
        ],
      ),
      PraktisEntry(
        title: 'Taksi & Ride-hailing',
        bullets: [
          'Aplikasi populer: Uber, Careem. Pastikan titik jemput yang aman.',
          'Selalu cek plat nomor kendaraan; bayar non-tunai jika memungkinkan.',
        ],
      ),
    ],
  ),

  // ===== Masjid & Ibadah =====
  PraktisSection(
    id: 'masjid',
    title: 'Masjid & Ibadah',
    entries: [
      PraktisEntry(
        title: 'Ke Masjid',
        bullets: [
          'Berangkat lebih awal, terutama saat Jumat & Ramadhan.',
          'Gunakan tas kecil untuk sandal; catat gate masuk/keluar.',
        ],
      ),
      PraktisEntry(
        title: 'Perlengkapan Ringan',
        bullets: [
          'Sajadah tipis, tasbih/dhikr counter, botol air kecil.',
          'Gunakan wewangian hanya **sebelum niat ihram**.',
        ],
      ),
    ],
  ),

  // ===== Etika & Adab =====
  PraktisSection(
    id: 'adab',
    title: 'Etika & Adab',
    entries: [
      PraktisEntry(
        title: 'Di Area Suci',
        bullets: [
          'Jaga kebersihan & ketertiban; jangan mendorong/berdebat.',
          'Utamakan lansia & perempuan; bantu jamaah lain.',
          'Tenang saat padat; ikuti arahan petugas & TL.',
        ],
      ),
      PraktisEntry(
        title: 'Foto & Privasi',
        bullets: [
          'Hindari memotret orang tanpa izin; patuhi larangan di area tertentu.',
          'Matikan suara kamera jika mengganggu.',
        ],
      ),
    ],
  ),

  // ===== Belanja & Oleh-oleh =====
  PraktisSection(
    id: 'shopping',
    title: 'Belanja',
    entries: [
      PraktisEntry(
        title: 'Tips Belanja',
        bullets: [
          'Bandingkan harga; banyak toko menerima kartu.',
          'Jaga struk pembelian; cek barang sebelum meninggalkan toko.',
          'Kurma, air zamzam (sesuai kebijakan bandara), sajadah, parfum non-alkohol.',
        ],
      ),
      PraktisEntry(
        title: 'Batas Bagasi',
        bullets: [
          'Ikuti batas maskapai (kg & ukuran). Powerbank harus di kabin.',
          'Kemas cairan sesuai aturan (≤100 ml di kabin).',
        ],
      ),
    ],
  ),

  // ===== Darurat & Kontak =====
  PraktisSection(
    id: 'emergency',
    title: 'Darurat',
    entries: [
      PraktisEntry(
        title: 'Nomor Penting',
        bullets: [
          'Nomor TL & rekan kamar.',
          'Ambulans/Polisi: 997/999 (cek update setempat).',
          'KJRI/KBRI terdekat (simpan alamat & telepon).',
        ],
      ),
      PraktisEntry(
        title: 'Kehilangan / Sakit',
        bullets: [
          'Tetap di tempat aman; hubungi TL.',
          'Untuk paspor/ barang: lapor ke hotel/airport Lost & Found.',
          'Manfaatkan asuransi; bawa kartu asuransi & paspor/fotokopi.',
        ],
      ),
    ],
  ),

  // ===== FAQ Singkat =====
  PraktisSection(
    id: 'faq',
    title: 'FAQ Singkat',
    entries: [
      PraktisEntry(
        title: 'Bawa Zamzam?',
        bullets: [
          'Ikuti kebijakan maskapai/bandara (kuota & kemasan khusus).',
        ],
        notes: [
          'Seringnya diurus travel; tanya TL pada hari kepulangan.',
        ],
      ),
      PraktisEntry(
        title: 'Powerbank & Baterai',
        bullets: [
          'WAJIB kabin; dilarang di bagasi check-in.',
        ],
      ),
      PraktisEntry(
        title: 'Adaptor Listrik',
        bullets: [
          'Colokan tipe G (UK); bawa universal adaptor.',
        ],
      ),
    ],
  ),
];
