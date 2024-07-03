// ignore_for_file: unused_catch_clause

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:route_tracker/utils/location_service.dart';
import 'package:route_tracker/utils/map_services.dart';
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
  late MapServices mapServices;
  late CameraPosition initialCameraPosition;
  late TextEditingController textEditingController;
  late Uuid uuid;
  late LatLng destination;
  String? sessiontoken;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<PlaceModel> places = [];
  Timer? debounce;

  @override
  void initState() {
    mapServices = MapServices();
    textEditingController = TextEditingController();
    initialCameraPosition = const CameraPosition(target: LatLng(0, 0));
    uuid = const Uuid();
    fetchPredictions();
    super.initState();
  }

  void fetchPredictions() {
    textEditingController.addListener(
      () {
        if (debounce?.isActive ?? false) {
          debounce?.cancel();
        }
        debounce = Timer(const Duration(milliseconds: 250), () async {
          sessiontoken ??= uuid.v4();
          await mapServices.getPredictions(
            input: textEditingController.text,
            sessiontoken: sessiontoken!,
            places: places,
          );
          setState(() {});
        });
      },
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    textEditingController.dispose();
    debounce?.cancel();
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
                  var points = await mapServices.getRouteData(
                    destination: destination,
                  );
                  mapServices.displayRoute(
                    points,
                    mapController: mapController,
                    polylines: polylines,
                  );
                  setState(() {});
                },
                places: places,
                mapServices: mapServices,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void updateCurrentLocation() {
    try {
      mapServices.updateCurrentLocation(
        mapController: mapController,
        markers: markers,
        onUpdateCurrentLocation: () {
          setState(() {});
        },
      );
      setState(() {});
    } on LocationServiceException catch (e) {
      // TODO
    } on LocationPermissionException catch (e) {
      // TODO
    } catch (e) {
      // TODO
    }
  }
}
