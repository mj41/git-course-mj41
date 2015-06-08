#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use autodie;
use FindBin ();

use Presentation::Builder::SlideCollection::Reveal;
use Presentation::Builder::RunEnv;
use Presentation::Builder::RunCmd qw/cmdo cd/;

# Parameters:
my $details_level = $ARGV[0] // 10;
my $sleep_mult = (defined $ARGV[1]) ? $ARGV[1] : 1;
my $verbose_level = $ARGV[2] // 3;

my $temp_user_name = 'linus';
my $course_dir = 'git-tt';

my @lt = localtime(time);
my $gen_date = $lt[3].'.'.($lt[4] + 1).'.'.($lt[5] + 1900);

my $rev_struct = cmdo( "cd $FindBin::RealBin; git rev-parse HEAD", no => 1 );
my $src_sha1 = $rev_struct->{out};
my $src_url = "https://github.com/mj41/git-course-mj41/commits/$src_sha1/git-course-mj41.pl";
my $first_slide_suffix_html =
	  '<small>by <a href="http://mj41.cz">Michal Jurosz (mj41)</a><br />'
	. qq|generated: <a href="$src_url">$gen_date</a><br /></small>|;

my $sc = Presentation::Builder::SlideCollection::Reveal->new(
	title => 'Git',
	subtitle => '(FS and DVCS)',
	author => 'Michal Jurosz (mj41)',
	author_url => 'http://mj41.cz',
	date => $gen_date,
	first_slide_suffix_html => $first_slide_suffix_html,
	revealjs_dir => File::Spec->catdir( $FindBin::RealBin, '..', 'third-part', 'reveal.js' ),
	out_fpath => File::Spec->catfile( $FindBin::RealBin, '..', 'final-slides', 'index.html' ),
	sleep_mult => $sleep_mult,
	vl => $verbose_level,
);
sub ap { $sc->process_slide_part(@_) };
sub pc { $sc->process_command(@_) };
sub ar { $sc->add_slide_raw(@_) };
sub sl_sleep { $sc->process_sleep(@_) };

sub img {
	my ( $img_fname, $width ) = @_;
	$width //= '600px';
	return sprintf(
		'<img%s src="%s">',
		(defined $width) ? qq/ width="$width"/ : '',
		'./img/' . $img_fname
	);
}

my $whoami = pc cmdo 'whoami', no => 1;
die "No user '$temp_user_name' but '$whoami'.\n" unless $whoami eq $temp_user_name;

my $home_dir = '/home/'.$temp_user_name;
my $base_dir = $home_dir . '/' . $course_dir;
my $tmp_dir = $home_dir . '/' . $course_dir . '-temp';

if ( -d $base_dir || -d $tmp_dir ) {
	my $dir_suffix = '-' . time() . '-' . $$;
	$base_dir .= $dir_suffix;
	$tmp_dir .= $dir_suffix;
}
mkdir($base_dir);
mkdir($tmp_dir);

die "Directory '$base_dir' not found." unless -d $base_dir;

my $run_env = Presentation::Builder::RunEnv->new(
	reset_env => sub {
		pc cmdo 'stty cols 70', no => 1;
		pc cmdo "mkdir -p $tmp_dir", no => 1;
	},
	init_env => sub {
		chdir( $home_dir );
	},
);

$sc->add_slide(
	'Git FS',
	markdown => <<'MD_END',
> "I really really designed it coming at the problem from the viewpoint
> of a filesystem person (hey, kernels is what I do), and I actually have
> absolutely zero interest in creating a traditional SCM system."

-- Linus Torvals
MD_END
	notes => <<'MD_NOTES',
* Linus Torvals - absolutely zero interest in creating a traditional SCM system
* non-linear development
* VCS - managment of changes
 * who+when - blame, legal issues, backdors
 * code review, issues tracking, continuous integrations
 * compare, restore, merge
 * versioning - stable, testing, devel
MD_NOTES
);

$sc->add_slide(
	'Git',
	markdown => <<'MD_END',
* a content-addressable filesystem
* manages tree snapshots (joined by commits) over time
* distributed version control system
MD_END
);


$sc->add_slide(
	'Why Git? Linux',
	markdown => <<'MD_END',
* 2002 - 2005 proprietary BitKeeper
* Apr 7, Linus Torvals - based on BitKeeper concepts

        Msg:    Initial revision of "git", the information manager
                from hell
        Author: Linus Torvalds <torvalds@ppc970.osdl.org>
        Date:   Thu Apr 7 15:13:13 2005 -0700
        Files:  cat-file.c, commit-tree.c, show-diff.c, ...

* May 26 - Linux 2.6.12 - the first release with Git
* December 21 - Git 1.0
MD_END
);

$sc->add_slide(
	'Linux needs',
	markdown => <<'MD_END',
* distributed, fast, many files, robust
* effective storage - full history
* non-linear development, trial branches, complex merges
* toolkit-based design, pluggable merge strategies
* cryptographic authentication of history
MD_END
	notes => <<'MD_NOTES',
* distributed - commit bit not needed, access control
* rename files - probabylity managment
* tree based merge - without explicit infromations
MD_NOTES
);

