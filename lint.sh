#!/bin/bash
pylint=0
echo "Auto-formatting python"
autopep8 --in-place --recursive .
echo "Linting python"
find . -type f -name "*.py" | xargs pylint --rcfile=.config/pylintrc

if [ $? -ne 0 ]
then
	pylint=1
fi
echo "Linting yaml"
yamllint -c .config/yamllint.yml .
if [ $? -ne 0 ]
then
	yamllint=1
fi
if [ $pylint -ne 0 ] || [ $yamllint -ne 0 ]
then
	exit 1
fi
