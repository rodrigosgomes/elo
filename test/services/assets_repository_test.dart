import 'dart:async';
import 'package:elo/services/assets_repository.dart';
import 'package:elo/models/asset_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockUser extends Mock implements User {}

// Fake builder that acts as a Future so 'await' works
class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final T _result;
  FakePostgrestFilterBuilder(this._result);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) async {
    return onValue(_result);
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestFilterBuilder<T> filter(
      String column, String operator, Object? value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    final listResult = _result is List ? _result : [_result];
    return FakePostgrestTransformBuilder(listResult as dynamic);
  }

  @override
  PostgrestTransformBuilder<T> order(String column,
      {bool ascending = false,
      bool nullsFirst = false,
      String? referencedTable}) {
    return FakePostgrestTransformBuilder(_result as dynamic);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(null);
  }
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final T _result;
  FakePostgrestTransformBuilder(this._result);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) async {
    return onValue(_result);
  }

  @override
  PostgrestTransformBuilder<T> range(int from, int to,
      {String? referencedTable}) {
    return this;
  }

  @override
  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    final item = (_result is List && (_result as List).isNotEmpty)
        ? (_result as List).first
        : _result;
    return FakePostgrestTransformBuilder(item as dynamic);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late AssetsRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');

    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);

    repository = AssetsRepository(client: mockClient);
  });

  group('AssetsRepository', () {
    test('upsertChecklistAfterFirstAsset calls upsert with onConflict: user_id',
        () async {
      final fakeSelectBuilder =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => fakeSelectBuilder);

      final fakeUpsertBuilder =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      when(() => mockQueryBuilder.upsert(any(),
              onConflict: any(named: 'onConflict')))
          .thenAnswer((_) => fakeUpsertBuilder);

      await repository.upsertChecklistAfterFirstAsset('test-user-id');

      verify(() => mockQueryBuilder.upsert(
            any(),
            onConflict: 'user_id',
          )).called(1);
    });

    test('insertAsset inserts and returns an AssetModel', () async {
      final input = AssetInput(
        category: AssetCategory.financeiro,
        title: 'New Asset',
        valueEstimated: 1000,
      );

      final assetMap = {
        'id': 1,
        'user_id': 'test-user-id',
        'category': 'FINANCEIRO',
        'title': 'New Asset',
        'value_estimated': 1000.0,
        'value_currency': 'BRL',
        'value_unknown': false,
        'ownership_percentage': 100,
        'has_proof': false,
        'status': 'PENDING_REVIEW',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final fakeInsertBuilder =
          FakePostgrestFilterBuilder<Map<String, dynamic>>(assetMap);

      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) => fakeInsertBuilder);

      final result = await repository.insertAsset(input);

      expect(result, isA<AssetModel>());
      expect(result.id, 1);
      expect(result.title, 'New Asset');
      verify(() => mockQueryBuilder.insert(any())).called(1);
    });

    test('updateAsset updates and returns modified AssetModel', () async {
      final input = AssetInput(
        category: AssetCategory.financeiro,
        title: 'Updated Asset',
        valueEstimated: 2000,
      );

      final assetMap = {
        'id': 1,
        'user_id': 'test-user-id',
        'category': 'FINANCEIRO',
        'title': 'Updated Asset',
        'value_estimated': 2000.0,
        'value_currency': 'BRL',
        'value_unknown': false,
        'ownership_percentage': 100,
        'has_proof': false,
        'status': 'ACTIVE',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final fakeUpdateBuilder =
          FakePostgrestFilterBuilder<Map<String, dynamic>>(assetMap);

      when(() => mockQueryBuilder.update(any()))
          .thenAnswer((_) => fakeUpdateBuilder);

      final result = await repository.updateAsset(assetId: 1, input: input);

      expect(result.title, 'Updated Asset');
      expect(result.valueEstimated, 2000);
      verify(() => mockQueryBuilder.update(any())).called(1);
    });

    test('deleteAsset removes the asset', () async {
      final fakeDeleteBuilder =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);

      when(() => mockQueryBuilder.delete())
          .thenAnswer((_) => fakeDeleteBuilder);

      await repository.deleteAsset(1);

      verify(() => mockQueryBuilder.delete()).called(1);
    });

    test('fetchAssets returns list of AssetModel', () async {
      final assetsList = [
        {
          'id': 1,
          'user_id': 'test-user-id',
          'category': 'VEICULOS',
          'title': 'Car',
          'value_estimated': 50000.0,
          'value_currency': 'BRL',
          'value_unknown': false,
          'ownership_percentage': 100,
          'has_proof': true,
          'status': 'ACTIVE',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ];

      final fakeSelectBuilder =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(assetsList);

      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => fakeSelectBuilder);

      final filters = AssetFilters(categories: {AssetCategory.veiculos});

      final result = await repository.fetchAssets(filters: filters);

      expect(result, isA<List<AssetModel>>());
      expect(result.length, 1);
      expect(result.first.title, 'Car');
      verify(() => mockQueryBuilder.select(any())).called(1);
    });
  });
}
