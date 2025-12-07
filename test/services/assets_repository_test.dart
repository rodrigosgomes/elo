import 'dart:async';
import 'package:elo/services/assets_repository.dart';
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
      // Arrange
      // 1. Mock select chain: from().select().eq().maybeSingle()
      // We return a Fake that handles the chain
      final fakeSelectBuilder =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      // Use thenAnswer because FakePostgrestFilterBuilder implements Future
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => fakeSelectBuilder);

      // 3. Mock upsert call
      // It calls: _client.from('user_checklists').upsert(...)
      final fakeUpsertBuilder =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      // Use thenAnswer because FakePostgrestFilterBuilder implements Future
      when(() => mockQueryBuilder.upsert(any(),
              onConflict: any(named: 'onConflict')))
          .thenAnswer((_) => fakeUpsertBuilder);

      // Act
      await repository.upsertChecklistAfterFirstAsset('test-user-id');

      // Assert
      // Verify upsert was called with onConflict: 'user_id'
      verify(() => mockQueryBuilder.upsert(
            any(),
            onConflict: 'user_id',
          )).called(1);
    });
  });
}
