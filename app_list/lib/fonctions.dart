import 'class.dart';
import 'package:flutter/services.dart' show rootBundle; //permets d'acceder aux csv
import 'package:csv/csv.dart'; //permet de convertir csv en list

Future<List<Recette>> chargerRecettes() async {
  try {
    final csvString = await rootBundle.loadString('assets/plats.csv');
    print('CSV chargé : ${csvString.length} caractères');
    print('Premières lignes : ${csvString.split('\n').take(3).join('\n')}');

    final csvRows = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(csvString);

    print('Nombre de lignes parsées : ${csvRows.length}');

    Map<String, List<Ingredient>> recettesMap = {};
    Map<String, String> imagesMap = {};

    for (var row in csvRows.skip(1)) {  // <-- retire le .skip(1), ton CSV n'a pas de header !
      if (row.length < 6) continue;

      final plat = row[0].toString().trim();
      final ingredient = row[1].toString().trim();
      final quantite = double.tryParse(row[2].toString()) ?? 0;
      final unite = row[3].toString().trim();
      final categorie = row[4].toString().trim();
      final image = row[5].toString().trim();

      if (!recettesMap.containsKey(plat)) {
        recettesMap[plat] = [];
        imagesMap[plat] = image.isNotEmpty ? image : 'assets/Images/default.jpg';
      }

      recettesMap[plat]!.add(Ingredient(
        nom: ingredient,
        quantite: quantite,
        unite: unite,
        categorie: categorie,
      ));
    }

    print('Recettes trouvées : ${recettesMap.keys.toList()}');

    return recettesMap.entries
        .map((e) => Recette(
        nom: e.key,
        ingredients: e.value,
        image: imagesMap[e.key] ?? 'assets/Images/default.jpg'))
        .toList();

  } catch (e) {
    print('ERREUR chargement CSV : $e');
    return [];
  }
}