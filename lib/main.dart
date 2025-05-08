import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MyApp());
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'cats.db');
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imageUrl TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertCat(Cat cat) async {
    final db = await database;
    final data = cat.toMap()..remove('id');
    return await db.insert('cats', data);
  }

  Future<List<Cat>> getAllCats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cats');
    return List.generate(maps.length, (i) => Cat.fromMap(maps[i]));
  }

  Future<int> deleteCat(int id) async {
    final db = await database;
    return await db.delete('cats', where: 'id = ?', whereArgs: [id]);
  }
}

const Color primaryColor = Color(0xFF6C5CE7);
const Color secondaryColor = Color(0xFFA8A4E6);
const Color accentColor = Color(0xFFFFD6A5);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color textColor = Color(0xFF2D3436);
const Color errorColor = Color(0xFFE57373);

class Cat {
  final int? id;
  final String imageUrl;
  final String name;
  final String description;
  final DateTime date;

  Cat({
    this.id,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Cat.fromMap(Map<String, dynamic> map) {
    return Cat(
      id: map['id'],
      imageUrl: map['imageUrl'],
      name: map['name'],
      description: map['description'],
      date: DateTime.parse(map['date']),
    );
  }
}

class LikeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LikeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.thumb_up, color: primaryColor, size: 30),
      ),
      onPressed: onPressed,
    );
  }
}

class DislikeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DislikeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.thumb_down, color: errorColor, size: 30),
      ),
      onPressed: onPressed,
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String imageUrl;
  final String description;

  DetailScreen({required this.imageUrl, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Description', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: backgroundColor,
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder:
                            (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                Icon(Icons.error, color: errorColor),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.8),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
      ),
      home: ImageScreen(),
    );
  }
}

