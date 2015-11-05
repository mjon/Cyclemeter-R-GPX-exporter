library (RSQLite)

# handy sqLiteConnect function from http://stackoverflow.com/questions/26824540/loading-sqlite-table-in-r-with-rsqlite
sqLiteConnect <- function(database, table) {
  library(DBI)
  library(RSQLite)
  con <- dbConnect(RSQLite::SQLite(), dbname = database)
  query <- dbSendQuery(con, paste("SELECT * FROM ", table, ";", sep="")) 
#  result <- fetch(query, n = -1, encoding="utf-8")
  result <- fetch(query, n = -1) # utf-8 gives error
  dbClearResult(query)
  dbDisconnect(con)
  return(result)
}

# load in the whole Cyclemeter database, called Meter.db. (I download it from my iPhone using the PhoneView Mac app, http://www.ecamm.com/mac/phoneview/. iTunes should also work.)
cyclemeter <- dbConnect(RSQLite::SQLite(), "data/Meter.db")

# list all of the tables
cyclemeter_tables <- dbListTables (cyclemeter)
cyclemeter_tables

# extract out each table as a separate R object
for (i in 1:length(cyclemeter_tables)){
	assign (cyclemeter_tables[i], sqLiteConnect("data/Meter.db",cyclemeter_tables[i]))
}

# a lot of these tables contain competitive cycling information that I don't use. For each track, I just want the date-time, coordinates, accuracy, travel mode, and trip name.

# activity
# This links activityID to activityTypeID

# activityType
# this contains the base information on each type of activity in the database (cycle, run, drive, etc., although these aren't named here). There are 23 named activity types on the app and only 20 listed in this table. Some IDs must be used for more than one named activity. I will have to compared known trips to activityTypes to callibrate this.

# altitude
# contains all of the altitude measurements (and timeOffset) for each sequenceID from each runID. I doubt these are very accurate but they're worth extracting in case they're of some use.

# coordinate
# this is the big one, containing the latitude, longitude, and timeOffset for each sequenceID from each runID. It also contains distanceDelta and speed, which may be of use.

# route
# contains all of my named routes, with routeID and name

# run
# this connects the runID to the associated routeID and activityID. It also contains the startTime, startTimeZone, runTime, stoppedTime, badGPSTime, distance, ascent, descent, maxSpeed

# stopDetection
# I'm not quite sure what this means, but it's used by the python script on Github to bulk make GPX files from a Cyclemeter database. It assigns an action value (one of 0,1,2,3) to each sequenceID from each runID. It's not immediately clear what these action values signify.

# simplify these down to just the fields I need...

my.altitude <- altitude [,c("runID", "sequenceID", "timeOffset", "altitude")]
my.coordinate <- coordinate
my.route <- route [,c("routeID","name")]
my.run <- run [,c("runID", "routeID", "activityID", "startTime", "startTimeZone", "runTime", "stoppedTime", "badGPSTime", "distance", "ascent", "descent", "maxSpeed", "minPace")]
my.stopDetection <- stopDetection
my.activityType <- activityType
my.activity <- activity [,c("activityID","activityTypeID", "activityNameID")]

# the data is structured with a "startTime" in the "run" table and a "timeOffset" in the "coordinate" table.
# to include time through the GPX file track, each coordinate needs its own time stamp.
# to do this, we need to get the start time into R's date-time format so the time offset can be added to it for each coordinate

my.run$startDate <- sub ("^([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) .+$", "\\1", my.run$startTime)
my.run$startTimeOnly <- sub ("^([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) (.+)$", "\\2", my.run$startTime)
# it looks like as.POSIXct wants time in HH:MM:SS exactly. Trim off startTimeOnly to match this.
my.run$startTimeOnly <- sub ("^([0-9]+:[0-9]+:[0-9][0-9]).+$", "\\1", my.run$startTimeOnly)

# "startTime" in "run" in Cyclemeter is GMT and the time zone is in "startTimeZone"

# convert the start time to an R POSIXct object
my.run$startDateTimeGMT <- as.POSIXct (paste(my.run$startDate, my.run$startTimeOnly), tz = "GMT")

