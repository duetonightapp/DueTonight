import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:due_tonight/data/repositories/room_repository.dart';

// Create a minimal fake class for SupabaseClient so we can instantiate RoomRepository
class FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('RoomRepository - getStoragePathFromUrl', () {
    late RoomRepository repository;

    setUp(() {
      repository = RoomRepository(client: FakeSupabaseClient());
    });

    test('correctly parses Supabase signed URL', () {
      const url = 'https://tdotndrapfawgljyzrkn.supabase.co/storage/v1/object/sign/room-files/rooms/a565f678-fbe5-443e-9a68-cd6b713fc6d6/assignments/1781339248771_CPPPrograms.pdf?token=abc';
      final path = repository.getStoragePathFromUrl(url);
      expect(path, 'rooms/a565f678-fbe5-443e-9a68-cd6b713fc6d6/assignments/1781339248771_CPPPrograms.pdf');
    });

    test('correctly parses Supabase public URL', () {
      const url = 'https://tdotndrapfawgljyzrkn.supabase.co/storage/v1/object/public/room-files/rooms/123/assignments/test.jpg';
      final path = repository.getStoragePathFromUrl(url);
      expect(path, 'rooms/123/assignments/test.jpg');
    });

    test('returns null for Cloudinary URL', () {
      const url = 'https://res.cloudinary.com/dbzl3odk6/image/upload/v1780730411/duetonight/rooms/a565f678-fbe5-443e-9a68-cd6b713fc6d6/assignments/rsy06wo2u1tseqetgzpd.jpg';
      final path = repository.getStoragePathFromUrl(url);
      expect(path, isNull);
    });

    test('returns null for invalid/empty URL', () {
      expect(repository.getStoragePathFromUrl(''), isNull);
      expect(repository.getStoragePathFromUrl('not_a_url'), isNull);
    });
  });
}
