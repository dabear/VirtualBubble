# BluetoothTester
This app is only suitable for people with general knowhow about xcode and libre sensors. It is not means for the general public

# How It works
It runs on your mac as a command line app. 
When started, it fakes a bubble cgm reader bluetooth profile, and responds to any requests with a predefined libre 1 FRAM
Every five minutes, every central connected will be woken up. A connected central is then expected to ask for sensordata 

# Prerequisite
Your Mac's local hostname *must* renamed to "Bubble_fake1" before you continue. To do so:
On your Mac, choose Apple menu > System Preferences, then click Sharing. Open Sharing preferences.
Type a new name in the Computer Name field. "Bubble_fake1" is what you should enter. You may need to click the lock icon and provide an administrator name and password before you can change the name.
You may have to toggle bluetooth on and off or reboot your computer for this to work reliably

# Installation and running the app
Only source code is provided. You should open the source code in xcode and go to BluetoothTester->targets->BluetoothTester and change the "Team" under "Signing and capabilities" to your own
Then run the app in xcode on "My Mac"

# Interacting with the bluetooth service
Open any compatible bluetooth app on an iphone or android and connect.
