#!/usr/bin/perl 
no warnings 'utf8';
use utf8;
use JSON;
use Config::Tiny;
use Data::Dumper;
#binmode STDOUT, ':utf8';
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
$items = 0;
while ($apiresp->{pagination}{total} == 0) {
    print "? > ";
    my $input = <STDIN>;
    chomp $input;
    $input =~ s/\ /+/g;
    if($input eq "!new"){
	_curl("v1/items/fresh?type=movie");
	$items = $apiresp->{'pagination'}->{'perpage'}; }
    else {
	_curl("v1/items/search?q='$input'&perpage=200");
	$items = $apiresp->{'pagination'}->{'total_items'}; }
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
	    print "\n";
	    $a++; } } else {
		print "Нет такого\n"; } }
print "Какое? > ";
my $input = <STDIN>;
chomp $input;
$input--;
if(($apiresp->{'items'}[$input]->{'type'} eq 'movie') | 
   ($apiresp->{'items'}[$input]->{'type'} eq 'documovie') or
   ($apiresp->{'items'}[$input]->{'type'} eq 'concert')) {
    $serial = 0;
    _curl("v1/items/$myfilm[$input]?nolinks=1");
    $id = $apiresp->{'item'}{'id'};
    $quit = 0;
    _movie();
    _mpv();

    #    $time_c = $apiresp->{'item'}->{'videos'}[$n]->{'watching'}->{'time'};

    # while ($apiresp_s_sezonami->{'item'}->{'watched'} == 0 &&
    # 	   $time_c > 0 &&
    # 	   $quit != 1) {
    # 	#    print("$id, $apiresp_s_sezonami->{'items'}->{'watched'}, $time_c, $quit\n");
    # 	$mid = $apiresp->{'item'}{'videos'}[$n]->{'id'};
    # 	#	_mid();
    # 	_file();
    # 	#	    print "Время - $time_c\n";
    # 	@start[$c] = "--start=".$time_c;
    # 	_mpv();
    # 	_curl("v1/items/$id?nolinks=1");
    # }
    _mpv2();
    #    _time();
} else {
    print "Сериал...\n";
    _curl("v1/items/$myfilm[$input]?nolinks=1");
    _serial();
}

sub _mpv2 {
    while ($apiresp_s_sezonami->{'item'}->{'watched'} == 0 &&
	   #$time_c > 0 &&
	   $quit != 1) {
	_curl("v1/items/$id?nolinks=1");
	$apiresp_s_sezonami = $apiresp;
	if ($serial == 0) {
   	    $mid = $apiresp->{'item'}{'videos'}[$n]->{'id'};
	    $time_c = $apiresp->{'item'}->{'videos'}[$n]->{'watching'}->{'time'};
	} else {
	    $mid = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'id'};
	    $time_c = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watching'}{'time'};
	}
	_file();
	@start[$c] = "--start=".$time_c;
	_mpv();
	_curl("v1/items/$id?nolinks=1");
    }
}
sub _curl {
    #    print @_;
    eval {
	$apiresp = decode_json(`curl  -s "https://api.service-kp.com/@_&access_token=$at"`);
	#$apiresp = decode_json(`curl --proxy socks5://localhost:9050 -s "https://api.service-kp.com/@_&access_token=$at"`);
#	print Dumper($apiresp);
    } or do {
	print "ff..";
	$apiresp = decode_json(`curl --proxy socks5://localhost:9050 -s "https://api.service-kp.com/@_&access_token=$at"`); } }
