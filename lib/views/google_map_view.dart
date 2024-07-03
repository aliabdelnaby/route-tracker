import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracker/models/location_info/lat_lng.dart';
import 'package:route_tracker/models/location_info/location.dart';
import 'package:route_tracker/models/location_info/location_info.dart';
import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:route_tracker/models/routes_model/routes_model.dart';
import 'package:route_tracker/utils/google_maps_place_service.dart';
import 'package:route_tracker/utils/location_service.dart';
import 'package:route_tracker/utils/routes_service.dart';
import 'package:route_tracker/widgets/custom_list_view_places.dart';
import 'package:route_tracker/widgets/custom_search_text_field.dart';
import 'package:uuid/uuid.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  late GoogleMapController mapController;
  late CameraPosition initialCameraPosition;
  late LocationServices locationService;
  late TextEditingController textEditingController;
  late GoogleMapsPlaceService googleMapsPlaceService;
  late RoutesService routesService;
  late Uuid uuid;
  late LatLng currentLocation;
  late LatLng destination;
  String? sessiontoken;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<PlaceModel> places = [];

  @override
  void initState() {
    textEditingController = TextEditingController();
    initialCameraPosition = const CameraPosition(target: LatLng(0, 0));
    uuid = const Uuid();
    locationService = LocationServices();
    routesService = RoutesService();
    fetchPredictions();
    super.initState();
  }

  void fetchPredictions() {
    googleMapsPlaceService = GoogleMapsPlaceService();
    textEditingController.addListener(
      () async {
        sessiontoken ??= uuid.v4();
        if (textEditingController.text.isNotEmpty) {
          var result = await googleMapsPlaceService.getPredictions(
            input: textEditingController.text,
            sessiontoken: sessiontoken!,
          );
          places.clear();
          places.addAll(result);
          setState(() {});
        } else {
          places.clear();
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          markers: markers,
          polylines: polylines,
          zoomControlsEnabled: false,
          initialCameraPosition: initialCameraPosition,
          onMapCreated: (controller) {
            mapController = controller;
            updateCurrentLocation();
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              CustomTextField(textEditingController: textEditingController),
              const SizedBox(height: 16),
              CustomListViewPlaces(
                onPlaceSelect: (placeDetailsModel) async {
                  textEditingController.clear();
                  places.clear();
                  sessiontoken = null;
                  setState(() {});
                  destination = LatLng(
                    placeDetailsModel.geometry!.location!.lat!,
                    placeDetailsModel.geometry!.location!.lng!,
                  );
                  var points = await getRouteData();
                  displayRoute(points);
                },
                places: places,
                googleMapsPlaceService: googleMapsPlaceService,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void updateCurrentLocation() async {
    try {
      var locationData = await locationService.getCurrentLocation();
      currentLocation = LatLng(
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
      setState(() {});
    } on LocationServiceException catch (e) {
      // TODO
    } on LocationPermissionException catch (e) {
      // TODO
    } catch (e) {
      // TODO
    }
  }

  Future<List<LatLng>> getRouteData() async {
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

  void displayRoute(List<LatLng> points) {
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
    setState(() {});
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
}
