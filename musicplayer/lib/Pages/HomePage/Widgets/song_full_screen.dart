import 'package:flutter/material.dart';

class SongFullScreen extends StatelessWidget {
  final Widget songImage;
  
  const SongFullScreen({super.key, required this.songImage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 50,
      height: MediaQuery.of(context).size.height - 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // back button
          SizedBox(
            width: MediaQuery.of(context).size.width ,
           
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.arrow_back_ios))
              ],
            ),
          ),

          // iamge here
          AspectRatio(
            aspectRatio: 1,
            child: songImage,
          ),

          Text("title"),
          Text("artist"),
          // // slider for time control
          Slider(value: 0, onChanged: (value) {}),
          
          // controls
        ],
      ),
    );
  }
}
