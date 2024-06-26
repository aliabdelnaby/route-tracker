import 'package:flutter/material.dart';
import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';

class CustomListViewPlaces extends StatelessWidget {
  const CustomListViewPlaces({super.key, required this.places});

  final List<PlaceModel> places;

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
              onPressed: () {},
              icon: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
