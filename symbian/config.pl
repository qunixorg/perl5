#!/usr/bin/perl -w

# Copyright (c) 2004-2005 Nokia.  All rights reserved.

use strict;
use lib "symbian";

print "Configuring...\n";
print "Configuring with: Perl version $] ($^X)\n";

do "sanity.pl";

my %VERSION = %{ do "version.pl" };

printf "Configuring for:  Perl version $VERSION{REVISION}.%03d%03d\n",
  $VERSION{VERSION}, $VERSION{SUBVERSION};

my $VERSION = "$VERSION{REVISION}$VERSION{VERSION}$VERSION{SUBVERSION}";
my $R_V_SV  = "$VERSION{REVISION}.$VERSION{VERSION}.$VERSION{SUBVERSION}";

my $SDK  = do "sdk.pl";
my %PORT = %{ do "port.pl" };

my ( $SYMBIAN_VERSION, $SDK_VERSION ) = ( $SDK =~ m!\\Symbian\\(.+?)\\(.+)$! );

if ($SDK eq 'C:\Symbian\Series60_1_2_CW') {
    ( $SYMBIAN_VERSION, $SDK_VERSION ) = qw(6.1 1.2);
}

my $WIN = $ENV{WIN} ; # 'wins', 'winscw' (from sdk.pl)
my $ARM = 'thumb';    # 'thumb', 'armi'
my $S60SDK = $ENV{S60SDK}; # qw(1.2 2.0 2.1 2.6) (from sdk.pl)

my $UREL = $ENV{UREL}; # from sdk.pl
$UREL =~ s/-ARM-/$ARM/;
my $UARM = $ENV{UARM}; # from sdk.pl

die "$0: SDK not recognized\n"
  if !defined($SYMBIAN_VERSION) || !defined($SDK_VERSION) || !defined($S60SDK);

die "$0: does not know which Windows compiler to use\n"
    unless defined $WIN;

print "Symbian $SYMBIAN_VERSION SDK $S60SDK ($WIN) installed at $SDK\n";

my $CWD = do "cwd.pl";
print "Build directory $CWD\n";

die "$0: '+' in cwd does not work with SDK 1.2\n"
    if $S60SDK eq '1.2' && $CWD =~ /\+/;

my @unclean;
my @mmp;

sub create_mmp {
    my ( $target, $type, @x ) = @_;
    my $miniperl = $target eq 'miniperl';
    my $perl     = $target eq 'perl';
    my $mmp        = "$target.mmp";
    my $targetpath = $miniperl
      || $perl ? "TARGETPATH\t\\System\\Apps\\Perl" : "";
    if ( open( my $fh, ">$mmp" ) ) {
        print "\t$mmp\n";
        push @mmp,     $mmp;
        push @unclean, $mmp;
        print $fh <<__EOF__;
TARGET		$target.$type
TARGETTYPE	$type
$targetpath
EPOCHEAPSIZE	1024 8388608
EPOCSTACKSIZE	65536
EXPORTUNFROZEN
SRCDBG
__EOF__
        print $fh "MACRO\t__SERIES60_1X__\n" if $S60SDK =~ /^1\./;
        print $fh "MACRO\t__SERIES60_2X__\n" if $S60SDK =~ /^2\./;
        my ( @c, %c );
        @c = map  { glob } qw(*.c);       # Find the .c files.
        @c = map  { lc } @c;              # Lowercase the names.
        @c = grep { !/malloc\.c/ } @c;    # Use the system malloc.
        @c = grep { !/main\.c/ } @c;      # main.c must be explicit.
        push @c, map { lc } @x;
        @c = map { s:^\.\./::; $_ } @c;    # Remove the leading ../
        @c = map { $c{$_}++ } @c;          # Uniquefy.
        @c = sort keys %c;                 # Beautify.

        for (@c) {
            print $fh "SOURCE\t\t$_\n";
        }
        print $fh <<__EOF__;
SOURCEPATH	$CWD
USERINCLUDE	$CWD
USERINCLUDE	$CWD\\ext\\DynaLoader
USERINCLUDE	$CWD\\symbian
SYSTEMINCLUDE	\\epoc32\\include\\libc
SYSTEMINCLUDE	\\epoc32\\include
LIBRARY		euser.lib
LIBRARY		estlib.lib
__EOF__
        if ( $miniperl || $perl || $type eq 'dll' ) {
            print $fh <<__EOF__;
LIBRARY		charconv.lib
LIBRARY		commonengine.lib
LIBRARY		hal.lib
LIBRARY		estor.lib
__EOF__
        }
        if ( $type eq 'exe' ) {
            print $fh <<__EOF__;
STATICLIBRARY	ecrt0.lib
__EOF__
        }
        if ($miniperl) {
            print $fh <<__EOF__;
MACRO		PERL_MINIPERL
__EOF__
        }
        if ($perl) {
            print $fh <<__EOF__;
MACRO		PERL_PERL
__EOF__
        }
        print $fh <<__EOF__;
MACRO		PERL_CORE
MACRO		MULTIPLICITY
MACRO		PERL_IMPLICIT_CONTEXT
__EOF__
        unless ( $miniperl || $perl ) {
            print $fh <<__EOF__;
MACRO		PERL_GLOBAL_STRUCT
MACRO		PERL_GLOBAL_STRUCT_PRIVATE
__EOF__
        }
        close $fh;
    }
    else {
        warn "$0: failed to open $mmp for writing: $!\n";
    }
}

