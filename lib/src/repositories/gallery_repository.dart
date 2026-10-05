import 'package:photo_manager/photo_manager.dart';
import 'package:tz_gallery/src/common/tz_enum.dart';

abstract class IGalleryRepository {
  Future<List<AssetPathEntity>> getAssetsPath(TzType type);
  Future<List<AssetEntity>> getAssets(AssetPathEntity path,
      {int page = 0, int limit = 40});
}

class GalleryRepository implements IGalleryRepository {
  @override
  Future<List<AssetEntity>> getAssets(AssetPathEntity path,
      {int page = 0, int limit = 40}) async {
    try {
      final List<AssetEntity> entities =
          await path.getAssetListPaged(page: page, size: limit);
      return entities;
    } catch (exception) {
      throw Exception(exception);
    }
  }

  @override
  Future<List<AssetPathEntity>> getAssetsPath(TzType type) async {
    try {
      late RequestType requestType;
      switch (type) {
        case TzType.photo:
          requestType = RequestType.image;
          break;
        case TzType.video:
          requestType = RequestType.video;
          break;
        case TzType.all:
          requestType = RequestType.common;
      }
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: requestType,
        filterOption: CustomFilter.sql(
          where: '',
          orderBy: [OrderByItem.desc(CustomColumns.base.createDate)],
        ),
      );
      return paths;
    } catch (exception) {
      throw Exception(exception);
    }
  }
}
