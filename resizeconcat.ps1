$wpath = 'D:/videoprocess/'
$opath = 'D:/output_video.mp4'
$spath = $wpath+'send.conv'
$ppath = $wpath+'pl.conv'
$mheight = 1080

[single]$sum = 0.0
Remove-Item $ppath, $spath -ErrorAction SilentlyContinue
foreach ($file in (Get-ChildItem $wpath -Include *.mp4,*.avi,*.mts,*.m2ts,*.mov -name | Sort-Object)) {
    "file $file" >> $ppath
    $date = $file.substring(0,8)
    [int]$width, [int]$height, [single]$duration, [int]$angle = `
        ffprobe -loglevel error -select_streams v:0 `
                -show_entries stream_tags=rotate:stream=duration`,height`,width `
                -of default=nw=1:nk=1 $wpath$file
    $scale  = if (($angle -eq 90) -or ($angle -eq 270)){$mheight/$width} else {$mheight/$height}
    $width  = [math]::floor($width*$scale)
    $height = [math]::floor($height*$scale)
    "$sum scale w $width, h $height, rotate a 'PI*$angle/180', drawtext reinit 'text=$date';" >> $spath
    $sum += $duration
}

Get-ChildItem $wpath -Include *.conv -recurse | ForEach-Object {
    $contents = [IO.File]::ReadAllText($_) -replace "`r`n?", "`n"
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($_, $contents, $utf8)
}

ffmpeg.exe `
    -noautorotate -f concat -safe 0 -i $ppath `
    -filter_complex "yadif=0:-1:1, sendcmd=f='$spath',scale=-1:$mheight`:force_original_aspect_ratio=decrease,rotate,`
    drawtext=text=:x=10:y=10:fontsize=25:fontcolor=Red:fontfile='C\:\\Windows\\Fonts\\arial.ttf'" `
    -c:v libx264 -preset slow -crf 25 -pix_fmt yuv420p -maxrate 5M -bufsize 10M -profile:v high -level 4.0 -r 25 `
    -c:a aac -ac 2 -b:a 96k -ar 44100 `
    $opath
Read-Host -Prompt "Press Enter to exit"
