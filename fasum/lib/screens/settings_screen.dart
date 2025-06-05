import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helper/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context).language),
            trailing: DropdownButton<Locale>(
              value: provider.locale ?? Locale('en'),
              items: [
                DropdownMenuItem(
                  child: Text('English'),
                  value: Locale('en'),
                ),
                DropdownMenuItem(
                  child: Text('Bahasa Indonesia'),
                  value: Locale('id'),
                ),
              ],
              onChanged: (locale) {
                if (locale != null) provider.setLocale(locale);
              },
            ),
          )
        ],
      ),
    );
  }
}
