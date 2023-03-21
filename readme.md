## mp3cover
Code exports the mp3 cover art, if present, to a temp folder 'cover'\
as a bonus an attempt is made to get the image dimensions of the\
exported jpeg or png. A csv report as output can alternatively be\
used with an sql variant db.
## usage
mp3cover.exe <file> single file or <path> ex. <g:\data\mp3\soul food>" \
for multiple mp3 files the path is scanned recursively"\
/? or -man shows above help 
## requirements
freebasic
## performance
windows 7 / windows 10(1903)\
ram usage ~2MB / 2MB\
handles   ~120 / ~200\
threads   4 / 7\
cpu       ~1 (low) / ~2\
tested on intel i5-6600T
## navigation
cli keyboard
## example report output
after scanning a folder:\
scanning and exporting mp3 covers(s)....\
no cover found in james ingram and michael mcdonald - yah mo b there\
no cover found in julian lennon - too late for goodbyes\
no cover found in nik kershaw - human racing\
...\
h: 298 / w: 300 - g:\data\mp3\10am\alison krauss & union station - find my way back to my heart.mp3\
h: 360 / w: 480 - g:\data\mp3\10am\annie lennox - waiting in vain.mp3\
h: 497 / w: 500 - g:\data\mp3\10am\bagdad cafe - calling you.mp3\
...\
thumbnail in g:\data\mp3\70s schmaltz\don mclean - american pie.mp3\
thumbnail in g:\data\mp3\70s schmaltz\elton john and kiki dee - dont go breaking my heart.mp3\
...\
coverart not square w: 320 / h: 180 - g:\data\mp3\70s schmaltz\andrew gold - never let her slip away.mp3\
...\
finished scanning 65 file(s)\
exported 54 covers(s) to f:\dev\freebasic\projects\mp3\cover
