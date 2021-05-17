part of yandex_mapkit;

class Placemark {
  Placemark({
    @required this.point,
    this.style = const PlacemarkStyle(),
    this.onTap,
  });

  Point point;
  final PlacemarkStyle style;
  final ArgumentCallback<Point> onTap;
}