# now adjust to NZST and PST (the only two time zones I have GPS tracks for).
# you'll need to adjust this for your time zones
my.run$startTimeLocalTimeZone <- NA
my.run$startTimeLocalTimeZone [my.run$startTimeZone == "America/Los_Angeles"] <- paste (format (my.run$startDateTimeGMT [my.run$startTimeZone == "America/Los_Angeles"], tz = "America/Los_Angeles"), "PDT")
my.run$startTimeLocalTimeZone [my.run$startTimeZone == "Pacific/Auckland"] <- paste (format (my.run$startDateTimeGMT [my.run$startTimeZone == "Pacific/Auckland"], tz = "Pacific/Auckland"), "NZDT")

# after far too long banging my head against R, I've given up trying to mix time zones in one POSIXct variable. I've come to the conclusion that it's not possible. It's not necessary for the GPX anyway.

# the Cyclemeter tables do not contain the names of each activity type.
# after looking at my route names, I worked out the following. These are just the activity types I use. There are more options in Cyclemeter. You'll have to work out any additional activities you use.
my.activity$activityName <- NA
my.activity$activityName  [my.activity$activityID == 1 ] <- "Run"
my.activity$activityName  [my.activity$activityID == 2 ] <- "Walk"
my.activity$activityName  [my.activity$activityID == 4 ] <- "Cycle"
my.activity$activityName  [my.activity$activityID == 10 ] <- "Drive"
my.activity$activityName  [my.activity$activityID == 255 ] <- "Sailing"

# none of the exisiting write GPX functions I found for R were complete enough, or legible enough, to do what I wanted.
# in the end it was quicker to just reconstruct the GPX export files from Cyclemeter app

# to make the syntax easier for this loop, I merge together all of the relevant objects into one.
my.cyclemeter <- merge (my.coordinate, my.altitude, by = c("runID", "sequenceID"), all.x = TRUE, all.y = FALSE)
my.cyclemeter <- merge (my.cyclemeter, my.run, by = "runID", all.x = TRUE, all.y = FALSE)
my.cyclemeter <- merge (my.cyclemeter, my.route, by = "routeID", all.x = TRUE, all.y = FALSE)
my.cyclemeter <- merge (my.cyclemeter, my.activity, by = "activityID", all.x = TRUE, all.y = FALSE)
my.cyclemeter <- merge (my.cyclemeter, my.activityType, by = "activityTypeID", all.x = TRUE, all.y = FALSE)
my.cyclemeter <- merge (my.cyclemeter, my.stopDetection, by = c("runID", "sequenceID"), all.x = TRUE, all.y = FALSE)

# calculate the date time for each coordinate
my.cyclemeter$coorddatetimeGMT <- my.cyclemeter$startDateTimeGMT + my.cyclemeter$timeOffset.x

# convert coordinate time to local time zone
# again, note that I've only got tracks from NZST and PDT. Add the ones you need.
my.cyclemeter$coorddatetimeLocalTimeZone <- NA
my.cyclemeter$coorddatetimeLocalTimeZone [my.cyclemeter$startTimeZone == "America/Los_Angeles"] <- paste (format (my.cyclemeter$coorddatetimeGMT [my.cyclemeter$startTimeZone == "America/Los_Angeles"], tz = "America/Los_Angeles"), "PDT")
my.cyclemeter$coorddatetimeLocalTimeZone [my.cyclemeter$startTimeZone == "Pacific/Auckland"] <- paste (format (my.cyclemeter$coorddatetimeGMT [my.cyclemeter$startTimeZone == "Pacific/Auckland"], tz = "Pacific/Auckland"), "NZDT")

# save it all out, just in case
write.csv (my.cyclemeter, file = "results/my.cyclemeter.spreadsheet.csv", row.names = FALSE)

# loop through each event (runID) making a GPX file of each
events <- unique (my.cyclemeter$runID)
for (i in 1:length(events)){
	source ("scripts/make GPX file.R")
}
