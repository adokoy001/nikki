use strict;
use warnings;
use utf8;
use FindBin;
use File::Path;
use Digest::MD5 qw(md5_hex);
use Storable qw(nstore retrieve);
use Safe;

####################################
#
#              NIKKI
#   a simple diary authoring tool
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
   entry_dir => $base_dir . 'public/entry/',
   tags_dir => $base_dir . 'public/tags/',
  };

our $files =
  {
   config => $dirs->{config_dir} . 'config.conf',
   hist => $dirs->{hist_dir} . 'hist.db',
   template_base => $dirs->{template_dir} . 'base.tmpl',
   template_index => $dirs->{template_dir} . 'index.tmpl',
   template_archive => $dirs->{template_dir} . 'archive.tmpl',
   template_page => $dirs->{template_dir} . 'page.tmpl',
   template_tags => $dirs->{template_dir} . 'tags.tmpl',
   };

## commands
my $command = $ARGV[0] // 'help';
my $name = $ARGV[1] // 0;

if($command eq 'init'){

  if(&check_build){
    print "NIKKI Already Exists! Aborted.\nTry: perl nikki.pl init-force\n";
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
}elsif($command eq 'rehash'){
  &rehash_db;
}elsif($command eq 'compile'){
  &compile_articles;
}else{
  print 'NIKKI - a simple diary authoring tool.
Usage: perl nikki.pl <command> <option>
 Commands:
  init    : Create diary project.
  new     : Create new article.
  compile : Compile and generate static html file.
  rehash  : ReOrg internal database.
 Example:
  $ perl nikki.pl init
  $ perl nikki.pl new
  $ perl nikki.pl compile
';
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
  unless(-d $dirs->{entry_dir}){
    mkdir $dirs->{entry_dir} or die "Could not create $dirs->{entry_dir} : $!\n";
  }
  unless(-d $dirs->{tags_dir}){
    mkdir $dirs->{tags_dir} or die "Could not create $dirs->{tags_dir} : $!\n";
  }
}

## get current timestamp
sub get_current_timestamp {
  my ($second, $minute, $hour, $mday, $month, $year) = localtime;
  $month += 1;
  $year  += 1900;
  $month = sprintf("%02d",$month);
  my $day = sprintf("%02d",$mday);
  $hour = sprintf("%02d",$hour);
  my $min = sprintf("%02d",$minute);
  my $sec = sprintf("%02d",$second);
  my $current_timestamp = $year.'-'.$month.'-'.$day.' '.$hour.':'.$min.':'.$sec;
  return $current_timestamp;
}

sub load_config{
  open(my $fh, "<", $files->{config});
  my $content = '';
  while(<$fh>){$content .= $_;}
  close($fh);
  my $safe = Safe->new;
  my $config = $safe->reval($content) or die "$!$@";
  return $config;
}


## make essential files
sub make_init_files{

  if(-f $files->{config}){
    print "Already Exists. Skipped.\n";
  }else{
    my $config_init = "
      {
       site_name => 'SITE NAME',
       author => 'AUTHOR',
       whats_new => 5,
       document_root => '/',
       deploy_to => undef,
      };
    ";
    open(my $fh, ">", $files->{config});
    print $fh $config_init;
    close($fh);
  }

  if(-f $files->{hist}){
    print "Already Exists. Skipped.\n";
  }else{
    my $current_timestamp = &get_current_timestamp();
    my $hist_init =
      {
       meta => {
		created_at => $current_timestamp,
		updated_at => $current_timestamp
	       },
       articles => {}
      };
    nstore $hist_init, $files->{hist};
    
  }

  if(-f $files->{template_base}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_base}) or die "$!\n";
    print
	  $fh
	  "<!DOCTYPE html>\n<html>\n<head>\n<title>_=_TITLE_=_</title>\n_=_HEAD_=_\n</head>\n"
	  ."<body>\n_=_BODY_=_\n<hr>\n"
	  ."created at : _=_CREATED_AT_=_<br>"
	  ."updated at : _=_UPDATED_AT_=_<br>"
	  ."author : _=_AUTHOR_=_<br>"
	  ."</body>\n</html>\n"
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

  if(-f $files->{template_tags}){
    print "Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_tags}) or die "$!\n";
    print
	  $fh
	  "<h1>_=_TAG_NAME_=_<h1>\n_=_RELATED_CONTENT_=_",
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
  my $relational_path = $year.'/'.$month.'/';
  my $dir = $dirs->{article_dir}.$relational_path;
  unless(-d $dir){
    mkpath($dir) or die "Could not create directory: $!\n";
  }
  my $filename_base = $year.'_'.$month.'_'.$day.'_';
  my $filename = $filename_base.$epoch.$proc.'.nk';
  for(1 .. 999){
    my $num = $_;
    my $tmp_filename = $filename_base.sprintf("%03d",$num).'.nk';
    unless(-e $dir.$tmp_filename){
      $filename = $tmp_filename;
      last;
    }
  }
  open(my $fh, ">", $dir.$filename) or die "$!\n";
  print $fh "==TITLE_START== title here ==TITLE_END==\n\n"
    ."==SUMMARY_START==\nsummarize this article.\n==SUMMARY_END==\n\n"
    ."==TAG_START==\nfoo bar baz anything\n==TAG_END==\n\n"
    ."==HEAD_START==\n==HEAD_END==\n\n==BODY_BELOW==\n";
  close($fh);
  open(FILE, $dir.$filename) or die "Can't open: $!";
  binmode(FILE);
  my $md5_value =  Digest::MD5->new->addfile(*FILE)->hexdigest;
  close(FILE);
  my $current_timestamp = &get_current_timestamp;
  my $hist_content = retrieve $files->{hist};
  $hist_content->{articles}->{$relational_path.$filename} =
    {
     rel_path => $relational_path,
     filename => $filename,
     created_at => $current_timestamp,
     updated_at => $current_timestamp,
     last_md5 => $md5_value
    };
  nstore $hist_content, $files->{hist};
  print "empty article was created. edit ".$dir.$filename."\n";

}

sub search_all{
  # file search
  my $all_files = [];
  my $all_files_relative = [];
  my $years = [];
  my $year_month = [];
  opendir(my $dh, $dirs->{article_dir}) or die "$!";
  while(my $name = readdir $dh){
    if($name =~ /^[1-9]{1}[0-9]{3}$/g){
      push(@$years,$name);
    }
  }
  closedir($dh);
  foreach my $year_dir (@$years){
    opendir(my $dh, $dirs->{article_dir}.$year_dir) or die "$1\n";
    while(my $name = readdir $dh){
      if($name =~ /^[0-9]{2}$/g){
	push(@$year_month,$year_dir.'/'.$name);
      }
    }
    closedir($dh);
  }

  foreach my $year_month_dir (@$year_month){
    opendir(my $dh, $dirs->{article_dir}.$year_month_dir) or die "$1\n";
    while(my $name = readdir $dh){
      if($name =~ /.*?\.nk$/g){
	push(@$all_files,$dirs->{article_dir}.$year_month_dir.'/'.$name);
	push(@$all_files_relative,$year_month_dir.'/'.$name);
      }
    }
    closedir($dh);
  }
  return ($all_files,$all_files_relative);
}

sub rehash_db{
  my ($all_files,$all_files_relative) = &search_all();
  my $hist = retrieve $files->{hist};
  foreach my $filename (sort {$b cmp $a} @$all_files_relative){
    my $filename_full = $dirs->{article_dir}.$filename;
    if(defined($hist->{articles}->{$filename})){
      open(FILE, $filename_full) or die "Can't open: $!";
      binmode(FILE);
      my $md5_value = Digest::MD5->new->addfile(*FILE)->hexdigest;
      close(FILE);
      if($md5_value ne $hist->{articles}->{$filename}->{last_md5}){
	print "NOTICE: Modified article found. $filename info will be updated.\n";
	$hist->{articles}->{$filename}->{last_md5} = $md5_value;
	$hist->{articles}->{$filename}->{updated_at} = &get_current_timestamp();
      }
    }else{
      print "NOTICE: Unregistered article found. $filename info will be created.\n";
      open(FILE, $filename_full) or die "Can't open: $!";
      binmode(FILE);
      my $md5_value = Digest::MD5->new->addfile(*FILE)->hexdigest;
      close(FILE);
      my @filepath_array = split('/',$filename);
      my $filename_only = $filepath_array[$#filepath_array];
      pop(@filepath_array);
      my $relpath_only = join('/',@filepath_array);
      $hist->{articles}->{$filename}->{rel_path} = $relpath_only;
      $hist->{articles}->{$filename}->{filename} = $filename_only;
      $hist->{articles}->{$filename}->{last_md5} = $md5_value;
      $hist->{articles}->{$filename}->{created_at} = &get_current_timestamp();
      $hist->{articles}->{$filename}->{updated_at} = &get_current_timestamp();
    }
  }
  foreach my $filename (sort {$b cmp $a} keys %{$hist->{articles}}){
    unless(-f $dirs->{article_dir}.$filename){
      print "NOTICE: Deleted file detected. Article info will be removed from DB.\n";
      delete $hist->{articles}->{$filename};
    }
  }
  nstore $hist, $files->{hist};
  print "Complete.\n";
}

sub compile_articles{
  # compile
  &rehash_db();
  my $hist = retrieve $files->{hist};
  my ($all_files,$all_files_relative) = &search_all();
  my $config = &load_config();
  my $tag_counter = {};
  my $tag_related = {};
  my $archive = [];
  my $converted = {};
  foreach my $file_rel ( sort {$b cmp $a} @$all_files_relative){
    my $created_at = $hist->{articles}->{$file_rel}->{created_at};
    my $file = $dirs->{article_dir}.$file_rel;
    my @file_array = split('/',$file);
    my $filename = $file_array[$#file_array];
    open(my $fh,"<",$file);
    my $content = '';
    while(<$fh>){
      $content .= $_;
    }
    close($fh);
    my ($body_above,$body_below) = split('==BODY_BELOW==',$content);
    my $title = 'NO TITLE';
    if($body_above =~ /==TITLE_START==(.*?)==TITLE_END==/msg){
      $title = $1;
      $title =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my $summary = 'NO SUMMARY';
    if($body_above =~ /==SUMMARY_START==(.*?)==SUMMARY_END==/msg){
      $summary = $1;
      $summary =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my $head = '';
    if($body_above =~ /==HEAD_START==(.*?)==HEAD_END==/msg){
      $head = $1;
      $head =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my $tag_raw = '';
    if($body_above =~ /==TAG_START==(.*?)==TAG_END==/msg){
      $tag_raw = $1;
      $tag_raw =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my @tags = split(/ \/,/,$tag_raw);
    foreach my $tag (@tags){
      if(defined($tag_counter->{$tag})){
	$tag_counter->{$tag} += 1;
      }else{
	$tag_counter->{$tag} = 1;
      }
      if(defined($tag_related->{$tag})){
	push(@{$tag_related->{$tag}},
	     created_at => $created_at,
	     title => $title,
	     path => $config->{document_root}.'entry/'.$file_rel,
	    );
      }else{
	$tag_related->{$tag} = [];
	push(@{$tag_related->{$tag}},
	     created_at => $created_at,
	     title => $title,
	     path => $config->{document_root}.'entry/'.$file_rel,
	    );
      }
    }

    push(@$archive,{created_at => $created_at, title => $title, path => $config->{document_root}.'entry/'.$file_rel});

    # Specified markup language
    $body_below =~ s/</&lt;/msg;
    $body_below =~ s/>/&gt;/msg;
    $body_below =~ s/^==h([1-6]{1}) (.*?)$/<h$1>$2<\/h$1>/msg;
    $body_below =~ s/^==hr$/<hr>/msg;
    $body_below =~ s/^==ul(.*?)ul==$/<ul>$1<\/ul>/msg;
    $body_below =~ s/==li (.*?)$/<li>$1<\/li>$2/msg;
    $body_below =~ s/^==precode$(.*?)^precode==$/<pre><code>$1<\/code><\/pre>/msg;
    $body_below =~ s/==code (.*?) code==/<code>$1<\/code>/msg;
    $body_below =~ s/==a (.*?) ==href (.*?) a==/<a href=\"$2\">$1<\/a>/msg;
    $body_below =~ s/==img (.*?) img==/<img src=\"$1\">/msg;
    $body_below =~ s/([\r\n|\n|\r]{1,})([^<>]+?)([\r\n|\n|\r]{2}|\Z)/$1<p>$2<\/p>$3/msg;
    $body_below =~ s/([\r\n|\n|\r]{1,})([^<>]+?)([\r\n|\n|\r]{2}|\Z)/$1<p>$2<\/p>$3/msg;
    $body_below =~ s/<p>([\r\n|\n|\r]{1,})<\/p>/$1/msg;

    $converted->{$file_rel} =
      {
       rel_path => $hist->{articles}->{$file_rel}->{rel_path},
       filename => $hist->{articles}->{$file_rel}->{filename},
       tags => \@tags,
       title => $title,
       summary => $summary,
       head => $head,
       content => $body_below,
      };
  }
  my $template_base = '';
  open(my $fh,"<",$files->{template_base});
  while(<$fh>){$template_base .= $_; }
  close($fh);
  my $template_index;
  open($fh,"<",$files->{template_index});
  while(<$fh>){$template_index .= $_; }
  close($fh);
  my $template_page = '';
  open($fh,"<",$files->{template_page});
  while(<$fh>){$template_page .= $_; }
  close($fh);
  my $template_archive = '';
  open($fh,"<",$files->{template_archive});
  while(<$fh>){$template_archive .= $_; }
  close($fh);
  my $template_tags = '';
  open($fh,"<",$files->{template_tags});
  while(<$fh>){$template_tags .= $_; }
  close($fh);
  
  foreach my $entry (sort {$b cmp $a} keys %{$converted}){
    unless(-d $converted->{$entry}->{rel_path}){
      mkpath($dirs->{entry_dir}.$converted->{$entry}->{rel_path});
    }
    my $body = $template_page;
    my $html = $template_base;
    my $title = $converted->{$entry}->{title};
    my $head = $converted->{$entry}->{head};
    my $created_at = $hist->{articles}->{$entry}->{created_at};
    my $updated_at = $hist->{articles}->{$entry}->{updated_at};
    my $author = $config->{author};
    
    my $content = $converted->{$entry}->{content};
    $body =~ s/_=_CONTENT_=_/$content/;
    $html =~ s/_=_TITLE_=_/$title/;
    $html =~ s/_=_HEAD_=_/$head/;
    $html =~ s/_=_BODY_=_/$body/;
    $html =~ s/_=_CREATED_AT_=_/$created_at/;
    $html =~ s/_=_UPDATED_AT_=_/$updated_at/;
    $html =~ s/_=_AUTHOR_=_/$author/;

    open(my $fh_out,">",$dirs->{entry_dir}.$converted->{$entry}->{rel_path}.$converted->{$entry}->{filename});
    print $fh_out $html;
    close($fh_out);
  }
}
