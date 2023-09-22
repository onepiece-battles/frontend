import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:one_piece_battles_flutter/route/app_router.dart';
part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit()
      : super(const NavigationState(
            sideNavItems: AppRouter.characterPath, index: 0));

  void getNavBarItem(int index) {
    switch (index) {
      case 0:
        emit(const NavigationState(
            sideNavItems: AppRouter.characterPath, index: 0));
        break;
      case 1:
        emit(
            const NavigationState(sideNavItems: AppRouter.fruitPath, index: 1));
        break;
      case 2:
        emit(const NavigationState(
            sideNavItems: AppRouter.battlePath, index: 2));
        break;
      case 3:
        emit(const NavigationState(sideNavItems: AppRouter.userPath, index: 3));
        break;
      case 4:
        emit(const NavigationState(
            sideNavItems: AppRouter.settingPath, index: 4));
        break;
    }
  }
}
