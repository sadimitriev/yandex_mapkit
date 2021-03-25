import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:yandex_mapkit_example/examples/widgets/map_page.dart';

class QueryModel {
  int id;
  String name;

  QueryModel({this.id, this.name});

  QueryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}

class SearchPage extends MapPage {
  const SearchPage() : super('Search example');

  @override
  Widget build(BuildContext context) {
    return _SearchExample();
  }
}

class _SearchExample extends StatefulWidget {
  @override
  _SearchExampleState createState() => _SearchExampleState();
}

class _SearchExampleState extends State<_SearchExample> {
  TextEditingController queryController = TextEditingController();
  List<QueryModel> response = List<QueryModel>();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Text('Search:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        controller: queryController,
                      ),
                    ),
                    InkWell(
                      child: Text("Query"),
                      onTap: () {
                        querySuggestions(queryController.text);
                      },
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Response:'),
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: response.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      color: Colors.black12,
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('${response[index].name}'),
                        ),
                        onTap: () => YandexSearch.onSearchElementTap(
                          response[index].name,
                          (dynamic value) {

                          }
                        ),
                      ),
                    );

                    return ListTile(
                      title: Text('${response[index].name}'),
                    );
                  },
                ),
              ]
            )
          )
        )
      ]
    );
  }

  Future<void> querySuggestions(String query) async {
    final CancelSuggestCallback cancelListening = await YandexSearch.getSuggestions(
      query,
      const Point(latitude: 55.5143, longitude: 37.24841),
      const Point(latitude: 56.0421, longitude: 38.0284),
      'GEO',
      true,
      (List<SuggestItem> suggestItems) {
        setState(() {
          response = [];
          suggestItems.asMap().forEach((key, value) {
            response.add(QueryModel(id: key, name: value.searchText));
          });
          print(response);
        });
      }
    );
    await Future<dynamic>.delayed(const Duration(seconds: 3), () => cancelListening());
  }
}
