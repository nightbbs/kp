#!/usr/bin/perl 
no warnings 'utf8';
use POSIX;
#use threads;
use utf8;
use Encode;
use URI::Escape;
use JSON;
use Config::Tiny;
use Data::Dumper;
use URI::Escape;
sub _read_config {
    $config = Config::Tiny->read("$ENV{'HOME'}/.config/kp/kp.conf") or die;
    $token = $config->{_}->{token};
    $identity = $config->{_}->{identity};
    $at = $config->{_}->{access_token};
    $pq = $config->{kpc}->{preferred_quality};
    $ps = $config->{kpc}->{preferred_stream};
    $us = $config->{kpc}->{use_subliminal};
    $subliminal = $config->{kpc}->{subliminal};
    $mpv = $config->{kpc}->{mpv};
    $ua = $config->{kpc}->{user_agent};
    $cont = $config->{kpc}->{continuos_mode};
    $mirror = $config->{_}->{mirror};
    $mirror_api = $config->{_}->{mirror_api};
    $flags = $config->{_}->{flags};
    $debug = $config->{_}->{debug};
    $da = $config->{_}->{debug_api};
    $h = $config->{kpc}->{hints};
}
_read_config();
_curl("v1/watching/serials?subscribed=1");
$apiresp_neweps = $apiresp;
print "Тут новые эпизоды\n" if (scalar(@{$apiresp->{'items'}}));
# for($a = 0; $a < scalar(@{$apiresp->{'items'}}); $a++) {
#     print $apiresp->{'items'}[$a]->{'title'};
#     print "\n";
#}
$a = 0;
$items = scalar(@{$apiresp_neweps->{'items'}});
while ($a < $items) {
    print $a + 1, " - ", $apiresp_neweps->{'items'}[$a]->{'title'}, " \($apiresp_neweps->{'items'}[$a]->{'new'}\)";
    print " \($apiresp_neweps->{'items'}[$a]{'year'}\)" if($apiresp_neweps->{'items'}[$a]{'year'});
    print ", IMDB: $apiresp_neweps->{'items'}[$a]{'imdb_rating'}" if($apiresp_neweps->{'items'}[$a]{'imdb_rating'});
    print ", Kinopoisk: $apiresp_neweps->{'items'}[$a]{'kinopoisk_rating'}" if($apiresp_neweps->{'items'}[$a]{'kinopoisk_rating'});
    print ", Kinopub: $apiresp_neweps->{'items'}[$a]{'rating'}" if($apiresp_neweps->{'items'}[$a]{'rating'});
    print "\n";
    $a++;
}
_curl("v1/user?");
my $numofdays = int($apiresp->{'user'}->{'subscription'}->{'days'} + 0.5);
system "figlet -f roman \" $numofdays\" | head -7";
@sub = ();
$a = 0;
$c = 0;
$n = 1;
$first = 1;
$items = 0;
$resume = 1 if ($ARGV[0] eq "-r");
$need_num = $ARGV[1];
$resume = 0 if ($ARGV[0] eq "");
if($resume == 1)
{
    open(resume_file, '<', "$ENV{'HOME'}/.config/kp/kp.resume") or die $!;
    while(<resume_file>) {
	if ($n == $need_num) {
	    @data = split(/\=|\,|\n/, $_);
	    $quit = 0;
	    if ($data[1] =~ 'y') {
		$id = $data[0];
		_youtube();
	    }
	    if ($data[1] =~ 'm') {
		if($data[2]) {
		    $ver = $data[2];
		}
		$start2 = $data[3];
		$id = $data[0];
		_movie();
		#		_start();
		_file();
		#		_subs();
		_mpv2();
	    }
	    if ($data[1] =~ 's') {
		$id = $data[0];
		$season = $data[2];
		$seasonnum = $season + 1;
		$startuem = $data[3];
		$start2 = $data[4];
		_api();
		$serial = 1;
		_serial();
	    }
	}
	$n++;
    }
} else {
    $n = 0;
    _curl("v1/items?type=movie&sort=created-");
    $apiresp_new = $apiresp;
    $items = $apiresp_new->{'pagination'}->{'perpage'};
    $yesterday = time() - 172400;
    while ($n < $items) {
	if ($apiresp_new->{'items'}[$n]->{'created_at'} > $yesterday) {
	    print $a + 1, " - (*) ", $apiresp_new->{'items'}[$a]->{'title'};
	    print " \($apiresp_new->{'items'}[$a]{'year'}\)" if($apiresp_new->{'items'}[$a]{'year'});
	    print ", IMDB: $apiresp_new->{'items'}[$a]{'imdb_rating'}" if($apiresp_new->{'items'}[$a]{'imdb_rating'});
	    print ", Kinopoisk: $apiresp_new->{'items'}[$a]{'kinopoisk_rating'}" if($apiresp_new->{'items'}[$a]{'kinopoisk_rating'});
	    print ", Kinopub: $apiresp_new->{'items'}[$a]{'rating'}" if($apiresp_new->{'items'}[$a]{'rating'});
	    print "\n";
	    $a++;
	    $newmovies = $a;
	}
	$n++;
    }
    $n = 0;
    _curl("v1/items?type=serial&sort=created-");
    $apiresp_news = $apiresp;
    $items = $apiresp_news->{'pagination'}->{'perpage'};
    while ($n < $items) {
	if ($apiresp_news->{'items'}[$n]->{'created_at'} > $yesterday) {
	    print $a + 1, " - ", $apiresp_news->{'items'}[$n]->{'title'};
	    print " \($apiresp_news->{'items'}[$n]{'year'}\)" if($apiresp_news->{'items'}[$n]{'year'});
	    print ", IMDB: $apiresp_news->{'items'}[$a]{'imdb_rating'}" if($apiresp_news->{'items'}[$n]{'imdb_rating'});
	    print ", Kinopoisk: $apiresp_news->{'items'}[$a]{'kinopoisk_rating'}" if($apiresp_news->{'items'}[$n]{'kinopoisk_rating'});
	    print ", Kinopub: $apiresp_news->{'items'}[$a]{'rating'}" if($apiresp_news->{'items'}[$n]{'rating'});
	    print "\n";
	    $a++;
	    $newserials = $a - $newmovies;
	}
	$n++;
    }
    $apiresp = ();
    $a = 0;
    $apiresp->{'pagination'}{'total'} = 0;
    while ($apiresp->{'pagination'}{'total'} == 0) {
	print "Выбор сериала с непросмотренными сериями - ~<номер>, выбор нового фильма/сериала из списка выше - !<номер>, ну или просто название...\n" if ($h);
	print "? > ";
	my $input = <STDIN>;
	chomp $input;
	$input =~ s/\ /+/g;
	if($input eq "!new"){
	    _curl("v1/items?type=movie&sort=created-");
 	    $items = $apiresp->{'pagination'}->{'perpage'};
	}
	elsif ($input eq "!news"){
	    _curl("v1/items?type=serial&sort=created-");
 	    $items = $apiresp->{'pagination'}->{'perpage'};
	}
	elsif ($input =~ /\~\d+/){
	    $luckynum = $input;
	    $luckynum =~ s/^\~//;
	    $id = $apiresp_neweps->{'items'}[$luckynum-1]{'id'};
	    _api();
	    _serial();
	}

	elsif ($input =~ /\!\d+/){
	    $luckynum = $input;
	    $luckynum =~ s/^\!//;
	    if ($luckynum <= $newmovies) {
		$id = $apiresp_new->{'items'}[$luckynum-1]{'id'};
		_api();
		$quit = 0;
		_movie();
		#		_subs();
		_mpv2();
	    } else {
		$id = $apiresp_news->{'items'}[$luckynum-$newmovies-1]{'id'};
		_api();
		_serial();
	    }
	}
	else {
	    $escaped_input = uri_escape($input);
	    _curl("v1/items/search?q=$escaped_input&perpage=100");
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
    print "Какой? > ";
    my $input = <STDIN>;
    chomp $input;
    $input--;
    if(($apiresp->{'items'}[$input]->{'type'} eq 'movie') | 
       ($apiresp->{'items'}[$input]->{'type'} eq 'documovie') or
       ($apiresp->{'items'}[$input]->{'type'} eq 'concert')) {
	$serial = 0;
	$id = $apiresp->{'items'}[$input]{'id'};
	$quit = 0;
	_movie();
	_mpv2();
    } else {
	$id = $apiresp->{'items'}[$input]{'id'};
	_serial();
    }
}
sub _youtube {
    system("mpv \"$id\"")
}
sub _resume_config {
    $resume_config = Config::Tiny->read("$ENV{'HOME'}/.config/kp/kp.resume") or die;
    if ($timesave == 1 && $serial == 1) {
	$cwoutn = $c;
	chomp $cwoutn;
	$resume_config->{_}->{"$id"} = "s,$season,$cwoutn,$time_c";
    }
    if ($timesave == 1 && $serial == 0 && $ver !~ /[1-9]/) {
	$resume_config->{_}->{"$id"} = "m,0,$time_c";
    }
    if ($timesave == 1 && $serial == 0 && $ver =~ /[1-9]/ && $delete == 0 ) {
	$resume_config->{_}->{"$id"} = "m,$ver,$time_c";
    }
    if ($delete) {
	delete $resume_config->{_}->{"$id"};
    }
    if ($timesave == 0 && $serial == 0 && $delete == 0)  {
	#	$resume_config->{_}->{"$id"} = "m,0";
    }
    if ($timesave == 0 && $serial == 0 && $ver =~ /[1-9]/ && $delete == 0 ) {
	#	$resume_config->{_}->{"$id"} = "m,$ver";
    }
    if ($timesave == 0 && $serial == 1 && $delete == 0) {
	#	$resume_config->{_}->{"$id"} = "s,$season,$c";
    }
    $resume_config->write("$ENV{'HOME'}/.config/kp/kp.resume");
    $delete = 0;
}
sub _start {
    _api();

    if ($serial == 0) {
	$time_c = 0;
	print "Время, записанное в апи: $apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'watching'}->{'time'}, а общее - $apiresp_s_sezonami->{'item'}->{'videos'}[$ver-1]->{'duration'}" if ($debug);
	$time_c = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'watching'}->{'time'} if ($apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'watching'}->{'time'} <= $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'duration'}-10);
    } else {
	$time_c = "0";
	$mid = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'id'};
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watched'} == 0 &&
	    $single !=1) {
	    $time_c = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}[$c]{'watching'}{'time'};
	} else {
	    $time_c = "0"
	}
    }
    if($serial == 0) {
	if ($start2 =~ /\d+/ &&
	    $time_c == 0) {
	    print "Устанавливаем старт $start2 вопреки апи" if ($debug);
	    $start = $start2;
	} else {
	    $start = $time_c;
	} 
    }
    else {
	if ($start2 =~ /\d+/ &&
	    $time_c == 0) {
	    print "Устанавливаем старт $start2 вопреки апи" if ($debug);
	    $start = $start2;
	} else {
	    $start = $time_c;
	}
    }
    if ($start) {
	$start =~ s/.$/0/;
    }
}
sub _mpv2 {
    while ($quit != 1) {
	if ($resume == 0) {
	    _read_config();
	}
	$time_save = 1;
	_resume_config();
	_read_config();
	_file();
	_start();
	_mpv();
    }
    $delete = 1;
    _resume_config();

}
sub _curl {
    $apiresp = "";
    print "@_[0]&access_token=$at\n" if ($debug);
    eval {
	$apiresp = decode_json(`curl --json \"@_[1]\" \"https://api.srvkp.com/@_[0]&access_token=$at\"`) if ($POST);
	$POST=0;
	$apiresp = decode_json(`curl $flags -H \"User-Agent: $ua\" -Ls "$mirror_api/@_&access_token=$at"`);
    } 
    or do {
	print "А кинопаб-то лежит! (ну или просто инет отвалился)\n";
	_curl(@_);
	#	}
    }
}
sub _movie() {
    _api();
    #print "Кинцо...\n";
    @sub=();
    $serial = 0;
    $n = 0;
    $seria = 1;
    #    $ver = 0;
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
	$seria = $ver;
	_resume_config();
    } else {
	if(scalar(@{$apiresp_s_sezonami->{'item'}->{'videos'}}) > 1 ) {
	    $mid = $apiresp->{'item'}{'videos'}[$ver]->{'id'};
	}
	else {
	    $mid = $apiresp_s_sezonami->{'item'}{'videos'}[0]->{'id'};
	    _resume_config();
	}
    }
    $seasonnum = 0;
    _api_mid();
    _start();
    _title();
    _subs();
}
sub _serial() {
    $serial = 1;
    if($resume == 0) {
	if(!$luckynum) {
	    _api();		
	} 
	$serial = 1;
	$a = 0;
	if(scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}}) > 1 ) {
	    for($a = 0; $a < scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}}); $a++) {
		$numunwatchedeps = 0;
		for($c = 0; $c < scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}[$a]{'episodes'}}); $c++) {
		    $numunwatchedeps++ if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$a]{'episodes'}[$c]{'watched'} != 1); }
		print $a+1;
		if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$a]->{'title'}) {
		    print " - $apiresp_s_sezonami->{'item'}->{'seasons'}[$a]->{'title'}";
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
    }
    $numofeps = scalar(@{$apiresp_s_sezonami->{'item'}->{'seasons'}[$season]{'episodes'}});
    for($c = $startuem; $c < $numofeps; $c++) {
	$seria = $c + 1;
	$nt = 0;
	$n = $c;
	@sub=();
	_title();
	_start();
	_api_mid();
	_subs();
	_resume_config();
	_mpv2();
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
	    print(", а всего серий - $numofeps\n");
	    _resume_config();
	} 
    }
}
sub _title {
    $title[$c] = $apiresp_s_sezonami->{'item'}->{'title'};
    print ("Название - $title[$c]. $apiresp->{'item'}->{'videos'}[$ver]{'title'}\n");
    @title_split = split /\//, $title[$c];
    $title_split[1] =~ s/[\$\:\"]//g;
    $title_split[1] =~ s/^.//;
    $smartsnum = sprintf ("%02d", $seasonnum);
    $smartenum = sprintf ("%02d", $seria);
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
    @sub = ();
    $subs=0;
    if (scalar(@{$apiresp_mid->{'subtitles'}}) != 0) {
	for($subs=0; $subs < scalar(@{$apiresp_mid->{'subtitles'}}); $subs++) {
	    if ($apiresp_mid->{'subtitles'}[$subs]->{'lang'} eq 'eng') {
		@sub[$subs] = "--sub-file='$apiresp_mid->{'subtitles'}[$subs]->{'url'}'";
		$subs++;
	    }
	}
    }
    if (scalar(@{$apiresp_mid->{'subtitles'}}) != 0 &&
	!@sub) {
	for($subs=0; $subs < scalar(@{$apiresp_mid->{'subtitles'}}); $subs++) {
	    if ($apiresp_mid->{'subtitles'}[$subs]->{'lang'} eq 'rus') {
		@sub[$subs] = "--sub-file='$apiresp_mid->{'subtitles'}[$subs]->{'url'}'";
		$subs++;
	    }
	}
    }
    print "Сабы - @sub<=====\n" if ($debug);
    if ($us &&
	$title_split[1] &&
	!@sub) {
	system("rm \"/tmp/$title_split[1]en.srt\" > /dev/null");
	system("rm \"/tmp/$title_split[1] - $seasonnum"."x"."$seria.en.srt\" > /dev/null");
	system("rm \"/tmp/$title_split[1].en.srt\" > /dev/null");
	print "Работает subliminal\n";
	if ($serial) {
	    $subliminal_command = "cd /tmp; $subliminal \"$title_split[1].s$smartsnum"."e$smartenum\"";
	} else {
	    $subliminal_command = "cd /tmp; $subliminal \"$title_split[1]\"";	
	}
	print "$subliminal_command \n" if ($debug);
	system($subliminal_command);
	@sub[7] = " --sub-file=\"/tmp/$title_split[1]en.srt\"";
	@sub[8] = " --sub-file=\"/tmp/$title_split[1] - $seasonnum"."x"."$seria.en.srt\"";
	@sub[9] = " --sub-file=\"/tmp/$title_split[1].en.srt\"";
    }
}
sub _api {
    _curl("v1/items/$id?nolinks=1");
    #    _curl("v1/items/$id?");
    $apiresp_s_sezonami = $apiresp;
    print Dumper($apiresp) if ($da);
}
sub _api_mid {
    print "api вызов\n" if ($debug); 
    _curl "v1/items/media-links?mid=$mid";
    $apiresp_mid = $apiresp;
    print Dumper($apiresp) if ($debug);
}
sub _file {
    $file = 0;
    #    $pq = "720p" if ($title[$c] =~ "Seinfeld");
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
    print "$file\n" if ($debug);
    $beginning = $file;
    $beginning =~ s/(.*)\/master-v1a1\.m3u.*/$1/;	
    print "$beginning\n" if ($debug);
    if ($ps eq "hls") {
	_audio_hls();
    }

    if ($ps eq "hls4") {
	@notes = `curl -H \"User-Agent: $ua\" -Ls $file`;
	#	$cdn = $file;
	#	$cdn =~ s/^(.*\.net).*$/$1/;
	$bandwidth=0;
	$added=0;
	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split/[\=\,]/, @notes[$a];
	    $pq =~ s/p//;
	    if ($next) {
		$file = "$note[0]$note[1]$note[2]";
		$added = 1;
		$next = 0;
	    }
	    if ($note[16] =~ "audio$pq") {
		$bandwidth=$note[3];
		$next = 1;
	    }
	}
	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split/[\=\,]/, @notes[$a];
	    $pq =~ s/p//;
	    if ($next && !$added) {
		$file = "$note[0]$note[1]$note[2]";
		$added = 1;
		$next = 0;
	    }
	    if ($note[16] =~ "audio720") {
		$bandwidth=$note[3];
		$next = 1;
	    }
	}	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split/[\=\,]/, @notes[$a];
	    $pq =~ s/p//;
	    if ($next && !$added) {
		$file = "$note[0]$note[1]$note[2]";
		$added = 1;
		$next = 0;
	    }
	    if ($note[16] =~ "audio480") {
		$bandwidth=$note[3];
		$next = 1;
	    }
	}
	_audio();
    }
    if ($ps eq "site") {
	print "Выполняем curl $flags -b \"token=$token\; _identity=$identity\" -s $mirror/item/view/$id/s${seasonnum}e$seria\n" if ($debug);
	@tempfile = `curl -H \"User-Agent: $ua\" $flags -b \"token=$token\; _identity=$identity\" -s \"$mirror/item/view/$id/s${seasonnum}e$seria\"`;
	@tempfile1 = grep ( /var\ playlist/, @tempfile);
	@tempfile1[0] =~ s/var playlist = //;
	@tempfile1[0] =~ s/;\n//;
	$tempfile2 = decode_json(@tempfile1[0]);
	$tempfile3 = $tempfile2->[$c]->{'file'};
	print "Команда curl $flags -b \"token=$token\; _identity=$identity\" -s \"$mirror/item/view/$id/s${seasonnum}e$seria\" | grep var\ playlist | sed -e s/var\ playlist\ =\ \[{\"file\":\"// | sed -e s/\",\".*//\" вывела $tempfile3\n" if ($debug);
	@notes = `curl -s -H \"User-Agent: $ua\" $tempfile3`;
	#	$cdn = $file;
	#	$cdn =~ s/^(.*\.net).*$/$1/;
	$bandwidth=0;
	$added=0;
	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split/[\=\,]/, @notes[$a];
	    $pq =~ s/p//;
	    if ($next) {
		$file = "$note[0]\=$note[1]";
		$added = 1;
		$next = 0;
	    }
	    if ($note[16] =~ "audio$pq") {
		$bandwidth=$note[3];
		$next = 1;
	    }
	}
	$next = 0;
	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split/[\=\,]/, @notes[$a];
	    if ($next && !$added) {
		$file = "$note[0]\=$note[1]";
		$added = 1;
		$next = 0;
	    }
	    if ($note[16] =~ "audio720" && !$added) {
		$bandwidth=$note[3];
		$next = 1;
	    }
	}
	$next = 0;
	for($a = 0; $a < scalar(@notes); $a++) {
	    @note = split/[\=\,]/, $notes[$a] if ($notes[$a]);
	    if ($next == 1 and
		!$added) {
		$file = "$note[0]\=$note[1]";
		$added = 1;
		$next = 0;
	    }
	    if ($note[14] =~ /audio480/ or
		$note[16] =~ /audio480/
		) {
		$bandwidth=$note[3];
		$next = 1;
	    }
	}
	_audio();
    }
}
sub _audio {
    @note = '';
    $next = 0;
    $stop = 0;
    $afirst = 1;
    $luckynum = 0;
    $afiles="";
    $num = 1;
    $added = 0;
    $pq =~ s/p//;
    for($a = 0; $a < scalar(@notes); $a++) {
	@note = split /=|,/, @notes[$a];
	if (@note[3] =~ /audio$pq/) {
	    if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]||
		$apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]) {
		if ($serial) {
		    $alang = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'lang'};
		    $alink = @note[9]."=".$note[10];
		    $atitle = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'type'}->{'title'} || "null";
		    $aauthor = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'author'}->{'title'};
		} else {
		    $alang = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'lang'};
		    $alink = @note[9]."=".$note[10];;
		    $atitle = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'type'}->{'title'} || "Null";
		    $aauthor = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'author'}->{'title'};
		}
		chomp $alink;
		if ($afirst) {
		    $afiles = $afiles."aud1\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles."aud1\=$alink|$atitle|$alang" if(!$aauthor);
		    $afirst = 0;
		    $added = 1;
		} else {
		    $afiles = $afiles.",aud$num\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles.",aud$num\=$alink|$atitle|$alang" if(!$aauthor);
		}
		$num++;
		$luckynum++;
	    }
	}
    }
    $stop = 1 if ($added);
    $added = 0;
    for($a = 0; $a < scalar(@notes); $a++) {
	@note = split /=|,/, @notes[$a];
 	if ($note[3] =~ "audio720" and
	    !$stop) {
	    if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]||
		$apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]) {
		if ($serial) {
		    $alang = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'lang'};
		    $alink = @note[9]."=".$note[10];;
		    $atitle = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'type'}->{'title'} || "null";
		    $aauthor = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'author'}->{'title'};
		} else {
		    $alang = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'lang'};
		    $alink = @note[9]."=".$note[10];;
		    $atitle = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'type'}->{'title'} || "Null";
		    $aauthor = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'author'}->{'title'};
		}
		chomp $alink;
		if ($afirst) {
		    $afiles = $afiles."aud1\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles."aud1\=$alink|$atitle|$alang" if(!$aauthor);
		    $afirst = 0;
		    $added = 1;
		} else {
		    $afiles = $afiles.",aud$num\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles.",aud$num\=$alink|$atitle|$alang" if(!$aauthor);
		}
		$num++;
		$luckynum++;
	    }
	}
    }
    $stop = 1 if ($added);
    $added = 0;
    for($a = 0; $a < scalar(@notes); $a++) {
	@note = split /=|,/, @notes[$a];
	if ($note[3] =~ "audio480" && !$stop) {
	    if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]||
		$apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]) {
		if ($serial) {
		    $alang = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'lang'};
		    $alink = $note[9]."=".$note[10];
		    $atitle = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'type'}->{'title'} || "null";
		    $aauthor = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'author'}->{'title'};
		} else {
		    $alang = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'lang'};
		    $alink = $note[9]."=".$note[10];
		    $atitle = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'type'}->{'title'} || "Null";
		    $aauthor = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'author'}->{'title'};
		}
		chomp $alink;
		if ($afirst) {
		    $afiles = $afiles."aud1\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles."aud1\=$alink|$atitle|$alang" if(!$aauthor);
		    $afirst = 0;
		} else {
		    $afiles = $afiles.",aud$num\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		    $afiles = $afiles.",aud$num\=$alink|$atitle|$alang" if(!$aauthor);
		}
		$num++;
		$luckynum++;
	    }
	}
    }
    $added = 1;
}
sub _audio_hls {
    @note = '';
    $next = 0;
    $stop = 0;
    $afirst = 1;
    $luckynum = 0;
    $afiles="";
    $num = 1;
    $added = 0;
    $pq =~ s/p//;
    if ($serial) {
	$number = @{($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'})};
    } else {
	$number = @{($apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'})};
    }
    for($a = 0; $a < $number; $a++) {
	if ($apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]||
	    $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]) {
	    if ($serial) {
		$alang = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'lang'};
		$alink = "$beginning/index-a".$apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'index'}.".m3u8?loc=nl";
		$atitle = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'type'}->{'title'} || "null";
		$aauthor = $apiresp_s_sezonami->{'item'}->{'seasons'}[$season]->{'episodes'}[$c]->{'audios'}[$luckynum]->{'author'}->{'title'};
	    } else {
		$alang = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'lang'};
		$alink = "$beginning/index-a".$apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'index'}.".m3u8?loc=nl";
		$atitle = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'type'}->{'title'} || "Null";
		$aauthor = $apiresp_s_sezonami->{'item'}->{'videos'}[$ver]->{'audios'}[$luckynum]->{'author'}->{'title'};
	    }
	    chomp $alink;
	    if ($afirst) {
		$afiles = $afiles."aud1\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		$afiles = $afiles."aud1\=$alink|$atitle|$alang" if(!$aauthor);
		$afirst = 0;
		$added = 1;
	    } else {
		$afiles = $afiles.",aud$num\=$alink|$atitle ($aauthor)|$alang" if($aauthor);
		$afiles = $afiles.",aud$num\=$alink|$atitle|$alang" if(!$aauthor);
	    }
	    $num++;
	    $luckynum++;
	}
	$added = 1;
    }
}
sub _similar {
    _curl("v1/items/similar?id=$id");
}
sub _subscribe {
    _curl("v1/watching/togglewatchlist?id=$id");
    print "Изменена отметка \"буду смотреть\" для $id\n";
}
# sub _sleep {
#     my $thr = threads->create(sub {
# 	sleep 10;
# 	print "10!\n";
# 			      });
# }
    
