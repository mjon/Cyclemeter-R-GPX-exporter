# make a GPX file from one Cyclemeter trip
# this script is called from "cyclemeter database importer.R" and expects a value of i from its loop

# create a temp file containing just the data from event i
gpx.temp <- my.cyclemeter[my.cyclemeter$runID == events[i],]

# strip the time zone from the startTimeLocalTimeZone and coorddatetimeLocalTimeZone as GPX doesn't include it (or at least it doesn't in the GPX files Cyclemeter exports)
startTimeLocalTimeZone.temp <- sub ("^(.+) [A-Z]+$", "\\1", gpx.temp$startTimeLocalTimeZone[1])
coorddatetimeLocalTimeZone.temp <- sub ("^(.+) [A-Z]+$", "\\1", gpx.temp$coorddatetimeGMT)

# note that GPX expect all of the coordinate date times to be in GMT
#  the date times in the meta data are more informative as the local time

# specify the path to the file to be created
mainfile <- paste("results/GPX_files/", gsub (" ", "_", gsub(":", "-", startTimeLocalTimeZone.temp)), ".gpx", sep = "")

# load in the header premable text
gpx.header<- readLines ("resources/gpx header.txt")

# now construct and add each other line to the GPX file

writeLines (gpx.header, con = mainfile) # note that writeLines uses "con =" where other functions use "file =".

cat ("<name>", gsub (" ", "_", gsub(":", "-", startTimeLocalTimeZone.temp)), ".gpx</name>", file = mainfile, sep = "", append = TRUE)
cat ("\n<desc>Cyclemeter ", gpx.temp$activityName[1], " ", startTimeLocalTimeZone.temp, "</desc>", file = mainfile, sep = "", append = TRUE)
cat ("\n<author><name>User data from Cyclemeter app</name></author>", file = mainfile, sep = "", append = TRUE)
cat ("\n<link href=\"http://www.cyclemeter.com\">", file = mainfile, sep = "", append = TRUE)
cat ("\n<text>Abvio Cyclemeter GPS track</text>", file = mainfile, sep = "", append = TRUE)cat ("\n<type>text/html</type>", file = mainfile, sep = "", append = TRUE)
cat ("\n</link>", file = mainfile, sep = "", append = TRUE)
cat ("\n<time>", gsub(" ", "T", startTimeLocalTimeZone.temp), "Z</time>", file = mainfile, sep = "", append = TRUE)
cat ("\n<keywords>Abvio, Cyclemeter, Unofficial R translator, ", gpx.temp$activityName[i], "</keywords>", file = mainfile, sep = "", append = TRUE)
cat ("\n<bounds minlat=\"", min(gpx.temp$latitude), "\" minlon=\"", min(gpx.temp$longitude), "\" maxlat=\"", max(gpx.temp$latitude), "\" maxlon=\"", max(gpx.temp$longitude), "\"/>", file = mainfile, sep = "", append = TRUE)
cat ("\n</metadata>", file = mainfile, sep = "", append = TRUE)cat ("\n<trk>", file = mainfile, sep = "", append = TRUE)cat ("\n<name><![CDATA[", gpx.temp$name[i], "]]></name>", file = mainfile, sep = "", append = TRUE)cat ("\n<type><![CDATA[", gpx.temp$activityName[i], "]]></type>", file = mainfile, sep = "", append = TRUE)cat ("\n<trkseg>", file = mainfile, sep = "", append = TRUE)
for (j in 1:nrow(gpx.temp)){
cat ("\n<trkpt lat=\"", gpx.temp$latitude[j], "\" lon=\"", gpx.temp$longitude[j], "\"><ele>", round(gpx.temp$altitude[j],1), "</ele><time>", gsub(" ", "T", coorddatetimeLocalTimeZone.temp[j]), "Z</time></trkpt>", file = mainfile, sep = "", append = TRUE)
}
cat ("\n</trkseg>", file = mainfile, sep = "", append = TRUE)cat ("\n</trk>", file = mainfile, sep = "", append = TRUE)
cat ("\n</gpx>", file = mainfile, sep = "", append = TRUE)

# flush gpx.temp just in case the loop malfunctions
gpx.temp <- NA
