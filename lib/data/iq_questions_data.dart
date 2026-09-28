import 'dart:math';
import '../models/iq_test_model.dart';

class IqQuestionsData {
  /// Mengambil set 25 soal acak yang seimbang (5 soal per kategori: 2 Mudah, 2 Sedang, 1 Sulit).
  /// Mencegah efek hafalan (practice effect) saat tes diulang.
  static List<IqQuestion> getRandomizedTestSet({AgeGroup ageGroup = AgeGroup.age22to35}) {
    final allQuestions = getAllQuestionsPool();
    final random = Random();

    final List<IqQuestion> selected = [];

    for (final cat in IqCategory.values) {
      final pool = allQuestions.where((q) => q.category == cat).toList();
      final easy = pool.where((q) => q.difficulty == 1).toList()..shuffle(random);
      final medium = pool.where((q) => q.difficulty == 2).toList()..shuffle(random);
      final hard = pool.where((q) => q.difficulty == 3).toList()..shuffle(random);

      // Ambil 2 Easy, 2 Medium, 1 Hard (total 5 per kategori)
      selected.addAll(easy.take(2));
      selected.addAll(medium.take(2));
      selected.addAll(hard.take(1));
    }

    // Acak urutan soal agar bervariasi antar kategori
    selected.shuffle(random);
    return selected;
  }

  /// Default questions list untuk fallback atau review
  static List<IqQuestion> getQuestions() {
    return getAllQuestionsPool().take(25).toList();
  }