sub create_bld_inf {
    if ( open( BLD_INF, ">bld.inf" ) ) {
        print "\tbld.inf\n";
        push @unclean, "bld.inf";
        print BLD_INF <<__EOF__;
PRJ_PLATFORMS
${WIN} ${ARM}
PRJ_MMPFILES
__EOF__
        for (@mmp) { print BLD_INF $_, "\n" }
        close BLD_INF;
    }
    else {
        warn "$0: failed to open bld.inf for writing: $!\n";
    }
}

my %config;

sub load_config_sh {
    if ( open( CONFIG_SH, "symbian/config.sh" ) ) {
        while (<CONFIG_SH>) {
            if (/^(\w+)=['"]?(.*?)["']?$/) {
                my ( $var, $val ) = ( $1, $2 );
                $val =~ s/x.y.z/$R_V_SV/gi;
                $val =~ s/thumb/$ARM/gi;
                $val = "'$SYMBIAN_VERSION'" if $var eq 'osvers';
                $val = "'$SDK_VERSION'"     if $var eq 'sdkvers';
                $config{$var} = $val;
            }
        }
        close CONFIG_SH;
    }
    else {
        warn "$0: failed to open symbian\\config.sh for reading: $!\n";
    }
}

sub create_config_h {
    load_config_sh();
    if ( open( CONFIG_H, ">config.h" ) ) {
        print "\tconfig.h\n";
        push @unclean, "config.h";
        if ( open( CONFIG_H_SH, "config_h.SH" ) ) {
            while (<CONFIG_H_SH>) {
                last if /\#ifndef _config_h_/;
            }
            print CONFIG_H <<__EOF__;
/*
 * Package name      : perl
 * Source directory  : .
 * Configuration time: 
 * Configured by     : 
 * Target system     : symbian
 */

#ifndef _config_h_
__EOF__
            while (<CONFIG_H_SH>) {
                last if /!GROK!THIS/;
                s/\$(\w+)/exists $config{$1} ? $config{$1} : ""/eg;
                s/^#undef\s+(\S+).+/#undef $1/g;
                s:\Q/**/::;
                print CONFIG_H;
            }
            close CONFIG_H_SH;
        }
        else {
            warn "$0: failed to open ../config_h.SH for reading: $!\n";
        }
        close CONFIG_H;
    }
    else {
        warn "$0: failed to open config.h for writing: $!\n";
    }
}

sub create_DynaLoader_cpp {
    print "\text\\DynaLoader\\DynaLoader.cpp\n";
    system(
q[perl -Ilib lib\ExtUtils\xsubpp ext\DynaLoader\dl_symbian.xs >ext\DynaLoader\DynaLoader.cpp]
      ) == 0
      or die "$0: creating DynaLoader.cpp failed: $!\n";
    push @unclean, 'ext\DynaLoader\DynaLoader.cpp';

}

