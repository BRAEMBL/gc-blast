#!/bin/bash
# VERSION: 0.2.00 #

prefix="BRAEMBLGC"

function html { # HTML Generator {{{
	indices=$(seq $1)

	for i in $indices; do 
		seq[$i]=$(sed -n 's/>//p' ${prefix}-${jobid}-${i}-*.sequence.txt)
	done

cat << HTML > $outhtml
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" /> 
        	<meta name="generator" content="Galaxy %s tool output - see http://g2.trac.bx.psu.edu/" /> 
        	<link rel="stylesheet" href="/static/style/base.css" type="text/css" /> 
		<title>BRAEMBL Galaxy Connect visual report: ${prog}</title>
		<style>
			#banner {
				height: 8em;
				background: #fffeef;
				border-bottom: solid 1px #d3d3d3;
			}
			#banner img {
				margin: 1em;
				height: 100px;
				float: left;
			}
			#banner h2 {
				margin-top: 2em;
				float: left;
			}

			#toc {
				clear: left;
			}
			#toc h2 {
				margin: 0;
			}
			#toc li {
				list-style-type: none;
				font-size: large;
			}


			#content h3 {
				margin-bottom: 0;
			}
			#content h3 font {
				font-size: small;
			}
			#content ul {
				padding: 0;
				/* margin: 0; */
				margin: 0 0 2em 0.5em;
			}
			#content ul li {
				padding: 0 0.5em;
				list-style-type: none;
				list-style-position: inside;
				float: left;
			}
			#content dt {
				margin: 1em 0 0.1em 2em;
				clear: left;
				font-weight: bold;
			}
			#content dt font a {
				font-size: small;
			}
		</style>
	</head>
	<body name="top">
		<div style="height: 8em; background: #fffeef; border-bottom: solid 1px #d3d3d3;">
			<img style="margin: 1em; height: 100px; float: left;" src="./BRAEMBL_logo.png" />
			<h2 style="margin-top: 2em; float: left;">BRAEMBL Galaxy Connect visual report: ${prog}</h2>
		</div>
		<div style="clear: left;">
			<h2 style="margin: 0">List of queries</h2>
			<ul>
HTML

	for i in $indices; do
cat << HTML >> $outhtml
				<li style="list-style-type: none; font-size: large;"><a href="#${i}">${seq[$i]}</a></li>
HTML
	done

cat << HTML >> $outhtml
			</ul>
		</div>
		<div>
			<h2>Queries</h2>
HTML

	for i in $indices; do

cat << HTML >> $outhtml
			<dl>
				<h3 style="margin-bottom: 0"><a name="${i}">&gt;&nbsp;${seq[$i]}
				<font style="font-size: small"><a href="#top"> ^top</a></font></a></h3>
HTML
		list=$( ls ${prefix}-${jobid}-${i}-*.error.txt 2>/dev/null )
		if [[ "$list" ]]; then # Show error message if there is an error
cat << HTML >> $outhtml
				<p>
HTML
				cat ${prefix}-${jobid}-${i}-*.error.txt
cat << HTML >> $outhtml
				</p>
HTML
		else
			cvisual=$(ls ${prefix}-${jobid}-${i}-*.complete-visual-png.png)
		 	visual=$(ls ${prefix}-${jobid}-${i}-*.visual-png.png)
cat << HTML >> $outhtml
				<ul style="padding: 0; margin: 0 0 2em 0.5em;">
					<li style="padding: 0 0.5em; list-style-type: none; list-style-position: inside; float: left;">
						<a href="#${i}_complete_visual">All alignments</a></li>
					<li style="padding: 0 0.5em; list-style-type: none; list-style-position: inside; float: left;">
						<a href="#${i}_visual">Significant alignments</a></li>
HTML
			if [[ $prog == "blastp" || $prog == "blastx" ]]; then
cat << HTML >> $outhtml
					<li style="padding: 0 0.5em; list-style-type: none; list-style-position: inside; float: left;">
						<a href="#${i}_ffdp_query">Fast Family Domain Prediction (query)</a></li>
					<li style="padding: 0 0.5em; list-style-type: none; list-style-position: inside; float: left;">
						<a href="#${i}_ffdp_subject">Fast Family and Domain Prediction (subject)</a></li>
HTML
			fi
