-- ============================================================================
-- SQL SCRIPT: Insert Dummy Data Persiapan Umrah (Diniyah & Teknis)
-- Project: Mobile Retali
-- Deskripsi: Data realistis materi persiapan diniyah & teknis umrah
-- Jumlah: 7 record untuk persiapan_diniyah & 7 record untuk persiapan_teknis
-- ============================================================================

-- (Opsional) Jika ingin membersihkan data uji coba / dummy lama terlebih dahulu,
-- hapus tanda komentar pada baris di bawah ini:
-- DELETE FROM persiapan_diniyah;
-- DELETE FROM persiapan_teknis;

-- ============================================================================
-- 1. TABEL: persiapan_diniyah (7 Data Realistis Ibadah Umrah)
-- ============================================================================
INSERT INTO persiapan_diniyah (
    title,
    sub_title,
    description,
    content,
    category,
    visibility,
    attachment_url,
    is_published,
    created_at,
    updated_at
) VALUES
(
    'Niat & Miqat Ihram',
    'Panduan mengambil miqat dan melafalkan niat ihram umrah',
    'Penjelasan titik miqat (Bir Ali, Yalamlam, Qarnul Manazil), amalan sunnah sebelum ihram, lafal niat umrah dan kalimat talbiyah.',
    '<p>Sebelum melintasi batas miqat makani, setiap jemaah wajib berniat ihram untuk memulai rangkaian ibadah umrah.</p><p><strong>Amalan Sunnah Sebelum Berihram:</strong><br/>1. Memotong kuku dan merapikan kumis atau bulu tubuh.<br/>2. Mandi sunnah ihram lalu berwudhu.<br/>3. Mengenakan wewangian di badan (bukan pada kain ihram).<br/>4. Memakai dua lembar kain ihram putih tak berjahit bagi laki-laki, atau busana syar''i penutup aurat bagi wanita.</p><p><strong>Lafal Niat Umrah:</strong><br/><em>"Labbaikallāhumma ''umratan"</em> (Aku sambut panggilan-Mu ya Allah untuk menunaikan umrah).</p><p><strong>Bacaan Talbiyah:</strong><br/><em>"Labbaik Allāhumma labbaik, labbaika lā syarīka laka labbaik. Innal-hamda wan-ni''mata laka wal-mulk, lā syarīka lak."</em></p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW(),
    NOW()
),
(
    'Larangan Selama Berihram',
    'Hal-hal yang diharamkan bagi jemaah selama berihram',
    'Daftar larangan syar''i bagi jemaah laki-laki dan perempuan selama ihram hingga tahallul guna menghindari kewajiban fidyah atau dam.',
    '<p>Setelah niat ihram diucapkan, status ihram mulai berlaku dan jemaah terikat dengan berbagai larangan ihram hingga tahallul selesai.</p><p><strong>Larangan Umum (Pria & Wanita):</strong><br/>1. Memotong rambut, bulu tubuh, atau memotong kuku.<br/>2. Memakai wewangian atau minyak wangi di pakaian maupun badan.<br/>3. Berburu atau menyakiti binatang liar di tanah haram.<br/>4. Menikah, menikahkan, atau melamar.<br/>5. Melakukan hubungan suami-istri atau bercumbu mesra.</p><p><strong>Larangan Khusus Pria:</strong><br/>1. Menutup kepala dengan penutup yang melekat (seperti peci, topi, atau tudung).<br/>2. Memakai pakaian berjahit atau membentuk lekuk badan (celana, kaos, celana dalam).<br/>3. Memakai sepatu yang menutupi kedua mata kaki.</p><p><strong>Larangan Khusus Wanita:</strong><br/>1. Menutup wajah dengan cadar/niqab.<br/>2. Memakai sarung tangan yang menutup telapak tangan.</p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '1 second',
    NOW() + INTERVAL '1 second'
),
(
    'Tata Cara Thawaf Ka''bah',
    'Panduan rukun thawaf 7 putaran dan shalat sunnah thawaf',
    'Panduan lengkap thawaf mengelilingi Ka''bah 7 putaran berlawanan jarum jam, dimulai dari garis lurus Hajar Aswad.',
    '<p>Thawaf merupakan rukun umrah yang dilakukan dengan mengelilingi Ka''bah sebanyak tujuh kali putaran berlawanan arah jarum jam.</p><p><strong>Ketentuan & Pelaksanaan Thawaf:</strong><br/>1. Wajib dalam keadaan suci dari hadas kecil maupun besar (berwudhu).<br/>2. Dimulai dari garis lurus Hajar Aswad dengan menghadap ke Ka''bah, mengangkat tangan kanan sambil berucap <em>"Bismillāhi Allāhu Akbar"</em>.<br/>3. Posisi Ka''bah selalu berada di sebelah kiri jemaah sepanjang putaran.<br/>4. Bagi pria, disunnahkan idhthiba'' (membuka pundak kanan) dan raml (berlari-lari kecil pada tiga putaran awal).<br/>5. Di antara Rukun Yamani dan Hajar Aswad disunnahkan membaca doa sapu jagat: <em>"Rabbanā ātinā fid-dunyā hasanatan wa fil-ākhirati hasanatan wa qinā ''adzāban-nār"</em>.<br/>6. Selesai putaran ketujuh, disunnahkan merapikan kembali kain ihram dan menunaikan shalat sunnah thawaf dua rakaat di belakang Maqam Ibrahim.</p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '2 seconds',
    NOW() + INTERVAL '2 seconds'
),
(
    'Tata Cara Sa''i Shafa & Marwah',
    'Panduan berjalan 7 kali antara bukit Shafa dan Marwah',
    'Pelaksanaan sa''i sebanyak 7 putaran berawal di Bukit Shafa dan berakhir di Bukit Marwah beserta doa dan dzikirnya.',
    '<p>Sa''i dilaksanakan setelah thawaf selesai. Tidak disyaratkan suci dari hadas (wanita haid diperbolehkan sa''i jika thawaf telah selesai), namun tetap disunnahkan berwudhu.</p><p><strong>Urutan Ibadah Sa''i:</strong><br/>1. Menuju Bukit Shafa, membaca firman Allah (QS. Al-Baqarah: 158) lalu menaiki bukit menghadap Ka''bah.<br/>2. Bertakbir tiga kali dan membaca zikir tauhid di Bukit Shafa sambil menengadahkan kedua tangan.<br/>3. Berjalan menuju Bukit Marwah (dihitung sebagai putaran ke-1).<br/>4. Bagi laki-laki, disunnahkan berlari-lari kecil di antara dua pilar lampu hijau.<br/>5. Setibanya di Bukit Marwah, menghadap kiblat dan melafalkan doa seperti di Shafa.<br/>6. Berjalan kembali ke Shafa (putaran ke-2), dan seterusnya hingga berakhir pada putaran ke-7 di Bukit Marwah.</p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '3 seconds',
    NOW() + INTERVAL '3 seconds'
),
(
    'Tahallul & Penutup Umrah',
    'Mencukur atau memotong rambut tanda kesempurnaan umrah',
    'Ketentuan memotong rambut bagi pria (halaq/taqshir) dan wanita untuk membebaskan diri dari seluruh larangan ihram.',
    '<p>Tahallul adalah rukun penutup ibadah umrah. Dengan dilakukannya tahallul, jemaah terbebas dari seluruh larangan ihram dan ibadah umrah telah tuntas.</p><p><strong>Ketentuan Tahallul:</strong><br/>1. Dilakukan segera setelah menuntaskan putaran ketujuh sa''i di Bukit Marwah.<br/>2. Bagi jemaah pria: Sangat utama mencukur habis seluruh rambut kepala (gundul / halaq), atau memendekkan rambut secara merata (taqshir).<br/>3. Bagi jemaah wanita: Mengumpulkan ujung rambut lalu memotongnya sepanjang satu ruas jari (sekitar 2 cm).<br/>4. Pemotongan rambut dapat dilakukan sendiri atau dibantu sesama jemaah yang sudah bertahallul.<br/>5. Setelah tahallul, jemaah diperbolehkan berganti memakai pakaian biasa, mandi memakai wewangian, dan terbebas dari larangan ihram.</p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '4 seconds',
    NOW() + INTERVAL '4 seconds'
),
(
    'Fiqih Umrah Bagi Wanita',
    'Panduan ihram, thaharah, dan solusi saat datang bulan',
    'Panduan khusus mengenai tata cara bersuci, niat ihram saat haid, dan solusi fiqih thawaf bagi jemaah perempuan.',
    '<p>Ibadah umrah memberikan kemudahan dan ketentuan khusus bagi kaum muslimah dalam menghadapi siklus biologis alami.</p><p><strong>Ketentuan Fiqih Wanita:</strong><br/>1. Niat Ihram Saat Haid: Wanita yang mendapati haid sebelum miqat tetap sah mandi sunnah dan berniat ihram dari miqat.<br/>2. Amalan yang Diperbolehkan: Tetap boleh membaca talbiyah, berzikir, berdoa, mendengarkan tausiyah, dan melakukan sa''i (jika thawaf suci sudah terlaksana).<br/>3. Larangan Thawaf: Wanita yang sedang haid tidak boleh thawaf mengelilingi Ka''bah sampai ia suci dan mandi wajib.<br/>4. Konsultasi Medis: Jemaah diperbolehkan mengonsumsi obat pengatur siklus haid dengan rekomendasi dokter sebelum keberangkatan.<br/>5. Pakaian Shalat: Mengenakan busana muslimah yang longgar, tidak transparan, menutup aurat secara sempurna kecuali wajah dan telapak tangan.</p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '5 seconds',
    NOW() + INTERVAL '5 seconds'
),
(
    'Adab & Ziarah Kota Madinah',
    'Tata cara ziarah makam Rasulullah SAW dan shalat di Raudhah',
    'Panduan ziarah ke Masjid Nabawi, adab memberi salam kepada Rasulullah SAW, reservasi Raudhah, dan ziarah situs bersejarah.',
    '<p>Madinah Al-Munawwarah adalah kota suci tempat bersemayamnya baginda Rasulullah SAW. Ziarah ke Madinah merupakan sunnah muakkadah yang sarat kemuliaan.</p><p><strong>Keutamaan & Adab di Madinah:</strong><br/>1. Menunaikan shalat berjamaah di Masjid Nabawi yang bernilai pahala 1.000 kali lipat dibanding masjid lainnya (selain Masjidil Haram).<br/>2. Menyampaikan salam kepada Rasulullah SAW, Abu Bakar Ash-Shiddiq, dan Umar bin Khattab di makam mulia dengan adab tawadhu'' dan suara lembut.<br/>3. Berdoa dan shalat sunnah di Raudhah (taman surga) sesuai jadwal reservasi resmi aplikasi Nusuk.<br/>4. Berziarah ke Masjid Quba dalam keadaan bersuci untuk memperoleh pahala setara ibadah umrah.<br/>5. Menziarahi Pemakaman Baqi'' dan Makam Syuhada Uhud untuk mendoakan para pejuang Islam dan mengingat kematian.</p>',
    'diniyah',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '6 seconds',
    NOW() + INTERVAL '6 seconds'
);

