import 'doa_model.dart';

const doaList = <Doa>[
  Doa(
    id: 1,
    judul: 'Niat Umrah',
    arab: 'لَبَّيْكَ عُمْرَةً',
    latin: 'Labbaika ‘umratan.',
    arti: 'Aku penuhi panggilan-Mu (ya Allah) untuk ber-umrah.',
    kategori: 'Makkah',
  ),
  Doa(
    id: 2,
    judul: 'Talbiyah',
    arab:
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، '
        'إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
    latin:
        'Labbaika Allāhumma labbaik, labbaika lā syarīka laka labbaik. '
        'Innal-ḥamda wan-ni‘mata laka wal-mulk, lā syarīka lak.',
    arti:
        'Aku penuhi panggilan-Mu ya Allah, tiada sekutu bagi-Mu. Sesungguhnya puji, nikmat, dan kerajaan adalah milik-Mu, tiada sekutu bagi-Mu.',
    kategori: 'Makkah',
  ),
  Doa(
    id: 3,
    judul: 'Doa Masuk Masjid',
    arab:
        'بِسْمِ اللَّهِ، اَللّٰهُمَّ افْتَحْ لِيْ أَبْوَابَ رَحْمَتِكَ',
    latin:
        'Bismillāh, Allāhummaftah lī abwāba raḥmatik.',
    arti: 'Dengan nama Allah. Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.',
    kategori: 'Masjid',
  ),
  Doa(
    id: 4,
    judul: 'Doa Keluar Masjid',
    arab:
        'بِسْمِ اللَّهِ، اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ مِنْ فَضْلِكَ',
    latin:
        'Bismillāh, Allāhumma innī as-aluka min faḍlik.',
    arti: 'Dengan nama Allah. Ya Allah, aku memohon keutamaan dari-Mu.',
    kategori: 'Masjid',
  ),
  Doa(
    id: 5,
    judul: 'Doa Safar (Perjalanan)',
    arab:
        'سُبْحَانَ الَّذِيْ سَخَّرَ لَنَا هٰذَا وَمَا كُنَّا لَهُ مُقْرِنِيْنَ '
        'وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُوْنَ',
    latin:
        'Subḥānalladzī sakhkhara lanā hādzā wa mā kunnā lahu muqrinīn, '
        'wa innā ilā rabbinā lamunqalibūn.',
    arti:
        'Maha Suci Allah yang menundukkan kendaraan ini bagi kami, sedangkan kami sebelumnya tidak mampu menguasainya. Dan sesungguhnya kami akan kembali kepada Tuhan kami.',
    kategori: 'Safar',
  ),
  Doa(
    id: 6,
    judul: 'Doa Naik Kendaraan',
    arab:
        'بِسْمِ اللَّهِ، اَلْحَمْدُ لِلّٰهِ، سُبْحَانَ الَّذِيْ سَخَّرَ لَنَا هٰذَا...',
    latin:
        'Bismillāh, al-ḥamdu lillāh, subḥānalladzī sakhkhara lanā hādzā...',
    arti:
        'Dengan nama Allah, segala puji bagi Allah. Maha Suci Allah yang menundukkan kendaraan ini bagi kami...',
    kategori: 'Safar',
  ),
  Doa(
    id: 7,
    judul: 'Doa Melihat Ka’bah (ringkas)',
    arab: 'اَللّٰهُمَّ زِدْ هٰذَا الْبَيْتَ تَشْرِيْفًا وَتَعْظِيْمًا...',
    latin: 'Allāhumma zid hādzal-baita tasyrīfan wata‘ẓīman...',
    arti: 'Ya Allah, tambahkanlah kemuliaan dan keagungan pada Baitullah ini...',
    kategori: 'Makkah',
  ),
  Doa(
    id: 8,
    judul: 'Dzikir Thawaf (umum)',
    arab:
        'سُبْحَانَ اللّٰهِ، وَالْحَمْدُ لِلّٰهِ، وَلَا إِلٰهَ إِلَّا اللّٰهُ، وَاللّٰهُ أَكْبَرُ',
    latin:
        'Subḥānallāh, wal-ḥamdu lillāh, wa lā ilāha illallāh, wallāhu akbar.',
    arti:
        'Maha Suci Allah, segala puji bagi Allah, tiada sesembahan selain Allah, Allah Maha Besar.',
    kategori: 'Thawaf',
  ),
  Doa(
    id: 9,
    judul: 'Antara Rukun Yamani & Hajar Aswad',
    arab: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    latin: 'Rabbana ātinā fī d-dunyā ḥasanah wa fī l-ākhirati ḥasanah wa qinā ‘adzāba n-nār.',
    arti: 'Ya Rabb kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan peliharalah kami dari siksa neraka.',
    kategori: 'Thawaf',
  ),
  Doa(
    id: 10,
    judul: 'Dzikir Sa’i (umum)',
    arab:
        'اللّٰهُ أَكْبَرُ، لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ...',
    latin:
        'Allāhu akbar, lā ilāha illallāhu waḥdahu lā syarīka lah, lahu-l-mulku wa lahu-l-ḥamd...',
    arti:
        'Allah Maha Besar. Tiada sesembahan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan pujian...',
    kategori: 'Sa\'i',
  ),
  Doa(
    id: 11,
    judul: 'Doa Minum Zamzam',
    arab: 'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا وَاسِعًا وَشِفَاءً مِنْ كُلِّ دَاءٍ',
    latin: 'Allāhumma innī as-aluka ‘ilman nāfi‘an, wa rizqan wāsi‘an, wa syifā’an min kulli dā’.',
    arti: 'Ya Allah, aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang luas, dan kesembuhan dari segala penyakit.',
    kategori: 'Makkah',
  ),
  Doa(
    id: 12,
    judul: 'Dzikir Setelah Shalat (ringkas)',
    arab:
        'أَسْتَغْفِرُ اللّٰهَ (3x) – اَللّٰهُمَّ أَنْتَ السَّلَامُ... – سُبْحَانَ اللّٰهِ (33x) الْحَمْدُ لِلّٰهِ (33x) اللّٰهُ أَكْبَرُ (34x)',
    latin:
        'Astaghfirullāh (3x) – Allāhumma anta s-salām... – Subḥānallāh (33x), Al-ḥamdu lillāh (33x), Allāhu akbar (34x).',
    arti:
        'Aku memohon ampun kepada Allah (3x) ... Maha Suci Allah (33x), Segala puji bagi Allah (33x), Allah Maha Besar (34x).',
    kategori: 'Umum',
  ),
];
