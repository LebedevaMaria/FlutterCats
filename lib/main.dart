import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  bool isLoading = true;
  int likeCount = 0;

  Future<void> fetchImage() async {
    final apiKey = 'live_RwIDFaaEwYQjTp6867lsetLrrWadwmOGPU0Z9hxzONWDhpqyOhPoGP3WkuXOPeMu';
    final endpoint = 'https://api.thecatapi.com/v1/images/search?has_breeds=1';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'x-api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        cards.add({
          'imageUrl': data[0]['url'],
          'name': data[0]['breeds'][0]['name'],
          'description': data[0]['breeds'][0]['description'],
        });
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchImage();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Text(
                    'Likes: $likeCount',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: CardSwiper(
                        controller: controller,
                        cardsCount: cards.length,
                        allowedSwipeDirection: AllowedSwipeDirection.symmetric(horizontal: true),
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
                                  builder: (context) => DetailScreen(
                                    imageUrl: card['imageUrl']!,
                                    description: card['description']!,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.fromARGB(122, 118, 102, 112), 
                                     Color.fromARGB(122, 118, 102, 112), 
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: CachedNetworkImage(
                                          imageUrl: card['imageUrl']!,
                                          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        card['name']!,
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 0, 0, 0)),
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
                                              setState(() {
                                                likeCount++;
                                              });
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
                  ),
                ),
              ],
            ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    fetchImage();
    return true;
  }
}



class LikeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LikeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.thumb_up, color: Colors.green, size: 30),
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
      icon: Icon(Icons.thumb_down, color: Colors.red, size: 30),
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
        title: Text('Description'),
      ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.3,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(122, 118, 102, 112), 
                    Color.fromARGB(122, 118, 102, 112), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 0, 0, 0)),
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
