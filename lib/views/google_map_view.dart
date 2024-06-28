import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:route_tracker/utils/google_maps_place_service.dart';
import 'package:route_tracker/utils/location_service.dart';
import 'package:route_tracker/widgets/custom_list_view_places.dart';
import 'package:route_tracker/widgets/custom_search_text_field.dart';

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
  Set<Marker> markers = {};
  List<PlaceModel> places = [];

  @override
  void initState() {
    initialCameraPosition = const CameraPosition(
      target: LatLng(26.839663247801774, 29.71044929719575),
    );
    locationService = LocationServices();
    textEditingController = TextEditingController();
    fetchPredictions();
    super.initState();
  }

  void fetchPredictions() {
    googleMapsPlaceService = GoogleMapsPlaceService();
    textEditingController.addListener(
      () async {
        if (textEditingController.text.isNotEmpty) {
          var result = await googleMapsPlaceService.getPredictions(
            input: textEditingController.text,
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
      var myLocationMarker = Marker(
        markerId: const MarkerId("myLocation"),
        position: LatLng(locationData.latitude!, locationData.longitude!),
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
}
