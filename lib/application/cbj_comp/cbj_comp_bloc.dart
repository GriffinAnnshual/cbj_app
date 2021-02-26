import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cybear_jinni/domain/cbj_comp/cbj_comp_entity.dart';
import 'package:cybear_jinni/domain/cbj_comp/cbj_comp_failures.dart';
import 'package:cybear_jinni/domain/cbj_comp/i_cbj_comp_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/kt.dart';

part 'cbj_comp_bloc.freezed.dart';
part 'cbj_comp_event.dart';
part 'cbj_comp_state.dart';

@injectable
class CBJCompBloc extends Bloc<CBJCompEvent, CBJCompState> {
  CBJCompBloc(this._cBJCompRepository) : super(CBJCompState.initial());

  final ICBJCompRepository _cBJCompRepository;

  StreamSubscription<Either<CBJCompFailure, KtList<CBJCompEntity>>>
      _CBJCompStreamSubscription;

  @override
  Stream<CBJCompState> mapEventToState(
    CBJCompEvent event,
  ) async* {
    yield* event.map(
      initialized: (e) async* {},
      create: (e) async* {},
      watchAllStarted: (e) async* {
        yield const CBJCompState.loadInProgress();
        await _CBJCompStreamSubscription?.cancel();
        _CBJCompStreamSubscription = _cBJCompRepository.watchAll().listen(
            (failureOrCBJCompList) =>
                add(CBJCompEvent.compDevicesReceived(failureOrCBJCompList)));
      },
      compDevicesReceived: (e) async* {
        yield e.failureOrCBJCompList.fold(
          (f) => CBJCompState.loadFailure(f),
          (devices) => CBJCompState.loadSuccess(devices),
        );
      },
      changeAction: (e) async* {
        final actionResult = await _cBJCompRepository.update(e.cBJCompEntity);

        yield actionResult.fold((f) => CBJCompState.loadFailure(f),
            (r) => const CBJCompState.loadSuccessTemp());
      },
    );
  }

  @override
  Future<void> close() async {
    await _CBJCompStreamSubscription?.cancel();
    return super.close();
  }
}