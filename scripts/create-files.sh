# for every directory in this directory, create a main.tf, outputs.tf and variables.tf file
for d in */; do
    if [ -d "$d" ]; then
        echo "Creating main.tf, outputs.tf and variables.tf in $d"
        touch "$d/main.tf"
        touch "$d/outputs.tf"
        touch "$d/variables.tf"
    fi
done