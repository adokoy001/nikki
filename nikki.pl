use strict;
use warnings;
use FindBin;

####################################
#
#              NIKKI
#
#   the simple diary authoring tool
#
####################################

## directory setting
our $base_dir = $FindBin::Bin . '/';

our $dirs =
  {
   article_dir => $base_dir . 'articles/',
   etc_dir => $base_dir . 'etc/',
   tmp_dir => $base_dir . 'etc/tmp/',
   hist_dir => $base_dir . 'etc/hist/',
   config_dir => $base_dir . 'etc/config/',
   template_dir => $base_dir . 'etc/templates/',
   public_dir => $base_dir . 'public/',
   asset_dir => $base_dir . 'public/assets/',
  };

our $files =
  {
   config => $dirs->{config_dir} . 'config.conf',
   template_base => $dirs->{template_dir} . 'base.tmpl',
   template_index => $dirs->{template_dir} . 'index.tmpl',
   template_archive => $dirs->{template_dir} . 'archive.tmpl',
   template_page => $dirs->{template_dir} . 'page.tmpl',
   };

## commands
my $command = $ARGV[0] // 'none';
my $name = $ARGV[1] // 0;

if($command eq 'init'){

  if(&check_build){
    print "NIKKI Already Exists! Aborted.\nTry:  nikki.pl init-force\n";
  }else{
    &make_dirs;
    &make_init_files;
    print "Initialization Complete!\n";
  }
}elsif($command eq 'init-force'){
    &make_dirs;
    &make_init_files;
    print "Initialization Complete!\n";
}


#### subroutines

sub check_build{
  if((-d $dirs->{etc_dir}) or (-d $dirs->{article_dir})){
    return 1;
  }else{
    return 0;
  }
}

sub make_dirs{
  unless(-d $dirs->{article_dir}){
    mkdir $dirs->{article_dir} or die "Could not create $dirs->{article_dir} : $!\n";
  }
  unless(-d $dirs->{etc_dir}){
    mkdir $dirs->{etc_dir} or die "Could not create $dirs->{etc_dir} : $!\n";
  }
  unless(-d $dirs->{tmp_dir}){
    mkdir $dirs->{tmp_dir} or die "Could not create $dirs->{tmp_dir} : $!\n";
  }
  unless(-d $dirs->{hist_dir}){
    mkdir $dirs->{hist_dir} or die "Could not create $dirs->{hist_dir} : $!\n";
  }
  unless(-d $dirs->{config_dir}){
    mkdir $dirs->{config_dir} or die "Could not create $dirs->{config_dir} : $!\n";
  }
  unless(-d $dirs->{template_dir}){
    mkdir $dirs->{template_dir} or die "Could not create $dirs->{template_dir} : $!\n";
  }
  unless(-d $dirs->{public_dir}){
    mkdir $dirs->{public_dir} or die "Could not create $dirs->{public_dir} : $!\n";
  }
  unless(-d $dirs->{asset_dir}){
    mkdir $dirs->{asset_dir} or die "Could not create $dirs->{asset_dir} : $!\n";
  }
}

sub make_init_files{

  if(-f $files->{config}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{config}) or die "$!\n";
    print $fh "{site_name => 'MY NIKKI', author => 'MY NAME'}";
    close($fh);
  }

  if(-f $files->{template_base}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_base}) or die "$!\n";
    print
	  $fh
	  "<!DOCTYPE html>\n<html>\n<head>\n<title>_=_TITLE_=_</title>\n_=_HEAD_=_\n</head>\n"
	  ."<body>\n_=_BODY_=_\n</body>\n</html>\n"
	 ;
    close($fh);
  }

  if(-f $files->{template_index}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_index}) or die "$!\n";
    print
	  $fh
	  "<h1>WELCOME</h1>\n<hr>\n<p>welcome.</p>\n_=_UPDATES_=_",
	 ;
    close($fh);
  }

  if(-f $files->{template_archive}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_archive}) or die "$!\n";
    print
	  $fh
	  "<h1>archive</h1>\n<hr>\n_=_ARCHIVE_=_",
	 ;
    close($fh);
  }

  if(-f $files->{template_page}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_page}) or die "$!\n";
    print
	  $fh
	  "_=_CONTENT_=_",
	 ;
    close($fh);
  }

}


