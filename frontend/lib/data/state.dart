part of 'cubit.dart';
class DataState extends Equatable {
 final Data? data;
 final String? message;
 const DataState({
    this.data,
    this.message,
  });
  @override
 List get props => [
 data,
 message,
      ];
}

class DataDefault extends DataState {}

class DataFetchLoading extends DataState {
 const DataFetchLoading() : super();
}

class DataFetchSuccess extends DataState {
 const DataFetchSuccess({super.data});
}

class DataFetchFailed extends DataState {
 const DataFetchFailed({super.message});
}

