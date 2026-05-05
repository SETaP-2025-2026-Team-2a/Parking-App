import 'dart:async';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data.dart';
part 'data_provider.dart';
part 'repository.dart';
part 'state.dart';

class DataCubit extends Cubit<DataState> {
  static DataCubit cubit(BuildContext context, [bool listen = false]) =>
      BlocProvider.of(context, listen: listen);
  DataCubit() : super(DataDefault());
  final repo = DataRepository();
  Future fetch() async {
    emit(const DataFetchLoading());
    try {
      final data = await repo.fetch();
      emit(DataFetchSuccess(data: data));
    } catch (e) {
      emit(DataFetchFailed(message: e.toString()));
    }
  }
}