sub create_symbian_port_h {
    print "\tsymbian\\symbian_port.h\n";
    if ( open( SYMBIAN_PORT_H, ">symbian/symbian_port.h" ) ) {
	$S60SDK =~ /^(\d+)\.(\d+)$/;
	my ($sdkmajor, $sdkminor) = ($1, $2);
        print SYMBIAN_PORT_H <<__EOF__;
/* Copyright (c) 2004-2005, Nokia.  All rights reserved. */

#ifndef __symbian_port_h__
#define __symbian_port_h__

#define PERL_SYMBIANPORT_MAJOR $PORT{dll}->{MAJOR}
#define PERL_SYMBIANPORT_MINOR $PORT{dll}->{MINOR}
#define PERL_SYMBIANPORT_PATCH $PORT{dll}->{PATCH}

#define PERL_SYMBIANSDK_FLAVOR	L"Series 60"
#define PERL_SYMBIANSDK_MAJOR	$sdkmajor
#define PERL_SYMBIANSDK_MINOR	$sdkminor

#endif /* #ifndef __symbian_port_h__ */
__EOF__
        close(SYMBIAN_PORT_H);
	push @unclean, 'symbian\symbian_port.h';
    }
    else {
        warn "$0: failed to open symbian/symbian_port.h for writing: $!\n";
    }
}

sub create_perlmain_c {
    print "\tperlmain.c\n";
    system(
q[perl -ne "print qq[    char *file = __FILE__;\n] if /dXSUB_SYS/;print;print qq[    newXS(\"DynaLoader::boot_DynaLoader\", boot_DynaLoader, file);\n] if /dXSUB_SYS/;print qq[EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);\n] if /Do not delete this line/" miniperlmain.c > perlmain.c]
      ) == 0
      or die "$0: Creating perlmain.c failed: $!\n";
    push @unclean, 'perlmain.c';
}

sub create_PerlApp_pkg {
    print "\tsymbian\\PerlApp.pkg\n";
    if ( open( PERLAPP_PKG, ">symbian\\PerlApp.pkg" ) ) {
	my $APPS = $UREL;
	if ($S60SDK ne '1.2' || $SDK =~ m/_CW$/) { # Do only if not in 1.2 VC.
	    $APPS =~ s!\\epoc32\\release\\(.+)\\$UARM$!\\epoc32\\data\\z\\system\\apps\\PerlApp!i;
	}
        print PERLAPP_PKG <<__EOF__;
; !!!!!!   DO NOT EDIT THIS FILE   !!!!!!
; This file is built by symbian\\config.pl.
; Any changes made here will be lost!
;
; PerlApp.pkg
;
; Note that the demo_pl needs to be run to create the demo .pl scripts.
;
; Languages
&EN;

; Standard SIS file header
#{"PerlApp"},(0x102015F6),0,1,0

; Supports Series 60 v0.9
(0x101F6F88), 0, 0, 0, {"Series60ProductID"}

; Files
"$UREL\\PerlApp.APP"-"!:\\system\\apps\\PerlApp\\PerlApp.app"
"$UREL\\PerlRecog.mdl"-"!:\\system\\recogs\\PerlRecog.mdl"
"$APPS\\PerlApp.rsc"-"!:\\system\\apps\\PerlApp\\PerlApp.rsc"
"$APPS\\PerlApp.aif"-"!:\\system\\apps\\PerlApp\\PerlApp.aif"
__EOF__
        if ( open( DEMOS, "perl symbian\\demo_pl list |" ) ) {
            while (<DEMOS>) {
                chomp;
                print PERLAPP_PKG qq["$_"-"!:\\Perl\\$_"\n];
            }
            close(DEMOS);
        }
        close(PERLAPP_PKG);
    }
    else {
        die "$0: symbian\\PerlApp.pkg: $!\n";
    }
    push @unclean, 'symbian\PerlApp.pkg';
}

print "Creating...\n";
create_mmp(
    'miniperl',             'exe',
    'miniperlmain.c',       'symbian\symbian_stubs.c',
    'symbian\PerlBase.cpp', 'symbian\symbian_utils.cpp',
);
create_mmp(
    "perl",                      'exe',
    'perlmain.c',                'symbian\symbian_stubs.c',
    'symbian\symbian_utils.cpp', 'symbian\PerlBase.cpp',
    'ext\DynaLoader\DynaLoader.cpp',
);

create_mmp(
    "perl$VERSION",              'dll',
    'symbian\symbian_dll.cpp',   'symbian\symbian_stubs.c',
    'symbian\symbian_utils.cpp', 'symbian\PerlBase.cpp',
    'ext\DynaLoader\DynaLoader.cpp',
);