  /// Pool Bank Soal Lengkap: 100% Netral Budaya, Bebas Hafalan Pengetahuan Khusus, Menguji Nalar Murni.
  static List<IqQuestion> getAllQuestionsPool() {
    return [
      // =========================================================================
      // KATEGORI 1: LOGIKA ABSTRAK & MATRIKS POLA (Fluid Intelligence / Gf)
      // =========================================================================
      const IqQuestion(
        id: 'fl_1',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks logika 3×3 berikut. Tentukan simbol atau angka yang tepat untuk menggantikan tanda tanya (?):',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'grid': [
            ['●', '●●', '●●●'],
            ['▲', '▲▲', '▲▲▲'],
            ['■', '■■', '?'],
          ],
          'theme': 'symbolCount'
        },
        options: ['■', '■■', '■■■', '▲▲▲', '●●●'],
        correctOptionIndex: 2, // ■■■
        difficulty: 1,
        explanation: 'Pada setiap baris dari kiri ke kanan, jumlah bentuk geometris bertambah 1 secara konsisten:\n'
            '• Baris 1: 1 lingkaran → 2 lingkaran → 3 lingkaran\n'
            '• Baris 2: 1 segitiga → 2 segitiga → 3 segitiga\n'
            '• Baris 3: 1 kotak → 2 kotak → 3 kotak (■■■).',
      ),
      const IqQuestion(
        id: 'fl_2',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks angka analitis 3×3 berikut. Angka berapakah yang mengisi tanda tanya (?):',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'grid': [
            ['3', '5', '8'],
            ['4', '6', '10'],
            ['7', '9', '?'],
          ],
          'theme': 'matrixSum'
        },
        options: ['14', '15', '16', '18', '20'],
        correctOptionIndex: 2, // 16
        difficulty: 1,
        explanation: 'Pola penjumlahan baris mendatar:\n'
            '• Baris 1: 3 + 5 = 8\n'
            '• Baris 2: 4 + 6 = 10\n'
            '• Baris 3: 7 + 9 = 16.',
      ),
      const IqQuestion(
        id: 'fl_3',
        category: IqCategory.fluidLogic,
        questionText: 'Analisis keteraturan pada matriks perkalian 3×3 di bawah ini:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'grid': [
            ['2', '4', '8'],
            ['3', '3', '9'],
            ['5', '4', '?'],
          ],
          'theme': 'matrixMultiply'
        },
        options: ['15', '18', '20', '22', '25'],
        correctOptionIndex: 2, // 20
        difficulty: 2,
        explanation: 'Pola setiap baris adalah perkalian kolom ke-1 dengan kolom ke-2:\n'
            '• Baris 1: 2 × 4 = 8\n'
            '• Baris 2: 3 × 3 = 9\n'
            '• Baris 3: 5 × 4 = 20.',
      ),
      const IqQuestion(
        id: 'fl_4',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks selisih dan operasi kombinasi 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'grid': [
            ['12', '7', '5'],
            ['19', '11', '8'],
            ['25', '16', '?'],
          ],
          'theme': 'matrixSubtract'
        },
        options: ['7', '8', '9', '10', '11'],
        correctOptionIndex: 2, // 9
        difficulty: 2,
        explanation: 'Pola pada setiap baris: Kolom 1 - Kolom 2 = Kolom 3:\n'
            '• Baris 1: 12 - 7 = 5\n'
            '• Baris 2: 19 - 11 = 8\n'
            '• Baris 3: 25 - 16 = 9.',
      ),
      const IqQuestion(
        id: 'fl_5',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks kuadrat dan akar 3×3 di bawah ini:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'grid': [
            ['2', '3', '13'],
            ['3', '4', '25'],
            ['1', '5', '?'],
          ],
          'theme': 'matrixPythagoras'
        },
        options: ['20', '24', '26', '28', '30'],
        correctOptionIndex: 2, // 26
        difficulty: 3,
        explanation: 'Pola kolom ke-3 adalah jumlah kuadrat kolom 1 dan kolom 2 (A² + B² = C):\n'
            '• Baris 1: 2² + 3² = 4 + 9 = 13\n'
            '• Baris 2: 3² + 4² = 9 + 16 = 25\n'
            '• Baris 3: 1² + 5² = 1 + 25 = 26.',
      ),
      const IqQuestion(
        id: 'fl_6',
        category: IqCategory.fluidLogic,
        questionText: 'Temukan elemen pengisi tanda tanya (?) pada matriks pola rotasi orientasi garis berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'grid': [
            ['—', '/', '|'],
            ['/', '|', '\\'],
            ['|', '\\', '?'],
          ],
          'theme': 'lineRotation'
        },
        options: ['—', '|', '/', '\\', '+'],
        correctOptionIndex: 0, // — (Horisontal)
        difficulty: 3,
        explanation: 'Garis berputar 45° searah jarum jam pada setiap langkah:\n'
            '• — (0°) → / (45°) → | (90°) → \\ (135°) → — (180° / Horisontal).',
      ),

      // =========================================================================
      // KATEGORI 2: PERSEPSI SPASIAL & TRANSFORMASI BENTUK (Visual Processing / Gv)
      // =========================================================================
      const IqQuestion(
        id: 'sp_1',
        category: IqCategory.spatialVisual,
        questionText: 'Perhatikan urutan transformasi penambahan sisi bangun datar geometri beraturan:\n'
            'Segitiga (3 sisi) → Persegi (4 sisi) → Segilima (5 sisi) → Segienam (6 sisi) → ...\n\n'
            'Bangun apakah yang berada di urutan selanjutnya?',
        diagramType: DiagramType.shapeSequenceVisual,
        diagramData: {
          'sequence': ['Segitiga (3)', 'Persegi (4)', 'Segilima (5)', 'Segienam (6)', '?']
        },
        options: [
          'Segidelapan (Oktagon)',
          'Segitujuh (Heptagon)',
          'Lingkaran',
          'Segisembilan (Nonagon)',
          'Bujur Sangkar'
        ],
        correctOptionIndex: 1, // Segitujuh (Heptagon)
        difficulty: 1,
        explanation: 'Pola bertambah 1 sisi pada setiap tahap berurutan: 3 → 4 → 5 → 6 → 7 sisi (Segitujuh / Heptagon).',
      ),
      const IqQuestion(
        id: 'sp_2',
        category: IqCategory.spatialVisual,
        questionText: 'Jaring-jaring dadu standar 6 sisi memiliki sifat: Jumlah titik pada dua sisi yang berhadapan SELALU bernilai 7.\n\n'
            'Jika sisi ATAS dadu menunjukkan angka 3 dan sisi DEPAN menunjukkan angka 1, angka berapakah yang berada di sisi BAWAH?',
        diagramType: DiagramType.diceNetVisual,
        diagramData: {'top': 3, 'front': 1},
        options: ['2', '4', '5', '6', '1'],
        correctOptionIndex: 1, // 4
        difficulty: 1,
        explanation: 'Sisi Atas berhadapan langsung dengan sisi Bawah.\n'
            'Karena jumlah dua sisi berhadapan dadu standar selalu bernilai 7:\n'
            'Sisi Bawah = 7 - Sisi Atas = 7 - 3 = 4.',
      ),
      const IqQuestion(
        id: 'sp_3',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah jarum penunjuk mula-mula menghadap ke arah UTARA. Jarum tersebut berputar 90° searah jarum jam, lalu diputar 180° berlawanan arah jarum jam, dan akhirnya diputar 45° searah jarum jam.\n\n'
            'Ke arah mata angin manakah jarum tersebut menghadap sekarang?',
        diagramType: DiagramType.gridRotationVisual,
        diagramData: {
          'initial': 'UTARA',
          'rotations': ['+90° (CW)', '-180° (CCW)', '+45° (CW)'],
        },
        options: ['Barat Laut', 'Barat Daya', 'Timur Laut', 'Tenggara', 'Selatan'],
        correctOptionIndex: 0, // Barat Laut
        difficulty: 2,
        explanation: 'Perhitungan rotasi sudut:\n'
            '• Awal = Utara (0° / 360°)\n'
            '• +90° = Timur (90°)\n'
            '• -180° = Barat (270°)\n'
            '• +45° = Barat Laut (315°).',
      ),
      const IqQuestion(
        id: 'sp_4',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah pola titik hitam berpindah mengelilingi 4 sudut persegi berukuran 2×2 searah jarum jam:\n'
            'Kiri-Atas → Kanan-Atas → Kanan-Bawah → ...\n\n'
            'Di posisi manakah titik hitam pada langkah berikutnya?',
        diagramType: DiagramType.gridRotationVisual,
        diagramData: {
          'pattern': 'corner_travel',
          'steps': ['Kiri-Atas', 'Kanan-Atas', 'Kanan-Bawah', '?']
        },
        options: [
          'Kiri-Bawah',
          'Pusat Tengah',
          'Kiri-Atas',
          'Kanan-Atas',
          'Kanan-Bawah'
        ],
        correctOptionIndex: 0, // Kiri-Bawah
        difficulty: 2,
        explanation: 'Urutan siklus 4 sudut persegi searah jarum jam: Kiri-Atas → Kanan-Atas → Kanan-Bawah → Kiri-Bawah.',
      ),
      const IqQuestion(
        id: 'sp_5',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah kubus padat besar berukuran 3×3×3 dicat seluruh permukaan luarnya dengan cat merah, kemudian dipotong rapi menjadi 27 kubus kecil (1×1×1).\n\n'
            'Berapa jumlah kubus kecil yang memiliki TEPAT 2 sisi terkena cat merah?',
        diagramType: DiagramType.geometricCountVisual,
        diagramData: {'dimension': '3x3x3', 'type': 'cubeEdges'},
        options: ['6 kubus', '8 kubus', '12 kubus', '16 kubus', '1 kubus'],
        correctOptionIndex: 2, // 12 kubus
        difficulty: 3,
        explanation: 'Analisis kubus 3×3×3:\n'
            '• 3 sisi merah = 8 titik sudut\n'
            '• Tepat 2 sisi merah = terletak di tengah 12 rusuk kubus = 12 × 1 = 12 kubus\n'
            '• 1 sisi merah = 6 bidang sisi × 1 di tengah = 6 kubus\n'
            '• 0 sisi merah = 1 kubus inti pusat (total 27).',
      ),
      const IqQuestion(
        id: 'sp_6',
        category: IqCategory.spatialVisual,
        questionText: 'Jika selembar kertas persegi dilipat tepat menjadi 2 bagian secara simetris horisontal, lalu dilipat lagi secara vertikal, dan dibuat 1 lubang di tengahnya, berapa total lubang yang terbentuk saat kertas dibuka kembali?',
        options: ['1 lubang', '2 lubang', '3 lubang', '4 lubang', '8 lubang'],
        correctOptionIndex: 3, // 4 lubang
        difficulty: 3,
        explanation: 'Setiap lipatan menggandakan lapisan kertas (2 × 2 = 4 lapisan). Satu lubang yang menembus 4 lapisan akan menghasilkan 4 lubang simetris saat dibuka penuh.',
      ),

      // =========================================================================
      // KATEGORI 3: POLA DERET & URUTAN LOGIS (Pattern Recognition / Gq)
      // =========================================================================
      const IqQuestion(
        id: 'ps_1',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan bilangan berikutnya dalam deret kelipatan selisih berikut:\n2, 3, 5, 9, 17, 33, ...',
        options: ['49', '57', '65', '67', '71'],
        correctOptionIndex: 2, // 65
        difficulty: 1,
        explanation: 'Pola selisih antar bilangan berlipat ganda dua kali lipat:\n'
            '+1, +2, +4, +8, +16, selanjutnya +32.\n'
            'Maka: 33 + 32 = 65.',
      ),
      const IqQuestion(
        id: 'ps_2',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka yang tepat untuk melengkapi deret selang-seling di bawah ini:\n4, 18, 8, 14, 12, 10, 16, ...',
        options: ['4', '6', '8', '12', '14'],
        correctOptionIndex: 1, // 6
        difficulty: 1,
        explanation: 'Deret ini terdiri dari 2 pola berselang-seling:\n'
            '• Suku ganjil (1, 3, 5, 7): 4, 8, 12, 16 (+4)\n'
            '• Suku genap (2, 4, 6, 8): 18, 14, 10, ? (-4)\n'
            'Maka suku berikutnya: 10 - 4 = 6.',
      ),
      const IqQuestion(
        id: 'ps_3',
        category: IqCategory.patternSeries,
        questionText: 'Perhatikan deret bilangan berpola kuadrat berurutan berikut:\n3, 4, 8, 17, 33, 58, ...\n\nBerapakah angka selanjutnya?',
        options: ['82', '89', '94', '99', '104'],
        correctOptionIndex: 2, // 94
        difficulty: 2,
        explanation: 'Selisih antar angka merupakan bilangan kuadrat berurutan:\n'
            '+1² (1), +2² (4), +3² (9), +4² (16), +5² (25).\n'
            'Langkah berikutnya adalah +6² (+36).\n'
            'Hasil: 58 + 36 = 94.',
      ),
      const IqQuestion(
        id: 'ps_4',
        category: IqCategory.patternSeries,
        questionText: 'Berapakah pecahan lanjutan dari barisan rasional beraturan berikut:\n1/2, 3/4, 7/8, 15/16, 31/32, ...',
        options: ['45/64', '59/64', '61/64', '63/64', '65/64'],
        correctOptionIndex: 3, // 63/64
        difficulty: 2,
        explanation: 'Pola pembilang dan penyebut:\n'
            '• Penyebut kelipatan dua: 2, 4, 8, 16, 32, 64 (2ⁿ)\n'
            '• Pembilang = Penyebut - 1 (64 - 1 = 63)\n'
            'Pecahan berikutnya = 63/64.',
      ),
      const IqQuestion(
        id: 'ps_5',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan suku berikutnya dari deret Fibonacci bergeser berikut:\n1, 2, 3, 5, 8, 13, 21, ...',
        options: ['28', '31', '34', '37', '42'],
        correctOptionIndex: 2, // 34
        difficulty: 2,
        explanation: 'Pola Fibonacci: Setiap angka adalah hasil penjumlahan dari dua angka sebelumnya:\n'
            '1+2=3, 2+3=5, 3+5=8, 5+8=13, 8+13=21.\n'
            'Maka berikutnya: 13 + 21 = 34.',
      ),
      const IqQuestion(
        id: 'ps_6',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka yang tepat untuk melengkapi deret bertingkat tiga:\n2, 6, 12, 20, 30, 42, ...',
        options: ['52', '54', '56', '58', '60'],
        correctOptionIndex: 2, // 56
        difficulty: 3,
        explanation: 'Perhatikan selisihnya: +4, +6, +8, +10, +12. Selisih berikutnya bertambah +2 yaitu +14.\n'
            'Maka: 42 + 14 = 56 (Atau rumus n × (n+1): 1×2, 2×3, 3×4, 4×5, 5×6, 6×7, 7×8 = 56).',
      ),

      // =========================================================================
      // KATEGORI 4: NALAR HUBUNGAN KONSEP SEHARI-HARI (Relational Concept Reasoning)
      // =========================================================================
      const IqQuestion(
        id: 'ra_1',
        category: IqCategory.relationalAnalogy,
        questionText: 'Pilihlah pasangan kata yang melengkapi analogi fungsi alat ukur umum berikut:\n'
            'KOMPAS : ARAH = TERMOMETER : ...',
        options: ['CUACA', 'SUHU', 'DERAJAT', 'PANAS', 'LOGAM'],
        correctOptionIndex: 1, // SUHU
        difficulty: 1,
        explanation: 'Kompas adalah instrumen pengukur ARAH, sebagaimana Termometer adalah instrumen pengukur SUHU.',
      ),
      const IqQuestion(
        id: 'ra_2',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah pasangan fungsi perlindungan tubuh berikut:\n'
            'SARUNG TANGAN : TANGAN = SEPATU : ...',
        options: ['KAUS KAKI', 'KAKI', 'LANTAI', 'JALAN', 'KULIT'],
        correctOptionIndex: 1, // KAKI
        difficulty: 1,
        explanation: 'Sarung tangan dikenakan untuk melindungi Tangan, sebagaimana Sepatu dikenakan untuk melindungi Kaki.',
      ),
      const IqQuestion(
        id: 'ra_3',
        category: IqCategory.relationalAnalogy,
        questionText: 'Pilihlah pasangan analogi kebutuhan biologis mendasar yang PALING TEPAT:\n'
            'HAUS : AIR = LAPAR : ...',
        options: ['PIRING', 'SENDOK', 'MAKANAN', 'DAPUR', 'KENYANG'],
        correctOptionIndex: 2, // MAKANAN
        difficulty: 1,
        explanation: 'Rasa haus dipenuhi dan dihilangkan dengan AIR, sebagaimana rasa lapar dipenuhi dan dihilangkan dengan MAKANAN.',
      ),
      const IqQuestion(
        id: 'ra_4',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah analogi pengemudi transportasi berikut:\n'
            'KAPAL : NAHKODA = PESAWAT : ...',
        options: ['KEMUDI', 'BANDARA', 'PILOT', 'SAYAP', 'MESIN'],
        correctOptionIndex: 2, // PILOT
        difficulty: 2,
        explanation: 'Kapal dikemudikan secara profesional oleh Nahkoda, sebagaimana Pesawat dikemudikan oleh Pilot.',
      ),
      const IqQuestion(
        id: 'ra_5',
        category: IqCategory.relationalAnalogy,
        questionText: 'Tentukan padanan hubungan wadah dan isinya:\n'
            'DOMPET : UANG = LEMARI : ...',
        options: ['KAYU', 'PAKAIAN', 'PINTU', 'KUNCI', 'KAMAR'],
        correctOptionIndex: 1, // PAKAIAN
        difficulty: 2,
        explanation: 'Dompet adalah tempat khusus menyimpan Uang, sebagaimana Lemari adalah tempat khusus menyimpan Pakaian.',
      ),
      const IqQuestion(
        id: 'ra_6',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah analogi relasi waktu dan alat penunjuknya:\n'
            'JAM : WAKTU = PENGGARIS : ...',
        options: ['PANJANG / JARAK', 'ANGKA', 'PLASTIK', 'KERTAS', 'TULISAN'],
        correctOptionIndex: 0, // PANJANG / JARAK
        difficulty: 3,
        explanation: 'Jam berfungsi mengukur besaran WAKTU, sedangkan Penggaris berfungsi mengukur besaran PANJANG/JARAK.',
      ),

      // =========================================================================
      // KATEGORI 5: DEDUKSI & PEMECAHAN MASALAH (Problem Solving & Logic)
      // =========================================================================
      const IqQuestion(
        id: 'pd_1',
        category: IqCategory.problemDeduction,
        questionText: 'Perhatikan aturan timbangan neraca berikut:\n'
            '• 2 Buah Apel = 1 Buah Mangga\n'
            '• 3 Buah Mangga = 1 Buah Melon\n\n'
            'Berapa buah Apel yang dibutuhkan untuk mengimbangi berat 2 Buah Melon?',
        diagramType: DiagramType.scaleBalanceVisual,
        diagramData: {'relation': '2 Apel = 1 Mangga, 3 Mangga = 1 Melon'},
        options: ['6 Apel', '8 Apel', '10 Apel', '12 Apel', '16 Apel'],
        correctOptionIndex: 3, // 12 Apel
        difficulty: 1,
        explanation: 'Substitusi neraca:\n'
            '• 1 Melon = 3 Mangga\n'
            '• Karena 1 Mangga = 2 Apel, maka 1 Melon = 3 × 2 Apel = 6 Apel\n'
            '• Maka 2 Melon = 2 × 6 Apel = 12 Apel.',
      ),
      const IqQuestion(
        id: 'pd_2',
        category: IqCategory.problemDeduction,
        questionText: 'Perhatikan premis logika berikut:\n'
            '• Premis 1: Jika hari ini hujan lebat, maka jalan raya basah.\n'
            '• Premis 2: Jalan raya saat ini kering (tidak basah sama sekali).\n\n'
            'Kesimpulan yang PASTI BENAR menurut aturan logika adalah:',
        options: [
          'Hari ini tidak hujan lebat.',
          'Kemungkinan hari ini gerimis.',
          'Jalanan baru saja dibersihkan.',
          'Akan segera turun hujan lebat.',
          'Tidak dapat disimpulkan.'
        ],
        correctOptionIndex: 0, // Hari ini tidak hujan lebat.
        difficulty: 1,
        explanation: 'Kaidah Modus Tollens:\n'
            'Jika P → Q, dan diketahui ~Q (jalan tidak basah), maka kesimpulan logis mutlak adalah ~P (Hari ini tidak hujan lebat).',
      ),
      const IqQuestion(
        id: 'pd_3',
        category: IqCategory.problemDeduction,
        questionText: '5 mesin pabrik yang identik membutuhkan waktu tepat 5 menit untuk menghasilkan 5 produk.\n\n'
            'Berapa menit waktu yang dibutuhkan oleh 100 mesin serupa untuk menghasilkan 100 produk secara bersamaan?',
        options: ['1 menit', '5 menit', '20 menit', '50 menit', '100 menit'],
        correctOptionIndex: 1, // 5 menit
        difficulty: 2,
        explanation: 'Laju produktivitas paralel:\n'
            'Jika 5 mesin membuat 5 produk dalam 5 menit, berarti 1 mesin membutuhkan 5 menit untuk membuat 1 produk.\n'
            'Jika 100 mesin bekerja bersamaan, dalam 5 menit masing-masing mesin menyelesaikan 1 produk (total 100 produk). Waktunya tetap 5 menit.',
      ),
      const IqQuestion(
        id: 'pd_4',
        category: IqCategory.problemDeduction,
        questionText: 'Sebuah mobil melaju dari Kota A menuju Kota B dengan kecepatan 60 km/jam. Pada saat bersamaan, sebuah truk melaju dari Kota B menuju Kota A dengan kecepatan 40 km/jam.\n\n'
            'Jika jarak Kota A dan Kota B adalah 200 km, setelah berapa jam mereka akan berpapasan di jalan?',
        options: ['1,5 jam', '2 jam', '2,5 jam', '3 jam', '4 jam'],
        correctOptionIndex: 1, // 2 jam
        difficulty: 2,
        explanation: 'Waktu berpapasan = Jarak Total / (Kecepatan 1 + Kecepatan 2)\n'
            'Waktu = 200 km / (60 + 40 km/jam) = 200 / 100 = 2 jam.',
      ),
      const IqQuestion(
        id: 'pd_5',
        category: IqCategory.problemDeduction,
        questionText: 'Umur seorang Ayah saat ini adalah 3 kali umur Budi. Sepuluh tahun yang akan datang, umur Ayah menjadi 2 kali umur Budi.\n\n'
            'Berapakah umur Budi saat ini?',
        options: ['10 tahun', '12 tahun', '15 tahun', '20 tahun', '25 tahun'],
        correctOptionIndex: 0, // 10 tahun
        difficulty: 3,
        explanation: 'Aljabar logika:\n'
            '1) Ayah = 3 × Budi (A = 3B)\n'
            '2) (A + 10) = 2 × (B + 10)\n'
            '3B + 10 = 2B + 20 → B = 10 tahun.',
      ),
      const IqQuestion(
        id: 'pd_6',
        category: IqCategory.problemDeduction,
        questionText: 'Empat anak (Andi, Budi, Citra, Doni) memiliki tinggi badan berbeda:\n'
            '• Andi lebih tinggi dari Budi.\n'
            '• Citra lebih pendek dari Doni.\n'
            '• Doni lebih pendek dari Budi.\n\n'
            'Siapakah yang memiliki tinggi badan paling tinggi di antara mereka?',
        options: ['Andi', 'Budi', 'Citra', 'Doni', 'Andi dan Budi sama'],
        correctOptionIndex: 0, // Andi
        difficulty: 3,
        explanation: 'Urutan tinggi badan dari tertinggi ke terpendek:\n'
            '1. Andi > Budi\n'
            '2. Budi > Doni\n'
            '3. Doni > Citra\n'
            'Urutan lengkap: Andi > Budi > Doni > Citra. Yang paling tinggi adalah Andi.',
      ),
    ];
  }
}
