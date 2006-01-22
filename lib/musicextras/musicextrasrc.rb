###############################
#### Musicextras config file
###############################
@config = MusicExtras::MConfig.instance

############################
#### Client Configuration
############################

## Base dir to keep musicextra data in
@config['basedir'] = File.join(ENV['HOME'], '.musicextras')

## Log plugin output?
@config['log'] = true

## When true, musicextras will output warnings when you haven't provided enough
## information to fetch a piece of data
@config['verbose'] = false

## Timeout for http retrieves.  Increase this if you are prone to timeouts
@config['timeout'] = 90

## Time greylist entries remain valid.  Set to nil if you don't want greylist
## entries to timeout.  Times are in seconds.  DAY, WEEK, and MONTH can be used.
@config['greylist_timeout'] = MusicExtras::MONTH

## What information should be fetched? Use musicextras --list-fetchers for a list
## Defaults to all available fetchers
#@config['fetchers'] = %w(lyrics synced_lyrics artist_image album_cover biography years_active album_review album_tracks album_year)

## What plugins should be used? Use musicextras --list-plugins for a list
## Defaults to all available plugins
#@config['plugins'] = %w(Atame Allofmp3 Lrcdb LyricsDomain LyricsTime Plyrics AllMusic LyricsNe )

# Save and load data from cache (if false, fetches data every time)
@config['use_cache'] = true

## Host:Port for GUI to use for data exchange with the client
@config['gui_host'] = 'localhost:1665'

## URL to get plugin updates from
@config['updateurl'] = 'http://divineinvasion.net/musicextras/plugins'

## Substitutions called on Artist's names before any pages are fetched
## The first item is the regexp to apply, the second is the replacement text.
## \1 \2 \3 etc reference any text captured by ()s in the first regexp
@config['artist_pre_regex'] = [
  [/Tom Petty.*/, 'Tom Petty']
]

## Substitutions called on an Artist's name if no pages could be found
## Same regexp rules from above apply
@config['artist_cond_regex'] = [
  [/^The\s/i, ''],
  [/^(?!The\s)(.*)/i, 'The \1']
]

## Substitutions called on Album name before anything is fetched
@config['album_pre_regex'] = [
  [/20 Percent Of My Hand/i, 'Twenty Percent of my Hand']
]

#########################
#### GUI Configuration
#########################

## Default size for GUI windows
@config['window_w'] = 625
@config['window_h'] = 500

## Size for GUI to scale images to (Aspect ratio will be kept)
@config['image_size'] = 200

## Program to run for editing text. %s is replaced with the filename
@config['editor'] = "/usr/bin/gvim %s"
