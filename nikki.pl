use strict;
use warnings;
use FindBin;
use File::Path;

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
}elsif($command eq 'new'){
  &make_nikki;
}elsif($command eq 'test'){
  &compile_articles;
}


#### subroutines

## check current state
sub check_build{
  if((-d $dirs->{etc_dir}) or (-d $dirs->{article_dir})){
    return 1;
  }else{
    return 0;
  }
}

## make directory
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

## make essential files
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

## make empty NIKKI
sub make_nikki{
  my $t = localtime;
  my $epoch = time();
  my $proc = $$;
  my ($second, $minute, $hour, $mday, $month, $year) = localtime;
  $month += 1;
  $year  += 1900;
  $month = sprintf("%02d",$month);
  my $day = sprintf("%02d",$mday);
  my $dir = $dirs->{article_dir}.$year.'/'.$month.'/';
  unless(-d $dir){
    mkpath($dir) or die "Could not create directory: $!\n";
  }
  my $filename_base = $year.'_'.$month.'_'.$day.'_';
  my $filename = $filename_base.$epoch.$proc.'.nk';
  for(1 .. 10000){
    my $num = $_;
    my $tmp_filename = $filename_base.$num.'.nk';
    unless(-e $dir.$tmp_filename){
      $filename = $tmp_filename;
      last;
    }
  }
  open(my $fh, ">", $dir.$filename) or die "$!\n";
  print $fh "_=_TITLE_START_=_ title here _=_TITLE_END_=_\n"
    ."_=_TAG_START_=_\nfoo bar baz\n_=_TAG_END_=_\n"
    ."_=_HEAD_START_=_\n_=_HEAD_END_=_\n_=_BODY_BELOW_=_\n";
  close($fh);
  print "empty article created. edit ".$dir.$filename."\n";

}

## compile all articles
sub compile_articles{
  # file search
  my $all_files = [];
  my $years = [];
  my $year_month = [];
  opendir(my $dh, $dirs->{article_dir}) or die "$!";
  while(my $name = readdir $dh){
    if($name =~ /^[1-9]{1}[0-9]{3}$/g){
      push(@$years,$dirs->{article_dir}.$name);
    }
  }
  closedir($dh);
  foreach my $year_dir (@$years){
    opendir(my $dh, $year_dir) or die "$1\n";
    while(my $name = readdir $dh){
      if($name =~ /^[0-9]{2}$/g){
	push(@$year_month,$year_dir.'/'.$name);
      }
    }
    closedir($dh);
  }

  foreach my $year_month_dir (@$year_month){
    opendir(my $dh, $year_month_dir) or die "$1\n";
    while(my $name = readdir $dh){
      if($name =~ /.*?\.nk$/g){
	push(@$all_files,$year_month_dir.'/'.$name);
      }
    }
    closedir($dh);
  }
  # compile
  my $tag_hash = {};
  foreach my $file (@$all_files){
    my @file_array = split('/',$file);
    my $filename = $file_array[$#file_array];
    open(my $fh,"<",$file);
    my $content = '';
    while(<$fh>){
      $content .= $_;
    }
    close($fh);
    my $title = 'NO TITLE';
    if($content =~ /_\=_TITLE_START_\=_(.*?)_\=_TITLE_END_\=_/msg){
      $title = $1;
    }
    my $tag_raw = '';
    if($content =~ /_\=_TAG_START_\=_(.*?)_\=_TAG_END_\=_/msg){
      $tag_raw = $1;
    }
    my @tags = split(/\s/,$tag_raw);
    foreach my $tag (@tags){
      if(defined($tag_hash->{$tag})){
	$tag_hash->{$tag} += 1;
      }else{
	$tag_hash->{$tag} = 1;
      }
    }
    my ($body_obove,$body_below) = split('_=_BODY_BELOW_=_',$content);
    # Specified markup language
    $body_below =~ s/^==h([1-6]{1})\s{1}(.*?)[\r\n|\n|\r]/<h$1> $2 <\/h$1>/msg;
    $body_below =~ s/^==hr/<hr>/msg;
    $body_below =~ s/^==uls(.*?)==ule/<ul>$1<\/ul>/msg;
    $body_below =~ s/==li\s{1}(.*?)([\r\n|\n|\r])/<li>$1<\/li>$2/msg;
    $body_below =~ s/^==codes[\r\n|\n|\r](.*?)==codee/<pre><code>$1<\/code><\/pre>/msg;
  }
}
