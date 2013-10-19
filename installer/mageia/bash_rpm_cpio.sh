#!/bin/sh
2	
3	pkg=$1
4	if [ "$pkg" = "" -o ! -e "$pkg" ]; then
5	    echo "no package supplied" 1>&2
6	   exit 1
7	fi
8	
9	leadsize=96
10	o=`expr $leadsize + 8`
11	set `od -j $o -N 8 -t u1 $pkg`
12	il=`expr 256 \* \( 256 \* \( 256 \* $2 + $3 \) + $4 \) + $5`
13	dl=`expr 256 \* \( 256 \* \( 256 \* $6 + $7 \) + $8 \) + $9`
14	# echo "sig il: $il dl: $dl"
15	
16	sigsize=`expr 8 + 16 \* $il + $dl`
17	o=`expr $o + $sigsize + \( 8 - \( $sigsize \% 8 \) \) \% 8 + 8`
18	set `od -j $o -N 8 -t u1 $pkg`
19	il=`expr 256 \* \( 256 \* \( 256 \* $2 + $3 \) + $4 \) + $5`
20	dl=`expr 256 \* \( 256 \* \( 256 \* $6 + $7 \) + $8 \) + $9`
21	# echo "hdr il: $il dl: $dl"
22	
23	hdrsize=`expr 8 + 16 \* $il + $dl`
24	o=`expr $o + $hdrsize`
25	EXTRACTOR="dd if=$pkg ibs=$o skip=1"
26	
27	COMPRESSION=`($EXTRACTOR |file -) 2>/dev/null`
28	if echo $COMPRESSION |grep -q gzip; then
29	        DECOMPRESSOR=gunzip
30	elif echo $COMPRESSION |grep -q bzip2; then
31	        DECOMPRESSOR=bunzip2
32	elif echo $COMPRESSION |grep -q xz; then
33	        DECOMPRESSOR=unxz
34	elif echo $COMPRESSION |grep -q cpio; then
35	        DECOMPRESSOR=cat
36	else
37	        # Most versions of file don't support LZMA, therefore we assume
38	        # anything not detected is LZMA
39	        DECOMPRESSOR=`which unlzma 2>/dev/null`
40	        case "$DECOMPRESSOR" in
41	            /* ) ;;
42	            *  ) DECOMPRESSOR=`which lzmash 2>/dev/null`
43	                 case "$DECOMPRESSOR" in
44	                     /* ) DECOMPRESSOR="lzmash -d -c" ;;
45	                     *  ) DECOMPRESSOR=cat ;;
46	                 esac
47	                 ;;
48	        esac
49	fi
50	
51	$EXTRACTOR 2>/dev/null | $DECOMPRESSOR