create_bld_inf();
create_config_h();
create_perlmain_c();
create_symbian_port_h();
create_DynaLoader_cpp();
create_PerlApp_pkg();

if ( open( PERLAPP_MMP, ">symbian/PerlApp.mmp" ) ) {
    my @MACRO;
    push @MACRO, '__SERIES60_1X__' if $S60SDK =~ /^1\./;
    push @MACRO, '__SERIES60_2X__' if $S60SDK =~ /^2\./;
    print PERLAPP_MMP <<__EOF__;
// !!!!!!   DO NOT EDIT THIS FILE   !!!!!!
// This file is built by symbian\\config.pl.
// Any changes made here will be lost!
TARGET            PerlApp.app
TARGETTYPE        app
UID               0x100039CE 0x102015F6
TARGETPATH        \\system\\apps\\PerlApp
SRCDBG
EXPORTUNFROZEN
SOURCEPATH        .
SOURCE            PerlApp.cpp 

RESOURCE          PerlApp.rss

USERINCLUDE       .
USERINCLUDE       ..
USERINCLUDE       \\symbian\\perl\\$R_V_SV\\include

SYSTEMINCLUDE     \\epoc32\\include
SYSTEMINCLUDE     \\epoc32\\include\\libc

LIBRARY           apparc.lib
LIBRARY           avkon.lib 
LIBRARY           bafl.lib
LIBRARY           charconv.lib 
LIBRARY           commondialogs.lib 
LIBRARY           cone.lib 
LIBRARY           efsrv.lib
LIBRARY           eikcore.lib 
LIBRARY           estlib.lib 
LIBRARY           euser.lib
LIBRARY           perl$VERSION.lib

AIF               PerlApp.aif . PerlAppAif.rss 
__EOF__
    if (@MACRO) {
	for my $macro (@MACRO) {
	    print PERLAPP_MMP <<__EOF__;
MACRO             $macro
__EOF__
        }
    }
    close(PERLAPP_MMP);
    push @unclean, 'symbian\PerlApp.mmp';
}
else {
    warn "$0: failed to create symbian\\PerlApp.mmp";
}

