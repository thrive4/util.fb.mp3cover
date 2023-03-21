' export cover art if present in mp3 file jan 2023 by thrive4
' info https://en.wikipedia.org/wiki/ID3
' exif jpeg needs more research    
' progressive DCT-based JPEG if instr(chunk, CHR(&hFF, &hC2)) > 0 then
' baseline DCT-based JPEG if instr(chunk, CHR(&hFF, &hC0)) > 0 then
' needs more research
' see http://home.elka.pw.edu.pl/~mmanowie/psap/neue/1%20JPEG%20Overview.htm
' and https://www.media.mit.edu/pia/Research/deepview/exif.html
' usefull tool for importing csv https://sqlitebrowser.org/

' dir function and provides constants to use for the attrib_mask parameter
#include once "vbcompat.bi"
#include once "dir.bi"

dim filename    as string
dim tempfolder  as string = exepath + "\cover"
dim listitem    as string
dim maxitems    as integer = 0
dim itemnr      as integer = 0
dim f           as integer
dim chk         as boolean
dim nocover     as string = ""
common shared coverwidth    as integer
common shared coverheight   as integer
common shared report        as string
common shared thumbnail     as string
common shared layout        as string
common shared csv           as string
csv = "'filename', 'width', 'height', 'thumbnail'" + chr$(13) + chr$(10)
report    = ""
thumbnail = ""
 
' parse arguments
dim as boolean validarg = false
if command(1) = "/?" or command(1) = "-man" or command(1) = "" then
    print "export cover art from mp3 file(s)"
    print "usage: mp3cover <file> single file or <path> ex. <g:\data\mp3\soul food>"
    print "       for multiple mp3 files the path is scanned recursively"    
    print "       an additional mp3cover.csv is generated for futher analysis"    
    sleep
    end
