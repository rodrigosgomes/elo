import '../../models/asset_model.dart';

bool requiresHighSecurityForAsset(AssetModel asset) {
  if (asset.category == AssetCategory.imoveis) {
    return true;
  }
  if (asset.valueUnknown) {
    return false;
  }
  final estimated = asset.valueEstimated ?? 0;
  return estimated > 200000;
}
