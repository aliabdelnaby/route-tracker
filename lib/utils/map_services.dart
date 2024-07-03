import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracker/models/location_info/lat_lng.dart';
import 'package:route_tracker/models/location_info/location.dart';
import 'package:route_tracker/models/location_info/location_info.dart';
import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:route_tracker/models/place_details_model/place_details_model.dart';
import 'package:route_tracker/models/routes_model/routes_model.dart';
import 'package:route_tracker/utils/google_maps_place_service.dart';
import 'package:route_tracker/utils/location_service.dart';
import 'package:route_tracker/utils/routes_service.dart';

class MapServices {
  PlaceService placeService = PlaceService();
  LocationServices locationService = LocationServices();
  RoutesService routesService = RoutesService();

  Future<void> getPredictions({
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

  Future<List<LatLng>> getRouteData({
    required LatLng currentLocation,
    required LatLng destination,
  }) async {
    LocationInfoModel origin = LocationInfoModel(
      location: LocationModel(
        latLng: LatLngModel(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        ),
      ),
    );
    LocationInfoModel destinationn = LocationInfoModel(
      location: LocationModel(
        latLng: LatLngModel(
          latitude: destination.latitude,
          longitude: destination.longitude,
        ),
      ),
    );
    RoutesModel routes = await routesService.fetchRoutes(
      origin: origin,
      destination: destinationn,
    );

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> points = getDecodedRoute(polylinePoints, routes);

    return points;
  }

  List<LatLng> getDecodedRoute(
      PolylinePoints polylinePoints, RoutesModel routes) {
    List<PointLatLng> result = polylinePoints.decodePolyline(
      routes.routes!.first.polyline!.encodedPolyline!,
    );

    List<LatLng> points =
        result.map((e) => LatLng(e.latitude, e.longitude)).toList();
    return points;
  }

  void displayRoute(
    List<LatLng> points, {
    required GoogleMapController mapController,
    required Set<Polyline> polylines,
  }) {
    Polyline route = Polyline(
      polylineId: const PolylineId("route"),
      color: Colors.blue,
      width: 3,
      points: points,
    );

    polylines.add(route);
    LatLngBounds bounds = getLatLngBounds(points);
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 32),
    );
  }

  LatLngBounds getLatLngBounds(List<LatLng> points) {
    var southWestLatitude = points.first.latitude;
    var southWLongitude = points.first.longitude;
    var northEastLatitude = points.first.latitude;
    var northEastLongitude = points.first.longitude;

    for (var point in points) {
      southWestLatitude = min(southWestLatitude, point.latitude);
      southWLongitude = min(southWLongitude, point.longitude);
      northEastLatitude = max(northEastLatitude, point.latitude);
      northEastLongitude = max(northEastLongitude, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(southWestLatitude, southWLongitude),
      northeast: LatLng(northEastLatitude, northEastLongitude),
    );
  }

  Future<LatLng> updateCurrentLocation({
    required GoogleMapController mapController,
    required Set<Marker> markers,
  }) async {
    var locationData = await locationService.getCurrentLocation();
    var currentLocation = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    var myLocationMarker = Marker(
      markerId: const MarkerId("myLocation"),
      position: currentLocation,
    );

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 15,
        ),
      ),
    );
    markers.add(myLocationMarker);

    return currentLocation;
  }

  Future<PlaceDetailsModel> getPlaceDetails({required String placeId}) async {
    return await placeService.getPlaceDetails(placeId: placeId);
  }
}
