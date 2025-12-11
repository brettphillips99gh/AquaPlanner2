class FilterMedia {
  final String id;
  final String name;
  final String description;

  // Specific Surface Area (m²/m³)
  // This is the key metric for determining biological filtration capacity.
  final double specificSurfaceAreaM2perM3;

  const FilterMedia({
    required this.id,
    required this.name,
    required this.description,
    required this.specificSurfaceAreaM2perM3,
  });
}

// Pre-defined list of common filter media, acting as an encyclopedia.
final filterMediaEncyclopedia = {
  'sponge': const FilterMedia(
    id: 'sponge',
    name: 'Sponge',
    description: 'A common, reusable filter media with a good surface area for biological filtration.',
    specificSurfaceAreaM2perM3: 800.0,
  ),
  'ceramic_rings': const FilterMedia(
    id: 'ceramic_rings',
    name: 'Ceramic Rings',
    description: 'Porous ceramic rings that provide a very high surface area for beneficial bacteria.',
    specificSurfaceAreaM2perM3: 1200.0,
  ),
  'bio_balls': const FilterMedia(
    id: 'bio_balls',
    name: 'Bio Balls',
    description: 'Plastic balls with a complex structure designed for high flow and good gas exchange.',
    specificSurfaceAreaM2perM3: 350.0,
  ),
  'k1_micro': const FilterMedia(
    id: 'k1_micro',
    name: 'K1 Micro',
    description: 'A moving bed biofilm reactor (MBBR) media that is self-cleaning and highly efficient.',
    specificSurfaceAreaM2perM3: 900.0,
  ),
};
