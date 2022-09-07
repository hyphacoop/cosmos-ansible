#!/bin/bash
pylint=0
yamllint=0

if [ ! $CI ]
then
	echo "Auto-formatting python"
	autopep8 --in-place --recursive .
fi
echo "Linting python"
find . -type f -name "*.py" | xargs python -m pylint --rcfile=.config/pylintrc
if [ $? -ne 0 ]
then
	pylint=1
	echo "Linting python failed"
fi
echo "Linting yaml"
yamllint -c .config/yamllint.yml .
if [ $? -ne 0 ]
then
	yamllint=1
	echo "Linting yaml failed"
fi
if [ $pylint -ne 0 ] || [ $yamllint -ne 0 ]
then
	exit 1
fi
