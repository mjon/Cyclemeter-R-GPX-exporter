# Cyclemeter R GPX exporter

## BACKGROUND

Cyclemeter (http://abvio.com/cyclemeter/) is a terrific GPS tracking app for iPhone. I use it to track pretty much everywhere I go and connect the GPS tracks to my photos and nature observations.

Cyclemeter has one flaw for me and that is the inability to export all of the tracks as GPX files. You can only export one at a time on the iPhone, and it takes a few clicks per track. I use the GPX track for geotagging the photos from my DSLR. I'd rather save my time and batch export the GPX files.

Also, my old iPhone was starting to get slowed down by the thousands of tracks I'd accumulated and I needed to clear out the app and start again, but still needed the option of exporting GPX tracks from some of my old trips.

## HOW TO USE

Before running this, make sure the Cyclemeter app is closed on your computer and connect it to your favourite download app on your computer (iTunes should work, but I prefer the simpler and more useful PhoneView Mac app, http://www.ecamm.com/mac/phoneview/). Download the Cyclemeter database, Meter.db, from your phone. Put it inside the "data" folder of this R script.

Double-click on the "cyclemeter database importer.R" script. The working directory in R needs to be the folder where this script it. It will be by default if you launch R by double-clicking on the script. This script opens up Meter.db, does some formatting, then runs a loop to make a GPX of each trip in the database. The GPX files are saved in the results/GPX_files folder.

For this to work, all you'll need R (http://r-project.org) and you'll need to add the package RSQLite (using the Package Installer in R).

## CUSTOMISATION

If you look inside the script, you'll see that it is only set to deal with the time zones I use (Pacific/Auckland and America/Los_Angeles). If that's not where you are, you'll need to add your time zones.

Also, Meter.db doesn't have the names of each activity type, just the activityTypeID. I figured out what these were for my activities (1 = Run, 2 = Walk, 4 = Cycle, 10 = Drive, 255 = Sailing). If your Meter.db has other activityTypeID values, you'll need to figure out what those are by looking at some of your example trips on your iPhone.

#ATTRIBUTION

The R scripts are creative commons attribution 4.0. Do what you like with them.

I've included an example Meter.db database with a couple of my trips. The structure of this database will be copyright Abvio (http://abvio.com/), the makers of Cyclemeter.

Jon.J.Sullivan@me.com

I've blogged about this at http://jonsullivan.canterburynature.org/?p=601
