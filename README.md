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


link like below.

==a my web site is here ==href https://your.web.site.example.com a==

would converted to : <a href="https://your.web.site.example.com">my web site is here</a>




show image like below.

==img /images/icon/my_icon.png img==

would converted to : <img src="/images/icon/my_icon.png">


```