cat << HTML >> $outhtml
				</ul>
				<dt style="margin: 1em 0 0.1em 2em; clear: left; font-weight: bold;"><a name="${i}_complete_visual">All alignments with significant matches
					<font><a href="#${i}" style="font-size: small"> ^back</a></font></a></dt>
					<dd><img src="$cvisual" /></dd>
				<dt style="margin: 1em 0 0.1em 2em; clear: left; font-weight: bold;"><a name="${i}_visual">Sequences producing significant alignments
					<font><a href="#${i}" style="font-size: small"> ^back</a></font></a></dt>
					<dd><img src="$visual" /></dd>
HTML
			if [[ $prog == "blastp" || $prog == "blastx" ]]; then
				ffdpq=$(ls ${prefix}-${jobid}-${i}-*.ffdp-query-png.png 2>/dev/null )
				ffdps=$(ls ${prefix}-${jobid}-${i}-*.ffdp-subject-png.png 2>/dev/null )
				if [[ "$ffdpq" ]]; then
cat << HTML >> $outhtml
				<dt style="margin: 1em 0 0.1em 2em; clear: left; font-weight: bold;"><a name="${i}_ffdp_query">Fast Family and Domain predictions with the guery sequence
					<font><a href="#${i}" style="font-size: small"> ^back</a></font></a></dt>
					<dd><img src="$ffdpq" /></dd>
HTML
				fi
				if [[ "$ffdps" ]]; then
cat << HTML >> $outhtml
				<dt style="margin: 1em 0 0.1em 2em; clear: left; font-weight: bold;"><a name="${i}_ffdp_subject">Fast Family and Domain predictions without the guery sequence
					<font><a href="#${i}" style="font-size: small"> ^back</a></font></a></dt>
					<dd><img src="$ffdps" /></dd>
HTML
				fi
			fi
		fi
cat << HTML >> $outhtml
			</dl>
HTML
	done

cat << HTML >> $outhtml
		</div>
	</body>
</html>
HTML
} # }}}

# all given paths should be absolute
  input=$1
 outtxt=$2
 outtab=$3
outhtml=$4
  jobid=$5
dirhtml=$6
 header=$7

if [[ "$input" == '-h' ]]; then
	# debugging purpose
	 scount=$(grep -c '^>' $2)
	outhtml=$3
	  jobid=$4
	dirhtml=${outhtml}_files
	   base=$(dirname $0)

	cp $base/BRAEMBL_logo.png $dirhtml/
	cp ${prefix}-${jobid}-*.png $dirhtml/
	mkdir $dirhtml
	html $scount
	exit
fi

  shift 7

  prog=$2
params="$*"
  base=$(dirname $0)
scount=$(grep -c '^>' $input) # counting the number of seqs by the number of '>'

if (( $scount > 1 )); then
	params=$params" --multifasta"
fi
params=$params" --prefix=${prefix}-${jobid}"
$base/braemblgc_blast.pl $params $input > ${prefix}-${jobid}.log 2>&1
bgccode=$?

grep -e 'JobId' -e 'FINISHED' -e 'FAILURE' -e 'NOT_FOUND' -e 'ERROR' ${prefix}-${jobid}.log

# First two are already taken care of
  if (( $bgccode == 1 )); then # Input access error
	exit 1
elif (( $bgccode == 2 )); then # Output access error
	exit 2
elif (( $bgccode == 3 )); then # Can't stat job
	echo 'Problem accessing job. Please contact support@braembl.org.au with the error details from Galaxy server'
	exit 3
elif (( $bgccode == 4 )); then # Job failed
	echo 'Job failed. Please contact support@braembl.org.au with the error details from Galaxy server'
	exit 4
elif (( $bgccode == 5 )); then # No such job; this shouldn't happen
	echo 'Job not found. Please contact support@braembl.org.au with the error details from Galaxy server'
	exit 5
elif (( $bgccode == 6 )); then # Other server error
	echo 'Server error. Please contact support@braembl.org.au with the error details from Galaxy server'
	exit 6
elif (( $bgccode >  0 )); then # All other unkonwn error
	echo 'Unknown error. Please contact support@braembl.org.au with the error details from Galaxy server'
	exit 7
fi

# Otherwise relay the output to galaxy
if (( $scount == 1 )); then
	mv *.out.txt $outtxt
else
	cat *.out.txt > $outtxt
fi

if [[ $header == 'T' ]]; then
	$base/blastreformat.pl -H $outtxt > $outtab
else 
	$base/blastreformat.pl $outtxt > $outtab
fi

mkdir $dirhtml/
cp $base/BRAEMBL_logo.png $dirhtml/
cp ${prefix}-${jobid}-*.png $dirhtml/
html $scount
