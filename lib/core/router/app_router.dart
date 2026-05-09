import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/presentation/screens/edit_logged_user_screen.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/church/presentation/screens/church_profile_screen.dart';
import 'package:client/features/church/presentation/screens/church_info_profile_screen.dart';
import 'package:client/features/church/presentation/screens/church_search_screen.dart';
import 'package:client/features/church/presentation/screens/register_church_screen.dart';
import 'package:client/features/church/presentation/screens/church_tab_screen.dart';
import 'package:client/features/church/presentation/screens/admin_church_general_info_screen.dart';
import 'package:client/features/church/presentation/screens/edit_church_unit_identity_screen.dart';
import 'package:client/features/church/presentation/screens/edit_church_unit_address_screen.dart';
import 'package:client/features/church/presentation/screens/edit_church_unit_images_screen.dart';
import 'package:client/features/church/presentation/screens/edit_church_unit_links_screen.dart';
import 'package:client/features/church/presentation/screens/admin_panel_screen.dart';
import 'package:client/features/department/presentation/screens/department_category_list_screen.dart';
import 'package:client/features/department/presentation/screens/my_departments_menu_screen.dart';
import 'package:client/features/department/presentation/screens/department_participants_selection_screen.dart';
import 'package:client/features/department/presentation/screens/department_screen.dart';
import 'package:client/features/department/presentation/screens/departments_list_screen.dart';
import 'package:client/features/department/presentation/screens/register_department_screen.dart';
import 'package:client/features/home/presentation/screens/calendar_screen.dart';
import 'package:client/features/calendar/sub_features/unit_agenda/presentation/screens/unit_agenda_screen.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/screens/create_event_screen.dart';
import 'package:client/features/membership/presentation/screens/edit_inactive_person_screen.dart';
import 'package:client/features/membership/presentation/screens/admin_membership_requests_screen.dart';
import 'package:client/features/membership/presentation/screens/member_options_screen.dart';
import 'package:client/features/membership/presentation/screens/member_profile_screen.dart';
import 'package:client/features/membership/presentation/screens/members_list_screen.dart';
import 'package:client/features/membership/presentation/screens/register_member_screen.dart';
import 'package:client/features/home/presentation/screens/home_screen.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/menu/presentation/screens/menu_screen.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _authRoutes = <String>{AppRoutes.login, AppRoutes.register};

final _systemRoutes = <String>{AppRoutes.splash};

final _protectedRoutes = <String>{
  AppRoutes.homeCalendar,
  AppRoutes.homeChurch,
  AppRoutes.homeChurchDepartmentsCategory,
  AppRoutes.homeChurchDepartmentDetail,
  AppRoutes.homeMenu,
  AppRoutes.homeMenuMyDepartments,
  AppRoutes.homeMenuEditProfile,
  AppRoutes.registerChurch,
  AppRoutes.churchSearch,
  AppRoutes.churchProfile,
  AppRoutes.churchPublicProfile,
  AppRoutes.adminPanel,
  AppRoutes.adminMembers,
  AppRoutes.adminMembershipRequests,
  AppRoutes.adminMembersRegister,
  AppRoutes.adminDepartments,
  AppRoutes.adminDepartmentsRegister,
  AppRoutes.adminGeneralInfo,
  AppRoutes.adminGeneralInfoIdentityEdit,
  AppRoutes.adminGeneralInfoAddressEdit,
  AppRoutes.adminGeneralInfoLinks,
  AppRoutes.adminGeneralInfoImages,
  AppRoutes.adminCalendar,
  AppRoutes.adminCalendarCreate,
  AppRoutes.peopleList,
  AppRoutes.peopleDetail,
  AppRoutes.peopleEdit,
  AppRoutes.departmentDetail,
  AppRoutes.departmentParticipantsAdd,
};

final _membershipRequiredRoutes = <String>{};

final _memberRoutes = <String>{AppRoutes.adminPanel};

