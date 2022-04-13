import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';

import 'package:http/io_client.dart';

Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await http.get(Uri.parse('https://kubsau.ru/api/getNews.php?key=6df2f5d38d4e16b5a923a6d4873e2ee295d0ac90'));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}

// A function that converts a response body into a List<Photo>.
List<Photo> parsePhotos(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}

class Photo {
  final String id;
  final String activeForm;
  final String title;
  final String previewText;
  final String previewPictureSrc;
  final String detailPageUrl;
  final String detailText;
  final String lastModified;

  const Photo({
    required this.id,
    required this.activeForm,
    required this.title,
    required this.previewText,
    required this.previewPictureSrc,
    required this.detailPageUrl,
    required this.detailText,
    required this.lastModified,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['ID'] as String,
      activeForm: json['ACTIVE_FROM'] as String,
      title: json['TITLE'] as String,
      previewText: json['PREVIEW_TEXT'] as String,
      previewPictureSrc: json['PREVIEW_PICTURE_SRC'] as String,
      detailPageUrl: json['DETAIL_PAGE_URL'] as String,
      detailText: json['DETAIL_TEXT'] as String,
      lastModified: json['LAST_MODIFIED'] as String,
    );
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Лента новостей КубГАУ';
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<Photo>>(
        future: fetchPhotos(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Ошибка запроса!'),
            );
          } else if (snapshot.hasData) {
            return PhotosList(photos: snapshot.data!);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class PhotosList extends StatelessWidget {
  const PhotosList({Key? key, required this.photos}) : super(key: key);

  final List<Photo> photos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, mainAxisSpacing: 1.2),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Card(        
          margin: const EdgeInsets.all(20),
          shadowColor: Colors.blueGrey,
          elevation: 6, 
          child: Column( 
          children: [
          ListTile(
          //title: Text(photos[index].lastModified),
          leading: Padding(
            padding: const EdgeInsets.all(0),
            child: SizedBox(
              child: Image.network(photos[index].previewPictureSrc),),
            ),
          )]         
          ) 
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
