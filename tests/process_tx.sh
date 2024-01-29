check_hash()
{
  # $1: tx hash
  # $2: binary
  # $3: home folder
  txhash=$1
  $2 q tx $txhash -o json --home $3
  code=$($2 q tx $txhash -o json --home $3 | jq -r '.code')
  if [ $code -eq 0 ]
  then
    return 0
  else
    return 1
  fi
}

submit_tx()
{
    # $1: transaction
    # $2: binary
    # $3: home folder
    full_tx="$2 $1 --home $3"
    echo $full_tx
    hash=$($full_tx | jq -r '.txhash')
    sleep $(($COMMIT_TIMEOUT+6))
    check_hash $hash $2 $3
    if [[ $? -eq 1 ]]; then
      printf "Transaction failed:\n$1\n"
      exit 1
    fi
}

submit_ibc_tx()
{
    # $1: transaction
    # $2: binary
    # $3: home folder
    full_tx="$2 $1 --home $3"
    echo $full_tx
    hash=$($full_tx | jq -r '.txhash')
    sleep $(($COMMIT_TIMEOUT*5))
    check_hash $hash $2 $3
    if [[ $? -eq 1 ]]; then
      printf "Transaction failed:\n$1\n"
      exit 1
    fi
}

submit_bad_tx()
{
    # $1: transaction
    # $2: binary
    # $3: home folder
    full_tx="$2 $1 --home $3"
    echo $full_tx
    $full_tx
    if [[ $? -eq 0 ]]; then
      printf "Transaction succeeded:\n$1\n"
      exit 1
    fi
}