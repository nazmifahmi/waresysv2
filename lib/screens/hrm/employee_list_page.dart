import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/employee_model.dart';
import '../../providers/hrm/employee_bloc.dart';
import '../../providers/theme_provider.dart';
import '../../services/hrm/employee_repository.dart';
import '../../constants/theme.dart';
import 'employee_form_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final EmployeeBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = EmployeeBloc(repository: EmployeeRepository());
  }

  void _openForm({EmployeeModel? employee}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeFormPage(existing: employee)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
            title: Text(
              'Daftar Karyawan',
              style: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                ),
                onPressed: () => _openForm(),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                    hintText: 'Cari nama karyawan...',
                    hintStyle: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textTertiary : AppTheme.textTertiaryLight,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
                    filled: true,
                    fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<EmployeeModel>>(
                  future: _bloc.getAll(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        ),
                      );
                    }
                    if (data.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada data karyawan.',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final e = data[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: themeProvider.isDarkMode 
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              e.fullName,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${e.position} • ${e.department} • ${e.status.name}',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                              ),
                            ),
                            onTap: () => _openForm(employee: e),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: themeProvider.isDarkMode ? AppTheme.accentRed : Colors.redAccent,
                              ),
                              onPressed: () async {
                                await _bloc.delete(e.employeeId);
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}