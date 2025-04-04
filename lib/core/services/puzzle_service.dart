import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../constants/constants.dart';
import '../models/puzzle_model.dart';
import 'dart:convert';

class PuzzleService {
  static String getPuzzlesUrlApi = ApiConstants.getPulzzesUrl;
  static String getPuzzleUrlApi = ApiConstants.getPulzzeUrl;

  Future<Puzzles> getPuzzles(String idToken, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$getPuzzlesUrlApi?limit=$limit"),
        headers: {'Authorization': idToken},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final puzzles = Puzzles.fromJson(responseData);

        // ✅ Lưu cache sau khi fetch
        await _cachePuzzles(puzzles.puzzles);

        return puzzles;
      } else {
        throw Exception('Không thể lấy puzzles: ${response.statusCode}');
      }
    } catch (error) {
      print("Lỗi khi gọi API, thử lấy từ cache...");

      // ✅ Nếu lỗi, load từ cache
      final cached = await _getCachedPuzzles();
      if (cached.isNotEmpty) {
        return Puzzles(puzzles: cached);
      }

      throw Exception('Không thể lấy puzzle: $error');
    }
  }

  // 🧠 Cache puzzles
  Future<void> _cachePuzzles(List<Puzzle> puzzles) async {
    final box = await Hive.openBox<Puzzle>('puzzleBox');
    await box.clear(); // optional: xoá cũ
    for (var puzzle in puzzles) {
      await box.put(puzzle.puzzleId, puzzle);
    }
  }

  // 📦 Lấy puzzle từ cache nếu cần
  Future<List<Puzzle>> _getCachedPuzzles() async {
    final box = await Hive.openBox<Puzzle>('puzzleBox');
    return box.values.toList();
  }

  // 🔑 Lấy 1 puzzle từ cache, nếu không có thì gọi API và tạo lại cache
  Future<Puzzles> getPuzzleFromCacheOrApi(String idToken) async {
    try {
      // Kiểm tra xem Hive đã được khởi tạo chưa
      if (!Hive.isBoxOpen('puzzleBox')) {
        // Đảm bảo Hive đã được khởi tạo trước khi mở box
        try {
          await Hive.openBox<Puzzle>('puzzleBox');
        } catch (e) {
          print("Lỗi khi mở Hive box: $e");
          // Nếu không thể mở box, gọi API để lấy puzzles
          return await getPuzzles(idToken);
        }
      }

      final box = await Hive.openBox<Puzzle>('puzzleBox');

      if (box.isNotEmpty) {
        final cachedPuzzles = box.values.toList();
        return Puzzles(puzzles: cachedPuzzles);
      }

      // Nếu không có trong cache, gọi API để lấy puzzles
      print("Không tìm thấy trong cache, gọi API để lấy puzzle...");
      final puzzles = await getPuzzles(idToken);
      return puzzles;
    } catch (error) {
      print("Lỗi khi lấy puzzle từ cache hoặc API: $error");
      // Thử gọi API trực tiếp nếu có lỗi với cache
      try {
        return await getPuzzles(idToken);
      } catch (apiError) {
        throw Exception('Không thể lấy puzzle: $error. Lỗi API: $apiError');
      }
    }
  }

  Future<void> deletePuzzleFromCache(Puzzle puzzle) async {
    final String puzzleId = puzzle.puzzleId;
    try {
      final box = await Hive.openBox<Puzzle>('puzzleBox');
      await box.delete(puzzleId); // Xóa puzzle theo puzzleId

      print("Puzzle với ID: $puzzleId đã bị xóa khỏi cache.");
    } catch (error) {
      print("Lỗi khi xóa puzzle khỏi cache: $error");
      throw Exception('Không thể xóa puzzle khỏi cache: $error');
    }
  }

  Future<void> solvedPuzzle(String idToken, Puzzle puzzle) async {
    try {
      final solvedPuzzleUrlApi = "$getPuzzleUrlApi/${puzzle.puzzleId}/solved";

      final response = await http.post(
        Uri.parse(solvedPuzzleUrlApi),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print(response.statusCode);

      if (response.statusCode == 200) {
        final newRating = jsonDecode(response.body);
        print("Điểm Puzzle Rating mới của bạn sau khi giải: $newRating");
      } else {
        throw Exception(
            'Không thể đánh dấu puzzle đã giải: ${response.statusCode}');
      }

      // Xóa puzzle đã giải khỏi cache
      await deletePuzzleFromCache(puzzle);

      print("Đã đánh dấu puzzle ${puzzle.puzzleId} là đã giải thành công");
    } catch (error) {
      print("Lỗi khi đánh dấu puzzle đã giải: $error");
      throw Exception('Không thể đánh dấu puzzle đã giải: $error');
    }
  }
}
