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
#        AUTHOR:  Troy C. Thompson (), troy.thompson@progressfin.com
#       COMPANY:  Nonagon Media
#       VERSION:  1.0
#       CREATED:  12/26/2014 11:37:12 AM PST
#      REVISION:  2
#===============================================================================

#Make sure a bucket name is given
if [ -z "$1" ]; then
  echo "USAGE: s3du BUCKETNAME [b|k|m|g]"
  exit 1
else
  bucket=$1
  convert_size=$2
fi

#Make sure a conversion size is selected
if [ -z "$2" ]; then
  echo "Using bytes because no conversion size was given"
  bucket=$1
  convert_size='b'
fi


#===  FUNCTION  ================================================================
#          NAME:  convert
#   DESCRIPTION:  Converts the bucket size (in bytes) to desired format (KB,MB, or GB)
#    PARAMETERS:  k,m,g (output format) | bucket size in bytes
#       RETURNS:  Currently does not return a value, but echo's it to stdout
#===============================================================================
function convert ()
{

output_format=$1
 target_value=$2
 shift;
 shift;
 IGNORED=$@


 case "$output_format" in
  b)
   echo "$target_value"
   ;;
  k)  
   bucket_size="$(( $target_value / 1024 ))" 
   echo "$bucket_size"
   ;;  
  m)  
   kb="$(( $target_value / 1024 ))" 
   bucket_size="$(( $kb / 1024 ))" 
   echo "$bucket_size"
   ;;  
  g)  
   kb="$(( $target_value / 1024 ))" 
   mb="$(( $kb / 1024 ))" 
   bucket_size="$(( $mb / 1024 ))" 
   echo "$bucket_size"
   ;; 
  *) 
   echo "Incorrect value given for the conversion size"
   echo "USAGE: s3du BUCKETNAME [b|k|m|g]" 
   exit 1
   ;;  
  esac
}    # ----------  end of function convert  ----------

#This line gets the size of the given bucket in bytes
bytesize=`aws s3api list-objects --bucket $bucket --output json --query "[sum(Contents[].Size)]" | sed '2q;d' | sed -e 's/^[ \t]*//'`

#This line passes the bucket's byte size and conversion type to the convert function
convert $convert_size $bytesize
