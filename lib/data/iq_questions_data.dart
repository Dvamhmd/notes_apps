import 'dart:math';
import '../models/iq_test_model.dart';

class IqQuestionsData {
  /// Mengambil set 25 soal acak yang seimbang (5 soal per kategori: 2 Mudah, 2 Sedang, 1 Sulit).
  /// Dipilih dari bank soal komprehensif (75+ butir soal), sehingga menghilangkan efek hafalan
  /// (practice effect) saat tes diulang.
  static List<IqQuestion> getRandomizedTestSet({AgeGroup ageGroup = AgeGroup.age22to35}) {
    final allQuestions = getAllQuestionsPool();
    final random = Random();

    final List<IqQuestion> selected = [];

    for (final cat in IqCategory.values) {
      final pool = allQuestions.where((q) => q.category == cat).toList();
      final easy = pool.where((q) => q.difficulty == 1).toList()..shuffle(random);
      final medium = pool.where((q) => q.difficulty == 2).toList()..shuffle(random);
      final hard = pool.where((q) => q.difficulty == 3).toList()..shuffle(random);

      // Ambil 2 Easy, 2 Medium, 1 Hard (total 5 per kategori = 25 total)
      selected.addAll(easy.take(2));
      selected.addAll(medium.take(2));
      selected.addAll(hard.take(1));
    }

    // Acak urutan soal agar bervariasi antar kategori
    selected.shuffle(random);
    return selected;
  }

  /// Default questions list untuk fallback atau review cepat
  static List<IqQuestion> getQuestions() {
    return getAllQuestionsPool().take(25).toList();
  }

