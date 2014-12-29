#!/bin/bash
#===============================================================================
#
#          FILE:  s3du.sh
# 
#         USAGE:  ./s3du.sh 
# 
#   DESCRIPTION:  Script to obtain the filesize of an S3 bucket
# 
#       OPTIONS:  BUCKETNAME k(KB) m(MB) g(GB)
#  REQUIREMENTS:  -aws cli, s3api
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Troy C. Thompson (), troy.thompson@cognitivenetworks.com
#       COMPANY:  Cognitive Networks
#       VERSION:  1.0
#       CREATED:  12/26/2014 11:37:12 AM PST
#      REVISION:  1
#===============================================================================

RET_CODE_OK=0
RET_CODE_ERROR=1

# Help/Usage function
print_help() {
	echo "$0: Usage"
	echo "    [-h|--help] Print help"
	echo "    [-b|--s3-bucket] (MANDATORY) S3 Bucket Name"
	echo "    [-c|--conversion] (OPTIONAL) Conversion factor (Possible options: K, M, G, T)"
	echo "    [-v|--verbose] (OPTIONAL) Verbose output"
	exit $RET_CODE_ERROR
}

# Check for supported operating system
p_uname=`whereis uname | cut -d' ' -f2`
if [ ! -x "$p_uname" ]; then
	echo "$0: No UNAME available in the system"
	exit $RET_CODE_ERROR;
fi
OS=`$p_uname`
if [ "$OS" != "Linux" ]; then
	echo "$0: Unsupported OS!";
	exit $RET_CODE_ERROR;
fi

# Check if awk is available in the system
p_awk=`whereis awk | cut -d' ' -f2`
if [ ! -x "$p_awk" ]; then
	echo "$0: No AWK available in the system!";
	exit $RET_CODE_ERROR;
fi

# Check if AWSCLI is available in the system (Special case due to aws.cmd)
p_aws=`locate aws | grep 'bin/aws$'`
if [ ! -x "$p_aws" ]; then
	echo "$0: No AWS CLI available in the system!";
	exit $RET_CODE_ERROR;
fi

# Check if bc is available in the system
p_bc=`whereis bc | cut -d' ' -f2`
if [ ! -x "$p_bc" ]; then
	echo "$0: No BC available in the system!";
	exit $RET_CODE_ERROR;
fi

# Parse command line arguments
while test -n "$1"; do
	case "$1" in
	-h|--help)
		print_help
		exit $RET_CODE_OK;
		;;
	-b|--s3-bucket)
		S3_BUCKET=$2
		shift
		;;
	-c|--conversion)
		CONV_FACTOR=$2
		shift
		;;
	-v|--verbose)
		VERBOSE="1"
		;;
	*)
		echo "$0: Unknown Argument: $1"
		print_help
		exit $RET_CODE_ERROR;
		;;
	esac

	shift
done

# Check if mandatory arguments are present
if [ -z "$S3_BUCKET" ]; then
	echo "$0: Required argument (-b|--s3-bucket) is not specified!"
	exit $RET_CODE_ERROR;
fi

# Validate conversion factor
if [ ! -z "$CONV_FACTOR" ]; then
	case "$CONV_FACTOR" in
	k|K)
		DENOMINATOR="1024"
		OUT_STRING="K"
		;;
	m|M)
		DENOMINATOR="$(( 1024 * 1024 ))"
		OUT_STRING="M"
		;;
	g|G)
		DENOMINATOR="$(( 1024 * 1024 * 1024 ))"
		OUT_STRING="G"
		;;
	t|T)
		DENOMINATOR="$(( 1024 * 1024 * 1024 * 1024 ))"
		OUT_STRING="T"
		;;
	*)
		DENOMINATOR="1"
		OUT_STRING="B"
		;;
	esac
else 
	DENOMINATOR="1"
	OUT_STRING="B"
fi

BYTES="0"
# Get the size of the given bucket in bytes
OUTPUT=`$p_aws s3api list-objects --bucket $S3_BUCKET --output text --query "[sum(Contents[].Size)]"`
for I in $OUTPUT; do
	BYTES="$(( BYTES + I ))"
done

# Scale the value accordingly
OUT_VALUE=`echo "scale=2; $BYTES / $DENOMINATOR" | $p_bc`

if [ ! -z "$VERBOSE" ]; then
	printf "S3 Bucket:\t%s\tSize:\t%.2f %s\n" $S3_BUCKET $OUT_VALUE $OUT_STRING
else
	printf "%.2f%s\n" $OUT_VALUE $OUT_STRING
fi

exit $RET_CODE_OK

