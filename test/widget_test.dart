import 'package:flutter_test/flutter_test.dart';
import 'package:pooring_bele/services/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le contenu JSON se charge et est cohérent', () async {
    final content = await ContentRepository.load();

    expect(content.manifest.levels, isNotEmpty);
    for (final level in content.manifest.levels) {
      expect(level.categories, isNotEmpty);
      for (final cat in level.categories) {
        final items = content.itemsOf(cat.id);
        expect(items, isNotEmpty,
            reason: 'La catégorie ${cat.id} doit avoir des mots');
        final ids = items.map((i) => i.id).toSet();
        expect(ids.length, items.length,
            reason: 'Les ids de ${cat.id} doivent être uniques');
      }
    }
    expect(content.config.avatars, isNotEmpty);
    expect(content.config.questionsPerLesson, greaterThanOrEqualTo(4));
  });
}
