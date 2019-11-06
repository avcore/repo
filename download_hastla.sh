#!/bin/bash
#скрипт для скачивания музыкальной дорожки или видео с ютуба.
#Можно качать с любого ресурса который поддерживает youtube-dl.
#для работы необходимо установить youtube-dl и ffmpeg.
#youtube-dl из репозитория не заработает так что лучше скачивать исходники с github 
#var
downloader=`which youtube-dl`
ffmpeg=`which ffmpeg`
bitrate=192000
ARGC=$#
LINK=$1
SAVEDFILE=$(basename $0)_download.mp4
is_exec_option=0
path_to_music_falder="/home/alex/Music/"
path_to_video_falder="/home/alex/Video/"
#functions
function init(){
    LINK_CUT=`echo $LINK | cut -d '&' -f 1 `
    FILENAME="$(youtube-dl $LINK_CUT -e)"
}

function lazy_init(){
    if [[ -z "$LINK_CUT" ]]
        then
        init
    fi
}

function check_song(){
    lazy_init
    if test -f "$path_to_music_falder$FILENAME"
        then
        return 0
    else 
        return 1
    fi
}

function check_video(){
    lazy_init
    if test -f "$path_to_video_falder$FILENAME.mp4"
        then
        return 0
    else 
        return 1
    fi
}

function download_song(){
    if check_song 
        then 
        echo "song file ($FILENAME) already downloaded"
    else
        cd $path_to_music_falder
        $downloader -f 18 $LINK_CUT -o "$SAVEDFILE"  &&  $ffmpeg -i "$SAVEDFILE" -f mp3 -ab $bitrate -vn "$FILENAME" 
        if [ $? -eq 0 ];
            then
            echo "File saved in " $FILENAME
            rm "$SAVEDFILE"
        else
            echo "error while seving file"
            exit 1
        fi
    fi
}

function download_video(){
    cd $path_to_video_falder
    if check_video
        then 
        echo "video file already downloaded"
    else
        $downloader -f 18 $LINK_CUT -o "$SAVEDFILE" 
        if [ $? -eq 0 ];
            then
            mv "$SAVEDFILE" "$FILENAME.mp4"
            echo "File saved in " $FILENAME
        else
            echo "error while seving file"
            exit 1
        fi
    fi
}

function download_song_and_video(){
    download_song
    download_video
}

function check_files(){
    lazy_init
    if check_song
        then
        echo "music file exist"
    else 
        echo "music file not exist"
    fi
    if check_video
        then
        echo "video file exist"
    else 
        echo "video file not exist"
    fi
    echo "хотите скачать видео $FILENAME" 
    echo "1:музыкальную дорожку"
    echo "2:видео файл"
    echo "3:все вместе "
    echo "4:выход"
    read answer
    case $answer in
        1)
            download_song
            shift;;
        2)
            download_video
            shift;;
        3)
            download_song_and_video
            shift;;
        4)
            exit 0
            shift;;
    esac
}

function check(){
    lazy_init
    if check_song
        then
        echo "music file exist"
    else 
        echo "music file not exist"
    fi
    if check_video
        then
        echo "video file exist"
    else 
        echo "video file not exist"
    fi
}

function convert2mkv(){
    ffmpeg -i "$FILENAME.mp4" "$FILENAME.mkv"
    if [ $? -eq 0 ]
        then
        echo "convert error"
        exit 1
    fi
    rm "$FILENAME.mp4"
}

function show_help(){
    echo "usage: ds url_to_youtube_video -flags"
    echo "Пример: скачивание музыкальной дорожки. ds "url" -s. все остальное по аналогии"
    echo "если не указать флаги скрипт проверить было ли скачано данное видео и спросит что сделать"
    echo "-c|-check) проверить существование файлов"
    echo "-s|-song) скачать аудио файл"
    echo "-v|-video) скачать видео файл"
    echo "-f|-full) скачать и видео и аудио файл"
    echo "-vm|-v-mkv) скачать видео в расширение mkv"
    echo "путь до папки с музыкой $path_to_music_falder"
    echo "путь до папки с видео $path_to_video_falder"
    echo "author: Fedechkin Alexey"
}
#script
while  [ -n "$1" ]
	do 
	case "$1" in
        -h)
            show_help
            is_exec_option=1
			shift;;
        -help)
            show_help
            is_exec_option=1
			shift;;
        -c)
            check
            is_exec_option=1
            shift;;
         -check)
            check
            is_exec_option=1
            shift;;
		-v) 
            download_video
            is_exec_option=1
			shift;;
        -video) 
            download_video
            is_exec_option=1
			shift;;
        -vm)
            download_video
            convert2mkv
            is_exec_option=1
			shift;;
        -v-mkv)
            download_video
            convert2mkv
            is_exec_option=1
			shift;;
		-s)
            download_song
            is_exec_option=1
			shift;;
        -song) 
            download_song
            is_exec_option=1
			shift;;
		-f) 
            download_song_and_video
            is_exec_option=1
			shift;;
        -full) 
            download_song_and_video
            is_exec_option=1
			shift;;
	esac
	shift
done
if [ $is_exec_option  -eq 0 ]
    then
    check_files
fi
exit 0
