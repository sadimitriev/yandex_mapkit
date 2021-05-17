import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:yandex_mapkit_example/examples/widgets/map_page.dart';
import 'package:yandex_mapkit_example/examples/layers_page.dart';
import 'package:yandex_mapkit_example/examples/map_controls_page.dart';
import 'package:yandex_mapkit_example/examples/placemark_page.dart';
import 'package:yandex_mapkit_example/examples/polyline_page.dart';
import 'package:yandex_mapkit_example/examples/polygon_page.dart';
import 'package:yandex_mapkit_example/examples/target_page.dart';
import 'package:yandex_mapkit_example/examples/search_page.dart';
import 'package:yandex_mapkit_example/examples/rotation_page.dart';

void main() {
  runApp(MaterialApp(home: MainPage()));
}

const List<MapPage> _allPages = <MapPage>[
  LayersPage(),
  MapControlsPage(),
  PlacemarkPage(),
  PolylinePage(),
  PolygonPage(),
  TargetPage(),
  SearchPage(),
  RotationPage(),
];

class MainPage extends StatelessWidget {
  void _pushPage(BuildContext context, MapPage page) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) =>
        Scaffold(
          appBar: AppBar(title: Text(page.title)),
          body: Container(
            padding: const EdgeInsets.all(8),
            child: page
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YandexMap examples')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 300,
              padding: const EdgeInsets.all(8),
              child: const YandexMap()
            ),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 100,
              itemBuilder: (_, int index) => ListTile(
                title: Text("test $index)"),
              ),
            )
          ]
        ),
      )
    );
  }
}