final _unitAdminRoutes = <String>{
  AppRoutes.adminPanel,
  AppRoutes.adminMembers,
  AppRoutes.adminMembershipRequests,
  AppRoutes.adminMembersRegister,
  AppRoutes.adminDepartments,
  AppRoutes.adminDepartmentsRegister,
  AppRoutes.adminGeneralInfo,
  AppRoutes.adminGeneralInfoIdentityEdit,
  AppRoutes.adminGeneralInfoAddressEdit,
  AppRoutes.adminGeneralInfoLinks,
  AppRoutes.adminGeneralInfoImages,
  AppRoutes.adminCalendar,
  AppRoutes.adminCalendarCreate,
  AppRoutes.peopleList,
  AppRoutes.peopleDetail,
  AppRoutes.peopleEdit,
};

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellCalendarNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-calendar',
);
final _shellChurchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-church',
);
final _shellMenuNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-menu',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();

  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentPath = state.matchedLocation;
      final routePath = state.fullPath ?? currentPath;

      if (authState.isLoading) {
        final isAuthRoute = _isAuthRoute(routePath);
        return isAuthRoute ? null : AppRoutes.splash;
      }

      final isLoggedIn = authState.value != null;
      final isAuthRoute = _isAuthRoute(routePath);
      final isSystemRoute = _isSystemRoute(routePath);
      final isProtectedRoute = _isProtectedRoute(routePath);

      if (!isLoggedIn && currentPath == AppRoutes.splash) {
        return AppRoutes.login;
      }

      if (!isLoggedIn && isProtectedRoute) return AppRoutes.login;

      if (isLoggedIn && (isAuthRoute || isSystemRoute)) {
        return AppRoutes.homeChurch;
      }

      if (isLoggedIn) {
        final permissionsAsync = ref.read(sessionPermissionsProvider);
        final permissions = permissionsAsync.asData?.value;

        if (permissions != null) {
          if (_membershipRequiredRoutes.contains(routePath) &&
              !permissions.hasMembership) {
            return AppRoutes.homeChurch;
          }

          if (_memberRoutes.contains(routePath) && !permissions.isMember) {
            return AppRoutes.homeChurch;
          }

          if (_unitAdminRoutes.contains(routePath) &&
              !permissions.isUnitAdmin) {
            return AppRoutes.homeChurch;
          }

          final isDepartmentDetailRoute =
              routePath == AppRoutes.homeChurchDepartmentDetail ||
              routePath == AppRoutes.departmentDetail ||
              routePath == AppRoutes.departmentParticipantsAdd;
          if (isDepartmentDetailRoute) {
            final departmentId = state.pathParameters['id'];
            if (departmentId != null &&
                !permissions.canObserveDept(departmentId)) {
              return AppRoutes.homeChurch;
            }
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellChurchNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeChurch,
                name: AppRoutes.homeChurchName,
                builder: (context, state) => const ChurchTabScreen(),
                routes: [
                  GoRoute(
                    path: 'departamentos/categoria/:category',
                    name: AppRoutes.homeChurchDepartmentsCategoryName,
                    builder: (context, state) {
                      final category = state.pathParameters['category']!;
                      return DepartmentCategoryListScreen(category: category);
                    },
                  ),
                  GoRoute(
                    path: 'departamentos/:id',
                    name: AppRoutes.homeChurchDepartmentDetailName,
                    builder: (context, state) {
                      final departmentId = state.pathParameters['id']!;
                      return DepartmentScreen(
                        departmentId: departmentId,
                        showBackButton: true,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellCalendarNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeCalendar,
                name: AppRoutes.homeCalendarName,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellMenuNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeMenu,
                name: AppRoutes.homeMenuName,
                builder: (context, state) => const MenuScreen(),
                routes: [
                  GoRoute(
                    path: 'meus-departamentos',
                    name: AppRoutes.homeMenuMyDepartmentsName,
                    builder: (context, state) =>
                        const MyDepartmentsMenuScreen(),
                  ),
                  GoRoute(
                    path: 'editar-informacoes',
                    name: AppRoutes.homeMenuEditProfileName,
                    builder: (context, state) => const EditLoggedUserScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.registerChurch,
        name: AppRoutes.registerChurchName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterChurchScreen(),
      ),
      GoRoute(
        path: AppRoutes.churchSearch,
        name: AppRoutes.churchSearchName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChurchSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.churchProfile,
        name: AppRoutes.churchProfileName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final unitId = state.pathParameters['id']!;
          return ChurchProfileScreen(unitId: unitId);
        },
      ),
      GoRoute(
        path: AppRoutes.churchPublicProfile,
        name: AppRoutes.churchPublicProfileName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final unitId = state.pathParameters['id']!;
          return ChurchInfoProfileScreen(unitId: unitId);
        },
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        name: AppRoutes.adminPanelName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMembers,
        name: AppRoutes.adminMembersName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MemberOptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMembershipRequests,
        name: AppRoutes.adminMembershipRequestsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminMembershipRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMembersRegister,
        name: AppRoutes.adminMembersRegisterName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterMemberScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDepartments,
        name: AppRoutes.adminDepartmentsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DepartmentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDepartmentsRegister,
        name: AppRoutes.adminDepartmentsRegisterName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterDepartmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGeneralInfo,
        name: AppRoutes.adminGeneralInfoName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminChurchGeneralInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGeneralInfoIdentityEdit,
        name: AppRoutes.adminGeneralInfoIdentityEditName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditChurchUnitIdentityScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGeneralInfoAddressEdit,
        name: AppRoutes.adminGeneralInfoAddressEditName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditChurchUnitAddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGeneralInfoLinks,
        name: AppRoutes.adminGeneralInfoLinksName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditChurchUnitLinksScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGeneralInfoImages,
        name: AppRoutes.adminGeneralInfoImagesName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditChurchUnitImagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCalendar,
        name: AppRoutes.adminCalendarName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UnitAgendaScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCalendarCreate,
        name: AppRoutes.adminCalendarCreateName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: AppRoutes.departmentDetail,
        name: AppRoutes.departmentDetailName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final departmentId = state.pathParameters['id']!;
          return DepartmentScreen(
            departmentId: departmentId,
            showBackButton: true,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.departmentParticipantsAdd,
        name: AppRoutes.departmentParticipantsAddName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final departmentId = state.pathParameters['id']!;
          return DepartmentParticipantsSelectionScreen(
            departmentId: departmentId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.peopleList,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MembersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.peopleDetail,
        name: AppRoutes.peopleDetailName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final personId = state.pathParameters['id']!;
          final initialMember = state.extra is UnitMemberEntity
              ? state.extra as UnitMemberEntity
              : null;
          return MemberProfileScreen(
            personId: personId,
            initialMember: initialMember,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.peopleEdit,
        name: AppRoutes.peopleEditName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final personId = state.pathParameters['id']!;
          final initialProfile = state.extra is MemberProfileEntity
              ? state.extra as MemberProfileEntity
              : null;
          return EditInactivePersonScreen(
            personId: personId,
            initialProfile: initialProfile,
          );
        },
      ),
    ],
  );
});

bool _isAuthRoute(String location) => _authRoutes.contains(location);

bool _isSystemRoute(String location) => _systemRoutes.contains(location);

bool _isProtectedRoute(String location) => _protectedRoutes.contains(location);

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, next) => notifyListeners());
    ref.listen(sessionPermissionsProvider, (_, next) => notifyListeners());
  }
}
