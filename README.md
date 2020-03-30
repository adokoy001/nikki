nikki.pl - A simple diary authoring tool.
====

## Install

```
$ mkdir your_diary
$ cd your_diary/
$ wget https://raw.githubusercontent.com/adokoy001/nikki/master/nikki.pl
```

## Create Project

```
$ perl nikki.pl init
```

## Create Diary

```
$ perl nikki.pl new
empty article was created. edit /home/yourname/your_diary/articles/2019/12/2019_12_31_001.nk
$ nano articles/2019/12/2019_12_31_001.nk
```

## Generate HTML files

```
$ perl nikki.pl gen
```

After this process completed, You will get static html files in ```public/``` directory.

## .nk Markup Language Cheat Sheet

```

==h1 this line would converted to <h1>*</h1>

==h2 level h2

.
.
.

==h5 level h5


==precode

this area would converted to <pre><code>AREA</code></pre>

precode==


something ==code code style code== 



list like below.

==ul
==li something 001
==li something 002
==li something 003
ul==



You can use other lists(<ol> type="1",a,A,i,I) like below.

==oln  (<ol type="1">)
==ola  (<ol type="a">)
==olA  (<ol type="A">)
==oli  (<ol type="i">)
==olI  (<ol type="I">)


Definition like below.

==dl
==dt Name
==dd Description and Definition
dl==



hyper-link like below.

==a my web site is here ==href https://your.web.site.example.com a==

would converted to : <a href="https://your.web.site.example.com">my web site is here</a>




show image like below.

==img /images/icon/my_icon.png img==

would converted to : <img src="/images/icon/my_icon.png">


```

## Configuration

Global configuration in `etc/config/config.conf` .

```
      {
       site_name => 'SITE NAME',  ## your diary name
       author => 'AUTHOR',  ## your name
       whats_new => 10,  ## number of articles would shown in TOP page.
       document_root => '/',  ## do not change.
       twitter_site_name => '', ## automatically generated meta tag related twitter card.
       twitter_creator => '',  ## Same as above.
       tag_unification => 'case_sensitive',  ## you can set tag generator unification policy.
      };

```


