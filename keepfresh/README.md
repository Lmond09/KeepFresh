# keepfresh

This project is a starting point for a Flutter application.

Open your VS code terminal and type the following command to run:
- flutter clean
- flutter pub get
- flutter run

## If there is an error:
bigLargeIcon is ambiguous
bigPictureStyle.bigLargeIcon(null);
      
Solution:
  1. Click on the error error file shown at the terminal(eg: C:\Users\raymo\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_local_notifications-15.1.3\...)
  2. Find "bigPictureStyle.bigLargeIcon(null);" in the file
  3. Replace with "bigPictureStyle.bigLargeIcon((Bitmap) null);"
  4. The error should be solved.