sub _mpv {
    @output = 0;
    print "Проигрываем...\n";
    _api_mid() if($nt);
    _file() if($nt);
    if ($ps eq "hls4" or
	$ps eq "hls" or
	$ps eq "site") {
	if($resume == 1 or
	   $nt == 1) {
	    #$command = "$mpv --x11-name=\"resume\" --script-opts=\"unpause=0,start=$start,$afiles\" --window-maximized=no --pause --loop-playlist=1 --no-resume-playback @title[$c] @sub  --user-agent='$ua' \"$file\" 2>&1";
	    #	    system("wmctrl -r :ACTIVE: -b remove,fullscreen");
	    $command = "$mpv --x11-name=\"resume\" --script-opts=\"unpause=0,start=$start,$afiles\" --fullscreen=no --pause --loop-playlist=1 --no-resume-playback @title[$c] @sub  --user-agent='$ua' \"$file\" 2>&1";
	    $resume = 0;
	    $nt = 0;
	} else {
	    $command = "$mpv --pause --script-opts=\"unpause=1,start=$start,$afiles\" --loop-playlist=1 --no-resume-playback --fullscreen=yes @title[$c] @sub --user-agent='$ua' \"$file\" 2>&1";
	    #system("wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz");
	    system("xdotool key super+2");
	    #	    system("wmctrl -r :ACTIVE: -b remove,fullscreen");
	}
    } elsif ($ps eq "http") {
	if($resume == 1 or
	   $nt == 1) {
	    $command = "$mpv --start=$start --fullscreen=no --pause --loop-playlist=1 @title[$c] @sub '$file' --user-agent=\"$ua\" 2>&1";
	}
	else {
	    $command = "$mpv --start=$start --fullscreen=yes --loop-playlist=1 @title[$c] @sub '$file' --user-agent=\"$ua\" 2>&1";
	}
	
	

    } 	

    print $command if ($debug);
    open($fh, "-|", $command);
    binmode($fh,":encoding(UTF-8)");
    $numofiterations = 0;
    $time_c = 0;
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
		print "ВЫХОД!!!\n";
		exit;
	    }
	    if ($output =~ /Failed\ to\ open/) {
		$nt = 1;
	    }
	    
	    if ($output =~ /Exiting\.\.\.\ \(End of file\)/) {
		$quit = 1;
		$start2='';
		$resume = 0;
		$delete = 1;
		_resume_config();
		exit(0) if ($serial != 1);
	    }
	    if ($output =~ /.*quitAAA.*/) {
		$quit = 1;
		$start2='';
		$resume = 0;
		_read_config();
		if ($serial != 1) {
		    $delete = 1;
		    _resume_config();
		    exit;
		}
		else {
		    _resume_config();
		}
	    }
	    if ($output =~ /.*subscribe.*/) {
		if ($serial != 1) {
		}
		else {
		    _subscribe();
		}
	    }
	    if ($output =~ /.*quitBBB.*/) {
		$quit = 1;
		$start2='';
		$c=$c-1;
		$resume = 0;
		_read_config();
	    }
	    if (($output =~ /.*AV:.*/) && ($numofiterations > 1600)) {
		#	    _sleep();
		#	    if (($output =~ /.*AV:.*/) && $thr) {
		$output = substr $output, 0;
		$output =~ s/.*AV..(........)/$1/ ;
		$time = $output;
		_timeconv();
		_time() if ($time_c != $lasttime);
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
    print "Запись временной метки..." if ($debug);
    if ($serial == 0) {
	$version = $ver + 1;
	$timesave = 1;
	$lasttime = $time_c;
	_resume_config();
	_curl("v1/watching/marktime?id=$id&time=$time_c&video=$version");
    }              # запись временной метки
    
    else{
	$timesave = 1;
	$lasttime = $time_c;
	_resume_config();
	_curl("v1/watching/marktime?id=$id&time=$time_c&season=$seasonnum&video=$seria");
    }               # запись временной метки для сериала
}
sub _timeconv {
    $secs = $time;
    $mins = $time;
    $hours = $time;
    $secs =~ s/.*:.*:(.*)/$1/;
    $mins =~ s/.*:(.*):.*/$1/;
    $hours =~ s/(.*):.*:.*/$1/;
    $time_c = $secs + $mins*60 + $hours*3600;
}