class ImageScreen extends StatefulWidget {
  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<Map<String, String>> cards = [];
  int totalLikes = 0;
  bool isLoading = true;
  Exception? _lastError;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  Future<void> fetchImage() async {
    if (_connectionStatus == ConnectivityResult.none) return;

    setState(() {
      isLoading = true;
      _lastError = null;
    });
    try {
      final apiKey =
          'live_RwIDFaaEwYQjTp6867lsetLrrWadwmOGPU0Z9hxzONWDhpqyOhPoGP3WkuXOPeMu';
      final endpoint =
          'https://api.thecatapi.com/v1/images/search?has_breeds=1';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'x-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            cards.insert(0, {
              'imageUrl': data[0]['url'],
              'name': data[0]['breeds'][0]['name'],
              'description': data[0]['breeds'][0]['description'],
            });
          });
        }
      }
    } on TimeoutException {
      _showErrorDialog('Превышено время ожидания');
    } on SocketException {
      _showErrorDialog('Нет подключения к интернету');
    } catch (e) {
      _showErrorDialog('Ошибка загрузки: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Ошибка', style: TextStyle(color: errorColor)),
            content: Text(message, style: TextStyle(color: textColor)),
            actions: [
              TextButton(
                child: Text('OK', style: TextStyle(color: primaryColor)),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );
  }

  Future<void> _loadTotalLikes() async {
    final dbHelper = DatabaseHelper();
    final cats = await dbHelper.getAllCats();
    setState(() => totalLikes = cats.length);
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    fetchImage();
    _loadTotalLikes();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (_connectionStatus == result) return;

    setState(() => _connectionStatus = result);
    if (!mounted) return;

    final message =
        result == ConnectivityResult.none
            ? 'Нет подключения к интернету'
            : 'Подключение восстановлено';

    final color = result == ConnectivityResult.none ? errorColor : primaryColor;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: Duration(seconds: 3),
        ),
      );

    if (result != ConnectivityResult.none && cards.isEmpty) {
      fetchImage();
    }
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.right) {
      final newCat = Cat(
        imageUrl: cards[previousIndex]['imageUrl']!,
        name: cards[previousIndex]['name']!,
        description: cards[previousIndex]['description']!,
        date: DateTime.now(),
      );
      DatabaseHelper().insertCat(newCat).then((_) => _loadTotalLikes());
    }
    fetchImage();
    return true;
  }

  void removeCat(int id) async {
    await DatabaseHelper().deleteCat(id);
    _loadTotalLikes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cats', style: TextStyle(color: textColor))),
      body: Column(
        children: [_buildTopPanel(), Expanded(child: _buildMainContent())],
      ),
    );
  }

  Widget _buildTopPanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Likes: $totalLikes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: primaryColor, fontSize: 24),
          ),
          SizedBox(width: 20),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.favorite, color: primaryColor, size: 30),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedCatsScreen(onRemove: removeCat),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: errorColor),
            SizedBox(height: 16),
            Text(
              'Не удалось загрузить котиков',
              style: TextStyle(fontSize: 18, color: textColor),
            ),
            TextButton(
              onPressed: fetchImage,
              child: Text(
                'Попробовать снова',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width,
        child: CardSwiper(
          controller: controller,
          cardsCount: cards.length,
          allowedSwipeDirection: AllowedSwipeDirection.symmetric(
            horizontal: true,
          ),
          onSwipe: _onSwipe,
          numberOfCardsDisplayed: 1,
          backCardOffset: const Offset(0, 0),
          cardBuilder: (
            context,
            index,
            horizontalThresholdPercentage,
            verticalThresholdPercentage,
          ) {
            final card = cards[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DetailScreen(
                          imageUrl: card['imageUrl']!,
                          description: card['description']!,
                        ),
                  ),
                );
              },
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: card['imageUrl']!,
                            placeholder:
                                (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    Icon(Icons.error, color: errorColor),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          card['name']!,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            DislikeButton(
                              onPressed: () {
                                controller.swipe(CardSwiperDirection.left);
                              },
                            ),
                            LikeButton(
                              onPressed: () {
                                controller.swipe(CardSwiperDirection.right);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LikedCatsScreen extends StatefulWidget {
  final Function(int) onRemove;

  const LikedCatsScreen({required this.onRemove});

  @override
  _LikedCatsScreenState createState() => _LikedCatsScreenState();
}

class _LikedCatsScreenState extends State<LikedCatsScreen> {
  List<Cat> likedCats = [];
  String? selectedBreed = 'All';
  List<String> breeds = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    final dbHelper = DatabaseHelper();
    final cats = await dbHelper.getAllCats();
    setState(() {
      likedCats = cats;
      breeds = _getUniqueBreeds(cats);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCats =
        selectedBreed == 'All'
            ? likedCats
            : likedCats.where((cat) => cat.name == selectedBreed).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Cats', style: TextStyle(color: textColor)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: DropdownButton<String>(
              value: selectedBreed,
              icon: Icon(Icons.filter_list, color: primaryColor),
              underline: SizedBox(),
              style: TextStyle(color: textColor),
              dropdownColor: backgroundColor,
              items:
                  breeds.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: textColor)),
                    );
                  }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedBreed = newValue;
                });
              },
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredCats.length,
        itemBuilder:
            (context, index) => Dismissible(
              key: Key(filteredCats[index].id.toString()),
              background: Container(color: errorColor),
              onDismissed: (direction) => _removeCat(index),
              child: ListTile(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DetailScreen(
                              imageUrl: filteredCats[index].imageUrl,
                              description: filteredCats[index].description,
                            ),
                      ),
                    ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: filteredCats[index].imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[200],
                          width: 50,
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[200],
                          width: 50,
                          height: 50,
                          child: Icon(Icons.error_outline, color: errorColor),
                        ),
                  ),
                ),
                title: Text(filteredCats[index].name),
                subtitle: Text(
                  DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).format(filteredCats[index].date),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _removeCat(index),
                ),
              ),
            ),
      ),
    );
  }

  List<String> _getUniqueBreeds(List<Cat> cats) {
    final breeds = cats.map((cat) => cat.name).toSet().toList()..sort();
    return ['All']..addAll(breeds);
  }

  Widget _buildBody(List<Map<String, dynamic>> cats) {
    if (cats.isEmpty) {
      return Center(
        child: Text(
          selectedBreed == 'All'
              ? 'No liked cats yet!'
              : 'No cats of this breed',
          style: TextStyle(fontSize: 18, color: textColor),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        return Dismissible(
          key: Key(cat['date'].toString() + index.toString()),
          background: Container(color: errorColor),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _removeCat(index);
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 15),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(15),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: cat['imageUrl']!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(cat['name']!, style: TextStyle(color: textColor)),
              subtitle: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(cat['date']),
                style: TextStyle(color: textColor.withOpacity(0.6)),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: errorColor),
                onPressed: () => _removeCat(index),
              ),
            ),
          ),
        );
      },
    );
  }

  void _removeCat(int index) async {
    final cat = likedCats[index];
    if (cat.id != null) {
      await DatabaseHelper().deleteCat(cat.id!);
      widget.onRemove(cat.id!);
      await _loadCats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cat removed', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryColor,
        ),
      );
    } else {
      print('Error: Cat ID is null');
    }
  }
}
