import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:alkohol_per_krona/components/body.dart';
import 'package:alkohol_per_krona/constants.dart';
import 'dart:developer' as developer;

Future<Database>? database;
Future<List<Product>>? productCache;
String? searchQuery;

class Product {
  final int productId;
  final int productNumber;
  final String productNameBold;
  final String productNameThin;
  final String producerName;
  final double alcoholPercentage;
  final double volume;
  final double price;
  final String country;
  final String categoryLevel1;
  final String categoryLevel2;
  final String categoryLevel3;
  final String categoryLevel4;
  final double apk;
  final String imageUrl;

  const Product({
    required this.productId,
    required this.productNumber,
    required this.productNameBold,
    required this.productNameThin,
    required this.producerName,
    required this.alcoholPercentage,
    required this.volume,
    required this.price,
    required this.country,
    required this.categoryLevel1,
    required this.categoryLevel2,
    required this.categoryLevel3,
    required this.categoryLevel4,
    required this.apk,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productNumber': productNumber,
      'productNameBold': productNameBold,
      'productNameThin': productNameThin,
      'producerName': producerName,
      'alcoholPercentage': alcoholPercentage,
      'volume': volume,
      'price': price,
      'country': country,
      'categoryLevel1': categoryLevel1,
      'categoryLevel2': categoryLevel2,
      'categoryLevel3': categoryLevel3,
      'categoryLevel4': categoryLevel4,
      'apk': apk,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'Product{productI: $productId, productNumber: $productNumber, productNameBold: $productNameBold, productNameThin: $productNameThin, producerName: $producerName, alcoholPercentage: $alcoholPercentage, volume: $volume, price: $price, country: $country, categoryLevel1: $categoryLevel1, categoryLevel2: $categoryLevel2, categoryLevel3: $categoryLevel3, categoryLevel4: $categoryLevel4, apk: $apk, imageUrl: $imageUrl}';
  }
}

Future<List> fetchProducts() async {
  var uri = Uri.parse(
      'https://api-extern.systembolaget.se/sb-api-ecommerce/v1/productsearch/search?');

  final response = await http.get(
    uri,
    headers: {'Ocp-Apim-Subscription-Key': 'cfc702aed3094c86b92d6d4ff7a54c84'},
  );

  if (response.statusCode == 200) {
    var productList = [];
    final body = jsonDecode(response.body);
    //developer.log(body["products"].length.toString(), name: "JSON");

    for (var i = 0; i < 30; i++) {
      //developer.log("i: $i, Length: ${body["products"][i]["images"].length}"); //, isNull?: ${body["products"][i]["images"][0]["imageUrl"] == null}", name: "imageUrl
      Product product = Product(
        productId: (body["products"][i]["productId"] == null)
            ? 0
            : int.parse(body["products"][i]["productId"]),
        productNumber: (body["products"][i]["productNumber"] == null)
            ? 0
            : int.parse(body["products"][i]["productNumber"]),
        productNameBold: (body["products"][i]["productNameBold"] == null)
            ? ""
            : body["products"][i]["productNameBold"],
        productNameThin: (body["products"][i]["productNameThin"] == null)
            ? ""
            : body["products"][i]["productNameThin"],
        producerName: (body["products"][i]["producerName"] == null)
            ? ""
            : body["products"][i]["producerName"],
        alcoholPercentage: (body["products"][i]["alcoholPercentage"] == null)
            ? 0.0
            : body["products"][i]["alcoholPercentage"],
        volume: (body["products"][i]["volume"] == null)
            ? 0.0
            : body["products"][i]["volume"],
        price: (body["products"][i]["price"] == null)
            ? 0.0
            : body["products"][i]["price"],
        country: (body["products"][i]["country"] == null)
            ? ""
            : body["products"][i]["country"],
        categoryLevel1: (body["products"][i]["categoryLevel1"] == null)
            ? ""
            : body["products"][i]["categoryLevel1"],
        categoryLevel2: (body["products"][i]["categoryLevel2"] == null)
            ? ""
            : body["products"][i]["categoryLevel2"],
        categoryLevel3: (body["products"][i]["categoryLevel3"] == null)
            ? ""
            : body["products"][i]["categoryLevel3"],
        categoryLevel4: (body["products"][i]["categoryLevel4"] == null)
            ? ""
            : body["products"][i]["categoryLevel4"],
        apk: (body["products"][i]["volume"] == null ||
                body["products"][i]["alcoholPercentage"] == null ||
                body["products"][i]["price"] == null)
            ? 0.0
            : body["products"][i]["volume"] *
                body["products"][i]["alcoholPercentage"] /
                (body["products"][i]["price"] * 100),
        imageUrl: (body["products"][i]["images"].length == 0)
            ? ""
            : (body["products"][i]["images"][0]["imageUrl"] == null)
                ? ""
                : body["products"][i]["images"][0]["imageUrl"] + "_400.png",
      );

      productList.add(product);
    }
    //developer.log(productList[6].imageUrl.toString(), name: "No image");

    return productList;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

Product toProduct(Map<String, dynamic> map) {
  return Product(
      productId: map['productId'],
      productNumber: map['productNumber'],
      productNameBold: map['productNameBold'],
      productNameThin: map['productNameThin'],
      producerName: map['producerName'],
      alcoholPercentage: map['alcoholPercentage'],
      volume: map['volume'],
      price: map['price'],
      country: map['country'],
      categoryLevel1: map['categoryLevel1'],
      categoryLevel2: map['categoryLevel2'],
      categoryLevel3: map['categoryLevel3'],
      categoryLevel4: map['categoryLevel4'],
      apk: map['apk'],
      imageUrl: map['imageUrl']);
}

List<Product> toProducts(List<Map<String, dynamic>> maps) {
  List<Product> list = List.generate(maps.length, (i) {
    //developer.log(i.toString(), name: "INDEX");
    //developer.log(maps[0]["productId"].toString(), name: "INDEX");

    return toProduct(maps[i]);
  });

  return list;
}

Future<void> insertProduct(Product product, Future<Database> database) async {
  final db = await database;

  await db.insert(
    'products',
    product.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Product>> getProductsSorted(
    String sortedParameter, bool descending, Future<Database> database) async {
  final db = await database;
  const space = " ";
  var direction = (descending) ? "DESC" : "ASC";

  final List<Map<String, dynamic>> maps = await db.query(
    'products',
    orderBy: sortedParameter + space + direction,
    limit: 30,
  );

  return toProducts(maps);
}

Future<bool> doesDatabaseExist(Future<Database> database) async {
  final db = await database;

  final productList = await db.query('products', limit: 1);

  return productList.isNotEmpty;
}

Future<void> deleteAllProducts(Future<Database> database) async {
  final db = await database;

  await db.delete(
    'products',
  );
}

Future<void> setUpDatabase(Future<Database> database) async {
  List productsArray = await fetchProducts();

  //developer.log(productsArray.toString(), name: "THEO DEBUGGER");

  for (int i = 0; i < 30; i++) {
    insertProduct(productsArray[i], database);
  }
}

Future<List<Product>> loadProductCache(Future<Database> database) async {
  Future<List<Product>> productCache =
      getProductsSorted("productId", false, database);

  return productCache;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = openDatabase(
    join(await getDatabasesPath(), 'product_database.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE products('
              'productId INTEGER PRIMARY KEY, '
              'productNumber INTEGER, '
              'productNameBold TEXT, '
              'productNameThin TEXT, '
              'producerName TEXT, '
              'alcoholPercentage DOUBLE, '
              'volume DOUBLE, '
              'price DOUBLE, '
              'country TEXT, '
              'categoryLevel1 TEXT, '
              'categoryLevel2 TEXT, '
              'categoryLevel3 TEXT, '
              'categoryLevel4 TEXT, '
              'apk DOUBLE, '
              'imageUrl TEXT)'
      );
    },
    version: 5,
  );

  //setUpDatabase(database);
  //List<Product> products = await getProductsSorted("productId", false, database);

  //developer.log(productCache.toString(), name: "THEO DEBUGGER");



  if (await doesDatabaseExist(database)) {
    productCache = loadProductCache(database);
  } else {
    setUpDatabase(database);
    productCache = loadProductCache(database);
  }

  runApp(App());
}

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return            Scaffold(
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: veryDarkBlue,
            ),
            padding: EdgeInsets.all(20),
            child: Text('Drawer Header'),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => App()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CategoriesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: const Text('Shoping Lists'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ShoppingListScreen()));
            },
          ),
        ]),
      ),
      appBar: buildAppBar(context),
      body: Body(),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: darkBlue,
      elevation: 0,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () async {
            searchQuery = await showSearch<String>(
                // delegate to customize the search bar
                context: context,
                delegate: CustomSearchDelegate()
            );
            developer.log(searchQuery!, name: "searchQuery");
          },
        ),
        SizedBox(width: defaultPadding / 2)
      ],
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  // Demo list to show querying
  List<String> searchTerms = [
    "Apple",
    "Banana",
    "Mango",
    "Pear",
    "Watermelons",
    "Blueberries",
    "Pineapples",
    "Strawberries"
  ];

  // first overwrite to
  // clear the search text
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  // second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, query);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  // third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }

    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
        );
      },
    );
  }

  // last overwrite to show the
  // querying process at the runtime
  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }

    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
          onTap: () {
            query = result;
            close(context, query);
          },
        );
      },
    );

  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: veryDarkBlue,
            ),
            child: Text('Drawer Header'),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => App()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CategoriesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: const Text('Shoping Lists'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ShoppingListScreen()));
            },
          ),
        ]),
      ),
      appBar: AppBar(
        title: const Text('Categories'),
      ),
    );
  }
}

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: veryDarkBlue,
            ),
            child: Text('Drawer Header'),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => App()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CategoriesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: const Text('Shoping Lists'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ShoppingListScreen()));
            },
          ),
        ]),
      ),
      appBar: AppBar(
        title: const Text('Shopping List'),
      ),
    );
  }
}
