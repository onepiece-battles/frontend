part of 'navigation_cubit.dart';

class NavigationState extends Equatable {

  final String sideNavItems;
  final int index;

  const NavigationState({required this.sideNavItems, required this.index});

  @override
  List<Object> get props => [sideNavItems, index];
}