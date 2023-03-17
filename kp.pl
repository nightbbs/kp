#!/usr/bin/perl 
no warnings 'utf8';
use utf8;
use Encode;
use URI::Escape;
#use locale;
use JSON;
use Config::Tiny;
use Data::Dumper;
use Time::Out qw(timeout);
#binmode STDOUT, ':utf8';
$mpv = "mpv --hr-seek=no";
$sl = 'streamlink';
$config = Config::Tiny->read("$ENV{'HOME'}/.config/kp/kp.conf") or die;

$at = $config->{_}->{access_token};
$pq = $config->{kpc}->{preferred_quality};
$ps = $config->{kpc}->{preferred_stream};
$us = $config->{kpc}->{use_subliminal};
$cont = $config->{kpc}->{continuos_mode};

_curl("v1/user?");
my $numofdays = int($apiresp->{'user'}->{'subscription'}->{'days'} + 0.5);
system "figlet -f banner3 \" $numofdays\"";
@sub = ();
$a = 0;
$c = 0;
$n = 1;
$first = 1;
$items = 0;
#print Dumper \@ARGV;
$resume = 1 if ($ARGV[0] eq "-r");
$need_num = $ARGV[1];
$resume = 0 if ($ARGV[0] eq "");
if($resume == 1)
{
    open(resume_file, '<', "$ENV{'HOME'}/.config/kp/kp.resume") or die $!;
    while(<resume_file>) {
	if ($n == $need_num) {
	    @data = split(/\=|\,/, $_);
	    $quit = 0;
	    if ($data[1] =~ 'y') {
		$id = $data[0];
		_youtube();
	    }
	    if ($data[1] =~ 'm') {
		if($data[2]) {
		    $ver = $data[2];
		}
		$id = $data[0];
		_movie();
		_start();
		_file();
		_subs();
		_mpv2();
	    }
	    if ($data[1] =~ 's') {
		$id = $data[0];
		$season = $data[2];
		$seasonnum = $season + 1;
		$startuem = $data[3];
		_api();
		$serial = 1;
		_serial();
	    }
	}
	$n++;
    }
} else {
    while ($apiresp->{pagination}{total} == 0) {
	print "? > ";
	my $input = <STDIN>;
	chomp $input;
	$input =~ s/\ /+/g;
	if($input eq "!new"){
	    _curl("v1/items?type=movie");
 	    $items = $apiresp->{'pagination'}->{'perpage'};
	} else {
	    _curl("v1/items/search?q='$input'&perpage=200");
	    $items = $apiresp->{'pagination'}->{'total_items'};
	}
	if ($items > 0) {
	    while ($a < $items) {
		if (($apiresp->{'items'}[$a]->{'type'} eq "movie") or
		    ($apiresp->{'items'}[$a]->{'type'} eq 'documovie') or
		    ($apiresp->{'items'}[$a]->{'type'} eq 'concert')) {
		    print $a + 1, " - (*) ", $apiresp->{'items'}[$a]->{'title'};
		    $myfilm[$a] = $apiresp->{'items'}[$a]->{'id'};
		} else {
		    print $a + 1, " - ", $apiresp->{'items'}[$a]->{'title'};
		    $myfilm[$a] = $apiresp->{'items'}[$a]->{'id'};    # Это чтобы по номеру позиции в поиске выводился именно этот фильм
		}
		print " \($apiresp->{'items'}[$a]{'year'}\)" if($apiresp->{'items'}[$a]{'year'});
		print ", IMDB: $apiresp->{'items'}[$a]{'imdb_rating'}" if($apiresp->{'items'}[$a]{'imdb_rating'});
		print ", Kinopoisk: $apiresp->{'items'}[$a]{'kinopoisk_rating'}" if($apiresp->{'items'}[$a]{'kinopoisk_rating'});
		print ", Kinopub: $apiresp->{'items'}[$a]{'rating'}" if($apiresp->{'items'}[$a]{'rating'});
		print "\n";
		$a++;
	    }
	} else {
	    print "Нет такого\n";
	}
    }
    print "Какое? > ";
    my $input = <STDIN>;
    chomp $input;
    $input--;
    if(($apiresp->{'items'}[$input]->{'type'} eq 'movie') | 
       ($apiresp->{'items'}[$input]->{'type'} eq 'documovie') or
       ($apiresp->{'items'}[$input]->{'type'} eq 'concert')) {
	$serial = 0;
	$id = $apiresp->{'items'}[$input]{'id'};
	_api();
	$quit = 0;
	_movie();
	_mpv2();
    } else {
	print "Сериал...\n";
	_curl("v1/items/$myfilm[$input]?nolinks=1");
	$apiresp_s_sezonami = $apiresp;
	$serial = 1;
	if(scalar(@{$apiresp->{'item'}->{'seasons'}}) > 1 ) {
	    for($a = 0; $a < scalar(@{$apiresp->{'item'}->{'seasons'}}); $a++) {
		$numunwatchedeps = 0;
		for($c = 0; $c < scalar(@{$apiresp->{'item'}->{'seasons'}[$a]{'episodes'}}); $c++) {
		    $numunwatchedeps++ if ($apiresp->{'item'}->{'seasons'}[$a]{'episodes'}[$c]{'watched'} != 1); }
		print $a+1;
		if ($apiresp->{'item'}->{'seasons'}[$a]->{'title'}) {
		    print " - $apiresp->{'item'}->{'seasons'}[$a]->{'title'}";
		}else{
		    print " - Сезон ", $a+1;}
		print " ($numunwatchedeps)\n" if ($numunwatchedeps > 0);
		print " \n" if ($numunwatchedeps == 0); }
	    print "Какой сезон? > ";
	    my $input = <STDIN>;
	    chomp $input;
	    $seasonnum = $input;
	    $season = $input-1;
	} else {
	    print "Да тут всего лишь один сезон\n";
	    $season = 0;
	    $seasonnum = 1;
	}
	if (($apiresp->{'item'}->{'title'} =~ /\!$/) ||
	    ($apiresp->{'item'}->{'title'} =~ /\?$/)) {
	    $dot = ""; } else {
		$dot = "."; }
	for($a = 0; $a < scalar(@{$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}}); $a++) {
	    $seria = $a+1;
	    print $a+1;
	    if ($apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'title'} =~ /\.$/) {
		$dot2 = "";
	    } else {
		$dot2 = "."; }
	    print " - ";
	    print "W " if ($apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'watched'} == 0);
	    print "N " if ($apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'watched'} == -1);
	    if ($apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'title'}) {
		print "$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'title'}\n";
	    } else {
		print "Серия ", $a+1, "\n";
	    }
	    #	    @start[$a] = 0;
	    @start[$a] = "--start=".$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'watching'}{'time'} if ($apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'watched'} == 0);
	    @start[$a] =~ s/\ //;
	}
	print "Какая серия? > ";
	my $input = <STDIN>;
	chomp $input;
	$numofeps = scalar(@{$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}});
	if ($input =~ /\!/) {
	    $input =~ s/\!//;
	    $single = 1;
	    @start = ();
	    $n = $input-1;
	} else {
	    $n = $input-1;
	    $single = 0;
	}
	$startuem = $n;
	$id = $apiresp->{'item'}{'id'};
	$sid = $apiresp->{'item'}->{'seasons'}[$season]{'id'};
	$mid = $apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$n]{'id'};
	$apiresp_s_sezonami = $apiresp;

	_serial();
    }
}
sub _youtube {
    system("mpv \"$id\"")
}
sub _resume_config {
    $resume_config = Config::Tiny->read("$ENV{'HOME'}/.config/kp/kp.resume") or die;
    if ($delete) {
	delete $resume_config->{_}->{"$id"};
    }
    if ($serial == 0 && $delete == 0)  {
	$resume_config->{_}->{"$id"} = "m";
    }
    if ($serial == 0 && $ver =~ /[1-9]/ && $delete == 0 ) {
	$resume_config->{_}->{"$id"} = "m,$ver";
    }
    if ($serial == 1 && $delete == 0) {
	$resume_config->{_}->{"$id"} = "s,$season,$c";
    }
    $resume_config->write("$ENV{'HOME'}/.config/kp/kp.resume");
    $delete = 0;
}
sub _start {
    if ($resume == 0) {
	_api();
    }
    if ($serial == 0) {
	$time_c = 0;
#print "Время, записанное в апи: $apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'watching'}->{'time'}, а общее - $apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'duration'}";
	$time_c = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'watching'}->{'time'} if ($apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'watching'}->{'time'} <= $apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'duration'});
    } else {
	$mid = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'id'};
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watched'} == 0 &&
	    $single !=1) {
	    $time_c = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watching'}{'time'};
	} else {
	    $time_c = "0"
	}
    }
	$start = "--start=".$time_c;
}
sub _mpv2 {
    while ($quit != 1) {
	if ($resume == 0) {
	    _file();
	}
	_start();
	_mpv();
    }
    $delete = 1;
    _resume_config();

}
sub _curl {
    $apiresp = "";
#    print "@_&access_token=$at\n";
    eval {
	$apiresp = decode_json(`curl  -s --connect-timeout 2 "https://api.service-kp.com/@_&access_token=$at"`);
#	print Dumper($apiresp);
    } 
    or do {
	print "РКН..";
	$apiresp = decode_json(`curl --proxy socks5://localhost:9050 -s "https://api.service-kp.com/@_&access_token=$at"`);

	#print Dumper($apiresp);
    }
}
sub _movie() {
    _api() if ($resume);
    #print "Кинцо...\n";
    @sub=();
    $serial = 0;
    $n = 0;
    $ver = 0;
    #    $apiresp_s_sezonami = $apiresp;
    if (scalar(@{$apiresp_s_sezonami->{'item'}->{'videos'}}) > 1 &&
	$resume != 1) {
	print "У этого фильма есть ", scalar(@{$apiresp_s_sezonami->{'item'}->{'videos'}}), " версии:\n";
	for ($a = 0; $a < scalar(@{$apiresp->{'item'}->{'videos'}}); $a++) {
	    print $a+1, " - ", $apiresp->{'item'}->{'videos'}[$a]{'title'}, "\n"; }
	print "Какую смотреть будем? > ";
	my $input = <STDIN>;
	chomp $input;
	$input--;
	$mid = $apiresp_s_sezonami->{'item'}{'videos'}[$input]->{'id'};
	$n = $input;
	$ver = $n;
	#@title[$c] = "--force-media-title=\"$apiresp_s_sezonami->{'item'}->{'title'}. $apiresp->{'item'}->{'videos'}[$n]{'title'}\"";
	#	_subs();
	_resume_config();
    } else {
	if(scalar(@{$apiresp_s_sezonami->{'item'}->{'videos'}}) > 1 ) {
	    #	    print "А чото\n";
	    #@title[$c] = "--force-media-title=\"$apiresp_s_sezonami->{'item'}->{'title'}. $apiresp->{'item'}->{'videos'}[$n]{'title'}\"";
	    $mid = $apiresp->{'item'}{'videos'}[$ver]->{'id'};
	}
	else {
	    #@title[$c] = "--force-media-title=\"$apiresp_s_sezonami->{'item'}->{'title'}.\"";
	    $mid = $apiresp_s_sezonami->{'item'}{'videos'}[0]->{'id'};
	    #	    _subs();
	    _resume_config();
	}
    }
    _api_mid();
    _start();
    _title();
    if($resume == 0) {
	_file();
	_subs();
    }
}
sub _serial() {
    $serial = 1;
    print "Сериал...\n";
    $numofeps = scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}});

