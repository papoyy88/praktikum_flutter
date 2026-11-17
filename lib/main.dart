import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef DataMhs = Map<String, String>;

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MahasiswaPage(),
));

class MahasiswaPage extends StatefulWidget {
  const MahasiswaPage({super.key});

  @override
  State<MahasiswaPage> createState() => _MahasiswaPageState();
}

class _MahasiswaPageState extends State<MahasiswaPage> {
  // TAHAP 1: Inisialisasi data sementara di RAM.
  final List<DataMhs> mahasiswa = [
    {'id': '1', 'nim': '2026001', 'nama': 'Andi', 'prodi': 'Informatika'},
    {'id': '2', 'nim': '2026002', 'nama': 'Siti', 'prodi': 'Informatika'},
  ];
  int nextId = 3;

  // State Pencarian & Pengurutan (Tantangan B & C)
  String kataKunci = '';
  bool urutkanAZ = false;

  // CREATE
  Future<void> tambahData() async {
    final hasil = await showDialog<DataMhs>(
      context: context,
      builder: (_) => MahasiswaForm(dataSudahAda: mahasiswa),
    );
    if (!mounted || hasil == null) return;
    setState(() {
      mahasiswa.add({'id': '${nextId++}', ...hasil});
    });
  }

  // UPDATE (Mencari berdasarkan ID unik sehingga aman walau terfilter / terurut A-Z)
  Future<void> ubahData(DataMhs target) async {
    final hasil = await showDialog<DataMhs>(
      context: context,
      builder: (_) => MahasiswaForm(
        dataAwal: target,
        dataSudahAda: mahasiswa,
      ),
    );
    if (!mounted || hasil == null) return;
    final indeksAsli = mahasiswa.indexWhere((m) => m['id'] == target['id']);
    if (indeksAsli == -1) return;
    setState(() {
      mahasiswa[indeksAsli] = {'id': target['id']!, ...hasil};
    });
  }

  // DELETE + TANTANGAN D: Fitur Undo dengan SnackBarAction
  Future<void> hapusData(DataMhs target) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Yakin ingin menghapus data ${target['nama']} (${target['nim']})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted || konfirmasi != true) return;

    // Simpan posisi indeks asli & salinan data sebelum dihapus untuk keperluan Undo
    final indeksAsli = mahasiswa.indexWhere((m) => m['id'] == target['id']);
    if (indeksAsli == -1) return;
    final dataTerhapus = DataMhs.from(mahasiswa[indeksAsli]);

    setState(() {
      mahasiswa.removeAt(indeksAsli);
    });

    // Tampilkan SnackBar dengan tombol Batalkan (Undo)
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data "${dataTerhapus['nama']}" dihapus'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'BATALKAN',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              final posisiKembalikan = indeksAsli <= mahasiswa.length
                  ? indeksAsli
                  : mahasiswa.length;
              mahasiswa.insert(posisiKembalikan, dataTerhapus);
            });
          },
        ),
      ),
    );
  }

  // Getter daftar tampilan: Filter Pencarian + Pengurutan A-Z tanpa merusak List asli
  List<DataMhs> get dataTampil {
    final q = kataKunci.trim().toLowerCase();
    final hasilFilter = q.isEmpty
        ? List<DataMhs>.from(mahasiswa)
        : mahasiswa.where((m) {
            return m['nim']!.toLowerCase().contains(q) ||
                m['nama']!.toLowerCase().contains(q) ||
                m['prodi']!.toLowerCase().contains(q);
          }).toList();

    // TANTANGAN C: Pengurutan nama A-Z pada salinan list tampilan
    if (urutkanAZ) {
      hasilFilter.sort(
        (a, b) => a['nama']!.toLowerCase().compareTo(b['nama']!.toLowerCase()),
      );
    }
    return hasilFilter;
  }

  @override
  Widget build(BuildContext context) {
    final daftar = dataTampil;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 7: Data Mahasiswa'),
        actions: [
          // Tombol Toggle Pengurutan A-Z (Tantangan C)
          IconButton(
            tooltip: urutkanAZ ? 'Matikan Urutan A-Z' : 'Urutkan Nama A-Z',
            icon: Icon(
              Icons.sort_by_alpha,
              color: urutkanAZ ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                urutkanAZ = !urutkanAZ;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kolom Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari NIM, Nama, atau Prodi',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => kataKunci = value),
            ),
          ),

          // TANTANGAN B: Menampilkan jumlah hasil pencarian terfilter & total data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  kataKunci.trim().isEmpty
                      ? 'Total data tersimpan: ${mahasiswa.length}'
                      : 'Hasil pencarian: ${daftar.length} dari ${mahasiswa.length} data',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (urutkanAZ)
                  const Text(
                    'Urutan: A–Z',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
              ],
            ),
          ),

          // Daftar Kartu Mahasiswa
          Expanded(
            child: daftar.isEmpty
                ? const Center(child: Text('Data tidak ditemukan'))
                : ListView.builder(
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final item = daftar[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(item['nama']!),
                          subtitle: Text('${item['prodi']} | ${item['nim']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Ubah',
                                onPressed: () => ubahData(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Hapus',
                                onPressed: () => hapusData(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: tambahData,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

// Form Input Mahasiswa
class MahasiswaForm extends StatefulWidget {
  final DataMhs? dataAwal;
  final List<DataMhs> dataSudahAda;

  const MahasiswaForm({super.key, this.dataAwal, required this.dataSudahAda});

  @override
  State<MahasiswaForm> createState() => _MahasiswaFormState();
}

class _MahasiswaFormState extends State<MahasiswaForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nim;
  late final TextEditingController nama;
  late final TextEditingController prodi;

  @override
  void initState() {
    super.initState();
    nim = TextEditingController(text: widget.dataAwal?['nim'] ?? '');
    nama = TextEditingController(text: widget.dataAwal?['nama'] ?? '');
    prodi = TextEditingController(text: widget.dataAwal?['prodi'] ?? '');
  }

  @override
  void dispose() {
    nim.dispose();
    nama.dispose();
    prodi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dataAwal == null ? 'Tambah Data' : 'Ubah Data'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TANTANGAN A: Validasi NIM hanya angka & minimal 6 digit
              TextFormField(
                controller: nim,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'NIM Mahasiswa',
                  hintText: 'Minimal 6 digit angka (cth: 240111006)',
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'NIM wajib diisi';
                  if (!RegExp(r'^\d+$').hasMatch(v)) {
                    return 'NIM hanya boleh berisi angka';
                  }
                  if (v.length < 6) {
                    return 'NIM minimal terdiri dari 6 digit';
                  }
                  final sudahAda = widget.dataSudahAda.any(
                    (m) => m['nim'] == v && m['id'] != widget.dataAwal?['id'],
                  );
                  if (sudahAda) return 'NIM sudah digunakan';
                  return null;
                },
              ),
              TextFormField(
                controller: nama,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Mahasiswa',
                  hintText: 'Masukkan nama lengkap',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: prodi,
                decoration: const InputDecoration(
                  labelText: 'Program Studi',
                  hintText: 'Contoh: Informatika',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Prodi wajib diisi' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'nim': nim.text.trim(),
              'nama': nama.text.trim(),
              'prodi': prodi.text.trim(),
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}