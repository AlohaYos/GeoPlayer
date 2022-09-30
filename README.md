# GeoPlayer

## What is GeoPlayer ?

GeoPlayer website: https://newtonjapan.com/GeoPlayer/

GeoPlayer is a simple yet powerful logging tool of your daily activity, works on iPhone running iOS7 and above.

GeoPlayer records your activity, which include location/heading/motion, and draw these data on the map while you are moving around. The motion data contains walking/running/automotive status if your iPhone has motion co-processer (M7). These information will be saved as GPX data and can be playback anytime. Playback speed is same as recording speed.

You can import/export GPX data via iTunes file sharing. Also, you can import GPX data which is exported from other service like RunKeeper.

GeoPlayer can share GPX and Motion data to your friends via AirDrop, Message and Mail. Tapping GPX data in Message or Mail automatically launch GeoPlayer and show its data on the map.

GeoPlayer can send GPX data to GeoPlayer-client app, which can receive location and motion data from GeoPlayer via Bluetooth. For developers, GeoPlayer act as location/motion simulator for your GPS app. You can playback any recorded GPX data listed in GeoPlayer, and the client app use that location/motion data as if they are coming from GPS and M7.

## GeoFake.framework

Simulate Location and Motion information for Debugging iOS apps. GeoFake framework works with GeoPlayer.

GeoFake website: https://newtonjapan.com/GeoPlayer/repeat-location-motion
Framework and source code: https://github.com/AlohaYos/GeoFake
