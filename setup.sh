echo "WCA Competitions Search Setup"

echo "Enter a region that you would like to limit searches to: "
read region

echo "{ \"region\" : \"${region}\" }" > config.json

echo "Enter the alias name you would like to use, to skip, enter 'skip'"
read alias

if [ "$alias" != "skip" ]; then
    echo "alias ${alias}=$(pwd)/main" >> ~/.zshrc
else
    echo "skipping alias creation"

fi

echo "" > competitions.txt

echo "setup complete"