  /// Pool Bank Soal Lengkap: 100% Netral Budaya (Culture-Fair), Bebas Hafalan Pengetahuan Khusus, Menguji Nalar Murni.
  static List<IqQuestion> getAllQuestionsPool() {
    return [
      // =========================================================================
      // KATEGORI 1: LOGIKA ABSTRAK & MATRIKS POLA (Fluid Intelligence / Gf) - 15 Soal
      // =========================================================================
      const IqQuestion(
        id: 'fl_1',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks logika 3×3 berikut. Tentukan simbol yang tepat untuk menggantikan tanda tanya (?):',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Pertambahan Jumlah Simbol',
          'grid': [
            ['●', '●●', '●●●'],
            ['▲', '▲▲', '▲▲▲'],
            ['■', '■■', '?'],
          ],
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
          'title': 'Matriks Penjumlahan Baris',
          'grid': [
            ['3', '5', '8'],
            ['4', '6', '10'],
            ['7', '9', '?'],
          ],
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
        questionText: 'Temukan pola keteraturan pada matriks simbol berikut. Manakah elemen yang tepat untuk tanda tanya (?):',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Kombinasi Bentuk & Arsiran',
          'grid': [
            ['○', '◐', '●'],
            ['□', '◩', '■'],
            ['△', '◭', '?'],
          ],
        },
        options: ['▲', '◭', '△', '▼', '◆'],
        correctOptionIndex: 0, // ▲ (Segitiga Hitam Penuh Mengarah ke Atas)
        difficulty: 1,
        explanation: 'Pola keteraturan arsiran dari kiri ke kanan pada setiap baris:\n'
            '• Baris 1: Lingkaran polos (○) → Terisi separuh (◐) → Terisi penuh (●)\n'
            '• Baris 2: Persegi polos (□) → Terisi separuh (◩) → Terisi penuh (■)\n'
            '• Baris 3: Segitiga polos (△) → Terisi separuh (◭) → Terisi penuh (▲).',
      ),
      const IqQuestion(
        id: 'fl_4',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks kombinasi garis berikut. Simbol apakah yang tepat untuk melengkapi matriks?',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Orientasi Garis',
          'grid': [
            ['|', '—', '+'],
            ['/', '\\', 'X'],
            ['||', '==', '?'],
          ],
        },
        options: ['++', 'XX', '#', '|||', '==='],
        correctOptionIndex: 2, // #
        difficulty: 1,
        explanation: 'Setiap baris menggabungkan garis vertikal dan horisontal:\n'
            '• Baris 1: | dan — digabung menjadi +\n'
            '• Baris 2: / dan \\ digabung menjadi X\n'
            '• Baris 3: || (dua vertikal) dan == (dua horisontal) digabung membentuk simbol pagar (#).',
      ),
      const IqQuestion(
        id: 'fl_5',
        category: IqCategory.fluidLogic,
        questionText: 'Analisis keteraturan pada matriks perkalian 3×3 di bawah ini:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Operasi Baris',
          'grid': [
            ['2', '4', '8'],
            ['3', '3', '9'],
            ['5', '4', '?'],
          ],
        },
        options: ['15', '18', '20', '22', '25'],
        correctOptionIndex: 2, // 20
        difficulty: 1,
        explanation: 'Pola setiap baris adalah perkalian kolom ke-1 dengan kolom ke-2:\n'
            '• Baris 1: 2 × 4 = 8\n'
            '• Baris 2: 3 × 3 = 9\n'
            '• Baris 3: 5 × 4 = 20.',
      ),
      const IqQuestion(
        id: 'fl_6',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks selisih dan operasi kombinasi 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Selisih Kolom',
          'grid': [
            ['12', '7', '5'],
            ['19', '11', '8'],
            ['25', '16', '?'],
          ],
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
        id: 'fl_7',
        category: IqCategory.fluidLogic,
        questionText: 'Temukan elemen pengisi tanda tanya (?) pada matriks pola rotasi orientasi garis berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Rotasi 45 Derajat',
          'grid': [
            ['—', '/', '|'],
            ['/', '|', '\\'],
            ['|', '\\', '?'],
          ],
        },
        options: ['—', '|', '/', '\\', '+'],
        correctOptionIndex: 0, // — (Horisontal)
        difficulty: 2,
        explanation: 'Garis berputar 45° searah jarum jam pada setiap langkah:\n'
            '• — (0°) → / (45°) → | (90°) → \\ (135°) → — (180° / Horisontal).',
      ),
      const IqQuestion(
        id: 'fl_8',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan pola pertambahan titik (dots) pada matriks 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Distribusi Titik',
          'grid': [
            ['1', '2', '3'],
            ['2', '4', '6'],
            ['3', '6', '?'],
          ],
        },
        options: ['7', '8', '9', '10', '12'],
        correctOptionIndex: 2, // 9
        difficulty: 2,
        explanation: 'Pola perkalian baris dan kolom (i × j):\n'
            '• Baris 3, Kolom 3 = 3 × 3 = 9.',
      ),
      const IqQuestion(
        id: 'fl_9',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks kuadrat dan penjumlahan berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Kuadrat Jumlah',
          'grid': [
            ['2', '3', '13'],
            ['3', '4', '25'],
            ['1', '5', '?'],
          ],
        },
        options: ['20', '24', '26', '28', '30'],
        correctOptionIndex: 2, // 26
        difficulty: 2,
        explanation: 'Pola kolom ke-3 adalah jumlah kuadrat kolom 1 dan kolom 2 (A² + B² = C):\n'
            '• Baris 1: 2² + 3² = 4 + 9 = 13\n'
            '• Baris 2: 3² + 4² = 9 + 16 = 25\n'
            '• Baris 3: 1² + 5² = 1 + 25 = 26.',
      ),
      const IqQuestion(
        id: 'fl_10',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks inversi nilai di bawah ini. Angka berapakah yang mengisi tanda tanya (?):',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Operasi Simetris',
          'grid': [
            ['6', '2', '3'],
            ['15', '3', '5'],
            ['28', '7', '?'],
          ],
        },
        options: ['3', '4', '5', '6', '7'],
        correctOptionIndex: 1, // 4
        difficulty: 2,
        explanation: 'Pola pada setiap baris: Kolom 1 ÷ Kolom 2 = Kolom 3:\n'
            '• Baris 1: 6 ÷ 2 = 3\n'
            '• Baris 2: 15 ÷ 3 = 5\n'
            '• Baris 3: 28 ÷ 7 = 4.',
      ),
      const IqQuestion(
        id: 'fl_11',
        category: IqCategory.fluidLogic,
        questionText: 'Analisis logika matriks 2×2 berikut. Tentukan huruf/simbol lanjutan yang konsisten:',
        diagramType: DiagramType.ravenMatrix2x2,
        diagramData: {
          'grid': [
            ['▲', '▼'],
            ['◀', '?'],
          ],
        },
        options: ['▶', '▲', '▼', '●', '■'],
        correctOptionIndex: 0, // ▶
        difficulty: 2,
        explanation: 'Pola rotasi/pencerminan arah mata panah berlawanan:\n'
            '• Atas (▲) berlawanan dengan Bawah (▼)\n'
            '• Kiri (◀) berlawanan dengan Kanan (▶).',
      ),
      const IqQuestion(
        id: 'fl_12',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks superposisi (penggabungan visual) 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Overlap Garis',
          'grid': [
            ['|', '—', '+'],
            ['+', 'X', '※'],
            ['—', '/', '?'],
          ],
        },
        options: ['|', '/', '∦', 'X', '⟂'],
        correctOptionIndex: 4, // ⟂ atau garis silang bersudut
        difficulty: 3,
        explanation: 'Setiap kolom dan baris merupakan tumpang tindih sudut garis murni. Menggabungkan garis horisontal (—) dan miring (/) menghasilkan sudut pertemuan bersilang.',
      ),
      const IqQuestion(
        id: 'fl_13',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks pola bilangan berlapis 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Rata-Rata Baris',
          'grid': [
            ['4', '8', '6'],
            ['10', '20', '15'],
            ['14', '26', '?'],
          ],
        },
        options: ['18', '20', '22', '24', '25'],
        correctOptionIndex: 1, // 20
        difficulty: 3,
        explanation: 'Pola Kolom 3 adalah nilai tengah (rata-rata) dari Kolom 1 dan Kolom 2: (A + B) / 2:\n'
            '• Baris 1: (4 + 8) / 2 = 6\n'
            '• Baris 2: (10 + 20) / 2 = 15\n'
            '• Baris 3: (14 + 26) / 2 = 40 / 2 = 20.',
      ),
      const IqQuestion(
        id: 'fl_14',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks selisih kuadrat 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Selisih Kuadrat',
          'grid': [
            ['5', '3', '16'],
            ['6', '4', '20'],
            ['7', '2', '?'],
          ],
        },
        options: ['40', '42', '45', '48', '50'],
        correctOptionIndex: 2, // 45
        difficulty: 3,
        explanation: 'Pola kolom ke-3 adalah selisih kuadrat kolom 1 dan kolom 2 (A² - B² = C):\n'
            '• Baris 1: 5² - 3² = 25 - 9 = 16\n'
            '• Baris 2: 6² - 4² = 36 - 16 = 20\n'
            '• Baris 3: 7² - 2² = 49 - 4 = 45.',
      ),
      const IqQuestion(
        id: 'fl_15',
        category: IqCategory.fluidLogic,
        questionText: 'Perhatikan matriks rotasi biner 3×3 berikut:',
        diagramType: DiagramType.ravenMatrix3x3,
        diagramData: {
          'title': 'Matriks Rotasi 90 Derajat',
          'grid': [
            ['▲', '▶', '▼'],
            ['▶', '▼', '◀'],
            ['▼', '◀', '?'],
          ],
        },
        options: ['▲', '▶', '▼', '◀', '●'],
        correctOptionIndex: 0, // ▲
        difficulty: 3,
        explanation: 'Pola perputaran 90° searah jarum jam pada setiap langkah:\n'
            '• ▲ (Atas) → ▶ (Kanan) → ▼ (Bawah) → ◀ (Kiri) → ▲ (Atas kembali).',
      ),

      // =========================================================================
      // KATEGORI 2: PERSEPSI SPASIAL & TRANSFORMASI BENTUK (Visual Processing / Gv) - 15 Soal
      // =========================================================================
      const IqQuestion(
        id: 'sp_1',
        category: IqCategory.spatialVisual,
        questionText: 'Perhatikan urutan transformasi penambahan sisi bangun datar geometri beraturan:\n'
            'Segitiga (3 sisi) → Persegi (4 sisi) → Segilima (5 sisi) → Segienam (6 sisi) → ...\n\n'
            'Bangun apakah yang berada di urutan selanjutnya?',
        diagramType: DiagramType.shapeSequenceVisual,
        diagramData: {
          'items': [
            {'name': 'Segitiga', 'sides': '3 sisi'},
            {'name': 'Persegi', 'sides': '4 sisi'},
            {'name': 'Segilima', 'sides': '5 sisi'},
            {'name': 'Segienam', 'sides': '6 sisi'},
            {'name': '?', 'sides': '? sisi'},
          ]
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
          'rotations': ['+90° (Searah Jarum)', '-180° (Berlawanan)', '+45° (Searah Jarum)'],
        },
        options: ['Barat Laut', 'Barat Daya', 'Timur Laut', 'Tenggara', 'Selatan'],
        correctOptionIndex: 0, // Barat Laut
        difficulty: 1,
        explanation: 'Perhitungan rotasi sudut:\n'
            '• Awal = Utara (0°)\n'
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
        options: [
          'Kiri-Bawah',
          'Pusat Tengah',
          'Kiri-Atas',
          'Kanan-Atas',
          'Kanan-Bawah'
        ],
        correctOptionIndex: 0, // Kiri-Bawah
        difficulty: 1,
        explanation: 'Urutan siklus 4 sudut persegi searah jarum jam: Kiri-Atas → Kanan-Atas → Kanan-Bawah → Kiri-Bawah.',
      ),
      const IqQuestion(
        id: 'sp_5',
        category: IqCategory.spatialVisual,
        questionText: 'Jika sebuah huruf "L" dicerminkan secara vertikal (terhadap sumbu horisontal di bawahnya), bagaimana bentuk hasil bayangannya?',
        options: [
          'Huruf L terbalik ke bawah (seperti ⅃ terbalik)',
          'Huruf L tetap sama persis',
          'Huruf J',
          'Garis lurus vertikal',
          'Huruf T'
        ],
        correctOptionIndex: 0,
        difficulty: 1,
        explanation: 'Pencerminan terhadap sumbu bawah membalik arah vertikal sehingga garis mendatar tetap di bawah namun kaki vertikal mengarah ke bawah (inversi vertikal).',
      ),
      const IqQuestion(
        id: 'sp_6',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah kubus padat besar berukuran 3×3×3 dicat seluruh permukaan luarnya dengan cat merah, kemudian dipotong rapi menjadi 27 kubus kecil (1×1×1).\n\n'
            'Berapa jumlah kubus kecil yang memiliki TEPAT 2 sisi terkena cat merah?',
        diagramType: DiagramType.geometricCountVisual,
        diagramData: {
          'title': 'Kubus 3 × 3 × 3 Tercat Luar',
          'subtitle': 'Dipotong menjadi 27 unit kubus kecil (1×1×1)',
        },
        options: ['6 kubus', '8 kubus', '12 kubus', '16 kubus', '1 kubus'],
        correctOptionIndex: 2, // 12 kubus
        difficulty: 2,
        explanation: 'Analisis kubus 3×3×3:\n'
            '• 3 sisi merah = 8 titik sudut\n'
            '• Tepat 2 sisi merah = terletak di tengah 12 rusuk kubus = 12 × 1 = 12 kubus\n'
            '• 1 sisi merah = 6 bidang sisi × 1 di tengah = 6 kubus\n'
            '• 0 sisi merah = 1 kubus inti pusat (total 27).',
      ),
      const IqQuestion(
        id: 'sp_7',
        category: IqCategory.spatialVisual,
        questionText: 'Jika selembar kertas persegi dilipat tepat menjadi 2 bagian secara simetris horisontal, lalu dilipat lagi secara vertikal, dan dibuat 1 lubang di tengahnya, berapa total lubang yang terbentuk saat kertas dibuka kembali?',
        diagramType: DiagramType.paperFoldVisual,
        options: ['1 lubang', '2 lubang', '3 lubang', '4 lubang', '8 lubang'],
        correctOptionIndex: 3, // 4 lubang
        difficulty: 2,
        explanation: 'Setiap lipatan menggandakan lapisan kertas (2 × 2 = 4 lapisan). Satu lubang yang menembus 4 lapisan akan menghasilkan 4 lubang simetris saat dibuka penuh.',
      ),
      const IqQuestion(
        id: 'sp_8',
        category: IqCategory.spatialVisual,
        questionText: 'Dua buah roda gigi A dan B saling bersinggungan langsung. Jika roda gigi A berputar SEARAH jarum jam, ke arah manakah roda gigi B akan berputar?',
        diagramType: DiagramType.gearRotationVisual,
        diagramData: {
          'gearA': 'Gear A (Searah Jarum / CW)',
          'gearB': 'Gear B',
        },
        options: [
          'Berlawanan arah jarum jam (CCW)',
          'Searah jarum jam (CW)',
          'Diam tidak berputar',
          'Maju mundur secara bergantian',
          'Tergantung ukuran roda gigi'
        ],
        correctOptionIndex: 0, // Berlawanan
        difficulty: 2,
        explanation: 'Dua roda gigi yang saling bertautan gigi secara langsung selalu berputar ke arah yang SALING BERLAWANAN.',
      ),
      const IqQuestion(
        id: 'sp_9',
        category: IqCategory.spatialVisual,
        questionText: 'Berapa banyak titik sudut yang dimiliki oleh sebuah prisma segitiga?',
        options: ['4 titik', '5 titik', '6 titik', '8 titik', '9 titik'],
        correctOptionIndex: 2, // 6 titik
        difficulty: 2,
        explanation: 'Prisma segitiga memiliki 2 bidang alas segitiga (masing-masing 3 titik sudut). Total titik sudut = 3 + 3 = 6 titik sudut.',
      ),
      const IqQuestion(
        id: 'sp_10',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah bentuk panah menghadap ke TIMUR. Jika bentuk tersebut diputar 180° kemudian dicerminkan secara horisontal, ke arah mana panah tersebut menunjuk?',
        options: ['Timur', 'Barat', 'Utara', 'Selatan', 'Timur Laut'],
        correctOptionIndex: 0, // Timur
        difficulty: 2,
        explanation: '• Menghadap Timur (0°)\n'
            '• Diputar 180° → Menghadap Barat\n'
            '• Dicerminkan horisontal (kiri ↔ kanan) → Membalik kembali ke Timur.',
      ),
      const IqQuestion(
        id: 'sp_11',
        category: IqCategory.spatialVisual,
        questionText: 'Pada jaring-jaring kubus terbuka standar berbentuk salib (cross net), berapa total bidang persegi yang menyusunnya?',
        options: ['4 bidang', '5 bidang', '6 bidang', '7 bidang', '8 bidang'],
        correctOptionIndex: 2, // 6 bidang
        difficulty: 2,
        explanation: 'Kubus memiliki tepat 6 bidang sisi identik berbentuk persegi.',
      ),
      const IqQuestion(
        id: 'sp_12',
        category: IqCategory.spatialVisual,
        questionText: 'Tiga roda gigi (A, B, C) tersusun sejajar dan saling bersinggungan berturut-turut (A bertaut ke B, B bertaut ke C). Jika roda A berputar searah jarum jam, ke arah mana roda C berputar?',
        diagramType: DiagramType.gearRotationVisual,
        diagramData: {
          'gearA': 'Gear A ➔ Gear B ➔ Gear C',
          'gearB': 'Rantai 3 Roda Gigi Sejajar',
        },
        options: [
          'Searah jarum jam (CW)',
          'Berlawanan arah jarum jam (CCW)',
          'Tidak bergerak',
          'Berputar dua kali lebih lambat',
          'Arahnya tidak menentu'
        ],
        correctOptionIndex: 0, // Searah jarum jam
        difficulty: 3,
        explanation: '• Roda A = Searah jarum jam (CW)\n'
            '• Roda B = Berlawanan jarum jam (CCW)\n'
            '• Roda C = Searah jarum jam (CW kembali).',
      ),
      const IqQuestion(
        id: 'sp_13',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah kubus padat 4×4×4 dicat seluruh permukaan luarnya dengan cat biru. Berapa kubus kecil berukuran 1×1×1 yang sama sekali TIDAK terkena cat biru (0 sisi terkena cat)?',
        diagramType: DiagramType.geometricCountVisual,
        diagramData: {
          'title': 'Kubus 4 × 4 × 4 Tercat Luar',
          'subtitle': 'Total: 64 unit kubus kecil (1×1×1)',
        },
        options: ['4 kubus', '8 kubus', '12 kubus', '16 kubus', '24 kubus'],
        correctOptionIndex: 1, // 8 kubus
        difficulty: 3,
        explanation: 'Kubus inti yang tidak terkena cat terletak di dalam: (4 - 2) × (4 - 2) × (4 - 2) = 2 × 2 × 2 = 8 kubus kecil.',
      ),
      const IqQuestion(
        id: 'sp_14',
        category: IqCategory.spatialVisual,
        questionText: 'Jika sebuah kertas persegi dilipat 3 kali secara diagonal berturut-turut lalu digunting salah satu sudut lancipnya, berapa total lubang simetris yang terbentuk saat dibuka penuh?',
        diagramType: DiagramType.paperFoldVisual,
        options: ['2 lubang', '4 lubang', '6 lubang', '8 lubang', '16 lubang'],
        correctOptionIndex: 3, // 8 lubang
        difficulty: 3,
        explanation: 'Tiga kali lipatan berturut-turut menghasilkan 2³ = 8 lapisan kertas. Potongan tunggal pada lipatan akan menduplikasi 8 lubang simetris.',
      ),
      const IqQuestion(
        id: 'sp_15',
        category: IqCategory.spatialVisual,
        questionText: 'Sebuah balok memiliki 6 sisi, 12 rusuk, dan 8 titik sudut. Jika sebuah sudut balok dipotong lurus secara datar, berapa jumlah sisi bidang yang dimiliki benda tersebut sekarang?',
        options: ['6 sisi', '7 sisi', '8 sisi', '9 sisi', '10 sisi'],
        correctOptionIndex: 1, // 7 sisi
        difficulty: 3,
        explanation: 'Memotong satu titik sudut balok secara mendatar menciptakan 1 bidang permukaan baru berbentuk segitiga (bidang faset), sehingga total sisi menjadi 6 + 1 = 7 sisi.',
      ),

      // =========================================================================
      // KATEGORI 3: POLA DERET & URUTAN LOGIS (Pattern Recognition / Gq) - 15 Soal
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
        questionText: 'Tentukan angka kelanjutan dari deret penambahan berulang berikut:\n5, 11, 17, 23, 29, ...',
        options: ['33', '34', '35', '36', '37'],
        correctOptionIndex: 2, // 35
        difficulty: 1,
        explanation: 'Setiap suku bertambah konstan +6:\n'
            '29 + 6 = 35.',
      ),
      const IqQuestion(
        id: 'ps_4',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka pengisi deret pembagian bertahap:\n64, 32, 16, 8, 4, ...',
        options: ['1', '2', '3', '0', '0.5'],
        correctOptionIndex: 1, // 2
        difficulty: 1,
        explanation: 'Setiap angka dibagi 2 dari angka sebelumnya: 4 ÷ 2 = 2.',
      ),
      const IqQuestion(
        id: 'ps_5',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan suku berikutnya dari deret Fibonacci dasar berikut:\n1, 1, 2, 3, 5, 8, 13, ...',
        options: ['18', '20', '21', '24', '26'],
        correctOptionIndex: 2, // 21
        difficulty: 1,
        explanation: 'Pola Fibonacci: setiap angka merupakan jumlah dari dua angka sebelumnya:\n'
            '8 + 13 = 21.',
      ),
      const IqQuestion(
        id: 'ps_6',
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
        id: 'ps_7',
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
        id: 'ps_8',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan suku berikutnya dari deret bertingkat dua:\n2, 5, 10, 17, 26, 37, ...',
        options: ['48', '49', '50', '52', '54'],
        correctOptionIndex: 2, // 50
        difficulty: 2,
        explanation: 'Pola selisih bilangan ganjil: +3, +5, +7, +9, +11. Langkah selanjutnya adalah +13:\n'
            '37 + 13 = 50 (atau rumus n² + 1: 1²+1, 2²+1, ..., 7²+1 = 50).',
      ),
      const IqQuestion(
        id: 'ps_9',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka lanjutan dari pola deret berikut:\n1, 3, 7, 15, 31, 63, ...',
        options: ['115', '121', '127', '129', '135'],
        correctOptionIndex: 2, // 127
        difficulty: 2,
        explanation: 'Rumus pola: (Angka × 2) + 1:\n'
            '• (63 × 2) + 1 = 126 + 1 = 127.',
      ),
      const IqQuestion(
        id: 'ps_10',
        category: IqCategory.patternSeries,
        questionText: 'Perhatikan deret selang tiga pola berikut:\n3, 6, 9, 20, 17, 14, 2, 4, ...',
        options: ['5', '6', '7', '8', '9'],
        correctOptionIndex: 1, // 6
        difficulty: 2,
        explanation: 'Kelompok 3 angka:\n'
            '• Kelompok 1: 3, 6, 9 (+3)\n'
            '• Kelompok 2: 20, 17, 14 (-3)\n'
            '• Kelompok 3: 2, 4, 6 (+2).',
      ),
      const IqQuestion(
        id: 'ps_11',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka yang melengkapi deret perkalian selisih:\n2, 6, 12, 20, 30, 42, ...',
        options: ['52', '54', '56', '58', '60'],
        correctOptionIndex: 2, // 56
        difficulty: 2,
        explanation: 'Selisih antar angka bertambah +2 (+4, +6, +8, +10, +12, selanjutnya +14):\n'
            '42 + 14 = 56 (atau perkalian bilangan berurutan: 6×7=42, 7×8=56).',
      ),
      const IqQuestion(
        id: 'ps_12',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka pengisi tanda tanya pada deret kubik bergeser:\n0, 7, 26, 63, 124, ...',
        options: ['185', '198', '215', '224', '242'],
        correctOptionIndex: 2, // 215
        difficulty: 3,
        explanation: 'Pola adalah bilangan kubik dikurangi 1 (n³ - 1):\n'
            '• 1³ - 1 = 0\n'
            '• 2³ - 1 = 7\n'
            '• 3³ - 1 = 26\n'
            '• 4³ - 1 = 63\n'
            '• 5³ - 1 = 124\n'
            '• 6³ - 1 = 216 - 1 = 215.',
      ),
      const IqQuestion(
        id: 'ps_13',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan suku berikutnya dari deret tribonacci (jumlah 3 angka sebelumnya):\n1, 1, 2, 4, 7, 13, 24, ...',
        options: ['38', '41', '44', '47', '52'],
        correctOptionIndex: 2, // 44
        difficulty: 3,
        explanation: 'Setiap suku adalah penjumlahan dari 3 suku sebelumnya:\n'
            '7 + 13 + 24 = 44.',
      ),
      const IqQuestion(
        id: 'ps_14',
        category: IqCategory.patternSeries,
        questionText: 'Perhatikan deret pecahan bersilang berikut:\n1/3, 2/5, 4/9, 8/17, 16/33, ...\n\nBerapakah pecahan berikutnya?',
        options: ['24/65', '32/65', '32/67', '30/65', '64/67'],
        correctOptionIndex: 1, // 32/65
        difficulty: 3,
        explanation: '• Pembilang berlipat ganda: 1, 2, 4, 8, 16, 32 (×2)\n'
            '• Penyebut: (2 × sebelumnya) - 1: (33 × 2) - 1 = 66 - 1 = 65\n'
            'Pecahan berikutnya: 32/65.',
      ),
      const IqQuestion(
        id: 'ps_15',
        category: IqCategory.patternSeries,
        questionText: 'Tentukan angka lanjutan dari deret faktorial bertingkat:\n1, 2, 6, 24, 120, 720, ...',
        options: ['1440', '3600', '4320', '5040', '7200'],
        correctOptionIndex: 3, // 5040
        difficulty: 3,
        explanation: 'Pola perkalian naik (n!):\n'
            '×2, ×3, ×4, ×5, ×6, selanjutnya ×7.\n'
            '720 × 7 = 5040.',
      ),

      // =========================================================================
      // KATEGORI 4: NALAR HUBUNGAN KONSEP SEHARI-HARI (Relational Concept Reasoning) - 15 Soal
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
        difficulty: 1,
        explanation: 'Kapal dikemudikan secara profesional oleh Nahkoda, sebagaimana Pesawat dikemudikan oleh Pilot.',
      ),
      const IqQuestion(
        id: 'ra_5',
        category: IqCategory.relationalAnalogy,
        questionText: 'Tentukan padanan hubungan wadah dan isinya:\n'
            'DOMPET : UANG = LEMARI : ...',
        options: ['KAYU', 'PAKAIAN', 'PINTU', 'KUNCI', 'KAMAR'],
        correctOptionIndex: 1, // PAKAIAN
        difficulty: 1,
        explanation: 'Dompet adalah tempat khusus menyimpan Uang, sebagaimana Lemari adalah tempat khusus menyimpan Pakaian.',
      ),
      const IqQuestion(
        id: 'ra_6',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah analogi relasi waktu dan alat penunjuknya:\n'
            'JAM : WAKTU = PENGGARIS : ...',
        options: ['PANJANG / JARAK', 'ANGKA', 'PLASTIK', 'KERTAS', 'TULISAN'],
        correctOptionIndex: 0, // PANJANG / JARAK
        difficulty: 2,
        explanation: 'Jam berfungsi mengukur besaran WAKTU, sedangkan Penggaris berfungsi mengukur besaran PANJANG/JARAK.',
      ),
      const IqQuestion(
        id: 'ra_7',
        category: IqCategory.relationalAnalogy,
        questionText: 'Tentukan padanan relasi penglihatan dan alat bantunya:\n'
            'MATA : KACAMATA = TELINGA : ...',
        options: ['SUARA', 'ALAT BANTU DENGAR', 'MUSIK', 'KEPALA', 'BICARA'],
        correctOptionIndex: 1, // ALAT BANTU DENGAR
        difficulty: 2,
        explanation: 'Kacamata adalah alat bantu eksternal untuk organ Mata, sebagaimana Alat Bantu Dengar adalah alat bantu eksternal untuk organ Telinga.',
      ),
      const IqQuestion(
        id: 'ra_8',
        category: IqCategory.relationalAnalogy,
        questionText: 'Pilihlah pasangan analogi pencegahan dan fungsinya:\n'
            'HELM : KEPALA = SABUK PENGAMAN : ...',
        options: ['MOBIL', 'TUBUH', 'JALAN RAYA', 'KURSI', 'KECELAKAAN'],
        correctOptionIndex: 1, // TUBUH
        difficulty: 2,
        explanation: 'Helm mengamankan bagian Kepala pengendara, sebagaimana Sabuk Pengaman mengamankan bagian Tubuh penumpang.',
      ),
      const IqQuestion(
        id: 'ra_9',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah pasangan fungsi penahan dan penstabil:\n'
            'KAPAL : JANGKAR = MOBIL : ...',
        options: ['RODA', 'REM TANGAN', 'KEMUDI', 'BENSIN', 'GARASI'],
        correctOptionIndex: 1, // REM TANGAN
        difficulty: 2,
        explanation: 'Jangkar berfungsi menahan dan menghentikan pergerakan Kapal saat diam, sebagaimana Rem Tangan menahan dan menghentikan pergerakan Mobil saat parkir.',
      ),
      const IqQuestion(
        id: 'ra_10',
        category: IqCategory.relationalAnalogy,
        questionText: 'Tentukan padanan analogi sumber cahaya dan bayangan:\n'
            'MATAHARI : SIANG = BULAN : ...',
        options: ['BINTANG', 'MALAM', 'GELAP', 'LANGIT', 'AWAN'],
        correctOptionIndex: 1, // MALAM
        difficulty: 2,
        explanation: 'Matahari menyinari dan menandai waktu Siang, sebagaimana Bulan menyinari dan menandai waktu Malam.',
      ),
      const IqQuestion(
        id: 'ra_11',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah relasi alat penulisan dan medianya:\n'
            'KUAS : KANVAS = PENA : ...',
        options: ['TINTA', 'KERTAS', 'MEJA', 'TULISAN', 'MENGGAMBAR'],
        correctOptionIndex: 1, // KERTAS
        difficulty: 2,
        explanation: 'Kuas digunakan untuk menorehkan cat di atas media Kanvas, sebagaimana Pena digunakan untuk menorehkan tinta di atas media Kertas.',
      ),
      const IqQuestion(
        id: 'ra_12',
        category: IqCategory.relationalAnalogy,
        questionText: 'Pilihlah padanan analogi struktur penyusun dan wujud utuhnya:\n'
            'BATA : DINDING = BENANG : ...',
        options: ['JARUM', 'KAIN', 'JAHIT', 'KANCING', 'KAPAS'],
        correctOptionIndex: 1, // KAIN
        difficulty: 3,
        explanation: 'Bata adalah unit dasar yang disusun membentuk Dinding, sebagaimana Benang adalah unit dasar yang dirajut/ditenun membentuk Lembaran Kain.',
      ),
      const IqQuestion(
        id: 'ra_13',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah hubungan sebab-akibat kondisi lingkungan berikut:\n'
            'KEMARAU : KEKERINGAN = HUJAN LEBAT : ...',
        options: ['PETIR', 'BANJIR', 'ANGIN', 'MENDUNG', 'BASAH'],
        correctOptionIndex: 1, // BANJIR
        difficulty: 3,
        explanation: 'Kemarau yang berkepanjangan berakibat Kekeringan, sebagaimana Hujan Lebat yang berkepanjangan berakibat Banjir.',
      ),
      const IqQuestion(
        id: 'ra_14',
        category: IqCategory.relationalAnalogy,
        questionText: 'Tentukan padanan hubungan penuntun arah:\n'
            'MERCUSUAR : KAPAL = RAMBU LALU LINTAS : ...',
        options: ['JALAN', 'KENDARAAN / PENGEMUDI', 'POLISI', 'LAMPU', 'ASPAL'],
        correctOptionIndex: 1, // KENDARAAN / PENGEMUDI
        difficulty: 3,
        explanation: 'Mercusuar menjadi panduan navigasi bagi Kapal di laut, sebagaimana Rambu Lalu Lintas menjadi panduan navigasi bagi Kendaraan/Pengemudi di darat.',
      ),
      const IqQuestion(
        id: 'ra_15',
        category: IqCategory.relationalAnalogy,
        questionText: 'Lengkapilah analogi struktur pelindung terluar:\n'
            'POHON : KULIT KAYU = MANUSIA : ...',
        options: ['TULANG', 'KULIT', 'RAMBUT', 'PAKAIAN', 'DAGING'],
        correctOptionIndex: 1, // KULIT
        difficulty: 3,
        explanation: 'Kulit kayu adalah lapisan protektif terluar dari Pohon, sebagaimana Kulit adalah lapisan protektif terluar dari tubuh Manusia.',
      ),

      // =========================================================================
      // KATEGORI 5: DEDUKSI & PEMECAHAN MASALAH (Problem Solving & Logic) - 15 Soal
      // =========================================================================
      const IqQuestion(
        id: 'pd_1',
        category: IqCategory.problemDeduction,
        questionText: 'Perhatikan aturan timbangan neraca berikut:\n'
            '• Neraca 1: 2 Buah Apel seimbang dengan 1 Buah Mangga\n'
            '• Neraca 2: 3 Buah Mangga seimbang dengan 1 Buah Melon\n\n'
            'Berapa buah Apel yang dibutuhkan untuk mengimbangi berat 2 Buah Melon?',
        diagramType: DiagramType.scaleBalanceVisual,
        diagramData: {
          'scale1Left': '2 🍎 Apel',
          'scale1Right': '1 🥭 Mangga',
          'scale2Left': '3 🥭 Mangga',
          'scale2Right': '1 🍈 Melon',
        },
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
        difficulty: 1,
        explanation: 'Laju produktivitas paralel:\n'
            'Jika 5 mesin membuat 5 produk dalam 5 menit, berarti 1 mesin membutuhkan 5 menit untuk membuat 1 produk.\n'
            'Jika 100 mesin bekerja bersamaan, dalam 5 menit masing-masing mesin menyelesaikan 1 produk (total 100 produk). Waktunya tetap 5 menit.',
      ),
      const IqQuestion(
        id: 'pd_4',
        category: IqCategory.problemDeduction,
        questionText: 'Empat anak (Andi, Budi, Citra, Doni) memiliki tinggi badan berbeda:\n'
            '• Andi lebih tinggi dari Budi.\n'
            '• Citra lebih pendek dari Doni.\n'
            '• Doni lebih pendek dari Budi.\n\n'
            'Siapakah yang memiliki tinggi badan paling tinggi di antara mereka?',
        options: ['Andi', 'Budi', 'Citra', 'Doni', 'Andi dan Budi sama'],
        correctOptionIndex: 0, // Andi
        difficulty: 1,
        explanation: 'Urutan tinggi badan dari tertinggi ke terpendek:\n'
            '1. Andi > Budi\n'
            '2. Budi > Doni\n'
            '3. Doni > Citra\n'
            'Urutan lengkap: Andi > Budi > Doni > Citra. Yang paling tinggi adalah Andi.',
      ),
      const IqQuestion(
        id: 'pd_5',
        category: IqCategory.problemDeduction,
        questionText: 'Semua anggota kelompok A memakai topi merah. Sebagian anggota kelompok A memakai kacamata hitam.\n\n'
            'Kesimpulan yang PASTI BENAR adalah:',
        diagramType: DiagramType.vennLogicVisual,
        options: [
          'Sebagian orang yang bertopi merah memakai kacamata hitam.',
          'Semua orang yang berkacamata hitam adalah kelompok A.',
          'Tidak ada orang bertopi merah yang memakai kacamata.',
          'Semua anggota kelompok A memakai kacamata hitam.',
          'Orang yang tidak bertopi merah pasti berkacamata.'
        ],
        correctOptionIndex: 0,
        difficulty: 1,
        explanation: 'Karena semua anggota kelompok A bertopi merah, dan sebagian dari mereka berkacamata, maka sebagian orang bertopi merah pasti berkacamata hitam.',
      ),
      const IqQuestion(
        id: 'pd_6',
        category: IqCategory.problemDeduction,
        questionText: 'Perhatikan susunan neraca berikut:\n'
            '• Neraca 1: 1 Kotak seimbang dengan 2 Bola\n'
            '• Neraca 2: 1 Bola seimbang dengan 3 Segitiga\n\n'
            'Berapa Segitiga yang dibutuhkan untuk menyeimbangkan 2 Kotak?',
        diagramType: DiagramType.scaleBalanceVisual,
        diagramData: {
          'scale1Left': '1 ⬛ Kotak',
          'scale1Right': '2 ⚪ Bola',
          'scale2Left': '1 ⚪ Bola',
          'scale2Right': '3 🔺 Segitiga',
        },
        options: ['6 Segitiga', '8 Segitiga', '10 Segitiga', '12 Segitiga', '16 Segitiga'],
        correctOptionIndex: 3, // 12 Segitiga
        difficulty: 2,
        explanation: '• 1 Kotak = 2 Bola = 2 × 3 Segitiga = 6 Segitiga\n'
            '• Maka 2 Kotak = 2 × 6 = 12 Segitiga.',
      ),
      const IqQuestion(
        id: 'pd_7',
        category: IqCategory.problemDeduction,
        questionText: 'Dalam suatu perlombaan lari cepat 5 orang (Riko, Soni, Tio, Udin, Vina):\n'
            '• Riko finis lebih cepat daripada Soni.\n'
            '• Tio finis lebih cepat daripada Riko.\n'
            '• Vina finis paling lambat.\n'
            '• Udin finis di antara Tio dan Riko.\n\n'
            'Siapakah yang berhasil menjadi juara pertama (finis paling depan)?',
        options: ['Riko', 'Soni', 'Tio', 'Udin', 'Vina'],
        correctOptionIndex: 2, // Tio
        difficulty: 2,
        explanation: 'Urutan posisi finis:\n'
            'Tio > Udin > Riko > Soni > Vina.\n'
            'Juara pertama yang finis paling depan adalah Tio.',
      ),
      const IqQuestion(
        id: 'pd_8',
        category: IqCategory.problemDeduction,
        questionText: 'Jika semua burung bernapas dengan paru-paru, dan burung elang adalah jenis burung, maka kesimpulan logis mutlaknya adalah:',
        options: [
          'Burung elang bernapas dengan paru-paru.',
          'Hanya burung elang yang bernapas dengan paru-paru.',
          'Semua hewan yang bernapas dengan paru-paru adalah elang.',
          'Sebagian elang tidak bernapas dengan paru-paru.',
          'Tidak dapat ditarik kesimpulan pasti.'
        ],
        correctOptionIndex: 0, // Burung elang bernapas dengan paru-paru.
        difficulty: 2,
        explanation: 'Silogisme Kategorial Baku:\n'
            'Semua A adalah B. C adalah bagian dari A. Maka C adalah B (Burung elang bernapas dengan paru-paru).',
      ),
      const IqQuestion(
        id: 'pd_9',
        category: IqCategory.problemDeduction,
        questionText: 'Di sebuah meja melingkar duduk 4 orang (A, B, C, D):\n'
            '• A duduk berhadapan langsung dengan C.\n'
            '• B duduk di sebelah kanan A.\n\n'
            'Siapakah yang duduk tepat di sebelah kiri C?',
        options: ['A', 'B', 'D', 'B dan D bersamaan', 'Tidak dapat ditentukan'],
        correctOptionIndex: 1, // B
        difficulty: 2,
        explanation: 'Pada meja melingkar 4 orang:\n'
            'A berhadapan dengan C. Sebelah kanan A adalah B. Maka B berada tepat di sebelah kiri C.',
      ),
      const IqQuestion(
        id: 'pd_10',
        category: IqCategory.problemDeduction,
        questionText: 'Ada 3 kotak tertutup (Kotak 1, 2, 3). Salah satu kotak berisi hadiah:\n'
            '• Kotak 1 bertuliskan: "Hadiah tidak ada di sini."\n'
            '• Kotak 2 bertuliskan: "Hadiah ada di Kotak 3."\n'
            '• Kotak 3 bertuliskan: "Tulisan di Kotak 2 adalah benar."\n'
            'Diketahui HANYA ADA 1 TULISAN YANG BENAR, dan hadiah pasti ada di salah satu kotak.\n\n'
            'Di kotak manakah hadiah berada?',
        options: ['Kotak 1', 'Kotak 2', 'Kotak 3', 'Kotak 1 atau 3', 'Tidak ada hadiah'],
        correctOptionIndex: 0, // Kotak 1
        difficulty: 2,
        explanation: '• Jika hadiah di Kotak 3, maka Kotak 1 Benar, Kotak 2 Benar, Kotak 3 Benar (ada 3 benar, bertentangan).\n'
            '• Jika hadiah di Kotak 2, maka Kotak 1 Benar, Kotak 2 Salah, Kotak 3 Salah (ada 1 benar, tapi jika Kotak 1 berisi hadiah maka Kotak 1 Salah, Kotak 2 Salah, Kotak 3 Salah).\n'
            '• Jika hadiah ada di Kotak 1: Kotak 1 SALAH ("tidak di sini"), Kotak 2 SALAH ("ada di 3"), Kotak 3 SALAH ("Kotak 2 benar").\n'
            'Analisis konsistensi: Hadiah berada di Kotak 1.',
      ),
      const IqQuestion(
        id: 'pd_11',
        category: IqCategory.problemDeduction,
        questionText: 'Sebuah lampu padam. Terdapat 3 saklar (A, B, C) di luar ruangan. Menekan saklar mana pun akan membalik status lampu (dari mati ke nyala, atau sebaliknya). Mula-mula lampu mati.\n\n'
            'Jika saklar A ditekan 3 kali, saklar B ditekan 2 kali, dan saklar C ditekan 1 kali, bagaimana status lampu pada akhirnya?',
        options: [
          'Lampu Padam (Mati)',
          'Lampu Menyala (Hidup)',
          'Lampu Berkedip',
          'Lampu Rusak',
          'Tidak dapat ditentukan'
        ],
        correctOptionIndex: 0, // Padam (Mati)
        difficulty: 2,
        explanation: 'Total penekanan saklar = 3 + 2 + 1 = 6 kali penekanan (Genap).\n'
            'Penekanan ganjil = Berubah status (Nyala)\n'
            'Penekanan genap = Kembali ke status awal (Mati/Padam).',
      ),
      const IqQuestion(
        id: 'pd_12',
        category: IqCategory.problemDeduction,
        questionText: 'Terdapat 5 kantong koin emas. 4 kantong berisi koin asli berbobot 10 gram/koin, dan 1 kantong berisi koin palsu berbobot 9 gram/koin.\n\n'
            'Dengan menggunakan timbangan jarum digital sekali timbang, berapa kantong koin yang bisa langsung dipastikan keasliannya?',
        options: [
          'Semua 5 kantong bisa dipastikan',
          'Hanya 1 kantong',
          'Hanya 2 kantong',
          'Hanya 3 kantong',
          'Tidak mungkin hanya 1 kali timbang'
        ],
        correctOptionIndex: 0, // Semua 5 kantong
        difficulty: 3,
        explanation: 'Metode penimbangan bertahap 1 kali (Puzzle Koin Klasik):\n'
            'Ambil 1 koin dari kantong 1, 2 dari kantong 2, 3 dari kantong 3, 4 dari kantong 4, 5 dari kantong 5 (total 15 koin).\n'
            'Jika semua asli = 150 gram. Selisih gram dari 150 gram langsung menunjukkan nomor kantong yang berisi koin palsu (misal kurang 3 gram = kantong 3).',
      ),
      const IqQuestion(
        id: 'pd_13',
        category: IqCategory.problemDeduction,
        questionText: 'Diketahui aturan relasi:\n'
            '1. Jika Ani pergi ke perpustakaan, Budi ikut pergi.\n'
            '2. Jika Budi pergi, Citra TIDAK ikut pergi.\n'
            '3. Hari ini Citra ikut pergi ke perpustakaan.\n\n'
            'Kesimpulan logis yang PASTI BENAR adalah:',
        options: [
          'Ani tidak pergi ke perpustakaan.',
          'Ani dan Budi pergi ke perpustakaan.',
          'Budi pergi ke perpustakaan.',
          'Semua orang pergi bersama-sama.',
          'Tidak dapat ditarik kesimpulan.'
        ],
        correctOptionIndex: 0, // Ani tidak pergi ke perpustakaan.
        difficulty: 3,
        explanation: 'Rantai deduksi Modus Tollens:\n'
            '• Citra pergi ➔ Budi TIDAK pergi (dari premis 2: Budi pergi → Citra tidak pergi, kontraposisi: Citra pergi → Budi tidak pergi)\n'
            '• Budi tidak pergi ➔ Ani TIDAK pergi (dari premis 1: Ani pergi → Budi pergi, kontraposisi: Budi tidak pergi → Ani tidak pergi).\n'
            'Kesimpulan pasti: Ani tidak pergi ke perpustakaan.',
      ),
      const IqQuestion(
        id: 'pd_14',
        category: IqCategory.problemDeduction,
        questionText: 'Sebuah tangki air dapat diisi penuh oleh Keran A dalam 2 jam, atau oleh Keran B dalam 3 jam. Jika kedua keran dibuka bersamaan pada tangki kosong, berapa jam waktu yang dibutuhkan untuk mengisi penuh tangki tersebut?',
        options: ['1,0 jam', '1,2 jam (72 menit)', '1,5 jam', '2,5 jam', '5,0 jam'],
        correctOptionIndex: 1, // 1,2 jam (72 menit)
        difficulty: 3,
        explanation: 'Laju gabungan per jam:\n'
            '• Keran A = 1/2 tangki/jam\n'
            '• Keran B = 1/3 tangki/jam\n'
            '• Gabungan = 1/2 + 1/3 = 5/6 tangki/jam\n'
            '• Waktu penuh = 1 / (5/6) = 6/5 jam = 1,2 jam (72 menit).',
      ),
      const IqQuestion(
        id: 'pd_15',
        category: IqCategory.problemDeduction,
        questionText: 'Di sebuah pulau hanya ada dua jenis penduduk: Ksatria (selalu jujur) dan Penipu (selalu berbohong). Anda bertemu dua orang, X dan Y.\n\n'
            'X berkata: "Setidaknya salah satu dari kami adalah Penipu."\n\n'
            'Apakah identitas X dan Y yang sebenarnya?',
        options: [
          'X adalah Ksatria, dan Y adalah Penipu.',
          'Keduanya adalah Penipu.',
          'Keduanya adalah Ksatria.',
          'X adalah Penipu, dan Y adalah Ksatria.',
          'Identitas mereka mustahil ditentukan.'
        ],
        correctOptionIndex: 0, // X Ksatria, Y Penipu
        difficulty: 3,
        explanation: 'Analisis logika kebenaran:\n'
            '• Jika X adalah Penipu, pernyataannya ("Setidaknya satu dari kami penipu") bernilai BENAR, yang merupakan kontradiksi bagi seorang penipu.\n'
            '• Maka X PASTI seorang Ksatria (jujur).\n'
            '• Karena X Ksatria (jujur), maka pernyataannya benar bahwa salah satu dari mereka adalah Penipu. Karena X bukan penipu, maka Y yang merupakan Penipu.\n'
            'Kesimpulan: X adalah Ksatria dan Y adalah Penipu.',
      ),
    ];
  }
}
