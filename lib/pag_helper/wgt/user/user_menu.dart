import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/pagrid_helper/user_helper/comm_sso.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../model/acl/mdl_pag_role.dart';
import '../../model/mdl_pag_app_config.dart';
import 'wgt_role_selector.dart';

class UserMenu extends StatefulWidget {
  const UserMenu({
    super.key,
    required this.appConfig,
    required this.onRoleSelected,
  });

  final MdlPagAppConfig appConfig;
  final Function(MdlPagRole) onRoleSelected;

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  late MdlPagUser? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeNotifier = Provider.of<ThemeProvider>(context);

    bool isLoggedIn = true;
    MdlPagUser? user = Provider.of<PagUserProvider>(context).currentUser;
    if (user == null) {
      isLoggedIn = false;
    }

    bool checkProfile = true;
    if (isLoggedIn) {
      // // if (user!.isAdminAndUp()) {
      // if (user!.useOpsDashboard()) {
      //   checkProfile = true;
      // } else {
      //   checkProfile = user.checkPermission2(
      //       AclScope.self, AclTarget.evs2user_p_profile, AclOperation.read);
      // }
      // if (user.hasRole2(AclRole.EVS2_Basic_Meter_Consumer)) {
      //   checkProfile = false;
      // }
    }

    String username = isLoggedIn ? user!.username ?? '' : '';

    return Row(
      children: [
        Text(
          username,
          style: TextStyle(fontSize: 18, color: Theme.of(context).hintColor),
        ),
        getUserMenu(checkProfile, isLoggedIn, themeNotifier),
      ],
    );
  }

  Widget getUserMenu(
    bool checkProfile,
    bool isLoggedIn,
    ThemeProvider themeNotifier,
  ) {
    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.onSurface,
      icon: const Icon(Icons.person),
      onSelected: (item) => onSelected(context, item, themeNotifier),
      itemBuilder: (context) => [
        // const PopupMenuItem<String>(
        //   value: 'dashboard',
        //   child: Text('Dashboard'),
        // ),
        PopupMenuItem<String>(
          value: 'roleSelector',
          child: Row(
            children: [
              Icon(
                Symbols.group,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: 8),
              WgtRoleSelector(
                appConfig: widget.appConfig,
                loggedInUser: _loggedInUser!,
                // roleList: _loggedInUser!.getRoleList(widget.appConfig.portalType.label),
                onRoleSelected: (role) {
                  widget.onRoleSelected?.call(role);
                },
              ),
            ],
          ),
        ),
        if (isLoggedIn) const PopupMenuDivider(),
        if (checkProfile)
          const PopupMenuItem<String>(
            value: 'myProfile',
            child: Text('My Profile'),
          ),
        // PopupMenuItem<String>(
        //   value: 'settings',
        //   child: Text('Settings'),
        // ),
        PopupMenuItem<String>(
          value: 'theme',
          child: Row(
            children: [
              themeNotifier.isDark
                  ? Icon(
                      Icons.wb_sunny,
                      color: Theme.of(context).primaryColorLight,
                    )
                  : Icon(
                      Icons.nightlight_round,
                      color: Theme.of(context).primaryColorDark,
                    ),
              const SizedBox(width: 8),
              Text(themeNotifier.isDark ? "Light Mode" : "Dark Mode"),
            ],
          ),
        ),
        if (isLoggedIn) const PopupMenuDivider(),
        if (isLoggedIn)
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                const Text('Sign Out'),
              ],
            ),
          ),
      ],
    );
  }
}

void onSelected(
  BuildContext context,
  String item,
  ThemeProvider themeNotifier,
) {
  // ThemeModel themeNotifier = Provider.of<ThemeModel>(context);
  switch (item) {
    case 'myProfile':
      context.push(getRoute(PagPageRoute.myProfile));
      return;
    case 'dashboard':
      MdlPagUser? user =
          Provider.of<PagUserProvider>(context, listen: false).currentUser;
      if (user == null) {
        context.go('/project_public_front');
        return;
      }
      context.go('/console_home_dashboard');
      break;
    case 'theme':
      themeNotifier.isDark = !themeNotifier.isDark;
      break;
    case 'logout':
      storage.deleteAll();
      MdlPagUser? user =
          Provider.of<PagUserProvider>(context, listen: false).currentUser;
      if (user != null) {
        user.logout();
      }
      logoutSso(context);

      context.go('/project_public_front');
      break;
  }
}
