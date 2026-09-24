import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/manage_user_groups/group/view.dart';
import 'package:smartmachine365/web_app_template/manage_user_groups/user/view.dart';
import 'package:smartmachine365/web_app_template/manage_user_groups/access_permission_matrix_widget.dart';

class ManageUserGroupsWidget extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userUid;
  final String userEmail;
  const ManageUserGroupsWidget({super.key, required this.userUid, required this.userRole, required this.userName, required this.userEmail});

  @override
  State<ManageUserGroupsWidget> createState() => _ManageUserGroupsWidgetState();
}

class _ManageUserGroupsWidgetState extends State<ManageUserGroupsWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Align(
                  alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: Image.asset('assets/images/backgroundanimated.gif').image,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
                      child: widget.userRole == "Super Admin"
                      ? Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: "Users"),
                              Tab(text: "Groups"),
                              Tab(text: "Action Permissions"),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                UserView(userUid: widget.userUid, userName: widget.userName, userEmail: widget.userEmail, userRole: widget.userRole),
                                GroupView(userName: widget.userName, userRole: widget.userRole),
                                const AccessPermissionMatrixWidget(),
                              ],
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: UserView(userUid: widget.userUid, userName: widget.userName, userEmail: widget.userEmail, userRole: widget.userRole)),
                        ],
                      )
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
