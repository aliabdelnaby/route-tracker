import 'package:flutter/material.dart';
import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:route_tracker/models/place_details_model/place_details_model.dart';
import 'package:route_tracker/utils/google_maps_place_service.dart';

class CustomListViewPlaces extends StatelessWidget {
  const CustomListViewPlaces({
    super.key,
    required this.places,
    required this.googleMapsPlaceService,
    required this.onPlaceSelect,
  });

  final List<PlaceModel> places;
  final PlaceService googleMapsPlaceService;
  final Function(PlaceDetailsModel) onPlaceSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: places.length,
        separatorBuilder: (context, index) => const Divider(height: 0),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(places[index].description!),
            leading: const Icon(Icons.place),
            trailing: IconButton(
              onPressed: () async {
                var placeDetails = await googleMapsPlaceService.getPlaceDetails(
                  placeId: places[index].placeId.toString(),
                );

                onPlaceSelect(placeDetails);
              },
              icon: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
