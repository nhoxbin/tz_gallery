import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tz_gallery/src/common/tz_enum.dart';
import 'package:tz_gallery/src/repositories/gallery_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  for (final (type, requestType) in [
    (TzType.photo, RequestType.image),
    (TzType.video, RequestType.video),
    (TzType.all, RequestType.common)
  ]) {
    test('$type album and all pages keep an explicit unfiltered creation order',
        () async {
      final pages = <int>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        if (call.method == 'getAssetPathList') {
          expect(args['type'], requestType.value);
          return {
            'data': [
              {'id': 'all', 'name': 'Recent', 'assetCount': 85, 'isAll': true}
            ]
          };
        }
        if (call.method == 'getAssetListPaged') {
          final option = (args['option'] as Map?)?['child'] as Map?;
          final order = option?['orderBy'] as List?;
          if (order == null || order.isEmpty) {
            throw PlatformException(
                code: 'getAssetListPaged',
                message: 'near LIMIT: ORDER BY LIMIT 40 OFFSET 0');
          }
          expect(option!['where'], '');
          expect(order, [
            {'column': CustomColumns.base.createDate, 'isAsc': false}
          ]);
          expect(option.containsKey('createDate'), isFalse);
          expect(option.containsKey('image'), isFalse);
          expect(option.containsKey('video'), isFalse);
          expect(args['type'], requestType.value);
          final page = args['page'] as int;
          pages.add(page);
          return {
            'data': List.generate(
                page == 2 ? 5 : 40,
                (index) => {
                      'id': '${page * 40 + index}',
                      'type': type == TzType.video ? 2 : 1,
                      'width': 0,
                      'height': 0,
                      'duration': 172800
                    })
          };
        }
        throw StateError('Unexpected photo-manager method: ${call.method}');
      });
      final repository = GalleryRepository();
      final album = (await repository.getAssetsPath(type)).single;
      final assets = [
        for (var page = 0; page < 3; page++)
          ...await repository.getAssets(album, page: page)
      ];
      expect(pages, [0, 1, 2]);
      expect(assets, hasLength(85));
      expect(assets.first.id, '0');
      expect(assets.last.id, '84');
    });
  }
}
