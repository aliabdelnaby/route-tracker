import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:route_tracker/utils/google_maps_place_service.dart';
import 'package:route_tracker/utils/location_service.dart';
import 'package:route_tracker/utils/routes_service.dart';

class MapServices {
  PlaceService placeService = PlaceService();
  LocationServices locationService = LocationServices();
  RoutesService routesService = RoutesService();

  getPredictions({
    required String input,
    required String sessiontoken,
    required List<PlaceModel> places,
  }) async {
    if (input.isNotEmpty) {
      var result = await placeService.getPredictions(
        input: input,
        sessiontoken: sessiontoken,
      );
      places.clear();
      places.addAll(result);
    } else {
      places.clear();
    }
  }
}
