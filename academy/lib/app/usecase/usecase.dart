import 'package:dartz/dartz.dart';

abstract class UseCase<Type, Params> {
  Future<Either<void, Type>> call(Params params);
}
abstract class UseCaseWithoutEither<Type, Params> {
  Future<Type> call(Params params);
}
class NoParams {}
