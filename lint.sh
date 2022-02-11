echo "Auto-formatting python"
autopep8 --in-place --recursive .
echo "Linting python"
find . -type f -name "*.py" | xargs pylint 
echo "Linting yaml"
yamllint .
