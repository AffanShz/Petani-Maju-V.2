class Pest {
  final int id;
  final String nama;
  final String jenis;
  final String deskripsi;
  final String gejala;
  final String pengendalian;
  final String pencegahan;
  final String? gambarUrl;

  Pest({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.deskripsi,
    required this.gejala,
    required this.pengendalian,
    required this.pencegahan,
    this.gambarUrl,
  });

  factory Pest.fromMap(Map<String, dynamic> map) {
    return Pest(
      id: map['id'] ?? 0,
      nama: map['nama'] ?? '',
      jenis: map['jenis'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      gejala: map['gejala'] ?? '',
      pengendalian: map['pengendalian'] ?? '',
      pencegahan: map['pencegahan'] ?? '',
      gambarUrl: map['gambar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'jenis': jenis,
      'deskripsi': deskripsi,
      'gejala': gejala,
      'pengendalian': pengendalian,
      'pencegahan': pencegahan,
      'gambar_url': gambarUrl,
    };
  }
}
