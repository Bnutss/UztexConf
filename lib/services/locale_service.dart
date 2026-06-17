import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ValueNotifier<String> {
  static final instance = LocaleService._('ru');

  LocaleService._(super.value);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString('language') ?? 'ru';
  }

  Future<void> setLanguage(String lang) async {
    value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  String get lang => value;

  String tr(String key) =>
      _strings[value]?[key] ?? _strings['ru']![key] ?? key;

  static const _strings = {
    'ru': {
      // Auth
      'username': 'Логин',
      'password': 'Пароль',
      'sign_in': 'Войти',
      'invalid_credentials': 'Неверный логин или пароль',
      'no_connection': 'Нет соединения с сервером',
      'enter_credentials': 'Введите логин и пароль',
      'enter_username': 'Введите логин',
      'enter_password': 'Введите пароль',
      // Home
      'rooms': 'Комнаты',
      'create_room': 'Создать комнату',
      'room_name_hint': 'Название комнаты',
      'new_room': 'Новая комната',
      'cancel': 'Отмена',
      'create': 'Создать',
      'join': 'Войти',
      'delete_room_title': 'Удалить комнату?',
      'delete_confirm': 'будет удалена.',
      'delete': 'Удалить',
      'created_by': 'Создал: ',
      'no_rooms': 'Нет активных комнат',
      'no_rooms_hint': 'Нажмите «+» чтобы создать комнату',
      'retry': 'Повторить',
      'logout': 'Выйти',
      'search_rooms': 'Поиск комнат',
      // Settings
      'settings': 'Настройки',
      'profile': 'Профиль',
      'general': 'Основное',
      'language': 'Язык',
      'language_desc': 'Выберите язык интерфейса',
      'select_language': 'Выберите язык',
      'save': 'Сохранить',
      'about': 'О приложении',
      'about_desc': 'Версия, разработчик',
      'close': 'Закрыть',
      'version': 'Версия',
      'conference_system': 'Система видеоконференций',
      'logout_confirm_title': 'Выйти из аккаунта?',
      'logout_confirm_body': 'Вы уверены, что хотите выйти?',
      'logout_confirm': 'Выйти',
      'copyright': '© 2026 UztexConf. Все права защищены.',
    },
    'en': {
      'username': 'Username',
      'password': 'Password',
      'sign_in': 'Sign In',
      'invalid_credentials': 'Invalid username or password',
      'no_connection': 'No connection to server',
      'enter_credentials': 'Enter username and password',
      'enter_username': 'Enter username',
      'enter_password': 'Enter password',
      'rooms': 'Rooms',
      'create_room': 'Create Room',
      'room_name_hint': 'Room name',
      'new_room': 'New Room',
      'cancel': 'Cancel',
      'create': 'Create',
      'join': 'Join',
      'delete_room_title': 'Delete room?',
      'delete_confirm': 'will be deleted.',
      'delete': 'Delete',
      'created_by': 'Created by: ',
      'no_rooms': 'No active rooms',
      'no_rooms_hint': 'Tap "+" to create a room',
      'retry': 'Retry',
      'logout': 'Logout',
      'search_rooms': 'Search rooms',
      'settings': 'Settings',
      'profile': 'Profile',
      'general': 'General',
      'language': 'Language',
      'language_desc': 'Choose interface language',
      'select_language': 'Select Language',
      'save': 'Save',
      'about': 'About App',
      'about_desc': 'Version, developer',
      'close': 'Close',
      'version': 'Version',
      'conference_system': 'Video Conference System',
      'logout_confirm_title': 'Log Out?',
      'logout_confirm_body': 'Are you sure you want to log out?',
      'logout_confirm': 'Log Out',
      'copyright': '© 2026 UztexConf. All rights reserved.',
    },
    'uz': {
      'username': 'Login',
      'password': 'Parol',
      'sign_in': 'Kirish',
      'invalid_credentials': "Noto'g'ri login yoki parol",
      'no_connection': "Server bilan aloqa yo'q",
      'enter_credentials': 'Login va parolni kiriting',
      'enter_username': 'Loginni kiriting',
      'enter_password': 'Parolni kiriting',
      'rooms': 'Xonalar',
      'create_room': 'Xona yaratish',
      'room_name_hint': 'Xona nomi',
      'new_room': 'Yangi xona',
      'cancel': 'Bekor qilish',
      'create': 'Yaratish',
      'join': 'Kirish',
      'delete_room_title': "Xonani o'chirish?",
      'delete_confirm': "o'chiriladi.",
      'delete': "O'chirish",
      'created_by': 'Yaratdi: ',
      'no_rooms': "Faol xonalar yo'q",
      'no_rooms_hint': '"+" tugmasini bosib xona yarating',
      'retry': 'Qayta urinish',
      'logout': 'Chiqish',
      'search_rooms': 'Xonalarni qidirish',
      'settings': 'Sozlamalar',
      'profile': 'Profil',
      'general': 'Asosiy',
      'language': 'Til',
      'language_desc': "Interfeys tilini tanlang",
      'select_language': 'Tilni tanlang',
      'save': 'Saqlash',
      'about': 'Ilova haqida',
      'about_desc': 'Versiya, ishlab chiqaruvchi',
      'close': 'Yopish',
      'version': 'Versiya',
      'conference_system': 'Video konferensiya tizimi',
      'logout_confirm_title': 'Chiqishni xohlaysizmi?',
      'logout_confirm_body': "Rostdan ham chiqishni xohlaysizmi?",
      'logout_confirm': 'Chiqish',
      'copyright': '© 2026 UztexConf. Barcha huquqlar himoyalangan.',
    },
  };
}
