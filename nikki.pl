use strict;
use warnings;
use utf8;
use FindBin;
use File::Path;
use Digest::MD5 qw(md5_hex);
use Storable qw(nstore retrieve);
use Safe;
use lib "$FindBin::Bin/etc";

our $version = 'v1.0.0';

my $user_function_load = eval{
  require NikkiUserFunction;
  1;
  };

my $text_markdown_load = eval {
  require Text::Markdown;
  1;
  };

$Storable::canonical = 1;

###################################################
#
#  NIKKI
#   a simple diary authoring tool.
#
#  Author: Toshiaki Yokoda
#   adokoy001@gmail.com
#
#  License: Artistic License 2.0
#   https://opensource.org/licenses/Artistic-2.0
#
#  This Perl program depends only on core modules.
#  [perl 5.10 or later is required]
#
###################################################

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
   template_tag_index => $dirs->{template_dir} . 'tag_index.tmpl',
   template_page => $dirs->{template_dir} . 'page.tmpl',
   template_tags => $dirs->{template_dir} . 'tags.tmpl',
   user_function => $dirs->{etc_dir} . 'NikkiUserFunction.pm',
   };

## commands
my $command = $ARGV[0] // 'help';
my $name = $ARGV[1] // '';

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
  &make_nikki($name);
}elsif($command eq 'newmd'){
  &make_nikki($name,undef,'.md');
}elsif($command eq 'dnew'){
  &make_nikki($name,'draft');
}elsif($command eq 'dnewmd'){
  &make_nikki($name,'draft','.md');
}elsif($command eq 'rehash'){
  &rehash_db;
}elsif($command eq 'gen'){
  &compile_articles;
}elsif($command eq 'info'){
  &show_info;
  }else{
    print 'NIKKI - a simple diary authoring tool. version: '.$version."\n";
    if(defined($text_markdown_load) and $text_markdown_load == 1){
      print " Markdown is available!\n";
    }else{
      print " Markdown is not available!\n Please install Text::Markdown if you want to write by it.\n";
    }
    print 'Usage: perl nikki.pl <command>'."\n"
      .'Commands:'."\n"
      .'  init    : Create new diary project.'."\n"
      .'  new     : Create new article.'."\n"
      .'  newmd   : Create new Markdown article.'."\n"
      .'  dnew    : Create new draft.'."\n"
      .'  dnewmd  : Create new Markdown draft.'."\n"
      .'  gen     : Compile and generate static html file.'."\n"
      .'  rehash  : ReOrg internal database.'."\n"
      .'  info    : Show all articles information'."\n"
      .' Example:'."\n"
      .'  $ perl nikki.pl init'."\n"
      .'  $ perl nikki.pl new'."\n"
      .'  $ perl nikki.pl gen'."\n"
      .'How to Update:'."\n"
      .' All You Need Is Execute This.'."\n"
      .'  $ rm nikki.pl && wget https://raw.githubusercontent.com/adokoy001/nikki/master/nikki.pl'."\n";
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

## escape_html
sub escape_html {
  my $input = shift;
  if(defined($input) and $input ne ''){
    $input =~ s/&/&amp;/msg;
    $input =~ s/</&lt;/msg;
    $input =~ s/>/&gt;/msg;
    $input =~ s/"/&quot;/msg;
    return $input;
  }else{
    return '';
  }
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

sub gen_rand{
  my $length = 128;
  my @chars = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');
  my $output = '';
  for(1 .. $length){
    my $tmp = $chars[int(rand($#chars+1))];
    $output = $output . $tmp;
  }
  return $output;
}

## make essential files
sub make_init_files{

  if(-f $base_dir.'.gitignore'){
    print ".gitignore Already Exists. Development environment? Skipped.\n";
  }else{
    my $gitignore = "
README.md
nikki.pl
public/
    ";
    open(my $fh, ">", $base_dir.'.gitignore');
    print $fh $gitignore;
    close($fh);
  }


  if(-f $files->{user_function}){
    print "User function Already exists. Skipped.\n";
  }else{

    my $user_function_content = 'package NikkiUserFunction;
use strict;
use warnings;
use utf8;
use Exporter \'import\';
our @EXPORT = qw/entry_filter archive_generator tag_index_generator related_content/;

sub escape_html {
  my $input = shift;
  if(defined($input) and $input ne ""){
    $input =~ s/&/&amp;/msg;
    $input =~ s/</&lt;/msg;
    $input =~ s/>/&gt;/msg;
    $input =~ s/"/&quot;/msg;
    return $input;
  }else{
    return "";
  }
}

sub entry_filter(){
  my $input = shift;
  ## write filter.
  my $output = $input;
  return $output;
}

sub archive_generator(){
  ## this will work on _=_USER_DEFINED_ARCHIVE_=_ label.
  my $archive = shift;
  my $archive_list = "";
  $archive_list .= "<ul>\n";
  foreach my $entry (@$archive){
    my ($date) = (split("/",$entry->{www_path}))[4];
    my ($yyyy,$mm,$dd) = (split("_",$date))[0,1,2];
    $archive_list .= "  <li> $yyyy-$mm-$dd : <a href=\"$entry->{www_path}\"> $entry->{title} </a> - $entry->{summary} </li>\n";
  }
  $archive_list .= "</ul>\n";
  return $archive_list;
}

sub tag_index_generator(){
  ## this will work on _=_USER_DEFINED_TAG_INDEX_=_ label.
  my $tag_info = shift;
  ## write tag index html content generator.
  my $body_tag_index .= "<ul>\n";
  foreach my $tmp_tag (sort keys %$tag_info){
    my $tag_link = $tag_info->{$tmp_tag}->{path};
    my $tag_real_path = $tag_info->{$tmp_tag}->{real_path};
    my $tag_counter = $tag_info->{$tmp_tag}->{counter};
    $body_tag_index .= "<li><a href=\"$tag_link\"> $tmp_tag ($tag_counter)</a></li>\n";
  }
  $body_tag_index .= "</ul>\n";
  return $body_tag_index;
}

sub related_content(){
  my $tag_related = shift;
  my $related_list = "<ul>\n";
  foreach my $entry (@$tag_related){
    my ($date) = (split("/",$entry->{path}))[4];
    my ($yyyy,$mm,$dd) = (split("_",$date))[0,1,2];
    $related_list .= "<li> $yyyy-$mm-$dd : <a href=\"" . $entry->{path} . "\">"
      . &escape_html($entry->{title}) . "</a></li>\n";
  }
  $related_list .= "</ul>\n";
  return $related_list;
}

sub whats_new(){
  my $archive = shift;
  my $config = shift;
  my $updates = "<ul>\n";
  my $counter = 0;
  foreach my $entry (@$archive){
    $counter++;
    if($counter > $config->{whats_new}){
      last;
    }else{
      $updates .= \'<li>\'.$entry->{created_at}
	.\': <a href="\'.$entry->{www_path}
	.\'">\'.$entry->{title}
	."</a> - ".&escape_html($entry->{summary})." - </li>\n";
    }
  }
  $updates .= "</ul>\n";
  return $updates;
}

sub related_tags(){
  my $tmp_tags = shift;
  my $tag_info = shift;
  my $tmp_tag_html = \'\';
  $tmp_tag_html .= "<ul>\n";
  foreach my $tmp_tag (@$tmp_tags){
    $tmp_tag_html .= "<li> <a href=\"".$tag_info->{$tmp_tag}->{path}."\">".&escape_html($tmp_tag)."</a></li>\n";
  }
  $tmp_tag_html .= "</ul>\n";
  return $tmp_tag_html;
}

1;
';
    open(my $fh, ">", $files->{user_function});
    print $fh $user_function_content;
    close($fh);
  }

  if(-f $files->{config}){
    print "Config File Already Exists. Skipped.\n";
  }else{
    my $config_init = "
      {
       site_name => 'SITE NAME',
       author => 'AUTHOR',
       whats_new => 10,
       document_root => '/',
       twitter_site_name => '',
       twitter_creator => '',
       tag_unification => 'case_sensitive',
       url => 'https://example.com',
       og_default_image => '',
       og_default_locale => '',
      };
    ";
    open(my $fh, ">", $files->{config});
    print $fh $config_init;
    close($fh);
  }

  if(-f $files->{hist}){
    print "Internal DB Already Exists. Skipped.\n";
  }else{
    my $current_timestamp = &get_current_timestamp();
    my $hist_init =
      {
       meta => {
		created_at => $current_timestamp,
		updated_at => $current_timestamp,
	       },
       articles => {}
      };
    nstore $hist_init, $files->{hist};
    
  }

  if(-f $files->{template_base}){
    print "Base Template Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_base}) or die "$!\n";
    print
	  $fh
	  "<!DOCTYPE html>\n<html>\n<head>\n_=_META_INFO_=_\n<title>_=_TITLE_=_ - _=_SITE_NAME_=_</title>\n_=_HEAD_=_\n</head>\n"
	  ."<body><a href=\"/\">TOP</a> | <a href=\"/tags.html\">TAG LIST<a> | <a href=\"/archive.html\">ARCHIVES</a>\n"
	  ."<hr>\n_=_BODY_=_\n</body>\n</html>\n"
	 ;
    close($fh);
  }

  if(-f $files->{template_index}){
    print "Index Template Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_index}) or die "$!\n";
    print
	  $fh
	  "<h1>WELCOME</h1>\n<hr>\n<p>welcome.</p>\n_=_UPDATES_=_",
	 ;
    close($fh);
  }

  if(-f $files->{template_archive}){
    print "Archives Template Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_archive}) or die "$!\n";
    print
	  $fh
	  "<h1>archives</h1>\n<hr>\n_=_ARCHIVE_=_",
	 ;
    close($fh);
  }

  if(-f $files->{template_page}){
    print "Article Template Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_page}) or die "$!\n";
    print
	  $fh
	  "_=_CONTENT_=_\n"
	  ."<hr><section>_=_RELATED_TAGS_=_</section>\n"
	  ."<section>prev:_=_PREVIOUS_=_ next:_=_NEXT_=_</section>\n"
	  ."<section>\n"
	  ."created at : _=_CREATED_AT_=_<br>\n"
	  ."updated at : _=_UPDATED_AT_=_<br>\n"
	  ."author : _=_AUTHOR_=_<br>\n"
	  ."</section>\n"
	 ;
    close($fh);
  }

  if(-f $files->{template_tag_index}){
    print "Tag Index Template Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_tag_index}) or die "$!\n";
    print
	  $fh
	  "<h1>TAG LIST</h1>\n<hr>\n_=_TAG_INDEX_=_",
	 ;
    close($fh);
  }

  if(-f $files->{template_tags}){
    print "Tags Template Already Exists. Skipped.\n";
  }else{
    open(my $fh, ">", $files->{template_tags}) or die "$!\n";
    print
	  $fh
	  "<h1>TAG: _=_TAG_NAME_=_</h1>\n<hr>\n_=_RELATED_CONTENT_=_",
	 ;
    close($fh);
  }

}

## make empty NIKKI
sub make_nikki{
  my $name = shift;
  my $mode = shift // '';
  my $type = shift // '.nk';
  my $t = localtime;
  my $epoch = time();
  my $proc = $$;
  my ($second, $minute, $hour, $mday, $month, $year) = localtime;
  $month += 1;
  $year  += 1900;
  $month = sprintf("%02d",$month);
  my $day = sprintf("%02d",$mday);
  my $relational_path = $year.'/'.$month.'/';
  my $dir;
  if($mode eq 'draft'){
    $dir = $dirs->{article_dir}.'draft/'.$relational_path;
  }else{
    $dir = $dirs->{article_dir}.$relational_path;
  }
  unless(-d $dir){
    mkpath($dir) or die "Could not create directory: $!\n";
  }
  my $filename_base = $year.'_'.$month.'_'.$day.'_';
  my $filename = $filename_base.'999X_'.$epoch.$proc.$name.$type;
  for(1 .. 999){
    my $num = $_;
    my $tmp_filename = $filename_base.sprintf("%03d",$num);
    my $tmp_filename_with_name = $filename_base.sprintf("%03d",$num).$name;
    if(!(-e $dir.$tmp_filename.'.nk') and !(-e $dir.$tmp_filename.'.md') and $name eq ''){
      $filename = $tmp_filename.$type;
      last;
    }elsif(!(-e $dir.$tmp_filename_with_name.'.nk') and !(-e $dir.$tmp_filename_with_name.'.md') and $name ne ''){
      $filename = $tmp_filename_with_name.$type;
      last;
    }
  }
  open(my $fh, ">", $dir.$filename) or die "$!\n";
  print $fh "==TITLE_START==\ntitle here\n==TITLE_END==\n\n"
    ."==OG_IMAGE \n==OG_LOCALE \n\n"
    ."==SUMMARY_START==\nsummarize this article.\n==SUMMARY_END==\n\n"
    ."==TAG_START==\nfoo bar baz anything\n==TAG_END==\n\n"
    ."==HEAD_START==\n==HEAD_END==\n\n==BODY_BELOW==\n";
  close($fh);
  open(FILE, $dir.$filename) or die "Can't open: $!";
  binmode(FILE);
  my $md5_value =  Digest::MD5->new->addfile(*FILE)->hexdigest;
  close(FILE);
  if($mode ne 'draft'){
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
    print "Empty article was created. edit ".$dir.$filename."\n";
  }else{
    print "Empty draft was created. edit ".$dir.$filename."\n";
  }
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
      if($name =~ /.*?(\.nk|\.md)$/g){
	push(@$all_files,$dirs->{article_dir}.$year_month_dir.'/'.$name);
	push(@$all_files_relative,$year_month_dir.'/'.$name);
      }
    }
    closedir($dh);
  }
  return ($all_files,$all_files_relative);
}

sub show_info{
  my ($all_files,$all_files_relative) = &search_all();
  my $hist = retrieve $files->{hist};
  foreach my $filename (sort {$a cmp $b} @$all_files_relative){
    my $filename_full = $dirs->{article_dir}.$filename;
    if(defined($hist->{articles}->{$filename})){
      print "========== RECORD ST ==========\n";
      print "FILENAME    : $filename\n";
      print "CREATED_AT  : ".$hist->{articles}->{$filename}->{created_at}."\n";
      print "LAST_UPDATE : ".$hist->{articles}->{$filename}->{updated_at}."\n";
      print "HISTORY     : \n";
      my $history = [];
      if(defined($hist->{articles}->{$filename}->{history})){
	$history = $hist->{articles}->{$filename}->{history};
      }
      for(my $ite = 0; $ite <= $#$history; $ite++){
	print " [".sprintf("%3s",$ite+1)."] UPDATED_AT: ".$history->[$ite]->{updated_at}." / MD5: ".$history->[$ite]->{md5}."\n";
      }
      print "========== RECORD EN ==========\n";
    }
  }
}

sub rehash_db{
  my ($all_files,$all_files_relative) = &search_all();
  my $hist = retrieve $files->{hist};
  foreach my $filename (sort {$b cmp $a} @$all_files_relative){
    my $filename_full = $dirs->{article_dir}.$filename;
    if(defined($hist->{articles}->{$filename})){
      my $current_update_at = $hist->{articles}->{$filename}->{updated_at};
      my $current_last_md5 = $hist->{articles}->{$filename}->{last_md5};
      my $history = [];
      if(defined($hist->{articles}->{$filename}->{history})){
	$history = $hist->{articles}->{$filename}->{history};
      }
      open(FILE, $filename_full) or die "Can't open: $!";
      binmode(FILE);
      my $md5_value = Digest::MD5->new->addfile(*FILE)->hexdigest;
      close(FILE);
      if($md5_value ne $hist->{articles}->{$filename}->{last_md5}){
	print "NOTICE: Modified article found. $filename Internal DB will be updated.\n";
	$hist->{articles}->{$filename}->{last_md5} = $md5_value;
	$hist->{articles}->{$filename}->{updated_at} = &get_current_timestamp();
	push(@$history,{updated_at => $current_update_at, md5 => $current_last_md5});
	$hist->{articles}->{$filename}->{history} = $history;
      }
    }else{
      print "NOTICE: Unregistered article found. $filename Internal DB entry will be created.\n";
      open(FILE, $filename_full) or die "Can't open: $!";
      binmode(FILE);
      my $md5_value = Digest::MD5->new->addfile(*FILE)->hexdigest;
      close(FILE);
      my @filepath_array = split('/',$filename);
      my $filename_only = $filepath_array[$#filepath_array];
      pop(@filepath_array);
      my $relpath_only = join('/',@filepath_array);
      $hist->{articles}->{$filename}->{rel_path} = $relpath_only . '/';
      $hist->{articles}->{$filename}->{filename} = $filename_only;
      $hist->{articles}->{$filename}->{last_md5} = $md5_value;
      $hist->{articles}->{$filename}->{created_at} = &get_current_timestamp();
      $hist->{articles}->{$filename}->{updated_at} = &get_current_timestamp();
    }
  }
  foreach my $filename (sort {$b cmp $a} keys %{$hist->{articles}}){
    unless(-f $dirs->{article_dir}.$filename){
      print "NOTICE: Deleted file detected. Article info will be removed from Internal DB.\n";
      delete $hist->{articles}->{$filename};
    }
  }
  nstore $hist, $files->{hist};
  print "Rehash Internal DB: OK!\n";
}

sub compile_articles{
  # compile
  print "Starting compile and generate html files.\n";
  &rehash_db();
  my $hist = retrieve $files->{hist};
  print "Load Internal DB: OK.\n";
  my ($all_files,$all_files_relative) = &search_all();
  print "Search All entries: OK.\n";
  my $config = &load_config();
  print "Load Config: OK.\n";
  my $url_base = '';
  unless(-d $dirs->{tags_dir}){
    mkpath($dirs->{tags_dir}) or die "Could not create directory: $!\n";
  }
  unless(-d $dirs->{entry_dir}){
    mkpath($dirs->{entry_dir}) or die "Could not create directory: $!\n";
  }
  unless(-d $dirs->{asset_dir}){
    mkpath($dirs->{asset_dir}) or die "Could not create directory: $!\n";
  }
  if(defined($config->{url}) and $config->{url} ne ''){
    $url_base = $config->{url};
  }
  my $og_default_image_str = "";
  if(defined($config->{og_default_image}) and $config->{og_default_image} ne ''){
    $og_default_image_str = "<meta property=\"og:image\" content=\"".$url_base. $config->{og_default_image}."\"/>\n";
  }
  my $twitter_default_image_str = "";
  if(defined($config->{og_default_image}) and $config->{og_default_image} ne ''){
    $twitter_default_image_str = "<meta property=\"twitter:image\" content=\"".$url_base.$config->{og_default_image}."\"/>\n";
  }
  my $og_default_locale_str = "";
  if(defined($config->{og_default_locale}) and $config->{og_default_locale} ne ''){
    $og_default_locale_str = "<meta property=\"og:locale\" content=\"".$config->{og_default_locale}."\"/>\n";
  }
  my $tag_info = {};
  my $archive = [];
  my $converted = {};
  ## compile all articles.
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
    my $tmp_path = $config->{document_root}.'entry/'.$file_rel;
    my $extension = '.nk';
    if($tmp_path =~ /\.md$/){
      $extension = '.md';
    }
    $tmp_path =~ s/(\.nk|\.md)$/\.html/;
    my ($body_above,$body_below) = split('==BODY_BELOW==',$content);
    my $title = 'NO TITLE';
    if($body_above =~ /==TITLE_START==(.*?)==TITLE_END==/msg){
      $title = $1;
      $title =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my $og_image = '';
    if($body_above =~ /==OG_IMAGE (.*?)$/msg){
      $og_image = $1;
      $og_image =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my $og_locale = '';
    if($body_above =~ /==OG_LOCALE (.*?)$/msg){
      $og_locale = $1;
      $og_locale =~ s/^\s*(.+?)\s*$/$1/msg;
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
    my $tag_raw = 'NOTAG';
    my $new_body_above = $body_above; # buggy
    if($new_body_above =~ /==TAG_START==(.*?)==TAG_END==/msg){
      $tag_raw = $1;
      $tag_raw =~ s/^\s*(.+?)\s*$/$1/msg;
    }
    my @tags = split(/ /,$tag_raw);
    my @tags_unified;
    my $tmp_counter;
    foreach my $tag (@tags){
      if(defined($config->{tag_unification})){
	if($config->{tag_unification} eq 'upper'){
	  $tag = uc($tag);
	}elsif($config->{tag_unification} eq 'lower'){
	  $tag = lc($tag);
	}
      }
      my $tag_hex = md5_hex($tag . md5_hex($tag) . $tag);
      my $tag_file_path = $config->{document_root}.'tags/'.$tag_hex.'.html';
      my $tag_file_real_path = $dirs->{tags_dir}.$tag_hex.'.html';
      $tag_info->{$tag}->{path} = $tag_file_path;
      $tag_info->{$tag}->{real_path} = $tag_file_real_path;

      unless(defined($tmp_counter->{$tag})){
	push(@tags_unified,$tag);
      }
      $tmp_counter->{$tag} = 1;
      if(defined($tag_info->{$tag}) and defined($tag_info->{$tag}->{counter})){
	$tag_info->{$tag}->{counter} += 1;
      }else{
	$tag_info->{$tag}->{counter} = 1;
      }
      if(defined($tag_info->{$tag}) and defined($tag_info->{$tag}->{related})){
	push(@{$tag_info->{$tag}->{related}},
	     {
	      created_at => $created_at,
	      title => $title,
	      path => $tmp_path,
	     }
	    );
      }else{
	$tag_info->{$tag}->{related} = [];
	push(@{$tag_info->{$tag}->{related}},
	     {
	      created_at => $created_at,
	      title => $title,
	      path => $tmp_path,
	     }
	    );
      }
    }


    if($extension eq '.md'){
      if(defined($text_markdown_load) and $text_markdown_load == 1){
	$body_below = &Text::Markdown::markdown($body_below);
      }else{
	warn("WARN: No Text::Markdown module found! $file_rel will be ignored.");
	next;
      }
    }else{
      ## .nk style
      # escape raw html
      my $escaped_text;
      while($body_below =~ /==literal(.+?)literal==/ms){
	my $tmp_raw_html = $1;
	my $rand = &gen_rand();
	$escaped_text->{$rand} = $tmp_raw_html;
	$body_below =~ s/==literal(.+?)literal==/$rand/ms;
      }
      # Specified markup language
      $body_below =~ s/</&lt;/msg;
      $body_below =~ s/>/&gt;/msg;
      $body_below =~ s/^==h([1-6]{1}) (.*?)$/<h$1>$2<\/h$1>/msg;
      $body_below =~ s/^==hr$/<hr>/msg;
      ## lists
      $body_below =~ s/^==ul(.*?)ul==$/<ul>$1<\/ul>/msg;
      $body_below =~ s/^==oln(.*?)oln==$/<ol type="1">$1<\/ol>/msg;
      $body_below =~ s/^==ola(.*?)ola==$/<ol type="a">$1<\/ol>/msg;
      $body_below =~ s/^==olA(.*?)olA==$/<ol type="A">$1<\/ol>/msg;
      $body_below =~ s/^==oli(.*?)oli==$/<ol type="i">$1<\/ol>/msg;
      $body_below =~ s/^==olI(.*?)olI==$/<ol type="I">$1<\/ol>/msg;
      $body_below =~ s/==li (.*?)$/<li>$1<\/li>/msg;
      ## definition
      $body_below =~ s/^==dl(.*?)dl==$/<dl>$1<\/dl>/msg;
      $body_below =~ s/==dt (.*?)$/<dt>$1<\/dt>/msg;
      $body_below =~ s/==dd (.*?)$/<dd>$1<\/dd>/msg;
      ## coding
      $body_below =~ s/^==precode[\r\n|\n|\r]{1}(.*?)^precode==$/<pre><code>$1<\/code><\/pre>/msg;
      $body_below =~ s/^==pcode[\r\n|\n|\r]{1}(.*?)^pcode==$/<pre><code>$1<\/code><\/pre>/msg;
      $body_below =~ s/==code (.*?) code==/<code>$1<\/code>/msg;
      ## modification
      $body_below =~ s/==big (.*?) big==/<big>$1<\/big>/msg;
      $body_below =~ s/==small (.*?) small==/<small>$1<\/small>/msg;
      $body_below =~ s/==del (.*?) del==/<strike>$1<\/strike>/msg;
      $body_below =~ s/==st (.*?) st==/<strong>$1<\/strong>/msg;
      $body_below =~ s/==dfn (.*?) dfn==/<dfn>$1<\/dfn>/msg;
      $body_below =~ s/==em (.*?) em==/<em>$1<\/em>/msg;
      $body_below =~ s/==i (.*?) i==/<i>$1<\/i>/msg;
      $body_below =~ s/==b (.*?) b==/<b>$1<\/b>/msg;
      $body_below =~ s/==u (.*?) u==/<u>$1<\/u>/msg;
      $body_below =~ s/==span (.*?) ==s (.*?) ==c (.*?) span==/<span style="$2" class="$3">$1<\/span>/msg;
      $body_below =~ s/==span (.*?) ==c (.*?) ==s (.*?) span==/<span class="$2" style="$3">$1<\/span>/msg;
      $body_below =~ s/==span (.*?) ==s (.*?) span==/<span style="$2">$1<\/span>/msg;
      $body_below =~ s/==span (.*?) ==c (.*?) span==/<span class="$2">$1<\/span>/msg;
      ## link
      $body_below =~ s/==a (.*?) ==href (.*?) a==/<a href=\"$2\">$1<\/a>/msg;
      ### suger
      $body_below =~ s/==link (.*?) link==/<a href=\"$1\">$1<\/a>/msg;
      $body_below =~ s/==img (.*?) img==/<img src=\"$1\">/msg;
      ## finalize
      $body_below =~ s/([\r\n|\n|\r]{1,})([^<>]+?)([\r\n|\n|\r]{2}|\Z)/$1<p>$2<\/p>$3/msg;
      $body_below =~ s/([\r\n|\n|\r]{1,})([^<>]+?)([\r\n|\n|\r]{2}|\Z)/$1<p>$2<\/p>$3/msg;
      $body_below =~ s/<p>([\r\n|\n|\r]{1,})<\/p>/$1/msg;
      
      sub remove_tag(){
	my $str = shift;
	$str =~ s/<p>//msg;
	$str =~ s/<\/p>//msg;
	my $output = '<pre><code>' . $str . '</pre></code>';
	return $output;
      }
      $body_below =~ s/^<pre><code>(.*?)<\/code><\/pre>$/&remove_tag($1)/emsg;
      
      if(defined($user_function_load) and $user_function_load == 1){
	if(defined(&NikkiUserFunction::entry_filter)){
	  $body_below = NikkiUserFunction::entry_filter($body_below);
	}
      }

      # restore escaped raw html
      foreach my $key (sort keys %$escaped_text){
	my $tmp_text = $escaped_text->{$key};
	$body_below =~ s/$key/$tmp_text/;
      }
      
    }

    $converted->{$file_rel} =
      {
       rel_path => $hist->{articles}->{$file_rel}->{rel_path},
       filename => $hist->{articles}->{$file_rel}->{filename},
       www_path => $tmp_path,
       og_image => $og_image,
       og_locale => $og_locale,
       tags => \@tags_unified,
       title => $title,
       summary => $summary,
       head => $head,
       content => $body_below,
      };
  }


  if(defined($text_markdown_load) and $text_markdown_load == 1){
    print "Converting to HTML from .nk and .md file: OK.\n";
  }else{
    print "Converting to HTML from .nk file: OK.\n";
  }
  my $tmp_prev = undef;
  my $tmp_prev_title = undef;
  my $tmp_next = undef;
  my $tmp_next_title = undef;
  foreach my $entry (sort {$a cmp $b} keys %{$converted}){
    $converted->{$entry}->{prev} = $tmp_prev;
    $converted->{$entry}->{prev_title} = $tmp_prev_title;
    $tmp_prev = $converted->{$entry}->{www_path};
    $tmp_prev_title = $converted->{$entry}->{title};
  }
  foreach my $entry (sort {$b cmp $a} keys %{$converted}){
    $converted->{$entry}->{next} = $tmp_next;
    $converted->{$entry}->{next_title} = $tmp_next_title;
    $tmp_next = $converted->{$entry}->{www_path};
    $tmp_next_title = $converted->{$entry}->{title};
  }
  print "PREVIOUS and NEXT Indexing: OK.\n";
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
  my $template_tag_index = '';
  my $tag_index_flag = 0;
  if(-f $files->{template_tag_index}){
    $tag_index_flag = 1;
    open($fh,"<",$files->{template_tag_index});
    while(<$fh>){$template_tag_index .= $_; }
    close($fh);
  }else{
    $template_tag_index = $template_base;
  }
  my $template_tags = '';
  open($fh,"<",$files->{template_tags});
  while(<$fh>){$template_tags .= $_; }
  close($fh);

  my $entry_num = keys %$converted;
  my $entry_counter = 1;
  print "Deploying...";
  foreach my $entry (sort {$b cmp $a} keys %{$converted}){
    if( $entry_counter % 50 == 0 and $entry_num >= 20){
      print ".";
    }
    $entry_counter++;
    unless(-d $converted->{$entry}->{rel_path}){
      mkpath($dirs->{entry_dir}.$converted->{$entry}->{rel_path});
    }
    my $output_file = $dirs->{entry_dir}.$converted->{$entry}->{rel_path}.$converted->{$entry}->{filename};
    my $body = $template_page;
    my $html = $template_base;
    my $title = &escape_html($converted->{$entry}->{title});
    my $head = $converted->{$entry}->{head};
    my $summary = &escape_html($converted->{$entry}->{summary});
    my $prev = 'NO ENTRY';
    my $next = 'NO ENTRY';
    if(defined($converted->{$entry}->{prev})){
      $prev = "<a href=\"".$converted->{$entry}->{prev}."\">".&escape_html($converted->{$entry}->{prev_title})."</a>";
    }
    if(defined($converted->{$entry}->{next})){
      $next = "<a href=\"".$converted->{$entry}->{next}."\">".&escape_html($converted->{$entry}->{next_title})."</a>";
    }
    my $tmp_tags = $converted->{$entry}->{tags};
    my $tmp_tag_html = '';
    $tmp_tag_html .= "<ul>\n";
    foreach my $tmp_tag (@$tmp_tags){
      $tmp_tag_html .= "<li> <a href=\"".$tag_info->{$tmp_tag}->{path}."\">".&escape_html($tmp_tag)."</a></li>\n";
    }
    $tmp_tag_html .= "</ul>\n";
    my $user_tmp_tag_html = '';

    if(defined($user_function_load) and $user_function_load == 1){
      if(defined(&NikkiUserFunction::related_tags)){
	$user_tmp_tag_html = NikkiUserFunction::related_tags($tmp_tags,$tag_info);
      }
    }
    my $created_at = $hist->{articles}->{$entry}->{created_at};
    my $updated_at = $hist->{articles}->{$entry}->{updated_at};
    my $author = $config->{author};
    my $content = $converted->{$entry}->{content};
    $body =~ s/_=_CONTENT_=_/$content/;
    $body =~ s/_=_RELATED_TAGS_=_/$tmp_tag_html/;
    $body =~ s/_=_USER_DEFINED_RELATED_TAGS_=_/$user_tmp_tag_html/;
    $body =~ s/_=_PREVIOUS_=_/$prev/;
    $body =~ s/_=_NEXT_=_/$next/;
    $body =~ s/_=_CREATED_AT_=_/$created_at/;
    $body =~ s/_=_UPDATED_AT_=_/$updated_at/;
    $body =~ s/_=_AUTHOR_=_/$author/;

    my $twitter_site_name = $config->{twitter_site_name} // '';
    my $twitter_creator = $config->{twitter_creator} // '';
    my $meta_info = "<meta name=\"twitter:card\" content=\"summary\" />\n";
    $meta_info .= "<meta name=\"twitter:site\" content=\"$twitter_site_name\" />\n";
    $meta_info .= "<meta name=\"twitter:creator\" content=\"$twitter_creator\" />\n";
    $meta_info .= "<meta property=\"og:type\" content=\"article\" />\n";
    if(defined($converted->{$entry}->{og_image}) and $converted->{$entry}->{og_image} ne ''){
      $meta_info .= "<meta property=\"og:image\" content=\"".$url_base.$converted->{$entry}->{og_image}."\" />\n";
      $meta_info .= "<meta property=\"twitter:image\" content=\"".$url_base.$converted->{$entry}->{og_image}."\" />\n";
    }else{
      $meta_info .= $og_default_image_str;
      $meta_info .= $twitter_default_image_str;
    }
    if(defined($converted->{$entry}->{og_locale}) and $converted->{$entry}->{og_locale} ne ''){
      $meta_info .= "<meta property=\"og:locale\" content=\"".$url_base.$converted->{$entry}->{og_locale}."\" />\n";
    }else{
      $meta_info .= $og_default_locale_str;
    }
    $meta_info .= "<meta property=\"og:title\" content=\"$title\" />\n";
    $meta_info .= "<meta property=\"og:description\" content=\"$summary\" />\n";

    $html =~ s/_=_META_INFO_=_/$meta_info/;
    $html =~ s/_=_TITLE_=_/$title/;
    $html =~ s/_=_SITE_NAME_=_/$config->{site_name}/g;
    $html =~ s/_=_HEAD_=_/$head/;
    $html =~ s/_=_BODY_=_/$body/;

    $output_file =~ s/(\.nk|\.md)$/\.html/;
    open(my $fh_out,">",$output_file);
    print $fh_out $html;
    close($fh_out);
    push(@$archive,
	 {
	  created_at => $created_at,
	  updated_at => $updated_at,
	  title => $title,
	  summary => $summary,
	  www_path => $converted->{$entry}->{www_path}
	 }
	);
  }
  print "\n";
  print "Creating All Article HTML files: OK\n";
  ## compile archive page
  my $body_archive = $template_archive;
  my $html_archive = $template_base;
  my $output_file_archive = $dirs->{public_dir}.'archive.html';
  my $archive_list = '';
  $archive_list .= "<ul>\n";
  foreach my $entry (@$archive){
    $archive_list .= "<li>".$entry->{created_at}." : <a href=\"".$entry->{www_path}."\">".$entry->{title}."</a></li>\n";
  }
  $archive_list .= "</ul>\n";
  $body_archive =~ s/_=_ARCHIVE_=_/$archive_list/;
  if(defined($user_function_load) and $user_function_load == 1){
    if(defined(&NikkiUserFunction::archive_generator)){
      my $user_archive = NikkiUserFunction::archive_generator($archive);
      $body_archive =~ s/_=_USER_DEFINED_ARCHIVE_=_/$user_archive/;
    }
  }

  my $twitter_site_name = $config->{twitter_site_name} // '';
  my $twitter_creator = $config->{twitter_creator} // '';
  my $meta_info_archive = "<meta name=\"twitter:card\" content=\"summary\" />\n";
  $meta_info_archive .= "<meta name=\"twitter:site\" content=\"$twitter_site_name\" />\n";
  $meta_info_archive .= "<meta name=\"twitter:creator\" content=\"$twitter_creator\" />\n";
  $meta_info_archive .= "<meta property=\"og:title\" content=\"Archive\" />\n";
  $meta_info_archive .= "<meta property=\"og:type\" content=\"blog\" />\n";
  $meta_info_archive .= "<meta property=\"og:description\" content=\"Archive\" />\n";
  $meta_info_archive .= $og_default_image_str;
  $meta_info_archive .= $twitter_default_image_str;
  $meta_info_archive .= $og_default_locale_str;
  $html_archive =~ s/_=_META_INFO_=_/$meta_info_archive/;
  $html_archive =~ s/_=_TITLE_=_/Archive/;
  $html_archive =~ s/_=_SITE_NAME_=_/$config->{site_name}/g;
  $html_archive =~ s/_=_HEAD_=_//;
  $html_archive =~ s/_=_BODY_=_/$body_archive/;
  open(my $fh_archive,">",$output_file_archive);
  print $fh_archive $html_archive;
  close($fh_archive);
  print "Create Archive Page: OK\n";
  ## compile tag page
  my $body_tag_index = '';
  my $html_tag_index = $template_base;
  if($tag_index_flag == 0){
    $body_tag_index .= "<h1>TAG LIST</h1>\n<ul>\n";
  }
  foreach my $tmp_tag (sort keys %$tag_info){
    my $tag_link = $tag_info->{$tmp_tag}->{path};
    my $tag_real_path = $tag_info->{$tmp_tag}->{real_path};
    my $tag_counter = $tag_info->{$tmp_tag}->{counter};
    $body_tag_index .= "<li><a href=\"".$tag_link."\">".&escape_html($tmp_tag)."(".$tag_counter.")"."</a></li>\n";
    my $tag_related = $tag_info->{$tmp_tag}->{related};
    my $body = $template_tags;
    my $html = $template_base;
    my $related_list = "<ul>\n";
    foreach my $entry (@$tag_related){
      $related_list .= '<li>'.$entry->{created_at}.': <a href="'.$entry->{path}.'">'
	.&escape_html($entry->{title})."</a></li>\n";
    }
    $related_list .= "<ul>\n";
    my $user_related_list = "";
    if(defined($user_function_load) and $user_function_load == 1){
      if(defined(&NikkiUserFunction::related_content)){
	$user_related_list = NikkiUserFunction::related_content($tag_related);
      }
    }
    my $tag_name_escaped = &escape_html($tmp_tag);
    my $html_title = 'Related content : ' . &escape_html($tmp_tag);
    $body =~ s/_=_TAG_NAME_=_/$tag_name_escaped/;
    $body =~ s/_=_RELATED_CONTENT_=_/$related_list/;
    $body =~ s/_=_USER_DEFINED_RELATED_CONTENT_=_/$user_related_list/;
    my $meta_info_tag = "<meta name=\"twitter:card\" content=\"summary\" />\n";
    $meta_info_tag .= "<meta name=\"twitter:site\" content=\"$twitter_site_name\" />\n";
    $meta_info_tag .= "<meta name=\"twitter:creator\" content=\"$twitter_creator\" />\n";
    $meta_info_tag .= "<meta property=\"og:title\" content=\"TAG : $tag_name_escaped\" />\n";
    $meta_info_tag .= "<meta property=\"og:type\" content=\"blog\" />\n";
    $meta_info_tag .= "<meta property=\"og:description\" content=\"related list by tag name\" />\n";
    $meta_info_tag .= $og_default_image_str;
    $meta_info_tag .= $twitter_default_image_str;
    $meta_info_tag .= $og_default_locale_str;

    $html =~ s/_=_META_INFO_=_/$meta_info_tag/;

    $html =~ s/_=_HEAD_=_//;
    $html =~ s/_=_TITLE_=_/$html_title/;
    $html =~ s/_=_SITE_NAME_=_/$config->{site_name}/g;
    $html =~ s/_=_BODY_=_/$body/;
    open(my $fh_tags, ">", $tag_info->{$tmp_tag}->{real_path});
    print $fh_tags $html;
    close($html);
  }
  $body_tag_index .= "</ul>\n";

  my $meta_info_tag_index = "<meta name=\"twitter:card\" content=\"summary\" />\n";
  $meta_info_tag_index .= "<meta name=\"twitter:site\" content=\"$twitter_site_name\" />\n";
  $meta_info_tag_index .= "<meta name=\"twitter:creator\" content=\"$twitter_creator\" />\n";
  $meta_info_tag_index .= "<meta property=\"og:title\" content=\"TAGS\" />\n";
  $meta_info_tag_index .= "<meta property=\"og:type\" content=\"blog\" />\n";
  $meta_info_tag_index .= $og_default_image_str;
  $meta_info_tag_index .= $twitter_default_image_str;
  $meta_info_tag_index .= $og_default_locale_str;

  $meta_info_tag_index .= "<meta property=\"og:description\" content=\"Tag list\" />\n";
  $html_tag_index =~ s/_=_META_INFO_=_/$meta_info_tag_index/;
  $html_tag_index =~ s/_=_TITLE_=_/TAG LIST/;
  $html_tag_index =~ s/_=_SITE_NAME_=_/$config->{site_name}/g;
  $html_tag_index =~ s/_=_HEAD_=_//;
  if($tag_index_flag == 0){
    $html_tag_index =~ s/_=_BODY_=_/$body_tag_index/;
  }else{
    $template_tag_index =~ s/_=_TAG_INDEX_=_/$body_tag_index/;
    $html_tag_index =~ s/_=_BODY_=_/$template_tag_index/;
  }
  if(defined($user_function_load) and $user_function_load == 1){
    if(defined(&NikkiUserFunction::tag_index_generator)){
      my $user_tag_index = NikkiUserFunction::tag_index_generator($tag_info);
      $html_tag_index =~ s/_=_USER_DEFINED_TAG_INDEX_=_/$user_tag_index/;
    }
  }
  open(my $fh_tag_index,">",$dirs->{public_dir}.'tags.html');
  print $fh_tag_index $html_tag_index;
  close($fh_tag_index);
  print "Create Tag Page: OK\n";
  ## compile index
  my $body_index = $template_index;
  my $html_index = $template_base;
  my $updates = "<ul>\n";
  my ($front_newest_timestamp,$rear_newest_timestamp) = split(' ',$archive->[0]->{updated_at});
  my $newest_timestamp = $front_newest_timestamp . 'T' . $rear_newest_timestamp . 'Z';
  my $url = '';
  if(defined($config->{url})){
    $url = $config->{url};
  }
  my $atom_content = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<feed xmlnx=\"http://www.w3.org/2005/Atom\">\n\n";
  $atom_content .= "<title>$config->{site_name}</title>\n<link href=\"$url\" />\n<updated>$newest_timestamp</updated>\n<author><name>$config->{author}</name></author>";
  my $counter = 0;
  foreach my $entry (@$archive){
    $counter++;
    if($counter > $config->{whats_new}){
      last;
    }else{
      $updates .= '<li>'.$entry->{created_at}
	.': <a href="'.$entry->{www_path}
	.'">'.$entry->{title}
	."</a> - ".&escape_html($entry->{summary})." - </li>\n";
      $atom_content .= "<entry>\n<title>$entry->{title}</title>\n<link href=\""
	. $url . $entry->{www_path} ."\"/><id>tag:" . $url . $entry->{www_path} . "</id>\n<updated>"
	. $entry->{updated_at}."</updated>\n<summary>"
	. &escape_html($entry->{summary})."</summary>\n</entry>\n";
    }
  }
  $updates .= "</ul>\n";
  $atom_content .= "</feed>\n";

  my $user_updates = '';
  if(defined($user_function_load) and $user_function_load == 1){
    if(defined(&NikkiUserFunction::whats_new)){
      $user_updates = NikkiUserFunction::whats_new($archive,$config);
    }
  }

  open(my $fh_atom, ">", $dirs->{public_dir}.'atom.xml');
  print $fh_atom $atom_content;
  close($fh_atom);
  print "Create atom.xml: OK.\n";
  $updates .= "<ul>\n";
  my $site_name = $config->{site_name};
  $body_index =~ s/_=_UPDATES_=_/$updates/;
  $body_index =~ s/_=_USER_DEFINED_UPDATES_=_/$user_updates/;
  my $meta_info_index = "<meta name=\"twitter:card\" content=\"summary\" />\n";
  $meta_info_index .= "<meta name=\"twitter:site\" content=\"$twitter_site_name\" />\n";
  $meta_info_index .= "<meta name=\"twitter:creator\" content=\"$twitter_creator\" />\n";
  $meta_info_index .= "<meta property=\"og:title\" content=\"$site_name\" />\n";
  $meta_info_index .= "<meta property=\"og:type\" content=\"blog\" />\n";
  $meta_info_index .= "<meta property=\"og:description\" content=\"$site_name : TOP\" />\n";
  $meta_info_index .= $og_default_image_str;
  $meta_info_index .= $twitter_default_image_str;
  $meta_info_index .= $og_default_locale_str;
  $meta_info_index .= "<link rel=\"alternate\" type=\"application/atom+xml\" title=\"Atom\" href=\"$config->{document_root}atom.xml\">\n";

  $html_index =~ s/_=_META_INFO_=_/$meta_info_index/;
  $html_index =~ s/_=_TITLE_=_/$site_name/;
  $html_index =~ s/_=_SITE_NAME_=_/$config->{site_name}/g;
  $html_index =~ s/_=_HEAD_=_//;
  $html_index =~ s/_=_BODY_=_/$body_index/;
  open(my $fh_index, ">", $dirs->{public_dir}.'index.html');
  print $fh_index $html_index;
  close($fh_index);
  print "Create index.html: OK.\n";
  print "COMPLETED!\n";
}