$sc->add_slide(
	'Annual Linux Development Report',
	markdown => <<'MD_END',
* by Linux Foundation - April 3, 2012
* Linux 3.2 release - Apr 1, 2012
 * 15,004,006 lines of code
* 72 days since 3.1.
 * 11,881 patches, 6.88 per hour
 * 1,316 developers from 226 organizations
* 2005-2015
 * 12,000 developers from 1200 organizations
MD_END
	notes => <<'MD_NOTES',
* [link](http://www.linuxfoundation.org/news-media/announcements/2015/02/linux-foundation-releases-linux-development-report)
* subsystem trees - be SCSI drivers, x86 architecture code, or networking - “Signed-off-by”
* 75% – The share of all kernel development that is done by developers who are being paid for their work.
* More than 7,800 developers from almost 800 different companies have contributed to the Linux kernel since tracking began in 2005
MD_NOTES
);

$sc->add_slide(
	'No Silver Bullet',
	markdown => <<'MD_END',
* permissions, ownership, empty directories, ...
* individual files (not project's files)
* large binary files ([GitHub: Git LFS](https://github.com/blog/1986-announcing-git-large-file-storage-lfs))

-------

* complexity - commit/push, checkout/clone
* no subtree of repository checkout
* no sequentially revision numbers

-------

* CVS 10%, Git 38%, Subversion 46% - [ohloh.net](http://www.ohloh.net/repositories/compare)
MD_END
);


$sc->add_slide(
	'Pit stop 1',
	markdown => <<'MD_END',
* short intro

----

Questions?
MD_END
);

# ------------------------------------------------------------------------------

$sc->add_slide(
	'git help',
	sub {
		pc cmdo 'git help';
	}
);

$sc->add_slide(
	'Porcelain/plumbing',
	markdown => <<'MD_END',
* porcelain
 * high level
 * user
* plumbing
 * low level
 * scripts (e.g. null string separators)
 * upward compatible
MD_END
);

$sc->add_slide(
	'git help -a',
	sub {
		pc cmdo 'git help -a';
	}
);

$sc->add_slide(
	'git init',
	sub {
		pc cd $base_dir, where_to_print => '~/'.$course_dir;
		pc cmdo 'mkdir repo-MJ';
		pc cd 'repo-MJ';
		pc cmdo 'git init';
		pc cmdo 'ls -a';
		#pc cmdo 'git log';
	}
);

$sc->add_slide(
	'Git files (empty)',
	sub {
		pc cmdo 'rm .git/hooks/*', no => 1;
		pc cmdo 'tree -aF .git';
		pc cmdo "tree --noreport -aF .git > $tmp_dir/tree-empty.out", no => 1;
		# pc cmdo 'cat .git/HEAD';
	}
);

# add image

$sc->add_slide(
	'The three trees 1/2',
	markdown => <<'MD_END',
* "HEAD tree" (in local repository)
 * HEAD - the snapshot of your last commit
* index - cache, staging area
 * proposed next commit snapshot
* working directory (working tree)
 * sandbox, files you see
MD_END
    ,
	notes => <<'MD_NOTES',
* HEAD - parent of next commit
* stash
* remote repositories
MD_NOTES
);


# todo
$sc->add_slide(
	'The three trees 2/2',
	cmd_sub => sub {
		# todo
		ar img 'flow.svg', '400px';
	},
	header => 0,
);

$sc->add_slide(
	'Working directory',
	sub {
		pc cmdo 'pwd';
		pc cmdo 'echo "textA line 1" > fileA.txt';
		pc cmdo 'echo "textB line 1" > fileB.txt';
		pc cmdo 'ls -a';
	}
);

$sc->add_slide(
	'git status',
	sub {
		pc cmdo 'git status';
		pc cmdo 'git status --short';
	}
);

# http://en.wikipedia.org/wiki/File:Git_operations.svg

$sc->add_slide(
	'Index (stage, cache)',
	sub {
		pc cmdo 'git help ls-files | head -7 | tail -3', no_cmd => 1;
		pc cmdo 'git ls-files --cached';
		pc cmdo 'git add fileA.txt';
		pc cmdo 'git ls-files --cached';
	}
);

$sc->add_slide(
	'git status (again)',
	sub {
		pc cmdo 'git status';
		pc cmdo 'git status --short';
	}
);

my $first_sha_name = 'Add to index (stage, cache)';
# todo - indentation before command?
$sc->add_slide(
	$first_sha_name,
	cmd_sub => sub {
		my $sha1 = pc cmdo 'git hash-object fileA.txt', no => 1;
		my $short7_sha1 = substr( $sha1, 0, 7 );
		my $short4_sha1 = substr( $sha1, 0, 4 );
		ap markdown => <<"MD_END";
* objects - blob, tree, commit, tag
 * type, size, content
* SHA-1 hash/checksum - 160-bit, 20 bytes
 * 40 hexadecimal number - e.g. $sha1
 * default 7 shown- e.g. $short7_sha1
 * minimum 4 required - e.g. $short4_sha1
MD_END
		pc cmdo 'git hash-object fileA.txt';
		return {
			firts_short7_sha1 => $short7_sha1,
		};
	},
	notes => <<'MD_NOTES',
* pravdepodobnost
 * 1.2 x 10^24 or 1 million billion billion
 * wolves and your programming team
MD_NOTES
);

$sc->add_slide(
	'.git after index change 1/4',
	sub {
		pc cmdo 'find .git/objects -type f';
		pc cmdo 'git add fileA.txt';
		pc cmdo 'find .git/objects -type f';
		pc cmdo 'tree -aF .git', no_out => 1;
	}
);

$sc->add_slide(
	'.git after index change 2/4',
	sub {
		pc cmdo "tree --noreport -aF .git > $tmp_dir/tree-index.out", no => 1;
		pc cmdo "diff --side --expand-tabs --width 55 $tmp_dir/tree-empty.out $tmp_dir/tree-index.out", no_cmd => 1;
	}
);

$sc->add_slide(
	'.git after index change 3/4',
	sub {
		my $fpath = pc cmdo 'find .git/objects -type f | head -n1', no => 1;
		pc cmdo "hexdump $fpath | head -n1";
		pc cmdo 'git help cat-file | head -6 | tail -1', no_cmd => 1;
		my $blob_sha1 = pc cmdo 'git hash-object fileA.txt', no => 1;
		pc cmdo "git cat-file -p $blob_sha1";
		pc cmdo "git cat-file -t $blob_sha1";
		pc cmdo "git cat-file -s $blob_sha1";
	}
);

$sc->add_slide(
	'.git after index change 4/4',
	sub {
		my $blob_sha1 = pc cmdo 'git hash-object fileA.txt';
		pc cmdo "git cat-file -t $blob_sha1";
		pc cmdo 'file .git/index';
		pc cmdo 'git ls-files --cached';
		pc cmdo 'find .git/objects -type f | head -n 5';
	}
);

$sc->add_slide(
	'Git objects',
	markdown => <<'MD_END',
* blob
* tree
* commit
* tag
MD_END
);

$sc->add_slide(
	'Git objects: blob, tree',
	markdown => <<'MD_END',
* a blob object - content of a file
 * no file name, time stamps, or other metadata
* a tree object - the equivalent of a directory
 * describes a snapshot of the source tree
 * names of blob and tree objects (type bits)
MD_END
);

$sc->add_slide(
	'Git objects: commit',
	markdown => <<'MD_END',
* a commit object
 * links tree objects together into a history
 * the name of a tree object (of the top-level source directory)
 * a time stamp, a log message
 * the names of zero or more parent commit objects
MD_END
);

$sc->add_slide(
	'Git objects: tag',
	markdown => <<'MD_END',
* a tag object
 * a container that contains reference to another object
 * and can hold additional meta-data
MD_END
);

$sc->add_slide(
	'Git objects: Graph example',
	cmd_sub => sub {
		ar img 'data-model-3.png';
	},
	header => 0,
);


$sc->add_slide(
	'First commit (attempt)',
	sub {
		pc cmdo 'git commit -m"commit 01 message"';
	}
);

$sc->add_slide(
	'Config --global (user)',
	sub {
		pc cmdo 'cat ~/.gitconfig';
		pc cmdo 'git config --global user.email "mj@mj41.cz"';
		pc cmdo 'git config --global user.name "Michal Jurosz"';
		pc cmdo 'cat ~/.gitconfig';
	}
);

if ( $details_level >= 2 ) {

	$sc->add_slide(
		'Config --local (directory)',
		sub {
			pc cmdo 'git config --local git-course-conf.local-var1 mj41';
			pc cmdo 'git config git-course-conf.local-var1 mj41';
			pc cmdo 'grep git-course-conf -A 2 .git/config';
			pc cmdo 'git config --remove-section git-course-conf';
			pc cmdo 'grep git-course-conf -A 2 .git/config';
		}
	);

	$sc->add_slide(
		'Config --system (/etc)',
		sub {
			pc cmdo
				'sudo git config --system git-course-conf.system-var1 system-mj41',
				no_run => 1,
				out => ''
			;
			pc cmdo 'cat /etc/gitconfig';
		}
	);

} # end if ( $detail_level ...

$sc->add_slide(
	'git aliases',
	sub {
		pc cmdo 'git config --global alias.st status';
		pc cmdo 'git config --global alias.ci commit';
		pc cmdo 'git config --global alias.co checkout';
		pc cmdo 'git config --global alias.br branch';
	}
);

$sc->add_slide(
	'First commit (finally)',
	sub {
		pc cmdo 'git commit -m"commit 01 message"';
		pc cmdo 'git log';
		pc cmdo 'git log --oneline --decorate';
	}
);

$sc->add_slide(
	'Git file status',
	cmd_sub => sub {
		ar img 'files-lifecycle.png', '800px';
	},
	header => 0,
);

$sc->add_slide(
	'.git after first commit 1/5',
	sub {
		pc cmdo 'tree -aF .git', no_out => 1;
		pc cmdo "tree --noreport -aF .git > $tmp_dir/tree-commit.out", no => 1;
		pc cmdo "diff --side --expand-tabs --width 55 $tmp_dir/tree-index.out $tmp_dir/tree-commit.out > $tmp_dir/diff-commit.out", no => 1;
		pc cmdo "grep -B 100 'objects/' $tmp_dir/diff-commit.out", no_cmd => 1;
	}
);

$sc->add_slide(
	'.git after first commit 2/5',
	sub {
		pc cmdo "grep -A 100 'objects/' $tmp_dir/diff-commit.out", no_cmd => 1;
	}
);

$sc->add_slide(
	'.git after first commit 3/5',
	sub {
		pc cmdo 'cat .git/COMMIT_EDITMSG';
		pc cmdo 'find .git/objects -type f';
	}
);

my $cat_tree_name = 'tree object';
$sc->add_slide(
	$cat_tree_name,
	sub {
		my $commit_sha1 = pc cmdo 'cat .git/refs/heads/master', no => 1;
		my $out = pc cmdo "git cat-file -p $commit_sha1", no => 1;
		my ( $tree_sha1 ) = $out =~ m{tree ([a-f0-9]{40})}m;

		pc cmdo "git cat-file -t $tree_sha1";
		pc cmdo "git cat-file -p $tree_sha1";

		return {
			tree_sha1 => $tree_sha1,
			commit_sha1 => $commit_sha1,
		};
	}
);

my $cat_commit_name = 'commit object';
$sc->add_slide(
	$cat_commit_name,
	cmd_sub => sub {
		my $pars = shift;
		my $commit_sha1 = $pars->{all_results}{$cat_tree_name}{commit_sha1};

		pc cmdo "git cat-file -t $commit_sha1";
		pc cmdo "git cat-file -p $commit_sha1";
		pc cmdo "git log -n1";
	}
);

$sc->add_slide(
	'.gitignore 1/2',
	sub {
		pc cmdo 'touch tempf.tmp';
		pc cmdo 'mkdir -p tmp ; touch tmp/tf.txt';
		pc cmdo 'git status --short';
	}
);

$sc->add_slide(
	'.gitignore 2/2',
	sub {
		pc cmdo q!echo 'tmp/' > .gitignore!;
		pc cmdo q!echo '*.tmp' >> .gitignore!;
		pc cmdo 'git status --short';
		pc cmdo 'git add .gitignore';
	}
);

$sc->add_slide(
	'Second commit',
	sub {
		pc cmdo 'cat fileB.txt';
		pc cmdo 'git add fileB.txt';
		pc cmdo 'git commit -m"commit 02 message"';
		# todo
		# pc cmdo q/git log --decorate --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative/;
		pc cmdo q/git log --decorate --graph --pretty=format:'%h -%d %s <%ae>' --all/;
		pc cmdo 'git branch BRc2';
	}
);

$sc->add_slide(
	'Third commit 1/3',
	sub {
		pc cmdo 'echo "textB line 2" >> fileB.txt';
		pc cmdo 'cat fileB.txt';
		pc cmdo 'mkdir dirH';
		pc cmdo 'echo "textHC line 1" > dirH/fileHC.txt';
	}
);

$sc->add_slide(
	'Third commit 2/3',
	sub {
		pc cmdo 'git status';
	}
);

$sc->add_slide(
	'Third commit 3/3',
	sub {
		pc cmdo 'git add fileB.txt';
		pc cmdo 'git add dirH';
		pc cmdo 'git status';
		pc cmdo 'git commit -m"commit 03 message"';
	}
);

$sc->add_slide(
	'Fourth commit (-a)',
	sub {
		pc cmdo 'echo "textHC line 2" >> dirH/fileHC.txt';
		pc cmdo 'git status';
		# sleep needed to make show different date in git blame slide
		sl_sleep 1;
		pc cmdo 'git commit -a -m"commit 04 message"';
	}
);

# todo - parents of commit

# todo - image of objects
# sl1 - commit, tree, subtree, files
# sl2 +master, HEAD
# sl3 +parent commit
# sl4 links to files

my $cat_tree_name_c4 = 'cat tree (the real one) 1/2';
$sc->add_slide(
	$cat_tree_name_c4,
	sub {
		my $commit_sha1 = pc cmdo 'cat .git/refs/heads/master', no => 1;
		my $out = pc cmdo "git cat-file -p $commit_sha1", no => 1;
		my ( $tree_sha1 ) = $out =~ m{tree ([a-f0-9]{40})}m;

		pc cmdo "git cat-file -t $tree_sha1";
		$out = pc cmdo "git cat-file -p $tree_sha1";
		my ( $dirH_tree_sha1 ) = $out =~ m{tree ([a-f0-9]{40})\tdirH}m;

		pc cmdo "git cat-file -t $dirH_tree_sha1";
		$out = pc cmdo "git cat-file -p $dirH_tree_sha1";
		my ( $fileA_blob_sha1 ) = $out =~ m{blob ([a-f0-9]{40})\tfileHC\.txt}m;

		return {
			fileA_blob_sha1 => $fileA_blob_sha1,
		};
	}
);


$sc->add_slide(
	'cat tree (the real one) 2/2',
	cmd_sub => sub {
		my $pars = shift;
		my $fileA_blob_sha1 = $pars->{all_results}{$cat_tree_name_c4}{fileA_blob_sha1};
		pc cmdo "git cat-file -t $fileA_blob_sha1";
		pc cmdo "git cat-file -p $fileA_blob_sha1";
	},
	notes => <<'MD_NOTES',
* index is prepared from HEAD
MD_NOTES
);



$sc->add_slide(
	'Cryptographic',
	markdown => <<'MD_END',
* the last commit - sha1
* cryptographic authentication of history
* commit
    * -> working tree -> trees + blobs
    * -> parent commit(s)
        * -> working tree(s) ...
        * ...
            * the first commit (without any parent)
MD_END
);

$sc->add_slide(
	'clean index',
	cmd_sub => sub {
		my $pars = shift;
		pc cmdo 'git status --short';
		pc cmdo 'git ls-files -s';
		pc cmdo 'echo "textHC line 3" >> dirH/fileHC.txt';
		pc cmdo 'git add -A ; git status --short';
		pc cmdo 'git ls-files -s';
	},
	notes => <<'MD_NOTES',
* index is prepared from HEAD
MD_NOTES
);

$sc->add_slide(
	'symbolic-ref (HEAD), refs',
	cmd_sub => sub {
		pc cmdo 'git log --oneline --decorate -n2';
		pc cmdo 'cat .git/HEAD';
		pc cmdo 'git symbolic-ref HEAD';
		pc cmdo 'cat .git/refs/heads/master';
		pc cmdo 'git rev-parse --short refs/heads/master';
	},
	notes => <<'MD_NOTES',
* HEAD
 * the last commit that was checked out into your working directory
 * next parent
 * default <ref>, e.g. for log, git diff, ...
MD_NOTES
);

$sc->add_slide(
	'Pit stop 2',
	markdown => <<'MD_END',
* working dir, index, object database (repository)
* blob, tree, commit, tag
* master, HEAD

----

Questions?
MD_END
);

# ------------------------------------------------------------------------------

$sc->add_slide(
	'Garbage',
	markdown => <<'MD_END',
* Garbage accumulates unless collected
* Periodic explicit object packing
MD_END
);

$sc->add_slide(
	'Objects (after commits)',
	sub {
		pc cmdo 'find .git/objects -type f | wc -l';
		pc cmdo 'du -hs .git/objects';
		pc cmdo 'find .git/objects -type f | head -n 10';
	}
);

$sc->add_slide(
	'git gc 1/2',
	sub {
		pc cmdo 'git gc --aggressive --prune';
		pc cmdo 'tree -aF .git/objects';
		pc cmdo 'du -hs .git/objects';
	}
);

$sc->add_slide(
	'git gc 2/2',
	sub {
		my $pars = shift;
		my $fileA_blob_sha1 = $pars->{all_results}{$cat_tree_name_c4}{fileA_blob_sha1};
		pc cmdo "git cat-file -p $fileA_blob_sha1";

		pc cmdo 'tree -aF .git/refs';
		pc cmdo 'cat .git/packed-refs';
	}
);

$sc->add_slide(
	'add after git gc',
	sub {
		pc cmdo 'echo "textA line 2" >> fileA.txt ; git add -A';
		pc cmdo "tree --noreport -aF .git | grep -A 100 'objects/'";
	}
);

$sc->add_slide(
	'git diff (prepare)',
	sub {
		pc cmdo 'git reset --hard HEAD';
		pc cmdo 'echo "textA line 2" >> fileA.txt';
		pc cmdo 'git add -A';
		pc cmdo 'echo "textA line 3" >> fileA.txt';
	}
);

$sc->add_slide(
	'git diff (intro)',
	sub {
		ar img 'diff.svg';
	}
);

$sc->add_slide(
	'git diff',
	sub {
		pc cmdo 'git diff';
	}
);

$sc->add_slide(
	'git diff --cached',
	sub {
		pc cmdo 'git diff --cached';
	}
);

$sc->add_slide(
	'git diff HEAD',
	sub {
		pc cmdo 'git diff HEAD';
	}
);

$sc->add_slide(
	'git diff &lt;ref1> &lt;ref2>',
	sub {
		pc cmdo 'git diff HEAD~3 HEAD~2';
	}
);

$sc->add_slide(
	'revisions - &lt;rev> 1/3',
	cmd_sub => sub {
		my $pars = shift;
		my $firts_short7_sha1 = $pars->{all_results}{$first_sha_name}{firts_short7_sha1};
		ap markdown => <<"MD_END",
* &lt;sha1> - e.g. $firts_short7_sha1
* &lt;refname> - e.g. HEAD, master, origin/master
 * .git/&lt;refname>
 * .git/refs&lt;refname>
 * .git/tags/&lt;refname>
 * .git/heads/&lt;refname>
 * .git/remotes/&lt;refname>
 * ...
* ...
MD_END
	},
	notes => <<'MD_NOTES',
* ...
MD_NOTES
);

$sc->add_slide(
	'revisions - &lt;rev> 2/3',
	cmd_sub => sub {
		my $pars = shift;
		my $firts_short7_sha1 = $pars->{all_results}{$first_sha_name}{firts_short7_sha1};
		ap markdown => <<"MD_END";
&lt;rev>~&lt;n> - e.g. master~3
MD_END
		pc cmdo 'git log -n3 --oneline --decorate';
		pc cmdo 'git rev-parse --short HEAD ; git rev-parse --short HEAD';
		my $head2_sha1 = pc cmdo 'git rev-parse --short HEAD~2';
		pc cmdo "git cat-file -t $head2_sha1";
	},
	notes => <<'MD_NOTES',
* no for ranges
MD_NOTES
);

$sc->add_slide(
	'revisions - &lt;rev> 3/3',
	cmd_sub => sub {
		ap markdown => <<"MD_END";
&lt;rev>:&lt;path>, e.g. HEAD:dirH/fileHC.txt
MD_END
		my $tree_sha1 = pc cmdo 'git rev-parse --short HEAD~1:dirH/fileHC.txt';
		pc cmdo "git cat-file -t $tree_sha1";
	},
	notes => <<'MD_NOTES',
* no for ranges
MD_NOTES
);

$sc->add_slide(
	'revisions ranges 1/3',
	cmd_sub => sub {
		my $pars = shift;
		ap markdown => <<"MD_END";
* &lt;rev> - reachable from &lt;rev>

MD_END
		pc cmdo 'git log --oneline';
		pc cmdo 'git log HEAD~2 --oneline';
		pc cmdo q|git log 'master^{/commit 03}' --oneline|;
	},
	notes => <<'MD_NOTES',
* ...
MD_NOTES
);

$sc->add_slide(
	'revisions ranges 2/3',
	cmd_sub => sub {
		ap markdown => <<'MD_END';
* &lt;rev1>..&lt;rev2>
 * include commits reachable from &lt;rev2>
 * exclude commits reachable from &lt;rev1>
* &lt;rev1>...&lt;rev2>
 * include commits reachable from either &lt;rev1> or &lt;rev2>
 * exclude reachable from both
MD_END
	},
	notes => <<'MD_NOTES',
* ...
MD_NOTES
);

$sc->add_slide(
	'revisions ranges 3/3',
	cmd_sub => sub {
		pc cmdo q|git log 'master^{/01}'..'master^{/03}' --oneline|;
		pc cmdo q|git log 'master^{/03}'...'master^{/01}' --oneline|;
	},
	notes => <<'MD_NOTES',
* ...
MD_NOTES
);

$sc->add_slide(
	'git grep',
	cmd_sub => sub {
		ap markdown => <<'MD_END';
* look for specified patterns in the tracked files
 * in the work tree
 * blobs in given tree objects
MD_END
		pc cmdo q[git grep -n 'line 3'];
		pc cmdo q[git grep -n -e 'line 2' HEAD~1 HEAD~2];
	},
);

$sc->add_slide(
	'git grep --cached',
	cmd_sub => sub {
		ap markdown => <<'MD_END';
* look for specified patterns in the tracked files
 * blobs registered in the index file
MD_END
		pc cmdo q[git grep -n --cached 'line 3'];
		pc cmdo q[git grep -n --cached 'line 2'];
	},
);

$sc->add_slide(
	'git log -- &lt;paths>',
	cmd_sub => sub {
		ap markdown => <<'MD_END';
* commits modifying the given <paths> are selected
* gitk -- &lt;string>
MD_END
		pc cmdo q!git log --oneline -- dirH!;
	},
);

$sc->add_slide(
	'git log -S &lt;string> 1/2',
    markdown => <<'MD_END',
* ... introduce or remove an instance of &lt;string>
* gitk -S &lt;string>
MD_END
	notes => <<'MD_NOTES',
* not the string simply appearing in diff output
 * see gitdiffcore(7) search pickaxe
MD_NOTES
);

$sc->add_slide(
	'git log -S &lt;string> 2/2',
	cmd_sub => sub {
		my $out = pc cmdo q[git log -S 'line 2' --oneline];
		my ( $sha1 ) = $out =~ /^\s*([^\s+]+)/;
		pc cmdo "git show $sha1";
	},
);

$sc->add_slide(
	'git blame',
	cmd_sub => sub {
		ap markdown => <<'MD_END';
* last change of each line
* git gui blame
MD_END
		pc cmdo q[git blame dirH/fileHC.txt];
	},
);

$sc->add_slide(
	'reset and checkout',
	markdown => <<'MD_END',
* the three trees
 * working directory
 * index
 * HEAD
MD_END
);

$sc->add_slide(
	'git reset --hard &lt;rev>',
	markdown => <<'MD_END',
* move HEAD (and the branch)
* reset index
* reset working tree
MD_END
);

# todo - images, v3 in index, v4 in working dir
# http://git-scm.com/blog/2011/07/11/reset.html

$sc->add_slide(
	'git reset [--mixed] &lt;rev>',
	markdown => <<'MD_END',
* move HEAD (and the branch)
* reset index
* <s>reset working tree</s>
MD_END
);

$sc->add_slide(
	'git reset --soft &lt;rev>',
	markdown => <<'MD_END',
* move HEAD (and the branch)
* <s>reset index</s>
* <s>reset working tree</s>
MD_END
);

$sc->add_slide(
	'git checkout/reset -- files',
	sub {
		ar img 'basic-usage.svg';
	}
);

$sc->add_slide(
	'Pit stop 3',
	markdown => <<'MD_END',
* git diff
* &lt;rev> - sha1, HEAD, master, moje-branchA
* gitk, git gui blame
 * git grep, git log -S 'use utf8', git blame
* git reset --hard

----

Questions?
MD_END
);

# ------------------------------------------------------------------------------

$sc->add_slide(
	'branches',
	cmd_sub => sub {
		pc cmdo 'git branch -v';
		pc cmdo 'git branch mj-test';
		pc cmdo 'git branch -v';
		pc cmdo 'git show-ref --head --abbrev';

	}
);

$sc->add_slide(
	'git checkout &lt;branch>',
	markdown => <<'MD_END',
* move _only_ HEAD (switch branch)
* <s>reset</s> index
 * reset _not modified_ files
 * merge modified
* <s>reset</s> working tree
 * reset _not modified_ files
 * merge modified
MD_END
	notes => <<'MD_NOTES',
* without files - switch branch
MD_NOTES
);

$sc->add_slide(
	'git checkout BRc2 1/2',
	cmd_sub => sub {
		pc cmdo 'git branch -v';
		pc cmdo 'git reset --hard master';
		pc cmdo 'cat fileA.txt';
		pc cmdo 'echo "textA line 2" >> fileA.txt';
		pc cmdo 'git add -A';
		pc cmdo 'echo "textA line 3" >> fileA.txt';
	}
);

$sc->add_slide(
	'git checkout BRc2 2/2',
	cmd_sub => sub {
		pc cmdo 'git checkout BRc2';
		pc cmdo 'git status --short';
		pc cmdo q/git diff --cached | grep '+textA'/;
		pc cmdo q/git diff | grep '+textA'/;
	}
);

$sc->add_slide(
	'new branch',
	cmd_sub => sub {
		pc cmdo 'git branch BRc2-pokus';
		pc cmdo q/git branch -v | grep '*'/;
		pc cmdo 'git checkout BRc2-pokus';
		pc cmdo q/git branch -v | grep '*'/;
		pc cmdo 'cat .git/HEAD';
	}
);

$sc->add_slide(
	'checkout -b (new branch)',
	cmd_sub => sub {
		pc cmdo 'git checkout -b BRc2-mod';
		pc cmdo 'git branch -d BRc2-pokus';
		pc cmdo 'git branch -v';
	}
);

$sc->add_slide(
	'new branch commits 1/2',
	cmd_sub => sub {
		# sleep needed to make '--date-order' work as minimal resolution is 1s
		sl_sleep 1;
		pc cmdo 'git ci -m"branch c2-mod commit A"';
		pc cmdo 'git ci -a -m"branch c2-mod commit B"';
		pc cmdo 'echo "textX line 1" >> fileX.txt';
		pc cmdo 'git add fileX.txt';
		pc cmdo 'git ci -a -m"branch c2-mod commit C - add fileX"';
	}
);

$sc->add_slide(
	'new branch commits 2/2',
	cmd_sub => sub {
		pc cmdo 'git log --all --graph --date-order --decorate --oneline';
		pc cmdo 'git branch -D mj-test';
	}
);

$sc->add_slide(
	'merge',
	cmd_sub => sub {
		pc cmdo 'git checkout master';
		pc cmdo 'git merge BRc2-mod';
		pc cmdo 'git log --all --graph --date-order --decorate --oneline';
	}
);

$sc->add_slide(
	'Remote repositories',
	cmd_sub => sub {
		ar img 'flow.svg', '400px';
	},
	header => 0,
);

$sc->add_slide(
	'GitHub',
	markdown => <<'MD_END',
* a web-based hosting service
 * 3.7M people, 7.1M repositories [June 2013](https://github.com/about/press)
* [A16Z](http://en.wikipedia.org/wiki/Andreessen_Horowitz) investment - July 2012, $100 million USD
* a pastebin-style site called Gist
* private
 * US$7/month for five repositories
 * up to US$200/month for 125 repositories
* Bitbucket, Gitorious, SourceForge, CodePlex, Google Code, Launchpad
MD_END
);

$sc->add_slide(
	'git init --bare',
	cmd_sub => sub {
		pc cd $base_dir, where_to_print => '~/'.$course_dir;
		pc cmdo q!git init git-tut-origin --bare!;
		pc cmdo 'ls git-tut-origin';
	},
);

$sc->add_slide(
	'git remote - origin',
	cmd_sub => sub {
		pc cd $base_dir.'/repo-MJ', where_to_print => '~/'.$course_dir.'/repo-MJ';
		pc cmdo "git remote add origin file://$base_dir/git-tut-origin";
		pc cmdo 'git push origin HEAD';
		pc cmdo q!git log --decorate --oneline!;
	},
);

$sc->add_slide(
	'git fetch',
	cmd_sub => sub {
		pc cd $base_dir.'/repo-MJ', where_to_print => '~/'.$course_dir.'/repo-MJ';
		pc cmdo "git remote -v";
		pc cmdo 'git help fetch | head -7 | tail -2', no_cmd => 1;
		pc cmdo 'git fetch';
	},
);

$sc->add_slide(
	'[Pepa] git clone 1/2',
	cmd_sub => sub {
		pc cd $base_dir, where_to_print => '~/'.$course_dir;
		pc cmdo "git clone file://$base_dir/git-tut-origin repo-Pepy";
		pc cd 'repo-Pepy';
		pc cmdo 'git remote -v';
		pc cmdo 'ls';
	},
);

$sc->add_slide(
	'[Pepa] git clone 2/2',
	cmd_sub => sub {
		pc cmdo 'ls';
		pc cmdo 'git branch -a';
	},
);

$sc->add_slide(
	'[Pepa] git log',
	cmd_sub => sub {
		pc cmdo q!git log --decorate --oneline --graph --all!;
	},
);

$sc->add_slide(
	'git remote - upstream',
	cmd_sub => sub {
		pc cd $base_dir.'/repo-MJ', where_to_print => '../repo-MJ';
		pc cmdo q!git remote add upstream git@github.com:mj41/git-fsdvcs-up.git!;
		pc cmdo q!git fetch upstream!, no_run => 1;
	},
);

$sc->add_slide(
	'git remote - configuration',
	cmd_sub => sub {
		pc cmdo q!git remote -v!;
		pc cmdo q!git config --local --list | grep remote!;
	},
);

$sc->add_slide(
	'git push',
	cmd_sub => sub {
		pc cmdo q!git checkout -b BRnp!;
		pc cmdo q!echo "textA line 4 - BRnp" >> fileA.txt!;
		pc cmdo q!git commit -a -m"branch np commit k"!;
		pc cmdo q!git push origin HEAD!;
	},
);

$sc->add_slide(
	'git push --force',
	markdown => <<'MD_END',
* please no to master
* your topic branche
 * use fixups
 * do it once before merging
MD_END
);

$sc->add_slide(
	'[Pepa] git fetch',
	cmd_sub => sub {
		pc cd $base_dir.'/repo-Pepy', where_to_print => '../repo-Pepy';
		pc cmdo q!git fetch!;
		pc cmdo q!git log --decorate --oneline --graph!;
	},
);

$sc->add_slide(
	'git reset --hard origin/... 1/2',
	cmd_sub => sub {
		pc cd $base_dir.'/repo-MJ', where_to_print => '../repo-MJ';
		pc cmdo q!git checkout master!;
		pc cmdo q!git log --decorate --oneline --all --graph | head -n5!;
	},
);

$sc->add_slide(
	'git reset --hard origin/... 2/2',
	cmd_sub => sub {
		pc cmdo q!git reset --hard origin/BRnp!;
		pc cmdo q!git log --decorate --oneline --all --graph | head -n5!;
		pc cmdo q!git push origin HEAD!;
	},
);

$sc->add_slide(
	'Pit stop 4',
	markdown => <<'MD_END',
* git checkout
* remote repositories
* git push
* git fetch

----

Questions?
MD_END
);


$sc->add_slide(
	'GUI',
	markdown => <<'MD_END',
* gitk --all --date-order
* git gui
 * git gui blame
* Windows: TortoiseGit
* MAC: GitX, GitNub
MD_END
);

$sc->add_slide(
	'Git more 1/2',
	markdown => <<'MD_END',
* git clean
* git commit --amend
* git ci --fixup
* git rebase -i
* git cherry-pick
* git revert
* git tag
MD_END
);

$sc->add_slide(
	'Git more 2/2',
	markdown => <<'MD_END',
* git bisec
* git reflog
* git filter-branch
* git gc
* git fsck
* ...
MD_END
);

$sc->add_slide(
	'Links',
	markdown => <<'MD_END',

* <a href="http://git-scm.com/">git-scm.com</a>
* Pro Git, Scott Chacon
 * license <a href="http://creativecommons.org/licenses/by/3.0/deed.cs" title="Creative Commons Attribution 3.0 Unported">CC BY 3.0</a>
 * <a href="knihy.nic.cz">knihy.nic.cz</a> - Czech translation
* <a href="http://ndpsoftware.com/git-cheatsheet.html">git-cheatsheet</a>
MD_END
);

$sc->add_slide(
	'Thank you',
	markdown => <<'MD_END',
Michal Jurosz (mj41)<br />
<small>[www.GoodData.com](https://www.gooddata.com)</small>
<br />
<p><small>
Generated from <a href="https://github.com/mj41/git-course-mj41">github.com/mj41/git-course-mj41</a> source<br />
by <a href="https://github.com/mj41/Presentation-Builder">Presentation::Builder</a>
 inside <a href="https://github.com/mj41/prbuilder-docker">prbuilder Docker container</a>.<br />
<br />
Powered by <a href="https://github.com/hakimel/reveal.js">reveal.js</a>.<br />
</small></p>
MD_END
);

$sc->add_slide(
	'Questions?',
	markdown => '',
);


if ( $details_level >= 11 ) {

	$sc->add_slide(
		'cherry-pick 1/2',
		cmd_sub => sub {
			pc cmdo q!git checkout -b BRc2-cherry 'master^{/commit 02}'!;
			pc cmdo q!git cherry-pick 'master^{/add fileX}'!;
			pc cmdo q!ls!;
			pc cmdo q!git diff HEAD~1 HEAD | grep '+textX'!;
			pc cmdo q!git log --decorate --oneline!;
		}
	);

	$sc->add_slide(
		'cherry-pick 2/2',
		cmd_sub => sub {
			pc cmdo q!git log --all --graph --date-order --decorate --oneline!;
			pc cmdo q!git checkout master!;
			pc cmdo q!git branch -D BRc2-cherry!;
		}
	);

} # end if ( $detail_level ...

$sc->run_all( $run_env );
