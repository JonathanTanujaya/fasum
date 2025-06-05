import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/add_post_screen.dart';
import 'package:fasum/screens/detail_screen.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../helper/locale_provider.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;

  List<String> getCategories(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      loc.categoryJalanRusak,
      loc.categoryMarkaPudar,
      loc.categoryLampuMati,
      loc.categoryTrotoarRusak,
      loc.categoryRambuRusak,
      loc.categoryJembatanRusak,
      loc.categorySampahMenumpuk,
      loc.categorySaluranTersumbat,
      loc.categorySungaiTercemar,
      loc.categorySampahSungai,
      loc.categoryPohonTumbang,
      loc.categoryTamanRusak,
      loc.categoryFasilitasRusak,
      loc.categoryPipaBocor,
      loc.categoryVandalisme,
      loc.categoryBanjir,
      loc.categoryLainnya,
    ];
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} secs ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else if (diff.inHours < 48) {
      return '1 day ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false, // Hapus semua route sebelumnya
    );
  }

  void _showCategoryFilter() async {
    final categories = getCategories(context);
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: Text(AppLocalizations.of(context).allCategories),
                  onTap: () => Navigator.pop(
                    context,
                    null,
                  ), // Null untuk memilih semua kategori
                ),
                const Divider(),
                ...categories.map(
                  (category) => ListTile(
                    title: Text(category),
                    trailing: selectedCategory == category
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(
                      context,
                      category,
                    ), // Kategori yang dipilih
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedCategory =
            result; // Set kategori yang dipilih atau null untuk Semua Kategori
      });
    } else {
      // Jika result adalah null, berarti memilih Semua Kategori
      setState(() {
        selectedCategory =
            null; // Reset ke null untuk menampilkan semua kategori
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Fasum',
          style: TextStyle(
            color: Colors.green[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.filter_list),
            tooltip: AppLocalizations.of(context).filterCategory,
          ),
          IconButton(
            onPressed: () {
              signOut();
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final posts = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              final category = data['category'] ?? AppLocalizations.of(context).categoryLainnya;
              return selectedCategory == null || selectedCategory == category;
            }).toList();

            if (posts.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context).noReportsInThisCategory),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final data = posts[index].data();
                final imageBase64 = data['image'];
                final description = data['description'];
                final createdAtStr = data['createdAt'];
                final fullName = data['fullName'] ?? 'Anonim';
                final latitude = data['latitude'];
                final longitude = data['longitude'];
                final category = data['category'] ?? AppLocalizations.of(context).categoryLainnya;
                final createdAt = DateTime.parse(createdAtStr);
                String heroTag =
                    'fasum-image-${createdAt.millisecondsSinceEpoch}';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          imageBase64: imageBase64,
                          description: description ?? '',
                          createdAt: createdAt,
                          fullName: fullName,
                          latitude: latitude,
                          longitude: longitude,
                          category: category,
                          heroTag: heroTag,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 1,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shadowColor: Theme.of(context).colorScheme.shadow,
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageBase64 != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: Hero(
                              tag: heroTag,
                              child: Image.memory(
                                base64Decode(imageBase64),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatTime(createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    description ?? '',
                                    style: const TextStyle(fontSize: 16),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(
              MaterialPageRoute(builder: (context) => const AddPostScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
