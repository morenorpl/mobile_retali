import 'fiqih_models.dart';

const fiqhSections = <FiqhSection>[
  // ===== HUKUM UMRAH =====
  FiqhSection(
    id: 'hukum',
    title: 'Hukum & Syarat',
    entries: [
      FiqhEntry(
        title: 'Definisi & Hukum Umrah',
        bullets: [
          'Umrah: ihram, thawaf, sa’i, tahallul.',
          'Mayoritas: sunnah muakkadah; Hanbali: wajib sekali seumur hidup.',
        ],
        dalil: [
          'QS. Al-Baqarah 196: “Dan sempurnakanlah haji dan umrah karena Allah…”.',
          'Hadits: Umrah satu ke umrah berikutnya menggugurkan dosa di antara keduanya (HR. Bukhari-Muslim).',
        ],
        notes: [
          'Travel umumnya mempraktikkan umrah di awal kedatangan (tamattu’ bagi yang berhaji).',
        ],
      ),
      FiqhEntry(
        title: 'Syarat Sah & Wajib',
        bullets: [
          'Syarat: Islam, berakal, mampu; ihram dari miqat; tertib rukun.',
          'Wajib: miqat yang benar, menjauhi larangan ihram.',
        ],
        dalil: [
          'Kaedah fiqh: “Al-amru idza dhāqa ittasa’a” — ada rukhshah pada kondisi darurat.',
        ],
        notes: [
          'Meninggalkan wajib tetap sah tapi wajib dam; meninggalkan rukun → tidak sah.',
        ],
      ),
    ],
  ),

  // ===== MIQAT & IHRAM =====
  FiqhSection(
    id: 'miqat',
    title: 'Miqat & Ihram',
    entries: [
      FiqhEntry(
        title: 'Miqat Makani',
        bullets: [
          'Zul Hulaifah (Bir Ali) — arah Madinah.',
          'Juhfah (Rabigh) — arah Syam/Mesir.',
          'Qarnul Manazil (As-Sail Al-Kabir) — arah Najd/Thaif.',
          'Yalamlam — arah Yaman.',
          'Dzat Irq — arah Iraq.',
          'Lewat udara: niat saat melintasi garis miqat (umumnya diumumkan di kabin).',
        ],
        dalil: [
          'Hadits penetapan miqat oleh Nabi ﷺ (HR. Bukhari-Muslim).',
        ],
        notes: [
          'Kalau terlewat miqat belum berniat, kembali ke miqat jika memungkinkan; bila tidak, umumnya terkena dam.',
        ],
      ),
      FiqhEntry(
        title: 'Niat & Talbiyah',
        bullets: [
          'Lafaz singkat: “Labbaika ‘umratan.”',
          'Setelah niat, talbiyah: “Labbaika Allāhumma labbaik…”.',
          'Larangan ihram berlaku setelah niat.',
        ],
        dalil: [
          'Talbiyah disyariatkan dalam hadits Jabir (HR. Muslim).',
        ],
        notes: [
          'Talbiyah disunnahkan sampai masuk Masjidil Haram menuju thawaf.',
        ],
      ),
      FiqhEntry(
        title: 'Pakaian Ihram',
        bullets: [
          'Laki-laki: 2 kain tanpa jahitan, kepala tidak ditutup; sandal terbuka.',
          'Perempuan: pakaian menutup aurat; tidak memakai niqab/bercadar.',
        ],
        dalil: [
          'Hadits: “Wanita ihram tidak bercadar dan tidak memakai sarung tangan.” (HR. Bukhari).',
        ],
        notes: [
          'Boleh menurunkan kain jilbab menutupi wajah saat berdesakan tanpa niat niqab.',
        ],
      ),
      FiqhEntry(
        title: 'Larangan Ihram',
        bullets: [
          'Wewangian (setelah niat), potong rambut/kuku.',
          'Laki-laki: pakaian berjahit & menutup kepala.',
          'Hubungan suami-istri, akad nikah, berburu/merusak tumbuhan haram.',
        ],
        dalil: [
          'QS. Al-Baqarah 197 (larangan rafats, fusuq).',
        ],
        notes: [
          'Lalai/tidak sengaja → rincian dam berbeda; konsultasikan ke TL/mutawwif.',
        ],
      ),
    ],
  ),

  // ===== THAWAF =====
  FiqhSection(
    id: 'thawaf',
    title: 'Thawaf',
    entries: [
      FiqhEntry(
        title: 'Syarat & Rukun Thawaf',
        bullets: [
          'Suci dari hadas (mayoritas), menutup aurat, Ka’bah di kiri.',
          'Mulai & berakhir di Hajar Aswad; 7 putaran penuh.',
        ],
        dalil: [
          'Riwayat tata cara thawaf dari Jabir r.a. (HR. Muslim).',
        ],
        notes: [
          'Khilaf soal kesucian; mayoritas mensyaratkan suci. Saat macet boleh di lantai atas.',
        ],
      ),
      FiqhEntry(
        title: 'Bacaan Thawaf',
        bullets: [
          'Tidak ada bacaan baku; isi dengan dzikir & doa.',
          'Antara Rukun Yamani & Hajar Aswad: “Rabbana ātinā fid-dunyā…”.',
          'Isyarat ke Hajar Aswad sambil takbir: “Allāhu akbar”.',
        ],
        dalil: [
          'Atsar & amalan sahabat; doa “Rabbana ātina…” (QS. Al-Baqarah 201).',
        ],
        notes: [
          'Cium Hajar Aswad tidak wajib; cukup isyarat jika padat.',
        ],
      ),
      FiqhEntry(
        title: 'Shalat 2 Rakaat & Zamzam',
        bullets: [
          'Sunnah 2 rakaat di belakang Maqam Ibrahim (atau di tempat lapang).',
          'Minum Zamzam niat kebaikan.',
        ],
        dalil: [
          'QS. Al-Baqarah 125: “Dan jadikanlah Maqam Ibrahim sebagai tempat shalat.”',
          'Hadits keutamaan Zamzam (HR. Ibn Majah, hasan).',
        ],
        notes: [
          'Jika padat, cari tempat longgar—fokus kekhusyukan.',
        ],
      ),
    ],
  ),

  // ===== SA’I =====
  FiqhSection(
    id: 'sai',
    title: 'Sa’i',
    entries: [
      FiqhEntry(
        title: 'Ketentuan Sa’i',
        bullets: [
          'Dilakukan setelah tawaf sah.',
          'Mulai di Shafa, berakhir di Marwah (7 lintasan).',
          'Laki-laki lari kecil pada area lampu hijau.',
        ],
        dalil: [
          'QS. Al-Baqarah 158: “Sesungguhnya Shafa dan Marwah termasuk syiar Allah…”.',
        ],
        notes: [
          'Doa di Shafa/Marwah: takbir, tahlil, doa bebas; tidak ada bacaan baku per lintasan.',
        ],
      ),
      FiqhEntry(
        title: 'Bacaan Awal di Shafa',
        bullets: [
          'Baca ayat: “Innaṣ-ṣafā wal-marwata min sya‘ā’irillāh” (sekali di awal).',
          'Menghadap Ka’bah, takbir 3×, berdoa, lalu mulai berjalan.',
        ],
        dalil: [
          'Hadits Jabir tentang tata cara Umrah Nabi ﷺ (HR. Muslim).',
        ],
        notes: [
          'Ulangi dzikir & doa tiap tiba di Shafa/Marwah.',
        ],
      ),
    ],
  ),

  // ===== TAHALLUL & LARANGAN =====
  FiqhSection(
    id: 'tahallul',
    title: 'Tahallul & Larangan',
    entries: [
      FiqhEntry(
        title: 'Tahallul',
        bullets: [
          'Laki-laki: cukur gundul lebih utama; atau pendek merata.',
          'Perempuan: potong ujung rambut ±1 ruas jari.',
        ],
        dalil: [
          'Doa Nabi ﷺ: “Ya Allah, rahmatilah orang yang mencukur (tiga kali) … dan orang yang memendekkan.” (HR. Bukhari-Muslim).',
        ],
        notes: [
          'Setelah tahallul, larangan ihram terangkat (umrah selesai).',
        ],
      ),
      FiqhEntry(
        title: 'Larangan Saat Ihram (Ringkas)',
        bullets: [
          'Wewangian (setelah niat), potong rambut/kuku.',
          'Pakaian berjahit & menutup kepala (laki-laki).',
          'Hubungan suami-istri, akad nikah, berburu.',
        ],
        dalil: [
          'QS. Al-Baqarah 197 dan riwayat fiqh haji/umrah.',
        ],
        notes: [
          'Pelanggaraan disengaja umumnya ada dam; kasus tidak sengaja/butuh pengobatan → perincian.',
        ],
      ),
    ],
  ),

  // ===== DAM (DENDA) =====
  FiqhSection(
    id: 'dam',
    title: 'Dam (Denda)',
    entries: [
      FiqhEntry(
        title: 'Kapan Wajib Dam?',
        bullets: [
          'Lewat miqat tanpa ihram dan tidak kembali.',
          'Meninggalkan wajib umrah.',
          'Melanggar larangan ihram dengan sengaja.',
        ],
        dalil: [
          'QS. Al-Baqarah 196 tentang fidyah/dam.',
        ],
        notes: [
          'Bentuk dam bervariasi: sembelih kambing di Tanah Haram; atau puasa (kasus tertentu).',
        ],
      ),
      FiqhEntry(
        title: 'Contoh Kasus',
        bullets: [
          'Memakai parfum setelah niat → dam menurut banyak ulama.',
          'Potong rambut/kuku saat ihram → dam (rincian kadar tergantung).',
        ],
        dalil: [
          'Penjelasan fuqaha madzhab dalam bab manasik.',
        ],
        notes: [
          'Selalu konsultasikan ke mutawwif/TL untuk keputusan praktis di lapangan.',
        ],
      ),
    ],
  ),

  // ===== WANITA, ANAK, UZUR =====
  FiqhSection(
    id: 'wanita',
    title: 'Wanita, Anak & Uzur',
    entries: [
      FiqhEntry(
        title: 'Wanita Haid/Nifas',
        bullets: [
          'Tidak boleh thawaf; tunggu suci. Sa’i dilakukan setelah thawaf sah.',
          'Darurat waktu (rombongan harus pulang) → minta arahan ulama setempat.',
        ],
        dalil: [
          'Hadits Aisyah tentang haid saat haji/umrah (HR. Bukhari).',
        ],
        notes: [
          'Bisa tetap dzikir/berdoa; fokus ibadah lain sambil menunggu suci.',
        ],
      ),
      FiqhEntry(
        title: 'Anak-Anak',
        bullets: [
          'Umrah anak sah tapi tidak menggugurkan kewajiban saat baligh.',
          'Orangtua meniatkan & membimbing rukun.',
        ],
        dalil: [
          'Riwayat para sahabat membawa anak kecil pada haji wada’.',
        ],
        notes: [
          'Boleh didorong kursi/stroller di area yang diizinkan.',
        ],
      ),
      FiqhEntry(
        title: 'Lansia/Disabilitas',
        bullets: [
          'Kursi roda/scooter boleh; tidak ada dam.',
          'Pilih waktu tidak padat dan jaga keselamatan.',
        ],
        dalil: [
          'Kaedah: “Lā yukallifullāhu nafsan illā wus‘ahā.” (QS. Al-Baqarah 286).',
        ],
        notes: [
          'Pendamping disunnahkan membantu; niat & doa sama.',
        ],
      ),
    ],
  ),

  // ===== SHALAT SAFAR =====
  FiqhSection(
    id: 'shalat',
    title: 'Shalat Safar',
    entries: [
      FiqhEntry(
        title: 'Jamak & Qashar',
        bullets: [
          'Musafir boleh qashar (Zhuhur/Asar/Isya jadi 2 rakaat).',
          'Boleh jamak taqdim/ta’khir sesuai kebutuhan perjalanan.',
          'Di Masjidil Haram/Nabawi ikut imam (tanpa qashar).',
        ],
        dalil: [
          'Hadits tentang rukhshah safar (HR. Muslim).',
        ],
        notes: [
          'Rinciannya beda-beda antar madzhab; ikuti pembimbing.',
        ],
      ),
    ],
  ),
];
