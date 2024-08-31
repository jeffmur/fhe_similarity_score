import 'package:test/test.dart';
import 'package:fhe_similarity_score/cramer.dart';
import 'test_utils.dart';

void main() {
  List<Map<String, dynamic>> tests = [
    {
      'x': [0.1, 0.2, 0.7],
      'y': [0.1, 0.2, 0.7],
      'distance': 0.0
    },
    {
      'x': [0.1, 0.2, 0.7],
      'y': [0.2, 0.3, 0.5],
      'distance': 0.24494897427831777
    },
  ];

  group("Plaintext", () {
    for (var config in tests) {
      var {'x': x, 'y': y} = config;
      test("List<Double> where x:$x y:$y", () {
        near(distance(x, y), config['distance'], eps: 1e-7);
      });
    }
    test('Throw on different length', () {
      expect(() => distance([1, 2, 3], [1]), throwsArgumentError);
      expect(() => distance([1], [1, 2, 3]), throwsArgumentError);
    });
  });

  Seal seal = Seal('ckks');
  seal.genContext({
    'polyModDegree': 8192,
    'encodeScalar': pow(2, 40),
    'qSizes': [60, 40, 40, 60]
  });
  seal.genKeys();

  group("SEAL CKKS", () {
    for (var config in tests) {
      var {'x': x, 'y': y} = config;
      var encryptX = encryptVecDouble(seal, x);
      test("Distance where x:$x y:$y", () {
        double decrypted = decryptAndSum(seal,
            distanceOfCiphertextVecDouble(seal, encryptX, y));
        near(decrypted > 0 ? sqrt(decrypted) : decrypted, // sqrt(0) = NaN
          config['distance'], eps: 1e-7);
      });
    }
  });
}