import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:provider/provider.dart';

class WgtProjectLogo extends StatefulWidget {
  const WgtProjectLogo({
    super.key,
    this.width = 88,
    this.height = 36,
    this.bgColor,
    this.onTap,
  });
  final double width;
  final double height;
  final Color? bgColor;
  final Function()? onTap;

  @override
  State<WgtProjectLogo> createState() => _WgtProjectLogoState();
}

class _WgtProjectLogoState extends State<WgtProjectLogo> {
  late final MdlPagUser? _loggedInUser;

  double _opacity = 0.82;
  late final String logoPath;

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    assert(_loggedInUser!.selectedScope.projectProfile != null);
    MdlPagProjectProfile selectedProjectProfile =
        _loggedInUser!.selectedScope.projectProfile!;

    logoPath = '${selectedProjectProfile.assetFolder}/app_bar_logo.png';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) {
        if (widget.onTap == null) return;
        setState(() {
          _opacity = value ? 1 : 0.82;
        });
      },
      onTap: widget.onTap,
      child: Opacity(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: widget.bgColor ?? Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Image.asset(
            logoPath,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }
}
