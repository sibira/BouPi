#!/usr/bin/perl
##############################################################
#BouPi
#Version: 1.0 28/03/2016)
#Copyright (c) 2016 Masahito Hayashi
#This software is released under the MIT Licenses:
#https://opensource.org/licenses/mit-license.php
##############################################################
#モジュール読み込み
use strict;	
use warnings;
use File::stat;
my $aquestalkpi = '/z-data/aquestalkpi/AquesTalkPi -s 70';	#AquesTalkPiのディレクトリとオプション指定
my $targetdir = '/motion';	#キャプチャ画像があるディレクトリ
my $my_no = 'aa:bb:cc:dd:ee:ff';	#Bluetoothデバイス
my $expiretime = 60*60*24*7;	#画像を保存する期間：一週間
my $vol_aq = 50;
my $blue_count = 0;
my $imgdel_count = 0;
my $file_count = 0;
my $blue_status;
my $motion_status;
my $now;
my $unix_time;
while (1) {
	sleep(60);
	$blue_status = `/usr/bin/sudo /usr/bin/hcitool info $my_no 2>&1 | /bin/grep Device`;
	$motion_status = `/usr/bin/pgrep motion`;
	#Enable
	if ( $blue_status ) {
		$blue_count = 0;
		if ( $motion_status ) {
			opendir my $dh, $targetdir or die "$!: $targetdir";
			while ( my $entry = readdir $dh ) {
				my $file = $targetdir."/".$entry;
				if ( -f $file and $file =~ /\.(jpg|gif|png)$/i and stat($file)->mtime > $unix_time ) {
					$file_count++;
				}
			}
			system("sudo service motion stop > /dev/null 2>&1");
			system("amixer set PCM $vol_aq\% > /dev/null 2>&1 ; $aquestalkpi '防犯システムを解除しました。おかえりなさいませー。' | aplay > /dev/null 2>&1 ; sleep 1");
			if ( $file_count ) {
				system("amixer set PCM $vol_aq\% > /dev/null 2>&1 ; $aquestalkpi '$file_count件の画像がありました。' | aplay > /dev/null 2>&1");
			} else {
				system("amixer set PCM $vol_aq\% > /dev/null 2>&1 ; $aquestalkpi '画像ファイルはありませんでした。' | aplay > /dev/null 2>&1");
			}

		}
	}
	#Disable
	if ( ! $blue_status and ! $motion_status ) {
		$blue_count++;
		if ( $blue_count > 2 ) {
			system("sudo service motion start > /dev/null 2>&1");
			system("amixer set PCM $vol_aq\% > /dev/null 2>&1 ; $aquestalkpi '防犯システムを有効にしましたー。' | aplay > /dev/null 2>&1");
			$unix_time = time();
			$file_count = 0;
		}
	}
	#img-delete (10分毎)
	$imgdel_count++;
	if ( $imgdel_count > 10 ) {
		$now = time;
		opendir my $dh, $targetdir or die "$!: $targetdir";
		while ( my $entry = readdir $dh ) {
			my $file = $targetdir."/".$entry;
			if ( -f $file and $file =~ /\.(jpg|gif|png)$/i and stat($file)->mtime < $now - $expiretime ) {
				unlink $file;
			}
		}
		$imgdel_count = 0;
	}
}
exit;
