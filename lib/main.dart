import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

const Color primaryColor = Color(0xFF6C5CE7);
const Color secondaryColor = Color(0xFFA8A4E6);
const Color accentColor = Color(0xFFFFD6A5);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color textColor = Color(0xFF2D3436);
const Color errorColor = Color(0xFFE57373);

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

void main() {
  runApp(MyApp());
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
  List<Map<String, dynamic>> likedCats = [];
  int totalLikes = 0;
  bool isLoading = true;
  Exception? _lastError;

  Future<void> fetchImage() async {
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

  @override
  void initState() {
    super.initState();
    fetchImage();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.right) {
      setState(() {
        likedCats.add({...cards[previousIndex], 'date': DateTime.now()});
        totalLikes++;
      });
    }
    fetchImage();
    return true;
  }

  void removeCat(int index) {
    setState(() {
      likedCats.removeAt(index);
      totalLikes = likedCats.length;
    });
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
                  builder:
                      (context) => LikedCatsScreen(
                        getLikedCats: () => likedCats,
                        onRemove: removeCat,
                      ),
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
        width: MediaQuery.of(context).size.width ,
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
  final List<Map<String, dynamic>> Function() getLikedCats;
  final Function(int) onRemove;

  const LikedCatsScreen({required this.getLikedCats, required this.onRemove});

  @override
  _LikedCatsScreenState createState() => _LikedCatsScreenState();
}

class _LikedCatsScreenState extends State<LikedCatsScreen> {
  String? selectedBreed = 'All';
  List<String> breeds = ['All'];

  @override
  Widget build(BuildContext context) {
    final currentCats = widget.getLikedCats();
    final newBreeds = _getUniqueBreeds(currentCats);
    if (!listEquals(newBreeds, breeds)) {
      breeds = newBreeds;
    }
    final filteredCats =
        selectedBreed == 'All'
            ? currentCats
            : currentCats.where((cat) => cat['name'] == selectedBreed).toList();

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
      body: _buildBody(filteredCats),
    );
  }

  List<String> _getUniqueBreeds(List<Map<String, dynamic>> cats) {
    final breeds = cats.map((cat) => cat['name'] as String).toSet().toList();
    breeds.sort();
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
            _removeCat(index, cats);
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
                onPressed: () => _removeCat(index, cats),
              ),
            ),
          ),
        );
      },
    );
  }

  void _removeCat(int index, List<Map<String, dynamic>> currentList) {
    final globalIndex = widget.getLikedCats().indexOf(currentList[index]);
    widget.onRemove(globalIndex);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cat removed', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
    );
  }
}
