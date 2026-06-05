class Achievement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String requirement;

  const Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requirement,
  });
}

const List<Achievement> achievementsList = [
  Achievement(
    id: 'eco_beginner',
    name: 'Eco Beginner',
    emoji: '🥉',
    description: 'Melakukan transaksi pertama di ReUsea',
    requirement: 'Transaksi 1x',
  ),
  Achievement(
    id: 'eco_contributor',
    name: 'Eco Contributor',
    emoji: '🥈',
    description: 'Berpartisipasi aktif dalam 5 transaksi selesai',
    requirement: 'Transaksi 5x',
  ),
  Achievement(
    id: 'eco_champion',
    name: 'Eco Champion',
    emoji: '🥇',
    description: 'Menjadi teladan dengan 20 transaksi selesai',
    requirement: 'Transaksi 20x',
  ),
  Achievement(
    id: 'sustainability_hero',
    name: 'Sustainability Hero',
    emoji: '🌱',
    description: 'Mengurangi limbah sebanyak minimal 20 kg',
    requirement: '20 kg limbah berkurang',
  ),
  Achievement(
    id: 'campus_seller',
    name: 'Campus Seller',
    emoji: '📦',
    description: 'Berhasil menjual 10 barang kepada sesama mahasiswa',
    requirement: 'Menjual 10 barang',
  ),
];
