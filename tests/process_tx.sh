check_code()
{
  txhash=$1
  code=$($CHAIN_BINARY q tx $txhash -o json | jq '.code')
  if [ $code -eq 0 ]
  then
    return 0
  else
    return 1
  fi
}

submit_tx()
{
    echo $1
    hash=$($1 | jq -r '.txhash')
    check=$(check_code $hash)
    if [ check -eq 1 ]; then
      printf "Transaction failed:\n$1\n"
      exit 1
    fi
}
