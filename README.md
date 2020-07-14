# Hacube

This is a game of Rubik's cube written in Flutter and yes, It's 3D !

## How this come

I am a Flutter fan and I just learned to play Rubik's cube. 
Then I wonder if I can write an app about it in Hack20. 

Flutter has a great graphics library but unluckily it only support 2D. 
I use some matrix transform to simulate the camera change in 3D, 
and manually calculate the depth of every surface of cube.

## Screenshots & Video

![Screenshot 01](https://raw.githubusercontent.com/likang/Hacube/master/assets/screenshots/Screenshot_1.jpg)
![Screenshot 02](https://raw.githubusercontent.com/likang/Hacube/master/assets/screenshots/Screenshot_2.jpg)

Here is a [video](https://www.youtube.com/watch?v=-Dd-tQKp1ug) to show how it looks like.

# Fluter Web

To enable web support on flutter, you need to chang the main channel to *beta* 
`flutter channel beta` and `flutter upgrade`, more info can be found [here](https://flutter.dev/docs/get-started/web).

To migrate the project to flutter web, you need to run `flutter create .` and `flutter run -d chrome` to run on the browser.


