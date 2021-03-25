import CoreLocation
import Flutter
import UIKit
import YandexMapsMobile

public class YandexSearch: NSObject, FlutterPlugin {
  private let methodChannel: FlutterMethodChannel!
  private let searchManager: YMKSearchManager!
  private var suggestSessionsById: [Int:YMKSearchSuggestSession] = [:]
  private var searchSession: YMKSearchSession?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "yandex_mapkit/yandex_search",
      binaryMessenger: registrar.messenger()
    )
    let plugin = YandexSearch(channel: channel)
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  public required init(channel: FlutterMethodChannel) {
    self.methodChannel = channel
    self.searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
    super.init()
    
    self.methodChannel.setMethodCallHandler(self.handle)
  }
  
  public func cancelSuggestSession(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let listenerId = (params["listenerId"] as! NSNumber).intValue
    self.suggestSessionsById.removeValue(forKey: listenerId)
  }

  public func getSuggestions(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let listenerId = (params["listenerId"] as! NSNumber).intValue
    let formattedAddress = params["formattedAddress"] as! String
    let boundingBox = YMKBoundingBox.init(
      southWest: YMKPoint.init(
        latitude: (params["southWestLatitude"] as! NSNumber).doubleValue,
        longitude: (params["southWestLongitude"] as! NSNumber).doubleValue
      ),
      northEast: YMKPoint.init(
        latitude: (params["northEastLatitude"] as! NSNumber).doubleValue,
        longitude: (params["northEastLongitude"] as! NSNumber).doubleValue
      )
    )
    let responseHandler = {(searchResponse: [YMKSuggestItem]?, error: Error?) -> Void in
      let thisListenerId = listenerId
      if searchResponse != nil {
        let suggestItems = searchResponse?.map({ (suggestItem) -> [String : Any] in
          var dict = [String : Any]()

          dict["title"] = suggestItem.title.text
          dict["subtitle"] = suggestItem.subtitle?.text
          dict["displayText"] = suggestItem.displayText
          dict["searchText"] = suggestItem.searchText
          dict["tags"] = suggestItem.tags

          switch suggestItem.type {
          case .toponym:
            dict["type"] = "TOPONYM"
          case .business:
            dict["type"] = "BUSINESS"
          case .transit:
            dict["type"] = "TRANSIT"
          default:
            dict["type"] = "UNKNOWN"
          }
          return dict
        })
        let arguments: [String:Any?] = [
          "listenerId": thisListenerId,
          "response": suggestItems
        ]
        self.methodChannel.invokeMethod("onSuggestListenerResponse", arguments: arguments)
      } else if error != nil {
        let arguments: [String:Any?] = [
          "listenerId": thisListenerId
        ]
        self.methodChannel.invokeMethod("onSuggestListenerError", arguments: arguments)
      }
    }

    let suggestSession = self.searchManager!.createSuggestSession()
    var suggestType = YMKSuggestType()
    switch params["suggestType"] as! String {
    case "GEO":
      suggestType = YMKSuggestType.geo
    case "BIZ":
      suggestType = YMKSuggestType.biz
    case "TRANSIT":
      suggestType = YMKSuggestType.transit
    default:
      suggestType = YMKSuggestType.init(rawValue: 0)
    }

    let suggestOptions = YMKSuggestOptions.init(
      suggestTypes: suggestType,
      userPosition: nil,
      suggestWords: (params["suggestWords"] as! NSNumber).boolValue
    )
    suggestSession.suggest(
      withText: formattedAddress,
      window: boundingBox,
      suggestOptions: suggestOptions,
      responseHandler: responseHandler
    )
    self.suggestSessionsById[listenerId] = suggestSession;
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSuggestions":
      getSuggestions(call)
      result(nil)
    case "cancelSuggestSession":
      cancelSuggestSession(call)
      result(nil)
    case "onSearchElementTap":
      searchDetail(call)
      result("test")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    func searchDetail(_ call: FlutterMethodCall) {
        
        let BOUNDING_BOX = YMKBoundingBox(
                southWest: YMKPoint(latitude: 54.176283, longitude: 48.189940),
                northEast: YMKPoint(latitude: 54.376283, longitude: 48.389940))
        let geometry = YMKGeometry(boundingBox: BOUNDING_BOX)
        let SEARCH_OPTIONS = YMKSearchOptions()

        let responseHandler = {(searchResponse: YMKSearchResponse?, error: Error?) -> Void in
            if let response = searchResponse {
                self.onSearchResponse(response)
              } else if error != nil {
                
              }
        }
        
        guard let args = call.arguments else {
            return
        }
        if let myArgs = args as? [String: Any], let query = myArgs["query"] as? String {
            searchSession = self.searchManager?.submit(
                withText: query,
                geometry: geometry,
                searchOptions: SEARCH_OPTIONS,
                responseHandler: responseHandler)
        }
    }
    
    func onSearchResponse(_ response: YMKSearchResponse) {

        for searchResult in response.collection.children {
            guard let obj = searchResult.obj else {
                continue
            }

            guard let objMetadata = obj.metadataContainer.getItemOf(YMKSearchToponymObjectMetadata.self) as? YMKSearchToponymObjectMetadata else {
                continue
            }

            let x = objMetadata.balloonPoint.latitude
            let y = objMetadata.balloonPoint.longitude

            var ymkPoint = YMKPoint(latitude: x, longitude: y)

            let address = objMetadata.address

            let formattedAddress = address.formattedAddress
            let postalCode:String = address.postalCode ?? ""
            let additionalInfo = address.additionalInfo ?? "none"

            var country:String = ""
            var region:String = ""
            var street:String = ""
            var locality:String = ""
            var house:String = ""

            address.components.forEach {
                let value = $0.name

                $0.kinds.forEach {
                    let kind = YMKSearchComponentKind(rawValue: UInt(truncating: $0))

                    switch kind {

                    case .country:
                        country = value
                        print("country: \(value)")

                    case .region:
                        region = value
                        print("region: \(value)")

                    case .locality:
                        locality = value
                        print("locality: \(value)")

                    case .street:
                        street = value
                        print("street: \(value)")
                        
                    case .house:
                        house = ", \(value)"
                        print("house number: \(value)")

                    default:
                        break
                    }
                }
            }
            
            let arguments: [String:Any?] = [
                "country": country,
                "region": region,
                "locality": locality,
                "street": street,
                "postalCode": postalCode
            ]
            
            self.methodChannel.invokeMethod("onSuggestListenerResponseTest", arguments: arguments)
        }
    }
}
