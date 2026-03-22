import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/storage_service.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final StorageService _storageService;

  ThemeCubit(this._storageService) : super(const ThemeInitial()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stored = await _storageService.getThemeMode();
    emit(ThemeLoaded(_parseThemeMode(stored)));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storageService.setThemeMode(mode.name);
    emit(ThemeLoaded(mode));
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}