#    print "Сериал... Начинаем с $startuem, а всего их $numofeps\n";
    
    for($c = $startuem; $c < $numofeps; $c++) {
	$seria = $c + 1;
	$n = $c;
	@sub=();
	_title();
	_start();
	_api_mid();
	_subs();
	_resume_config();
	_file();
	_mpv2();
	$resume = 0;
	$quit=0;
	$delete = 1;
	_resume_config();
	if ($single == 1) {
	    print "Был запрос только на одну серию!\n";
	    $delete = 1;
	    _resume_config();
	    exit;
	}
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c+1]{'id'} eq "" &&
	    scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}[$season+1]{'episodes'}}) == 0) {
	    print "Больше серий нет, выход\n";
	    $delete = 1;
	    _resume_config();
	    exit;
	}
	if ($seria == $numofeps &&
	    $cont == 1 &&
	    scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}[$season+1]{'episodes'}}) &&
	    $single == 0
	    ) {
	    print("В этом сезоне это последняя серия...\n");
	    $c = -1;
	    $season++;
	    $seasonnum++;
	    print("Номер сезона - $seasonnum");
	    $numofeps = scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}});
	    print(", а всего серий - $numofeps");
	    _resume_config();
	} 
    }
}
sub _title {
    $title[$c] = $apiresp_s_sezonami->{'item'}->{'title'};
    print ("Название - $title[$c]\n");
    @title_split = split /\//, $title[$c];
    $title_split[1] =~ s/[\$\:\"]//g;
    $title_split[1] =~ s/^.//;
    $smartsnum = sprintf ("%02d", $seasonnum);
    $smartenum = sprintf ("%02d", $seria);
    #    $title[$c] = "--force-media-title=\"".$title_split[1];
    if ($serial == 0 && $title_split[1]) {                               # Иностранное кино
	@title_split[1] =~ s/^\ (.*)/$1/;
	$title[$c] = "--force-media-title=\"".$title_split[1]."\"";
    }
    if ($serial == 0 && $title_split[1] eq "") {                         # Русское кино
	$title[$c] = "--force-media-title=\"".$title[$c]."\"";
    }
    if ($serial == 1 && $title_split[1]) {                               # Иностранный сериал
	@title_split[1] =~ s/^\ (.*.) Season.*Episode.* - .*/$1/;
	if($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'title'}) {
	    $title[$c] = "--force-media-title=\"$title_split[1] - s$smartsnum"."e$smartenum \($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'title'}\)\"";
	} else {
	    $title[$c] = "--force-media-title=\"$title_split[1] - s$smartsnum"."e$smartenum\"";
	}
    }
    if ($serial == 1 && !$title_split[1]) {                         # Русский сериал
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]->{'title'}) {
	    $title[$c] = "--force-media-title=\"$title[$c] - s$smartsnum"."e$smartenum \($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]->{'title'}\)\"";
	} else {
	    $title[$c] = "--force-media-title=\"$title[$c] - s$smartsnum"."e$smartenum\"";
	}
    }
     $title_c =~ s/[\$\:\"]//g;
    $title_split[1] =~ s/[\$\:\"]//g;
}
sub _subs {
    #    _curl "v1/items/media-links?mid=$mid";
    if (scalar(@{$apiresp_mid->{'subtitles'}}) > 0) {
	for($subs=0; $subs < scalar(@{$apiresp_mid->{'subtitles'}}); $subs++) {
	    if ($apiresp_mid->{'subtitles'}[$subs]->{'lang'} eq 'eng') {
		@sub[$subs] = "--sub-file=$apiresp_mid->{'subtitles'}[$subs]->{'url'} ";
	    }
	}
    }
    #print "Сабы - @sub<=====\n";
    if ($us &&
	$title_split[1] &&
	!@sub) {
#	print @sub;
	print "Работает subliminal\n";
	if ($serial) {
	    $subliminal_command = "cd /tmp; subliminal download -l eng \"$title_split[1].s$smartsnum"."e$smartenum\"";
	} else {
	    $subliminal_command = "cd /tmp; subliminal download -l eng \"$title_split[1]\"";	
	}
	#print "subliminal download -d /tmp -l eng \"$title_split[1] s$smartsnum"."e$smartenum\"\n\n ";
	print "$subliminal_command \n";
	#system("subliminal download -d /tmp -l eng \"$title_split[1]$apiresp_s_sezonami->{'item'}{'year'}\" > /dev/null");
	#	system("cd /tmp; subliminal download -l eng \"$title_split[1].s$smartsnum"."e$smartenum\"");
	system($subliminal_command);
	#	@sub[5] = " --sub-file=\"/tmp/$title_c".".en.srt\"";
	#	@sub[6] = " --sub-file=\"/tmp/$title_c"."en.srt\"";
	@sub[7] = " --sub-file=\"/tmp/$title_split[1]en.srt\"";
	@sub[8] = " --sub-file=\"/tmp/$title_split[1] - $seasonnum"."x"."$seria.en.srt\"";
	@sub[9] = " --sub-file=\"/tmp/$title_split[1].en.srt\"";
    }

}
sub _api {
    _curl("v1/items/$id?nolinks=1");
    $apiresp_s_sezonami = $apiresp;
}
sub _api_mid {
#    print "api вызов";
    _curl "v1/items/media-links?mid=$mid";
    $apiresp_mid = $apiresp;
}
sub _file {
    $file = 0;
    for($a=0; $a < scalar(@{$apiresp_mid->{'files'}}); $a++) {
	$file = $apiresp_mid->{'files'}[$a]->{'url'}->{$ps} if ($apiresp_mid->{'files'}[$a]->{'quality'} eq $pq);
    }
    if ($file eq '0' ) {
	for($a=0; $a < scalar(@{$apiresp_mid->{'files'}}); $a++) {
	    $file = $apiresp_mid->{'files'}[$a]->{'url'}->{$ps} if ($apiresp_mid->{'files'}[$a]->{'quality'} eq "720p");
	}
    }
    if ($file eq '0' ) {
	for($a=0; $a < scalar(@{$apiresp_mid->{'files'}}); $a++) {
	    $file = $apiresp_mid->{'files'}[$a]->{'url'}->{$ps} if ($apiresp_mid->{'files'}[$a]->{'quality'} eq "480p");
	}
    }
#    print "$file ========================================\n";
    if ($ps eq "hls4") {
	@notes = `curl -s $file`;
	$cdn = $file;
	$cdn =~ s/^(.*\.net).*$/$1/;
	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split /(="|[":,])/, @notes[$a];
	    $pq =~ s/p//;
	    if ($next) {
		$file = "$cdn$note[0]";
		$next = 0;
	    }
	    if ($note[24] =~ "audio$pq") {
		$next = 1;
	    }
	}
	_audio();
    }
}
sub _audio {
    $afirst = 1;
    $luckynum = 0;
    $afiles = "--script-opts=\"";
    for($a = 0; $a < scalar(@notes); $a++) {
	@note = split /(="|[":,])/, @notes[$a];
#	for($b = 0; $b < scalar(@note); $b++) {
#	    print " $b - @note[$b]\n";
#	}
	$pq =~ s/p//;
#	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]) {
	if ($note[6] =~ "audio") {
	    if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]||
		$apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]) {
		#	    print $note[12];
		#	    $apiresp_s_sezonami->{'item'}->{'videos'}[0]->{'audios'}[0]->{'type'}->{'title'} = "null" if (!$apiresp_s_sezonami->{'item'}->{'videos'}[0]->{'audios'}[0]->{'type'}->{'title'});
#		$apiresp_s_sezonami->{'item'}->{'videos'}[0]->{'audios'}[0]->{'lang'} = "null" if (!$apiresp_s_sezonami->{'item'}->{'videos'}[0]->{'audios'}[0]->{'lang'});
#			    $apiresp_s_sezonami->{'item'}->{'videos'}[0]->{'audios'}[0]->{'lang'} = "null" if (!$apiresp_s_sezonami->{'item'}->{'videos'}[0]->{'audios'}[0]->{'lang'});
		#	    $alang =  $note[12];
		#	    $alang =~ s/.*\((.*)\)/$1/;
		#	    $alang = lc($alang);
		if ($serial) {
		    $alang = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'lang'};
		    #	    $alink = `curl -s $cdn$note[20]| grep \\\<title\\\>Redire | sed -e s/\\\<title\\\>Redirecting\\\ to\/\/ | sed -e "s/<\\\/title>.*//" | sed -e "s/\ //g"`;
		    $alink = $cdn.$note[20];
		    $atitle = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'type'}->{'title'} || "null";

		    $aauthor = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'author'}->{'title'};
		} else {
		    $alang = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'lang'};
		    #	    $alink = `curl -s $cdn$note[20]| grep \\\<title\\\>Redire | sed -e s/\\\<title\\\>Redirecting\\\ to\/\/ | sed -e "s/<\\\/title>.*//" | sed -e "s/\ //g"`;
		    $alink = $cdn.$note[20];
		    $atitle = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'type'}->{'title'} || "Null";
		$aauthor = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'author'}->{'title'};
		}
		chomp $alink;
		if ($afirst) {
		    $afiles = $afiles."aud$a\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles."aud$a\=$alink|$atitle|$alang" if(!$aauthor);
		    $afirst = 0;
		} else {
		    #afiles = $afiles.",aud$a\=$alink|$atitle (\'$aauthor\')|$alang";
		    $afiles = $afiles.",aud$a\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles.",aud$a\=$alink|$atitle|$alang" if(!$aauthor);
		}
		$luckynum++;
	    }
	}
    }
    $afiles = $afiles."\"";
}	
sub _mpv {
    @output = 0;
    print "Проигрываем...\n";
    #open($fh, "-|", "mpv @title[$n] @sub '$file'");
    #open($fh, "-|", "mpv @title[$n] @sub '$file' 2>&1" );
    #open($fh, "-|", "mpv @start[$n] @title[$n] @sub '$file' 2>&1" );
    if ($ps eq "hls4") {
	if($resume == 1) {
	    $command = "$mpv --x11-name=\"resume\" $afiles --fs=no --pause --loop-playlist=1 --no-resume-playback $start @title[$c] @sub '$file' 2>&1";
	    $resume = 0;
	} else {
	    system("wmctrl -r :ACTIVE: -b remove,fullscreen");
	    $command ="$mpv --pause=no ".$afiles." --loop-playlist=1 --no-resume-playback $start @title[$c] @sub '$file' 2>&1";
	}
    } else {
	print("$mpv --fs=no --pause --loop-playlist=1 $start @title[$c] @sub '$file' 2>&1\n");
	$command = "mpv --fs=no --pause --loop-playlist=1 $start @title[$c] @sub '$file' 2>&1";
    }
    #print $command;
    open($fh, "-|", $command);
    binmode($fh,":encoding(UTF-8)");
    $numofiterations = 0;
    $fs = 0;
    while (read $fh, $char, 1) {
	$numofiterations++;
	if (($char eq "\n") || ($char eq "\e")) {
	    $output = $output . "\n";
	    if (($output =~ /.*AV:.*/) && ($fs != 1) && ($resume != 1)) {
		$fs = 1;
 	    }
	    if ($output =~ /.*ragequit.*/) {
		$delete = 1;
		_resume_config();
		print "ВЫХОД!!!11\n";
		exit;
	    }
	    if ($output =~ /.*quitAAA.*/) {
		$quit = 1;
		if ($serial != 1) {
		    #print "НЕ сериал\n";
		    $delete = 1;
		    _resume_config();
		    exit;
		}
		else {
		    _resume_config();
		}
	    }
	    if (($output =~ /.*AV:.*/) && ($numofiterations > 300)) {
		$output = substr $output, 0;
		$output =~ s/.*AV..(........)/$1/ ;
		$time = $output;
		_timeconv();
		_time();
		$output = "";
		$numofiterations = 0;
	    } else {
		
		$output = "";
	    }
	} else {
	    $output = $output . $char;
	}
    }
    close $fh;
}
sub _time {
    if($time_c == 0) {
	return; }
    #    print "Запись временной метки...";
    $season=$season+1;
    if ($serial == '0') {
	$version = $ver + 1;
	_curl("v1/watching/marktime?id=$id&time=$time_c&video=$version"); }              # запись временной метки
    else{
	_curl("v1/watching/marktime?id=$id&time=$time_c&season=$season&video=$seria"); }               # запись временной метки для сериала
    $season--;
}
sub _timeconv {
    $secs = $time;
    $mins = $time;
    $hours = $time;
    $secs =~ s/.*:.*:(.*)/$1/;
    $mins =~ s/.*:(.*):.*/$1/;
    $hours =~ s/(.*):.*:.*/$1/;
    $time_c = $secs + $mins*60 + $hours*3600; }
