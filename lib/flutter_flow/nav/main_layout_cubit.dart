import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/flutter_flow/session_storage.dart';

class MainLayoutCubit extends Cubit<MainLayoutState> {
  MainLayoutCubit() : super(MainLayoutState(
    showSideNav: SessionStorage.getSetting<bool>('showSideNav') ?? true,
  ));

  void showSideNav(bool showSideNav) {
    SessionStorage.saveSetting('showSideNav', showSideNav);
    emit(state.copyWith(showSideNav: showSideNav));
  }

  void showButton(bool showButton) =>
      emit(state.copyWith(showButton: showButton));
}

class MainLayoutState extends Equatable {
  const MainLayoutState({this.showSideNav = true, this.showButton = false});

  final bool showSideNav;
  final bool showButton;

  @override
  List<Object?> get props => [showSideNav, showButton];

  MainLayoutState copyWith({bool? showSideNav, bool? showButton}) {
    return MainLayoutState(
      showSideNav: showSideNav ?? this.showSideNav,
      showButton: showButton ?? this.showButton,
    );
  }
}