sub _movie() {
    @sub=();
    @start = ();
    $serial = 0;
    $n = -1;
    $ver = 1;
    $id = $apiresp->{'item'}->{'id'};
    if (scalar(@{$apiresp->{'item'}->{'videos'}}) > 1) {
	print "У этого фильма есть ", scalar(@{$apiresp->{'item'}->{'videos'}}), " версии:\n";
	for ($a = 0; $a < scalar(@{$apiresp->{'item'}->{'videos'}}); $a++) {
	    print $a+1, " - ", $apiresp->{'item'}->{'videos'}[$a]{'title'}, "\n"; }
	print "Какую смотреть будем? > ";
	my $input = <STDIN>;
	chomp $input;
	$input--;
	$mid = $apiresp->{'item'}{'videos'}[$input]->{'id'};
	#	$id = $apiresp->{'item'}->{'id'};
	$n = $input;
	$ver = $apiresp->{'item'}{'videos'}[$input]->{'number'};
	#	print $apiresp->{'item'}->{'videos'}[$input]->{'watching'}->{'time'};
	#	if ($apiresp->{'item'}->{'videos'}[$input]->{'watched'} == 0) {
	@start[$c] = "--start=" . $apiresp->{'item'}->{'videos'}[$input]->{'watching'}->{'time'};
	#	}
	#	$title_split = split /\//, $apiresp->{'item'}->{'title'};
	@title[$c] = "--force-media-title=\"$apiresp->{'item'}->{'title'}. $apiresp->{'item'}->{'videos'}[$input]{'title'}\"";
	#	_mid();
	_file();
	_subs();
    } else {
	if ($apiresp->{'item'}->{'videos'}[0]->{'watched'} == 0) {
	    @start[$n+1] = "--start=".$apiresp->{'item'}->{'videos'}[0]->{'watching'}->{'time'}; }
	@title[$c] = "--force-media-title=\"$apiresp->{'item'}->{'title'}.\"";
	$mid = $apiresp->{'item'}{'videos'}[0]->{'id'};
	#	_mid();
	_file();
	
	_subs();

    }
}
sub _serial() {
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
	$season = $input-1;} else {
	    print "Да тут всего лишь один сезон\n";
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
	    #	    $seasonnum = $season+1;
	    print "$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'title'}\n";
	    #	    @title[$a] = "--force-media-title=\"$apiresp->{'item'}->{'title'}$dot Сезон $seasonnum. Серия $seria\ - \""."\"$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'title'}$dot2\"";
	} else {
	    #	    $seasonnum = $season+1;
	    print "Серия ", $a+1, "\n";
	    #	    @title[$a] = "--force-media-title=\"$apiresp->{'item'}{'title'}$dot Сезон $seasonnum. Серия $seria.\"";
	}
        @start[$a] = 0;
	@start[$a] = "--start=".$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'watching'}{'time'} if ($apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$a]{'watched'} == 0);
	@start[$a] =~ s/\ //; }
    print "Какая серия? > ";
    my $input = <STDIN>;
    chomp $input;
    $numofeps = scalar(@{$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}});
    if ($input =~ /\!/) {
	$input =~ s/\!//;
	$n = $input-1;
	$numofeps = $n + 1;
	$single = 1;
	@start = (); } else {
	    $n = $input-1;
	    $single = 0;}
    $startuem = $n;
    $id = $apiresp->{'item'}{'id'};
    $sid = $apiresp->{'item'}->{'seasons'}[$season]{'id'};
    $mid = $apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$n]{'id'};
    $apiresp_s_sezonami = $apiresp;
    for($c=$startuem; $c < $numofeps; $c++) {
	$mid = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'id'};
	_file();
	$seria = $c + 1;
	$n = $c;
	_file();
	@sub=();
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'title'}) {
	    @title[$c] = "--force-media-title=\"$apiresp_s_sezonami->{'item'}->{'title'}$dot Season $seasonnum. Episode $seria - $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'title'}$dot2 \"";
	}
	else {
	    @title[$c] = "--force-media-title=\"$apiresp_s_sezonami->{'item'}{'title'}$dot Season $seasonnum. Episode $seria.\"";
	}
	_subs();
#	print("$apiresp->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watched'}, $time_c, $quit");
	_mpv();
	$quit = 0;
	#print("$apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watched'}, $time_c, $quit\n")
	
	# while ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watched'} == 0 &&
	#        $time_c > 0 &&
	#        $quit != 1) {
	#     $mid = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'id'};
	#     _file();
	#     #	    print "Время - $time_c\n";
	#     #	    print "Вот и\n";
	#     $time_c = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watching'}{'time'};
	#     @start[$c] = "--start=".$time_c;
	#     _mpv();
	#     _curl("v1/items/$id?nolinks=1");
	#     $apiresp_s_sezonami = $apiresp;
	# }
	_mpv2();
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
	} 
    }
}
sub _subs {

    #    print "Было - $title[$c]\n";
    @title_split = split /\//, $title[$c];
    if ($serial == 0) {
	@title_split[1] =~ s/^\ (.*)"/$1/;
	$title_c = $title_split[1];
    }
    else {
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'title'}) {
	    @title_split[1] =~ s/^\ (.*). Season.*Episode.* - .*/$1/;
	}
	else {
	    @title_split[1] =~ s/^\ (.*). Season.*Episode.*/$1/;
	}
        $title_c = "$title_split[1] - $seasonnum"."x"."$seria";
    }
    
    #    @title_split[1] =~ s/(.*) - ".*"/$1/;
    #   print "Стало - $title_split[1]\n";
    if ($us && $title_split[1]) {
	@title[$c] = "--force-media-title=\"$title_c\"";
	$title_c =~ s/\&//;
	system("subliminal download -d /tmp -l eng \"$title_c\" > /dev/null");
	@sub[6] = " --sub-file=\"/tmp/$title_c"."en.srt\"";
	@sub[7] = " --sub-file=\"/tmp/$title_split[1]en.srt\"";
	@sub[8] = " --sub-file=\"/tmp/$title_split[1] - $seasonnum"."x"."$seria.en.srt\"";
	@sub[9] = " --sub-file=\"/tmp/$title_split[1].en.srt\"";
    }

    if (scalar(@{$apiresp->{'subtitles'}}) > 0) {
	for($subs=0; $subs < scalar(@{$apiresp->{'subtitles'}}); $subs++) {
	    if ($apiresp->{'subtitles'}[$subs]->{'lang'} eq 'eng') {
		@sub[$subs] = "--sub-file=$apiresp->{'subtitles'}[$subs]->{'url'} ";
	    }
	}
    }
}
sub _file {
    $file = 0;
    _curl "v1/items/media-links?mid=$mid";
    for($a=0; $a < scalar(@{$apiresp->{'files'}}); $a++) {
	$file = $apiresp->{'files'}[$a]->{'url'}->{$ps} if ($apiresp->{'files'}[$a]->{'quality'} eq $pq); }
    if ($file eq '0' ) {
	for($a=0; $a < scalar(@{$apiresp->{'files'}}); $a++) {
	    $file = $apiresp->{'files'}[$a]->{'url'}->{$ps} if ($apiresp->{'files'}[$a]->{'quality'} eq "720p"); } }
    if ($file eq '0' ) {
	for($a=0; $a < scalar(@{$apiresp->{'files'}}); $a++) {
	    $file = $apiresp->{'files'}[$a]->{'url'}->{$ps} if ($apiresp->{'files'}[$a]->{'quality'} eq "480p"); } } }