if ( open( MAKEFILE, ">Makefile" ) ) {
    my $perl = "perl$VERSION";
    my $windef1 = "$SDK\\Epoc32\\Build$CWD\\$perl\\$WIN\\$perl.def";
    my $windef2 = "..\\BWINS\\${perl}u.def";
    my $armdef1 = "$SDK\\Epoc32\\Build$CWD\\$perl\\$ARM\\$perl.def";
    my $armdef2 = "..\\BMARM\\${perl}u.def";
    print "\tMakefile\n";
    print MAKEFILE <<__EOF__;
help:
	\@echo === Perl for Symbian ===
	\@echo Useful targets:
	\@echo all win arm clean
	\@echo perldll.sis perlext.sis perlsdk.zip

WIN	= ${WIN}
ARM	= ${ARM}

all:	build

build:	rename_makedef build_win build_arm

@unclean: symbian\\config.pl
	perl symbian\\config.pl

build_win:	abld.bat win_perl.mf win_miniperl.mf win_${VERSION}.mf perldll_win

build_vc6:	abld.bat win_perl.mf win_miniperl.mf win_${VERSION}.mf vc6.mf perldll_win

build_arm:	abld.bat perl_arm miniperl_arm arm_${VERSION}.mf perldll_arm

miniperl_win:	miniperl.mmp abld.bat win_miniperl.mf rename_makedef
	abld build \$(WIN) udeb miniperl

miniperl_arm:	miniperl.mmp abld.bat arm_miniperl.mf rename_makedef
	abld build \$(ARM) $UARM miniperl

miniperl:	miniperl_win miniperl_arm

perl:	perl_win perl_arm

perl_win:	perl.mmp abld.bat win_perl.mf rename_makedef
	abld build \$(WIN) perl

perl_arm:	perl.mmp abld.bat arm_perl.mf rename_makedef
	abld build \$(ARM) $UARM perl

perldll_win: perl${VERSION}_win freeze_win perl${VERSION}_win

perl${VERSION}_win:	perl$VERSION.mmp abld.bat rename_makedef
	abld build \$(WIN) perl$VERSION

perldll_arm: perl${VERSION}_arm freeze_arm perl${VERSION}_arm

perl${VERSION}_arm:	perl$VERSION.mmp arm_${VERSION}.mf abld.bat rename_makedef
	abld build \$(ARM) $UARM perl$VERSION

perldll perl$VERSION:	perldll_win perldll_arm

win:	miniperl_win perl_win perldll_win

arm:	miniperl_arm perl_arm perldll_arm

rename_makedef:
	-ren makedef.pl nomakedef.pl

# Symbian SDK has a makedef.pl of its own,
# and we don't need Perl's.
rerename_makedef:
	-ren nomakedef.pl makedef.pl

abld.bat abld: bld.inf
	bldmake bldfiles

makefiles: win.mf arm.mf vc6.mf

vc6:	win.mf vc6.mf build_vc6

win_miniperl.mf: abld.bat symbian\\config.pl
	abld makefile \$(WIN) miniperl
	echo > win_miniperl.mf

win_perl.mf: abld.bat symbian\\config.pl
	abld makefile \$(WIN) perl
	echo > win_perl.mf

win_${VERSION}.mf: abld.bat symbian\\config.pl
	abld makefile \$(WIN) perl${VERSION}
	echo > win_${VERSION}.mf

symbian\\win.mf:
	cd symbian; make win.mf

win.mf: win_miniperl.mf win_perl.mf win_${VERSION}.mf symbian\\win.mf

arm_miniperl.mf: abld.bat symbian\\config.pl
	abld makefile \$(ARM) miniperl
	echo > arm_miniperl.mf

arm_perl.mf: abld.bat symbian\\config.pl
	abld makefile \$(ARM) perl
	echo > arm_perl.mf

arm_${VERSION}.mf: abld.bat symbian\\config.pl
	abld makefile \$(ARM) perl${VERSION}
	echo > arm_${VERSION}.mf

arm.mf: arm_miniperl.mf arm_perl.mf arm_${VERSION}.mf

vc6.mf: abld.bat symbian\\config.pl
	abld makefile vc6
	echo > vc6.mf

PM  = lib\\Config.pm lib\\Cross.pm lib\\lib.pm ext\\DynaLoader\\DynaLoader.pm ext\\DynaLoader\\XSLoader.pm ext\\Errno\\Errno.pm
POD = lib\\Config.pod

pm:	\$(PM)

XLIB	= -Ixlib\\symbian

XSBOPT	= --win=\$(WIN) --arm=\$(ARM)

lib\\Config.pm:
	copy symbian\\config.sh config.sh
	perl -pi.bak -e "s:x\\.y\\.z+:$R_V_SV:g" config.sh
	perl \$(XLIB) configpm --cross=symbian
	copy xlib\\symbian\\Config.pm lib\\Config.pm
	perl -pi.bak -e "s:x\\.y\\.z:$R_V_SV:g" lib\\Config.pm
	perl -pi.bak -e "s:5\\.\\d+\\.\\d+:$R_V_SV:g" lib\\Config.pm
	-perl -pi.bak -e "s:x\\.y\\.z:$R_V_SV:g" xlib\\symbian\\Config_heavy.pl

lib\\lib.pm:
	perl lib\\lib_pm.PL

ext\\DynaLoader\\DynaLoader.pm:
	-del /f ext\\DynaLoader\\DynaLoader.pm
	perl -Ixlib\\symbian ext\\DynaLoader\\DynaLoader_pm.PL
	perl -pi.bak -e "s/__END__//" DynaLoader.pm
	copy /y DynaLoader.pm ext\\DynaLoader\\DynaLoader.pm
	-del /f DynaLoader.pm DynaLoader.pm.bak

ext\\DynaLoader\\XSLoader.pm:
	perl \$(XLIB) symbian\\xsbuild.pl \$(XSBOPT) XSLoader

ext\\Errno\\Errno.pm:
	perl \$(XLIB) symbian\\xsbuild.pl \$(XSBOPT) Errno

miniperlexe.sis:	miniperl_arm symbian\\makesis.pl
	perl \$(XLIB) symbian\\makesis.pl miniperl

perlexe.sis:	perl_arm symbian\\makesis.pl
	perl \$(XLIB) symbian\\makesis.pl perl


allsis: all miniperlexe.sis perlexe.sis perldll.sis perllib.sis perlext.sis perlapp.sis

perldll.sis perl$VERSION.sis:	perldll_arm pm symbian\\makesis.pl
	perl \$(XLIB) symbian\\makesis.pl perl${VERSION}dll

perllib.sis:	\$(PM)
	perl \$(XLIB) symbian\\makesis.pl perl${VERSION}lib

perlext.sis:	perldll_arm buildext_sis
	perl symbian\\makesis.pl perl${VERSION}ext

EXT = 	Cwd Data::Dumper Devel::Peek Digest::MD5 Errno Fcntl File::Glob Filter::Util::Call IO List::Util MIME::Base64 PerlIO::scalar PerlIO::via SDBM_File Socket Storable Time::HiRes XSLoader attrs

buildext: perldll symbian\\xsbuild.pl
	perl \$(XLIB) symbian\\xsbuild.pl \$(XSBOPT) \$(EXT)

buildext_sis: perldll.sis symbian\\xsbuild.pl
	perl \$(XLIB) symbian\\xsbuild.pl \$(XSBOPT) --sis \$(EXT)

cleanext: symbian\\xsbuild.pl
	perl \$(XLIB) symbian\\xsbuild.pl \$(XSBOPT) --clean \$(EXT)

distcleanext: symbian\\xsbuild.pl
	perl \$(XLIB) symbian\\xsbuild.pl \$(XSBOPT) --distclean \$(EXT)

sis makesis:	miniperl perl perldll pm buildext perlapp.sis
	perl \$(XLIB) symbian\\makesis.pl

APIDIR = \\Symbian\\perl\\$R_V_SV

sdkinstall:
	-mkdir \\Symbian\\perl
	-mkdir \\Symbian\\perl\\$R_V_SV
	-mkdir \$(APIDIR)\\include
	-mkdir \$(APIDIR)\\include\\symbian
	-mkdir \$(APIDIR)\\lib
	-mkdir \$(APIDIR)\\lib\\ExtUtils
	-mkdir \$(APIDIR)\\pod
	-mkdir \$(APIDIR)\\bin
	-mkdir \$(BINDIR)
	copy /y *.h   \$(APIDIR)\\include
	- copy /y *.inc \$(APIDIR)\\include
	copy /y lib\\ExtUtils\\xsubpp  \$(APIDIR)\\lib\\ExtUtils
	copy /y lib\\ExtUtils\\typemap \$(APIDIR)\\lib\\ExtUtils
	copy /y symbian\\xsbuild.pl    \$(APIDIR)\\bin
	copy /y symbian\\PerlBase.h    \$(APIDIR)\\include
	copy /y symbian\\symbian*.h    \$(APIDIR)\\include\\symbian
	copy /y symbian\\PerlBase.pod  \$(APIDIR)\\pod

RELDIR  = $SDK\\epoc32\\release
RELWIN = \$(RELDIR)\\\$(WIN)\\udeb
RELARM = \$(RELDIR)\\\$(ARM)\\$UARM

perlsdk.zip: perldll sdkinstall
	zip -r perl${VERSION}sdk.zip \$(RELWIN)\\perl$VERSION.* \$(RELARM)\\perl$VERSION.* \$(APIDIR)
	\@echo perl${VERSION}sdk.zip created.

perlapp:	sdkinstall perlapp_win perlapp_arm

perlapp_win: config.h
	cd symbian; make perlapp_win

perlapp_arm: config.h
	cd symbian; make perlapp_arm

perlapp_demo_extract:
	cd symbian; make perlapp_demo_extract

perlapp.sis: perlapp_arm
	cd symbian; make perlapp.sis

perlapp.zip:
	cd symbian; zip perlapp.zip PerlApp.* PerlRecog.* PerlBase.* demo_pl

zip:	perlsdk.zip perlapp.zip

freeze:	freeze_win freeze_arm

freeze_win:
	abld freeze \$(WIN) perl$VERSION

freeze_arm:
	abld freeze \$(ARM) perl$VERSION

defrost:	defrost_win defrost_arm

defrost_win:
	-del /f $windef1
	-del /f $windef2

defrost_arm:
	-del /f $armdef1
	-del /f $armdef2

clean_win: abld.bat
	abld clean \$(WIN)

clean_arm: abld.bat
	abld clean \$(ARM)

clean:	clean_win clean_arm rerename_makedef
	-del /f \$(PM)
	-del /f \$(POD)
	-del /f lib\\Config.pm.bak
	-del /f xlib\\symbian\\Config_heavy.pl
	-rmdir /s /q xlib
	-del /f config.sh
	-del /f DynaLoader.pm ext\\DynaLoader\\DynaLoader.pm
	-del /f ext\\DynaLoader\\Makefile
	-del /f ext\\SDBM_File\\sdbm\\Makefile
	-del /f symbian\\*.lst
	-del /f abld.bat @unclean *.pkg *.sis *.zip
	-del /f symbian\\abld.bat symbian\\*.sis symbian\\*.zip
	-del /f symbian\\perl5*.pkg symbian\\miniperl.pkg
	-del arm_*.mf win_*.mf vc6*.mf
	-perl symbian\\xsbuild.pl \$(XSBOPT) --clean \$(EXT)
	-rmdir /s /q perl${VERSION}_Data
	-cd symbian; make clean

reallyclean: abld.bat
	abld reallyclean

distclean: defrost reallyclean clean
	-perl symbian\\xsbuild.pl \$(XSBOPT) --distclean \$(EXT)
	-del /f config.h config.sh.bak symbian\\symbian_port.h
	-del /f Makefile symbian\\PerlApp.mmp
	-del /f BMARM\\*.def
	-del /f *.cwlink *.resources *.pref
	-del /f perl${VERSION}.xml perl${VERSION}.mcp uid.cpp
	-rmdir /s /q BMARM
	cd symbian; make distclean
	-del /f symbian\\Makefile
__EOF__
    close MAKEFILE;
}
else {
    warn "$0: failed to create Makefile: $!\n";
}

