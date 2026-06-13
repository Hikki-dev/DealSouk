import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/stores/domain/store_price.dart';

final Map<String, List<StorePrice>> staticStorePricesByStoreId = {
  'carr-moe': [
    _price(
      'milk-almarai-1l',
      'Almarai Fresh Milk',
      'Almarai',
      '1 L',
      'Dairy & Sweet',
      7.95,
      true,
    ),
    _price('banana-dole-1kg', 'Bananas', 'Dole', '1 kg', 'Fruits', 5.75, false),
    _price(
      'rice-india-gate-5kg',
      'Basmati Rice',
      'India Gate',
      '5 kg',
      'Grocery',
      32.50,
      true,
    ),
  ],
  'lulu-albarsha': [
    _price(
      'eggs-local-30',
      'Large Eggs',
      'Local farm',
      '30 pcs',
      'Dairy & Sweet',
      21.95,
      true,
    ),
    _price(
      'apple-red-1kg',
      'Red Apples',
      'Fresh',
      '1 kg',
      'Fruits',
      8.25,
      false,
    ),
    _price(
      'oil-sunflower-1-8l',
      'Sunflower Oil',
      'Noor',
      '1.8 L',
      'Bakery',
      14.75,
      true,
    ),
  ],
  'spin-jlt': [
    _price(
      'bread-white-loaf',
      'White Bread',
      'Spinneys',
      '600 g',
      'Bakery',
      5.50,
      true,
    ),
    _price(
      'chicken-breast-1kg',
      'Chicken Breast',
      'Fresh',
      '1 kg',
      'Meat & Seafood',
      29.95,
      false,
    ),
  ],
  'wait-marina': [
    _price(
      'yogurt-greek-500g',
      'Greek Yogurt',
      'Waitrose',
      '500 g',
      'Dairy & Sweet',
      13.25,
      true,
    ),
    _price(
      'tomato-local-1kg',
      'Tomatoes',
      'Local',
      '1 kg',
      'Vegetable',
      6.95,
      false,
    ),
  ],
};

List<StorePrice> fallbackPricesForStore(String storeId) {
  final direct = staticStorePricesByStoreId[storeId];
  if (direct != null) return direct;

  if (storeId.startsWith('carr-')) {
    return staticStorePricesByStoreId['carr-moe']!;
  }
  if (storeId.startsWith('lulu-')) {
    return staticStorePricesByStoreId['lulu-albarsha']!;
  }
  if (storeId.startsWith('spin-')) {
    return staticStorePricesByStoreId['spin-jlt']!;
  }
  if (storeId.startsWith('wait-')) {
    return staticStorePricesByStoreId['wait-marina']!;
  }

  return const [];
}

StorePrice _price(
  String id,
  String name,
  String brand,
  String packSize,
  String category,
  double priceAed,
  bool verifiedWithPhoto,
) {
  return StorePrice(
    product: Product(
      id: id,
      name: name,
      brand: brand,
      packSize: packSize,
      category: category,
      lowestPrice: priceAed,
      lowestPriceStore: 'Nearby store',
      updatedAtLabel: 'Updated 2h ago',
    ),
    priceAed: priceAed,
    updatedAtLabel: 'Updated 2h ago',
    hoursAgo: 2,
    verifiedWithPhoto: verifiedWithPhoto,
  );
}
