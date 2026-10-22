import 'prosedur_models.dart';

const prosedurSections = <ProcSection>[
  ProcSection(
    id: 'pra',
    title: 'Pra-Keberangkatan',
    entries: [
      ProcEntry(
        title: 'Cek Dokumen & Aplikasi',
        bullets: [
          'Paspor (≥6 bln), visa/e-visa, tiket, polis asuransi, voucher hotel.',
          'Fotokopi paspor & KTP disimpan terpisah + simpan versi digital di ponsel.',
          'Nomor darurat Tour Leader dan kantor travel.',
          'Unduh aplikasi penting (WhatsApp, Maps, jadwal shalat).',
        ],
      ),
      ProcEntry(
        title: 'Kesehatan & Obat',
        bullets: [
          'Siapkan obat rutin & obat umum (maag, flu, diare, painkiller).',
          'Masker & hand sanitizer; istirahat cukup sebelum hari H.',
          'Konsultasikan kondisi khusus (lansia/hamil) ke Tour Leader.',
        ],
      ),
      ProcEntry(
        title: 'Packing & Bagasi',
        bullets: [
          'Bagasi terdaftar (check-in) sesuai batas maskapai; kabin max 7–10 kg (cek maskapai).',
          'Baterai/powerbank WAJIB di kabin; cairan di kabin ≤100 ml/botol (total 1 liter).',
          'Label bagasi travel terpasang; barang berharga disimpan di kabin.',
        ],
      ),
      ProcEntry(
        title: 'Briefing & Jadwal',
        bullets: [
          'Ikuti briefing travel: meeting point, jadwal bus, seat plan pesawat, alur imigrasi.',
          'Datang lebih awal ke bandara (3–4 jam sebelum ETD).',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'bandaraID',
    title: 'Bandara Indonesia',
    entries: [
      ProcEntry(
        title: 'Check-in & Imigrasi',
        bullets: [
          'Kumpulkan paspor sesuai instruksi TL jika group check-in.',
          'Cetak boarding pass, timbang bagasi, tempel tag & claim tag.',
          'Lewati pemeriksaan keamanan: keluarkan laptop & cairan dari tas.',
          'Imigrasi keberangkatan: siapkan paspor & boarding pass.',
        ],
      ),
      ProcEntry(
        title: 'Keberangkatan',
        bullets: [
          'Menuju gate sesuai boarding pass; dengarkan pengumuman gate change.',
          'Gunakan kursi roda bila perlu (minta bantuan TL).',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'pesawat',
    title: 'Dalam Pesawat',
    entries: [
      ProcEntry(
        title: 'Sebelum Miqat',
        bullets: [
          'Ganti kain ihram di rumah/bandara; bisa juga di pesawat sebelum miqat.',
          'Ambil wudhu; dengarkan pengumuman pramugari tentang miqat.',
        ],
      ),
      ProcEntry(
        title: 'Niat Ihram (jika umrah dulu)',
        bullets: [
          'Saat melewati miqat: niat “Labbaika ‘umratan.”',
          'Setelah niat, baca talbiyah berulang hingga memasuki Masjidil Haram.',
          'Larangan ihram mulai berlaku setelah niat.',
        ],
      ),
      ProcEntry(
        title: 'Etika & Kesehatan',
        bullets: [
          'Minum cukup, lakukan peregangan ringan per 1–2 jam.',
          'Ikuti arahan pramugari; simpan boarding pass sampai tujuan.',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'kedatangan',
    title: 'Kedatangan Saudi',
    entries: [
      ProcEntry(
        title: 'Imigrasi & Bagasi',
        bullets: [
          'Ikuti jalur imigrasi; siapkan paspor, visa/e-visa, dan sidik jari jika diminta.',
          'Ambil bagasi di belt sesuai penerbangan; cocokkan nomor claim tag.',
          'Jika bagasi hilang/terlambat, laporan di Lost & Found (bawa boarding pass & tag).',
        ],
      ),
      ProcEntry(
        title: 'Zamzam & Custom',
        bullets: [
          'Aturan air zamzam mengikuti kebijakan bandara maskapai; biasanya jalur khusus/diurus travel.',
          'Hindari membawa cairan >100 ml di kabin saat penerbangan domestik lanjut.',
        ],
      ),
      ProcEntry(
        title: 'Keluar Bandara',
        bullets: [
          'Bertemu TL di meeting point; naik bus sesuai pembagian seat.',
          'Pastikan semua barang terbawa; cek kembali paspor & tas kabin.',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'hotel',
    title: 'Menuju Hotel & Check-in',
    entries: [
      ProcEntry(
        title: 'Perjalanan ke Hotel',
        bullets: [
          'Perjalanan bus: simak instruksi TL, jangan berpencar di rest area.',
          'Simpan lokasi hotel di Google Maps; foto gate/landmark sekitar.',
        ],
      ),
      ProcEntry(
        title: 'Check-in & Kunci',
        bullets: [
          'Tunggu pembagian kamar/kunci sesuai rooming list.',
          'Laporkan segera ke TL jika ada kerusakan kamar atau masalah kartu kunci.',
        ],
      ),
      ProcEntry(
        title: 'Orientasi',
        bullets: [
          'Kenali jalur ke masjid, meeting point, jadwal makan & ibadah.',
          'Gunakan lift dengan tertib; catat nomor bus/travel di ponsel.',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'perpindahan',
    title: 'Perpindahan Kota',
    entries: [
      ProcEntry(
        title: 'Check-out & Naik Bus',
        bullets: [
          'Packing malam sebelumnya; pastikan tidak ada barang tertinggal di kamar/brankas.',
          'Turunkan koper ke lobi sesuai jadwal; label koper tetap terpasang.',
          'Bawalah tas kabin berisi barang penting, obat, dan camilan.',
        ],
      ),
      ProcEntry(
        title: 'Di Perjalanan',
        bullets: [
          'Ikuti jadwal ziarah; patuhi instruksi TL dan mutawwif.',
          'Jaga kebersihan bus; buang sampah pada tempatnya.',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'kembaliID',
    title: 'Kepulangan',
    entries: [
      ProcEntry(
        title: 'Persiapan Pulang',
        bullets: [
          'Packing rapi; oleh-oleh cair dikemas sesuai aturan (hindari cairan di kabin).',
          'Bagasi sesuai bobot; powerbank/lithium tetap di kabin.',
          'Konfirmasi waktu kumpul & keberangkatan ke bandara.',
        ],
      ),
      ProcEntry(
        title: 'Bandara Saudi',
        bullets: [
          'Check-in group; perhatikan gate & waktu boarding.',
          'Lewati imigrasi keberangkatan; simpan boarding pass.',
        ],
      ),
      ProcEntry(
        title: 'Tiba di Indonesia',
        bullets: [
          'Ambil bagasi; cek kondisi koper. Klaim bila ada kerusakan/hilang.',
          'Kumpulkan paspor ke TL jika prosedur administrasi travel masih diperlukan.',
          'Pulangkan jamaah sesuai kota/penjemputan.',
        ],
      ),
    ],
  ),

  ProcSection(
    id: 'darurat',
    title: 'Darurat & Kontak',
    entries: [
      ProcEntry(
        title: 'Kehilangan Paspor/Barang',
        bullets: [
          'Segera hubungi TL; lapor ke pihak hotel/airport Lost & Found.',
          'Koordinasi dengan KJRI/KBRI melalui travel (siapkan fotokopi paspor).',
        ],
      ),
      ProcEntry(
        title: 'Sakit / Cedera',
        bullets: [
          'Hubungi TL; manfaatkan klinik/hospital rekanan asuransi.',
          'Batasi aktivitas; utamakan keselamatan & kondisi fisik.',
        ],
      ),
      ProcEntry(
        title: 'Tersesat / Terpisah',
        bullets: [
          'Tetap di lokasi aman; telepon TL; tunjukkan kartu hotel ke petugas.',
          'Gunakan share location bila memungkinkan.',
        ],
      ),
    ],
  ),
];

/// Checklist umum perjalanan
const prosedurChecklist = <String>[
  'Paspor + visa/e-visa',
  'Tiket & voucher hotel',
  'Asuransi perjalanan',
  'Uang riyal & kartu',
  'Label bagasi & claim tag',
  'Obat pribadi & masker',
  'Adaptor colokan + powerbank',
  'Kain ihram/mukena',
  'Kontak TL & kartu hotel',
];