if ( open( MAKEFILE, ">symbian/Makefile")) {
    my $wrap = $S60SDK eq '1.2' && $SDK !~ /_CW$/;
    my $ABLD = $wrap ? 'perl b.pl': 'abld';
    print "\tsymbian/Makefile\n";
    print MAKEFILE <<__EOF__;
WIN = $WIN
ARM = $ARM
ABLD = $ABLD

abld.bat:
	bldmake bldfiles

perlapp_win: abld.bat ..\\config.h PerlApp.h PerlApp.cpp
	bldmake bldfiles
	\$(ABLD) build \$(WIN) udeb

perlapp_arm: ..\\config.h PerlApp.h PerlApp.cpp
	bldmake bldfiles
	\$(ABLD) build \$(ARM) $UARM

win.mf:
	bldmake bldfiles
	abld makefile vc6

perlapp_demo_extract:
	perl demo_pl extract

perlapp.sis: perlapp_arm perlapp_demo_extract
	-del /f perlapp.SIS
	makesis perlapp.pkg
	copy /y perlapp.SIS ..\\perlapp.SIS

clean:
	-perl demo_pl cleanup
	-del /f perlapp.sis
	-del /f b.pl

distclean: clean
	-del /f *.cwlink *.resources *.pref
	-del /f PerlApp.xml PerlApp.mcp uid.cpp
	-rmdir /s /q PerlApp_Data
	-del /f abld.bat
__EOF__
    close(MAKEFILE);
    if ($wrap) {
	if ( open( B_PL, ">symbian/b.pl")) {
	    print B_PL <<'__EOF__';
# abld.pl wrapper.

# nmake doesn't like MFLAGS and MAKEFLAGS being set to -w and w.
delete $ENV{MFLAGS};
delete $ENV{MAKEFLAGS};

system("abld @ARGV");
__EOF__
	    close(B_PL);
	} else {
	    warn "$0: failed to create symbian/b.pl: $!\n";
	}
    }
} else {
    warn "$0: failed to create symbian/Makefile: $!\n";
}

print "Deleting...\n";
for my $config (
		# Do not delete config.h here.
		"config.sh",
		"lib\\Config.pm",
		"xlib\\symbian\\Config.pm",
		"xlib\\symbian\\Config_heavy.pl",
		) {
    print "\t$config\n";
    unlink($config);
}

print <<__EOM__;
Configuring done.
Now you can run:
    make all
    make allsis
__EOM__

1;    # Happy End.
