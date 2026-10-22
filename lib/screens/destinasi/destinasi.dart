class Destinasi {
  final String nama;
  final double lat;
  final double lng;
  final String kota; // 'Makkah' | 'Madinah'
  const Destinasi(this.nama, this.lat, this.lng, this.kota);
}

// ——— Makkah ———
const destinasiMakkah = <Destinasi>[
  Destinasi('Masjidil Haram (Ka’bah)',        21.422487, 39.826206, 'Makkah'),
  Destinasi('Masjid Aisyah / Tan’im (Miqat)', 21.436000, 39.763400, 'Makkah'),
  Destinasi('Jabal Rahmah (Arafah)',          21.355413, 39.983476, 'Makkah'),
  Destinasi('Muzdalifah',                      21.382316, 39.932684, 'Makkah'),
  Destinasi('Mina (Kota Tenda)',               21.414174, 39.894035, 'Makkah'),
  Destinasi('Jamarat Bridge',                  21.420126, 39.893742, 'Makkah'),
  Destinasi('Jabal Nur (Gua Hira)',            21.462600, 39.859000, 'Makkah'),
  Destinasi('Jabal Tsur (Gua Tsur)',           21.381200, 39.829100, 'Makkah'),
  Destinasi('Masjid Ji’ranah (Miqat)',         21.632500, 39.916900, 'Makkah'),
  Destinasi('Hudaibiyah / As-Shumaisi',        21.462300, 39.455100, 'Makkah'),
];

// ——— Madinah ———
const destinasiMadinah = <Destinasi>[
  Destinasi('Masjid Nabawi',                   24.467266, 39.611111, 'Madinah'),
  Destinasi('Raudhah (area Nabawi)',          24.467450, 39.612250, 'Madinah'),
  Destinasi('Jannatul Baqi’ (Pemakaman)',     24.468700, 39.614800, 'Madinah'),
  Destinasi('Masjid Quba’',                    24.437154, 39.614087, 'Madinah'),
  Destinasi('Masjid Qiblatain',                24.470970, 39.565460, 'Madinah'),
  Destinasi('Jabal Uhud',                      24.507500, 39.611667, 'Madinah'),
  Destinasi('Makam Syuhada Uhud (Hamzah)',     24.518600, 39.616400, 'Madinah'),
  Destinasi('Area Khandaq / Sab’ah Masajid',   24.488900, 39.590300, 'Madinah'),
  Destinasi('Masjid Jum’ah',                   24.440700, 39.620800, 'Madinah'),
];

// Gabungan (kalau butuh)
const destinasiZiarah = <Destinasi>[
  ...destinasiMakkah,
  ...destinasiMadinah,
];