-- ============================================================================
-- 2. TABEL: persiapan_teknis (7 Data Realistis Kesiapan Lapangan Umrah)
-- ============================================================================
INSERT INTO persiapan_teknis (
    title,
    sub_title,
    description,
    content,
    category,
    visibility,
    attachment_url,
    is_published,
    created_at,
    updated_at
) VALUES
(
    'Kelengkapan Dokumen Perjalanan',
    'Checklist paspor, e-visa umrah, dan tanda pengenal travel',
    'Panduan memeriksa masa aktif paspor, verifikasi nama di paspor, cetak e-visa, tiket PP, dan ID card resmi biro perjalanan.',
    '<p>Kelengkapan dokumen administrasi merupakan syarat utama kelancaran penerbangan dan pemeriksaan imigrasi di bandara kedatangan Arab Saudi.</p><p><strong>Daftar Dokumen Wajib:</strong><br/>1. Paspor Asli: Masa berlaku minimal 6-8 bulan sebelum tanggal kepulangan. Pastikan susunan nama minimal 2 atau 3 suku kata sesuai ketentuan visa.<br/>2. E-Visa Umrah: Lembar visa elektronik resmi dari Kementerian Haji & Umrah Kerajaan Arab Saudi yang telah dicetak jelas.<br/>3. Tiket Pesawat & Bukti Hotel: Tiket pulang-pergi (PP) serta konfirmasi pemesanan hotel di Makkah dan Madinah.<br/>4. ID Card Jemaah: Tanda pengenal dada dari biro travel yang wajib dikalungkan setiap saat keluar kamar hotel.<br/>5. Salinan Dokumen: Simpan fotokopi KTP, Kartu Keluarga, dan Buku Nikah, serta simpan foto/scan dokumen di cloud/Google Drive HP.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW(),
    NOW()
),
(
    'Manajemen Koper & Bagasi',
    'Aturan berat koper bagasi, tas kabin, dan penanda koper',
    'Panduan memilah barang ke koper besar dan tas kabin, batasan cairan (aerosol/liquid), serta cara mencegah koper tertukar.',
    '<p>Packing yang cermat akan menghindarkan jemaah dari denda kelebihan bagasi (excess baggage) serta memudahkan mobilitas saat perpindahan hotel.</p><p><strong>Panduan Bagasi & Kabin:</strong><br/>1. Koper Bagasi Besar (Maksimal 20-30 kg sesuai tiket): Tempatkan semua cairan di atas 100ml, gunting kecil tahallul, gunting kuku, botol sampo, dan sabun cair di sini.<br/>2. Tas Kabin / Ransel (Maksimal 7 kg): Simpan 1 stel kain ihram cadangan, pakaian ganti darurat untuk 1 hari, jaket/sweater, powerbank (di bawah 20.000 mAh), dan obat-obatan pribadi harian.<br/>3. Tas Selempang Kecil: Selalu bawa paspor, dompet, ponsel, dan tiket saat berada di bandara.<br/>4. Identitas Koper: Ikatkan pita cerah atau gunakan sarung koper travel seragam agar koper mudah dikenali di conveyor belt bandara King Abdulaziz Jeddah atau Madinah.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '1 second',
    NOW() + INTERVAL '1 second'
),
(
    'Pakaian & Perlengkapan Pribadi',
    'Pemilihan kain ihram, busana harian, dan sandal empuk',
    'Rekomendasi jenis kain ihram, gamis longgar berbahan sejuk, kaos kaki, dan alas kaki yang nyaman untuk jalan kaki jauh.',
    '<p>Aktivitas ibadah di Makkah dan Madinah menuntut fisik yang banyak berjalan kaki antara hotel, masjid, dan terminal bus.</p><p><strong>Rekomendasi Pakaian & Sandal:</strong><br/>1. Pria: Minimal bawa 2 set kain ihram handuk katun tebal tidak menerawang, sabuk ihram tanpa jahitan dengan kantong uang, serta 3-4 helai gamis jubah atau koko.<br/>2. Wanita: 3-5 stel pakaian muslimah syar''i berbahan dingin (katun/rayon), celana panjang dalaman gamis, bergo instan menutup dada, ciput, dan sarung tangan katun shalat.<br/>3. Alas Kaki: Sandal selop atau sepatu slip-on yang memiliki bantalan tumit empuk dan tidak licin. Hindari sandal berbahan kaku yang mudah menimbulkan lecet.<br/>4. Tas Serut Sandal: Bawa tas serut kain kecil untuk membawa sandal masuk ke dalam Masjidil Haram dan Masjid Nabawi agar sandal tidak hilang atau tertinggal.<br/>5. Kacamata Hitam & Payung: Sangat bermanfaat untuk menangkal paparan terik sinar matahari di pelataran masjid pada siang hari.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '2 seconds',
    NOW() + INTERVAL '2 seconds'
),
(
    'Kesehatan Fisik & Kotak P3K',
    'Vaksin wajib, obat rutin, lip balm, dan pencegahan dehidrasi',
    'Daftar obat pribadi yang wajib dibawa, cara menjaga stamina menghadapi cuaca kering, dan pencegahan kaki melepuh.',
    '<p>Perbedaan iklim gurun yang kering serta padatnya kerumunan jemaah menuntut proteksi kesehatan yang disiplin sejak sebelum berangkat.</p><p><strong>Tips Medis & Kesehatan:</strong><br/>1. Vaksinasi: Pastikan telah menerima vaksin Meningitis Meningokokus dan sertifikat vaksinasi telah terintegrasi di sistem SatuSehat.<br/>2. Latihan Stamina: Mulai rutin jalan kaki santai 30-45 menit setiap pagi minimal 2 minggu sebelum hari keberangkatan.<br/>3. Kotak P3K Pribadi: Bawa obat pereda demam/nyeri (Paracetamol), tablet hisap radang tenggorokan, obat flu/batuk, obat diare/oralit, antasida/maag, obat alergi, dan koyo/balsam pereda pegal.<br/>4. Obat Kronis: Jemaah dengan riwayat darah tinggi, diabetes, asam urat, atau asma wajib membawa persediaan obat rutin cukup untuk 14 hari beserta resep dokter.<br/>5. Perawatan Kulit Kering: Gunakan lip balm pada bibir, pelembab kulit, dan oleskan petroleum jelly pada pangkal paha sebelum thawaf/sa''i untuk mencegah lecet parah akibat gesekan saat jalan kaki.<br/>6. Hidrasi: Minum air zamzam atau air mineral minimal 2-3 liter per hari meskipun tidak merasa haus.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '3 seconds',
    NOW() + INTERVAL '3 seconds'
),
(
    'Komunikasi & Paket Internet',
    'Pilihan SIM Card Arab Saudi, paket roaming, dan eSIM',
    'Panduan memilih paket data internet terbaik untuk komunikasi rombongan keluarga, WhatsApp, dan aplikasi Nusuk.',
    '<p>Jaringan internet seluler sangat diperlukan untuk komunikasi antar jemaah, memantau arahan tour leader di grup WhatsApp, serta login aplikasi ibadah.</p><p><strong>Pilihan Akses Data:</strong><br/>1. Paket Roaming Umrah Indonesia: Operator seperti Telkomsel, Indosat, dan XL menyediakan paket umrah 10-14 hari. Praktis karena tidak perlu mengganti kartu SIM dan nomor WA tetap sama.<br/>2. SIM Card Lokal Saudi (STC / Mobily / Zain): Dapat dibeli di gerai resmi bandara kedatangan (Jeddah/Madinah) atau sekitar hotel dengan mendaftarkan sidik jari dan paspor.<br/>3. Layanan eSIM Digital: Solusi praktis bagi pengguna smartphone berfitur eSIM (seperti iPhone atau Samsung seri flagship) dengan membeli paket data Saudi via aplikasi online.<br/>4. Powerbank & Adaptor: Bawa adaptor colokan listrik tipe internasional (tipe G berkaki tiga standar Saudi) dan powerbank berlabel resmi maskapai.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '4 seconds',
    NOW() + INTERVAL '4 seconds'
),
(
    'Keuangan & Transaksi Riyal',
    'Uang saku Saudi Riyal (SAR), penarikan ATM, dan kartu debit',
    'Tips menukar mata uang Riyal pecahan kecil, penggunaan kartu debit bank Indonesia di ATM Saudi, dan belanja hemat.',
    '<p>Ekosistem transaksi di Arab Saudi saat ini sudah sangat maju dan menerima kartu debit/kredit internasional secara luas.</p><p><strong>Panduan Finansial:</strong><br/>1. Uang Tunai Riyal (SAR): Tukarkan uang pecahan kecil (5, 10, 50, dan 100 Riyal) di money changer Indonesia sekitar 500 - 1.000 SAR untuk keperluan sedekah, tip bellboy, dan beli makanan ringan.<br/>2. Tarik Tunai di ATM Saudi: Kartu debit bank Indonesia berlogo Visa / Mastercard dapat digunakan di ATM Al-Rajhi, SNB Al-Ahli, atau Riyad Bank dengan kurs kompetitif.<br/>3. Transaksi Non-Tunai (Cashless): Toko serba ada seperti Bin Dawood, apotek Al-Nahdi, restoran cepat saji (Al-Baik), dan toko kurma menerima pembayaran tap kartu debit/kredit tanpa biaya tambahan.<br/>4. Keamanan Dompet: Jangan membawa seluruh uang tunai saat shalat di masjid. Simpan sebagian uang dan paspor di dalam safety deposit box kamar hotel.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '5 seconds',
    NOW() + INTERVAL '5 seconds'
),
(
    'Aplikasi Nusuk & Reservasi Raudhah',
    'Tata cara daftar akun, booking tasreh Raudhah, dan barcode izin',
    'Panduan registrasi aplikasi Nusuk Pemerintah Arab Saudi untuk mendapatkan slot izin masuk dan shalat di Raudhah Masjid Nabawi.',
    '<p>Pemerintah Kerajaan Arab Saudi menerapkan sistem reservasi digital wajib melalui aplikasi Nusuk bagi setiap jemaah yang ingin berziarah ke Raudhah Syarifah di Masjid Nabawi.</p><p><strong>Langkah Pendaftaran & Reservasi:</strong><br/>1. Unduh aplikasi "Nusuk" resmi dari Google Play Store atau Apple App Store.<br/>2. Buat akun baru dengan memilih opsi "International Visitor / Zairun", lalu masukkan nomor paspor, nomor visa umrah, tanggal lahir, kebangsaan, dan alamat email aktif.<br/>3. Masuk ke beranda aplikasi, pilih menu "Prophet''s Mosque Services" dilanjutkan "Praying in the Noble Rawdah" (pilih kategori Man / Woman).<br/>4. Pilih tanggal dan slot jam kedatangan yang bertanda warna hijau (masih tersedia kuota).<br/>5. Setelah konfirmasi berhasil, izin (tasreh) akan terbit berupa kode QR aktif.<br/>6. Tunjukkan kode QR Nusuk di layar smartphone kepada petugas pemeriksa di gerbang antrian masuk pelataran Raudhah sesuai jadwal yang dipilih.</p>',
    'teknis',
    'public',
    NULL,
    TRUE,
    NOW() + INTERVAL '6 seconds',
    NOW() + INTERVAL '6 seconds'
);
