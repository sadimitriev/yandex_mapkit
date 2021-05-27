package com.unact.yandexmapkit;

import android.content.Context;

import androidx.annotation.NonNull;

import com.yandex.mapkit.geometry.Geometry;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.BoundingBox;
import com.yandex.mapkit.map.GeoObjectSelectionMetadata;
import com.yandex.mapkit.search.Response;
import com.yandex.mapkit.search.SuggestItem;
import com.yandex.mapkit.search.SuggestType;
import com.yandex.mapkit.search.SearchFactory;
import com.yandex.mapkit.search.SearchManagerType;
import com.yandex.mapkit.search.SuggestOptions;
import com.yandex.mapkit.search.SearchManager;
import com.yandex.mapkit.search.SuggestSession;
import com.yandex.mapkit.search.SearchOptions;
import com.yandex.mapkit.search.Session;
import com.yandex.mapkit.search.ToponymObjectMetadata;
import com.yandex.runtime.Error;
import com.yandex.runtime.any.Collection;
import com.yandex.mapkit.search.ToponymObjectMetadata;
import com.yandex.mapkit.search.Address;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class YandexSearchHandlerImpl implements MethodCallHandler, Session.SearchListener {
  private MethodChannel methodChannel;
  private Map<Integer, SuggestSession> suggestSessionsById = new HashMap<>();
  private final SearchManager searchManager;
  private Session searchSession;

  public YandexSearchHandlerImpl(Context context, MethodChannel channel) {
    SearchFactory.initialize(context);
    methodChannel = channel;
    searchManager = SearchFactory.getInstance().createSearchManager(SearchManagerType.COMBINED);
  }

  @Override
  public void onSearchError(Error error) {

  }

  @Override
  public void onSearchResponse(Response response) {

    ToponymObjectMetadata data = response.getCollection().getChildren().get(0)
            .getObj().getMetadataContainer().getItem(ToponymObjectMetadata.class);

    final double x = data.getBalloonPoint().getLatitude();
    final double y = data.getBalloonPoint().getLongitude();
    final String postalCode = data.getAddress().getPostalCode();

    String country = "";
    String region = "";
    String street = "";
    String locality = "";
    String house = "";
    String province = "";
    String area = "";
    final String district = "";

    for (Address.Component component : data.getAddress().getComponents()) {
      String value = component.getName();
      for (Address.Component.Kind kind : component.getKinds()) {

        switch (kind.name()) {
          case "COUNTRY":
            country = value;
            break;
          case "PROVINCE":
            province = value;
            break;
          case "REGION":
            region = value;
            break;
          case "AREA":
            area = value;
            break;
          case "LOCALITY":
            locality = value;
            break;
          case "STREET":
            street = value;
            break;
          case "HOUSE":
            house = value;
            break;
        }
      }
    }

    final String finalCountry = country;
    final String finalRegion = region;
    final String finalLocality = locality;
    final String finalStreet = street;
    final String finalArea = area;
    final String finalHouse = house;
    final String finalProvince = province;
    Map<String, String> arguments = new HashMap<String, String>()
    {
      {
        put("country", finalCountry);
        put("region", finalRegion);
        put("locality", finalLocality);
        put("street", finalStreet);
        put("postalCode", postalCode);
        put("area", finalArea);
        put("house", finalHouse);
        put("lat", String.valueOf(x));
        put("lon", String.valueOf(y));
        put("province", finalProvince);
        put("district", district);
      }
    };

    Log.d("list", arguments.toString());

    methodChannel.invokeMethod("onSuggestListenerResponseTest", arguments);
  }

  @SuppressWarnings("unchecked")
  private void searchDetail(MethodCall call) {
    Map<String, Object> args = ((Map<String, Object>) call.arguments);
    final String query = ((String) args.get("query")).toString();

    Geometry point = Geometry.fromPoint(new Point(54.176283, 48.189940));

    searchSession = searchManager.submit(
      query,
      point,
      new SearchOptions(),
      this
    );
  }

  @SuppressWarnings("unchecked")
  private void cancelSuggestSession(MethodCall call) {
    Map<String, Object> params = ((Map<String, Object>) call.arguments);
    final int listenerId = ((Number) params.get("listenerId")).intValue();
    suggestSessionsById.remove(listenerId);
  }

  @SuppressWarnings("unchecked")
  private void getSuggestions(MethodCall call) {
    Map<String, Object> params = ((Map<String, Object>) call.arguments);

    final int listenerId = ((Number) params.get("listenerId")).intValue();

    String formattedAddress = (String) params.get("formattedAddress");
    BoundingBox boundingBox = new BoundingBox(
      new Point(((Double) params.get("southWestLatitude")), ((Double) params.get("southWestLongitude"))),
      new Point(((Double) params.get("northEastLatitude")), ((Double) params.get("northEastLongitude")))
    );
    SuggestType suggestType;
    switch ((String) params.get("suggestType")) {
      case "GEO":
        suggestType = SuggestType.GEO;
        break;
      case "BIZ":
        suggestType = SuggestType.BIZ;
        break;
      case "TRANSIT":
        suggestType = SuggestType.TRANSIT;
        break;
      default:
        suggestType = SuggestType.UNSPECIFIED;
        break;
    }
    Boolean suggestWords = ((Boolean) params.get("suggestWords"));
    SuggestSession suggestSession = searchManager.createSuggestSession();
    SuggestOptions suggestOptions = new SuggestOptions();
    suggestOptions.setSuggestTypes(suggestType.value);
    suggestOptions.setSuggestWords(suggestWords);
    suggestSession.suggest(formattedAddress, boundingBox, suggestOptions, new YandexSuggestListener(listenerId));
    suggestSessionsById.put(listenerId, suggestSession);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "getSuggestions":
        getSuggestions(call);
        result.success(null);
        break;
      case "cancelSuggestSession":
        cancelSuggestSession(call);
        result.success(null);
        break;
      case "onSearchElementTap":
        searchDetail(call);
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private class YandexSuggestListener implements SuggestSession.SuggestListener {
    public YandexSuggestListener(int id) {
      listenerId = id;
    }
    private int listenerId;

    @Override
    public void onResponse(@NonNull List<SuggestItem> suggestItems) {
      List<Map<String, Object>> suggests = new ArrayList<>();

      for (SuggestItem suggestItemResult : suggestItems) {
        Map<String, Object> suggestMap = new HashMap<>();
        suggestMap.put("title", suggestItemResult.getTitle().getText());
        if(suggestItemResult.getSubtitle() != null) {
          suggestMap.put("subtitle", suggestItemResult.getSubtitle().getText());
        }
        if(suggestItemResult.getDisplayText() != null) {
          suggestMap.put("displayText", suggestItemResult.getDisplayText());
        }
        suggestMap.put("searchText", suggestItemResult.getSearchText());
        suggestMap.put("tags", suggestItemResult.getTags());
        String suggestItemType;
        switch (suggestItemResult.getType()) {
          case TOPONYM:
            suggestItemType = "TOPONYM";
            break;
          case BUSINESS:
            suggestItemType = "BUSINESS";
            break;
          case TRANSIT:
            suggestItemType = "TRANSIT";
            break;
          default:
            suggestItemType = "UNKNOWN";
            break;
        }
        suggestMap.put("type", suggestItemType);
        suggests.add(suggestMap);
      }

      Map<String, Object> arguments = new HashMap<>();
      arguments.put("listenerId", listenerId);
      arguments.put("response", suggests);
      methodChannel.invokeMethod("onSuggestListenerResponse", arguments);
    }

    @Override
    public void onError(@NonNull Error error) {
      Map<String, Object> arguments = new HashMap<>();
      arguments.put("listenerId", listenerId);
      methodChannel.invokeMethod("onSuggestListenerError", arguments);
    }
  }
}
