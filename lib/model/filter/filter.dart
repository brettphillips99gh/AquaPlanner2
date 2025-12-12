enum FilterMediaType { sponge, ceramicRings, bioBalls, k1Micro }

class FilterMediaSlot {
  final FilterMediaType mediaType;
  final double portion; // Value from 0.0 to 1.0, representing percentage of total volume

  const FilterMediaSlot({
    required this.mediaType,
    this.portion = 1.0,
  });
}

class FilterProfile {
  final double filterFlowRateLph;
  final double filterMediaVolumeLiters;
  final List<FilterMediaSlot> mediaSlots;

  const FilterProfile({
    required this.filterFlowRateLph,
    required this.filterMediaVolumeLiters,
    this.mediaSlots = const [FilterMediaSlot(mediaType: FilterMediaType.sponge, portion: 1.0)],
  });
}