end if
select case true
    case instr(command(1), ".mp3") > 0
        validarg = true
    case instr(command(1), "\") > 0
        validarg = true
    case else
        print "error: invalid switch " + command(1) + " valid switches are file or path"
        sleep
        end
end select

' attempt to extract and write cover art of mp3 to temp thumb file
Function getmp3cover(filename As String, temp as string) As boolean
    Dim buffer  As String
    dim chunk   as string
    dim length  as string
    dim bend    as integer
    dim ext     as string = ""
    dim image   as string
    dim thumb   as integer = 0
    report = ""
    Open filename For Binary Access Read As #1
        If LOF(1) > 0 Then
            buffer = String(LOF(1), 0)
            Get #1, , buffer
        End If
    Close #1
    if instr(1, buffer, "APIC") > 0 then
        length = mid(buffer, instr(buffer, "APIC") + 4, 4)
        ' ghetto check funky first 4 bytes signifying length image
        ' not sure how reliable this info is
        ' see comment codecaster https://stackoverflow.com/questions/47882569/id3v2-tag-issue-with-apic-in-c-net
        if val(asc(length, 1) & asc(length, 2)) = 0 then
            bend = (asc(length, 3) shl 8) or asc(length, 4)
        else
            bend = (asc(length, 1) shl 24 + asc(length, 2) shl 16 + asc(length, 3) shl 8 or asc(length, 4))
        end if
        ' get image dimensions jpg
        ' aided by https://www.freebasic.net/forum/viewtopic.php?t=21922&hilit=instr+hex+search&start=15
        ' and https://stackoverflow.com/questions/18264357/how-to-get-the-width-height-of-jpeg-file-without-using-library
        if instr(1, buffer, "JFIF") > 0 then
            ' override end jpg if marker FFD9 is present
            if instr(buffer, CHR(&hFF, &hD9)) > 0 then
                bend = instr(1, mid(buffer, instr(1, buffer, "JFIF")), CHR(&hFF, &hD9)) + 7
            end if
            chunk = mid(buffer, instr(buffer, "JFIF") - 6, bend)
            ' thumbnail detection
            if instr(instr(1, buffer, "JFIF") + 4, buffer, "JFIF") > 0 then
                thumbnail = thumbnail + "thumbnail in " + filename + chr$(13) + chr$(10)
                thumb = 1
                chunk = mid(buffer, instr(10, buffer, CHR(&hFF, &hD8)), instr(instr(buffer, CHR(&hFF, &hD9)) + 1, buffer, CHR(&hFF, &hD9)) - (instr(10, buffer, CHR(&hFF, &hD8)) - 2))
                ' thumbnail in thumbnail edge case ffd8 ffd8 ffd9 ffd9 pattern in jpeg
                if instr(chunk, CHR(&hFF, &hD8, &hFF)) > 0 then
                    chunk = mid(buffer,_
                    instr(1,buffer, CHR(&hFF, &hD8)),_
                    instr(instr(instr(instr(1,buffer, CHR(&hFF, &hD9)) + 1, buffer, CHR(&hFF, &hD9)) + 1, buffer, CHR(&hFF, &hD9))_
                    , buffer, CHR(&hFF, &hD9)) + 2 - instr(buffer, CHR(&hFF, &hD8)))
                end if
            end if
            if instr(chunk, CHR(&hFF, &hC2)) > 0 then
                coverwidth  = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 7, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 8, 1)))
                coverheight = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 5, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 6, 1)))
            else
                coverwidth  = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 7, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 8, 1)))
                coverheight = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 5, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 6, 1)))
            end if
            ext = ".jpg"
        end if
        ' use ext and exif check to catch false png
        if instr(1, buffer, "‰PNG") > 0 and instr(1, buffer, "Exif") = 0 and ext = "" then
            ' override end png if tag is present
            if instr(1, buffer, "IEND") > 0 then
                bend = instr(1, mid(buffer, instr(1, buffer, "‰PNG")), "IEND") + 7
            end if
            chunk = mid(buffer, instr(buffer, "‰PNG"), bend)
            ' get image dimensions png
            ' aided by see post by Ry- https://stackoverflow.com/questions/15327959/get-height-and-width-dimensions-from-base64-png
            ' and https://www.w3.org/TR/PNG-Chunks.html
            ' width
            length = mid(chunk, instr(chunk, "IHDR") + 4, 4)
            if val(asc(length, 1) & asc(length, 2)) = 0 then
                coverwidth  = cint("&H" + hex(asc(length, 3)) & hex(asc(length, 4)))
            else
                coverwidth  = cint("&H" + hex(asc(length, 1)) & hex(asc(length, 2)) & hex(asc(length, 3)) & hex(asc(length, 4)))
            end if
            ' height
            length = mid(chunk, instr(chunk, "IHDR") + 8, 4)
            if val(asc(length, 1) & asc(length, 2)) = 0 then
                coverheight = cint("&H" + hex(asc(length, 3)) & hex(asc(length, 4)))
            else
                coverheight = cint("&H" + hex(asc(length, 1)) & hex(asc(length, 2)) & hex(asc(length, 3)) & hex(asc(length, 4)))
            end if
            ext = ".png"
        end if
        ' funky variant for non jfif and jpegs video encoding?
        if (instr(1, buffer, "Lavc58") > 0 or instr(1, buffer, "Exif") > 0) and ext = "" then
            ' override end jpg if marker FFD9 is present
            if instr(buffer, CHR(&hFF, &hD9)) > 0 then
                bend = instr(1, mid(buffer, instr(1, buffer, "Exif")), CHR(&hFF, &hD9)) + 7
            end if
            if instr(1, buffer, "Exif") > 0 then
                chunk = mid(buffer, instr(buffer, "Exif") - 6, bend)
            else
                chunk = mid(buffer, instr(buffer, "Lavc58") - 6, bend)
            end if
            if instr(chunk, CHR(&hFF, &hC2)) > 0 then
                coverwidth  = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 7, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 8, 1)))
                coverheight = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 5, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 6, 1)))
            else
                coverwidth  = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 7, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 8, 1)))
                coverheight = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 5, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 6, 1)))
            end if
            ext = ".jpg"
        end if
        ' last resort just check on begin and end marker very tricky...
        ' see https://stackoverflow.com/questions/4585527/detect-end-of-file-for-jpg-images#4614629
        if instr(buffer, CHR(&hFF, &hD8)) > 0 and ext = "" then
            chunk = mid(buffer, instr(1, buffer, CHR(&hFF, &hD8)), instr(1, buffer, CHR(&hFF, &hD9)))
            ext = ".jpg"
            if instr(chunk, CHR(&hFF, &hC2)) > 0 then
                coverwidth  = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 7, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 8, 1)))
                coverheight = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 5, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC2)) + 6, 1)))
            else
                coverwidth  = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 7, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 8, 1)))
                coverheight = ((asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 5, 1)) shl 8) or asc(mid(chunk, instr(chunk, CHR(&hFF, &hC0)) + 6, 1)))
            end if
        end if
        buffer = ""
        Close #1
        ' attempt to write coverart to temp file
        if ext <> "" then
            image = exepath + "\cover\" + temp + ext
            open image for Binary Access Write as #1
                put #1, , chunk
            close #1
        else
            ' optional use folder.jpg if present as thumb
        end if
        ' report check for square layout with tolerance
        if coverwidth > 0 and coverheight > 0 then
            select case coverwidth / coverheight
                case is > 1.1
                    layout = layout + "coverart not square " + "w: " & coverwidth  & " / h: " & coverheight & " - " & filename + chr$(13) + chr$(10)
                case is < 0.9
                    layout = layout + "coverart not square " + "w: " & coverwidth  & " / h: " & coverheight & " - " & filename + chr$(13) + chr$(10)
            end select
            'print filename + "w" & coverwidth & " h" & coverheight & " ratio " & coverwidth / coverheight
        end if   
        report = report + "w: " & coverwidth
        report = report + " / h: " & coverheight
        report = report + " - " + filename
        csv = csv + chr$(34) + filename + chr$(34) + "," & coverwidth & "," & coverheight & "," & thumb & chr(13) + chr$(10)
        print report

        return true
    else
        return false
        ' no thumb generated remove old thumb if present
        'delfile(exepath + "\thumb.jpg")
        'delfile(exepath + "\thumb.png")
    end if