sub _mpv {
    @output = 0;
    print "Проигрываем...\n";
    #    system("mpv --panscan=0.1 --loop-playlist=1 @start[$n] @title[$n] @sub '$file'");
    #       print $file;
    #open($fh, "-|", "mpv @title[$n] @sub '$file'");
    #open($fh, "-|", "mpv @title[$n] @sub '$file' 2>&1" );
    #open($fh, "-|", "mpv @start[$n] @title[$n] @sub '$file' 2>&1" );
#    print("mpv @start[$c] @title[$c] @sub '$file' 2>&1");
    open($fh, "-|", "mpv --loop-playlist=1 @start[$c] @title @sub '$file' 2>&1" );
    #open($fh, "-|", "mpv @start[$c] @title[$c] @sub '$file' 2>&1" );
    #print("mpv @start[$n] @title[$n] @sub '$file' 2>&1");
    #system("wmctrl -ir   \$\(xdotool getwindowfocus\) -b add,maximized_vert,maximized_horz");
    binmode($fh);
#    $n = 0;
    $numofiterations = 0;
    $fs = 0;
    while (read $fh, $char, 1) {
	$numofiterations++;
#	if (($char eq ":" && $fs != 1)) {
#
#	system("wmctrl -ir   \$\(xdotool getwindowfocus\) -b add,maximized_vert,maximized_horz");
#	    $fs = 1;
#	}
	    
	if (($char eq "\n") || ($char eq "\e")) {
	    $output = $output . "\n";
	    if (($output =~ /.*AV:.*/) && ($fs != 1)) {
		system("wmctrl -ir   \$\(xdotool getwindowfocus\) -b add,maximized_vert,maximized_horz");
		$fs = 1;
 	    }
	    # if ($output =~ /.*Savepos.*/) {
	    # 	$output =~ s/.*AV..(........)/$1/ ;
	    # 	#		print $output;
	    # 	#system("wmctrl -ir   \$\(xdotool getwindowfocus\) -b add,maximized_vert,maximized_horz");
	    # 	$time = $output;
	    # 	_timeconv();
	    # 	_time();
	    # }
	    if ($output =~ /.*quitAAA.*/) {
		$quit = 1;
	    }
	    if (($output =~ /.*AV:.*/) && ($numofiterations > 1000)) {


#		print "Saving...\n";
		$output = substr $output, 0;
		$output =~ s/.*AV..(........)/$1/ ;
		#		print $output;
		#system("wmctrl -ir   \$\(xdotool getwindowfocus\) -b add,maximized_vert,maximized_horz");
		$time = $output;
		_timeconv();
		_time();
#		print "Save com!\n";
		$output = "";
		$numofiterations = 0;
	    } else {
		
		$output = "";
	    }
	} else {
	    $output = $output . $char;
	}
    }
    close $fh; }
sub _mid {
    _curl "v1/items/media-links?mid=$mid"; }
sub _time {
    if($time_c == 0) {
	return; }
    #    print "Запись временной метки...";
    $season=$season+1;
    if ($serial == '0') {
	_curl("v1/watching/marktime?id=$id&time=$time_c&video=$ver"); }              # запись временной метки
    else{
	_curl("v1/watching/marktime?id=$id&time=$time_c&season=$season&video=$seria"); }               # запись временной метки для сериала
    $season--;
    #   print "\r";
    #    $time=0;
}
sub _timeconv {
    $secs = $time;
    $mins = $time;
    $hours = $time;
    $secs =~ s/.*:.*:(.*)/$1/;
    $mins =~ s/.*:(.*):.*/$1/;
    $hours =~ s/(.*):.*:.*/$1/;
    $time_c = $secs + $mins*60 + $hours*3600; }
