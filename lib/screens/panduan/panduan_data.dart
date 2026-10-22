import 'panduan_models.dart';

const sections = <GuideSection>[
  GuideSection(
    id: 'pra',
    title: 'Pra-Berangkat',
    entries: [
      GuideEntry(
        title: 'Dokumen & Aplikasi',
        bullets: [
          'Paspor (masa berlaku min. 6 bulan), visa/e-visa, tiket, voucher hotel, polis asuransi.',
          'Fotokopi paspor & KTP disimpan terpisah + versi digital di ponsel.',
          'Nomor darurat travel & Tour Leader (isi oleh travel).',
          'Aplikasi pendukung (maps, komunikasi, jadwal shalat).',
        ],
      ),
      GuideEntry(
        title: 'Kesehatan & Obat',
        bullets: [
          'Bawa obat pribadi (maag, pusing, flu, diare), plester, minyak angin.',
          'Masker & hand sanitizer. Cek kebutuhan khusus lansia/hamil.',
          'Istirahat cukup sebelum keberangkatan.',
        ],
      ),
      GuideEntry(
        title: 'Pakaian & Perlengkapan',
        bullets: [
          'Pakaian ihram (2 kain putih) untuk laki-laki; perempuan pakaian menutup aurat.',
          'Sandal/selop nyaman, kaos kaki, peniti/ikat kain, sabuk uang.',
          'Pakaian harian 3–5 set, baju koko/gamis, jaket tipis (musim dingin), pakaian dalam.',
          'Peralatan mandi non-wangi untuk masa ihram (atau gunakan secukupnya sebelum niat).',
        ],
      ),
      GuideEntry(
        title: 'Keuangan & Komunikasi',
        bullets: [
          'Riyal tunai secukupnya; kartu debit/kredit internasional.',
          'Adaptor colokan (tipe G), powerbank, kabel pendek.',
          'eSIM/SIM lokal (opsional) atau Wi-Fi travel.',
        ],
      ),
      GuideEntry(
        title: 'Briefing & Barang Terlarang',
        bullets: [
          'Ikuti briefing travel: jadwal, meeting point, ketentuan bagasi.',
          'Dilarang: benda tajam, cairan >100 ml di kabin, baterai longgar di bagasi terdaftar.',
        ],
      ),
    ],
  ),

  GuideSection(
    id: 'miqat',
    title: 'Perjalanan & Miqat',
    entries: [
      GuideEntry(
        title: 'Di Bandara & Pesawat',
        bullets: [
          'Check-in sesuai arahan rombongan, pastikan label bagasi.',
          'Ganti pakaian ihram di rumah/bandara; bisa juga di pesawat sebelum miqat.',
          'Ambil wudhu menjelang miqat, siapkan niat.',
        ],
      ),
      GuideEntry(
        title: 'Niat Ihram & Talbiyah',
        bullets: [
          'Saat melewati miqat (umumnya diumumkan pramugari): niat **“Labbaika ‘umratan.”**',
          'Setelah niat, baca talbiyah berulang: **“Labbaika Allāhumma labbaik… lā syarīka lak.”**',
          'Mulai berlaku larangan ihram.',
        ],
      ),
      GuideEntry(
        title: 'Larangan Ihram (Ringkas)',
        bullets: [
          'Memakai wewangian (setelah niat), memotong rambut/kuku.',
          'Bagi laki-laki: memakai pakaian berjahit & menutup kepala (topi/peci).',
          'Hubungan suami-istri/akad nikah; berburu/merusak tanaman haram.',
        ],
      ),
    ],
  ),

  GuideSection(
    id: 'umrah',
    title: 'Ritual Umrah',
    entries: [
      GuideEntry(
        title: 'Masuk Masjidil Haram',
        bullets: [
          'Masuk kaki kanan; doa: **“Bismillāh, Allāhummaftah lī abwāba raḥmatik.”**',
          'Menuju mataf (area thawaf) dengan tenang; lanjut talbiyah lirih.',
        ],
      ),
      GuideEntry(
        title: 'Thawaf (7 putaran)',
        bullets: [
          'Mulai di garis sejajar **Hajar Aswad**; isyarat dengan takbir **“Allāhu akbar.”**',
          'Ka’bah selalu di kiri. Antara **Rukun Yamani → Hajar Aswad**: **“Rabbana ātinā….”**',
          'Lengkapi 7 putaran, berhenti kembali di Hajar Aswad.',
        ],
      ),
      GuideEntry(
        title: 'Shalat Sunnah 2 Rakaat',
        bullets: [
          'Utamakan di belakang **Maqam Ibrahim**; jika padat, di tempat yang lapang.',
        ],
      ),
      GuideEntry(
        title: 'Minum Zamzam',
        bullets: [
          'Niatkan kebaikan. Doa yang masyhur: **“Allāhumma innī as-aluka ‘ilman nāfi‘an, wa rizqan wāsi‘an, wa syifā’an min kulli dā’.”**',
        ],
      ),
      GuideEntry(
        title: 'Sa’i (Shafa → Marwah, 7 lintasan)',
        bullets: [
          'Di Shafa, baca **“Innaṣ-ṣafā wal-marwata min sya‘ā’irillāh”** (sekali di awal).',
          'Takbir, tahlil, doa di Shafa/Marwah. Lintasan **1**: Shafa→Marwah; **7** berakhir di **Marwah**.',
          'Laki-laki lari kecil di area lampu hijau (antara dua tanda).',
        ],
      ),
      GuideEntry(
        title: 'Tahallul (Selesai Umrah)',
        bullets: [
          'Laki-laki: **cukur gundul** lebih utama (atau potong merata).',
          'Perempuan: potong ujung rambut ±1 ruas jari.',
          'Larangan ihram terangkat; ibadah umrah selesai.',
        ],
      ),
      GuideEntry(
        title: 'Kesalahan Umum',
        bullets: [
          'Niat setelah melewati miqat (terlambat) → konsultasi dam.',
          'Thawaf kurang putaran atau mulai bukan di Hajar Aswad.',
          'Lupa tahallul sehingga masih terikat larangan ihram.',
        ],
      ),
    ],
  ),

  GuideSection(
    id: 'makkah',
    title: 'Selama di Makkah',
    entries: [
      GuideEntry(
        title: 'Adab & Jadwal',
        bullets: [
          'Dahulukan shalat berjamaah; jaga adab di masjid & area suci.',
          'Simpan titik hotel & gate di Google Maps; tentukan meeting point rombongan.',
        ],
      ),
      GuideEntry(
        title: 'Tips Praktis',
        bullets: [
          'Pilih waktu tidak padat untuk ibadah sunnah (pagi/larut malam).',
          'Bawa kantong sandal, botol kecil, masker. Jaga kebersihan & stamina.',
          'Jangan memaksakan diri untuk mencium Hajar Aswad saat ramai—cukup isyarat.',
        ],
      ),
    ],
  ),

  GuideSection(
    id: 'madinah',
    title: 'Ke Madinah',
    entries: [
      GuideEntry(
        title: 'Perjalanan ke Madinah',
        bullets: [
          'Check-out hotel sesuai jadwal; pastikan bagasi diberi label.',
          'Perjalanan darat/udara sesuai paket; istirahat cukup.',
        ],
      ),
      GuideEntry(
        title: 'Ibadah di Masjid Nabawi',
        bullets: [
          'Perbanyak shalat & zikir; adab di masjid & Raudhah (ikuti arahan petugas/travel).',
          'Ziarah sekitar: Jannatul Baqi’, Masjid Quba, Qiblatain, Uhud (sesuai arahan).',
        ],
      ),
    ],
  ),

  GuideSection(
    id: 'pulang',
    title: 'Kepulangan',
    entries: [
      GuideEntry(
        title: 'Persiapan Check-out',
        bullets: [
          'Pastikan semua barang: paspor, tiket, obat, charger, oleh-oleh.',
          'Bagasi sesuai batas maskapai; baterai & powerbank **di kabin**.',
        ],
      ),
      GuideEntry(
        title: 'Menuju Bandara & Zamzam',
        bullets: [
          'Ikuti arahan rombongan; untuk air zamzam gunakan prosedur resmi bandara (jika tersedia/diurus travel).',
          'Cairan di kabin maksimal 100 ml per botol (total 1 liter).',
        ],
      ),
      GuideEntry(
        title: 'Tiba di Tanah Air',
        bullets: [
          'Ambil bagasi, cek kondisi koper. Simpan bukti klaim bila ada kerusakan/hilang.',
          'Sampaikan evaluasi dan testimoni ke travel (opsional).',
        ],
      ),
    ],
  ),

  GuideSection(
    id: 'darurat',
    title: 'Darurat',
    entries: [
      GuideEntry(
        title: 'Kehilangan Paspor/Barang',
        bullets: [
          'Segera hubungi Tour Leader & pihak hotel. Laporkan ke polisi setempat bila perlu.',
          'Koordinasi dengan KJRI/KBRI melalui travel.',
        ],
      ),
      GuideEntry(
        title: 'Sakit / Cedera',
        bullets: [
          'Hubungi Tour Leader; gunakan fasilitas klinik/hospital rekanan. Siapkan kartu asuransi.',
          'Istirahat yang cukup; sesuaikan aktivitas ibadah.',
        ],
      ),
      GuideEntry(
        title: 'Tersesat',
        bullets: [
          'Tetap di lokasi aman. Hubungi kontak TL. Tunjukkan kartu hotel kepada petugas.',
          'Gunakan lokasi berbagi (share location) bila memungkinkan.',
        ],
      ),
    ],
  ),
];

// Checklist bawaan (bisa ditambah)
const defaultChecklist = <String>[
  'Paspor + fotokopi',
  'Visa / e-visa',
  'Tiket & voucher hotel',
  'Asuransi perjalanan',
  'Uang riyal & kartu',
  'Pakaian ihram (2 kain) / mukena',
  'Sandal nyaman + kantong sandal',
  'Obat pribadi & masker',
  'Adaptor colokan + powerbank',
  'Label bagasi & kartu hotel',
];