end function

function createlist(folder as string, filterext as string, listname as string) as integer
    ' setup filelist
    dim chk as boolean
    redim path(1 to 1) As string
    dim as integer i = 1, n = 1, attrib
    dim file as string
    dim fileext as string
    dim maxfiles as integer
    dim f as integer
    f = freefile
    dim filelist as string = exepath + "\" + listname + ".tmp"
    open filelist for output as #f

    #ifdef __FB_LINUX__
      const pathchar = "/"
    #else
      const pathchar = "\"
    #endif

    ' read dir recursive starting directory
    path(1) = folder 
    if( right(path(1), 1) <> pathchar) then
        file = dir(path(1), fbNormal or fbDirectory, @attrib)
        if( attrib and fbDirectory ) then
            path(1) += pathchar
        end if
    end if

    while i <= n
    file = dir(path(i) + "*" , fbNormal or fbDirectory, @attrib)
        while file > ""
            if (attrib and fbDirectory) then
                if file <> "." and file <> ".." then
                    n += 1
                    redim preserve path(1 to n)
                    path(n) = path(i) + file + pathchar
                end if
            else
                fileext = lcase(mid(file, instrrev(file, ".")))
                if instr(1, filterext, fileext) > 0 and len(fileext) > 3 then 
                    print #f, path(i) & file
                    maxfiles += 1
                else
                    'logentry("warning", "file format not supported - " + path(i) & file)
                end if    
            end if
            file = dir(@attrib)
        wend
        i += 1
    wend
    close(f)

    ' chk if filelist is created
    if FileExists(filelist) = false then
        print "could not create filelist: " + filelist
        exit function
    end if
    
    ' setup base shuffle and reduce probability
    dim lastitem as string = exepath + "\" + listname + ".lst"
    
    return maxfiles

end function

' export covers to jpeg or png file(s)
mkdir (tempfolder) ' create export folder regardless
print "scanning and exporting mp3 covers(s)...."
if instr(command(1), ".mp3") > 0 then
    filename = lcase(mid(command(1), instrrev(command(1), "\") + 1))
    filename =  lcase(mid(filename, 1, instr(filename, ".") - 1))
    getmp3cover(command(1), filename)
    itemnr = 1
else
    createlist(command(1), ".mp3", "cover")
    open "cover.tmp" for input as 10
    Do Until EOF(10)
        Line Input #10, listitem
        filename = lcase(mid(listitem, instrrev(listitem, "\") + 1))
        filename =  lcase(mid(filename, 1, instrrev(filename, ".") - 1))
        if getmp3cover(listitem, filename) then
            itemnr += 1
        else
            nocover = nocover + "no cover art found in " + filename + chr$(13) + chr$(10)
            csv = csv + chr$(34) + command(1) + "\" + filename + chr$(34) + ",0,0" + chr$(13) + chr$(10)
        end if
        listitem = ""
        maxitems += 1
    loop
    close 10
    ' cleanup listplay files
    If Kill(exepath + "\cover.tmp") <> 0 Then
        print "error deleting cover.tmp"
    end if
end if

' report to command line
print nocover
if thumbnail = "" then
    print "no thumbnail(s) found in scanned files"
    print
else
    print thumbnail
end if
if layout = "" then
    print "all scanned file(s) are sqare"
    print    
else
    print layout
end if
print "finished scanning " & maxitems & " file(s)"
print "exported " & itemnr & " covers(s) to " + tempfolder

' export results as csv
open "mp3cover.csv" for output encoding "utf8" as #1
print #1, csv
close

end
